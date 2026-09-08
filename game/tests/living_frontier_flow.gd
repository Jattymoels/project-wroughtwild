extends "res://tests/first_hour_journey.gd"
## No supplied materials, kits, stations or unlocks. Gathering/travel is paced
## by the harness; catalogue buttons, camera placement and E do the actual work.
const LF_SAVE := "user://lf1-flow.json"
const LF_MIDTRIP := "user://lf1-midtrip.json"
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
		check(kindling_active(),"fresh process restores the manufactured Kindling effect")
		await restart_delivery()
		return _finish_lf()
	if "--lf-continue-c" in OS.get_cmdline_user_args():
		check(manager.read("res://../build/lf1/lf1b.json",player),"published LF-1B world migrates: "+manager.last_error)
		await get_tree().process_frame
		refresh_stations()
		await connection_journey()
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
	# LF-1B: six further draws, ordinary smelting and charcoal; no rare find.
	for lot in 6:
		await aim_at(red)
		player.interact()
		for step in 4: await press(String(red.state().next_work))
		await press("Collect Red Salt")
	player.work_panel.close_panel()
	check(_sim().material_count("ember_catalyst")==0,"the chosen fixed lots need no rare success")
	if not await gather("wood",32): return _finish_lf()
	if not await gather("iron_ore",8): return _finish_lf()
	if not craft("smelt_iron",4,forge): return _finish_lf()
	if not craft("charcoal",4,forge): return _finish_lf()
	await aim_at(forge)
	forge.interact(player)
	player.work_panel.catalogue.select_recipe("forge_faint_ember")
	check(not _sim().recipe_ids().has("distil_ember"),"experiment catalogue uses costly replacement")
	for item: String in _sim().recipe("forge_faint_ember").inputs:
		check(_sim().material_count(item)>=int(_sim().recipe("forge_faint_ember").inputs[item]) and int(_sim().recipe("forge_faint_ember").inputs[item])<=_sim().carry_cap(item),"whole recipe carried together: "+item)
	await snap("ember-recipe")
	before = _sim().inventory()
	if not craft("forge_faint_ember",1,forge): return _finish_lf()
	check(_sim().material_count("red_salt")==int(before.red_salt)-96 and _sim().material_count("iron_ingot")==int(before.iron_ingot)-4 and _sim().material_count("charcoal")==int(before.charcoal)-8,"costly recipe pays all three inputs exactly")
	await demonstrate_foundry()
	await checkpoint("manufactured persistent Kindling")
	check(kindling_active(),"manufactured Kindling survives full checkpoint restore")
	await connection_journey()
	_finish_lf()

