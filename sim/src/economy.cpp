#include "wroughtwild/economy.h"

#include <algorithm>
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

PlayerEconomy::CraftResult PlayerEconomy::craft(const std::string& recipeId, bool forOrder) {
    CraftResult result;
    const tuning::Recipe* recipe = tuning_.crafting.findRecipe(recipeId);
    if (!recipe) {
        result.failure.unknownRecipe = true;
        return result;
    }
    if (!stationAvailable(recipe->station)) result.failure.stationUnavailable = true;
    for (const auto& [skillId, level] : recipe->minimumSkill)
        if (skillLevel(skillId) < level) result.failure.skillTooLow = true;
    if (!hasAll(inventory, recipe->inputs)) result.failure.missingInputs = true;
    if (result.failure.any()) return result;

    remove(inventory, recipe->inputs);
    add(inventory, recipe->outputs);

    result.xpMultiplier = repetitionMultiplier(recipeId, forOrder);
    result.xpGranted = static_cast<int>(std::floor(recipe->baseSkillXp * result.xpMultiplier));
    for (const auto& [skillId, level] : recipe->minimumSkill)
        grantSkillXp(skillId, result.xpGranted);

    if (!(forOrder && tuning_.crafting.repetitionDecay.orderCraftingIgnoresDecay))
        craftCounts_[recipeId] += 1;

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
    worldEffects_.push_back(order->worldEffect);
    result.fulfilled = true;
    result.worldEffect = order->worldEffect;
    return result;
}

bool PlayerEconomy::worldEffectActive(const std::string& effect) const {
    return std::find(worldEffects_.begin(), worldEffects_.end(), effect) != worldEffects_.end();
}

void PlayerEconomy::recordWorldEffect(const std::string& effect) {
    if (!worldEffectActive(effect)) worldEffects_.push_back(effect);
}

bool PlayerEconomy::canAffordPlacement(const std::string& shapeId, const std::string& materialFamily) const {
    const tuning::ShapeDef* shape = tuning_.construction.findShape(shapeId);
    return shape != nullptr && hasAll(inventory, {{materialFamily, shape->materialCost}});
}

bool PlayerEconomy::payPlacement(const std::string& shapeId, const std::string& materialFamily) {
    if (!canAffordPlacement(shapeId, materialFamily)) return false;
    remove(inventory, {{materialFamily, tuning_.construction.findShape(shapeId)->materialCost}});
    return true;
}

int PlayerEconomy::refundRemoval(const std::string& shapeId, const std::string& materialFamily) {
    const tuning::ShapeDef* shape = tuning_.construction.findShape(shapeId);
    if (shape == nullptr) return 0;
    const int refund = static_cast<int>(
        std::floor(shape->materialCost * tuning_.construction.removalRefundFraction));
    if (refund > 0) add(inventory, {{materialFamily, refund}});
    return refund;
}

bool PlayerEconomy::buildStation(const std::string& stationId) {
    const tuning::Station* station = tuning_.crafting.findStation(stationId);
    if (!station || stationAvailable(stationId)) return false;

    const std::map<std::string, int>* cost = &station->buildCost;
    if (!station->upgradeFrom.empty()) {
        if (!stationAvailable(station->upgradeFrom)) return false;
        cost = &station->upgradeCost;
    }

    // Cost entries name either inventory materials or currency; verify both
    // sides before paying anything.
    for (const auto& [id, amount] : *cost) {
        auto inInventory = inventory.find(id);
        int held = inInventory != inventory.end() ? inInventory->second : 0;
        auto inCurrency = currency.find(id);
        if (held < amount) held = inCurrency != currency.end() ? inCurrency->second : 0;
        if (held < amount) return false;
    }
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
    return state;
}

void PlayerEconomy::importState(const State& state) {
    inventory = state.inventory;
    currency = state.currency;
    skills_.clear();
    for (const auto& [id, xp] : state.skillXp) skills_[id].xp = xp;
    availableStations_ = state.availableStations;
    craftCounts_ = state.craftCounts;
    fulfilledOrders_ = state.fulfilledOrders;
    worldEffects_ = state.worldEffects;
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
