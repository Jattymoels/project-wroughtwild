extends Node3D
## Isolated model display; posed stock/heat views do not grant gameplay ownership.
var cfg:Dictionary
var entries:Array=[]
var mats:Array[ShaderMaterial]=[]
var camera:Camera3D
var sun:DirectionalLight3D
var env:Environment
var label:Label
var paused:=false
var automatic:=false
var clock_seconds:=0.0
var light_on:=true
var clay:=false
var force_lod:=0
var mood:=0
var output:String
var selected:=-1
func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://c5/kit.json"));output="res://c5/evidence/"+RenderingServer.get_current_rendering_method();DirAccess.make_dir_recursive_absolute(output)
	for i in cfg.ores.size():
		var row:Dictionary=cfg.ores[i]
		for state in 3:
			var units:int=row.units if state==0 else (int(row.units)-2 if state==1 else 2);var crack:bool=state==2 and i>0
			var entry:={"id":row.id,"i":i,"state":state,"levels":[]}
			var root:=Node3D.new();add_child(root);root.position=Vector3((i-2)*2.9,0,-state*1.55);entry.root=root
			for lod in 3:
				var model:Node3D=load("res://c5/assets/%s-u%d-%s-lod%d.gltf"%[row.id,units,"cracked" if crack else "cold",lod]).instantiate();root.add_child(model);entry.levels.append(model)
				var mm:Array=preload("res://c5/materials.gd").apply(model,row);mats.append_array(mm)
				for mat in mm:
					mat.set_shader_parameter("tint",Vector3(.55,.5,.5) if crack else Vector3.ONE)
					mat.set_meta("ember_preview",i==3 and state==0)
			entries.append(entry)
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(60,60);floor.position.y=-.025;var fm:=StandardMaterial3D.new();fm.albedo_color=Color(.23,.24,.21);fm.roughness=1;floor.material_override=fm;add_child(floor)
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world);env.background_mode=Environment.BG_COLOR;env.background_color=Color(.26,.30,.33);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.8,.88,1);env.glow_enabled=false;env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-30,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=45;add_child(sun)
	camera=Camera3D.new();add_child(camera);camera.fov=55;camera.make_current();overview();get_viewport().msaa_3d=Viewport.MSAA_4X;DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(20,18);label.add_theme_font_size_override("font_size",18)
	lighting(0);set_time(0)
	var args:=OS.get_cmdline_user_args()
	if "--capture" in args:automatic=true;await capture();get_tree().quit()
	elif "--benchmark" in args:automatic=true;await benchmark();get_tree().quit()
func overview()->void:
	selected=-1;camera.position=Vector3(0,8,11);camera.look_at(Vector3(0,.15,-1.4))
func focus(i:int)->void:
	selected=i;var x:float=(i-2)*2.9;camera.position=Vector3(x+1.7,1.65,2.1);camera.look_at(Vector3(x,.20,-.8))
func lighting(i:int)->void:
	mood=i;sun.light_energy=[1.8,.28,.45][i];sun.light_color=[Color(1,.94,.85),Color(.7,.83,1),Color(1,.64,.35)][i];env.ambient_light_energy=[.8,.55,.32][i]
	label.text="ART-07C5 | "+["DAY","SHADE","DUSK"][i]+" | "+RenderingServer.get_current_rendering_method()+"\nIron / Copper / Tin / Ember-Iron / Silver • full, worked, final/cracked rows • source study\nWASD/QE flight • L lighting • C clay • M light • H posed heat • Space pause • 0–3 LOD • R overview"
func set_time(value:float)->void:
	clock_seconds=value
	for mat in mats:mat.set_shader_parameter("clock_seconds",value);mat.set_shader_parameter("light_enabled",light_on);mat.set_shader_parameter("clay",clay)
func pose_heat(on:bool)->void:
	for mat in mats:
		var active:bool=on and mat.get_meta("ember_preview",false)
		mat.set_shader_parameter("heat_active",active);mat.set_shader_parameter("state_emission",Vector3(1.2,.48,.06) if active else Vector3.ZERO)
