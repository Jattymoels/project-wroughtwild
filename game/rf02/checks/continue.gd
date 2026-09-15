extends "res://tests/rf01/placement.gd"
## Reuse the already paid RF01 fixture, without repeating its economy journey.
func _ready() -> void:
	output = OS.get_environment("WROUGHTWILD_RF02_OUTPUT")
	set_physics_process(false)
	seed_controls = SEED_CONTROLS.new()
	add_child(seed_controls)
	seed_controls.configure(self,"77",output.path_join("paid-continue.json"))
	_restore.call_deferred()

func _restore() -> void:
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("paid-continue.json")))
	if not check(seed_controls.continue_saved(),"ordinary Continue opens the retained paid RF01 fixture"): return _finish_restore()
	quiet()
	check(terrain._rf02_biome_mask!=null and world_seed==77 and world_profile=="frontier_v6","Continue selects RF02 in the same saved world")
	for origin: Vector2i in fixture_origins: terrain.ensure_area(Vector3(origin.x+8,32,origin.y+8),16)
	await get_tree().physics_frame
	quiet()
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		check(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"Continue renderer cannot take focus")
	var restored: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.new().capture(player),"",true,true))
	check(_sim().export_json()==saved.sim,"exact native possessions/progression survive Continue")
	for key in ["blocks","stations","contraptions","leylines","resource_nodes","world_drops","broken_blocks"]:
		check(restored.get(key,[])==saved.get(key,[]),"exact saved ownership: "+key)
	check(restored.get("blocks",[]).size()==9 and restored.get("stations",[]).size()==1,"fixture retains its paid nine-piece octagon and workbench")
	var index: Dictionary = terrain.reclaimed_cover.workspace_index(terrain,StrangeSites._building_index(terrain))
	var overlaps := 0
	var visible_overlap := false
	var overlap_rows: Array = []
	for row in poses():
		var bounds: AABB = row.pose * row.part.get_meta("clearance_bounds")
		if not StrangeSites._building_overlap(index,bounds): continue
		overlaps += 1
		var transforms: Array = row.part.get_meta("world_transforms")
		var i := transforms.find(row.pose)
		var shown: Transform3D = row.part.multimesh.get_instance_transform(i)
		if shown.basis.determinant()!=0: visible_overlap=true
		overlap_rows.append({"part":row.part.name,"at":str(row.pose.origin),"determinant":shown.basis.determinant(),"hidden":row.part.get_meta("hidden_by_building",[]),"index":i})
	FileAccess.open(output.path_join("clearance-diagnostic.json"),FileAccess.WRITE).store_string(JSON.stringify({"overlaps":overlaps,"visible_overlap":visible_overlap,"rows":overlap_rows,"renderer":RenderingServer.get_current_rendering_method(),"display":DisplayServer.get_name()},"\t"))
	print("RF02_CLEARANCE overlaps=",overlaps," visible_overlap=",visible_overlap)
	check(overlaps>0 and not visible_overlap,"new moving blade bounds are hidden at actual paid floor/workbench footprints")
	var initial := snapshot()
	StrangeSites.refresh_buildings(self,terrain)
	check(snapshot()==initial,"loaded cover already agrees with complete building/station refresh")
	var station: StationSite
	for site in get_tree().get_nodes_in_group("crafting_stations"):
		if site is StationSite and site.player_built: station=site; break
	if check(station!=null,"retained workbench exists"):
		station.interact(player)
		check(player.work_panel.is_open(),"retained workbench remains usable")
		player.work_panel.close_panel()
	player.set_physics_process(true)
	for i in 20: await get_tree().physics_frame
	check(player.is_on_floor(),"real Continue player reaches floor contact")
	var start := player.position
	for direction in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
		if player.test_move(player.global_transform,direction): continue
		player.rotation.y=0
		player.test_walk=Vector2(direction.x,direction.z)
		for i in 10: await get_tree().physics_frame
		break
	player.test_walk=Vector2.ZERO
	check(player.position.distance_to(start)>.25,"real player moves after Continue")
	quiet()
	check(SaveManager.new().write(output.path_join("resaved-continue.json"),player),"ordinary private resave works")
	# Only the changed mesh footprint is rechecked at one existing excavation edge.
	var candidates := poses()
	candidates.sort_custom(func(a: Dictionary,b: Dictionary)->bool:
		return absf(fmod(a.pose.origin.x,16.0)-15.5)<absf(fmod(b.pose.origin.x,16.0)-15.5))
	if check(not candidates.is_empty(),"a supported edge plant exists"):
		var at: Vector3=candidates[0].pose.origin
		var dug:=Vector3i(floori(at.x),terrain.height_at(floori(at.x),floori(at.z))-1,floori(at.z))
		check(terrain.break_block(dug.x,dug.y,dug.z)!="","one real excavation removes blade support")
		await get_tree().process_frame
		quiet()
		var lingering:=false
		for row in poses():
			if floori(row.pose.origin.x)==dug.x and floori(row.pose.origin.z)==dug.z: lingering=true
		check(not lingering and terrain.block_at(dug.x,dug.y,dug.z)==0,"new grass leaves no lid over the excavation")
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"mouse opt-out stays active")
	_finish_restore()

func _finish_restore() -> void:
	var report:={"checks":checks,"failures":failures,"scope":"One private fresh-process Continue of RF01's already paid seed-77 fixture; exact ownership, changed moving mesh/workspace bounds, station use, real movement and one excavation edge. No economy/campaign replay."}
	FileAccess.open(output.path_join("continue-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("RF02_CONTINUE ",JSON.stringify(report))
	get_tree().quit(0 if failures==0 else 1)
