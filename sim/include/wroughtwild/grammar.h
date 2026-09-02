#pragma once

// The skill-grammar resolver (docs/systems/skill-grammar.md). Pure
// functions: given the tuning tables, the set of active modifiers (with
// magnitudes) and a skill, they produce the final numbers - fork counts,
// status buildup, status damage and durations, hook parameters, damage,
// cooldowns - using the increased-vs-more rule from day one: add_* is flat,
// increased_* sums additively within its bucket, more_* multiplies. The
// engine owns where projectiles fly, which mob a fork jumps to and when a
// DoT ticks; every number here is the sim's (ADR-0003). Since D-014 the
// modifiers come from worn gear (items.json modifiers); the F1-F3 debug
// toggles add one at a fixed value.

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
// Which skills the player has and which sit on the bar is the loadout's
// business (economy.h, D-016); the grammar only resolves numbers for one.

// Forks the skill's projectile splits into on impact (0 for non-forking).
int forkCount(const tuning::Tuning& tuning, const ActiveMods& active,
              const std::string& skillId);

// Damage fraction retained by fork generation g (generation 0 = the cast).
double forkDamageFraction(const tuning::Tuning& tuning, const std::string& skillId,
                          int generation);

// Status buildup one hit of the skill applies. A skill without that payload
// contributes 0 of its own, but a flat add_<status>_buildup modifier whose
// tags match still gives it one (a Frostbite mace chills with plain strikes);
// isBoss applies the day-one boss status resistance.
double chillApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                    const std::string& skillId, bool isBoss);
double igniteApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                     const std::string& skillId, bool isBoss);
double bleedApplied(const tuning::Tuning& tuning, const ActiveMods& active,
                    const std::string& skillId, bool isBoss);

// A damage-over-time status once its buildup threshold is crossed. The
// engine ticks damagePerS each second while the status lasts; bleed
// multiplies its tick by movingMultiplier while the mob is walking.
struct DotStatus {
    double buildupMax = 100.0;
    double decayPerS = 0.0;
    double durationS = 0.0;
    double damagePerS = 0.0;
    double movingMultiplier = 1.0;
};
DotStatus igniteStatus(const tuning::Tuning& tuning, const ActiveMods& active);
DotStatus bleedStatus(const tuning::Tuning& tuning, const ActiveMods& active);

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
    bool executesBoss = false; // frozen bosses take the nova but survive the execute
};

// Shatter parameters when triggered by skillId: enabled when the skill
// carries any of the hook's trigger tags (attacks, by the day-one rule).
// Radius honours shatter-tagged mods.
ShatterParams shatterFor(const tuning::Tuning& tuning, const ActiveMods& active,
                         const std::string& skillId);

// Proliferate: a burning mob's death gives spreadBuildup of ignite to every
// mob within radiusM. Radius honours proliferate-tagged mods.
struct ProliferateParams {
    bool enabled = false;
    double radiusM = 0.0;
    double spreadBuildup = 0.0;
};
ProliferateParams proliferateFor(const tuning::Tuning& tuning, const ActiveMods& active);

} // namespace wroughtwild::grammar
