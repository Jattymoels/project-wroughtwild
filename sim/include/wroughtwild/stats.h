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
    double coldResistancePercent = 0.0; // already capped (D-023 slice 4)
    double areaBonus = 0.0;             // fractional area size increase
    // The Vanguard's answers to a hit (D-023 slice 4), numbers the engine
    // applies when a hit lands: bleed buildup on the striker, how far the
    // answer reaches beyond the striker, a burst of speed after a hit.
    double barbsBuildup = 0.0;
    double answerReachM = 0.0;
    double hasteAfterHit = 0.0; // fractional speed increase
    // The Marrow's and the Quicksilver's sheet numbers (D-023 slice 8):
    // every heal amplified; the Dash's extra reach, its life, its armour,
    // its faster recovery.
    double healMore = 0.0;
    double dashReachM = 0.0;
    double lifeOnDash = 0.0;
    double armourOnDash = 0.0;
    double dashRecovery = 0.0;
    // The rails' sheet numbers (D-023 slice 9): the fraction of armour
    // that counts against fire and cold (Shield Wall); the Barbs' extra
    // buildup and the striker's stagger (Riposte); the fraction of the
    // proliferate spread an ignite gives on the hit (Pyre); life a second
    // from burning ground (Ashen Step); more against an enemy moving
    // toward you (the Hound's Manner); armour after a second of stillness
    // (the Husk's Manner).
    double armourVsElements = 0.0;
    double barbsMore = 0.0;
    double barbsStagger = 0.0;
    double proliferateOnHit = 0.0;
    double burningGroundHeal = 0.0;
    double damageVsApproaching = 0.0;
    double stillArmour = 0.0;
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
// (reduction = armour / (armour + scale)); fire and cold by their
// resistance percents, then by the fraction of armour that counts against
// them (the Shield Wall rail), when any does.
double mitigateDamage(double amount, const std::string& damageType,
                      const DerivedStats& stats, const tuning::PlayerBase& base);

} // namespace wroughtwild::stats
