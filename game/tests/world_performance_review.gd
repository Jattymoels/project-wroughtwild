extends "res://tests/wide_frontier_review.gd"
## Common INT-07B fixture copied into both preserved and current projects.
## Reuses the historical rendered route; no production API introduced by this
## slice is required. This is a scripted camera journey, not physical walking.
var phase := "current"
var capture_rows: Array[Dictionary] = []

func _ready() -> void:
	world_profile = "frontier_v6"
	world_seed = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-profile="): world_profile = arg.trim_prefix("--review-profile=")
		if arg.begins_with("--review-seed="): world_seed = int(arg.trim_prefix("--review-seed="))
		if arg.begins_with("--review-phase="): phase = arg.trim_prefix("--review-phase=")
	output = ProjectSettings.globalize_path("res://../build/world-performance/" + phase)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="): output = arg.trim_prefix("--review-output=")
	check(DirAccess.make_dir_recursive_absolute(output) == OK, "isolated review output is writable")
	var rendered := DisplayServer.get_name() != "headless"
	if rendered:
		DisplayServer.window_set_size(Vector2i(1440, 900))
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
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
	report.merge({"phase": phase, "profile": world_profile, "seed": world_seed,
		"rendered": rendered, "resolution": [DisplayServer.window_get_size().x, DisplayServer.window_get_size().y] if rendered else [], "fps_cap": Engine.max_fps,
		"resource_records": terrain.resource_stream.records.size(), "pack_records": mob_packs.packs.size(),
		"initial_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"scope": "Cold isolated process; same native region[0] approach, full world presentation, FOV75 and 1.65m eye. Scripted camera and pawn positions follow the route at 5m/s for 30s (nominal 150m); player physics/combat and world clock disabled, ordinary terrain/resource streaming and biome blending active. This is not a physical traversal or combat playtest. The reported frame cap limits spare-capacity conclusions. Memory is engine static allocations, excluding native stdlib/process peak and GPU memory.",
		"correctness_fixture": "Run wide_terrain_stream separately for exact retired/returned terrain, collision, excavation seams, partial/depleted nodes and save restoration; this timing fixture does not replace those assertions."})
	check(terrain.world_profile() == world_profile, "terrain and selected identity agree")
	check(terrain.map.regions.size() == 3 and terrain.map.habitats.size() == 3, "all three regions and building habitats exist")
	if world_profile == "frontier_v6":
		check(terrain.map.width == 1024 and terrain.map.height == 1024 and terrain.map.depth == 96, "same finite V6 volume")
		check(terrain.map.home_sites.size() == 4, "four home opportunities remain")
	var route: PackedVector3Array = terrain.map.regions[0].approach
	var route_length := 0.0
	for i in range(1, route.size()): route_length += route[i-1].distance_to(route[i])
	check(route_length >= 150.0, "native approach provides the full measured 150 metres")
	report.route = {"region": terrain.map.regions[0].id, "points": route.size(), "length_m": route_length,
		"fingerprint": str(hash(route)), "speed_m_per_second": 5.0, "duration_seconds": 30.0}
	var spawn := terrain.surface_position(int(terrain.map.spawn_x), int(terrain.map.spawn_z))
	await _settle(spawn, 128)
	_pose(spawn, spawn + Vector3(25, 0, -35))
	_review_light(false)
	mood.set_process(true)
	if rendered:
		await _review_capture("starter-valley-day")
		report.settled_spawn = await _sample_frames(600)
		# Clear only historical diagnostic buffers. Normal streaming retains its
		# job, queue and scheduling; no timing sample changes game behaviour.
		terrain.chunk_stream.phase_build_ms.clear()
		terrain.chunk_stream.chunk_build_ms.clear()
		terrain.chunk_stream.chunk_retire_ms.clear()
		report.walk = await _paced_walk(route, 30.0)
		report.walk["diagnostic_scope"] = "Aggregate rolling buffers reset before route setup; include its synchronous settle. Per-stage accessor, when available, is the production rolling window and may retain setup samples. Pending-work frames have a job or queue immediately before their process-frame wait."
		report.walk["preparation_stages"] = _preparation_report()
		check(int(report.walk.all_frames.samples) > 0, "rendered journey sampled frames")
		check(int(report.walk.preparing_frames.samples) > 0, "journey exercises pending terrain preparation")
		# Match the final picture exactly, rather than the last timer-dependent
		# fraction of the route. Captures occur outside all frame sample windows.
		_pose_on_route(route, 150.0)
		await _review_capture("route-150m-day")
		mood.set_process(false)
		_review_light(true)
		await _review_capture("route-150m-dusk")
	else:
		report["timing_note"] = "Headless smoke/save check only; no rendered frame-performance claim."
		await _save_probe()
	report.last_synchronous_chunk_ms = terrain.last_chunk_profile.duplicate(true)
	report.retention = terrain.chunk_stream.retention()
	report.final_memory_bytes = Performance.get_monitor(Performance.MEMORY_STATIC)
	report.final_active_resources = terrain.resource_stream.active.size()
	report.captures = capture_rows
	_finish_review()

func _preparation_report() -> Dictionary:
	var result := {"available": false, "scope": "Not instrumented in this preserved production version; use aggregate streaming_phases and last_synchronous_chunk_ms."}
	if terrain.chunk_stream.has_method("preparation_samples"):
		var samples: Dictionary = terrain.chunk_stream.call("preparation_samples")
		result = {"available": true, "scope": "Bounded production rolling samples, per actual preparation stage."}
		for stage in samples:
			var values: Array[float] = []
			for value in samples[stage]: values.append(float(value))
			result[String(stage)] = _stats(values)
	return result

func _pose_on_route(route: PackedVector3Array, metres: float) -> void:
	for index in range(1, route.size()):
		var length := route[index-1].distance_to(route[index])
		if metres <= length:
			_pose(route[index-1].lerp(route[index], metres/maxf(.001, length)), route[mini(index+5, route.size()-1)])
			return
		metres -= length

func _review_capture(id: String) -> void:
	caption.text = "WORLD PREPARATION REVIEW · " + world_profile + " · SEED " + str(world_seed)
	await _capture(id)
	check(FileAccess.file_exists(output.path_join(id + ".png")), "actual gameplay image written: " + id)
	capture_rows.append({"id": id, "file": id + ".png", "camera": [review_camera.global_position.x, review_camera.global_position.y, review_camera.global_position.z],
		"rotation": [review_camera.global_rotation.x, review_camera.global_rotation.y, review_camera.global_rotation.z]})

func _finish_review() -> void:
	report.checks = checks
	report.failures = failures
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	if file == null:
		failures += 1
		printerr("FAIL WORLD PERFORMANCE: could not write isolated manifest")
	else:
		file.store_string(JSON.stringify(report, "\t"))
		file.close()
	print("WORLD_PERFORMANCE_REVIEW %d checks, %d failures; %s seed %d phase %s" % [checks, failures, world_profile, world_seed, phase])
	get_tree().quit(0 if failures == 0 else 1)
