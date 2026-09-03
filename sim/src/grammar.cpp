#include "wroughtwild/grammar.h"

#include <algorithm>
#include <cmath>

namespace wroughtwild::grammar {

namespace {

const tuning::CombatSkillDef* findSkill(const tuning::Tuning& tuning, const std::string& skillId) {
    for (const auto& def : tuning.skills.combatSkills)
        if (def.id == skillId) return &def;
    return nullptr;
}

double skillNumber(const tuning::CombatSkillDef& def, const std::string& key, double fallback) {
    auto it = def.numbers.find(key);
    return it == def.numbers.end() ? fallback : it->second;
}

// Buildup for one status: the skill's own payload number (0 when it has
// none - a flat add_* mod matching the tags can still supply one), scaled by
// mods matching the skill's tags, then by the boss resistance rule.
double statusApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                     const std::string& skillId, const char* payloadKey,
                     const char* resolveKey, double bossMultiplier, bool isBoss) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    double base = skillNumber(*def, payloadKey, 0.0);
    double applied = resolve(active, def->resolveTags(), resolveKey, base);
    if (applied <= 0.0) return 0.0;
    if (isBoss) applied *= bossMultiplier;
    return applied;
}

} // namespace

bool modAppliesToTags(const std::vector<std::string>& appliesToTags,
                      const std::vector<std::string>& tags) {
    if (appliesToTags.empty()) return true;
    for (const auto& wanted : appliesToTags)
        if (std::find(tags.begin(), tags.end(), wanted) != tags.end()) return true;
    return false;
}

double resolve(const ActiveMods& active,
               const std::vector<std::string>& tags,
               const std::string& key,
               double base) {
    double flat = 0.0;
    double increased = 0.0;
    double more = 1.0;
    const std::string add = "add_" + key;
    const std::string inc = "increased_" + key;
    const std::string mre = "more_" + key;
    for (const auto& mod : active) {
        if (!modAppliesToTags(mod.appliesToTags, tags)) continue;
        if (mod.effectKey == add) flat += mod.value;
        else if (mod.effectKey == inc) increased += mod.value;
        else if (mod.effectKey == mre) more *= (1.0 + mod.value);
    }
    return (base + flat) * (1.0 + increased) * more;
}

ActiveMods gearMods(const tuning::ItemTable& table, const stats::Equipment& equipment) {
    ActiveMods mods;
    for (const auto& [slot, item] : equipment.slots) {
        const tuning::ItemBase* base = table.findBase(item.baseId);
        if (base) {
            for (const auto& implicit : base->implicitModifiers) {
                const auto* def = table.findModifier(implicit.id);
                if (def) mods.push_back({def->id, def->appliesToTags, def->effectKey, implicit.value, slot});
            }
        }
        for (const auto& rolled : item.rolledProperties) {
            const auto* def = table.findModifier(rolled.propertyId);
            if (!def) continue;
            // The base caps what the roll can say (D-019 held-back rule), and
            // the tier it does say brings its breakpoints with it.
            const items::EffectiveRoll eff = items::effectiveRoll(table, item, rolled);
            mods.push_back({def->id, def->appliesToTags, def->effectKey, eff.value, slot});
            for (const auto* bp : items::breakpointsFor(*def, eff.tier))
                mods.push_back({def->id + "@" + bp->effect, bp->appliesTo, bp->effect, bp->value, slot});
        }
    }
    return mods;
}

double defaultValue(const tuning::ModifierDef& def) {
    const tuning::ModifierTier* first = def.findTier(1);
    if (!first && !def.tiers.empty()) first = &def.tiers.front();
    return first ? first->maximum : 0.0;
}

ActiveMod modAt(const tuning::ItemTable& table, const std::string& modifierId, double value,
                const std::string& source) {
    const auto* def = table.findModifier(modifierId);
    if (!def) return {modifierId, {}, "", 0.0, source};
    return {def->id, def->appliesToTags, def->effectKey, value, source};
}

ActiveMods masteryMods(const tuning::Tuning& tuning, const std::map<std::string, int>& skillUses) {
    ActiveMods mods;
    for (const auto& def : tuning.skills.combatSkills) {
        auto it = skillUses.find(def.id);
        const int uses = it == skillUses.end() ? 0 : it->second;
        for (const auto& perk : def.mastery) {
            if (perk.uses > uses) continue;
            ActiveMod mod = modAt(tuning.items, perk.modifier, perk.value, "mastery:" + def.id);
            mod.appliesToTags = {"skill:" + def.id}; // this skill alone
            mods.push_back(std::move(mod));
        }
    }
    return mods;
}