func connection_journey() -> void:
	var white: LeylineSource
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		if source.source_id == "white_home_margin": white = source
	if not check(white!=null,"discoverable White host on the second home approach"): return
	await aim_at(white)
	player.interact()
	await press(String(white.state().next_work))
	await checkpoint("partial White work")
	await aim_at(white)
	player.interact()
	for step in 3: await press(String(white.state().next_work))
	await snap("white-extraction")
	await press("Collect White Mineral")
	check(_sim().material_count("white_mineral")==16,"paid expedition collects useful White without a rare result")
	player.work_panel.close_panel()
	if not await gather("thrumroot",1) or not await gather("stormglass",1): return
	if not await gather("wood",60) or not await gather("iron_ore",8): return
	if not craft("smelt_iron",4,forge): return
	var kit_inputs := _sim().inventory()
	for kind in ["cargo_winch","winch_landing","stormglass_lever","white_connection"]:
		if not craft("assemble_"+kind,1,bench): return
	check(_sim().material_count("thrumroot")==int(kit_inputs.thrumroot)-1 and _sim().material_count("stormglass")==int(kit_inputs.stormglass)-1 and _sim().material_count("white_mineral")==int(kit_inputs.white_mineral)-2,"all cores and White are actually paid")
	var placements := {"cargo_winch":Vector3(-8,0,-6),"winch_landing":Vector3(6,0,-6),"white_connection":Vector3(-8,0,-2),"stormglass_lever":Vector3(-12,0,-2)}
	for kind: String in placements:
		if not await place_paid_kit(kind+"_kit",player.spawn_position+Vector3(placements[kind])): return
	freeze_fixtures()
	var drum := fixture("cargo_winch")
	var landing := fixture("winch_landing")
	var connection := fixture("white_connection")
	var lever := fixture("stormglass_lever")
	if not check(drum!=null and landing!=null and connection!=null and lever!=null,"all four paid fixtures exist"): return
	for node in [drum,landing,connection,lever]: print("LF1_PLACED ",node.kind," ",node.global_position)
	await connect_control(drum,landing,"Choose landing")
	await connect_control(lever,connection,"Choose receiver")
	await connect_control(connection,drum,"Choose cargo drum")
	check(drum.span_clear() and connection.span_clear() and lever.span_clear(),"complete supported signal route and full basket span are physically clear")
	await aim_at(lever)
	player.interact()
	check(lever._panel._signal_description(machine(lever)).contains("unwound"),"lever explains empty mechanical drive before a request")
	await press("Strike the lever")
	check(not machine(drum).moving and machine(drum).energy==0 and machine(connection).pulses==1,"real empty-drive request conveys a pulse and supplies no work")
	await aim_at(drum)
	player.interact()
	await press("Wind the drum")
	await press("Load 10 wood")
	check(machine(drum).energy==1 and machine(drum).cargo.get("wood",0)==10,"manual winding and actual loaded cargo")
	await blocked_route_probes(lever,connection,drum,landing)
	await aim_at(connection)
	player.interact()
	await press("Disconnect signal")
	await aim_at(lever)
	player.interact()
	check(lever._panel._signal_description(machine(lever)).contains("disconnected"),"lever explains the missing White output")
	await press("Strike the lever")
	check(not machine(drum).moving and machine(drum).energy==1 and machine(drum).cargo.get("wood",0)==10,"disconnected White conserves paid winding and cargo")
	await connect_control(connection,drum,"Choose cargo drum")
	await checkpoint("paid connected setup")
	freeze_fixtures()
	drum=fixture("cargo_winch"); landing=fixture("winch_landing"); connection=fixture("white_connection"); lever=fixture("stormglass_lever")
	await aim_at(lever)
	player.interact()
	player.hud.notify("")
	await snap("white-connected")
	player.work_panel.close_panel()
	await workshop_picture("white-workshop")
	await aim_at(lever)
	player.interact()
	await press("Strike the lever")
	check(machine(drum).moving and machine(drum).energy==0,"normal lever sends via White and spends exactly one stored operation")
	drum._physics_process(.4)
	check(machine(drum).progress>0 and machine(drum).progress<1,"real basket starts along its linked span")
	var manager := SaveManager.new()
	check(manager.write(LF_MIDTRIP,player),"write exact in-flight checkpoint for fresh-process delivery")
	await workshop_picture("cargo-in-flight")
	await checkpoint("in-flight White-requested cargo")
	freeze_fixtures()
	drum=fixture("cargo_winch"); landing=fixture("winch_landing")
	await aim_at(drum)
	drum._physics_process(20)
	check(machine(drum).at_landing and machine(drum).completed_trips==1 and machine(drum).cargo.get("wood",0)==10,"one paid trip delivers actual cargo to its landing")
	if not await gather("wood",_sim().carry_cap("wood")): return
	await aim_at(landing)
	player.interact()
	await press("Collect wood")
	check(machine(drum).cargo.get("wood",0)==10,"full carried family leaves all delivered cargo in its drum")
	player.work_panel.close_panel()
	if not craft("timber_wedge"): return
	var room := _sim().carry_cap("wood")-_sim().material_count("wood")
	await aim_at(landing)
	player.interact()
	await press("Collect wood")
	check(machine(drum).cargo.get("wood",0)==10-room,"only actual carried room transfers at the landing")
	await checkpoint("partially collected landing cargo")
	freeze_fixtures()
	drum=fixture("cargo_winch"); landing=fixture("winch_landing")
	var remaining := int(machine(drum).cargo.get("wood",0))
	var per_wedge := int(_sim().recipe("timber_wedge").inputs.wood)
	if not craft("timber_wedge",ceili(float(remaining)/per_wedge)): return
	await aim_at(landing)
	player.interact()
	await press("Collect wood")
	check(machine(drum).cargo.is_empty(),"remaining cargo collected once through normal landing controls")
	await snap("cargo-delivered")
	await checkpoint("complete Wave 1 paid expedition")
	connection=fixture("white_connection"); lever=fixture("stormglass_lever")
	var key := connection.machine_key
	var before_white := _sim().material_count("white_mineral")
	await aim_at(connection)
	player.interact()
	await press("Dismantle and recover")
	check(_sim().contraption_state(key).is_empty() and machine(lever).link.is_empty(),"normal dismantling removes White and disconnects its incoming lever")
	check(_sim().material_count("white_mineral")==before_white+1,"ordinary half-frame refund returns one of the two White units")
	check(not _sim().contraption_remove(key).ok,"removed White cannot refund twice")
	check(manager.read(LF_SAVE,player),"restore the complete paid workshop checkpoint after dismantle verification")
	freeze_fixtures()
	check(_sim().material_count("white_mineral")==before_white and fixture("white_connection")!=null,"whole-checkpoint restore replaces ownership without retaining a demolition refund")

