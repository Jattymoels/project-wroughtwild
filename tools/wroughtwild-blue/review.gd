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
var source_material: ShaderMaterial
var post_material: ShaderMaterial
var fragment_materials: Array[ShaderMaterial]=[]
var label: Label
var message_label: Label
var phase_label: Label
var signal_wall: StaticBody3D
var cargo_wall: StaticBody3D
var pulse: MeshInstance3D
var source_body: StaticBody3D
var post_body: StaticBody3D
var drum_body: StaticBody3D
var landing_body: StaticBody3D
var lever_body: StaticBody3D
var white_body: StaticBody3D
var shot := "source"
var lod := "near"
var light_off := false
var shade := false
var hold_simulation := false
var telemetry: Array[Dictionary]=[]
var visual_checks := 0
var evidence_directory := "res://evidence"
var source_at := Vector3(-2.8,0,2.8)
var post_at := Vector3.ZERO
# Preserve the actual paid checkpoint's relative fixture positions and spans.
var white_at := Vector3(-4,0,1)
var lever_at := Vector3(-8,0,0)
var drum_at := Vector3(-4,0,-4)
var landing_at := Vector3(10,0,-4)
func _ready() -> void:
	if "--compatibility-proof" in OS.get_cmdline_user_args(): evidence_directory="res://evidence-compat"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(evidence_directory))
	config=JSON.parse_string(FileAccess.get_file_as_string("res://blue.json"))
	native=Adapter.new();native.release_duration=config.presentation.release_seconds
	source_material=scar_material();post_material=scar_material()
	for i in 3:fragment_materials.append(scar_material("fragment-%d"%(i+1)))
	build_setting();build_assets();build_ui();set_shot("source")
	if "--capture" in OS.get_cmdline_user_args():hold_simulation=true;call_deferred("capture_proof")
	elif "--benchmark" in OS.get_cmdline_user_args():hold_simulation=true;call_deferred("benchmark")
func scar_material(prefix_: String="blue") -> ShaderMaterial:
	var m:=ShaderMaterial.new();m.shader=load("res://blue_scar.gdshader")
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
func apply_mineral(node: Node,material: ShaderMaterial) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var previous:Material=node.get_active_material(i)
			if previous!=null and (previous.resource_name.begins_with("BLUE_MINERAL") or previous.resource_name.begins_with("BLUE_FRAGMENT") or previous.resource_name.begins_with("WHITE_MINERAL")):node.set_surface_override_material(i,material)
	for child in node.get_children():apply_mineral(child,material)
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
	box(self,Vector3(4,-.09,0),Vector3(36,.18,26),ground)
	for at in [Vector3(-6,0,-5),Vector3(2,0,-10),Vector3(11,0,-11),Vector3(17,0,-7)]:
		var tree:=scene_at("context/quiet-tree.glb",at);tree.rotation.y=at.x*.72;scene_at("context/canopy-far.glb",Vector3.ZERO,tree)
	var timber:=pbr(Color("66503a"));box(self,Vector3(-1.1,.62,1.5),Vector3(1.05,.07,.70),timber)
	for x in [-1.50,-.70]:
		for z in [1.25,1.75]:box(self,Vector3(x,.30,z),Vector3(.075,.60,.075),timber)
	camera=Camera3D.new();camera.fov=config.presentation.camera_fov;add_child(camera);camera.current=true
