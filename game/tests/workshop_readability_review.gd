extends "res://tests/pressure_workshop.gd"
## The same fixture runs against preserved and current production. It uses
## existing V6 generation, paid kit/building paths, and actual panel callbacks.
## Seeded supplies and inspected poses are engineering evidence, not playtest.
var review_height := 720
var report := {"captures":[], "states":[], "actions":[], "timing":{}}
var samples: Array[float] = []
var measuring := false
var previous_usec := 0
var timing_cpu := Vector3.ZERO
var sweep_camera := false
var sweep_started := 0
var workshop_at := Vector3.ZERO
var first_person_at := Vector3.ZERO

func _ready() -> void:
	world_seed = 77
	world_profile = "frontier_v6"
	output = ProjectSettings.globalize_path("res://../captures/workshop")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="): output = arg.trim_prefix("--review-output=")
		if arg.begins_with("--review-height="): review_height = int(arg.trim_prefix("--review-height="))
		if arg.begins_with("--cat-seed="): world_seed = int(arg.trim_prefix("--cat-seed="))
	check(review_height in [720, 1080], "review uses an approved panel resolution")
	get_window().size = Vector2i(roundi(review_height * 16.0 / 9.0), review_height)
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	DirAccess.make_dir_recursive_absolute(output)
	var started := Time.get_ticks_usec()
	_build_world(world_seed)
	report.world_startup_ms = (Time.get_ticks_usec() - started) / 1000.0
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	await _review_frames()
	var pockets: Array = terrain.map.get("pressure_pockets", [])
	check(pockets.size() == 1, "actual V6 world contains its finite pressure source")
	if pockets.size() != 1: _finish(); return
	var definition: Dictionary = pockets[0]
	source = PressurePocket.find_source(get_tree(), String(definition.id))
	check(source != null and definition.origin == "pre_cataclysm_blacksmith" and bool(definition.accidental), "source is the accidental impact at an older smithy")
	if source == null: _finish(); return
	workshop_at = definition.work_position
	terrain.ensure_area(workshop_at, 30)
	player.global_position = workshop_at + Vector3(0, 1.2, 5)
	await _review_frames(6)
	# Hold the actual local daylight rather than let comparison runs drift.
	_tick_day(0)
	mood._process(100.0)
	mood.set_process(false)
	terrain.set_process(false)
	check(source.supported(), "source stands on actual generated terrain")
	if "--performance-only" not in OS.get_cmdline_user_args():
		check(await _aim_from_ground(source), "player-height aim reaches the old hearth")
		player.interact()
		check(player.work_panel.is_open(), "normal E opens the source inspection")
		await _snap("struck-hearth-panel", "Existing finite source inspection before the new workshop")
		player.work_panel.close_panel()
	_sim().add_station("workbench")
	player.global_position = workshop_at + Vector3(0, 1.2, 5)
	await _place_workshop(workshop_at)
	check(feeder != null and forge != null, "seeded recipe supplies make two paid, physically placed kits")
	if feeder == null or forge == null: _finish(); return
	feeder_key = feeder.machine_key
	await _open_feeder()
	# Both versions expose these actual choices, on a subpage or the old list.
	check(await _press("page:attach"), "open physical forge and pocket choices")
	check(await _press("attach:" + forge.station_key + ":" + source.source_id), "attach through the actual local choice callback")
	check(String(_state().get("forge_key", "")) == forge.station_key and String(_state().get("source_id", "")) == source.source_id, "attachment owns this placed forge and finite source")
	if "--performance-only" not in OS.get_cmdline_user_args(): await _capture_state("empty")
	_sim().add_materials({"raw_clay":32, "wood":4})
	await _open_feeder()
	check(await _press("load:wood"), "load ordinary fuel through the actual hopper control")
	check(_state().input == {"wood":4}, "fuel-only hopper contains fuel, no clay")
	if "--performance-only" not in OS.get_cmdline_user_args(): await _capture_state("fuel-only")
	check(await _press("load:raw_clay"), "load clay through the actual hopper control")
	await _open_feeder()
	check(await _press("action:charge"), "draw finite pressure through the actual drive control")
	check(_state().input == {"raw_clay":32, "wood":4} and int(_state().energy) == 4 and int(source.source_state().remaining) == 20, "ready stock and source debit are exact")
	if "--performance-only" not in OS.get_cmdline_user_args():
		await _capture_state("ready")
		await _capture_page("hopper", "ready-supplies")
		await _capture_page("drive", "ready-drive")
	await _open_feeder()
	check(await _press("action:start"), "start through the actual production control")
	feeder._physics_process(2.0)
	check(int(_state().escrow_drive) == 1 and float(_state().cycle_seconds) == 2.0, "one live firing owns two seconds of existing work")
	if "--performance-only" not in OS.get_cmdline_user_args(): await _capture_state("firing")
	await _open_feeder()
	check(await _press("action:pause"), "pause through the actual production control")
	var paused: String = _sim().contraption_save()
	feeder._physics_process(2.0)
	check(_sim().contraption_save() == paused, "paused presentation does not advance or change escrow")
	if "--performance-only" not in OS.get_cmdline_user_args(): await _capture_state("paused")
	check(await _press("action:resume"), "resume through the actual production control")
	for cycle in 4: feeder._physics_process(8.0)
	check(_state().output == {"rustclay_brick":16} and int(_state().completed_cycles) == 4 and int(_state().escrow_drive) == 0, "four scripted active firings pay the existing sixteen-brick output exactly")
	if "--performance-only" not in OS.get_cmdline_user_args(): await _capture_state("completed")
	await _open_feeder()
	var carried: int = _sim().material_count("rustclay_brick")
	check(await _press("take:output:rustclay_brick"), "collect completed bricks through the actual tray callback")
	check(_sim().material_count("rustclay_brick") == carried + 16 and Dictionary(_state().output).is_empty(), "collection transfers completed output once")
	player.work_panel.close_panel()
	player.global_position = workshop_at + Vector3(0, 1.2, 5)
	await _build_bricks(workshop_at)
	if "--performance-only" not in OS.get_cmdline_user_args():
		await _aim_from_ground(feeder)
		player.camera.look_at(workshop_at + Vector3(-2, 0.55, 3))
		await _snap("built-brick-handoff", "Three paid masonry pieces use bricks collected from this feeder")
		_record_state("built-brick-handoff")
	if "--skip-performance" not in OS.get_cmdline_user_args(): await _timing_review()
	_finish()

