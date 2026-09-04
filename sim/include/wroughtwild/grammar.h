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

#include "wroughtwild/foundry.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::grammar {

// One modifier in force, with its magnitude and where it came from.
struct ActiveMod {
    std::string id;
    std::vector<std::string> appliesToTags; // empty = applies to everything; else any one must match
    std::string effectKey;                  // add_<key> | increased_<key> | more_<key>
    double value = 0.0;
    std::string source;                     // slot id, "debug", "test"...
    // Every one of these must also be present (D-023 slice 2): a support
    // keeps its modifier's own applies_to (cold) and requires its skill's
    // tag, so a Frost support scales the orb's cold packet and never the
    // fire packet an Ember support adds to the same orb.
    std::vector<std::string> requiresTags;

    ActiveMod() = default;
    ActiveMod(std::string inId, std::vector<std::string> inAppliesTo, std::string inEffectKey, double inValue,
              std::string inSource, std::vector<std::string> inRequires = {})
        : id(std::move(inId)), appliesToTags(std::move(inAppliesTo)), effectKey(std::move(inEffectKey)),
          value(inValue), source(std::move(inSource)), requiresTags(std::move(inRequires)) {}
};
using ActiveMods = std::vector<ActiveMod>;

// True when a modifier with these applies_to tags targets something
// carrying `tags` (an empty applies_to list applies to everything).
bool modAppliesToTags(const std::vector<std::string>& appliesToTags,
                      const std::vector<std::string>& tags);

// True when the modifier speaks to something carrying `tags`: its
// applies_to matches and every one of its requiresTags is present.
bool modApplies(const ActiveMod& mod, const std::vector<std::string>& tags);

// A skill's own damage type: the first grammar.json damage type among its
// tags (the first of all when it names none).
std::string nativeType(const tuning::Tuning& tuning, const std::vector<std::string>& skillTags);

// Core resolver: (base + sum of add_<key>) * (1 + sum of increased_<key>)
// * product(1 + more_<key>), over active mods whose tags match.
double resolve(const ActiveMods& active,
               const std::vector<std::string>& tags,
               const std::string& key,
               double base);

// Every modifier the worn gear supplies: each base's implicit modifiers and
// each item's rolled modifiers, tagged with their slot as the source.
ActiveMods gearMods(const tuning::ItemTable& table, const stats::Equipment& equipment);

// Every modifier the Foundry's plate supplies in `era`: each placed ingot's
// verb, each matching adjacent pair's mechanic, and each working's
// readings - supports, added elements and backing - which keep their
// modifier's applies_to and require the socket's skill tag (sources
// "foundry:ingot" / "foundry:pair" / "foundry:support" / "foundry:added" /
// "foundry:backing").
ActiveMods foundryMods(const tuning::Tuning& tuning, const foundry::State& state, int era);

// Every mastery perk the player's skill uses have unlocked, each targeting
// its own skill's "skill:<id>" tag (sources "mastery:<skill>").
ActiveMods masteryMods(const tuning::Tuning& tuning, const std::map<std::string, int>& skillUses);

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

// One typed part of a hit (D-023 slice 2). A skill's hit is a list of
// these: its own element first, then one packet per element the plate
// adds to it (an Ember ingot beside Frost Orb makes a cold-and-fire bolt).
// Each packet is scaled by its own type's modifiers, and the engine applies
// a mob's immunities packet by packet.
struct HitPacket {
    std::string type;    // a grammar.json damage type: physical, fire, cold
    double damage = 0.0;
    bool added = false;  // true for an element the plate added to the hit
};
using Hit = std::vector<HitPacket>;

// The skill's hit as typed packets. The native packet is base_damage after
// damage modifiers matching the skill's tags. An added packet of type T is
// base_damage times the resolved "as_T" fraction (add_as_T modifiers, the
// added-element reading), then damage modifiers matching the skill's tags
// with its element swapped for T. Empty for a skill with no base_damage.
// targetStatuses (of chill, ignite, bleed): what the struck mob carries;
// every packet is multiplied by the resolved "damage_vs_<status>" for each
// (more_damage_vs_ignite: a form's "an ignited enemy takes 20% more").
Hit skillHit(const tuning::Tuning& tuning, const ActiveMods& active,
             const std::string& skillId);
