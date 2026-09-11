extends Node3D
## Isolated ART-07F3 native-work review. Inspection stock; real paid transactions.
var checks := 0
var failures := 0
var sim: WroughtwildSim
var player: WroughtwildPlayer
var sorter: ContraptionSite
var bellows: ContraptionSite
var camera: Camera3D
var caption: Label
var renderer := "headless"
var recording := false
var sources: Dictionary = {}
var manager
var ferrous_items: Array = []
const SAVE := "user://f3-partial.json"
const DEPLETED := "user://f3-depleted.json"
const SORT_KEY := "fixture_-4_0_0"
const BELLOWS_KEY := "fixture_4_0_0"

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL F3: ",label)

func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--interactive"):
		get_tree().create_timer(120.0,true,false,true).timeout.connect(func(): printerr("F3 review exceeded its bounded duration"); get_tree().quit(2))
	call_deferred("_run")

func body(at: Vector3, size: Vector3) -> StaticBody3D:
	var node := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	node.add_child(collider)
	var mesh := MeshInstance3D.new()
	var cube := BoxMesh.new()
	cube.size = size
	mesh.mesh = cube
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("353c36")
	mat.roughness = .92
	mesh.material_override = mat
	node.add_child(mesh)
	add_child(node)
	node.position = at
	return node

func resource(kind: String, at: Vector3, name_id: String) -> ResourceNode:
	var node: ResourceNode = (load("res://scenes/resource_node.tscn") as PackedScene).instantiate()
	node.name = name_id
	node.resource_id = "f3-inspection-"+name_id
	node.visual = StringName(kind)
	node.material_family = StringName(kind)
	node.remaining_units = 8 if kind=="seam" else 3
	node.units_per_harvest = 2 if kind=="seam" else 3
	node.drive_presses = 4
	node.position = at
	add_child(node)
	return node

