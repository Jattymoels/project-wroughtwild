extends "res://tests/travel_performance_review.gd"
## One synthetic opening into the recorded cave; actual fall has no warmup.
func _ready() -> void:
	output = OS.get_environment("WROUGHTWILD_PLAY03_OUTPUT")
	world_seed = 1
	world_profile = "frontier_v6"
	var setup_start := Time.get_ticks_usec()
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false) # Synthetic staging only, released below.
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "mouse stays visible")
	check(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS), "window cannot focus")
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
	report["world_setup_ms"] = (Time.get_ticks_usec()-setup_start)/1000.0
	await get_tree().physics_frame
	await get_tree().physics_frame
	setup_start = Time.get_ticks_usec()
	var entry := Vector3(495.5,terrain.height_at(495,361)+1.1,361.5)
	var fixture_edits: Array = []
	for x in range(494,497):
		for z in range(360,363):
			for y in range(25,terrain.height_at(x,z)+1):
				if terrain.block_at(x,y,z) != 0: fixture_edits.append([x,y,z])
	report["breach_selection_ms"] = (Time.get_ticks_usec()-setup_start)/1000.0
	check(not fixture_edits.is_empty(), "explicit synthetic opening reaches the previously recorded cave floor")
	if not entry.is_finite():
		get_tree().quit(1)
		return
	report["entry"] = [entry.x,entry.y,entry.z]
	report["scope"] = "Seed 1 V6 at (495.5,361.5), the prior documented cave. Synthetic 3x3 opening removes only voxels at Y>=25 via the existing saved-edit path, with its synchronous time retained. Synthetic relocation above it, two frames held for ordinary stream guard, then real gravity, collision, actors, world processing and stationary landing. No explicit ensure_area or extra warmup, no support queries/screenshots/disk writes during frame sampling. No active digging needed during the drop. Not the owner's route; edit preparation is fixture-only."
	report["settings"] = {"resolution":[1280,720],"fps_cap":120,"vsync":"disabled","renderer":"forward_plus"}
	var rows: Array[Dictionary] = []
	var elapsed := 0.0
	var landed_at := -1.0
	var last := Time.get_ticks_usec()
	var window := "before_fixture_relocation"
	while elapsed < 12.0 and rows.size() < 1800:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var ms := (now-last)/1000.0
		elapsed += ms/1000.0
		var row := _frame_row(ms)
		row.merge(player.motion_sample)
		row["window"] = window
		row["elapsed_s"] = elapsed
		row["position"] = [player.position.x,player.position.y,player.position.z]
		row["projection_pending"] = terrain.resource_stream._projection_pending.size()
		row["terrain_pending"] = terrain.chunk_stream._pending.size()
		row["chunks_built_total"] = terrain.chunk_stream.chunks_built_total
		row["focus"] = [terrain.chunk_stream._focus.x,terrain.chunk_stream._focus.y,terrain.chunk_stream._focus.z]
		row["enemies"] = get_tree().get_nodes_in_group("enemies").size()
		rows.append(row)
		last = now
		if rows.size() == 1:
			player.position = entry
			player.velocity = Vector3.ZERO
			var edit_began := Time.get_ticks_usec()
			terrain.apply_broken_blocks(fixture_edits)
			report["fixture_edit_ms"] = (Time.get_ticks_usec()-edit_began)/1000.0
			window = "fixture_edit_arrival_and_stream_guard"
		elif rows.size() == 3:
			player.set_physics_process(true)
			window = "entry_and_fall"
		if rows.size() > 3 and player.is_on_floor() and player.position.y < entry.y-4.0:
			if landed_at < 0.0: landed_at = elapsed
			window = "landed_stationary"
		if landed_at >= 0.0 and elapsed-landed_at >= 4.0: break
	check(landed_at >= 0.0, "actual capsule drops at least four metres and lands on native collision")
	check(landed_at >= 0.0 and elapsed-landed_at >= 4.0, "four seconds after landing are retained")
	check(player.combat.is_physics_processing() and mob_packs.is_physics_processing(), "normal combat and packs stay active")
	check(terrain.broken.size() == fixture_edits.size(), "drop adds no edits beyond the explicitly staged opening")
	report["windows"] = {}
	for label in ["before_fixture_relocation","fixture_edit_arrival_and_stream_guard","entry_and_fall","landed_stationary"]:
		var times: Array[float] = []
		for row in rows:
			if row.window == label: times.append(float(row.frame_ms))
		report.windows[label] = _stats(times) if not times.is_empty() else {}
	report["landed_at_s"] = landed_at
	report["end"] = [player.position.x,player.position.y,player.position.z]
	report["checks"] = checks
	report["failures"] = failures
	report["retention"] = terrain.chunk_stream.retention()
	FileAccess.open(output.path_join("frames.json"),FileAccess.WRITE).store_string(JSON.stringify(rows))
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("PLAY03_TRANSITION ",JSON.stringify(report))
	get_tree().quit(0 if failures == 0 else 1)
