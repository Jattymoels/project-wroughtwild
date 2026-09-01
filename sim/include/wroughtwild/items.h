#pragma once

// Items: a base plus implicit properties plus rolled modifiers (D-014, one
// modifier pool for character stats and skill mods alike). Rolling is
// deterministic per seed. Catalyst tempering (ADR-0002 proposal C) guarantees
// a modifier's domain while its magnitude stays a bounded roll.

#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "wroughtwild/tuning.h"

namespace wroughtwild::items {

// One rolled (or catalyst-added) modifier on an item: propertyId names a
// tuning::ModifierDef; value is its magnitude in that modifier's own unit.
struct RolledProperty {
    std::string propertyId;
    int tier = 0;
    double value = 0.0;
};

struct ItemInstance {
    std::string baseId;
    std::string rarity = "plain"; // tuning::RarityDef id
    std::map<std::string, double> implicitProperties;
    std::vector<RolledProperty> rolledProperties;
};

// Modifiers whose tags intersect the base's allowed tags: the base's roll pool.
std::vector<const tuning::ModifierDef*> eligibleModifiers(const tuning::ItemTable& table,
                                                          const tuning::ItemBase& base);

// Creates an item of the given base and rolls up to propertyCount distinct
// modifiers at the given tier (or the nearest tier the modifier defines),
// uniformly within the tier's range. The same seed always produces the same
// item. Throws when the base is unknown.
ItemInstance rollItem(const tuning::ItemTable& table,
                      const std::string& baseId,
                      int tier,
                      int propertyCount,
                      uint64_t seed);

// rollItem with the modifier count drawn from the rarity's range; the item
// records its rarity. Throws when the base or rarity is unknown.
ItemInstance rollRarityItem(const tuning::ItemTable& table,
                            const std::string& baseId,
                            const std::string& rarityId,
                            int tier,
                            uint64_t seed);

// Total of implicit and rolled values for one property/modifier id (0 when absent).
double propertyTotal(const ItemInstance& item, const std::string& propertyId);

// The character stats one item contributes: its implicit numeric properties
// plus every implicit or rolled modifier whose effect key is a stat
// (add_max_life, add_armour, add_fire_resistance, add_area_size).
struct StatTotals {
    double maxLife = 0.0;
    double armour = 0.0;
    double fireResistance = 0.0;
    double areaSize = 0.0;
};
StatTotals statTotals(const tuning::ItemTable& table, const ItemInstance& item);

// "+12 Maximum Life", "50% increased Chill Buildup for chill skills".
std::string modifierSentence(const tuning::ModifierDef& def, double value);
std::string formatNumber(double value);

// PROVISIONAL — Proposal C of ADR-0002 (D-007 remains open).
// Catalyst tempering: the catalyst guarantees the DOMAIN (the named modifier
// lands, at the configured tier) while the MAGNITUDE stays a bounded roll.
// Craft skill raises the roll floor (minimum_roll_fraction_at_skill), and an
// existing equal-or-better roll is never downgraded (preservation rule).
struct TemperResult {
    bool applied = false;
    bool skillTooLow = false;
    bool wrongTier = false; // modifier has no such tier defined
    double rolledValue = 0.0;
    double previousValue = 0.0;
};

TemperResult catalystTemper(const tuning::ItemTable& table,
                            const tuning::CatalystProcess& process,
                            ItemInstance& item,
                            int craftSkillLevel,
                            uint64_t seed);

// Basic (non-catalyst) tempering: adds the modifier at exactly the tier
// range's midpoint — the "upgraded forge produces baseline fire resistance
// deterministically" acceptance criterion. Never downgrades an existing roll.
bool basicTemper(const tuning::ItemTable& table,
                 ItemInstance& item,
                 const std::string& propertyId,
                 int tier);

} // namespace wroughtwild::items