func build_assets() -> void:
	source_root=scene_at("blue-source-"+lod+".glb",source_at);apply_mineral(source_root,source_material);source_body=body(source_at,Vector3(1.5,1.1,1.5),"SourceBody")
	post_root=scene_at("blue-post-"+lod+".glb",post_at);apply_mineral(post_root,post_material);post_body=body(post_at,Vector3(.65,1.18,.55),"PostBody")
	claim_root=Node3D.new();add_child(claim_root);claim_root.position=source_at
	pocket_root=Node3D.new();add_child(pocket_root);pocket_root.position=Vector3(-1.1,.657,1.5)
	for i in 3:
		var c:=scene_at("blue-fragment-%d.glb"%(i+1),Vector3(-.28+i*.24,.002,.66),claim_root);c.scale=Vector3.ONE*.55;c.rotation.y=i*.7;apply_mineral(c,fragment_materials[i])
		var p:=scene_at("blue-fragment-%d.glb"%(i+1),Vector3(-.28+i*.27,0,.03-abs(i-1)*.05),pocket_root);p.rotation.y=i*.6;apply_mineral(p,fragment_materials[i])
	var white_context:=scene_at("context/white-post.glb",white_at)
	var white_surface:=scar_material("context/white");white_surface.set_shader_parameter("core_colour",Color("fff5ca"));apply_mineral(white_context,white_surface)
	white_body=body(white_at,Vector3(.65,1.18,.55),"WhiteBody")
	var winch:=scene_at("context/strange_winch.glb",Vector3.ZERO);fit(winch,Vector3(1.4,1.83,1.15));winch.position+=drum_at
	var landing:=scene_at("context/strange_winch.glb",Vector3.ZERO);fit(landing,Vector3(1.4,1.83,1.15));landing.position+=landing_at
	var lever:=scene_at("context/strange_lever.glb",Vector3.ZERO);fit(lever,Vector3(.65,.95,.5));lever.position+=lever_at
	drum_body=body(drum_at,Vector3(1.4,1.83,1.15),"DrumBody");landing_body=body(landing_at,Vector3(1.4,1.83,1.15),"LandingBody");lever_body=body(lever_at,Vector3(.65,.95,.5),"LeverBody")
	basket=scene_at("context/strange_basket.glb",Vector3.ZERO);fit(basket,Vector3(.56,.38,.50))
	var cable:=pbr(Color("8b8973"),.65,.3)
	pipe(lever_at+Vector3.UP*.95,white_at+Vector3.UP*1.18,.012,cable)
	pipe(white_at+Vector3.UP*1.18,post_at+Vector3.UP*1.18,.012,cable)
	pipe(post_at+Vector3.UP*1.18,drum_at+Vector3.UP*1.7,.012,cable)
	pipe(drum_at+Vector3.UP*1.7,landing_at+Vector3.UP*1.7,.014,cable)
	pulse=box(self,Vector3.ZERO,Vector3(.06,.06,.06),pbr(Color("fff1c9")));pulse.visible=false
	signal_wall=body(post_at.lerp(drum_at,.5),Vector3(.45,1.9,.35),"SignalObstruction");box(signal_wall,Vector3(0,.95,0),Vector3(.45,1.9,.35),pbr(Color("545a50")))
	cargo_wall=body(drum_at.lerp(landing_at,.5),Vector3(.45,2.1,.7),"CargoObstruction");box(cargo_wall,Vector3(0,1.05,0),Vector3(.45,2.1,.7),pbr(Color("545a50")))
	set_wall(signal_wall,false);set_wall(cargo_wall,false)
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
func refresh_physics() -> void:
	native.input_clear=physical_clear(lever_at+Vector3.UP*.95,white_at+Vector3.UP*1.18,[lever_body.get_rid(),white_body.get_rid()]) and physical_clear(white_at+Vector3.UP*1.18,post_at+Vector3.UP*1.18,[white_body.get_rid(),post_body.get_rid()])
	native.signal_clear=physical_clear(post_at+Vector3.UP*1.18,drum_at+Vector3.UP*1.7,[post_body.get_rid(),drum_body.get_rid()])
	# Sweep the actual existing 0.3 m basket-clearance volume along its span.
	var shape:=SphereShape3D.new();shape.radius=.3
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=drum_at+Vector3.UP*1.7;query.motion=landing_at-drum_at;query.exclude=[drum_body.get_rid(),landing_body.get_rid()]
	var sweep:=get_world_3d().direct_space_state.cast_motion(query);native.cargo_clear=sweep[0]>=1.0
