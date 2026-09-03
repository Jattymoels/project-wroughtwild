#include "wroughtwild/tuning.h"

#include <algorithm>

#include "wroughtwild/json.h"
#include "wroughtwild/lattice.h"

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
bool CraftingTable::isCurrency(const std::string& id) const {
    return std::find(currencies.begin(), currencies.end(), id) != currencies.end();
}
const Station* CraftingTable::findStationForKit(const std::string& kitItemId) const {
    if (kitItemId.empty()) return nullptr;
    for (const auto& station : stations)
        if (station.kitItem == kitItemId) return &station;
    return nullptr;
}
const BiomeDef* WorldgenTable::findBiome(const std::string& id) const { return findById(biomes, id); }
double WorldgenTable::dangerMultiplierAt(double distanceM) const {
    const DangerRing* ring = dangerRingAt(distanceM);
    return ring ? ring->packDensityMultiplier : 1.0;
}
const DangerRing* WorldgenTable::dangerRingAt(double distanceM) const {
    for (const auto& ring : dangerRings)
        if (distanceM <= ring.radiusM) return &ring;
    return dangerRings.empty() ? nullptr : &dangerRings.back();
}
const ModifierDef* ItemTable::findModifier(const std::string& id) const { return findById(modifiers, id); }
const RarityDef* ItemTable::findRarity(const std::string& id) const { return findById(rarities, id); }
bool ModifierDef::isSelf() const {
    return appliesToTags.size() == 1 && appliesToTags.front() == "self";
}
const ModifierTier* ModifierDef::findTier(int tier) const {
    for (const auto& t : tiers)
        if (t.tier == tier) return &t;
    return nullptr;
}
const ShapeDef* ConstructionTable::findShape(const std::string& id) const { return findById(shapes, id); }
const BuildMaterialDef* ConstructionTable::findMaterial(const std::string& id) const { return findById(materials, id); }
bool BuildMaterialDef::hasTrait(const std::string& trait) const {
    return std::find(traits.begin(), traits.end(), trait) != traits.end();
}
bool ConstructionTable::shapeAllowsMaterial(const ShapeDef& shape, const BuildMaterialDef& material) const {
    for (const auto& trait : shape.requiresTraits)
        if (!material.hasTrait(trait)) return false;
    return true;
}
const BehaviourRealtime* RealtimeTable::findBehaviour(const std::string& id) const {
    auto it = behaviours.find(id);
    return it == behaviours.end() ? nullptr : &it->second;
}
const EnemyDef* WorldTable::findEnemy(const std::string& id) const { return findById(enemies, id); }
const EliteModifierDef* WorldTable::findEliteModifier(const std::string& id) const {
    return findById(eliteModifiers, id);
}
const GatherSite* WorldTable::findSite(const std::string& id) const { return findById(gatheringSites, id); }
const CraftSkillDef* SkillTable::findCraftSkill(const std::string& id) const { return findById(craftSkills, id); }
const CombatSkillDef* SkillTable::findCombatSkill(const std::string& id) const { return findById(combatSkills, id); }
std::vector<std::string> SkillTable::startingSkillIds() const {
    std::vector<std::string> ids;
    for (const auto& def : combatSkills)
        if (def.starting) ids.push_back(def.id);
    return ids;
}
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
        if (auto kit = s->find("kit_item")) station.kitItem = kit->asString();
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
        if (auto fuel = r->find("fuel_cost")) recipe.fuelCost = fuel->asInt();
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

    if (auto currencies = doc->find("currencies"))
        table.currencies = readStringArray(*currencies);

    if (auto fuels = doc->find("fuels")) {
        for (const auto& [item, value] : fuels->asObject())
            if (item != "design_purpose") table.fuels[item] = value->asInt();
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

    static const std::vector<std::string> deliveries = {"cone", "strike", "projectile", "dash"};
    for (const auto& s : doc->get("combat_skills").asArray()) {
        CombatSkillDef def;
        for (const auto& [key, value] : s->asObject()) {
            if (key == "id") def.id = value->asString();
            else if (key == "display_name") def.displayName = value->asString();
            else if (key == "delivery") def.delivery = value->asString();
            else if (key == "tags") def.tags = readStringArray(*value);
            else if (key == "starting") def.starting = value->asBool();
            else if (key == "drop_weight") def.dropWeight = value->asNumber();
            else if (key == "design_purpose") continue;
            else def.numbers[key] = value->asNumber();
        }
        if (std::find(deliveries.begin(), deliveries.end(), def.delivery) == deliveries.end())
            throw std::runtime_error("skills: combat skill " + def.id + " has unknown delivery " + def.delivery);
        if (def.dropWeight < 0.0)
            throw std::runtime_error("skills: combat skill " + def.id + " drop_weight must not be negative");
        table.combatSkills.push_back(std::move(def));
    }
    if (table.startingSkillIds().empty())
        throw std::runtime_error("skills: at least one combat skill must be starting");

    return table;
}

