extends "res://tests/home_workshop_review.gd"
## Deterministic paid operations on supplied inspection stock. This is not a
## first-hour journey. Only the model/state view differs in the copied game.
const SAVE := "user://e2-held-firing.json"
var forge: StationSite
var feeder: ContraptionSite
var camera: Camera3D
var caption: Label
var output := ""
var backend := ""
var frames: Array = []
var auto := false
var finished := false

func _run() -> void:
	get_window().size = Vector2i(1600,900)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	backend = RenderingServer.get_current_rendering_method()
	output = ProjectSettings.globalize_path("res://../evidence/"+backend)
	DirAccess.make_dir_recursive_absolute(output)
	player.hud.hide()
	player.hide() # External review camera must not expose first-person-only hands.
	player.spring_arm.set_physics_process(false)
	player.camera.current = false
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 42
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(28,22)
	caption.add_theme_font_size_override("font_size",22)
	layer.add_child(caption)
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.glow_enabled = false
	var args := OS.get_cmdline_user_args()
	auto = args.has("--capture") or args.has("--check") or args.has("--restore") or args.has("--benchmark")
	if args.has("--restore"):
		await _restore()
		await _finish_e2("restore")
		return
	check(sim.contraption_bind_world("legacy_v1",0), "isolated context-free save uses its existing seed-zero legacy identity")
	sim.drop_inventory()
	sim.add_station("workbench") # Supplied assembly facility, no pacing claim.
	sim.add_materials({"timber_frame":1,"stone":8,"iron_ore":4})
	check(sim.craft("forge_kit").crafted, "original forge recipe pays original inputs")
	forge = _place(&"forge_kit",&"wood",Vector3i.ZERO,"volume",0,0,true) as StationSite
	if forge == null:
		await _finish_e2("failed-placement")
		return
	player.placement.set_build_mode_enabled(false)
	player.position = Vector3(0,1,3)
	await _settle()
	_view()
	check(get_tree().get_nodes_in_group("crafting_stations").size()==1 and sim.material_count("forge_kit")==0,"one paid kit produces exactly one usable forge")
	check(forge.feeder_eligible(sim),"forge retains physical player-built identity")
	await _bounds()
	await _capture("01-basic-cold","BASIC / cold basin / steady light remains the existing decorative light")
	var pose := forge.transform
	var body: Shape3D = forge.get_node("CollisionShape3D").shape
	# A genuine cold refusal spends nothing and must not make a work response.
	sim.add_material("raw_clay",8)
	forge.interact(player)
	var before := sim.export_json()
	check(not player.work_panel.craft("refine_rustclay_brick").crafted and sim.export_json()==before,"cold refusal preserves all clay and ownership")
	check(forge.get_node_or_null("CraftWorkResponse")==null,"cold refusal creates no success feedback")
	player.work_panel.close_panel()
	await _manual()
	await _settle(30)
	check(forge.get_node("E2State").amount==0,"successful manual response expires to cold")
	# The actual panel upgrade pays native costs and changes this very object.
	var experience: Dictionary = JSON.parse_string(sim.export_json())
	experience.economy.skill_xp.blacksmithing = 1000 # Declared review skill fixture.
	check(sim.import_json(JSON.stringify(experience)),"review smith experience uses the existing save schema")
	for id: String in sim.station("forge_improved").upgrade_cost:
		sim.add_material(id,int(sim.station("forge_improved").upgrade_cost[id]))
	forge.interact(player)
	var oracle := WroughtwildSim.new()
	check(oracle.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()) and oracle.import_json(sim.export_json()),"upgrade oracle begins with exact economy")
	check(oracle.build_station("forge_improved") and player.work_panel.upgrade(),"normal panel performs paid in-place upgrade")
	check(sim.export_json()==oracle.export_json(),"upgrade payment and progression exactly match unchanged native operation")
	player.work_panel.close_panel()
	check(forge.transform==pose and forge.get_node("CollisionShape3D").shape==body and get_tree().get_nodes_in_group("crafting_stations").size()==1,"upgrade retains original site, body, pose and one object")
	check(StationSite.kit_mesh(sim,&"forge_kit")==forge._mesh.mesh,"later kit preview shares the current global improved tier")
	check(not sim.kit_item_ids().has("forge_improved_kit"),"upgrade introduces no new kit")
	await _capture("03-improved-cold","IMPROVED / same plinth, paid collar and refined plate / same body")
	await _manual()
	await _settle(30)
	await _placement_and_corners()
	await _feeder()
	if args.has("--benchmark"):
		await _benchmark()
		await _finish_e2("benchmark")
		return
	if auto:
		await _working_proof()
		await _finish_e2("checks")
	else:
		feeder.set_physics_process(true)
		caption.text="E2 / actual native state / C craft  W wind  F start  P pause/resume  X cancel  K collect\n1/2/3 detail   Esc quit / inspection stock only"
		set_process(true)

