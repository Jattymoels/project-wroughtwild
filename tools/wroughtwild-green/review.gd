extends Node3D
const Adapter := preload("res://native_state.gd")
var native: RefCounted
var config: Dictionary
var camera: Camera3D
var environment: Environment
var sun: DirectionalLight3D
var source_root: Node3D
var post_root: Node3D
var claim_root: Node3D
var pocket_root: Node3D
var basket: Node3D
var bricks_root: Node3D
var floor_body: StaticBody3D
var source_material: ShaderMaterial
var core_materials: Array[ShaderMaterial]=[]
var fragment_materials: Array[ShaderMaterial]=[]
var bodies: Dictionary={}
var walls: Dictionary={}
var markers: Array[MeshInstance3D]=[]
var label: Label
var message_label: Label
var phase_label: Label
var shot := "source"
var lod := "near"
var light_off := false
var shade := false
var hold_simulation := false
var telemetry: Array[Dictionary]=[]
var visual_checks := 0
var evidence_directory := "res://evidence"
var source_at := Vector3(-2.6,0,4.0)
# Exact relative positions of the original paid checkpoint, centred on Green.
var post_at := Vector3.ZERO
var blue_at := Vector3(-4,0,2)
var white_at := Vector3(-8,0,3)
var lever_at := Vector3(-12,0,2)
var drum_at := Vector3(-8,0,-2)
var landing_at := Vector3(6,0,-2)
var feeder_at := Vector3(5,0,10)
var forge_at := Vector3(8,0,12)
func _ready() -> void:
	if "--compatibility-proof" in OS.get_cmdline_user_args():evidence_directory="res://evidence-compat"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_directory))
	config=JSON.parse_string(FileAccess.get_file_as_string("res://green.json"))
	native=Adapter.new();native.passage_duration=config.presentation.passage_seconds
	source_material=scar_material()
	var report:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://asset-report.json"))
	for i in 3:
		fragment_materials.append(scar_material("fragment-%d"%(i+1)))
		var m:=scar_material("fragment-%d"%(i+1));m.set_shader_parameter("branch_override",i*.5)
		m.set_shader_parameter("height_local",report.post.cores[i].height_local)
		m.set_shader_parameter("flow_start",0.0 if i==0 else .42);m.set_shader_parameter("flow_span",.42 if i==0 else .58);core_materials.append(m)
	build_setting();build_assets();build_ui();set_shot("source")
	if "--capture" in OS.get_cmdline_user_args():hold_simulation=true;call_deferred("capture_proof")
	elif "--benchmark" in OS.get_cmdline_user_args():hold_simulation=true;call_deferred("benchmark")
func scar_material(prefix_: String="green") -> ShaderMaterial:
	var m:=ShaderMaterial.new();m.shader=load("res://green_scar.gdshader")
	for pair in [["base_texture","base.png"],["orm_texture","orm.png"],["scar_texture","scar.png"],["normal_texture","normal.png"]]:m.set_shader_parameter(pair[0],load("res://"+prefix_+"-"+pair[1]))
	for name_ in ["period_seconds","minimum_light","peak_emission"]:m.set_shader_parameter(name_,config.scar[name_])
	var c:Array=config.scar.colour_srgb;m.set_shader_parameter("core_colour",Color(c[0],c[1],c[2]))
	return m
func pbr(colour: Color,roughness: float=.85,metallic: float=0.0) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=colour;m.roughness=roughness;m.metallic=metallic;return m
func box(parent: Node3D,at: Vector3,size: Vector3,material: Material) -> MeshInstance3D:
	var o:=MeshInstance3D.new();var mesh:=BoxMesh.new();mesh.size=size;o.mesh=mesh;o.material_override=material;parent.add_child(o);o.position=at;return o
func scene_at(path: String,at: Vector3,parent: Node3D=self) -> Node3D:
	var packed:PackedScene=load("res://"+path);assert(packed!=null,path)
	var o:=packed.instantiate() as Node3D;parent.add_child(o);o.position=at;return o
func bound_count(node: Node,material: Material) -> int:
	var count:=0
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			if node.get_active_material(i)==material:count+=1
	for child in node.get_children():count+=bound_count(child,material)
	return count
