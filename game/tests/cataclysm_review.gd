extends "res://tests/strange_frontier_review.gd"
## V4 walking-height review in the actual game. Captures are separate from
## timings and never substitute for the owner's discovery/combat playtest.

func _ready() -> void:
	world_profile = "frontier_v4"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cat-seed="): world_seed = int(arg.get_slice("=", 1))
	var began := Time.get_ticks_msec()
	_build_world(world_seed)
	report.world_setup_ms = Time.get_ticks_msec() - began
	report.terrain_startup = terrain.build_profile.duplicate(true)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	mood.set_process(false)
	mood.set_physics_process(false)
	player.hud.notify("")
	output = ProjectSettings.globalize_path("res://../build/cataclysm/seed-%d" % world_seed)
	if "--cat-cost-only" in OS.get_cmdline_user_args(): output = ProjectSettings.globalize_path("res://../build/cataclysm/cost-%d" % world_seed)
	DirAccess.make_dir_recursive_absolute(output)
	_setup_camera()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	report.profile = world_profile
	report.seed = world_seed
	report.scope = "Actual v4 generated world, 1440x900 Forward+, 1.65m eye height, fixed daylight/dusk views. Scripted walks are presentation evidence, not a human playtest. Terrain differs from archived v3."
	report.views = []
	report.routes = []
	await _review()
	report.checks = checks
	report.failures = failures
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("CATACLYSM_REVIEW %d checks, %d failures; seed %d" % [checks, failures, world_seed])
	get_tree().quit(0 if failures == 0 else 1)

func _daylight() -> void:
	mood._target = mood.active_mood(mood._biome_under_player())
	mood._apply(1.0)

func _view(id: String, from: Vector3, toward: Vector3) -> void:
	await _settle(from, 48)
	_daylight()
	review_camera.global_position = _ground(from) + Vector3.UP * 1.65
	review_camera.look_at(toward)
	caption.text = id.replace("_", " ").to_upper() + " · SEED %d" % world_seed
	await _capture(id + "-day")
	var energy: float = $Sun.light_energy
	var colour: Color = $Sun.light_color
	$Sun.light_energy = energy * .48
	$Sun.light_color = Color("d9bd91")
	await _capture(id + "-dusk")
	$Sun.light_energy = energy
	$Sun.light_color = colour
	report.views.append({"id": id, "from": [review_camera.position.x, review_camera.position.y, review_camera.position.z], "toward": [toward.x, toward.y, toward.z]})

func _review() -> void:
	var views_only := "--cat-views-only" in OS.get_cmdline_user_args()
	if "--cat-cost-only" in OS.get_cmdline_user_args():
		await _cost_views()
		return
	var seen: Dictionary = {}
	for ruin: Dictionary in terrain.map.get("ruins", []):
		var region_id := String(ruin.get("region_id", ""))
		var is_forge := "forge" in String(ruin.kind) or "forge" in String(ruin.id)
		if seen.has(region_id) and not is_forge: continue
		if not is_forge: seen[region_id] = true
		var centre := terrain.surface_position(int(ruin.x), int(ruin.z))
		var approach: PackedVector3Array = ruin.approach
		var from := approach[maxi(0, approach.size() - 6)] if not approach.is_empty() else centre + Vector3(0, 0, 10)
		var id := "forge_threshold" if is_forge else region_id + "_ruin"
		await _view(id, from, centre + Vector3.UP * 1.25)
		var route: PackedVector3Array = ruin.get("discovery_route", PackedVector3Array())
		if not views_only and not is_forge and route.size() > 3:
			caption.text = "FROM SURVIVING CRAFT TO RUNAWAY GROWTH · " + region_id.replace("_", " ").to_upper()
			_daylight()
			var timing := await _timed_route(route)
			var record := await _walk(region_id, route)
			record.id = region_id
			record.timing_without_captures = timing
			report.routes.append(record)
	var gate := get_node("TrialGate") as Node3D
	await _view("trial_gate", gate.global_position + Vector3(7, 0, 2), gate.global_position + Vector3.UP * 2)
	for impact: Dictionary in terrain.map.get("impacts", []):
		var centre := terrain.surface_position(int(impact.x), int(impact.z))
		var direction: Vector3 = impact.get("impact_direction", Vector3.FORWARD)
		var from := centre - direction * 8.0 + Vector3(direction.z, 0, -direction.x) * 5.0
		await _view(String(impact.region_id) + "_impact", from, centre + Vector3.UP * 1.1)
	# Actual resource/work lifecycle, followed by the existing home demonstration.
	for site: Dictionary in terrain.map.rare_sites:
		if site.resource_type != "thrumroot": continue
		var at := terrain.surface_position(int(site.x), int(site.z))
		await _settle(at, 32)
		_daylight()
		var path: PackedVector3Array = site.approach
		review_camera.global_position = _ground(path[maxi(0, path.size() - 5)]) + Vector3.UP * 1.65
		review_camera.look_at(at + Vector3.UP * .7)
		caption.text = "STORED TENSION · A THRUMROOT FIND"
		await _capture("thrumroot-intact")
		for row: Dictionary in terrain.map.nodes:
			if row.get("site_id", "") != site.id: continue
			var node := terrain.resource_stream.materialise(String(row.resource_id))
			if node == null: continue
			var result: Dictionary = {}
			for press in node.drive_presses: result = node.work(_sim())
			check(int(result.get("granted", 0)) > 0, "reference discovery uses ordinary contextual work")
			caption.text = "CONTEXTUAL WORK RELEASES THE COMPONENT · ITS HOUSING REMAINS"
			await _capture("thrumroot-worked")
			break

		break
	await _interior()
	await _cost_views()

