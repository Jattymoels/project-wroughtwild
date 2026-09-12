extends Node3D
## Isolated F1 finite source -> collected core -> paid fixture -> native request.
var checks := 0
var failures := 0
var sim: WroughtwildSim
var player: WroughtwildPlayer
var lamp: ContraptionSite
var lever: ContraptionSite
var camera: Camera3D
var caption: Label
var renderer := "headless"
var recording := false
var sources: Dictionary = {}
var manager
const SAVE := "user://f1-partial.json"
const DEPLETED := "user://f1-depleted.json"
const LAMP_KEY := "fixture_-4_0_0"
const LEVER_KEY := "fixture_4_0_0"

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	check(sim.last_error().is_empty(),"recorded current native tuning loads")
	check(sim.contraption_bind_world("legacy_v1",0),"isolated authored context")
	check(sim.contraption_load(""),"fresh machine ledger")
	sim.add_station("workbench")
	body(Vector3(0,-.5,0),Vector3(30,1,24))
	player=preload("res://scenes/player.tscn").instantiate()
	player.position=Vector3(0,.96,5)
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
	for kind: String in ["lanternheart","stormglass"]:
		var at := Vector3(-1.5 if kind=="lanternheart" else 2.5,0,-2.1)
		var shell := (load("res://f1/assets/"+kind+"_shell.glb") as PackedScene).instantiate() as Node3D
		shell.name=kind+"_aftermath"
		shell.set_meta("inspection_shell_no_stock",true)
		add_child(shell)
		shell.position=at
		sources[kind]=resource(kind,at,kind+"_native")
	manager=load("res://scripts/save_manager.gd").new()
	var args := OS.get_cmdline_user_args()
	if args.has("--restart") or args.has("--restart-depleted"):
		await restore_check(DEPLETED if args.has("--restart-depleted") else SAVE)
		finish("restart-depleted" if args.has("--restart-depleted") else "restart")
		return
	recording=args.has("--capture") and DisplayServer.get_name()!="headless"
	for kind: String in sources:
		view(kind)
		await capture(kind+"-intact","INTACT SOURCE / six finite inspection units")
		var node := sources[kind] as ResourceNode
		for i in 4: player._apply_work(node,node.work(sim))
		check(node.remaining_units==3,"first work cycle releases three and retains three: "+kind)
		check(sim.material_count(kind)==0,"freed core belongs to physical pickup before collection: "+kind)
		for drop in get_tree().get_nodes_in_group("pickups"):
			if drop is Pickup and drop.family==kind:
				var at: Vector3=drop.global_position+Vector3(0,.22,0)
				camera.position=at+Vector3(2,1.65,3.8);camera.look_at(at);camera.size=1.6
				break
		await capture(kind+"-recovered","PHYSICAL RECOVERED CORE / native pickup owns the released quantity")
	await collect_cores(3)
	lamp=await place("lantern_lamp",Vector3i(-4,0,0))
	lever=await place("stormglass_lever",Vector3i(4,0,0))
	if lamp==null or lever==null: finish("placement-failed");return
	for kind: String in sources:
		check(sim.material_count(kind)==2,"fixture paid one recovered core: "+kind)
		for i in 2: player._apply_work(sources[kind],sources[kind].work(sim))
		check(sources[kind].drive_progress==2 and sources[kind].remaining_units==3,"partial second work cycle persists: "+kind)
	var before := sim.contraption_save()
	check(not lever.perform("pulse").ok,"unconnected request refuses")
	check(sim.contraption_save()==before and lever._visual.event_left==0.0,"unavailable request has no success pulse or native mutation")
	check(sim.contraption_link(LEVER_KEY,LAMP_KEY,lever.link_clear(lamp)).ok,"physically clear native lamp link")
	if args.has("--interactive"):
		caption.text="F1 / 0 overview · 1–4 views · T lamp · P request · W source work · C collect · F5/F9 isolated save"
		return
	if args.has("--benchmark") or args.has("--benchmark-no-shadows"):
		await benchmark();return
	if args.has("--motion"):
		await motion();return
	view("overview")
	await capture("overview","RECOVERED CORES / PAID TIMBER AND REED OR IRON FRAMES")
	view("lantern_lamp")
	await capture("lamp-on","LAMP ON / native light state")
	set_dark(true)
	await capture("lamp-on-dark","DARK REVIEW / native lamp on, no bloom")
	set_dark(false)
	check(lamp.perform("toggle").ok,"actual lamp control toggles off")
	check(not bool(sim.contraption_state(LAMP_KEY).lamp_on),"native lamp off")
	check(lamp._visual.get_node("Heart").visible,"same solid core remains visible when off")
	for mat in lamp._visual.materials: check(float(mat.get_shader_parameter("work"))==0,"off state extinguishes core emission")
	await capture("lamp-off","LAMP OFF / same recovered heart remains")
	set_dark(true)
	await capture("lamp-off-dark","DARK REVIEW / lamp off, solid core remains")
	set_dark(false)
	view("stormglass_lever")
	await capture("lever-idle","IDLE RESONATOR / no continuous power")
	check(lever.perform("pulse").ok,"actual request accepted by native lamp receiver")
	lamp.refresh_from_sim()
	check(sim.contraption_state(LEVER_KEY).pulses==1 and bool(sim.contraption_state(LAMP_KEY).lamp_on),"one request changes native receiver once")
	check(sim.contraption_state(LEVER_KEY).energy==0,"request grants no drive")
	await capture("lever-pulse","ONE ACTUAL REQUEST / receiver changed once")
	var phase: float=lever._visual.event_phase
	get_tree().paused=true
	for i in 3: await get_tree().process_frame
	check(lever._visual.event_phase==phase,"pause freezes engine pulse")
	get_tree().paused=false
	for i in 70: await get_tree().physics_frame
	check(lever._visual.event_left==0,"request event expires")
	for mat in lever._visual.materials:check(float(mat.get_shader_parameter("work"))==0,"settled tube is unlit")
	var wall := body(Vector3(.5,1,.5),Vector3(.15,2,.8))
	for i in 2:await get_tree().physics_frame
	before=sim.contraption_save()
	check(not lever.perform("pulse").ok and sim.contraption_save()==before,"physical obstruction refuses without native mutation")
	wall.free()
	check(manager.write(SAVE,player),"atomic paid fixtures and partial sources checkpoint")
	var saved: Dictionary=manager.capture(player)
	for i in 8:
		lamp.refresh_from_sim();lever.refresh_from_sim()
		for node in sources.values():StrangeResourceArt.update(node,.5)
	check(sim.export_json()==saved.sim and sim.contraption_save()==saved.contraptions,"visual refresh grants and spends nothing")
	check(manager.read(SAVE,player),"same-process normal restore: "+manager.last_error)
	await get_tree().physics_frame
	rebind()
	check(sim.export_json()==saved.sim and sim.contraption_save()==saved.contraptions,"exact ownership after ordinary restore")
	for kind: String in sources:
		view(kind)
		await capture(kind+"-worked","NATIVE PARTIAL WORK / same core lifted from its housing")
		var node := sources[kind] as ResourceNode
		var released := 0
		for i in 2:
			var result:=node.work(sim)
			released+=int(result.get("granted",0));player._apply_work(node,result)
		check(released==3 and node.remaining_units==0,"last finite source lot released: "+kind)
		check(node.work(sim).has("refusal"),"depleted source refuses duplicate work: "+kind)
	await collect_cores(3)
	for i in 24:await get_tree().physics_frame
	check(manager.write(DEPLETED,player),"depletion and collected cores checkpoint")
	view("overview")
	await capture("depleted","EMPTY HUSK / EMPTY LIGHTNING SCAR / finite stock exhausted")
	await refunds()
	if recording:
		check(manager.read(SAVE,player),"restore reviewable partial state")
		await get_tree().physics_frame
		rebind()
		for level: String in ["near","middle","far"]:
			for node in sources.values():node.get_node("StrangeCore").set_lod(level)
			view("overview");await capture("lod-"+level,"SOURCE DETAIL / "+level.to_upper())
	finish("capture" if recording else "checks")

