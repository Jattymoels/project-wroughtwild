#pragma once

// Derives the player's combat numbers from base stats plus equipped items.
// In plain terms: "given what you are wearing, how tough and strong are you?"

#include <map>
#include <string>

#include "wroughtwild/items.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::stats {

// Equipped items by slot ("chest" is the only slice slot).
struct Equipment {
    std::map<std::string, items::ItemInstance> slots;
};

struct DerivedStats {
    double maxLife = 0.0;
    double armour = 0.0;
    double fireResistancePercent = 0.0; // already capped
    double areaBonus = 0.0;             // fractional area size increase
};

DerivedStats deriveStats(const tuning::PlayerBase& base, const Equipment& equipment);

// Damage after defences. Physical is reduced by armour
// (reduction = armour / (armour + scale)); fire by resistance percent.
double mitigateDamage(double amount, const std::string& damageType,
                      const DerivedStats& stats, const tuning::PlayerBase& base);

} // namespace wroughtwild::stats
