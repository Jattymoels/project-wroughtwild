extends Node3D
const Adapter := preload("res://native_state.gd")
var native: RefCounted
var config: Dictionary
var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var source_root: Node3D
var buffer_root: Node3D
var claim_root: Node3D
var pocket_root: Node3D
var rare_root: MeshInstance3D
var source_material: ShaderMaterial
var buffer_material: ShaderMaterial
var fragment_materials: Array[ShaderMaterial]=[]
var source_label: Label
var pocket_label: Label
var buffer_label: Label
var message_label: Label
var phase_label: Label
var wall: StaticBody3D
var heat_windows: Array[MeshInstance3D] = []
var output_bricks: Array[MeshInstance3D] = []
var active_pipe: MeshInstance3D
var housing_body: StaticBody3D
var shot := "overview"
var lod := "near"
var light_off := false
var shade := false
var automatic := false
var hold_simulation := false
var capture_id := 0
var telemetry: Array[Dictionary] = []
var visual_checks := 0
var evidence_directory := "res://evidence"
var source_at := Vector3(-2.3,0,0.4)
var buffer_at := Vector3(1.2,0,0.4)
var feeder_at := Vector3(3.2,0,-1.6)
var forge_at := Vector3(6.2,0,0.4)

func _ready() -> void:
	if "--compatibility-proof" in OS.get_cmdline_user_args():evidence_directory="res://evidence-compat"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_directory))
	config = JSON.parse_string(FileAccess.get_file_as_string("res://red.json"))
	native = Adapter.new()
	source_material = scar_material()
	buffer_material = scar_material()
	for i in 3:fragment_materials.append(scar_material("fragment-%d"%(i+1)))
	build_setting()
	build_assets()
	build_ui()
	set_shot("overview")
	if "--capture" in OS.get_cmdline_user_args():
		automatic = true
		hold_simulation = true
		call_deferred("capture_proof")
	elif "--benchmark" in OS.get_cmdline_user_args():
		hold_simulation=true
		call_deferred("benchmark")

func scar_material(prefix_: String="red") -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://red_scar.gdshader")
	for pair in [["base_texture","base.png"],["orm_texture","orm.png"],["scar_texture","scar.png"],["normal_texture","normal.png"]]:
		m.set_shader_parameter(pair[0],load("res://"+prefix_+"-"+pair[1]))
	m.set_shader_parameter("period_seconds",config.scar.period_seconds)
	m.set_shader_parameter("minimum_light",config.scar.minimum_light)
	m.set_shader_parameter("peak_emission",config.scar.peak_emission)
	var c: Array = config.scar.colour_srgb
	m.set_shader_parameter("core_colour",Color(c[0],c[1],c[2]))
	return m