func body(at: Vector3,size: Vector3,name_: String) -> StaticBody3D:
	var b:=StaticBody3D.new();b.name=name_;add_child(b);b.position=at
	var shape:=BoxShape3D.new();shape.size=size;var c:=CollisionShape3D.new();c.shape=shape;c.position.y=size.y*.5;b.add_child(c);return b
func merged_bounds(node: Node,transform: Transform3D) -> AABB:
	if node is Node3D:transform*=node.transform
	var result:=AABB();var first:=true
	if node is MeshInstance3D:result=transform*node.mesh.get_aabb();first=false
	for child in node.get_children():
		var found:=merged_bounds(child,transform)
		if found.size==Vector3.ZERO:continue
		result=found if first else result.merge(found);first=false
	return result
func fit(root: Node3D,dimensions: Vector3) -> void:
	var bounds:=merged_bounds(root,Transform3D.IDENTITY);root.scale=dimensions/bounds.size;root.position=-Vector3(bounds.position.x+bounds.size.x*.5,bounds.position.y,bounds.position.z+bounds.size.z*.5)*root.scale
func pipe(a: Vector3,b: Vector3,radius: float,mat: Material) -> void:
	var o:=MeshInstance3D.new();var mesh:=CylinderMesh.new();mesh.top_radius=radius;mesh.bottom_radius=radius;mesh.height=a.distance_to(b);mesh.radial_segments=10;o.mesh=mesh;o.material_override=mat;add_child(o);o.position=(a+b)*.5
	o.quaternion=Quaternion(Vector3.UP,(b-a).normalized())
func set_wall(wall: StaticBody3D,enabled: bool) -> void:
	wall.visible=enabled;wall.collision_layer=1 if enabled else 0
func physical_clear(a: Vector3,b: Vector3,excluded: Array[RID]) -> bool:
	var query:=PhysicsRayQueryParameters3D.create(a,b);query.exclude=excluded
	return get_world_3d().direct_space_state.intersect_ray(query).is_empty()
func check(value: bool,description: String) -> void:
	visual_checks+=1;assert(value,description)