func _run() -> void:
	sim = load("res://scripts/sim.gd").shared()
	var tuning: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(ProjectSettings.globalize_path("res://").path_join("../data/tuning/contraptions.json")))
	ferrous_items = tuning.ferrous_items
	check(sim.last_error().is_empty(),"recorded native tuning loads")
	check(sim.contraption_bind_world("legacy_v1",0),"isolated authored context")
	check(sim.contraption_load(""),"fresh machine ledger")
	sim.add_station("workbench")
	body(Vector3(0,-.5,0),Vector3(30,1,24))
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(0,.96,4)
	add_child(player)
	player.set_physics_process(false)
	player.hide()
	player.spring_arm.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_process(false)
	player.placement.set_physics_process(false)
	player.hud.hide()
	player.set_process_unhandled_input(false)
	setup_view()
	for frame in 3: await get_tree().physics_frame
	for kind: String in ["pullstone","ventlung"]:
		var housing := (load("res://f3/assets/"+kind+"_shell.glb") as PackedScene).instantiate() as Node3D
		housing.name = kind+"_aftermath"
		housing.position = Vector3(-1.5 if kind=="pullstone" else 2.5,0,-2.1)
		housing.set_meta("inspection_shell_no_stock",true)
		add_child(housing)
	# Recreate the authored source geography before SaveManager applies finite
	# state, exactly as the normal world does before loading a checkpoint.
	for kind: String in ["pullstone","ventlung"]:
		sources[kind] = resource(kind,Vector3(-1.5 if kind=="pullstone" else 2.5,0,-2.1),kind+"_native")
	var seam := resource("seam",Vector3(5,0,.5),"TargetSeam")
	seam.material_family = &"split_stone"
	seam.remaining_units = 8
	seam.units_per_harvest = 2
	seam.tool_item = &"timber_wedge"
	seam.wedge_set = true
	seam._refresh_wedge_look()
	manager = load("res://scripts/save_manager.gd").new()
	var args := OS.get_cmdline_user_args()
	if args.has("--restart") or args.has("--restart-depleted"):
		var path := DEPLETED if args.has("--restart-depleted") else SAVE
		await restore_check(path)
		finish("restart-depleted" if args.has("--restart-depleted") else "restart")
		return
	sorter = await place("magnetic_sorter",Vector3i(-4,0,0))
	bellows = await place("ventlung_bellows",Vector3i(4,0,0))
	if sorter==null or bellows==null: finish("placement-failed"); return
	for frame in 3: await get_tree().physics_frame
	check(bellows.bellows_target()==seam,"existing nearest prepared seam selected through real line of sight")
	if args.has("--interactive"):
		caption.text="F3 / 1–4 views · 0 overview · L load test batch · S sort · B prime · R release · W source work · F5/F9 save/load"
		return
	if args.has("--benchmark") or args.has("--benchmark-no-shadows"):
		await benchmark()
		return
	if args.has("--motion"):
		await motion()
		return
	recording = args.has("--capture") and DisplayServer.get_name()!="headless"
	view("overview")
	await capture("overview","TWO FINDS / TWO HAND-WORKED DEVICES / inspection stock")
	for kind: String in ["pullstone","ventlung","magnetic_sorter","ventlung_bellows"]:
		view(kind)
		await capture(kind+"-idle","FULL SOURCE / EMPTY OR UNPRIMED DEVICE / no work pulse")
	load_mixed()
	view("magnetic_sorter")
	await capture("sorter-input","HAND-LOADED INPUT / output trays empty")
	check(sorter.perform("sort").ok,"real paid hand operation sorts one bounded batch")
	var sorted: Dictionary = sim.contraption_state(SORT_KEY)
	check(units(sorted.ferrous)==13 and units(sorted.remainder)==3 and units(sorted.input)==12,"native item-order batch routes 16 units and keeps 12 inputs")
	check(sorter._visual.piles.input.get_meta("native_units")==12,"visible input follows native remaining units")
	check(sorter._visual.piles.ferrous.get_meta("native_units")==13,"visible ferrous tray follows native quantity")
	await capture("sorter-first-batch","FIRST 16 SORTED / 12 REMAIN IN INPUT")
	check(sorter.perform("sort").ok,"second real hand operation routes ordinary materials")
	sorted = sim.contraption_state(SORT_KEY)
	check(units(sorted.input)==0 and units(sorted.remainder)==12,"ordinary ingredients remain distinct")
	for id: String in ferrous_items: check(sorted.ferrous.get(id,0)==4,"native ferrous classification: "+id)
	for id: String in ["wood","raw_reed","copper_ore","silver_ore"]: check(sorted.remainder.get(id,0)==3,"native remainder classification: "+id)
	await capture("sorter-trays","FERROUS LEFT / REMAINDER RIGHT / native output stores")
	var before := sim.contraption_save()
	check(not sorter.perform("sort").ok,"empty sort refuses")
	check(sim.contraption_save()==before,"failed operation cannot move stock")
	check(bellows.perform("prime").ok and bellows.perform("prime").ok,"two accepted hand primes")
	check(sim.contraption_state(BELLOWS_KEY).energy==2,"two exact stored operations")
	view("ventlung_bellows")
	await capture("bellows-primed","TWO HAND PRIMES / supported raised platen")
	for kind: String in sources:
		var node := sources[kind] as ResourceNode
		for i in 2: player._apply_work(node,node.work(sim))
		check(node.drive_progress==2 and node.remaining_units==3,"partial finite work: "+kind)
		view(kind)
		await capture(kind+"-worked","TWO OF FOUR PRESSES / finite core still owned by source")
	# Save paid fixtures, both trays, partial resources and primed pressure together.
	check(manager.write(SAVE,player),"atomic native/world partial checkpoint")
	var saved: Dictionary = manager.capture(player)
	var unchanged := sim.export_json()
	for i in 8:
		sorter.refresh_from_sim(); bellows.refresh_from_sim()
		for node in sources.values(): StrangeResourceArt.update(node,.5)
	check(sim.export_json()==unchanged,"visual refresh grants/spends nothing")
	check(manager.read(SAVE,player),"same-process normal save restore: "+manager.last_error)
	await get_tree().physics_frame
	rebind()
	check(sim.export_json()==saved.sim and sim.contraption_save()==saved.contraptions,"all native ownership restores exactly")
	seam = get_node("TargetSeam") as ResourceNode
	view("ventlung_bellows")
	check(bellows.release_at_resource(player).ok,"actual discharge uses existing impact route")
	check(sim.contraption_state(BELLOWS_KEY).energy==1 and seam.remaining_units==6 and not seam.wedge_set,"release spends one prime and existing wedge, grants exactly two split stone as drops")
	await capture("bellows-discharged","ONE PAID RELEASE / wedge consumed / two finite stone released")
	before = sim.contraption_save()
	check(not bellows.release_at_resource(player).ok,"unprepared seam refuses")
	check(sim.contraption_save()==before,"failed release retains remaining pressure")
	# Add a target obstruction while pressure remains: real ray blocks impact.
	seam.wedge_set = true
	var obstruction := body(bellows.position+Vector3(.85,.65,0),Vector3(.25,1.3,.8))
	for i in 2: await get_tree().physics_frame
	check(not bellows.release_at_resource(player).ok and sim.contraption_save()==before,"blocked physical line retains pressure")
	obstruction.free()
	for kind: String in sources:
		var node := sources[kind] as ResourceNode
		var released := 0
		for i in 2:
			var result := node.work(sim)
			released += int(result.get("granted",0))
			player._apply_work(node,result)
		check(released==3 and node.remaining_units==0,"completing actual work releases three finite "+kind)
		var refused := node.work(sim)
		check(refused.has("refusal") and int(refused.get("granted",0))==0,"depleted source cannot pay twice: "+kind)
	for i in 24: await get_tree().physics_frame
	check(manager.write(DEPLETED,player),"depleted sources and remaining work save atomically")
	view("overview")
	await capture("depleted","EMPTY MINERAL HOUSINGS / exhausted sources remain exhausted")
	await refunds()
	if recording or args.has("--restore-cycle"):
		check(manager.read(SAVE,player),"restore reviewable partial state after refund checks")
		await get_tree().physics_frame
		rebind()
		for level: String in ["near","middle","far"]:
			for node in sources.values(): node.get_node("StrangeCore").set_lod(level)
			view("overview")
			await capture("lod-"+level,"SOURCE DETAIL / "+level.to_upper()+" / same native bodies")
	if not args.has("--interactive"): finish("capture" if recording else "checks")

