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
const TrialFloor* TrialTable::findFloor(const std::string& id) const { return findById(floors, id); }
const BuildMaterialDef* ConstructionTable::findMaterial(const std::string& id) const { return findById(materials, id); }
bool BuildMaterialDef::hasTrait(const std::string& trait) const {
    return std::find(traits.begin(), traits.end(), trait) != traits.end();
}
bool ConstructionTable::shapeAllowsMaterial(const ShapeDef& shape, const BuildMaterialDef& material) const {
    for (const auto& trait : shape.requiresTraits)
        if (!material.hasTrait(trait)) return false;
    if (!material.onlyForTrait.empty() &&
        std::find(shape.requiresTraits.begin(), shape.requiresTraits.end(), material.onlyForTrait) ==
            shape.requiresTraits.end())
        return false;
    return true;
}
int FireSettingDef::fuelHeat(const std::string& family) const {
    auto it = fuels.find(family);
    return it == fuels.end() ? 0 : it->second.heat;
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
std::vector<std::string> CombatSkillDef::resolveTags() const {
    std::vector<std::string> out = tags;
    out.push_back("skill:" + id);
    return out;
}
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
            if (auto gp = c->find("guaranteed_property")) process.guaranteedProperty = gp->asString();
            if (auto rt = c->find("result_tier")) process.resultTier = rt->asInt();
            if (auto fr = c->find("minimum_roll_fraction_at_skill")) process.minimumRollFractionAtSkill = fr->asNumber();
            table.catalystProcesses.push_back(std::move(process));
        }
    }

    if (auto currencies = doc->find("currencies"))
        table.currencies = readStringArray(*currencies);
    if (auto market = doc->find("market")) {
        for (const auto& o : market->get("offers").asArray()) {
            CraftingTable::MarketOffer offer;
            offer.item = o->get("item").asString();
            if (auto n = o->find("count")) offer.count = n->asInt();
            offer.price = o->get("price").asInt();
            if (auto cur = o->find("currency")) offer.currency = cur->asString();
            table.market.push_back(std::move(offer));
        }
    }
    if (auto rolls = doc->find("craft_rolls")) {
        table.keenChanceAtLevel1 = rolls->get("keen_chance_at_level_1").asNumber();
        table.keenChancePerLevel = rolls->get("keen_chance_per_level").asNumber();
        table.wroughtChanceFromLevel = rolls->get("wrought_chance_from_level").asInt();
        table.wroughtChancePerLevel = rolls->get("wrought_chance_per_level").asNumber();
    }

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
            else if (key == "mastery") {
                for (const auto& m : value->asArray()) {
                    MasteryPerk perk;
                    perk.uses = m->get("uses").asInt();
                    perk.modifier = m->get("modifier").asString();
                    perk.value = m->get("value").asNumber();
                    perk.text = m->get("text").asString();
                    def.mastery.push_back(std::move(perk));
                }
            }
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
        if (auto from = m->find("from_tier")) def.fromTier = from->asInt();
        if (auto purpose = m->find("design_purpose")) def.designPurpose = purpose->asString();
        for (const auto& t : m->get("tiers").asArray()) {
            ModifierTier tier;
            tier.tier = t->get("tier").asInt();
            tier.minimum = t->get("minimum").asNumber();
            tier.maximum = t->get("maximum").asNumber();
            if (auto bps = t->find("breakpoints")) {
                for (const auto& b : bps->asArray()) {
                    Breakpoint bp;
                    bp.effect = b->get("effect").asString();
                    bp.value = b->get("value").asNumber();
                    bp.appliesTo = readStringArray(b->get("applies_to"));
                    bp.text = b->get("text").asString();
                    tier.breakpoints.push_back(std::move(bp));
                }
            }
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
        if (auto cap = b->find("tier_cap")) base.tierCap = cap->asInt();
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

const IngotDef* FoundryDef::findIngot(const std::string& id) const { return findById(ingots, id); }
const IngotPairDef* FoundryDef::findPair(const std::string& a, const std::string& b) const {
    for (const auto& p : pairs)
        if ((p.a == a && p.b == b) || (p.a == b && p.b == a)) return &p;
    return nullptr;
}

FoundryDef loadFoundry(const std::string& path) {
    auto doc = json::parseFile(path);
    FoundryDef def;
    for (const auto& size : doc->get("plate_by_era").asArray()) {
        const auto& pair = size->asArray();
        if (pair.size() != 2) throw std::runtime_error("foundry: plate_by_era entries are [rows, cols]");
        def.plateByEra.push_back({pair[0]->asInt(), pair[1]->asInt()});
    }
    if (def.plateByEra.empty()) throw std::runtime_error("foundry: plate_by_era needs at least one size");
    def.reforgeCost = readIntMap(doc->get("reforge_cost"));
    if (auto n = doc->find("line_length")) def.lineLength = n->asInt();
    if (auto n = doc->find("line_bonus")) def.lineBonus = n->asNumber();
    for (const auto& i : doc->get("ingots").asArray()) {
        IngotDef ingot;
        ingot.id = i->get("id").asString();
        ingot.displayName = i->get("display_name").asString();
        ingot.verb = i->get("verb").asString();
        ingot.modifier = i->get("modifier").asString();
        ingot.value = i->get("value").asNumber();
        def.ingots.push_back(std::move(ingot));
    }
    for (const auto& p : doc->get("pairs").asArray()) {
        IngotPairDef pair;
        pair.a = p->get("a").asString();
        pair.b = p->get("b").asString();
        pair.displayName = p->get("display_name").asString();
        pair.modifier = p->get("modifier").asString();
        pair.value = p->get("value").asNumber();
        if (!def.findIngot(pair.a) || !def.findIngot(pair.b))
            throw std::runtime_error("foundry: pair " + pair.displayName + " names an unknown ingot");
        def.pairs.push_back(std::move(pair));
    }
    for (const auto& s : doc->get("sources").asArray()) {
        IngotSourceDef source;
        source.id = s->get("id").asString();
        source.event = s->get("event").asString();
        source.ingot = s->get("ingot").asString();
        if (auto era = s->find("era")) source.era = era->asInt();
        if (!def.findIngot(source.ingot)) throw std::runtime_error("foundry: source " + source.id + " grants an unknown ingot");
        def.sources.push_back(std::move(source));
    }
    return def;
}

const std::map<std::string, double>* EraDef::mechanic(const std::string& enemyId, const std::string& name) const {
    auto enemy = mobMechanics.find(enemyId);
    if (enemy == mobMechanics.end()) return nullptr;
    auto m = enemy->second.find(name);
    return m == enemy->second.end() ? nullptr : &m->second;
}

EraTable loadEras(const std::string& path) {
    auto doc = json::parseFile(path);
    EraTable table;
    for (const auto& e : doc->get("eras").asArray()) {
        EraDef era;
        era.id = e->get("id").asString();
        era.displayName = e->get("display_name").asString();
        era.story = e->get("story").asString();
        era.triggerWorldEffect = e->get("trigger_world_effect").asString();
        if (auto enc = e->find("encroachment")) era.encroachment = enc->asBool();
        if (auto bonus = e->find("elite_chance_bonus")) era.eliteChanceBonus = bonus->asNumber();
        if (auto escorts = e->find("pack_escorts"))
            for (const auto& [enemyId, list] : escorts->asObject()) era.packEscorts[enemyId] = readStringArray(*list);
        if (auto mechanics = e->find("mob_mechanics")) {
            for (const auto& [enemyId, byName] : mechanics->asObject()) {
                for (const auto& [name, params] : byName->asObject()) {
                    std::map<std::string, double> values;
                    if (params->type == json::Type::Object) {
                        for (const auto& [key, value] : params->asObject()) values[key] = value->asNumber();
                    } else {
                        values["value"] = params->asNumber();
                    }
                    era.mobMechanics[enemyId][name] = std::move(values);
                }
            }
        }
        table.eras.push_back(std::move(era));
    }
    if (table.eras.empty()) throw std::runtime_error("eras: at least one era is needed");
    if (!table.eras.front().triggerWorldEffect.empty()) throw std::runtime_error("eras: the first era has no trigger");
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
            if (shape.form != "box" && shape.form != "stairs" && shape.form != "wedge" && shape.form != "door" &&
                shape.form != "arch" && shape.form != "fire" && shape.form != "low")
                throw std::runtime_error("construction: shape '" + shape.id +
                                         "' form must be box, stairs, wedge, door, arch, fire or low");
        }
        if (auto oriented = s->find("oriented")) shape.oriented = oriented->asBool();
        if (auto tall = s->find("cells_tall")) {
            shape.cellsTall = tall->asInt();
            if (shape.cellsTall < 1) throw std::runtime_error("construction: shape '" + shape.id + "' cells_tall must be >= 1");
        }
        if (auto fine = s->find("fine")) shape.fine = fine->asBool();
        if (auto fineOf = s->find("fine_of")) shape.fineOf = fineOf->asString();
        if (auto hint = s->find("hint")) shape.hint = hint->asString();
        if (auto unlockHint = s->find("unlock_hint")) shape.unlockHint = unlockHint->asString();
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
        if (auto only = m->find("only_for_trait")) material.onlyForTrait = only->asString();
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
        if (auto flees = b->find("flees")) behaviour.flees = flees->asBool();
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
        if (auto immune = e->find("immune_statuses")) def.immuneStatuses = readStringArray(*immune);
        if (auto tint = e->find("tint")) def.tint = tint->asString();
        if (auto scale = e->find("size_scale")) def.sizeScale = scale->asNumber();
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
    if (auto floors = doc->find("floors")) {
        auto readBoss = [](const Value& b) {
            BossDef boss;
            boss.id = b.get("id").asString();
            boss.displayName = b.get("display_name").asString();
            boss.maxLife = b.get("max_life").asNumber();
            boss.clawDamage = b.get("claw_damage").asNumber();
            boss.clawDamageType = b.get("claw_damage_type").asString();
            boss.clawPeriodRounds = b.get("claw_period_rounds").asInt();
            boss.breathDamage = b.get("breath_damage").asNumber();
            boss.breathDamageType = b.get("breath_damage_type").asString();
            boss.breathPeriodRounds = b.get("breath_period_rounds").asInt();
            boss.breathTelegraphRounds = b.get("breath_telegraph_rounds").asInt();
            return boss;
        };
        for (const auto& f : floors->asArray()) {
            TrialFloor floor;
            floor.id = f->get("id").asString();
            floor.displayName = f->get("display_name").asString();
            floor.requiresWorldEffect = f->get("requires_world_effect").asString();
            floor.boss = readBoss(f->get("boss"));
            for (const auto& stage : f->get("stages").asArray()) {
                TrialStage trialStage;
                for (const auto& ch : stage->get("choices").asArray()) {
                    RoomChoice choice;
                    choice.id = ch->get("id").asString();
                    choice.displayName = ch->get("display_name").asString();
                    choice.encounter = readStringArray(ch->get("encounter"));
                    choice.reward = ch->get("reward").asString();
                    trialStage.choices.push_back(std::move(choice));
                }
                floor.stages.push_back(std::move(trialStage));
            }
            floor.exitAfterStage = f->get("exit_after_stage").asInt();
            floor.completionUnlock = f->get("completion_unlock").asString();
            if (auto text = f->find("completion_text")) floor.completionText = text->asString();
            if (floor.stages.empty()) throw std::runtime_error("trial: floor " + floor.id + " has no stages");
            table.floors.push_back(std::move(floor));
        }
    }
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
        if (auto hand = rule->find("by_hand")) r.byHand = hand->asBool();
        if (auto heat = rule->find("heat_to_crack")) r.heatToCrack = heat->asInt();
        table.blockRules[kind] = std::move(r);
    }
    if (auto fire = doc->find("fire_setting")) {
        for (const auto& [family, fuel] : fire->get("fuels").asObject()) {
            if (family == "design_purpose") continue;
            FireFuelDef f;
            f.heat = fuel->get("heat").asInt();
            f.burnSeconds = fuel->get("burn_seconds").asNumber();
            table.fireSetting.fuels[family] = f;
        }
        if (auto v = fire->find("reach_cells")) table.fireSetting.reachCells = v->asInt();
        if (auto v = fire->find("soak_seconds")) table.fireSetting.soakSeconds = v->asNumber();
        if (auto v = fire->find("hot_seconds")) table.fireSetting.hotSeconds = v->asNumber();
        if (auto v = fire->find("quench_radius_m")) table.fireSetting.quenchRadiusM = v->asNumber();
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
        if (auto v = b->find("grazer_density")) biome.grazerDensity = v->asNumber();
        if (auto grazers = b->find("grazers"))
            for (const auto& pack : grazers->asArray())
                biome.grazers.push_back(readStringArray(*pack));
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
        if (auto era = n->find("era")) node.era = era->asInt();
        if (auto heat = n->find("heat_to_work")) node.heatToWork = heat->asInt();
        if (auto tool = n->find("tool_item")) node.toolItem = tool->asString();
        if (auto presses = n->find("drive_presses")) node.drivePresses = presses->asInt();
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
    tuning.eras = loadEras(tuningDirectory + "/eras.json");
    tuning.foundry = loadFoundry(tuningDirectory + "/foundry.json");
    tuning.skills = loadSkills(tuningDirectory + "/skills.json");
    tuning.items = loadItems(tuningDirectory + "/items.json");
    tuning.boons = loadBoons(tuningDirectory + "/boons.json");
    tuning.world = loadWorld(tuningDirectory + "/world.json");
    tuning.trial = loadTrial(tuningDirectory + "/trial.json");
    tuning.realtime = loadRealtime(tuningDirectory + "/combat_realtime.json");
    tuning.worldgen = loadWorldgen(tuningDirectory + "/worldgen.json");
    tuning.grammar = loadGrammar(tuningDirectory + "/grammar.json");
    // The Foundry speaks in the item table's modifiers: every ingot and pair
    // must name one, or a placed ingot would be a silent point.
    for (const auto& ingot : tuning.foundry.ingots)
        if (!tuning.items.findModifier(ingot.modifier))
            throw std::runtime_error("foundry: ingot " + ingot.id + " names unknown modifier " + ingot.modifier);
    for (const auto& pair : tuning.foundry.pairs)
        if (!tuning.items.findModifier(pair.modifier))
            throw std::runtime_error("foundry: pair " + pair.displayName + " names unknown modifier " + pair.modifier);
    for (const auto& skill : tuning.skills.combatSkills)
        for (const auto& perk : skill.mastery)
            if (!tuning.items.findModifier(perk.modifier))
                throw std::runtime_error("skills: mastery perk on " + skill.id + " names unknown modifier " + perk.modifier);
    return tuning;
}

} // namespace wroughtwild::tuning
