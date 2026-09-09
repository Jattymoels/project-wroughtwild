#include "wroughtwild_sim.h"
#include <limits>

#include <algorithm>
#include <exception>
#include <cmath>
#include <random>

#include "wroughtwild/items.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>
#include <godot_cpp/variant/packed_color_array.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>

#include "wroughtwild/grammar.h"
#include "wroughtwild/loot.h"
#include "wroughtwild/save.h"
#include "wroughtwild/worldgen.h"

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

// --- D-014 item views ---------------------------------------------------------

PackedStringArray strings_to_packed(const std::vector<std::string>& values) {
    PackedStringArray out;
    for (const auto& v : values) {
        out.push_back(to_godot(v));
    }
    return out;
}

Dictionary mod_entry(const wroughtwild::tuning::ModifierDef& def, double value, int tier, const std::string& source) {
    Dictionary m;
    m["id"] = to_godot(def.id);
    m["display_name"] = to_godot(def.displayName);
    m["value"] = value;
    m["tier"] = tier;
    m["sentence"] = to_godot(wroughtwild::items::modifierSentence(def, value));
    m["source"] = to_godot(source);
    m["applies_to_tags"] = strings_to_packed(def.appliesToTags);
    m["effect_key"] = to_godot(def.effectKey);
    return m;
}

Dictionary item_entry(const wroughtwild::tuning::Tuning& tuning, const wroughtwild::items::ItemInstance& item,
                      int index) {
    Dictionary d;
    const auto* base = tuning.items.findBase(item.baseId);
    d["index"] = index;
    d["base_id"] = to_godot(item.baseId);
    d["display_name"] = to_godot(base ? base->displayName : item.baseId);
    d["slot"] = to_godot(base ? base->slot : std::string());
    d["rarity"] = to_godot(item.rarity);
    d["tier_cap"] = item.workpieceTier > 0 ? item.workpieceTier : (base ? base->tierCap : 99);
    d["workpiece_tier"] = item.workpieceTier;
    d["material"] = to_godot(base ? base->material : std::string());
    const auto totals = wroughtwild::items::statTotals(tuning.items, item);
    d["armour"] = totals.armour;
    d["fire_resistance"] = totals.fireResistance;
    d["max_life"] = totals.maxLife;
    d["area_size"] = totals.areaSize;
    Array mods;
    if (base) {
        for (const auto& implicit : base->implicitModifiers) {
            const auto* def = tuning.items.findModifier(implicit.id);
            if (def) {
                mods.push_back(mod_entry(*def, implicit.value, 0, "implicit"));
            }
        }
    }
    Array rolled;
    for (const auto& r : item.rolledProperties) {
        const auto* def = tuning.items.findModifier(r.propertyId);
        if (def) {
            const auto eff = wroughtwild::items::effectiveRoll(tuning.items, item, r);
            Dictionary m = mod_entry(*def, eff.value, eff.tier, "rolled");
            m["rolled_tier"] = r.tier;
            m["held_back"] = eff.heldBack;
            m["full_sentence"] = to_godot(wroughtwild::items::modifierSentence(*def, r.value));
            m["unleashed_by"] = eff.heldBack ? String("a base that holds tier ") + String::num_int64(r.tier) : String();
            Array breakpoints;
            for (const auto* bp : wroughtwild::items::breakpointsFor(*def, eff.tier, r.crafted)) {
                breakpoints.push_back(to_godot(bp->text));
            }
            m["breakpoints"] = breakpoints;
            Array locked;
            for (const auto* bp : wroughtwild::items::breakpointsFor(*def, r.tier, r.crafted)) {
                bool have = false;
                for (const auto* got : wroughtwild::items::breakpointsFor(*def, eff.tier, r.crafted)) have = have || got == bp;
                if (!have) locked.push_back(to_godot(bp->text));
            }
            m["held_breakpoints"] = locked;
            mods.push_back(m);
        }
        Dictionary p;
        p["property"] = to_godot(r.propertyId);
        p["tier"] = r.tier;
        p["value"] = r.value;
        rolled.push_back(p);
    }
    d["mods"] = mods;
    d["rolled"] = rolled;
    return d;
}

} // namespace

void WroughtwildSim::_bind_methods() {
    ClassDB::bind_method(D_METHOD("contraption_kinds"), &WroughtwildSim::contraption_kinds);
    ClassDB::bind_method(D_METHOD("contraption_kind_for_kit", "kit"), &WroughtwildSim::contraption_kind_for_kit);
    ClassDB::bind_method(D_METHOD("contraption_place", "kind", "key", "position", "rotation"), &WroughtwildSim::contraption_place);
    ClassDB::bind_method(D_METHOD("contraption_remove", "key"), &WroughtwildSim::contraption_remove);
    ClassDB::bind_method(D_METHOD("contraption_ids"), &WroughtwildSim::contraption_ids);
    ClassDB::bind_method(D_METHOD("contraption_state", "key"), &WroughtwildSim::contraption_state);
    ClassDB::bind_method(D_METHOD("contraption_config"), &WroughtwildSim::contraption_config);
    ClassDB::bind_method(D_METHOD("contraption_feeder_inspect", "key", "physical_ready"), &WroughtwildSim::contraption_feeder_inspect);
    ClassDB::bind_method(D_METHOD("contraption_link", "key", "target", "clear"), &WroughtwildSim::contraption_link);
    ClassDB::bind_method(D_METHOD("contraption_link_second", "key", "target", "clear"), &WroughtwildSim::contraption_link_second);
    ClassDB::bind_method(D_METHOD("contraption_request", "key", "space"), &WroughtwildSim::contraption_request);
    ClassDB::bind_method(D_METHOD("contraption_request_tick", "key", "seconds", "space"), &WroughtwildSim::contraption_request_tick);
    ClassDB::bind_method(D_METHOD("contraption_action", "key", "action", "clear", "other_clear", "distance"), &WroughtwildSim::contraption_action, DEFVAL(true), DEFVAL(true), DEFVAL(0.0));
    ClassDB::bind_method(D_METHOD("contraption_tick", "key", "seconds", "clear"), &WroughtwildSim::contraption_tick);
    ClassDB::bind_method(D_METHOD("contraption_delay_tick", "key", "seconds", "clear", "receiver_clear"), &WroughtwildSim::contraption_delay_tick);
    ClassDB::bind_method(D_METHOD("contraption_deposit", "key", "item", "count"), &WroughtwildSim::contraption_deposit);
    ClassDB::bind_method(D_METHOD("contraption_withdraw", "key", "port", "item", "count"), &WroughtwildSim::contraption_withdraw);
    ClassDB::bind_method(D_METHOD("contraption_save"), &WroughtwildSim::contraption_save);
    ClassDB::bind_method(D_METHOD("contraption_validate", "text"), &WroughtwildSim::contraption_validate);
    ClassDB::bind_method(D_METHOD("contraption_load", "text"), &WroughtwildSim::contraption_load);
    ClassDB::bind_method(D_METHOD("contraption_bind_world", "profile", "seed"), &WroughtwildSim::contraption_bind_world);
    ClassDB::bind_method(D_METHOD("leyline_bind_world", "profile", "seed"), &WroughtwildSim::leyline_bind_world);
    ClassDB::bind_method(D_METHOD("leyline_sources"), &WroughtwildSim::leyline_sources);
    ClassDB::bind_method(D_METHOD("leyline_work", "id"), &WroughtwildSim::leyline_work);
    ClassDB::bind_method(D_METHOD("leyline_collect", "id", "item"), &WroughtwildSim::leyline_collect);
    ClassDB::bind_method(D_METHOD("leyline_tick", "seconds", "blocked"), &WroughtwildSim::leyline_tick);
    ClassDB::bind_method(D_METHOD("leyline_save"), &WroughtwildSim::leyline_save);
    ClassDB::bind_method(D_METHOD("leyline_validate_world", "text", "profile", "seed"), &WroughtwildSim::leyline_validate_world);
    ClassDB::bind_method(D_METHOD("leyline_load_world", "text", "profile", "seed"), &WroughtwildSim::leyline_load_world);
    ClassDB::bind_method(D_METHOD("contraption_validate_world", "text", "profile", "seed"), &WroughtwildSim::contraption_validate_world);
    ClassDB::bind_method(D_METHOD("contraption_load_world", "text", "profile", "seed"), &WroughtwildSim::contraption_load_world);
    ClassDB::bind_method(D_METHOD("contraption_pressure_sources"), &WroughtwildSim::contraption_pressure_sources);
    ClassDB::bind_method(D_METHOD("contraption_attach_feeder", "key", "source_id", "forge_key", "forge_position", "clear"), &WroughtwildSim::contraption_attach_feeder);
    ClassDB::bind_method(D_METHOD("rare_resource_guide"), &WroughtwildSim::rare_resource_guide);
    ClassDB::bind_method(D_METHOD("load_tuning", "tuning_directory"), &WroughtwildSim::load_tuning);
    ClassDB::bind_method(D_METHOD("is_loaded"), &WroughtwildSim::is_loaded);
    ClassDB::bind_method(D_METHOD("last_error"), &WroughtwildSim::last_error);

    ClassDB::bind_method(D_METHOD("recipe_ids"), &WroughtwildSim::recipe_ids);
    ClassDB::bind_method(D_METHOD("recipe", "recipe_id"), &WroughtwildSim::recipe);
    ClassDB::bind_method(D_METHOD("salvage_return_fraction"), &WroughtwildSim::salvage_return_fraction);
    ClassDB::bind_method(D_METHOD("shape_ids"), &WroughtwildSim::shape_ids);
    ClassDB::bind_method(D_METHOD("shape_material_cost", "shape_id"), &WroughtwildSim::shape_material_cost);
    ClassDB::bind_method(D_METHOD("shape", "shape_id"), &WroughtwildSim::shape);
    ClassDB::bind_method(D_METHOD("shape_unlocked", "shape_id"), &WroughtwildSim::shape_unlocked);
    ClassDB::bind_method(D_METHOD("build_material_ids"), &WroughtwildSim::build_material_ids);
    ClassDB::bind_method(D_METHOD("build_material", "material_id"), &WroughtwildSim::build_material);
    ClassDB::bind_method(D_METHOD("shape_allows_family", "shape_id", "material_family"),
                         &WroughtwildSim::shape_allows_family);
    ClassDB::bind_method(D_METHOD("equipment"), &WroughtwildSim::equipment);
    ClassDB::bind_method(D_METHOD("equip_from_inventory", "base_id"), &WroughtwildSim::equip_from_inventory);
    ClassDB::bind_method(D_METHOD("catalyst_process", "process_id"), &WroughtwildSim::catalyst_process);
    ClassDB::bind_method(D_METHOD("catalyst_process_ids"), &WroughtwildSim::catalyst_process_ids);
    ClassDB::bind_method(D_METHOD("basic_temper_info"), &WroughtwildSim::basic_temper_info);
    ClassDB::bind_method(D_METHOD("temper_basic"), &WroughtwildSim::temper_basic);
    ClassDB::bind_method(D_METHOD("temper_with_catalyst", "process_id"), &WroughtwildSim::temper_with_catalyst);
    ClassDB::bind_method(D_METHOD("set_temper_seed", "seed"), &WroughtwildSim::set_temper_seed);
    ClassDB::bind_method(D_METHOD("grid_size"), &WroughtwildSim::grid_size);
    ClassDB::bind_method(D_METHOD("placement_range"), &WroughtwildSim::placement_range);
    ClassDB::bind_method(D_METHOD("removal_refund_fraction"), &WroughtwildSim::removal_refund_fraction);

    ClassDB::bind_method(D_METHOD("gather_site", "site_id"), &WroughtwildSim::gather_site);
    ClassDB::bind_method(D_METHOD("skill_mod_ids"), &WroughtwildSim::skill_mod_ids);
    ClassDB::bind_method(D_METHOD("skill_mod", "mod_id"), &WroughtwildSim::skill_mod);
    ClassDB::bind_method(D_METHOD("set_skill_mod_active", "mod_id", "active"), &WroughtwildSim::set_skill_mod_active);
    ClassDB::bind_method(D_METHOD("skill_mod_active", "mod_id"), &WroughtwildSim::skill_mod_active);
    ClassDB::bind_method(D_METHOD("fork_count", "skill_id"), &WroughtwildSim::fork_count);
    ClassDB::bind_method(D_METHOD("fork_damage_fraction", "skill_id", "generation"), &WroughtwildSim::fork_damage_fraction);
    ClassDB::bind_method(D_METHOD("chill_applied", "skill_id", "is_boss"), &WroughtwildSim::chill_applied);
    ClassDB::bind_method(D_METHOD("ignite_applied", "skill_id", "is_boss"), &WroughtwildSim::ignite_applied);
    ClassDB::bind_method(D_METHOD("bleed_applied", "skill_id", "is_boss"), &WroughtwildSim::bleed_applied);
    ClassDB::bind_method(D_METHOD("chill_status"), &WroughtwildSim::chill_status);
    ClassDB::bind_method(D_METHOD("ignite_status"), &WroughtwildSim::ignite_status);
    ClassDB::bind_method(D_METHOD("bleed_status"), &WroughtwildSim::bleed_status);
    ClassDB::bind_method(D_METHOD("shatter_for", "skill_id"), &WroughtwildSim::shatter_for);
    ClassDB::bind_method(D_METHOD("shatter_rules"), &WroughtwildSim::shatter_rules);
    ClassDB::bind_method(D_METHOD("skill_echo_every", "skill_id"), &WroughtwildSim::skill_echo_every);
    ClassDB::bind_method(D_METHOD("skill_quenches", "skill_id"), &WroughtwildSim::skill_quenches);
    ClassDB::bind_method(D_METHOD("skill_nova_chill", "skill_id"), &WroughtwildSim::skill_nova_chill);
    ClassDB::bind_method(D_METHOD("skill_sear", "skill_id"), &WroughtwildSim::skill_sear);
    ClassDB::bind_method(D_METHOD("skill_brittle", "skill_id"), &WroughtwildSim::skill_brittle);
    ClassDB::bind_method(D_METHOD("skill_arc", "skill_id"), &WroughtwildSim::skill_arc);
    ClassDB::bind_method(D_METHOD("skill_life_on_hit", "skill_id"), &WroughtwildSim::skill_life_on_hit);
    ClassDB::bind_method(D_METHOD("skill_refund_on_kill", "skill_id"), &WroughtwildSim::skill_refund_on_kill);
    ClassDB::bind_method(D_METHOD("skill_haste_on_kill", "skill_id"), &WroughtwildSim::skill_haste_on_kill);
    ClassDB::bind_method(D_METHOD("skill_stagger", "skill_id", "is_boss"), &WroughtwildSim::skill_stagger, DEFVAL(false));
    ClassDB::bind_method(D_METHOD("skill_push", "skill_id", "is_boss"), &WroughtwildSim::skill_push, DEFVAL(false));
    ClassDB::bind_method(D_METHOD("skill_projectiles", "skill_id"), &WroughtwildSim::skill_projectiles);
    ClassDB::bind_method(D_METHOD("skill_pierce", "skill_id"), &WroughtwildSim::skill_pierce);
    ClassDB::bind_method(D_METHOD("foundry_choose_class", "class_id"), &WroughtwildSim::foundry_choose_class);
    ClassDB::bind_method(D_METHOD("foundry_specialise", "specialisation"), &WroughtwildSim::foundry_specialise);
    ClassDB::bind_method(D_METHOD("foundry_set_rail", "axis", "index", "pattern"), &WroughtwildSim::foundry_set_rail);
    ClassDB::bind_method(D_METHOD("foundry_clear_rail", "axis", "index"), &WroughtwildSim::foundry_clear_rail);
    ClassDB::bind_method(D_METHOD("foundry_pattern", "pattern_id"), &WroughtwildSim::foundry_pattern);
    ClassDB::bind_method(D_METHOD("foundry_links"), &WroughtwildSim::foundry_links);
    ClassDB::bind_method(D_METHOD("skill_triggers", "skill_id"), &WroughtwildSim::skill_triggers);
    ClassDB::bind_method(D_METHOD("linked_casts", "skill_id", "trigger"), &WroughtwildSim::linked_casts);
    ClassDB::bind_method(D_METHOD("proliferate_for"), &WroughtwildSim::proliferate_for);
    ClassDB::bind_method(D_METHOD("player_build_tags"), &WroughtwildSim::player_build_tags);
    ClassDB::bind_method(D_METHOD("known_skill_ids"), &WroughtwildSim::known_skill_ids);
    ClassDB::bind_method(D_METHOD("knows_skill", "skill_id"), &WroughtwildSim::knows_skill);
    ClassDB::bind_method(D_METHOD("skill_bar_size"), &WroughtwildSim::skill_bar_size);
    ClassDB::bind_method(D_METHOD("skill_bar"), &WroughtwildSim::skill_bar);
    ClassDB::bind_method(D_METHOD("set_bar_slot", "slot", "skill_id"), &WroughtwildSim::set_bar_slot);
    ClassDB::bind_method(D_METHOD("learn_skill", "skill_id"), &WroughtwildSim::learn_skill);
    ClassDB::bind_method(D_METHOD("slot_ids"), &WroughtwildSim::slot_ids);
    ClassDB::bind_method(D_METHOD("item_base_ids"), &WroughtwildSim::item_base_ids);
    ClassDB::bind_method(D_METHOD("item_base", "base_id"), &WroughtwildSim::item_base);
    ClassDB::bind_method(D_METHOD("modifier_ids"), &WroughtwildSim::modifier_ids);
    ClassDB::bind_method(D_METHOD("modifier", "modifier_id"), &WroughtwildSim::modifier);
    ClassDB::bind_method(D_METHOD("pack_items"), &WroughtwildSim::pack_items);
    ClassDB::bind_method(D_METHOD("compare_equipment", "pack_index", "base_id"), &WroughtwildSim::compare_equipment, DEFVAL(String()));
    ClassDB::bind_method(D_METHOD("equip_pack_item", "index"), &WroughtwildSim::equip_pack_item);
    ClassDB::bind_method(D_METHOD("unequip", "slot"), &WroughtwildSim::unequip);
    ClassDB::bind_method(D_METHOD("active_modifiers"), &WroughtwildSim::active_modifiers);
    ClassDB::bind_method(D_METHOD("roll_item_into_pack", "base_id", "rarity", "tier", "seed"), &WroughtwildSim::roll_item_into_pack);
    ClassDB::bind_method(D_METHOD("skill_cooldown_seconds", "skill_id"), &WroughtwildSim::skill_cooldown_seconds);
    ClassDB::bind_method(D_METHOD("skill_reach", "skill_id"), &WroughtwildSim::skill_reach);
    ClassDB::bind_method(D_METHOD("skill_life_on_kill", "skill_id"), &WroughtwildSim::skill_life_on_kill);
    ClassDB::bind_method(D_METHOD("skill_cast_armour", "skill_id"), &WroughtwildSim::skill_cast_armour);
    ClassDB::bind_method(D_METHOD("ward_multiplier", "carried_statuses"), &WroughtwildSim::ward_multiplier);
    ClassDB::bind_method(D_METHOD("world_map", "seed"), &WroughtwildSim::world_map);
    ClassDB::bind_method(D_METHOD("set_campaign_policy", "policy"), &WroughtwildSim::set_campaign_policy);
    ClassDB::bind_method(D_METHOD("campaign_policy"), &WroughtwildSim::campaign_policy);
    ClassDB::bind_method(D_METHOD("resonance_json"), &WroughtwildSim::resonance_json);
    ClassDB::bind_method(D_METHOD("resonance_second_json"), &WroughtwildSim::resonance_second_json);
    ClassDB::bind_method(D_METHOD("resonance_signature"), &WroughtwildSim::resonance_signature);
    ClassDB::bind_method(D_METHOD("resonance_queue", "seed"), &WroughtwildSim::resonance_queue);
    ClassDB::bind_method(D_METHOD("resonance_prepare", "seed", "protection"), &WroughtwildSim::resonance_prepare);
    ClassDB::bind_method(D_METHOD("resonance_validate_world", "profile", "seed"), &WroughtwildSim::resonance_validate_world);
    ClassDB::bind_method(D_METHOD("set_world_profile", "profile_id"), &WroughtwildSim::set_world_profile);
    ClassDB::bind_method(D_METHOD("world_profile"), &WroughtwildSim::world_profile);
    ClassDB::bind_method(D_METHOD("world_mesh", "seed", "chunk_cells", "faceted", "palette"), &WroughtwildSim::world_mesh, DEFVAL(false), DEFVAL(Dictionary()));
    ClassDB::bind_method(D_METHOD("world_mesh_chunk", "seed", "chunk_cells", "chunk_x", "chunk_z", "removed_blocks", "faceted", "palette"),
                         &WroughtwildSim::world_mesh_chunk, DEFVAL(false), DEFVAL(Dictionary()));
    ClassDB::bind_method(D_METHOD("block_rules"), &WroughtwildSim::block_rules);
    ClassDB::bind_method(D_METHOD("fire_setting"), &WroughtwildSim::fire_setting);
    ClassDB::bind_method(D_METHOD("lattice_registry_grid"), &WroughtwildSim::lattice_registry_grid);
    ClassDB::bind_method(D_METHOD("lattice_candidates", "shape_id", "point", "normal", "fine_grid"),
                         &WroughtwildSim::lattice_candidates, DEFVAL(false));
    ClassDB::bind_method(D_METHOD("structure_touches", "shape_id", "element"), &WroughtwildSim::structure_touches);
    ClassDB::bind_method(D_METHOD("structure_near_point", "point"), &WroughtwildSim::structure_near_point);
    ClassDB::bind_method(D_METHOD("structure_piece_count"), &WroughtwildSim::structure_piece_count);
    ClassDB::bind_method(D_METHOD("lattice_pose", "shape_id", "element"), &WroughtwildSim::lattice_pose);
    ClassDB::bind_method(D_METHOD("lattice_footprint", "shape_id", "element"), &WroughtwildSim::lattice_footprint);
    ClassDB::bind_method(D_METHOD("shape_accepts", "shape_id", "element"), &WroughtwildSim::shape_accepts);
    ClassDB::bind_method(D_METHOD("structure_occupied", "element"), &WroughtwildSim::structure_occupied);
    ClassDB::bind_method(D_METHOD("structure_free_for", "shape_id", "element"), &WroughtwildSim::structure_free_for);
    ClassDB::bind_method(D_METHOD("structure_piece", "element"), &WroughtwildSim::structure_piece);
    ClassDB::bind_method(D_METHOD("structure_place", "element", "shape_id", "family", "rotation_step"),
                         &WroughtwildSim::structure_place);
    ClassDB::bind_method(D_METHOD("structure_remove", "element"), &WroughtwildSim::structure_remove);
    ClassDB::bind_method(D_METHOD("structure_clear"), &WroughtwildSim::structure_clear);
    ClassDB::bind_method(D_METHOD("structure_pieces"), &WroughtwildSim::structure_pieces);
    ClassDB::bind_method(D_METHOD("structure_trim_edges"), &WroughtwildSim::structure_trim_edges);
    ClassDB::bind_method(D_METHOD("structure_enclosure", "seed", "removed_blocks", "at"),
                         &WroughtwildSim::structure_enclosure);
    ClassDB::bind_method(D_METHOD("shelter"), &WroughtwildSim::shelter);
    ClassDB::bind_method(D_METHOD("advance_time", "seconds"), &WroughtwildSim::advance_time);
    ClassDB::bind_method(D_METHOD("day"), &WroughtwildSim::day);
    ClassDB::bind_method(D_METHOD("day_rules"), &WroughtwildSim::day_rules);
    ClassDB::bind_method(D_METHOD("set_day_clock", "seconds"), &WroughtwildSim::set_day_clock);
    ClassDB::bind_method(D_METHOD("hauling_rules"), &WroughtwildSim::hauling_rules);
    ClassDB::bind_method(D_METHOD("noise_rules"), &WroughtwildSim::noise_rules);
    ClassDB::bind_method(D_METHOD("train_rules"), &WroughtwildSim::train_rules);
    ClassDB::bind_method(D_METHOD("train_multiplier", "earlier_hits"), &WroughtwildSim::train_multiplier);
    ClassDB::bind_method(D_METHOD("armour_reduction_cap"), &WroughtwildSim::armour_reduction_cap);
    ClassDB::bind_method(D_METHOD("siege_rules"), &WroughtwildSim::siege_rules);
    ClassDB::bind_method(D_METHOD("siege_tonight", "seed", "day_index"), &WroughtwildSim::siege_tonight);
    ClassDB::bind_method(D_METHOD("siege_pack"), &WroughtwildSim::siege_pack);
    ClassDB::bind_method(D_METHOD("threat_score", "enemy_id"), &WroughtwildSim::threat_score);
    ClassDB::bind_method(D_METHOD("set_curio", "landmark_id"), &WroughtwildSim::set_curio);
    ClassDB::bind_method(D_METHOD("landmark_wants", "landmark_id"), &WroughtwildSim::landmark_wants);
    ClassDB::bind_method(D_METHOD("curio_hints"), &WroughtwildSim::curio_hints);
    ClassDB::bind_method(D_METHOD("mingle_pick", "biome", "salt"), &WroughtwildSim::mingle_pick);
    ClassDB::bind_method(D_METHOD("carry_cap", "family"), &WroughtwildSim::carry_cap);
    ClassDB::bind_method(D_METHOD("carry_room", "family"), &WroughtwildSim::carry_room);
    ClassDB::bind_method(D_METHOD("haul", "family", "amount"), &WroughtwildSim::haul);
    ClassDB::bind_method(D_METHOD("store_deposit", "key", "family", "amount"), &WroughtwildSim::store_deposit);
    ClassDB::bind_method(D_METHOD("store_withdraw", "key", "family", "amount"), &WroughtwildSim::store_withdraw);
    ClassDB::bind_method(D_METHOD("store_contents", "key"), &WroughtwildSim::store_contents);
    ClassDB::bind_method(D_METHOD("store_units", "key"), &WroughtwildSim::store_units);
    ClassDB::bind_method(D_METHOD("store_room", "key"), &WroughtwildSim::store_room);
    ClassDB::bind_method(D_METHOD("store_remove", "key"), &WroughtwildSim::store_remove);
    ClassDB::bind_method(D_METHOD("note_skill_use", "skill_id"), &WroughtwildSim::note_skill_use);
    ClassDB::bind_method(D_METHOD("discard_pack_item", "index"), &WroughtwildSim::discard_pack_item);
    ClassDB::bind_method(D_METHOD("transfer_targets", "process_id"), &WroughtwildSim::transfer_targets);
    ClassDB::bind_method(D_METHOD("transfer_with_catalyst", "process_id", "target_index"),
                         &WroughtwildSim::transfer_with_catalyst);
    ClassDB::bind_method(D_METHOD("foundry"), &WroughtwildSim::foundry);
    ClassDB::bind_method(D_METHOD("foundry_ingot_ids"), &WroughtwildSim::foundry_ingot_ids);
    ClassDB::bind_method(D_METHOD("foundry_ingot", "ingot_id"), &WroughtwildSim::foundry_ingot);
    ClassDB::bind_method(D_METHOD("foundry_effects"), &WroughtwildSim::foundry_effects);
    ClassDB::bind_method(D_METHOD("skill_mutation", "skill_id"), &WroughtwildSim::skill_mutation);
    ClassDB::bind_method(D_METHOD("foundry_preview", "row", "col", "piece_id", "metal_id"), &WroughtwildSim::foundry_preview);
    ClassDB::bind_method(D_METHOD("foundry_place", "row", "col", "ingot_id", "metal_id"), &WroughtwildSim::foundry_place, DEFVAL(String()));
    ClassDB::bind_method(D_METHOD("foundry_recast", "ingot_id", "metal_id"), &WroughtwildSim::foundry_recast);
    ClassDB::bind_method(D_METHOD("can_recast", "ingot_id", "metal_id"), &WroughtwildSim::can_recast);
    ClassDB::bind_method(D_METHOD("foundry_remove", "row", "col"), &WroughtwildSim::foundry_remove);
    ClassDB::bind_method(D_METHOD("foundry_place_skill", "row", "col", "skill_id"), &WroughtwildSim::foundry_place_skill);
    ClassDB::bind_method(D_METHOD("foundry_place_kind", "row", "col", "kind_id"), &WroughtwildSim::foundry_place_kind);
    ClassDB::bind_method(D_METHOD("foundry_event", "event"), &WroughtwildSim::foundry_event);
    ClassDB::bind_method(D_METHOD("foundry_notices"), &WroughtwildSim::foundry_notices);
    ClassDB::bind_method(D_METHOD("era"), &WroughtwildSim::era);
    ClassDB::bind_method(D_METHOD("era_mechanic", "enemy_id", "mechanic"), &WroughtwildSim::era_mechanic);
    ClassDB::bind_method(D_METHOD("record_world_effect", "effect"), &WroughtwildSim::record_world_effect);
    ClassDB::bind_method(D_METHOD("enemy_loot", "enemy_id", "seed", "elite_id"),
                         &WroughtwildSim::enemy_loot, DEFVAL(String()));
    ClassDB::bind_method(D_METHOD("enemy_gear_loot", "enemy_id", "seed", "elite_id"),
                         &WroughtwildSim::enemy_gear_loot, DEFVAL(String()));
    ClassDB::bind_method(D_METHOD("claim_enemy_gear", "enemy_id", "seed", "elite_id"),
                         &WroughtwildSim::claim_enemy_gear, DEFVAL(String()));
    ClassDB::bind_method(D_METHOD("enemy_skill_page", "enemy_id", "seed", "elite_id"),
                         &WroughtwildSim::enemy_skill_page, DEFVAL(String()));
    ClassDB::bind_method(D_METHOD("elite_modifier_ids"), &WroughtwildSim::elite_modifier_ids);
    ClassDB::bind_method(D_METHOD("elite_modifier", "elite_id"), &WroughtwildSim::elite_modifier);
    ClassDB::bind_method(D_METHOD("kit_station", "kit_item_id"), &WroughtwildSim::kit_station);
    ClassDB::bind_method(D_METHOD("kit_item_ids"), &WroughtwildSim::kit_item_ids);
    ClassDB::bind_method(D_METHOD("fuels"), &WroughtwildSim::fuels);
    ClassDB::bind_method(D_METHOD("fuel_value_held"), &WroughtwildSim::fuel_value_held);
    ClassDB::bind_method(D_METHOD("add_materials", "amounts"), &WroughtwildSim::add_materials);
    ClassDB::bind_method(D_METHOD("drop_inventory"), &WroughtwildSim::drop_inventory);
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
    ClassDB::bind_method(D_METHOD("craft", "recipe_id", "for_order", "aim_kind", "quality", "quantity"), &WroughtwildSim::craft, DEFVAL(false), DEFVAL(""), DEFVAL(1), DEFVAL(1));
    ClassDB::bind_method(D_METHOD("craft_preview", "recipe_id", "aim_kind", "quality", "quantity"), &WroughtwildSim::craft_preview, DEFVAL(""), DEFVAL(1), DEFVAL(1));
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

    ClassDB::bind_method(D_METHOD("derived_stats"), &WroughtwildSim::derived_stats);
    ClassDB::bind_method(D_METHOD("combat_skill_ids"), &WroughtwildSim::combat_skill_ids);
    ClassDB::bind_method(D_METHOD("combat_skill", "skill_id"), &WroughtwildSim::combat_skill);
    ClassDB::bind_method(D_METHOD("enemy_ids"), &WroughtwildSim::enemy_ids);
    ClassDB::bind_method(D_METHOD("enemy", "enemy_id"), &WroughtwildSim::enemy);
    ClassDB::bind_method(D_METHOD("boss"), &WroughtwildSim::boss);
    ClassDB::bind_method(D_METHOD("realtime"), &WroughtwildSim::realtime);
    ClassDB::bind_method(D_METHOD("combat_mods"), &WroughtwildSim::combat_mods);
    ClassDB::bind_method(D_METHOD("begin_fight", "seed"), &WroughtwildSim::begin_fight);
    ClassDB::bind_method(D_METHOD("player_hit_damage", "skill_id", "isolated"), &WroughtwildSim::player_hit_damage);
    ClassDB::bind_method(D_METHOD("player_hit", "skill_id", "isolated", "target_statuses"), &WroughtwildSim::player_hit, DEFVAL(PackedStringArray()));
    ClassDB::bind_method(D_METHOD("enemy_hit_damage", "raw_damage", "damage_type", "bonus_armour"), &WroughtwildSim::enemy_hit_damage, DEFVAL(0.0));
    ClassDB::bind_method(D_METHOD("mitigate", "amount", "damage_type"), &WroughtwildSim::mitigate);

    ClassDB::bind_method(D_METHOD("trial_start", "seed", "floor_id"), &WroughtwildSim::trial_start, DEFVAL(String()));
    ClassDB::bind_method(D_METHOD("trial_start_story", "seed", "run_id"), &WroughtwildSim::trial_start_story, DEFVAL(String("forge_tyrant")));
    ClassDB::bind_method(D_METHOD("trial_story_runs"), &WroughtwildSim::trial_story_runs);
    ClassDB::bind_method(D_METHOD("trial_layout"), &WroughtwildSim::trial_layout);
    ClassDB::bind_method(D_METHOD("trial_rules"), &WroughtwildSim::trial_rules);
    ClassDB::bind_method(D_METHOD("trial_map_offers", "tier"), &WroughtwildSim::trial_map_offers);
    ClassDB::bind_method(D_METHOD("trial_start_map", "tier", "offer_index"), &WroughtwildSim::trial_start_map);
    ClassDB::bind_method(D_METHOD("trial_map_progress"), &WroughtwildSim::trial_map_progress);
    ClassDB::bind_method(D_METHOD("trial_continue_floor"), &WroughtwildSim::trial_continue_floor);
    ClassDB::bind_method(D_METHOD("trial_skip_reward"), &WroughtwildSim::trial_skip_reward);
    ClassDB::bind_method(D_METHOD("trial_claim_secret"), &WroughtwildSim::trial_claim_secret);
    ClassDB::bind_method(D_METHOD("trial_checkpoint"), &WroughtwildSim::trial_checkpoint);
    ClassDB::bind_method(D_METHOD("trial_checkpoint_valid", "text"), &WroughtwildSim::trial_checkpoint_valid);
    ClassDB::bind_method(D_METHOD("trial_checkpoint_matches", "text", "player_state"), &WroughtwildSim::trial_checkpoint_matches);
    ClassDB::bind_method(D_METHOD("trial_restore_checkpoint", "text"), &WroughtwildSim::trial_restore_checkpoint);
    ClassDB::bind_method(D_METHOD("trial_floors"), &WroughtwildSim::trial_floors);
    ClassDB::bind_method(D_METHOD("trial_floor"), &WroughtwildSim::trial_floor);
    ClassDB::bind_method(D_METHOD("market_offers"), &WroughtwildSim::market_offers);
    ClassDB::bind_method(D_METHOD("buy", "item_id"), &WroughtwildSim::buy);
    ClassDB::bind_method(D_METHOD("currency_kinds"), &WroughtwildSim::currency_kinds);
    ClassDB::bind_method(D_METHOD("exchange_rate"), &WroughtwildSim::exchange_rate);
    ClassDB::bind_method(D_METHOD("can_exchange", "from_kind", "to_kind"), &WroughtwildSim::can_exchange);
    ClassDB::bind_method(D_METHOD("exchange", "from_kind", "to_kind"), &WroughtwildSim::exchange);
    ClassDB::bind_method(D_METHOD("trial_active"), &WroughtwildSim::trial_active);
    ClassDB::bind_method(D_METHOD("trial_finished"), &WroughtwildSim::trial_finished);
    ClassDB::bind_method(D_METHOD("trial_player_died"), &WroughtwildSim::trial_player_died);
    ClassDB::bind_method(D_METHOD("trial_boss_defeated"), &WroughtwildSim::trial_boss_defeated);
    ClassDB::bind_method(D_METHOD("trial_stage"), &WroughtwildSim::trial_stage);
    ClassDB::bind_method(D_METHOD("trial_begin_room", "choice_index"), &WroughtwildSim::trial_begin_room);
    ClassDB::bind_method(D_METHOD("trial_resolve_room", "victory"), &WroughtwildSim::trial_resolve_room);
    ClassDB::bind_method(D_METHOD("trial_accept_boon", "boon_id"), &WroughtwildSim::trial_accept_boon);
    ClassDB::bind_method(D_METHOD("trial_accept_weakness"), &WroughtwildSim::trial_accept_weakness);
    ClassDB::bind_method(D_METHOD("trial_bank_and_exit"), &WroughtwildSim::trial_bank_and_exit);
    ClassDB::bind_method(D_METHOD("trial_abandon"), &WroughtwildSim::trial_abandon);
    ClassDB::bind_method(D_METHOD("trial_run_state"), &WroughtwildSim::trial_run_state);
    ClassDB::bind_method(D_METHOD("trial_loot"), &WroughtwildSim::trial_loot);
    ClassDB::bind_method(D_METHOD("trial_end"), &WroughtwildSim::trial_end);
}