func _settle(count := 3) -> void:
	for i in count: await get_tree().physics_frame

func _view(distance := 4.4) -> void:
	var at := forge.global_position+Vector3.UP*.95
	camera.position = at+Vector3(.52,.26,1).normalized()*distance
	camera.look_at(at)

func _capture(name: String, text: String) -> void:
	caption.text = "ART-07E2 / "+backend+"\n"+text
	if not OS.get_cmdline_user_args().has("--capture"):return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name+".png"))

func _manual() -> void:
	sim.add_materials({"raw_clay":8,"wood":1})
	forge.interact(player)
	var oracle := WroughtwildSim.new()
	check(oracle.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()) and oracle.import_json(sim.export_json()),"manual oracle starts at same exact economy")
	var expected: Dictionary = oracle.craft("refine_rustclay_brick")
	var result: Dictionary = player.work_panel.craft("refine_rustclay_brick")
	check(result.crafted and result==expected and sim.export_json()==oracle.export_json(),"actual manual forging retains exact recipe, fuel, XP and ownership")
	check(forge.get_node_or_null("CraftWorkResponse")!=null,"original paid local work flecks still exist")
	player.work_panel.close_panel()
	forge.get_node("E2State")._process(0)
	check(forge.get_node("E2State").amount==1,"only successful local manual completion activates buried work light")
	await _capture("02-"+String(forge.current_station_id(sim))+"-manual","PAID MANUAL FORGING / original cost and completion flecks; no craft timer added")

func _bounds() -> void:
	var audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://e2/geometry.json"))
	for tier: StringName in [&"forge_basic",&"forge_improved"]:
		var prev := 100000
		for level: String in ["near","middle","far"]:
			var mesh: ArrayMesh = E2ForgeArt.mesh_for(tier,level)
			var count := 0
			for i in mesh.get_surface_count():count+=mesh.surface_get_array_index_len(i)/3
			check(count==int(audit[String(tier)+"_"+level].triangles),"actual exported triangles match source: "+String(tier)+level)
			check(count<prev,"detail level reduces actual triangles")
			prev=count
			check(AABB(Vector3(-.48,0,-.48),Vector3(.96,2,.96)).grow(.00001).encloses(mesh.get_aabb()),"all mesh details fit unchanged native body")
			check(mesh.get_surface_count()==5,"five shared material roles per tier/detail")
	check(forge.get_node("CollisionShape3D").shape.size==Vector3(.96,2,.96),"native body is exactly unchanged")
	check(is_equal_approx(forge.get_node("HearthLight").light_energy,preload("res://art/station_look.tres").hearth_energy),"existing decorative light control preserved")

