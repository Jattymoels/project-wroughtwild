extends "res://tests/home_workshop_review.gd"
## Real paid transactions on declared inspection stock; not a first-hour run.
const SAVE := "user://e1-stations.json"
var sites: Array[StationSite] = []
var camera: Camera3D
var caption: Label
var output := ""
var backend := ""
var automatic := true

func _run() -> void:
	get_window().size = Vector2i(1440,900)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	backend = RenderingServer.get_current_rendering_method()
	output = ProjectSettings.globalize_path("res://../evidence/"+backend)
	DirAccess.make_dir_recursive_absolute(output)
	player.hud.hide()
	player.hide()
	player.spring_arm.set_physics_process(false)
	player.camera.current = false
	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 42
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24,20)
	caption.add_theme_font_size_override("font_size",22)
	layer.add_child(caption)
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.glow_enabled = false
	var args := OS.get_cmdline_user_args()
	automatic = not args.has("--play")
	if args.has("--restore"):
		await restore_check()
		await finish_e1("restore")
		return
	check(sim.contraption_bind_world("legacy_v1",0),"isolated empty native ledger")
	sim.drop_inventory()
	sim.add_material("wood",18) # Eight for bench, ten for frame; fixed stock.
	check(sim.craft("workbench_kit").crafted,"field recipe spends original eight wood")
	var bench := _place(&"workbench_kit",&"wood",Vector3i.ZERO,"volume",0,0,true) as StationSite
	if bench == null: await finish_e1("failed"); return
	bench.name="E1Workbench"
	sites.append(bench)
	player.placement.set_build_mode_enabled(false)
	await settle()
	bench.interact(player)
	check(player.work_panel.craft("timber_frame").crafted,"paid frame is made at actual bench")
	sim.add_material("fieldstone",6)
	check(player.work_panel.craft("mason_yard_kit").crafted,"yard recipe spends the paid frame and six fieldstone")
	player.work_panel.close_panel()
	var yard := _place(&"mason_yard_kit",&"wood",Vector3i(3,0,0),"volume",0,0,true) as StationSite
	if yard == null: await finish_e1("failed"); return
	yard.name="E1MasonYard"
	sites.append(yard)
	player.placement.set_build_mode_enabled(false)
	await settle(30)
	check(sim.material_count("wood")==0 and sim.material_count("fieldstone")==0 and sim.material_count("timber_frame")==0,"both stations pay exactly 18 wood and six fieldstone")
	check(get_tree().get_nodes_in_group("crafting_stations").size()==2,"two native paid station owners")
	view_site(bench)
	await capture("01-workbench","Pegged wood workface / contained wooden clamp / existing paid station")
	view_site(yard)
	await capture("02-mason-yard","Stone dressing bed / attached chisel rest / fixed cosmetic bed stones")
	await bounds_check()
	await craft_check(bench)
	await craft_check(yard)
	await corners_check()
	await settle(30)
	var manager := SaveManager.new()
	check(manager.write(SAVE,player),"atomic save of paid stations and crafted holdings")
	var saved := manager.capture(player)
	check(manager.apply(player,JSON.parse_string(JSON.stringify(saved))),"ordinary in-process restoration")
	if manager.capture(player).stations!=saved.stations:
		var diagnostic:=FileAccess.open(output.path_join("station-diagnostic.json"),FileAccess.WRITE)
		diagnostic.store_string(JSON.stringify({"before":saved.stations,"after":manager.capture(player).stations},"\t"))
		diagnostic.close()
	check(manager.capture(player).stations==saved.stations,"exact native station keys and rotations restore")
	check(JSON.parse_string(sim.export_json())==JSON.parse_string(saved.sim),"exact inventory, costs and work ownership restore")
	sites.clear()
	for n in get_tree().get_nodes_in_group("crafting_stations"):sites.append(n)
	if args.has("--benchmark"):
		await benchmark()
	elif args.has("--capture"):
		await gallery()
	if automatic: await finish_e1("checks")
	else:
		view_site(sites[0])
		caption.text="ART-07E1 / 1 bench  2 yard / Esc quit\nInspection stock; native recipe transactions"

func settle(count := 3) -> void:
	for i in count: await get_tree().physics_frame

