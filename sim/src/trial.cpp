#include "wroughtwild/trial.h"

#include <cmath>
#include <stdexcept>

namespace wroughtwild::trial {

TrialSession::TrialSession(const tuning::Tuning& tuning,
                           economy::PlayerEconomy& economy,
                           boons::BuildTags buildTags,
                           uint64_t seed,
                           const tuning::TrialFloor* floor)
    : tuning_(tuning), economy_(economy), floor_(floor), buildTags_(std::move(buildTags)), seed_(seed) {
    // Deposit ordinary carried possessions at the entrance (D-006).
    depositedInventory_ = economy_.inventory;
    economy_.inventory.clear();
}

const std::vector<tuning::TrialStage>& TrialSession::stages() const {
    return floor_ ? floor_->stages : tuning_.trial.stages;
}
const tuning::BossDef& TrialSession::boss() const { return floor_ ? floor_->boss : tuning_.trial.boss; }
int TrialSession::exitAfterStage() const { return floor_ ? floor_->exitAfterStage : tuning_.trial.exitAfterStage; }
const std::string& TrialSession::completionUnlock() const {
    return floor_ ? floor_->completionUnlock : tuning_.trial.completionUnlock;
}

const tuning::TrialStage& TrialSession::currentStage() const {
    if (stageIndex_ >= static_cast<int>(stages().size()))
        throw std::runtime_error("trial: no stage at index " + std::to_string(stageIndex_));
    return stages()[stageIndex_];
}

bool TrialSession::canBankAndExit() const {
    return !finished_ && exitAfterStage() >= 0 &&
           stageIndex_ > exitAfterStage();
}

combat::CombatMods TrialSession::currentMods() const {
    return combat::buildMods(tuning_.boons, run_);
}

TrialSession::RoomOutcome TrialSession::enterRoom(int choiceIndex,
                                                  const stats::DerivedStats& playerStats,
                                                  const combat::Controller& controller,
                                                  std::vector<std::string>* log) {
    RoomStart start = beginRoom(choiceIndex);
    if (!start.started) return RoomOutcome{};

    combat::EncounterResult fight = combat::runEncounter(tuning_, playerStats, roomMods_,
                                                         start.encounter, start.seed,
                                                         controller, log);
    RoomOutcome outcome = resolveRoom(fight.victory);
    outcome.combat = fight;
    return outcome;
}

TrialSession::RoomStart TrialSession::beginRoom(int choiceIndex) {
    RoomStart start;
    if (finished_ || roomInProgress_) return start;

    const tuning::TrialStage& stage = currentStage();
    if (choiceIndex < 0 || choiceIndex >= static_cast<int>(stage.choices.size()))
        throw std::runtime_error("trial: invalid room choice");
    currentRoom_ = &stage.choices[choiceIndex];
    roomMods_ = currentMods();
    roomSeed_ = seed_ + 7919ull * static_cast<uint64_t>(++roomsEntered_);
    roomInProgress_ = true;

    start.started = true;
    start.roomId = currentRoom_->id;
    start.displayName = currentRoom_->displayName;
    start.encounter = currentRoom_->encounter;
    start.seed = roomSeed_;
    return start;
}

void TrialSession::abandon() {
    if (finished_) return;
    roomInProgress_ = false;
    finish(/*died=*/true);
}

TrialSession::RoomOutcome TrialSession::resolveRoom(bool victory) {
    RoomOutcome outcome;
    if (finished_ || !roomInProgress_) return outcome;
    roomInProgress_ = false;
    const tuning::RoomChoice& room = *currentRoom_;
    const combat::CombatMods& mods = roomMods_;
    const uint64_t roomSeed = roomSeed_;
    outcome.combat.victory = victory;

    if (!victory) {
        finish(/*died=*/true);
        return outcome;
    }

    outcome.rewardType = room.reward;

    // Gear drops (D-014): the room's reward type decides rarity and tier;
    // the base is drawn from every base, so any build can be pulled sideways.
    auto itemReward = tuning_.trial.itemRewards.find(room.reward);
    if (itemReward != tuning_.trial.itemRewards.end() && !tuning_.items.itemBases.empty()) {
        const auto& bases = tuning_.items.itemBases;
        const auto& base = bases[static_cast<size_t>((roomSeed >> 8) % bases.size())];
        auto item = items::rollRarityItem(tuning_.items, base.id, itemReward->second.rarity,
                                          itemReward->second.tier, roomSeed ^ 0xA5A5A5A5ull);
        lootItems_.push_back(item);
        outcome.items.push_back(item);
    }

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
    if (stageIndex_ >= static_cast<int>(stages().size()))
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

    // Dropped gear follows the same contract as run materials.
    if (!died || !tuning_.trial.loseRunMaterialsOnDeath)
        for (const auto& item : lootItems_) economy_.packItems.push_back(item);

    if (bossDefeated_)
        economy_.recordWorldEffect(completionUnlock());

    // Temporary trial effects never outlive the run (design pillar).
    run_.clear();
}

} // namespace wroughtwild::trial
