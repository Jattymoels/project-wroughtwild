#include "wroughtwild_sim.h"

#include <algorithm>
#include <exception>
#include <random>

#include "wroughtwild/items.h"

#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/utility_functions.hpp>

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
    ClassDB::bind_method(D_METHOD("world_map", "seed"), &WroughtwildSim::world_map);
    ClassDB::bind_method(D_METHOD("enemy_loot", "enemy_id", "seed"), &WroughtwildSim::enemy_loot);
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
    const auto s = wroughtwild::stats::deriveStats(tuning_->world.playerBase, equipment_);
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
    d["player"] = player;

    Dictionary behaviours;
    for (const auto& [id, b] : rt.behaviours) {
        Dictionary entry;
        entry["move_speed_mps"] = b.moveSpeedMps;
        entry["attack_range_m"] = b.attackRangeM;
        entry["preferred_distance_m"] = b.preferredDistanceM;
        entry["aggro_range_m"] = b.aggroRangeM;
        entry["windup_seconds"] = b.windupSeconds;
        behaviours[to_godot(id)] = entry;
    }
    d["behaviours"] = behaviours;

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
    return d;
}

wroughtwild::combat::CombatMods WroughtwildSim::current_mods() const {
    if (trial_ && !trial_->finished()) {
        return trial_->currentMods();
    }
    return wroughtwild::combat::buildMods(tuning_->boons, wroughtwild::boons::RunState{});
}

wroughtwild::boons::BuildTags WroughtwildSim::build_tags() const {
    // The prototype build equips every combat skill; its identity is their tags.
    wroughtwild::boons::BuildTags tags;
    for (const auto& def : tuning_->skills.combatSkills) {
        for (const auto& tag : def.tags) {
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
    return hits_->playerHit(*def, current_mods(), isolated);
}

double WroughtwildSim::enemy_hit_damage(double raw_damage, const String& damage_type) {
    if (!require_loaded("enemy_hit_damage")) {
        return 0.0;
    }
    if (!hits_) {
        begin_fight(0);
    }
    const auto stats = wroughtwild::stats::deriveStats(tuning_->world.playerBase, equipment_);
    return hits_->enemyHit(raw_damage, to_std(damage_type), stats, tuning_->world.playerBase);
}

double WroughtwildSim::mitigate(double amount, const String& damage_type) const {
    if (!require_loaded("mitigate")) {
        return amount;
    }
    const auto stats = wroughtwild::stats::deriveStats(tuning_->world.playerBase, equipment_);
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
    d["requires_world_effect"] = to_godot(s->requiresWorldEffect);
    d["unlocked"] = player_->shapeUnlocked(s->id);
    return d;
}

bool WroughtwildSim::shape_unlocked(const String& shape_id) const {
    return require_loaded("shape_unlocked") && player_->shapeUnlocked(to_std(shape_id));
}

namespace {

const char* kChestSlot = "chest";

const wroughtwild::tuning::PropertyDef* find_property(const wroughtwild::tuning::ItemTable& table,
                                                      const std::string& id) {
    for (const auto& def : table.propertyDefinitions) {
        if (def.id == id) {
            return &def;
        }
    }
    return nullptr;
}

const wroughtwild::tuning::PropertyTier* find_tier(const wroughtwild::tuning::PropertyDef* def, int tier) {
    if (def == nullptr) {
        return nullptr;
    }
    for (const auto& t : def->tiers) {
        if (t.tier == tier) {
            return &t;
        }
    }
    return nullptr;
}

} // namespace

Dictionary WroughtwildSim::equipment() const {
    Dictionary d;
    if (!require_loaded("equipment")) {
        return d;
    }
    for (const auto& [slot, item] : equipment_.slots) {
        Dictionary entry;
        entry["base_id"] = to_godot(item.baseId);
        const auto* base = tuning_->items.findBase(item.baseId);
        entry["display_name"] = to_godot(base ? base->displayName : item.baseId);
        entry["armour"] = wroughtwild::items::propertyTotal(item, "armour");
        entry["fire_resistance"] = wroughtwild::items::propertyTotal(item, "fire_resistance");
        entry["max_life"] = wroughtwild::items::propertyTotal(item, "max_life");
        entry["area_size"] = wroughtwild::items::propertyTotal(item, "area_size");
        Array rolled;
        for (const auto& r : item.rolledProperties) {
            Dictionary p;
            p["property"] = to_godot(r.propertyId);
            p["tier"] = r.tier;
            p["value"] = r.value;
            rolled.push_back(p);
        }
        entry["rolled"] = rolled;
        d[to_godot(slot)] = entry;
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
    auto worn = equipment_.slots.find(kChestSlot);
    if (worn != equipment_.slots.end()) {
        player_->inventory[worn->second.baseId] += 1;
    }
    wroughtwild::items::ItemInstance item;
    item.baseId = base->id;
    item.implicitProperties = base->implicitProperties;
    equipment_.slots[kChestSlot] = item;
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
    wroughtwild::economy::add(player_->inventory, converted);
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

Dictionary WroughtwildSim::enemy_loot(const String& enemy_id, int seed) {
    Dictionary d;
    if (!require_loaded("enemy_loot")) {
        return d;
    }
    const auto drops = wroughtwild::loot::rollEnemyLoot(
        tuning_->world, to_std(enemy_id), static_cast<uint64_t>(seed));
    for (const auto& [item, count] : drops) {
        d[to_godot(item)] = count;
    }
    return d;
}

Dictionary WroughtwildSim::world_map(int seed) {
    Dictionary d;
    if (!require_loaded("world_map")) {
        return d;
    }
    const auto map = wroughtwild::worldgen::generate(*tuning_, static_cast<uint64_t>(seed));

    d["seed"] = seed;
    d["width"] = map.width;
    d["height"] = map.height;
    d["cell_size"] = map.cellSize;

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
        n["z"] = node.z;
        n["material_family"] = to_godot(typeIt->second.materialFamily);
        n["display_name"] = to_godot(typeIt->second.displayName);
        n["units"] = typeIt->second.units;
        n["units_per_harvest"] = typeIt->second.unitsPerHarvest;
        n["visual"] = to_godot(typeIt->second.visual);
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
        p["z"] = pack.z;
        packs.push_back(p);
    }
    d["packs"] = packs;

    d["spawn_x"] = map.spawnX;
    d["spawn_z"] = map.spawnZ;
    d["gate_x"] = map.gateX;
    d["gate_z"] = map.gateZ;
    return d;
}

} // namespace godot
