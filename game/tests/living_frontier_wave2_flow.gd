extends "res://tests/living_frontier_flow.gd"
## Continues an actually paid Wave 1 checkpoint. No stock, cores or drive grants.
const LF2_PENDING := "user://lf2-pending.json"
const LF2_PAUSED := "user://lf2-paused.json"
const LF2_COMPLETE := "user://lf2-complete.json"

func find_host(id: String) -> LeylineSource:
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		if source.source_id==id: return source
	return null

func press(label: String) -> bool:
	var result := await super.press(label)
	if not result:
		print("LF2_CONTROL_REFUSAL ",label," title=",player.work_panel._custom_title)
		for button in player.work_panel.find_children("*","Button",true,false):
			if button.is_visible_in_tree(): print("LF2_BUTTON ",button.text," disabled=",button.disabled)
	return result

func _run_lf() -> void:
	var manager := SaveManager.new()
	if "--lf2-restore" in OS.get_cmdline_user_args():
		await restore_blue()
		return _finish_lf()
	var starting := LF_SAVE if "--lf2-bootstrap" in OS.get_cmdline_user_args() else "res://../build/lf2/wave1.json"
	if not check(manager.read(starting,player),"paid Wave 1 checkpoint loads: "+manager.last_error): return _finish_lf()
	freeze_fixtures()
	refresh_stations()
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(starting))
	var old_sources: Dictionary = JSON.parse_string(previous.leylines)
	var current_sources: Dictionary = JSON.parse_string(_sim().leyline_save())
	for id: String in old_sources.sources:
		check(current_sources.sources[id]==old_sources.sources[id],"published source ledger preserved exactly: "+id)
	check(JSON.parse_string(_sim().export_json())==JSON.parse_string(previous.sim),"migration keeps paid inventory, progression and Kindling")
	var old_machines: Dictionary = JSON.parse_string(previous.contraptions)
	var current_machines: Dictionary = JSON.parse_string(_sim().contraption_save())
	for old: Dictionary in old_machines.machines:
		for current: Dictionary in current_machines.machines:
			if current.key!=old.key: continue
			for field: String in old: check(current[field]==old[field],"published machine field exact: "+old.key+" / "+field)
	check(current_machines.sources==old_machines.sources,"finite pressure ledger survives migration")
	var source := find_host("blue_home_margin")
	if not check(source!=null and source.state().lot==0,"one newly available Blue host"): return _finish_lf()
	await aim_at(source)
	check(source.supported(),"Blue has real support and workspace")
	player.interact()
	await press(String(source.state().next_work))
	var partial := _sim().leyline_save()
	var captured := manager.capture(player)
	check(manager.apply(player,captured) and _sim().leyline_save()==partial,"Blue interrupted work survives complete checkpoint")
	source=find_host("blue_home_margin")
	refresh_stations()
	freeze_fixtures()
	await aim_at(source)
	player.interact()
	for step in 3: await press(String(source.state().next_work))
	await snap("blue-source")
	for item: String in source.state().claim.keys(): await press("Collect "+Hud.pretty(item))
	check(_sim().material_count("blue_flake")==16,"actual Blue claim collected")
	if not craft("assemble_blue_delay",1,bench): return _finish_lf()
	check(_sim().material_count("blue_flake")==14,"Blue kit costs two harvested flakes")
	if not await place_paid_kit("blue_delay_kit",player.spawn_position+Vector3(-4,0,-2)): return _finish_lf()
	freeze_fixtures()
	var blue := fixture("blue_delay")
	var drum := fixture("cargo_winch")
	var landing := fixture("winch_landing")
	var white := fixture("white_connection")
	var lever := fixture("stormglass_lever")
	print("LF2_PLACED blue_delay ",blue.global_position)
	# Return the previous journey's empty basket through ordinary winding/crank.
	if machine(drum).at_landing:
		await aim_at(drum)
		player.interact()
		await press("Wind the drum")
		await press("Crank a trip")
		drum._physics_process(20)
	check(not machine(drum).moving and not machine(drum).at_landing,"paid empty return prepares the drum")
	await connect_control(blue,drum,"Choose receiver")
	await connect_control(white,blue,"Choose receiver")
	await aim_at(drum)
	player.interact()
	await press("Wind the drum")
	await press("Load 10 wood")
	check(machine(drum).cargo.get("wood",0)==10,"cargo is loaded from the paid player's pack")
	var drive := int(machine(drum).energy)
	var trips := int(machine(drum).completed_trips)
	await aim_at(lever)
	player.interact()
	await press("Strike the lever")
	check(machine(blue).pending_request and not machine(drum).moving,"lever through White holds request at Blue")
	blue._physics_process(.8)
	var held := _sim().contraption_save()
	await aim_at(lever)
	player.interact()
	await press("Strike the lever")
	check(_sim().contraption_save()==held,"repeated actual input cannot restart or queue the delay")
	await aim_at(blue)
	player.interact()
	await press("Pause")
	held=_sim().contraption_save()
	blue._physics_process(10)
	check(_sim().contraption_save()==held,"explicit pause holds exact delay")
	check(manager.write(LF2_PAUSED,player),"paused request writes for fresh-process test")
	await snap("blue-paused")
	await press("Resume")
	await aim_at(white)
	player.interact()
	await press("Disconnect signal")
	check(not machine(blue).pending_request and int(machine(drum).energy)==drive,"upstream disconnection cancels without consuming work")
	await connect_control(white,blue,"Choose receiver")
	blue._physics_process(10)
	check(not machine(drum).moving,"reconnection does not resurrect a request")
	await aim_at(lever)
	player.interact()
	await press("Strike the lever")
	blue._physics_process(.8)
	check(manager.write(LF2_PENDING,player),"pending request writes with exact paid cargo and drive")
	await aim_at(blue)
	player.interact()
	await snap("blue-held")
	player.work_panel.close_panel()
	held=_sim().contraption_save()
	get_tree().paused=true
	blue._physics_process(10)
	get_tree().paused=false
	check(_sim().contraption_save()==held,"game pause gives no delay credit")
	var nearby := player.global_position
	player.global_position=blue.global_position+Vector3(100,0,0)
	blue._physics_process(10)
	check(_sim().contraption_save()==held,"leaving active distance gives no delay credit")
	player.global_position=nearby
	var wall := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size=Vector3(.8,3,.8)
	collider.shape=shape
	wall.add_child(collider)
	add_child(wall)
	wall.global_position=blue.cable_anchor().lerp(drum.cable_anchor(),.5)
	for frame in 2: await get_tree().physics_frame
	check(not blue.span_clear(),"actual collider obstructs Blue's output span")
	blue._physics_process(10)
	check(_sim().contraption_save()==held,"physical obstruction holds exact pending request")
	wall.free()
	for frame in 2: await get_tree().physics_frame
	blue._physics_process(2.21)
	check(not machine(blue).pending_request and machine(drum).moving and int(machine(drum).energy)==drive-1,"after full delay receiver spends exactly its own winding")
	await workshop_picture("blue-workshop")
	await aim_at(drum)
	drum._physics_process(20)
	check(int(machine(drum).completed_trips)==trips+1,"one delayed paid trip")
	await aim_at(landing)
	player.interact()
	await press("Collect wood")
	check(machine(drum).cargo.is_empty(),"delayed cargo collected once at landing")
	check(manager.write(LF2_COMPLETE,player),"complete paid LF-2A checkpoint for next slice")
	_finish_lf()