bool WroughtwildSim::trial_start(int seed, const String& floor_id) {
    if (!require_loaded("trial_start") || trial_) {
        return false;
    }
    if (player_->campaignPolicy == wroughtwild::resonance::campaign) return false;
    const wroughtwild::tuning::TrialFloor* floor = nullptr;
    if (!floor_id.is_empty()) {
        floor = tuning_->trial.findFloor(to_std(floor_id));
        if (floor == nullptr || !player_->worldEffectActive(floor->requiresWorldEffect)) {
            return false;
        }
    }
    trial_ = std::make_unique<wroughtwild::trial::TrialSession>(
        *tuning_, *player_, build_tags(), static_cast<uint64_t>(seed), floor);
    return true;
}

Array WroughtwildSim::trial_floors() const {
    Array out;
    if (!require_loaded("trial_floors")) {
        return out;
    }
    for (const auto& floor : tuning_->trial.floors) {
        Dictionary d;
        d["id"] = to_godot(floor.id);
        d["display_name"] = to_godot(floor.displayName);
        d["available"] = floor.requiresWorldEffect.empty() || player_->worldEffectActive(floor.requiresWorldEffect);
        d["done"] = player_->worldEffectActive(floor.completionUnlock);
        out.push_back(d);
    }
    return out;
}

Dictionary WroughtwildSim::trial_floor() const {
    Dictionary d;
    d["id"] = String();
    if (!require_loaded("trial_floor") || !trial_ || trial_->floor() == nullptr) {
        return d;
    }
    d["id"] = to_godot(trial_->floor()->id);
    d["display_name"] = to_godot(trial_->floor()->displayName);
    d["completion_text"] = to_godot(trial_->floor()->completionText);
    return d;
}

Array WroughtwildSim::market_offers() const {
    Array out;
    if (!require_loaded("market_offers")) {
        return out;
    }
    for (const auto& offer : tuning_->crafting.market) {
        Dictionary d;
        d["item"] = to_godot(offer.item);
        d["count"] = offer.count;
        d["price"] = offer.price;
        d["currency"] = to_godot(offer.currency);
        auto have = player_->currency.find(offer.currency);
        d["affordable"] = have != player_->currency.end() && have->second >= offer.price;
        out.push_back(d);
    }
    return out;
}

bool WroughtwildSim::buy(const String& item_id) {
    return require_loaded("buy") && player_->buy(to_std(item_id));
}

Array WroughtwildSim::currency_kinds() const {
    Array out;
    if (!require_loaded("currency_kinds")) {
        return out;
    }
    const auto& exchange = tuning_->crafting.exchangeKinds;
    for (const auto& kind : tuning_->crafting.currencyKinds) {
        Dictionary d;
        d["id"] = to_godot(kind.id);
        d["display_name"] = to_godot(kind.displayName);
        d["family"] = to_godot(kind.family);
        d["craft_tag"] = to_godot(kind.craftTag);
        d["potency"] = kind.potency;
        d["canonical_kind"] = to_godot(kind.canonicalKind);
        d["description"] = to_godot(kind.description);
        PackedStringArray sources;
        for (const auto& enemy : tuning_->world.enemies) {
            for (const auto& entry : enemy.loot) {
                if (entry.kind == "item" && entry.item == kind.id && entry.chance > 0.0) {
                    sources.push_back(to_godot(enemy.displayName));
                    break;
                }
            }
        }
        d["sources"] = sources;
        d["held"] = player_->held(kind.id);
        d["exchangeable"] = std::find(exchange.begin(), exchange.end(), kind.id) != exchange.end();
        out.push_back(d);
    }
    return out;
}

int WroughtwildSim::exchange_rate() const {
    return require_loaded("exchange_rate") ? tuning_->crafting.exchangeRate : 0;
}

bool WroughtwildSim::can_exchange(const String& from_kind, const String& to_kind) const {
    return require_loaded("can_exchange") && player_->canExchange(to_std(from_kind), to_std(to_kind));
}

bool WroughtwildSim::exchange(const String& from_kind, const String& to_kind) {
    return require_loaded("exchange") && player_->exchange(to_std(from_kind), to_std(to_kind));
}

bool WroughtwildSim::trial_active() const { return trial_ != nullptr; }
bool WroughtwildSim::trial_finished() const { return trial_ && trial_->finished(); }
bool WroughtwildSim::trial_player_died() const { return trial_ && trial_->playerDied(); }
bool WroughtwildSim::trial_boss_defeated() const { return trial_ && trial_->bossDefeated(); }

Dictionary WroughtwildSim::trial_stage() const {
    Dictionary d;
    if (!trial_ || trial_->finished()) {
        return d;
    }
    d["index"] = trial_->currentStageIndex();
    d["floor_index"] = trial_->floorIndex();
    d["floor_count"] = trial_->floorCount();
    d["awaiting_floor"] = trial_->awaitingFloor();
    d["can_suspend"] = trial_->canSuspend();
    Array choices;
    for (const auto& choice : trial_->currentStage().choices) {
        Dictionary c;
        c["id"] = to_godot(choice.id);
        c["display_name"] = to_godot(choice.displayName);
        PackedStringArray encounter;
        for (const auto& id : choice.encounter) {
            encounter.push_back(to_godot(id));
        }
        c["encounter"] = encounter;
        c["reward"] = to_godot(choice.reward);
        c["module"] = to_godot(choice.module);
        choices.push_back(c);
    }
    d["choices"] = choices;
    d["can_bank_and_exit"] = trial_->canBankAndExit();
    d["room_in_progress"] = trial_->roomInProgress();
    return d;
}

Dictionary WroughtwildSim::trial_begin_room(int choice_index) {
    Dictionary d;
    d["started"] = false;
    if (!trial_) {
        return d;
    }
    try {
        const auto start = trial_->beginRoom(choice_index);
        d["started"] = start.started;
        if (!start.started) {
            return d;
        }
        d["id"] = to_godot(start.roomId);
        d["display_name"] = to_godot(start.displayName);
        PackedStringArray encounter;
        for (const auto& id : start.encounter) {
            encounter.push_back(to_godot(id));
        }
        d["encounter"] = encounter;
        d["seed"] = static_cast<int64_t>(start.seed);
        hits_ = std::make_unique<wroughtwild::combat::HitStream>(start.seed);
    } catch (const std::exception& e) {
        last_error_ = to_godot(e.what());
        UtilityFunctions::push_warning("WroughtwildSim.trial_begin_room: ", last_error_);
    }
    return d;
}

Dictionary WroughtwildSim::trial_resolve_room(bool victory) {
    Dictionary d;
    d["victory"] = victory;
    if (!trial_) {
        return d;
    }
    const auto outcome = trial_->resolveRoom(victory);
    if (outcome.rewardType == "completion" && trial_->tier() > 0 && trial_->bossDefeated())
        trial_gate_.clearedMap(trial_->tier());
    d["reward_type"] = to_godot(outcome.rewardType);
    Array offer;
    for (const auto* boon : outcome.boonOffer) {
        Dictionary b;
        b["id"] = to_godot(boon->id);
        b["display_name"] = to_godot(boon->displayName);
        b["design_purpose"] = to_godot(boon->designPurpose);
        offer.push_back(b);
    }
    d["boon_offer"] = offer;
    Dictionary weakness;
    if (!outcome.offeredWeakness.empty()) {
        for (const auto& w : tuning_->boons.weaknesses) {
            if (w.id == outcome.offeredWeakness) {
                weakness["id"] = to_godot(w.id);
                weakness["display_name"] = to_godot(w.displayName);
                weakness["reward_multiplier"] = w.baseRewardMultiplier;
                weakness["design_purpose"] = to_godot(w.designPurpose);
            }
        }
    }
    d["offered_weakness"] = weakness;
    d["catalyst_recovered"] = outcome.catalystRecovered;
    d["materials"] = to_dictionary(outcome.materials);
    Array items;
    for (const auto& item : outcome.items) {
        items.push_back(item_entry(*tuning_, item, -1));
    }
    d["items"] = items;
    d["finished"] = trial_->finished();
    d["died"] = trial_->playerDied();
    d["boss_defeated"] = trial_->bossDefeated();
    return d;
}

bool WroughtwildSim::trial_accept_boon(const String& boon_id) {
    return trial_ && trial_->acceptBoonFromOffer(to_std(boon_id));
}

bool WroughtwildSim::trial_accept_weakness() {
    return trial_ && trial_->acceptOfferedWeakness();
}

bool WroughtwildSim::trial_bank_and_exit() {
    if (!trial_ || !trial_->canBankAndExit()) {
        return false;
    }
    trial_->bankAndExit();
    return trial_->finished();
}

void WroughtwildSim::trial_abandon() {
    if (trial_) {
        trial_->abandon();
    }
}

Dictionary WroughtwildSim::trial_run_state() const {
    Dictionary d;
    Array boons;
    Array weaknesses;
    if (trial_) {
        for (const auto& id : trial_->runState().activeBoons) {
            Dictionary b;
            b["id"] = to_godot(id);
            const auto* def = tuning_->boons.findBoon(id);
            b["display_name"] = to_godot(def ? def->displayName : id);
            boons.push_back(b);
        }
        for (const auto& id : trial_->runState().activeWeaknesses) {
            Dictionary w;
            w["id"] = to_godot(id);
            String name = to_godot(id);
            for (const auto& def : tuning_->boons.weaknesses) {
                if (def.id == id) {
                    name = to_godot(def.displayName);
                }
            }
            w["display_name"] = name;
            weaknesses.push_back(w);
        }
    }
    d["boons"] = boons;
    d["weaknesses"] = weaknesses;
    return d;
}

Dictionary WroughtwildSim::trial_loot() const {
    return trial_ ? to_dictionary(trial_->runLoot()) : Dictionary();
}

bool WroughtwildSim::trial_end() {
    if (!trial_ || !trial_->finished()) {
        return false;
    }
    trial_.reset();
    return true;
}

const wroughtwild::tuning::CombatSkillDef* WroughtwildSim::find_skill(const String& skill_id) const {
    const std::string id = to_std(skill_id);
    for (const auto& def : tuning_->skills.combatSkills) {
        if (def.id == id) {
            return &def;
        }
    }
    return nullptr;
}

Dictionary WroughtwildSim::derived_stats() const {
    Dictionary d;
    if (!require_loaded("derived_stats")) {
        return d;
    }
    const auto s = derived_now();
    d["max_life"] = s.maxLife;
    d["armour"] = s.armour;
    d["fire_resistance_percent"] = s.fireResistancePercent;
    d["cold_resistance_percent"] = s.coldResistancePercent;
    d["area_bonus"] = s.areaBonus;
    // The Vanguard's answers to a hit (D-023 slice 4), for the engine to apply.
    d["barbs"] = s.barbsBuildup;
    d["answer_reach_m"] = s.answerReachM;
    d["haste_after_hit"] = s.hasteAfterHit;
    // The Marrow's and the Quicksilver's sheet numbers (D-023 slice 8).
    d["heal_more"] = s.healMore;
    d["dash_reach_m"] = s.dashReachM;
    d["life_on_dash"] = s.lifeOnDash;
    d["armour_on_dash"] = s.armourOnDash;
    d["dash_recovery"] = s.dashRecovery;
    // The rails' sheet numbers (D-023 slice 9).
    d["armour_vs_elements"] = s.armourVsElements;
    d["barbs_more"] = s.barbsMore;
    d["barbs_stagger"] = s.barbsStagger;
    d["proliferate_on_hit"] = s.proliferateOnHit;
    d["burning_ground_heal"] = s.burningGroundHeal;
    d["damage_vs_approaching"] = s.damageVsApproaching;
    d["still_armour"] = s.stillArmour;
    return d;
}

PackedStringArray WroughtwildSim::combat_skill_ids() const {
    PackedStringArray ids;
    if (require_loaded("combat_skill_ids")) {
        for (const auto& def : tuning_->skills.combatSkills) {
            ids.push_back(to_godot(def.id));
        }
    }
    return ids;
}

Dictionary WroughtwildSim::combat_skill(const String& skill_id) const {
    Dictionary d;
    if (!require_loaded("combat_skill")) {
        return d;
    }
    const auto* def = find_skill(skill_id);
    if (def == nullptr) {
        return d;
    }
    d["id"] = to_godot(def->id);
    d["display_name"] = to_godot(def->displayName);
    d["delivery"] = to_godot(def->delivery);
    d["description"] = to_godot(def->description);
    d["starting"] = def->starting;
    d["drop_weight"] = def->dropWeight;
    d["uses"] = player_->skillUses(def->id);
    d["practice"] = player_->skillPractice(def->id);
    Array mastery;
    const auto earned = player_->masteryUnlocked(def->id);
    for (size_t i = 0; i < def->mastery.size(); ++i) {
        const auto& perk = i < earned.size() ? *earned[i] : def->mastery[i];
        Dictionary m;
        m["uses"] = def->mastery[i].uses;
        m["text"] = to_godot(perk.text);
        m["unlocked"] = i < earned.size();
        m["value"] = perk.value;
        m["modifier"] = to_godot(perk.modifier);
        mastery.push_back(m);
    }
    d["mastery"] = mastery;
    PackedStringArray tags;
    for (const auto& tag : def->tags) {
        tags.push_back(to_godot(tag));
    }
    d["tags"] = tags;
    for (const auto& [key, value] : def->numbers) {
        d[to_godot(key)] = value;
    }
    return d;
}

PackedStringArray WroughtwildSim::enemy_ids() const {
    PackedStringArray ids;
    if (require_loaded("enemy_ids")) {
        for (const auto& e : tuning_->world.enemies) {
            if (!e.worldProfile.empty() && e.worldProfile != world_profile_) continue;
            ids.push_back(to_godot(e.id));
        }
        for (const auto& e : tuning_->world.frontierEnemies)
            if (e.worldProfile == world_profile_) ids.push_back(to_godot(e.id));
    }
    return ids;
}

Dictionary WroughtwildSim::enemy(const String& enemy_id) const {
    Dictionary d;
    if (!require_loaded("enemy")) {
        return d;
    }
    const auto* e = tuning_->world.findEnemy(to_std(enemy_id));
    if (e == nullptr) {
        return d;
    }
    d["id"] = to_godot(e->id);
    d["display_name"] = to_godot(e->displayName);
    d["max_life"] = e->maxLife;
    d["behaviour"] = to_godot(e->behaviour);
    d["damage"] = e->damage;
    d["damage_type"] = to_godot(e->damageType);
    d["attack_period_rounds"] = e->attackPeriodRounds;
    d["tint"] = to_godot(e->tint);
    d["size_scale"] = e->sizeScale;
    d["immune_statuses"] = strings_to_packed(e->immuneStatuses);
    d["currency_kind"] = to_godot(e->currencyKind);
    d["visual_id"] = to_godot(e->visualId);
    d["influence"] = to_godot(e->influence);
    Dictionary taken;
    for (const auto& [type, share] : e->damageTaken) {
        taken[to_godot(type)] = share;
    }
    d["damage_taken"] = taken;
    return d;
}

Dictionary WroughtwildSim::boss() const {
    Dictionary d;
    if (!require_loaded("boss")) {
        return d;
    }
    const auto& b = (trial_ && trial_->floor() != nullptr) ? trial_->floor()->boss : tuning_->trial.boss;
    d["id"] = to_godot(b.id);
    d["display_name"] = to_godot(b.displayName);
    d["max_life"] = b.maxLife;
    d["claw_damage"] = b.clawDamage;
    d["claw_damage_type"] = to_godot(b.clawDamageType);
    d["claw_period_rounds"] = b.clawPeriodRounds;
    d["breath_damage"] = b.breathDamage;
    d["breath_damage_type"] = to_godot(b.breathDamageType);
    d["breath_period_rounds"] = b.breathPeriodRounds;
    d["breath_telegraph_rounds"] = b.breathTelegraphRounds;
    return d;
}

