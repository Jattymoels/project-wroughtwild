extends "res://tests/strange_frontier_review.gd"
## Cold-process V5/V6 comparison in the full world presentation. The scripted
## camera follows native routes at player height; this is not a combat playtest.
var views: Array[Dictionary] = []

func _ready() -> void:
	world_profile = "frontier_v6"
	world_seed = 1
	visual_only = OS.get_cmdline_user_args().has("--review-views-only")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-profile="): world_profile = arg.get_slice("=", 1)
		if arg.begins_with("--review-seed="): world_seed = int(arg.get_slice("=", 1))
	output = ProjectSettings.globalize_path("res://../build/wide-frontier/" + world_profile + "-" + str(world_seed))
	DirAccess.make_dir_recursive_absolute(output)
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_size(Vector2i(1440, 900))
	var began := Time.get_ticks_usec()
	_build_world(world_seed)
	report.world_setup_ms = (Time.get_ticks_usec() - began) / 1000.0
	report.terrain_startup = terrain.build_profile.duplicate(true)
	if terrain.map.is_empty():
		check(false, "complete world generated")
		_finish_review()
		return
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.hide()
	player.hud.hide()
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	mood.set_process(false)
	mood.set_physics_process(false)
	set_physics_process(false)
	_setup_camera()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
	report.profile = world_profile
	report.seed = world_seed
	report.scope = "Separate cold process per profile, full terrain/resource/regional/history presentation; fixed 1440x900, FOV75, 1.65m eye, 120fps cap. Scripted 5m/s route; combat and clock disabled. Owner's game may share hardware. Memory is engine static allocations, not peak process/GPU memory."
	report.initial_memory_bytes = Performance.get_monitor(Performance.MEMORY_STATIC)
	report.resource_records = terrain.resource_stream.records.size()
	report.pack_records = mob_packs.packs.size()
	check(terrain.world_profile() == world_profile, "terrain and selected identity agree")
	check(terrain.map.regions.size() == 3 and terrain.map.habitats.size() == 3, "three regions and all building habitats remain")
	check(terrain.map.pressure_pockets.size() == 1 and _sim().contraption_pressure_sources().size() == 1, "accidental old smithy and finite ledger integrated")
	if world_profile == "frontier_v6":
		check(terrain.map.width == 1024 and terrain.map.height == 1024 and terrain.map.depth == 96, "approved finite one-kilometre volume")
		check(terrain.map.home_sites.size() == 4, "four native home opportunities")
		check(terrain.map.starter_first_siege_night == 3, "new-world home pressure follows the opening")
	var spawn := terrain.surface_position(int(terrain.map.spawn_x), int(terrain.map.spawn_z))
	await _settle(spawn, 128)
	_pose(spawn, spawn + Vector3(25, 0, -35))
	_review_light(false)
	mood.set_process(true) # Ordinary biome blending during the measured walk.
	if DisplayServer.get_name() != "headless":
		await _capture("starter-valley-day")
		if not visual_only:
			report.settled_spawn = await _sample_frames(600)
			var route: PackedVector3Array = terrain.map.regions[0].approach
			report.walk = await _paced_walk(route, 30.0)
	await _places()
	if DisplayServer.get_name() == "headless": await _save_probe()
	report.final_memory_bytes = Performance.get_monitor(Performance.MEMORY_STATIC)
	report.final_chunks = terrain.chunks.size()
	report.final_active_resources = terrain.resource_stream.active.size()
	report.views = views
	_finish_review()

func _setup_camera() -> void:
	review_camera = Camera3D.new()
	review_camera.fov = 75
	add_child(review_camera)
	review_camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 22)
	caption.add_theme_font_size_override("font_size", 18)
	layer.add_child(caption)

func _pose(at: Vector3, target: Vector3) -> void:
	player.global_position = at + Vector3.UP * 1.2
	review_camera.global_position = _ground(at) + Vector3.UP * 1.65
	if review_camera.global_position.distance_to(target + Vector3.UP * 1.3) > .01:
		review_camera.look_at(target + Vector3.UP * 1.3)

func _stats(values: Array[float]) -> Dictionary:
	if values.is_empty(): return {"samples": 0}
	values.sort()
	return {"samples": values.size(), "median_ms": values[values.size()/2],
		"p95_ms": values[mini(values.size()-1, floori(values.size()*.95))], "max_ms": values.back()}

func _sample_frames(count: int) -> Dictionary:
	for i in 90: await get_tree().process_frame
	var values: Array[float] = []
	for i in count:
		var began := Time.get_ticks_usec()
		await get_tree().process_frame
		values.append((Time.get_ticks_usec() - began)/1000.0)
	var result := _stats(values)
	result.draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	result.primitives = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	return result

