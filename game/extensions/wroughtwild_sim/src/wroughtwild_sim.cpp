#include "wroughtwild_sim.h"

#include <algorithm>
#include <exception>
#include <random>

#include "wroughtwild/items.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

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
    d["tier_cap"] = base ? base->tierCap : 99;
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
            for (const auto* bp : wroughtwild::items::breakpointsFor(*def, eff.tier)) {
                breakpoints.push_back(to_godot(bp->text));
            }
            m["breakpoints"] = breakpoints;
            Array locked;
            for (const auto* bp : wroughtwild::items::breakpointsFor(*def, r.tier)) {
                bool have = false;
                for (const auto* got : wroughtwild::items::breakpointsFor(*def, eff.tier)) have = have || got == bp;
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
    ClassDB::bind_method(D_METHOD("equip_pack_item", "index"), &WroughtwildSim::equip_pack_item);
    ClassDB::bind_method(D_METHOD("unequip", "slot"), &WroughtwildSim::unequip);
    ClassDB::bind_method(D_METHOD("active_modifiers"), &WroughtwildSim::active_modifiers);
    ClassDB::bind_method(D_METHOD("roll_item_into_pack", "base_id", "rarity", "tier", "seed"), &WroughtwildSim::roll_item_into_pack);
    ClassDB::bind_method(D_METHOD("skill_cooldown_seconds", "skill_id"), &WroughtwildSim::skill_cooldown_seconds);
    ClassDB::bind_method(D_METHOD("world_map", "seed"), &WroughtwildSim::world_map);
    ClassDB::bind_method(D_METHOD("world_mesh", "seed", "chunk_cells"), &WroughtwildSim::world_mesh);
    ClassDB::bind_method(D_METHOD("world_mesh_chunk", "seed", "chunk_cells", "chunk_x", "chunk_z", "removed_blocks"),
                         &WroughtwildSim::world_mesh_chunk);
    ClassDB::bind_method(D_METHOD("block_rules"), &WroughtwildSim::block_rules);
    ClassDB::bind_method(D_METHOD("lattice_registry_grid"), &WroughtwildSim::lattice_registry_grid);
    ClassDB::bind_method(D_METHOD("lattice_candidates", "shape_id", "point", "normal", "fine_grid"),
                         &WroughtwildSim::lattice_candidates, DEFVAL(false));
    ClassDB::bind_method(D_METHOD("structure_touches", "shape_id", "element"), &WroughtwildSim::structure_touches);
    ClassDB::bind_method(D_METHOD("structure_near_point", "point"), &WroughtwildSim::structure_near_point);
    ClassDB::bind_method(D_METHOD("structure_piece_count"), &WroughtwildSim::structure_piece_count);
    ClassDB::bind_method(D_METHOD("lattice_pose", "shape_id", "element"), &WroughtwildSim::lattice_pose);
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
    ClassDB::bind_method(D_METHOD("transfer_targets", "process_id"), &WroughtwildSim::transfer_targets);
    ClassDB::bind_method(D_METHOD("transfer_with_catalyst", "process_id", "target_index"),
                         &WroughtwildSim::transfer_with_catalyst);
    ClassDB::bind_method(D_METHOD("foundry"), &WroughtwildSim::foundry);
    ClassDB::bind_method(D_METHOD("foundry_ingot_ids"), &WroughtwildSim::foundry_ingot_ids);
    ClassDB::bind_method(D_METHOD("foundry_ingot", "ingot_id"), &WroughtwildSim::foundry_ingot);
    ClassDB::bind_method(D_METHOD("foundry_effects"), &WroughtwildSim::foundry_effects);
    ClassDB::bind_method(D_METHOD("foundry_place", "row", "col", "ingot_id"), &WroughtwildSim::foundry_place);
    ClassDB::bind_method(D_METHOD("foundry_remove", "row", "col"), &WroughtwildSim::foundry_remove);
    ClassDB::bind_method(D_METHOD("foundry_event", "event"), &WroughtwildSim::foundry_event);
    ClassDB::bind_method(D_METHOD("foundry_notices"), &WroughtwildSim::foundry_notices);
    ClassDB::bind_method(D_METHOD("era"), &WroughtwildSim::era);
    ClassDB::bind_method(D_METHOD("era_mechanic", "enemy_id", "mechanic"), &WroughtwildSim::era_mechanic);
    ClassDB::bind_method(D_METHOD("record_world_effect", "effect"), &WroughtwildSim::record_world_effect);
    ClassDB::bind_method(D_METHOD("encroachment_reset", "seed"), &WroughtwildSim::encroachment_reset);
    ClassDB::bind_method(D_METHOD("encroachment_tick", "now", "has_home", "home"), &WroughtwildSim::encroachment_tick);
    ClassDB::bind_method(D_METHOD("encroachment_nests"), &WroughtwildSim::encroachment_nests);
    ClassDB::bind_method(D_METHOD("encroachment_rest_multiplier", "at"), &WroughtwildSim::encroachment_rest_multiplier);
    ClassDB::bind_method(D_METHOD("encroachment_clear", "nest_id", "now"), &WroughtwildSim::encroachment_clear);
    ClassDB::bind_method(D_METHOD("encroachment_kill_drops", "kill_seed"), &WroughtwildSim::encroachment_kill_drops);
    ClassDB::bind_method(D_METHOD("encroachment_pressure"), &WroughtwildSim::encroachment_pressure);
    ClassDB::bind_method(D_METHOD("encroachment_rules"), &WroughtwildSim::encroachment_rules);
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
    ClassDB::bind_method(D_METHOD("enemy_hit_damage", "raw_damage", "damage_type"), &WroughtwildSim::enemy_hit_damage);
    ClassDB::bind_method(D_METHOD("mitigate", "amount", "damage_type"), &WroughtwildSim::mitigate);

    ClassDB::bind_method(D_METHOD("trial_start", "seed"), &WroughtwildSim::trial_start);
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

bool WroughtwildSim::trial_start(int seed) {
    if (!require_loaded("trial_start") || trial_) {
        return false;
    }
    trial_ = std::make_unique<wroughtwild::trial::TrialSession>(
        *tuning_, *player_, build_tags(), static_cast<uint64_t>(seed));
    return true;
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
    d["area_bonus"] = s.areaBonus;
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
    d["starting"] = def->starting;
    d["drop_weight"] = def->dropWeight;
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
            ids.push_back(to_godot(e.id));
        }
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
    return d;
}