func _placement_and_corners() -> void:
	var build := player.placement
	sim.add_materials({"forge_kit":10,"wood":100}) # Failure/corner inspection stock.
	build.set_build_mode_enabled(true)
	build._select_kit(&"forge_kit")
	build.preview_element={"kind":"volume","axis":0,"cell":Vector3i.ZERO}
	build.preview_visible=true
	var owned := sim.material_count("forge_kit")
	check(not build.try_place_block() and sim.material_count("forge_kit")==owned,"occupied placement refuses and retains kit")
	for fine in [false,true]:
		for turn in 4:
			var cell:=Vector3i(16+turn*8,0,12+(8 if fine else 0))
			if fine:cell+=Vector3i(1,0,1)
			for axis in [0,2]:
				for y in 2:check(build.place_piece({"kind":"face","axis":axis,"cell":cell+Vector3i(0,y*2,0)},&"wall_panel",&"wood")!=null,"paid corner wall")
			check(build.place_piece({"kind":"face","axis":1,"cell":cell},&"floor_slab",&"wood")!=null,"paid corner footing")
			await _settle()
			build._select_kit(&"forge_kit")
			build.preview_element={"kind":"volume","axis":0,"cell":cell}
			build.preview_visible=true
			build.preview_rotation_step=turn
			owned=sim.material_count("forge_kit")
			check(build.try_place_block() and sim.material_count("forge_kit")==owned-1,"full/fine corner accepts one paid current-tier forge")
			await _settle()
			for n: Node in get_tree().get_nodes_in_group("crafting_stations"):
				if n==forge or n.position.distance_to(Vector3(cell)*.5)>2:continue
				n.name="E2Corner_%s_%d"%[fine,turn]
				check(n._mesh.mesh==StationSite.kit_mesh(sim,&"forge_kit"),"new corner forge uses global upgrade appearance")
				var query:=PhysicsShapeQueryParameters3D.new()
				query.shape=StationSite.BODY
				query.transform=n.get_node("CollisionShape3D").global_transform
				query.exclude=[n.get_rid()]
				for hit in get_world_3d().direct_space_state.intersect_shape(query):
					check(not hit.collider is PlacedBlock or hit.collider.element.axis==1,"full physical body clears corner walls")
				player.position=n.position+Vector3(0,1,2.5)
				var collision:=player.move_and_collide(Vector3(0,0,-3),true)
				check(collision!=null,"actual player capsule cannot walk through the forge body")
	build.set_build_mode_enabled(false)
	player.position=Vector3(0,1,3)
	_view()

func _feeder() -> void:
	sim.add_materials({"pressure_feeder_kit":1,"raw_clay":16,"wood":2})
	check(sim.contraption_place("pressure_feeder","e2_feeder",Vector3(3.5,0,.5),0),"one paid feeder kit creates one native owner")
	feeder=ContraptionSite.new()
	feeder.machine_key="e2_feeder"
	feeder.sim=sim
	add_child(feeder)
	feeder.set_physics_process(false)
	await _settle()
	check(feeder.attach_feeder(forge.station_key,"").ok,"upgraded physical basic forge accepts existing support and connection envelope")
	check(sim.contraption_deposit(feeder.machine_key,"raw_clay",16).ok,"load real clay")
	check(sim.contraption_deposit(feeder.machine_key,"wood",2).ok,"load real fuel separately")
	check(feeder.perform("wind").ok and feeder.perform("start").ok,"native paid work reserves original firing")