func benchmark() -> void:
	await get_tree().process_frame
	var results:Array=[]
	for view_name in ["source","post","overview"]:
		set_shot(view_name)
		for shadow in [false,true]:
			shade=shadow
			var gpu:Array=[];var cpu:Array=[]
			for frame in 150:
				await get_tree().process_frame
				if frame<30:continue
				gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
				cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
			gpu.sort();cpu.sort();results.append({"shot":view_name,"shade":shade,"gpu_median_ms":gpu[60],"gpu_p95_ms":gpu[114],"cpu_median_ms":cpu[60],"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
	FileAccess.open(evidence_directory+"/performance.json",FileAccess.WRITE).store_string(JSON.stringify({"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"cases":results},"\t"));get_tree().quit()

func build_setting() -> void:
	var e:=WorldEnvironment.new();environment=Environment.new();e.environment=environment;add_child(e)
	environment.background_mode=Environment.BG_COLOR;environment.background_color=Color("454e4b")
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;environment.ambient_light_color=Color("e5e6dc");environment.ambient_light_energy=.75
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC;environment.glow_enabled=false
	environment.ssao_enabled=RenderingServer.get_current_rendering_method()=="forward_plus";environment.ssao_radius=.8;environment.ssao_intensity=1.15
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-32,0);sun.light_color=Color("fff0d8");sun.light_energy=1.6;sun.shadow_enabled=true;add_child(sun)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var ground:=pbr(Color.WHITE);ground.albedo_texture=load("res://context/forest-floor.png");ground.uv1_scale=Vector3(10,10,10)
	box(self,Vector3(0,-.09,4),Vector3(40,.18,40),ground)
	floor_body=body(Vector3(0,-.18,4),Vector3(40,.18,40),"ReviewGround")
	for at in [Vector3(-14,0,-5),Vector3(-5,0,-10),Vector3(11,0,-6),Vector3(14,0,9)]:
		var tree:=scene_at("context/quiet-tree.glb",at);tree.rotation.y=at.x*.72;scene_at("context/canopy-far.glb",Vector3.ZERO,tree)
	var timber:=pbr(Color("66503a"));box(self,Vector3(-1.1,.62,1.5),Vector3(1.05,.07,.70),timber)
	for x in [-1.50,-.70]:
		for z in [1.25,1.75]:box(self,Vector3(x,.30,z),Vector3(.075,.60,.075),timber)
	camera=Camera3D.new();camera.fov=config.presentation.camera_fov;add_child(camera);camera.current=true
func apply_surface(node: Node,material: ShaderMaterial,prefix_: String) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var previous:Material=node.get_active_material(i)
			if previous!=null and previous.resource_name.begins_with(prefix_):node.set_surface_override_material(i,material)
	for child in node.get_children():apply_surface(child,material,prefix_)
func load_heroes() -> void:
	source_root=scene_at("green-source-"+lod+".glb",source_at);apply_surface(source_root,source_material,"GREEN_MINERAL")
	post_root=scene_at("green-post-"+lod+".glb",post_at)
	for i in 3:apply_surface(post_root,core_materials[i],"GREEN_FRAGMENT - %d"%(i+1))
func build_assets() -> void:
	load_heroes();bodies.source=body(source_at,Vector3(1.5,1.1,1.5),"SourceBody");bodies.post=body(post_at,Vector3(.65,1.18,.55),"GreenBody")
	claim_root=Node3D.new();add_child(claim_root);claim_root.position=source_at
	pocket_root=Node3D.new();add_child(pocket_root);pocket_root.position=Vector3(-1.1,.657,1.5)
	for i in 3:
		var c:=scene_at("green-fragment-%d.glb"%(i+1),Vector3(-.28+i*.24,.002,.66),claim_root);c.scale=Vector3.ONE*.55;c.rotation.y=i*.7;apply_surface(c,fragment_materials[i],"GREEN_FRAGMENT")
		var p:=scene_at("green-fragment-%d.glb"%(i+1),Vector3(-.28+i*.27,0,.03-abs(i-1)*.05),pocket_root);p.rotation.y=i*.6;apply_surface(p,fragment_materials[i],"GREEN_FRAGMENT")
	for data in [["white",white_at],["blue",blue_at]]:
		var context:=scene_at("context/"+data[0]+"-post.glb",data[1]);var surface:=scar_material("context/"+data[0]);surface.set_shader_parameter("state_mode",0)
		apply_surface(context,surface,String(data[0]).to_upper()+"_MINERAL");bodies[data[0]]=body(data[1],Vector3(.65,1.18,.55),String(data[0])+"Body")
	for data in [["drum","strange_winch",drum_at,Vector3(1.4,1.83,1.15)],["landing","strange_winch",landing_at,Vector3(1.4,1.83,1.15)],["lever","strange_lever",lever_at,Vector3(.65,.95,.5)]]:
		var model:=scene_at("context/"+data[1]+".glb",Vector3.ZERO);fit(model,data[3]);model.position+=data[2];bodies[data[0]]=body(data[2],data[3],String(data[0])+"Body")
	scene_at("context/forge_basic.glb",forge_at);bodies.forge=body(forge_at,Vector3(.95,1.65,.95),"ForgeBody")
	# Existing feeder is a fitted assembly; reuse its actual component layout.
	var feeder:=Node3D.new();add_child(feeder);feeder.position=feeder_at
	for part in [["winch",Vector3.ZERO,Vector3(1.25,1.15,1.05)],["basket",Vector3(0,1.05,-.26),Vector3(.65,.35,.55)],["ventlung",Vector3(-.31,.32,.1),Vector3(.42,.5,.46)],["drum",Vector3(.33,.66,.02),Vector3(.46,.48,.46)],["basket",Vector3(.12,.17,.3),Vector3(.74,.18,.62)]]:
		var component:=scene_at("context/strange_"+part[0]+".glb",Vector3.ZERO,feeder);fit(component,part[2]);component.position+=part[1]
	bodies.feeder=body(feeder_at,Vector3(1.5,1.45,1.45),"FeederBody")
	basket=scene_at("context/strange_basket.glb",Vector3.ZERO);fit(basket,Vector3(.56,.38,.50))
	bricks_root=Node3D.new();add_child(bricks_root);bricks_root.position=feeder_at+Vector3(-.06,.33,.24)
	for i in 8:box(bricks_root,Vector3((i%2)*.18,(i/4)*.09,((i/2)%2)*.10),Vector3(.17,.085,.09),pbr(Color("99654b")))
	var cable:=pbr(Color("8b8973"),.65,.3)
	for endpoints in [[lever_at+Vector3.UP*.95,white_at+Vector3.UP*1.18],[white_at+Vector3.UP*1.18,blue_at+Vector3.UP*1.18],[blue_at+Vector3.UP*1.18,post_at+Vector3.UP*1.18],[post_at+Vector3.UP*1.18,drum_at+Vector3.UP*1.7],[post_at+Vector3.UP*1.18,feeder_at+Vector3.UP*1.45],[drum_at+Vector3.UP*1.7,landing_at+Vector3.UP*1.7],[feeder_at+Vector3.UP*.85,forge_at+Vector3.UP*.85]]:pipe(endpoints[0],endpoints[1],.012,cable)
	for i in 2:
		var m:=box(self,Vector3.ZERO,Vector3(.07,.07,.07),pbr(Color("bbffc2")));m.visible=false;markers.append(m)
	for data in [["upstream",blue_at.lerp(post_at,.5)],["first",post_at.lerp(drum_at,.5)],["second",post_at.lerp(feeder_at,.5)],["cargo",drum_at.lerp(landing_at,.5)],["feeder",feeder_at.lerp(forge_at,.5)]]:
		var w:=body(data[1],Vector3(.45,2.1,.7),String(data[0])+"Obstruction");box(w,Vector3(0,1.05,0),Vector3(.45,2.1,.7),pbr(Color("545a50")));walls[data[0]]=w;set_wall(w,false)
func ray(a: Vector3,b: Vector3,first: String,second: String) -> bool:
	return physical_clear(a,b,[bodies[first].get_rid(),bodies[second].get_rid()])
func supported(at: Vector3,half_width: float) -> bool:
	var excluded:Array[RID]=[]
	for b in bodies.values():excluded.append(b.get_rid())
	for x in [-half_width,half_width]:
		for z in [-half_width,half_width]:
			var foot:=at+Vector3(x,0,z);var query:=PhysicsRayQueryParameters3D.create(foot+Vector3.UP*.15,foot-Vector3.UP*.4)
			query.exclude=excluded
			var hit:=get_world_3d().direct_space_state.intersect_ray(query)
			if hit.is_empty() or hit.collider!=floor_body or Vector3(hit.normal).dot(Vector3.UP)<.5:return false
	return true
func refresh_physics() -> void:
	native.input_clear=ray(lever_at+Vector3.UP*.95,white_at+Vector3.UP*1.18,"lever","white") and ray(white_at+Vector3.UP*1.18,blue_at+Vector3.UP*1.18,"white","blue")
	native.blue_output_clear=ray(blue_at+Vector3.UP*1.18,post_at+Vector3.UP*1.18,"blue","post")
	native.first_clear=ray(post_at+Vector3.UP*1.18,drum_at+Vector3.UP*1.7,"post","drum")
	native.second_clear=ray(post_at+Vector3.UP*1.18,feeder_at+Vector3.UP*1.45,"post","feeder")
	var tube:=SphereShape3D.new();tube.radius=.045
	var connection:=PhysicsShapeQueryParameters3D.new();connection.shape=tube;connection.transform.origin=feeder_at+Vector3.UP*.85;connection.motion=forge_at-feeder_at;connection.exclude=[bodies.feeder.get_rid(),bodies.forge.get_rid()]
	var geometry:=get_world_3d().direct_space_state
	native.feeder_clear=supported(feeder_at,.46) and supported(forge_at,.32) and geometry.intersect_shape(connection,1).is_empty() and geometry.cast_motion(connection)[0]>=.9999
	var shape:=SphereShape3D.new();shape.radius=.3
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=drum_at+Vector3.UP*1.45;query.motion=landing_at-drum_at;query.exclude=[bodies.drum.get_rid(),bodies.landing.get_rid()]
	var state:=get_world_3d().direct_space_state;native.cargo_clear=supported(drum_at,0) and supported(landing_at,0) and state.intersect_shape(query,1).is_empty() and state.cast_motion(query)[0]>=1.0
func build_ui() -> void:
	var layer:=CanvasLayer.new();add_child(layer)
	var panel:=PanelContainer.new();panel.position=Vector2(28,24);layer.add_child(panel)
	var title:=Label.new();title.text="GREEN / CONNECTED GROWTH\nScarred grain → recovered resin → one request, two branches";title.add_theme_font_size_override("font_size",23);panel.add_child(title)
	phase_label=Label.new();phase_label.position=Vector2(30,92);phase_label.add_theme_font_size_override("font_size",16);layer.add_child(phase_label)
	var bottom:=PanelContainer.new();bottom.position=Vector2(28,780);bottom.size=Vector2(1544,198);layer.add_child(bottom)
	var column:=VBoxContainer.new();bottom.add_child(column)
	label=Label.new();label.add_theme_font_size_override("font_size",19);column.add_child(label)
	message_label=Label.new();message_label.add_theme_font_size_override("font_size",16);column.add_child(message_label)
	for pairs in [[["Work source","work"],["Collect resin","collect"],["Collect rare","rare"],["Send request","request"],["Hold Blue","pause"],["Resume","resume"],["Cancel","cancel"],["Cut branch 2","disconnect_second"],["Connect branch 2","connect_second"]],[["Wind winch","wind"],["Collect cargo","cargo"],["Load 10 wood","load"],["Wind feeder","wind_feeder"],["8 clay","clay"],["1 fuel","fuel"],["Collect bricks","bricks"]]]:
		var row:=HBoxContainer.new();column.add_child(row)
		for pair in pairs:
			var button:=Button.new();button.text=pair[0];button.pressed.connect(act.bind(pair[1]));row.add_child(button)
	var help:=Label.new();help.text="1 Source  2 Junction  3 Route  4 Resin  5 Feeder | D Shade  G Glow  N/M/F Detail | U Upstream  J/K Branch walls  C Cargo  V Forge | Space Pause  A Away  R Reset  Esc Close";help.add_theme_font_size_override("font_size",14);column.add_child(help)
func act(action: String) -> void:
	refresh_physics();native.act(action);refresh()
func set_shot(name_: String) -> void:
	shot=name_;var target:=source_at+Vector3(0,.40,0);var offset:=Vector3(1.65,1.15,2.45)
	if shot=="post":target=post_at+Vector3(0,.64,0);offset=Vector3(-1.1,.72,2.0)
	elif shot=="fragments":target=pocket_root.position+Vector3(0,.11,0);offset=Vector3(1.1,.75,1.5)
	elif shot=="overview":target=Vector3(-2,.50,3.2);offset=Vector3(16,15,23)
	elif shot=="feeder":target=feeder_at.lerp(forge_at,.45)+Vector3.UP*.65;offset=Vector3(5,3,6)
	camera.position=target+offset;camera.look_at(target)
func set_lod(value: String) -> void:
	lod=value;source_root.free();post_root.free();load_heroes()
func refresh() -> void:
	var v:Dictionary=native.view()
	source_material.set_shader_parameter("state_mode",2 if v.source_ready else 0);source_material.set_shader_parameter("native_gain",(config.presentation.source_work_gain if v.source_work>0 else config.presentation.source_ready_gain) if v.source_ready else 0.0)
	for m in core_materials:
		m.set_shader_parameter("state_mode",3 if v.passage_visible else 0);m.set_shader_parameter("native_gain",1.0 if v.passage_visible else 0.0)
		m.set_shader_parameter("passage_fraction",v.passage_age/config.presentation.passage_seconds if v.passage_visible else -1.0);m.set_shader_parameter("first_sent",v.first_sent);m.set_shader_parameter("second_sent",v.second_sent)
	for m in [source_material]+core_materials+fragment_materials:m.set_shader_parameter("cosmetic_clock",native.ambient_clock);m.set_shader_parameter("light_off",light_off)
	for m in fragment_materials:m.set_shader_parameter("state_mode",1);m.set_shader_parameter("native_gain",config.presentation.claim_gain)
	claim_root.visible=v.raw_claim>0;pocket_root.visible=v.mineral_owned>0
	var fraction:float=1.0 if v.at_landing else 0.0
	if v.moving:fraction+=v.progress*(-1.0 if v.at_landing else 1.0)
	basket.position=drum_at.lerp(landing_at,fraction)+Vector3.UP*1.25
	for i in 8:bricks_root.get_child(i).visible=v.bricks>i
	for i in 2:
		markers[i].visible=v.passage_visible and (v.first_sent if i==0 else v.second_sent) and not light_off
		if markers[i].visible:markers[i].position=(post_at+Vector3.UP*1.18).lerp((drum_at+Vector3.UP*1.7) if i==0 else (feeder_at+Vector3.UP*1.45),clampf(v.passage_age/config.presentation.passage_seconds,0,1))
	label.text="SOURCE  %s · %d/%d lots · %d resin + %d rare held     PACK  %d Green Resin\nJUNCTION  %d received · %s     BLUE  %s\nWINCH  %d winding · %d wood · %s     FEEDER  %d winding · %d clay + %d fuel held · %d bricks · %s"%[v.source_state,v.lot,v.lots,v.raw_claim,v.rare_claim,v.mineral_owned,v.pulses,"request dividing" if v.passage_visible else "idle",("holding %.2f/%.1fs"%[v.blue_elapsed,v.delay_total]) if v.blue_pending else "idle",v.energy,v.cargo,"travelling %.0f%%"%(v.progress*100) if v.moving else ("at landing" if v.at_landing else "at drum"),v.feeder_energy,v.clay_escrow,v.fuel_escrow,v.bricks,"firing %.1f/%.0fs"%[v.feeder_progress,v.feeder_duration] if v.feeder_working else "idle"]
	message_label.text=native.message;phase_label.text="ISOLATED REVIEW · %s · %s · %s detail · no bloom"%["shade" if shade else "day","emission off" if light_off else "native-state light",lod]
	sun.light_energy=.28 if shade else 1.6;environment.ambient_light_energy=.45 if shade else .75
func _process(delta: float) -> void:
	if not hold_simulation:refresh_physics();native.tick(delta)
	refresh()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1:set_shot("source")
		KEY_2:set_shot("post")
		KEY_3:set_shot("overview")
		KEY_4:set_shot("fragments")
		KEY_5:set_shot("feeder")
		KEY_D:shade=not shade
		KEY_G:light_off=not light_off
		KEY_N:set_lod("near")
		KEY_M:set_lod("mid")
		KEY_F:set_lod("far")
		KEY_U:set_wall(walls.upstream,not walls.upstream.visible)
		KEY_J:set_wall(walls.first,not walls.first.visible)
		KEY_K:set_wall(walls.second,not walls.second.visible)
		KEY_C:set_wall(walls.cargo,not walls.cargo.visible)
		KEY_V:set_wall(walls.feeder,not walls.feeder.visible)
		KEY_SPACE:native.paused=not native.paused
		KEY_A:native.active=not native.active
		KEY_R:native.load_checkpoint("res://paid-checkpoint.json")
		KEY_ESCAPE:get_tree().quit()
func capture(name_: String) -> void:
	refresh();await get_tree().process_frame;await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(evidence_directory+"/"+name_+".png")
	var v:Dictionary=native.view();telemetry.append({"file":name_+".png","view":v,"shot":shot,"lod":lod,"light_off":light_off,"shade":shade})
	check(claim_root.visible==(v.raw_claim>0),"claim ownership visibility");check(pocket_root.visible==(v.mineral_owned>0),"carried ownership visibility")
	check(int(source_material.get_shader_parameter("state_mode"))==(2 if v.source_ready else 0),"native source state owns light")
	for m in core_materials:check(int(m.get_shader_parameter("state_mode"))==(3 if v.passage_visible else 0),"native passage owns each core")
	for i in 2:check(markers[i].visible==(v.passage_visible and (v.first_sent if i==0 else v.second_sent) and not light_off),"each actual signal owns marker")
func wall_state(name_: String,enabled: bool) -> void:
	set_wall(walls[name_],enabled);await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
func capture_proof() -> void:
	await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
	check(native.input_clear and native.blue_output_clear and native.first_clear and native.second_clear and native.cargo_clear and native.feeder_clear,"actual native route rays and basket sweep clear")
	floor_body.collision_layer=0;await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
	check(not native.feeder_clear and not native.cargo_clear,"lost actual support blocks both receivers")
	floor_body.collision_layer=1;await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
	check(native.feeder_clear and native.cargo_clear,"restored actual ground supports receivers")
	check(bound_count(source_root,source_material)==1,"actual source shader bound")
	for i in 3:check(bound_count(post_root,core_materials[i])==1 and bound_count(pocket_root,fragment_materials[i])==1,"three independent real resin atlases bound")
	native.ambient_clock=1.8;await capture("source-ready");light_off=true;await capture("source-no-glow");light_off=false;shade=true;await capture("source-shade");shade=false
	for i in 4:check(native.act("work").ok,"real manual extraction");await capture("source-step-%d"%(i+1))
	check(native.view().raw_claim==16,"real lot source-owned");await capture("source-claim");check(native.act("collect").moved==16,"real collection");set_shot("fragments");await capture("green-resin")
	set_shot("post");shade=true;await capture("junction-restored-idle")
	await wall_state("upstream",true);check(not native.blue_output_clear,"real upstream obstruction");native.tick(5)
	check(native.view().blue_elapsed==.5 and not native.view().passage_visible,"blocked upstream holds without Green replay");await capture("upstream-blocked");await wall_state("upstream",false)
	# Fixed-step clip is the real native timeline: held Blue, branch, paid receivers.
	for i in 96:
		if i==32:set_shot("overview")
		if i==64:set_shot("feeder")
		await capture("request-%02d"%i);native.tick(.125)
	check(native.view().trips==5 and native.view().at_landing and native.view().bricks==8 and native.view().cycles==2,"both paid jobs finish exactly once")
	await capture("feeder-complete");set_shot("overview");await capture("workshop-overview");set_shot("post");await capture("junction-idle")
	check(native.act("cargo").moved==10 and native.act("bricks").moved==8,"real outputs transferred once")
	# Rendered branches distinguish clear signal from receiver's willingness to work.
	check(native.act("request").ok,"ask both unwound receivers");native.tick(3.01);native.tick(.6)
	check(native.view().first_sent and native.view().second_sent and not native.view().first_started and not native.view().second_started,"clear request does not invent work")
	await capture("junction-unwound");light_off=true;await capture("junction-unwound-no-glow");light_off=false
	native.paused=true;native.tick(3);await capture("junction-passage-paused");native.paused=false
	for branch in ["first","second","cargo","feeder"]:
		native.load_checkpoint("res://paid-checkpoint.json");await wall_state(branch,true)
		check(not bool(native.get(branch+"_clear")),"physical branch or receiver obstruction: "+branch)
		native.tick(2.51);native.tick(.6);await capture("junction-"+branch+"-blocked")
		check(native.view().first_started==(branch not in ["first","cargo"]) and native.view().second_started==(branch not in ["second","feeder"]),"only clear paid receiver starts: "+branch)
		await wall_state(branch,false);native.tick(12)
		check(native.view().trips==(4 if branch in ["first","cargo"] else 5) and native.view().bricks==(4 if branch in ["second","feeder"] else 8),"clearing wall does not replay refused work")
	# An obstruction appearing after payment must hold exact escrow and cargo.
	native.load_checkpoint("res://paid-checkpoint.json");native.tick(2.51);native.tick(1.25)
	await wall_state("cargo",true);await wall_state("feeder",true);var held:String=native.sim.contraption_save();native.tick(10)
	check(native.sim.contraption_save()==held,"physical blockage holds paid jobs exactly");set_shot("overview");await capture("paid-work-blocked")
	await wall_state("cargo",false);await wall_state("feeder",false);native.tick(10)
	check(native.view().trips==5 and native.view().bricks==8,"same paid jobs resume once")
	for level in ["near","mid","far"]:
		set_lod(level)
		for view_name in ["source","post"]:
			set_shot(view_name)
			for shadow in [false,true]:shade=shadow;await capture(view_name+"-"+level+("-shade" if shade else "-day"))
	set_lod("near");set_shot("source");shade=false;native.load_checkpoint("res://paid-checkpoint.json")
	var rare_found:=false
	for lot in 7:
		for step in 4:check(native.act("work").ok,"actual remaining source extraction")
		check(native.act("collect").moved==16,"actual source lot transfer")
		if native.view().rare_claim>0:
			rare_found=true;check(native.view().raw_claim==0 and not native.view().source_ready,"rare-only claim remains exposed");await capture("source-rare-held");native.act("rare")
	check(rare_found and native.view().mineral_owned==126 and not native.view().source_ready,"actual finite stock and rare stream");await capture("source-spent")
	FileAccess.open(evidence_directory+"/visual-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":visual_checks,"failures":[],"captures":telemetry,"renderer":RenderingServer.get_current_rendering_method()},"\t"))
	print("GREEN_VISUAL_CHECKS ",visual_checks);get_tree().quit()