ActiveMods foundryMods(const tuning::Tuning& tuning, const foundry::State& state, int era) {
    ActiveMods mods;
    const auto size = foundry::plateSize(tuning.foundry, era);
    for (const auto& effect : foundry::effects(tuning.foundry, state, size))
        mods.push_back(modAt(tuning.items, effect.modifier, effect.value, "foundry:" + effect.kind));
    return mods;
}

int forkCount(const tuning::Tuning& tuning, const ActiveMods& active,
              const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0;
    double base = skillNumber(*def, "fork_count", 0.0);
    return static_cast<int>(std::floor(resolve(active, def->resolveTags(), "fork", base)));
}

double forkDamageFraction(const tuning::Tuning& tuning, const std::string& skillId,
                          int generation) {
    const auto* def = findSkill(tuning, skillId);
    if (!def || generation <= 0) return 1.0;
    double fraction = skillNumber(*def, "fork_damage_fraction", 1.0);
    return std::pow(fraction, generation);
}

double chillApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                    const std::string& skillId, bool isBoss) {
    return statusApplied(tuning, active, skillId, "chill_buildup", "chill_buildup",
                         tuning.grammar.chill.bossBuildupMultiplier, isBoss);
}

double igniteApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                     const std::string& skillId, bool isBoss) {
    return statusApplied(tuning, active, skillId, "ignite_buildup", "ignite_buildup",
                         tuning.grammar.ignite.bossBuildupMultiplier, isBoss);
}

double bleedApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                    const std::string& skillId, bool isBoss) {
    return statusApplied(tuning, active, skillId, "bleed_buildup", "bleed_buildup",
                         tuning.grammar.bleed.bossBuildupMultiplier, isBoss);
}

DotStatus igniteStatus(const tuning::Tuning& tuning, const ActiveMods& active) {
    const auto& cfg = tuning.grammar.ignite;
    DotStatus status;
    status.buildupMax = cfg.buildupMax;
    status.decayPerS = cfg.decayPerS;
    status.durationS = resolve(active, {"fire", "ignite"}, "ignite_duration", cfg.durationS);
    status.damagePerS = resolve(active, {"fire", "ignite"}, "burn_damage", cfg.damagePerS);
    return status;
}

DotStatus bleedStatus(const tuning::Tuning& tuning, const ActiveMods& active) {
    const auto& cfg = tuning.grammar.bleed;
    DotStatus status;
    status.buildupMax = cfg.buildupMax;
    status.decayPerS = cfg.decayPerS;
    status.durationS = resolve(active, {"physical", "bleed"}, "bleed_duration", cfg.durationS);
    status.damagePerS = resolve(active, {"physical", "bleed"}, "bleed_damage", cfg.damagePerS);
    status.movingMultiplier = cfg.movingMultiplier;
    return status;
}

double skillDamage(const tuning::Tuning& tuning, const ActiveMods& active,
                   const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    return resolve(active, def->resolveTags(), "damage", skillNumber(*def, "base_damage", 0.0));
}

double skillCooldownSeconds(const tuning::Tuning& tuning, const ActiveMods& active,
                            const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    double base = skillNumber(*def, "cooldown_seconds", 0.0);
    double recovery = resolve(active, def->resolveTags(), "cooldown_recovery", 1.0);
    return recovery > 0.0 ? base / recovery : base;
}

ShatterParams shatterFor(const tuning::Tuning& tuning, const ActiveMods& active,
                         const std::string& skillId) {
    ShatterParams params;
    const auto& hook = tuning.grammar.shatter;
    const auto* def = findSkill(tuning, skillId);
    if (!def || !modAppliesToTags(hook.triggerTags, def->resolveTags()) || hook.triggerTags.empty())
        return params;
    params.enabled = true;
    params.novaDamage = hook.novaDamage;
    params.novaDamageType = hook.novaDamageType;
    params.executesFrozen = hook.executesFrozen;
    params.executesBoss = hook.executesBoss;
    // Shatter mods target the "shatter" tag by convention.
    params.novaRadiusM = resolve(active, {"shatter", "cold"}, "shatter_radius", hook.novaRadiusM);
    return params;
}

ProliferateParams proliferateFor(const tuning::Tuning& tuning, const ActiveMods& active) {
    ProliferateParams params;
    const auto& hook = tuning.grammar.proliferate;
    params.enabled = hook.enabled;
    // Proliferate mods target the "proliferate" tag by convention.
    params.radiusM = resolve(active, {"proliferate", "fire"}, "proliferate_radius", hook.radiusM);
    params.spreadBuildup = resolve(active, {"proliferate", "fire", "ignite"}, "proliferate_buildup",
                                   hook.spreadBuildup);
    return params;
}

} // namespace wroughtwild::grammar
