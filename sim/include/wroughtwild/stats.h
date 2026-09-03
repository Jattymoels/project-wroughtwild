#pragma once

// Derives the player's combat numbers from base stats plus equipped items.
// In plain terms: "given what you are wearing, how tough and strong are you?"

#include <map>
#include <string>
#include <vector>

#include "wroughtwild/items.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::stats {

// Equipped items by slot ("weapon", "chest", "charm" since D-014).
struct Equipment {
    std::map<std::string, items::ItemInstance> slots;
};

struct DerivedStats {
    double maxLife = 0.0;
    double armour = 0.0;
    double fireResistancePercent = 0.0; // already capped
    double areaBonus = 0.0;             // fractional area size increase
};

// Stats from the item table's modifier pool: implicit properties plus every
// implicit or rolled modifier whose effect is a character stat (D-014).
DerivedStats deriveStats(const tuning::PlayerBase& base, const Equipment& equipment,
                         const tuning::ItemTable& table);

// A character-stat effect from outside the gear: the Foundry's ingots
// (add_max_life, add_armour, add_fire_resistance, add_area_size).
struct ExtraEffect {
    std::string key;
    double value = 0.0;
};
DerivedStats deriveStats(const tuning::PlayerBase& base, const Equipment& equipment,
                         const tuning::ItemTable& table, const std::vector<ExtraEffect>& extra);

// Legacy view without the table: implicit properties plus rolled entries
// whose id names a stat directly (max_life, armour, fire_resistance,
// area_size). Kept for the balance and playtest tools, which build items by
// hand from those ids.
DerivedStats deriveStats(const tuning::PlayerBase& base, const Equipment& equipment);

// Damage after defences. Physical is reduced by armour
// (reduction = armour / (armour + scale)); fire by resistance percent.
double mitigateDamage(double amount, const std::string& damageType,
                      const DerivedStats& stats, const tuning::PlayerBase& base);

} // namespace wroughtwild::stats
