#include "wroughtwild/trial.h"

#include <cmath>
#include <stdexcept>

namespace wroughtwild::trial {

TrialSession::TrialSession(const tuning::Tuning& tuning,
                           economy::PlayerEconomy& economy,
                           boons::BuildTags buildTags,
                           uint64_t seed)
    : tuning_(tuning), economy_(economy), buildTags_(std::move(buildTags)), seed_(seed) {
    // Deposit ordinary carried possessions at the entrance (D-006).
    depositedInventory_ = economy_.inventory;
    economy_.inventory.clear();
}

const tuning::TrialStage& TrialSession::currentStage() const {
    if (stageIndex_ >= static_cast<int>(tuning_.trial.stages.size()))
        throw std::runtime_error("trial: no stage at index " + std::to_string(stageIndex_));
    return tuning_.trial.stages[stageIndex_];
}

bool TrialSession::canBankAndExit() const {
    return !finished_ && tuning_.trial.exitAfterStage >= 0 &&
           stageIndex_ > tuning_.trial.exitAfterStage;
}

combat::CombatMods TrialSession::currentMods() const {
    return combat::buildMods(tuning_.boons, run_);
}

TrialSession::RoomOutcome TrialSession::enterRoom(int choiceIndex,
                                                  const stats::DerivedStats& playerStats,
                                                  const combat::Controller& controller,
                                                  std::vector<std::string>* log) {
    RoomOutcome outcome;
    if (finished_) return outcome;

    const tuning::TrialStage& stage = currentStage();
    if (choiceIndex < 0 || choiceIndex >= static_cast<int>(stage.choices.size()))
        throw std::runtime_error("trial: invalid room choice");
    const tuning::RoomChoice& room = stage.choices[choiceIndex];

    combat::CombatMods mods = currentMods();
    uint64_t roomSeed = seed_ + 7919ull * static_cast<uint64_t>(++roomsEntered_);
    outcome.combat = combat::runEncounter(tuning_, playerStats, mods, room.encounter,
                                          roomSeed, controller, log);

    if (!outcome.combat.victory) {
        finish(/*died=*/true);
        return outcome;
    }

    outcome.rewardType = room.reward;
    if (room.reward == "boon_offer") {
        pendingOffer_ = boons::generateOffer(tuning_.boons, buildTags_, run_, roomSeed);
        outcome.boonOffer = pendingOffer_;
    } else if (room.reward == "weakness_offer") {
        // The slice has a small weakness pool; offer the first not yet active.
        for (const auto& weakness : tuning_.boons.weaknesses) {
            if (!run_.hasWeakness(weakness.id)) {
                pendingWeakness_ = weakness.id;
                outcome.offeredWeakness = weakness.id;
                break;
            }
        }
    } else if (room.reward == "materials") {
        for (const auto& [id, amount] : tuning_.trial.materialsReward) {
            int granted = static_cast<int>(
                std::floor(amount * mods.rewardQuantityMultiplier));
            loot_[id] += granted;
            outcome.materials[id] = granted;
        }
    } else if (room.reward == "catalyst") {
        loot_[tuning_.trial.catalystItem] += 1;
        outcome.catalystRecovered = true;
    } else if (room.reward == "completion") {
        bossDefeated_ = true;
        finish(/*died=*/false);
        return outcome;
    }

    ++stageIndex_;
    if (stageIndex_ >= static_cast<int>(tuning_.trial.stages.size()))
        finish(/*died=*/false);
    return outcome;
}

bool TrialSession::acceptBoonFromOffer(const std::string& boonId) {
    for (const auto* boon : pendingOffer_) {
        if (boon->id == boonId) {
            pendingOffer_.clear();
            return boons::acceptBoon(tuning_.boons, boonId, buildTags_, run_);
        }
    }
    return false;
}

bool TrialSession::acceptOfferedWeakness() {
    if (pendingWeakness_.empty()) return false;
    run_.acceptWeakness(pendingWeakness_);
    pendingWeakness_.clear();
    return true;
}

void TrialSession::bankAndExit() {
    if (finished_ || !canBankAndExit()) return;
    finish(/*died=*/false);
}

void TrialSession::finish(bool died) {
    if (finished_) return;
    finished_ = true;
    died_ = died;

    // The deposited inventory always comes home: trial death never costs
    // stored possessions or permanent equipment (D-006).
    economy_.inventory = depositedInventory_;

    for (const auto& [id, amount] : loot_) {
        bool isCatalyst = (id == tuning_.trial.catalystItem);
        if (died) {
            // Provisional death contract: catalysts represent learning and
            // survive a failed attempt; ordinary run loot is lost.
            if (isCatalyst && tuning_.trial.keepCatalystsOnDeath)
                economy_.inventory[id] += amount;
            else if (!isCatalyst && !tuning_.trial.loseRunMaterialsOnDeath)
                economy_.inventory[id] += amount;
        } else {
            economy_.inventory[id] += amount;
        }
    }

    if (bossDefeated_)
        economy_.recordWorldEffect(tuning_.trial.completionUnlock);

    // Temporary trial effects never outlive the run (design pillar).
    run_.clear();
}

} // namespace wroughtwild::trial