func view_site(site: StationSite, distance := 2.7) -> void:
	var at := site.global_position+Vector3.UP*.55
	camera.position = at+Vector3(.65,.52,1).normalized()*distance
	camera.look_at(at)

func capture(name: String, text: String) -> void:
	caption.text="ART-07E1 / "+backend+"\n"+text
	if not OS.get_cmdline_user_args().has("--capture"): return
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join(name+".png"))

func click(action: String) -> void:
	var event := InputEventAction.new()
	event.action=action
	event.pressed=true
	player._unhandled_input(event)

func craft_check(site: StationSite) -> void:
	player.placement.set_build_mode_enabled(false)
	var id := String(site.station_id)
	var recipe := "timber_frame" if id=="workbench" else "dress_stone"
	var ingredient := "wood" if id=="workbench" else "split_stone"
	var quantity := 10 if id=="workbench" else 2
	check(_aim(site,site.position+Vector3(0,.98,2),site.position+Vector3.UP*.7),"actual E ray reaches "+id)
	click("interact")
	var before := sim.export_json()
	check(not player.work_panel.craft(recipe).crafted and before==sim.export_json(),"refused craft retains exact native ownership")
	check(site.get_node_or_null("CraftWorkResponse")==null,"refused craft has no success response")
	sim.add_material(ingredient,quantity)
	var oracle := WroughtwildSim.new()
	check(oracle.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()) and oracle.import_json(sim.export_json()),"exact independent native craft oracle")
	var expected: Dictionary = oracle.craft(recipe)
	var result: Dictionary = player.work_panel.craft(recipe)
	check(result.crafted and result==expected and sim.export_json()==oracle.export_json(),"real panel craft preserves costs, output, XP and RNG: "+id)
	player.work_panel.close_panel()
	var response := site.get_node_or_null("CraftWorkResponse")
	check(response!=null and site.get_children().filter(func(n):return n.name=="CraftWorkResponse").size()==1,"exactly one existing completion response")
	var held_pose: Transform3D=response.get_child(0).transform
	var held_rules:=sim.export_json()
	get_tree().paused=true
	for i in 5:await get_tree().process_frame
	check(response.get_child(0).transform==held_pose and sim.export_json()==held_rules,"pause freezes existing feedback and exact native ownership")
	get_tree().paused=false
	view_site(site)
	await capture("03-"+id+"-work","Existing native paid completion / transient flecks, no automatic work")
	if OS.get_cmdline_user_args().has("--capture"):
		for i in 24:
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png(output.path_join("work-"+id+"-%03d.png"%i))
	await settle(30)
	check(site.get_node_or_null("CraftWorkResponse")==null,"completion expires to idle")
	var body: Transform3D = site.get_node("CollisionShape3D").global_transform
	var economy := sim.export_json()
	site.refresh_visual(sim)
	check(site.get_node_or_null("CraftWorkResponse")==null and sim.export_json()==economy and site.get_node("CollisionShape3D").global_transform==body,"visual refresh is silent and preserves body/ownership")

func bounds_check() -> void:
	var geometry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://e1/geometry.json"))
	for id: StringName in [&"workbench",&"mason_yard"]:
		var previous := 100000
		for level: String in ["near","middle","far"]:
			var mesh := E1StationArt.mesh_for(id,level)
			var triangles := 0
			for i in mesh.get_surface_count(): triangles+=mesh.surface_get_array_index_len(i)/3
			check(triangles==int(geometry[String(id)+"_"+level].triangles),"independently imported triangle count")
			check(triangles<previous,"authored detail reduces triangles")
			previous=triangles
			check(AABB(Vector3(-.48,0,-.48),Vector3(.96,2,.96)).grow(.00001).encloses(mesh.get_aabb()),"every detail fits native body")
		for site in sites:
			if site.station_id!=id:continue
			check(site.get_node("CollisionShape3D").shape.size==Vector3(.96,2,.96),"unchanged full two-metre station body")
			check(StationSite.kit_mesh(sim,StringName(String(id)+"_kit"))==site._mesh.mesh,"preview and paid object share actual mesh")

