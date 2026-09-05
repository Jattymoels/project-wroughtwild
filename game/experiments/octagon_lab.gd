extends Node3D
## Codex (OpenAI), 5 Sep 2026. Isolated, self-driving construction experiment.
## Loads a COPIED tuning directory, never a player save. No input or saving.

var player: WroughtwildPlayer
var sim: WroughtwildSim
var checks := 0
var failures := 0
var frame := 0
var camera: Camera3D
var roofs: Array[PlacedBlock] = []
var door: PlacedBlock
var corner: PlacedBlock
var output := ""
var observations: Dictionary = {}
var caption: Label

func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: ", label)

func _ready() -> void:
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/" + review_id())
	var tuning := output.path_join("tuning")
	DirAccess.make_dir_recursive_absolute(tuning)
	var source := load("res://scripts/sim.gd").get_tuning_directory() as String
	for file in DirAccess.get_files_at(source):
		if file.ends_with(".json"):
			check(DirAccess.copy_absolute(source.path_join(file), tuning.path_join(file)) == OK, "copy fixture " + file)
	var construction: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(tuning.path_join("construction.json")))
	construction["shapes"].append_array(shape_fixtures())
	var file := FileAccess.open(tuning.path_join("construction.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(construction))
	file.close()
	sim = load("res://scripts/sim.gd").shared()
	check(sim.load_tuning(tuning), "experimental shape loads: " + sim.last_error())
	if failures > 0:
		get_tree().quit(1)
		return
	player = preload("res://scenes/player.tscn").instantiate()
	if OS.get_cmdline_user_args().has("--workshop-play"):
		player.set_script(preload("res://experiments/workshop_player.gd"))
	add_child(player)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.global_position = Vector3(5, 1.1, 5)
	player.hud.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_build_room()
	_setup_view()

func review_id() -> String:
	return "octagon"

func shape_fixtures() -> Array:
	return [JSON.parse_string(FileAccess.get_file_as_string("res://experiments/octagon_shape.json"))]

func _place(cell: Vector3i, shape: StringName = &"cube", rotation_step: int = 0, kind: String = "volume", axis: int = 0) -> PlacedBlock:
	var piece := player.placement.place_piece({"kind": kind, "axis": axis, "cell": cell * 2}, shape, &"wood", rotation_step)
	check(piece != null, "place %s at %s" % [shape, cell])
	return piece

func _build_room() -> void:
	for x in 10:
		for z in 10:
			var distances := [x + z, 9 - x + z, 18 - x - z, x + 9 - z]
			if distances.min() < 4:
				continue
			_place(Vector3i(x, 1, z), &"floor_slab", 0, "face", 1)
			roofs.append(_place(Vector3i(x, 4, z), &"floor_slab", 0, "face", 1))
			var turn := -1
			for i in 4:
				if distances[i] == 4 and x not in [0, 9] and z not in [0, 9]:
					turn = [3, 2, 1, 0][i]
			for y in range(1, 4):
				if turn >= 0:
					var piece := _place(Vector3i(x, y, z), &"codex_corner", turn)
					if x == 2 and y == 2 and z == 2:
						corner = piece
				elif x in [0, 9] or z in [0, 9]:
					if x == 4 and z == 0 and y < 3:
						continue
					_place(Vector3i(x, y, z))
	door = _place(Vector3i(4, 1, 1), &"door", 0, "face", 2)

func _setup_view() -> void:
	get_window().size = Vector2i(1920, 1080)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("24333e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c8d7e0")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, -35, 0)
	sun.shadow_enabled = true
	add_child(sun)
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 12.5
	camera.position = Vector3(15, 13, -10)
	camera.look_at(Vector3(5, 1.5, 5))
	camera.current = true
	var label := Label.new()
	caption = label
	label.text = "CODEX / OCTAGON LAB\nWhole-cell corner blocks · existing lattice\nCutaway roof for inspection"
	label.position = Vector2(36, 30)
	label.add_theme_font_size_override("font_size", 25)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(label)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		_probe()
	if frame == 15:
		_save_roundtrip()
	if frame == 30:
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			check(get_viewport().get_texture().get_image().save_png(output.path_join("cutaway.png")) == OK, "save cutaway screenshot")
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 80
		camera.position = Vector3(5, 2.7, 7.3)
		camera.look_at(Vector3(2, 2.3, 2))
		caption.text = "CODEX / OCTAGON LAB\nInterior at eye level · roof hidden\nDiagonal inner wall, thick stepped exterior"
	if frame == 60:
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			check(get_viewport().get_texture().get_image().save_png(output.path_join("interior.png")) == OK, "save interior screenshot")
		var file := FileAccess.open(output.path_join("observations.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(observations, "  "))
		print("CODEX_OCTAGON ", JSON.stringify(observations))
		print("%d checks, %d failures" % [checks, failures])
		get_tree().quit(0 if failures == 0 else 1)

func _probe() -> void:
	var centre := Vector3(5, 2, 5)
	check(player.placement.enclosure_at(centre)["enclosed"], "octagon centre is enclosed")
	var physics := get_world_3d().direct_space_state
	# In the NW diagonal block, x+z>5 is visibly empty interior; x+z<5 is solid.
	var empty := physics.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(2.8, 2.8, 2.8), Vector3(2.8, 2.2, 2.8)))
	check(empty.is_empty(), "triangular corner leaves its inner half physically empty")
	# Horizontal ray avoids the roof and crosses the diagonal face.
	var solid := physics.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(2.9, 2.5, 2.9), Vector3(2.1, 2.5, 2.1)))
	check(not solid.is_empty() and solid.get("collider") == corner, "diagonal face has matching convex collision")
	observations["empty_half_sheltered"] = player.placement.enclosure_at(Vector3(2.8, 2.5, 2.8))["enclosed"]
	check(observations["empty_half_sheltered"], "corner's usable half now receives shelter")
	check(not player.placement.enclosure_at(Vector3(2.1, 2.5, 2.1))["enclosed"], "solid prism is not shelter air")
	observations["whole_cell_reserved"] = not sim.structure_place(corner.element, "cube", "wood", 0)
	check(observations["whole_cell_reserved"], "corner reserves the entire block")
	door.toggle()
	observations["open_door_sheltered"] = player.placement.enclosure_at(centre)["enclosed"]
	door.toggle()
	# Open doors count as walls by the accepted construction shelter rule.
	check(observations["open_door_sheltered"], "open door retains documented shelter behaviour")
	var removed: PlacedBlock
	for roof in roofs:
		if roof.element["cell"] == Vector3i(10, 8, 10):
			removed = roof
	var element := removed.element.duplicate()
	check(player.placement.remove_piece(removed), "remove a roof slab through normal placement")
	check(not player.placement.enclosure_at(centre)["enclosed"], "roof hole breaks shelter")
	check(player.placement.place_piece(element, &"floor_slab", &"wood") != null, "replace roof slab")
	check(player.placement.enclosure_at(centre)["enclosed"], "repaired roof restores shelter")

func _save_roundtrip() -> void:
	var manager := SaveManager.new()
	var captured := manager.capture(player)
	var data: Dictionary = JSON.parse_string(JSON.stringify(captured))
	check(manager.apply(player, data), "existing save schema restores lab in memory")
	var restored := manager.capture(player)
	check(JSON.stringify(captured["blocks"]) == JSON.stringify(restored["blocks"]), "every block address, shape, family and rotation survives save roundtrip")
	var turns: Dictionary = {}
	for node in get_children():
		if node is PlacedBlock:
			if node.shape_id == &"codex_corner":
				turns[node.rotation_step] = true
				check(node.form == "corner" and node._collision_shapes[0].shape is ConvexPolygonShape3D, "restored corner keeps prism geometry")
			if node.shape_id == &"floor_slab" and node.element["cell"].y == 8:
				node.hide() # Only the capture is a cutaway; shelter geometry remains.
	check(turns.size() == 4, "all four corner rotations restored")
	check(player.placement.enclosure_at(Vector3(5, 2, 5))["enclosed"], "saved octagon still shelters its centre")
	observations["save_schema"] = SaveManager.SCHEMA_VERSION
	observations["corner_rotations"] = turns.size()