Dictionary WroughtwildSim::boss() const {
    Dictionary d;
    if (!require_loaded("boss")) {
        return d;
    }
    const auto& b = tuning_->trial.boss;
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
        entry["attack_range_m"] = b.attackRangeM;
        entry["preferred_distance_m"] = b.preferredDistanceM;
        entry["aggro_range_m"] = b.aggroRangeM;
        entry["windup_seconds"] = b.windupSeconds;
        entry["give_up_distance_m"] = b.giveUpDistanceM;
        entry["scream_period_seconds"] = b.screamPeriodSeconds;
        entry["scream_radius_m"] = b.screamRadiusM;
        behaviours[to_godot(id)] = entry;
    }
    d["behaviours"] = behaviours;

    Dictionary horde;
    horde["separation_radius_m"] = rt.hordeSeparationRadiusM;
    horde["separation_strength_mps"] = rt.hordeSeparationStrengthMps;
    horde["give_up_seconds"] = rt.hordeGiveUpSeconds;
    horde["vertical_reach_m"] = rt.hordeVerticalReachM;
    horde["jump_speed_mps"] = rt.hordeJumpSpeedMps;
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
    return d;
}

void WroughtwildSim::begin_fight(int seed) {
    hits_ = std::make_unique<wroughtwild::combat::HitStream>(static_cast<uint64_t>(seed));
}