func blocked_route_probes(lever: ContraptionSite, connection: ContraptionSite, drum: ContraptionSite, landing: ContraptionSite) -> void:
	# Controlled geometry probes are separate from material acquisition: these
	# temporary colliders supply no items, paid pieces, source stock or energy.
	for pair in [[lever,connection],[connection,drum],[drum,landing]]:
		var wall := StaticBody3D.new()
		var collider := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size=Vector3(.8,3,.8)
		collider.shape=box
		wall.add_child(collider)
		add_child(wall)
		wall.global_position=pair[0].cable_anchor().lerp(pair[1].cable_anchor(),.5)
		for frame in 2: await get_tree().physics_frame
		check(not pair[0].span_clear(),"physical obstruction detected on "+pair[0].kind+" span")
		await aim_at(lever)
		player.interact()
		await press("Strike the lever")
		check(not machine(drum).moving and machine(drum).energy==1 and machine(drum).cargo.get("wood",0)==10,"blocked route cannot spend work or move its real cargo")
		wall.free()
		for frame in 2: await get_tree().physics_frame
		check(pair[0].span_clear(),"removed obstruction restores clear span")

func fixture(kind: String) -> ContraptionSite:
	for node in get_tree().get_nodes_in_group("contraptions"):
		if node.kind==kind: return node
	return null

func machine(node: ContraptionSite) -> Dictionary:
	return _sim().contraption_state(node.machine_key)

func freeze_fixtures() -> void:
	for node in get_tree().get_nodes_in_group("contraptions"): node.set_physics_process(false)

func connect_control(from: ContraptionSite, to: ContraptionSite, label: String) -> void:
	await aim_at(from)
	player.interact()
	await press(label)
	await press("Link this "+String(ContraptionSite.LABELS[to.kind]))
	check(machine(from).link==to.machine_key,"ordinary connection control: "+from.kind+" → "+to.kind)
	player.work_panel.close_panel()

func restart_delivery() -> void:
	var manager := SaveManager.new()
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(LF_MIDTRIP))
	check(manager.read(LF_MIDTRIP,player),"fresh process restores in-flight paid cargo: "+manager.last_error)
	freeze_fixtures()
	check(_sim().contraption_save()==saved.contraptions,"restart neither advances nor replays the saved request")
	var drum := fixture("cargo_winch")
	var landing := fixture("winch_landing")
	if not check(drum!=null and landing!=null,"saved real drum and landing are restored"): return
	check(machine(drum).energy==0 and machine(drum).moving,"restart keeps spent drive and in-flight trip")
	await aim_at(drum)
	drum._physics_process(20)
	check(machine(drum).completed_trips==1 and machine(drum).at_landing,"fresh process completes the one paid journey")
	var before := _sim().material_count("wood")
	await aim_at(landing)
	player.interact()
	await press("Collect wood")
	check(_sim().material_count("wood")==before+10 and machine(drum).cargo.is_empty(),"fresh process delivers exact cargo once through the landing")
	drum._physics_process(20)
	check(machine(drum).completed_trips==1,"extra restarted time cannot repeat a delivered trip")

