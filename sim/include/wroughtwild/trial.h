#pragma once

// One attempt at the repeatable trial. In plain terms: the "dungeon run
// manager" — it stores your ordinary inventory at the entrance (so dying
// cannot cost it), walks you through branching rooms, hands out temporary
// boon offers, and settles the death contract at the end. The persistent
// build (equipment, skills, economy) is never modified by a run; only the
// loot you bank comes home.

#include <cstdint>
#include <map>
#include <string>
#include <vector>

#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::trial {

class TrialSession {
public:
    // Constructing the session deposits the player's carried inventory at the
    // gate (D-006: trials protect stored possessions).
    TrialSession(const tuning::Tuning& tuning,
                 economy::PlayerEconomy& economy,
                 boons::BuildTags buildTags,
                 uint64_t seed);

    // A session ends exactly once: bossDefeated, banked out, or died.
    bool finished() const { return finished_; }
    bool playerDied() const { return died_; }
    bool bossDefeated() const { return bossDefeated_; }

    int currentStageIndex() const { return stageIndex_; }
    const tuning::TrialStage& currentStage() const;
    // True once the player has cleared the configured bank-out point: they
    // may leave with their run loot instead of pushing to the boss.
    bool canBankAndExit() const;

    struct RoomOutcome {
        combat::EncounterResult combat;
        std::string rewardType;
        // For boon_offer rooms: pick one with acceptBoonFromOffer (or skip).
        std::vector<const tuning::BoonDef*> boonOffer;
        // For weakness_offer rooms: accept with acceptOfferedWeakness or skip.
        std::string offeredWeakness;
        bool catalystRecovered = false;
        std::map<std::string, int> materials; // already multiplied by reward mods
    };

    // Fights the chosen room. On victory the room's reward is prepared (and
    // materials/catalysts added to run loot); on defeat the death contract is
    // applied and the session finishes.
    RoomOutcome enterRoom(int choiceIndex,
                          const stats::DerivedStats& playerStats,
                          const combat::Controller& controller,
                          std::vector<std::string>* log = nullptr);

    // For a real-time host (ADR-0003): beginRoom chooses the room and hands
    // back who to fight plus the seed for that fight's HitStream; the host
    // fights in its own time and then calls resolveRoom, which applies the
    // reward (victory) or the death contract (defeat) exactly as enterRoom
    // would. enterRoom is these two calls around runEncounter.
    struct RoomStart {
        bool started = false;
        std::string roomId;
        std::string displayName;
        std::vector<std::string> encounter;
        uint64_t seed = 0;
    };
    RoomStart beginRoom(int choiceIndex);
    RoomOutcome resolveRoom(bool victory);
    bool roomInProgress() const { return roomInProgress_; }

    // Walking out mid-run is a failed attempt: the death contract applies.
    void abandon();

    bool acceptBoonFromOffer(const std::string& boonId);
    bool acceptOfferedWeakness();

    // Leave after the bank-out point: run loot is kept, the boss waits.
    void bankAndExit();

    const boons::RunState& runState() const { return run_; }
    const std::map<std::string, int>& runLoot() const { return loot_; }
    combat::CombatMods currentMods() const;

private:
    void finish(bool died);

    const tuning::Tuning& tuning_;
    economy::PlayerEconomy& economy_;
    boons::BuildTags buildTags_;
    uint64_t seed_;
    int roomsEntered_ = 0;

    economy::Inventory depositedInventory_;
    boons::RunState run_;
    std::map<std::string, int> loot_;
    std::vector<const tuning::BoonDef*> pendingOffer_;
    std::string pendingWeakness_;

    int stageIndex_ = 0;
    bool finished_ = false;
    bool died_ = false;
    bool bossDefeated_ = false;

    bool roomInProgress_ = false;
    const tuning::RoomChoice* currentRoom_ = nullptr;
    combat::CombatMods roomMods_;
    uint64_t roomSeed_ = 0;
};

} // namespace wroughtwild::trial
