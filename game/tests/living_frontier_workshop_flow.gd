extends "res://tests/living_frontier_heat_flow.gd"
## Continues the genuinely paid A/B/C workshop. No inventory or core grants.
const WORKSHOP_PENDING := "user://lf2-workshop-pending.json"
const WORKSHOP_COMPLETE := "user://lf2-workshop-complete.json"
const FORMS := {"ember":"Kindling","frost":"Smoulder","preserving":"Emberbed","impact":"Firebreak","piercing":"Cinder Lance"}

func _run_lf() -> void:
	if "--workshop-restore" in OS.get_cmdline_user_args():
		await restore_workshop()
		return _finish_lf()
	var manager := SaveManager.new()
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HEAT_COMPLETE))
	if not check(manager.read(HEAT_COMPLETE,player),"continue the actually paid heat workshop: "+manager.last_error): return _finish_lf()
	freeze_fixtures(); refresh_stations()
	check(_sim().leyline_save()==previous.leylines and _sim().contraption_save()==previous.contraptions,"recipe addition leaves published source and machine ledgers exact")
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		print("LF2_SOURCE ",source.source_id," ",source.global_position)
	# Empty both original manifestations through their ordinary manual work and
	# collect every released claim before the already accepted formation clock.
	for id: String in ["red_home_margin","white_home_margin"]:
		var source := find_host(id)
		while int(source.state().lot)<int(source.state().lots):
			if not await draw_lot(source): return _finish_lf()
	if not await gather("wood",160): return _finish_lf()
	# Smelt modest carried ore batches through the same ordinary forge recipe.
	# Twenty-seven ingots fund all five recipes and five actual Kind lifts.
	for trip in 9:
		if not await gather("iron_ore",6): return _finish_lf()
		await aim_at(forge)
		if not craft("smelt_iron",3,forge): return _finish_lf()
	if not craft("charcoal",18,forge): return _finish_lf()
	if not await forge_catalyst("impact"): return _finish_lf()
	if not await gather_medium("blue_home_margin","blue_flake",96) or not await forge_catalyst("frost"): return _finish_lf()
	if not await gather_medium("green_home_margin","green_resin",96) or not await forge_catalyst("preserving"): return _finish_lf()
	player.work_panel.close_panel()
	check(not get_tree().paused and not player.trial.active() and player.combat.life>0,"formation uses live active overworld time")
	# Harness time compression: the same native dispatcher receives 600 active
	# seconds and real host obstruction state; no source stock is assigned.
	var blocked := PackedStringArray()
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		if not source.supported(): blocked.append(source.source_id)
	for step in 60: _sim().leyline_tick(10,blocked)
	check(int(find_host("red_home_margin").state().manifestation)==1 and int(find_host("white_home_margin").state().manifestation)==1,"exhausted sources form one capped new manifestation")
	if not await gather_medium("red_home_margin","red_salt",96) or not await forge_catalyst("ember"): return _finish_lf()
	if not await gather_medium("white_home_margin","white_mineral",96) or not await forge_catalyst("piercing"): return _finish_lf()
	await inspect_crafted_identities()
	await paid_brick_workshop()
	_finish_lf()

func draw_lot(source: LeylineSource) -> bool:
	await aim_at(source)
	if not check(source.supported(),"real source remains supported: "+source.source_id): return false
	player.interact()
	var lot := int(source.state().lot)
	var steps := int(source.state().steps)-int(source.state().work)
	for step in steps:
		if not await press(String(source.state().next_work)): return false
	if not check(int(source.state().lot)==lot+1,"manual work releases next fixed lot"): return false
	for item: String in source.state().claim.keys():
		if not await press("Collect "+Hud.pretty(item)): return false
	return check(source.state().claim.is_empty(),"all released raw and optional rare claims actually collected")

func gather_medium(id: String, material: String, wanted: int) -> bool:
	for lot in 8:
		if _sim().material_count(material)>=wanted: return true
		if not await draw_lot(find_host(id)): return false
	return check(_sim().material_count(material)>=wanted,"acquired enough "+material)