func _paced_walk(route: PackedVector3Array, seconds: float) -> Dictionary:
	check(route.size() > 150, "native route supports a thirty-second outward walk")
	if route.size() < 2: return {}
	await _settle(route[0], 128)
	var distances: Array[float] = [0.0]
	for i in range(1, route.size()): distances.append(distances.back() + route[i-1].distance_to(route[i]))
	var cursor := 0
	var values: Array[float] = []
	var active: Array[float] = []
	var began := Time.get_ticks_usec()
	var last := began
	while (Time.get_ticks_usec()-began)/1000000.0 < seconds:
		var travelled := minf(distances.back(), (Time.get_ticks_usec()-began)/1000000.0 * 5.0)
		while cursor+1 < distances.size()-1 and distances[cursor+1] < travelled: cursor += 1
		var weight := clampf((travelled-distances[cursor])/maxf(.001, distances[cursor+1]-distances[cursor]), 0, 1)
		_pose(route[cursor].lerp(route[cursor+1], weight), route[mini(cursor+6, route.size()-1)])
		var preparing := not terrain.chunk_stream._job.is_empty() or not terrain.chunk_stream._pending.is_empty()
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var frame_ms := (now-last)/1000.0
		values.append(frame_ms)
		if preparing: active.append(frame_ms)
		last = now
	return {"all_frames": _stats(values), "preparing_frames": _stats(active), "metres": seconds*5,
		"chunks": terrain.chunks.size(), "engine_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"streaming_phases": _stats(terrain.chunk_stream.phase_build_ms.duplicate()),
		"synchronous_chunks": _stats(terrain.chunk_stream.chunk_build_ms.duplicate()),
		"chunk_retirements": _stats(terrain.chunk_stream.chunk_retire_ms.duplicate())}

func _places() -> void:
	mood.set_process(false)
	var places: Array[Dictionary] = []
	for home: Dictionary in terrain.map.get("home_sites", []): places.append(home)
	for region: Dictionary in terrain.map.regions: places.append(region)
	for place in places:
		var path: PackedVector3Array = place.approach
		check(not path.is_empty(), "supported approach exists: " + String(place.id))
		if path.is_empty(): continue
		var at := path[maxi(0, path.size()-16)]
		var target := Vector3(place.x+.5, place.y, place.z+.5)
		await _settle(at, 64)
		_pose(at, target)
		var ray := PhysicsRayQueryParameters3D.create(_ground(at)+Vector3.UP*3, _ground(at)-Vector3.UP*3, 1)
		check(not get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "actual approach collision: " + String(place.id))
		var row := {"id": place.id, "at": [at.x, at.y, at.z], "target": [target.x, target.y, target.z], "radius_m": place.radius_m}
		if DisplayServer.get_name() != "headless":
			caption.text = String(place.id).replace("_", " ").to_upper() + " · " + world_profile + " · SEED " + str(world_seed)
			_review_light(false)
			await _capture(String(place.id)+"-day")
			_review_light(true)
			await _capture(String(place.id)+"-dusk")
			_review_light(false)
		views.append(row)

func _review_light(dusk: bool) -> void:
	var rules: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://../data/tuning/world.json"))).day
	# Sample the middle of the actual day/dusk phases. At dusk's midpoint
	# the native smooth transition is exactly halfway to night light.
	var fraction := (float(rules.dawn_end)+float(rules.day_end))*.5
	var daylight := 1.0
	if dusk:
		fraction = (float(rules.day_end)+float(rules.dusk_end))*.5
		daylight = (1.0+float(rules.night_light))*.5
	mood.set_day({"fraction":fraction,"daylight":daylight},rules)
	mood._target = mood.active_mood(mood._biome_under_player())
	mood._apply(1.0)

func _save_probe() -> void:
	var manager := SaveManager.new()
	var began := Time.get_ticks_usec()
	var snapshot := manager.capture(player)
	report.capture_ms = (Time.get_ticks_usec()-began)/1000.0
	check(snapshot.world_profile == world_profile and snapshot.world_seed == world_seed, "save owns full identity")
	var ledger: String = _sim().contraption_save()
	check(not _sim().contraption_validate_world("", world_profile, world_seed), "missing source ledger cannot refill pressure")
	check(_sim().contraption_save() == ledger, "validation cannot mutate finite stock")
	var save_path := output.path_join("review-save.json")
	began = Time.get_ticks_usec()
	check(manager.write_data(save_path, snapshot), "atomic isolated save: " + manager.last_error)
	report.write_ms = (Time.get_ticks_usec()-began)/1000.0
	began = Time.get_ticks_usec()
	check(manager.read(save_path, player), "complete restore: " + manager.last_error)
	report.restore_ms = (Time.get_ticks_usec()-began)/1000.0
	check(_sim().contraption_save() == ledger and world_profile == snapshot.world_profile and world_seed == snapshot.world_seed, "restore retains seed, geography and exact source ledger")

func _finish_review() -> void:
	report.checks = checks
	report.failures = failures
	var filename := "checks.json" if DisplayServer.get_name() == "headless" else ("views.json" if visual_only else "manifest.json")
	var file := FileAccess.open(output.path_join(filename), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("WIDE_FRONTIER_REVIEW %d checks, %d failures; %s" % [checks, failures, world_profile])
	get_tree().quit(0 if failures == 0 else 1)
