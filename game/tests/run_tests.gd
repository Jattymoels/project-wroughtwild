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
	_test_prop_mesh()
	_test_biome_mood()
	_test_scene_instantiation()
	_test_sim_extension()
	_test_sandpit_extension()

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
	check(WroughtwildGrid.placement_cell_center(Vector3(0.5, 0.5, 0.5), Vector3.UP, grid) == Vector3(0.5, 0.5, 0.5),
		"grid: the top of a half-height slab still targets its own cell")
	check(WroughtwildGrid.placement_cell_center(Vector3(0.5, 0.5, 0.0), Vector3.BACK, grid) == Vector3(0.5, 0.5, 0.5),
		"grid: a face-anchored panel's inner side targets its own cell")

	# Anchored shapes sit flush to the face or corner their rotation selects.
	var panel := Vector3(1.0, 1.0, 0.25)
	check(WroughtwildGrid.shape_offset(panel, &"face", 0.0, grid).is_equal_approx(Vector3(0.0, 0.0, -0.375)),
		"grid: face anchor presses a panel against the -z face")
	check(WroughtwildGrid.shape_offset(panel, &"face", PI / 2.0, grid).is_equal_approx(Vector3(-0.375, 0.0, 0.0)),
		"grid: a quarter turn moves the panel to the -x face")
	check(WroughtwildGrid.shape_offset(Vector3(0.3, 1.0, 0.3), &"corner", 0.0, grid).is_equal_approx(Vector3(-0.35, 0.0, -0.35)),
		"grid: corner anchor tucks a pillar into the corner")
	check(WroughtwildGrid.shape_offset(Vector3(1.0, 0.5, 1.0), &"centre", 0.0, grid).is_equal_approx(Vector3(0.0, -0.25, 0.0)),
		"grid: short centred shapes rest on the cell floor")
	check(WroughtwildGrid.slot_id(&"face", 0.0) == &"face_0" and WroughtwildGrid.slot_id(&"face", 3.0 * PI / 2.0) == &"face_3",
		"grid: face slots follow the rotation step")
	check(WroughtwildGrid.slot_id(&"face", TAU - 1e-6) == &"face_0", "grid: a full turn wraps to the first face")
	check(WroughtwildGrid.slot_id(&"centre", PI) == &"centre", "grid: centred shapes ignore rotation for their slot")
	check(WroughtwildGrid.fills_cell(Vector3.ONE, grid) and not WroughtwildGrid.fills_cell(panel, grid),
		"grid: only a full-size shape fills its cell")
	check(not WroughtwildGrid.slots_conflict(&"face_0", false, &"face_1", false),
		"grid: panels on different faces share a cell")
	check(WroughtwildGrid.slots_conflict(&"face_0", false, &"face_0", false), "grid: the same face is taken once")
	check(WroughtwildGrid.slots_conflict(&"centre", true, &"face_2", false), "grid: a cube fills its cell")
	check(not WroughtwildGrid.slots_conflict(&"centre", false, &"corner_1", false),
		"grid: a slab floor and a corner pillar coexist")
	var offset := WroughtwildGrid.shape_offset(panel, &"face", PI / 2.0, grid)
	check(WroughtwildGrid.cell_of(Vector3(2.5, 3.5, -1.5) + offset, offset, grid) == Vector3i(2, 3, -2),
		"grid: cell recovered from an anchored position")


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


func _test_prop_mesh() -> void:
	# Procedural props (D-013): deterministic, faceted, palette-coloured.
	var a: ArrayMesh = PropMesh.build_tree(7)
	var b: ArrayMesh = PropMesh.build_tree(7)
	var c: ArrayMesh = PropMesh.build_tree(8)
	var a_verts: PackedVector3Array = a.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(a_verts.size() == 84 * 3, "props: tree is 84 flat facets (%d verts)" % a_verts.size())
	check(a_verts == b.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],
		"props: the same seed grows the same tree")
	check(a_verts != c.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],
		"props: different seeds grow different trees")
	check(PropMesh.build_boulder(3).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == 20 * 3,
		"props: boulder is 20 facets")
	var vein_colors: PackedColorArray = PropMesh.build_iron_vein(5).surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var has_rust := false
	for color in vein_colors:
		if color.r > color.b * 1.5:
			has_rust = true
	check(has_rust, "props: the iron vein carries rust facets")


