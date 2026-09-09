#include "wroughtwild/trial.h"

#include <cmath>
#include <algorithm>
#include <limits>
#include <random>
#include <sstream>
#include <stdexcept>
#include "wroughtwild/json.h"
#include "wroughtwild/save.h"

namespace wroughtwild::trial {

namespace {
uint64_t mix(uint64_t x) {
    x += 0x9e3779b97f4a7c15ull;
    x = (x ^ (x >> 30)) * 0xbf58476d1ce4e5b9ull;
    x = (x ^ (x >> 27)) * 0x94d049bb133111ebull;
    return x ^ (x >> 31);
}
std::string pack(const std::vector<std::string>& values) {
    std::string out;
    for (const auto& value : values) { if (!out.empty()) out += '|'; out += value; }
    return out;
}
std::vector<std::string> unpack(const std::string& text) {
    std::vector<std::string> out;
    std::stringstream stream(text);
    std::string value;
    while (std::getline(stream, value, '|')) out.push_back(value);
    return out;
}
int integer(const std::string& text) {
    size_t used = 0;
    int value = std::stoi(text, &used);
    if (used != text.size()) throw std::runtime_error("trial checkpoint: malformed integer");
    return value;
}
uint64_t unsignedInteger(const std::string& text) {
    if (text.empty() || text.front() == '-') throw std::runtime_error("trial checkpoint: malformed seed");
    size_t used = 0;
    auto value = std::stoull(text, &used);
    if (used != text.size()) throw std::runtime_error("trial checkpoint: malformed seed");
    return value;
}
std::string inventoryJson(const economy::Inventory& inventory) {
    save::SaveGame payload;
    payload.economy.inventory = inventory;
    return save::toJson(payload);
}
economy::Inventory inventoryFromJson(const std::string& text) {
    auto inventory = save::fromJson(text).economy.inventory;
    for (const auto& [id, count] : inventory)
        if (id.empty() || count < 0) throw std::runtime_error("trial checkpoint: invalid inventory");
    return inventory;
}
const tuning::TrialFloor* expeditionForBoss(const tuning::Tuning& tuning, const std::string& boss) {
    for (const auto& run : tuning.trial.expeditions) if (run.boss.id == boss) return &run;
    return nullptr;
}
tuning::TrialFloor mapFloor(const tuning::Tuning& tuning, const MapOffer& offer) {
    const auto* source = expeditionForBoss(tuning, offer.bossId);
    if (!source || offer.moduleOrder.size() != 5) throw std::runtime_error("trial: invalid map offer");
    tuning::TrialFloor run;
    run.id = offer.id;
    run.displayName = "Forge Expedition - tier " + std::to_string(offer.tier);
    run.boss = source->boss;
    run.runKind = "map";
    run.completionText = "The expedition is cleared. Its spoils are secured.";
    run.exitAfterStage = 3;
    const std::vector<std::string> rewards = {"boon_offer", "materials", "boon_offer", "catalyst", "completion"};
    for (int i = 0; i < 5; ++i) {
        tuning::RoomChoice room;
        room.id = "map_room_" + std::to_string(i);
        room.displayName = i == 4 ? source->boss.displayName : "The Forge Passage";
        room.module = offer.moduleOrder[static_cast<size_t>(i)];
        room.reward = rewards[static_cast<size_t>(i)];
        if (i == 4) room.encounter = source->stages.back().choices.front().encounter;
        else {
            const auto& stage = source->stages[static_cast<size_t>(i) % source->stages.size()];
            room.encounter = stage.choices.front().encounter;
        }
        tuning::TrialStage stage;
        stage.choices.push_back(std::move(room));
        run.stages.push_back(std::move(stage));
    }
    return run;
}
} // namespace

void GateState::enteredMap() { batchSeed = mix(batchSeed) & 0x7fffffffffffffffull; }
void GateState::clearedMap(int tier) {
    if (tier >= 1 && tier <= maxTier && tier < std::numeric_limits<int>::max()) maxTier = std::max(maxTier, tier + 1);
}
std::string GateState::toJson() const {
    return "{\"version\":1,\"batch_seed\":\"" + std::to_string(batchSeed) + "\",\"max_tier\":" + std::to_string(maxTier) + "}";
}
GateState GateState::fromJson(const std::string& text) {
    auto value = json::parse(text);
    if (value->get("version").asInt() != 1) throw std::runtime_error("trial gate: unknown revision");
    GateState state;
    state.batchSeed = unsignedInteger(value->get("batch_seed").asString());
    state.maxTier = value->get("max_tier").asInt();
    if (state.maxTier < 1) throw std::runtime_error("trial gate: invalid tier");
    return state;
}
std::vector<MapOffer> mapOffers(const tuning::Tuning& tuning, const GateState& gate, int tier) {
    if (tier < 1 || tier > gate.maxTier || tuning.trial.expeditions.empty()) return {};
    if (tuning.trial.conditions.size() < 4 || tuning.trial.modules.size() < 5 || tuning.trial.mapTargetPools.size() != 3)
        throw std::runtime_error("trial: incomplete map catalogue");
    std::vector<MapOffer> offers;
    for (int slot = 0; slot < 3; ++slot) {
        MapOffer offer;
        offer.seed = mix(gate.batchSeed ^ (static_cast<uint64_t>(tier) << 16) ^ static_cast<uint64_t>(slot)) & 0x7fffffffffffffffull;
        offer.id = "map_" + std::to_string(offer.seed);
        offer.tier = tier;
        std::mt19937_64 rng(offer.seed);
        offer.bossId = tuning.trial.expeditions[static_cast<size_t>(rng() % tuning.trial.expeditions.size())].boss.id;
        std::vector<std::string> candidates;
        for (const auto& condition : tuning.trial.conditions) candidates.push_back(condition.id);
        std::shuffle(candidates.begin(), candidates.end(), rng);
        const size_t wanted = tier <= 3 ? 2 : (tier <= 7 ? 3 : 4);
        int majorHazards = 0;
        for (const auto& candidate : candidates) {
            const auto& def = *tuning.trial.findCondition(candidate);
            bool compatible = !def.majorHazard || majorHazards < 2;
            for (const auto& selected : offer.conditions) {
                const auto& other = *tuning.trial.findCondition(selected);
                if (std::find(def.incompatible.begin(), def.incompatible.end(), selected) != def.incompatible.end() ||
                    std::find(other.incompatible.begin(), other.incompatible.end(), candidate) != other.incompatible.end()) compatible = false;
                for (const auto& [key, value] : def.effects) {
                    (void)value;
                    if (other.effects.count(key)) compatible = false;
                }
            }
            if (!compatible) continue;
            offer.conditions.push_back(candidate);
            if (def.majorHazard) ++majorHazards;
            if (offer.conditions.size() == wanted) break;
        }
        if (offer.conditions.size() != wanted) throw std::runtime_error("trial: not enough compatible map conditions");
        const auto& pool = tuning.trial.mapTargetPools[static_cast<size_t>(slot)];
        if (pool.empty()) throw std::runtime_error("trial: empty map target pool");
        offer.materialTarget = pool[static_cast<size_t>(rng() % pool.size())];
        offer.rewardMultiplier = 1.0 + tuning.trial.mapRewardPerTier * (tier - 1) +
                                  tuning.trial.mapRewardPerCondition * offer.conditions.size();
        offer.moduleOrder = tuning.trial.modules;
        offer.moduleOrder.erase(std::remove(offer.moduleOrder.begin(), offer.moduleOrder.end(), "secret_crucible"), offer.moduleOrder.end());
        offer.moduleOrder.erase(std::remove(offer.moduleOrder.begin(), offer.moduleOrder.end(), "heart_forge"), offer.moduleOrder.end());
        std::shuffle(offer.moduleOrder.begin(), offer.moduleOrder.end(), rng);
        offer.moduleOrder.resize(4);
        offer.moduleOrder.push_back("heart_forge");
        offers.push_back(std::move(offer));
    }
    return offers;
}

TrialSession::TrialSession(const tuning::Tuning& tuning,
                           economy::PlayerEconomy& economy,
                           boons::BuildTags buildTags,
                           uint64_t seed,
                           const tuning::TrialFloor* floor)
    : TrialSession(tuning, economy, std::move(buildTags), seed, floor, true) {}

TrialSession::TrialSession(const tuning::Tuning& tuning, economy::PlayerEconomy& economy,
                           boons::BuildTags buildTags, uint64_t seed, const tuning::TrialFloor* floor, bool deposit)
    : tuning_(tuning), economy_(economy), floor_(floor), buildTags_(std::move(buildTags)), seed_(seed) {
    if (floor && floor->id=="forge_tyrant" && economy_.campaignPolicy==resonance::campaign) floor_=&tuning_.laboratory;
    if (floor && floor->id=="deep_forge" && economy_.campaignPolicy==resonance::campaign) {
        if (!economy_.resonanceState.campaignAward) throw std::runtime_error("Pairing requires the first physical campaign publication");
        floor_=&tuning_.pairingLaboratory;
    }
    // Deposit ordinary carried possessions at the entrance (D-006).
    if (deposit) {
        depositedInventory_ = economy_.inventory;
        economy_.inventory.clear();
    }
}

TrialSession::TrialSession(const tuning::Tuning& tuning, economy::PlayerEconomy& economy,
                          boons::BuildTags buildTags, const MapOffer& offer)
    : TrialSession(tuning, economy, std::move(buildTags), offer.seed, nullptr, false) {
    // Validate/generate before touching the owner's possessions.
    ownedFloor_ = std::make_unique<tuning::TrialFloor>(mapFloor(tuning, offer));
    floor_ = ownedFloor_.get();
    mapTier_ = offer.tier;
    conditions_ = offer.conditions;
    materialTarget_ = offer.materialTarget;
    mapRewardMultiplier_ = offer.rewardMultiplier;
    for (const auto& id : conditions_) if (!tuning.trial.findCondition(id)) throw std::runtime_error("trial: unknown map condition");
    depositedInventory_ = economy_.inventory;
    economy_.inventory.clear();
}

std::string TrialSession::runId() const { return floor_ ? floor_->id : "legacy_forge"; }
std::string TrialSession::runKind() const { return floor_ ? floor_->runKind : "legacy"; }
int TrialSession::floorIndex() const {
    const int index = std::min(stageIndex_, static_cast<int>(stages().size()) - 1);
    return stages()[static_cast<size_t>(std::max(0, index))].floorIndex;
}
void TrialSession::skipReward() { pendingOffer_.clear(); pendingWeakness_.clear(); }
bool TrialSession::canSuspend() const {
    return !finished_ && !roomInProgress_ && awaitingFloor_ && pendingOffer_.empty() && pendingWeakness_.empty();
}
bool TrialSession::continueFloor() {
    if (!canSuspend()) return false;
    awaitingFloor_ = false;
    return true;
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
    return !finished_ && !roomInProgress_ && exitAfterStage() >= 0 &&
           stageIndex_ > exitAfterStage();
}

combat::CombatMods TrialSession::currentMods() const {
    auto mods = combat::buildMods(tuning_.boons, run_);
    if (mapTier_ > 0) {
        mods.enemyLifeMultiplier *= 1.0 + tuning_.trial.mapLifePerTier * (mapTier_ - 1);
        mods.enemyDamageMultiplier *= 1.0 + tuning_.trial.mapDamagePerTier * (mapTier_ - 1);
        mods.rewardQuantityMultiplier *= mapRewardMultiplier_;
    }
    for (const auto& id : conditions_) {
        const auto* condition = tuning_.trial.findCondition(id);
        if (!condition) continue;
        for (const auto& [key, value] : condition->effects) {
            if (key.find("multiplier") != std::string::npos) {
                auto [it, inserted] = mods.trialEffects.emplace(key, 1.0);
                (void)inserted;
                it->second *= value;
            } else mods.trialEffects[key] += value;
        }
    }
    return mods;
}

TrialSession::RoomOutcome TrialSession::enterRoom(int choiceIndex,
                                                  const stats::DerivedStats& playerStats,
                                                  const combat::Controller& controller,
                                                  std::vector<std::string>* log) {
    RoomStart start = beginRoom(choiceIndex);
    if (!start.started) return RoomOutcome{};

    combat::EncounterResult fight = combat::runEncounter(tuning_, playerStats, roomMods_,
                                                         start.encounter, start.seed,
                                                         controller, log, &boss());
    RoomOutcome outcome = resolveRoom(fight.victory);
    outcome.combat = fight;
    return outcome;
}

TrialSession::RoomStart TrialSession::beginRoom(int choiceIndex) {
    RoomStart start;
    if (finished_ || roomInProgress_ || awaitingFloor_) return start;
    if (runKind() != "legacy" && (!pendingOffer_.empty() || !pendingWeakness_.empty())) return start;

    const tuning::TrialStage& stage = currentStage();
    if (choiceIndex < 0 || choiceIndex >= static_cast<int>(stage.choices.size()))
        throw std::runtime_error("trial: invalid room choice");
    currentRoom_ = &stage.choices[choiceIndex];
    skipReward();
    route_.push_back(choiceIndex);
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
        // The saved encounter seed rotates the bargain, so all three authored
        // risks can appear at the story's single optional bargain chamber.
        for (size_t i = 0; i < tuning_.boons.weaknesses.size(); ++i) {
            const size_t offset = runKind() == "legacy" ? 0 : static_cast<size_t>(roomSeed % tuning_.boons.weaknesses.size());
            const auto& weakness = tuning_.boons.weaknesses[(i + offset) % tuning_.boons.weaknesses.size()];
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
        if (runKind() != "legacy") grantHaul(outcome, tuning_.trial.haulUnits, roomSeed);
        for (const auto& [id, units] : room.haul) { loot_[id] += units; outcome.materials[id] += units; }
    } else if (room.reward == "catalyst") {
        loot_[tuning_.trial.catalystItem] += 1;
        outcome.catalystRecovered = true;
    } else if (room.reward == "completion") {
        bossDefeated_ = true;
        if (mapTier_ > 0) {
            const auto reward=tuning_.trial.mapCompletionComponents.find(materialTarget_);
            if (reward!=tuning_.trial.mapCompletionComponents.end()) {
                for (const auto& [id,units] : reward->second) { loot_[id]+=units; outcome.materials[id]+=units; }
            }
        }
        finish(/*died=*/false);
        return outcome;
    }

    const int previousFloor = floorIndex();
    ++stageIndex_;
    if (stageIndex_ >= static_cast<int>(stages().size()))
        finish(/*died=*/false);
    else if (floorIndex() != previousFloor) awaitingFloor_ = true;
    return outcome;
}

void TrialSession::grantHaul(RoomOutcome& outcome, int units, uint64_t seed) {
    const auto& items = tuning_.trial.haulItems;
    if (items.empty()) return;
    const std::string& id = materialTarget_.empty() ? items[static_cast<size_t>(mix(seed) % items.size())] : materialTarget_;
    if (mapTier_ > 0) {
        auto count = tuning_.trial.mapHaulUnits.find(id);
        if (count != tuning_.trial.mapHaulUnits.end()) units = count->second;
    }
    const int granted = static_cast<int>(std::floor(units * currentMods().rewardQuantityMultiplier));
    loot_[id] += granted;
    outcome.materials[id] += granted;
}
TrialSession::RoomOutcome TrialSession::claimSecret() {
    RoomOutcome outcome;
    if (finished_ || roomInProgress_ || runKind() == "legacy") return outcome;
    // At a lift decision the native stage already points to the next floor,
    // but the player can still explore the cleared floor before descending.
    const int floor = floorIndex() - (awaitingFloor_ ? 1 : 0);
    if (floor != 0 || !secretFloors_.empty()) return outcome;
    secretFloors_.push_back(floor);
    outcome.rewardType = "secret";
    grantHaul(outcome, tuning_.trial.secretUnits, seed_ ^ static_cast<uint64_t>(floor + 71));
    return outcome;
}

std::string TrialSession::checkpoint() const {
    if (!canSuspend()) throw std::runtime_error("trial: suspend requires a settled floor boundary");
    // Reuse the save codec for escaped opaque host fields and exact item values.
    // These records never import an economy; restore validates before constructing.
    save::SaveGame payload;
    auto& e = payload.extra;
    e["trial_checkpoint_version"] = "1";
    e["content_revision"] = std::to_string(tuning_.trial.contentRevision);
    e["run_id"] = runId();
    if (economy_.campaignPolicy==resonance::campaign) {
        e["campaign_policy"]=economy_.campaignPolicy;
        e["laboratory_revision"]=floor_ && floor_->id=="deep_forge" ? "2" : "1";
    }
    e["run_kind"] = runKind();
    e["seed"] = std::to_string(seed_);
    e["stage"] = std::to_string(stageIndex_);
    e["rooms_entered"] = std::to_string(roomsEntered_);
    e["tier"] = std::to_string(mapTier_);
    e["build_tags"] = pack(buildTags_);
    e["boons"] = pack(run_.activeBoons);
    e["weaknesses"] = pack(run_.activeWeaknesses);
    e["conditions"] = pack(conditions_);
    std::vector<std::string> route, secrets;
    for (int choice : route_) route.push_back(std::to_string(choice));
    for (int floor : secretFloors_) secrets.push_back(std::to_string(floor));
    e["route"] = pack(route);
    e["secret_floors"] = pack(secrets);
    e["deposited_inventory"] = inventoryJson(depositedInventory_);
    e["run_loot"] = inventoryJson(loot_);
    e["run_items"] = save::itemListToJson(lootItems_);
    return save::toJson(payload);
}

std::unique_ptr<TrialSession> TrialSession::restore(const tuning::Tuning& tuning,
                                                  economy::PlayerEconomy& economy,
                                                  const std::string& text) {
    const auto payload = save::fromJson(text);
    const auto& e = payload.extra;
    if (e.at("trial_checkpoint_version") != "1" || integer(e.at("content_revision")) != tuning.trial.contentRevision)
        throw std::runtime_error("trial checkpoint: unknown content revision");
    if (e.at("run_kind") != "story" || integer(e.at("tier")) != 0)
        throw std::runtime_error("trial checkpoint: only story floor boundaries can suspend");
    const auto* floor = tuning.trial.findExpedition(e.at("run_id"));
    if (!floor) throw std::runtime_error("trial checkpoint: unknown story run");
    const auto savedPolicy=e.find("campaign_policy");
    const std::string policy=savedPolicy==e.end() ? "legacy" : savedPolicy->second;
    if (policy!=economy.campaignPolicy) throw std::runtime_error("trial checkpoint: campaign policy mismatch");
    if (policy==resonance::campaign) {
        if (floor->id=="forge_tyrant" && e.at("laboratory_revision")=="1") floor=&tuning.laboratory;
        else if (floor->id=="deep_forge" && e.at("laboratory_revision")=="2" && economy.resonanceState.campaignAward) floor=&tuning.pairingLaboratory;
        else throw std::runtime_error("trial checkpoint: unavailable laboratory or unknown revision");
    }
    const int stage = integer(e.at("stage"));
    if (stage <= 0 || stage >= static_cast<int>(floor->stages.size()) ||
        floor->stages[static_cast<size_t>(stage)].floorIndex != floor->stages[static_cast<size_t>(stage - 1)].floorIndex + 1)
        throw std::runtime_error("trial checkpoint: not a floor boundary");
    auto restored = std::unique_ptr<TrialSession>(new TrialSession(tuning, economy, unpack(e.at("build_tags")),
                                                                  unsignedInteger(e.at("seed")), floor, false));
    restored->stageIndex_ = stage;
    restored->roomsEntered_ = integer(e.at("rooms_entered"));
    if (restored->roomsEntered_ != stage) throw std::runtime_error("trial checkpoint: inconsistent encounter count");
    for (const auto& choice : unpack(e.at("route"))) restored->route_.push_back(integer(choice));
    if (restored->route_.size() != static_cast<size_t>(stage)) throw std::runtime_error("trial checkpoint: incomplete route");
    for (int i = 0; i < stage; ++i) {
        int choice = restored->route_[static_cast<size_t>(i)];
        if (choice < 0 || choice >= static_cast<int>(floor->stages[static_cast<size_t>(i)].choices.size()))
            throw std::runtime_error("trial checkpoint: invalid route choice");
    }
    for (const auto& secret : unpack(e.at("secret_floors"))) {
        int index = integer(secret);
        if (index < 0 || index >= restored->floorIndex() ||
            std::find(restored->secretFloors_.begin(), restored->secretFloors_.end(), index) != restored->secretFloors_.end())
            throw std::runtime_error("trial checkpoint: invalid secret claim");
        restored->secretFloors_.push_back(index);
    }
    for (const auto& weakness : unpack(e.at("weaknesses"))) {
        auto it = std::find_if(tuning.boons.weaknesses.begin(), tuning.boons.weaknesses.end(),
                               [&](const auto& def) { return def.id == weakness; });
        if (it == tuning.boons.weaknesses.end() || restored->run_.hasWeakness(weakness))
            throw std::runtime_error("trial checkpoint: invalid weakness");
        restored->run_.acceptWeakness(weakness);
    }
    for (const auto& boon : unpack(e.at("boons")))
        if (!boons::acceptBoon(tuning.boons, boon, restored->buildTags_, restored->run_))
            throw std::runtime_error("trial checkpoint: invalid boon");
    if (!unpack(e.at("conditions")).empty()) throw std::runtime_error("trial checkpoint: story has map conditions");
    restored->depositedInventory_ = inventoryFromJson(e.at("deposited_inventory"));
    restored->loot_ = inventoryFromJson(e.at("run_loot"));
    restored->lootItems_ = save::itemListFromJson(e.at("run_items"));
    for (const auto& item : restored->lootItems_)
        if (!tuning.items.findBase(item.baseId)) throw std::runtime_error("trial checkpoint: unknown item base");
    restored->awaitingFloor_ = true;
    return restored;
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
                economy_.grant(id, amount);
            else if (!isCatalyst && !tuning_.trial.loseRunMaterialsOnDeath)
                economy_.grant(id, amount);
        } else {
            economy_.grant(id, amount);
        }
    }

    // Dropped gear follows the same contract as run materials.
    if (!died || !tuning_.trial.loseRunMaterialsOnDeath)
        for (const auto& item : lootItems_) economy_.packItems.push_back(item);

    // The curio and the lock (Wave 8 slice 2): the boss's fall leaves its
    // curio in your hand, and a landmark in another biome takes it to
    // record the unlock. A floor without a curio unlocks outright.
    if (bossDefeated_) {
        const std::string curio = floor_ ? floor_->completionCurio : tuning_.trial.completionCurio;
        if(economy_.campaignPolicy==resonance::campaign && floor_ && floor_->id=="forge_tyrant") {
            if(!economy_.worldEffectActive("lf4_annex_victory")) {
                economy_.recordWorldEffect("lf4_annex_victory");
                if(!curio.empty() && !economy_.curioHeld(curio))economy_.grant(curio,1);
                if(economy_.resonanceState.phase=="dormant") {
                    economy_.resonanceState.phase="pending";
                    economy_.resonanceState.seed=economy_.worldSeed;
                }
            }
        } else if(economy_.campaignPolicy==resonance::campaign && floor_ && floor_->id=="deep_forge") {
            if(!economy_.worldEffectActive("lf5_pairing_victory")) {
                economy_.recordWorldEffect("lf5_pairing_victory");
                if(!curio.empty() && !economy_.curioHeld(curio))economy_.grant(curio,1);
            }
            if(economy_.secondResonance.phase=="dormant") {
                economy_.secondResonance.phase="pending";
                economy_.secondResonance.seed=economy_.resonanceState.seed;
            }
        } else {
            if (!curio.empty()) economy_.grant(curio, 1);
            else if (!completionUnlock().empty()) economy_.recordWorldEffect(completionUnlock());
        }
    }

    // Temporary trial effects never outlive the run (design pillar).
    run_.clear();
}

} // namespace wroughtwild::trial
