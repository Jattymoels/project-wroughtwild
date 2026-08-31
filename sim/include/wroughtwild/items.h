#pragma once

// Deterministic equipment property generation from items.json.
// Catalyst-influenced operations are intentionally absent: D-007 (crafting
// economy and catalysts) is a high-priority open decision.

#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "wroughtwild/tuning.h"

namespace wroughtwild::items {

struct RolledProperty {
    std::string propertyId;
    int tier = 0;
    double value = 0.0;
};

struct ItemInstance {
    std::string baseId;
    std::map<std::string, double> implicitProperties;
    std::vector<RolledProperty> rolledProperties;
};

// Property definitions whose tags intersect the base's allowed tags.
std::vector<const tuning::PropertyDef*> eligibleProperties(const tuning::ItemTable& table,
                                                           const tuning::ItemBase& base);

// Creates an item of the given base and rolls up to propertyCount distinct
// properties at the given tier, uniformly within the tier's range. The same
// seed always produces the same item. Throws when the base or tier is unknown.
ItemInstance rollItem(const tuning::ItemTable& table,
                      const std::string& baseId,
                      int tier,
                      int propertyCount,
                      uint64_t seed);

// Total of implicit and rolled values for one property id (0 when absent).
double propertyTotal(const ItemInstance& item, const std::string& propertyId);

// PROVISIONAL — Proposal C of ADR-0002 (D-007 remains open).
// Catalyst tempering: the catalyst guarantees the DOMAIN (the named property
// lands, at the configured tier) while the MAGNITUDE stays a bounded roll.
// Craft skill raises the roll floor (minimum_roll_fraction_at_skill), and an
// existing equal-or-better roll is never downgraded (preservation rule).
struct TemperResult {
    bool applied = false;
    bool skillTooLow = false;
    bool wrongTier = false; // property has no such tier defined
    double rolledValue = 0.0;
    double previousValue = 0.0;
};

TemperResult catalystTemper(const tuning::ItemTable& table,
                            const tuning::CatalystProcess& process,
                            ItemInstance& item,
                            int craftSkillLevel,
                            uint64_t seed);

// Basic (non-catalyst) tempering: adds the property at exactly the tier
// range's midpoint — the "upgraded forge produces baseline fire resistance
// deterministically" acceptance criterion. Never downgrades an existing roll.
bool basicTemper(const tuning::ItemTable& table,
                 ItemInstance& item,
                 const std::string& propertyId,
                 int tier);

} // namespace wroughtwild::items
