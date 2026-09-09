#pragma once

// GDExtension binding of the engine-neutral rules library (sim/). This class
// is the only door from GDScript into the economy rules; scripts must not
// re-implement crafting, skill or salvage logic (game/README.md boundaries).

#include <set>
#include <memory>
#include <string>

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/variant/array.hpp>
#include <godot_cpp/variant/dictionary.hpp>
#include <godot_cpp/variant/packed_int32_array.hpp>
#include <godot_cpp/variant/packed_string_array.hpp>
#include <godot_cpp/variant/string.hpp>

#include "wroughtwild/boons.h"
#include "wroughtwild/combat.h"
#include "wroughtwild/contraptions.h"
#include "wroughtwild/leyline.h"
#include "wroughtwild/daycycle.h"
#include "wroughtwild/economy.h"
#include "wroughtwild/grammar.h"
#include "wroughtwild/lattice.h"
#include "wroughtwild/stats.h"
#include "wroughtwild/trial.h"
#include "wroughtwild/tuning.h"
#include "wroughtwild/worldgen.h"

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
    // Keys: id, display_name, material_cost, size (Vector3), element (the
    // lattice slot: block, wall, floor, post, beam), form (box, stairs,
    // wedge, door), oriented, cells_tall, fine, fine_of (the full-size twin
    // of a fine shape), requires_world_effect, unlocked.
    Dictionary shape(const String& shape_id) const;
    bool shape_unlocked(const String& shape_id) const;
    // Building families (construction.json materials): ids in data order.
    PackedStringArray build_material_ids() const;
    // Keys: id, display_name, source, traits, texture, tint, carried (units
    // of the source item in the pack).
    Dictionary build_material(const String& material_id) const;
    // True when the family has every trait the shape requires.
    bool shape_allows_family(const String& shape_id, const String& material_family) const;
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

    // --- itemisation (D-014, docs/systems/items-and-modifiers.md) ---
    PackedStringArray slot_ids() const;
    PackedStringArray item_base_ids() const;
    // Keys: id, display_name, slot, material, implicit_properties,
    // implicit_modifiers (array of modifier entries), allowed_modifier_tags.
    Dictionary item_base(const String& base_id) const;
    PackedStringArray modifier_ids() const;
    // Keys: id, display_name, tags, applies_to_tags, effect_key, display, self,
    // tiers (array of {tier, minimum, maximum}).
    Dictionary modifier(const String& modifier_id) const;
    // Rolled gear carried in the pack: array of item entries (keys: index,
    // base_id, display_name, slot, rarity, armour, fire_resistance, max_life,
    // area_size, mods (array of {id, display_name, tier, value, sentence,
    // source}), rolled).
    Array pack_items() const;
    // Wears pack item `index` in its base's slot; anything worn there returns
    // to the pack with its modifiers. False when the index is out of range.
    bool equip_pack_item(int index);
    // Returns the worn item of a slot to the pack. False when empty.
    bool unequip(const String& slot);
    // Every modifier in force (worn gear plus debug toggles): array of
    // modifier entries with source.
    Array active_modifiers() const;
    // Rolls a rarity item of base_id into the pack; returns its index or -1.
    int roll_item_into_pack(const String& base_id, const String& rarity, int tier, int seed);
    // Cooldown after cooldown-recovery modifiers.
    double skill_cooldown_seconds(const String& skill_id) const;
    // The skill's spatial extent multiplier after reach modifiers (D-023): an
    // area's radius, a projectile's flight, a strike's reach.
    double skill_reach(const String& skill_id) const;
    // The self ingots' readings beside the skill (D-023 slice 2): life a
    // kill with it restores; {armour, seconds} a cast of it grants.
    double skill_life_on_kill(const String& skill_id) const;
    Dictionary skill_cast_armour(const String& skill_id) const;
    // What an enemy's hit on the player is multiplied by for the statuses
    // it carries (of chill, ignite, bleed): the Ward reading.
    double ward_multiplier(const PackedStringArray& carried_statuses) const;

    // --- grammar (docs/systems/skill-grammar.md) ---
    // Debug toggles (F1-F3): force one non-self modifier at its tier-1
    // maximum, on top of what gear supplies.
    PackedStringArray skill_mod_ids() const;
    // Keys: id, display_name, applies_to_tags, active, effect (dict), sentence.
    Dictionary skill_mod(const String& mod_id) const;
    void set_skill_mod_active(const String& mod_id, bool active);
    bool skill_mod_active(const String& mod_id) const;
    // Resolved numbers for the active mod set (the sim owns them all):
    int fork_count(const String& skill_id) const;
    double fork_damage_fraction(const String& skill_id, int generation) const;
    // Status buildup one hit of the skill applies (0 when the skill has no
    // such payload and no flat add_*_buildup modifier reaches its tags).
    double chill_applied(const String& skill_id, bool is_boss) const;
    double ignite_applied(const String& skill_id, bool is_boss) const;
    double bleed_applied(const String& skill_id, bool is_boss) const;
    // Keys: buildup_max, freeze_duration_s, decay_per_s.
    Dictionary chill_status() const;
    // Keys: buildup_max, decay_per_s, duration_s, damage_per_s,
    // moving_multiplier (after ignite/bleed-tagged modifiers).
    Dictionary ignite_status() const;
    Dictionary bleed_status() const;
    // Keys: enabled, nova_damage, nova_damage_type, nova_radius_m,
    // executes_frozen, executes_boss.
    Dictionary shatter_for(const String& skill_id) const;
    // The shatter hook's numbers regardless of trigger, for a form that
    // cashes in a freeze from a spell (Brittle).
    Dictionary shatter_rules() const;
    // The reactions' hooks (D-023, the flow), read per skill by the engine.
    int skill_echo_every(const String& skill_id) const;
    bool skill_quenches(const String& skill_id) const;
    double skill_nova_chill(const String& skill_id) const;
    double skill_sear(const String& skill_id) const;
    bool skill_brittle(const String& skill_id) const;
    double skill_arc(const String& skill_id) const;
    // The Marrow's and the Quicksilver's skill hooks (D-023 slice 8).
    double skill_life_on_hit(const String& skill_id) const;
    double skill_refund_on_kill(const String& skill_id) const;
    double skill_haste_on_kill(const String& skill_id) const;
    // Rails (D-023 slice 9): the projectiles a cast fires and how many
    // enemies each pierces; the specialisation and the rails themselves.
    // Melee's space control (Wave 5 item 11): the stagger and the shove a
    // skill deals the mob it hits.
    double skill_stagger(const String& skill_id, bool is_boss = false) const;
    double skill_push(const String& skill_id, bool is_boss = false) const;
    int skill_projectiles(const String& skill_id) const;
    int skill_pierce(const String& skill_id) const;
    bool foundry_choose_class(const String& class_id);
    bool foundry_specialise(const String& specialisation);
    bool foundry_set_rail(const String& axis, int index, const String& pattern);
    bool foundry_clear_rail(const String& axis, int index);
    Dictionary foundry_pattern(const String& pattern_id) const;
    // Links (D-023): every link on the plate [{first, second, row, col,
    // support_row, support_col}]; the triggers a skill can fire (freeze,
    // ignite, bleed); the skills that cast themselves when skill_id's
    // trigger fires.
    Array foundry_links() const;
    PackedStringArray skill_triggers(const String& skill_id) const;
    PackedStringArray linked_casts(const String& skill_id, const String& trigger) const;
    // Keys: enabled, radius_m, spread_buildup, spread_buildup_boss.
    Dictionary proliferate_for() const;

    // --- skill loadout (D-016: skills are learned, not worn) ---
    // The build's identity: the union of tags across the skills on the bar.
    PackedStringArray player_build_tags() const;
    // Every skill the player knows, in learning order (starting skills first).
    PackedStringArray known_skill_ids() const;
    bool knows_skill(const String& skill_id) const;
    // The action bar: skill_bar_size() entries, "" for an empty slot.
    int skill_bar_size() const;
    PackedStringArray skill_bar() const;
    // Puts skill_id in slot (moving it if it sits elsewhere); "" clears.
    // False for a bad slot or a skill the player does not know.
    bool set_bar_slot(int slot, const String& skill_id);
    // Learns a skill (from a page): it takes the first empty bar slot, if
    // any. False when unknown to tuning or already known.
    bool learn_skill(const String& skill_id);

    // --- Wave 1 sandpit ---
    // The generated bounded world for a seed (deterministic). Keys: seed,
    // width, height, depth (vertical block levels), cell_size, heights +
    // biomes (PackedInt32Array, row-major z*width+x), blocks
    // (PackedByteArray, column-contiguous (z*width+x)*depth+y; ids 0 air,
    // 1 surface, 2 dirt, 3 stone, 4 bedrock), biome_defs (array of {id,
    // display_name, surface}), nodes (array of {type, x, y, z,
    // material_family, display_name, units, units_per_harvest, visual}),
    // packs (array of {enemies, x, z}), spawn_x/z, gate_x/z.
    Dictionary world_map(int seed);
    bool set_campaign_policy(const String& policy);
    String campaign_policy() const;
    String resonance_json() const;
    String resonance_second_json() const;
    String resonance_signature() const;
    bool resonance_queue(int seed);
    bool resonance_prepare(int seed, const Array& protection);
    bool resonance_validate_world(const String& profile, int seed);
    // Active generation identity. Unknown profiles never replace the current
    // selection; old direct callers default to legacy_v1.
    bool set_world_profile(const String& profile_id);
    String world_profile() const;
    // The world's render/collision geometry, chunked (the sim derives it so
    // the engine never re-walks a million blocks in script): one entry per
    // chunk_cells x chunk_cells column chunk - {x, z, kinds: {kind ->
    // PackedVector3Array of visible-block centres; kind is the biome
    // surface key, "dirt", "stone" or "bedrock"}, faces: PackedVector3Array
    // of exposed-face collision triangles (use backface_collision)}.
    // Optional engine-authored sRGB palette adds blend_colours to faceted
    // surfaces: RGB is linear albedo; alpha carries the stone-detail weight.
    // Empty palette retains the previous output/behaviour, except an empty
    // blend_colours dictionary. The palette never changes collision or saves.
    Array world_mesh(int seed, int chunk_cells, bool faceted = false, const Dictionary& palette = Dictionary());
    // One chunk's geometry with engine edits applied: removed_blocks is a
    // flat PackedInt32Array of x,y,z triples (dug blocks) treated as air.
    // The digging loop rebuilds only the touched chunk(s) through this.
    Dictionary world_mesh_chunk(int seed, int chunk_cells, int chunk_x, int chunk_z,
                                const PackedInt32Array& removed_blocks, bool faceted = false, const Dictionary& palette = Dictionary());
    // Rules for breaking generic terrain blocks, by kind ("surface",
    // "dirt", "stone", "bedrock"): {breakable, dig_seconds, yields}.
    Dictionary block_rules() const;
    Dictionary fire_setting() const;

    // --- the building lattice (Wave 4, lattice.h, D-017) ---
    // An element is a Dictionary {kind: "volume" | "face" | "edge", axis:
    // 0..2, cell: Vector3i} - the canonical address of a cell, a face two
    // cells share, or an edge four share. Cells are REGISTRY coordinates:
    // the occupancy registry runs lattice_divisions times finer than the
    // build grid, and a full-size piece anchors at a registry element
    // aligned to the build grid and covers a footprint of them. Two pieces
    // conflict only when their footprints share an element.
    //
    // The registry's cell size in metres (grid_size / lattice_divisions).
    double lattice_registry_grid() const;
    // Anchor elements the shape could take around a surface hit, nearest
    // the point first. Each entry is an element plus centre (Vector3, the
    // whole footprint's centre) and yaw_turns (quarter turns for a shape
    // authored thin along z / long along x). The host filters by what its
    // world knows (occupancy, terrain, props) and takes the first survivor.
    // fine_grid: generate on the registry lattice instead of the build
    // grid, so a full-size piece can sit on a half-scale one (the piece you
    // build on decides the grid).
    Array lattice_candidates(const String& shape_id, const Vector3& point, const Vector3& normal,
                             bool fine_grid) const;
    // Pose of the shape anchored at an element: {centre, yaw_turns}.
    Dictionary lattice_pose(const String& shape_id, const Dictionary& element) const;
    // Exact registry elements covered by a valid shape/anchor. The host
    // checks terrain exposure for each; span/tall/long stay native rules.
    Array lattice_footprint(const String& shape_id, const Dictionary& element) const;
    // True when the shape may anchor on the element: the right kind of
    // element for its slot.
    bool shape_accepts(const String& shape_id, const Dictionary& element) const;
    // True when the shape anchored here would touch something already
    // built (its footprint's box grown by one registry cell holds a placed
    // element): what lets a piece continue out into empty air.
    bool structure_touches(const String& shape_id, const Dictionary& element) const;
    // True when a placed element lies within one registry cell of the point.
    bool structure_near_point(const Vector3& point) const;
    int structure_piece_count() const;

    // The player's structure: what stands on which element. The host
    // mirrors it with scene nodes and rebuilds it from a save.
    bool structure_occupied(const Dictionary& element) const;
    // True when every element of the shape's footprint from this anchor is
    // free (what the preview asks before structure_place would succeed).
    bool structure_free_for(const String& shape_id, const Dictionary& element) const;
    // The piece covering an element - {shape, family, rotation_step, slot}
    // plus its anchor's element keys - or {} when free.
    Dictionary structure_piece(const Dictionary& element) const;
    // Anchors the shape at the element (its footprint follows from the
    // shape). False when any of the footprint is taken or the shape may
    // not anchor there.
    bool structure_place(const Dictionary& element, const String& shape_id, const String& family,
                         int rotation_step);
    // Removes the piece covering the element.
    bool structure_remove(const Dictionary& element);
    void structure_clear();
    // Every piece as structure_piece entries.
    Array structure_pieces() const;
    // Vertical registry edges (as elements, with centre) that want a corner
    // post drawn: where walls end or meet at an angle and no real post
    // stands. A post visual is one registry cell tall.
    Array structure_trim_edges() const;
    // Shelter (slice 3): is the world position inside an enclosed room?
    // Flood-fills open registry volumes from the position, stopped by the
    // structure's faces and volumes and by the seed's terrain with the
    // dug blocks (x,y,z triples) removed; a room is a shelter when the
    // fill closes before shelter().max_room_cells build cells without
    // reaching open sky. seed < 0 means no terrain at all (test scenes).
    // Keys: enclosed, cells (build cells reached).
    Dictionary structure_enclosure(int seed, const PackedInt32Array& removed_blocks, const Vector3& at);
    // world.json shelter: regen_life_per_round, settle_rounds, max_room_cells.
    Dictionary shelter() const;

    // --- day and night (Wave 6 slice 5) ---
    // The sim keeps the clock; the engine advances it by seconds of play.
    void advance_time(double seconds);
    // Where the clock stands: index, fraction, phase (dawn|day|dusk|night),
    // daylight (1 by day, night_light at the dead of night), night,
    // seconds_to_night, seconds_to_dawn, clock_seconds.
    Dictionary day() const;
    // world.json day: length_seconds, night_light, exposure_life_per_second
    // (already per second of play), exposure_floor_fraction,
    // night_aggro_multiplier, night_sleep_range_multiplier,
    // shelter_night_regen_multiplier.
    Dictionary day_rules() const;
    // Tests: set the clock outright (seconds of play).
    void set_day_clock(double seconds);

    // --- hauling (Wave 6 slice 6) ---
    // world.json hauling: carry_cap_default, chest_units.
    Dictionary hauling_rules() const;
    // Noise (Wave 7 slice 1): combat_realtime.json noise - radius_m by
    // source kind (work, tree_fall, rock_crack, strike, fight, horn) and
    // muffle, the fraction a closed room lets out.
    Dictionary noise_rules() const;
    // The train (Wave 7 slice 2): combat_realtime.json horde train_* -
    // window_seconds, bonus_per_hit, max_bonus - and the multiplier a bite
    // lands with after earlier_hits bites from other mobs in the window.
    Dictionary train_rules() const;
    double train_multiplier(int earlier_hits) const;
    // The current era's ceiling on armour's reduction (eras.json).
    double armour_reduction_cap() const;
    // The siege (Wave 7 slice 3): world.json siege - first_night,
    // chance_per_night, arrive_seconds_into_night, spawn_radius_m,
    // home_radius_m, timber_break_hits; whether the hounds come on a
    // night of the world; the current era's siege pack.
    Dictionary siege_rules() const;
    bool siege_tonight(int seed, int day_index) const;
    PackedStringArray siege_pack() const;
    // Equal threat, different shape (Wave 8 slice 1): a family's threat
    // score - damage per round, reach, bulk and its verb's control.
    double threat_score(const String& enemy_id) const;
    // The curio and the lock (Wave 8 slice 2): set the curio a landmark
    // wants (false without it); what a landmark wants ({curio,
    // display_name, held}, empty for nothing); the readings of the curios held.
    bool set_curio(const String& landmark_id);
    Dictionary landmark_wants(const String& landmark_id) const;
    PackedStringArray curio_hints() const;
    // The mingling (Wave 8 slice 3): the foreign family a pack spawning in
    // `biome` takes this era, or "" - the sim's pick, deterministic per salt.
    String mingle_pick(const String& biome, int salt) const;
    // The pack's cap for a family (0 = uncapped) and the room left in it.
    int carry_cap(const String& family) const;
    int carry_room(const String& family) const;
    // Takes up to the room from the ground; returns what it took.
    int haul(const String& family, int amount);
    // Chests, keyed by the engine (a placed piece's element key): move
    // stacks between the pack and the store (returns what moved), read a
    // store, its units and its room, and empty one (returns its contents).
    int store_deposit(const String& key, const String& family, int amount);
    int store_withdraw(const String& key, const String& family, int amount);
    Dictionary store_contents(const String& key) const;
    int store_units(const String& key) const;
    int store_room(const String& key) const;
    Dictionary store_remove(const String& key);

    // --- the peddler (crafting.json market) ---
    // [{item, count, price, currency, affordable}].
    Array market_offers() const;
    // Typed currency (D-023 slice 3): every kind with what the player holds
    // of it - [{id, display_name, family, held, exchangeable}] - and the
    // peddler's exchange: rate of one kind for one of another.
    Array currency_kinds() const;
    int exchange_rate() const;
    bool can_exchange(const String& from_kind, const String& to_kind) const;
    bool exchange(const String& from_kind, const String& to_kind);
    bool buy(const String& item_id);
    // --- trial floors (D-019) ---
    // Deeper runs the gate can offer: [{id, display_name, available, done}].
    Array trial_floors() const;
    // The active run's floor: {id, display_name, completion_text}; id "" for the first floor.
    Dictionary trial_floor() const;

    // --- skill mastery (D-019) ---
    // A cast that fired; returns the perk texts it unlocked (usually none).
    PackedStringArray note_skill_use(const String& skill_id);
    // Throws a pack item away (no refund). False for a bad index.
    bool discard_pack_item(int index);

    // --- items as mechanics (D-019) ---
    // Pack items in the worn item's slot that a Preserving Transfer could
    // carry the worn rolls onto: item entries with index and display_name.
    Array transfer_targets(const String& process_id) const;
    // Moves the worn item's rolled modifiers (in the target's slot) onto the
    // pack item at target_index; the worn base and one catalyst are spent.
    // Keys: applied, reason (no_source | wrong_process | station_unavailable
    // | missing_catalyst | skill_too_low | bad_target), moved (count).
    Dictionary transfer_with_catalyst(const String& process_id, int target_index);

    // --- the Foundry (foundry.json, D-019, D-023): ingots on the frame the era has forged ---
    // {rows, cols, era, plate: [{row, col, ingot}], owned: {id: n},
    // unplaced: {id: n}, reforge_cost: {item: n}, can_reforge}.
    Dictionary foundry() const;
    PackedStringArray foundry_ingot_ids() const;
    // {id, display_name, verb, modifier, value, sentence, owned, unplaced}.
    Dictionary foundry_ingot(const String& ingot_id) const;
    // What the plate does now: [{kind: ingot|pair|support|added|backing,
    // label, sentence, modifier, value, skill, row, col, cell_row, cell_col}].
    Array foundry_effects() const;
    Dictionary skill_mutation(const String& skill_id) const;
    Dictionary foundry_preview(int row, int col, const String& piece_id, const String& metal_id) const;
    bool foundry_place(int row, int col, const String& ingot_id, const String& metal_id = String());
    // The metal of an ingot (D-023 slice 10): re-casting at the forge.
    bool foundry_recast(const String& ingot_id, const String& metal_id);
    bool can_recast(const String& ingot_id, const String& metal_id) const;
    bool foundry_remove(int row, int col);
    bool foundry_place_skill(int row, int col, const String& skill_id);
    // Sets a currency kind from the purse on a forged cell that cannot
    // touch a socket (D-023, the flow). Lifting returns it to the purse.
    bool foundry_place_kind(int row, int col, const String& kind_id);
    // Reports a milestone the engine saw ("first_kill:ash_hound"); returns
    // the ingot ids it granted (each source once).
    Array foundry_event(const String& event);
    // Ingot ids granted by the economy's own milestones (crafts, world
    // effects, eras) since last asked, for notices.
    Array foundry_notices();

    // --- eras (eras.json, D-019): the world's state, from milestones ---
    // {index (1-based), id, display_name, story}.
    Dictionary era() const;
    // The current era's parameters for an enemy's mechanic ({} when none):
    // eras.json mob_mechanics, e.g. ash_hound pack_size_bonus -> {value}.
    Dictionary era_mechanic(const String& enemy_id, const String& mechanic) const;
    // Records a world effect (trial rewards do this; tests and debug too).
    void record_world_effect(const String& effect);

    // Deterministic per-kill drops from the enemy's world.json loot table:
    // material stacks as item -> count. elite_id ("" for none) applies the
    // elite modifier's loot bonuses (Wave 3): extra table passes.
    Dictionary enemy_loot(const String& enemy_id, int seed, const String& elite_id);
    // The rolled gear the same kill drops (array of item entries as in
    // pack_items, index -1): a preview for spawning pickups. Nothing enters
    // the pack until claim_enemy_gear repeats the roll for the same kill
    // (same enemy, seed AND elite_id - the pickup remembers all three).
    Array enemy_gear_loot(const String& enemy_id, int seed, const String& elite_id);
    // Rolls the kill's gear again into the pack; returns the entries added.
    Array claim_enemy_gear(const String& enemy_id, int seed, const String& elite_id);
    // The skill page the kill drops given what the player knows now: a skill
    // id to learn_skill on pickup, or "" for no page.
    String enemy_skill_page(const String& enemy_id, int seed, const String& elite_id) const;
    // The elite prefixes mobs can spawn with (world.json elite_modifiers).
    PackedStringArray elite_modifier_ids() const;
    // Keys: id, display_name, life/speed/damage_multiplier, immune_statuses,
    // death_burst_damage/radius_m/type, extra_loot_rolls,
    // gear/page_chance_multiplier. Empty for an unknown id.
    Dictionary elite_modifier(const String& elite_id) const;
    // Station founded by placing this kit item ("" when not a kit).
    String kit_station(const String& kit_item_id) const;
    PackedStringArray kit_item_ids() const;
    // Fuel item -> value per unit, and the total fuel value carried.
    Dictionary fuels() const;
    int fuel_value_held() const;

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
    Dictionary craft(const String& recipe_id, bool for_order = false, const String& aim_kind = "", int quality = 1, int quantity = 1);
    Dictionary craft_preview(const String& recipe_id, const String& aim_kind = "", int quality = 1, int quantity = 1) const;
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
    // Keys: id, display_name, delivery (cone | strike | projectile | dash),
    // tags, starting, drop_weight, plus every numeric field of skills.json
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
    // The same hit as typed packets (D-023 slice 2): [{type, damage,
    // added}], rolled through the fight's stream exactly as
    // player_hit_damage rolls one number. The engine deals each packet and
    // lets the mob refuse the types it is immune to.
    // target_statuses: what the struck mob carries (of chill, ignite,
    // bleed), for the forms' reactions ("an ignited enemy takes 20% more").
    Array player_hit(const String& skill_id, bool isolated, const PackedStringArray& target_statuses = PackedStringArray());
    // Damage the player takes from one enemy hit, after mitigation.
    // bonus_armour: armour the engine is granting right now (the Plate
    // reading's armour on cast), counted with the sheet's.
    double enemy_hit_damage(double raw_damage, const String& damage_type, double bonus_armour = 0.0);
    // Mitigation without variance, for previews and UI.
    double mitigate(double amount, const String& damage_type) const;

    // --- equipment and tempering ---
    // Keys per slot: base_id, display_name, armour, fire_resistance,
    // max_life, area_size, rolled (array of {property, tier, value}).
    Dictionary equipment() const;
    // Read-only swap preview. A nonnegative index selects pack gear; -1 selects
    // a carried plain base. Rules resolve against a local equipment copy.
    Dictionary compare_equipment(int pack_index, const String& base_id) const;
    // Takes one plain item of base_id from the inventory and wears it in its
    // base's slot; anything already worn there goes to the pack with its
    // modifiers intact (D-014). False when none is carried.
    bool equip_from_inventory(const String& base_id);
    // Keys: id, display_name, catalyst, station, process, minimum_skill,
    // guaranteed_property, property_display_name, result_tier, tier_minimum,
    // tier_maximum, floor_at_skill, catalyst_held, station_available,
    // skill_met, armour_equipped.
    Dictionary catalyst_process(const String& process_id) const;
    PackedStringArray catalyst_process_ids() const;
    // Keys: process, property, property_display_name, tier, value,
    // station_available, armour_equipped, current_value.
    Dictionary basic_temper_info() const;
    // Deterministic baseline: adds the configured property at the tier
    // midpoint. Keys: applied, reason (no_armour | station_unavailable),
    // value.
    Dictionary temper_basic();
    // Consumes one catalyst and applies the process. Keys: applied, reason
    // (no_armour | station_unavailable | missing_catalyst | skill_too_low |
    // wrong_tier), rolled_value, previous_value.
    Dictionary temper_with_catalyst(const String& process_id);
    // Tests fix the roll; the default seed is random per load.
    void set_temper_seed(int seed);

    // --- trial (one run at a time; the sim's TrialSession is the authority
    // on deposit, rooms, offers, loot and the death contract) ---
    // Deposits carried materials at the gate and opens a run. False when a
    // run is already open.
    // floor_id "" for the first floor, else a trial_floors() id.
    bool trial_start(int seed, const String& floor_id);
    bool trial_start_story(int seed, const String& run_id);
    Array trial_story_runs() const;
    Dictionary trial_layout() const;
    Dictionary trial_rules() const;
    Array trial_map_offers(int tier) const;
    bool trial_start_map(int tier, int offer_index);
    Dictionary trial_map_progress() const;
    bool trial_continue_floor();
    void trial_skip_reward();
    Dictionary trial_claim_secret();
    String trial_checkpoint() const;
    bool trial_checkpoint_valid(const String& text) const;
    bool trial_checkpoint_matches(const String& text, const String& player_state) const;
    bool trial_restore_checkpoint(const String& text);
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

