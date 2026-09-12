extends "res://tests/home_workshop_review.gd"
## Actual paid native placement/storage/removal with explicitly granted stock.
## Existing native burn method is time-stepped for short repeatable evidence.
const E3_SAVE := "user://e3-storage.json"
const E3_EXPECTED := "user://e3-expected.json"
const CHESTS := ["wood","pine","bog_oak","ash_wood","resinheart","iron","bronze","steel"]
const FUELS := ["wood","pine","bog_oak","ash_wood","charcoal"]
var camera: Camera3D
var caption: Label
var backend := ""
var output := ""
var chest_nodes: Array[PlacedBlock] = []
var fires: Array[PlacedBlock] = []
var manager := SaveManager.new()
var play_index := 0
var playing := false
var e3_report := {"scope":"Supplied stock; native payment, panels, burn method and saves. No first-hour pacing claim.","fuel":[],"benchmarks":[]}

func _run() -> void:
	get_window().size = Vector2i(1440,900)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	backend = RenderingServer.get_current_rendering_method()
	output = ProjectSettings.globalize_path("res://../evidence/"+backend)
	DirAccess.make_dir_recursive_absolute(output)
	player.hide()
	player.hud.hide()
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
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	environment.glow_enabled = false
	var args := OS.get_cmdline_user_args()
	if args.has("--restore"):
		await restart()
		finish_e3("restart")
		return
	check(sim.contraption_bind_world("legacy_v1",0),"same explicit isolated native world identity")
	sim.drop_inventory()
	for family in sim.build_material_ids():
		check(sim.shape_allows_family("chest",family)==CHESTS.has(String(family)),"unchanged chest trait gate "+String(family))
		check(sim.shape_allows_family("campfire",family)==FUELS.has(String(family)),"unchanged fuel trait gate "+String(family))
	await settle()
	for i in CHESTS.size():
		var f: String = CHESTS[i]
		var source: String = sim.build_material(f).source
		sim.add_material(source,12)
		var c := _place(&"chest",StringName(f),Vector3i((i%4)*2,0,(i/4)*3)) as PlacedBlock
		if not check(c != null,"usable paid "+f+" chest"): finish_e3("failure");return
		chest_nodes.append(c)
		var before := sim.export_json()
		var count := sim.structure_piece_count()
		check(not player.placement.try_place_block(),"duplicate placement refuses "+f)
		check(sim.export_json()==before and sim.structure_piece_count()==count,"failed "+f+" placement retains all materials and exactly one object")
		await settle()
		await chest_check(c)
	await ghost_check()
	player.placement.set_build_mode_enabled(false)
	view(Vector3(3.5,.3,2),11)
	await snap("01-all-chests","Eight legal storage families / closed native-body fit")
	for d in [6.0,12.0,24.0]:
		view(Vector3(3.5,.3,2),d)
		await snap("chests-distance-"+str(int(d)),"Same source parts / inspection distance %d m"%d)
	view(chest_nodes[0].global_position+Vector3(0,-.1,0))
	sun.light_energy = .10
	environment.ambient_light_energy = .18
	await snap("chest-shade","Quiet ordinary material / shaded review")
	sun.light_energy = 0
	environment.ambient_light_energy = .045
	await snap("chest-dusk","Dusk / ordinary chest has no emission")
	sun.light_energy = 1.15
	environment.ambient_light_energy = .45
	await save_chests()
	if args.has("--play"):
		playing = true
		play_view()
		if args.has("--play-smoke"):await play_smoke()
		return
	await fire_checks()
	await spill_check()
	if args.has("--benchmark"):
		await benchmark()
	finish_e3("benchmark" if args.has("--benchmark") else "checks")

func settle(count := 3) -> void:
	for i in count: await get_tree().process_frame

func view(at: Vector3, distance := 2.7) -> void:
	camera.position = at+Vector3(.60,.42,1).normalized()*distance
	camera.look_at(at)

