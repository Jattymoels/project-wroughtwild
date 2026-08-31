#include "wroughtwild_sim.h"

#include <exception>

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

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
