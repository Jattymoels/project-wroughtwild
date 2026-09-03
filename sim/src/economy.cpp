#include "wroughtwild/economy.h"

#include <algorithm>
#include <random>
#include <cmath>
#include <stdexcept>

namespace wroughtwild::economy {

bool hasAll(const Inventory& inventory, const std::map<std::string, int>& required) {
    for (const auto& [id, count] : required) {
        auto it = inventory.find(id);
        if (it == inventory.end() || it->second < count) return false;
    }
    return true;
}

void remove(Inventory& inventory, const std::map<std::string, int>& amounts) {
    if (!hasAll(inventory, amounts))
        throw std::runtime_error("economy: removing more than the inventory holds");
    for (const auto& [id, count] : amounts) inventory[id] -= count;
}

void add(Inventory& inventory, const std::map<std::string, int>& amounts) {
    for (const auto& [id, count] : amounts) inventory[id] += count;
}

int levelForXp(const tuning::CraftSkillDef& skill, int xp) {
    int level = 0;
    for (size_t i = 0; i < skill.xpRequiredByLevel.size(); ++i)
        if (xp >= skill.xpRequiredByLevel[i]) level = static_cast<int>(i) + 1;
    return std::min(level, skill.maximumPrototypeLevel);
}

PlayerEconomy::PlayerEconomy(const tuning::Tuning& tuning) : tuning_(tuning) {
    resetLoadout();
}

void PlayerEconomy::resetLoadout() {
    knownSkills_ = tuning_.skills.startingSkillIds();
    skillBar_.assign(kSkillBarSize, "");
    for (size_t i = 0; i < knownSkills_.size() && i < static_cast<size_t>(kSkillBarSize); ++i)
        skillBar_[i] = knownSkills_[i];
}

bool PlayerEconomy::knowsSkill(const std::string& skillId) const {
    return std::find(knownSkills_.begin(), knownSkills_.end(), skillId) != knownSkills_.end();
}

bool PlayerEconomy::learnSkill(const std::string& skillId) {
    if (!tuning_.skills.findCombatSkill(skillId) || knowsSkill(skillId)) return false;
    knownSkills_.push_back(skillId);
    for (auto& slot : skillBar_) {
        if (slot.empty()) {
            slot = skillId;
            break;
        }
    }
    return true;
}

bool PlayerEconomy::setBarSlot(int slot, const std::string& skillId) {
    if (slot < 0 || slot >= kSkillBarSize) return false;
    if (!skillId.empty() && !knowsSkill(skillId)) return false;
    if (!skillId.empty()) {
        // One key per skill: moving it vacates its old slot.
        for (auto& existing : skillBar_)
            if (existing == skillId) existing.clear();
    }
    skillBar_[static_cast<size_t>(slot)] = skillId;
    return true;
}

int PlayerEconomy::skillXp(const std::string& skillId) const {
    auto it = skills_.find(skillId);
    return it == skills_.end() ? 0 : it->second.xp;
}

int PlayerEconomy::skillLevel(const std::string& skillId) const {
    const tuning::CraftSkillDef* def = tuning_.skills.findCraftSkill(skillId);
    if (!def) return 0;
    return levelForXp(*def, skillXp(skillId));
}

void PlayerEconomy::grantSkillXp(const std::string& skillId, int amount) {
    if (!tuning_.skills.findCraftSkill(skillId))
        throw std::runtime_error("economy: unknown craft skill " + skillId);
    skills_[skillId].xp += amount;
}

void PlayerEconomy::addAvailableStation(const std::string& stationId) {
    if (!tuning_.crafting.findStation(stationId))
        throw std::runtime_error("economy: unknown station " + stationId);
    if (!stationAvailable(stationId)) availableStations_.push_back(stationId);
}

bool PlayerEconomy::stationAvailable(const std::string& stationId) const {
    return std::find(availableStations_.begin(), availableStations_.end(), stationId) !=
           availableStations_.end();
}

double PlayerEconomy::repetitionMultiplier(const std::string& recipeId, bool forOrder) const {
    const tuning::RepetitionDecay& decay = tuning_.crafting.repetitionDecay;
    if (!decay.enabled) return 1.0;
    if (forOrder && decay.orderCraftingIgnoresDecay) return 1.0;

    auto it = craftCounts_.find(recipeId);
    int repetition = (it == craftCounts_.end() ? 0 : it->second) + 1; // the craft being attempted
    if (repetition <= decay.fullXpRepetitions) return 1.0;
    double multiplier = static_cast<double>(decay.fullXpRepetitions) / repetition;
    return std::max(multiplier, decay.minimumMultiplier);
}

int PlayerEconomy::fuelValueHeld() const {
    int total = 0;
    for (const auto& [item, value] : tuning_.crafting.fuels) {
        auto held = inventory.find(item);
        if (held != inventory.end()) total += held->second * value;
    }
    return total;
}

bool PlayerEconomy::fuelMet(const std::string& recipeId) const {
    const tuning::Recipe* recipe = tuning_.crafting.findRecipe(recipeId);
    if (!recipe || recipe->fuelCost <= 0 || recipe->station.empty()) return true;
    int available = 0;
    for (const auto& [item, value] : tuning_.crafting.fuels) {
        auto held = inventory.find(item);
        int count = held != inventory.end() ? held->second : 0;
        // Units committed as recipe inputs cannot also burn as fuel.
        auto asInput = recipe->inputs.find(item);
        if (asInput != recipe->inputs.end()) count -= asInput->second;
        available += std::max(0, count) * value;
    }
    return available >= recipe->fuelCost;
}

PlayerEconomy::CraftResult PlayerEconomy::craft(const std::string& recipeId, bool forOrder) {
    CraftResult result;
    const tuning::Recipe* recipe = tuning_.crafting.findRecipe(recipeId);
    if (!recipe) {
        result.failure.unknownRecipe = true;
        return result;
    }
    // An empty station means hand-crafting: no facility gate, no fuel burned.
    bool handCraft = recipe->station.empty();
    if (!handCraft && !stationAvailable(recipe->station)) result.failure.stationUnavailable = true;
    for (const auto& [skillId, level] : recipe->minimumSkill)
        if (skillLevel(skillId) < level) result.failure.skillTooLow = true;
    if (!hasAll(inventory, recipe->inputs)) result.failure.missingInputs = true;
    if (!fuelMet(recipeId)) result.failure.missingFuel = true;
    if (result.failure.any()) return result;

    remove(inventory, recipe->inputs);

    // Burn fuel cheapest-value first, so wood feeds the fire before charcoal.
    if (!handCraft && recipe->fuelCost > 0) {
        std::vector<std::pair<int, std::string>> byValue;
        for (const auto& [item, value] : tuning_.crafting.fuels)
            byValue.push_back({value, item});
        std::sort(byValue.begin(), byValue.end());
        int needed = recipe->fuelCost;
        for (const auto& [value, item] : byValue) {
            while (needed > 0 && inventory[item] > 0) {
                inventory[item] -= 1;
                needed -= value;
            }
        }
    }

    // Outputs that are item bases become rolled gear in the pack (D-019:
    // crafted gear rolls like a drop); everything else stacks.
    for (const auto& [outputId, count] : recipe->outputs) {
        const tuning::ItemBase* base = tuning_.items.findBase(outputId);
        if (base == nullptr) {
            add(inventory, {{outputId, count}});
            continue;
        }
        for (int i = 0; i < count; ++i) {
            const uint64_t seed = 0xC4A1F7ull * static_cast<uint64_t>(++craftedGear_) + 17;
            std::mt19937_64 rng(seed);
            std::uniform_real_distribution<double> roll(0.0, 1.0);
            int level = 0;
            for (const auto& [skillId, minimum] : recipe->minimumSkill) level = std::max(level, skillLevel(skillId));
            const auto& rolls = tuning_.crafting;
            std::string rarity = "plain";
            const double wrought = level >= rolls.wroughtChanceFromLevel
                                       ? rolls.wroughtChancePerLevel * (level - rolls.wroughtChanceFromLevel + 1)
                                       : 0.0;
            const double keen = rolls.keenChanceAtLevel1 + rolls.keenChancePerLevel * std::max(0, level - 1);
            if (roll(rng) < wrought) rarity = "wrought";
            else if (roll(rng) < keen) rarity = "keen";
            packItems.push_back(items::rollRarityItem(tuning_.items, outputId, rarity, currentEra(), rng()));
        }
    }

    result.xpMultiplier = repetitionMultiplier(recipeId, forOrder);
    result.xpGranted = static_cast<int>(std::floor(recipe->baseSkillXp * result.xpMultiplier));
    for (const auto& [skillId, level] : recipe->minimumSkill)
        grantSkillXp(skillId, result.xpGranted);

    if (!(forOrder && tuning_.crafting.repetitionDecay.orderCraftingIgnoresDecay))
        craftCounts_[recipeId] += 1;

    for (const auto& id : foundryEvent("recipe:" + recipeId)) foundryNotices_.push_back(id);
    result.crafted = true;
    return result;
}

PlayerEconomy::OrderResult PlayerEconomy::fulfillOrder(const std::string& orderId) {
    OrderResult result;
    const tuning::Order* order = tuning_.crafting.findOrder(orderId);
    if (!order) return result;
    if (std::find(fulfilledOrders_.begin(), fulfilledOrders_.end(), orderId) !=
        fulfilledOrders_.end()) {
        result.alreadyFulfilled = true;
        return result;
    }
    if (!hasAll(inventory, order->requiredOutputs)) {
        result.missingOutputs = true;
        return result;
    }

    remove(inventory, order->requiredOutputs);
    for (const auto& [rewardId, amount] : order->rewards) {
        // Rewards named "<skill>_xp" feed that craft skill; everything else is currency.
        const std::string xpSuffix = "_xp";
        if (rewardId.size() > xpSuffix.size() &&
            rewardId.compare(rewardId.size() - xpSuffix.size(), xpSuffix.size(), xpSuffix) == 0) {
            std::string skillId = rewardId.substr(0, rewardId.size() - xpSuffix.size());
            if (tuning_.skills.findCraftSkill(skillId)) {
                grantSkillXp(skillId, amount);
                continue;
            }
        }
        currency[rewardId] += amount;
    }

    fulfilledOrders_.push_back(orderId);
    recordWorldEffect(order->worldEffect);
    result.fulfilled = true;
    result.worldEffect = order->worldEffect;
    return result;
}

bool PlayerEconomy::orderFulfilled(const std::string& orderId) const {
    return std::find(fulfilledOrders_.begin(), fulfilledOrders_.end(), orderId) != fulfilledOrders_.end();
}

bool PlayerEconomy::recipeFeedsOpenOrder(const std::string& recipeId) const {
    const tuning::Recipe* recipe = tuning_.crafting.findRecipe(recipeId);
    if (!recipe) return false;
    for (const auto& order : tuning_.crafting.orders) {
        if (orderFulfilled(order.id)) continue;
        for (const auto& [outputId, count] : recipe->outputs)
            if (order.requiredOutputs.count(outputId) > 0) return true;
    }
    return false;
}

bool PlayerEconomy::worldEffectActive(const std::string& effect) const {
    return std::find(worldEffects_.begin(), worldEffects_.end(), effect) != worldEffects_.end();
}

void PlayerEconomy::recordWorldEffect(const std::string& effect) {
    if (worldEffectActive(effect)) return;
    const int before = currentEra();
    worldEffects_.push_back(effect);
    for (const auto& id : foundryEvent("world_effect:" + effect)) foundryNotices_.push_back(id);
    // An effect that wakes an era is a milestone of its own.
    for (int era = before + 1; era <= currentEra(); ++era)
        for (const auto& id : foundryEvent("era:" + std::to_string(era))) foundryNotices_.push_back(id);
}

bool PlayerEconomy::buy(const std::string& itemId) {
    for (const auto& offer : tuning_.crafting.market) {
        if (offer.item != itemId) continue;
        auto have = currency.find(offer.currency);
        if (have == currency.end() || have->second < offer.price) return false;
        have->second -= offer.price;
        inventory[offer.item] += offer.count;
        return true;
    }
    return false;
}

std::vector<std::string> PlayerEconomy::noteSkillUse(const std::string& skillId) {
    std::vector<std::string> unlocked;
    const tuning::CombatSkillDef* def = tuning_.skills.findCombatSkill(skillId);
    if (!def) return unlocked;
    const int uses = ++skillUses_[skillId];
    for (const auto& perk : def->mastery)
        if (perk.uses == uses) unlocked.push_back(perk.text);
    return unlocked;
}

int PlayerEconomy::skillUses(const std::string& skillId) const {
    auto it = skillUses_.find(skillId);
    return it == skillUses_.end() ? 0 : it->second;
}

std::vector<const tuning::MasteryPerk*> PlayerEconomy::masteryUnlocked(const std::string& skillId) const {
    std::vector<const tuning::MasteryPerk*> out;
    const tuning::CombatSkillDef* def = tuning_.skills.findCombatSkill(skillId);
    if (!def) return out;
    const int uses = skillUses(skillId);
    for (const auto& perk : def->mastery)
        if (perk.uses <= uses) out.push_back(&perk);
    return out;
}

foundry::PlateSize PlayerEconomy::plateSize() const { return foundry::plateSize(tuning_.foundry, currentEra()); }

std::vector<std::string> PlayerEconomy::foundryEvent(const std::string& event) {
    std::vector<std::string> granted;
    const int era = currentEra();
    for (const auto& source : tuning_.foundry.sources) {
        if (source.event != event || source.era > era) continue;
        if (std::find(foundry_.milestones.begin(), foundry_.milestones.end(), source.id) != foundry_.milestones.end())
            continue;
        foundry_.milestones.push_back(source.id);
        foundry_.owned[source.ingot] += 1;
        granted.push_back(source.ingot);
    }
    return granted;
}

bool PlayerEconomy::foundryPlace(int row, int col, const std::string& ingot) {
    const auto size = plateSize();
    if (row < 0 || col < 0 || row >= size.rows || col >= size.cols) return false;
    if (!tuning_.foundry.findIngot(ingot)) return false;
    if (foundry::at(foundry_, row, col) != nullptr) return false;
    if (foundry::unplacedCount(foundry_, ingot) <= 0) return false;
    foundry_.plate.push_back({row, col, ingot});
    return true;
}

bool PlayerEconomy::canAffordReforge() const { return hasAll(inventory, tuning_.foundry.reforgeCost); }

bool PlayerEconomy::foundryRemove(int row, int col) {
    auto it = std::find_if(foundry_.plate.begin(), foundry_.plate.end(),
                           [&](const foundry::Placement& p) { return p.row == row && p.col == col; });
    if (it == foundry_.plate.end() || !canAffordReforge()) return false;
    remove(inventory, tuning_.foundry.reforgeCost);
    foundry_.plate.erase(it);
    return true;
}

std::vector<std::string> PlayerEconomy::takeFoundryNotices() {
    std::vector<std::string> out;
    out.swap(foundryNotices_);
    return out;
}

int PlayerEconomy::currentEra() const {
    int era = 1;
    const auto& eras = tuning_.eras.eras;
    for (size_t i = 1; i < eras.size(); ++i) {
        if (!eras[i].triggerWorldEffect.empty() && !worldEffectActive(eras[i].triggerWorldEffect)) break;
        era = static_cast<int>(i) + 1;
    }
    return era;
}

const tuning::EraDef& PlayerEconomy::era() const { return tuning_.eras.eras[static_cast<size_t>(currentEra() - 1)]; }

bool PlayerEconomy::shapeUnlocked(const std::string& shapeId) const {
    const tuning::ShapeDef* shape = tuning_.construction.findShape(shapeId);
    return shape != nullptr &&
           (shape->requiresWorldEffect.empty() || worldEffectActive(shape->requiresWorldEffect));
}

bool PlayerEconomy::shapeAllowsFamily(const std::string& shapeId, const std::string& materialFamily) const {
    const tuning::ShapeDef* shape = tuning_.construction.findShape(shapeId);
    const tuning::BuildMaterialDef* material = tuning_.construction.findMaterial(materialFamily);
    return shape != nullptr && material != nullptr && tuning_.construction.shapeAllowsMaterial(*shape, *material);
}

// A placement is paid in the family's source item (timber in wood, iron
// in ingots), and only a family with the shape's traits may be used.
bool PlayerEconomy::canAffordPlacement(const std::string& shapeId, const std::string& materialFamily) const {
    const tuning::ShapeDef* shape = tuning_.construction.findShape(shapeId);
    const tuning::BuildMaterialDef* material = tuning_.construction.findMaterial(materialFamily);
    return shape != nullptr && material != nullptr && shapeUnlocked(shapeId) &&
           shapeAllowsFamily(shapeId, materialFamily) &&
           hasAll(inventory, {{material->source, shape->materialCost}});
}

bool PlayerEconomy::payPlacement(const std::string& shapeId, const std::string& materialFamily) {
    if (!canAffordPlacement(shapeId, materialFamily)) return false;
    remove(inventory, {{tuning_.construction.findMaterial(materialFamily)->source,
                        tuning_.construction.findShape(shapeId)->materialCost}});
    return true;
}

int PlayerEconomy::refundRemoval(const std::string& shapeId, const std::string& materialFamily) {
    const tuning::ShapeDef* shape = tuning_.construction.findShape(shapeId);
    const tuning::BuildMaterialDef* material = tuning_.construction.findMaterial(materialFamily);
    if (shape == nullptr || material == nullptr) return 0;
    const int refund = static_cast<int>(
        std::floor(shape->materialCost * tuning_.construction.removalRefundFraction));
    if (refund > 0) add(inventory, {{material->source, refund}});
    return refund;
}

namespace {

// A station's price list: build_cost, or upgrade_cost when it upgrades a
// station the player must already have. Null when the station is unknown,
// already available, or its prerequisite is missing.
const std::map<std::string, int>* stationCost(const PlayerEconomy& player,
                                              const tuning::Station* station) {
    if (!station || player.stationAvailable(station->id)) return nullptr;
    if (station->upgradeFrom.empty()) return &station->buildCost;
    return player.stationAvailable(station->upgradeFrom) ? &station->upgradeCost : nullptr;
}

} // namespace

bool PlayerEconomy::canBuildStation(const std::string& stationId) const {
    const std::map<std::string, int>* cost =
        stationCost(*this, tuning_.crafting.findStation(stationId));
    if (!cost) return false;
    // Cost entries name either inventory materials or currency.
    for (const auto& [id, amount] : *cost) {
        auto inInventory = inventory.find(id);
        int held = inInventory != inventory.end() ? inInventory->second : 0;
        auto inCurrency = currency.find(id);
        if (held < amount) held = inCurrency != currency.end() ? inCurrency->second : 0;
        if (held < amount) return false;
    }
    return true;
}

bool PlayerEconomy::buildStation(const std::string& stationId) {
    if (!canBuildStation(stationId)) return false;
    const std::map<std::string, int>* cost =
        stationCost(*this, tuning_.crafting.findStation(stationId));
    for (const auto& [id, amount] : *cost) {
        auto inInventory = inventory.find(id);
        if (inInventory != inventory.end() && inInventory->second >= amount)
            inInventory->second -= amount;
        else
            currency[id] -= amount;
    }

    availableStations_.push_back(stationId);
    return true;
}

PlayerEconomy::State PlayerEconomy::exportState() const {
    State state;
    state.inventory = inventory;
    state.currency = currency;
    for (const auto& [id, skill] : skills_) state.skillXp[id] = skill.xp;
    state.availableStations = availableStations_;
    state.craftCounts = craftCounts_;
    state.fulfilledOrders = fulfilledOrders_;
    state.worldEffects = worldEffects_;
    state.packItems = packItems;
    state.knownSkills = knownSkills_;
    state.skillBar = skillBar_;
    state.foundry = foundry_;
    state.skillUses = skillUses_;
    return state;
}

void PlayerEconomy::importState(const State& state) {
    foundry_ = state.foundry;
    skillUses_ = state.skillUses;
    inventory = state.inventory;
    currency = state.currency;
    skills_.clear();
    for (const auto& [id, xp] : state.skillXp) skills_[id].xp = xp;
    availableStations_ = state.availableStations;
    craftCounts_ = state.craftCounts;
    fulfilledOrders_ = state.fulfilledOrders;
    worldEffects_ = state.worldEffects;
    packItems = state.packItems;

    // Loadout: a pre-D-016 save has no skill list; start it as a fresh
    // character would. Otherwise keep what tuning still knows about.
    resetLoadout();
    if (state.knownSkills.empty()) return;
    knownSkills_.clear();
    for (const auto& id : state.knownSkills)
        if (tuning_.skills.findCombatSkill(id) && !knowsSkill(id)) knownSkills_.push_back(id);
    for (const auto& id : tuning_.skills.startingSkillIds())
        if (!knowsSkill(id)) knownSkills_.push_back(id); // a new starting skill is never lost
    skillBar_.assign(kSkillBarSize, "");
    for (size_t i = 0; i < state.skillBar.size() && i < static_cast<size_t>(kSkillBarSize); ++i)
        if (knowsSkill(state.skillBar[i])) setBarSlot(static_cast<int>(i), state.skillBar[i]);
}

bool PlayerEconomy::salvage(const std::string& recipeId) {
    const tuning::Recipe* recipe = tuning_.crafting.findRecipe(recipeId);
    if (!recipe) return false;

    // One unit of the recipe's primary output is consumed; the fraction of the
    // full input cost is scaled by that unit's share of the output batch.
    if (recipe->outputs.empty()) return false;
    const auto& [outputId, batchSize] = *recipe->outputs.begin();
    auto held = inventory.find(outputId);
    if (held == inventory.end() || held->second < 1) return false;

    inventory[outputId] -= 1;
    for (const auto& [inputId, count] : recipe->inputs) {
        double perUnit = static_cast<double>(count) / batchSize;
        inventory[inputId] +=
            static_cast<int>(std::floor(perUnit * tuning_.crafting.salvageReturnFraction));
    }
    return true;
}

} // namespace wroughtwild::economy
