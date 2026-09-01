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
            if (def) mods.push_back({def->id, def->appliesToTags, def->effectKey, rolled.value, slot});
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

int forkCount(const tuning::Tuning& tuning, const ActiveMods& active,
              const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0;
    double base = skillNumber(*def, "fork_count", 0.0);
    return static_cast<int>(std::floor(resolve(active, def->tags, "fork", base)));
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
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    double base = skillNumber(*def, "chill_buildup", 0.0);
    if (base <= 0.0) return 0.0;
    double applied = resolve(active, def->tags, "chill_buildup", base);
    if (isBoss) applied *= tuning.grammar.chill.bossBuildupMultiplier;
    return applied;
}

double skillDamage(const tuning::Tuning& tuning, const ActiveMods& active,
                   const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    return resolve(active, def->tags, "damage", skillNumber(*def, "base_damage", 0.0));
}

double skillCooldownSeconds(const tuning::Tuning& tuning, const ActiveMods& active,
                            const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0.0;
    double base = skillNumber(*def, "cooldown_seconds", 0.0);
    double recovery = resolve(active, def->tags, "cooldown_recovery", 1.0);
    return recovery > 0.0 ? base / recovery : base;
}

ShatterParams shatterFor(const tuning::Tuning& tuning, const ActiveMods& active,
                         const std::string& skillId) {
    ShatterParams params;
    const auto& hook = tuning.grammar.shatter;
    if (std::find(hook.triggerSkills.begin(), hook.triggerSkills.end(), skillId) ==
        hook.triggerSkills.end()) {
        return params;
    }
    params.enabled = true;
    params.novaDamage = hook.novaDamage;
    params.novaDamageType = hook.novaDamageType;
    params.executesFrozen = hook.executesFrozen;
    // Shatter mods target the "shatter" tag by convention.
    params.novaRadiusM = resolve(active, {"shatter", "cold"}, "shatter_radius", hook.novaRadiusM);
    return params;
}

} // namespace wroughtwild::grammar
