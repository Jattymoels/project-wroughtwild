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
	_test_lattice()
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


## Wave 4: the building lattice through the extension. The geometry rules
## are regression-tested in tests/sim; this proves the door and the
## Dictionary shape of an element ({kind, axis, cell}).
func _test_lattice() -> void:
	if not ClassDB.class_exists(&"WroughtwildSim"):
		return
	var sim: RefCounted = ClassDB.instantiate(&"WroughtwildSim")
	sim.load_tuning(load("res://scripts/sim.gd").get_tuning_directory())

	check(sim.shape("wall_panel")["element"] == "wall" and sim.shape("pillar")["element"] == "post"
		and sim.shape("cube")["element"] == "block" and sim.shape("floor_slab")["element"] == "floor",
		"lattice: shapes name the element kind they occupy")
	check(sim.shape("door")["form"] == "door" and sim.shape("door")["cells_tall"] == 2
		and sim.shape("stairs")["oriented"] and not sim.shape("wall_panel")["oriented"],
		"lattice: forms, height and orientation come from data")
	check(absf(sim.lattice_registry_grid() - 0.5) < 0.0001, "lattice: the registry runs at half cells")

	# A wall aimed at the ground: the nearest vertical plane, standing on
	# it. Elements are in registry coordinates (twice the build cell).
	var walls: Array = sim.lattice_candidates("wall_panel", Vector3(10.4, 12.0, 10.3), Vector3.UP)
	check(walls.size() == 4, "lattice: four planes box a ground hit in")
	var first: Dictionary = walls[0]
	check(first["kind"] == "face" and first["axis"] == 2 and first["cell"] == Vector3i(20, 24, 20),
		"lattice: the nearest plane wins")
	check(first["centre"] == Vector3(10.5, 12.5, 10.0) and first["yaw_turns"] == 0,
		"lattice: a z-face pose lies on its plane, unturned")
	var face_x_far := {"kind": "face", "axis": 0, "cell": Vector3i(20, 24, 20)}
	check(sim.lattice_pose("wall_panel", face_x_far)["yaw_turns"] == 1, "lattice: an x-face turns a quarter")
	check(sim.lattice_pose("door", face_x_far)["centre"] == Vector3(10.0, 13.0, 10.5),
		"lattice: a two-cell door is posed at the centre of both cells")
	# A block aimed at a cube's top: the one cell above it.
	var blocks: Array = sim.lattice_candidates("cube", Vector3(10.5, 13.0, 10.5), Vector3.UP)
	check(blocks.size() == 1 and blocks[0]["cell"] == Vector3i(20, 26, 20), "lattice: blocks stack")
	check(sim.shape_accepts("pillar", {"kind": "edge", "axis": 1, "cell": Vector3i.ZERO})
		and not sim.shape_accepts("pillar", {"kind": "edge", "axis": 0, "cell": Vector3i.ZERO}),
		"lattice: a post wants a vertical edge")

	# The structure: one piece per element, footprints, corners grow trims.
	var face_x := {"kind": "face", "axis": 0, "cell": Vector3i(10, 6, 10)}
	var face_z := {"kind": "face", "axis": 2, "cell": Vector3i(10, 6, 10)}
	check(sim.structure_pieces().is_empty(), "structure: starts empty")
	check(sim.structure_place(face_x, "wall_panel", "wood", 0), "structure: a wall takes a face")
	check(not sim.structure_place(face_x, "wall_panel", "wood", 0), "structure: a taken face refuses another")
	check(not sim.structure_place(face_x, "cube", "wood", 0), "structure: a cube may not stand on a face")
	check(sim.structure_occupied(face_x) and sim.structure_occupied({"kind": "face", "axis": 0, "cell": Vector3i(10, 7, 11)})
		and not sim.structure_occupied(face_z), "structure: a full-size wall covers its four registry faces")
	check(sim.structure_piece({"kind": "face", "axis": 0, "cell": Vector3i(10, 7, 11)})["shape"] == "wall_panel",
		"structure: any covered element finds the piece")
	check(sim.structure_trim_edges().size() == 4, "structure: a lone panel is framed at both ends")
	check(sim.structure_place(face_z, "wall_panel", "wood", 0), "structure: the perpendicular wall joins")
	var trims: Array = sim.structure_trim_edges()
	var corner := false
	for trim in trims:
		if trim["cell"] == Vector3i(10, 6, 10) and trim["kind"] == "edge":
			corner = true
	check(trims.size() == 6 and corner, "structure: the corner grows a post")
	check(sim.structure_remove({"kind": "face", "axis": 0, "cell": Vector3i(10, 7, 11)})
		and not sim.structure_remove(face_x), "structure: removing through a covered element frees the piece once")
	check(sim.structure_pieces().size() == 1, "structure: one piece left")
	var above := {"kind": "face", "axis": 0, "cell": Vector3i(10, 8, 10)}
	check(sim.structure_free_for("door", face_x) and sim.structure_place(face_x, "door", "wood", 0)
		and not sim.structure_free_for("wall_panel", above),
		"structure: a door takes the face above it as well")
	sim.structure_clear()
	check(sim.structure_pieces().is_empty() and sim.structure_trim_edges().is_empty(), "structure: clear empties it")

	# Fine mode: a half post aimed at the middle of a cube's top takes the
	# registry edge there - "a post on a block" - where a full post cannot.
	var mid_top := {"kind": "edge", "axis": 1, "cell": Vector3i(21, 26, 21)}
	var half_posts: Array = sim.lattice_candidates("half_pillar", Vector3(10.5, 13.0, 10.5), Vector3.UP)
	check(not half_posts.is_empty() and half_posts[0]["cell"] == mid_top["cell"] and half_posts[0]["kind"] == "edge",
		"fine: a half post aimed at a cube's top centre takes the edge through it")
	check(sim.shape_accepts("half_pillar", mid_top) and sim.shape_accepts("pillar", mid_top),
		"fine: a full post may stand off the build grid too - the piece you build on decides")
	# A full cube on a half cube's top: fine-grid candidates put its bottom
	# on the half cube (y = 12.5), a whole cube tall from there.
	var on_half: Array = sim.lattice_candidates("cube", Vector3(10.75, 12.5, 10.75), Vector3.UP, true)
	check(on_half.size() == 1 and on_half[0]["cell"] == Vector3i(21, 25, 21)
		and on_half[0]["centre"] == Vector3(11.0, 13.0, 11.0), "fine: a full cube sits on a half cube")
	check(sim.lattice_pose("half_pillar", mid_top)["centre"] == Vector3(10.5, 13.25, 10.5),
		"fine: a half post is posed at its registry edge")
	var half_cell := {"kind": "volume", "axis": 0, "cell": Vector3i(21, 24, 21)}
	check(sim.lattice_pose("half_cube", half_cell)["centre"] == Vector3(10.75, 12.25, 10.75),
		"fine: a half cube sits in its registry cell")
	check(sim.structure_place(half_cell, "half_cube", "wood", 0)
		and not sim.structure_free_for("cube", {"kind": "volume", "axis": 0, "cell": Vector3i(20, 24, 20)})
		and sim.structure_place({"kind": "volume", "axis": 0, "cell": Vector3i(20, 24, 20)}, "half_cube", "wood", 0),
		"fine: a half cube blocks the full cube from its cell but not another half cube")
	sim.structure_clear()

	# Reaching into air: a beam's continuation touches the beam, a beam
	# three cells on does not; the ray brushes the structure near the beam.
	var beam_edge := {"kind": "edge", "axis": 0, "cell": Vector3i(20, 26, 20)}
	check(sim.structure_piece_count() == 0 and sim.structure_place(beam_edge, "beam", "wood", 0)
		and sim.structure_piece_count() == 1, "touch: one beam placed")
	check(sim.structure_touches("beam", {"kind": "edge", "axis": 0, "cell": Vector3i(22, 26, 20)}),
		"touch: the next beam along the line touches")
	check(not sim.structure_touches("beam", {"kind": "edge", "axis": 0, "cell": Vector3i(28, 26, 20)}),
		"touch: a beam three cells on does not")
	# Population (3 Sep): the mob grid answers neighbour queries from the last
	# finished frame (pack sleep is covered in the horde scene).
	MobGrid.reset()
	var m1 := Node3D.new()
	var m2 := Node3D.new()
	var m3 := Node3D.new()
	get_root().add_child(m1); get_root().add_child(m2); get_root().add_child(m3)
	m1.position = Vector3(10, 0, 10)
	m2.position = Vector3(10.8, 0, 10)
	m3.position = Vector3(30, 0, 10)
	MobGrid.register(m1); MobGrid.register(m2); MobGrid.register(m3)
	check(MobGrid.near(Vector3(10, 0, 10), 2.0, m1).size() == 1, "grid: a mob registered this frame is already findable")
	MobGrid._frame = -1  # pretend a new frame began
	MobGrid.register(m1)
	check(MobGrid.near(Vector3(10, 0, 10), 2.0, m1).size() == 1 and MobGrid.near(Vector3(10, 0, 10), 2.0, m1)[0] == m2
		and MobGrid.near(Vector3(30, 0, 10), 1.0).size() == 1 and MobGrid.population() == 3,
		"grid: neighbours within the radius, excluding yourself, from the finished frame")
	m1.queue_free(); m2.queue_free(); m3.queue_free()
	MobGrid.reset()


	# A block owns its interior: a wall cannot be placed through its middle
	# plane, and a block cannot be placed around an off-grid wall.
	check(sim.structure_place({"kind": "volume", "axis": 0, "cell": Vector3i(60, 26, 60)}, "cube", "wood", 0),
		"interior: a cube stands")
	check(not sim.structure_free_for("wall_panel", {"kind": "face", "axis": 0, "cell": Vector3i(61, 26, 60)})
		and not sim.structure_place({"kind": "face", "axis": 0, "cell": Vector3i(61, 26, 60)}, "wall_panel", "wood", 0),
		"interior: no wall through the cube's middle")
	check(sim.structure_place({"kind": "face", "axis": 0, "cell": Vector3i(71, 26, 60)}, "wall_panel", "wood", 0)
		and not sim.structure_free_for("cube", {"kind": "volume", "axis": 0, "cell": Vector3i(70, 26, 60)}),
		"interior: no cube around an off-grid wall")
	sim.structure_remove({"kind": "volume", "axis": 0, "cell": Vector3i(60, 26, 60)})
	sim.structure_remove({"kind": "face", "axis": 0, "cell": Vector3i(71, 26, 60)})
	check(sim.structure_near_point(Vector3(10.5, 13.1, 10.05)) and not sim.structure_near_point(Vector3(15.0, 13.0, 10.0)),
		"touch: the ray brushes the structure only near the beam")
	sim.structure_clear()

	# Shelter: with no terrain (seed -1) the structure alone must close the
	# room - four walls, a floor and a roof around build cell (0, 0, 0).
	var rules: Dictionary = sim.shelter()
	check(rules.get("regen_life_per_round", 0.0) > 0.0 and rules.get("max_room_cells", 0) > 0,
		"shelter: rules come from world.json")
	var no_digs := PackedInt32Array()
	var middle := Vector3(0.5, 0.5, 0.5)
	check(not sim.structure_enclosure(-1, no_digs, middle)["enclosed"], "shelter: nothing built, no shelter")
	for wall in [[0, Vector3i(0, 0, 0)], [0, Vector3i(2, 0, 0)], [2, Vector3i(0, 0, 0)], [2, Vector3i(0, 0, 2)]]:
		sim.structure_place({"kind": "face", "axis": wall[0], "cell": wall[1]}, "wall_panel", "wood", 0)
	sim.structure_place({"kind": "face", "axis": 1, "cell": Vector3i(0, 0, 0)}, "floor_slab", "wood", 0)
	check(not sim.structure_enclosure(-1, no_digs, middle)["enclosed"], "shelter: no roof, no shelter")
	var roofless: Dictionary = sim.structure_enclosure(-1, no_digs, middle)
	check(roofless["reason"] == "sky" and roofless.has("leak") and (roofless["leak"] as Vector3).y > middle.y,
		"shelter: a roofless room reports the sky leak above it (%s)" % str(roofless.get("leak")))
	sim.structure_place({"kind": "face", "axis": 1, "cell": Vector3i(0, 2, 0)}, "floor_slab", "wood", 0)
	var room: Dictionary = sim.structure_enclosure(-1, no_digs, middle)
	check(room["enclosed"] and room["cells"] == 1, "shelter: a closed one-cell box is a shelter of one cell")
	check(not sim.structure_enclosure(-1, no_digs, Vector3(3.5, 0.5, 0.5))["enclosed"],
		"shelter: standing outside the box is not sheltered")
	sim.structure_clear()

	# Encroachment through the door: nothing without a home, a nest on the
	# fringe with a home, uneasy rest beside it, a scar after clearing.
	sim.encroachment_reset(5)
	var enc_rules: Dictionary = sim.encroachment_rules()
	# Nests belong to era two: with a home in era one nothing settles.
	check(sim.era()["index"] == 1, "eras: a fresh sim is era one")
	sim.encroachment_tick(10.0, true, Vector3(40, 0, 40))
	check(sim.encroachment_tick(10.0 + enc_rules["settle_seconds"] * 2, true, Vector3(40, 0, 40)).is_empty(),
		"eras: era one has no nests even with a home")
	sim.record_world_effect("stonecut_blocks")
	check(sim.era()["index"] == 2 and sim.era()["id"] == "deep_wakes" and sim.era()["encroachment"],
		"eras: the completion effect wakes the deep")
	check(sim.era_mechanic("ash_hound", "pack_size_bonus").get("value", 0) == 1
		and sim.era_mechanic("ember_whelp", "burning_ground").has("seconds")
		and sim.era_mechanic("stone_husk", "burning_ground").is_empty(), "eras: mechanics through the door")
	sim.encroachment_reset(5)
	check(enc_rules["max_nests"] >= 1 and sim.encroachment_tick(10.0, false, Vector3.ZERO).is_empty(),
		"encroach: nothing settles without a home")
	sim.encroachment_tick(10.0, true, Vector3(40, 0, 40))
	var born: Array = sim.encroachment_tick(10.0 + enc_rules["settle_seconds"], true, Vector3(40, 0, 40))
	check(born.size() == 1 and born[0]["pack"].size() >= 1 and sim.encroachment_nests().size() == 1,
		"encroach: a nest settles on the fringe with a pack")
	var at := Vector3(born[0]["x"], 0.0, born[0]["z"])
	check(at.distance_to(Vector3(40, 0, 40)) <= 31.0 and sim.encroachment_rest_multiplier(at) < 1.0
		and sim.encroachment_rest_multiplier(Vector3(400, 0, 400)) == 1.0, "encroach: blight only near the nest")
	var dropped := 0
	for k in 200:
		if sim.encroachment_kill_drops(k * 31 + 7):
			dropped += 1
	check(dropped > 40 and dropped < 130, "encroach: nest-born kills drop only a fraction of the time")
	check(sim.encroachment_pressure() == 1 and sim.encroachment_clear(born[0]["id"], 500.0)
		and sim.encroachment_nests().is_empty() and sim.encroachment_pressure() == 0, "encroach: a nest tears down")
	sim.encroachment_reset(5)

	# The Foundry through the door: a milestone forges an ingot, the plate
	# takes it, the pair speaks, and the stats read it.
	var life_before: float = sim.derived_stats()["max_life"]
	sim.foundry_notices()  # drain what the era test's world effect forged
	# Era two here (the era test above woke the deep): the frame has three
	# of its four rows forged, and two sockets on the diagonal.
	check(sim.foundry()["rows"] == 4 and sim.foundry()["cols"] == 4 and sim.foundry()["first_row"] == 0
		and sim.foundry()["last_row"] == 2 and sim.foundry()["sockets"].size() == 2
		and sim.foundry_ingot_ids().size() >= 8 and sim.foundry_effects().is_empty(),
		"foundry: a 4x4 frame with three rows forged, bare")
	check(sim.foundry_event("first_kill:stone_husk") == ["plate"] and sim.foundry_event("first_kill:stone_husk").is_empty(),
		"foundry: a first kill forges its ingot once")
	check(sim.foundry_ingot("plate")["unplaced"] == 1 and sim.foundry_ingot("plate")["sentence"].contains("Armour"),
		"foundry: the ingot view names its sentence")
	check(not sim.foundry_place(3, 0, "plate") and not sim.foundry_place(1, 1, "plate"),
		"foundry: an unforged row and a socket refuse an ingot")
	check(sim.foundry_place(1, 0, "plate") and sim.foundry_effects().size() == 1 and sim.foundry()["unplaced"]["plate"] == 0,
		"foundry: placed, and the plate does one thing")
	check(sim.derived_stats()["armour"] >= 8.0, "foundry: a plate ingot is armour on the sheet")
	check(sim.foundry_event("recipe:workbench_kit") == ["vigour"] and sim.foundry_place(2, 0, "vigour"),
		"foundry: vigour below plate")
	var kinds := []
	for effect in sim.foundry_effects():
		kinds.append(effect["kind"])
	check(kinds.count("pair") == 1 and sim.derived_stats()["max_life"] > life_before, "foundry: the Bulwark pair, and life rose")
	check(not sim.foundry_remove(1, 0), "foundry: re-forging needs metal")
	sim.add_material("iron_ingot", 1)
	check(sim.foundry_remove(1, 0) and sim.material_count("iron_ingot") == 0 and sim.foundry_effects().size() == 1,
		"foundry: lifted for one ingot of iron")
	check(absf(sim.skill_reach("prototype_frost_orb") - 1.0) < 0.001, "reach: nothing speaks to the orb through the door")
	check(sim.foundry_notices().is_empty(), "foundry: engine-reported milestones raise no notices of their own")

	# Items as mechanics through the door: a tier-three roll on iron is
	# held back and says so; the pack view carries breakpoints.
	# Only cold damage has a third tier in the sceptre's pool, so roll until it lands.
	var any_held := false
	var cap := 0
	for seed in range(1, 40):
		var held_index: int = sim.roll_item_into_pack("frost_sceptre", "keen", 3, seed)
		var held_item: Dictionary = sim.pack_items()[held_index]
		cap = held_item["tier_cap"]
		for mod in held_item["mods"]:
			if mod.get("held_back", false):
				any_held = mod["tier"] <= 2 and mod["rolled_tier"] == 3 and mod["unleashed_by"].contains("tier 3")
		if any_held:
			break
	check(cap == 2 and any_held, "items: a tier-three roll on an iron base is held back at tier two")
	check(sim.catalyst_process("preserving_transfer")["process"] == "catalyst_transfer", "items: the transfer process is visible")
	sim.structure_clear()

	# Mastery and the pack: uses unlock a perk, discards throw gear away.
	check(sim.combat_skill("prototype_frost_orb")["mastery"].size() == 2 and sim.combat_skill("prototype_frost_orb")["uses"] == 0,
		"mastery: perks visible, no uses yet")
	var unlocked := PackedStringArray()
	for i in 30:
		unlocked.append_array(sim.note_skill_use("prototype_frost_orb"))
	check(unlocked.size() == 1 and sim.combat_skill("prototype_frost_orb")["mastery"][0]["unlocked"],
		"mastery: thirty orbs unlock the first perk")
	check(sim.combat_skill("prototype_shatter")["tags"].has("shatter") and not sim.shatter_for("prototype_shatter").is_empty(),
		"shatter: the Shatter spell carries the trigger tag")
	var before_count: int = sim.pack_items().size()
	var junk: int = sim.roll_item_into_pack("iron_mace", "plain", 1, 3)
	check(sim.discard_pack_item(junk) and sim.pack_items().size() == before_count and not sim.discard_pack_item(999),
		"pack: a discarded item is gone")
	# Era three, floors, the peddler through the door.
	# A fresh sim: this one already woke the deep above.
	var fresh: RefCounted = ClassDB.instantiate(&"WroughtwildSim")
	fresh.load_tuning(load("res://scripts/sim.gd").get_tuning_directory())
	var floors: Array = fresh.trial_floors()
	check(floors.size() == 1 and floors[0]["id"] == "deep_forge" and not floors[0]["available"],
		"floor: the deeper forge waits on the Tyrant")
	check(not fresh.trial_start(3, "deep_forge"), "floor: it cannot be entered before then")
	check(sim.trial_floors()[0]["available"] and sim.trial_start(3, "deep_forge") and sim.boss()["id"] == "ash_warden"
		and sim.trial_floor()["id"] == "deep_forge", "floor: with the deep awake it opens, and its boss is the warden")
	sim.trial_end()
	check(sim.market_offers().size() >= 3 and not sim.market_offers()[0]["affordable"], "peddler: offers listed, none affordable yet")
	check(sim.era()["pack_escorts"].is_empty() and sim.era()["elite_chance_bonus"] == 0.0, "era3: era one escorts nothing")
	check(sim.realtime()["behaviours"]["grazer"]["flees"] and not sim.realtime()["behaviours"]["melee"].get("flees", false),
		"life: the grazer behaviour flees")

	# The bigger world and its new families (3 Sep 2026).
	check(sim.enemy("bog_lurker")["behaviour"] == "lurker" and sim.enemy("bog_lurker")["tint"] == "#4E5E3E"
		and float(sim.enemy("bog_lurker")["size_scale"]) > 1.0, "world: the bog lurker has its own look")
	check(sim.realtime()["behaviours"].has("skirmisher") and sim.realtime()["behaviours"]["skirmisher"]["preferred_distance_m"] > 0.0,
		"world: the skirmisher keeps its distance")

	check(PieceMesh.mesh_for("stairs", Vector3.ONE).get_aabb().size.is_equal_approx(Vector3.ONE)
		and PieceMesh.mesh_for("wedge", Vector3.ONE).get_aabb().size.is_equal_approx(Vector3.ONE),
		"piece mesh: stairs and wedge fill their cell")
	check(PieceMesh.collision_for("stairs", Vector3.ONE).size() == 2
		and (PieceMesh.collision_for("wedge", Vector3.ONE)[0]["shape"] as ConvexPolygonShape3D).points.size() == 6,
		"piece mesh: stairs collide as two boxes, the wedge as a six-point hull")


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
	check(sim.combat_skill_ids().size() == 8, "combat: eight skills defined (four arrive as pages)")
	check(sim.enemy("ember_whelp")["max_life"] == 75.0 and sim.enemy_ids().size() == 11,
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
	check(not sim.shape_unlocked("roof_wedge") and sim.shape_unlocked("floor_slab"),
		"shape: the wedge waits on the completion unlock, the slab does not")
	check(sim.shape_ids().size() >= 9 and sim.shape_unlocked("wall_panel") and sim.shape("wall_panel")["size"].z < 0.5,
		"shape: nine-shape set with sizes from data")
	check(sim.build_material_ids().size() == 8 and sim.build_material("iron")["source"] == "iron_ingot"
		and sim.build_material("stone")["texture"] == "masonry", "materials: families through the door")
	check(sim.shape_allows_family("door", "wood") and not sim.shape_allows_family("door", "stone")
		and sim.shape("girder")["cells_long"] == 2 and sim.shape("girder")["requires_traits"].has("metal"),
		"materials: trait gating through the door")

	# D-020 fire-setting through the door: hands, heat, fuels, the campfire.
	var rules: Dictionary = sim.block_rules()
	check(rules["dirt"]["by_hand"] and not rules["stone"]["by_hand"] and rules["stone"]["heat_to_crack"] == 1
		and not rules["bedrock"]["by_hand"] and rules["bedrock"]["heat_to_crack"] == 0,
		"fire: block rules carry hands and heat")
	var fs: Dictionary = sim.fire_setting()
	check(fs["fuels"]["wood"]["heat"] == 1 and fs["fuels"]["charcoal"]["heat"] == 2
		and fs["fuels"]["wood"]["burn_seconds"] > 0.0 and fs["quench_radius_m"] > 0.0 and fs["reach_cells"] >= 1,
		"fire: fuels through the door")
	check(sim.shape("campfire")["form"] == "fire" and sim.shape("campfire")["requires_traits"].has("fuel"),
		"fire: the campfire is a fire-form piece that wants fuel")
	check(sim.shape_allows_family("campfire", "wood") and sim.shape_allows_family("campfire", "charcoal")
		and not sim.shape_allows_family("cube", "charcoal") and not sim.shape_allows_family("campfire", "stone"),
		"fire: charcoal lays a fire and nothing else; stone does not burn")
	check(sim.build_material("charcoal")["only_for_trait"] == "fuel" and sim.build_material("wood")["traits"].has("fuel"),
		"fire: timber is fuel too")
	check(sim.lattice_pose("girder", {"kind": "edge", "axis": 0, "cell": Vector3i(20, 26, 20)})["centre"] == Vector3(11.0, 13.0, 10.0),
		"materials: a girder is posed across both its cells")

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
	check(mods.size() >= 2 and String(mods[0]["sentence"]).to_lower().contains("cold"), "items: the item card lists the implicit (a small cold add, D-020) first")
	check(sim.equip_pack_item(index) and sim.equipment().has("weapon") and sim.pack_items().size() == before, "items: wearing from the pack fills the weapon slot")
	check(sim.fork_count("prototype_frost_orb") == 1, "items: the worn sceptre no longer forks the orb (D-020: forks wait for tier two)")
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
	check(a["biome_defs"].size() == 5, "sandpit: five biomes defined")

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

	# D-020 fire-setting on the terrain: stone refuses hands, a fire beside
	# it soaks it, cold cracks it, cracked stone digs, cracks save.
	var stone_y := -1
	for y in range(sh - 3, 0, -1):
		if terrain.kind_at(sx, y, sz) == "stone":
			stone_y = y
			break
	check(stone_y > 0, "fire: stone lies under the spawn column")
	var rock := Vector3i(sx, stone_y, sz)
	check(not terrain.diggable_by_hand(rock) and terrain.break_block(sx, stone_y, sz) == "",
		"fire: hands cannot dig stone")
	check(terrain.dig_refusal(rock).contains("fire"), "fire: the refusal names the fire")
	check(terrain.heat_around(rock + Vector3i(1, 0, 0), 1, 1) >= 1 and terrain.heat_level(rock) == 1,
		"fire: a fire beside the rock soaks it")
	check(terrain.dig_refusal(rock).contains("cold"), "fire: hot rock asks for cold")
	var cs2: float = terrain.map["cell_size"]
	var hot_centre := Vector3((rock.x + 0.5) * cs2, (rock.y + 0.5) * cs2, (rock.z + 0.5) * cs2)
	check(terrain.quench_at(hot_centre + Vector3(12, 0, 0), 2.5) == 0 and terrain.heat_level(rock) == 1,
		"fire: cold far away cracks nothing")
	check(terrain.quench_at(hot_centre, 2.5) >= 1 and terrain.is_cracked(rock) and terrain.heat_level(rock) == 0,
		"fire: cold on hot rock cracks it")
	check(terrain.cracked_packed_list().has([rock.x, rock.y, rock.z]), "fire: cracks list for the save")
	check(terrain.diggable_by_hand(rock) and terrain.break_block(sx, stone_y, sz) == "stone",
		"fire: cracked stone digs by hand and pays stone")
	check(not terrain.is_cracked(rock), "fire: the dug cell forgets its crack")
	var below := Vector3i(sx, stone_y - 1, sz)
	if terrain.kind_at(below.x, below.y, below.z) == "stone":
		terrain.apply_cracked([[below.x, below.y, below.z]])
		check(terrain.is_cracked(below) and terrain.diggable_by_hand(below), "fire: a save's cracks restore")
	# Nodes: an alloy ore wants a charcoal fire; hot it works, cold cracks it for good.
	var boulder: ResourceNode = load("res://scenes/resource_node.tscn").instantiate()
	boulder.material_family = &"copper_ore"
	boulder.heat_to_work = 2
	boulder.remaining_units = 6
	get_root().add_child(boulder)
	check(not boulder.workable() and boulder.harvest() == 0 and boulder.work_refusal().contains("fire"),
		"fire: an alloy vein refuses hands and says why")
	boulder.soak(1, 30.0)
	check(not boulder.workable() and boulder.work_refusal().contains("hotter"), "fire: a wood fire is not enough for copper")
	boulder.soak(2, 30.0)
	check(boulder.workable() and boulder.harvest() == 2, "fire: hot at charcoal heat, it works (softened)")
	check(boulder.quench() and boulder.cracked and boulder.workable(), "fire: cold on the hot vein cracks it for good")

	# D-021 seams: the three routes. Baseline E drives the wedge; a blow
	# splits at once; a hot seam splits twice under one blow.
	sim.add_material("timber_wedge", 3)
	var seam: ResourceNode = load("res://scenes/resource_node.tscn").instantiate()
	seam.material_family = &"split_stone"
	seam.tool_item = &"timber_wedge"
	seam.drive_presses = 3
	seam.remaining_units = 12
	seam.units_per_harvest = 2
	get_root().add_child(seam)
	check(seam.is_seam() and seam.interact_label(sim).contains("set a wedge"), "seams: the label offers a wedge you carry")
	check(seam.strike().has("refusal"), "seams: a blow on a bare seam does nothing")
	var step: Dictionary = seam.work(sim)
	check(step.has("text") and seam.wedge_set and sim.material_count("timber_wedge") == 2, "seams: E sets a wedge and spends it")
	check(seam.work(sim).has("text") and seam.work(sim).has("text") and seam.drive_progress == 2, "seams: E drives it a press at a time")
	var split: Dictionary = seam.work(sim)
	check(int(split.get("granted", 0)) == 2 and not seam.wedge_set and seam.remaining_units == 10, "seams: the last press splits two stone and frees the wedge")
	seam.work(sim)
	var blow: Dictionary = seam.strike()
	check(int(blow.get("granted", 0)) == 2 and blow.get("struck", false) and not blow.get("synergy", true) and seam.remaining_units == 8,
		"seams: a heavy blow on a set wedge splits at once (exploit)")
	seam.work(sim)
	seam.soak(1, 30.0)
	check(seam.interact_label(sim).contains("whole seam"), "seams: a hot seam says what a blow will do")
	var whole: Dictionary = seam.strike()
	check(int(whole.get("granted", 0)) == 4 and whole.get("synergy", false) and seam.remaining_units == 4,
		"seams: heat and impact take the whole seam (synergy)")
	check(sim.material_count("timber_wedge") == 0 and seam.work(sim).has("refusal"), "seams: out of wedges, the seam says so")
	seam.queue_free()
	boulder.queue_free()
	var tree: ResourceNode = load("res://scenes/resource_node.tscn").instantiate()
	tree.material_family = &"wood"
	get_root().add_child(tree)
	check(tree.workable() and tree.harvest() == 2, "fire: trees are hands' work")
	boulder.queue_free()
	tree.queue_free()
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
	check(int(elite_husk.get("split_stone", 0)) > int(plain_husk.get("split_stone", 0)),
		"elites: the bounty pays more stone")

	check(sim.kit_station("workbench_kit") == "workbench", "sandpit: workbench kit maps to workbench")
	check(sim.kit_station("forge_kit") == "forge_basic", "sandpit: forge kit maps to the forge")
	check(sim.kit_station("wood") == "", "sandpit: non-kits map to nothing")
	check(sim.kit_item_ids().size() == 3 and sim.kit_station("mason_yard_kit") == "mason_yard", "sandpit: three kits exist (the yard joined, D-021)")

	var drops_a: Dictionary = sim.enemy_loot("stone_husk", 77)
	var drops_b: Dictionary = sim.enemy_loot("stone_husk", 77)
	check(drops_a == drops_b, "sandpit: loot deterministic per seed")
	check(drops_a.get("split_stone", 0) >= 2, "sandpit: husks always pay split stone (D-021)")

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