func _test_biome_mood() -> void:
	# The art direction's contract (D-013): light drains toward danger.
	var meadow: Dictionary = BiomeMood.mood_for("meadow")
	var wastes: Dictionary = BiomeMood.mood_for("ember_wastes")
	var forest: Dictionary = BiomeMood.mood_for("forest")
	check(wastes["sun_energy"] < forest["sun_energy"]
		and forest["sun_energy"] <= BiomeMood.mood_for("rocky_hills")["sun_energy"]
		and BiomeMood.mood_for("rocky_hills")["sun_energy"] < meadow["sun_energy"],
		"art: sun energy orders safe > exposed > forest > wastes (D-013)")
	check(wastes["fog_density"] > forest["fog_density"]
		and forest["fog_density"] > meadow["fog_density"],
		"art: fog thickens toward danger")
	check(wastes["ambient"] < meadow["ambient"], "art: the wastes sit darker than safe country")
	check(BiomeMood.mood_for("no_such_biome") == meadow, "art: unknown biomes fall back to the safe mood")


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
	# Inputs alone are not enough any more: the forge burns fuel on top.
	var cold: Dictionary = sim.craft("smelt_iron")
	check(not cold["crafted"] and cold["failure"] == "missing_fuel",
		"sim: craft refused without fuel (%s)" % cold.get("failure"))
	sim.add_material("wood", int(recipe["fuel_cost"]))
	var result: Dictionary = sim.craft("smelt_iron")
	check(result["crafted"], "sim: craft succeeds with station, inputs and fuel")
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
	check(sim.combat_skill_ids().size() == 4, "combat: four prototype skills (frost orb joined)")
	check(sim.enemy("ember_whelp")["max_life"] == 30.0 and sim.enemy_ids().size() == 4, "combat: enemy view")
	check(sim.boss()["breath_damage"] == 42.0, "combat: boss view")
	var rt: Dictionary = sim.realtime()
	# D-012: dash is pure movement, so its invulnerability window is zero.
	check(rt["round_seconds"] > 0.0 and rt["behaviours"].has("fast")
		and rt["dash"]["invulnerable_seconds"] == 0.0
		and rt["behaviours"]["fast"]["give_up_distance_m"] > rt["behaviours"]["melee"]["give_up_distance_m"]
		and rt["horde"]["separation_radius_m"] > 0.0
		and rt["player"]["cone_degrees"] > 0.0,
		"combat: realtime tunables (D-012 horde fields present)")
	check(sim.combat_mods()["enemy_speed_multiplier"] == 1.0, "combat: no mods outside a run")
	check(absf(sim.mitigate(100.0, "physical") - 100.0) < 0.000001, "combat: no armour, no mitigation")

	# Skill grammar (grammar spike): the sim owns the sentence's numbers and
	# the engine only asks. Mods are tag-gated and toggle cleanly.
	check(sim.skill_mod_ids().size() == 3, "grammar: three spike mods loaded")
	check(sim.skill_mod("deep_frost")["applies_to_tags"].has("chill"), "grammar: mod view carries tags")
	check(sim.fork_count("prototype_frost_orb") == 1, "grammar: orb forks once bare")
	check(sim.fork_count("prototype_area_strike") == 0, "grammar: strike never forks (no projectile tag)")
	check(absf(sim.chill_applied("prototype_frost_orb", false) - 40.0) < 0.000001, "grammar: bare chill buildup")
	check(absf(sim.chill_applied("prototype_frost_orb", true) - 10.0) < 0.000001, "grammar: boss resists chill x0.25")
	sim.set_skill_mod_active("forked_lattice", true)
	sim.set_skill_mod_active("deep_frost", true)
	check(sim.fork_count("prototype_frost_orb") == 2, "grammar: Forked Lattice adds a fork")
	check(absf(sim.chill_applied("prototype_frost_orb", false) - 60.0) < 0.000001, "grammar: Deep Frost is 50 percent increased chill")
	check(absf(sim.fork_damage_fraction("prototype_frost_orb", 1) - 0.7) < 0.000001, "grammar: fork generation decays damage")
	var shatter: Dictionary = sim.shatter_for("prototype_area_strike")
	check(shatter["enabled"] and shatter["executes_frozen"], "grammar: area strike carries the shatter hook")
	check(not sim.shatter_for("prototype_heavy_strike")["enabled"], "grammar: heavy strike does not shatter")
	var bare_radius: float = shatter["nova_radius_m"]
	sim.set_skill_mod_active("wide_shatter", true)
	check(absf(sim.shatter_for("prototype_area_strike")["nova_radius_m"] - bare_radius * 1.4) < 0.000001,
		"grammar: Wide Shatter is 40 percent increased nova radius")
	for mod_id in sim.skill_mod_ids():
		sim.set_skill_mod_active(mod_id, false)
	check(not sim.skill_mod_active("deep_frost"), "grammar: mods toggle back off")

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

