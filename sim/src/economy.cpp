#include "wroughtwild/economy.h"

#include <climits>
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
    const auto* cls = tuning_.foundry.rails.findClass(foundry_.chosenClass);
    knownSkills_ = cls && !cls->startingSkills.empty() ? cls->startingSkills : tuning_.skills.startingSkillIds();
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

PlayerEconomy::CraftPlan PlayerEconomy::craftPlan(const std::string& recipeId, const std::string& aimKind,
                                                 int quality, int quantity) const {
    CraftPlan plan;
    plan.quality = quality;
    const auto* recipe = tuning_.crafting.findRecipe(recipeId);
    if (!recipe || (!recipe->worldProfile.empty() && recipe->worldProfile != worldProfile)) { plan.failure.unknownRecipe = true; return plan; }
    for (const auto& [output, count] : recipe->outputs)
        if (tuning_.items.findBase(output)) plan.baseId = output;
    if (quantity < 1 || quantity > tuning_.crafting.batchMaximum || (!plan.baseId.empty() && quantity != 1)) {
        plan.failure.invalidQuantity = true; return plan;
    }
    if (!recipe->station.empty() && !stationAvailable(recipe->station)) plan.failure.stationUnavailable = true;
    if (currentEra() < recipe->minimumEra) plan.failure.qualityUnavailable = true;
    for (const auto& [skill, minimum] : recipe->minimumSkill)
        if (skillLevel(skill) < minimum) plan.failure.skillTooLow = true;
    for (const auto& [id, count] : recipe->inputs) plan.costs[id] += count * quantity;
    plan.fuel = recipe->station.empty() ? 0 : recipe->fuelCost * quantity;
    if (!plan.baseId.empty()) {
        const auto& rules = tuning_.crafting;
        if (quality < 1 || quality > static_cast<int>(rules.grades.size())) { plan.failure.qualityUnavailable = true; return plan; }
        const auto* aim = aimKind.empty() ? nullptr : rules.findKind(aimKind);
        if (!aimKind.empty() && (!aim || held(aimKind) < 1)) plan.failure.missingKind = true;
        plan.potency = aim ? aim->potency : 1;
        const int processGrade = std::max(quality, plan.potency);
        if (processGrade < 1 || processGrade > static_cast<int>(rules.grades.size())) { plan.failure.qualityUnavailable = true; return plan; }
        const auto& gate = rules.grades[static_cast<size_t>(processGrade - 1)];
        if ((!gate.station.empty() && !stationAvailable(gate.station)) || currentEra() < gate.minimumEra || skillLevel("blacksmithing") < gate.minimumSkill)
            plan.failure.qualityUnavailable = true;
        for (const auto& [id, count] : rules.grades[static_cast<size_t>(quality - 1)].reinforcement) plan.costs[id] += count;
        if (aim) {
            plan.costs[aimKind] += 1;
            const auto* base = tuning_.items.findBase(plan.baseId);
            bool compatible = false;
            for (const auto* modifier : items::eligibleModifiers(tuning_.items, *base, plan.potency))
                if (items::craftBand(*modifier, plan.potency) && std::find(modifier->tags.begin(), modifier->tags.end(), aim->craftTag) != modifier->tags.end()) compatible = true;
            if (!compatible) plan.failure.incompatibleKind = true;
        }
        std::string process = recipe->station;
        if (process == "forge_basic" && stationAvailable("forge_improved")) process = "forge_improved";
        for (const auto& profile : rules.craftProcesses)
            if (profile.station == process && currentEra() >= profile.minimumEra) {
                plan.counts = profile.counts; plan.minimumCount = aim ? profile.aimedMinimum : 0;
            }
        if (plan.counts.empty()) plan.counts = {1, 0, 0, 0, 0};
        const auto* base = tuning_.items.findBase(plan.baseId);
        const size_t poolSize = items::eligibleModifiers(tuning_.items, *base, plan.potency).size();
        plan.minimumCount = std::min(plan.minimumCount, static_cast<int>(poolSize));
        for (size_t i = poolSize + 1; i < plan.counts.size(); ++i) { plan.counts[poolSize] += plan.counts[i]; plan.counts[i] = 0; }
        plan.rollFloor = std::min(rules.rollFloorMaximum, rules.rollFloorPerLevel * std::max(0, skillLevel("blacksmithing") - 1));
    }
    int fuelAvailable = 0;
    for (const auto& [id, count] : plan.costs) if (held(id) < count) plan.failure.missingInputs = true;
    for (const auto& [id, value] : tuning_.crafting.fuels) {
        const auto input = plan.costs.find(id);
        fuelAvailable += std::max(0, held(id) - (input == plan.costs.end() ? 0 : input->second)) * value;
    }
    if (fuelAvailable < plan.fuel) plan.failure.missingFuel = true;
    return plan;
}