func units(items: Dictionary) -> int:
	var total := 0
	for count in items.values(): total += int(count)
	return total

func load_mixed() -> void:
	for id: String in ferrous_items:
		sim.add_material(id,4)
		check(sim.contraption_deposit(SORT_KEY,id,4).moved==4,"deliberate ferrous hand feed: "+id)
	for id: String in ["wood","raw_reed","copper_ore","silver_ore"]:
		sim.add_material(id,3)
		check(sim.contraption_deposit(SORT_KEY,id,3).moved==3,"deliberate ordinary hand feed: "+id)
	sorter.refresh_from_sim()

func place(kind: String, cell: Vector3i) -> ContraptionSite:
	var recipe: Dictionary = sim.recipe("assemble_"+kind)
	var before := sim.inventory().duplicate(true)
	sim.add_materials(recipe.inputs)
	check(sim.craft("assemble_"+kind).crafted,"exact current recipe: "+kind)
	for id: String in recipe.inputs: check(sim.material_count(id)==before.get(id,0),"recipe pays exactly: "+id)
	var build := player.placement
	build.set_build_mode_enabled(true)
	build._select_kit(StringName(kind+"_kit"))
	var element := {"kind":"volume","axis":0,"cell":cell}
	build.preview_element = element
	build.preview_visible = true
	var at := Vector3(cell)*.5+Vector3(.5,0,.5)
	var wall := body(at+Vector3(0,.6,0),Vector3(.2,1.2,.7))
	for i in 2: await get_tree().physics_frame
	check(not build.element_accepts(element),"whole native body detects obstructing wall: "+kind)
	check(not build.try_place_block() and sim.material_count(kind+"_kit")==1,"failed placement retains paid kit: "+kind)
	wall.free()
	for i in 2: await get_tree().physics_frame
	check(build.element_accepts(element),"whole body fits after obstruction removed: "+kind)
	check(build.try_place_block(),"normal successful kit transaction: "+kind)
	var site := ContraptionSite.find_site(get_tree(),"fixture_%d_%d_%d" % [cell.x,cell.y,cell.z])
	check(site!=null and sim.material_count(kind+"_kit")==0,"exactly one usable paid object: "+kind)
	if site!=null:
		site.set_physics_process(false)
		site.interact(player)
		check(player.work_panel.is_open(),"placed object opens native work controls: "+kind)
		player.work_panel.close_panel()
		check_fit(site._visual,ContraptionSite.bounds_for(kind))
		check(site.global_position.y==0.0 and site._visual.position==Vector3.ZERO,"native ground origin retained: "+kind)
	build.set_build_mode_enabled(false)
	return site

func check_fit(root: Node3D, size: Vector3) -> void:
	var inverse := root.global_transform.affine_inverse()
	for mesh in root.find_children("*","MeshInstance3D",true,false):
		var mi := mesh as MeshInstance3D
		var aabb := mi.mesh.get_aabb()
		for corner in 8:
			var p := inverse*mi.global_transform*aabb.get_endpoint(corner)
			check(absf(p.x)<=size.x*.5+.001 and absf(p.z)<=size.z*.5+.001 and p.y>=-.001 and p.y<=size.y+.001,"rendered part within unchanged whole body: "+mi.name)