ItemTable loadItems(const std::string& path) {
    auto doc = json::parseFile(path);
    ItemTable table;

    table.slots = readStringArray(doc->get("slots"));

    for (const auto& r : doc->get("rarities").asArray()) {
        RarityDef rarity;
        rarity.id = r->get("id").asString();
        rarity.displayName = r->get("display_name").asString();
        rarity.modifiersMin = r->get("modifiers_min").asInt();
        rarity.modifiersMax = r->get("modifiers_max").asInt();
        if (rarity.modifiersMax < rarity.modifiersMin)
            throw std::runtime_error("items: rarity " + rarity.id + " has max below min");
        table.rarities.push_back(std::move(rarity));
    }

    for (const auto& m : doc->get("modifiers").asArray()) {
        ModifierDef def;
        def.id = m->get("id").asString();
        def.displayName = m->get("display_name").asString();
        def.tags = readStringArray(m->get("tags"));
        def.appliesToTags = readStringArray(m->get("applies_to"));
        def.effectKey = m->get("effect").asString();
        if (def.effectKey.rfind("add_", 0) != 0 && def.effectKey.rfind("increased_", 0) != 0 &&
            def.effectKey.rfind("more_", 0) != 0)
            throw std::runtime_error("items: modifier " + def.id + " effect must start with add_, increased_ or more_");
        if (auto display = m->find("display")) def.display = display->asString();
        if (auto weight = m->find("weight")) def.weight = weight->asNumber();
        if (auto purpose = m->find("design_purpose")) def.designPurpose = purpose->asString();
        for (const auto& t : m->get("tiers").asArray()) {
            ModifierTier tier;
            tier.tier = t->get("tier").asInt();
            tier.minimum = t->get("minimum").asNumber();
            tier.maximum = t->get("maximum").asNumber();
            def.tiers.push_back(tier);
        }
        if (def.tiers.empty()) throw std::runtime_error("items: modifier " + def.id + " needs tiers");
        table.modifiers.push_back(std::move(def));
    }

    for (const auto& b : doc->get("item_bases").asArray()) {
        ItemBase base;
        base.id = b->get("id").asString();
        base.displayName = b->get("display_name").asString();
        base.material = b->get("material").asString();
        if (auto slot = b->find("slot")) base.slot = slot->asString();
        if (std::find(table.slots.begin(), table.slots.end(), base.slot) == table.slots.end())
            throw std::runtime_error("items: base " + base.id + " uses unknown slot " + base.slot);
        if (b->find("grants_skill"))
            throw std::runtime_error("items: base " + base.id + " grants_skill is gone (D-016: skills are learned, not worn)");
        if (auto implicit = b->find("implicit_properties")) base.implicitProperties = readNumberMap(*implicit);
        if (auto mods = b->find("implicit_modifiers")) {
            for (const auto& im : mods->asArray()) {
                ImplicitModifier implicit;
                implicit.id = im->get("id").asString();
                implicit.value = im->get("value").asNumber();
                if (!table.findModifier(implicit.id))
                    throw std::runtime_error("items: base " + base.id + " implicit modifier " + implicit.id + " is undefined");
                base.implicitModifiers.push_back(implicit);
            }
        }
        base.allowedModifierTags = readStringArray(b->get("allowed_modifier_tags"));
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
    if (auto divisions = doc->find("lattice_divisions")) {
        table.latticeDivisions = divisions->asInt();
        if (table.latticeDivisions < 1) throw std::runtime_error("construction: lattice_divisions must be >= 1");
    }

    for (const auto& s : doc->get("shapes").asArray()) {
        ShapeDef shape;
        shape.id = s->get("id").asString();
        shape.displayName = s->get("display_name").asString();
        shape.materialCost = s->get("material_cost").asInt();
        const auto& size = s->get("size_m").asArray();
        if (size.size() != 3) throw std::runtime_error("construction: size_m needs 3 numbers");
        for (size_t i = 0; i < 3; ++i) shape.sizeM[i] = size[i]->asNumber();
        shape.element = s->get("element").asString();
        try {
            lattice::slotFromName(shape.element);
        } catch (const std::exception& e) {
            throw std::runtime_error("construction: shape '" + shape.id + "': " + e.what());
        }
        if (auto form = s->find("form")) {
            shape.form = form->asString();
            if (shape.form != "box" && shape.form != "stairs" && shape.form != "wedge" && shape.form != "door")
                throw std::runtime_error("construction: shape '" + shape.id +
                                         "' form must be box, stairs, wedge or door");
        }
        if (auto oriented = s->find("oriented")) shape.oriented = oriented->asBool();
        if (auto tall = s->find("cells_tall")) {
            shape.cellsTall = tall->asInt();
            if (shape.cellsTall < 1) throw std::runtime_error("construction: shape '" + shape.id + "' cells_tall must be >= 1");
        }
        if (auto fine = s->find("fine")) shape.fine = fine->asBool();
        if (auto fineOf = s->find("fine_of")) shape.fineOf = fineOf->asString();
        if (auto hint = s->find("hint")) shape.hint = hint->asString();
        if (auto traits = s->find("requires_traits")) shape.requiresTraits = readStringArray(*traits);
        if (auto lengthCells = s->find("cells_long")) {
            shape.cellsLong = lengthCells->asInt();
            if (shape.cellsLong < 1) throw std::runtime_error("construction: shape '" + shape.id + "' cells_long must be >= 1");
            if (shape.element != "beam")
                throw std::runtime_error("construction: shape '" + shape.id + "' cells_long is for beams");
        }
        if (!shape.fineOf.empty() && !shape.fine)
            throw std::runtime_error("construction: shape '" + shape.id + "' names fine_of but is not fine");
        if (auto effect = s->find("requires_world_effect"))
            shape.requiresWorldEffect = effect->asString();
        table.shapes.push_back(std::move(shape));
    }
    for (const auto& m : doc->get("materials").asArray()) {
        BuildMaterialDef material;
        material.id = m->get("id").asString();
        material.displayName = m->get("display_name").asString();
        material.source = m->get("source").asString();
        material.traits = readStringArray(m->get("traits"));
        material.texture = m->get("texture").asString();
        if (auto tint = m->find("tint")) material.tint = tint->asString();
        table.materials.push_back(std::move(material));
    }
    if (table.materials.empty()) throw std::runtime_error("construction: at least one building material is needed");
    for (const auto& shape : table.shapes) {
        bool workable = false;
        for (const auto& material : table.materials)
            if (table.shapeAllowsMaterial(shape, material)) workable = true;
        if (!workable) throw std::runtime_error("construction: no material can be worked into shape '" + shape.id + "'");
    }
    for (const auto& shape : table.shapes) {
        if (shape.fineOf.empty()) continue;
        const auto* twin = table.findShape(shape.fineOf);
        if (twin == nullptr || twin->fine)
            throw std::runtime_error("construction: shape '" + shape.id + "' fine_of must name a full-size shape");
        if (twin->element != shape.element)
            throw std::runtime_error("construction: shape '" + shape.id + "' must occupy the same element kind as its twin");
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
    if (auto cone = player.find("cone_degrees"))
        table.playerConeDegrees = cone->asNumber();

    for (const auto& [id, b] : doc->get("behaviours").asObject()) {
        BehaviourRealtime behaviour;
        behaviour.moveSpeedMps = b->get("move_speed_mps").asNumber();
        behaviour.attackRangeM = b->get("attack_range_m").asNumber();
        if (auto preferred = b->find("preferred_distance_m"))
            behaviour.preferredDistanceM = preferred->asNumber();
        behaviour.aggroRangeM = b->get("aggro_range_m").asNumber();
        behaviour.windupSeconds = b->get("windup_seconds").asNumber();
        if (auto giveUp = b->find("give_up_distance_m"))
            behaviour.giveUpDistanceM = giveUp->asNumber();
        if (auto scream = b->find("scream_period_seconds"))
            behaviour.screamPeriodSeconds = scream->asNumber();
        if (auto radius = b->find("scream_radius_m"))
            behaviour.screamRadiusM = radius->asNumber();
        table.behaviours[id] = behaviour;
    }

    if (auto horde = doc->find("horde")) {
        table.hordeSeparationRadiusM = horde->get("separation_radius_m").asNumber();
        table.hordeSeparationStrengthMps = horde->get("separation_strength_mps").asNumber();
        table.hordeGiveUpSeconds = horde->get("give_up_seconds").asNumber();
        if (auto reach = horde->find("vertical_reach_m"))
            table.hordeVerticalReachM = reach->asNumber();
        if (auto jump = horde->find("jump_speed_mps"))
            table.hordeJumpSpeedMps = jump->asNumber();
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

    // Per-skill space-and-time tunables (projectile speeds, ranges...):
    // numeric fields pass through verbatim for the engine to read.
    for (const auto& [skillId, spatial] : doc->get("skills").asObject()) {
        if (skillId == "design_purpose" || skillId == "prototype_dash") continue;
        for (const auto& [key, value] : spatial->asObject()) {
            if (key == "design_purpose") continue;
            table.skillSpatials[skillId][key] = value->asNumber();
        }
    }
    return table;
}

GrammarTable loadGrammar(const std::string& path) {
    auto doc = json::parseFile(path);
    GrammarTable table;

    const Value& statuses = doc->get("statuses");
    const Value& chill = statuses.get("chill");
    table.chill.buildupMax = chill.get("buildup_max").asNumber();
    table.chill.freezeDurationS = chill.get("freeze_duration_s").asNumber();
    table.chill.decayPerS = chill.get("decay_per_s").asNumber();
    table.chill.bossBuildupMultiplier = chill.get("boss_buildup_multiplier").asNumber();

    auto readDot = [](const Value& v, DotStatusDef& def) {
        def.buildupMax = v.get("buildup_max").asNumber();
        def.durationS = v.get("duration_s").asNumber();
        def.damagePerS = v.get("damage_per_s").asNumber();
        def.decayPerS = v.get("decay_per_s").asNumber();
        def.bossBuildupMultiplier = v.get("boss_buildup_multiplier").asNumber();
        if (auto moving = v.find("moving_multiplier")) def.movingMultiplier = moving->asNumber();
    };
    readDot(statuses.get("ignite"), table.ignite);
    readDot(statuses.get("bleed"), table.bleed);

    const Value& hooks = doc->get("hooks");
    const Value& shatter = hooks.get("shatter");
    table.shatter.triggerTags = readStringArray(shatter.get("trigger_tags"));
    table.shatter.novaDamage = shatter.get("nova_damage").asNumber();
    table.shatter.novaDamageType = shatter.get("nova_damage_type").asString();
    table.shatter.novaRadiusM = shatter.get("nova_radius_m").asNumber();
    table.shatter.executesFrozen = shatter.get("executes_frozen").asBool();
    table.shatter.executesBoss = shatter.get("executes_boss").asBool();

    const Value& proliferate = hooks.get("proliferate");
    table.proliferate.enabled = proliferate.get("enabled").asBool();
    table.proliferate.radiusM = proliferate.get("radius_m").asNumber();
    table.proliferate.spreadBuildup = proliferate.get("spread_buildup").asNumber();

    // skill_mods moved to items.json modifiers (D-014); an old file is tolerated.
    return table;
}

WorldTable loadWorld(const std::string& path) {
    auto doc = json::parseFile(path);
    WorldTable table;

    const Value& base = doc->get("player_base");
    table.playerBase.maxLife = base.get("max_life").asNumber();
    table.playerBase.armourReductionScale = base.get("armour_reduction_scale").asNumber();
    table.playerBase.resistanceCapPercent = base.get("resistance_cap_percent").asNumber();
    if (auto shelter = doc->find("shelter")) {
        table.shelter.regenLifePerRound = shelter->get("regen_life_per_round").asNumber();
        table.shelter.settleRounds = shelter->get("settle_rounds").asNumber();
        table.shelter.maxRoomCells = shelter->get("max_room_cells").asInt();
        if (table.shelter.maxRoomCells < 1) throw std::runtime_error("world: shelter.max_room_cells must be >= 1");
    }
    if (auto enc = doc->find("encroachment")) {
        auto& e = table.encroachment;
        e.settleSeconds = enc->get("settle_seconds").asNumber();
        e.fringeMinM = enc->get("fringe_min_m").asNumber();
        e.fringeMaxM = enc->get("fringe_max_m").asNumber();
        e.maxNests = enc->get("max_nests").asInt();
        e.spacingM = enc->get("spacing_m").asNumber();
        e.growthSeconds = enc->get("growth_seconds").asNumber();
        e.respawnSeconds = enc->get("respawn_seconds").asNumber();
        e.blightRadiusM = enc->get("blight_radius_m").asNumber();
        e.uneasyRestMultiplier = enc->get("uneasy_rest_multiplier").asNumber();
        e.nestLootFraction = enc->get("nest_loot_fraction").asNumber();
        e.scarSeconds = enc->get("scar_seconds").asNumber();
        for (const auto& tier : enc->get("tiers").asArray()) e.tiers.push_back(readStringArray(*tier));
        if (e.tiers.empty()) throw std::runtime_error("world: encroachment.tiers needs at least one tier");
        if (e.fringeMaxM < e.fringeMinM) throw std::runtime_error("world: encroachment fringe_max_m < fringe_min_m");
        if (e.nestLootFraction < 0.0 || e.nestLootFraction > 1.0)
            throw std::runtime_error("world: encroachment.nest_loot_fraction must be within [0, 1]");
    }

    for (const auto& e : doc->get("enemies").asArray()) {
        EnemyDef def;
        def.id = e->get("id").asString();
        def.displayName = e->get("display_name").asString();
        def.maxLife = e->get("max_life").asNumber();
        def.behaviour = e->get("behaviour").asString();
        def.damage = e->get("damage").asNumber();
        def.damageType = e->get("damage_type").asString();
        def.attackPeriodRounds = e->get("attack_period_rounds").asInt();
        if (auto loot = e->find("loot")) {
            for (const auto& entry : loot->asArray()) {
                LootEntry drop;
                drop.chance = entry->get("chance").asNumber();
                if (auto gear = entry->find("gear")) {
                    // {"gear": "<rarity>", "tier": n, "chance": p}
                    drop.kind = "gear";
                    drop.gearRarity = gear->asString();
                    if (auto tier = entry->find("tier")) drop.gearTier = tier->asInt();
                } else if (auto page = entry->find("skill_page")) {
                    // {"skill_page": true, "chance": p}
                    if (!page->asBool())
                        throw std::runtime_error("world: enemy " + def.id + " skill_page entry must be true");
                    drop.kind = "skill_page";
                } else {
                    // {"item": "<material>", "min": a, "max": b, "chance": p}
                    drop.item = entry->get("item").asString();
                    drop.minCount = entry->get("min").asInt();
                    drop.maxCount = entry->get("max").asInt();
                    if (drop.maxCount < drop.minCount)
                        throw std::runtime_error("world: enemy " + def.id + " loot " + drop.item + " has max below min");
                }
                def.loot.push_back(std::move(drop));
            }
        }
        table.enemies.push_back(std::move(def));
    }

    if (auto elites = doc->find("elite_modifiers")) {
        for (const auto& e : elites->asArray()) {
            EliteModifierDef def;
            def.id = e->get("id").asString();
            def.displayName = e->get("display_name").asString();
            if (auto v = e->find("life_multiplier")) def.lifeMultiplier = v->asNumber();
            if (auto v = e->find("speed_multiplier")) def.speedMultiplier = v->asNumber();
            if (auto v = e->find("damage_multiplier")) def.damageMultiplier = v->asNumber();
            if (auto v = e->find("immune_statuses")) def.immuneStatuses = readStringArray(*v);
            if (auto burst = e->find("death_burst")) {
                def.deathBurstDamage = burst->get("damage").asNumber();
                def.deathBurstRadiusM = burst->get("radius_m").asNumber();
                def.deathBurstType = burst->get("damage_type").asString();
            }
            if (auto v = e->find("extra_loot_rolls")) def.extraLootRolls = v->asInt();
            if (auto v = e->find("gear_chance_multiplier")) def.gearChanceMultiplier = v->asNumber();
            if (auto v = e->find("page_chance_multiplier")) def.pageChanceMultiplier = v->asNumber();
            table.eliteModifiers.push_back(std::move(def));
        }
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
    if (auto itemRewards = rewards.find("item_rewards")) {
        for (const auto& [rewardType, spec] : itemRewards->asObject()) {
            TrialTable::ItemReward reward;
            reward.rarity = spec->get("rarity").asString();
            reward.tier = spec->get("tier").asInt();
            table.itemRewards[rewardType] = reward;
        }
    }

    const Value& contract = doc->get("death_contract");
    table.keepCatalystsOnDeath = contract.get("keep_catalysts_on_death").asBool();
    table.loseRunMaterialsOnDeath = contract.get("lose_run_materials_on_death").asBool();
    return table;
}

WorldgenTable loadWorldgen(const std::string& path) {
    auto doc = json::parseFile(path);
    WorldgenTable table;

    table.defaultSeed = static_cast<uint64_t>(doc->get("default_seed").asNumber());

    const Value& map = doc->get("map");
    table.map.widthCells = map.get("width_cells").asInt();
    table.map.heightCells = map.get("height_cells").asInt();
    table.map.cellSizeM = map.get("cell_size_m").asNumber();
    table.map.worldDepth = map.get("world_depth").asInt();
    table.map.baseHeight = map.get("base_height").asInt();
    table.map.heightScale = map.get("height_scale").asInt();
    table.map.heightFrequency = map.get("height_frequency").asNumber();
    table.map.heightOctaves = map.get("height_octaves").asInt();
    table.map.moistureFrequency = map.get("moisture_frequency").asNumber();

    const Value& mountains = doc->get("mountains");
    table.mountains.extraScale = mountains.get("extra_scale").asInt();
    table.mountains.frequency = mountains.get("frequency").asNumber();
    table.mountains.cragginessFrequency = mountains.get("cragginess_frequency").asNumber();
    table.mountains.cragginessThreshold = mountains.get("cragginess_threshold").asNumber();

    table.strata.dirtDepth = doc->get("strata").get("dirt_depth").asInt();

    const Value& caves = doc->get("caves");
    table.caves.enabled = caves.get("enabled").asBool();
    table.caves.tunnelFrequency = caves.get("tunnel_frequency").asNumber();
    table.caves.tunnelWidth = caves.get("tunnel_width").asNumber();
    table.caves.cavernFrequency = caves.get("cavern_frequency").asNumber();
    table.caves.cavernThreshold = caves.get("cavern_threshold").asNumber();
    table.caves.cavernMaxYFraction = caves.get("cavern_max_y_fraction").asNumber();
    table.caves.minY = caves.get("min_y").asInt();
    table.caves.surfaceMargin = caves.get("surface_margin").asInt();
    table.caves.breachChance = caves.get("breach_chance").asNumber();
    if (auto density = caves.find("node_density"))
        for (const auto& [type, value] : density->asObject())
            if (type != "design_purpose") table.caves.nodeDensity[type] = value->asNumber();
    if (auto cavePacks = caves.find("packs"))
        for (const auto& pack : cavePacks->asArray())
            table.caves.packs.push_back(readStringArray(*pack));
    if (auto packDensity = caves.find("pack_density"))
        table.caves.packDensity = packDensity->asNumber();

    for (const auto& ring : doc->get("danger").get("rings").asArray()) {
        DangerRing r;
        r.radiusM = ring->get("radius_m").asNumber();
        r.packDensityMultiplier = ring->get("pack_density_multiplier").asNumber();
        if (auto v = ring->find("pack_size_bonus")) r.packSizeBonus = v->asInt();
        if (auto v = ring->find("elite_chance")) r.eliteChance = v->asNumber();
        table.dangerRings.push_back(r);
    }

    for (const auto& [kind, rule] : doc->get("block_rules").asObject()) {
        if (kind == "design_purpose") continue;
        BlockRule r;
        r.breakable = rule->get("breakable").asBool();
        r.digSeconds = rule->get("dig_seconds").asNumber();
        if (auto yields = rule->find("yields")) r.yields = readIntMap(*yields);
        table.blockRules[kind] = std::move(r);
    }

    for (const auto& b : doc->get("biomes").asArray()) {
        BiomeDef biome;
        biome.id = b->get("id").asString();
        biome.displayName = b->get("display_name").asString();
        biome.surface = b->get("surface").asString();
        if (auto v = b->find("height_min")) biome.heightMin = v->asInt();
        if (auto v = b->find("height_max")) biome.heightMax = v->asInt();
        if (auto v = b->find("moisture_min")) biome.moistureMin = v->asNumber();
        if (auto v = b->find("moisture_max")) biome.moistureMax = v->asNumber();
        if (auto density = b->find("node_density"))
            for (const auto& [type, value] : density->asObject())
                biome.nodeDensity[type] = value->asNumber();
        if (auto v = b->find("pack_density")) biome.packDensity = v->asNumber();
        if (auto packs = b->find("packs"))
            for (const auto& pack : packs->asArray())
                biome.packs.push_back(readStringArray(*pack));
        table.biomes.push_back(std::move(biome));
    }

    for (const auto& [id, n] : doc->get("nodes").asObject()) {
        if (id == "design_purpose") continue;
        NodeTypeDef node;
        node.id = id;
        node.displayName = n->get("display_name").asString();
        node.materialFamily = n->get("material_family").asString();
        node.units = n->get("units").asInt();
        node.unitsPerHarvest = n->get("units_per_harvest").asInt();
        node.visual = n->get("visual").asString();
        table.nodeTypes[id] = std::move(node);
    }

    const Value& g = doc->get("guarantees");
    table.guarantees.spawnBiome = g.get("spawn_biome").asString();
    table.guarantees.spawnClearRadiusM = g.get("spawn_clear_radius_m").asNumber();
    table.guarantees.nearRadiusM = g.get("near_radius_m").asNumber();
    table.guarantees.minNodesNear = readIntMap(g.get("min_nodes_near"));
    table.guarantees.gateBiome = g.get("gate_biome").asString();
    table.guarantees.gateMinDistanceM = g.get("gate_min_distance_m").asNumber();
    table.guarantees.packMinDistanceFromSpawnM =
        g.get("pack_min_distance_from_spawn_m").asNumber();

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
    tuning.worldgen = loadWorldgen(tuningDirectory + "/worldgen.json");
    tuning.grammar = loadGrammar(tuningDirectory + "/grammar.json");
    return tuning;
}

} // namespace wroughtwild::tuning
