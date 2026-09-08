extends "res://tests/first_hour_journey.gd"
## No supplied materials, kits, stations or unlocks. Gathering/travel is paced
## by the harness; catalogue buttons, camera placement and E do the actual work.
const LF_SAVE := "user://lf1-flow.json"
var red: LeylineSource
var bench: StationSite
var forge: StationSite

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	world_seed = 77
	world_profile = "living_frontier_wave1"
	_build_world(world_seed)
	player.class_panel.choose("warden")
	for actor in [player,player.placement,player.combat,player.spring_arm,mob_packs]: actor.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	_run_lf.call_deferred()

func _run_lf() -> void:
	var manager := SaveManager.new()
	if "--lf-restore" in OS.get_cmdline_user_args():
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LF_SAVE))
		check(manager.read(LF_SAVE,player),"fresh process restores complete LF checkpoint: " + manager.last_error)
		check(_sim().leyline_save() == saved.leylines,"fresh process exact lots, outcomes, work, claims and formation")
		check(JSON.parse_string(_sim().export_json()) == JSON.parse_string(saved.sim),"fresh process exact owned inventory and progression")
		check(JSON.parse_string(_sim().contraption_save()) == JSON.parse_string(saved.contraptions),"fresh process exact machinery")
		return _finish_lf()
	check(_sim().inventory().is_empty(),"no supplied inventory")
	check(_sim().recipe_ids().has("fire_red_brick"),"ordinary catalogue exposes Red brick variant in experiment")
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		if source.source_id == "red_home_margin": red = source
	if not check(red != null,"one discoverable Red source"): return _finish_lf()
	terrain.ensure_area(red.global_position,24)
	await aim_at(red)
	check(red.supported(),"source has real accessible ground support")
	player.interact()
	check(player.work_panel._custom_context == "leyline:"+red.source_id,"normal aimed E opens source work")
	await snap("red-ready")
	if not await press(String(red.state().next_work)): return _finish_lf()
	check(red.state().work == 1,"first work is retained without output")
	await checkpoint("partial source work")
	await aim_at(red)
	player.interact()
	for i in 3: await press(String(red.state().next_work))
	check(red.state().claim.get("red_salt",0) == 16 && _sim().material_count("red_salt")==0,"released raw has one uncollected owner")
	await checkpoint("released source claim")
	await aim_at(red)
	player.interact()
	await snap("red-released")
	await press("Collect Red Salt")
	check(_sim().material_count("red_salt")==16 && red.state().claim.is_empty(),"one collection transfers raw once, with zero Catalyst")
	player.work_panel.close_panel()
	# Complete the ordinary first forge bootstrap using generated finite sources.
	if not await gather("wood",65): return _finish_lf()
	if not craft("workbench_kit"): return _finish_lf()
	bench = await place_station("workbench_kit",Vector2i(8,0))
	if bench==null: return _finish_lf()
	if not craft("timber_frame",2,bench): return _finish_lf()
	if not await gather("fieldstone",6): return _finish_lf()
	if not craft("mason_yard_kit",1,bench): return _finish_lf()
	var yard := await place_station("mason_yard_kit",Vector2i(8,4))
	if yard==null: return _finish_lf()
	if not craft("timber_wedge",4): return _finish_lf()
	if not await gather("split_stone",16): return _finish_lf()
	if not craft("dress_stone",8,yard): return _finish_lf()
	if not await gather("iron_ore",12): return _finish_lf()
	if not craft("forge_kit",1,bench): return _finish_lf()
	forge = await place_station("forge_kit",Vector2i(8,8))
	if forge==null: return _finish_lf()
	if not await gather("raw_clay",8): return _finish_lf()
	await aim_at(forge)
	check(_sim().material_count("ember_catalyst")==0,"zero-Catalyst expedition reaches its useful consumer")
	var before := _sim().inventory()
	if not craft("fire_red_brick",1,forge): return _finish_lf()
	check(_sim().material_count("raw_clay")==int(before.get("raw_clay",0))-8 && _sim().material_count("red_salt")==14 && _sim().material_count("wood")==int(before.get("wood",0)),"variant pays eight clay and two salt, leaves fuel exact")
	forge.interact(player)
	player.work_panel.catalogue.select_recipe("fire_red_brick")
	await snap("red-brick-catalogue")
	player.work_panel.close_panel()
	await checkpoint("paid Red bricks")
	_finish_lf()