func rebind() -> void:
	sorter = ContraptionSite.find_site(get_tree(),SORT_KEY)
	bellows = ContraptionSite.find_site(get_tree(),BELLOWS_KEY)
	for site in [sorter,bellows]:
		if site!=null: site.set_physics_process(false)
	sources.clear()
	for kind: String in ["pullstone","ventlung"]:
		var node := get_node_or_null(kind+"_native") as ResourceNode
		if node!=null: sources[kind]=node

func restore_check(path: String) -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(not expected.is_empty(),"separate-process checkpoint exists")
	check(manager.read(path,player),"normal fresh-process restore: "+manager.last_error)
	for i in 3: await get_tree().physics_frame
	rebind()
	check(sim.export_json()==expected.sim,"fresh process exact paid inventory/progression")
	check(sim.contraption_save()==expected.contraptions,"fresh process exact trays/pressure/identity")
	check(get_tree().get_nodes_in_group("contraptions").size()==2,"one scene per saved machine")
	for site in [sorter,bellows]:
		check(site!=null,"native fixture restored")
		if site!=null:
			check_fit(site._visual,ContraptionSite.bounds_for(site.kind))
			check(site._visual.event_left==0.0,"restore never replays a work pulse")
	if path==SAVE:
		for kind: String in ["pullstone","ventlung"]:
			check(sources.has(kind) and sources[kind].drive_progress==2 and sources[kind].remaining_units==3,"partial source restored: "+kind)
	else:
		check(sources.is_empty(),"depleted nodes remain absent in fresh process")
	check(manager.read(path,player),"repeat load remains replacement")
	check(sim.export_json()==expected.sim and sim.contraption_save()==expected.contraptions,"repeat load conserves exact ownership")

func refunds() -> void:
	for key_id: String in [SORT_KEY,BELLOWS_KEY]:
		var state := sim.contraption_state(key_id)
		var expected := sim.inventory().duplicate(true)
		var recipe := sim.recipe("assemble_"+String(state.kind))
		for id: String in recipe.inputs:
			var count := int(recipe.inputs[id]) if id in ["pullstone","ventlung"] else floori(float(recipe.inputs[id])*sim.removal_refund_fraction())
			expected[id]=int(expected.get(id,0))+count
		for port: String in ["input","ferrous","remainder"]:
			for id: String in state.get(port,{}): expected[id]=int(expected.get(id,0))+int(state[port][id])
		check(sim.contraption_remove(key_id).ok,"dismantle actual device")
		check(sim.inventory()==expected,"all contents + intact core + exact common refund; stored pressure vents")
		check(not sim.contraption_remove(key_id).ok and sim.inventory()==expected,"second removal cannot repay")

func setup_view() -> void:
	var look: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://f3/settings.json")).review_lighting
	get_window().size = Vector2i(1600,900)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	renderer = RenderingServer.get_current_rendering_method()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("303a36")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("dbded5")
	env.ambient_light_energy = float(look.ambient)
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.glow_enabled = false
	var world := WorldEnvironment.new()
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-26,0)
	sun.light_energy = float(look.key)
	sun.shadow_enabled = not OS.get_cmdline_user_args().has("--benchmark-no-shadows")
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-30,150,0)
	fill.light_energy = float(look.fill)
	add_child(fill)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.0
	add_child(camera)
	camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(25,20)
	caption.add_theme_font_size_override("font_size",23)
	layer.add_child(caption)
	view("overview")

func view(kind: String) -> void:
	var at := Vector3(.5,.65,-.6)
	var extent := 7.1
	if kind=="magnetic_sorter": at=Vector3(-1.5,.6,.5); extent=2.1
	if kind=="ventlung_bellows": at=Vector3(2.5,.5,.5); extent=1.9
	if kind=="pullstone": at=Vector3(-1.5,.6,-2.1); extent=2.1
	if kind=="ventlung": at=Vector3(2.5,.6,-2.1); extent=1.65
	if kind=="devices": at=Vector3(.5,.55,.5); extent=5.3
	camera.position=at+Vector3(2,1.65,3.8)
	camera.look_at(at)
	camera.size=extent

