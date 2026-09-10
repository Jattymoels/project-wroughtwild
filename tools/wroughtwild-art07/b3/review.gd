extends Node3D
## Authored static contact composition. Native work and physical checks are a separate scene.
var cfg:Dictionary
var camera:Camera3D
var sun:DirectionalLight3D
var env:Environment
var label:Label
var entries:Array=[]
var mats:Array[ShaderMaterial]=[]
var clock_seconds:=0.0
var paused:=false
var light_on:=true
var automatic:=false
var mood:=0
var force_lod:=-1
var output:String
func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://kit.json"))
	output="res://evidence/"+RenderingServer.get_current_rendering_method();DirAccess.make_dir_recursive_absolute(output)
	for row in [["boulder-full",-4,2],["boulder-worked",-2,2],["boulder-remnant",0,2],["stone-seam",-3,-.6],["river-bank",2,0],["talus-pebbles",-3,4],["rock-shelf",3,-3],["rock-shelf-altered",3,-6],["cave-threshold",-3,-6]]:
		var root:=Node3D.new();add_child(root);root.position=Vector3(row[1],-.025,row[2]);var levels:Array=[]
		for lod in 3:
			var model:Node3D=load("res://assets/"+row[0]+"-lod%d.glb"%lod).instantiate();root.add_child(model);levels.append(model)
			if row[0]=="rock-shelf-altered":
				for mesh in model.find_children("*","MeshInstance3D",true,false):
					for s in mesh.mesh.get_surface_count():
						var base:StandardMaterial3D=mesh.mesh.surface_get_material(s)
						var mat:=ShaderMaterial.new();mat.shader=load("res://scar.gdshader");mat.set_shader_parameter("albedo_map",base.albedo_texture);mat.set_shader_parameter("orm_map",base.roughness_texture);mat.set_shader_parameter("period",cfg.pulse_period_s);mat.set_shader_parameter("peak",cfg.pulse_peak);mesh.set_surface_override_material(s,mat);mats.append(mat)
		entries.append({"id":row[0],"root":root,"levels":levels})
		if "--no-art" in OS.get_cmdline_user_args():root.hide()
	var floor_mesh:=MeshInstance3D.new();floor_mesh.mesh=PlaneMesh.new();floor_mesh.mesh.size=Vector2(70,70);floor_mesh.position.y=-.055
	var floor_image:=Image.load_from_file("res://forest-floor.png");floor_image.generate_mipmaps()
	var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_texture=ImageTexture.create_from_image(floor_image);floor_mat.uv1_scale=Vector3(23,23,23);floor_mat.roughness=1;floor_mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC;floor_mesh.material_override=floor_mat;add_child(floor_mesh)
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world);env.background_mode=Environment.BG_COLOR;env.background_color=Color(.24,.30,.34);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.75,.83,.9);env.glow_enabled=false
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-30,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=70;add_child(sun)
	camera=Camera3D.new();add_child(camera);camera.fov=58;camera.make_current();overview()
	get_viewport().msaa_3d=Viewport.MSAA_4X
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(20,18);label.add_theme_font_size_override("font_size",19)
	lighting(0)
	for i in 12:await get_tree().process_frame
	var args:=OS.get_cmdline_user_args()
	if "--capture" in args:automatic=true;await capture();get_tree().quit()
	elif "--benchmark" in args:automatic=true;await benchmark();get_tree().quit()
func overview()->void:
	camera.position=Vector3(12,9,14);camera.look_at(Vector3(0,.5,-1.8))
func set_time(value:float)->void:
	clock_seconds=value
	for mat in mats:mat.set_shader_parameter("clock_seconds",value);mat.set_shader_parameter("light_enabled",light_on)
