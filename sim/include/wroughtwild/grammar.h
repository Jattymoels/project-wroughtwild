#pragma once

// The skill-grammar resolver (docs/systems/skill-grammar.md, spike stage).
// Pure functions: given the tuning tables, the set of active mod ids and a
// skill, they produce the final numbers - fork counts, chill buildup,
// shatter parameters - using the increased-vs-more rule from day one:
// add_* is flat, increased_* sums additively within its bucket, more_*
// multiplies. The engine owns where orbs fly and which mob a fork jumps
// to; every number here is the sim's (ADR-0003).

#include <set>
#include <string>
#include <vector>

#include "wroughtwild/tuning.h"

namespace wroughtwild::grammar {

using ActiveMods = std::set<std::string>;

// True when the mod applies to something carrying these tags (an empty
// applies_to_tags list applies to everything).
bool modAppliesToTags(const tuning::SkillModDef& mod, const std::vector<std::string>& tags);

// Core resolver: base * (1 + sum of increased_<key>) * product(1 + more_<key>)
// + sum of add_<key>, over active mods whose tags match.
double resolve(const tuning::GrammarTable& grammar,
               const ActiveMods& active,
               const std::vector<std::string>& tags,
               const std::string& key,
               double base);

// --- resolved views for one skill --------------------------------------------

// Forks the skill's projectile splits into on impact (0 for non-forking).
int forkCount(const tuning::Tuning& tuning, const ActiveMods& active,
              const std::string& skillId);

// Damage fraction retained by fork generation g (generation 0 = the cast).
double forkDamageFraction(const tuning::Tuning& tuning, const std::string& skillId,
                          int generation);

// Chill buildup one hit of the skill applies (0 for non-chilling skills);
// isBoss applies the day-one boss status resistance.
double chillApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                    const std::string& skillId, bool isBoss);

struct ShatterParams {
    bool enabled = false; // the given skill carries the shatter hook
    double novaDamage = 0.0;
    std::string novaDamageType;
    double novaRadiusM = 0.0;
    bool executesFrozen = true;
};

// Shatter parameters when triggered by skillId (enabled=false when the
// skill does not carry the hook). Radius honours shatter-tagged mods.
ShatterParams shatterFor(const tuning::Tuning& tuning, const ActiveMods& active,
                         const std::string& skillId);

} // namespace wroughtwild::grammar
