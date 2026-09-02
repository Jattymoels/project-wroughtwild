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
	_test_ui_theme()
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


func _test_ui_theme() -> void:
	check(UiTheme.theme() == UiTheme.theme(), "ui: one shared theme")
	check(UiTheme.theme().has_stylebox("panel", "PanelContainer") and UiTheme.theme().has_stylebox("disabled", "Button"),
		"ui: theme styles panels and buttons")
	check(UiTheme.family_colour("wood") == UiTheme.BARK and UiTheme.family_colour("forge_kit") == UiTheme.FROST,
		"ui: material swatches follow the family")
	check(UiTheme.family_colour("ember_catalyst") == UiTheme.EMBER and UiTheme.family_colour("unknown_thing") == UiTheme.MUTED,
		"ui: catalysts glow ember, unknowns stay muted")
	check(UiTheme.card(true).border_color.a > UiTheme.card(false).border_color.a, "ui: available cards have the brighter edge")
	var root := Control.new()
	var stop := Button.new()
	root.add_child(stop)
	UiTheme.ignore_mouse(root)
	check(root.mouse_filter == Control.MOUSE_FILTER_IGNORE and stop.mouse_filter == Control.MOUSE_FILTER_IGNORE,
		"ui: ignore_mouse reaches every descendant")
	root.free()


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
	check(heavy["delivery"] == "strike" and heavy["starting"], "combat: skill view carries delivery and starting (D-016)")
	check(sim.combat_skill_ids().size() == 7, "combat: seven skills defined (three arrive as pages)")
	check(sim.enemy("ember_whelp")["max_life"] == 30.0 and sim.enemy_ids().size() == 6,
		"combat: enemy view (shrieker and gloom crawler joined)")
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
	check(sim.skill_mod_ids().size() >= 3 and sim.skill_mod_ids().has("deep_frost"), "grammar: debug toggles come from the item modifier pool")
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
	check(not shatter["executes_boss"], "grammar: shatter novas a frozen boss, never executes it")
	check(sim.shatter_for("prototype_heavy_strike")["enabled"], "grammar: every attack shatters (trigger by tag, D-016)")
	check(not sim.shatter_for("prototype_frost_orb")["enabled"], "grammar: cold spells set up, attacks cash in")
	var bare_radius: float = shatter["nova_radius_m"]
	sim.set_skill_mod_active("wide_shatter", true)
	check(absf(sim.shatter_for("prototype_area_strike")["nova_radius_m"] - bare_radius * 1.4) < 0.000001,
		"grammar: Wide Shatter is 40 percent increased nova radius")
	for mod_id in sim.skill_mod_ids():
		sim.set_skill_mod_active(mod_id, false)
	check(not sim.skill_mod_active("deep_frost"), "grammar: mods toggle back off")

	# D-016 statuses: ignite and bleed sit beside chill, resolved by tag.
	check(absf(sim.ignite_applied("prototype_ember_bolt", false) - 45.0) < 0.000001, "grammar: bolt ignite buildup")
	check(absf(sim.ignite_applied("prototype_ember_bolt", true) - 11.25) < 0.000001, "grammar: bosses resist ignite x0.25")
	check(absf(sim.bleed_applied("prototype_rend", false) - 70.0) < 0.000001, "grammar: rend bleed buildup")
	check(sim.ignite_status()["damage_per_s"] == 6.0 and sim.ignite_status()["duration_s"] == 4.0,
		"grammar: ignite DoT rules exposed")
	check(sim.bleed_status()["moving_multiplier"] == 3.0, "grammar: bleed punishes walking")
	var prolif: Dictionary = sim.proliferate_for()
	check(prolif["enabled"] and prolif["radius_m"] == 3.0 and prolif["spread_buildup"] == 100.0,
		"grammar: proliferate hook exposed")
	check(absf(prolif["spread_buildup_boss"] - 25.0) < 0.000001, "grammar: proliferate respects boss resistance")

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

	# D-014 itemisation: bases, rarities, pack items, gear-driven grammar.
	check(sim.slot_ids().size() == 3 and sim.item_base_ids().has("frost_sceptre"), "items: slots and bases from data")
	check(sim.modifier("deep_frost")["applies_to_tags"].has("chill") and sim.modifier("max_life")["self"], "items: modifier views")
	# The trial run above banked the gear its rooms dropped, so the pack is not empty.
	var before: int = sim.pack_items().size()
	check(before == 2, "items: the trial's loot room and shrine banked one piece of gear each")
	var index: int = sim.roll_item_into_pack("frost_sceptre", "keen", 1, 7)
	check(index == before and sim.pack_items().size() == before + 1 and sim.pack_items()[index]["rarity"] == "keen", "items: a keen sceptre rolled into the pack")
	var mods: Array = sim.pack_items()[index]["mods"]
	check(mods.size() >= 2 and String(mods[0]["sentence"]).begins_with("+1 Forks"), "items: the item card lists the implicit fork first")
	check(sim.equip_pack_item(index) and sim.equipment().has("weapon") and sim.pack_items().size() == before, "items: wearing from the pack fills the weapon slot")
	check(sim.fork_count("prototype_frost_orb") == 2, "items: the worn sceptre forks the orb")
	check(sim.active_modifiers().size() >= 2, "items: active modifiers list the worn gear")
	check(sim.unequip("weapon") and sim.pack_items().size() == before + 1 and not sim.equipment().has("weapon"), "items: taking it off returns it to the pack with its modifiers")
	check(sim.fork_count("prototype_frost_orb") == 1, "items: bare again")
	check(absf(sim.skill_cooldown_seconds("prototype_heavy_strike") - 1.4) < 0.000001, "items: cooldown view matches skills.json bare")
	check(sim.export_json().find("pack_items") >= 0, "items: pack items are in the save schema")
	check(sim.roll_item_into_pack("no_such_base", "keen", 1, 1) == -1 and sim.pack_items().size() == before + 1, "items: unknown bases roll nothing")

	# D-016 loadout: skills are found, not worn. The starting four fill the
	# bar; pages teach the rest; gear only ever scales skills by tag.
	check(sim.skill_bar_size() == 4 and sim.skill_bar().size() == 4, "loadout: four bar slots")
	check(sim.known_skill_ids().size() == 4 and sim.knows_skill("prototype_dash"), "loadout: the starting four are known")
	check(sim.skill_bar()[0] == "prototype_area_strike" and sim.skill_bar()[3] == "prototype_dash",
		"loadout: starting skills fill the bar in data order")
	check(not sim.knows_skill("prototype_ember_bolt"), "loadout: page skills start unknown")
	check(not sim.set_bar_slot(0, "prototype_ember_bolt"), "loadout: cannot slot a skill you do not know")
	check(sim.learn_skill("prototype_ember_bolt") and sim.knows_skill("prototype_ember_bolt"), "loadout: a page teaches the skill")
	check(not sim.learn_skill("prototype_ember_bolt"), "loadout: relearning refused")
	check(sim.set_bar_slot(1, "prototype_ember_bolt") and sim.skill_bar()[1] == "prototype_ember_bolt",
		"loadout: a learned skill takes slot 2")
	check(sim.set_bar_slot(2, "prototype_ember_bolt") and sim.skill_bar()[2] == "prototype_ember_bolt"
		and sim.skill_bar()[1] == "", "loadout: one key per skill - moving it vacates the old slot")
	check(sim.player_build_tags().has("fire"), "loadout: build tags follow what the bar holds")
	var loadout_snapshot: String = sim.export_json()
	check(loadout_snapshot.find("known_skills") >= 0, "loadout: known skills in the save schema")
	sim.set_bar_slot(2, "")
	check(sim.import_json(loadout_snapshot) and sim.skill_bar()[2] == "prototype_ember_bolt",
		"loadout: the bar round-trips through the save")

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
	check(sqrt(gate_dx * gate_dx + gate_dz * gate_dz) >= 70.0, "sandpit: gate far from spawn")
	check(a["nodes"].size() > 0 and a["packs"].size() > 0, "sandpit: nodes and packs placed")
	check(a["biome_defs"].size() == 4, "sandpit: four biomes defined")

	# Wave 3 world slice 1: the world is a 3D block field with caves.
	var blocks: PackedByteArray = a["blocks"]
	check(int(a["depth"]) > 0 and blocks.size() == int(a["width"]) * int(a["height"]) * int(a["depth"]),
		"sandpit: 3D block field sized to the map")
	check(blocks[0] == 4, "sandpit: bedrock floors the first column")
	var heights: PackedInt32Array = a["heights"]
	var underground := false
	for node in a["nodes"]:
		if int(node["y"]) < heights[int(node["z"]) * int(a["width"]) + int(node["x"])]:
			underground = true
	check(underground, "sandpit: some nodes live on cave floors")
	var mesh: Array = sim.world_mesh(5, 16)
	check(mesh.size() == ceili(int(a["width"]) / 16.0) * ceili(int(a["height"]) / 16.0),
		"sandpit: world mesh chunks cover the map")
	var chunk: Dictionary = mesh[0]
	check(not (chunk["faces"] as PackedVector3Array).is_empty()
		and not (chunk["kinds"] as Dictionary).is_empty(),
		"sandpit: chunks carry visible blocks and collision faces")

	# Digging (Wave 3 slice 2): rules from the sim, holes in the terrain,
	# the save restoring the world's exact set of holes.
	var sx: int = a["spawn_x"]
	var sz: int = a["spawn_z"]
	var sh: int = heights[sz * int(a["width"]) + sx]
	var removed := PackedInt32Array([sx, sh - 1, sz])
	var patched: Dictionary = sim.world_mesh_chunk(5, 16, sx - sx % 16, sz - sz % 16, removed)
	var centre := Vector3(sx + 0.5, sh - 1 + 0.5, sz + 0.5)
	var still_there := false
	for kind in patched["kinds"]:
		if (patched["kinds"][kind] as PackedVector3Array).has(centre):
			still_there = true
	check(not still_there, "dig: world_mesh_chunk treats removed blocks as air")

	var terrain := Terrain.new()
	get_root().add_child(terrain)
	terrain.build(sim, 5)
	check(terrain.chunks.size() == mesh.size(), "dig: terrain builds its chunks")
	check(terrain.block_rules.has("stone") and not terrain.block_rules["bedrock"]["breakable"],
		"dig: block rules arrive from the sim")
	check(terrain.kind_at(sx, sh - 1, sz) == "surface", "dig: spawn column crowned by turf")
	check(terrain.break_block(sx, sh - 1, sz) == "surface", "dig: the turf digs out")
	check(terrain.block_at(sx, sh - 1, sz) == 0 and terrain.broken.size() == 1, "dig: hole recorded")
	check(terrain.kind_at(sx, sh - 2, sz) == "dirt", "dig: dirt under the turf")
	check(terrain.break_block(sx, 0, sz) == "" and terrain.block_at(sx, 0, sz) == 4,
		"dig: bedrock refuses to break")
	var saved_holes: Array = []
	for v in terrain.broken:
		saved_holes.append([v.x, v.y, v.z])
	check(terrain.break_block(sx, sh - 2, sz) == "dirt" and terrain.broken.size() == 2,
		"dig: digging deeper")
	terrain.apply_broken_blocks(saved_holes)
	check(terrain.broken.size() == 1 and terrain.block_at(sx, sh - 2, sz) != 0
		and terrain.block_at(sx, sh - 1, sz) == 0,
		"dig: a save's holes restore exactly (dug-since filled back)")
	terrain.queue_free()

	# Wave 3 elites through the binding: views, crowned packs, elite loot.
	check(sim.elite_modifier_ids().size() == 4, "elites: four modifiers exposed")
	var unfreezable: Dictionary = sim.elite_modifier("unfreezable")
	check(unfreezable["display_name"] == "Unfreezable" and unfreezable["immune_statuses"].has("chill"),
		"elites: modifier view carries immunities")
	check(sim.elite_modifier("nobody").is_empty(), "elites: unknown ids are empty")
	var crowned := 0
	var cave_dens := 0
	for pack in a["packs"]:
		if int(pack["elite_member"]) >= 0 and String(pack["elite_modifier"]) != "":
			crowned += 1
		if int(pack["y"]) < heights[int(pack["z"]) * int(a["width"]) + int(pack["x"])]:
			cave_dens += 1
	check(crowned > 0, "elites: the far rings crowned some packs")
	check(cave_dens > 0, "elites: cave packs den underground")
	var plain_husk: Dictionary = sim.enemy_loot("stone_husk", 99)
	var elite_husk: Dictionary = sim.enemy_loot("stone_husk", 99, "unfreezable")
	check(int(elite_husk.get("stone", 0)) > int(plain_husk.get("stone", 0)),
		"elites: the bounty pays more stone")

	check(sim.kit_station("workbench_kit") == "workbench", "sandpit: workbench kit maps to workbench")
	check(sim.kit_station("forge_kit") == "forge_basic", "sandpit: forge kit maps to the forge")
	check(sim.kit_station("wood") == "", "sandpit: non-kits map to nothing")
	check(sim.kit_item_ids().size() == 2, "sandpit: two kits exist")

	var drops_a: Dictionary = sim.enemy_loot("stone_husk", 77)
	var drops_b: Dictionary = sim.enemy_loot("stone_husk", 77)
	check(drops_a == drops_b, "sandpit: loot deterministic per seed")
	check(drops_a.get("stone", 0) >= 2, "sandpit: husks always pay stone")

	# D-016 loot: gear and pages ride independent streams off the kill seed,
	# and a gear pickup remembers only its kill - the claim re-rolls it.
	var gear_seed := -1
	for s in 400:
		if not sim.enemy_gear_loot("stone_husk", s).is_empty():
			gear_seed = s
			break
	check(gear_seed >= 0, "loot: a husk eventually drops gear")
	if gear_seed >= 0:
		var preview: Dictionary = sim.enemy_gear_loot("stone_husk", gear_seed)[0]
		check(preview["rarity"] == "keen" and int(preview["index"]) == -1, "loot: gear preview is keen and unbanked")
		var pack_before: int = sim.pack_items().size()
		var claimed: Array = sim.claim_enemy_gear("stone_husk", gear_seed)
		check(claimed.size() == 1 and sim.pack_items().size() == pack_before + 1, "loot: claiming banks the item")
		check(claimed[0]["base_id"] == preview["base_id"] and claimed[0]["mods"].size() == preview["mods"].size(),
			"loot: the claim re-rolls the identical item from the kill seed")
	var page_seed := -1
	for s in 400:
		if sim.enemy_skill_page("stone_husk", s) != "":
			page_seed = s
			break
	check(page_seed >= 0, "loot: a husk eventually drops a skill page")
	if page_seed >= 0:
		var page: String = sim.enemy_skill_page("stone_husk", page_seed)
		check(not sim.knows_skill(page) and sim.combat_skill(page)["drop_weight"] > 0.0,
			"loot: pages only teach unknown droppable skills")
		for id in sim.combat_skill_ids():
			sim.learn_skill(id)
		check(sim.enemy_skill_page("stone_husk", page_seed) == "", "loot: a full spellbook drops no pages")

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