func corners_check() -> void:
	var build := player.placement
	sim.add_material("wood",500) # Declared corner fixture materials, all spent natively.
	for id: String in ["workbench","mason_yard"]:
		var kit := StringName(id+"_kit")
		sim.add_material(kit,9) # Isolate placement/refusal; first two kits were crafted.
		for fine in [false,true]:
			for turn in 4:
				var cell := Vector3i(10+turn*8,0,8+(8 if fine else 0)+(16 if id=="mason_yard" else 0))
				if fine:cell+=Vector3i.ONE
				player.position=Vector3(-10,3,-10)
				for axis in [0,2]:
					for y in 2:check(build.place_piece({"kind":"face","axis":axis,"cell":cell+Vector3i(0,y*2,0)},&"wall_panel",&"wood")!=null,"paid D1 corner wall")
				check(build.place_piece({"kind":"face","axis":1,"cell":cell},&"half_slab" if fine else &"floor_slab",&"wood")!=null,"paid native full/fine floor")
				await settle()
				build.set_build_mode_enabled(true)
				player.build_palette.group="All"
				player.build_palette.open_panel()
				player.build_palette.select_entry(kit,"kit")
				player.build_palette.close_panel()
				build.preview_rotation_step=turn
				var base := Vector3(cell)*.5
				player.camera.global_position=base+Vector3(1.5,1.65,2.5)
				player.camera.look_at(base+Vector3(.25,.0625 if fine else .125,.25))
				build._update_preview()
				check(build.preview_element.get("cell")==cell and build.preview_valid,"actual floor ray gives valid full/fine rotated ghost")
				var ghost := build._preview_mesh.global_transform
				var count := sim.material_count(kit)
				var owners := get_tree().get_nodes_in_group("crafting_stations").size()
				if turn==0:
					camera.global_transform=player.camera.global_transform
					await capture("04-"+id+"-ghost-"+str(fine),"Actual floor ray / native kit preview / unchanged full collision")
				click("primary_action")
				await settle()
				check(sim.material_count(kit)==count-1 and get_tree().get_nodes_in_group("crafting_stations").size()==owners+1,"click spends one kit and creates one station")
				var site: StationSite
				for n in get_children():
					if n is StationSite and n.position.distance_to(base)<2:site=n
				if not check(site!=null,"corner site exists"):continue
				site.name="E1_%s_%s_%d"%[id,fine,turn]
				check(site.global_transform.is_equal_approx(ghost),"placed pose matches visible preview")
				check(site._mesh.mesh==StationSite.kit_mesh(sim,kit),"corner uses current imported model")
				var query := PhysicsShapeQueryParameters3D.new()
				query.shape=StationSite.BODY
				query.transform=site.get_node("CollisionShape3D").global_transform
				query.exclude=[site.get_rid()]
				for hit in get_world_3d().direct_space_state.intersect_shape(query):check(not hit.collider is PlacedBlock or hit.collider.element.axis==1,"full body clears actual walls")
				count=sim.material_count(kit)
				click("primary_action")
				check(sim.material_count(kit)==count and get_tree().get_nodes_in_group("crafting_stations").size()==owners+1,"occupied refusal preserves kit and exact object count")
				build.set_build_mode_enabled(false)
				check(_aim(site,site.position+Vector3(0,.98,2),site.position+Vector3.UP*.7),"real interaction ray reaches corner station")
				click("interact")
				check(player.work_panel.visible,"actual E opens corner station controls")
				player.work_panel.close_panel()
				player.position=site.position+Vector3(0,1,2.5)
				var collision := player.move_and_collide(Vector3(0,0,-3),true)
				check(collision!=null and collision.get_collider()==site,"real player capsule cannot bypass station")
				if turn==0:
					view_site(site)
					await capture("05-"+id+"-corner-"+str(fine),"Paid wall/floor corner / same ghost and body / actual usable station")
	build.set_build_mode_enabled(false)

