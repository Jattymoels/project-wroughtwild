extends "res://tests/cataclysm_intensive.gd"
## Actual generated site and ordinary kit/payment/UI/save path. Recipe supplies
## are seeded for this engineering review; this is not a discovery playtest.
var source: PressurePocket
var feeder: ContraptionSite
var forge: StationSite
var feeder_key := ""
var review_camera: Camera3D
var captions: Label
var captures: Array[String] = []

func _ready() -> void:
	world_profile="frontier_v5" # Preserve historical workshop geography; explicitly probe V6 too.
	output=ProjectSettings.globalize_path("res://../build/pressure-workshop")
	DirAccess.make_dir_recursive_absolute(output)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--cat-seed="):world_seed=int(arg.get_slice("=",1))
		if arg.begins_with("--pressure-profile="):world_profile=arg.get_slice("=",1)
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	await get_tree().physics_frame
	check(world_profile in ["frontier_v5","frontier_v6"], "workshop uses a supported pressure-source profile")
	check(terrain.map.get("pressure_pockets",[]).size()==1,"one source is generated")
	if terrain.map.get("pressure_pockets",[]).size()!=1:_finish();return
	var definition: Dictionary=terrain.map.pressure_pockets[0]
	check(definition.origin=="pre_cataclysm_blacksmith" and definition.accidental,"source tells an accidental pre-impact history")
	source=PressurePocket.find_source(get_tree(),String(definition.id))
	check(source!=null,"generated source has normal inspection body")
	if source==null:_finish();return
	var work: Vector3=definition.work_position
	terrain.ensure_area(work,24)
	player.global_position=work+Vector3(0,1.2,5)
	for frame in 5:await get_tree().physics_frame
	check(source.source_state().remaining==24,"initial finite source has24strokes")
	check(source.supported(),"old hearth is grounded in actual terrain")
	check(await _aim_body(source),"normal aim ray reaches the struck hearth")
	player.interact()
	check(player.work_panel.is_open() and player.work_panel._custom_title=="The struck blacksmith's hearth","normal E opens source history and remaining pressure")
	player.work_panel.close_panel()
	await _record("struck-hearth",source.global_position)
	_sim().add_station("workbench")
	player.global_position=work+Vector3(0,1.2,5)
	await _place_workshop(work)
	if feeder==null or forge==null:_finish();return
	feeder_key=feeder.machine_key
	check(forge.player_built and not forge.station_key.is_empty(),"paid forge has persistent physical ownership")
	check(forge.feeder_eligible(_sim()),"actual player-built basic forge is eligible")
	var attachment: Dictionary=feeder.attach_feeder(forge.station_key,source.source_id)
	check(attachment.ok,"local attachment: "+String(attachment.get("message",""))+" forge="+str(forge.global_position)+" feeder="+str(feeder.global_position)+" source="+str(source.global_position))
	if not attachment.ok:_finish();return
	check(feeder.perform("charge").ok,"local source charging succeeds")
	check(source.source_state().remaining==20 and _sim().contraption_state(feeder_key).energy==4,"source debit and stored drive match exactly")
	var initial: String=_sim().contraption_save()
	check(not feeder.perform("charge").ok and _sim().contraption_save()==initial,"full store cannot debit source again")
	_sim().add_materials({"raw_clay":32,"wood":4})
	check(_sim().contraption_deposit(feeder_key,"raw_clay",32).moved==32,"explicit hopper clay leaves pack")
	check(_sim().contraption_deposit(feeder_key,"wood",4).moved==4,"ordinary heat fuel enters hopper")
	check(not _sim().contraption_deposit(feeder_key,"iron_ore",1).ok,"unrelated materials cannot enter brick hopper")
	feeder.interact(player)
	check(player.work_panel.is_open(),"ordinary feeder panel opens")
	player.work_panel.close_panel()
	check(feeder.perform("start").ok,"local handle starts a bounded batch")
	feeder._physics_process(2.375)
	var started: Dictionary=_sim().contraption_state(feeder_key)
	check(started.escrow_drive==1 and started.cycle_seconds==2.375 and started.energy==3,"one in-flight recipe owns inputs, fuel and drive")
	check(started.escrow_inputs=={"raw_clay":8} and started.escrow_fuel=={"wood":1},"escrow matches existing manual recipe exactly")
	check(feeder.perform("pause").ok,"local pause is explicit")
	initial=_sim().contraption_save()
	feeder._physics_process(60.0)
	check(_sim().contraption_save()==initial,"paused work gains no catch-up time")
	check(feeder.perform("resume").ok,"resume preserves exact cycle")
	await _save_midcycle()
	if feeder==null:_finish();return
	await _record("working",work)
	# A deliberately oversized tick can finish only its already-reserved cycle;
	# no offline or burst catch-up is allowed. Subsequent cycles receive live ticks.
	for cycle in 4:feeder._physics_process(8.0)
	var complete: Dictionary=_sim().contraption_state(feeder_key)
	check(complete.completed_cycles==4 and complete.output=={"rustclay_brick":16},"four cycles deliver sixteen existing bricks")
	check(complete.escrow_drive==0 and complete.energy==0 and complete.input.is_empty(),"finished work leaves no second owner")
	initial=_sim().contraption_save()
	feeder._physics_process(60.0)
	check(_sim().contraption_save()==initial,"completed batch cannot award output again")
	check(_sim().contraption_withdraw(feeder_key,"output","rustclay_brick",16).moved==16,"output tray transfers bricks once")
	check(not _sim().contraption_withdraw(feeder_key,"output","rustclay_brick",16).ok,"second collection gives nothing")
	await _build_bricks(work)
	await _record("rebuilt",work)
	await _cancel_and_trial()
	var pocket_before: int=source.source_state().remaining
	var core_before: int=_sim().material_count("ventlung")
	check(_sim().contraption_remove(feeder_key).ok,"dismantle returns owned contents and intact core")
	check(_sim().material_count("ventlung")==core_before+1,"Ventlung core survives dismantling")
	check(source.source_state().remaining==pocket_before,"dismantling vents drive without refilling source")
	check(not _sim().contraption_remove(feeder_key).ok,"dismantle cannot refund twice")
	feeder.free()
	_finish()

