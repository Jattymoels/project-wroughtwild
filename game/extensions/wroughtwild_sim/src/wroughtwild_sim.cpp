#include "wroughtwild_sim.h"

#include <exception>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

#include "wroughtwild/save.h"

namespace godot {

namespace {

std::string to_std(const String& s) { return std::string(s.utf8().get_data()); }
String to_godot(const std::string& s) { return String::utf8(s.c_str()); }

Dictionary to_dictionary(const std::map<std::string, int>& counts) {
    Dictionary d;
    for (const auto& [key, value] : counts) {
        d[to_godot(key)] = value;
    }
    return d;
}

} // namespace

void WroughtwildSim::_bind_methods() {
    ClassDB::bind_method(D_METHOD("load_tuning", "tuning_directory"), &WroughtwildSim::load_tuning);
    ClassDB::bind_method(D_METHOD("is_loaded"), &WroughtwildSim::is_loaded);
    ClassDB::bind_method(D_METHOD("last_error"), &WroughtwildSim::last_error);

    ClassDB::bind_method(D_METHOD("recipe_ids"), &WroughtwildSim::recipe_ids);
    ClassDB::bind_method(D_METHOD("recipe", "recipe_id"), &WroughtwildSim::recipe);
    ClassDB::bind_method(D_METHOD("salvage_return_fraction"), &WroughtwildSim::salvage_return_fraction);
    ClassDB::bind_method(D_METHOD("shape_ids"), &WroughtwildSim::shape_ids);
    ClassDB::bind_method(D_METHOD("shape_material_cost", "shape_id"), &WroughtwildSim::shape_material_cost);
    ClassDB::bind_method(D_METHOD("grid_size"), &WroughtwildSim::grid_size);
    ClassDB::bind_method(D_METHOD("placement_range"), &WroughtwildSim::placement_range);
    ClassDB::bind_method(D_METHOD("removal_refund_fraction"), &WroughtwildSim::removal_refund_fraction);

    ClassDB::bind_method(D_METHOD("add_material", "material_id", "amount"), &WroughtwildSim::add_material);
    ClassDB::bind_method(D_METHOD("consume_material", "material_id", "amount"), &WroughtwildSim::consume_material);
    ClassDB::bind_method(D_METHOD("material_count", "material_id"), &WroughtwildSim::material_count);
    ClassDB::bind_method(D_METHOD("can_afford_placement", "shape_id", "material_family"), &WroughtwildSim::can_afford_placement);
    ClassDB::bind_method(D_METHOD("pay_placement", "shape_id", "material_family"), &WroughtwildSim::pay_placement);
    ClassDB::bind_method(D_METHOD("refund_removal", "shape_id", "material_family"), &WroughtwildSim::refund_removal);
    ClassDB::bind_method(D_METHOD("add_station", "station_id"), &WroughtwildSim::add_station);
    ClassDB::bind_method(D_METHOD("has_station", "station_id"), &WroughtwildSim::has_station);
    ClassDB::bind_method(D_METHOD("skill_xp", "skill_id"), &WroughtwildSim::skill_xp);
    ClassDB::bind_method(D_METHOD("skill_level", "skill_id"), &WroughtwildSim::skill_level);
    ClassDB::bind_method(D_METHOD("craft", "recipe_id", "for_order"), &WroughtwildSim::craft, DEFVAL(false));
    ClassDB::bind_method(D_METHOD("salvage", "recipe_id"), &WroughtwildSim::salvage);
    ClassDB::bind_method(D_METHOD("recipe_feeds_open_order", "recipe_id"), &WroughtwildSim::recipe_feeds_open_order);

    ClassDB::bind_method(D_METHOD("station_ids"), &WroughtwildSim::station_ids);
    ClassDB::bind_method(D_METHOD("station", "station_id"), &WroughtwildSim::station);
    ClassDB::bind_method(D_METHOD("order_ids"), &WroughtwildSim::order_ids);
    ClassDB::bind_method(D_METHOD("order", "order_id"), &WroughtwildSim::order);
    ClassDB::bind_method(D_METHOD("skill_progress", "skill_id"), &WroughtwildSim::skill_progress);
    ClassDB::bind_method(D_METHOD("inventory"), &WroughtwildSim::inventory);
    ClassDB::bind_method(D_METHOD("currency"), &WroughtwildSim::currency);
    ClassDB::bind_method(D_METHOD("currency_count", "currency_id"), &WroughtwildSim::currency_count);
    ClassDB::bind_method(D_METHOD("can_build_station", "station_id"), &WroughtwildSim::can_build_station);
    ClassDB::bind_method(D_METHOD("build_station", "station_id"), &WroughtwildSim::build_station);
    ClassDB::bind_method(D_METHOD("fulfill_order", "order_id"), &WroughtwildSim::fulfill_order);
    ClassDB::bind_method(D_METHOD("order_fulfilled", "order_id"), &WroughtwildSim::order_fulfilled);
    ClassDB::bind_method(D_METHOD("world_effect_active", "effect"), &WroughtwildSim::world_effect_active);

    ClassDB::bind_method(D_METHOD("export_json"), &WroughtwildSim::export_json);
    ClassDB::bind_method(D_METHOD("import_json", "text"), &WroughtwildSim::import_json);
}

String WroughtwildSim::export_json() const {
    if (!require_loaded("export_json")) {
        return String();
    }
    wroughtwild::save::SaveGame game;
    game.economy = player_->exportState();
    game.equipment = equipment_;
    return to_godot(wroughtwild::save::toJson(game));
}

bool WroughtwildSim::import_json(const String& text) {
    if (!require_loaded("import_json")) {
        return false;
    }
    try {
        const wroughtwild::save::SaveGame game = wroughtwild::save::fromJson(to_std(text));
        player_->importState(game.economy);
        equipment_ = game.equipment;
        last_error_ = String();
        return true;
    } catch (const std::exception& e) {
        last_error_ = to_godot(e.what());
        UtilityFunctions::push_warning("WroughtwildSim.import_json failed: ", last_error_);
        return false;
    }
}

PackedStringArray WroughtwildSim::station_ids() const {
    PackedStringArray ids;
    if (require_loaded("station_ids")) {
        for (const auto& s : tuning_->crafting.stations) {
            ids.push_back(to_godot(s.id));
        }
    }
    return ids;
}

Dictionary WroughtwildSim::station(const String& station_id) const {
    Dictionary d;
    if (!require_loaded("station")) {
        return d;
    }
    const auto* s = tuning_->crafting.findStation(to_std(station_id));
    if (s == nullptr) {
        return d;
    }
    d["id"] = to_godot(s->id);
    d["display_name"] = to_godot(s->displayName);
    d["tier"] = s->tier;
    d["build_cost"] = to_dictionary(s->buildCost);
    d["upgrade_from"] = to_godot(s->upgradeFrom);
    d["upgrade_cost"] = to_dictionary(s->upgradeCost);
    d["available"] = player_->stationAvailable(s->id);
    return d;
}

PackedStringArray WroughtwildSim::order_ids() const {
    PackedStringArray ids;
    if (require_loaded("order_ids")) {
        for (const auto& o : tuning_->crafting.orders) {
            ids.push_back(to_godot(o.id));
        }
    }
    return ids;
}

Dictionary WroughtwildSim::order(const String& order_id) const {
    Dictionary d;
    if (!require_loaded("order")) {
        return d;
    }
    const auto* o = tuning_->crafting.findOrder(to_std(order_id));
    if (o == nullptr) {
        return d;
    }
    d["id"] = to_godot(o->id);
    d["display_name"] = to_godot(o->displayName);
    d["required_outputs"] = to_dictionary(o->requiredOutputs);
    d["rewards"] = to_dictionary(o->rewards);
    d["world_effect"] = to_godot(o->worldEffect);
    d["fulfilled"] = player_->orderFulfilled(o->id);
    return d;
}

Dictionary WroughtwildSim::skill_progress(const String& skill_id) const {
    Dictionary d;
    if (!require_loaded("skill_progress")) {
        return d;
    }
    const auto* def = tuning_->skills.findCraftSkill(to_std(skill_id));
    if (def == nullptr) {
        return d;
    }
    const int level = player_->skillLevel(def->id);
    d["id"] = to_godot(def->id);
    d["display_name"] = to_godot(def->displayName);
    d["level"] = level;
    d["xp"] = player_->skillXp(def->id);
    d["max_level"] = def->maximumPrototypeLevel;
    // xpRequiredByLevel[i] is the cumulative XP for level i+1.
    const bool atMax = level >= def->maximumPrototypeLevel ||
                       level >= static_cast<int>(def->xpRequiredByLevel.size());
    d["next_level_xp"] = atMax ? -1 : def->xpRequiredByLevel[static_cast<size_t>(level)];
    return d;
}

Dictionary WroughtwildSim::inventory() const {
    return require_loaded("inventory") ? to_dictionary(player_->inventory) : Dictionary();
}

Dictionary WroughtwildSim::currency() const {
    return require_loaded("currency") ? to_dictionary(player_->currency) : Dictionary();
}

int WroughtwildSim::currency_count(const String& currency_id) const {
    if (!require_loaded("currency_count")) {
        return 0;
    }
    const auto it = player_->currency.find(to_std(currency_id));
    return it == player_->currency.end() ? 0 : it->second;
}

bool WroughtwildSim::recipe_feeds_open_order(const String& recipe_id) const {
    return require_loaded("recipe_feeds_open_order") && player_->recipeFeedsOpenOrder(to_std(recipe_id));
}

bool WroughtwildSim::can_build_station(const String& station_id) const {
    return require_loaded("can_build_station") && player_->canBuildStation(to_std(station_id));
}

bool WroughtwildSim::build_station(const String& station_id) {
    return require_loaded("build_station") && player_->buildStation(to_std(station_id));
}

Dictionary WroughtwildSim::fulfill_order(const String& order_id) {
    Dictionary d;
    d["fulfilled"] = false;
    if (!require_loaded("fulfill_order")) {
        return d;
    }
    const auto result = player_->fulfillOrder(to_std(order_id));
    d["fulfilled"] = result.fulfilled;
    d["already_fulfilled"] = result.alreadyFulfilled;
    d["missing_outputs"] = result.missingOutputs;
    d["world_effect"] = to_godot(result.worldEffect);
    return d;
}

bool WroughtwildSim::order_fulfilled(const String& order_id) const {
    return require_loaded("order_fulfilled") && player_->orderFulfilled(to_std(order_id));
}

bool WroughtwildSim::world_effect_active(const String& effect) const {
    return require_loaded("world_effect_active") && player_->worldEffectActive(to_std(effect));
}

bool WroughtwildSim::load_tuning(const String& tuning_directory) {
    try {
        auto loaded = std::make_unique<wroughtwild::tuning::Tuning>(
            wroughtwild::tuning::loadAll(to_std(tuning_directory)));
        // PlayerEconomy keeps a reference to the tuning, so the tuning must
        // outlive it: drop the player first, then swap the tuning in.
        player_.reset();
        tuning_ = std::move(loaded);
        player_ = std::make_unique<wroughtwild::economy::PlayerEconomy>(*tuning_);
        last_error_ = String();
        return true;
    } catch (const std::exception& e) {
        last_error_ = to_godot(e.what());
        UtilityFunctions::push_warning("WroughtwildSim.load_tuning failed: ", last_error_);
        return false;
    }
}

bool WroughtwildSim::require_loaded(const char* method) const {
    if (tuning_ && player_) {
        return true;
    }
    UtilityFunctions::push_error("WroughtwildSim.", method, " called before load_tuning()");
    return false;
}

PackedStringArray WroughtwildSim::recipe_ids() const {
    PackedStringArray ids;
    if (!require_loaded("recipe_ids")) {
        return ids;
    }
    for (const auto& recipe : tuning_->crafting.recipes) {
        ids.push_back(to_godot(recipe.id));
    }
    return ids;
}

Dictionary WroughtwildSim::recipe(const String& recipe_id) const {
    Dictionary d;
    if (!require_loaded("recipe")) {
        return d;
    }
    const auto* r = tuning_->crafting.findRecipe(to_std(recipe_id));
    if (r == nullptr) {
        return d;
    }
    d["id"] = to_godot(r->id);
    d["display_name"] = to_godot(r->displayName);
    d["station"] = to_godot(r->station);
    d["minimum_skill"] = to_dictionary(r->minimumSkill);
    d["inputs"] = to_dictionary(r->inputs);
    d["outputs"] = to_dictionary(r->outputs);
    d["base_skill_xp"] = r->baseSkillXp;
    // Gate status for UI: the same three checks craft() applies.
    bool skillMet = true;
    for (const auto& [skillId, level] : r->minimumSkill) {
        if (player_->skillLevel(skillId) < level) {
            skillMet = false;
        }
    }
    d["station_available"] = player_->stationAvailable(r->station);
    d["skill_met"] = skillMet;
    d["inputs_met"] = wroughtwild::economy::hasAll(player_->inventory, r->inputs);
    return d;
}

double WroughtwildSim::salvage_return_fraction() const {
    return require_loaded("salvage_return_fraction") ? tuning_->crafting.salvageReturnFraction : 0.0;
}

PackedStringArray WroughtwildSim::shape_ids() const {
    PackedStringArray ids;
    if (!require_loaded("shape_ids")) {
        return ids;
    }
    for (const auto& shape : tuning_->construction.shapes) {
        ids.push_back(to_godot(shape.id));
    }
    return ids;
}

int WroughtwildSim::shape_material_cost(const String& shape_id) const {
    if (!require_loaded("shape_material_cost")) {
        return 0;
    }
    const auto* shape = tuning_->construction.findShape(to_std(shape_id));
    return shape == nullptr ? 0 : shape->materialCost;
}

double WroughtwildSim::grid_size() const {
    return require_loaded("grid_size") ? tuning_->construction.gridSizeMetres : 1.0;
}

double WroughtwildSim::placement_range() const {
    return require_loaded("placement_range") ? tuning_->construction.placementRangeMetres : 0.0;
}

double WroughtwildSim::removal_refund_fraction() const {
    return require_loaded("removal_refund_fraction") ? tuning_->construction.removalRefundFraction : 0.0;
}

void WroughtwildSim::add_material(const String& material_id, int amount) {
    if (require_loaded("add_material")) {
        wroughtwild::economy::add(player_->inventory, {{to_std(material_id), amount}});
    }
}

bool WroughtwildSim::consume_material(const String& material_id, int amount) {
    if (!require_loaded("consume_material")) {
        return false;
    }
    const std::map<std::string, int> amounts{{to_std(material_id), amount}};
    if (!wroughtwild::economy::hasAll(player_->inventory, amounts)) {
        return false;
    }
    wroughtwild::economy::remove(player_->inventory, amounts);
    return true;
}

bool WroughtwildSim::can_afford_placement(const String& shape_id, const String& material_family) const {
    return require_loaded("can_afford_placement") &&
           player_->canAffordPlacement(to_std(shape_id), to_std(material_family));
}

bool WroughtwildSim::pay_placement(const String& shape_id, const String& material_family) {
    return require_loaded("pay_placement") && player_->payPlacement(to_std(shape_id), to_std(material_family));
}

int WroughtwildSim::refund_removal(const String& shape_id, const String& material_family) {
    return require_loaded("refund_removal") ? player_->refundRemoval(to_std(shape_id), to_std(material_family)) : 0;
}

int WroughtwildSim::material_count(const String& material_id) const {
    if (!require_loaded("material_count")) {
        return 0;
    }
    const auto it = player_->inventory.find(to_std(material_id));
    return it == player_->inventory.end() ? 0 : it->second;
}

void WroughtwildSim::add_station(const String& station_id) {
    if (require_loaded("add_station")) {
        player_->addAvailableStation(to_std(station_id));
    }
}

bool WroughtwildSim::has_station(const String& station_id) const {
    return require_loaded("has_station") && player_->stationAvailable(to_std(station_id));
}

int WroughtwildSim::skill_xp(const String& skill_id) const {
    return require_loaded("skill_xp") ? player_->skillXp(to_std(skill_id)) : 0;
}

int WroughtwildSim::skill_level(const String& skill_id) const {
    return require_loaded("skill_level") ? player_->skillLevel(to_std(skill_id)) : 0;
}

Dictionary WroughtwildSim::craft(const String& recipe_id, bool for_order) {
    Dictionary d;
    d["crafted"] = false;
    if (!require_loaded("craft")) {
        return d;
    }
    const auto result = player_->craft(to_std(recipe_id), for_order);
    d["crafted"] = result.crafted;
    d["xp_granted"] = result.xpGranted;
    d["xp_multiplier"] = result.xpMultiplier;
    if (!result.crafted) {
        const auto& f = result.failure;
        d["failure"] = f.unknownRecipe        ? "unknown_recipe"
                       : f.stationUnavailable ? "station_unavailable"
                       : f.skillTooLow        ? "skill_too_low"
                       : f.missingInputs      ? "missing_inputs"
                                              : "unknown";
    }
    return d;
}

bool WroughtwildSim::salvage(const String& recipe_id) {
    return require_loaded("salvage") && player_->salvage(to_std(recipe_id));
}

} // namespace godot
