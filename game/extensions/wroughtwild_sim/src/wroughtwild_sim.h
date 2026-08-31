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

#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/trial.h"
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

    // Keys: id, display_name, yields_per_action, ambush_chance,
    // ambush_enemies, ambush_removed_by_world_effect.
    Dictionary gather_site(const String& site_id) const;

    // --- player economy (one player, prototype scope) ---
    Dictionary inventory() const;
    Dictionary currency() const;
    int currency_count(const String& currency_id) const;
    void add_material(const String& material_id, int amount);
    void add_materials(const Dictionary& amounts);
    // Open-world death (D-006): removes and returns every carried material so
    // the host can leave it where the player fell. Currency and equipment
    // are never dropped.
    Dictionary drop_inventory();
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

    // --- combat numbers (ADR-0003: the sim owns numbers, the engine owns
    // time and space) ---
    // Keys: max_life, armour, fire_resistance_percent, area_bonus.
    Dictionary derived_stats() const;
    PackedStringArray combat_skill_ids() const;
    // Keys: id, display_name, tags, plus every numeric field of skills.json
    // (base_damage, base_area_radius, cooldown_seconds, distance...).
    Dictionary combat_skill(const String& skill_id) const;
    PackedStringArray enemy_ids() const;
    // Keys: id, display_name, max_life, behaviour, damage, damage_type,
    // attack_period_rounds.
    Dictionary enemy(const String& enemy_id) const;
    // Keys: id, display_name, max_life, claw_damage, claw_damage_type,
    // claw_period_rounds, breath_damage, breath_damage_type,
    // breath_period_rounds, breath_telegraph_rounds.
    Dictionary boss() const;
    // combat_realtime.json as nested dictionaries: round_seconds, player,
    // behaviours, boss, dash.
    Dictionary realtime() const;
    // Boon/weakness effects of the current run as numbers: keys
    // enemy_speed_multiplier, reward_quantity_multiplier, repeat_hit_count,
    // repeat_damage_multiplier, isolated_damage_multiplier,
    // isolated_area_multiplier.
    Dictionary combat_mods() const;

    // One deterministic damage stream per fight (same seed + same calls =
    // same numbers). Call begin_fight before the first hit of an encounter.
    void begin_fight(int seed);
    // Damage one player hit of skill_id deals; isolated when the target is
    // the only living enemy.
    double player_hit_damage(const String& skill_id, bool isolated);
    // Damage the player takes from one enemy hit, after mitigation.
    double enemy_hit_damage(double raw_damage, const String& damage_type);
    // Mitigation without variance, for previews and UI.
    double mitigate(double amount, const String& damage_type) const;

    // --- trial (one run at a time; the sim's TrialSession is the authority
    // on deposit, rooms, offers, loot and the death contract) ---
    // Deposits carried materials at the gate and opens a run. False when a
    // run is already open.
    bool trial_start(int seed);
    bool trial_active() const;
    bool trial_finished() const;
    bool trial_player_died() const;
    bool trial_boss_defeated() const;
    // Keys: index, choices (array of {id, display_name, encounter, reward}),
    // can_bank_and_exit, room_in_progress.
    Dictionary trial_stage() const;
    // Keys: started, id, display_name, encounter, seed. Also seeds the hit
    // stream for the fight.
    Dictionary trial_begin_room(int choice_index);
    // Keys: victory, reward_type, boon_offer (array of {id, display_name,
    // design_purpose}), offered_weakness ({id, display_name,
    // reward_multiplier} or empty), catalyst_recovered, materials, finished,
    // died, boss_defeated.
    Dictionary trial_resolve_room(bool victory);
    bool trial_accept_boon(const String& boon_id);
    bool trial_accept_weakness();
    bool trial_bank_and_exit();
    void trial_abandon();
    // Keys: boons, weaknesses (arrays of {id, display_name}).
    Dictionary trial_run_state() const;
    Dictionary trial_loot() const;
    // Closes a finished run so a new one can start. False while unfinished.
    bool trial_end();

    // --- save/load ---
    // The rules state (economy, equipment) in the sim's own SaveGame JSON
    // schema, so engine saves and text-playtest saves stay interchangeable.
    // Schema v1 is not yet declared stable.
    String export_json() const;
    // Replaces the current rules state. Returns false (see last_error) and
    // leaves state untouched when the text is malformed.
    bool import_json(const String& text);

protected:
    static void _bind_methods();

private:
    bool require_loaded(const char* method) const;

    const wroughtwild::tuning::CombatSkillDef* find_skill(const String& skill_id) const;
    wroughtwild::combat::CombatMods current_mods() const;
    wroughtwild::boons::BuildTags build_tags() const;

    std::unique_ptr<wroughtwild::tuning::Tuning> tuning_;
    std::unique_ptr<wroughtwild::economy::PlayerEconomy> player_;
    wroughtwild::stats::Equipment equipment_;
    std::unique_ptr<wroughtwild::trial::TrialSession> trial_; // null outside a run
    std::unique_ptr<wroughtwild::combat::HitStream> hits_;
    String last_error_;
};

} // namespace godot
