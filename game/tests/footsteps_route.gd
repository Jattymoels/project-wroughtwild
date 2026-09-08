extends Node3D
## Same actual walking fixture for baseline/current. Existing authored surfaces
## and biome export contract; no generated-world startup or economy claim.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var measuring := false
var samples: Array[float] = []
var previous_us := 0
var max_steps := 0
var max_beds := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FOOTSTEPS_ROUTE: ", label)

func _ready() -> void:
	_run.call_deferred()

func _process(_delta: float) -> void:
	if not measuring: return
	var now := Time.get_ticks_usec()
	if previous_us > 0: samples.append(float(now - previous_us) / 1000.0)
	previous_us = now
	max_steps = maxi(max_steps, get_tree().get_nodes_in_group("footstep_sounds").size())
	max_beds = maxi(max_beds, get_tree().get_nodes_in_group("environment_ambience_voices").size())

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func _run() -> void:
	get_window().size = Vector2i(1280,720)
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var terrain := Terrain.new()
	terrain.name = "Terrain"
	var indices := PackedInt32Array()
	indices.resize(16 * 90)
	for z in 90:
		for x in 16: indices[z * 16 + x] = mini(3, z / 20)
	terrain.map = {"width":16,"height":90,"cell_size":1.0,"depth":4,"biomes":indices,
		"biome_defs":[{"id":"meadow","surface":"grass"},{"id":"forest","surface":"forest_floor"},
			{"id":"marsh","surface":"marsh"},{"id":"crags","surface":"rock"}]}
	add_child(terrain)
	var families := ["wood", "stone", "corkbark", "vitrified_basalt"]
	for section in 4:
		var block := PlacedBlock.new()
		add_child(block)
		block.init_piece(&"cube", StringName(families[section]), {"kind":"block","axis":0,"cell":Vector3i(0,0,section)},
			0, "box", Vector3(14,.2,20), Vector3(8,-.1,section * 20 + 10), 0)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("92a6ac")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("acb5b0")
	world.environment.ambient_light_energy = .55
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-25,0)
	add_child(sun)
	var player_started := Time.get_ticks_usec()
	player = preload("res://scenes/player.tscn").instantiate()
	# Matched measurements use the same defaults, independent of earlier UI probes.
	player.audio_preferences.path = "res://../build/intensives/route-preferences.cfg"
	player.position = Vector3(8,.97,74)
	add_child(player)
	player.class_panel.choose("warden")
	var player_ready_ms := float(Time.get_ticks_usec() - player_started) / 1000.0
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.camera.make_current()
	player.spring_arm.rotation.x = -.25
	await frames(10)
	var before := player.inventory.get_sim().export_json()
	# Warm every floor/biome in 120 actual physics frames. Fast review-only
	# travel avoids making the steady sample include first palette synthesis.
	player.move_speed = 30
	player.test_walk = Vector2(0,-1)
	await frames(120)
	player.test_walk = Vector2.ZERO
	player.position = Vector3(8,.97,74)
	player.velocity = Vector3.ZERO
	player.move_speed = 5
	await frames(12)
	var start := player.position
	player.test_walk = Vector2(0,-1)
	measuring = true
	await frames(720)
	measuring = false
	player.test_walk = Vector2.ZERO
	check(absf(start.z - player.position.z - 60.0) < .3, "720 real physics frames travel sixty metres")
	check(player.is_on_floor(), "route ends on its actual constructed support")
	check(player.inventory.get_sim().export_json() == before, "walking and ambience leave native state exact")
	check(samples.size() >= 700, "steady timing covers complete route")
	samples.sort()
	var report := {"checks":checks,"failures":failures,"frames":samples.size(),"physics_frames":720,"warmup_physics_frames":120,
		"cold_player_ready_ms":player_ready_ms,
		"frame_median_ms":samples[samples.size()/2],"frame_p95_ms":samples[int(samples.size()*.95)],
		"max_step_voices":max_steps,"max_ambient_voices":max_beds,"distance_m":start.distance_to(player.position),
		"scope":"1280x720 Forward+, VSync disabled, 60 m of real walking over four constructed materials and biome beds; authored support/map, Dummy audio. Excludes native world generation, device mix and dense combat."}
	var directory := ProjectSettings.globalize_path("res://../captures/footsteps")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(directory.path_join("walking-route.json"), FileAccess.WRITE)
	check(file != null, "isolated route report opens")
	if file != null: file.store_string(JSON.stringify(report,"  ")); file.close()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(get_viewport().get_texture().get_image().save_png(directory.path_join("walking-route.png")) == OK, "capture actual walking route")
	print("FOOTSTEPS_ROUTE %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
