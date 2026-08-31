#include "wroughtwild/tuning.h"

#include "wroughtwild/json.h"

namespace wroughtwild::tuning {

namespace {

using json::Value;

std::vector<std::string> readStringArray(const Value& v) {
    std::vector<std::string> out;
    for (const auto& item : v.asArray()) out.push_back(item->asString());
    return out;
}

std::map<std::string, int> readIntMap(const Value& v) {
    std::map<std::string, int> out;
    for (const auto& [key, value] : v.asObject()) out[key] = value->asInt();
    return out;
}

std::map<std::string, double> readNumberMap(const Value& v) {
    std::map<std::string, double> out;
    for (const auto& [key, value] : v.asObject()) out[key] = value->asNumber();
    return out;
}

std::vector<BoonEffect> readEffects(const Value& v) {
    std::vector<BoonEffect> effects;
    for (const auto& item : v.asArray()) {
        BoonEffect effect;
        for (const auto& [key, value] : item->asObject()) {
            if (key == "operation") effect.operation = value->asString();
            else effect.parameters[key] = value->asNumber();
        }
        effects.push_back(std::move(effect));
    }
    return effects;
}

template <typename T>
const T* findById(const std::vector<T>& list, const std::string& id) {
    for (const auto& entry : list)
        if (entry.id == id) return &entry;
    return nullptr;
}

} // namespace

const Station* CraftingTable::findStation(const std::string& id) const { return findById(stations, id); }
const Recipe* CraftingTable::findRecipe(const std::string& id) const { return findById(recipes, id); }
const Order* CraftingTable::findOrder(const std::string& id) const { return findById(orders, id); }
const CraftSkillDef* SkillTable::findCraftSkill(const std::string& id) const { return findById(craftSkills, id); }
const ItemBase* ItemTable::findBase(const std::string& id) const { return findById(itemBases, id); }
const BoonDef* BoonTable::findBoon(const std::string& id) const { return findById(boons, id); }

CraftingTable loadCrafting(const std::string& path) {
    auto doc = json::parseFile(path);
    CraftingTable table;

    for (const auto& s : doc->get("stations").asArray()) {
        Station station;
        station.id = s->get("id").asString();
        station.displayName = s->get("display_name").asString();
        station.tier = s->get("tier").asInt();
        station.supportedProcesses = readStringArray(s->get("supported_processes"));
        table.stations.push_back(std::move(station));
    }

    for (const auto& r : doc->get("recipes").asArray()) {
        Recipe recipe;
        recipe.id = r->get("id").asString();
        recipe.displayName = r->get("display_name").asString();
        recipe.station = r->get("station").asString();
        recipe.minimumSkill = readIntMap(r->get("minimum_skill"));
        recipe.inputs = readIntMap(r->get("inputs"));
        recipe.outputs = readIntMap(r->get("outputs"));
        recipe.baseSkillXp = r->get("base_skill_xp").asInt();
        recipe.useCategories = readStringArray(r->get("use_categories"));
        table.recipes.push_back(std::move(recipe));
    }

    for (const auto& o : doc->get("orders").asArray()) {
        Order order;
        order.id = o->get("id").asString();
        order.displayName = o->get("display_name").asString();
        order.requiredOutputs = readIntMap(o->get("required_outputs"));
        order.rewards = readIntMap(o->get("rewards"));
        order.worldEffect = o->get("world_effect").asString();
        table.orders.push_back(std::move(order));
    }

    table.salvageReturnFraction = doc->get("salvage_return_fraction").asNumber();

    const Value& decay = doc->get("repetition_decay");
    table.repetitionDecay.enabled = decay.get("enabled").asBool();
    table.repetitionDecay.fullXpRepetitions = decay.get("full_xp_repetitions").asInt();
    table.repetitionDecay.minimumMultiplier = decay.get("minimum_multiplier").asNumber();
    table.repetitionDecay.orderCraftingIgnoresDecay = decay.get("order_crafting_ignores_decay").asBool();

    return table;
}

SkillTable loadSkills(const std::string& path) {
    auto doc = json::parseFile(path);
    SkillTable table;

    for (const auto& s : doc->get("craft_skills").asArray()) {
        CraftSkillDef def;
        def.id = s->get("id").asString();
        def.displayName = s->get("display_name").asString();
        def.maximumPrototypeLevel = s->get("maximum_prototype_level").asInt();
        for (const auto& xp : s->get("xp_required_by_level").asArray())
            def.xpRequiredByLevel.push_back(xp->asInt());
        table.craftSkills.push_back(std::move(def));
    }

    for (const auto& s : doc->get("combat_skills").asArray()) {
        CombatSkillDef def;
        for (const auto& [key, value] : s->asObject()) {
            if (key == "id") def.id = value->asString();
            else if (key == "display_name") def.displayName = value->asString();
            else if (key == "tags") def.tags = readStringArray(*value);
            else def.numbers[key] = value->asNumber();
        }
        table.combatSkills.push_back(std::move(def));
    }

    return table;
}

ItemTable loadItems(const std::string& path) {
    auto doc = json::parseFile(path);
    ItemTable table;

    for (const auto& p : doc->get("property_definitions").asArray()) {
        PropertyDef def;
        def.id = p->get("id").asString();
        def.displayName = p->get("display_name").asString();
        def.tags = readStringArray(p->get("tags"));
        for (const auto& t : p->get("tiers").asArray()) {
            PropertyTier tier;
            tier.tier = t->get("tier").asInt();
            tier.minimum = t->get("minimum").asNumber();
            tier.maximum = t->get("maximum").asNumber();
            def.tiers.push_back(tier);
        }
        table.propertyDefinitions.push_back(std::move(def));
    }

    for (const auto& b : doc->get("item_bases").asArray()) {
        ItemBase base;
        base.id = b->get("id").asString();
        base.displayName = b->get("display_name").asString();
        base.material = b->get("material").asString();
        base.implicitProperties = readNumberMap(b->get("implicit_properties"));
        base.allowedPropertyTags = readStringArray(b->get("allowed_property_tags"));
        table.itemBases.push_back(std::move(base));
    }

    return table;
}

BoonTable loadBoons(const std::string& path) {
    auto doc = json::parseFile(path);
    BoonTable table;

    for (const auto& b : doc->get("boons").asArray()) {
        BoonDef def;
        def.id = b->get("id").asString();
        def.displayName = b->get("display_name").asString();
        if (auto tags = b->find("requires_any_tags")) def.requiresAnyTags = readStringArray(*tags);
        if (auto weakness = b->find("requires_weakness")) def.requiresWeakness = weakness->asString();
        def.effects = readEffects(b->get("effects"));
        if (auto purpose = b->find("design_purpose")) def.designPurpose = purpose->asString();
        table.boons.push_back(std::move(def));
    }

    for (const auto& w : doc->get("weaknesses").asArray()) {
        WeaknessDef def;
        def.id = w->get("id").asString();
        def.displayName = w->get("display_name").asString();
        def.effects = readEffects(w->get("effects"));
        def.baseRewardMultiplier = w->get("base_reward_multiplier").asNumber();
        table.weaknesses.push_back(std::move(def));
    }

    const auto& rules = doc->get("offer_rules");
    table.offerRules.optionsPerOffer = rules.get("options_per_offer").asInt();
    table.offerRules.allowIncompatibleOptions = rules.get("allow_incompatible_options").asBool();
    table.offerRules.minimumUnweightedOptionCount = rules.get("minimum_unweighted_option_count").asInt();

    return table;
}

Tuning loadAll(const std::string& tuningDirectory) {
    Tuning tuning;
    tuning.crafting = loadCrafting(tuningDirectory + "/crafting.json");
    tuning.skills = loadSkills(tuningDirectory + "/skills.json");
    tuning.items = loadItems(tuningDirectory + "/items.json");
    tuning.boons = loadBoons(tuningDirectory + "/boons.json");
    return tuning;
}

} // namespace wroughtwild::tuning
