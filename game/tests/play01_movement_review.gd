extends "res://tests/travel_performance_review.gd"
## One short real-controller route. No screenshots or disk writes while timed.
func _ready() -> void:
	output = ProjectSettings.globalize_path("res://../build/play01/diagnosis")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="): output = arg.trim_prefix("--review-output=")
	DirAccess.make_dir_recursive_absolute(output)
	world_seed = 1
	world_profile = "frontier_v6"
	_build_world(world_seed)
	player.class_panel.choose("warden")
	var underground := OS.get_cmdline_user_args().has("--play01-underground")
	if underground and not await _place_in_cave():
		get_tree().quit(1)
		return
	if DisplayServer.get_name() != "headless":
		check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "test mouse remains visible")
		check(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS), "test window cannot focus")
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
	for i in 120: await get_tree().process_frame
	var start := player.global_position
	if not underground: player.rotation.y = -PI/2.0
	player.test_walk = Vector2(0,-1)
	var rows: Array[Dictionary] = []
	var elapsed := 0.0
	var last := Time.get_ticks_usec()
	while elapsed < (12.0 if underground else 18.0) and rows.size() < 2400:
		player.test_walk = Vector2.ZERO if underground and elapsed<4.0 else Vector2(0,-1)
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var ms := (now-last)/1000.0
		elapsed += ms/1000.0
		var row := _frame_row(ms)
		row.merge(player.motion_sample)
		row["window"] = ("underground_stationary" if elapsed<4.0 else "underground_walk") if underground else "surface_walk"
		row["enemies"] = get_tree().get_nodes_in_group("enemies").size()
		row["projection_pending"] = terrain.resource_stream._projection_pending.size()
		row["position"] = [player.position.x,player.position.y,player.position.z]
		var support := terrain.rendered_height(player.position.x,player.position.z,player.position.y-0.96,3.0)
		row["terrain_height"] = support if is_finite(support) else null
		row["foot_block"] = terrain.block_at(floori(player.position.x),floori(player.position.y-0.95),floori(player.position.z))
		rows.append(row)
		last = now
	player.test_walk = Vector2.ZERO
	var times: Array[float] = []
	for row in rows: times.append(float(row.frame_ms))
	report["walk"] = _stats(times)
	report["projection_pending"] = terrain.resource_stream._projection_pending.size()
	check(player.position.distance_to(start)>(0.2 if underground else 20.0),"real controller travelled on the selected route")
	if underground:
		check(start.y<float(report.surface_above_y)-3.0,"sample begins on the selected underground floor")
	else:
		check(rows.all(func(row:Dictionary)->bool:return row.terrain_height!=null and float(row.position[1])-0.96>=float(row.terrain_height)-0.002),"sampled capsule stayed above actual terrain triangles")
	report["start"] = [start.x,start.y,start.z]
	report["end"] = [player.position.x,player.position.y,player.position.z]
	report["checks"] = checks
	report["failures"] = failures
	report["retention"] = terrain.chunk_stream.retention()
	FileAccess.open(output.path_join("frames.json"),FileAccess.WRITE).store_string(JSON.stringify(rows))
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("PLAY01_SAMPLE ",JSON.stringify(report))
	get_tree().quit(0 if failures == 0 else 1)

func _place_in_cave()->bool:
	player.set_physics_process(false)
	var candidates:Array[Vector3]=[]
	for definition:Dictionary in terrain.map.nodes:
		if int(definition.y)<terrain.height_at(int(definition.x),int(definition.z))-4:
			candidates.append(Vector3(float(definition.x)+0.5,definition.y,float(definition.z)+0.5))
	candidates.sort_custom(func(a:Vector3,b:Vector3)->bool:return a.distance_squared_to(player.position)<b.distance_squared_to(player.position))
	var selected:=Vector3.INF
	for i in mini(16,candidates.size()):
		var at:=candidates[i]
		terrain.ensure_area(at,16)
		await get_tree().physics_frame
		for offset in [Vector3(2,0,0),Vector3(-2,0,0),Vector3(0,0,2),Vector3(0,0,-2)]:
			var p:Vector3=at+offset
			var floor_y:=terrain.rendered_height(p.x,p.z,at.y,1.25)
			if not is_finite(floor_y):continue
			p.y=floor_y+1.01
			var query:=PhysicsShapeQueryParameters3D.new()
			query.shape=player.get_node("CollisionShape3D").shape
			query.transform=Transform3D(Basis.IDENTITY,p)
			query.exclude=[player.get_rid()]
			if get_world_3d().direct_space_state.intersect_shape(query,1).is_empty():
				selected=p
				break
		if selected.is_finite():break
	check(selected.is_finite(),"native cave has a clear physical capsule position")
	if not selected.is_finite():return false
	player.position=selected
	player.velocity=Vector3.ZERO
	for direction in [Vector3.FORWARD,Vector3.RIGHT,Vector3.BACK,Vector3.LEFT]:
		if not player.test_move(player.global_transform,direction):
			player.rotation.y=atan2(-direction.x,-direction.z)
			break
	player.set_physics_process(true)
	report["cave_scope"]="Synthetic placement on a generated seed-1 cave floor near spawn, then 4 seconds standing and 8 seconds scripted walking. Not the owner's incident location. Normal collision, mobs, resources and world processing remain active."
	report["cave_position"]=[selected.x,selected.y,selected.z]
	report["surface_above_y"]=terrain.height_at(floori(selected.x),floori(selected.z))
	return true