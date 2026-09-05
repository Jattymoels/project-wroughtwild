extends Node3D
## Codex, 5 Sep 2026. Fixed-seed/camera/hour comparison; no save IO.
## Run this scene with -- --frontier-look to capture the candidate.

var world: Sandpit
var camera: Camera3D
var views: Array[Dictionary] = []
var records: Array[Dictionary] = []
var index := 0
var frame := 0
var capturing := false
var variant := "baseline"
var output: String

func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	if OS.get_cmdline_user_args().has("--frontier-look"):
		variant = "frontier"
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/" + variant)
	DirAccess.make_dir_recursive_absolute(output)
	world = preload("res://scenes/sandpit.tscn").instantiate()
	add_child(world)
	world.player.class_panel.choose("warden")
	world.player.hud.hide()
	world._tick_day(0.0)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	camera = Camera3D.new()
	camera.fov = world.player.camera.fov
	add_child(camera)
	camera.make_current()
	var spawn := world.player.global_position
	views.append({"name": "spawn", "eye": spawn + Vector3(0, 0.72, 0), "target": spawn + Vector3(0, 0.57, -1)})
	views.append({"name": "overlook", "eye": spawn + Vector3(12, 18, 22), "target": spawn + Vector3(-15, 0, -35)})
	for biome in ["forest", "fen", "ember_wastes"]:
		_add_biome_view(biome, spawn)
	_set_view()

func _add_biome_view(biome: String, spawn: Vector3) -> void:
	var map: Dictionary = world.terrain.map
	var width := int(map["width"])
	var height := int(map["height"])
	var biome_index := -1
	var defs: Array = map["biome_defs"]
	for i in defs.size():
		if String(defs[i]["id"]) == biome:
			biome_index = i
	var best := INF
	var cell := Vector2i(-1, -1)
	var biomes: PackedInt32Array = map["biomes"]
	for z in range(20, height - 24):
		for x in range(20, width - 24):
			if biomes[z * width + x] != biome_index:
				continue
			# Prefer a patch with the same biome ahead, rather than its edge.
			if biomes[(z - 12) * width + x] != biome_index:
				continue
			var at := world.terrain.surface_position(x, z)
			var distance := at.distance_squared_to(spawn)
			if distance < best and world.terrain.block_at(x, int(at.y) - 1, z) != 0:
				best = distance
				cell = Vector2i(x, z)
	if cell.x < 0:
		push_error("Comparison seed has no view for " + biome)
		get_tree().quit(1)
		return
	var eye := world.terrain.surface_position(cell.x, cell.y) + Vector3(0, 2.4, 0)
	views.append({"name": biome, "eye": eye, "target": eye + Vector3(0, -1.0, -14)})

func _set_view() -> void:
	var view: Dictionary = views[index]
	camera.global_position = view["eye"]
	camera.look_at(view["target"])
	world.player.global_position = view["eye"] - Vector3(0, 0.72, 0)
	world.mood._target = BiomeMood.mood_for(world.mood._biome_under_player())
	world.mood._apply(1.0)
	frame = 0

func _process(_delta: float) -> void:
	if capturing:
		return
	frame += 1
	if frame < 45:
		return
	capturing = true
	await RenderingServer.frame_post_draw
	var view: Dictionary = views[index]
	var path := output.path_join(String(view["name"]) + ".png")
	var result := get_viewport().get_texture().get_image().save_png(path)
	if result != OK:
		push_error("Capture failed: " + path)
		get_tree().quit(1)
		return
	var record := {"view": view["name"], "variant": variant, "seed": world.world_seed,
		"camera": [camera.position.x, camera.position.y, camera.position.z],
		"target": [view["target"].x, view["target"].y, view["target"].z],
		"godot": Engine.get_version_info()["string"], "renderer": RenderingServer.get_current_rendering_method(),
		"size": [1920, 1080], "day": world.player.inventory.get_sim().day(),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)}
	records.append(record)
	print("CODEX_CAPTURE ", JSON.stringify(record))
	index += 1
	if index == views.size():
		var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(records, "\t"))
		get_tree().quit()
	else:
		_set_view()
		capturing = false
