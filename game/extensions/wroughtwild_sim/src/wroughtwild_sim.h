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

    // --- player economy (one player, prototype scope) ---
    void add_material(const String& material_id, int amount);
    int material_count(const String& material_id) const;
    void add_station(const String& station_id);
    bool has_station(const String& station_id) const;
    int skill_xp(const String& skill_id) const;
    int skill_level(const String& skill_id) const;

    // Runs the sim's craft rule. Keys: crafted, xp_granted, xp_multiplier and,
    // when not crafted, failure (unknown_recipe | station_unavailable |
    // skill_too_low | missing_inputs).
    Dictionary craft(const String& recipe_id, bool for_order = false);
    bool salvage(const String& recipe_id);

protected:
    static void _bind_methods();

private:
    bool require_loaded(const char* method) const;

    std::unique_ptr<wroughtwild::tuning::Tuning> tuning_;
    std::unique_ptr<wroughtwild::economy::PlayerEconomy> player_;
    String last_error_;
};

} // namespace godot
