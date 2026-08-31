extends SceneTree
## Headless unit tests, run with:
##   godot --headless --path game --script tests/run_tests.gd
## Exits non-zero on any failure. Frame-dependent behaviour (physics,
## placement raycasts) is covered by tests/integration.tscn instead.

var failures := 0
var checks := 0


func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: %s" % label)


func _initialize() -> void:
	_test_grid()
	_test_inventory()
	_test_sim_gateway()
	_test_resource_node()
	_test_scene_instantiation()
	_test_sim_extension()

	print("%d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_grid() -> void:
	var grid := 1.0
	check(WroughtwildGrid.snap_to_cell_center(Vector3(0.1, 0.2, 0.3), grid) == Vector3(0.5, 0.5, 0.5),
		"grid: origin cell")
	check(WroughtwildGrid.snap_to_cell_center(Vector3(-0.1, -1.7, 0.0), grid) == Vector3(-0.5, -1.5, 0.5),
		"grid: negative coordinates")
	check(WroughtwildGrid.snap_to_cell_center(Vector3(0.5, 0.5, 0.5), grid) == Vector3(0.5, 0.5, 0.5),
		"grid: snapping is idempotent")
	check(WroughtwildGrid.placement_cell_center(Vector3(0.5, 1.0, 0.5), Vector3.UP, grid) == Vector3(0.5, 1.5, 0.5),
		"grid: face placement selects adjacent cell")


func _test_inventory() -> void:
	var inventory: WroughtwildInventory = WroughtwildInventory.new()
	check(inventory.get_count(&"wood") == 0, "inventory: starts empty")
	inventory.add_material(&"wood", 5)
	check(inventory.get_count(&"wood") == 5, "inventory: add")
	check(not inventory.consume_material(&"wood", 6), "inventory: refuses overdraw")
	check(inventory.get_count(&"wood") == 5, "inventory: overdraw consumes nothing")
	check(inventory.consume_material(&"wood", 3), "inventory: consume")
	check(inventory.get_count(&"wood") == 2, "inventory: count after consume")
	inventory.add_material(&"wood", -4)
	check(inventory.get_count(&"wood") == 2, "inventory: negative add ignored")
	inventory.free()


func _test_sim_gateway() -> void:
	# The autoload is not instantiated in --script mode; test the script directly.
	var gateway: Node = load("res://scripts/sim.gd").new()
	check(gateway.loaded, "sim gateway: tuning loads from the repo checkout")
	check(gateway.sim.recipe_ids().has("smelt_iron"), "sim gateway: crafting recipes visible")
	check(gateway.sim.shape_ids().has("cube"), "sim gateway: construction shapes visible")
	check(gateway.sim.grid_size() > 0.0 and gateway.sim.placement_range() > gateway.sim.grid_size(),
		"sim gateway: grid size and placement range come from construction.json")
	check(absf(gateway.sim.salvage_return_fraction() - 0.5) < 0.000001, "sim gateway: salvage fraction read")
	gateway.free()


func _test_resource_node() -> void:
	var node: ResourceNode = load("res://scenes/resource_node.tscn").instantiate()
	node.remaining_units = 5
	node.units_per_harvest = 2
	check(node.harvest() == 2, "resource: harvest grants units_per_harvest")
	check(node.remaining_units == 3, "resource: units deplete")
	check(node.harvest() == 2, "resource: second harvest")
	check(node.harvest() == 1, "resource: final partial harvest")
	check(node.harvest() == 0, "resource: depleted node grants nothing")
	node.free()


func _test_scene_instantiation() -> void:
	# The whole spike scene must instantiate without errors. @onready wiring
	# is not exercised here (ready is deferred in --script mode); the
	# integration test covers it inside a running tree.
	var scene: Node = load("res://scenes/spike_valley.tscn").instantiate()
	get_root().add_child(scene)
	var player: WroughtwildPlayer = scene.get_node("Player")
	check(player != null, "scene: player present")
	check(player.get_node("Placement") is GridPlacement, "scene: placement component present")
	check(player.get_node("Inventory") is WroughtwildInventory, "scene: inventory component present")
	check(scene.get_node("IronNode").material_family == &"iron_ore",
		"scene: per-instance material family override applies")
	check(scene.get_node("WoodNode1").material_family == &"wood",
		"scene: default material family")
	check(scene.get_node("ForgeSite") is StationSite, "scene: forge site present")
	check(scene.get_node("MineBoard") is OrderBoard, "scene: mine order board present")
	check(scene.get_node("TrialGate") is TrialGate and scene.get_node("TrialArena") is TrialArena,
		"scene: trial gate and arena present")
	get_root().remove_child(scene)
	scene.free()


func _test_sim_extension() -> void:
	# The rules library reached through the GDExtension in
	# game/extensions/wroughtwild_sim. These checks prove the door works; the
	# rules themselves are regression-tested in tests/sim.
	if not ClassDB.class_exists(&"WroughtwildSim"):
		check(false, "sim: WroughtwildSim extension not loaded (build game/extensions/wroughtwild_sim first)")
		return
	var sim: RefCounted = ClassDB.instantiate(&"WroughtwildSim")
	var tuning_dir: String = load("res://scripts/sim.gd").get_tuning_directory()
	check(sim.load_tuning(tuning_dir), "sim: tuning loads through the sim library (%s)" % sim.last_error())
	check(sim.recipe_ids().has("smelt_iron"), "sim: recipes visible")
	check(absf(sim.salvage_return_fraction() - 0.5) < 0.000001, "sim: salvage fraction agrees with GDScript loader")

	var blocked: Dictionary = sim.craft("smelt_iron")
	check(not blocked["crafted"] and blocked["failure"] == "station_unavailable",
		"sim: craft refused without station (%s)" % blocked.get("failure"))
	sim.add_station("forge_basic")
	blocked = sim.craft("smelt_iron")
	check(not blocked["crafted"] and blocked["failure"] == "missing_inputs",
		"sim: craft refused without inputs (%s)" % blocked.get("failure"))

	var recipe: Dictionary = sim.recipe("smelt_iron")
	for material in recipe["inputs"]:
		sim.add_material(material, recipe["inputs"][material])
	var result: Dictionary = sim.craft("smelt_iron")
	check(result["crafted"], "sim: craft succeeds with station and inputs")
	check(sim.material_count("iron_ingot") == 1 and sim.material_count("iron_ore") == 0,
		"sim: inputs consumed and output added by the sim rule")
	check(sim.skill_xp("blacksmithing") == recipe["base_skill_xp"], "sim: skill XP granted by the sim rule")
	check(sim.craft("no_such_recipe")["failure"] == "unknown_recipe", "sim: unknown recipe reported")

	# Construction draws on the same inventory as crafting.
	var cost: int = sim.shape_material_cost("cube")
	check(cost > 0, "sim: cube shape has a material cost")
	check(not sim.can_afford_placement("cube", "wood"), "sim: cannot place with no wood")
	sim.add_material("wood", cost * 2)
	check(sim.pay_placement("cube", "wood"), "sim: placement paid from the family")
	check(sim.material_count("wood") == cost, "sim: placement consumed one shape's cost")
	var refund: int = sim.refund_removal("cube", "wood")
	check(refund == int(floorf(cost * sim.removal_refund_fraction())), "sim: refund follows removal_refund_fraction")
	check(sim.material_count("wood") == cost + refund, "sim: refund returned to the family")
	check(not sim.consume_material("wood", 999), "sim: consume refuses overdraw")
	check(sim.consume_material("wood", 1), "sim: consume succeeds within holdings")

	# Stations, orders and skill views used by the HUD and work panel.
	var forge: Dictionary = sim.station("forge_basic")
	check(forge.get("display_name", "") == "Basic Forge" and forge["available"], "sim: station view (already built above)")
	check(not sim.can_build_station("forge_basic"), "sim: built station not buildable again")
	check(sim.station_ids().has("forge_improved") and not sim.can_build_station("forge_improved"),
		"sim: upgrade unaffordable before the order pays out")
	var progress: Dictionary = sim.skill_progress("blacksmithing")
	check(progress["level"] == 1 and progress["next_level_xp"] == 50, "sim: skill progress view")
	check(sim.recipe_feeds_open_order("iron_fittings"), "sim: fittings feed the open mine order")
	var order: Dictionary = sim.order("reinforce_old_mine")
	check(order["required_outputs"].get("iron_fittings", 0) == 24 and not order["fulfilled"], "sim: order view")
	check(sim.fulfill_order("reinforce_old_mine")["missing_outputs"], "sim: order refused without fittings")
	sim.add_material("iron_fittings", 24)
	check(sim.fulfill_order("reinforce_old_mine")["fulfilled"], "sim: order fulfilled")
	check(sim.currency_count("trade_currency") == 40 and sim.inventory().get("iron_fittings", 0) == 0,
		"sim: order paid currency and consumed fittings")
	check(sim.skill_progress("blacksmithing")["level"] >= 2, "sim: order XP reward levelled Blacksmithing")
	check(sim.fulfill_order("reinforce_old_mine")["already_fulfilled"], "sim: second delivery refused")

	# Rules state round-trips through the sim's own save schema.
	var snapshot: String = sim.export_json()
	var xp_before: int = sim.skill_xp("blacksmithing")
	sim.add_material("wood", 50)
	check(sim.import_json(snapshot), "save: sim JSON imports (%s)" % sim.last_error())
	check(sim.material_count("wood") != 50 + cost, "save: import replaced the mutated inventory")
	check(sim.skill_xp("blacksmithing") == xp_before and sim.has_station("forge_basic")
		and sim.order_fulfilled("reinforce_old_mine"), "save: skills, stations and orders round-trip")
	check(not sim.import_json("{not json"), "save: malformed text rejected")
	check(sim.has_station("forge_basic"), "save: rejected import leaves state untouched")

	# Combat numbers (ADR-0003): everything damage-related is asked of the sim.
	var stats: Dictionary = sim.derived_stats()
	check(stats["max_life"] == 100.0 and stats["armour"] == 0.0, "combat: bare derived stats")
	var heavy: Dictionary = sim.combat_skill("prototype_heavy_strike")
	check(heavy["base_damage"] == 28.0 and heavy["tags"].has("single_target"), "combat: skill view")
	check(sim.combat_skill_ids().size() == 3, "combat: three prototype skills")
	check(sim.enemy("ember_whelp")["max_life"] == 30.0 and sim.enemy_ids().size() == 3, "combat: enemy view")
	check(sim.boss()["breath_damage"] == 42.0, "combat: boss view")
	var rt: Dictionary = sim.realtime()
	check(rt["round_seconds"] > 0.0 and rt["behaviours"].has("fast") and rt["dash"]["invulnerable_seconds"] > 0.0,
		"combat: realtime tunables")
	check(sim.combat_mods()["enemy_speed_multiplier"] == 1.0, "combat: no mods outside a run")
	check(absf(sim.mitigate(100.0, "physical") - 100.0) < 0.000001, "combat: no armour, no mitigation")

	sim.begin_fight(42)
	var first: Array = []
	for i in 5:
		first.append(sim.player_hit_damage("prototype_heavy_strike", false))
	sim.begin_fight(42)
	var replay_ok := true
	for i in 5:
		if sim.player_hit_damage("prototype_heavy_strike", false) != first[i]:
			replay_ok = false
	check(replay_ok, "combat: hit stream replays per seed")
	check(first[0] >= 28.0 * 0.9 and first[0] <= 28.0 * 1.1, "combat: hit inside variance band")
	var fire: float = sim.enemy_hit_damage(40.0, "fire")
	check(fire >= 36.0 and fire <= 44.0, "combat: unresisted fire lands in band")

	# Gathering sites and the open-world death contract's inventory drop.
	var mine: Dictionary = sim.gather_site("old_mine")
	check(mine["ambush_enemies"].size() == 2 and mine["ambush_removed_by_world_effect"] == "old_mine_reinforced",
		"world: mine ambush data from world.json")
	sim.add_material("wood", 3)
	var dropped: Dictionary = sim.drop_inventory()
	check(dropped.get("wood", 0) >= 3 and sim.inventory().is_empty(), "death: drop empties carried materials")
	sim.add_materials(dropped)
	check(sim.material_count("wood") == dropped["wood"], "death: recovered pack restores them")

	# Trial run driven the way the engine will drive it: begin room, fight
	# elsewhere, resolve. The sim owns the deposit, offers, loot and contract.
	var wood_deposit: int = sim.material_count("wood")
	check(sim.trial_start(99), "trial: run opens")
	check(not sim.trial_start(1), "trial: only one run at a time")
	check(sim.material_count("wood") == 0, "trial: carried materials deposited at the gate")
	var stage: Dictionary = sim.trial_stage()
	check(stage["index"] == 0 and stage["choices"].size() == 2, "trial: first stage offers two doors")
	var room: Dictionary = sim.trial_begin_room(0)
	check(room["started"] and room["encounter"].size() == 2 and room["seed"] != 0, "trial: room begun with an encounter and seed")
	check(sim.trial_stage()["room_in_progress"], "trial: room in progress")
	var outcome: Dictionary = sim.trial_resolve_room(true)
	check(outcome["reward_type"] == "boon_offer" and outcome["boon_offer"].size() >= 1, "trial: boon offer after victory")
	check(sim.trial_accept_boon(outcome["boon_offer"][0]["id"]), "trial: boon accepted")
	check(sim.trial_run_state()["boons"].size() == 1, "trial: run state shows the boon")
	check(sim.combat_mods() != {} and (sim.combat_mods()["repeat_hit_count"] > 0 or sim.combat_mods()["isolated_damage_multiplier"] > 1.0),
		"trial: accepted boon changes combat mods")
	check(sim.trial_begin_room(1)["started"], "trial: materials room begun")
	outcome = sim.trial_resolve_room(true)
	check(outcome["reward_type"] == "materials" and outcome["materials"].get("iron_ingot", 0) >= 4, "trial: materials paid into run loot")
	check(sim.trial_begin_room(0)["started"] and sim.trial_resolve_room(true)["catalyst_recovered"], "trial: catalyst recovered")
	check(sim.trial_stage()["can_bank_and_exit"], "trial: bank-out point reached")
	check(sim.trial_bank_and_exit() and sim.trial_finished() and not sim.trial_player_died(), "trial: banked out")
	check(sim.material_count("wood") == wood_deposit, "trial: deposit restored after banking")
	check(sim.material_count("ember_catalyst") == 1 and sim.material_count("iron_ingot") >= 4, "trial: loot banked")
	check(sim.trial_run_state()["boons"].is_empty(), "trial: boons cleared at run end")
	check(sim.trial_end() and not sim.trial_active(), "trial: run closed")

	# Death contract through the host path.
	check(sim.trial_start(5) and sim.trial_begin_room(0)["started"], "trial: second run begun")
	outcome = sim.trial_resolve_room(false)
	check(outcome["died"] and outcome["finished"], "trial: host-reported defeat ends the run")
	check(sim.material_count("wood") == wood_deposit and sim.material_count("ember_catalyst") == 1,
		"trial: deposit and earlier catalyst survive death")
	check(sim.trial_end(), "trial: failed run closed")

	# Shapes: the slab waits on the boss kill; sizes come from data.
	check(sim.shape("cube")["size"] == Vector3.ONE and sim.shape("cube")["unlocked"], "shape: cube view")
	check(not sim.shape_unlocked("stonecut_slab"), "shape: slab locked until the completion unlock")
	check(sim.shape_ids().size() >= 6 and sim.shape_unlocked("wall_panel") and sim.shape("wall_panel")["size"].z < 0.5,
		"shape: six-shape set with sizes from data")

	# Equipment and tempering (the catalyst banked above is still held).
	check(sim.equipment().is_empty(), "gear: nothing worn")
	check(not sim.equip_from_inventory("iron_chest_armour"), "gear: cannot wear armour you do not carry")
	sim.add_material("iron_chest_armour", 1)
	check(sim.equip_from_inventory("iron_chest_armour") and sim.equipment()["chest"]["armour"] == 20.0,
		"gear: worn armour shows its implicit armour")
	check(sim.derived_stats()["armour"] == 20.0 and sim.material_count("iron_chest_armour") == 0,
		"gear: derived stats include the worn piece and the pack is lighter")
	check(sim.temper_basic()["reason"] == "station_unavailable", "temper: quench needs a forge that supports basic_temper")
	sim.add_material("iron_fittings", 6)
	check(sim.build_station("forge_improved"), "temper: forge upgraded with the order's pay")
	var quench: Dictionary = sim.temper_basic()
	check(quench["applied"] and absf(quench["value"] - 11.5) < 0.001, "temper: quench sets the tier-1 midpoint")
	check(absf(sim.derived_stats()["fire_resistance_percent"] - 11.5) < 0.001, "temper: resistance flows into derived stats")
	check(sim.mitigate(100.0, "fire") < 100.0 and absf(sim.mitigate(100.0, "physical") - 100.0 / (1.0 + 20.0 / 100.0)) < 0.5,
		"temper: fire and armour both mitigate now")
	var process: Dictionary = sim.catalyst_process("ember_catalyst_tempering")
	check(process["catalyst_held"] == 1 and process["tier_minimum"] == 25.0 and absf(process["floor_at_skill"] - 32.5) < 0.001,
		"temper: catalyst process explained before use")
	var refused: Dictionary = sim.temper_with_catalyst("ember_catalyst_tempering")
	check(refused["reason"] == "skill_too_low" and sim.material_count("ember_catalyst") == 1,
		"temper: refused below the skill floor without consuming the catalyst")
	var snapshot_with_gear: String = sim.export_json()
	check(snapshot_with_gear.find("fire_resistance") >= 0, "gear: tempered armour is in the save schema")