func checkpoint(label: String) -> void:
	player.work_panel.close_panel()
	var manager := SaveManager.new()
	var sources := _sim().leyline_save()
	var inventory := _sim().inventory().duplicate(true)
	check(manager.write(LF_SAVE,player),label+" writes: "+manager.last_error)
	check(manager.read(LF_SAVE,player),label+" reloads: "+manager.last_error)
	check(_sim().leyline_save()==sources && _sim().inventory()==inventory,label+" owns exact source and player state")
	var bad := manager.capture(player)
	bad.leylines = ""
	check(not manager.apply(player,bad) && _sim().leyline_save()==sources && _sim().inventory()==inventory,label+" missing source ledger refuses before mutation")
	check(_sim().leyline_bind_world(world_profile,world_seed) && _sim().leyline_save()==sources,label+" repeated binding cannot refill or reroll")
	await get_tree().process_frame
	for source in get_tree().get_nodes_in_group("leyline_sources"): source.refresh()

func aim_at(node: Node3D) -> void:
	player.work_panel.close_panel()
	player.placement.set_build_mode_enabled(false)
	terrain.ensure_area(node.global_position,20)
	var height := .6
	if node is ContraptionSite: height = ContraptionSite.bounds_for(node.kind).y*.5
	player.global_position = node.global_position+Vector3(0,1.2,2.3)
	for i in 2: await get_tree().physics_frame
	player.camera.position = Vector3.ZERO
	player.camera.look_at(node.global_position+Vector3.UP*height)
	check(player.aim_probe().get("target")==node,"actual camera reaches "+node.name)

func press(label: String) -> bool:
	# The real button's input activation invokes the same callback as a click.
	for button in player.work_panel.find_children("*","Button",true,false):
		if button.text.nocasecmp_to(label) == 0 and button.is_visible_in_tree() and not button.disabled:
			button.pressed.emit()
			await get_tree().process_frame
			return check(true,"player control: "+label)
	return check(false,"available player control: "+label)

func place_station(id: String, offset: Vector2i) -> StationSite:
	var at := player.spawn_position+Vector3(offset.x,0,offset.y)
	if not await place_paid_kit(id,at): return null
	for station in get_tree().get_nodes_in_group("crafting_stations"):
		if station.player_built && station.station_id == StringName(_sim().kit_station(id)): return station
	return null

func place_paid_kit(id: String, at: Vector3) -> bool:
	player.work_panel.close_panel()
	var build := player.placement
	build.set_build_mode_enabled(true)
	player.build_palette.open_panel()
	player.build_palette.select_entry(StringName(id),"kit")
	player.build_palette.close_panel()
	for attempt in 16:
		var target := terrain.surface_position(floori(at.x)+attempt%4,floori(at.z)+attempt/4)
		terrain.ensure_area(target,20)
		target.y = terrain.rendered_height(target.x,target.z,target.y)
		player.position = target+Vector3(0,2.3,3)
		for i in 2: await get_tree().physics_frame
		player.camera.position = Vector3.ZERO
		player.camera.look_at(target)
		build._update_preview()
		if not build.preview_valid: continue
		var before := _sim().material_count(id)
		var event := InputEventAction.new()
		event.action = "primary_action"
		event.pressed = true
		player._unhandled_input(event)
		build.set_build_mode_enabled(false)
		await get_tree().physics_frame
		return check(_sim().material_count(id)==before-1,"actual camera/click paid placement: "+id)
	build.set_build_mode_enabled(false)
	return check(false,"legal footprint for "+id)

func snap(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf1"))
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../captures/lf1/"+label+".png")

func _finish_lf() -> void:
	print("LF1_PLAYER_FLOW %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