double WroughtwildSim::player_hit_damage(const String& skill_id, bool isolated) {
    if (!require_loaded("player_hit_damage")) {
        return 0.0;
    }
    const auto* def = find_skill(skill_id);
    if (def == nullptr) {
        UtilityFunctions::push_error("WroughtwildSim.player_hit_damage: unknown skill ", skill_id);
        return 0.0;
    }
    if (!hits_) {
        begin_fight(0);
    }
    // Gear modifiers scale the skill's base damage by tag before the hit
    // stream applies variance and run boons (D-014).
    auto modded = *def;
    modded.numbers["base_damage"] = wroughtwild::grammar::skillDamage(*tuning_, active_mods(), to_std(skill_id));
    return hits_->playerHit(modded, current_mods(), isolated);
}

double WroughtwildSim::enemy_hit_damage(double raw_damage, const String& damage_type) {
    if (!require_loaded("enemy_hit_damage")) {
        return 0.0;
    }
    if (!hits_) {
        begin_fight(0);
    }
    const auto stats = derived_now();
    return hits_->enemyHit(raw_damage, to_std(damage_type), stats, tuning_->world.playerBase);
}

double WroughtwildSim::mitigate(double amount, const String& damage_type) const {
    if (!require_loaded("mitigate")) {
        return amount;
    }
    const auto stats = derived_now();
    return wroughtwild::stats::mitigateDamage(amount, to_std(damage_type), stats, tuning_->world.playerBase);
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
        // PlayerEconomy keeps a reference to the tuning, so the tuning must
        // outlive it: drop the session and player first, then swap the tuning in.
        trial_.reset();
        player_.reset();
        world_cache_.reset();
        structure_.clear();
        encroachment_.reset();
        tuning_ = std::move(loaded);
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
    d["fuel_cost"] = r->fuelCost;
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
    d["inputs_met"] = wroughtwild::economy::hasAll(player_->inventory, r->inputs);
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
    auto catalyst = player_->inventory.find(p->catalyst);
    d["catalyst_held"] = catalyst == player_->inventory.end() ? 0 : catalyst->second;
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
    auto catalyst = player_->inventory.find(p->catalyst);
    if (catalyst == player_->inventory.end() || catalyst->second < 1) {
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
    catalyst->second -= 1; // consumed only once the temper has applied
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
                       : f.missingFuel        ? "missing_fuel"
                                              : "unknown";
    }
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

const wroughtwild::worldgen::WorldMap& WroughtwildSim::cached_world(uint64_t seed) {
    // The 3D world costs real time to generate; world_map and world_mesh
    // are always asked about the same seed back to back, so keep the last
    // one. Deterministic generation makes the cache invisible.
    if (!world_cache_ || world_cache_->seed != seed) {
        world_cache_ = std::make_unique<wroughtwild::worldgen::WorldMap>(
            wroughtwild::worldgen::generate(*tuning_, seed));
    }
    return *world_cache_;
}

Dictionary WroughtwildSim::world_map(int seed) {
    Dictionary d;
    if (!require_loaded("world_map")) {
        return d;
    }
    const auto& map = cached_world(static_cast<uint64_t>(seed));

    d["seed"] = seed;
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
    for (const auto& biome : tuning_->worldgen.biomes) {
        Dictionary b;
        b["id"] = to_godot(biome.id);
        b["display_name"] = to_godot(biome.displayName);
        b["surface"] = to_godot(biome.surface);
        biome_defs.push_back(b);
    }
    d["biome_defs"] = biome_defs;

    Array nodes;
    for (const auto& node : map.nodes) {
        const auto typeIt = tuning_->worldgen.nodeTypes.find(node.type);
        if (typeIt == tuning_->worldgen.nodeTypes.end()) {
            continue;
        }
        Dictionary n;
        n["type"] = to_godot(node.type);
        n["x"] = node.x;
        n["y"] = node.y;
        n["z"] = node.z;
        n["material_family"] = to_godot(typeIt->second.materialFamily);
        n["display_name"] = to_godot(typeIt->second.displayName);
        n["units"] = typeIt->second.units;
        n["units_per_harvest"] = typeIt->second.unitsPerHarvest;
        n["visual"] = to_godot(typeIt->second.visual);
        n["era"] = typeIt->second.era;
        nodes.push_back(n);
    }
    d["nodes"] = nodes;

    Array packs;
    for (const auto& pack : map.packs) {
        Dictionary p;
        PackedStringArray enemies;
        for (const auto& id : pack.enemies) {
            enemies.push_back(to_godot(id));
        }
        p["enemies"] = enemies;
        p["x"] = pack.x;
        p["y"] = pack.y;
        p["z"] = pack.z;
        p["elite_member"] = pack.eliteMemberIndex;
        p["elite_modifier"] = to_godot(pack.eliteModifierId);
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
Dictionary build_world_chunk(const wroughtwild::tuning::Tuning& tuning,
                             const wroughtwild::worldgen::WorldMap& map, int cx, int cz,
                             int chunk_cells, const std::set<int64_t>& removed) {
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

    Dictionary chunk;
    chunk["x"] = cx;
    chunk["z"] = cz;
    // Accumulate locally: Packed arrays behind a Variant are copy-on-write,
    // so growing them in place through the Dictionary would copy the whole
    // array per block.
    std::map<String, PackedVector3Array> bucket;
    PackedVector3Array faces;
    for (int z = cz; z < std::min(cz + chunk_cells, map.height); ++z) {
        for (int x = cx; x < std::min(cx + chunk_cells, map.width); ++x) {
            for (int y = 0; y < map.depth; ++y) {
                uint8_t id = eff(x, y, z);
                if (id == kAir) {
                    continue;
                }
                bool visible = false;
                for (const auto& dir : kDirs) {
                    if (eff(x + dir.dx, y + dir.dy, z + dir.dz) != kAir) {
                        continue;
                    }
                    visible = true;
                    const Vector3 base(x * cs, y * cs, z * cs);
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
                String kind;
                switch (id) {
                    case kSurface:
                        kind = to_godot(tuning.worldgen.biomes[map.at(x, z).biomeIndex].surface);
                        break;
                    case kDirt: kind = "dirt"; break;
                    case kBedrock: kind = "bedrock"; break;
                    case kStone:
                    default: kind = "stone"; break;
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

Array WroughtwildSim::world_mesh(int seed, int chunk_cells) {
    Array chunks;
    if (!require_loaded("world_mesh") || chunk_cells < 1) {
        return chunks;
    }
    const auto& map = cached_world(static_cast<uint64_t>(seed));
    const std::set<int64_t> none;
    for (int cz = 0; cz < map.height; cz += chunk_cells) {
        for (int cx = 0; cx < map.width; cx += chunk_cells) {
            chunks.push_back(build_world_chunk(*tuning_, map, cx, cz, chunk_cells, none));
        }
    }
    return chunks;
}

Dictionary WroughtwildSim::world_mesh_chunk(int seed, int chunk_cells, int chunk_x, int chunk_z,
                                            const PackedInt32Array& removed_blocks) {
    Dictionary d;
    if (!require_loaded("world_mesh_chunk") || chunk_cells < 1) {
        return d;
    }
    const auto& map = cached_world(static_cast<uint64_t>(seed));
    return build_world_chunk(*tuning_, map, chunk_x, chunk_z, chunk_cells,
                             removed_set(map, removed_blocks));
}

Dictionary WroughtwildSim::block_rules() const {
    Dictionary d;
    if (!require_loaded("block_rules")) {
        return d;
    }
    for (const auto& [kind, rule] : tuning_->worldgen.blockRules) {
        Dictionary r;
        r["breakable"] = rule.breakable;
        r["dig_seconds"] = rule.digSeconds;
        r["yields"] = to_dictionary(rule.yields);
        d[to_godot(kind)] = r;
    }
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
    for (const auto& covered : wroughtwild::lattice::footprint(e, sl.span, sl.tall, sl.longCells)) {
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
    piece.footprint = wroughtwild::lattice::footprint(e, sl.span, sl.tall, sl.longCells);
    piece.shapeId = to_std(shape_id);
    piece.family = to_std(family);
    piece.rotationStep = ((rotation_step % 4) + 4) % 4;
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
            return wroughtwild::lattice::WorldCell::Open;
        }
        if (!map->inBounds(bx, bz) || by >= map->depth) {
            return wroughtwild::lattice::WorldCell::Outside;
        }
        if (by < 0) {
            return wroughtwild::lattice::WorldCell::Solid;
        }
        const int64_t key = (static_cast<int64_t>(bz) * map->width + bx) * map->depth + by;
        if (removed.count(key)) {
            return wroughtwild::lattice::WorldCell::Open;
        }
        return map->blockAt(bx, by, bz) == wroughtwild::worldgen::kAir ? wroughtwild::lattice::WorldCell::Open
                                                                        : wroughtwild::lattice::WorldCell::Solid;
    };
    wroughtwild::lattice::Element start;
    start.kind = ElementKind::Volume;
    start.cell = wroughtwild::lattice::Cell{static_cast<int>(std::floor(at.x / registry)),
                                            static_cast<int>(std::floor(at.y / registry)),
                                            static_cast<int>(std::floor(at.z / registry))};
    const int cap = tuning_->world.shelter.maxRoomCells * div * div * div;
    const auto result = wroughtwild::lattice::enclosure(structure_, start, cap, world);
    d["enclosed"] = result.enclosed;
    d["cells"] = result.volumes / (div * div * div);
    return d;
}

// --- encroachment ----------------------------------------------------------------

namespace {

Dictionary nest_to(const wroughtwild::encroachment::Encroachment& e, const wroughtwild::encroachment::Nest& n) {
    Dictionary d;
    d["id"] = n.id;
    d["x"] = n.x;
    d["z"] = n.z;
    d["tier"] = n.tier;
    d["pack"] = strings_to_packed(e.packFor(n.tier));
    return d;
}

} // namespace

void WroughtwildSim::encroachment_reset(int seed) {
    if (!require_loaded("encroachment_reset")) {
        return;
    }
    encroachment_ = std::make_unique<wroughtwild::encroachment::Encroachment>(tuning_->world.encroachment,
                                                                             static_cast<uint64_t>(seed));
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
    auto catalyst = player_->inventory.find(p->catalyst);
    if (catalyst == player_->inventory.end() || catalyst->second < 1) {
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
    catalyst->second -= 1;
    equipment_.slots.erase(worn); // the old base is spent with the catalyst
    d["applied"] = true;
    return d;
}

// --- the Foundry ---------------------------------------------------------------

wroughtwild::stats::DerivedStats WroughtwildSim::derived_now() const {
    std::vector<wroughtwild::stats::ExtraEffect> extra;
    for (const auto& mod : wroughtwild::grammar::foundryMods(*tuning_, player_->foundry(), player_->currentEra())) {
        extra.push_back({mod.effectKey, mod.value});
    }
    return wroughtwild::stats::deriveStats(tuning_->world.playerBase, equipment_, tuning_->items, extra);
}

Dictionary WroughtwildSim::foundry() const {
    Dictionary d;
    if (!require_loaded("foundry")) {
        return d;
    }
    const auto size = player_->plateSize();
    const auto& state = player_->foundry();
    d["rows"] = size.rows;
    d["cols"] = size.cols;
    d["era"] = player_->currentEra();
    Array plate;
    for (const auto& p : state.plate) {
        Dictionary cell;
        cell["row"] = p.row;
        cell["col"] = p.col;
        cell["ingot"] = to_godot(p.ingot);
        plate.push_back(cell);
    }
    d["plate"] = plate;
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
    const auto& state = player_->foundry();
    auto owned = state.owned.find(ingot->id);
    d["owned"] = owned == state.owned.end() ? 0 : owned->second;
    d["unplaced"] = wroughtwild::foundry::unplacedCount(state, ingot->id);
    return d;
}

Array WroughtwildSim::foundry_effects() const {
    Array out;
    if (!require_loaded("foundry_effects")) {
        return out;
    }
    for (const auto& e : wroughtwild::foundry::effects(tuning_->foundry, player_->foundry(), player_->plateSize())) {
        Dictionary d;
        d["kind"] = to_godot(e.kind);
        d["label"] = to_godot(e.label);
        const auto* def = tuning_->items.findModifier(e.modifier);
        d["sentence"] = def ? to_godot(wroughtwild::items::modifierSentence(*def, e.value)) : String();
        d["modifier"] = to_godot(e.modifier);
        d["value"] = e.value;
        d["row"] = e.row;
        d["col"] = e.col;
        out.push_back(d);
    }
    return out;
}

bool WroughtwildSim::foundry_place(int row, int col, const String& ingot_id) {
    return require_loaded("foundry_place") && player_->foundryPlace(row, col, to_std(ingot_id));
}

bool WroughtwildSim::foundry_remove(int row, int col) {
    return require_loaded("foundry_remove") && player_->foundryRemove(row, col);
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
    d["encroachment"] = e.encroachment;
    d["count"] = static_cast<int>(tuning_->eras.eras.size());
    return d;
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

Array WroughtwildSim::encroachment_tick(double now, bool has_home, const Vector3& home) {
    Array out;
    if (!require_loaded("encroachment_tick")) {
        return out;
    }
    if (!encroachment_) {
        encroachment_reset(0);
    }
    // Nests belong to the eras that allow them (D-019): before then the
    // clock does not run and nothing settles.
    const bool allowed = player_->era().encroachment;
    for (const auto& n : encroachment_->tick(now, allowed && has_home, home.x, home.z)) {
        out.push_back(nest_to(*encroachment_, n));
    }
    return out;
}

Array WroughtwildSim::encroachment_nests() const {
    Array out;
    if (!require_loaded("encroachment_nests") || !encroachment_) {
        return out;
    }
    for (const auto& n : encroachment_->nests()) {
        out.push_back(nest_to(*encroachment_, n));
    }
    return out;
}

double WroughtwildSim::encroachment_rest_multiplier(const Vector3& at) const {
    if (!require_loaded("encroachment_rest_multiplier") || !encroachment_) {
        return 1.0;
    }
    return encroachment_->restMultiplierAt(at.x, at.z);
}

bool WroughtwildSim::encroachment_clear(int nest_id, double now) {
    return require_loaded("encroachment_clear") && encroachment_ && encroachment_->clear(nest_id, now);
}

bool WroughtwildSim::encroachment_kill_drops(int kill_seed) const {
    return require_loaded("encroachment_kill_drops") && encroachment_ &&
           encroachment_->killDrops(static_cast<uint64_t>(static_cast<int64_t>(kill_seed)));
}

int WroughtwildSim::encroachment_pressure() const {
    return (require_loaded("encroachment_pressure") && encroachment_) ? encroachment_->pressure() : 0;
}

Dictionary WroughtwildSim::encroachment_rules() const {
    Dictionary d;
    if (!require_loaded("encroachment_rules")) {
        return d;
    }
    const auto& e = tuning_->world.encroachment;
    d["respawn_seconds"] = e.respawnSeconds;
    d["settle_seconds"] = e.settleSeconds;
    d["growth_seconds"] = e.growthSeconds;
    d["blight_radius_m"] = e.blightRadiusM;
    d["max_nests"] = e.maxNests;
    d["nest_loot_fraction"] = e.nestLootFraction;
    return d;
}

// --- D-014 itemisation ---------------------------------------------------------

wroughtwild::grammar::ActiveMods WroughtwildSim::active_mods() const {
    auto mods = wroughtwild::grammar::gearMods(tuning_->items, equipment_);
    // The Foundry's plate speaks in the same modifiers as gear (D-019).
    for (auto& mod : wroughtwild::grammar::foundryMods(*tuning_, player_->foundry(), player_->currentEra())) {
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

} // namespace godot
