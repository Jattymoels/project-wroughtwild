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
const CatalystProcess* CraftingTable::findCatalystProcess(const std::string& id) const { return findById(catalystProcesses, id); }
const ShapeDef* ConstructionTable::findShape(const std::string& id) const { return findById(shapes, id); }
const BehaviourRealtime* RealtimeTable::findBehaviour(const std::string& id) const {
    auto it = behaviours.find(id);
    return it == behaviours.end() ? nullptr : &it->second;
}
const EnemyDef* WorldTable::findEnemy(const std::string& id) const { return findById(enemies, id); }
const GatherSite* WorldTable::findSite(const std::string& id) const { return findById(gatheringSites, id); }
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
        if (auto cost = s->find("build_cost")) station.buildCost = readIntMap(*cost);
        if (auto from = s->find("upgrade_from")) station.upgradeFrom = from->asString();
        if (auto cost = s->find("upgrade_cost")) station.upgradeCost = readIntMap(*cost);
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

    if (auto processes = doc->find("catalyst_processes")) {
        for (const auto& c : processes->asArray()) {
            CatalystProcess process;
            process.id = c->get("id").asString();
            process.displayName = c->get("display_name").asString();
            process.catalyst = c->get("catalyst").asString();
            process.station = c->get("station").asString();
            process.process = c->get("process").asString();
            process.minimumSkill = readIntMap(c->get("minimum_skill"));
            process.guaranteedProperty = c->get("guaranteed_property").asString();
            process.resultTier = c->get("result_tier").asInt();
            process.minimumRollFractionAtSkill = c->get("minimum_roll_fraction_at_skill").asNumber();
            table.catalystProcesses.push_back(std::move(process));
        }
    }

    table.salvageReturnFraction = doc->get("salvage_return_fraction").asNumber();

    const Value& basic = doc->get("basic_temper");
    table.basicTemper.process = basic.get("process").asString();
    table.basicTemper.property = basic.get("property").asString();
    table.basicTemper.tier = basic.get("tier").asInt();

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

ConstructionTable loadConstruction(const std::string& path) {
    auto doc = json::parseFile(path);
    ConstructionTable table;

    table.gridSizeMetres = doc->get("grid_size_metres").asNumber();
    table.placementRangeMetres = doc->get("placement_range_metres").asNumber();
    table.removalRefundFraction = doc->get("removal_refund_fraction").asNumber();

    for (const auto& s : doc->get("shapes").asArray()) {
        ShapeDef shape;
        shape.id = s->get("id").asString();
        shape.displayName = s->get("display_name").asString();
        shape.materialCost = s->get("material_cost").asInt();
        const auto& size = s->get("size_m").asArray();
        if (size.size() != 3) throw std::runtime_error("construction: size_m needs 3 numbers");
        for (size_t i = 0; i < 3; ++i) shape.sizeM[i] = size[i]->asNumber();
        if (auto effect = s->find("requires_world_effect"))
            shape.requiresWorldEffect = effect->asString();
        table.shapes.push_back(std::move(shape));
    }
    return table;
}

RealtimeTable loadRealtime(const std::string& path) {
    auto doc = json::parseFile(path);
    RealtimeTable table;

    table.roundSeconds = doc->get("round_seconds").asNumber();

    const Value& player = doc->get("player");
    table.playerMoveSpeedMps = player.get("move_speed_mps").asNumber();
    table.playerMeleeReachM = player.get("melee_reach_m").asNumber();

    for (const auto& [id, b] : doc->get("behaviours").asObject()) {
        BehaviourRealtime behaviour;
        behaviour.moveSpeedMps = b->get("move_speed_mps").asNumber();
        behaviour.attackRangeM = b->get("attack_range_m").asNumber();
        if (auto preferred = b->find("preferred_distance_m"))
            behaviour.preferredDistanceM = preferred->asNumber();
        behaviour.aggroRangeM = b->get("aggro_range_m").asNumber();
        behaviour.windupSeconds = b->get("windup_seconds").asNumber();
        table.behaviours[id] = behaviour;
    }

    const Value& boss = doc->get("boss");
    table.boss.moveSpeedMps = boss.get("move_speed_mps").asNumber();
    table.boss.clawRangeM = boss.get("claw_range_m").asNumber();
    table.boss.clawWindupSeconds = boss.get("claw_windup_seconds").asNumber();
    table.boss.breathRangeM = boss.get("breath_range_m").asNumber();
    table.boss.breathConeDegrees = boss.get("breath_cone_degrees").asNumber();
    table.boss.breathTelegraphSeconds = boss.get("breath_telegraph_seconds").asNumber();

    const Value& dash = doc->get("skills").get("prototype_dash");
    table.dashInvulnerableSeconds = dash.get("invulnerable_seconds").asNumber();
    table.dashDurationSeconds = dash.get("duration_seconds").asNumber();
    return table;
}

