#include "wroughtwild/combat.h"

#include <algorithm>
#include <cmath>
#include <random>

namespace wroughtwild::combat {

namespace {

double param(const tuning::BoonEffect& effect, const std::string& key, double fallback) {
    auto it = effect.parameters.find(key);
    return it == effect.parameters.end() ? fallback : it->second;
}

void applyEffect(CombatMods& mods, const tuning::BoonEffect& effect) {
    if (effect.operation == "enemy_speed_multiplier")
        mods.enemySpeedMultiplier *= param(effect, "value", 1.0);
    else if (effect.operation == "reward_quantity_multiplier")
        mods.rewardQuantityMultiplier *= param(effect, "value", 1.0);
    else if (effect.operation == "repeat_every_nth_hit") {
        mods.repeatHitCount = static_cast<int>(param(effect, "hit_count", 0.0));
        mods.repeatDamageMultiplier = param(effect, "damage_multiplier", 0.0);
    } else if (effect.operation == "damage_multiplier_against_isolated")
        mods.isolatedDamageMultiplier *= param(effect, "value", 1.0);
    else if (effect.operation == "area_multiplier_against_isolated")
        mods.isolatedAreaMultiplier *= param(effect, "value", 1.0);
}

} // namespace

double HitStream::playerHit(const tuning::CombatSkillDef& skill, const CombatMods& mods, bool isolated) {
    auto baseIt = skill.numbers.find("base_damage");
    double base = baseIt == skill.numbers.end() ? 0.0 : baseIt->second;
    if (isolated) base *= mods.isolatedDamageMultiplier;
    double dealt = base * variance_(rng_);
    if (mods.repeatHitCount > 0 && ++hitCounter_ % mods.repeatHitCount == 0)
        dealt += base * mods.repeatDamageMultiplier;
    return dealt;
}

double HitStream::enemyHit(double rawDamage, const std::string& damageType,
                           const stats::DerivedStats& playerStats, const tuning::PlayerBase& base) {
    return stats::mitigateDamage(rawDamage * variance_(rng_), damageType, playerStats, base);
}

CombatMods buildMods(const tuning::BoonTable& table, const boons::RunState& run) {
    CombatMods mods;
    for (const auto& boon : table.boons)
        if (run.hasBoon(boon.id))
            for (const auto& effect : boon.effects) applyEffect(mods, effect);
    for (const auto& weakness : table.weaknesses)
        if (run.hasWeakness(weakness.id))
            for (const auto& effect : weakness.effects) applyEffect(mods, effect);
    mods.rewardQuantityMultiplier *= boons::rewardMultiplier(table, run);
    return mods;
}

int CombatView::aliveEnemyCount() const {
    int count = 0;
    for (const auto& enemy : *enemies)
        if (enemy.alive()) ++count;
    return count;
}

namespace {

std::vector<Combatant> buildCombatants(const tuning::Tuning& tuning,
                                       const std::vector<std::string>& enemyIds) {
    std::vector<Combatant> combatants;
    for (const auto& id : enemyIds) {
        Combatant c;
        const tuning::BossDef* bossDef = id == tuning.trial.boss.id ? &tuning.trial.boss : nullptr;
        for (const auto& floor : tuning.trial.floors)
            if (id == floor.boss.id) bossDef = &floor.boss;
        if (bossDef != nullptr) {
            const tuning::BossDef& boss = *bossDef;
            c.id = boss.id;
            c.displayName = boss.displayName;
            c.life = c.maxLife = boss.maxLife;
            c.damage = boss.clawDamage;
            c.damageType = boss.clawDamageType;
            c.attackPeriodRounds = boss.clawPeriodRounds;
            c.isBoss = true;
            c.breathDamage = boss.breathDamage;
            c.breathDamageType = boss.breathDamageType;
            c.breathPeriodRounds = boss.breathPeriodRounds;
        } else {
            const tuning::EnemyDef* def = tuning.world.findEnemy(id);
            if (!def) continue;
            c.id = def->id;
            c.displayName = def->displayName;
            c.life = c.maxLife = def->maxLife;
            c.damage = def->damage;
            c.damageType = def->damageType;
            c.attackPeriodRounds = def->attackPeriodRounds;
        }
        combatants.push_back(std::move(c));
    }
    return combatants;
}

bool hasTag(const tuning::CombatSkillDef& def, const std::string& tag) {
    return std::find(def.tags.begin(), def.tags.end(), tag) != def.tags.end();
}

void logLine(std::vector<std::string>* log, const std::string& text) {
    if (log) log->push_back(text);
}

} // namespace

Action autoPolicy(const CombatView& view) {
    int dash = -1, area = -1, heavy = -1;
    for (size_t i = 0; i < view.skills->size(); ++i) {
        const SkillSlot& slot = (*view.skills)[i];
        if (!slot.ready()) continue;
        if (hasTag(*slot.def, "movement")) dash = static_cast<int>(i);
        else if (hasTag(*slot.def, "area")) area = static_cast<int>(i);
        else if (hasTag(*slot.def, "single_target")) heavy = static_cast<int>(i);
    }

    if (view.breathIncoming && dash >= 0) return {dash, 0};

    int firstAlive = 0;
    for (size_t i = 0; i < view.enemies->size(); ++i)
        if ((*view.enemies)[i].alive()) { firstAlive = static_cast<int>(i); break; }

    if (view.aliveEnemyCount() >= 2 && area >= 0) return {area, firstAlive};
    if (heavy >= 0) return {heavy, firstAlive};
    if (area >= 0) return {area, firstAlive};
    return {-1, 0};
}

EncounterResult runEncounter(const tuning::Tuning& tuning,
                             const stats::DerivedStats& playerStats,
                             const CombatMods& mods,
                             const std::vector<std::string>& enemyIds,
                             uint64_t seed,
                             const Controller& controller,
                             std::vector<std::string>* log) {
    std::vector<Combatant> enemies = buildCombatants(tuning, enemyIds);
    HitStream hits(seed);

    // The round model fights with the starting bar (D-016): learned skills
    // are the real-time game's business, and the balance baseline must not
    // shift every time skills.json gains a page.
    std::vector<SkillSlot> skills;
    for (const auto& def : tuning.skills.combatSkills) {
        if (!def.starting) continue;
        SkillSlot slot;
        slot.def = &def;
        auto cd = def.numbers.find("cooldown_seconds");
        slot.cooldownRounds =
            std::max(1, static_cast<int>(std::ceil(cd == def.numbers.end() ? 1.0 : cd->second)));
        skills.push_back(slot);
    }

    double playerLife = playerStats.maxLife;
    EncounterResult result;

    const int maxRounds = 200; // attrition guard: outlasting this counts as defeat
    for (int round = 1; round <= maxRounds; ++round) {
        result.rounds = round;

        bool breathThisRound = false;
        for (const auto& enemy : enemies)
            if (enemy.isBoss && enemy.alive() && round % enemy.breathPeriodRounds == 0)
                breathThisRound = true;

        CombatView view;
        view.round = round;
        view.playerLife = playerLife;
        view.playerMaxLife = playerStats.maxLife;
        view.breathIncoming = breathThisRound;
        view.enemies = &enemies;
        view.skills = &skills;

        Action action = controller(view);
        bool dodging = false;

        if (action.skillIndex >= 0 && action.skillIndex < static_cast<int>(skills.size()) &&
            skills[action.skillIndex].ready()) {
            SkillSlot& slot = skills[action.skillIndex];
            slot.cooldownRemaining = slot.cooldownRounds;
            const tuning::CombatSkillDef& def = *slot.def;

            if (hasTag(def, "movement")) {
                dodging = true;
                logLine(log, "You dash clear of danger.");
            } else {
                const bool isolated = view.aliveEnemyCount() == 1;

                auto strike = [&](Combatant& target) {
                    if (!target.alive()) return;
                    double dealt = hits.playerHit(def, mods, isolated);
                    target.life -= dealt;
                    logLine(log, def.displayName + " hits " + target.displayName + " for " +
                                     std::to_string(static_cast<int>(dealt)) +
                                     (target.alive() ? "." : " - slain!"));
                };

                if (hasTag(def, "area")) {
                    for (auto& enemy : enemies) strike(enemy);
                } else {
                    int target = std::clamp(action.targetIndex, 0,
                                            static_cast<int>(enemies.size()) - 1);
                    if (!enemies[target].alive())
                        for (size_t i = 0; i < enemies.size(); ++i)
                            if (enemies[i].alive()) { target = static_cast<int>(i); break; }
                    strike(enemies[target]);
                }
            }
        } else {
            logLine(log, "You catch your breath.");
        }

        for (auto& slot : skills)
            if (slot.cooldownRemaining > 0) --slot.cooldownRemaining;

        bool anyAlive = false;
        for (auto& enemy : enemies) {
            if (!enemy.alive()) continue;
            anyAlive = true;

            double incoming = 0.0;
            std::string incomingType;
            if (enemy.isBoss && round % enemy.breathPeriodRounds == 0) {
                incoming = enemy.breathDamage;
                incomingType = enemy.breathDamageType;
                logLine(log, enemy.displayName + " breathes fire!");
            } else if (enemy.isBoss && (round + 1) % enemy.breathPeriodRounds == 0) {
                enemy.actionPoints += mods.enemySpeedMultiplier;
                while (enemy.actionPoints >= enemy.attackPeriodRounds) {
                    enemy.actionPoints -= enemy.attackPeriodRounds;
                    incoming += enemy.damage;
                    incomingType = enemy.damageType;
                }
                logLine(log, enemy.displayName + " inhales deeply - fire is coming!");
            } else {
                enemy.actionPoints += mods.enemySpeedMultiplier;
                while (enemy.actionPoints >= enemy.attackPeriodRounds) {
                    enemy.actionPoints -= enemy.attackPeriodRounds;
                    incoming += enemy.damage;
                    incomingType = enemy.damageType;
                }
            }

            if (incoming <= 0.0) continue;
            if (dodging) {
                logLine(log, "You evade " + enemy.displayName + "'s attack.");
                continue;
            }
            double taken = hits.enemyHit(incoming, incomingType, playerStats, tuning.world.playerBase);
            playerLife -= taken;
            logLine(log, enemy.displayName + " hits you for " +
                             std::to_string(static_cast<int>(taken)) + ".");
        }

        if (playerLife <= 0.0) {
            result.victory = false;
            result.playerLifeRemaining = 0.0;
            logLine(log, "You fall.");
            return result;
        }
        if (!anyAlive) {
            result.victory = true;
            result.playerLifeRemaining = playerLife;
            logLine(log, "The room is clear.");
            return result;
        }
    }

    result.victory = false;
    result.playerLifeRemaining = playerLife;
    logLine(log, "The attempt drags on too long; you withdraw defeated.");
    return result;
}

} // namespace wroughtwild::combat