func capture(name_id: String, title: String) -> void:
	caption.text="ART-07F3 / "+renderer+" / "+title
	if not recording: return
	for i in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://f3/evidence")
	check(get_viewport().get_texture().get_image().save_png("res://f3/evidence/"+renderer+"-"+name_id+".png")==OK,"actual renderer capture: "+name_id)

func motion() -> void:
	load_mixed()
	DirAccess.make_dir_recursive_absolute("res://f3/evidence/"+renderer+"-motion")
	view("ventlung_bellows")
	for i in 120:
		if i in [12,24,36]: check(bellows.perform("prime").ok,"recorded actual prime")
		if i==58: check(bellows.release_at_resource(player).ok,"recorded actual discharge")
		if i==70: view("magnetic_sorter")
		if i==85: check(sorter.perform("sort").ok,"recorded actual first sort")
		if i==106: check(sorter.perform("sort").ok,"recorded actual second sort")
		caption.text="ART-07F3 / "+renderer+" / "+("THREE PAID HAND PRIMES → ONE DISCHARGE" if i<70 else "TWO HAND SORTS / distinct native output trays")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://f3/evidence/"+renderer+"-motion/%04d.png" % i)
	check(sim.contraption_state(BELLOWS_KEY).energy==2,"three recorded primes minus one paid discharge leaves two")
	check(units(sim.contraption_state(SORT_KEY).ferrous)==16 and units(sim.contraption_state(SORT_KEY).remainder)==12,"recorded sorting exact")
	# Pausing stops event travel; there is no shader TIME clock.
	check(bellows.perform("prime").ok,"prime before pause proof")
	var phase: float = bellows._visual.event_phase
	get_tree().paused=true
	for i in 4: await RenderingServer.frame_post_draw
	check(bellows._visual.event_phase==phase,"paused cosmetic motion remains stopped")
	get_tree().paused=false
	finish("motion")

func benchmark() -> void:
	view("overview")
	caption.text="ART-07F3 / separate fixed-view benchmark / no capture"
	for i in 132: await get_tree().process_frame
	var samples: Array[float]=[]
	var last := Time.get_ticks_usec()
	for i in 600:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		samples.append(float(now-last)/1000.0)
		last=now
	samples.sort()
	var result := {"renderer":renderer,"device":RenderingServer.get_video_adapter_name(),"frames":600,"warmup_frames":132,"width":1600,"height":900,"msaa":4,"vsync":false,"p50_ms":samples[300],"p95_ms":samples[570],"worst_ms":samples.back(),"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"note":"Complete devices and source hosts in isolated native stage; test stock, no generation/capture/compiler overlap."}
	result["directional_shadows"] = not OS.get_cmdline_user_args().has("--benchmark-no-shadows")
	write_report(renderer+("-benchmark" if result.directional_shadows else "-benchmark-no-shadows"),result)
	print("F3_BENCHMARK ",JSON.stringify(result))
	get_tree().quit(0)

func write_report(name_id: String, value: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute("res://f3/evidence")
	var file := FileAccess.open("res://f3/evidence/"+name_id+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"  "))
	file.close()

func finish(mode: String) -> void:
	write_report(renderer+"-"+mode,{"checks":checks,"failures":failures,"mode":mode,"native_inventory":sim.inventory(),"machine_state":sim.contraption_save(),"user_dir":OS.get_user_data_dir()})
	print("F3_",mode.to_upper()," ",checks," checks, ",failures," failures")
	get_tree().quit(0 if failures==0 else 1)

func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.get_cmdline_user_args().has("--interactive"): return
	var key_event := event as InputEventKey
	if key_event==null or not key_event.pressed or key_event.echo: return
	match key_event.keycode:
		KEY_ESCAPE: get_tree().quit()
		KEY_0: view("overview")
		KEY_1: view("pullstone")
		KEY_2: view("ventlung")
		KEY_3: view("magnetic_sorter")
		KEY_4: view("ventlung_bellows")
		KEY_L: load_mixed()
		KEY_S: caption.text=String(sorter.perform("sort").message)
		KEY_B: caption.text=String(bellows.perform("prime").message)
		KEY_R: caption.text=String(bellows.release_at_resource(player).message)
		KEY_W:
			for node in sources.values():
				if is_instance_valid(node) and node.remaining_units>0: player._apply_work(node,node.work(sim))
		KEY_F5: caption.text="Saved isolated inspection" if manager.write(SAVE,player) else manager.last_error
		KEY_F9:
			if manager.read(SAVE,player): rebind(); caption.text="Restored isolated native ownership"
			else: caption.text=manager.last_error