func fire_view(at: Vector3, distance := 2.4) -> void:
	# A standing player's downward inspection angle exposes the real V recess.
	camera.position = at+Vector3(.45,1.2,.65).normalized()*distance
	camera.look_at(at)

func snap(name: String, text: String) -> void:
	caption.text = "ART-07E3 / "+backend+"\n"+text
	if not OS.get_cmdline_user_args().has("--capture"):return
	await settle(2)
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"actual capture "+name)

func visual_bounds(node: Node3D, reference: Node3D) -> AABB:
	var bounds := AABB()
	var first := true
	var queue: Array[Node] = [node]
	while not queue.is_empty():
		var child: Node = queue.pop_back()
		if child is MeshInstance3D and child.visible:
			var box: AABB = reference.global_transform.affine_inverse()*child.global_transform*child.mesh.get_aabb()
			bounds = box if first else bounds.merge(box)
			first = false
		queue.append_array(child.get_children())
	return bounds

func ghost_check() -> void:
	var build := player.placement
	var prior := build.camera
	build.camera = camera
	player.position = Vector3(-3.5,1,3)
	camera.position = Vector3(-3.5,1.6,3.2)
	camera.look_at(Vector3(-3.5,0,.5))
	var baseline := sim.export_json()
	for shape in [&"chest",&"campfire"]:
		build.set_build_mode_enabled(true)
		player.build_palette.group = "All"
		player.build_palette.open_panel()
		player.build_palette.select_entry(shape,"shape")
		player.build_palette.select_material(&"wood")
		player.build_palette.close_panel()
		for i in 2:await get_tree().physics_frame
		build._update_preview()
		check(build.preview_visible and build.preview_valid,"actual camera ray produces valid "+String(shape)+" ghost: "+build.preview_reason)
		if build.preview_visible:
			var pose: Dictionary = build.piece_pose(shape,build.preview_element,build.preview_rotation_step)
			check(build._preview_mesh.global_position.is_equal_approx(pose.centre),"actual ghost uses unchanged native pose")
			var form := "chest" if shape==&"chest" else "fire"
			check(build._preview_mesh.mesh==E3HomeArt.closed(form,&"wood"),"actual ghost uses identical source geometry")
		await snap("ghost-"+String(shape),"Actual ray-driven valid native ghost / no payment")
	check(sim.export_json()==baseline,"ghost selection and view spend or create nothing")
	build.set_build_mode_enabled(false)
	build.camera = prior
	selected = ""