func _cost_views() -> void:
	# Matched v4 views with presentation shown/hidden isolate its rendering cost.
	var history := get_node("CataclysmSites") as Node3D
	var seen: Dictionary = {}
	for ruin: Dictionary in terrain.map.ruins:
		if "forge" not in String(ruin.kind): seen[String(ruin.region_id)] = true
	for region_id in seen:
		for ruin: Dictionary in terrain.map.ruins:
			if ruin.region_id != region_id: continue
			if "forge" in String(ruin.kind): continue
			var centre := terrain.surface_position(int(ruin.x), int(ruin.z))
			var approach: PackedVector3Array = ruin.approach
			var from := approach[maxi(0, approach.size() - 6)]
			await _settle(from, 144)
			_daylight()
			review_camera.global_position = _ground(from) + Vector3.UP * 1.65
			review_camera.look_at(centre + Vector3.UP * 1.2)
			terrain.set_process(false)
			var shown := await _frames()
			history.hide()
			var hidden := await _frames()
			history.show()
			terrain.set_process(true)
			report.views.append({"id": String(region_id) + "_cost", "shown": shown, "hidden": hidden})
			break

func _frames() -> Dictionary:
	var values: Array[float] = []
	for i in 660:
		var begin := Time.get_ticks_usec()
		await get_tree().process_frame
		if i >= 60: values.append(float(Time.get_ticks_usec() - begin) / 1000)
	values.sort()
	return {"median": values[300], "p95": values[570], "samples": 600,
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"loaded_chunks": terrain.chunks.size(), "active_resources": terrain.resource_stream.active.size()}

func _timed_route(path: PackedVector3Array) -> Dictionary:
	# Separate actual streaming walk with no image readback. Camera animation
	# keeps the same 5 m/s speed and ordinary eye height as the archived v3 route.
	await _settle(path[0], 64)
	var values: Array[float] = []
	var distance := 0.0
	var previous := Time.get_ticks_usec()
	review_camera.global_position = _ground(path[0]) + Vector3.UP * 1.65
	for index in range(1, path.size() - 3):
		var target := path[index]
		while Vector2(review_camera.position.x - target.x, review_camera.position.z - target.z).length() > .05:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			var ms := float(now - previous) / 1000.0
			previous = now
			values.append(ms)
			var current := Vector3(review_camera.position.x, 0, review_camera.position.z)
			var step := current.move_toward(Vector3(target.x, 0, target.z), 5.0 * minf(ms / 1000.0, .05))
			distance += current.distance_to(step)
			var ground := _ground(step)
			check(ground.is_finite(), "timed v4 route has a rendered walking surface")
			if not ground.is_finite(): break
			review_camera.global_position = ground + Vector3.UP * 1.65
			player.global_position = ground + Vector3.UP * 1.2
			var ahead := path[mini(path.size() - 1, index + 5)] + Vector3.UP * 1.65
			if ahead.distance_to(review_camera.global_position) > .1: review_camera.look_at(ahead)
	values.sort()
	return {"samples": values.size(), "distance_m": distance, "median_ms": values[values.size() / 2],
		"p95_ms": values[int(values.size() * .95)], "max_ms": values.back(), "capture_readbacks": 0}
