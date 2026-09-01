#pragma once

// The skill-grammar resolver (docs/systems/skill-grammar.md). Pure
// functions: given the tuning tables, the set of active modifiers (with
// magnitudes) and a skill, they produce the final numbers - fork counts,
// chill buildup, shatter parameters, damage, cooldowns - using the
// increased-vs-more rule from day one: add_* is flat, increased_* sums
// additively within its bucket, more_* multiplies. The engine owns where
// orbs fly and which mob a fork jumps to; every number here is the sim's
// (ADR-0003). Since D-014 the modifiers come from worn gear
// (items.json modifiers); the F1-F3 debug toggles add one at a fixed value.

#include <string>
#include <vector>

#include "wroughtwild/stats.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::grammar {

// One modifier in force, with its magnitude and where it came from.
struct ActiveMod {
    std::string id;
    std::vector<std::string> appliesToTags; // empty = applies to everything
    std::string effectKey;                  // add_<key> | increased_<key> | more_<key>
    double value = 0.0;
    std::string source;                     // slot id, "debug", "test"...
};
using ActiveMods = std::vector<ActiveMod>;

// True when a modifier with these applies_to tags targets something
// carrying `tags` (an empty applies_to list applies to everything).
bool modAppliesToTags(const std::vector<std::string>& appliesToTags,
                      const std::vector<std::string>& tags);

// Core resolver: (base + sum of add_<key>) * (1 + sum of increased_<key>)
// * product(1 + more_<key>), over active mods whose tags match.
double resolve(const ActiveMods& active,
               const std::vector<std::string>& tags,
               const std::string& key,
               double base);

// Every modifier the worn gear supplies: each base's implicit modifiers and
// each item's rolled modifiers, tagged with their slot as the source.
ActiveMods gearMods(const tuning::ItemTable& table, const stats::Equipment& equipment);

// One modifier at a given magnitude (debug toggles, tests).
ActiveMod modAt(const tuning::ItemTable& table, const std::string& modifierId, double value,
                const std::string& source);

// The magnitude a debug toggle uses: the modifier's tier-1 maximum.
double defaultValue(const tuning::ModifierDef& def);

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

// The skill's base_damage after damage modifiers matching its tags.
double skillDamage(const tuning::Tuning& tuning, const ActiveMods& active,
                   const std::string& skillId);

// The skill's cooldown after cooldown-recovery modifiers (recovery speeds
// the timer: cooldown = base / resolved recovery factor).
double skillCooldownSeconds(const tuning::Tuning& tuning, const ActiveMods& active,
                            const std::string& skillId);

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
