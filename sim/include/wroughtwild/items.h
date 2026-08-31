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

} // namespace wroughtwild::items