func chest_check(c: PlacedBlock) -> void:
	var state: Node3D = c.get_node("E3View")
	var closed := visual_bounds(state,c)
	var native: AABB = AABB(Vector3(-.5,-.5,-.4),Vector3(1,.7,.8))
	check(native.grow(.0001).encloses(closed),"closed geometry within unchanged 1 x .7 x .8 body: "+String(c.material_family))
	check(c._collision_shapes.size()==1 and c._collision_shapes[0].shape.size.is_equal_approx(native.size),"one unchanged solid chest body")
	check(c._collision_shapes[0].position.is_equal_approx(native.get_center()),"native floor offset unchanged")
	check(c._mesh.mesh.get_aabb().is_equal_approx(closed),"closed preview and actual model share complete geometry")
	view(c.global_position+Vector3(0,-.13,0))
	await snap("chest-"+String(c.material_family)+"-closed",String(c.material_family)+" / closed / six native material units")
	player.placement.set_build_mode_enabled(false)
	await get_tree().physics_frame
	check(_aim(c,c.global_position+Vector3(0,.8,2),c.global_position+Vector3(0,-.15,.4)),"actual ray finds chest body")
	player.interact()
	check(player.chest_panel.is_open() and player.chest_panel.chest==c,"actual E opens the right native storage")
	var baseline := sim.export_json()
	var body_transform := c._collision_shapes[0].transform
	for i in 40: state._process(1.0/60)
	check(is_equal_approx(state.angle,-deg_to_rad(float(E3HomeArt.look().lid_angle_degrees))),"supported lid follows actual panel opening")
	check(sim.export_json()==baseline,"lid movement has no inventory or progression writes")
	check(c._collision_shapes[0].transform==body_transform,"lid keeps full native body")
	sim.add_materials({"wood":17,"stone":23})
	check(player.chest_panel.store(&"wood",17)==17 and player.chest_panel.store(&"stone",23)==23,"panel stores exact supplied stacks")
	check(player.chest_panel.take(&"stone",3)==3,"panel withdrawal uses native ownership")
	check(sim.store_contents(c.store_key())=={"wood":17,"stone":20},"chest has exactly 37 units")
	if c.material_family==&"wood":
		await snap("02-storage-panel","Actual storage panel / 37 of 960 shared units")
	player.chest_panel.hide() # Hide canvas for model inspection; its real open state remains true.
	view(c.global_position+Vector3(0,.12,0),3.3)
	await snap("chest-"+String(c.material_family)+"-open",String(c.material_family)+" / actual open panel, canvas hidden for model view")
	if c.material_family==&"wood" and OS.get_cmdline_user_args().has("--capture"):
		state.set_process(false) # Fixed cosmetic sampling; normal play keeps delta-driven processing.
		for i in 40:
			if i==0: player.chest_panel.close_panel()
			if i==20: player.open_chest(c);player.chest_panel.hide()
			state._process(1.0/30)
			await snap("motion-lid-%03d"%i,"Native panel close / open; cosmetic hinge travel sampled at 30 Hz")
		state.set_process(true)
	player.chest_panel.close_panel()
	player.chest_panel.show()
	for i in 40:state._process(1.0/60)
	check(is_zero_approx(state.angle),"lid closes after actual panel closes")
	get_tree().paused = true
	var angle: float = state.angle
	state._process(1)
	check(state.angle==angle,"pause freezes cosmetic lid")
	get_tree().paused = false
	check(sim.store_room(c.store_key())==923,"unchanged shared capacity of 960")

func save_chests() -> void:
	var before := sim.export_json()
	check(manager.write(E3_SAVE,player),"write exact chest checkpoint: "+manager.last_error)
	var expected := {"native":JSON.parse_string(before),"blocks":manager.capture(player).blocks}
	var file := FileAccess.open(E3_EXPECTED,FileAccess.WRITE)
	file.store_string(JSON.stringify(expected));file.close()
	check(manager.read(E3_SAVE,player),"same-process reload: "+manager.last_error)
	check(JSON.parse_string(sim.export_json())==expected.native,"native contents exact on reload")
	chest_nodes.clear()
	for child in get_children():
		if child is PlacedBlock and child.is_chest():chest_nodes.append(child)
	check(chest_nodes.size()==8,"reload creates exactly eight usable chests")
	for c in chest_nodes:
		check(c.get_node("E3View").angle==0 and sim.store_units(c.store_key())==37,"reload closes cosmetic lid and keeps all contents")