Dictionary WroughtwildSim::realtime() const {
    Dictionary d;
    if (!require_loaded("realtime")) {
        return d;
    }
    const auto& rt = tuning_->realtime;
    d["round_seconds"] = rt.roundSeconds;

    Dictionary player;
    player["move_speed_mps"] = rt.playerMoveSpeedMps;
    player["melee_reach_m"] = rt.playerMeleeReachM;
    player["cone_degrees"] = rt.playerConeDegrees;
    d["player"] = player;

    Dictionary behaviours;
    for (const auto& [id, b] : rt.behaviours) {
        Dictionary entry;
        entry["move_speed_mps"] = b.moveSpeedMps;
        entry["flees"] = b.flees;
        entry["attack_range_m"] = b.attackRangeM;
        entry["preferred_distance_m"] = b.preferredDistanceM;
        entry["aggro_range_m"] = b.aggroRangeM;
        entry["windup_seconds"] = b.windupSeconds;
        entry["windup_advance_m"] = b.windupAdvanceM;
        entry["release_shape"] = to_godot(b.releaseShape);
        entry["release_warning_seconds"] = b.releaseWarningSeconds;
        entry["release_seconds"] = b.releaseSeconds;
        entry["release_distance_m"] = b.releaseDistanceM;
        entry["release_radius_m"] = b.releaseRadiusM;
        entry["recovery_seconds"] = b.recoverySeconds;
        entry["attack_arc_degrees"] = b.attackArcDegrees;
        if (b.projectile.enabled) {
            const auto& p = b.projectile;
            Dictionary shot;
            shot["speed_mps"] = p.speedMps;
            shot["radius_m"] = p.radiusM;
            shot["max_range_m"] = p.maxRangeM;
            shot["muzzle_height_m"] = p.muzzleHeightM;
            shot["trail_length_m"] = p.trailLengthM;
            shot["glow_energy"] = p.glowEnergy;
            shot["colour"] = to_godot(p.colour);
            entry["projectile"] = shot;
        }
        entry["give_up_distance_m"] = b.giveUpDistanceM;
        entry["scream_period_seconds"] = b.screamPeriodSeconds;
        entry["scream_radius_m"] = b.screamRadiusM;
        entry["verb"] = to_godot(b.verb);
        entry["verb_seconds"] = b.verbSeconds;
        entry["verb_strength"] = b.verbStrength;
        entry["verb_radius_m"] = b.verbRadiusM;
        entry["verb_arc_degrees"] = b.verbArcDegrees;
        entry["verb_cap"] = b.verbCap;
        behaviours[to_godot(id)] = entry;
    }
    d["behaviours"] = behaviours;

    Dictionary horde;
    horde["separation_radius_m"] = rt.hordeSeparationRadiusM;
    horde["separation_strength_mps"] = rt.hordeSeparationStrengthMps;
    horde["give_up_seconds"] = rt.hordeGiveUpSeconds;
    horde["vertical_reach_m"] = rt.hordeVerticalReachM;
    horde["jump_speed_mps"] = rt.hordeJumpSpeedMps;
    horde["max_live_mobs"] = rt.hordeMaxLiveMobs;
    horde["sleep_range_m"] = rt.hordeSleepRangeM;
    horde["sleep_after_seconds"] = rt.hordeSleepAfterSeconds;
    d["horde"] = horde;

    Dictionary boss;
    boss["move_speed_mps"] = rt.boss.moveSpeedMps;
    boss["claw_range_m"] = rt.boss.clawRangeM;
    boss["claw_windup_seconds"] = rt.boss.clawWindupSeconds;
    boss["breath_range_m"] = rt.boss.breathRangeM;
    boss["breath_cone_degrees"] = rt.boss.breathConeDegrees;
    boss["breath_telegraph_seconds"] = rt.boss.breathTelegraphSeconds;
    d["boss"] = boss;

    Dictionary dash;
    dash["invulnerable_seconds"] = rt.dashInvulnerableSeconds;
    dash["duration_seconds"] = rt.dashDurationSeconds;
    d["dash"] = dash;

    Dictionary skills;
    for (const auto& [skillId, numbers] : rt.skillSpatials) {
        Dictionary entry;
        for (const auto& [key, value] : numbers) {
            entry[to_godot(key)] = value;
        }
        skills[to_godot(skillId)] = entry;
    }
    d["skills"] = skills;
    return d;
}

wroughtwild::combat::CombatMods WroughtwildSim::current_mods() const {
    if (trial_ && !trial_->finished()) {
        return trial_->currentMods();
    }
    return wroughtwild::combat::buildMods(tuning_->boons, wroughtwild::boons::RunState{});
}

wroughtwild::boons::BuildTags WroughtwildSim::build_tags() const {
    // The build's identity is the tags of the skills on its bar (D-016):
    // what the player actually fights with, not everything they know.
    wroughtwild::boons::BuildTags tags;
    for (const auto& id : player_->skillBar()) {
        const auto* def = tuning_->skills.findCombatSkill(id);
        if (def == nullptr) {
            continue;
        }
        for (const auto& tag : def->tags) {
            if (std::find(tags.begin(), tags.end(), tag) == tags.end()) {
                tags.push_back(tag);
            }
        }
    }
    return tags;
}

Dictionary WroughtwildSim::combat_mods() const {
    Dictionary d;
    if (!require_loaded("combat_mods")) {
        return d;
    }
    const auto mods = current_mods();
    d["enemy_speed_multiplier"] = mods.enemySpeedMultiplier;
    d["reward_quantity_multiplier"] = mods.rewardQuantityMultiplier;
    d["repeat_hit_count"] = mods.repeatHitCount;
    d["repeat_damage_multiplier"] = mods.repeatDamageMultiplier;
    d["isolated_damage_multiplier"] = mods.isolatedDamageMultiplier;
    d["isolated_area_multiplier"] = mods.isolatedAreaMultiplier;
    d["enemy_life_multiplier"] = mods.enemyLifeMultiplier;
    d["enemy_damage_multiplier"] = mods.enemyDamageMultiplier;
    d["player_damage_multiplier"] = mods.playerDamageMultiplier;
    d["incoming_damage_multiplier"] = mods.incomingDamageMultiplier;
    for (const auto* key : {"melee_reach_multiplier", "staggered_damage_multiplier", "low_life_tempo_multiplier", "control_duration_multiplier", "ailment_duration_multiplier", "boss_recovery_multiplier"})
        d[key] = 1.0;
    for (const auto* key : {"projectile_pierce_bonus", "low_life_threshold", "dash_armour", "dash_armour_seconds", "elite_kill_heal_fraction", "ailment_spread_radius_m", "ailment_spread_fraction", "crowded_extra_count", "reinforcement_count", "reinforcement_delay_seconds", "rare_ward_radius_m", "rare_ward_reduction", "volatile_delay_seconds", "volatile_damage", "volatile_radius_m", "crossfire_extra_projectiles", "crossfire_fan_degrees", "guard_arc_bonus_degrees", "extra_vent_count", "enemy_added_fire_fraction"})
        d[key] = 0.0;
    for (const auto& [key, value] : mods.trialEffects) d[to_godot(key)] = value;
    return d;
}

void WroughtwildSim::begin_fight(int seed) {
    hits_ = std::make_unique<wroughtwild::combat::HitStream>(static_cast<uint64_t>(seed));
}

wroughtwild::grammar::Hit WroughtwildSim::rolled_hit(const String& skill_id, bool isolated,
                                                     const PackedStringArray& target_statuses) {
    const auto* def = find_skill(skill_id);
    if (def == nullptr) {
        UtilityFunctions::push_error("WroughtwildSim.player_hit: unknown skill ", skill_id);
        return {};
    }
    if (!hits_) {
        begin_fight(0);
    }
    std::vector<std::string> carried;
    for (int i = 0; i < target_statuses.size(); ++i) {
        carried.push_back(to_std(target_statuses[i]));
    }
    // The gear and the plate make the hit's typed packets (D-014, D-023
    // slice 2), the struck mob's statuses the forms' reactions; the hit
    // stream rolls the whole hit once, for every packet.
    return hits_->playerHit(wroughtwild::grammar::skillHit(*tuning_, active_mods(), to_std(skill_id), carried),
                            current_mods(), isolated);
}

double WroughtwildSim::player_hit_damage(const String& skill_id, bool isolated) {
    if (!require_loaded("player_hit_damage")) {
        return 0.0;
    }
    double total = 0.0;
    for (const auto& packet : rolled_hit(skill_id, isolated, PackedStringArray())) {
        total += packet.damage;
    }
    return total;
}

Array WroughtwildSim::player_hit(const String& skill_id, bool isolated, const PackedStringArray& target_statuses) {
    Array out;
    if (!require_loaded("player_hit")) {
        return out;
    }
    for (const auto& packet : rolled_hit(skill_id, isolated, target_statuses)) {
        Dictionary d;
        d["type"] = to_godot(packet.type);
        d["damage"] = packet.damage;
        d["added"] = packet.added;
        out.push_back(d);
    }
    return out;
}

double WroughtwildSim::enemy_hit_damage(double raw_damage, const String& damage_type, double bonus_armour) {
    if (!require_loaded("enemy_hit_damage")) {
        return 0.0;
    }
    if (!hits_) {
        begin_fight(0);
    }
    // Armour the engine is granting for a moment (the Plate reading's
    // armour on cast) counts with the sheet's.
    auto stats = derived_now();
    stats.armour += std::max(0.0, bonus_armour);
    // The era's ceiling on armour (Wave 7 slice 2): low until the deep wakes.
    auto base = tuning_->world.playerBase;
    base.armourReductionCap = player_->era().armourReductionCap;
    return hits_->enemyHit(raw_damage, to_std(damage_type), stats, base);
}

double WroughtwildSim::mitigate(double amount, const String& damage_type) const {
    if (!require_loaded("mitigate")) {
        return amount;
    }
    const auto stats = derived_now();
    return wroughtwild::stats::mitigateDamage(amount * current_mods().incomingDamageMultiplier, to_std(damage_type), stats, tuning_->world.playerBase);
}

String WroughtwildSim::export_json() const {
    if (!require_loaded("export_json")) {
        return String();
    }
    wroughtwild::save::SaveGame game;
    game.economy = player_->exportState();
    game.equipment = equipment_;
    game.extra["trial_gate"] = trial_gate_.toJson();
    return to_godot(wroughtwild::save::toJson(game));
}