func _review_frames(count := 5) -> void:
	for i in count: await get_tree().process_frame

func _state() -> Dictionary:
	return _sim().contraption_state(feeder_key)

func _aim_from_ground(body: StaticBody3D) -> bool:
	var target := body.global_position + Vector3.UP * 0.8
	for child in body.get_children():
		if child is CollisionShape3D: target = child.global_position; break
	for direction: Vector3 in [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]:
		var near := body.global_position + direction * 2.6
		var floor_at := StrangeSites._ground(terrain, near.x, near.z)
		if not floor_at.is_finite(): continue
		player.global_position = floor_at + Vector3.UP * 0.96
		player.velocity = Vector3.ZERO
		player.camera.global_position = player.global_position + Vector3.UP * player.FP_EYE_HEIGHT
		player.camera.look_at(target)
		player.camera.make_current()
		await get_tree().physics_frame
		if player.aim_probe().get("target") == body:
			first_person_at = player.camera.global_position
			return true
	return false

func _open_feeder() -> void:
	player.work_panel.close_panel()
	check(await _aim_from_ground(feeder), "grounded first-person aim reaches the actual feeder body")
	player.interact()
	check(player.work_panel.is_open() and player.work_panel._custom_title == "Pressure feeder", "normal E opens this feeder's main page")
	player.work_panel._scroll.scroll_vertical = 0
	await _review_frames()