func fire_checks() -> void:
	for i in FUELS.size():
		var f: String = FUELS[i]
		sim.add_material(f,6)
		var c := _place(&"campfire",StringName(f),Vector3i(i*2,0,7)) as PlacedBlock
		if not check(c != null,"one paid fire "+f):return
		c.set_process(false) # Explicit stepped native clock, never a new game timer.
		var cfg: Dictionary = sim.fire_setting().fuels[f]
		check(is_equal_approx(c.burn_left,float(cfg.burn_seconds)) and c.fire_heat==int(cfg.heat),"native fuel duration and heat "+f)
		var state: Node3D = c.get_node("E3View")
		var native := AABB(Vector3(-.4,-.25,-.4),Vector3(.8,.25,.8))
		check(native.grow(.0001).encloses(visual_bounds(state,c)),"fuel and residue fit original low body "+f)
		check(c._collision_shapes.size()==1 and c._collision_shapes[0].shape.size.is_equal_approx(native.size),"fire retains one low step-over body")
		check(c._collision_shapes[0].position.is_equal_approx(native.get_center()),"native fire body offset unchanged")
		check(c._mesh.mesh.get_aabb().is_equal_approx(visual_bounds(state.fuel,c)),"fire preview and placed fuel share complete geometry")
		var balance := sim.export_json()
		check(not player.placement.try_place_block() and sim.export_json()==balance,"failed fire placement retains fuel")
		fires.append(c)
	player.placement.set_build_mode_enabled(false)
	player.position = Vector3(-3,1,-3)
	for i in fires.size():
		var c := fires[i]
		fire_view(c.global_position+Vector3(0,-.16,0))
		await snap("fire-"+String(c.material_family)+"-new","Paid fuel / native heat %d / no stone ingredient"%c.fire_heat)
	var saved := manager.capture(player)
	check(saved.blocks.size()==8,"existing save policy omits all five live fires")
	check(manager.write("user://e3-live-fires.json",player),"save while all five paid fires are present")
	var fire_expected := FileAccess.open("user://e3-live-fires-expected.json",FileAccess.WRITE)
	fire_expected.store_string(JSON.stringify({"native":JSON.parse_string(sim.export_json()),"blocks":saved.blocks}));fire_expected.close()
	var original_inventory := sim.inventory().duplicate(true)
	for step in 61:
		for c in fires:
			if not is_instance_valid(c) or not c.is_inside_tree():continue
			var left := c.burn_left
			var body := c._collision_shapes[0].shape
			if step>0:c._process(1.0)
			if c.is_inside_tree():
				var state: Node3D = c.get_node("E3View")
				state._process(0)
				check(is_equal_approx(c.burn_left,left-(1.0 if step>0 else 0.0)),"only native clock consumes fuel")
				check(c._collision_shapes[0].shape==body,"charring leaves physical body unchanged")
				if step==12:
					get_tree().paused=true
					var phase: float = state.ember.get_shader_parameter("native_seconds")
					state._process(5)
					check(state.ember.get_shader_parameter("native_seconds")==phase,"paused emission has no wall-clock travel")
					get_tree().paused=false
					if c.material_family==&"wood":
						state.ember.set_shader_parameter("gain",0.0)
						fire_view(c.global_position+Vector3(0,-.16,0))
						await snap("fire-emission-off","Emission disabled for inspection / actual recessed fuel geometry")
						sun.light_energy = 0
						environment.ambient_light_energy = .045
						await snap("fire-dusk-emission-off","Dusk / ember emission off / unchanged native fire light remains")
						state.ember.set_shader_parameter("gain",E3HomeArt.look().ember_gain)
						await snap("fire-dusk","Dusk / finite native fuel phase / unchanged single fire light")
						sun.light_energy = 1.15
						environment.ambient_light_energy = .45
				if step==36:
					fire_view(c.global_position+Vector3(0,-.16,0))
					await snap("fire-"+String(c.material_family)+"-late","Native age 36 s / charred fuel and finite heat")
		if OS.get_cmdline_user_args().has("--capture") and step<45:
			fire_view(fires[0].global_position+Vector3(0,-.16,0))
			await snap("motion-fire-%03d"%step,"Actual native burn method / 1 second per frame / ash before removal")
		if step in [44,59]:
			var c := fires[0] if step==44 else fires[4]
			if is_instance_valid(c) and c.is_inside_tree():
				check(c.get_node("E3View").ash.visible,"ash visible before native expiry")
				fire_view(c.global_position+Vector3(0,-.16,0))
				await snap("fire-last-"+str(step),"Last paid second / no persistent ash object or refund")
		if step in [45,60]:
			var remaining := 0
			for child in get_children():
				if child is PlacedBlock and child.is_fire():remaining+=1
			check(remaining==(1 if step==45 else 0),"native expiry removes correct fuels at second "+str(step))
	check(sim.inventory()==original_inventory,"burning and expiry refund nothing")
	check(sim.structure_piece_count()==8,"all fires leave registry; eight chests remain")
	view(Vector3(1.5,.35,7.5),5.1)
	await snap("fire-spent","Spent / native fire removed / no refund, residue ownership or saved fuel")
	e3_report.fuel = [{"families":FUELS,"timber_seconds":45,"charcoal_seconds":60,"heat":[1,2],"save":"omitted as before","clock":"unchanged native method, one-second test steps"}]