func collect_cores(expected: int) -> void:
	var totals: Dictionary={"lanternheart":0,"stormglass":0}
	for drop in get_tree().get_nodes_in_group("pickups"):
		if drop is Pickup and drop.family in totals and not drop._claimed:
			check(drop.has_node("RecoveredCore"),"physical drop reuses intact core model: "+drop.family)
			check(drop.get_node("RecoveredCore").get_meta("source_geometry")==drop.family+"_near.glb","same geometry through source and recovery")
			totals[drop.family]+=drop.amount
			var before:=sim.material_count(drop.family)
			var amount: int=drop.amount
			drop._absorb(player)
			check(sim.material_count(drop.family)==before+amount,"native pickup transfers exact finite amount")
	for kind: String in totals:check(totals[kind]==expected,"exact released physical amount: "+kind)
	await get_tree().physics_frame

func motion() -> void:
	DirAccess.make_dir_recursive_absolute("res://f1/evidence/"+renderer+"-motion")
	view("devices")
	for i in 120:
		if i in [15,65]:check(lever.perform("pulse").ok,"recorded actual request")
		lamp.refresh_from_sim()
		caption.text="ART-07F1 / "+renderer+" / native request toggles the same lamp / no drive created"
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://f1/evidence/"+renderer+"-motion/%04d.png" % i)
	check(sim.contraption_state(LEVER_KEY).pulses==2 and bool(sim.contraption_state(LAMP_KEY).lamp_on),"two filmed native requests restore lamp state")
	finish("motion")