PlayerEconomy::CraftResult PlayerEconomy::craft(const std::string& recipeId, bool forOrder,
                                               const std::string& aimKind, int quality) {
    return craftBatch(recipeId, forOrder, aimKind, quality, 1);
}

PlayerEconomy::CraftResult PlayerEconomy::craftBatch(const std::string& recipeId, bool forOrder,
                                                    const std::string& aimKind, int quality, int quantity) {
    CraftResult result;
    const auto plan = craftPlan(recipeId, aimKind, quality, quantity);
    result.failure = plan.failure;
    if (result.failure.any()) return result;
    const auto& recipe = *tuning_.crafting.findRecipe(recipeId);
    for (const auto& [id, count] : plan.costs) take(id, count);
    std::vector<std::pair<int, std::string>> fuels;
    for (const auto& [id, value] : tuning_.crafting.fuels) fuels.push_back({value, id});
    std::sort(fuels.begin(), fuels.end());
    int needed = plan.fuel;
    for (const auto& [value, id] : fuels) while (needed > 0 && held(id) > 0) { take(id, 1); needed -= value; }
    for (int batch = 0; batch < quantity; ++batch) {
        for (const auto& [output, count] : recipe.outputs) {
            if (!tuning_.items.findBase(output)) { grant(output, count); continue; }
            for (int i = 0; i < count; ++i) {
                std::mt19937_64 rng(0xC4A1F7ull * static_cast<uint64_t>(++craftedGear_) + 17);
                std::discrete_distribution<int> pickCount(plan.counts.begin(), plan.counts.end());
                const int rolls = std::max(plan.minimumCount, pickCount(rng));
                const auto* aim = tuning_.crafting.findKind(aimKind);
                auto item = items::rollItem(tuning_.items, output, plan.potency, rolls, rng(), aim ? aim->craftTag : "");
                item.workpieceTier = quality;
                static const std::vector<std::string> names = {"plain", "worked", "keen", "refined", "wrought"};
                item.rarity = names.at(item.rolledProperties.size());
                for (auto& rolled : item.rolledProperties) {
                    const auto* def = tuning_.items.findModifier(rolled.propertyId);
                    const auto* band = items::craftBand(*def, plan.potency);
                    if (!band) throw std::runtime_error("craft modifier needs authored band: " + rolled.propertyId);
                    std::uniform_real_distribution<double> range(band->minimum + plan.rollFloor * (band->maximum - band->minimum), band->maximum);
                    rolled.value = range(rng); rolled.tier = plan.potency; rolled.crafted = true;
                }
                packItems.push_back(item);
            }
        }
        result.xpMultiplier = repetitionMultiplier(recipeId, forOrder);
        const int xp = static_cast<int>(std::floor(recipe.baseSkillXp * result.xpMultiplier));
        result.xpGranted += recipe.minimumSkill.empty() ? 0 : xp;
        for (const auto& [skill, level] : recipe.minimumSkill) grantSkillXp(skill, xp);
        if (!(forOrder && tuning_.crafting.repetitionDecay.orderCraftingIgnoresDecay)) craftCounts_[recipeId] += 1;
    }
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
        grant(rewardId, amount);
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

int PlayerEconomy::held(const std::string& id) const {
    auto inPack = inventory.find(id);
    auto inPurse = currency.find(id);
    return (inPack != inventory.end() ? inPack->second : 0) + (inPurse != currency.end() ? inPurse->second : 0);
}

void PlayerEconomy::grant(const std::string& id, int amount) {
    if (amount <= 0) return;
    if (tuning_.crafting.isCurrency(id)) currency[id] += amount;
    else inventory[id] += amount;
}

void PlayerEconomy::take(const std::string& id, int amount) {
    if (amount <= 0) return;
    if (held(id) < amount) throw std::runtime_error("economy: insufficient stock for " + id);
    // held() includes both stores. Older saves and inventory imports can carry
    // a Kind in the pack, so payment must consume the same stock it validated.
    auto& preferred = tuning_.crafting.isCurrency(id) ? currency : inventory;
    auto& other = tuning_.crafting.isCurrency(id) ? inventory : currency;
    const int first = std::min(amount, std::max(0, preferred[id]));
    preferred[id] -= first;
    if (first < amount) other[id] -= amount - first;
}

bool PlayerEconomy::canExchange(const std::string& from, const std::string& to) const {
    const auto& kinds = tuning_.crafting.exchangeKinds;
    auto listed = [&](const std::string& id) { return std::find(kinds.begin(), kinds.end(), id) != kinds.end(); };
    return from != to && listed(from) && listed(to) && held(from) >= tuning_.crafting.exchangeRate;
}

bool PlayerEconomy::exchange(const std::string& from, const std::string& to) {
    if (!canExchange(from, to)) return false;
    take(from, tuning_.crafting.exchangeRate);
    grant(to, 1);
    return true;
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
    const auto* def = tuning_.skills.findCombatSkill(skillId);
    if (!def || !knowsSkill(skillId)) return unlocked;
    ++skillUses_[skillId];
    auto& progress = skillPractice_[skillId];
    progress += def->numbers.at("cooldown_seconds") / tuning_.skills.practiceSecondsPerPoint;
    auto& earned = earnedMastery_[skillId];
    for (size_t i = earned.size(); i < def->mastery.size(); ++i) {
        if (progress + 1e-8 < def->mastery[i].uses) break;
        earned.push_back(def->mastery[i]); unlocked.push_back(def->mastery[i].text);
    }
    return unlocked;
}

int PlayerEconomy::skillUses(const std::string& skillId) const {
    auto it = skillUses_.find(skillId);
    return it == skillUses_.end() ? 0 : it->second;
}

double PlayerEconomy::skillPractice(const std::string& skillId) const {
    auto it = skillPractice_.find(skillId);
    return it == skillPractice_.end() ? 0 : it->second;
}

std::vector<const tuning::MasteryPerk*> PlayerEconomy::masteryUnlocked(const std::string& skillId) const {
    std::vector<const tuning::MasteryPerk*> out;
    auto it = earnedMastery_.find(skillId);
    if (it != earnedMastery_.end()) for (const auto& perk : it->second) out.push_back(&perk);
    return out;
}

foundry::Plate PlayerEconomy::plate() const { return foundry::plate(tuning_.foundry, currentEra()); }

std::vector<std::string> PlayerEconomy::foundryEvent(const std::string& event) {
    std::vector<std::string> granted;
    const int era = currentEra();
    // Every kill is reported as its family's first_kill event; the kills
    // count toward the manners the family teaches (D-023 slice 9), and a
    // manner just taught is announced.
    static const std::string kKill = "first_kill:";
    if (event.rfind(kKill, 0) == 0) {
        const auto before = foundry::knownPatterns(tuning_, foundry_);
        foundry_.kills[event.substr(kKill.size())] += 1;
        for (const auto& id : foundry::knownPatterns(tuning_, foundry_))
            if (std::find(before.begin(), before.end(), id) == before.end()) foundryNotices_.push_back("manner:" + id);
    }
    for (const auto& source : tuning_.foundry.sources) {
        if (source.event != event || source.era > era) continue;
        if (std::find(foundry_.milestones.begin(), foundry_.milestones.end(), source.id) != foundry_.milestones.end())
            continue;
        foundry_.milestones.push_back(source.id);
        foundry_.owned[source.ingot] += 1;
        // The metal it is cast in (slice 10): the default, the era's alloy, or as named.
        const std::string metal = source.metal == "alloy" ? tuning_.foundry.alloyForEra(era)
                                  : source.metal.empty() ? tuning_.foundry.defaultMetal()
                                                         : source.metal;
        if (!metal.empty()) foundry_.metals[source.ingot][metal] += 1;
        granted.push_back(source.ingot);
    }
    return granted;
}

bool PlayerEconomy::foundryPlace(int row, int col, const std::string& ingot, const std::string& metal) {
    const auto plate = this->plate();
    if (!plate.forged(row, col) || plate.isSocket(row, col)) return false;
    if (!tuning_.foundry.findIngot(ingot)) return false;
    if (foundry::at(foundry_, row, col) != nullptr) return false;
    if (foundry::unplacedCount(foundry_, ingot) <= 0) return false;
    const auto& def = tuning_.foundry;
    std::string cast = metal;
    if (cast.empty()) {
        // The widest-reaching casting in hand; an untuned plate has no metals.
        for (auto m = def.metals.rbegin(); m != def.metals.rend(); ++m)
            if (foundry::unplacedCountOf(def, foundry_, ingot, m->id) > 0) {
                cast = m->id;
                break;
            }
        if (cast.empty() && !def.metals.empty()) return false;
    } else if (!def.findMetal(cast) || foundry::unplacedCountOf(def, foundry_, ingot, cast) <= 0) {
        return false;
    }
    foundry::Placement piece;
    piece.row = row;
    piece.col = col;
    piece.ingot = ingot;
    piece.metal = cast;
    foundry_.plate.push_back(piece);
    return true;
}

namespace {
// The narrowest-reaching casting of an ingot in hand below `reach`, or "".
std::string narrowestInHand(const tuning::FoundryDef& def, const foundry::State& state, const std::string& ingot, int reach) {
    for (const auto& m : def.metals)
        if (m.reach < reach && foundry::unplacedCountOf(def, state, ingot, m.id) > 0) return m.id;
    return std::string();
}
} // namespace

bool PlayerEconomy::canRecast(const std::string& ingot, const std::string& metal) const {
    const auto& def = tuning_.foundry;
    const auto* target = def.findMetal(metal);
    if (!target || target->recastCost.empty() || target->era > currentEra()) return false;
    if (!def.findIngot(ingot)) return false;
    if (!def.recastStation.empty() && !stationAvailable(def.recastStation)) return false;
    if (narrowestInHand(def, foundry_, ingot, target->reach).empty()) return false;
    return hasAll(inventory, target->recastCost);
}

bool PlayerEconomy::foundryRecast(const std::string& ingot, const std::string& metal) {
    if (!canRecast(ingot, metal)) return false;
    const auto& def = tuning_.foundry;
    const auto* target = def.findMetal(metal);
    const std::string from = narrowestInHand(def, foundry_, ingot, target->reach);
    remove(inventory, target->recastCost);
    auto& counts = foundry_.metals[ingot];
    if (--counts[from] <= 0) counts.erase(from);
    counts[metal] += 1;
    return true;
}

bool PlayerEconomy::canAffordReforge() const { return hasAll(inventory, tuning_.foundry.reforgeCost); }

bool PlayerEconomy::foundryPlaceSkill(int row, int col, const std::string& skillId) {
    const auto plate = this->plate();
    if (!plate.forged(row, col) || !plate.isSocket(row, col)) return false;
    if (std::find(knownSkills_.begin(), knownSkills_.end(), skillId) == knownSkills_.end()) return false;
    if (foundry::at(foundry_, row, col) != nullptr) return false;
    if (foundry::tabletFor(foundry_, skillId) != nullptr) return false;
    foundry::Placement tablet;
    tablet.row = row;
    tablet.col = col;
    tablet.skill = skillId;
    foundry_.plate.push_back(tablet);
    return true;
}

bool PlayerEconomy::foundryPlaceKind(int row, int col, const std::string& kind) {
    const auto plate = this->plate();
    if (!foundry::kindMayRest(plate, row, col)) return false;
    if (!tuning_.foundry.findKindOnPlate(kind)) return false;
    if (foundry::at(foundry_, row, col) != nullptr) return false;
    if (held(kind) < 1) return false;
    take(kind, 1);
    foundry::Placement piece;
    piece.row = row;
    piece.col = col;
    piece.currency = kind;
    foundry_.plate.push_back(piece);
    return true;
}

// Lifting an ingot or a kind re-forges it (metal); lifting a tablet is
// free - a tablet is knowledge, not metal. A kind returns to the purse.
bool PlayerEconomy::foundryRemove(int row, int col) {
    auto it = std::find_if(foundry_.plate.begin(), foundry_.plate.end(),
                           [&](const foundry::Placement& p) { return p.row == row && p.col == col; });
    if (it == foundry_.plate.end()) return false;
    if (!it->isTablet()) {
        if (!canAffordReforge()) return false;
        remove(inventory, tuning_.foundry.reforgeCost);
    }
    if (it->isCurrency()) grant(it->currency, 1);
    foundry_.plate.erase(it);
    return true;
}

bool PlayerEconomy::canChooseClass() const {
    return foundry_.chosenClass.empty() && !tuning_.foundry.rails.classes.empty();
}

bool PlayerEconomy::foundryChooseClass(const std::string& classId) {
    const auto* cls = tuning_.foundry.rails.findClass(classId);
    if (!canChooseClass() || !cls) return false;
    foundry_.chosenClass = classId;
    // The class's kit (owner, 4 Sep 2026: "more initial skills, not frost
    // orb - a bow shot, or a strike for a Warden"): it replaces the base
    // starting skills and fills the bar in its order; what pages taught
    // stays known; a tablet laid for a skill no longer known lifts free.
    if (cls->startingSkills.empty()) return true;
    const auto base = tuning_.skills.startingSkillIds();
    std::vector<std::string> kept;
    for (const auto& id : knownSkills_) {
        const bool inBase = std::find(base.begin(), base.end(), id) != base.end();
        const bool inKit = std::find(cls->startingSkills.begin(), cls->startingSkills.end(), id) != cls->startingSkills.end();
        if (!inBase && !inKit) kept.push_back(id);
    }
    knownSkills_ = cls->startingSkills;
    for (const auto& id : kept) knownSkills_.push_back(id);
    skillBar_.assign(kSkillBarSize, "");
    for (size_t i = 0; i < cls->startingSkills.size() && i < static_cast<size_t>(kSkillBarSize); ++i)
        skillBar_[i] = cls->startingSkills[i];
    foundry_.plate.erase(std::remove_if(foundry_.plate.begin(), foundry_.plate.end(),
                                        [&](const foundry::Placement& p) { return p.isTablet() && !knowsSkill(p.skill); }),
                         foundry_.plate.end());
    return true;
}

bool PlayerEconomy::canSpecialise() const {
    const auto& rails = tuning_.foundry.rails;
    const auto* cls = rails.findClass(foundry_.chosenClass);
    return cls && !cls->specialisations.empty() && foundry_.specialisation.empty() &&
           (rails.specialiseOnWorldEffect.empty() || worldEffectActive(rails.specialiseOnWorldEffect));
}

bool PlayerEconomy::foundrySpecialise(const std::string& specialisation) {
    if (!canSpecialise()) return false;
    const auto* spec = tuning_.foundry.rails.findSpecialisation(specialisation);
    if (!spec || spec->classId != foundry_.chosenClass) return false;
    foundry_.specialisation = specialisation;
    // A rail holding a pattern that becomes something becomes it too.
    for (auto& rail : foundry_.rails) {
        const auto it = spec->becomes.find(rail.pattern);
        if (it != spec->becomes.end()) rail.pattern = it->second;
    }
    return true;
}

int PlayerEconomy::railsAllowed() const { return tuning_.foundry.rails.allowed(currentEra()); }

std::vector<std::string> PlayerEconomy::foundryPatterns() const { return foundry::knownPatterns(tuning_, foundry_); }

bool PlayerEconomy::foundrySetRail(const std::string& axis, int index, const std::string& pattern) {
    const auto* def = tuning_.foundry.rails.findPattern(pattern);
    if (!def || def->axis != axis) return false;
    if (!foundry::patternKnown(tuning_, foundry_, pattern)) return false;
    if (foundry::lineCells(plate(), axis, index).empty()) return false;
    for (const auto& r : foundry_.rails)
        if (r.pattern == pattern && !(r.axis == axis && r.index == index)) return false; // one rail per pattern
    auto it = std::find_if(foundry_.rails.begin(), foundry_.rails.end(),
                           [&](const foundry::Rail& r) { return r.axis == axis && r.index == index; });
    if (it != foundry_.rails.end()) {
        it->pattern = pattern; // a set rail takes the new pattern
        return true;
    }
    if (static_cast<int>(foundry_.rails.size()) >= railsAllowed()) return false;
    foundry_.rails.push_back({axis, index, pattern});
    return true;
}

bool PlayerEconomy::foundryClearRail(const std::string& axis, int index) {
    auto it = std::find_if(foundry_.rails.begin(), foundry_.rails.end(),
                           [&](const foundry::Rail& r) { return r.axis == axis && r.index == index; });
    if (it == foundry_.rails.end()) return false;
    foundry_.rails.erase(it);
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

void PlayerEconomy::advanceTime(double seconds) {
    if (seconds > 0.0) dayClock_ += seconds;
}

void PlayerEconomy::setDayClock(double seconds) { dayClock_ = seconds > 0.0 ? seconds : 0.0; }

int PlayerEconomy::carryCap(const std::string& family) const {
    if (tuning_.items.findBase(family) != nullptr) return 0;
    auto it = tuning_.world.hauling.carryCap.find(family);
    if (it != tuning_.world.hauling.carryCap.end()) return it->second;
    return tuning_.world.hauling.carryCapDefault;
}

int PlayerEconomy::carryRoom(const std::string& family) const {
    const int cap = carryCap(family);
    if (cap <= 0) return INT_MAX;
    auto it = inventory.find(family);
    const int held = it == inventory.end() ? 0 : it->second;
    return std::max(0, cap - held);
}

int PlayerEconomy::haul(const std::string& family, int count) {
    const int taken = std::min(count, carryRoom(family));
    if (taken <= 0) return 0;
    inventory[family] += taken;
    return taken;
}

int PlayerEconomy::storeUnits(const std::string& key) const {
    auto it = stores_.find(key);
    if (it == stores_.end()) return 0;
    int total = 0;
    for (const auto& [family, count] : it->second) total += count;
    return total;
}

int PlayerEconomy::storeRoom(const std::string& key) const {
    return std::max(0, tuning_.world.hauling.chestUnits - storeUnits(key));
}

int PlayerEconomy::storeDeposit(const std::string& key, const std::string& family, int count) {
    auto held = inventory.find(family);
    if (held == inventory.end()) return 0;
    const int moved = std::min({count, held->second, storeRoom(key)});
    if (moved <= 0) return 0;
    held->second -= moved;
    if (held->second == 0) inventory.erase(held);
    stores_[key][family] += moved;
    return moved;
}

int PlayerEconomy::storeWithdraw(const std::string& key, const std::string& family, int count) {
    auto store = stores_.find(key);
    if (store == stores_.end()) return 0;
    auto it = store->second.find(family);
    if (it == store->second.end()) return 0;
    const int moved = std::min({count, it->second, carryRoom(family)});
    if (moved <= 0) return 0;
    it->second -= moved;
    if (it->second == 0) store->second.erase(it);
    if (store->second.empty()) stores_.erase(store);
    inventory[family] += moved;
    return moved;
}

const Inventory& PlayerEconomy::storeContents(const std::string& key) const {
    static const Inventory empty;
    auto it = stores_.find(key);
    return it == stores_.end() ? empty : it->second;
}

bool PlayerEconomy::setCurio(const std::string& landmarkId) {
    const auto* curio = tuning_.trial.curioForLandmark(landmarkId);
    if (!curio || !curioHeld(curio->id)) return false;
    remove(inventory, {{curio->id, 1}});
    recordWorldEffect(curio->unlock);
    return true;
}

std::string PlayerEconomy::landmarkWants(const std::string& landmarkId) const {
    const auto* curio = tuning_.trial.curioForLandmark(landmarkId);
    return curio ? curio->id : std::string();
}

bool PlayerEconomy::curioHeld(const std::string& curioId) const {
    auto it = inventory.find(curioId);
    return it != inventory.end() && it->second > 0;
}

std::vector<std::string> PlayerEconomy::curioHints() const {
    std::vector<std::string> out;
    for (const auto& curio : tuning_.trial.curios)
        if (curioHeld(curio.id)) out.push_back(curio.displayName + ": " + curio.reading);
    return out;
}

Inventory PlayerEconomy::storeRemove(const std::string& key) {
    auto it = stores_.find(key);
    if (it == stores_.end()) return {};
    Inventory out = std::move(it->second);
    stores_.erase(it);
    return out;
}

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
    state.skillPractice = skillPractice_; state.earnedMastery = earnedMastery_; state.craftedGear = craftedGear_;
    state.dayClock = dayClock_;
    state.stores = stores_;
    return state;
}

void PlayerEconomy::importState(const State& state) {
    foundry_ = state.foundry;
    skillUses_ = state.skillUses;
    skillPractice_ = state.skillPractice; earnedMastery_ = state.earnedMastery;
    craftedGear_ = state.craftedGear;
    if (state.masteryVersion == 0) {
        for (const auto& def : tuning_.skills.combatSkills) {
            const int oldUses = skillUses(def.id);
            if (oldUses <= 0) continue;
            auto& earned = earnedMastery_[def.id];
            for (size_t i = 0; i < def.legacyMastery.size(); ++i) {
                if (oldUses < def.legacyMastery[i].uses) break;
                auto perk = def.legacyMastery[i];
                perk.uses = i < def.mastery.size() ? def.mastery[i].uses : perk.uses;
                earned.push_back(perk);
            }
            // Carry unearned effort forward, without awarding another legacy perk.
            double progress = oldUses * def.numbers.at("cooldown_seconds") / tuning_.skills.practiceSecondsPerPoint;
            if (!earned.empty()) progress = std::max(progress, static_cast<double>(earned.back().uses));
            if (earned.size() < def.mastery.size()) progress = std::min(progress, def.mastery[earned.size()].uses - 0.001);
            skillPractice_[def.id] = progress;
        }
    }
    dayClock_ = state.dayClock > 0.0 ? state.dayClock : 0.0;
    stores_ = state.stores;
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
    const auto startingKit = knownSkills_;
    knownSkills_.clear();
    for (const auto& id : state.knownSkills)
        if (tuning_.skills.findCombatSkill(id) && !knowsSkill(id)) knownSkills_.push_back(id);
    for (const auto& id : startingKit)
        if (!knowsSkill(id)) knownSkills_.push_back(id); // a new starting skill is never lost
    skillBar_.assign(kSkillBarSize, "");
    for (size_t i = 0; i < state.skillBar.size() && i < static_cast<size_t>(kSkillBarSize); ++i)
        if (knowsSkill(state.skillBar[i])) setBarSlot(static_cast<int>(i), state.skillBar[i]);

    // The plate holds only what the era has forged (D-023): a save from an
    // older plate, or a hand-edited one, is lifted free of anything the
    // frame cannot hold. Nothing is lost: ingots return to the tray.
    // What the frame cannot hold is lifted; a kind lifted goes back to the purse.
    std::vector<foundry::Placement> lifted;
    foundry::validate(foundry_, plate(), &lifted);
    for (const auto& p : lifted)
        if (p.isCurrency()) grant(p.currency, 1);
    // The metals (slice 10): an older save is all iron; a doctored one is
    // brought back to what is owned.
    foundry::normaliseMetals(tuning_.foundry, foundry_);
    // The surround: a class or specialisation tuning no longer knows (or
    // a specialisation of another class) is forgotten, and every rail the
    // state cannot hold is dropped (D-023 slice 9).
    const auto* cls = tuning_.foundry.rails.findClass(foundry_.chosenClass);
    if (!cls) foundry_.chosenClass.clear();
    const auto* spec = tuning_.foundry.rails.findSpecialisation(foundry_.specialisation);
    if (!cls || !spec || spec->classId != cls->id) foundry_.specialisation.clear();
    foundry::validateRails(tuning_, foundry_, plate(), railsAllowed());
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