func demonstrate_foundry() -> void:
	var panel := player.foundry_panel
	var event := InputEventAction.new()
	event.action = "toggle_foundry"
	event.pressed = true
	player._unhandled_input(event)
	check(panel.is_open(),"normal Foundry action opens the plate")
	await foundry_button(panel._tablets,"Lay "+String(_sim().combat_skill("prototype_heavy_strike").display_name))
	panel._cell_buttons[Vector2i(1,1)].pressed.emit()
	await get_tree().process_frame
	await foundry_button(panel._tray,"Ember")
	panel._cell_buttons[Vector2i(1,0)].pressed.emit()
	await get_tree().process_frame
	for kind: Dictionary in _sim().foundry().kinds:
		if kind.id == "ember_catalyst": await foundry_button(panel._subjects,"Set a "+String(kind.display_name))
	panel._cell_buttons[Vector2i(2,0)].pressed.emit()
	await get_tree().process_frame
	check(_sim().material_count("ember_catalyst")==0 and kindling_active(),"earned Ember ingot and manufactured Faint Kind create existing Kindling")
	await snap("ember-foundry")
	panel.close_panel()

func kindling_active() -> bool:
	for form: Dictionary in _sim().skill_mutation("prototype_heavy_strike").forms:
		if form.form_name == "Kindling": return true
	return false

func foundry_button(container: Node, prefix: String) -> void:
	for button in container.get_children():
		if button is Button and not button.is_queued_for_deletion() and button.text.begins_with(prefix):
			await reveal_control(button)
			button.pressed.emit()
			await get_tree().process_frame
			check(true,"Foundry player control: "+prefix)
			return
	check(false,"Foundry player control exists: "+prefix)

func checkpoint(label: String) -> void:
	player.work_panel.close_panel()
	var manager := SaveManager.new()
	var sources := _sim().leyline_save()
	var machinery := _sim().contraption_save()
	var inventory := _sim().inventory().duplicate(true)
	check(manager.write(LF_SAVE,player),label+" writes: "+manager.last_error)
	check(manager.read(LF_SAVE,player),label+" reloads: "+manager.last_error)
	freeze_fixtures()
	check(_sim().contraption_save()==machinery,label+" restores exact connections, drive, cargo and progress")
	check(_sim().leyline_save()==sources && _sim().inventory()==inventory,label+" owns exact source and player state")
	var bad := manager.capture(player)
	bad.leylines = ""
	check(not manager.apply(player,bad) && _sim().leyline_save()==sources && _sim().inventory()==inventory,label+" missing source ledger refuses before mutation")
	check(_sim().leyline_bind_world(world_profile,world_seed) && _sim().leyline_save()==sources,label+" repeated binding cannot refill or reroll")
	await get_tree().process_frame
	for source in get_tree().get_nodes_in_group("leyline_sources"): source.refresh()
	refresh_stations()

func refresh_stations() -> void:
	for station in get_tree().get_nodes_in_group("crafting_stations"):
		if station.player_built:
			if station.station_id == &"workbench": bench = station
			if station.station_id == &"forge_basic": forge = station

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
	await get_tree().process_frame
	for button in player.work_panel.find_children("*","Button",true,false):
		if button.text.nocasecmp_to(label) == 0 and button.is_visible_in_tree() and not button.disabled:
			await reveal_control(button)
			button.pressed.emit()
			await get_tree().process_frame
			return check(true,"player control: "+label)
	return check(false,"available player control: "+label)

func reveal_control(button: Button) -> void:
	var ancestor := button.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer: ancestor.ensure_control_visible(button)
		ancestor = ancestor.get_parent()
	await get_tree().process_frame

func workshop_picture(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	player.work_panel.close_panel()
	for node in get_tree().get_nodes_in_group("contraptions"): node.refresh_from_sim()
	var drum := fixture("cargo_winch")
	var landing := fixture("winch_landing")
	var centre := drum.global_position.lerp(landing.global_position,.5)+Vector3(0,1,2)
	player.global_position=centre+Vector3(-9,8,13)
	player.camera.position=Vector3.ZERO
	player.camera.look_at(centre)
	player.hud.notify("")
	await snap(label)

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