func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.get_cmdline_user_args().has("--interactive"):return
	var k := event as InputEventKey
	if k==null or not k.pressed or k.echo:return
	match k.keycode:
		KEY_ESCAPE:get_tree().quit()
		KEY_0:view("overview")
		KEY_1:view("lanternheart")
		KEY_2:view("stormglass")
		KEY_3:view("lantern_lamp")
		KEY_4:view("stormglass_lever")
		KEY_T:caption.text=String(lamp.perform("toggle").message)
		KEY_P:caption.text=String(lever.perform("pulse").message)
		KEY_W:
			for node in sources.values():
				if is_instance_valid(node):player._apply_work(node,node.work(sim))
		KEY_C:
			for drop in get_tree().get_nodes_in_group("pickups"):
				if drop is Pickup:drop._absorb(player)
		KEY_F5:caption.text="Saved isolated F1 checkpoint" if manager.write(SAVE,player) else manager.last_error
		KEY_F9:
			if manager.read(SAVE,player):rebind();caption.text="Restored isolated F1 checkpoint"
			else:caption.text=manager.last_error


func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL F1: ",label)


func _ready() -> void:
	if not OS.get_cmdline_user_args().has("--interactive"):
		get_tree().create_timer(120.0,true,false,true).timeout.connect(func(): printerr("F1 review exceeded its bounded duration"); get_tree().quit(2))
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
	node.resource_id = "f1-inspection-"+name_id
	node.visual = StringName(kind)
	node.material_family = StringName(kind)
	node.remaining_units = 8 if kind=="seam" else 6
	node.units_per_harvest = 2 if kind=="seam" else 3
	node.drive_presses = 4
	node.position = at
	add_child(node)
	return node


func place(kind: String, cell: Vector3i) -> ContraptionSite:
	var recipe: Dictionary = sim.recipe("assemble_"+kind)
	var before := sim.inventory().duplicate(true)
	for id: String in recipe.inputs:
		if id not in ["lanternheart","stormglass"]:sim.add_material(id,int(recipe.inputs[id]))
	check(sim.craft("assemble_"+kind).crafted,"exact current recipe: "+kind)
	for id: String in recipe.inputs: check(sim.material_count(id)==int(before.get(id,0))-(int(recipe.inputs[id]) if id in ["lanternheart","stormglass"] else 0),"recipe pays exactly: "+id)
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
	lamp = ContraptionSite.find_site(get_tree(),LAMP_KEY)
	lever = ContraptionSite.find_site(get_tree(),LEVER_KEY)
	for site in [lamp,lever]:
		if site!=null: site.set_physics_process(false)
	sources.clear()
	for kind: String in ["lanternheart","stormglass"]:
		var node := get_node_or_null(kind+"_native") as ResourceNode
		if node!=null: sources[kind]=node