func spill_check() -> void:
	var c := chest_nodes[0]
	var key := c.store_key()
	var counts: Dictionary = sim.store_contents(key).duplicate(true)
	check(player.placement.remove_piece(c),"removal uses actual chest spill path")
	check(sim.store_contents(key).is_empty(),"removed chest has no native contents")
	check(not player.placement.remove_piece(c),"duplicate removal cannot duplicate contents")
	var drops := {}
	for child in get_children():
		if child is Pickup:
			child.set_physics_process(false)
			drops[String(child.family)] = int(drops.get(String(child.family),0))+child.amount
	check(drops==counts,"physical spilled quantities equal every stored unit")
	check(manager.write("user://e3-spill.json",player),"save real loose spill")
	var spill_expected := FileAccess.open("user://e3-spill-expected.json",FileAccess.WRITE)
	spill_expected.store_string(JSON.stringify({"native":JSON.parse_string(sim.export_json()),"drops":counts}));spill_expected.close()
	check(manager.read("user://e3-spill.json",player),"restore real loose spill without chest")

func restart() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(E3_EXPECTED))
	for i in 2:
		check(manager.read(E3_SAVE,player),"fresh-process exact chest read "+str(i)+": "+manager.last_error)
		check(JSON.parse_string(sim.export_json())==expected.native,"fresh-process native inventory/storage exact")
		var actual_blocks: Array = JSON.parse_string(JSON.stringify(manager.capture(player).blocks))
		if actual_blocks!=expected.blocks:
			var diagnostic := FileAccess.open(output+"/restart-block-diff.json",FileAccess.WRITE)
			diagnostic.store_string(JSON.stringify({"actual":actual_blocks,"expected":expected.blocks},"\t"));diagnostic.close()
		check(actual_blocks==expected.blocks,"fresh-process exact eight saved addresses and materials")
		var count := 0
		for child in get_children():
			if child is PlacedBlock:
				count+=1
				check(child.is_chest() and child.get_node("E3View").angle==0,"loaded object has closed usable chest appearance")
		check(count==8,"no duplicated chest or resurrected fuel")
	view(Vector3(3.5,.3,2),11)
	await snap("restart","Fresh process / exact storage and material identities")
	var fire_expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://e3-live-fires-expected.json"))
	check(manager.read("user://e3-live-fires.json",player),"fresh-process read of checkpoint made with five live fires")
	check(JSON.parse_string(sim.export_json())==fire_expected.native,"fuel payment and all storage remain exact after reload")
	check(JSON.parse_string(JSON.stringify(manager.capture(player).blocks))==fire_expected.blocks,"original policy restores eight chests and no fire")
	for i in 2:
		var spill_expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("user://e3-spill-expected.json"))
		check(manager.read("user://e3-spill.json",player),"fresh-process loose spill reload "+str(i))
		check(JSON.parse_string(sim.export_json())==spill_expected.native,"removed chest storage stays removed; native inventory exact")
		var drops := {}
		for child in get_children():
			if child is Pickup:
				child.set_physics_process(false)
				drops[String(child.family)] = int(drops.get(String(child.family),0))+child.amount
		check(JSON.parse_string(JSON.stringify(drops))==spill_expected.drops,"exact physical spill restored once")