func restore_check() -> void:
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
	var manager := SaveManager.new()
	check(manager.read(SAVE,player),"fresh process reads isolated checkpoint: "+manager.last_error)
	await settle()
	check(JSON.parse_string(sim.export_json())==JSON.parse_string(saved.sim),"fresh exact inventory/XP/work ownership")
	check(manager.capture(player).stations==saved.stations,"fresh exact station keys/poses/ownership")
	# Disk JSON numbers are floats; recapture uses integer lattice cells. Compare
	# complete serialized records without dropping fields or rounding values.
	check(JSON.parse_string(JSON.stringify(manager.capture(player).blocks))==saved.blocks,"fresh exact serialized paid corner lattice")
	check(JSON.parse_string(sim.contraption_save())==JSON.parse_string(saved.contraptions),"source/machine ledger unchanged")
	check(get_tree().get_nodes_in_group("crafting_stations").size()==18,"eighteen stations restore once")
	for n in get_tree().get_nodes_in_group("crafting_stations"):
		sites.append(n)
		check(n._mesh.mesh==StationSite.kit_mesh(sim,StringName(String(n.station_id)+"_kit")),"fresh packed-model appearance agrees with kit")
		check(n.get_node_or_null("CraftWorkResponse")==null,"restore cannot replay completed craft")
		check(_aim(n,n.position+Vector3(0,.98,2),n.position+Vector3.UP*.7),"fresh station remains physically reachable")
		click("interact")
		check(player.work_panel.visible,"fresh E opens restored station controls")
		player.work_panel.close_panel()
	await bounds_check()
	view_site(sites[0])
	await capture("07-restored","Fresh process / same paid stations and holdings / no replayed craft")

func gallery() -> void:
	for id: StringName in [&"workbench",&"mason_yard"]:
		var site: StationSite=sites.filter(func(n):return n.station_id==id)[0]
		view_site(site)
		for level: String in ["near","middle","far"]:
			site._mesh.mesh=E1StationArt.mesh_for(id,level)
			await capture("06-"+String(id)+"-"+level,"Authored "+level+" detail / same camera and body")
		site.refresh_visual(sim)
		for i in 48:
			var angle := -.7+float(i)/47*1.4
			var at := site.position+Vector3.UP*.55
			camera.position=at+Vector3(sin(angle)*2.5,1.2,cos(angle)*2.5)
			camera.look_at(at)
			await capture("orbit-"+String(id)+"-%03d"%i,"Actual static model / camera orbit")
		view_site(site)
		sun.light_energy=.22
		await capture("06-"+String(id)+"-shade","Shade / ordinary unlit material")
		sun.light_energy=.08
		environment.ambient_light_energy=.12
		await capture("06-"+String(id)+"-dusk","Dusk / no magical emission or work pulse")
		sun.light_energy=1.15
		environment.ambient_light_energy=.45

func benchmark() -> void:
	var rows: Array=[]
	for level: String in ["baseline","near","middle","far"]:
		for site in sites:
			site._mesh.mesh=AuthoredAssets.mesh_for(String(site.station_id)) if level=="baseline" else E1StationArt.mesh_for(site.station_id,level)
		camera.position=Vector3(11,12,24)
		camera.look_at(Vector3(9,0,9))
		for i in 132:await get_tree().process_frame
		var previous := Time.get_ticks_usec()
		var times: Array[float]=[]
		for i in 360:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			times.append(float(now-previous)/1000)
			previous=now
		times.sort()
		rows.append({"level":level,"p50_ms":times[180],"p95_ms":times[342],"worst_ms":times[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	var f:=FileAccess.open(output.path_join("benchmark.json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"renderer":backend,"device":RenderingServer.get_video_adapter_name(),"resolution":[1440,900],"warmup":132,"samples":360,"rows":rows},"\t"))

func finish_e1(mode: String) -> void:
	var f:=FileAccess.open(output.path_join(mode+".json"),FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"renderer":backend,"scope":"actual paid transactions on fixed inspection stock, not owner gameplay"},"\t"))
	f.close()
	print("E1_",mode.to_upper()," ",checks," checks, ",failures," failures")
	for child in get_children():child.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	get_tree().quit(1 if failures else 0)

func _unhandled_input(event: InputEvent) -> void:
	if automatic or not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_ESCAPE:get_tree().quit()
	if event.keycode in [KEY_1,KEY_2]:
		var id: StringName=&"workbench" if event.keycode==KEY_1 else &"mason_yard"
		var found: StationSite=sites.filter(func(n):return n.station_id==id)[0]
		view_site(found)