Hit skillHit(const tuning::Tuning& tuning, const ActiveMods& active,
             const std::string& skillId, const std::vector<std::string>& targetStatuses);

// The whole hit as one number: the packets summed.
double skillDamage(const tuning::Tuning& tuning, const ActiveMods& active,
                   const std::string& skillId);

// --- the self ingots' readings beside a skill (D-023 slice 2) ---------------
// Life a kill with the skill restores (add_life_on_kill; the Vigour reading).
double skillLifeOnKill(const tuning::Tuning& tuning, const ActiveMods& active,
                       const std::string& skillId);

// Armour a cast of the skill grants for tuning.foundry.castArmourSeconds
// (add_armour_on_cast; the Plate reading). The engine runs the clock.
double skillCastArmour(const tuning::Tuning& tuning, const ActiveMods& active,
                       const std::string& skillId);

// What an enemy's hit on the player is multiplied by, given the statuses
// the enemy carries (of chill, ignite, bleed): every skill with a
// status_ward reading that applies one of those statuses takes its ward
// off the hit, multiplicatively (the Ward reading). 1.0 when nothing speaks.
double wardMultiplier(const tuning::Tuning& tuning, const ActiveMods& active,
                      const std::vector<std::string>& carriedStatuses);

// --- the reactions' hooks (D-023, the flow): numbers the engine applies ---
// Every nth cast of the skill repeats itself (0: never). The Echo form.
int skillEchoEvery(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);
// A burning enemy the skill freezes takes the rest of its burn at once. Quench.
bool skillQuenches(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);
// Chill the skill's shatter novas apply to the mobs they reach. Rime.
double skillNovaChill(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);
// How much faster a burn the skill lights ticks while the mob moves and bleeds. Sear.
double skillSear(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);
// A frozen, bleeding enemy shatters from the skill's own hit. Brittle.
bool skillBrittle(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);
// How far either side of a strike's line its sweep reaches, in metres (0:
// a single target). The Arc form.
double skillArc(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);
// The Marrow's and the Quicksilver's skill hooks (D-023 slice 8): life a
// hit restores; the fraction of the cooldown a kill refunds; how much a
// kill quickens you for a moment.
double skillLifeOnHit(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);
double skillRefundOnKill(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);
double skillHasteOnKill(const tuning::Tuning& tuning, const ActiveMods& active, const std::string& skillId);

// --- links (D-023) -----------------------------------------------------------
// The triggers a skill's payload can fire on an enemy: "freeze" when it
// applies chill, "ignite" when it applies ignite, "bleed" when it applies
// bleed - its own payload or a modifier's.
std::vector<std::string> skillTriggers(const tuning::Tuning& tuning, const ActiveMods& active,
                                       const std::string& skillId);
// The skills that cast themselves when skillId's `trigger` fires: every
// skill linked to it on the plate, when the trigger is one of skillId's.
std::vector<std::string> linkedCasts(const tuning::Tuning& tuning, const ActiveMods& active,
                                     const foundry::State& state, const foundry::Plate& plate,
                                     const std::string& skillId, const std::string& trigger);

// The skill's cooldown after cooldown-recovery modifiers (recovery speeds
// the timer: cooldown = base / resolved recovery factor).
double skillCooldownSeconds(const tuning::Tuning& tuning, const ActiveMods& active,
                            const std::string& skillId);

// The skill's spatial extent as a multiplier after reach modifiers matching
// its tags (D-023): an area's radius, a projectile's flight, a strike's
// reach. The engine applies it to the delivery it owns. 1.0 when nothing
// speaks.
double skillReach(const tuning::Tuning& tuning, const ActiveMods& active,
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