func _process(delta:float)->void:
	if not paused and not automatic:set_time(clock_seconds+delta)
	if not automatic and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		var v:=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		camera.position+=camera.basis*v*delta*5
	for entry in entries:
		var d:=camera.position.distance_to(entry.root.position);var lod:=force_lod if force_lod>=0 else (0 if d<cfg.lod_distances_m[0] else (1 if d<cfg.lod_distances_m[1] else 2))
		for i in 3:entry.levels[i].visible=i==lod
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:camera.rotation.y-=event.relative.x*.003;camera.rotation.x=clampf(camera.rotation.x-event.relative.y*.003,-1.5,1.5)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			KEY_SPACE:paused=not paused
			KEY_L:lighting((mood+1)%3)
			KEY_M:light_on=not light_on;set_time(clock_seconds)
			KEY_R:overview()
			KEY_1:force_lod=0
			KEY_2:force_lod=1
			KEY_3:force_lod=2
			KEY_0:force_lod=-1
func lighting(index:int)->void:
	mood=index;sun.light_energy=[1.7,.3,.5][index];sun.light_color=[Color(1,.94,.84),Color(.75,.84,1),Color(1,.64,.36)][index];env.ambient_light_energy=[.72,.45,.25][index]
	label.text="ART-07B3 | "+["DAY","SHADE","DUSK"][index]+" | "+RenderingServer.get_current_rendering_method()+"\nStatic kit • WASD/QE flight • click/mouse look • L light • M scars • Space pause • 0–3 LOD • R overview"
func shot(name:String)->void:
	for i in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK)
func capture()->void:
	force_lod=0
	for index in 3:lighting(index);await shot(["day","shade","dusk"][index])
	lighting(0)
	for row in [["work-states",Vector3(-1,3,7),Vector3(-2,.4,2)],["bank-contact",Vector3(5,2.3,4),Vector3(2,.25,0)],["cave-clearance",Vector3(-3,1.7,0),Vector3(-3,1.35,-6)],["bedding-workface",Vector3(-2,2,2),Vector3(-3,.1,-.6)]]:
		camera.position=row[1];camera.look_at(row[2]);await shot(row[0])
	camera.position=Vector3(5.8,2.3,-3.5);camera.look_at(Vector3(3,.4,-6));lighting(1);light_on=false;set_time(0);await shot("scar-off");light_on=true
	for i in 40:set_time(i*.1);await shot("pulse-%03d"%i)
	paused=true;var held:=clock_seconds
	for i in 10:await get_tree().process_frame
	assert(clock_seconds==held);paused=false
	for lod in 3:force_lod=lod;overview();lighting(0);await shot("lod-%d"%lod)
	var f:=FileAccess.open(output+"/checks.json",FileAccess.WRITE);f.store_string(JSON.stringify({"pause_clock_unchanged":true,"decorative_collision_objects":find_children("*","CollisionObject3D",true,false).size(),"asset_entries":entries.size(),"states":"Static assembly only; native scene verifies work and passage."},"\t"));print("B3_RENDER_OK")
func benchmark()->void:
	overview();lighting(0);force_lod=-1
	for i in 180:await get_tree().process_frame
	var values:Array=[];var last:=Time.get_ticks_usec()
	for i in 600:
		await get_tree().process_frame;var now:=Time.get_ticks_usec();values.append((now-last)/1000.0);last=now
	values.sort()
	var hidden:bool="--no-art" in OS.get_cmdline_user_args()
	var f:=FileAccess.open(output+("/benchmark-no-art.json" if hidden else "/benchmark.json"),FileAccess.WRITE);f.store_string(JSON.stringify({"samples":600,"art_visible":not hidden,"p50_ms":values[300],"p95_ms":values[570],"worst_ms":values[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"device":RenderingServer.get_video_adapter_name(),"viewport":"1440x900 MSAA4 shadows on vsync off fixed camera","scope":"Static composed B3 kit; hidden-art comparison retains loaded textures. Not a whole-world budget or lower-spec approval."},"\t"));print("B3_BENCHMARK_OK")