func pbr(colour: Color, roughness: float = 0.85, metallic: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour; m.roughness = roughness; m.metallic = metallic
	return m

func box(parent: Node3D, at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	var o := MeshInstance3D.new(); var mesh := BoxMesh.new(); mesh.size = size
	o.mesh = mesh; o.material_override = material; parent.add_child(o); o.position = at
	return o

func scene_at(path: String, at: Vector3, parent: Node3D = self) -> Node3D:
	var scene: PackedScene = load("res://"+path)
	assert(scene != null, path)
	var o := scene.instantiate() as Node3D; parent.add_child(o);o.position = at
	return o

func apply_mineral(node: Node, material: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var previous: Material = node.get_active_material(i)
			if previous != null and (previous.resource_name.begins_with("RED_MINERAL") or previous.resource_name.begins_with("RED_FRAGMENT")):
				node.set_surface_override_material(i,material)
	for child in node.get_children(): apply_mineral(child,material)

func body(at: Vector3, size: Vector3, name_: String) -> StaticBody3D:
	var b := StaticBody3D.new(); b.name = name_; add_child(b); b.position = at
	var shape := BoxShape3D.new();shape.size = size
	var collider := CollisionShape3D.new();collider.shape = shape;collider.position.y = size.y * .5;b.add_child(collider)
	return b

func build_setting() -> void:
	var e := WorldEnvironment.new(); environment = Environment.new(); e.environment = environment;add_child(e)
	environment.background_mode = Environment.BG_COLOR;environment.background_color = Color("454e4b")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("cedbd8");environment.ambient_light_energy = .65
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC;environment.glow_enabled = false
	sun = DirectionalLight3D.new();sun.rotation_degrees = Vector3(-48,-32,0);sun.light_color=Color("ffdeb4");sun.light_energy=1.6;sun.shadow_enabled=true;add_child(sun)
	var ground := pbr(Color("343d32"))
	if ResourceLoader.exists("res://context/forest-floor.png"):
		ground.albedo_texture=load("res://context/forest-floor.png");ground.albedo_color=Color.WHITE;ground.uv1_scale=Vector3(8,8,8)
	box(self,Vector3(1,-.09,0),Vector3(26,.18,22),ground)
	environment.ssao_enabled=RenderingServer.get_current_rendering_method()=="forward_plus"
	environment.ssao_radius=1.0;environment.ssao_intensity=1.25
	get_viewport().msaa_3d=Viewport.MSAA_4X
	# Review backdrop only: reused grove trees, without native resource ownership.
	if ResourceLoader.exists("res://context/quiet-tree.glb"):
		for at in [Vector3(-6,0,-4),Vector3(0,0,-5),Vector3(7,0,-6),Vector3(11,0,-2)]:
			var tree := scene_at("context/quiet-tree.glb",at)
			tree.rotation.y=at.x*.72
			if ResourceLoader.exists("res://context/canopy-far.glb"):scene_at("context/canopy-far.glb",Vector3.ZERO,tree)
	# Crafted review plinths have no inventory or production role.
	var timber := pbr(Color("58402c"));var stone := pbr(Color("44423a"))
	for x in range(8):
		for z in range(5):
			box(self,Vector3(4.2+(x-4)*.59,.012,(z-2)*.58),Vector3(.56,.045,.55),stone)
	box(self,Vector3(-.30,.69,1.0),Vector3(1.0,.09,.72),timber)
	for x in [-.65,.05]:
		for z in [.74,1.26]:box(self,Vector3(x,.33,z),Vector3(.09,.66,.09),timber)
	camera=Camera3D.new();camera.fov=config.presentation.camera_fov;add_child(camera);camera.current=true

func build_assets() -> void:
	source_root=scene_at("red-source-"+lod+".glb",source_at)
	apply_mineral(source_root,source_material)
	body(source_at,Vector3(1.5,1.1,1.5),"SourceBody")
	buffer_root=scene_at("red-buffer-"+lod+".glb",buffer_at)
	apply_mineral(buffer_root,buffer_material)
	housing_body=body(buffer_at,Vector3(1,1.2,1),"BufferBody")
	claim_root=Node3D.new();add_child(claim_root);claim_root.position=source_at
	pocket_root=Node3D.new();add_child(pocket_root);pocket_root.position=Vector3(-.3,.736,1)
	for i in 3:
		var claim_piece:=scene_at("red-fragment-%d.glb"%(i+1),Vector3(-.29+i*.22,.002,.58),claim_root)
		claim_piece.scale=Vector3.ONE*.52;claim_piece.rotation.y=i*.73;apply_mineral(claim_piece,fragment_materials[i])
		var pocket_piece:=scene_at("red-fragment-%d.glb"%(i+1),Vector3(-.25+i*.25,0,.03-abs(i-1)*.07),pocket_root)
		pocket_piece.rotation.y=i*1.21;apply_mineral(pocket_piece,fragment_materials[i])
	# Existing rare claim remains independently visible after raw collection.
	# This small faceted marker is not a second collectable or a new rare asset.
	rare_root=MeshInstance3D.new();var rare_mesh:=SphereMesh.new();rare_mesh.radius=.075;rare_mesh.height=.18;rare_mesh.radial_segments=6;rare_mesh.rings=3
	rare_root.mesh=rare_mesh;rare_root.material_override=pbr(Color("852718"),.65,.1);claim_root.add_child(rare_root);rare_root.position=Vector3(.38,.10,.53)
	var forge:=scene_at("context/forge_basic.glb",forge_at)
	body(forge_at,Vector3(.95,1.65,.95),"ForgeReviewBody")
	# Reuse the existing feeder components and their authored fitted sizes.
	var feeder:=Node3D.new();add_child(feeder);feeder.position=feeder_at
	for role in [["strange_winch",Vector3.ZERO,Vector3(1.25,1.15,1.05)],["strange_basket",Vector3(0,1.05,-.26),Vector3(.65,.35,.55)],["strange_ventlung",Vector3(-.31,.32,.1),Vector3(.42,.5,.46)],["strange_drum",Vector3(.33,.66,.02),Vector3(.46,.48,.46)],["strange_basket",Vector3(.12,.17,.3),Vector3(.74,.18,.62)]]:
		var component:=scene_at("context/"+role[0]+".glb",Vector3.ZERO,feeder)
		fit(component,role[2]);component.position+=role[1]
	body(feeder_at,Vector3(1.5,1.45,1.45),"FeederBody")
	var tube:=pbr(Color("4b3324"),.55,.65)
	pipe(buffer_at+Vector3.UP*.85,feeder_at+Vector3.UP*.85,.045,tube)
	active_pipe=pipe(buffer_at+Vector3.UP*.85,feeder_at+Vector3.UP*.85,.021,pbr(Color("de6427")))
	active_pipe.visible=false
	pipe(feeder_at+Vector3.UP*.85,forge_at+Vector3.UP*.85,.038,tube)
	for i in 4:
		var m:=pbr(Color("562210"))
		var w:=box(self,buffer_at+Vector3(-.25+i*.165,.585,.418),Vector3(.025,.152,.012),m)
		heat_windows.append(w)
	var brick:=pbr(Color("995536"))
	for i in 4:output_bricks.append(box(self,feeder_at+Vector3(-.12+(i%2)*.24,.33+(i/2)*.075,.3),Vector3(.215,.064,.3),brick))
	wall=body(buffer_at.lerp(feeder_at,.5),Vector3(.38,1.4,.38),"ThermalObstruction")
	box(wall,Vector3(0,.7,0),Vector3(.38,1.4,.38),pbr(Color("56595a")))
	set_obstruction(false)

func fit(root: Node3D, dimensions: Vector3) -> void:
	var aabb:=merged_bounds(root,Transform3D.IDENTITY)
	root.scale=dimensions/aabb.size
	root.position=-Vector3(aabb.position.x+aabb.size.x*.5,aabb.position.y,aabb.position.z+aabb.size.z*.5)*root.scale

func merged_bounds(node: Node, transform: Transform3D) -> AABB:
	if node is Node3D:transform*=node.transform
	var result:=AABB();var first:=true
	if node is MeshInstance3D:result=transform*node.mesh.get_aabb();first=false
	for child in node.get_children():
		var found:=merged_bounds(child,transform)
		if found.size==Vector3.ZERO:continue
		result=found if first else result.merge(found);first=false
	return result

func pipe(a: Vector3,b: Vector3,radius: float,mat: Material) -> MeshInstance3D:
	var o:=MeshInstance3D.new();var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=a.distance_to(b);mesh.radial_segments=12
	o.mesh=mesh;o.material_override=mat;add_child(o);o.position=(a+b)*.5
	var direction: Vector3=(b-a).normalized();o.quaternion=Quaternion(Vector3.UP,direction)
	return o

func build_ui() -> void:
	var canvas:=CanvasLayer.new();add_child(canvas)
	var root:=Control.new();canvas.add_child(root);root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);root.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var panel:=PanelContainer.new();root.add_child(panel);panel.position=Vector2(34,26);panel.size=Vector2(490,125)
	var style:=StyleBoxFlat.new();style.bg_color=Color(.035,.047,.043,.9);style.content_margin_left=22;style.content_margin_right=22;style.content_margin_top=16;style.content_margin_bottom=16;panel.add_theme_stylebox_override("panel",style)
	var v:=VBoxContainer.new();panel.add_child(v)
	label(v,"RED  /  EXCITATION",29,Color("f0c896"))
	label(v,"Fractured host  →  recovered salt  →  deliberate heat",17,Color("d9ded3"))
	phase_label=label(v,"ISOLATED REVIEW · saved workshop",14,Color("a0aba3"))
	var footer:=PanelContainer.new();root.add_child(footer);footer.position=Vector2(34,735);footer.size=Vector2(1532,230);footer.add_theme_stylebox_override("panel",style)
	var stack:=VBoxContainer.new();footer.add_child(stack)
	var row:=HBoxContainer.new();row.add_theme_constant_override("separation",40);stack.add_child(row)
	var left:=VBoxContainer.new();left.custom_minimum_size.x=440;row.add_child(left)
	label(left,"01  THE INCLUSION",16,Color("b08c69"));source_label=label(left,"",20,Color("f3e8d6"))
	var mid:=VBoxContainer.new();mid.custom_minimum_size.x=370;row.add_child(mid)
	label(mid,"02  RECOVERED MATERIAL",16,Color("b08c69"));pocket_label=label(mid,"",20,Color("f3e8d6"))
	var right:=VBoxContainer.new();row.add_child(right)
	label(right,"03  RED HEAT BUFFER",16,Color("b08c69"));buffer_label=label(right,"",20,Color("f3e8d6"))
	message_label=label(stack,"",16,Color("bfc6bc"))
	var buttons:=HBoxContainer.new();stack.add_child(buttons)
	for pair in [["Work inclusion","work"],["Collect Red Salt","collect"],["Pay 2 Salt → 1 heat","heat"],["Start firing","start"],["Resume firing","resume"],["Pause firing","pause"],["Cancel firing","cancel"]]:
		var button:=Button.new();button.text=pair[0];buttons.add_child(button);button.pressed.connect(func():native.act(pair[1]))
	var rare_button:=Button.new();rare_button.text="Collect catalyst";buttons.add_child(rare_button);rare_button.pressed.connect(func():native.act("collect_rare"))
	var block_button:=Button.new();block_button.text="Block thermal span";buttons.add_child(block_button);block_button.pressed.connect(func():set_obstruction(not wall.visible))
	label(stack,"1  Source    2  Buffer    3  Whole workshop    4  Fragments    D  Day / shade    G  Light off    N / M / F  Detail    Space  Review pause    R  Reset review    Esc  Close",14,Color("99a69f"))

func label(parent: Node,text: String,size_: int,colour: Color) -> Label:
	var l:=Label.new();l.text=text;l.add_theme_font_size_override("font_size",size_);l.add_theme_color_override("font_color",colour);parent.add_child(l);return l

func set_shot(value: String) -> void:
	shot=value
	if value=="source":camera.position=source_at+Vector3(1.7,2.2,3.25);camera.look_at(source_at+Vector3(0,.31,0))
	elif value=="buffer":camera.position=buffer_at+Vector3(1.75,1.6,2.8);camera.look_at(buffer_at+Vector3(0,.60,0))
	elif value=="fragments":camera.position=Vector3(.48,1.53,2.38);camera.look_at(Vector3(-.3,.78,1))
	else:camera.position=Vector3(7.2,5.2,9.6);camera.look_at(Vector3(1.5,.48,-.1))

func set_obstruction(value: bool) -> void:
	wall.visible=value;wall.collision_layer=1 if value else 0

func thermal_clear() -> bool:
	var ray:=PhysicsRayQueryParameters3D.create(buffer_at+Vector3.UP*.85,feeder_at+Vector3.UP*.85)
	ray.exclude=[housing_body.get_rid(),get_node("FeederBody").get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()

func _physics_process(delta: float) -> void:
	if native == null:return
	native.physical_ready=thermal_clear()
	if not hold_simulation:native.tick(delta)
	update_visuals()

func update_visuals() -> void:
	var v: Dictionary=native.view()
	for m in [source_material,buffer_material]+fragment_materials:
		m.set_shader_parameter("cosmetic_clock",native.ambient_clock);m.set_shader_parameter("work_clock",native.work_clock);m.set_shader_parameter("light_off",light_off)
	for m in fragment_materials:m.set_shader_parameter("state_mode",1);m.set_shader_parameter("native_gain",config.presentation.claim_gain)
	source_material.set_shader_parameter("state_mode",2 if v.source_ready and not v.source_blocked else 0)
	source_material.set_shader_parameter("native_gain",config.presentation.source_work_gain if v.source_work>0 else config.presentation.source_ready_gain)
	claim_root.visible=v.raw_claim>0 or v.rare_claim>0
	for child in claim_root.get_children():child.visible=v.rare_claim>0 if child==rare_root else v.raw_claim>0
	pocket_root.visible=v.salt_owned>0
	buffer_material.set_shader_parameter("state_mode",3 if v.working else (1 if v.heat+v.reserved_heat>0 else 0))
	buffer_material.set_shader_parameter("native_gain",config.presentation.working_gain if v.working else config.presentation.stored_gain*float(v.heat+v.reserved_heat)/v.capacity)
	for i in heat_windows.size():
		var m:=heat_windows[i].material_override as StandardMaterial3D
		m.albedo_color=Color("d26727") if i<v.heat else (Color("985f35") if i<v.heat+v.reserved_heat else Color("211b15"))
		m.emission_enabled=not light_off and i<v.heat+v.reserved_heat
		m.emission=Color("e77c35") if i<v.heat else Color("824628")
		m.emission_energy_multiplier=.5
	# The solid thermal span is always present. Only a native advancing firing
	# may show a small travel marker; no endless success or stored-heat loop.
	active_pipe.visible=v.working and not light_off
	if active_pipe.visible:
		var t:=fmod(native.work_clock,1.6)/1.6
		active_pipe.scale.y=.07;active_pipe.position=(buffer_at+Vector3.UP*.85).lerp(feeder_at+Vector3.UP*.85,t)
	for i in output_bricks.size():output_bricks[i].visible=v.output>0
	source_label.text="%s · %d / %d lots drawn\n%d Salt held at the source"%[v.source_state,v.lot,v.lots,v.raw_claim]
	if v.rare_claim>0:source_label.text+=" + %d catalyst"%v.rare_claim
	pocket_label.text="%d Red Salt in your pack\n2 Salt pay for 1 stored heat"%v.salt_owned
	var state: String="Firing" if v.working else ("Obstructed" if not v.physical_ready else ("Paused" if v.feeder_paused else "Idle"))
	buffer_label.text="%d stored + %d held / %d heat\n%s · %.2f / %.0f s · %d bricks"%[v.heat,v.reserved_heat,v.capacity,state,v.progress,v.cycle_seconds,v.output]
	message_label.text=native.message
	phase_label.text="ISOLATED REVIEW · %s · %s · %s"%["shade" if shade else "day","light off" if light_off else "no bloom",lod]

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1:set_shot("source")
		KEY_2:set_shot("buffer")
		KEY_3:set_shot("overview")
		KEY_4:set_shot("fragments")
		KEY_D:set_shade(not shade)
		KEY_G:light_off=not light_off
		KEY_SPACE:native.paused=not native.paused
		KEY_R:native.load_checkpoint("res://paid-checkpoint.json");native.message="Reset to the isolated paid checkpoint."
		KEY_N:set_lod("near")
		KEY_M:set_lod("mid")
		KEY_F:set_lod("far")
		KEY_ESCAPE:get_tree().quit()

func set_shade(value: bool) -> void:
	shade=value;sun.light_energy=.30 if shade else 1.6;environment.ambient_light_energy=.38 if shade else .65
	environment.background_color=Color("293b3b") if shade else Color("454e4b")

func set_lod(value: String) -> void:
	lod=value;source_root.free();buffer_root.free()
	source_root=scene_at("red-source-"+lod+".glb",source_at);apply_mineral(source_root,source_material)
	buffer_root=scene_at("red-buffer-"+lod+".glb",buffer_at);apply_mineral(buffer_root,buffer_material)

func snap(name_: String) -> void:
	update_visuals()
	var state: Dictionary=native.view()
	assert(claim_root.visible==(state.raw_claim>0 or state.rare_claim>0));visual_checks+=1
	assert(rare_root.visible==(state.rare_claim>0));visual_checks+=1
	assert(pocket_root.visible==(state.salt_owned>0));visual_checks+=1
	assert(active_pipe.visible==(state.working and not light_off));visual_checks+=1
	assert(int(source_material.get_shader_parameter("state_mode"))==(2 if state.source_ready and not state.source_blocked else 0));visual_checks+=1
	assert(int(buffer_material.get_shader_parameter("state_mode"))==(3 if state.working else (1 if state.heat+state.reserved_heat>0 else 0)));visual_checks+=1
	for i in 3:await RenderingServer.frame_post_draw
	var path: String=evidence_directory+"/"+name_+".png"
	get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	var record: Dictionary=native.view();record["capture"]=name_;record["shot"]=shot;record["shade"]=shade;record["light_off"]=light_off;record["lod"]=lod
	record["render_objects"]=Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
	record["draw_calls"]=Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	record["render_primitives"]=Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
	record["video_memory_bytes"]=Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)
	telemetry.append(record)

func capture_proof() -> void:
	await get_tree().physics_frame
	native.ambient_clock=2.3
	await snap("01-overview-ready")
	set_shot("source");await snap("02-source-ready-day")
	light_off=true;await snap("03-source-light-off");light_off=false
	native.act("work");native.act("work");await snap("04-source-worked")
	native.act("work");native.act("work");await snap("05-source-released-claim")
	native.act("collect");await snap("06-source-spent")
	set_shot("fragments");await snap("07-recovered-fragments")
	set_shot("buffer");set_shade(true);await snap("08-buffer-held-shade")
	light_off=true;await snap("09-buffer-light-off");light_off=false
	native.act("resume")
	for i in 8:native.tick(.125);await get_tree().process_frame
	await snap("10-buffer-real-firing")
	set_obstruction(true)
	for i in 3:await get_tree().physics_frame
	native.tick(50);set_shot("overview");await snap("11-thermal-obstruction")
	set_obstruction(false)
	for i in 3:await get_tree().physics_frame
	native.act("pause");native.tick(50);set_shot("buffer");await snap("12-buffer-paused")
	native.act("resume");native.tick(4.75);native.tick(0)
	await snap("13-paid-firing-complete")
	native.act("heat");await snap("14-recovered-salt-stored")
	set_shade(false);set_shot("overview");await snap("15-chain-complete")
	# Same-camera LOD evidence, no changed state or lighting between captures.
	for detail in ["near","mid","far"]:
		set_lod(detail);set_shot("source");await snap("16-source-lod-"+detail)
		set_shot("buffer");await snap("17-buffer-lod-"+detail)
	# Real, finite firing clip: each frame advances the loaded held transaction.
	set_lod("near");set_shade(true);set_shot("buffer")
	native.load_checkpoint("res://paid-checkpoint.json");native.act("resume")
	for frame in 48:
		native.tick(.125)
		await snap("motion-%03d"%frame)
	native.load_checkpoint("user://rare-held.json");set_shot("source");await snap("18-native-rare-only-claim")
	assert(native.view().raw_claim==0 and native.view().rare_claim==1);visual_checks+=1
	var file:=FileAccess.open(evidence_directory+"/capture-state.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(telemetry,"\t"))
	file=FileAccess.open(evidence_directory+"/capture-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"captures":telemetry.size(),"visual_checks":visual_checks,"failures":[],"renderer":RenderingServer.get_current_rendering_method(),"bloom":false},"\t"))
	print("ART04_CAPTURE_COMPLETE ",telemetry.size()," visual checks ",visual_checks)
	get_tree().quit()

func benchmark() -> void:
	set_shot("overview")
	var viewport:=get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport,true)
	var results: Array[Dictionary]=[]
	for detail in ["near","mid","far"]:
		set_lod(detail)
		for light in [false,true]:
			light_off=not light;update_visuals()
			var cpu: Array[float]=[];var gpu: Array[float]=[];var wall_time: Array[float]=[]
			var previous:=Time.get_ticks_usec()
			for frame in 120:
				native.tick(1.0/60.0);update_visuals()
				await RenderingServer.frame_post_draw
				var now:=Time.get_ticks_usec()
				if frame>=30:
					cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport));gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport));wall_time.append((now-previous)/1000.0)
				previous=now
			cpu.sort();gpu.sort();wall_time.sort()
			results.append({"lod":detail,"light":light,"cpu_ms_median":cpu[45],"gpu_ms_median":gpu[45],"gpu_ms_p95":gpu[85],"frame_ms_median":wall_time[45],"draws_visible":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"texture_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)})
	var file:=FileAccess.open(evidence_directory+"/performance.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"adapter":RenderingServer.get_video_adapter_name(),"resolution":[1600,1000],"warmup_frames":30,"sample_frames":90,"cases":results,"limitation":"Isolated source/workshop and reused tree backdrop, not populated world streaming. One desktop GPU."},"\t"))
	print("ART04_BENCHMARK_COMPLETE")
	get_tree().quit()