func benchmark() -> void:
	for i in FUELS.size():
		sim.add_material(FUELS[i],3)
		var c := _place(&"campfire",StringName(FUELS[i]),Vector3i(i*2,0,7)) as PlacedBlock
		check(c!=null,"benchmark creates one paid active fuel instance")
		if c!=null:c._process(float(sim.fire_setting().fuels[FUELS[i]].burn_seconds)*.4)
	player.placement.set_build_mode_enabled(false)
	player.position = Vector3(-3,1,-3)
	caption.text = "E3 settled seven chests + five live fuel piles / benchmark without capture"
	for distance in [6.0,12.0,24.0]:
		view(Vector3(3.5,.3,4),distance)
		await settle(180)
		var samples: Array[float] = []
		var last := Time.get_ticks_usec()
		for i in 360:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			samples.append((now-last)/1000.0);last=now
		samples.sort()
		var live := 0
		for child in get_children():
			if child is PlacedBlock and child.is_fire():live+=1
		check(live==5,"all five native fires remain live throughout benchmark")
		e3_report.benchmarks.append({"distance_m":distance,"live_fires":live,"p50_ms":samples[180],"p95_ms":samples[342],"worst_ms":samples[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})

func finish_e3(mode: String) -> void:
	e3_report["checks"] = checks
	e3_report["failures"] = failures
	e3_report["backend"] = backend
	var f := FileAccess.open(output+"/"+mode+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(e3_report,"\t"));f.close()
	print("E3_",mode.to_upper()," ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func play_view() -> void:
	var c := chest_nodes[play_index]
	view(c.global_position+Vector3(0,.12,0),3.3)
	caption.text = "ART-07E3 / isolated stock / "+String(c.material_family)+"\n1–8 chest  O open/close  F paid timber fire  Esc quit"
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func play_smoke() -> void:
	for i in CHESTS.size():
		var select := InputEventKey.new()
		select.pressed = true
		select.keycode = KEY_1+i
		_input(select)
		check(play_index==i,"review key selects chest "+str(i))
		var open := InputEventKey.new()
		open.pressed = true
		open.keycode = KEY_O
		_input(open)
		await settle(40)
		check(player.chest_panel.is_open() and player.chest_panel.chest==chest_nodes[i],"review key opens actual native panel")
		_input(open)
		check(not player.chest_panel.is_open(),"review key closes actual panel")
	var fire := InputEventKey.new()
	fire.pressed = true
	fire.keycode = KEY_F
	_input(fire)
	var placed: PlacedBlock
	for child in get_children():
		if child is PlacedBlock and child.is_fire():placed=child
	check(placed!=null,"review fire key creates actual paid fire")
	if placed!=null:
		var before := placed.burn_left
		await settle(120)
		check(placed.burn_left<before and placed.burn_left>0,"interactive fire uses natural native clock")
	finish_e3("play-smoke")

func _input(event: InputEvent) -> void:
	if not playing or not event is InputEventKey or not event.pressed or event.echo:return
	if event.keycode==KEY_ESCAPE:get_tree().quit();return
	if event.keycode>=KEY_1 and event.keycode<=KEY_8:
		player.chest_panel.close_panel()
		play_index = int(event.keycode-KEY_1)
		play_view()
	if event.keycode==KEY_O:
		if player.chest_panel.is_open():player.chest_panel.close_panel()
		else:player.open_chest(chest_nodes[play_index]);player.chest_panel.hide()
	if event.keycode==KEY_F:
		sim.add_material("wood",3) # Explicit review stock; normal payment follows.
		var c := _place(&"campfire",&"wood",Vector3i(0,0,7)) as PlacedBlock
		if c!=null:
			player.placement.set_build_mode_enabled(false)
			fire_view(c.global_position+Vector3(0,-.16,0))
			caption.text = "Actual 45-second paid timber burn / native heat 1 / 1–8 return to chests"
