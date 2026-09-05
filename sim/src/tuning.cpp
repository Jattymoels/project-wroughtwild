#include "wroughtwild/tuning.h"

#include <algorithm>
#include <cmath>

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
const CraftingTable::CurrencyKind* CraftingTable::findKind(const std::string& id) const {
    return findById(currencyKinds, id);
}
const Station* CraftingTable::findStationForKit(const std::string& kitItemId) const {
    if (kitItemId.empty()) return nullptr;
    for (const auto& station : stations)
        if (station.kitItem == kitItemId) return &station;
    return nullptr;
}
const BiomeDef* WorldgenTable::findBiome(const std::string& id) const { return findById(biomes, id); }
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
const CurioDef* TrialTable::findCurio(const std::string& id) const {
    for (const auto& c : curios)
        if (c.id == id) return &c;
    return nullptr;
}
const CurioDef* TrialTable::curioForLandmark(const std::string& landmark) const {
    for (const auto& c : curios)
        if (c.landmark == landmark) return &c;
    return nullptr;
}
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
    if (auto kinds = doc->find("currency_kinds")) {
        for (const auto& k : kinds->asArray()) {
            CraftingTable::CurrencyKind kind;
            kind.id = k->get("id").asString();
            kind.displayName = k->get("display_name").asString();
            kind.family = k->get("family").asString();
            table.currencyKinds.push_back(std::move(kind));
        }
    }
    if (auto market = doc->find("market")) {
        for (const auto& o : market->get("offers").asArray()) {
            CraftingTable::MarketOffer offer;
            offer.item = o->get("item").asString();
            if (auto n = o->find("count")) offer.count = n->asInt();
            offer.price = o->get("price").asInt();
            if (auto cur = o->find("currency")) offer.currency = cur->asString();
            table.market.push_back(std::move(offer));
        }
        if (auto exchange = market->find("exchange")) {
            table.exchangeRate = exchange->get("rate").asInt();
            table.exchangeKinds = readStringArray(exchange->get("kinds"));
            if (table.exchangeRate < 1) throw std::runtime_error("crafting: market.exchange.rate must be at least 1");
        }
    }
    if (auto rolls = doc->find("craft_rolls")) {
        table.keenChanceAtLevel1 = rolls->get("keen_chance_at_level_1").asNumber();
        table.keenChancePerLevel = rolls->get("keen_chance_per_level").asNumber();
        table.wroughtChanceFromLevel = rolls->get("wrought_chance_from_level").asInt();
        table.wroughtChancePerLevel = rolls->get("wrought_chance_per_level").asNumber();
        if (auto weighting = rolls->find("currency_weighting"))
            if (auto rarity = weighting->find("aimed_minimum_rarity")) table.aimedMinimumRarity = rarity->asString();
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
        if (auto sentence = m->find("sentence")) def.sentence = sentence->asString();
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
const KindDef* FoundryDef::findKindOnPlate(const std::string& id) const { return findById(kinds, id); }
const IngotMetalDef* FoundryDef::findMetal(const std::string& id) const { return findById(metals, id); }
std::string FoundryDef::defaultMetal() const { return metals.empty() ? std::string() : metals.front().id; }
int FoundryDef::metalReach(const std::string& id) const {
    const auto* metal = findMetal(id.empty() ? defaultMetal() : id);
    return metal ? std::max(1, metal->reach) : 1;
}
int FoundryDef::maxReach() const {
    int widest = 1;
    for (const auto& m : metals) widest = std::max(widest, m.reach);
    return widest;
}
std::string FoundryDef::alloyForEra(int era) const {
    std::string best = defaultMetal();
    int reach = 0;
    for (const auto& m : metals)
        if (m.era <= era && m.reach > reach) {
            best = m.id;
            reach = m.reach;
        }
    return best;
}
const RailPatternDef* RailsDef::findPattern(const std::string& id) const { return findById(patterns, id); }
const ClassDef* RailsDef::findClass(const std::string& id) const { return findById(classes, id); }
const SpecialisationDef* RailsDef::findSpecialisation(const std::string& id) const { return findById(specialisations, id); }
int RailsDef::allowed(int era) const {
    if (byEra.empty()) return 0;
    const size_t index = static_cast<size_t>(std::max(0, era - 1));
    return byEra[std::min(index, byEra.size() - 1)];
}
std::string FoundryDef::familyName(const std::string& family) const {
    auto it = familyNames.find(family);
    return it == familyNames.end() ? std::string() : it->second;
}
const IngotPairDef* FoundryDef::findPair(const std::string& a, const std::string& b) const {
    for (const auto& p : pairs)
        if ((p.a == a && p.b == b) || (p.a == b && p.b == a)) return &p;
    return nullptr;
}

// True when a rail pattern states any condition of its own.
static bool p_has_condition(const RailPatternDef& pattern) {
    const auto& c = pattern.condition;
    return !c.allPlacedAre.empty() || !c.alternating.empty() || !c.endsAre.empty() || !c.holdsSkillTag.empty() ||
           !c.holdsKindFamily.empty();
}

FoundryDef loadFoundry(const std::string& path) {
    auto doc = json::parseFile(path);
    FoundryDef def;
    {
        const auto& frame = doc->get("frame").asArray();
        if (frame.size() != 2) throw std::runtime_error("foundry: frame is [rows, cols]");
        def.frameRows = frame[0]->asInt();
        def.frameCols = frame[1]->asInt();
        if (def.frameRows < 1 || def.frameCols < 1) throw std::runtime_error("foundry: the frame needs a row and a column");
    }
    for (const auto& span : doc->get("rows_by_era").asArray()) {
        const auto& pair = span->asArray();
        if (pair.size() != 2) throw std::runtime_error("foundry: rows_by_era entries are [first_row, last_row]");
        const int first = pair[0]->asInt(), last = pair[1]->asInt();
        if (first < 0 || last < first || last >= def.frameRows)
            throw std::runtime_error("foundry: a rows_by_era entry lies outside the frame");
        def.rowsByEra.push_back({first, last});
    }
    if (def.rowsByEra.empty()) throw std::runtime_error("foundry: rows_by_era needs at least one era");
    for (const auto& cell : doc->get("sockets").asArray()) {
        const auto& pair = cell->asArray();
        if (pair.size() != 2) throw std::runtime_error("foundry: sockets entries are [row, col]");
        const int row = pair[0]->asInt(), col = pair[1]->asInt();
        if (row < 0 || col < 0 || row >= def.frameRows || col >= def.frameCols)
            throw std::runtime_error("foundry: a socket lies outside the frame");
        def.sockets.push_back({row, col});
    }
    if (def.sockets.empty()) throw std::runtime_error("foundry: sockets needs at least one cell");
    def.reforgeCost = readIntMap(doc->get("reforge_cost"));
    if (auto n = doc->find("support_multiplier")) def.supportMultiplier = n->asNumber();
    if (auto n = doc->find("cast_armour_seconds")) def.castArmourSeconds = n->asNumber();
    if (auto n = doc->find("haste_after_hit_seconds")) def.hasteAfterHitSeconds = n->asNumber();
    if (auto kinds = doc->find("kinds")) {
        for (const auto& k : kinds->asArray()) {
            KindDef kind;
            kind.id = k->get("id").asString();
            kind.family = k->get("family").asString();
            kind.displayName = k->get("display_name").asString();
            if (auto s = k->find("short_name")) kind.shortName = s->asString();
            if (kind.shortName.empty()) kind.shortName = kind.displayName;
            if (auto m = k->find("modifier")) kind.modifier = m->asString();
            if (auto v = k->find("value")) kind.value = v->asNumber();
            def.kinds.push_back(std::move(kind));
        }
    }
    if (auto links = doc->find("links")) def.linkFamily = links->get("family").asString();
    if (auto metals = doc->find("ingot_metals")) {
        for (const auto& m : metals->asArray()) {
            IngotMetalDef metal;
            metal.id = m->get("id").asString();
            metal.displayName = m->get("display_name").asString();
            metal.reach = m->get("reach").asInt();
            if (auto era = m->find("era")) metal.era = era->asInt();
            if (auto cost = m->find("recast_cost")) metal.recastCost = readIntMap(*cost);
            if (metal.reach < 1) throw std::runtime_error("foundry: metal " + metal.id + " reaches less than one cell");
            def.metals.push_back(std::move(metal));
        }
        for (size_t i = 1; i < def.metals.size(); ++i)
            if (def.metals[i].reach < def.metals[i - 1].reach)
                throw std::runtime_error("foundry: ingot_metals must be listed in reach order");
    }
    if (auto station = doc->find("recast_station")) def.recastStation = station->asString();
    if (auto names = doc->find("family_names")) {
        for (const auto& [family, name] : names->asObject())
            if (family != "design_purpose") def.familyNames[family] = name->asString();
    }
    if (auto forms = doc->find("forms")) {
        for (const auto& f : forms->asArray()) {
            FormDef form;
            form.family = f->get("family").asString();
            if (auto kind = f->find("kind")) form.kind = kind->asString();
            form.ingot = f->get("ingot").asString();
            if (auto lane = f->find("lane")) form.lane = lane->asString();
            if (auto tag = f->find("skill_tag")) form.skillTag = tag->asString();
            if (auto metal = f->find("metal")) form.metal = metal->asString();
            form.displayName = f->get("display_name").asString();
            for (const auto& e : f->get("effects").asArray()) {
                FormEffect effect;
                effect.modifier = e->get("modifier").asString();
                effect.value = e->get("value").asNumber();
                if (auto packet = e->find("packet")) effect.packet = packet->asString();
                form.effects.push_back(std::move(effect));
            }
            if (form.effects.empty()) throw std::runtime_error("foundry: form " + form.displayName + " has no effects");
            if (!form.lane.empty() && form.lane != "same" && form.lane != "added")
                throw std::runtime_error("foundry: form " + form.displayName + " names an unknown lane " + form.lane);
            def.forms.push_back(std::move(form));
        }
    }
    if (auto rails = doc->find("rails")) {
        for (const auto& n : rails->get("by_era").asArray()) def.rails.byEra.push_back(n->asInt());
        if (def.rails.byEra.empty()) throw std::runtime_error("foundry: rails.by_era needs at least one era");
        if (auto e = rails->find("specialise_on_world_effect")) def.rails.specialiseOnWorldEffect = e->asString();
        if (auto classes = rails->find("classes")) {
            for (const auto& c : classes->asArray()) {
                ClassDef cls;
                cls.id = c->get("id").asString();
                cls.displayName = c->get("display_name").asString();
                cls.patterns = readStringArray(c->get("patterns"));
                if (auto s = c->find("specialisations")) cls.specialisations = readStringArray(*s);
                if (auto k = c->find("starting_skills")) cls.startingSkills = readStringArray(*k);
                def.rails.classes.push_back(std::move(cls));
            }
        }
        if (auto specs = rails->find("specialisations")) {
            for (const auto& s : specs->asArray()) {
                SpecialisationDef spec;
                spec.id = s->get("id").asString();
                spec.displayName = s->get("display_name").asString();
                spec.classId = s->get("class").asString();
                for (const auto& [from, to] : s->get("becomes").asObject()) spec.becomes[from] = to->asString();
                def.rails.specialisations.push_back(std::move(spec));
            }
        }
        if (auto patterns = rails->find("patterns")) {
            for (const auto& p : patterns->asArray()) {
                RailPatternDef pattern;
                pattern.id = p->get("id").asString();
                pattern.displayName = p->get("display_name").asString();
                if (auto from = p->find("from")) pattern.from = from->asString();
                if (auto axis = p->find("axis")) pattern.axis = axis->asString();
                if (auto c = p->find("condition")) {
                    if (auto v = c->find("all_placed_are")) pattern.condition.allPlacedAre = readStringArray(*v);
                    if (auto v = c->find("alternating")) pattern.condition.alternating = readStringArray(*v);
                    if (auto v = c->find("ends_are")) pattern.condition.endsAre = readStringArray(*v);
                    if (auto v = c->find("minimum_placed")) pattern.condition.minimumPlaced = v->asInt();
                    if (auto v = c->find("holds_skill_tag")) pattern.condition.holdsSkillTag = v->asString();
                    if (auto v = c->find("holds_kind_family")) pattern.condition.holdsKindFamily = v->asString();
                }
                if (!pattern.condition.alternating.empty() && pattern.condition.alternating.size() != 2)
                    throw std::runtime_error("foundry: rail pattern " + pattern.id + " alternates between two ingots");
                if (!pattern.condition.endsAre.empty() && pattern.condition.endsAre.size() != 2)
                    throw std::runtime_error("foundry: rail pattern " + pattern.id + " names two ends");
                if (auto t = p->find("condition_text")) pattern.conditionText = t->asString();
                if (auto t = p->find("rule_text")) pattern.ruleText = t->asString();
                for (const auto& e : p->get("effects").asArray()) {
                    RailEffect effect;
                    effect.modifier = e->get("modifier").asString();
                    effect.value = e->get("value").asNumber();
                    if (auto tag = e->find("skill_tag")) effect.skillTag = tag->asString();
                    pattern.effects.push_back(std::move(effect));
                }
                if (pattern.effects.empty()) throw std::runtime_error("foundry: rail pattern " + pattern.id + " bends no rule");
                if (auto taught = p->find("taught_by")) {
                    pattern.taughtByEnemy = taught->get("enemy").asString();
                    pattern.taughtKills = taught->get("kills").asInt();
                }
                def.rails.patterns.push_back(std::move(pattern));
            }
        }
        // A grown pattern inherits its base's axis and condition (and the
        // condition's words) unless it says its own.
        for (auto& pattern : def.rails.patterns) {
            if (!pattern.isGrown()) continue;
            const auto* base = def.rails.findPattern(pattern.from);
            if (!base || base->isGrown())
                throw std::runtime_error("foundry: rail pattern " + pattern.id + " grows from unknown or grown pattern " + pattern.from);
            if (pattern.axis.empty()) pattern.axis = base->axis;
            if (!p_has_condition(pattern)) pattern.condition = base->condition;
            if (pattern.conditionText.empty()) pattern.conditionText = base->conditionText;
        }
        for (const auto& pattern : def.rails.patterns)
            if (pattern.axis != "row" && pattern.axis != "column")
                throw std::runtime_error("foundry: rail pattern " + pattern.id + " names an unknown axis " + pattern.axis);
    }
    for (const auto& i : doc->get("ingots").asArray()) {
        IngotDef ingot;
        ingot.id = i->get("id").asString();
        ingot.displayName = i->get("display_name").asString();
        ingot.verb = i->get("verb").asString();
        ingot.modifier = i->get("modifier").asString();
        if (auto m = i->find("skill_modifier")) ingot.skillModifier = m->asString();
        if (auto m = i->find("added_modifier")) ingot.addedModifier = m->asString();
        ingot.value = i->get("value").asNumber();
        if (auto v = i->find("skill_value")) ingot.skillValue = v->asNumber();
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
        if (auto metal = s->find("metal")) source.metal = metal->asString();
        if (!def.findIngot(source.ingot)) throw std::runtime_error("foundry: source " + source.id + " grants an unknown ingot");
        if (!source.metal.empty() && source.metal != "alloy" && !def.findMetal(source.metal))
            throw std::runtime_error("foundry: source " + source.id + " casts in unknown metal " + source.metal);
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

std::string EraDef::minglePick(const std::string& biome, unsigned long long salt) const {
    auto it = mingle.find(biome);
    if (it == mingle.end() || it->second.empty() || mingleChance <= 0.0) return std::string();
    unsigned long long h = salt ^ 0xD6E8FEB86659FD93ull;
    h ^= h >> 32;
    h *= 0xD6E8FEB86659FD93ull;
    h ^= h >> 29;
    if (static_cast<double>(h % 10007ull) / 10007.0 >= mingleChance) return std::string();
    return it->second[static_cast<size_t>((h >> 16) % it->second.size())];
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
        if (auto bonus = e->find("elite_chance_bonus")) era.eliteChanceBonus = bonus->asNumber();
        if (auto cap = e->find("armour_reduction_cap")) {
            era.armourReductionCap = cap->asNumber();
            if (era.armourReductionCap < 0.0 || era.armourReductionCap > 1.0)
                throw std::runtime_error("eras: " + era.id + " armour_reduction_cap must be in [0, 1]");
        }
        if (auto mingle = e->find("mingle"))
            for (const auto& [biome, list] : mingle->asObject()) era.mingle[biome] = readStringArray(*list);
        if (auto chance = e->find("mingle_chance")) era.mingleChance = chance->asNumber();
        if (auto cross = e->find("patrols_cross_biomes")) era.patrolsCrossBiomes = cross->asBool();
        if (era.mingleChance < 0.0 || era.mingleChance > 1.0) throw std::runtime_error("eras: " + era.id + " mingle_chance must be in [0, 1]");
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
                shape.form != "arch" && shape.form != "fire" && shape.form != "low" && shape.form != "chest" &&
                shape.form != "corner" && shape.form != "roof_slope" && shape.form != "roof_hip" && shape.form != "roof_valley")
                throw std::runtime_error("construction: shape '" + shape.id +
                                         "' form must be box, stairs, wedge, door, arch, fire, low, chest, corner, roof_slope, roof_hip or roof_valley");
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
        if (shape.form == "roof_slope" || shape.form == "roof_hip" || shape.form == "roof_valley") {
            const double extent = table.gridSizeMetres / (shape.fine ? table.latticeDivisions : 1);
            if (shape.element != "block" || !shape.oriented || shape.cellsTall != 1 || shape.cellsLong != 1 ||
                std::abs(shape.sizeM[0] - extent) > 1e-8 || std::abs(shape.sizeM[2] - extent) > 1e-8 ||
                shape.sizeM[1] <= 0 || shape.sizeM[1] > extent)
                throw std::runtime_error("construction: roof transitions require an oriented square block no taller than its grid extent");
        }
        if (shape.form == "corner") {
            const double extent = table.gridSizeMetres / (shape.fine ? table.latticeDivisions : 1);
            const bool block = shape.element == "block", floor = shape.element == "floor";
            if ((!block && !floor) || !shape.oriented || shape.cellsTall != 1 || shape.cellsLong != 1 ||
                std::abs(shape.sizeM[0] - extent) > 1e-8 || std::abs(shape.sizeM[2] - extent) > 1e-8 ||
                (block && std::abs(shape.sizeM[1] - extent) > 1e-8) ||
                (floor && (shape.sizeM[1] <= 0 || shape.sizeM[1] > extent)))
                throw std::runtime_error("construction: corner requires an oriented square block or floor matching its grid extent");
        }
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
        if (auto shot = b->find("projectile")) {
            auto& p = behaviour.projectile;
            p.enabled = true;
            p.speedMps = shot->get("speed_mps").asNumber();
            p.radiusM = shot->get("radius_m").asNumber();
            p.maxRangeM = shot->get("max_range_m").asNumber();
            p.muzzleHeightM = shot->get("muzzle_height_m").asNumber();
            p.trailLengthM = shot->get("trail_length_m").asNumber();
            p.glowEnergy = shot->get("glow_energy").asNumber();
            p.colour = shot->get("colour").asString();
            if (!(p.speedMps > 0.0 && p.radiusM > 0.0 && p.maxRangeM > 0.0 &&
                  p.muzzleHeightM >= 0.0 && p.trailLengthM > 0.0 && p.glowEnergy >= 0.0))
                throw std::runtime_error("combat_realtime: invalid projectile dimensions for '" + id + "'");
            if (p.colour.size() != 6 || p.colour.find_first_not_of("0123456789abcdefABCDEF") != std::string::npos)
                throw std::runtime_error("combat_realtime: projectile colour must be six hex digits for '" + id + "'");
        }
        if (auto giveUp = b->find("give_up_distance_m"))
            behaviour.giveUpDistanceM = giveUp->asNumber();
        if (auto scream = b->find("scream_period_seconds"))
            behaviour.screamPeriodSeconds = scream->asNumber();
        if (auto radius = b->find("scream_radius_m"))
            behaviour.screamRadiusM = radius->asNumber();
        if (auto v = b->find("verb")) behaviour.verb = v->asString();
        if (auto v = b->find("verb_seconds")) behaviour.verbSeconds = v->asNumber();
        if (auto v = b->find("verb_strength")) behaviour.verbStrength = v->asNumber();
        if (auto v = b->find("verb_radius_m")) behaviour.verbRadiusM = v->asNumber();
        if (auto v = b->find("verb_arc_degrees")) behaviour.verbArcDegrees = v->asNumber();
        if (auto v = b->find("verb_cap")) behaviour.verbCap = v->asNumber();
        static const char* const kVerbs[] = {"", "harry", "guard", "mark", "root", "kindle", "swarm", "ward", "recruit"};
        bool known = false;
        for (const char* verb : kVerbs) known = known || behaviour.verb == verb;
        if (!known) throw std::runtime_error("combat_realtime: behaviour '" + id + "' has an unknown verb '" + behaviour.verb + "'");
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
        if (auto cap = horde->find("max_live_mobs")) table.hordeMaxLiveMobs = cap->asInt();
        if (auto range = horde->find("sleep_range_m")) table.hordeSleepRangeM = range->asNumber();
        if (auto after = horde->find("sleep_after_seconds")) table.hordeSleepAfterSeconds = after->asNumber();
        if (auto v = horde->find("train_window_seconds")) table.hordeTrainWindowSeconds = v->asNumber();
        if (auto v = horde->find("train_bonus_per_hit")) table.hordeTrainBonusPerHit = v->asNumber();
        if (auto v = horde->find("train_max_bonus")) table.hordeTrainMaxBonus = v->asNumber();
        if (table.hordeTrainWindowSeconds < 0.0 || table.hordeTrainBonusPerHit < 0.0 || table.hordeTrainMaxBonus < 0.0)
            throw std::runtime_error("combat_realtime: horde train numbers must be >= 0");
    }
    if (auto noise = doc->find("noise")) {
        if (auto radii = noise->find("radius_m"))
            for (const auto& [kind, radius] : radii->asObject()) {
                table.noiseRadiusM[kind] = radius->asNumber();
                if (radius->asNumber() < 0.0) throw std::runtime_error("combat_realtime: noise radius_m." + kind + " must be >= 0");
            }
        if (auto muffle = noise->find("muffle")) table.noiseMuffle = muffle->asNumber();
        if (auto horn = noise->find("horn_cooldown_seconds")) table.noiseHornCooldownSeconds = horn->asNumber();
        if (table.noiseMuffle < 0.0 || table.noiseMuffle > 1.0) throw std::runtime_error("combat_realtime: noise.muffle must be in [0, 1]");
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
    table.damageTypes = readStringArray(doc->get("damage_types"));
    if (table.damageTypes.empty()) throw std::runtime_error("grammar: damage_types needs at least one type");

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

    if (auto melee = hooks.find("melee")) {
        table.melee.bossStaggerMultiplier = melee->get("boss_stagger_multiplier").asNumber();
        table.melee.bossPushMultiplier = melee->get("boss_push_multiplier").asNumber();
    }
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
    if (auto day = doc->find("day")) {
        auto& d = table.day;
        d.lengthSeconds = day->get("length_seconds").asNumber();
        d.startFraction = day->get("start_fraction").asNumber();
        d.dawnEnd = day->get("dawn_end").asNumber();
        d.dayEnd = day->get("day_end").asNumber();
        d.duskEnd = day->get("dusk_end").asNumber();
        d.nightLight = day->get("night_light").asNumber();
        d.exposureLifePerRound = day->get("exposure_life_per_round").asNumber();
        d.exposureFloorFraction = day->get("exposure_floor_fraction").asNumber();
        d.nightAggroMultiplier = day->get("night_aggro_multiplier").asNumber();
        d.nightSleepRangeMultiplier = day->get("night_sleep_range_multiplier").asNumber();
        d.shelterNightRegenMultiplier = day->get("shelter_night_regen_multiplier").asNumber();
        if (d.lengthSeconds <= 0.0) throw std::runtime_error("world: day.length_seconds must be > 0");
        if (!(0.0 <= d.dawnEnd && d.dawnEnd <= d.dayEnd && d.dayEnd <= d.duskEnd && d.duskEnd <= 1.0))
            throw std::runtime_error("world: day phases must run dawn_end <= day_end <= dusk_end within [0, 1]");
        if (d.startFraction < 0.0 || d.startFraction >= 1.0) throw std::runtime_error("world: day.start_fraction must be in [0, 1)");
        if (d.exposureFloorFraction < 0.0 || d.exposureFloorFraction > 1.0)
            throw std::runtime_error("world: day.exposure_floor_fraction must be in [0, 1]");
    }
    if (auto hauling = doc->find("hauling")) {
        table.hauling.carryCapDefault = hauling->get("carry_cap_default").asInt();
        if (auto caps = hauling->find("carry_cap"))
            for (const auto& [family, cap] : caps->asObject()) table.hauling.carryCap[family] = cap->asInt();
        table.hauling.chestUnits = hauling->get("chest_units").asInt();
        if (table.hauling.carryCapDefault < 0 || table.hauling.chestUnits < 0)
            throw std::runtime_error("world: hauling caps must be >= 0");
        for (const auto& [family, cap] : table.hauling.carryCap)
            if (cap < 0) throw std::runtime_error("world: hauling carry_cap." + family + " must be >= 0");
    }
    if (auto siege = doc->find("siege")) {
        auto& s = table.siege;
        s.firstNight = siege->get("first_night").asInt();
        s.chancePerNight = siege->get("chance_per_night").asNumber();
        s.arriveSecondsIntoNight = siege->get("arrive_seconds_into_night").asNumber();
        s.spawnRadiusM = siege->get("spawn_radius_m").asNumber();
        s.homeRadiusM = siege->get("home_radius_m").asNumber();
        s.timberBreakHits = siege->get("timber_break_hits").asInt();
        if (auto packs = siege->find("pack_by_era"))
            for (const auto& [era, list] : packs->asObject()) s.packByEra[std::stoi(era)] = readStringArray(*list);
        if (s.chancePerNight < 0.0 || s.chancePerNight > 1.0) throw std::runtime_error("world: siege.chance_per_night must be in [0, 1]");
        if (s.timberBreakHits < 1) throw std::runtime_error("world: siege.timber_break_hits must be >= 1");
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
        if (auto kind = e->find("currency_kind")) def.currencyKind = kind->asString();
        if (auto immune = e->find("immune_statuses")) def.immuneStatuses = readStringArray(*immune);
        if (auto taken = e->find("damage_taken")) def.damageTaken = readNumberMap(*taken);
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
            if (auto v = e->find("damage_taken")) def.damageTaken = readNumberMap(*v);
            if (auto burst = e->find("death_burst")) {
                def.deathBurstDamage = burst->get("damage").asNumber();
                def.deathBurstRadiusM = burst->get("radius_m").asNumber();
                def.deathBurstType = burst->get("damage_type").asString();
            }
            if (auto v = e->find("extra_loot_rolls")) def.extraLootRolls = v->asInt();
            if (auto v = e->find("gear_chance_multiplier")) def.gearChanceMultiplier = v->asNumber();
            if (auto v = e->find("page_chance_multiplier")) def.pageChanceMultiplier = v->asNumber();
            if (auto bounty = e->find("bounty"))
                for (const auto& b : bounty->asArray()) {
                    LootEntry entry;
                    entry.item = b->get("item").asString();
                    if (auto v = b->find("min")) entry.minCount = v->asInt();
                    if (auto v = b->find("max")) entry.maxCount = v->asInt();
                    if (auto v = b->find("chance")) entry.chance = v->asNumber();
                    if (entry.item.empty() || entry.minCount < 1 || entry.maxCount < entry.minCount)
                        throw std::runtime_error("world: elite " + def.id + " has a malformed bounty entry");
                    def.bounty.push_back(entry);
                }
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
    if (auto curio = rewards.find("completion_curio")) table.completionCurio = curio->asString();
    if (auto curios = doc->find("curios"))
        for (const auto& c : curios->asArray()) {
            CurioDef def;
            def.id = c->get("id").asString();
            def.displayName = c->get("display_name").asString();
            def.landmark = c->get("landmark").asString();
            def.unlock = c->get("unlock").asString();
            if (auto reading = c->find("reading")) def.reading = reading->asString();
            table.curios.push_back(def);
        }
    if (!table.completionCurio.empty() && !table.findCurio(table.completionCurio))
        throw std::runtime_error("trial: completion_curio " + table.completionCurio + " is not a curio");
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
            if (auto curio = f->find("completion_curio")) {
                floor.completionCurio = curio->asString();
                if (!table.findCurio(floor.completionCurio))
                    throw std::runtime_error("trial: floor " + floor.id + " completion_curio is not a curio");
            }
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
    if (auto warp = map.find("height_warp_metres")) table.map.heightWarpMetres = warp->asNumber();
    if (auto frequency = map.find("height_warp_frequency")) table.map.heightWarpFrequency = frequency->asNumber();
    if (!std::isfinite(table.map.heightWarpMetres) || table.map.heightWarpMetres < 0 ||
        !std::isfinite(table.map.heightWarpFrequency) || table.map.heightWarpFrequency <= 0)
        throw std::runtime_error("worldgen: height warp must be finite and non-negative, frequency positive");
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

    if (auto landmarks = doc->find("landmarks"))
        for (const auto& l : landmarks->asArray()) {
            LandmarkDef def;
            def.id = l->get("id").asString();
            def.displayName = l->get("display_name").asString();
            def.biome = l->get("biome").asString();
            def.look = l->get("look").asString();
            if (auto v = l->find("min_distance_from_spawn_m")) def.minDistanceFromSpawnM = v->asNumber();
            table.landmarks.push_back(def);
        }
    for (const auto& ring : doc->get("danger").get("rings").asArray()) {
        DangerRing r;
        r.radiusM = ring->get("radius_m").asNumber();
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
        if (auto v = b->find("patrols")) biome.patrols = v->asBool();
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
    if (auto rimWidth = doc->get("mountains").find("rim_width_cells")) table.mountains.rimWidthCells = rimWidth->asInt();
    if (auto rimScale = doc->get("mountains").find("rim_extra_scale")) table.mountains.rimExtraScale = rimScale->asInt();
    table.guarantees.nearRadiusM = g.get("near_radius_m").asNumber();
    table.guarantees.minNodesNear = readIntMap(g.get("min_nodes_near"));
    if (auto far = g.find("far_radius_m")) table.guarantees.farRadiusM = far->asNumber();
    if (auto far = g.find("min_nodes_far")) table.guarantees.minNodesFar = readIntMap(*far);
    table.guarantees.gateBiome = g.get("gate_biome").asString();
    table.guarantees.gateMinDistanceM = g.get("gate_min_distance_m").asNumber();
    table.guarantees.packMinDistanceFromSpawnM =
        g.get("pack_min_distance_from_spawn_m").asNumber();
    if (auto v = g.find("patrol_length_m")) table.guarantees.patrolLengthM = v->asNumber();

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
    for (const auto& ingot : tuning.foundry.ingots) {
        if (!tuning.items.findModifier(ingot.modifier))
            throw std::runtime_error("foundry: ingot " + ingot.id + " names unknown modifier " + ingot.modifier);
        if (!ingot.skillModifier.empty() && !tuning.items.findModifier(ingot.skillModifier))
            throw std::runtime_error("foundry: ingot " + ingot.id + " names unknown skill modifier " + ingot.skillModifier);
        if (!ingot.addedModifier.empty() && !tuning.items.findModifier(ingot.addedModifier))
            throw std::runtime_error("foundry: ingot " + ingot.id + " names unknown added modifier " + ingot.addedModifier);
    }
    // The flow: every currency kind has a plate entry in its family; every
    // form names a known family, ingot, kind and modifiers.
    for (const auto& kind : tuning.foundry.kinds) {
        if (!kind.modifier.empty() && !tuning.items.findModifier(kind.modifier))
            throw std::runtime_error("foundry: kind " + kind.id + " names unknown modifier " + kind.modifier);
        const auto* currency = tuning.crafting.findKind(kind.id);
        if (!currency || currency->family != kind.family)
            throw std::runtime_error("foundry: kind " + kind.id + " is not a currency kind of family " + kind.family);
        if (tuning.foundry.familyName(kind.family).empty())
            throw std::runtime_error("foundry: kind " + kind.id + " belongs to an unnamed family " + kind.family);
    }
    for (const auto& currency : tuning.crafting.currencyKinds)
        if (!tuning.foundry.findKindOnPlate(currency.id))
            throw std::runtime_error("foundry: currency " + currency.id + " has no place on the plate (kinds)");
    for (const auto& form : tuning.foundry.forms) {
        if (tuning.foundry.familyName(form.family).empty())
            throw std::runtime_error("foundry: form " + form.displayName + " names unknown family " + form.family);
        if (!form.kind.empty() && !tuning.foundry.findKindOnPlate(form.kind))
            throw std::runtime_error("foundry: form " + form.displayName + " names unknown kind " + form.kind);
        if (!tuning.foundry.findIngot(form.ingot))
            throw std::runtime_error("foundry: form " + form.displayName + " names unknown ingot " + form.ingot);
        for (const auto& effect : form.effects)
            if (!tuning.items.findModifier(effect.modifier))
                throw std::runtime_error("foundry: form " + form.displayName + " names unknown modifier " + effect.modifier);
        if (!form.metal.empty() && !tuning.foundry.findMetal(form.metal))
            throw std::runtime_error("foundry: form " + form.displayName + " needs unknown metal " + form.metal);
    }
    // The metals (slice 10): the re-cast station is a known one.
    if (!tuning.foundry.recastStation.empty() && !tuning.crafting.findStation(tuning.foundry.recastStation))
        throw std::runtime_error("foundry: recast_station names unknown station " + tuning.foundry.recastStation);
    for (const auto& pair : tuning.foundry.pairs)
        if (!tuning.items.findModifier(pair.modifier))
            throw std::runtime_error("foundry: pair " + pair.displayName + " names unknown modifier " + pair.modifier);
    // Rails (D-023 slice 9): every pattern's condition names known ingots
    // and a known family, its effects known modifiers, its teacher a known
    // enemy; every specialisation lists known patterns.
    for (const auto& p : tuning.foundry.rails.patterns) {
        for (const auto* list : {&p.condition.allPlacedAre, &p.condition.alternating, &p.condition.endsAre})
            for (const auto& id : *list)
                if (!tuning.foundry.findIngot(id))
                    throw std::runtime_error("foundry: rail pattern " + p.id + " names unknown ingot " + id);
        if (!p.condition.holdsKindFamily.empty() && tuning.foundry.familyName(p.condition.holdsKindFamily).empty())
            throw std::runtime_error("foundry: rail pattern " + p.id + " names unknown family " + p.condition.holdsKindFamily);
        for (const auto& e : p.effects)
            if (!tuning.items.findModifier(e.modifier))
                throw std::runtime_error("foundry: rail pattern " + p.id + " names unknown modifier " + e.modifier);
        if (p.isManner() && !tuning.world.findEnemy(p.taughtByEnemy))
            throw std::runtime_error("foundry: rail pattern " + p.id + " is taught by unknown enemy " + p.taughtByEnemy);
    }
    for (const auto& cls : tuning.foundry.rails.classes) {
        for (const auto& id : cls.patterns) {
            const auto* p = tuning.foundry.rails.findPattern(id);
            if (!p || p->isManner() || p->isGrown())
                throw std::runtime_error("foundry: class " + cls.id + " names unknown, manner or grown rail pattern " + id);
        }
        for (const auto& id : cls.specialisations) {
            const auto* s = tuning.foundry.rails.findSpecialisation(id);
            if (!s || s->classId != cls.id)
                throw std::runtime_error("foundry: class " + cls.id + " names unknown or foreign specialisation " + id);
        }
        for (const auto& id : cls.startingSkills)
            if (!tuning.skills.findCombatSkill(id))
                throw std::runtime_error("foundry: class " + cls.id + " starts with unknown skill " + id);
    }
    for (const auto& spec : tuning.foundry.rails.specialisations) {
        const auto* cls = tuning.foundry.rails.findClass(spec.classId);
        if (!cls) throw std::runtime_error("foundry: specialisation " + spec.id + " names unknown class " + spec.classId);
        for (const auto& [from, to] : spec.becomes) {
            if (std::find(cls->patterns.begin(), cls->patterns.end(), from) == cls->patterns.end())
                throw std::runtime_error("foundry: specialisation " + spec.id + " grows " + from + ", not a pattern of " + cls->id);
            const auto* grown = tuning.foundry.rails.findPattern(to);
            if (!grown || grown->from != from)
                throw std::runtime_error("foundry: specialisation " + spec.id + " names " + to + ", which does not grow from " + from);
        }
    }
    // Typed currency: the exchange and the families pay in known kinds.
    for (const auto& id : tuning.crafting.exchangeKinds)
        if (!tuning.crafting.findKind(id)) throw std::runtime_error("crafting: market.exchange names unknown kind " + id);
    for (const auto& enemy : tuning.world.enemies)
        if (!enemy.currencyKind.empty() && !tuning.crafting.findKind(enemy.currencyKind))
            throw std::runtime_error("world: enemy " + enemy.id + " pays unknown kind " + enemy.currencyKind);
    for (const auto& skill : tuning.skills.combatSkills)
        for (const auto& perk : skill.mastery)
            if (!tuning.items.findModifier(perk.modifier))
                throw std::runtime_error("skills: mastery perk on " + skill.id + " names unknown modifier " + perk.modifier);
    return tuning;
}

} // namespace wroughtwild::tuning