public:
    PackedStringArray contraption_kinds() const;
    bool leyline_bind_world(const String& profile, int seed);
    Array leyline_sources() const;
    Dictionary leyline_work(const String& id);
    Dictionary leyline_collect(const String& id, const String& item);
    void leyline_tick(double seconds, const PackedStringArray& blocked);
    String leyline_save() const;
    bool leyline_validate_world(const String& text, const String& profile, int seed) const;
    bool leyline_load_world(const String& text, const String& profile, int seed);
    String contraption_kind_for_kit(const String& kit) const;
    bool contraption_place(const String& kind, const String& key, const Vector3& position, int rotation);
    Dictionary contraption_remove(const String& key);
    PackedStringArray contraption_ids() const;
    Dictionary contraption_state(const String& key) const;
    Dictionary contraption_config() const;
    Dictionary contraption_feeder_inspect(const String& key, bool physical_ready) const;
    Dictionary contraption_link(const String& key, const String& target, bool clear);
    Dictionary contraption_link_second(const String& key, const String& target, bool clear);
    Dictionary contraption_request(const String& key, const Dictionary& space);
    Dictionary contraption_request_tick(const String& key, double seconds, const Dictionary& space);
    Dictionary contraption_action(const String& key, const String& action, bool clear=true, bool other_clear=true, double distance=0);
    Dictionary contraption_tick(const String& key, double seconds, bool clear);
    Dictionary contraption_delay_tick(const String& key, double seconds, bool clear, bool receiver_clear);
    Dictionary contraption_deposit(const String& key, const String& item, int count);
    Dictionary contraption_withdraw(const String& key, const String& port, const String& item, int count);
    String contraption_save() const;
    bool contraption_validate(const String& text) const;
    bool contraption_load(const String& text);
    bool contraption_bind_world(const String& profile, int seed);
    bool contraption_validate_world(const String& text, const String& profile, int seed) const;
    bool contraption_load_world(const String& text, const String& profile, int seed);
    Array contraption_pressure_sources() const;
    Dictionary contraption_attach_feeder(const String& key, const String& source_id,
        const String& forge_key, const Vector3& forge_position, bool clear);
    Array rare_resource_guide() const;