func _working_proof() -> void:
	# Controlled real ticks; each frame derives its phase from native cycle_seconds.
	for i in 48:
		feeder._physics_process(1.0/24.0)
		forge.get_node("E2State")._process(0)
		frames.append({"frame":i,"native":sim.contraption_state(feeder.machine_key),"phase":forge.get_node("E2State").phase,"amount":forge.get_node("E2State").amount})
		await _capture("motion-%03d"%i,"PAID FIRING / 24 Hz deterministic native ticks / reserved clay + fuel + drive")
	check(forge.get_node("E2State").visual_state=="paid firing","working light follows real attached native firing")
	camera.position=Vector3(5.0,3.0,7.0)
	camera.look_at(Vector3(1.8,1,.5))
	await _capture("03-working-context","PAID FIRING / existing feeder, supported forge and unchanged centre-height connection")
	feeder.interact(player)
	await _capture("03-working-controls","ACTUAL FEEDER CONTROLS / reserved ingredients and drive remain native-owned")
	player.work_panel.close_panel()
	_view()
	check(feeder.perform("pause").ok,"native pause accepted")
	forge.get_node("E2State")._process(0)
	var held := sim.contraption_save()
	var phase: float=forge.get_node("E2State").phase
	for i in 12:
		feeder._physics_process(.1)
		forge.get_node("E2State")._process(0)
		check(sim.contraption_save()==held and forge.get_node("E2State").phase==phase,"explicit pause freezes exact ownership and visual phase")
		await _capture("motion-%03d"%(48+i),"PAUSED / same paid firing held; no progress or new success pulse")
	await _capture("04-paused","PAUSED / exact paid inputs, drive and fractional progress retained")
	var manager:=SaveManager.new()
	check(manager.write(SAVE,player),"save paused paid firing through normal atomic SaveManager")
	check(feeder.perform("resume").ok,"native resume accepted")
	var blocker:=StaticBody3D.new()
	var shape:=CollisionShape3D.new()
	shape.shape=BoxShape3D.new()
	shape.shape.size=Vector3(.3,1,.8)
	blocker.add_child(shape)
	blocker.position=Vector3(2,.85,.5)
	add_child(blocker)
	await _settle()
	held=sim.contraption_save()
	feeder._physics_process(3)
	forge.get_node("E2State")._process(0)
	check(not feeder.feeder_status().ready and sim.contraption_save()==held,"real connection blocker holds native firing unchanged")
	check(forge.get_node("E2State").visual_state=="paused / held firing","blocked connection cannot display advancing work")
	blocker.free()
	await _settle()
	var before_pause: float=forge.get_node("E2State").phase
	get_tree().paused=true
	for i in 5:await get_tree().process_frame
	check(forge.get_node("E2State").phase==before_pause,"engine pause freezes shader input without TIME")
	get_tree().paused=false
	feeder._physics_process(8)
	forge.get_node("E2State")._process(0)
	check(int(sim.contraption_state(feeder.machine_key).output.get("rustclay_brick",0))==4,"one held firing completes exactly four existing bricks")
	await _capture("05-complete","COMPLETE / four real bricks in existing tray / no extra fuel or product")
	var bricks_before:=sim.material_count("rustclay_brick")
	check(_collect_output(),"normal output withdrawal collects the completed bricks")
	check(sim.material_count("rustclay_brick")==bricks_before+4,"collection transfers exactly four bricks to existing inventory")
	check(not _collect_output() and sim.material_count("rustclay_brick")==bricks_before+4,"empty tray cannot pay again")
	# Cancelling any remaining queue cannot duplicate the settled firing.
	feeder.perform("cancel")
	var idle:=sim.contraption_save()
	check(not feeder.perform("cancel").ok and sim.contraption_save()==idle,"repeated cancellation cannot duplicate stock")
	for level: String in ["near","middle","far"]:
		forge._mesh.mesh=E2ForgeArt.mesh_for(&"forge_improved",level)
		forge.get_node("E2State").bind_mesh()
		_view({"near":4.4,"middle":10.0,"far":24.0}[level])
		await _capture("06-distance-"+level,"IMPROVED / "+level+" at "+str({"near":4.4,"middle":10,"far":24}[level])+" m / explicit candidate detail")
	forge.refresh_visual(sim)
	_view()
	sun.light_energy=.16
	environment.ambient_light_energy=.20
	await _capture("07-shade","SHADE / cold forge / existing decorative hearth light retained")
	# Read-only presentation calls cannot modify inventory, world or source ledgers.
	var rules_before:=sim.export_json()
	var machines_before:=sim.contraption_save()
	for i in 100:forge.get_node("E2State")._process(.016)
	check(sim.export_json()==rules_before and sim.contraption_save()==machines_before,"one hundred visual reads are pure")