func build_ui() -> void:
	var layer:=CanvasLayer.new();add_child(layer)
	var panel:=PanelContainer.new();panel.position=Vector2(28,24);layer.add_child(panel)
	var title:=Label.new();title.text="BLUE / RETENTION\nLayered fracture → recovered flakes → one held request";title.add_theme_font_size_override("font_size",23);panel.add_child(title)
	phase_label=Label.new();phase_label.position=Vector2(30,92);phase_label.add_theme_font_size_override("font_size",16);layer.add_child(phase_label)
	var bottom:=PanelContainer.new();bottom.position=Vector2(28,802);bottom.size=Vector2(1544,170);layer.add_child(bottom)
	var column:=VBoxContainer.new();bottom.add_child(column)
	label=Label.new();label.add_theme_font_size_override("font_size",21);column.add_child(label)
	message_label=Label.new();message_label.add_theme_font_size_override("font_size",17);column.add_child(message_label)
	var row:=HBoxContainer.new();column.add_child(row)
	for pair in [["Work source","work"],["Collect flakes","collect"],["Collect rare","rare"],["Wind drum","wind"],["Send request","request"],["Collect cargo","cargo"],["Load 10 wood","load"],["Hold","pause"],["Resume","resume"],["Cancel","cancel"],["Disconnect","disconnect"],["Connect","connect"]]:
		var button:=Button.new();button.text=pair[0];button.pressed.connect(act.bind(pair[1]));row.add_child(button)
	var help:=Label.new();help.text="1 Source   2 Delay   3 Whole route   4 Fragments    D Day/shade   G Glow off   N/M/F Detail    S Block signal   C Block cargo   Space Review pause   A Active/away   R Reset   Esc Close";help.add_theme_font_size_override("font_size",15);column.add_child(help)
func act(action: String) -> void:
	refresh_physics();native.act(action);refresh()
func set_shot(name_: String) -> void:
	shot=name_
	var target:=source_at+Vector3(0,.43,0);var offset:=Vector3(2.4,1.7,3.3)
	if shot=="post":target=post_at+Vector3(0,.66,0);offset=Vector3(1.65,1.0,2.5)
	elif shot=="fragments":target=pocket_root.position+Vector3(0,.12,0);offset=Vector3(1.3,.9,1.8)
	elif shot=="overview":target=Vector3(4,.55,-2.8);offset=Vector3(11,9,17)
	camera.position=target+offset;camera.look_at(target)
func set_lod(value: String) -> void:
	lod=value;source_root.free();post_root.free()
	source_root=scene_at("blue-source-"+lod+".glb",source_at);apply_mineral(source_root,source_material)
	post_root=scene_at("blue-post-"+lod+".glb",post_at);apply_mineral(post_root,post_material)