func forge_catalyst(id: String) -> bool:
	var recipe: Dictionary = _sim().recipe("forge_faint_"+id)
	if not check(not recipe.is_empty(),"ordinary recipe exists: "+id): return false
	await aim_at(forge)
	player.interact()
	player.work_panel.catalogue.select_recipe("forge_faint_"+id)
	await snap("catalyst-"+id)
	var before := _sim().inventory().duplicate(true)
	if not craft("forge_faint_"+id,1,forge): return false
	for item: String in recipe.inputs:
		check(_sim().material_count(item)==int(before.get(item,0))-int(recipe.inputs[item]),"exact acquired Catalyst payment: "+id+" / "+item)
	print("LF2_FORGED ",id," paid=",recipe.inputs," output=",recipe.outputs)
	return true

func inspect_crafted_identities() -> void:
	var panel := player.foundry_panel
	for id: String in ["frost","preserving","impact","piercing","ember"]:
		player.work_panel.close_panel()
		var event := InputEventAction.new()
		event.action="toggle_foundry"; event.pressed=true
		player._unhandled_input(event)
		check(panel.is_open(),"normal Foundry opens for manufactured "+id)
		var iron := _sim().material_count("iron_ingot")
		panel._cell_buttons[Vector2i(2,0)].pressed.emit()
		await get_tree().process_frame
		check(_sim().material_count("iron_ingot")==iron-1,"normal paid Kind lift returns prior owned identity")
		var stock := _sim().material_count(id+"_catalyst")
		for kind: Dictionary in _sim().foundry().kinds:
			if kind.id==id+"_catalyst": await foundry_button(panel._subjects,"Set a "+String(kind.display_name))
		panel._cell_buttons[Vector2i(2,0)].pressed.emit()
		await get_tree().process_frame
		var named := false
		for form: Dictionary in _sim().skill_mutation("prototype_heavy_strike").forms:
			if form.form_name==FORMS[id]: named=true
		check(named and _sim().material_count(id+"_catalyst")==stock-1,"manufactured Kind invests into existing "+String(FORMS[id]))
		await snap("manufactured-"+id)
		panel.close_panel()

func paid_brick_workshop() -> void:
	var feeder := fixture("pressure_feeder")
	var buffer := fixture("red_heat_buffer")
	var drum := fixture("cargo_winch")
	var landing := fixture("winch_landing")
	var blue := fixture("blue_delay")
	var green := fixture("green_junction")
	if machine(drum).at_landing:
		await aim_at(drum); player.interact(); await press("Wind the drum"); await press("Crank a trip")
		drum._physics_process(20)
	await aim_at(feeder); player.interact(); await press("Collect 12 "+Hud.pretty("rustclay_brick"))
	check(_sim().material_count("rustclay_brick")==16,"twelve workshop bricks join four paid manual bricks")
	await aim_at(drum); player.interact(); await press("Load "+Hud.pretty("rustclay_brick")); await press("Wind the drum")
	check(machine(drum).cargo=={"rustclay_brick":16} and _sim().material_count("rustclay_brick")==0,"cargo actually leaves the player's pack")
	if not await prepare_firing(feeder): return
	check(machine(buffer).heat==3,"previously paid heat remains available")
	await aim_at(fixture("stormglass_lever")); player.interact(); await press("Strike the lever")
	blue._physics_process(1)
	var manager := SaveManager.new()
	check(manager.write(WORKSHOP_PENDING,player),"save useful loaded workshop with one pending delayed request")
	blue._physics_process(2)
	check(machine(drum).moving and machine(drum).energy==0 and machine(feeder).escrow_drive==1 and machine(feeder).escrow_heat==1 and machine(buffer).heat==2,"both useful receivers spend their own drive; only feeder takes held thermal input")
	await workshop_picture("complete-paid-workshop")
	await aim_at(green); drum._physics_process(20); feeder._physics_process(8)
	await aim_at(landing); player.interact(); await press("Collect "+Hud.pretty("rustclay_brick"))
	check(_sim().material_count("rustclay_brick")==16 and machine(drum).cargo.is_empty() and machine(feeder).output.get("rustclay_brick",0)==4,"one request delivers actual bricks and makes a new four-brick batch")
	for part in 4:
		if not await place_paid_brick(landing.global_position+Vector3(4+2*(part%2),0,-3-2*(part/2))): return
	check(_sim().material_count("rustclay_brick")==8,"eight delivered bricks pay four actual building cubes")
	await snap("paid-brick-foundation")
	check(manager.write(WORKSHOP_COMPLETE,player),"save construction, actual manufactured identities and exact remaining workshop contents")
	print("LF2_PAID_WORKSHOP delivery=16 construction=8 feeder_output=4 available_heat=2")