func _place_workshop(work: Vector3) -> void:
	for recipe_id in ["forge_kit","assemble_pressure_feeder"]:
		var recipe: Dictionary=_sim().recipe(recipe_id)
		for id in recipe.get("inputs",{}):_sim().add_material(String(id),int(recipe.inputs[id]))
		check(_sim().craft(recipe_id).crafted,recipe_id+" pays ordinary bench recipe")
	player.placement.set_build_mode_enabled(true)
	for kit in ["forge_kit","pressure_feeder_kit"]:
		player.placement._select_kit(StringName(kit))
		var selected: Dictionary={}
		# Candidate search uses normal footprint checks on the old flat foundation.
		for offset in [Vector3(0,0,0),Vector3(2,0,0),Vector3(-2,0,0),Vector3(0,0,2),Vector3(0,0,-2),Vector3(2,0,2),Vector3(-2,0,-2),Vector3(-2,0,2),Vector3(2,0,-2)]:
			var at: Vector3=work+offset
			var cell:=Vector3i(floori(at.x/player.placement.registry_grid),roundi(at.y/player.placement.registry_grid),floori(at.z/player.placement.registry_grid))
			var element: Dictionary={"kind":"volume","axis":0,"cell":cell}
			if player.placement.element_accepts(element):selected=element;break
		check(not selected.is_empty(),kit+" has a clear place around the old smithy")
		if selected.is_empty():return
		player.placement.preview_element=selected
		player.placement.preview_visible=true
		check(player.placement.try_place_block(),kit+" places through ordinary payment and collision checks")
		await get_tree().physics_frame
		if kit=="forge_kit":
			for site in get_tree().get_nodes_in_group("crafting_stations"):
				if site is StationSite and site.player_built and site.station_id==&"forge_basic":forge=site
		else:
			for fixture in get_tree().get_nodes_in_group("contraptions"):
				if fixture is ContraptionSite and fixture.kind=="pressure_feeder":feeder=fixture;feeder.set_physics_process(false)
	player.placement.set_build_mode_enabled(false)
	for frame in 2:await get_tree().physics_frame

func _save_midcycle() -> void:
	var manager:=SaveManager.new()
	var snapshot:=manager.capture(player)
	var ledger: String=_sim().contraption_save()
	check(manager.write_data(output.path_join("midcycle.json"),snapshot),"whole world and cycle write atomically")
	check(manager.read(output.path_join("midcycle.json"),player),"checkpoint restores through validating save operation: "+manager.last_error)
	feeder=ContraptionSite.find_site(get_tree(),feeder_key)
	if feeder!=null:feeder.set_physics_process(false)
	check(_sim().contraption_save()==ledger,"save/load preserves exact cycle, materials and source stock")
	for frame in 2:await get_tree().physics_frame
	if feeder!=null:
		forge=feeder.feeder_forge(String(_sim().contraption_state(feeder_key).forge_key))
		check(forge!=null and forge.player_built,"restored attachment finds saved player-built forge")
	var rejected:=snapshot.duplicate(true)
	rejected.world_seed=world_seed+1
	var before: String=_sim().export_json()
	check(not manager.apply(player,rejected) and _sim().contraption_save()==ledger and _sim().export_json()==before,"wrong-world source ledger rejects before any mutation")
	rejected=snapshot.duplicate(true)
	rejected.erase("contraptions")
	check(not manager.apply(player,rejected) and _sim().contraption_save()==ledger,"missing V5 ledger cannot refill a source")
	check(_sim().contraption_bind_world(world_profile,world_seed) and _sim().contraption_save()==ledger,"rebuilding same identity never initializes pressure twice")
	check(not _sim().contraption_validate("") and not _sim().contraption_load("") and _sim().contraption_save()==ledger,"legacy empty-load API cannot reset V5 stock")

