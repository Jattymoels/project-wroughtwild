#include "wroughtwild/stats.h"

#include <algorithm>

namespace wroughtwild::stats {

namespace {

DerivedStats finish(const tuning::PlayerBase& base, DerivedStats stats) {
    stats.fireResistancePercent =
        std::min(stats.fireResistancePercent, base.resistanceCapPercent);
    stats.coldResistancePercent =
        std::min(stats.coldResistancePercent, base.resistanceCapPercent);
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

DerivedStats deriveStats(const tuning::PlayerBase& base, const Equipment& equipment,
                         const tuning::ItemTable& table, const std::vector<ExtraEffect>& extra) {
    DerivedStats stats;
    stats.maxLife = base.maxLife;
    for (const auto& [slot, item] : equipment.slots) {
        const items::StatTotals totals = items::statTotals(table, item);
        stats.maxLife += totals.maxLife;
        stats.armour += totals.armour;
        stats.fireResistancePercent += totals.fireResistance;
        stats.areaBonus += totals.areaSize;
    }
    for (const auto& e : extra) {
        if (e.key == "add_max_life") stats.maxLife += e.value;
        else if (e.key == "add_armour") stats.armour += e.value;
        else if (e.key == "add_fire_resistance") stats.fireResistancePercent += e.value;
        else if (e.key == "add_cold_resistance") stats.coldResistancePercent += e.value;
        else if (e.key == "add_all_resistance") {
            stats.fireResistancePercent += e.value;
            stats.coldResistancePercent += e.value;
        } else if (e.key == "add_area_size") stats.areaBonus += e.value;
        else if (e.key == "add_barbs") stats.barbsBuildup += e.value;
        else if (e.key == "add_answer_reach") stats.answerReachM += e.value;
        else if (e.key == "add_haste_after_hit") stats.hasteAfterHit += e.value;
        else if (e.key == "add_heal_more") stats.healMore += e.value;
        else if (e.key == "add_dash_reach") stats.dashReachM += e.value;
        else if (e.key == "add_life_on_dash") stats.lifeOnDash += e.value;
        else if (e.key == "add_armour_on_dash") stats.armourOnDash += e.value;
        else if (e.key == "add_dash_recovery") stats.dashRecovery += e.value;
        else if (e.key == "add_armour_vs_elements") stats.armourVsElements += e.value;
        else if (e.key == "add_barbs_more") stats.barbsMore += e.value;
        else if (e.key == "add_barbs_stagger") stats.barbsStagger += e.value;
        else if (e.key == "add_proliferate_on_hit") stats.proliferateOnHit += e.value;
        else if (e.key == "add_burning_ground_heal") stats.burningGroundHeal += e.value;
        else if (e.key == "add_damage_vs_approaching") stats.damageVsApproaching += e.value;
        else if (e.key == "add_still_armour") stats.stillArmour += e.value;
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
    if (damageType == "fire" || damageType == "cold") {
        const double resistance = damageType == "fire" ? stats.fireResistancePercent : stats.coldResistancePercent;
        double after = amount * (1.0 - resistance / 100.0);
        // The Shield Wall rail (D-023 slice 9): a fraction of the armour
        // counts against the elements too, after the resistance.
        const double counted = stats.armour * std::min(1.0, std::max(0.0, stats.armourVsElements));
        if (counted > 0.0) after *= 1.0 - std::min(base.armourReductionCap, counted / (counted + base.armourReductionScale));
        return after;
    }
    // Everything else counts as physical for the slice.
    // The era's ceiling (Wave 7 slice 2): until the deep wakes, armour
    // takes away no more than the era allows, however much you wear.
    double reduction = std::min(base.armourReductionCap, stats.armour / (stats.armour + base.armourReductionScale));
    return amount * (1.0 - reduction);
}

} // namespace wroughtwild::stats