func _restore() -> void:
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	var manager:=SaveManager.new()
	check(manager.read(SAVE,player),"fresh process restores exact paid checkpoint: "+manager.last_error)
	check(JSON.parse_string(sim.export_json())==JSON.parse_string(saved.sim),"fresh process retains exact inventory, skill and global tier")
	check(JSON.parse_string(sim.contraption_save())==JSON.parse_string(saved.contraptions),"fresh process retains exact source/machine escrow")
	feeder=ContraptionSite.find_site(get_tree(),"e2_feeder")
	check(feeder!=null,"fresh process creates one feeder owner")
	if feeder==null:return
	feeder.set_physics_process(false)
	forge=feeder.feeder_forge(String(sim.contraption_state(feeder.machine_key).forge_key))
	check(forge!=null and forge.feeder_eligible(sim),"saved attachment resolves original physical forge key")
	if forge==null:return
	player.position=Vector3(0,1,3)
	await _settle()
	var actual_stations: Array=manager.capture(player).stations
	if actual_stations!=saved.stations:
		var diagnostic:=FileAccess.open(output.path_join("station-roundtrip.json"),FileAccess.WRITE)
		diagnostic.store_string(JSON.stringify({"expected":saved.stations,"actual":actual_stations},"\t"))
	check(actual_stations==saved.stations,"saved stations preserve keys, offsets, rotations and physical ownership")
	check(forge._mesh.mesh==StationSite.kit_mesh(sim,&"forge_kit"),"fresh global tier and later-kit preview agree")
	check(forge.get_node_or_null("CraftWorkResponse")==null,"reload cannot replay manual completion")
	_view()
	forge.get_node("E2State")._process(0)
	check(forge.get_node("E2State").visual_state=="paused / held firing","fresh process shows held paused work")
	await _capture("08-fresh-process-paused","FRESH PROCESS / same tier, attachment, paid escrow and frozen progress")
	check(feeder.perform("resume").ok,"restored firing resumes through actual control")
	feeder._physics_process(8)
	check(int(sim.contraption_state(feeder.machine_key).output.get("rustclay_brick",0))==4,"resumed saved firing completes exactly once")
	var output_before: Dictionary=sim.contraption_state(feeder.machine_key).output.duplicate(true)
	feeder._physics_process(0)
	check(sim.contraption_state(feeder.machine_key).output==output_before,"zero extra time cannot duplicate output")

func _benchmark() -> void:
	caption.text="E2 isolated working forge / benchmark without capture"
	feeder.set_physics_process(true)
	_view()
	for i in 132:await get_tree().process_frame
	var times: Array[float]=[]
	var previous:=Time.get_ticks_usec()
	for i in 600:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		times.append(float(now-previous)/1000.0)
		previous=now
	times.sort()
	var result:={"renderer":backend,"device":RenderingServer.get_video_adapter_name(),"resolution":[1600,900],"warmup_frames":132,"sample_frames":600,"p50_ms":times[300],"p95_ms":times[570],"worst_ms":times[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
	var file:=FileAccess.open(output.path_join("timings.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()

func _collect_output() -> bool:
	var contents: Dictionary=sim.contraption_state(feeder.machine_key).output
	var ok:=false
	for item: String in contents:
		var result: Dictionary=sim.contraption_withdraw(feeder.machine_key,"output",item,int(contents[item]))
		ok=bool(result.ok) or ok
	feeder.refresh_from_sim()
	return ok

func _finish_e2(mode: String) -> void:
	finished=true
	var file:=FileAccess.open(output.path_join(mode+".json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":backend,"device":RenderingServer.get_video_adapter_name(),"frames":frames,"scope":"paid engineering fixture on supplied stock; no owner world opened"},"\t"))
	print("E2_",mode.to_upper()," ",checks," checks, ",failures," failures")
	for child in get_children():child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)

func _unhandled_input(event: InputEvent) -> void:
	if auto or not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_ESCAPE:get_tree().quit()
		KEY_C:await _manual()
		KEY_W:feeder.perform("wind")
		KEY_F:feeder.perform("start")
		KEY_P:feeder.perform("resume" if sim.contraption_state(feeder.machine_key).feeder_paused else "pause")
		KEY_X:feeder.perform("cancel")
		KEY_K:_collect_output()
		KEY_1,KEY_2,KEY_3:
			forge._mesh.mesh=E2ForgeArt.mesh_for(&"forge_improved",["near","middle","far"][event.keycode-KEY_1])
			forge.get_node("E2State").bind_mesh()