func _row_for(id: String) -> Dictionary:
	for row: Dictionary in player.work_panel._custom_rows:
		if String(row.get("id", "")) == id: return row
	# These are the preserved version's real rows, not substitute operations.
	for row: Dictionary in player.work_panel._custom_rows:
		var caption := String(row.get("button", ""))
		var callback: Callable = row.get("callback", Callable())
		if not callback.is_valid(): continue
		var bound := callback.get_bound_arguments()
		if id.begins_with("load:") and callback.get_method() == "_deposit" and bound.size() >= 1 and String(bound[0]) == id.trim_prefix("load:"): return row
		if id.begins_with("take:") and callback.get_method() == "_withdraw" and bound.size() >= 2 and String(bound[0]) == id.get_slice(":", 1) and String(bound[1]) == id.get_slice(":", 2): return row
		if id.begins_with("action:") and callback.get_method() == "_operate" and bound.size() >= 1 and String(bound[0]) == id.trim_prefix("action:"): return row
		if id == "page:attach" and caption == "Choose forge and pocket": return row
		if id.begins_with("attach:") and caption == "Attach forge and pocket": return row
	return {}

func _press(id: String) -> bool:
	var row := _row_for(id)
	if row.is_empty():
		var page := "page:hopper" if id.begins_with("load:") else "page:drive" if id in ["action:charge", "action:wind", "page:attach"] else "page:main"
		var navigation := _row_for(page)
		if not navigation.is_empty():
			if not await _press_row(navigation, page): return false
			row = _row_for(id)
	if row.is_empty():
		printerr("Missing review action: ", id)
		return false
	return await _press_row(row, id)

func _press_row(row: Dictionary, id: String) -> bool:
	if not bool(row.get("enabled", true)): return false
	for button in player.work_panel._body.find_children("*", "Button", true, false):
		if button.text != String(row.get("button", "")) or button.disabled: continue
		player.work_panel._scroll.ensure_control_visible(button)
		await _review_frames(3)
		if not is_instance_valid(button) or button.disabled: return false
		report.actions.append({"id":id, "button":button.text})
		button.pressed.emit()
		await _review_frames()
		return true
	return false

func _capture_state(id: String) -> void:
	player.work_panel.close_panel()
	feeder.refresh_from_sim()
	check(await _aim_from_ground(feeder), id + " has a real player-height inspection ray")
	await _snap(id + "-world", "Existing feeder at " + id + "; actual first-person HUD and physical supplies")
	await _open_feeder()
	await _snap(id + "-panel", "Existing local controls at " + id + "; no synthetic labels or debug overlay")
	_record_state(id)

func _capture_page(page: String, id: String) -> void:
	await _open_feeder()
	var ledger: String = _sim().contraption_save()
	# A current page is reached through its actual navigation row. The preserved
	# list has no such row and keeps its corresponding controls in the main view.
	var navigation := _row_for("page:" + page)
	if not navigation.is_empty(): check(await _press_row(navigation, "page:" + page), "open " + page + " review page")
	await _snap(id, "Actual " + page + " controls; preserved production uses its single main list")
	for button in player.work_panel._body.find_children("*", "Button", true, false):
		if button.text != "Details" or not button.visible: continue
		button.button_pressed = true
		break
	await _snap(id + "-expanded", "Optional " + page + " explanation expanded with Close and actions available")
	check(_sim().contraption_save() == ledger, "opening and expanding " + page + " never performs workshop work")

func _record_state(id: String) -> void:
	var rows := []
	for row: Dictionary in player.work_panel._custom_rows:
		rows.append({"text":row.get("text", ""), "button":row.get("button", ""), "enabled":row.get("enabled", true)})
	report.states.append({"id":id, "machine":_state(), "source_remaining":source.source_state().remaining,
		"carried_bricks":_sim().material_count("rustclay_brick"), "rows":rows,
		"eye":[player.camera.global_position.x,player.camera.global_position.y,player.camera.global_position.z]})

func _snap(id: String, description: String) -> void:
	player.hud._notice_timer = 0
	player.hud._notice.text = ""
	player.hud.refresh()
	player.hud._refresh_crosshair()
	await _review_frames(6)
	if player.work_panel.is_open():
		var bounds := player.work_panel._root.get_global_rect()
		check(bounds.position.x >= 0 and bounds.position.y >= 0 and bounds.end.x <= get_window().size.x + 1 and bounds.end.y <= get_window().size.y + 1, id + " panel and Close fit the viewport")
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	var filename := "%dp-%s.png" % [review_height, id]
	check(get_viewport().get_texture().get_image().save_png(output.path_join(filename)) == OK, "capture " + filename)
	report.captures.append({"file":filename, "description":description})