bool WroughtwildSim::import_json(const String& text) {
    if (!require_loaded("import_json")) {
        return false;
    }
    if (trial_) {
        last_error_ = "An active trial must settle before loading another player state.";
        return false;
    }
    try {
        const wroughtwild::save::SaveGame game = wroughtwild::save::fromJson(to_std(text));
        wroughtwild::trial::GateState gate;
        auto savedGate = game.extra.find("trial_gate");
        if (savedGate != game.extra.end()) gate = wroughtwild::trial::GateState::fromJson(savedGate->second);
        player_->importState(game.economy);
        world_cache_.reset();
        equipment_ = game.equipment;
        trial_gate_ = gate;
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
    d["kit_item"] = to_godot(s->kitItem);
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
        auto machine_config = wroughtwild::contraptions::Config::load(to_std(tuning_directory.path_join("contraptions.json")));
        const auto* feeder_recipe = loaded->crafting.findRecipe("refine_rustclay_brick");
        if (!feeder_recipe || feeder_recipe->station != "forge_basic" || feeder_recipe->baseSkillXp != 0)
            throw std::runtime_error("Pressure feeder requires the existing zero-mastery basic-forge brick recipe.");
        machine_config.feederRecipeInputs = feeder_recipe->inputs;
        machine_config.feederRecipeOutputs = feeder_recipe->outputs;
        machine_config.feederFuelCost = feeder_recipe->fuelCost;
        machine_config.feederFuels = loaded->crafting.fuels;
        for (const auto& recipe : loaded->crafting.recipes) {
            for (const auto& [id, amount] : recipe.inputs) { (void)amount; machine_config.allowedItems.insert(id); }
            for (const auto& [id, amount] : recipe.outputs) { (void)amount; machine_config.allowedItems.insert(id); }
        }
        for (const auto& [id, node] : loaded->worldgen.nodeTypes) { (void)id; machine_config.allowedItems.insert(node.materialFamily); }
        // Machinery handles ordinary stacks, never purse entries or equipment
        // instances whose ownership/quality lives in another economy contract.
        for (const auto& id : loaded->crafting.currencies) machine_config.allowedItems.erase(id);
        for (const auto& base : loaded->items.itemBases) machine_config.allowedItems.erase(base.id);
        auto machines = std::make_unique<wroughtwild::contraptions::MachineWorld>(machine_config);
        auto leyline_config = wroughtwild::leyline::Config::load(to_std(tuning_directory.path_join("leyline.json")));
        auto resonance_config = wroughtwild::resonance::Config::load(to_std(tuning_directory.path_join("resonance.json")));
        // PlayerEconomy keeps a reference to the tuning, so the tuning must
        // outlive it: drop the session and player first, then swap the tuning in.
        trial_.reset();
        player_.reset();
        world_cache_.reset();
        world_profile_ = "legacy_v1";
        structure_.clear();
        tuning_ = std::move(loaded);
        contraptions_ = std::move(machines);
        leylines_.reset();
        leyline_positions_.clear();
        leyline_config_ = std::move(leyline_config);
        resonance_config_ = resonance_config;
        player_ = std::make_unique<wroughtwild::economy::PlayerEconomy>(*tuning_);
        temper_seed_ = std::random_device{}();
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
        if (!recipe.availableIn(world_profile_)) continue;
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
    if (r == nullptr || !r->availableIn(world_profile_)) {
        return d;
    }
    d["id"] = to_godot(r->id);
    d["display_name"] = to_godot(r->displayName);
    d["station"] = to_godot(r->station);
    d["minimum_skill"] = to_dictionary(r->minimumSkill);
    d["inputs"] = to_dictionary(r->inputs);
    d["outputs"] = to_dictionary(r->outputs);
    d["base_skill_xp"] = r->baseSkillXp;
    d["fuel_cost"] = r->fuelCost;
    d["minimum_era"] = r->minimumEra;
    d["era_met"] = player_->currentEra() >= r->minimumEra;
    d["use_categories"] = strings_to_packed(r->useCategories);
    d["description"] = to_godot(r->description);
    // Gate status for UI: the same checks craft() applies. An empty station
    // means hand-crafting: no facility or fuel gate.
    bool skillMet = true;
    for (const auto& [skillId, level] : r->minimumSkill) {
        if (player_->skillLevel(skillId) < level) {
            skillMet = false;
        }
    }
    d["hand_craftable"] = r->station.empty();
    d["station_available"] = r->station.empty() || player_->stationAvailable(r->station);
    d["skill_met"] = skillMet;
    d["inputs_met"] = !player_->craftPlan(r->id).failure.missingInputs;
    d["fuel_met"] = player_->fuelMet(r->id);
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

Dictionary WroughtwildSim::shape(const String& shape_id) const {
    Dictionary d;
    if (!require_loaded("shape")) {
        return d;
    }
    const auto* s = tuning_->construction.findShape(to_std(shape_id));
    if (s == nullptr) {
        return d;
    }
    d["id"] = to_godot(s->id);
    d["display_name"] = to_godot(s->displayName);
    d["material_cost"] = s->materialCost;
    d["size"] = Vector3(static_cast<real_t>(s->sizeM[0]), static_cast<real_t>(s->sizeM[1]),
                        static_cast<real_t>(s->sizeM[2]));
    d["element"] = to_godot(s->element);
    d["form"] = to_godot(s->form);
    d["oriented"] = s->oriented;
    d["cells_tall"] = s->cellsTall;
    d["fine"] = s->fine;
    d["fine_of"] = to_godot(s->fineOf);
    d["hint"] = to_godot(s->hint);
    d["unlock_hint"] = to_godot(s->unlockHint);
    d["requires_traits"] = strings_to_packed(s->requiresTraits);
    d["cells_long"] = s->cellsLong;
    d["requires_world_effect"] = to_godot(s->requiresWorldEffect);
    d["unlocked"] = player_->shapeUnlocked(s->id);
    return d;
}

bool WroughtwildSim::shape_unlocked(const String& shape_id) const {
    return require_loaded("shape_unlocked") && player_->shapeUnlocked(to_std(shape_id));
}

PackedStringArray WroughtwildSim::build_material_ids() const {
    PackedStringArray ids;
    if (!require_loaded("build_material_ids")) {
        return ids;
    }
    for (const auto& m : tuning_->construction.materials) {
        ids.push_back(to_godot(m.id));
    }
    return ids;
}

Dictionary WroughtwildSim::build_material(const String& material_id) const {
    Dictionary d;
    if (!require_loaded("build_material")) {
        return d;
    }
    const auto* m = tuning_->construction.findMaterial(to_std(material_id));
    if (m == nullptr) {
        return d;
    }
    d["id"] = to_godot(m->id);
    d["display_name"] = to_godot(m->displayName);
    d["source"] = to_godot(m->source);
    d["traits"] = strings_to_packed(m->traits);
    d["only_for_trait"] = to_godot(m->onlyForTrait);
    d["texture"] = to_godot(m->texture);
    d["tint"] = to_godot(m->tint);
    auto carried = player_->inventory.find(m->source);
    d["carried"] = carried == player_->inventory.end() ? 0 : carried->second;
    return d;
}

bool WroughtwildSim::shape_allows_family(const String& shape_id, const String& material_family) const {
    return require_loaded("shape_allows_family") &&
           player_->shapeAllowsFamily(to_std(shape_id), to_std(material_family));
}

namespace {

const char* kChestSlot = "chest";

const wroughtwild::tuning::PropertyDef* find_property(const wroughtwild::tuning::ItemTable& table,
                                                      const std::string& id) {
    return table.findModifier(id);
}

const wroughtwild::tuning::PropertyTier* find_tier(const wroughtwild::tuning::PropertyDef* def, int tier) {
    return def == nullptr ? nullptr : def->findTier(tier);
}


} // namespace

Dictionary WroughtwildSim::equipment() const {
    Dictionary d;
    if (!require_loaded("equipment")) {
        return d;
    }
    for (const auto& [slot, item] : equipment_.slots) {
        d[to_godot(slot)] = item_entry(*tuning_, item, -1);
    }
    return d;
}

bool WroughtwildSim::equip_from_inventory(const String& base_id) {
    if (!require_loaded("equip_from_inventory")) {
        return false;
    }
    const std::string id = to_std(base_id);
    const auto* base = tuning_->items.findBase(id);
    auto held = player_->inventory.find(id);
    if (base == nullptr || held == player_->inventory.end() || held->second < 1) {
        return false;
    }
    held->second -= 1;
    auto worn = equipment_.slots.find(base->slot);
    if (worn != equipment_.slots.end()) {
        player_->packItems.push_back(worn->second); // modifiers travel with it (D-014)
    }
    wroughtwild::items::ItemInstance item;
    item.baseId = base->id;
    item.implicitProperties = base->implicitProperties;
    equipment_.slots[base->slot] = item;
    return true;
}

PackedStringArray WroughtwildSim::catalyst_process_ids() const {
    PackedStringArray ids;
    if (require_loaded("catalyst_process_ids")) {
        for (const auto& p : tuning_->crafting.catalystProcesses) {
            ids.push_back(to_godot(p.id));
        }
    }
    return ids;
}

Dictionary WroughtwildSim::catalyst_process(const String& process_id) const {
    Dictionary d;
    if (!require_loaded("catalyst_process")) {
        return d;
    }
    const auto* p = tuning_->crafting.findCatalystProcess(to_std(process_id));
    if (p == nullptr) {
        return d;
    }
    d["id"] = to_godot(p->id);
    d["display_name"] = to_godot(p->displayName);
    d["catalyst"] = to_godot(p->catalyst);
    d["station"] = to_godot(p->station);
    d["process"] = to_godot(p->process);
    d["minimum_skill"] = to_dictionary(p->minimumSkill);
    d["guaranteed_property"] = to_godot(p->guaranteedProperty);
    const auto* def = find_property(tuning_->items, p->guaranteedProperty);
    d["property_display_name"] = to_godot(def ? def->displayName : p->guaranteedProperty);
    d["result_tier"] = p->resultTier;
    const auto* tier = find_tier(def, p->resultTier);
    d["tier_minimum"] = tier ? tier->minimum : 0.0;
    d["tier_maximum"] = tier ? tier->maximum : 0.0;
    d["floor_at_skill"] = tier ? tier->minimum + p->minimumRollFractionAtSkill * (tier->maximum - tier->minimum) : 0.0;
    d["catalyst_held"] = player_->held(p->catalyst);
    d["station_available"] = player_->stationAvailable(p->station);
    bool skillMet = true;
    for (const auto& [skillId, level] : p->minimumSkill) {
        if (player_->skillLevel(skillId) < level) {
            skillMet = false;
        }
    }
    d["skill_met"] = skillMet;
    d["armour_equipped"] = equipment_.slots.count(kChestSlot) > 0;
    return d;
}

Dictionary WroughtwildSim::basic_temper_info() const {
    Dictionary d;
    if (!require_loaded("basic_temper_info")) {
        return d;
    }
    const auto& cfg = tuning_->crafting.basicTemper;
    d["process"] = to_godot(cfg.process);
    d["property"] = to_godot(cfg.property);
    const auto* def = find_property(tuning_->items, cfg.property);
    d["property_display_name"] = to_godot(def ? def->displayName : cfg.property);
    d["tier"] = cfg.tier;
    const auto* tier = find_tier(def, cfg.tier);
    d["value"] = tier ? (tier->minimum + tier->maximum) / 2.0 : 0.0;
    bool stationAvailable = false;
    for (const auto& station : tuning_->crafting.stations) {
        if (player_->stationAvailable(station.id) &&
            std::find(station.supportedProcesses.begin(), station.supportedProcesses.end(), cfg.process) !=
                station.supportedProcesses.end()) {
            stationAvailable = true;
        }
    }
    d["station_available"] = stationAvailable;
    auto worn = equipment_.slots.find(kChestSlot);
    d["armour_equipped"] = worn != equipment_.slots.end();
    d["current_value"] = worn == equipment_.slots.end()
                             ? 0.0
                             : wroughtwild::items::propertyTotal(worn->second, cfg.property);
    return d;
}

Dictionary WroughtwildSim::temper_basic() {
    Dictionary d;
    d["applied"] = false;
    if (!require_loaded("temper_basic")) {
        return d;
    }
    const Dictionary info = basic_temper_info();
    auto worn = equipment_.slots.find(kChestSlot);
    if (worn == equipment_.slots.end()) {
        d["reason"] = "no_armour";
        return d;
    }
    if (!static_cast<bool>(info["station_available"])) {
        d["reason"] = "station_unavailable";
        return d;
    }
    const auto& cfg = tuning_->crafting.basicTemper;
    d["applied"] = wroughtwild::items::basicTemper(tuning_->items, worn->second, cfg.property, cfg.tier);
    d["value"] = wroughtwild::items::propertyTotal(worn->second, cfg.property);
    return d;
}

Dictionary WroughtwildSim::temper_with_catalyst(const String& process_id) {
    Dictionary d;
    d["applied"] = false;
    if (!require_loaded("temper_with_catalyst")) {
        return d;
    }
    const auto* p = tuning_->crafting.findCatalystProcess(to_std(process_id));
    if (p == nullptr) {
        d["reason"] = "unknown_process";
        return d;
    }
    auto worn = equipment_.slots.find(kChestSlot);
    if (worn == equipment_.slots.end()) {
        d["reason"] = "no_armour";
        return d;
    }
    if (!player_->stationAvailable(p->station)) {
        d["reason"] = "station_unavailable";
        return d;
    }
    if (player_->held(p->catalyst) < 1) {
        d["reason"] = "missing_catalyst";
        return d;
    }
    int skillLevel = 0;
    for (const auto& [skillId, level] : p->minimumSkill) {
        skillLevel = player_->skillLevel(skillId);
    }
    const auto result = wroughtwild::items::catalystTemper(tuning_->items, *p, worn->second, skillLevel,
                                                           temper_seed_++);
    if (result.skillTooLow) {
        d["reason"] = "skill_too_low";
        return d;
    }
    if (result.wrongTier) {
        d["reason"] = "wrong_tier";
        return d;
    }
    player_->take(p->catalyst, 1); // consumed only once the temper has applied
    d["applied"] = result.applied;
    d["rolled_value"] = result.rolledValue;
    d["previous_value"] = result.previousValue;
    return d;
}

void WroughtwildSim::set_temper_seed(int seed) {
    temper_seed_ = static_cast<uint64_t>(seed);
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

Dictionary WroughtwildSim::gather_site(const String& site_id) const {
    Dictionary d;
    if (!require_loaded("gather_site")) {
        return d;
    }
    const auto* s = tuning_->world.findSite(to_std(site_id));
    if (s == nullptr) {
        return d;
    }
    d["id"] = to_godot(s->id);
    d["display_name"] = to_godot(s->displayName);
    d["yields_per_action"] = to_dictionary(s->yieldsPerAction);
    d["ambush_chance"] = s->ambushChance;
    PackedStringArray enemies;
    for (const auto& id : s->ambushEnemies) {
        enemies.push_back(to_godot(id));
    }
    d["ambush_enemies"] = enemies;
    d["ambush_removed_by_world_effect"] = to_godot(s->ambushRemovedByWorldEffect);
    return d;
}

void WroughtwildSim::add_materials(const Dictionary& amounts) {
    if (!require_loaded("add_materials")) {
        return;
    }
    std::map<std::string, int> converted;
    const Array keys = amounts.keys();
    for (int i = 0; i < keys.size(); ++i) {
        const int amount = static_cast<int>(amounts[keys[i]]);
        if (amount > 0) {
            converted[to_std(String(keys[i]))] = amount;
        }
    }
    // Currency ids (crafting.json "currencies") land in the purse; everything
    // else is a carried material.
    for (const auto& [id, amount] : converted) {
        if (tuning_->crafting.isCurrency(id)) {
            player_->currency[id] += amount;
        } else {
            player_->inventory[id] += amount;
        }
    }
}

Dictionary WroughtwildSim::drop_inventory() {
    Dictionary dropped;
    if (!require_loaded("drop_inventory")) {
        return dropped;
    }
    for (const auto& [id, count] : player_->inventory) {
        if (count > 0) {
            dropped[to_godot(id)] = count;
        }
    }
    player_->inventory.clear();
    return dropped;
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

Dictionary WroughtwildSim::craft(const String& recipe_id, bool for_order, const String& aim_kind, int quality, int quantity) {
    Dictionary d;
    d["crafted"] = false;
    if (!require_loaded("craft")) {
        return d;
    }
    const auto result = player_->craftBatch(to_std(recipe_id), for_order, to_std(aim_kind), quality, quantity);
    d["crafted"] = result.crafted;
    d["xp_granted"] = result.xpGranted;
    d["xp_multiplier"] = result.xpMultiplier;
    if (!result.crafted) {
        const auto& f = result.failure;
        d["failure"] = f.unknownRecipe        ? "unknown_recipe"
                       : f.stationUnavailable ? "station_unavailable"
                       : f.skillTooLow        ? "skill_too_low"
                       : f.incompatibleKind   ? "incompatible_kind"
                       : f.qualityUnavailable ? "quality_unavailable"
                       : f.invalidQuantity    ? "invalid_quantity"
                       : f.missingKind        ? "missing_kind"
                       : f.missingInputs      ? "missing_inputs"
                       : f.missingFuel        ? "missing_fuel"
                                              : "unknown";
    }
    return d;
}

Dictionary WroughtwildSim::craft_preview(const String& recipe_id, const String& aim_kind, int quality, int quantity) const {
    Dictionary d;
    if (!require_loaded("craft_preview")) return d;
    const auto* recipe = tuning_->crafting.findRecipe(to_std(recipe_id));
    if (!recipe || !recipe->availableIn(world_profile_)) return d;
    const auto plan = player_->craftPlan(recipe->id, to_std(aim_kind), quality, quantity);
    d["ready"] = !plan.failure.any();
    d["base_id"] = to_godot(plan.baseId); d["quality"] = plan.quality; d["potency"] = plan.potency;
    d["quantity"] = quantity; d["batch_maximum"] = tuning_->crafting.batchMaximum;
    d["fuel"] = plan.fuel; d["minimum_count"] = plan.minimumCount;
    d["roll_floor"] = plan.rollFloor;
    d["incompatible_kind"] = plan.failure.incompatibleKind;
    d["quality_available"] = !plan.failure.qualityUnavailable;
    d["outputs"] = to_dictionary(recipe->outputs);
    d["comparison"] = plan.baseId.empty() ? Dictionary() : compare_equipment(-2, to_godot(plan.baseId));
    auto source = [&](const std::string& id) {
        for (const auto& r : tuning_->crafting.recipes) if (r.availableIn(world_profile_) && r.outputs.count(id)) return r.id;
        return std::string();
    };
    Array costs;
    int fuelAvailable = 0;
    for (const auto& [id, value] : tuning_->crafting.fuels) {
        auto reserved = plan.costs.find(id);
        fuelAvailable += std::max(0, player_->held(id) - (reserved == plan.costs.end() ? 0 : reserved->second)) * value;
    }
    d["fuel_available"] = fuelAvailable;
    for (const auto& [id, count] : plan.costs) {
        Dictionary row;
        row["id"] = to_godot(id); row["need"] = count; row["have"] = player_->held(id);
        row["recipe"] = to_godot(source(id)); costs.push_back(row);
    }
    d["costs"] = costs;
    String reason;
    if (plan.failure.invalidQuantity) reason = "Choose one equipment item or a material batch within the limit.";
    else if (plan.failure.incompatibleKind) reason = "This Kind has no compatible modifier at this potency. Choose another Kind.";
    else if (plan.failure.stationUnavailable) reason = "Use " + to_godot(tuning_->crafting.findStation(recipe->station)->displayName) + ".";
    else if (plan.failure.qualityUnavailable) {
        const int gradeIndex = std::clamp(std::max(quality, plan.potency), 1, static_cast<int>(tuning_->crafting.grades.size())) - 1;
        const auto& grade = tuning_->crafting.grades[static_cast<size_t>(gradeIndex)];
        int requiredSkill = grade.minimumSkill;
        for (const auto& [skill, minimum] : recipe->minimumSkill) { (void)skill; requiredSkill = std::max(requiredSkill, minimum); }
        reason = "Requires " + to_godot(grade.station.empty() ? recipe->station : grade.station) + ", Blacksmithing " + String::num_int64(requiredSkill) + ", Era " + String::num_int64(std::max(grade.minimumEra, recipe->minimumEra)) + ".";
    } else if (plan.failure.skillTooLow) {
        for (const auto& [skill, level] : recipe->minimumSkill) if (player_->skillLevel(skill) < level) reason = "Requires " + to_godot(skill) + " " + String::num_int64(level) + ".";
    } else if (plan.failure.missingInputs || plan.failure.missingKind) {
        for (const auto& [id, count] : plan.costs) if (player_->held(id) < count) {
            reason = "Need " + String::num_int64(count - player_->held(id)) + " more " + to_godot(id) + "."; break;
        }
    } else if (plan.failure.missingFuel) reason = "Add fuel after reserving the recipe ingredients.";
    else reason = "Ready to make.";
    d["next_action"] = reason;
    Array grades;
    for (const auto& grade : tuning_->crafting.grades) {
        Dictionary row;
        row["tier"] = grade.tier; row["quality"] = to_godot(grade.quality); row["potency"] = to_godot(grade.potency);
        row["station"] = to_godot(grade.station); row["skill"] = grade.minimumSkill; row["era"] = grade.minimumEra;
        row["available"] = (grade.station.empty() || player_->stationAvailable(grade.station)) && player_->skillLevel("blacksmithing") >= grade.minimumSkill && player_->currentEra() >= grade.minimumEra;
        row["reinforcement"] = to_dictionary(grade.reinforcement);
        row["recipe"] = grade.reinforcement.empty() ? String() : to_godot(source(grade.reinforcement.begin()->first));
        grades.push_back(row);
    }
    d["grades"] = grades;
    Array outcomes;
    std::map<int, double> chances;
    for (size_t i = 0; i < plan.counts.size(); ++i) chances[std::max(plan.minimumCount, static_cast<int>(i))] += plan.counts[i];
    static const std::vector<std::string> names = {"Plain", "Worked", "Keen", "Refined", "Wrought"};
    for (const auto& [count, chance] : chances) if (chance > 0) {
        Dictionary row; row["count"] = count; row["chance"] = chance; row["name"] = to_godot(names.at(count)); outcomes.push_back(row);
    }
    d["outcomes"] = outcomes;
    Array kinds;
    if (!plan.baseId.empty()) for (const auto& kind : tuning_->crafting.currencyKinds) {
        const auto option = player_->craftPlan(recipe->id, kind.id, quality);
        Dictionary row;
        row["id"] = to_godot(kind.id); row["canonical_kind"] = to_godot(kind.canonicalKind);
        row["display_name"] = to_godot(kind.displayName); row["potency"] = kind.potency;
        row["family"] = to_godot(kind.craftTag); row["held"] = player_->held(kind.id);
        row["compatible"] = !option.failure.incompatibleKind; row["process_available"] = !option.failure.qualityUnavailable;
        row["recipe"] = to_godot(source(kind.id)); kinds.push_back(row);
    }
    d["kinds"] = kinds;
    Array modifiers;
    const auto* base = tuning_->items.findBase(plan.baseId);
    const auto* aim = tuning_->crafting.findKind(to_std(aim_kind));
    if (base) for (const auto* modifier : wroughtwild::items::eligibleModifiers(tuning_->items, *base)) {
        if (aim && std::find(modifier->tags.begin(), modifier->tags.end(), aim->craftTag) == modifier->tags.end()) continue;
        Dictionary row; row["name"] = to_godot(modifier->displayName); row["id"] = to_godot(modifier->id);
        row["eligible"] = modifier->fromTier <= plan.potency;
        row["from_tier"] = modifier->fromTier;
        Array bands;
        for (const auto& band : modifier->craftTiers) {
            Dictionary range;
            range["tier"] = band.tier; range["eligible"] = modifier->fromTier <= band.tier;
            const double floor = band.minimum + plan.rollFloor * (band.maximum - band.minimum);
            range["minimum"] = floor; range["maximum"] = band.maximum;
            range["minimum_sentence"] = to_godot(wroughtwild::items::modifierSentence(*modifier, floor));
            range["maximum_sentence"] = to_godot(wroughtwild::items::modifierSentence(*modifier, band.maximum));
            auto weak = wroughtwild::items::craftBand(*modifier, quality);
            range["expressed_maximum"] = quality < band.tier && weak ? std::min(band.maximum, weak->maximum) : band.maximum;
            range["expressed_sentence"] = to_godot(wroughtwild::items::modifierSentence(*modifier, static_cast<double>(range["expressed_maximum"])));
            range["held_back"] = quality < band.tier;
            PackedStringArray breakpoints;
            for (const auto* bp : wroughtwild::items::breakpointsFor(*modifier, band.tier, true)) breakpoints.push_back(to_godot(bp->text));
            range["breakpoints"] = breakpoints;
            bands.push_back(range);
        }
        row["bands"] = bands; modifiers.push_back(row);
    }
    d["modifiers"] = modifiers;
    return d;
}

bool WroughtwildSim::salvage(const String& recipe_id) {
    return require_loaded("salvage") && player_->salvage(to_std(recipe_id));
}

int WroughtwildSim::fuel_value_held() const {
    return require_loaded("fuel_value_held") ? player_->fuelValueHeld() : 0;
}

Dictionary WroughtwildSim::fuels() const {
    Dictionary d;
    if (require_loaded("fuels")) {
        for (const auto& [item, value] : tuning_->crafting.fuels) {
            d[to_godot(item)] = value;
        }
    }
    return d;
}

String WroughtwildSim::kit_station(const String& kit_item_id) const {
    if (!require_loaded("kit_station")) {
        return String();
    }
    const auto* station = tuning_->crafting.findStationForKit(to_std(kit_item_id));
    return station != nullptr ? to_godot(station->id) : String();
}

PackedStringArray WroughtwildSim::kit_item_ids() const {
    PackedStringArray ids;
    if (require_loaded("kit_item_ids")) {
        for (const auto& kind : contraption_kinds()) ids.push_back(String(kind) + String("_kit"));
        for (const auto& station : tuning_->crafting.stations) {
            if (!station.kitItem.empty()) {
                ids.push_back(to_godot(station.kitItem));
            }
        }
    }
    return ids;
}

const wroughtwild::tuning::EliteModifierDef* WroughtwildSim::find_elite(const String& elite_id) const {
    if (elite_id.is_empty()) {
        return nullptr;
    }
    return tuning_->world.findEliteModifier(to_std(elite_id));
}

Dictionary WroughtwildSim::enemy_loot(const String& enemy_id, int seed, const String& elite_id) {
    Dictionary d;
    if (!require_loaded("enemy_loot")) {
        return d;
    }
    const auto drops = wroughtwild::loot::rollEnemyLoot(
        tuning_->world, to_std(enemy_id), static_cast<uint64_t>(seed), find_elite(elite_id));
    for (const auto& [item, count] : drops) {
        d[to_godot(item)] = count;
    }
    return d;
}

Array WroughtwildSim::enemy_gear_loot(const String& enemy_id, int seed, const String& elite_id) {
    Array out;
    if (!require_loaded("enemy_gear_loot")) {
        return out;
    }
    const auto gear = wroughtwild::loot::rollEnemyGear(*tuning_, to_std(enemy_id),
                                                       static_cast<uint64_t>(seed), find_elite(elite_id),
                                                       player_->currentEra());
    for (const auto& item : gear) {
        out.push_back(item_entry(*tuning_, item, -1));
    }
    return out;
}

Array WroughtwildSim::claim_enemy_gear(const String& enemy_id, int seed, const String& elite_id) {
    Array out;
    if (!require_loaded("claim_enemy_gear")) {
        return out;
    }
    // The same kill rolls the same gear (the gear stream is deterministic per
    // seed and elite), so a pickup only needs to remember which kill it came
    // from - the elite id included.
    const auto gear = wroughtwild::loot::rollEnemyGear(*tuning_, to_std(enemy_id),
                                                       static_cast<uint64_t>(seed), find_elite(elite_id),
                                                       player_->currentEra());
    for (const auto& item : gear) {
        player_->packItems.push_back(item);
        out.push_back(item_entry(*tuning_, item, static_cast<int>(player_->packItems.size()) - 1));
    }
    return out;
}

String WroughtwildSim::enemy_skill_page(const String& enemy_id, int seed, const String& elite_id) const {
    if (!require_loaded("enemy_skill_page")) {
        return String();
    }
    return to_godot(wroughtwild::loot::rollEnemySkillPage(*tuning_, to_std(enemy_id), static_cast<uint64_t>(seed),
                                                          player_->knownSkills(), find_elite(elite_id)));
}

PackedStringArray WroughtwildSim::elite_modifier_ids() const {
    PackedStringArray ids;
    if (require_loaded("elite_modifier_ids")) {
        for (const auto& def : tuning_->world.eliteModifiers) {
            ids.push_back(to_godot(def.id));
        }
    }
    return ids;
}

Dictionary WroughtwildSim::elite_modifier(const String& elite_id) const {
    Dictionary d;
    if (!require_loaded("elite_modifier")) {
        return d;
    }
    const auto* def = find_elite(elite_id);
    if (def == nullptr) {
        return d;
    }
    d["id"] = to_godot(def->id);
    d["display_name"] = to_godot(def->displayName);
    d["life_multiplier"] = def->lifeMultiplier;
    d["speed_multiplier"] = def->speedMultiplier;
    d["damage_multiplier"] = def->damageMultiplier;
    d["immune_statuses"] = strings_to_packed(def->immuneStatuses);
    Dictionary taken;
    for (const auto& [type, share] : def->damageTaken) {
        taken[to_godot(type)] = share;
    }
    d["damage_taken"] = taken;
    d["death_burst_damage"] = def->deathBurstDamage;
    d["death_burst_radius_m"] = def->deathBurstRadiusM;
    d["death_burst_type"] = to_godot(def->deathBurstType);
    d["extra_loot_rolls"] = def->extraLootRolls;
    d["gear_chance_multiplier"] = def->gearChanceMultiplier;
    d["page_chance_multiplier"] = def->pageChanceMultiplier;
    return d;
}

PackedStringArray WroughtwildSim::player_build_tags() const {
    PackedStringArray tags;
    if (require_loaded("player_build_tags")) {
        tags = strings_to_packed(build_tags());
    }
    return tags;
}

PackedStringArray WroughtwildSim::known_skill_ids() const {
    PackedStringArray ids;
    if (require_loaded("known_skill_ids")) {
        ids = strings_to_packed(player_->knownSkills());
    }
    return ids;
}

bool WroughtwildSim::knows_skill(const String& skill_id) const {
    return require_loaded("knows_skill") && player_->knowsSkill(to_std(skill_id));
}

int WroughtwildSim::skill_bar_size() const { return wroughtwild::economy::kSkillBarSize; }

PackedStringArray WroughtwildSim::skill_bar() const {
    PackedStringArray ids;
    if (require_loaded("skill_bar")) {
        ids = strings_to_packed(player_->skillBar());
    }
    return ids;
}

bool WroughtwildSim::set_bar_slot(int slot, const String& skill_id) {
    return require_loaded("set_bar_slot") && player_->setBarSlot(slot, to_std(skill_id));
}

bool WroughtwildSim::learn_skill(const String& skill_id) {
    return require_loaded("learn_skill") && player_->learnSkill(to_std(skill_id));
}

PackedStringArray WroughtwildSim::skill_mod_ids() const {
    PackedStringArray ids;
    if (require_loaded("skill_mod_ids")) {
        for (const auto& def : tuning_->items.modifiers) {
            if (!def.isSelf()) {
                ids.push_back(to_godot(def.id));
            }
        }
    }
    return ids;
}

Dictionary WroughtwildSim::skill_mod(const String& mod_id) const {
    Dictionary d;
    if (!require_loaded("skill_mod")) {
        return d;
    }
    const auto* def = tuning_->items.findModifier(to_std(mod_id));
    if (def == nullptr || def->isSelf()) {
        return d;
    }
    const double value = wroughtwild::grammar::defaultValue(*def);
    d["id"] = to_godot(def->id);
    d["display_name"] = to_godot(def->displayName);
    d["applies_to_tags"] = strings_to_packed(def->appliesToTags);
    Dictionary effect;
    effect[to_godot(def->effectKey)] = value;
    d["effect"] = effect;
    d["sentence"] = to_godot(wroughtwild::items::modifierSentence(*def, value));
    d["active"] = active_skill_mods_.count(def->id) > 0;
    return d;
}

void WroughtwildSim::set_skill_mod_active(const String& mod_id, bool active) {
    if (!require_loaded("set_skill_mod_active")) {
        return;
    }
    const std::string id = to_std(mod_id);
    const auto* def = tuning_->items.findModifier(id);
    if (def == nullptr || def->isSelf()) {
        return;
    }
    if (active) {
        active_skill_mods_.insert(id);
    } else {
        active_skill_mods_.erase(id);
    }
}

bool WroughtwildSim::skill_mod_active(const String& mod_id) const {
    return active_skill_mods_.count(to_std(mod_id)) > 0;
}

int WroughtwildSim::fork_count(const String& skill_id) const {
    if (!require_loaded("fork_count")) {
        return 0;
    }
    return wroughtwild::grammar::forkCount(*tuning_, active_mods(), to_std(skill_id));
}

double WroughtwildSim::fork_damage_fraction(const String& skill_id, int generation) const {
    if (!require_loaded("fork_damage_fraction")) {
        return 1.0;
    }
    return wroughtwild::grammar::forkDamageFraction(*tuning_, to_std(skill_id), generation);
}

double WroughtwildSim::chill_applied(const String& skill_id, bool is_boss) const {
    if (!require_loaded("chill_applied")) {
        return 0.0;
    }
    return wroughtwild::grammar::chillApplied(*tuning_, active_mods(), to_std(skill_id),
                                              is_boss);
}

double WroughtwildSim::ignite_applied(const String& skill_id, bool is_boss) const {
    if (!require_loaded("ignite_applied")) {
        return 0.0;
    }
    return wroughtwild::grammar::igniteApplied(*tuning_, active_mods(), to_std(skill_id), is_boss);
}

double WroughtwildSim::bleed_applied(const String& skill_id, bool is_boss) const {
    if (!require_loaded("bleed_applied")) {
        return 0.0;
    }
    return wroughtwild::grammar::bleedApplied(*tuning_, active_mods(), to_std(skill_id), is_boss);
}

Dictionary WroughtwildSim::chill_status() const {
    Dictionary d;
    if (require_loaded("chill_status")) {
        d["buildup_max"] = tuning_->grammar.chill.buildupMax;
        d["freeze_duration_s"] = tuning_->grammar.chill.freezeDurationS;
        d["decay_per_s"] = tuning_->grammar.chill.decayPerS;
    }
    return d;
}

namespace {

Dictionary dot_status_entry(const wroughtwild::grammar::DotStatus& status) {
    Dictionary d;
    d["buildup_max"] = status.buildupMax;
    d["decay_per_s"] = status.decayPerS;
    d["duration_s"] = status.durationS;
    d["damage_per_s"] = status.damagePerS;
    d["moving_multiplier"] = status.movingMultiplier;
    return d;
}

} // namespace

Dictionary WroughtwildSim::ignite_status() const {
    if (!require_loaded("ignite_status")) {
        return Dictionary();
    }
    return dot_status_entry(wroughtwild::grammar::igniteStatus(*tuning_, active_mods()));
}

Dictionary WroughtwildSim::bleed_status() const {
    if (!require_loaded("bleed_status")) {
        return Dictionary();
    }
    return dot_status_entry(wroughtwild::grammar::bleedStatus(*tuning_, active_mods()));
}

Dictionary WroughtwildSim::proliferate_for() const {
    Dictionary d;
    d["enabled"] = false;
    if (!require_loaded("proliferate_for")) {
        return d;
    }
    const auto params = wroughtwild::grammar::proliferateFor(*tuning_, active_mods());
    d["enabled"] = params.enabled;
    d["radius_m"] = params.radiusM;
    d["spread_buildup"] = params.spreadBuildup;
    // Bosses resist spread the way they resist any ignite hit.
    d["spread_buildup_boss"] = params.spreadBuildup * tuning_->grammar.ignite.bossBuildupMultiplier;
    return d;
}

Dictionary WroughtwildSim::shatter_for(const String& skill_id) const {
    Dictionary d;
    d["enabled"] = false;
    if (!require_loaded("shatter_for")) {
        return d;
    }
    const auto params =
        wroughtwild::grammar::shatterFor(*tuning_, active_mods(), to_std(skill_id));
    d["enabled"] = params.enabled;
    d["nova_damage"] = params.novaDamage;
    d["nova_damage_type"] = to_godot(params.novaDamageType);
    d["nova_radius_m"] = params.novaRadiusM;
    d["executes_frozen"] = params.executesFrozen;
    d["executes_boss"] = params.executesBoss;
    return d;
}

Dictionary WroughtwildSim::shatter_rules() const {
    Dictionary d;
    d["enabled"] = false;
    if (!require_loaded("shatter_rules")) {
        return d;
    }
    const auto& hook = tuning_->grammar.shatter;
    d["enabled"] = true;
    d["nova_damage"] = hook.novaDamage;
    d["nova_damage_type"] = to_godot(hook.novaDamageType);
    d["nova_radius_m"] = hook.novaRadiusM;
    d["executes_frozen"] = hook.executesFrozen;
    d["executes_boss"] = hook.executesBoss;
    return d;
}

int WroughtwildSim::skill_echo_every(const String& skill_id) const {
    return require_loaded("skill_echo_every") ? wroughtwild::grammar::skillEchoEvery(*tuning_, active_mods(), to_std(skill_id)) : 0;
}

bool WroughtwildSim::skill_quenches(const String& skill_id) const {
    return require_loaded("skill_quenches") && wroughtwild::grammar::skillQuenches(*tuning_, active_mods(), to_std(skill_id));
}

double WroughtwildSim::skill_nova_chill(const String& skill_id) const {
    return require_loaded("skill_nova_chill") ? wroughtwild::grammar::skillNovaChill(*tuning_, active_mods(), to_std(skill_id)) : 0.0;
}

double WroughtwildSim::skill_sear(const String& skill_id) const {
    return require_loaded("skill_sear") ? wroughtwild::grammar::skillSear(*tuning_, active_mods(), to_std(skill_id)) : 0.0;
}

bool WroughtwildSim::skill_brittle(const String& skill_id) const {
    return require_loaded("skill_brittle") && wroughtwild::grammar::skillBrittle(*tuning_, active_mods(), to_std(skill_id));
}

double WroughtwildSim::skill_arc(const String& skill_id) const {
    return require_loaded("skill_arc") ? wroughtwild::grammar::skillArc(*tuning_, active_mods(), to_std(skill_id)) : 0.0;
}

double WroughtwildSim::skill_life_on_hit(const String& skill_id) const {
    return require_loaded("skill_life_on_hit") ? wroughtwild::grammar::skillLifeOnHit(*tuning_, active_mods(), to_std(skill_id)) : 0.0;
}

double WroughtwildSim::skill_refund_on_kill(const String& skill_id) const {
    return require_loaded("skill_refund_on_kill") ? wroughtwild::grammar::skillRefundOnKill(*tuning_, active_mods(), to_std(skill_id)) : 0.0;
}

double WroughtwildSim::skill_haste_on_kill(const String& skill_id) const {
    return require_loaded("skill_haste_on_kill") ? wroughtwild::grammar::skillHasteOnKill(*tuning_, active_mods(), to_std(skill_id)) : 0.0;
}

int WroughtwildSim::skill_projectiles(const String& skill_id) const {
    return require_loaded("skill_projectiles") ? wroughtwild::grammar::skillProjectiles(*tuning_, active_mods(), to_std(skill_id)) : 1;
}

int WroughtwildSim::skill_pierce(const String& skill_id) const {
    return require_loaded("skill_pierce") ? wroughtwild::grammar::skillPierce(*tuning_, active_mods(), to_std(skill_id)) : 0;
}

bool WroughtwildSim::foundry_choose_class(const String& class_id) {
    return require_loaded("foundry_choose_class") && player_->foundryChooseClass(to_std(class_id));
}

bool WroughtwildSim::foundry_specialise(const String& specialisation) {
    return require_loaded("foundry_specialise") && player_->foundrySpecialise(to_std(specialisation));
}

bool WroughtwildSim::foundry_set_rail(const String& axis, int index, const String& pattern) {
    return require_loaded("foundry_set_rail") && player_->foundrySetRail(to_std(axis), index, to_std(pattern));
}

bool WroughtwildSim::foundry_clear_rail(const String& axis, int index) {
    return require_loaded("foundry_clear_rail") && player_->foundryClearRail(to_std(axis), index);
}

Dictionary WroughtwildSim::foundry_pattern(const String& pattern_id) const {
    Dictionary d;
    if (!require_loaded("foundry_pattern")) {
        return d;
    }
    const auto* def = tuning_->foundry.rails.findPattern(to_std(pattern_id));
    if (def == nullptr) {
        return d;
    }
    d["id"] = to_godot(def->id);
    d["display_name"] = to_godot(def->displayName);
    d["axis"] = to_godot(def->axis);
    d["condition_text"] = to_godot(def->conditionText);
    d["rule_text"] = to_godot(def->ruleText);
    d["manner"] = def->isManner();
    d["taught_by"] = to_godot(def->taughtByEnemy);
    d["taught_kills"] = def->taughtKills;
    const auto* teacher = def->isManner() ? tuning_->world.findEnemy(def->taughtByEnemy) : nullptr;
    d["teacher_name"] = teacher ? to_godot(teacher->displayName) : String();
    return d;
}

Array WroughtwildSim::foundry_links() const {
    Array out;
    if (!require_loaded("foundry_links")) {
        return out;
    }
    for (const auto& link : wroughtwild::foundry::links(*tuning_, player_->foundry(), player_->plate())) {
        Dictionary d;
        d["first"] = to_godot(link.first);
        d["second"] = to_godot(link.second);
        d["row"] = link.row;
        d["col"] = link.col;
        d["support_row"] = link.supportRow;
        d["support_col"] = link.supportCol;
        out.push_back(d);
    }
    return out;
}

PackedStringArray WroughtwildSim::skill_triggers(const String& skill_id) const {
    if (!require_loaded("skill_triggers")) {
        return PackedStringArray();
    }
    return strings_to_packed(wroughtwild::grammar::skillTriggers(*tuning_, active_mods(), to_std(skill_id)));
}

PackedStringArray WroughtwildSim::linked_casts(const String& skill_id, const String& trigger) const {
    if (!require_loaded("linked_casts")) {
        return PackedStringArray();
    }
    return strings_to_packed(wroughtwild::grammar::linkedCasts(*tuning_, active_mods(), player_->foundry(), player_->plate(),
                                                                to_std(skill_id), to_std(trigger)));
}

bool WroughtwildSim::set_campaign_policy(const String& policy) {
    if (!require_loaded("set_campaign_policy")) return false;
    const auto id=to_std(policy);
    if (id!="legacy" && id!=wroughtwild::resonance::campaign) return false;
    if (player_->resonanceState.phase!="dormant" || player_->secondResonance.phase!="dormant") return false;
    player_->campaignPolicy=id; world_cache_.reset(); return true;
}
String WroughtwildSim::campaign_policy() const { return player_ ? to_godot(player_->campaignPolicy) : String("legacy"); }
String WroughtwildSim::resonance_json() const { return player_ && player_->campaignPolicy==wroughtwild::resonance::campaign ? to_godot(player_->resonanceState.toJson()) : String(); }
String WroughtwildSim::resonance_second_json() const { return player_ && player_->campaignPolicy==wroughtwild::resonance::campaign ? to_godot(player_->secondResonance.toJson()) : String(); }
String WroughtwildSim::resonance_signature() const { return player_ && player_->campaignPolicy==wroughtwild::resonance::campaign ? (resonance_json()+resonance_second_json()).sha256_text() : String(); }
bool WroughtwildSim::resonance_queue(int seed) {
    if (!require_loaded("resonance_queue") || trial_ || seed<0 || player_->campaignPolicy!=wroughtwild::resonance::campaign || world_profile_!="living_frontier_wave3" || player_->resonanceState.phase!="dormant") return false;
    player_->resonanceState.phase="pending";player_->resonanceState.seed=static_cast<uint64_t>(seed);world_cache_.reset();return true;
}
bool WroughtwildSim::resonance_validate_world(const String& profile,int seed) {
    if (!require_loaded("resonance_validate_world")) return false;
    if (player_->campaignPolicy=="legacy")return true;
    try {
        if(to_std(profile)!="living_frontier_wave3" || seed<0)throw std::runtime_error("Campaign and saved geography disagree");
        if(!set_world_profile(profile))return false;
        (void)cached_world(static_cast<uint64_t>(seed)); return true;
    } catch(const std::exception& e) {last_error_=to_godot(e.what());return false;}
}
bool WroughtwildSim::resonance_prepare(int seed,const Array& protection) {
    if (!require_loaded("resonance_prepare")) return false;
    const bool second=player_->resonanceState.phase=="applied" && player_->secondResonance.phase=="pending";
    auto& event=second?player_->secondResonance:player_->resonanceState;
    if (trial_ || seed<0 || player_->campaignPolicy!=wroughtwild::resonance::campaign || world_profile_!="living_frontier_wave3" || event.phase!="pending" || event.seed!=static_cast<uint64_t>(seed) || (second && (!player_->resonanceState.campaignAward || !player_->worldEffectActive("lf5_pairing_victory")))) {
        last_error_="No pending resonance for this world";return false;
    }
    try {
        std::vector<wroughtwild::resonance::Bounds> bounds;
        for(int64_t i=0;i<protection.size();++i) {
            const Array a=protection[i];if(a.size()!=4)throw std::runtime_error("Invalid protection bounds");
            double b[4];for(int j=0;j<4;++j) {b[j]=static_cast<double>(a[j]);if(!std::isfinite(b[j]))throw std::runtime_error("Invalid protection coordinate");}
            if(b[0]>b[2] || b[1]>b[3])throw std::runtime_error("Reversed protection bounds");
            bounds.push_back({b[0],b[1],b[2],b[3]});
        }
        const auto& current=cached_world(static_cast<uint64_t>(seed));
        if(second)for(const auto& c:player_->resonanceState.columns)
            bounds.push_back({c.x*current.cellSize,c.z*current.cellSize,(c.x+1)*current.cellSize,(c.z+1)*current.cellSize});
        auto prepared=wroughtwild::resonance::prepare(current,resonance_config_,bounds,event.event);
        prepared.campaignAward=player_->worldEffectActive(second?"lf5_pairing_victory":"lf4_annex_victory");
        // Reuse the exact candidate voxel field instead of generating it again
        // when the publisher asks for its node list. Never reuse stale signatures.
        wroughtwild::resonance::apply(*world_cache_,prepared);
        event=std::move(prepared);
        if(event.campaignAward)player_->recordWorldEffect(second?"ash_tide":"stonecut_blocks");
        world_cache_resonance_=player_->resonanceState.toJson()+player_->secondResonance.toJson();
        last_error_=String();return true;
    } catch(const std::exception& e) {world_cache_.reset();last_error_=to_godot(e.what());return false;}
}

const wroughtwild::worldgen::WorldMap& WroughtwildSim::cached_world(uint64_t seed) {
    // The 3D world costs real time to generate; world_map and world_mesh
    // are always asked about the same seed back to back, so keep the last
    // one. Deterministic generation makes the cache invisible.
    const std::string signature = player_->campaignPolicy==wroughtwild::resonance::campaign ? player_->resonanceState.toJson()+player_->secondResonance.toJson() : "";
    if (!world_cache_ || world_cache_->seed != seed || world_cache_->profileId != world_profile_ || world_cache_resonance_!=signature) {
        world_cache_.reset(); // Do not retain the old voxel field during new generation.
        world_cache_ = std::make_unique<wroughtwild::worldgen::WorldMap>(
            wroughtwild::worldgen::generateProfile(*tuning_, seed, world_profile_));
        if (player_->campaignPolicy == wroughtwild::resonance::campaign) {
            try {
                wroughtwild::resonance::apply(*world_cache_, player_->resonanceState);
                wroughtwild::resonance::apply(*world_cache_, player_->secondResonance);
            }
            catch (...) { world_cache_.reset(); throw; }
        }
        world_cache_resonance_=signature;
    }
    return *world_cache_;
}

const wroughtwild::tuning::WorldgenTable& WroughtwildSim::world_table() const {
    return wroughtwild::worldgen::profileTable(*tuning_, world_profile_);
}

bool WroughtwildSim::set_world_profile(const String& profile_id) {
    if (!require_loaded("set_world_profile")) return false;
    const std::string id = to_std(profile_id);
    if (!wroughtwild::worldgen::knownProfile(id) ||
        wroughtwild::worldgen::profileTable(*tuning_, id).generationProfile != id) {
        last_error_ = "Unknown or unavailable generation profile: " + profile_id;
        return false;
    }
    if (id != world_profile_) {
        world_profile_ = id;
        // A validating save restore may already have prepared this profile.
        if (world_cache_ && world_cache_->profileId != id) world_cache_.reset();
    }
    player_->worldProfile = id;
    last_error_ = String();
    return true;
}

bool WroughtwildSim::trial_start_story(int seed, const String& run_id) {
    if (!require_loaded("trial_start_story") || trial_) return false;
    std::string id = run_id.is_empty() ? "forge_tyrant" : to_std(run_id);
    if (player_->campaignPolicy == wroughtwild::resonance::campaign &&
        (id!="forge_tyrant" && (id!="deep_forge" || !player_->resonanceState.campaignAward))) return false;
    const auto* run = tuning_->trial.findExpedition(id);
    if (!run || (!run->requiresWorldEffect.empty() && !player_->worldEffectActive(run->requiresWorldEffect))) return false;
    trial_ = std::make_unique<wroughtwild::trial::TrialSession>(*tuning_, *player_, build_tags(), static_cast<uint64_t>(seed), run);
    return true;
}

Array WroughtwildSim::trial_story_runs() const {
    Array out;
    if (!require_loaded("trial_story_runs")) return out;
    for (const auto& historical : tuning_->trial.expeditions) {
        const bool laboratory=player_->campaignPolicy==wroughtwild::resonance::campaign;
        if (laboratory && historical.id!="forge_tyrant" && historical.id!="deep_forge") continue;
        const auto& run=laboratory ? (historical.id=="deep_forge" ? tuning_->pairingLaboratory : tuning_->laboratory) : historical;
        Dictionary d;
        d["id"] = to_godot(run.id);
        d["display_name"] = to_godot(run.displayName);
        d["available"] = run.requiresWorldEffect.empty() || player_->worldEffectActive(run.requiresWorldEffect);
        if(laboratory && run.id=="deep_forge")d["available"]=player_->resonanceState.campaignAward;
        d["done"] = player_->worldEffectActive(laboratory ? (run.id=="deep_forge" ? "lf5_pairing_victory" : "lf4_annex_victory") : run.completionUnlock);
        d["boss_id"] = to_godot(run.boss.id);
        d["boss_preview"] = to_godot(run.bossPreview);
        d["floor_count"] = run.floorCount;
        d["completion_text"] = to_godot(run.completionText);
        out.push_back(d);
    }
    return out;
}

Dictionary WroughtwildSim::trial_rules() const {
    Dictionary out;
    if (!require_loaded("trial_rules")) return out;
    for (const auto& [key, value] : tuning_->trial.engineRules) out[to_godot(key)] = value;
    out["content_revision"] = tuning_->trial.contentRevision;
    return out;
}

Dictionary WroughtwildSim::trial_layout() const {
    Dictionary out;
    if (!trial_ || trial_->runKind() == "legacy") return out;
    out["run_id"] = to_godot(trial_->runId());
    if (player_->campaignPolicy==wroughtwild::resonance::campaign) out["laboratory"] = true;
    if (player_->campaignPolicy==wroughtwild::resonance::campaign && trial_->runId()=="deep_forge") out["pairing_laboratory"] = true;
    out["run_kind"] = to_godot(trial_->runKind());
    out["display_name"] = to_godot(trial_->floor()->displayName);
    out["seed"] = static_cast<int64_t>(trial_->seed());
    out["tier"] = trial_->tier();
    out["material_target"] = to_godot(trial_->materialTarget());
    out["reward_multiplier"] = trial_->currentMods().rewardQuantityMultiplier;
    out["content_revision"] = tuning_->trial.contentRevision;
    out["floor_index"] = trial_->floorIndex();
    out["floor_count"] = trial_->floorCount();
    out["boss_id"] = to_godot(trial_->boss().id);
    out["completion_text"] = to_godot(trial_->floor()->completionText);
    Array stages;
    int index = 0;
    for (const auto& stage : trial_->stages()) {
        Dictionary s;
        s["index"] = index++;
        s["floor_index"] = stage.floorIndex;
        Array choices;
        for (const auto& room : stage.choices) {
            Dictionary c;
            c["id"] = to_godot(room.id);
            c["display_name"] = to_godot(room.displayName);
            c["module"] = to_godot(room.module);
            c["encounter"] = strings_to_packed(room.encounter);
            c["reward"] = to_godot(room.reward);
            choices.push_back(c);
        }
        s["choices"] = choices;
        stages.push_back(s);
    }
    out["stages"] = stages;
    Array conditions;
    for (const auto& id : trial_->conditions()) {
        const auto* def = tuning_->trial.findCondition(id);
        if (!def) continue;
        Dictionary c;
        c["id"] = to_godot(id);
        c["display_name"] = to_godot(def->displayName);
        c["description"] = to_godot(def->description);
        conditions.push_back(c);
    }
    out["conditions"] = conditions;
    Array route;
    for (int choice : trial_->route()) route.push_back(choice);
    out["route"] = route;
    return out;
}

Dictionary WroughtwildSim::trial_map_progress() const {
    Dictionary out;
    if (!require_loaded("trial_map_progress")) return out;
    out["available"] = player_->campaignPolicy!=wroughtwild::resonance::campaign && player_->worldEffectActive("forge_arc_complete");
    out["max_tier"] = trial_gate_.maxTier;
    return out;
}

Array WroughtwildSim::trial_map_offers(int tier) const {
    Array out;
    if (!require_loaded("trial_map_offers") || !player_->worldEffectActive("forge_arc_complete")) return out;
    if(player_->campaignPolicy==wroughtwild::resonance::campaign)return out;
    for (const auto& offer : wroughtwild::trial::mapOffers(*tuning_, trial_gate_, tier)) {
        Dictionary d;
        d["id"] = to_godot(offer.id);
        d["seed"] = static_cast<int64_t>(offer.seed);
        d["tier"] = offer.tier;
        d["material_target"] = to_godot(offer.materialTarget);
        auto component=tuning_->trial.mapCompletionComponents.find(offer.materialTarget);
        d["completion_components"]=component==tuning_->trial.mapCompletionComponents.end() ? Dictionary() : to_dictionary(component->second);
        d["reward_multiplier"] = offer.rewardMultiplier;
        auto haul = tuning_->trial.mapHaulUnits.find(offer.materialTarget);
        d["target_haul_units"] = haul == tuning_->trial.mapHaulUnits.end() ? 0 : static_cast<int>(std::floor(haul->second * offer.rewardMultiplier));
        d["boss_id"] = to_godot(offer.bossId);
        for (const auto& run : tuning_->trial.expeditions)
            if (run.boss.id == offer.bossId) d["boss_preview"] = to_godot(run.bossPreview);
        d["module_order"] = strings_to_packed(offer.moduleOrder);
        Array conditions;
        for (const auto& id : offer.conditions) {
            const auto* def = tuning_->trial.findCondition(id);
            Dictionary c;
            c["id"] = to_godot(id);
            c["display_name"] = to_godot(def->displayName);
            c["description"] = to_godot(def->description);
            conditions.push_back(c);
        }
        d["conditions"] = conditions;
        out.push_back(d);
    }
    return out;
}

bool WroughtwildSim::trial_start_map(int tier, int offer_index) {
    if (!require_loaded("trial_start_map") || trial_ || !player_->worldEffectActive("forge_arc_complete")) return false;
    if (player_->campaignPolicy == wroughtwild::resonance::campaign) return false;
    const auto offers = wroughtwild::trial::mapOffers(*tuning_, trial_gate_, tier);
    if (offer_index < 0 || offer_index >= static_cast<int>(offers.size())) return false;
    auto run = std::make_unique<wroughtwild::trial::TrialSession>(*tuning_, *player_, build_tags(), offers[static_cast<size_t>(offer_index)]);
    trial_ = std::move(run);
    trial_gate_.enteredMap();
    return true;
}

bool WroughtwildSim::trial_continue_floor() { return trial_ && trial_->continueFloor(); }
void WroughtwildSim::trial_skip_reward() { if (trial_) trial_->skipReward(); }
Dictionary WroughtwildSim::trial_claim_secret() {
    Dictionary out;
    if (!trial_) return out;
    const auto result = trial_->claimSecret();
    out["claimed"] = result.rewardType == "secret";
    out["materials"] = to_dictionary(result.materials);
    return out;
}

String WroughtwildSim::trial_checkpoint() const {
    if (!trial_ || !trial_->canSuspend()) return String();
    wroughtwild::save::SaveGame payload;
    payload.extra["trial_host_revision"] = "1";
    payload.extra["session"] = trial_->checkpoint();
    payload.extra["hit_stream"] = hits_ ? hits_->checkpoint() : wroughtwild::combat::HitStream(trial_->seed()).checkpoint();
    // Pair the suspended run with its exact permanent build/progression and
    // empty carried inventory. A checkpoint cannot be grafted onto another save.
    payload.extra["player_state"] = to_std(export_json());
    return to_godot(wroughtwild::save::toJson(payload));
}
bool WroughtwildSim::trial_checkpoint_valid(const String& text) const {
    if (!require_loaded("trial_checkpoint_valid")) return false;
    try {
        const auto payload = wroughtwild::save::fromJson(to_std(text));
        if (payload.extra.at("trial_host_revision") != "1") return false;
        const auto paired = wroughtwild::save::fromJson(payload.extra.at("player_state"));
        if (!paired.economy.inventory.empty()) return false;
        wroughtwild::economy::PlayerEconomy probe(*tuning_);
        probe.importState(paired.economy);
        auto session = wroughtwild::trial::TrialSession::restore(*tuning_, probe, payload.extra.at("session"));
        auto stream = wroughtwild::combat::HitStream::restore(payload.extra.at("hit_stream"));
        (void)session;
        (void)stream;
        return true;
    } catch (const std::exception&) { return false; }
}
bool WroughtwildSim::trial_checkpoint_matches(const String& text, const String& player_state) const {
    if (!trial_checkpoint_valid(text)) return false;
    try {
        const auto payload = wroughtwild::save::fromJson(to_std(text));
        const auto expected = wroughtwild::save::fromJson(payload.extra.at("player_state"));
        const auto supplied = wroughtwild::save::fromJson(to_std(player_state));
        return wroughtwild::save::toJson(expected) == wroughtwild::save::toJson(supplied);
    } catch (const std::exception&) { return false; }
}
bool WroughtwildSim::trial_restore_checkpoint(const String& text) {
    if (!require_loaded("trial_restore_checkpoint") || trial_) return false;
    if (!trial_checkpoint_matches(text, export_json())) return false;
    try {
        const auto payload = wroughtwild::save::fromJson(to_std(text));
        if (payload.extra.at("trial_host_revision") != "1") return false;
        auto session = wroughtwild::trial::TrialSession::restore(*tuning_, *player_, payload.extra.at("session"));
        auto stream = std::make_unique<wroughtwild::combat::HitStream>(wroughtwild::combat::HitStream::restore(payload.extra.at("hit_stream")));
        trial_ = std::move(session);
        hits_ = std::move(stream);
        return true;
    } catch (const std::exception& error) {
        last_error_ = to_godot(error.what());
        return false;
    }
}

String WroughtwildSim::world_profile() const { return to_godot(world_profile_); }

Dictionary WroughtwildSim::world_map(int seed) {
    Dictionary d;
    if (!require_loaded("world_map")) {
        return d;
    }
    const wroughtwild::worldgen::WorldMap* prepared = nullptr;
    try {
        prepared = &cached_world(static_cast<uint64_t>(seed));
    } catch (const std::exception& error) {
        // A failed composition must not throw across the engine boundary or
        // leave a fresh launch moving in an empty world. The chooser can keep
        // its pre-entry state and report this seed without overwriting a save.
        last_error_ = "World generation failed: " + to_godot(error.what());
        return d;
    }
    const auto& map = *prepared;
    player_->worldSeed=static_cast<uint64_t>(seed);
    const auto& table = world_table();

    d["seed"] = seed;
    d["profile_id"] = to_godot(map.profileId);
    if (player_->campaignPolicy == wroughtwild::resonance::campaign) d["resonance_signature"] = resonance_signature();
    d["width"] = map.width;
    d["height"] = map.height;
    d["depth"] = map.depth;
    d["cell_size"] = map.cellSize;

    PackedByteArray blocks;
    blocks.resize(static_cast<int64_t>(map.blocks.size()));
    memcpy(blocks.ptrw(), map.blocks.data(), map.blocks.size());
    d["blocks"] = blocks;

    PackedInt32Array heights;
    PackedInt32Array biome_indices;
    heights.resize(static_cast<int64_t>(map.cells.size()));
    biome_indices.resize(static_cast<int64_t>(map.cells.size()));
    for (size_t i = 0; i < map.cells.size(); ++i) {
        heights[static_cast<int64_t>(i)] = map.cells[i].height;
        biome_indices[static_cast<int64_t>(i)] = map.cells[i].biomeIndex;
    }
    d["heights"] = heights;
    d["biomes"] = biome_indices;

    Array biome_defs;
    for (const auto& biome : table.biomes) {
        Dictionary b;
        b["id"] = to_godot(biome.id);
        b["display_name"] = to_godot(biome.displayName);
        b["surface"] = to_godot(biome.surface);
        biome_defs.push_back(b);
    }
    d["biome_defs"] = biome_defs;

    Array nodes;
    for (const auto& node : map.nodes) {
        const auto typeIt = table.nodeTypes.find(node.type);
        if (typeIt == table.nodeTypes.end()) {
            continue;
        }
        Dictionary n;
        n["type"] = to_godot(node.type);
        n["resource_id"] = to_godot(node.resourceId);
        n["habitat_id"] = to_godot(node.habitatId);
        n["site_id"] = to_godot(node.siteId);
        n["region_id"] = to_godot(node.regionId);
        n["exceptional"] = node.exceptional;
        n["x"] = node.x;
        n["y"] = node.y;
        n["z"] = node.z;
        n["material_family"] = to_godot(typeIt->second.materialFamily);
        n["display_name"] = to_godot(typeIt->second.displayName);
        n["presentation_label"] = to_godot(typeIt->second.displayName);
        n["units"] = node.unitsOverride > 0 ? node.unitsOverride : typeIt->second.units;
        n["units_per_harvest"] = typeIt->second.unitsPerHarvest;
        n["visual"] = to_godot(typeIt->second.visual);
        n["era"] = typeIt->second.era;
        n["heat_to_work"] = typeIt->second.heatToWork;
        n["tool_item"] = to_godot(typeIt->second.toolItem);
        n["drive_presses"] = typeIt->second.drivePresses;
        PackedStringArray properties, stages;
        for (const auto& value : typeIt->second.properties) properties.push_back(to_godot(value));
        for (const auto& value : typeIt->second.harvestStages) stages.push_back(to_godot(value));
        n["properties"] = properties;
        n["harvest_stages"] = stages;
        n["use_preview"] = to_godot(typeIt->second.usePreview);
        nodes.push_back(n);
    }
    d["nodes"] = nodes;

    // The locks (Wave 8 slice 2): the landmarks worldgen placed, with their looks.
    Array landmarks;
    for (const auto& placed : map.landmarks) {
        Dictionary l;
        l["id"] = to_godot(placed.id);
        l["x"] = placed.x;
        l["z"] = placed.z;
        for (const auto& def : table.landmarks)
            if (def.id == placed.id) {
                l["display_name"] = to_godot(def.displayName);
                l["look"] = to_godot(def.look);
                l["biome"] = to_godot(def.biome);
            }
        landmarks.push_back(l);
    }
    d["landmarks"] = landmarks;

    Array habitats;
    for (const auto& placed : map.habitats) {
        Dictionary h;
        h["id"] = to_godot(placed.id);
        h["biome"] = to_godot(placed.biome);
        h["x"] = placed.x; h["y"] = placed.y; h["z"] = placed.z;
        h["radius_m"] = placed.radiusM;
        for (const auto& def : table.habitats)
            if (def.id == placed.id) h["display_name"] = to_godot(def.displayName);
        PackedVector3Array approach;
        for (const auto& point : placed.approach)
            approach.push_back(Vector3((point.x + 0.5) * map.cellSize,
                                       point.y * map.cellSize, (point.z + 0.5) * map.cellSize));
        h["approach"] = approach;
        habitats.push_back(h);
    }
    d["habitats"] = habitats;

    const auto route = [&map](const auto& points) {
        PackedVector3Array result;
        for (const auto& p : points)
            result.push_back(Vector3((p.x + 0.5) * map.cellSize, p.y * map.cellSize, (p.z + 0.5) * map.cellSize));
        return result;
    };
    d["starter_quiet_radius_m"] = map.starterQuietRadiusM;
    d["hostile_boundary_m"] = map.hostileBoundaryM;
    d["starter_first_siege_night"] = map.starterFirstSiegeNight;
    Array home_sites;
    for (const auto& placed : map.homeSites) {
        Dictionary h;
        h["id"] = to_godot(placed.id);
        h["x"] = placed.x; h["y"] = placed.y; h["z"] = placed.z;
        h["radius_m"] = placed.radiusM;
        h["approach"] = route(placed.approach);
        home_sites.push_back(h);
    }
    d["home_sites"] = home_sites;
    Array regions;
    for (const auto& placed : map.regions) {
        Dictionary r;
        r["id"] = to_godot(placed.id); r["biome"] = to_godot(placed.biome);
        r["x"] = placed.x; r["y"] = placed.y; r["z"] = placed.z;
        r["radius_m"] = placed.radiusM; r["transition_m"] = placed.transitionM;
        r["approach"] = route(placed.approach); r["cave_approach"] = route(placed.caveApproach);
        r["impact_id"] = to_godot(placed.impactId); r["augmentation_property"] = to_godot(placed.augmentationProperty);
        regions.push_back(r);
    }
    d["regions"] = regions;
    Array rare_sites;
    for (const auto& placed : map.rareSites) {
        Dictionary s;
        s["id"] = to_godot(placed.id); s["resource_type"] = to_godot(placed.resourceType);
        s["region_id"] = to_godot(placed.regionId);
        s["x"] = placed.x; s["y"] = placed.y; s["z"] = placed.z;
        s["radius_m"] = placed.radiusM; s["clue_radius_m"] = placed.clueRadiusM;
        s["exceptional"] = placed.exceptional; s["guarded"] = placed.guarded;
        s["approach"] = route(placed.approach); s["clue_points"] = route(placed.cluePoints);
        rare_sites.push_back(s);
    }
    d["rare_sites"] = rare_sites;

    Array pressure_pockets;
    for (const auto& source : map.pressurePockets) {
        Dictionary p;
        p["id"]=to_godot(source.id); p["x"]=source.x; p["y"]=source.y; p["z"]=source.z;
        p["radius_m"]=source.radiusM; p["ruin_id"]=to_godot(source.ruinId);
        p["impact_id"]=to_godot(source.impactId); p["leyline_id"]=to_godot(source.leylineId);
        p["linked_site_id"]=to_godot(source.linkedSiteId); p["origin"]=to_godot(source.origin);
        p["accidental"]=source.accidental; p["approach"]=route(source.approach);
        const auto& work=source.workPosition;
        p["work_position"]=Vector3((work.x+0.5)*map.cellSize,work.y*map.cellSize,(work.z+0.5)*map.cellSize);
        pressure_pockets.push_back(p);
    }
    d["pressure_pockets"]=pressure_pockets;

    Array impacts;
    for (const auto& placed : map.impacts) {
        Dictionary r;
        r["id"] = to_godot(placed.id); r["region_id"] = to_godot(placed.regionId); r["kind"] = to_godot(placed.kind);
        r["x"] = placed.x; r["y"] = placed.y; r["z"] = placed.z;
        r["radius_m"] = placed.radiusM; r["influence_radius_m"] = placed.influenceRadiusM;
        r["impact_direction"] = Vector3(placed.impactDirection.x, placed.impactDirection.y, placed.impactDirection.z);
        r["approach"] = route(placed.approach);
        impacts.push_back(r);
    }
    d["impacts"] = impacts;
    Array leylines;
    for (const auto& placed : map.leylines) {
        Dictionary r;
        r["id"] = to_godot(placed.id); r["region_id"] = to_godot(placed.regionId); r["property"] = to_godot(placed.property);
        r["from_impact_id"] = to_godot(placed.fromImpactId); r["to_impact_id"] = to_godot(placed.toImpactId);
        r["width_m"] = placed.widthM; r["influence_radius_m"] = placed.influenceRadiusM;
        r["points"] = route(placed.points);
        PackedByteArray exposure;
        for (const auto value : placed.exposure) exposure.push_back(value);
        r["exposure"] = exposure;
        leylines.push_back(r);
    }
    d["leylines"] = leylines;
    Array ruins;
    for (const auto& placed : map.ruins) {
        Dictionary r;
        r["id"] = to_godot(placed.id); r["region_id"] = to_godot(placed.regionId); r["kind"] = to_godot(placed.kind);
        r["x"] = placed.x; r["y"] = placed.y; r["z"] = placed.z;
        r["width_m"] = placed.widthM; r["depth_m"] = placed.depthM; r["rotation_quarters"] = placed.rotationQuarters;
        r["impact_id"] = to_godot(placed.impactId); r["leyline_id"] = to_godot(placed.leylineId);
        r["linked_site_id"] = to_godot(placed.linkedSiteId); r["augmentation"] = to_godot(placed.augmentation);
        r["damage_direction"] = Vector3(placed.damageDirection.x, placed.damageDirection.y, placed.damageDirection.z);
        r["entrance"] = Vector3((placed.entrance.x + 0.5) * map.cellSize, placed.entrance.y * map.cellSize, (placed.entrance.z + 0.5) * map.cellSize);
        r["approach"] = route(placed.approach); r["discovery_route"] = route(placed.discoveryRoute); r["foundation"] = route(placed.foundation);
        ruins.push_back(r);
    }
    d["ruins"] = ruins;
    PackedFloat32Array augmentation;
    augmentation.resize(static_cast<int64_t>(map.augmentationField.size()));
    for (size_t i = 0; i < map.augmentationField.size(); ++i) augmentation.set(static_cast<int64_t>(i), map.augmentationField[i]);
    d["augmentation_field"] = augmentation;

    Array frontier_hosts, laboratories, transforms;
    const auto position = [&](const wroughtwild::worldgen::SurfacePoint& p) {
        return Vector3((p.x+.5)*map.cellSize,p.y*map.cellSize,(p.z+.5)*map.cellSize);
    };
    for (const auto& host : map.frontierHosts) {
        Dictionary h; h["id"]=to_godot(host.id); h["source_id"]=to_godot(host.sourceId);
        h["enemy_id"]=to_godot(host.enemyId); h["influence"]=to_godot(host.influence);
        h["position"]=position(host.at); h["approach"]=route(host.approach);
        h["source_route"]=route(host.sourceRoute); h["habits"]=route(host.habits); frontier_hosts.push_back(h);
    }
    for (const auto& lab : map.laboratories) {
        Dictionary l; l["id"]=to_godot(lab.id); l["label"]=to_godot(lab.label); l["region_id"]=to_godot(lab.regionId);
        l["position"]=position(lab.at); l["approach"]=route(lab.approach);
        l["size"]=Vector3(lab.widthM,lab.heightM,lab.depthM); laboratories.push_back(l);
    }
    for (const auto& region : map.futureTransformations) {
        Dictionary r; r["id"]=to_godot(region.id); r["region_id"]=to_godot(region.regionId);
        r["position"]=position(region.at); r["radius_m"]=region.radiusM;
        r["active"]=player_->campaignPolicy==wroughtwild::resonance::campaign &&
            ((player_->resonanceState.phase=="applied" && region.id=="retained_fen") || (player_->secondResonance.phase=="applied" && region.id=="excited_uplands"));
        transforms.push_back(r);
    }
    d["frontier_hosts"]=frontier_hosts; d["laboratories"]=laboratories;
    d["future_transformations"]=transforms; d["laboratory_trail"]=route(map.laboratoryTrail);
    Dictionary frontier_rules;
    frontier_rules["habit_pause_seconds"]=tuning_->livingFrontier.habitPauseSeconds;
    frontier_rules["habitat_cue_spacing_m"]=tuning_->livingFrontier.habitatCueSpacingM;
    frontier_rules["trail_spacing_m"]=tuning_->livingFrontier.trailSpacingM;
    d["frontier_rules"]=frontier_rules;

    Array packs;
    for (const auto& pack : map.packs) {
        Dictionary p;
        PackedStringArray enemies;
        for (const auto& id : pack.enemies) {
            enemies.push_back(to_godot(id));
        }
        p["enemies"] = enemies;
        p["frontier_host_id"] = to_godot(pack.frontierHostId);
        p["x"] = pack.x;
        p["y"] = pack.y;
        p["z"] = pack.z;
        p["elite_member"] = pack.eliteMemberIndex;
        p["elite_modifier"] = to_godot(pack.eliteModifierId);
        p["grazer"] = pack.grazer;
        p["biome"] = to_godot(pack.biome);
        p["patrols"] = pack.patrols;
        p["route_x"] = pack.routeX;
        p["route_z"] = pack.routeZ;
        p["has_foreign"] = pack.hasForeign;
        p["foreign_x"] = pack.foreignX;
        p["foreign_z"] = pack.foreignZ;
        p["foreign_biome"] = to_godot(pack.foreignBiome);
        packs.push_back(p);
    }
    d["packs"] = packs;

    d["spawn_x"] = map.spawnX;
    d["spawn_z"] = map.spawnZ;
    d["gate_x"] = map.gateX;
    d["gate_z"] = map.gateZ;
    return d;
}

namespace {

// One chunk's render/collision geometry. `removed` are engine edits (dug
// blocks, as flat block-field indices) treated as air, so a rebuilt chunk
// reflects the world the player has actually carved.
Dictionary build_world_chunk(const wroughtwild::tuning::WorldgenTable& table,
                             const wroughtwild::worldgen::WorldMap& map, int cx, int cz,
                             int chunk_cells, const std::set<int64_t>& removed, bool faceted = false,
                             const Dictionary& palette = Dictionary()) {
    const double cs = map.cellSize;
    using wroughtwild::worldgen::kAir;
    using wroughtwild::worldgen::kBedrock;
    using wroughtwild::worldgen::kDirt;
    using wroughtwild::worldgen::kStone;
    using wroughtwild::worldgen::kSurface;

    auto eff = [&](int x, int y, int z) -> uint8_t {
        if (x < 0 || z < 0 || x >= map.width || z >= map.height || y < 0 || y >= map.depth) {
            return kAir;
        }
        int64_t idx = (static_cast<int64_t>(z) * map.width + x) * map.depth + y;
        if (!removed.empty() && removed.count(idx)) {
            return kAir;
        }
        return map.blocks[static_cast<size_t>(idx)];
    };

    // Codex faceted surface: average solid/air edge crossings in the eight
    // voxels surrounding a lattice vertex. Neighbour chunks read identical
    // samples, so their vertices agree. Face centres remain at their voxel
    // planes, preserving the ground at resource anchors. Both rendering and
    // collision use these triangles; each triangle retains its source cell.
    std::map<int64_t, Vector3> surfaceCache;
    std::map<int64_t, Vector3> normalCache;
    // Material-independent occupancy gradient. The same eight samples are
    // read on either side of a chunk/material boundary, including after digs.
    auto surfaceNormal = [&](int x, int y, int z) {
        const int64_t key = (int64_t(z) * (map.width + 1) + x) * (map.depth + 1) + y;
        auto found = normalCache.find(key);
        if (found != normalCache.end()) return found->second;
        Vector3 n;
        auto solid = [&](int a, int b, int c) { return eff(a,b,c) != kAir ? 1.0f : 0.0f; };
        for (int a=-1; a<=0; ++a) for (int b=-1; b<=0; ++b) {
            n.x += solid(x-1,y+a,z+b) - solid(x,y+a,z+b);
            n.y += solid(x+a,y-1,z+b) - solid(x+a,y,z+b);
            n.z += solid(x+a,y+b,z-1) - solid(x+a,y+b,z);
        }
        n.normalize();
        normalCache[key] = n;
        return n;
    };
    auto surfaceVertex = [&](int x, int y, int z) {
        const int64_t key = (int64_t(z) * (map.width + 1) + x) * (map.depth + 1) + y;
        auto found = surfaceCache.find(key);
        if (found != surfaceCache.end()) return found->second;
        Vector3 sum;
        int count = 0;
        for (int i = 0; i < 8; ++i) {
            const int a[3] = {x - 1 + (i & 1), y - 1 + ((i >> 1) & 1), z - 1 + ((i >> 2) & 1)};
            for (int axis = 0; axis < 3; ++axis) {
                if (i & (1 << axis)) continue;
                int b[3] = {a[0],a[1],a[2]}; ++b[axis];
                if ((eff(a[0],a[1],a[2]) == kAir) == (eff(b[0],b[1],b[2]) == kAir)) continue;
                sum += Vector3((a[0]+b[0]+1)*0.5, (a[1]+b[1]+1)*0.5, (a[2]+b[2]+1)*0.5);
                ++count;
            }
        }
        const Vector3 result = (count ? sum / count : Vector3(x,y,z)) * cs;
        surfaceCache[key] = result;
        return result;
    };

    // The six neighbour directions and, for each, the face's four corners
    // (two triangles) on the unit block [0,1]^3. The engine's collision
    // shape enables backface_collision, so winding is not load-bearing.
    struct Dir { int dx, dy, dz; Vector3 corners[4]; };
    static const Dir kDirs[6] = {
        {1, 0, 0, {{1, 0, 1}, {1, 1, 1}, {1, 1, 0}, {1, 0, 0}}},
        {-1, 0, 0, {{0, 0, 0}, {0, 1, 0}, {0, 1, 1}, {0, 0, 1}}},
        {0, 1, 0, {{0, 1, 1}, {1, 1, 1}, {1, 1, 0}, {0, 1, 0}}},
        {0, -1, 0, {{0, 0, 0}, {1, 0, 0}, {1, 0, 1}, {0, 0, 1}}},
        {0, 0, 1, {{0, 0, 1}, {0, 1, 1}, {1, 1, 1}, {1, 0, 1}}},
        {0, 0, -1, {{1, 0, 0}, {1, 1, 0}, {0, 1, 0}, {0, 0, 0}}},
    };

    // Presentation palette is supplied by the engine resource, never by sim
    // tuning. Shared lattice samples keep colours identical across material
    // and chunk boundaries. Only exposed solids influence a surface join.
    std::map<String, Color> paletteColours;
    for (int i=0; i<palette.size(); ++i) {
        const String kind = palette.keys()[i];
        Color colour = Color(palette[kind]).srgb_to_linear();
        colour.a = (kind == "rock" || kind == "stone" || kind == "bedrock") ? 1.0f : 0.0f;
        paletteColours[kind] = colour;
    }
    auto materialColour = [&](int x, int y, int z) {
        const auto id = eff(x,y,z);
        String kind = id == kDirt ? "dirt" : id == kBedrock ? "bedrock" : "stone";
        if (id == kSurface) kind = to_godot(table.biomes[map.at(x,z).biomeIndex].surface);
        auto found = paletteColours.find(kind);
        return found == paletteColours.end() ? Color(0.2,0.2,0.2,1.0) : found->second;
    };
    std::map<int64_t, Color> colourCache;
    auto surfaceColour = [&](int x, int y, int z) {
        const int64_t key = (int64_t(z)*(map.width+1)+x)*(map.depth+1)+y;
        auto found = colourCache.find(key);
        if (found != colourCache.end()) return found->second;
        Color sum(0,0,0,0);
        int count = 0;
        for (int dz=-1; dz<=0; ++dz) for (int dy=-1; dy<=0; ++dy) for (int dx=-1; dx<=0; ++dx) {
            const int a=x+dx, b=y+dy, c=z+dz;
            if (eff(a,b,c)==kAir) continue;
            // Only faces meeting this corner count. The stencil stays within
            // its eight cells, matching the existing dig invalidation halo.
            const bool exposed = eff(x-1-dx,b,c)==kAir || eff(a,y-1-dy,c)==kAir || eff(a,b,z-1-dz)==kAir;
            if (!exposed) continue;
            sum += materialColour(a,b,c);
            ++count;
        }
        const Color result = count ? sum / float(count) : Color(0.2,0.2,0.2,1.0);
        colourCache[key] = result;
        return result;
    };

    Dictionary chunk;
    chunk["x"] = cx;
    chunk["z"] = cz;
    // Accumulate locally: Packed arrays behind a Variant are copy-on-write,
    // so growing them in place through the Dictionary would copy the whole
    // array per block.
    std::map<String, PackedVector3Array> bucket;
    std::map<String, PackedVector3Array> surfaceBucket, normalBucket, softNormalBucket;
    std::map<String, PackedColorArray> colourBucket;
    PackedVector3Array sourceCells;
    PackedVector3Array faces;
    for (int z = cz; z < std::min(cz + chunk_cells, map.height); ++z) {
        for (int x = cx; x < std::min(cx + chunk_cells, map.width); ++x) {
            for (int y = 0; y < map.depth; ++y) {
                uint8_t id = eff(x, y, z);
                if (id == kAir) {
                    continue;
                }
                bool visible = false;
                String kind;
                switch (id) {
                    case kSurface: kind = to_godot(table.biomes[map.at(x,z).biomeIndex].surface); break;
                    case kDirt: kind = "dirt"; break;
                    case kBedrock: kind = "bedrock"; break;
                    default: kind = "stone"; break;
                }
                for (const auto& dir : kDirs) {
                    if (eff(x + dir.dx, y + dir.dy, z + dir.dz) != kAir) {
                        continue;
                    }
                    visible = true;
                    const Vector3 base(x * cs, y * cs, z * cs);
                    if (faceted) {
                        const Vector3 centre = (Vector3(x+0.5,y+0.5,z+0.5) + Vector3(dir.dx,dir.dy,dir.dz)*0.5) * cs;
                        Vector3 corners[4];
                        Vector3 cornerNormals[4], centreNormal;
                        Color cornerColours[4], centreColour(0,0,0,0);
                        for (int i=0; i<4; ++i) corners[i] = surfaceVertex(x+int(dir.corners[i].x), y+int(dir.corners[i].y), z+int(dir.corners[i].z));
                        for (int i=0; i<4; ++i) {
                            cornerNormals[i] = surfaceNormal(x+int(dir.corners[i].x), y+int(dir.corners[i].y), z+int(dir.corners[i].z));
                            centreNormal += cornerNormals[i];
                            if (!palette.is_empty()) {
                                cornerColours[i] = surfaceColour(x+int(dir.corners[i].x),y+int(dir.corners[i].y),z+int(dir.corners[i].z));
                                centreColour += cornerColours[i] * 0.25f;
                            }
                        }
                        centreNormal.normalize();
                        if (!palette.is_empty()) centreColour = centreColour.lerp(materialColour(x,y,z),0.55f);
                        for (int i=0; i<4; ++i) {
                            Vector3 a=corners[i], b=corners[(i+1)%4];
                            Vector3 na=cornerNormals[i], nb=cornerNormals[(i+1)%4];
                            Color ca=cornerColours[i], cb=cornerColours[(i+1)%4];
                            Vector3 normal = (b-centre).cross(a-centre);
                            if (normal.length_squared() < 1e-12) continue;
                            if (normal.dot(Vector3(dir.dx,dir.dy,dir.dz)) < 0) { std::swap(a,b); std::swap(na,nb); std::swap(ca,cb); normal=-normal; }
                            normal.normalize();
                            for (const auto& vertex : {centre,a,b}) {
                                faces.push_back(vertex);
                                surfaceBucket[kind].push_back(vertex);
                                normalBucket[kind].push_back(normal);
                            }
                            for (const auto& soft : {centreNormal,na,nb})
                                softNormalBucket[kind].push_back(soft.length_squared() > 0.01 ? soft : normal);
                            sourceCells.push_back(Vector3(x,y,z));
                            if (!palette.is_empty())
                                for (const auto& colour : {centreColour,ca,cb}) colourBucket[kind].push_back(colour);
                        }
                        continue;
                    }
                    faces.push_back(base + dir.corners[0] * cs);
                    faces.push_back(base + dir.corners[1] * cs);
                    faces.push_back(base + dir.corners[2] * cs);
                    faces.push_back(base + dir.corners[0] * cs);
                    faces.push_back(base + dir.corners[2] * cs);
                    faces.push_back(base + dir.corners[3] * cs);
                }
                if (!visible) {
                    continue;
                }
                bucket[kind].push_back(Vector3((x + 0.5) * cs, (y + 0.5) * cs, (z + 0.5) * cs));
            }
        }
    }
    Dictionary kinds; // kind string -> PackedVector3Array of block centres
    for (const auto& [kind, centres] : bucket) {
        kinds[kind] = centres;
    }
    chunk["kinds"] = kinds;
    chunk["faces"] = faces;
    if (faceted) {
        Dictionary surfaces, normals, softNormals;
        for (const auto& entry : surfaceBucket) surfaces[entry.first] = entry.second;
        for (const auto& entry : normalBucket) normals[entry.first] = entry.second;
        for (const auto& entry : softNormalBucket) softNormals[entry.first] = entry.second;
        chunk["surfaces"] = surfaces;
        chunk["normals"] = normals;
        chunk["soft_normals"] = softNormals;
        Dictionary colours;
        for (const auto& entry : colourBucket) colours[entry.first] = entry.second;
        chunk["blend_colours"] = colours;
        chunk["source_cells"] = sourceCells;
    }
    return chunk;
}

std::set<int64_t> removed_set(const wroughtwild::worldgen::WorldMap& map,
                              const PackedInt32Array& removed_blocks) {
    std::set<int64_t> removed;
    for (int64_t i = 0; i + 2 < removed_blocks.size(); i += 3) {
        int x = removed_blocks[i], y = removed_blocks[i + 1], z = removed_blocks[i + 2];
        if (x < 0 || z < 0 || x >= map.width || z >= map.height || y < 0 || y >= map.depth) {
            continue;
        }
        removed.insert((static_cast<int64_t>(z) * map.width + x) * map.depth + y);
    }
    return removed;
}

} // namespace

Array WroughtwildSim::world_mesh(int seed, int chunk_cells, bool faceted, const Dictionary& palette) {
    Array chunks;
    if (!require_loaded("world_mesh") || chunk_cells < 1) {
        return chunks;
    }
    const auto& map = cached_world(static_cast<uint64_t>(seed));
    const std::set<int64_t> none;
    for (int cz = 0; cz < map.height; cz += chunk_cells) {
        for (int cx = 0; cx < map.width; cx += chunk_cells) {
            chunks.push_back(build_world_chunk(world_table(), map, cx, cz, chunk_cells, none, faceted, palette));
        }
    }
    return chunks;
}

Dictionary WroughtwildSim::world_mesh_chunk(int seed, int chunk_cells, int chunk_x, int chunk_z,
                                            const PackedInt32Array& removed_blocks, bool faceted, const Dictionary& palette) {
    Dictionary d;
    if (!require_loaded("world_mesh_chunk") || chunk_cells < 1) {
        return d;
    }
    const auto& map = cached_world(static_cast<uint64_t>(seed));
    return build_world_chunk(world_table(), map, chunk_x, chunk_z, chunk_cells,
                             removed_set(map, removed_blocks), faceted, palette);
}

Dictionary WroughtwildSim::block_rules() const {
    Dictionary d;
    if (!require_loaded("block_rules")) {
        return d;
    }
    for (const auto& [kind, rule] : world_table().blockRules) {
        Dictionary r;
        r["breakable"] = rule.breakable;
        r["dig_seconds"] = rule.digSeconds;
        r["yields"] = to_dictionary(rule.yields);
        r["by_hand"] = rule.byHand;
        r["heat_to_crack"] = rule.heatToCrack;
        d[to_godot(kind)] = r;
    }
    return d;
}

// Fire-setting (D-020): fuels by building family, reach, soak, how long
// rock stays hot, and the quench radius. The engine burns and glows; the
// numbers are the sim's.
Dictionary WroughtwildSim::fire_setting() const {
    Dictionary d;
    if (!require_loaded("fire_setting")) {
        return d;
    }
    const auto& fs = tuning_->worldgen.fireSetting;
    Dictionary fuels;
    for (const auto& [family, fuel] : fs.fuels) {
        Dictionary f;
        f["heat"] = fuel.heat;
        f["burn_seconds"] = fuel.burnSeconds;
        fuels[to_godot(family)] = f;
    }
    d["fuels"] = fuels;
    d["reach_cells"] = fs.reachCells;
    d["soak_seconds"] = fs.soakSeconds;
    d["hot_seconds"] = fs.hotSeconds;
    d["quench_radius_m"] = fs.quenchRadiusM;
    return d;
}

// --- the building lattice (Wave 4, D-017) --------------------------------------

namespace {

using wroughtwild::lattice::Element;
using wroughtwild::lattice::ElementKind;

const char* kind_name(ElementKind kind) {
    switch (kind) {
    case ElementKind::Volume: return "volume";
    case ElementKind::Face: return "face";
    case ElementKind::Edge: return "edge";
    }
    return "volume";
}

// Reads an element Dictionary; false when it is not one.
bool element_from(const Dictionary& d, Element& out) {
    if (!d.has("kind") || !d.has("cell")) {
        return false;
    }
    const String kind = d["kind"];
    if (kind == "volume") out.kind = ElementKind::Volume;
    else if (kind == "face") out.kind = ElementKind::Face;
    else if (kind == "edge") out.kind = ElementKind::Edge;
    else return false;
    out.axis = out.kind == ElementKind::Volume ? 0 : static_cast<int>(d.get("axis", 0));
    if (out.axis < 0 || out.axis > 2) {
        return false;
    }
    const Vector3i cell = d["cell"];
    out.cell = wroughtwild::lattice::Cell{cell.x, cell.y, cell.z};
    return true;
}

Dictionary element_to(const Element& e) {
    Dictionary d;
    d["kind"] = kind_name(e.kind);
    d["axis"] = e.axis;
    d["cell"] = Vector3i(e.cell.x, e.cell.y, e.cell.z);
    return d;
}

Vector3 to_vector(const wroughtwild::lattice::Vec3& v) {
    return Vector3(static_cast<real_t>(v.x), static_cast<real_t>(v.y), static_cast<real_t>(v.z));
}

Dictionary piece_to(const wroughtwild::lattice::Piece& piece) {
    Dictionary d = element_to(piece.anchor);
    d["shape"] = to_godot(piece.shapeId);
    d["family"] = to_godot(piece.family);
    d["rotation_step"] = piece.rotationStep;
    d["slot"] = wroughtwild::lattice::slotName(piece.slot);
    return d;
}

// How a shape sits on the registry: its own grid, its span in registry
// cells per piece cell, and how many piece cells tall it is.
struct ShapeLattice {
    const wroughtwild::tuning::ShapeDef* shape = nullptr;
    wroughtwild::lattice::Slot slot = wroughtwild::lattice::Slot::Block;
    double pieceGrid = 1.0;
    double registryGrid = 1.0;
    int span = 1;
    int tall = 1;
    int longCells = 1;
};

bool shape_lattice(const wroughtwild::tuning::Tuning& tuning, const String& shape_id, ShapeLattice& out) {
    out.shape = tuning.construction.findShape(to_std(shape_id));
    if (out.shape == nullptr) {
        return false;
    }
    const int divisions = std::max(1, tuning.construction.latticeDivisions);
    out.slot = wroughtwild::lattice::slotFromName(out.shape->element);
    out.registryGrid = tuning.construction.gridSizeMetres / divisions;
    out.span = out.shape->fine ? 1 : divisions;
    out.pieceGrid = out.registryGrid * out.span;
    out.tall = std::max(1, out.shape->cellsTall);
    out.longCells = std::max(1, out.shape->cellsLong);
    return true;
}

Dictionary pose_of(const ShapeLattice& sl, const Element& anchor) {
    Dictionary d;
    d["centre"] = to_vector(wroughtwild::lattice::footprintCentre(anchor, sl.span, sl.tall, sl.registryGrid, sl.longCells));
    d["yaw_turns"] = wroughtwild::lattice::yawTurns(anchor);
    return d;
}

} // namespace

double WroughtwildSim::lattice_registry_grid() const {
    if (!require_loaded("lattice_registry_grid")) {
        return 1.0;
    }
    return tuning_->construction.gridSizeMetres / std::max(1, tuning_->construction.latticeDivisions);
}

Array WroughtwildSim::lattice_candidates(const String& shape_id, const Vector3& point, const Vector3& normal,
                                         bool fine_grid) const {
    Array out;
    ShapeLattice sl;
    if (!require_loaded("lattice_candidates") || !shape_lattice(*tuning_, shape_id, sl)) {
        return out;
    }
    // On the fine grid the anchor is any registry element; the footprint
    // still spans the piece's full size from it.
    const int step = fine_grid ? 1 : sl.span;
    const double grid = fine_grid ? sl.registryGrid : sl.pieceGrid;
    const auto found = wroughtwild::lattice::candidates(sl.slot, {point.x, point.y, point.z},
                                                        {normal.x, normal.y, normal.z}, grid);
    for (const auto& coarse : found) {
        const Element anchor = wroughtwild::lattice::scaled(coarse, step);
        Dictionary d = element_to(anchor);
        d.merge(pose_of(sl, anchor));
        out.push_back(d);
    }
    return out;
}

Dictionary WroughtwildSim::lattice_pose(const String& shape_id, const Dictionary& element) const {
    ShapeLattice sl;
    Element e;
    if (!require_loaded("lattice_pose") || !shape_lattice(*tuning_, shape_id, sl) || !element_from(element, e)) {
        return Dictionary();
    }
    return pose_of(sl, e);
}

bool WroughtwildSim::shape_accepts(const String& shape_id, const Dictionary& element) const {
    ShapeLattice sl;
    Element e;
    return require_loaded("shape_accepts") && shape_lattice(*tuning_, shape_id, sl) && element_from(element, e) &&
           wroughtwild::lattice::slotAccepts(sl.slot, e);
}

Array WroughtwildSim::lattice_footprint(const String& shape_id, const Dictionary& element) const {
    Array out;
    ShapeLattice sl;
    Element e;
    if (!require_loaded("lattice_footprint") || !shape_lattice(*tuning_, shape_id, sl) ||
        element.get("cell", Variant()).get_type() != Variant::VECTOR3I || !element_from(element, e) ||
        !wroughtwild::lattice::slotAccepts(sl.slot, e)) {
        return out;
    }
    for (const auto& covered : wroughtwild::lattice::footprint(e, sl.span, sl.tall, sl.longCells)) {
        out.push_back(element_to(covered));
    }
    return out;
}

bool WroughtwildSim::structure_touches(const String& shape_id, const Dictionary& element) const {
    ShapeLattice sl;
    Element e;
    if (!require_loaded("structure_touches") || !shape_lattice(*tuning_, shape_id, sl) || !element_from(element, e)) {
        return false;
    }
    return structure_.near(wroughtwild::lattice::footprint(e, sl.span, sl.tall, sl.longCells), 0);
}

bool WroughtwildSim::structure_near_point(const Vector3& point) const {
    if (!require_loaded("structure_near_point")) {
        return false;
    }
    const double registry = lattice_registry_grid();
    Element cell;
    cell.kind = ElementKind::Volume;
    cell.cell = wroughtwild::lattice::Cell{static_cast<int>(std::floor(point.x / registry)),
                                           static_cast<int>(std::floor(point.y / registry)),
                                           static_cast<int>(std::floor(point.z / registry))};
    return structure_.near({cell}, 1);
}

int WroughtwildSim::structure_piece_count() const {
    return static_cast<int>(structure_.pieces().size());
}

bool WroughtwildSim::structure_occupied(const Dictionary& element) const {
    Element e;
    return require_loaded("structure_occupied") && element_from(element, e) && structure_.occupied(e);
}

bool WroughtwildSim::structure_free_for(const String& shape_id, const Dictionary& element) const {
    ShapeLattice sl;
    Element e;
    if (!require_loaded("structure_free_for") || !shape_lattice(*tuning_, shape_id, sl) || !element_from(element, e)) {
        return false;
    }
    for (const auto& covered : wroughtwild::lattice::withInterior(
             wroughtwild::lattice::footprint(e, sl.span, sl.tall, sl.longCells))) {
        if (structure_.occupied(covered)) {
            return false;
        }
    }
    return true;
}

Dictionary WroughtwildSim::structure_piece(const Dictionary& element) const {
    Element e;
    if (!require_loaded("structure_piece") || !element_from(element, e)) {
        return Dictionary();
    }
    const auto* piece = structure_.at(e);
    return piece == nullptr ? Dictionary() : piece_to(*piece);
}

bool WroughtwildSim::structure_place(const Dictionary& element, const String& shape_id, const String& family,
                                     int rotation_step) {
    ShapeLattice sl;
    Element e;
    if (!require_loaded("structure_place") || !shape_lattice(*tuning_, shape_id, sl) || !element_from(element, e)) {
        return false;
    }
    if (!wroughtwild::lattice::slotAccepts(sl.slot, e)) {
        return false;
    }
    wroughtwild::lattice::Piece piece;
    piece.anchor = e;
    piece.slot = sl.slot;
    piece.footprint = wroughtwild::lattice::withInterior(
        wroughtwild::lattice::footprint(e, sl.span, sl.tall, sl.longCells));
    piece.shapeId = to_std(shape_id);
    piece.family = to_std(family);
    piece.rotationStep = ((rotation_step % 4) + 4) % 4;
    piece.cornerSpan = sl.shape->form == "corner" ? sl.span : 0;
    return structure_.place(piece);
}

bool WroughtwildSim::structure_remove(const Dictionary& element) {
    Element e;
    return require_loaded("structure_remove") && element_from(element, e) && structure_.remove(e);
}

void WroughtwildSim::structure_clear() { structure_.clear(); }

Array WroughtwildSim::structure_pieces() const {
    Array out;
    for (const auto& [anchor, piece] : structure_.pieces()) {
        out.push_back(piece_to(piece));
    }
    return out;
}

Array WroughtwildSim::structure_trim_edges() const {
    Array out;
    if (!require_loaded("structure_trim_edges")) {
        return out;
    }
    const double grid = lattice_registry_grid();
    for (const auto& e : structure_.trimEdges()) {
        Dictionary d = element_to(e);
        d["centre"] = to_vector(wroughtwild::lattice::centre(e, grid));
        const auto walls = structure_.wallsAt(e);
        d["family"] = walls.empty() ? String() : to_godot(walls.front()->family);
        out.push_back(d);
    }
    return out;
}

Dictionary WroughtwildSim::shelter() const {
    Dictionary d;
    if (!require_loaded("shelter")) {
        return d;
    }
    d["regen_life_per_round"] = tuning_->world.shelter.regenLifePerRound;
    d["settle_rounds"] = tuning_->world.shelter.settleRounds;
    d["max_room_cells"] = tuning_->world.shelter.maxRoomCells;
    return d;
}

void WroughtwildSim::advance_time(double seconds) {
    if (require_loaded("advance_time")) player_->advanceTime(seconds);
}

void WroughtwildSim::set_day_clock(double seconds) {
    if (require_loaded("set_day_clock")) player_->setDayClock(seconds);
}

Dictionary WroughtwildSim::day() const {
    Dictionary d;
    if (!require_loaded("day")) {
        return d;
    }
    const auto info = wroughtwild::daycycle::info(tuning_->world.day, player_->dayClock());
    d["index"] = info.index;
    d["fraction"] = info.fraction;
    d["phase"] = String(info.phase.c_str());
    d["daylight"] = info.daylight;
    d["night"] = info.night;
    d["seconds_to_night"] = info.secondsToNight;
    d["seconds_to_dawn"] = info.secondsToDawn;
    d["clock_seconds"] = player_->dayClock();
    return d;
}

Dictionary WroughtwildSim::day_rules() const {
    Dictionary d;
    if (!require_loaded("day_rules")) {
        return d;
    }
    const auto& r = tuning_->world.day;
    const double round = tuning_->realtime.roundSeconds > 0.01 ? tuning_->realtime.roundSeconds : 0.01;
    d["length_seconds"] = r.lengthSeconds;
    d["night_light"] = r.nightLight;
    d["dawn_end"] = r.dawnEnd;
    d["dusk_end"] = r.duskEnd;
    d["exposure_life_per_second"] = r.exposureLifePerRound / round;
    d["exposure_floor_fraction"] = r.exposureFloorFraction;
    d["night_aggro_multiplier"] = r.nightAggroMultiplier;
    d["night_sleep_range_multiplier"] = r.nightSleepRangeMultiplier;
    d["shelter_night_regen_multiplier"] = r.shelterNightRegenMultiplier;
    return d;
}

Dictionary WroughtwildSim::hauling_rules() const {
    Dictionary d;
    if (!require_loaded("hauling_rules")) {
        return d;
    }
    d["carry_cap_default"] = tuning_->world.hauling.carryCapDefault;
    d["chest_units"] = tuning_->world.hauling.chestUnits;
    return d;
}

Dictionary WroughtwildSim::train_rules() const {
    Dictionary d;
    if (!require_loaded("train_rules")) {
        return d;
    }
    d["window_seconds"] = tuning_->realtime.hordeTrainWindowSeconds;
    d["bonus_per_hit"] = tuning_->realtime.hordeTrainBonusPerHit;
    d["max_bonus"] = tuning_->realtime.hordeTrainMaxBonus;
    return d;
}

double WroughtwildSim::train_multiplier(int earlier_hits) const {
    return require_loaded("train_multiplier") ? wroughtwild::combat::trainMultiplier(earlier_hits, tuning_->realtime) : 1.0;
}

double WroughtwildSim::armour_reduction_cap() const {
    return require_loaded("armour_reduction_cap") ? player_->era().armourReductionCap : 1.0;
}

Dictionary WroughtwildSim::noise_rules() const {
    Dictionary d;
    if (!require_loaded("noise_rules")) {
        return d;
    }
    Dictionary radii;
    for (const auto& [kind, radius] : tuning_->realtime.noiseRadiusM) radii[String(kind.c_str())] = radius;
    d["radius_m"] = radii;
    d["muffle"] = tuning_->realtime.noiseMuffle;
    d["horn_cooldown_seconds"] = tuning_->realtime.noiseHornCooldownSeconds;
    return d;
}

bool WroughtwildSim::set_curio(const String& landmark_id) {
    return require_loaded("set_curio") && player_->setCurio(to_std(landmark_id));
}

Dictionary WroughtwildSim::landmark_wants(const String& landmark_id) const {
    Dictionary d;
    if (!require_loaded("landmark_wants")) {
        return d;
    }
    if(player_->landmarkWants(to_std(landmark_id)).empty())return d;
    const auto* curio = tuning_->trial.curioForLandmark(to_std(landmark_id));
    if (curio == nullptr) {
        return d;
    }
    d["curio"] = String(curio->id.c_str());
    d["display_name"] = String(curio->displayName.c_str());
    d["held"] = player_->curioHeld(curio->id);
    if(player_->campaignPolicy==wroughtwild::resonance::campaign)d["remembrance"]=true;
    return d;
}

PackedStringArray WroughtwildSim::curio_hints() const {
    PackedStringArray out;
    if (!require_loaded("curio_hints")) {
        return out;
    }
    for (const auto& hint : player_->curioHints()) out.push_back(String(hint.c_str()));
    return out;
}

double WroughtwildSim::threat_score(const String& enemy_id) const {
    if (!require_loaded("threat_score")) {
        return 0.0;
    }
    const auto* enemy = tuning_->world.findEnemy(to_std(enemy_id));
    const auto* behaviour = enemy ? tuning_->realtime.findBehaviour(enemy->behaviour) : nullptr;
    return enemy && behaviour ? wroughtwild::combat::threatScore(*enemy, *behaviour) : 0.0;
}

Dictionary WroughtwildSim::siege_rules() const {
    Dictionary d;
    if (!require_loaded("siege_rules")) {
        return d;
    }
    const auto& s = tuning_->world.siege;
    d["first_night"] = s.firstNight;
    d["chance_per_night"] = s.chancePerNight;
    d["arrive_seconds_into_night"] = s.arriveSecondsIntoNight;
    d["spawn_radius_m"] = s.spawnRadiusM;
    d["home_radius_m"] = s.homeRadiusM;
    d["timber_break_hits"] = s.timberBreakHits;
    return d;
}

bool WroughtwildSim::siege_tonight(int seed, int day_index) const {
    return require_loaded("siege_tonight") &&
           wroughtwild::daycycle::siegeTonight(tuning_->world.siege, static_cast<uint64_t>(seed), day_index);
}

PackedStringArray WroughtwildSim::siege_pack() const {
    PackedStringArray out;
    if (!require_loaded("siege_pack")) {
        return out;
    }
    for (const auto& id : wroughtwild::daycycle::siegePack(tuning_->world.siege, player_->currentEra())) out.push_back(String(id.c_str()));
    return out;
}

int WroughtwildSim::carry_cap(const String& family) const {
    return require_loaded("carry_cap") ? player_->carryCap(to_std(family)) : 0;
}

int WroughtwildSim::carry_room(const String& family) const {
    return require_loaded("carry_room") ? player_->carryRoom(to_std(family)) : 0;
}

int WroughtwildSim::haul(const String& family, int amount) {
    return require_loaded("haul") ? player_->haul(to_std(family), amount) : 0;
}

int WroughtwildSim::store_deposit(const String& key, const String& family, int amount) {
    return require_loaded("store_deposit") ? player_->storeDeposit(to_std(key), to_std(family), amount) : 0;
}

int WroughtwildSim::store_withdraw(const String& key, const String& family, int amount) {
    return require_loaded("store_withdraw") ? player_->storeWithdraw(to_std(key), to_std(family), amount) : 0;
}

Dictionary WroughtwildSim::store_contents(const String& key) const {
    Dictionary d;
    if (!require_loaded("store_contents")) {
        return d;
    }
    for (const auto& [family, count] : player_->storeContents(to_std(key))) d[String(family.c_str())] = count;
    return d;
}

int WroughtwildSim::store_units(const String& key) const {
    return require_loaded("store_units") ? player_->storeUnits(to_std(key)) : 0;
}

int WroughtwildSim::store_room(const String& key) const {
    return require_loaded("store_room") ? player_->storeRoom(to_std(key)) : 0;
}

Dictionary WroughtwildSim::store_remove(const String& key) {
    Dictionary d;
    if (!require_loaded("store_remove")) {
        return d;
    }
    for (const auto& [family, count] : player_->storeRemove(to_std(key))) d[String(family.c_str())] = count;
    return d;
}

Dictionary WroughtwildSim::structure_enclosure(int seed, const PackedInt32Array& removed_blocks, const Vector3& at) {
    Dictionary d;
    d["enclosed"] = false;
    d["cells"] = 0;
    if (!require_loaded("structure_enclosure")) {
        return d;
    }
    const int div = std::max(1, tuning_->construction.latticeDivisions);
    const double registry = tuning_->construction.gridSizeMetres / div;
    const wroughtwild::worldgen::WorldMap* map = seed >= 0 ? &cached_world(static_cast<uint64_t>(seed)) : nullptr;
    const std::set<int64_t> removed = map ? removed_set(*map, removed_blocks) : std::set<int64_t>();
    // Registry volume -> build cell -> terrain. Without terrain the world
    // is open everywhere and the structure alone must close the room.
    auto world = [&](const wroughtwild::lattice::Cell& c) {
        const int bx = static_cast<int>(std::floor(static_cast<double>(c.x) / div));
        const int by = static_cast<int>(std::floor(static_cast<double>(c.y) / div));
        const int bz = static_cast<int>(std::floor(static_cast<double>(c.z) / div));
        if (map == nullptr) {
            return wroughtwild::lattice::WorldCell::Sky; // no ground: all of it is open air
        }
        if (!map->inBounds(bx, bz) || by >= map->depth) {
            return wroughtwild::lattice::WorldCell::Outside;
        }
        if (by < 0) {
            return wroughtwild::lattice::WorldCell::Solid;
        }
        const int64_t key = (static_cast<int64_t>(bz) * map->width + bx) * map->depth + by;
        if (removed.count(key)) {
            return wroughtwild::lattice::WorldCell::Open; // dug: a hollow, never sky
        }
        if (map->blockAt(bx, by, bz) != wroughtwild::worldgen::kAir) {
            return wroughtwild::lattice::WorldCell::Solid;
        }
        return by >= map->at(bx, bz).height ? wroughtwild::lattice::WorldCell::Sky
                                            : wroughtwild::lattice::WorldCell::Open;
    };
    wroughtwild::lattice::Element start;
    start.kind = ElementKind::Volume;
    start.cell = wroughtwild::lattice::Cell{static_cast<int>(std::floor(at.x / registry)),
                                            static_cast<int>(std::floor(at.y / registry)),
                                            static_cast<int>(std::floor(at.z / registry))};
    const int cap = tuning_->world.shelter.maxRoomCells * div * div * div;
    const wroughtwild::lattice::Vec3 precise{at.x / registry, at.y / registry, at.z / registry};
    const auto result = wroughtwild::lattice::enclosure(structure_, start, cap, world, &precise);
    d["enclosed"] = result.enclosed;
    d["cells"] = result.volumes / (div * div * div);
    d["reason"] = to_godot(result.leakReason);
    if (!result.leakReason.empty()) {
        // The escape volume's centre in world metres, for a marker.
        d["leak"] = Vector3(static_cast<real_t>((result.leak.x + 0.5) * registry),
                            static_cast<real_t>((result.leak.y + 0.5) * registry),
                            static_cast<real_t>((result.leak.z + 0.5) * registry));
    }
    return d;
}

// --- skill mastery ---------------------------------------------------------------

PackedStringArray WroughtwildSim::note_skill_use(const String& skill_id) {
    PackedStringArray out;
    if (!require_loaded("note_skill_use")) {
        return out;
    }
    for (const auto& text : player_->noteSkillUse(to_std(skill_id))) {
        out.push_back(to_godot(text));
    }
    return out;
}

bool WroughtwildSim::discard_pack_item(int index) {
    if (!require_loaded("discard_pack_item") || index < 0 || index >= static_cast<int>(player_->packItems.size())) {
        return false;
    }
    player_->packItems.erase(player_->packItems.begin() + index);
    return true;
}

// --- items as mechanics: Preserving Transfer -----------------------------------

Array WroughtwildSim::transfer_targets(const String& process_id) const {
    Array out;
    if (!require_loaded("transfer_targets")) {
        return out;
    }
    const auto* p = tuning_->crafting.findCatalystProcess(to_std(process_id));
    if (p == nullptr || p->process != "catalyst_transfer") {
        return out;
    }
    for (size_t i = 0; i < player_->packItems.size(); ++i) {
        const auto& target = player_->packItems[i];
        const auto* base = tuning_->items.findBase(target.baseId);
        if (base == nullptr) {
            continue;
        }
        auto worn = equipment_.slots.find(base->slot);
        if (worn == equipment_.slots.end() || worn->second.rolledProperties.empty()) {
            continue;
        }
        if (worn->second.baseId == target.baseId && target.rolledProperties.empty() && base->tierCap <=
            tuning_->items.findBase(worn->second.baseId)->tierCap) {
            // Same base, nothing gained: still allowed (a spare), but list it last? Keep simple: allow.
        }
        Dictionary entry = item_entry(*tuning_, target, static_cast<int>(i));
        entry["worn_display_name"] = to_godot(tuning_->items.findBase(worn->second.baseId)
                                                   ? tuning_->items.findBase(worn->second.baseId)->displayName
                                                   : worn->second.baseId);
        out.push_back(entry);
    }
    return out;
}

Dictionary WroughtwildSim::transfer_with_catalyst(const String& process_id, int target_index) {
    Dictionary d;
    d["applied"] = false;
    d["moved"] = 0;
    if (!require_loaded("transfer_with_catalyst")) {
        return d;
    }
    const auto* p = tuning_->crafting.findCatalystProcess(to_std(process_id));
    if (p == nullptr || p->process != "catalyst_transfer") {
        d["reason"] = "wrong_process";
        return d;
    }
    if (target_index < 0 || target_index >= static_cast<int>(player_->packItems.size())) {
        d["reason"] = "bad_target";
        return d;
    }
    auto& target = player_->packItems[static_cast<size_t>(target_index)];
    const auto* base = tuning_->items.findBase(target.baseId);
    if (base == nullptr) {
        d["reason"] = "bad_target";
        return d;
    }
    auto worn = equipment_.slots.find(base->slot);
    if (worn == equipment_.slots.end() || worn->second.rolledProperties.empty()) {
        d["reason"] = "no_source";
        return d;
    }
    if (!player_->stationAvailable(p->station)) {
        d["reason"] = "station_unavailable";
        return d;
    }
    if (player_->held(p->catalyst) < 1) {
        d["reason"] = "missing_catalyst";
        return d;
    }
    for (const auto& [skillId, level] : p->minimumSkill) {
        if (player_->skillLevel(skillId) < level) {
            d["reason"] = "skill_too_low";
            return d;
        }
    }
    if (!wroughtwild::items::catalystTransfer(tuning_->items, worn->second, target)) {
        d["reason"] = "bad_target";
        return d;
    }
    d["moved"] = static_cast<int>(target.rolledProperties.size());
    player_->take(p->catalyst, 1);
    equipment_.slots.erase(worn); // the old base is spent with the catalyst
    d["applied"] = true;
    return d;
}

// --- the Foundry ---------------------------------------------------------------

wroughtwild::stats::DerivedStats WroughtwildSim::derived_now(const wroughtwild::stats::Equipment* preview) const {
    std::vector<wroughtwild::stats::ExtraEffect> extra;
    for (const auto& mod : wroughtwild::grammar::foundryMods(*tuning_, player_->foundry(), player_->currentEra())) {
        extra.push_back({mod.effectKey, mod.value});
    }
    return wroughtwild::stats::deriveStats(tuning_->world.playerBase, preview ? *preview : equipment_, tuning_->items, extra);
}

Dictionary WroughtwildSim::foundry() const {
    Dictionary d;
    if (!require_loaded("foundry")) {
        return d;
    }
    const auto frame = player_->plate();
    const auto& state = player_->foundry();
    // The frame (D-023): every row is drawn; the era has forged first_row
    // to last_row; the sockets take a subject.
    d["rows"] = frame.rows;
    d["cols"] = frame.cols;
    d["first_row"] = frame.firstRow;
    d["last_row"] = frame.lastRow;
    Array sockets;
    for (const auto& s : frame.sockets) {
        Array cell;
        cell.push_back(s.row);
        cell.push_back(s.col);
        sockets.push_back(cell);
    }
    d["sockets"] = sockets;
    d["era"] = player_->currentEra();
    Array plate;
    for (const auto& p : state.plate) {
        Dictionary cell;
        cell["row"] = p.row;
        cell["col"] = p.col;
        cell["ingot"] = to_godot(p.ingot);
        cell["skill"] = to_godot(p.skill);
        cell["currency"] = to_godot(p.currency);
        cell["metal"] = p.isIngot() ? to_godot(wroughtwild::foundry::metalOf(tuning_->foundry, p)) : String();
        plate.push_back(cell);
    }
    d["plate"] = plate;
    // The metals (slice 10): every metal in reach order with its re-cast
    // cost and whether the era allows it, the era's alloy, and what is in
    // hand of each ingot by metal.
    Array metals;
    for (const auto& m : tuning_->foundry.metals) {
        Dictionary entry;
        entry["id"] = to_godot(m.id);
        entry["display_name"] = to_godot(m.displayName);
        entry["reach"] = m.reach;
        entry["era"] = m.era;
        entry["recast_cost"] = to_dictionary(m.recastCost);
        entry["available"] = m.era <= player_->currentEra() && !m.recastCost.empty();
        metals.push_back(entry);
    }
    d["metals"] = metals;
    d["default_metal"] = to_godot(tuning_->foundry.defaultMetal());
    d["alloy"] = to_godot(tuning_->foundry.alloyForEra(player_->currentEra()));
    d["max_reach"] = tuning_->foundry.maxReach();
    Dictionary byMetal;
    for (const auto& [id, count] : state.owned) {
        Dictionary counts;
        for (const auto& m : tuning_->foundry.metals) {
            const int n = wroughtwild::foundry::unplacedCountOf(tuning_->foundry, state, id, m.id);
            if (n > 0) counts[to_godot(m.id)] = n;
        }
        if (!counts.is_empty()) byMetal[to_godot(id)] = counts;
    }
    d["unplaced_by_metal"] = byMetal;
    // Tablets (D-022): the known skills not yet laid, for the tray.
    Array tablets;
    for (const auto& id : player_->knownSkills()) {
        if (wroughtwild::foundry::tabletFor(state, id) != nullptr) continue;
        const auto* def = tuning_->skills.findCombatSkill(id);
        if (def == nullptr) continue;
        Dictionary t;
        t["id"] = to_godot(id);
        t["display_name"] = to_godot(def->displayName);
        tablets.push_back(t);
    }
    d["tablets"] = tablets;
    // Kinds (D-023, the flow): every variant that may rest on the plate,
    // with what the purse holds of it and its own base, for the tray.
    Array kinds;
    for (const auto& currency : tuning_->crafting.currencyKinds) {
        const auto& k = *tuning_->foundry.findKindOnPlate(currency.id);
        Dictionary entry;
        entry["id"] = to_godot(currency.id);
        entry["display_name"] = to_godot(currency.displayName);
        entry["potency"] = currency.potency;
        entry["short_name"] = to_godot(k.shortName);
        entry["family"] = to_godot(k.family);
        entry["family_name"] = to_godot(tuning_->foundry.familyName(k.family));
        entry["held"] = player_->held(currency.id);
        const auto* def = k.modifier.empty() ? nullptr : tuning_->items.findModifier(k.modifier);
        entry["base_sentence"] = def ? to_godot(wroughtwild::items::modifierSentence(*def, k.value)) : String("no base of its own");
        kinds.push_back(entry);
    }
    d["kinds"] = kinds;
    // The flow per placed kind: whether a chain leads inward to a skill.
    Array flows;
    for (const auto& p : state.plate) {
        if (!p.isCurrency()) {
            continue;
        }
        Dictionary f;
        f["row"] = p.row;
        f["col"] = p.col;
        f["flows"] = wroughtwild::foundry::flowsToSkill(state, frame, p.row, p.col);
        flows.push_back(f);
    }
    d["flows"] = flows;
    // The surround (D-023 slice 9): the class chosen before play and
    // whether the choice is still open, every class with its patterns and
    // its specialisations (each saying what the patterns become), the
    // chosen class's specialisations and whether one is offered, the
    // patterns known, and every rail slot around the frame with its
    // pattern, whether the line lights it and - while the specialisation
    // is offered - what it would become.
    const auto& railsDef = tuning_->foundry.rails;
    auto specialisation_view = [&](const wroughtwild::tuning::SpecialisationDef& s) {
        Dictionary entry;
        entry["id"] = to_godot(s.id);
        entry["display_name"] = to_godot(s.displayName);
        entry["class"] = to_godot(s.classId);
        Array becomes;
        for (const auto& [from, to] : s.becomes) {
            Dictionary b;
            b["from"] = foundry_pattern(to_godot(from));
            b["to"] = foundry_pattern(to_godot(to));
            becomes.push_back(b);
        }
        entry["becomes"] = becomes;
        return entry;
    };
    d["class"] = to_godot(state.chosenClass);
    const auto* chosenClass = railsDef.findClass(state.chosenClass);
    d["class_name"] = chosenClass ? to_godot(chosenClass->displayName) : String();
    d["can_choose_class"] = player_->canChooseClass();
    Array classes;
    for (const auto& c : railsDef.classes) {
        Dictionary entry;
        entry["id"] = to_godot(c.id);
        entry["display_name"] = to_godot(c.displayName);
        Array patterns;
        for (const auto& id : c.patterns) {
            patterns.push_back(foundry_pattern(to_godot(id)));
        }
        entry["patterns"] = patterns;
        Array specs;
        for (const auto& id : c.specialisations) {
            if (const auto* s = railsDef.findSpecialisation(id)) {
                specs.push_back(specialisation_view(*s));
            }
        }
        entry["specialisations"] = specs;
        // The class's kit (4 Sep 2026): the skills it starts with, in bar order.
        PackedStringArray kit, kitNames;
        for (const auto& id : c.startingSkills) {
            kit.push_back(to_godot(id));
            const auto* skill = tuning_->skills.findCombatSkill(id);
            kitNames.push_back(to_godot(skill ? skill->displayName : id));
        }
        entry["starting_skills"] = kit;
        entry["starting_skill_names"] = kitNames;
        classes.push_back(entry);
    }
    d["classes"] = classes;
    d["specialisation"] = to_godot(state.specialisation);
    const auto* chosen = railsDef.findSpecialisation(state.specialisation);
    d["specialisation_name"] = chosen ? to_godot(chosen->displayName) : String();
    d["can_specialise"] = player_->canSpecialise();
    Array specialisations;
    if (chosenClass != nullptr) {
        for (const auto& id : chosenClass->specialisations) {
            if (const auto* s = railsDef.findSpecialisation(id)) {
                specialisations.push_back(specialisation_view(*s));
            }
        }
    }
    d["specialisations"] = specialisations;
    Array known;
    for (const auto& id : player_->foundryPatterns()) {
        known.push_back(foundry_pattern(to_godot(id)));
    }
    d["patterns"] = known;
    d["rails_allowed"] = player_->railsAllowed();
    d["rails_set"] = static_cast<int>(state.rails.size());
    Array railSlots;
    auto slot = [&](const std::string& axis, int index) {
        Dictionary r;
        r["axis"] = to_godot(axis);
        r["index"] = index;
        r["forged"] = !wroughtwild::foundry::lineCells(frame, axis, index).empty();
        const auto* rail = wroughtwild::foundry::railAt(state, axis, index);
        r["pattern"] = rail ? to_godot(rail->pattern) : String();
        r["holds"] = false;
        if (rail != nullptr) {
            const auto* def = railsDef.findPattern(rail->pattern);
            r["display_name"] = def ? to_godot(def->displayName) : to_godot(rail->pattern);
            r["condition_text"] = def ? to_godot(def->conditionText) : String();
            r["rule_text"] = def ? to_godot(def->ruleText) : String();
            const auto status = wroughtwild::foundry::railStatus(*tuning_, state, frame, *rail);
            r["holds"] = status.holds;
            r["placed"] = status.placed;
            r["minimum"] = status.minimum;
            r["missing_skill"] = status.missingSkill;
            r["missing_kind"] = status.missingKind;
            Array breaking;
            for (const auto& c : status.breaking) {
                Array cell;
                cell.push_back(c.row);
                cell.push_back(c.col);
                breaking.push_back(cell);
            }
            r["breaking"] = breaking;
            r["skills"] = strings_to_packed(status.skills);
            // The view: what this rail becomes under each specialisation offered.
            Array becomes;
            if (chosenClass != nullptr && player_->canSpecialise()) {
                for (const auto& id : chosenClass->specialisations) {
                    const auto* s = railsDef.findSpecialisation(id);
                    if (s == nullptr) {
                        continue;
                    }
                    const auto it = s->becomes.find(rail->pattern);
                    if (it == s->becomes.end()) {
                        continue;
                    }
                    Dictionary b;
                    b["specialisation"] = to_godot(s->id);
                    b["display_name"] = to_godot(s->displayName);
                    b["pattern"] = foundry_pattern(to_godot(it->second));
                    becomes.push_back(b);
                }
            }
            r["becomes"] = becomes;
        }
        railSlots.push_back(r);
    };
    for (int r = 0; r < frame.rows; ++r) {
        slot("row", r);
    }
    for (int c = 0; c < frame.cols; ++c) {
        slot("column", c);
    }
    d["rails"] = railSlots;
    d["haste_after_hit_seconds"] = tuning_->foundry.hasteAfterHitSeconds;
    d["support_multiplier"] = tuning_->foundry.supportMultiplier;
    Dictionary owned, unplaced;
    for (const auto& [id, count] : state.owned) {
        owned[to_godot(id)] = count;
        unplaced[to_godot(id)] = wroughtwild::foundry::unplacedCount(state, id);
    }
    d["owned"] = owned;
    d["unplaced"] = unplaced;
    d["reforge_cost"] = to_dictionary(tuning_->foundry.reforgeCost);
    d["can_reforge"] = player_->canAffordReforge();
    return d;
}

PackedStringArray WroughtwildSim::foundry_ingot_ids() const {
    PackedStringArray ids;
    if (!require_loaded("foundry_ingot_ids")) {
        return ids;
    }
    for (const auto& ingot : tuning_->foundry.ingots) {
        ids.push_back(to_godot(ingot.id));
    }
    return ids;
}

Dictionary WroughtwildSim::foundry_ingot(const String& ingot_id) const {
    Dictionary d;
    if (!require_loaded("foundry_ingot")) {
        return d;
    }
    const auto* ingot = tuning_->foundry.findIngot(to_std(ingot_id));
    if (ingot == nullptr) {
        return d;
    }
    d["id"] = to_godot(ingot->id);
    d["display_name"] = to_godot(ingot->displayName);
    d["verb"] = to_godot(ingot->verb);
    d["modifier"] = to_godot(ingot->modifier);
    d["value"] = ingot->value;
    const auto* def = tuning_->items.findModifier(ingot->modifier);
    d["sentence"] = def ? to_godot(wroughtwild::items::modifierSentence(*def, ingot->value)) : String();
    // What it reads as beside a skill (D-023 slice 2): its skill modifier at
    // the support multiplier and, for an element ingot, what it adds to a
    // skill of another element.
    const auto* reading = tuning_->items.findModifier(ingot->supportModifier());
    d["skill_sentence"] = reading ? to_godot(wroughtwild::items::modifierSentence(
                                        *reading, ingot->supportValue() * tuning_->foundry.supportMultiplier))
                                  : String();
    const auto* added = ingot->addedModifier.empty() ? nullptr : tuning_->items.findModifier(ingot->addedModifier);
    d["added_sentence"] = added ? to_godot(wroughtwild::items::modifierSentence(
                                      *added, ingot->value * tuning_->foundry.supportMultiplier))
                                : String();
    const auto& state = player_->foundry();
    auto owned = state.owned.find(ingot->id);
    d["owned"] = owned == state.owned.end() ? 0 : owned->second;
    d["unplaced"] = wroughtwild::foundry::unplacedCount(state, ingot->id);
    Dictionary cast, unplacedByMetal;
    for (const auto& m : tuning_->foundry.metals) {
        cast[to_godot(m.id)] = wroughtwild::foundry::castCount(state, ingot->id, m.id);
        unplacedByMetal[to_godot(m.id)] = wroughtwild::foundry::unplacedCountOf(tuning_->foundry, state, ingot->id, m.id);
    }
    d["cast"] = cast;
    d["unplaced_by_metal"] = unplacedByMetal;
    return d;
}

namespace {
Dictionary mutation_effect(const wroughtwild::tuning::Tuning& tuning, const wroughtwild::foundry::Effect& e) {
    Dictionary d;
    d["kind"] = String(e.kind.c_str()); d["label"] = String(e.label.c_str());
    d["skill"] = String(e.skill.c_str()); d["subject"] = String(e.subject.c_str());
    d["packet"] = String(e.packet.c_str()); d["cell_row"] = e.cellRow; d["cell_col"] = e.cellCol;
    d["form_name"] = String(e.formName.c_str()); d["description"] = String(e.description.c_str());
    d["source_kind"] = String(e.sourceKind.c_str());
    Array path;
    for (const auto& cell : e.path) { Array pair; pair.push_back(cell.row); pair.push_back(cell.col); path.push_back(pair); }
    d["path"] = path;
    const auto* def = tuning.items.findModifier(e.modifier);
    d["sentence"] = def ? String(wroughtwild::items::modifierSentence(*def, e.value).c_str()) : String();
    if (e.kind == "link") d["sentence"] = String("on either's new freeze, ignite or bleed, the other casts at that enemy");
    d["modifier"] = String(e.modifier.c_str()); d["value"] = e.value;
    d["row"] = e.row; d["col"] = e.col;
    return d;
}
}

Dictionary WroughtwildSim::skill_mutation(const String& skill_id) const {
    Dictionary d;
    if (!require_loaded("skill_mutation")) return d;
    const auto* def = find_skill(skill_id);
    if (!def) return d;
    const auto mods = active_mods();
    for (const auto& [key, value] : wroughtwild::grammar::skillMutation(*tuning_, mods, def->id)) d[to_godot(key)] = value;
    d["tags"] = strings_to_packed(wroughtwild::grammar::effectiveTags(*tuning_, mods, def->id));
    Dictionary limits;
    for (const auto& [key, value] : tuning_->foundry.mutationLimits) limits[to_godot(key)] = value;
    d["limits"] = limits;
    Array forms; PackedStringArray names;
    for (const auto& e : wroughtwild::foundry::effects(*tuning_, player_->foundry(), player_->plate())) {
        if (e.skill != def->id || e.formName.empty() || names.has(to_godot(e.formName))) continue;
        names.push_back(to_godot(e.formName)); forms.push_back(mutation_effect(*tuning_, e));
    }
    d["forms"] = forms;
    d["display_name"] = names.is_empty() ? to_godot(def->displayName) : String(" + ").join(names) + " " + to_godot(def->displayName);
    return d;
}

Dictionary WroughtwildSim::foundry_preview(int row, int col, const String& piece_id, const String& metal_id) const {
    Dictionary result;
    result["valid"] = false;
    if (!require_loaded("foundry_preview")) return result;
    // Use the real placement economy on a copy. Affordability, depth, ownership,
    // learned tablets, occupied cells and alloy availability exactly match commit.
    auto preview = *player_;
    bool valid = false;
    const auto id = to_std(piece_id);
    if (tuning_->foundry.findIngot(id)) valid = preview.foundryPlace(row, col, id, to_std(metal_id));
    else if (tuning_->foundry.findKindOnPlate(id)) valid = preview.foundryPlaceKind(row, col, id);
    else if (tuning_->skills.findCombatSkill(id)) valid = preview.foundryPlaceSkill(row, col, id);
    result["valid"] = valid;
    if (!valid) { result["reason"] = String("This piece cannot be placed here, or is not held."); return result; }
    Array effects;
    for (const auto& e : wroughtwild::foundry::effects(*tuning_, preview.foundry(), preview.plate()))
        effects.push_back(mutation_effect(*tuning_, e));
    result["effects"] = effects;
    return result;
}

Array WroughtwildSim::foundry_effects() const {
    Array out;
    if (!require_loaded("foundry_effects")) {
        return out;
    }
    for (const auto& e : wroughtwild::foundry::effects(*tuning_, player_->foundry(), player_->plate()))
        out.push_back(mutation_effect(*tuning_, e));
    return out;
}

bool WroughtwildSim::foundry_place(int row, int col, const String& ingot_id, const String& metal_id) {
    return require_loaded("foundry_place") && player_->foundryPlace(row, col, to_std(ingot_id), to_std(metal_id));
}

bool WroughtwildSim::foundry_recast(const String& ingot_id, const String& metal_id) {
    return require_loaded("foundry_recast") && player_->foundryRecast(to_std(ingot_id), to_std(metal_id));
}

bool WroughtwildSim::can_recast(const String& ingot_id, const String& metal_id) const {
    return require_loaded("can_recast") && player_->canRecast(to_std(ingot_id), to_std(metal_id));
}

bool WroughtwildSim::foundry_remove(int row, int col) {
    return require_loaded("foundry_remove") && player_->foundryRemove(row, col);
}

bool WroughtwildSim::foundry_place_skill(int row, int col, const String& skill_id) {
    return require_loaded("foundry_place_skill") && player_->foundryPlaceSkill(row, col, to_std(skill_id));
}

bool WroughtwildSim::foundry_place_kind(int row, int col, const String& kind_id) {
    return require_loaded("foundry_place_kind") && player_->foundryPlaceKind(row, col, to_std(kind_id));
}

Array WroughtwildSim::foundry_event(const String& event) {
    Array out;
    if (!require_loaded("foundry_event")) {
        return out;
    }
    for (const auto& id : player_->foundryEvent(to_std(event))) {
        out.push_back(to_godot(id));
    }
    return out;
}

Array WroughtwildSim::foundry_notices() {
    Array out;
    if (!require_loaded("foundry_notices")) {
        return out;
    }
    for (const auto& id : player_->takeFoundryNotices()) {
        out.push_back(to_godot(id));
    }
    return out;
}

Dictionary WroughtwildSim::era() const {
    Dictionary d;
    if (!require_loaded("era")) {
        return d;
    }
    const auto& e = player_->era();
    d["index"] = player_->currentEra();
    d["id"] = to_godot(e.id);
    d["display_name"] = to_godot(e.displayName);
    d["story"] = to_godot(e.story);
    d["count"] = static_cast<int>(tuning_->eras.eras.size());
    d["elite_chance_bonus"] = e.eliteChanceBonus;
    Dictionary escorts;
    for (const auto& [enemyId, list] : e.packEscorts) {
        escorts[to_godot(enemyId)] = strings_to_packed(list);
    }
    d["pack_escorts"] = escorts;
    // The mingling (Wave 8 slice 3).
    Dictionary mingle;
    for (const auto& [biome, list] : e.mingle) {
        mingle[to_godot(biome)] = strings_to_packed(list);
    }
    d["mingle"] = mingle;
    d["mingle_chance"] = e.mingleChance;
    d["patrols_cross_biomes"] = e.patrolsCrossBiomes;
    return d;
}

String WroughtwildSim::mingle_pick(const String& biome, int salt) const {
    if (!require_loaded("mingle_pick")) {
        return String();
    }
    return String(player_->era().minglePick(to_std(biome), static_cast<unsigned long long>(static_cast<long long>(salt))).c_str());
}

Dictionary WroughtwildSim::era_mechanic(const String& enemy_id, const String& mechanic) const {
    Dictionary d;
    if (!require_loaded("era_mechanic")) {
        return d;
    }
    const auto* params = player_->era().mechanic(to_std(enemy_id), to_std(mechanic));
    if (params == nullptr) {
        return d;
    }
    for (const auto& [key, value] : *params) {
        d[to_godot(key)] = value;
    }
    return d;
}

void WroughtwildSim::record_world_effect(const String& effect) {
    if (require_loaded("record_world_effect")) {
        player_->recordWorldEffect(to_std(effect));
    }
}

// --- D-014 itemisation ---------------------------------------------------------

wroughtwild::grammar::ActiveMods WroughtwildSim::active_mods(const wroughtwild::stats::Equipment* preview) const {
    auto mods = wroughtwild::grammar::gearMods(tuning_->items, preview ? *preview : equipment_);
    // The Foundry's plate speaks in the same modifiers as gear (D-019).
    for (auto& mod : wroughtwild::grammar::foundryMods(*tuning_, player_->foundry(), player_->currentEra())) {
        mods.push_back(std::move(mod));
    }
    // Mastery perks speak to their own skill only.
    for (auto& mod : wroughtwild::grammar::earnedMasteryMods(*tuning_, player_->exportState().earnedMastery)) {
        mods.push_back(std::move(mod));
    }
    for (const auto& id : active_skill_mods_) {
        const auto* def = tuning_->items.findModifier(id);
        if (def != nullptr) {
            mods.push_back(wroughtwild::grammar::modAt(tuning_->items, id,
                                                       wroughtwild::grammar::defaultValue(*def), "debug"));
        }
    }
    return mods;
}

PackedStringArray WroughtwildSim::slot_ids() const {
    return require_loaded("slot_ids") ? strings_to_packed(tuning_->items.slots) : PackedStringArray();
}

PackedStringArray WroughtwildSim::item_base_ids() const {
    PackedStringArray ids;
    if (require_loaded("item_base_ids")) {
        for (const auto& base : tuning_->items.itemBases) {
            ids.push_back(to_godot(base.id));
        }
    }
    return ids;
}

Dictionary WroughtwildSim::item_base(const String& base_id) const {
    Dictionary d;
    if (!require_loaded("item_base")) {
        return d;
    }
    const auto* base = tuning_->items.findBase(to_std(base_id));
    if (base == nullptr) {
        return d;
    }
    d["id"] = to_godot(base->id);
    d["display_name"] = to_godot(base->displayName);
    d["slot"] = to_godot(base->slot);
    d["material"] = to_godot(base->material);
    Dictionary implicit;
    for (const auto& [key, value] : base->implicitProperties) {
        implicit[to_godot(key)] = value;
    }
    d["implicit_properties"] = implicit;
    Array mods;
    for (const auto& im : base->implicitModifiers) {
        const auto* def = tuning_->items.findModifier(im.id);
        if (def != nullptr) {
            mods.push_back(mod_entry(*def, im.value, 0, "implicit"));
        }
    }
    d["implicit_modifiers"] = mods;
    d["allowed_modifier_tags"] = strings_to_packed(base->allowedModifierTags);
    return d;
}

PackedStringArray WroughtwildSim::modifier_ids() const {
    PackedStringArray ids;
    if (require_loaded("modifier_ids")) {
        for (const auto& def : tuning_->items.modifiers) {
            ids.push_back(to_godot(def.id));
        }
    }
    return ids;
}

Dictionary WroughtwildSim::modifier(const String& modifier_id) const {
    Dictionary d;
    if (!require_loaded("modifier")) {
        return d;
    }
    const auto* def = tuning_->items.findModifier(to_std(modifier_id));
    if (def == nullptr) {
        return d;
    }
    d["id"] = to_godot(def->id);
    d["display_name"] = to_godot(def->displayName);
    d["tags"] = strings_to_packed(def->tags);
    d["applies_to_tags"] = strings_to_packed(def->appliesToTags);
    d["effect_key"] = to_godot(def->effectKey);
    d["display"] = to_godot(def->display);
    d["self"] = def->isSelf();
    d["design_purpose"] = to_godot(def->designPurpose);
    Array tiers;
    for (const auto& tier : def->tiers) {
        Dictionary t;
        t["tier"] = tier.tier;
        t["minimum"] = tier.minimum;
        t["maximum"] = tier.maximum;
        tiers.push_back(t);
    }
    d["tiers"] = tiers;
    return d;
}

Array WroughtwildSim::pack_items() const {
    Array items;
    if (!require_loaded("pack_items")) {
        return items;
    }
    for (size_t i = 0; i < player_->packItems.size(); ++i) {
        items.push_back(item_entry(*tuning_, player_->packItems[i], static_cast<int>(i)));
    }
    return items;
}

Dictionary WroughtwildSim::compare_equipment(int pack_index, const String& base_id) const {
    Dictionary result;
    if (!require_loaded("compare_equipment")) return result;
    wroughtwild::items::ItemInstance candidate;
    if (pack_index >= 0) {
        if (static_cast<size_t>(pack_index) >= player_->packItems.size()) return result;
        candidate = player_->packItems[static_cast<size_t>(pack_index)];
    } else {
        if (pack_index != -1 && pack_index != -2) return result;
        const auto* base = tuning_->items.findBase(to_std(base_id));
        const auto held = player_->inventory.find(to_std(base_id));
        if (!base || (pack_index == -1 && (held == player_->inventory.end() || held->second < 1))) return result;
        candidate.baseId = base->id;
        candidate.implicitProperties = base->implicitProperties;
    }
    const auto* base = tuning_->items.findBase(candidate.baseId);
    if (!base) return result;
    auto equipment = equipment_;
    const auto worn = equipment.slots.find(base->slot);
    result["current"] = worn == equipment.slots.end() ? Dictionary() : item_entry(*tuning_, worn->second, -1);
    result["candidate"] = item_entry(*tuning_, candidate, -1);
    result["slot"] = to_godot(base->slot);
    equipment.slots[base->slot] = candidate;
    auto stats_view = [](const wroughtwild::stats::DerivedStats& stats) {
        Dictionary d;
        d["max_life"] = stats.maxLife;
        d["armour"] = stats.armour;
        d["fire_resistance_percent"] = stats.fireResistancePercent;
        d["cold_resistance_percent"] = stats.coldResistancePercent;
        d["area_bonus"] = stats.areaBonus;
        return d;
    };
    result["before"] = stats_view(derived_now());
    result["after"] = stats_view(derived_now(&equipment));
    const auto before = active_mods();
    const auto after = active_mods(&equipment);
    Array skills;
    for (const auto& id : known_skill_ids()) {
        const auto skill_id = to_std(String(id));
        const auto* skill = tuning_->skills.findCombatSkill(skill_id);
        if (!skill) continue;
        Dictionary row;
        row["id"] = String(id);
        row["display_name"] = to_godot(skill->displayName);
        auto skill_view = [&](const wroughtwild::grammar::ActiveMods& mods) {
            Dictionary d;
            d["hit_payload"] = wroughtwild::grammar::skillDamage(*tuning_, mods, skill_id);
            d["cooldown_seconds"] = wroughtwild::grammar::skillCooldownSeconds(*tuning_, mods, skill_id);
            d["reach_multiplier"] = wroughtwild::grammar::skillReach(*tuning_, mods, skill_id);
            if (skill->delivery == "projectile") {
                d["projectiles"] = wroughtwild::grammar::skillProjectiles(*tuning_, mods, skill_id);
                d["pierce"] = wroughtwild::grammar::skillPierce(*tuning_, mods, skill_id);
            }
            return d;
        };
        row["before"] = skill_view(before);
        row["after"] = skill_view(after);
        skills.push_back(row);
    }
    result["skills"] = skills;
    return result;
}

bool WroughtwildSim::equip_pack_item(int index) {
    if (!require_loaded("equip_pack_item") || index < 0 ||
        static_cast<size_t>(index) >= player_->packItems.size()) {
        return false;
    }
    const wroughtwild::items::ItemInstance item = player_->packItems[static_cast<size_t>(index)];
    const auto* base = tuning_->items.findBase(item.baseId);
    if (base == nullptr) {
        return false;
    }
    player_->packItems.erase(player_->packItems.begin() + index);
    auto worn = equipment_.slots.find(base->slot);
    if (worn != equipment_.slots.end()) {
        player_->packItems.push_back(worn->second);
    }
    equipment_.slots[base->slot] = item;
    return true;
}

bool WroughtwildSim::unequip(const String& slot) {
    if (!require_loaded("unequip")) {
        return false;
    }
    auto worn = equipment_.slots.find(to_std(slot));
    if (worn == equipment_.slots.end()) {
        return false;
    }
    player_->packItems.push_back(worn->second);
    equipment_.slots.erase(worn);
    return true;
}

Array WroughtwildSim::active_modifiers() const {
    Array out;
    if (!require_loaded("active_modifiers")) {
        return out;
    }
    for (const auto& mod : active_mods()) {
        const auto* def = tuning_->items.findModifier(mod.id);
        if (def != nullptr) {
            out.push_back(mod_entry(*def, mod.value, 0, mod.source));
        }
    }
    return out;
}

int WroughtwildSim::roll_item_into_pack(const String& base_id, const String& rarity, int tier, int seed) {
    if (!require_loaded("roll_item_into_pack")) {
        return -1;
    }
    try {
        player_->packItems.push_back(wroughtwild::items::rollRarityItem(
            tuning_->items, to_std(base_id), to_std(rarity), tier, static_cast<uint64_t>(seed)));
    } catch (const std::exception& e) {
        UtilityFunctions::push_warning("WroughtwildSim.roll_item_into_pack: ", e.what());
        return -1;
    }
    return static_cast<int>(player_->packItems.size()) - 1;
}

double WroughtwildSim::skill_cooldown_seconds(const String& skill_id) const {
    if (!require_loaded("skill_cooldown_seconds")) {
        return 0.0;
    }
    return wroughtwild::grammar::skillCooldownSeconds(*tuning_, active_mods(), to_std(skill_id));
}

double WroughtwildSim::skill_reach(const String& skill_id) const {
    if (!require_loaded("skill_reach")) {
        return 1.0;
    }
    return wroughtwild::grammar::skillReach(*tuning_, active_mods(), to_std(skill_id));
}

double WroughtwildSim::skill_life_on_kill(const String& skill_id) const {
    if (!require_loaded("skill_life_on_kill")) {
        return 0.0;
    }
    return wroughtwild::grammar::skillLifeOnKill(*tuning_, active_mods(), to_std(skill_id));
}

Dictionary WroughtwildSim::skill_cast_armour(const String& skill_id) const {
    Dictionary d;
    if (!require_loaded("skill_cast_armour")) {
        return d;
    }
    // The skill's own swing armour lasts its swing (melee, Wave 5 item
    // 11); once a reading speaks, the whole grant lasts the reading's time.
    const double armour = wroughtwild::grammar::skillCastArmour(*tuning_, active_mods(), to_std(skill_id));
    const double swing = wroughtwild::grammar::skillSwingSeconds(*tuning_, to_std(skill_id));
    const double reading = wroughtwild::grammar::skillCastArmour(*tuning_, {}, to_std(skill_id));
    d["armour"] = armour;
    d["seconds"] = (armour > reading + 1e-9 || swing <= 0.0) ? tuning_->foundry.castArmourSeconds : swing;
    return d;
}

double WroughtwildSim::skill_stagger(const String& skill_id, bool is_boss) const {
    return require_loaded("skill_stagger") ? wroughtwild::grammar::skillStagger(*tuning_, active_mods(), to_std(skill_id), is_boss) : 0.0;
}

double WroughtwildSim::skill_push(const String& skill_id, bool is_boss) const {
    return require_loaded("skill_push") ? wroughtwild::grammar::skillPush(*tuning_, active_mods(), to_std(skill_id), is_boss) : 0.0;
}

double WroughtwildSim::ward_multiplier(const PackedStringArray& carried_statuses) const {
    if (!require_loaded("ward_multiplier")) {
        return 1.0;
    }
    std::vector<std::string> carried;
    for (int i = 0; i < carried_statuses.size(); ++i) {
        carried.push_back(to_std(carried_statuses[i]));
    }
    return wroughtwild::grammar::wardMultiplier(*tuning_, active_mods(), carried);
}

#include "strange_frontier_bindings.inc"
#include "leyline_bindings.inc"

} // namespace godot