func refresh() -> void:
	var v:Dictionary=native.view()
	var source_gain:float=config.presentation.source_work_gain if v.source_work>0 else config.presentation.source_ready_gain
	source_material.set_shader_parameter("state_mode",2 if v.source_ready else 0);source_material.set_shader_parameter("native_gain",source_gain if v.source_ready else 0.0)
	post_material.set_shader_parameter("state_mode",3 if v.pending else (4 if v.release_visible else 0));post_material.set_shader_parameter("native_gain",1.0 if v.pending or v.release_visible else 0.0)
	post_material.set_shader_parameter("request_fraction",v.delay_seconds/v.delay_total)
	post_material.set_shader_parameter("release_fraction",v.release_age/config.presentation.release_seconds if v.release_visible else -1.0)
	for m in [source_material,post_material]+fragment_materials:m.set_shader_parameter("cosmetic_clock",native.ambient_clock);m.set_shader_parameter("light_off",light_off)
	for m in fragment_materials:m.set_shader_parameter("state_mode",1);m.set_shader_parameter("native_gain",config.presentation.claim_gain)
	claim_root.visible=v.raw_claim>0;pocket_root.visible=v.mineral_owned>0
	var fraction:float=1.0 if v.at_landing else 0.0
	if v.moving:fraction+=v.progress*(-1.0 if v.at_landing else 1.0)
	basket.position=drum_at.lerp(landing_at,fraction)+Vector3.UP*1.25
	pulse.visible=v.release_visible and not light_off
	if pulse.visible:pulse.position=(post_at+Vector3.UP*1.18).lerp(drum_at+Vector3.UP*1.7,clampf(v.release_age/config.presentation.release_seconds,0,1))
	var held_text:="Holding %.2f / %.1f s%s"%[v.delay_seconds,v.delay_total," · PAUSED" if v.delay_paused or not v.signal_clear or not v.active else ""] if v.pending else ("Released once" if v.release_visible else "Idle")
	label.text="SOURCE  %s · %d / %d lots · %d flakes + %d rare held     PACK  %d Blue Flakes\nDELAY  %s · %d accepted     DRUM  %d winding · %d wood · %s"%[v.source_state,v.lot,v.lots,v.raw_claim,v.rare_claim,v.mineral_owned,held_text,v.pulses,v.energy,v.cargo,"Travelling %.0f%%"%(v.progress*100) if v.moving else ("At landing" if v.at_landing else "At drum")]
	message_label.text=native.message
	phase_label.text="ISOLATED REVIEW · %s · %s · %s detail · no bloom"%["shade" if shade else "day","emission off" if light_off else "native-state light",lod]
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
		KEY_D:shade=not shade
		KEY_G:light_off=not light_off
		KEY_N:set_lod("near")
		KEY_M:set_lod("mid")
		KEY_F:set_lod("far")
		KEY_S:set_wall(signal_wall,not signal_wall.visible)
		KEY_C:set_wall(cargo_wall,not cargo_wall.visible)
		KEY_SPACE:native.paused=not native.paused
		KEY_A:native.active=not native.active
		KEY_R:native.load_checkpoint("res://paid-checkpoint.json");native.message="Reset to the copied paid checkpoint."
		KEY_ESCAPE:get_tree().quit()
func check(value: bool,description: String) -> void:
	visual_checks+=1;assert(value,description)
func capture(name_: String) -> void:
	refresh();await get_tree().process_frame;await RenderingServer.frame_post_draw
	var image:=get_viewport().get_texture().get_image();image.save_png(evidence_directory+"/"+name_+".png")
	var v:Dictionary=native.view();telemetry.append({"file":name_+".png","view":v,"shot":shot,"lod":lod,"light_off":light_off,"shade":shade})
	check(claim_root.visible==(v.raw_claim>0),"claim visibility follows ownership")
	check(pocket_root.visible==(v.mineral_owned>0),"carried display follows ownership")
	check(int(source_material.get_shader_parameter("state_mode"))==(2 if v.source_ready else 0),"source readiness owns light")
	check(int(post_material.get_shader_parameter("state_mode"))==(3 if v.pending else (4 if v.release_visible else 0)),"native held/release state owns delay light")
	check(pulse.visible==(v.release_visible and not light_off),"signal marker follows actual request")