func _process(_delta: float) -> void:
	if sweep_camera and is_instance_valid(feeder):
		var phase := float(Time.get_ticks_usec() - sweep_started) / 1000000.0
		var target := feeder.global_position.lerp(source.global_position, (sin(phase * 0.5) + 1.0) * 0.25) + Vector3.UP * 0.9
		player.camera.look_at(target)
	if not measuring: return
	var now := Time.get_ticks_usec()
	if previous_usec > 0: samples.append(float(now - previous_usec) / 1000.0)
	previous_usec = now
	timing_cpu += Vector3(Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0,
		Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

func _timing_review() -> void:
	_sim().add_materials({"raw_clay":32, "wood":4})
	await _open_feeder()
	check(await _press("load:raw_clay"), "timing cohort loads clay through the UI")
	check(await _press("load:wood"), "timing cohort loads fuel through the UI")
	await _open_feeder()
	check(await _press("action:charge"), "timing cohort draws only finite remaining pressure")
	await _open_feeder()
	check(await _press("action:start"), "timing cohort starts the existing four-firing batch")
	player.work_panel.close_panel()
	await _aim_from_ground(feeder)
	feeder.set_physics_process(true)
	await _sample_timing("world", true)
	await _open_feeder()
	await _sample_timing("live_panel", false)
	feeder.set_physics_process(false)
	check(int(_state().escrow_drive) > 0 and int(_state().completed_cycles) > 4, "performance samples contain real advancing workshop work")

func _sample_timing(id: String, move_view: bool) -> void:
	sweep_camera = move_view
	sweep_started = Time.get_ticks_usec()
	var warm_started := Time.get_ticks_msec()
	while Time.get_ticks_msec() - warm_started < 3000: await _review_frames(1)
	samples.clear()
	previous_usec = 0
	timing_cpu = Vector3.ZERO
	sweep_started = Time.get_ticks_usec()
	var sample_started := Time.get_ticks_msec()
	measuring = true
	while Time.get_ticks_msec() - sample_started < 5000: await _review_frames(1)
	measuring = false
	sweep_camera = false
	samples.sort()
	check(not samples.is_empty(), id + " records actual elapsed frames")
	if samples.is_empty(): return
	report.timing[id] = {"frames":samples.size(), "median_ms":samples[samples.size() / 2],
		"p95_ms":samples[ceili(samples.size() * 0.95) - 1], "mean_process_ms":timing_cpu.x / samples.size(),
		"mean_physics_ms":timing_cpu.y / samples.size(), "mean_draw_calls":timing_cpu.z / samples.size(),
		"warmup_ms":3000, "sample_ms":Time.get_ticks_msec() - sample_started, "capture_readbacks":0,
		"active_machine_count":1, "completed_cycles":int(_state().completed_cycles), "cycle_seconds":float(_state().cycle_seconds)}

func _finish() -> void:
	report.checks = checks
	report.failures = failures
	report.profile = world_profile
	report.seed = world_seed
	report.height = review_height
	report.renderer = DisplayServer.get_name()
	report.scope = "Same V6 seed and paid kit/masonry paths in baseline/current. Recipe supplies are explicitly seeded; control callbacks, geometry, escrow and output are real. Screenshots hold inspected first-person poses and scripted firing states. Timings use live machine physics, 3 s warmup and 5 s samples with no screenshot readbacks; world view sweeps from a fixed grounded approach. This does not certify human comprehension, discovery pace, physical walking or fun."
	var filename := "%dp-%s.json" % [review_height, "performance" if "--performance-only" in OS.get_cmdline_user_args() else "manifest"]
	var file := FileAccess.open(output.path_join(filename), FileAccess.WRITE)
	check(file != null, "write isolated common workshop report")
	if file != null:
		report.checks = checks
		report.failures = failures
		file.store_string(JSON.stringify(report, "  "))
		file.close()
	print("WORKSHOP_READABILITY_REVIEW %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
