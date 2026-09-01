#include "wroughtwild/stats.h"

#include <algorithm>

namespace wroughtwild::stats {

namespace {

DerivedStats finish(const tuning::PlayerBase& base, DerivedStats stats) {
    stats.fireResistancePercent =
        std::min(stats.fireResistancePercent, base.resistanceCapPercent);
    return stats;
}

} // namespace

DerivedStats deriveStats(const tuning::PlayerBase& base, const Equipment& equipment,
                         const tuning::ItemTable& table) {
    DerivedStats stats;
    stats.maxLife = base.maxLife;
    for (const auto& [slot, item] : equipment.slots) {
        const items::StatTotals totals = items::statTotals(table, item);
        stats.maxLife += totals.maxLife;
        stats.armour += totals.armour;
        stats.fireResistancePercent += totals.fireResistance;
        stats.areaBonus += totals.areaSize;
    }
    return finish(base, stats);
}

DerivedStats deriveStats(const tuning::PlayerBase& base, const Equipment& equipment) {
    DerivedStats stats;
    stats.maxLife = base.maxLife;
    for (const auto& [slot, item] : equipment.slots) {
        stats.maxLife += items::propertyTotal(item, "max_life");
        stats.armour += items::propertyTotal(item, "armour");
        stats.fireResistancePercent += items::propertyTotal(item, "fire_resistance");
        stats.areaBonus += items::propertyTotal(item, "area_size");
    }
    return finish(base, stats);
}

double mitigateDamage(double amount, const std::string& damageType,
                      const DerivedStats& stats, const tuning::PlayerBase& base) {
    if (damageType == "fire")
        return amount * (1.0 - stats.fireResistancePercent / 100.0);
    // Everything else counts as physical for the slice.
    double reduction = stats.armour / (stats.armour + base.armourReductionScale);
    return amount * (1.0 - reduction);
}

} // namespace wroughtwild::stats
