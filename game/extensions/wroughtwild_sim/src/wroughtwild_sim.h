#pragma once

// GDExtension binding of the engine-neutral rules library (sim/). This class
// is the only door from GDScript into the economy rules; scripts must not
// re-implement crafting, skill or salvage logic (game/README.md boundaries).

#include <memory>
#include <string>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

#include "wroughtwild/economy.h"
#include "wroughtwild/tuning.h"

namespace godot {

class WroughtwildSim : public RefCounted {
    GDCLASS(WroughtwildSim, RefCounted)

public:
    // Loads every data/tuning/*.json from the directory. Returns false and
    // records last_error() when a file is missing or malformed.
    bool load_tuning(const String& tuning_directory);
    bool is_loaded() const { return static_cast<bool>(tuning_); }
    String last_error() const { return last_error_; }

    // --- tuning views ---
    PackedStringArray recipe_ids() const;
    Dictionary recipe(const String& recipe_id) const;
    double salvage_return_fraction() const;
    PackedStringArray shape_ids() const;
    int shape_material_cost(const String& shape_id) const;
    double grid_size() const;
    double placement_range() const;
    double removal_refund_fraction() const;

    PackedStringArray station_ids() const;
    // Keys: id, display_name, tier, build_cost, upgrade_from, upgrade_cost, available.
    Dictionary station(const String& station_id) const;
    PackedStringArray order_ids() const;
    // Keys: id, display_name, required_outputs, rewards, world_effect, fulfilled.
    Dictionary order(const String& order_id) const;
    // Keys: id, display_name, level, xp, max_level, next_level_xp (-1 at max).
    Dictionary skill_progress(const String& skill_id) const;

    // --- player economy (one player, prototype scope) ---
    Dictionary inventory() const;
    Dictionary currency() const;
    int currency_count(const String& currency_id) const;
    void add_material(const String& material_id, int amount);
    // Returns false (and consumes nothing) when fewer than amount are held.
    bool consume_material(const String& material_id, int amount);
    int material_count(const String& material_id) const;

    // Construction: shapes are paid in the selected material family at the
    // cost in construction.json; removal refunds by removal_refund_fraction.
    bool can_afford_placement(const String& shape_id, const String& material_family) const;
    bool pay_placement(const String& shape_id, const String& material_family);
    int refund_removal(const String& shape_id, const String& material_family);
    void add_station(const String& station_id);
    bool has_station(const String& station_id) const;
    int skill_xp(const String& skill_id) const;
    int skill_level(const String& skill_id) const;

    // Runs the sim's craft rule. Keys: crafted, xp_granted, xp_multiplier and,
    // when not crafted, failure (unknown_recipe | station_unavailable |
    // skill_too_low | missing_inputs).
    Dictionary craft(const String& recipe_id, bool for_order = false);
    bool salvage(const String& recipe_id);
    bool recipe_feeds_open_order(const String& recipe_id) const;

    bool can_build_station(const String& station_id) const;
    bool build_station(const String& station_id);

    // Keys: fulfilled, already_fulfilled, missing_outputs, world_effect.
    Dictionary fulfill_order(const String& order_id);
    bool order_fulfilled(const String& order_id) const;
    bool world_effect_active(const String& effect) const;

protected:
    static void _bind_methods();

private:
    bool require_loaded(const char* method) const;

    std::unique_ptr<wroughtwild::tuning::Tuning> tuning_;
    std::unique_ptr<wroughtwild::economy::PlayerEconomy> player_;
    String last_error_;
};

} // namespace godot