func _test_sandpit_extension() -> void:
	# Wave 1 surface: worldgen, loot, kits, fuel and currency routing.
	if not ClassDB.class_exists(&"WroughtwildSim"):
		return
	var sim: RefCounted = ClassDB.instantiate(&"WroughtwildSim")
	sim.load_tuning(load("res://scripts/sim.gd").get_tuning_directory())

	var a: Dictionary = sim.world_map(5)
	var b: Dictionary = sim.world_map(5)
	check(not a.is_empty() and a["width"] > 0, "sandpit: world map generates")
	check(a["heights"] == b["heights"] and a["spawn_x"] == b["spawn_x"]
		and a["nodes"].size() == b["nodes"].size(), "sandpit: world map deterministic per seed")
	var gate_dx: float = float(a["gate_x"] - a["spawn_x"])
	var gate_dz: float = float(a["gate_z"] - a["spawn_z"])
	check(sqrt(gate_dx * gate_dx + gate_dz * gate_dz) >= 45.0, "sandpit: gate far from spawn")
	check(a["nodes"].size() > 0 and a["packs"].size() > 0, "sandpit: nodes and packs placed")
	check(a["biome_defs"].size() == 4, "sandpit: four biomes defined")

	check(sim.kit_station("workbench_kit") == "workbench", "sandpit: workbench kit maps to workbench")
	check(sim.kit_station("forge_kit") == "forge_basic", "sandpit: forge kit maps to the forge")
	check(sim.kit_station("wood") == "", "sandpit: non-kits map to nothing")
	check(sim.kit_item_ids().size() == 2, "sandpit: two kits exist")

	var drops_a: Dictionary = sim.enemy_loot("stone_husk", 77)
	var drops_b: Dictionary = sim.enemy_loot("stone_husk", 77)
	check(drops_a == drops_b, "sandpit: loot deterministic per seed")
	check(drops_a.get("stone", 0) >= 2, "sandpit: husks always pay stone")

	# Currency loot lands in the purse, material loot in the pack.
	var before: int = sim.currency_count("trade_currency")
	sim.add_materials({"trade_currency": 3, "stone": 2})
	check(sim.currency_count("trade_currency") == before + 3, "sandpit: currency loot routed to the purse")
	check(sim.material_count("stone") == 2, "sandpit: material loot routed to the pack")
	check(sim.inventory().get("trade_currency", 0) == 0, "sandpit: currency never sits in the pack")

	# Hand-crafting through the extension: the start-with-nothing rung.
	var kit_recipe: Dictionary = sim.recipe("workbench_kit")
	check(kit_recipe["hand_craftable"] and kit_recipe["station_available"],
		"sandpit: workbench kit is hand-craftable anywhere")
	sim.add_material("wood", 8)
	check(sim.craft("workbench_kit")["crafted"], "sandpit: kit crafts with no station")
	check(sim.material_count("workbench_kit") == 1, "sandpit: kit in the pack")
	check(sim.fuel_value_held() == 0, "sandpit: fuel meter reads an empty pack")
	sim.add_material("wood", 2)
	sim.add_material("charcoal", 1)
	check(sim.fuel_value_held() == 6, "sandpit: fuel meter sums wood and charcoal values")