WorldTable loadWorld(const std::string& path) {
    auto doc = json::parseFile(path);
    WorldTable table;

    const Value& base = doc->get("player_base");
    table.playerBase.maxLife = base.get("max_life").asNumber();
    table.playerBase.armourReductionScale = base.get("armour_reduction_scale").asNumber();
    table.playerBase.resistanceCapPercent = base.get("resistance_cap_percent").asNumber();

    for (const auto& e : doc->get("enemies").asArray()) {
        EnemyDef def;
        def.id = e->get("id").asString();
        def.displayName = e->get("display_name").asString();
        def.maxLife = e->get("max_life").asNumber();
        def.behaviour = e->get("behaviour").asString();
        def.damage = e->get("damage").asNumber();
        def.damageType = e->get("damage_type").asString();
        def.attackPeriodRounds = e->get("attack_period_rounds").asInt();
        table.enemies.push_back(std::move(def));
    }

    for (const auto& s : doc->get("gathering_sites").asArray()) {
        GatherSite site;
        site.id = s->get("id").asString();
        site.displayName = s->get("display_name").asString();
        site.yieldsPerAction = readIntMap(s->get("yields_per_action"));
        site.ambushChance = s->get("ambush_chance").asNumber();
        site.ambushEnemies = readStringArray(s->get("ambush_enemies"));
        if (auto removedBy = s->find("ambush_removed_by_world_effect"))
            site.ambushRemovedByWorldEffect = removedBy->asString();
        table.gatheringSites.push_back(std::move(site));
    }

    table.droppedInventoryRecoverable =
        doc->get("open_world_death").get("dropped_inventory_recoverable").asBool();
    return table;
}

TrialTable loadTrial(const std::string& path) {
    auto doc = json::parseFile(path);
    TrialTable table;

    const Value& boss = doc->get("boss");
    table.boss.id = boss.get("id").asString();
    table.boss.displayName = boss.get("display_name").asString();
    table.boss.maxLife = boss.get("max_life").asNumber();
    table.boss.clawDamage = boss.get("claw_damage").asNumber();
    table.boss.clawDamageType = boss.get("claw_damage_type").asString();
    table.boss.clawPeriodRounds = boss.get("claw_period_rounds").asInt();
    table.boss.breathDamage = boss.get("breath_damage").asNumber();
    table.boss.breathDamageType = boss.get("breath_damage_type").asString();
    table.boss.breathPeriodRounds = boss.get("breath_period_rounds").asInt();
    table.boss.breathTelegraphRounds = boss.get("breath_telegraph_rounds").asInt();

    for (const auto& stage : doc->get("stages").asArray()) {
        TrialStage trialStage;
        for (const auto& c : stage->get("choices").asArray()) {
            RoomChoice choice;
            choice.id = c->get("id").asString();
            choice.displayName = c->get("display_name").asString();
            choice.encounter = readStringArray(c->get("encounter"));
            choice.reward = c->get("reward").asString();
            trialStage.choices.push_back(std::move(choice));
        }
        table.stages.push_back(std::move(trialStage));
    }

    table.exitAfterStage = doc->get("exit_after_stage").asInt();

    const Value& rewards = doc->get("rewards");
    table.materialsReward = readIntMap(rewards.get("materials_reward"));
    table.catalystItem = rewards.get("catalyst_item").asString();
    table.completionUnlock = rewards.get("completion_unlock").asString();

    const Value& contract = doc->get("death_contract");
    table.keepCatalystsOnDeath = contract.get("keep_catalysts_on_death").asBool();
    table.loseRunMaterialsOnDeath = contract.get("lose_run_materials_on_death").asBool();
    return table;
}

Tuning loadAll(const std::string& tuningDirectory) {
    Tuning tuning;
    tuning.crafting = loadCrafting(tuningDirectory + "/crafting.json");
    tuning.construction = loadConstruction(tuningDirectory + "/construction.json");
    tuning.skills = loadSkills(tuningDirectory + "/skills.json");
    tuning.items = loadItems(tuningDirectory + "/items.json");
    tuning.boons = loadBoons(tuningDirectory + "/boons.json");
    tuning.world = loadWorld(tuningDirectory + "/world.json");
    tuning.trial = loadTrial(tuningDirectory + "/trial.json");
    tuning.realtime = loadRealtime(tuningDirectory + "/combat_realtime.json");
    return tuning;
}

} // namespace wroughtwild::tuning