private:
    bool require_loaded(const char* method) const;

    const wroughtwild::tuning::CombatSkillDef* find_skill(const String& skill_id) const;
    // One hit of skill_id as typed packets, rolled through the fight's stream.
    wroughtwild::grammar::Hit rolled_hit(const String& skill_id, bool isolated, const PackedStringArray& target_statuses);
    wroughtwild::combat::CombatMods current_mods() const;
    wroughtwild::boons::BuildTags build_tags() const;
    wroughtwild::grammar::ActiveMods active_mods(const wroughtwild::stats::Equipment* preview = nullptr) const;
    // Generates (or reuses) the world for a seed; generation costs real time.
    const wroughtwild::worldgen::WorldMap& cached_world(uint64_t seed);
    const wroughtwild::tuning::WorldgenTable& world_table() const;
    wroughtwild::contraptions::WorldIdentity machine_world_identity(const String& profile, int seed) const;
    // The elite modifier for an id, or nullptr for "" / unknown.
    const wroughtwild::tuning::EliteModifierDef* find_elite(const String& elite_id) const;
    // Character stats with the Foundry's stat ingots applied.
    wroughtwild::stats::DerivedStats derived_now(const wroughtwild::stats::Equipment* preview = nullptr) const;

    std::unique_ptr<wroughtwild::tuning::Tuning> tuning_;
    std::unique_ptr<wroughtwild::contraptions::MachineWorld> contraptions_;
    wroughtwild::leyline::Config leyline_config_;
    wroughtwild::resonance::Config resonance_config_;
    mutable std::string world_cache_resonance_;
    std::unique_ptr<wroughtwild::leyline::World> leylines_;
    std::map<std::string, Vector3> leyline_positions_; // bound geography, independent of validation's cache
    std::unique_ptr<wroughtwild::economy::PlayerEconomy> player_;
    wroughtwild::stats::Equipment equipment_;
    std::unique_ptr<wroughtwild::trial::TrialSession> trial_; // null outside a run
    wroughtwild::trial::GateState trial_gate_;
    std::unique_ptr<wroughtwild::combat::HitStream> hits_;
    mutable std::unique_ptr<wroughtwild::worldgen::WorldMap> world_cache_; // last queried identity, including validated restores
    std::string world_profile_ = "legacy_v1";
    wroughtwild::lattice::Structure structure_; // the player's placed pieces
    std::set<std::string> active_skill_mods_; // debug toggles (F1-F3)
    uint64_t temper_seed_ = 0;
    String last_error_;
};

} // namespace godot
