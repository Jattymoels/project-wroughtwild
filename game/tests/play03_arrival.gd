extends Sandpit
## One disclosed placement outside a normal pack; subsequent movement is real.
var checks := 0
var failures := 0
var output := ""
var report := {}
var trace: Node
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ARRIVAL ", label)
	return ok
func _ready() -> void:
	output = OS.get_environment("WROUGHTWILD_ARRIVAL_OUTPUT")
	trace = preload("res://scripts/play03_trace.gd").install(self, PackedStringArray(["--play03-trace="+output]))
	world_seed = 77
	world_profile = "frontier_v8"
	var began := Time.get_ticks_usec()
	_build_world(world_seed)
	player.class_panel.choose("warden")
	report["world_setup_ms"] = (Time.get_ticks_usec()-began)/1000.0
	_run.call_deferred()
func _run() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "mouse remains visible")
	check(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS), "window cannot focus")
	var chosen := {}
	var distance := INF
	var spawn := player.position
	for p: Dictionary in mob_packs.packs:
		if p.biome == "cave" or p.grazer: continue
		var d := mob_packs.pack_position(p).distance_to(spawn)
		if d < distance:
			distance = d
			chosen = p
	if not check(not chosen.is_empty(), "reachable surface pack selected"):
		finish()
		return
	var at := mob_packs.pack_position(chosen)
	var axis := ((at-spawn)*Vector3(1,0,1)).normalized()
	var start := at-axis*34.0
	start.y = terrain.height_at(floori(start.x),floori(start.z))+1.1
	player.position = start
	player.velocity = Vector3.ZERO
	player.rotation.y = atan2(-axis.x,-axis.z)
	player.spring_arm.rotation.x = -.08
	report["pack"] = {"index":chosen.index, "enemies":Array(chosen.enemies), "position":[at.x,at.y,at.z]}
	report["initial_position"] = [start.x,start.y,start.z]
	report["initial_distance"] = at.distance_to(start)
	check(at.distance_to(start)>28.0 and not chosen.spawned, "staged outside activation before any chosen member exists")
	check(not RecoveredActorArt._meshes.has("ember_whelp") and not FinishedFauna._scenes.has("boar"), "selected boar assets have not been used (spawn-area grazers may already exist)")
	trace.note_arrival("fixture_position",Time.get_ticks_usec())
	# Normal guard/streaming runs from this position, with all pack processing on.
	for i in 90: await get_tree().process_frame
	check(not chosen.spawned, "selected pack remains dormant before walking")
	check(not RecoveredActorArt._meshes.has("ember_whelp") and not FinishedFauna._scenes.has("boar"), "selected assets still unused immediately before walking")
	report["walk_start_frame"] = Engine.get_process_frames()
	trace.note_arrival("walk_start",Time.get_ticks_usec())
	var arrived := -1
	var walk_start := Time.get_ticks_msec()
	player.test_walk = Vector2(0,-1)
	while Time.get_ticks_msec()-walk_start < 8000:
		await get_tree().process_frame
		if chosen.spawned and arrived < 0:
			arrived = Time.get_ticks_msec()
			player.test_walk = Vector2.ZERO
			report["arrival_frame"] = Engine.get_process_frames()
			report["arrival_distance"] = at.distance_to(player.position)
		if arrived >= 0 and Time.get_ticks_msec()-arrived >= 2200: break
	player.test_walk = Vector2.ZERO
	check(arrived >= 0, "ordinary walking crosses activation and constructs pack")
	check(player.is_physics_processing() and mob_packs.is_physics_processing() and terrain.is_processing() and is_physics_processing(), "ordinary world, player, packs and streaming remain active")
	check(not player.trial.active() and terrain.world_profile()=="frontier_v8" and terrain.map.lakes.size()==1, "normal V8 including lake remains loaded")
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS), "comfort flags retained")
	report["members"] = []
	for e: Enemy in chosen.members:
		var motion := e._mesh.get_node("Motion") as CreatureMotion
		var box := e._mesh.mesh.get_aabb()
		report.members.append({"id":String(e.enemy_id), "role":e.behaviour, "bounds_position":[box.position.x,box.position.y,box.position.z], "bounds_size":[box.size.x,box.size.y,box.size.z], "model_scale":str(motion.finished.model.scale) if motion.finished != null else "", "model_position":str(motion.finished.model.position) if motion.finished != null else "", "life":e.life})
	finish()
func finish() -> void:
	trace.stop("arrival_complete")
	report["checks"] = checks
	report["failures"] = failures
	report["trace"] = trace.output_path
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ARRIVAL_RESULT ",JSON.stringify(report))
	get_tree().quit(0 if failures==0 else 1)
