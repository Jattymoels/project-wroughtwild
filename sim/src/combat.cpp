#include "wroughtwild/combat.h"

#include <algorithm>
#include <cmath>
#include <random>
#include <sstream>
#include <stdexcept>

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
    else if (effect.operation == "player_damage_multiplier") mods.playerDamageMultiplier *= param(effect, "value", 1.0);
    else if (effect.operation == "incoming_damage_multiplier") mods.incomingDamageMultiplier *= param(effect, "value", 1.0);
    else if (effect.operation == "enemy_life_multiplier") mods.enemyLifeMultiplier *= param(effect, "value", 1.0);
    else {
        // Spatial trial boons are interpreted here and timed/applied by Godot.
        // Distinct effects compose by name; multiplier effects multiply.
        const bool multiplier = effect.operation.find("multiplier") != std::string::npos;
        auto [it, inserted] = mods.trialEffects.emplace(effect.operation, multiplier ? 1.0 : 0.0);
        (void)inserted;
        if (multiplier) it->second *= param(effect, "value", 1.0);
        else it->second += param(effect, "value", 0.0);
    }
}

} // namespace

std::string HitStream::checkpoint() const {
    std::ostringstream out;
    out << hitCounter_ << '\n' << rng_;
    return out.str();
}
HitStream HitStream::restore(const std::string& text) {
    HitStream restored(0);
    std::istringstream in(text);
    if (!(in >> restored.hitCounter_ >> restored.rng_) || restored.hitCounter_ < 0)
        throw std::runtime_error("combat checkpoint: invalid hit stream");
    in >> std::ws;
    if (!in.eof()) throw std::runtime_error("combat checkpoint: trailing data");
    return restored;
}

HitStream::Roll HitStream::roll(const CombatMods& mods) {
    Roll r;
    r.variance = variance_(rng_);
    r.echo = mods.repeatHitCount > 0 && ++hitCounter_ % mods.repeatHitCount == 0;
    return r;
}

double HitStream::dealt(double base, const Roll& roll, const CombatMods& mods, bool isolated) const {
    base *= mods.playerDamageMultiplier;
    if (isolated) base *= mods.isolatedDamageMultiplier;
    double out = base * roll.variance;
    if (roll.echo) out += base * mods.repeatDamageMultiplier;
    return out;
}

double HitStream::playerHit(const tuning::CombatSkillDef& skill, const CombatMods& mods, bool isolated) {
    auto baseIt = skill.numbers.find("base_damage");
    const double base = baseIt == skill.numbers.end() ? 0.0 : baseIt->second;
    return dealt(base, roll(mods), mods, isolated);
}

std::vector<grammar::HitPacket> HitStream::playerHit(std::vector<grammar::HitPacket> packets,
                                                     const CombatMods& mods, bool isolated) {
    const Roll r = roll(mods);
    for (auto& packet : packets) packet.damage = dealt(packet.damage, r, mods, isolated);
    return packets;
}

double HitStream::enemyHit(double rawDamage, const std::string& damageType,
                           const stats::DerivedStats& playerStats, const tuning::PlayerBase& base) {
    return stats::mitigateDamage(rawDamage * variance_(rng_), damageType, playerStats, base);
}

double trainMultiplier(int earlierHitsInWindow, const tuning::RealtimeTable& rt) {
    if (earlierHitsInWindow <= 0) return 1.0;
    return 1.0 + std::min(rt.hordeTrainMaxBonus, rt.hordeTrainBonusPerHit * earlierHitsInWindow);
}

namespace {
double controlWeight(const std::string& verb) {
    if (verb == "harry") return 0.3;
    if (verb == "guard") return 0.2;
    if (verb == "mark") return 0.25;
    if (verb == "root") return 0.35;
    if (verb == "kindle") return 0.2;
    if (verb == "swarm") return 0.2;
    if (verb == "ward") return 0.25;
    if (verb == "recruit") return 0.5;
    return 0.0;
}
} // namespace

double threatScore(const tuning::EnemyDef& enemy, const tuning::BehaviourRealtime& behaviour) {
    const double perRound = enemy.damage / static_cast<double>(std::max(1, enemy.attackPeriodRounds));
    const double reach = behaviour.attackRangeM >= 5.0 ? 1.3 : 1.0;
    const double bulk = std::sqrt(std::max(1.0, enemy.maxLife) / 75.0);
    return perRound * reach * bulk * (1.0 + controlWeight(behaviour.verb));
}

double packThreat(const tuning::WorldTable& world, const tuning::RealtimeTable& rt, const std::vector<std::string>& pack) {
    double total = 0.0;
    for (const auto& id : pack) {
        const auto* enemy = world.findEnemy(id);
        if (!enemy) continue;
        const auto* behaviour = rt.findBehaviour(enemy->behaviour);
        if (!behaviour) continue;
        total += threatScore(*enemy, *behaviour);
    }
    return total;
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
                                       const std::vector<std::string>& enemyIds,
                                       const tuning::BossDef* runBoss) {
    std::vector<Combatant> combatants;
    for (const auto& id : enemyIds) {
        Combatant c;
        const tuning::BossDef* bossDef = id == tuning.trial.boss.id ? &tuning.trial.boss : nullptr;
        for (const auto& floor : tuning.trial.floors)
            if (id == floor.boss.id) bossDef = &floor.boss;
        for (const auto& expedition : tuning.trial.expeditions)
            if (!bossDef && id == expedition.boss.id) bossDef = &expedition.boss;
        if (runBoss && id == runBoss->id) bossDef = runBoss;
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
                             std::vector<std::string>* log,
                             const tuning::BossDef* runBoss) {
    std::vector<Combatant> enemies = buildCombatants(tuning, enemyIds, runBoss);
    for (auto& enemy : enemies) {
        enemy.life *= mods.enemyLifeMultiplier;
        enemy.maxLife *= mods.enemyLifeMultiplier;
        enemy.damage *= mods.enemyDamageMultiplier;
        enemy.breathDamage *= mods.enemyDamageMultiplier;
    }
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
            double taken = hits.enemyHit(incoming * mods.incomingDamageMultiplier, incomingType, playerStats, tuning.world.playerBase);
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