func _process(delta:float)->void:
	if not paused and not automatic:set_time(clock_seconds+delta)
	if not automatic and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		var move:=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		camera.position+=camera.basis*move*delta*4
	for e in entries:
		e.root.visible=selected<0 or selected==e.i
		var d:=camera.position.distance_to(e.root.position);var lod:=force_lod if force_lod>=0 else (0 if d<cfg.lod_distances_m[0] else (1 if d<cfg.lod_distances_m[1] else 2))
		for i in 3:e.levels[i].visible=i==lod
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventMouseButton and event.pressed:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:camera.rotation.y-=event.relative.x*.003;camera.rotation.x=clampf(camera.rotation.x-event.relative.y*.003,-1.5,1.5)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			KEY_SPACE:paused=not paused
			KEY_L:lighting((mood+1)%3)
			KEY_C:clay=not clay;set_time(clock_seconds)
			KEY_M:light_on=not light_on;set_time(clock_seconds)
			KEY_H:pose_heat(not bool(mats[0].get_meta("posed",false)));mats[0].set_meta("posed",not bool(mats[0].get_meta("posed",false)))
			KEY_R:overview()
			KEY_0:force_lod=-1
			KEY_1:force_lod=0
			KEY_2:force_lod=1
			KEY_3:force_lod=2
func shot(name:String)->void:
	for i in 3:await get_tree().process_frame
	await RenderingServer.frame_post_draw;assert(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK)
func capture()->void:
	for i in 3:lighting(i);await shot(["day","shade","dusk"][i])
	lighting(0)
	for i in 5:
		focus(i);clay=false;set_time(0);await shot(cfg.ores[i].id+"-material")
		clay=true;set_time(0);await shot(cfg.ores[i].id+"-clay")
	clay=false;focus(3);lighting(1);light_on=false;set_time(0);await shot("scar-off")
	light_on=true;pose_heat(true)
	for i in 42:set_time(i/12.0);await shot("heat-motion-%03d"%i)
	automatic=false
	var pause_event:=InputEventKey.new();pause_event.physical_keycode=KEY_SPACE;pause_event.pressed=true;_unhandled_input(pause_event)
	var held:=clock_seconds
	for i in 3:await shot("paused-%d"%i)
	assert(paused and clock_seconds==held)
	_unhandled_input(pause_event)
	for i in 5:await get_tree().process_frame
	assert(not paused and clock_seconds>held);automatic=true
	pose_heat(false);overview();lighting(0)
	for lod in 3:force_lod=lod;await shot("lod-%d"%lod)
	var f:=FileAccess.open(output+"/capture.json",FileAccess.WRITE);f.store_string(JSON.stringify({"models":15,"textures_shared":2,"collision_objects":find_children("*","CollisionObject3D",true,false).size(),"scope":"Posed source study. Native flow is captured separately. Heat preview is explicit, not free stock/work."},"\t"));print("C5_CAPTURE_OK")
func benchmark()->void:
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true);label.hide();var cases:Array=[]
	for lod in [0,1,2]:
		force_lod=lod;overview();lighting(0);label.hide()
		for i in 120:await get_tree().process_frame
		var wall:Array=[];var gpu:Array=[]
		for i in 600:
			var start:=Time.get_ticks_usec();await RenderingServer.frame_post_draw;gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()));await get_tree().process_frame;wall.append((Time.get_ticks_usec()-start)/1000.0)
		wall.sort();gpu.sort();cases.append({"lod":lod,"wall_p50_ms":wall[300],"wall_p95_ms":wall[570],"wall_worst_ms":wall[-1],"gpu_p50_ms":gpu[300],"gpu_p95_ms":gpu[570],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	var f:=FileAccess.open(output+"/benchmark.json",FileAccess.WRITE);f.store_string(JSON.stringify({"device":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"cases":cases,"settings":"1440x900, MSAA4, shadows on, VSync off, 120 warmup and 600 samples each, fixed view","scope":"15 source specimens, not an ordinary habitat or lower-spec approval."},"\t"));print("C5_BENCHMARK_OK")