func restore_check(path: String) -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(not expected.is_empty(),"separate-process checkpoint exists")
	check(manager.read(path,player),"normal fresh-process restore: "+manager.last_error)
	for i in 3: await get_tree().physics_frame
	rebind()
	check(sim.export_json()==expected.sim,"fresh process exact paid inventory/progression")
	check(sim.contraption_save()==expected.contraptions,"fresh process exact lamp/request/identity")
	check(get_tree().get_nodes_in_group("contraptions").size()==2,"one scene per saved machine")
	for site in [lamp,lever]:
		check(site!=null,"native fixture restored")
		if site!=null:
			check_fit(site._visual,ContraptionSite.bounds_for(site.kind))
			check(site._visual.event_left==0.0,"restore never replays a work pulse")
	if path==SAVE:
		for kind: String in ["lanternheart","stormglass"]:
			check(sources.has(kind) and sources[kind].drive_progress==2 and sources[kind].remaining_units==3,"partial source restored: "+kind)
	else:
		check(sources.is_empty(),"depleted nodes remain absent in fresh process")
	check(manager.read(path,player),"repeat load remains replacement")
	check(sim.export_json()==expected.sim and sim.contraption_save()==expected.contraptions,"repeat load conserves exact ownership")


func refunds() -> void:
	for key_id: String in [LAMP_KEY,LEVER_KEY]:
		var state := sim.contraption_state(key_id)
		var expected := sim.inventory().duplicate(true)
		var recipe := sim.recipe("assemble_"+String(state.kind))
		for id: String in recipe.inputs:
			var count := int(recipe.inputs[id]) if id in ["lanternheart","stormglass"] else floori(float(recipe.inputs[id])*sim.removal_refund_fraction())
			expected[id]=int(expected.get(id,0))+count
		for port: String in ["input","ferrous","remainder"]:
			for id: String in state.get(port,{}): expected[id]=int(expected.get(id,0))+int(state[port][id])
		check(sim.contraption_remove(key_id).ok,"dismantle actual device")
		check(sim.inventory()==expected,"all contents + intact core + exact common refund; signal and common-frame refund unchanged")
		check(not sim.contraption_remove(key_id).ok and sim.inventory()==expected,"second removal cannot repay")


func setup_view() -> void:
	var look: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://f1/settings.json")).review_lighting
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
	world.name="ReviewEnvironment"
	world.environment = env
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name="ReviewKey"
	sun.rotation_degrees = Vector3(-42,-26,0)
	sun.light_energy = float(look.key)
	sun.shadow_enabled = not OS.get_cmdline_user_args().has("--benchmark-no-shadows")
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.name="ReviewFill"
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

func set_dark(enabled: bool) -> void:
	var look: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://f1/settings.json")).review_lighting
	get_node("ReviewEnvironment").environment.ambient_light_energy = float(look.dark_ambient) if enabled else float(look.ambient)
	get_node("ReviewKey").visible=not enabled
	get_node("ReviewFill").visible=not enabled


func view(kind: String) -> void:
	var at := Vector3(.5,.65,-.6)
	var extent := 7.1
	if kind=="lantern_lamp": at=Vector3(-1.5,.6,.5); extent=1.45
	if kind=="stormglass_lever": at=Vector3(2.5,.5,.5); extent=1.4
	if kind=="lanternheart": at=Vector3(-1.5,.6,-2.1); extent=1.3
	if kind=="stormglass": at=Vector3(2.5,.6,-2.1); extent=2.1
	if kind=="devices": at=Vector3(.5,.55,.5); extent=5.3
	camera.position=at+Vector3(2,1.65,3.8)
	camera.look_at(at)
	camera.size=extent


func capture(name_id: String, title: String) -> void:
	caption.text="ART-07F1 / "+renderer+" / "+title
	if not recording: return
	for i in 5: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://f1/evidence")
	check(get_viewport().get_texture().get_image().save_png("res://f1/evidence/"+renderer+"-"+name_id+".png")==OK,"actual renderer capture: "+name_id)


func benchmark() -> void:
	view("overview")
	caption.text="ART-07F1 / separate fixed-view benchmark / no capture"
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
	print("F1_BENCHMARK ",JSON.stringify(result))
	get_tree().quit(0)


func write_report(name_id: String, value: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute("res://f1/evidence")
	var file := FileAccess.open("res://f1/evidence/"+name_id+".json",FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"  "))
	file.close()


func finish(mode: String) -> void:
	write_report(renderer+"-"+mode,{"checks":checks,"failures":failures,"mode":mode,"native_inventory":sim.inventory(),"machine_state":sim.contraption_save(),"user_dir":OS.get_user_data_dir()})
	print("F1_",mode.to_upper()," ",checks," checks, ",failures," failures")
	get_tree().quit(0 if failures==0 else 1)