func _build_bricks(work: Vector3) -> void:
	player.placement.set_build_mode_enabled(true)
	player.placement.select_shape(&"cube")
	player.placement.selected_material_family=&"rustclay_brick"
	var before: int=_sim().material_count("rustclay_brick")
	for index in 3:
		var at:=work+Vector3(-3.0+index,0,3)
		var element: Dictionary={"kind":"volume","axis":0,"cell":Vector3i(floori(at.x/.5),roundi(at.y/.5),floori(at.z/.5))}
		player.placement.preview_element=element
		player.placement.preview_visible=true
		check(player.placement.try_place_block(),"feeder bricks build normal masonry")
	check(_sim().material_count("rustclay_brick")==before-3*int(_sim().shape("cube").material_cost),"building uses crafted output at existing cost")
	player.placement.set_build_mode_enabled(false)
	await get_tree().physics_frame

func _cancel_and_trial() -> void:
	check(feeder.perform("wind").ok,"manual winding remains available")
	_sim().add_materials({"raw_clay":8,"wood":1})
	_sim().contraption_deposit(feeder_key,"raw_clay",8)
	_sim().contraption_deposit(feeder_key,"wood",1)
	check(feeder.perform("start").ok,"manually driven cycle can reserve same recipe")
	feeder._physics_process(1.0)
	var ledger: String=_sim().contraption_save()
	check(_sim().trial_start_story(412,"forge_tyrant"),"trial test deposits ordinary carried possessions")
	check(not _sim().contraption_tick(feeder_key,20,true).ok and not feeder.perform("charge").ok,"trial pauses machinery and refuses source actions")
	check(_sim().contraption_save()==ledger,"trial never advances or deposits hopper escrow")
	_sim().trial_abandon()
	check(_sim().trial_end(),"leaving the trial restores the protected deposit")
	check(feeder.perform("cancel").ok,"cancellation restores in-flight ingredients and drive")
	var cancelled: Dictionary=_sim().contraption_state(feeder_key)
	check(cancelled.input=={"raw_clay":8,"wood":1} and cancelled.energy==1,"cancel returns exact recipe/fuel/store once")
	ledger=_sim().contraption_save()
	feeder.perform("cancel")
	check(_sim().contraption_save()==ledger,"repeated cancel cannot duplicate recovery")

func _record(id: String,work: Vector3) -> void:
	if DisplayServer.get_name()=="headless":return
	player.hud.hide()
	if review_camera==null:
		review_camera=Camera3D.new();add_child(review_camera);review_camera.fov=64
		review_camera.make_current()
		var canvas:=CanvasLayer.new();add_child(canvas)
		captions=Label.new();captions.position=Vector2(32,24);captions.add_theme_font_size_override("font_size",24);canvas.add_child(captions)
	var from:=work+Vector3(8,0,9)
	# A close side view exposes the separate hopper/tray and both connections;
	# the other views retain the whole ruin and the new masonry in context.
	if id=="working":from=work+Vector3(5,0,-3)
	review_camera.global_position=StrangeSites._ground(terrain,from.x,from.z)+Vector3.UP*2.2
	review_camera.look_at(work+Vector3.UP*.9)
	captions.text="THE STRUCK SMITHY · "+id.to_upper()+" · SEED "+str(world_seed)
	for light in ["day","dusk"]:
		var energy: float=$Sun.light_energy
		if light=="dusk":$Sun.light_energy=energy*.48
		for frame in 3:await RenderingServer.frame_post_draw
		var filename: String=id+"-"+light+".png"
		check(get_viewport().get_texture().get_image().save_png(output.path_join(filename))==OK,"capture "+filename)
		captures.append(filename)
		$Sun.light_energy=energy

func _finish() -> void:
	var manifest_name: String="manifest-headless.json" if DisplayServer.get_name()=="headless" else "manifest.json"
	var file:=FileAccess.open(output.path_join(manifest_name),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures,"profile":world_profile,"seed":world_seed,"scope":"Real generation, kit placement, local controls and save path; seeded recipe ingredients, scripted active ticks, no discovery or balance claim."},"\t"))
	print("PRESSURE_WORKSHOP %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
