#pragma once

// Round-based combat resolution. In plain terms: a battle calculator — each
// round the player picks one skill, every living enemy attacks on its own
// rhythm, and armour/fire resistance decide how much gets through. The engine
// version will be real-time, but these damage rules are the shared truth.

#include <cstdint>
#include <functional>
#include <string>
#include <vector>

#include "wroughtwild/boons.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::combat {

// Boon/weakness effects translated into concrete combat numbers.
struct CombatMods {
    double enemySpeedMultiplier = 1.0;
    double rewardQuantityMultiplier = 1.0;
    int repeatHitCount = 0; // 0 = expanding_echo off
    double repeatDamageMultiplier = 0.0;
    double isolatedDamageMultiplier = 1.0; // concentrated_force vs a lone enemy
};

// Interprets the effect operations of every active boon and weakness.
CombatMods buildMods(const tuning::BoonTable& table, const boons::RunState& run);

struct Combatant {
    std::string id;
    std::string displayName;
    double life = 0.0;
    double maxLife = 0.0;
    // Ordinary enemies attack every attackPeriodRounds; the boss claws on its
    // own period and breathes fire on a slower, telegraphed schedule.
    double damage = 0.0;
    std::string damageType;
    int attackPeriodRounds = 1;
    bool isBoss = false;
    double breathDamage = 0.0;
    std::string breathDamageType;
    int breathPeriodRounds = 3;
    double actionPoints = 0.0; // accumulates speed; an attack costs one period

    bool alive() const { return life > 0.0; }
};

struct SkillSlot {
    const tuning::CombatSkillDef* def = nullptr;
    int cooldownRounds = 1;     // derived from cooldown_seconds
    int cooldownRemaining = 0;

    bool ready() const { return cooldownRemaining == 0; }
};

// What the acting player (human or policy) sees before choosing.
struct CombatView {
    int round = 0;
    double playerLife = 0.0;
    double playerMaxLife = 0.0;
    // True when fire breath lands THIS round: dashing now dodges it. The
    // inhale telegraph appears in the log one round earlier.
    bool breathIncoming = false;
    const std::vector<Combatant>* enemies = nullptr;
    const std::vector<SkillSlot>* skills = nullptr;

    int aliveEnemyCount() const;
};

struct Action {
    int skillIndex = -1; // -1 = wait/recover
    int targetIndex = 0; // enemy index for single-target skills
};

using Controller = std::function<Action(const CombatView&)>;

struct EncounterResult {
    bool victory = false;
    int rounds = 0;
    double playerLifeRemaining = 0.0;
};

// Runs one encounter to the end. enemyIds may name ordinary enemies or the
// boss id from trial.json. The same seed and inputs always replay identically
// (damage carries a small seeded variance so balance runs form distributions).
EncounterResult runEncounter(const tuning::Tuning& tuning,
                             const stats::DerivedStats& playerStats,
                             const CombatMods& mods,
                             const std::vector<std::string>& enemyIds,
                             uint64_t seed,
                             const Controller& controller,
                             std::vector<std::string>* log = nullptr);

// The scripted player used by balance simulations and tests: dashes through
// telegraphed breath, clears groups with area, focuses lone targets with the
// heavy strike.
Action autoPolicy(const CombatView& view);

} // namespace wroughtwild::combat
