#pragma once

// One attempt at the repeatable trial. In plain terms: the "dungeon run
// manager" — it stores your ordinary inventory at the entrance (so dying
// cannot cost it), walks you through branching rooms, hands out temporary
// boon offers, and settles the death contract at the end. The persistent
// build (equipment, skills, economy) is never modified by a run; only the
// loot you bank comes home.

#include <cstdint>
#include <map>
#include <memory>
#include <string>
#include <vector>

#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/tuning.h"

namespace wroughtwild::trial {

struct MapOffer {
    std::string id;
    uint64_t seed = 0;
    int tier = 1;
    std::string bossId;
    std::vector<std::string> conditions;
    std::vector<std::string> moduleOrder;
    std::string materialTarget;
    double rewardMultiplier = 1.0;
};

// The three offers are pure functions of saved state and selected tier.
// Only a successfully opened map advances the batch; clearing unlocks a tier.
struct GateState {
    uint64_t batchSeed = 741103;
    int maxTier = 1;
    void enteredMap();
    void clearedMap(int tier);
    std::string toJson() const;
    static GateState fromJson(const std::string& text);
};
std::vector<MapOffer> mapOffers(const tuning::Tuning& tuning, const GateState& gate, int tier);

class TrialSession {
public:
    // Constructing the session deposits the player's carried inventory at the
    // gate (D-006: trials protect stored possessions).
    // floor: a deeper run (tuning::TrialFloor), or nullptr for the first.
    TrialSession(const tuning::Tuning& tuning,
                 economy::PlayerEconomy& economy,
                 boons::BuildTags buildTags,
                 uint64_t seed,
                 const tuning::TrialFloor* floor = nullptr);
    TrialSession(const tuning::Tuning& tuning, economy::PlayerEconomy& economy,
                 boons::BuildTags buildTags, const MapOffer& offer);

    const tuning::TrialFloor* floor() const { return floor_; }
    const std::vector<tuning::TrialStage>& stages() const;
    const tuning::BossDef& boss() const;
    int exitAfterStage() const;
    const std::string& completionUnlock() const;
    std::string runId() const;
    std::string runKind() const;
    uint64_t seed() const { return seed_; }
    int tier() const { return mapTier_; }
    const std::string& materialTarget() const { return materialTarget_; }
    int floorIndex() const;
    int floorCount() const { return floor_ ? floor_->floorCount : 1; }
    bool awaitingFloor() const { return awaitingFloor_; }
    bool continueFloor();
    bool canSuspend() const;
    void skipReward();
    const std::vector<std::string>& conditions() const { return conditions_; }
    const std::vector<int>& route() const { return route_; }
    // A checkpoint contains a settled floor boundary, never a live encounter.
    std::string checkpoint() const;
    static std::unique_ptr<TrialSession> restore(const tuning::Tuning& tuning,
                                               economy::PlayerEconomy& economy,
                                               const std::string& text);

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
        std::vector<items::ItemInstance> items; // gear the room dropped (D-014)
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
    RoomOutcome claimSecret();
    bool roomInProgress() const { return roomInProgress_; }

    // Walking out mid-run is a failed attempt: the death contract applies.
    void abandon();

    bool acceptBoonFromOffer(const std::string& boonId);
    bool acceptOfferedWeakness();

    // Leave after the bank-out point: run loot is kept, the boss waits.
    void bankAndExit();

    const boons::RunState& runState() const { return run_; }
    const std::map<std::string, int>& runLoot() const { return loot_; }
    const std::vector<items::ItemInstance>& runLootItems() const { return lootItems_; }
    combat::CombatMods currentMods() const;

private:
    TrialSession(const tuning::Tuning& tuning, economy::PlayerEconomy& economy,
                 boons::BuildTags buildTags, uint64_t seed,
                 const tuning::TrialFloor* floor, bool deposit);
    void finish(bool died);
    void grantHaul(RoomOutcome& outcome, int units, uint64_t seed);

    const tuning::Tuning& tuning_;
    economy::PlayerEconomy& economy_;
    const tuning::TrialFloor* floor_ = nullptr;
    std::unique_ptr<tuning::TrialFloor> ownedFloor_;
    boons::BuildTags buildTags_;
    uint64_t seed_;
    int roomsEntered_ = 0;
    int mapTier_ = 0;
    std::string materialTarget_;
    double mapRewardMultiplier_ = 1.0;
    std::vector<std::string> conditions_;
    std::vector<int> route_;
    std::vector<int> secretFloors_;
    bool awaitingFloor_ = false;

    economy::Inventory depositedInventory_;
    boons::RunState run_;
    std::map<std::string, int> loot_;
    std::vector<items::ItemInstance> lootItems_;
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