func restore_blue() -> void:
	var manager := SaveManager.new()
	for path: String in [LF2_PAUSED,LF2_PENDING]:
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
		if not check(manager.read(path,player),"fresh process restores held Blue: "+manager.last_error): return
		freeze_fixtures()
		check(_sim().contraption_save()==saved.contraptions and _sim().leyline_save()==saved.leylines,"fresh process exact source, delay, cargo and energy")
		check(JSON.parse_string(_sim().export_json())==JSON.parse_string(saved.sim),"fresh process exact paid inventory")
		var future_path := "user://lf2-future.json"
		check(manager.write(future_path,player) and manager.write(future_path,player),"valid previous checkpoint exists for future-version refusal")
		var future := manager.capture(player)
		var payload: Dictionary = JSON.parse_string(future.contraptions)
		payload.schema=999
		future.contraptions=JSON.stringify(payload)
		var file := FileAccess.open(future_path,FileAccess.WRITE)
		file.store_string(JSON.stringify(future))
		file.close()
		check(not manager.read(future_path,player) and manager.last_error=="unsupported contraption save version" and not manager.recovered_previous,"future machine format refuses without rewinding to older ownership")
		check(_sim().contraption_save()==saved.contraptions,"future-format refusal preserves live request")
		var blue := fixture("blue_delay")
		var drum := fixture("cargo_winch")
		var landing := fixture("winch_landing")
		await aim_at(blue)
		player.interact()
		if path==LF2_PAUSED:
			blue._physics_process(50)
			check(_sim().contraption_save()==saved.contraptions,"restarted paused request stays paused")
			await press("Resume")
		var before := int(machine(drum).completed_trips)
		blue._physics_process(2.21)
		check(machine(drum).moving and not machine(blue).pending_request,"restarted request releases after only its remaining delay")
		drum._physics_process(20)
		await aim_at(landing)
		player.interact()
		var wood := _sim().material_count("wood")
		await press("Collect wood")
		check(_sim().material_count("wood")==wood+10 and machine(drum).cargo.is_empty(),"fresh delivery transfers exact ten real wood once")
		blue._physics_process(100)
		check(int(machine(drum).completed_trips)==before+1,"extra time cannot duplicate restarted request")

func snap(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf2"))
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../captures/lf2/"+label+".png")

func _finish_lf() -> void:
	print("LF2_PLAYER_FLOW %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