func place_paid_brick(at: Vector3) -> bool:
	player.work_panel.close_panel()
	var build := player.placement
	build.set_build_mode_enabled(true)
	player.build_palette.open_panel()
	player.build_palette.select_entry(&"cube","shape")
	player.build_palette.select_material(&"rustclay_brick")
	player.build_palette.close_panel()
	for attempt in 16:
		var target := terrain.surface_position(floori(at.x)+attempt%4,floori(at.z)+attempt/4)
		terrain.ensure_area(target,20)
		target.y=terrain.rendered_height(target.x,target.z,target.y)
		player.position=target+Vector3(0,2.3,3)
		for frame in 2: await get_tree().physics_frame
		player.camera.position=Vector3.ZERO; player.camera.look_at(target)
		build._update_preview()
		if not build.preview_valid: continue
		var before := _sim().material_count("rustclay_brick")
		var event := InputEventAction.new(); event.action="primary_action"; event.pressed=true
		player._unhandled_input(event)
		build.set_build_mode_enabled(false)
		await get_tree().physics_frame
		return check(_sim().material_count("rustclay_brick")==before-2,"actual camera/click consumes delivered construction material")
	build.set_build_mode_enabled(false)
	return check(false,"legal physical footprint for paid bricks")

func restore_workshop() -> void:
	var manager := SaveManager.new()
	var previous: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(WORKSHOP_PENDING))
	if not check(manager.read(WORKSHOP_PENDING,player),"fresh process loads combined paid workshop: "+manager.last_error): return
	freeze_fixtures()
	check(_sim().leyline_save()==previous.leylines and _sim().contraption_save()==previous.contraptions and JSON.parse_string(_sim().export_json())==JSON.parse_string(previous.sim),"all source, machine and manufactured ownership survives restart exactly")
	var blue := fixture("blue_delay")
	var drum := fixture("cargo_winch")
	var feeder := fixture("pressure_feeder")
	await aim_at(fixture("green_junction")); blue._physics_process(2)
	check(machine(drum).moving and machine(feeder).escrow_heat==1 and machine(fixture("red_heat_buffer")).heat==2,"saved request pays each receiver once")
	drum._physics_process(20); feeder._physics_process(8); blue._physics_process(100)
	await aim_at(fixture("winch_landing")); player.interact(); await press("Collect "+Hud.pretty("rustclay_brick"))
	check(_sim().material_count("rustclay_brick")==16 and machine(feeder).output.get("rustclay_brick",0)==4,"fresh process completes one real delivery and one real firing")
	previous=JSON.parse_string(FileAccess.get_file_as_string(WORKSHOP_COMPLETE))
	check(manager.read(WORKSHOP_COMPLETE,player),"fresh process loads the completed paid construction")
	freeze_fixtures()
	check(_sim().contraption_save()==previous.contraptions and JSON.parse_string(_sim().export_json())==JSON.parse_string(previous.sim) and kindling_active(),"finished workshop retains exact contents and the existing crafted Kindling")
	var bricks := 0
	var blocks: Array = []
	SaveManager._walk(player.world_root(),blocks,[],[])
	for block in blocks:
		if block.material_family==&"rustclay_brick": bricks+=1
	check(bricks==4,"four delivered-and-paid brick cubes survive fresh restart")
