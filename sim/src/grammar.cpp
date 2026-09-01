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

bool modAppliesToTags(const tuning::SkillModDef& mod, const std::vector<std::string>& tags) {
    if (mod.appliesToTags.empty()) return true;
    for (const auto& wanted : mod.appliesToTags)
        if (std::find(tags.begin(), tags.end(), wanted) != tags.end()) return true;
    return false;
}

double resolve(const tuning::GrammarTable& grammar,
               const ActiveMods& active,
               const std::vector<std::string>& tags,
               const std::string& key,
               double base) {
    double flat = 0.0;
    double increased = 0.0;
    double more = 1.0;
    for (const auto& mod : grammar.skillMods) {
        if (!active.count(mod.id) || !modAppliesToTags(mod, tags)) continue;
        auto add = mod.effect.find("add_" + key);
        if (add != mod.effect.end()) flat += add->second;
        auto inc = mod.effect.find("increased_" + key);
        if (inc != mod.effect.end()) increased += inc->second;
        auto mre = mod.effect.find("more_" + key);
        if (mre != mod.effect.end()) more *= (1.0 + mre->second);
    }
    return (base + flat) * (1.0 + increased) * more;
}

int forkCount(const tuning::Tuning& tuning, const ActiveMods& active,
              const std::string& skillId) {
    const auto* def = findSkill(tuning, skillId);
    if (!def) return 0;
    double base = skillNumber(*def, "fork_count", 0.0);
    return static_cast<int>(std::floor(
        resolve(tuning.grammar, active, def->tags, "fork", base)));
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
    double applied = resolve(tuning.grammar, active, def->tags, "chill_buildup", base);
    if (isBoss) applied *= tuning.grammar.chill.bossBuildupMultiplier;
    return applied;
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
    params.novaRadiusM =
        resolve(tuning.grammar, active, {"shatter", "cold"}, "shatter_radius", hook.novaRadiusM);
    return params;
}

} // namespace wroughtwild::grammar