func capture_proof() -> void:
	await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
	check(native.input_clear and native.signal_clear and native.cargo_clear,"actual three signal rays and basket sweep clear")
	check(native.view().pending and not native.view().release_visible,"restore shows held request without replaying release")
	check(bound_count(source_root,source_material)==1 and bound_count(post_root,post_material)==1,"actual imported surfaces receive shader")
	for i in 3:check(bound_count(pocket_root,fragment_materials[i])==1,"actual fragment shader bound")
	native.ambient_clock=1.8
	await capture("source-ready");light_off=true;await capture("source-no-glow");light_off=false
	shade=true;await capture("source-shade");shade=false
	for i in 4:check(native.act("work").ok,"real manual extraction");await capture("source-step-%d"%(i+1))
	check(native.view().raw_claim==16,"released lot source owned");await capture("source-claim")
	check(native.act("collect").moved==16,"native collection");set_shot("fragments");await capture("blue-flakes")
	set_shot("post");shade=true;await capture("delay-held")
	light_off=true;await capture("delay-held-no-glow");light_off=false
	check(native.act("pause").ok,"actual explicit pause");var held:Dictionary=native.view();native.tick(2)
	check(native.view().delay_seconds==held.delay_seconds and native.view().energy==held.energy,"explicit pause preserves countdown and drive");await capture("delay-paused")
	check(native.act("resume").ok,"actual resume")
	set_wall(signal_wall,true);await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
	check(not native.signal_clear,"physical output obstruction")
	held=native.view();native.tick(5)
	check(native.view().pending and native.view().delay_seconds==held.delay_seconds and native.view().energy==1,"blocked output freezes native held request");await capture("delay-signal-blocked")
	set_wall(signal_wall,false);await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
	check(native.act("cancel").ok and not native.view().pending and not native.view().release_visible,"cancel has no release light");await capture("delay-cancelled")
	check(native.act("request").ok,"accept one new request with existing paid winding")
	for i in 64:
		await capture("request-%02d"%i);native.tick(.125)
	check(not native.view().pending and not native.view().moving and native.view().at_landing and native.view().trips==3,"single paid outbound arrival")
	await capture("delay-idle")
	check(native.act("cargo").moved==10,"collect original ten wood once")
	check(native.act("request").ok,"unwound receiver accepts delay")
	native.tick(3.01);check(native.view().release_visible and not native.view().moving and native.view().energy==0,"unwound expiry releases without creating motion");await capture("delay-unwound-release")
	native.paused=true;var age:float=native.release_age;native.tick(3)
	check(native.release_age==age,"review pause freezes transient");await capture("delay-release-paused");native.paused=false
	native.tick(1);check(native.act("wind").ok,"new paid winding");native.tick(4)
	check(not native.view().moving and native.view().energy==1,"later winding never replays failed release")
	check(native.act("request").ok,"new request for cargo obstruction")
	set_wall(cargo_wall,true);await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
	check(not native.cargo_clear,"actual basket sweep blocked")
	native.tick(3.01);check(not native.view().pending and not native.view().moving and native.view().energy==1,"blocked cargo consumes request without paying drive");set_shot("overview");await capture("cargo-blocked")
	set_wall(cargo_wall,false);await get_tree().physics_frame;await get_tree().physics_frame;refresh_physics()
	native.tick(1);await capture("workshop-overview")
	for level in ["near","mid","far"]:
		set_lod(level)
		for view_name in ["source","post"]:
			set_shot(view_name)
			for shadow in [false,true]:
				shade=shadow;light_off=false;await capture(view_name+"-"+level+("-shade" if shade else "-day"))
	set_lod("near");set_shot("source");shade=false
	for lot in 6:
		for step in 4:check(native.act("work").ok,"exhaust existing native source")
		check(native.act("collect").moved==16,"collect existing source lot")
	check(not native.view().source_ready and native.view().mineral_owned==126,"actual native source exhaustion");await capture("source-spent")
	# Separate labelled rare-claim coverage; consume carried test flakes to make
	# room while advancing the actual fixed stream. No grant or outcome rewrite.
	var rare_found:=false
	for lot in 160:
		if native.view().mineral_owned>0:native.sim.consume_material("blue_flake",native.view().mineral_owned)
		if native.view().lot==native.view().lots:native.tick(600)
		for step in 4:native.act("work")
		if native.view().rare_claim>0:
			rare_found=true;check(native.act("collect").moved==16,"rare proof collects real raw claim")
			check(native.view().raw_claim==0 and native.view().rare_claim==1 and not native.view().source_ready,"rare-only claim remains exposed by review")
			native.message="Accelerated rare-claim check: test flakes consumed for capacity; native outcome unchanged."
			await capture("source-rare-held");break
		native.act("collect")
	check(rare_found,"fixed Blue stream reaches rare-only review")
	FileAccess.open(evidence_directory+"/visual-checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":visual_checks,"failures":[],"captures":telemetry,"renderer":RenderingServer.get_current_rendering_method()},"\t"))
	print("BLUE_VISUAL_CHECKS ",visual_checks);get_tree().quit()
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
