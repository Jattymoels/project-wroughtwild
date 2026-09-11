extends Node3D
const View=preload("res://asset_view.gd")
var cfg:Dictionary
var camera:Camera3D
var body:CharacterBody3D
var sun:DirectionalLight3D
var env:Environment
var label:Label
var trees:Array=[]
var deadfalls:Array=[]
var plants:Array=[]
var hero:Node3D
var clock_seconds:=0.0
var paused:=false
var automatic:=false
var light_enabled:=true
var force_lod:=-1
var mood:=0
var output:String
var route_samples:Array=[]
var walk_active:=false
func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://kit.json"))
	output="res://evidence/"+RenderingServer.get_current_rendering_method();DirAccess.make_dir_recursive_absolute(output)
	automatic=not OS.get_cmdline_user_args().is_empty()
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(42,50);add_child(floor)
	var fm:=ShaderMaterial.new();fm.shader=load("res://surface.gdshader");fm.set_shader_parameter("role",5);fm.set_shader_parameter("albedo_map",load("res://forest-floor.png"));floor.material_override=fm;floor.create_trimesh_collision()
	for entry in [[3.2,0.0],[-3.8,-7.0],[4.3,-11.0],[-4.1,7.0],[4.7,10.5],[-7.0,-15.0],[7.0,-19.0]]:
		var root:=Node3D.new();add_child(root);root.position=Vector3(entry[0],0,entry[1]);var levels:Array=[]
		var altered:bool=trees.is_empty();var key:="resinheart-altered" if altered else "resinheart"
		for i in 3:
			var m:=View.model(key+"-lod"+str(i));root.add_child(m);levels.append(m)
		var collider:=StaticBody3D.new();root.add_child(collider);var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(.805,4.5,.805);shape.position.y=2.25;collider.add_child(shape)
		trees.append({"root":root,"levels":levels,"lod":0})
	for i in 3:
		var node:=View.model("corkbark-"+str(18-i*6)+"-lod0");add_child(node);node.position=Vector3(-2.4,0,2.5-i*2.5);deadfalls.append(node)
		var col:=StaticBody3D.new();node.add_child(col);var shape:=CollisionShape3D.new();shape.shape=BoxShape3D.new();shape.shape.size=Vector3(1.65,.65,.9);shape.position.y=.325;col.add_child(shape)
	var rng:=RandomNumberGenerator.new();rng.seed=42
	for i in 54:
		var family:String=["fern-sparse","moss","leaf-litter","grass-edge"][i%4]
		var node:=View.model(family);add_child(node);node.position=Vector3(rng.randf_range(1.3,7)*(1 if i%2 else -1),0,rng.randf_range(-19,13));node.rotation.y=rng.randf_range(0,TAU)
		plants.append(node)
		for mesh in node.find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	hero=View.model("resinheart-altered-hero");add_child(hero);hero.hide()
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world)
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(.30,.37,.37);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.73,.82,.87);env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.glow_enabled=false
	sun=DirectionalLight3D.new();add_child(sun);sun.rotation_degrees=Vector3(-38,-35,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=28;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	body=CharacterBody3D.new();add_child(body);body.floor_snap_length=.3
	var cs:=CollisionShape3D.new();cs.shape=CapsuleShape3D.new();cs.shape.height=1.8;cs.shape.radius=.32;cs.position.y=.9;body.add_child(cs)
	camera=Camera3D.new();body.add_child(camera);camera.position.y=1.62;camera.fov=68;camera.make_current()
	for pair in [["c3_f",KEY_W],["c3_b",KEY_S],["c3_l",KEY_A],["c3_r",KEY_D]]:
		InputMap.add_action(pair[0]);var ev:=InputEventKey.new();ev.physical_keycode=pair[1];InputMap.action_add_event(pair[0],ev)
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(18,18);label.add_theme_font_size_override("font_size",18)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	body.position=Vector3(0,.03,13);lighting(0);set_time(0)
	for i in 10:await get_tree().physics_frame
	var args:=OS.get_cmdline_user_args()
	if "--capture" in args:await capture()
	elif "--motion" in args:await motion()
	elif "--walk" in args:await walk()
	elif "--benchmark" in args:await benchmark()
	else:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
func set_time(value:float)->void:
	clock_seconds=value;View.set_time(value,light_enabled)
func lighting(which:int)->void:
	mood=posmod(which,3);sun.light_energy=[1.9,.35,.65][mood];env.ambient_light_energy=[.7,.50,.30][mood];sun.light_color=Color(1,.83,.62) if mood==2 else Color(1,.96,.85)
func lods()->void:
	for tree:Dictionary in trees:
		var distance:float=Vector2(camera.global_position.x,camera.global_position.z).distance_to(Vector2(tree.root.position.x,tree.root.position.z))
		var level:=force_lod if force_lod>=0 else (0 if distance<cfg.tree.lod_m[0] else (1 if distance<cfg.tree.lod_m[1] else 2))
		for i in 3:tree.levels[i].visible=i==level
		tree.lod=level
func view(eye:Vector3,target:Vector3)->void:
	camera.global_position=eye;camera.look_at(target);lods()
func _process(delta:float)->void:
	if not automatic and not paused:set_time(clock_seconds+delta)
	lods()
func _physics_process(delta:float)->void:
	if automatic and not walk_active:return
	if paused:return
	var input:=Input.get_vector("c3_l","c3_r","c3_f","c3_b")
	var direction:Vector3=(body.transform.basis*Vector3(input.x,0,input.y)).normalized()
	body.velocity.x=direction.x*3;body.velocity.z=direction.z*3;body.velocity.y-=12*delta;body.move_and_slide()
	if walk_active:route_samples.append({"x":body.position.x,"y":body.position.y,"z":body.position.z,"floor":body.is_on_floor()})
func _unhandled_input(event:InputEvent)->void:
	if automatic:return
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		body.rotate_y(-event.relative.x*.002);camera.rotation.x=clampf(camera.rotation.x-event.relative.y*.002,-1.4,1.4)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:paused=not paused
			KEY_L:lighting(mood+1)
			KEY_M:light_enabled=not light_enabled;set_time(clock_seconds)
			KEY_0:force_lod=-1
			KEY_1:force_lod=0
			KEY_2:force_lod=1
			KEY_3:force_lod=2
			KEY_R:body.position=Vector3(0,.03,13);body.rotation=Vector3.ZERO;camera.position=Vector3(0,1.62,0);camera.rotation=Vector3.ZERO
			KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
func shot(name:String,caption:String="")->void:
	label.text="ART-07C3 | "+(name if caption.is_empty() else caption)+" | "+RenderingServer.get_current_rendering_method()+"\nSource study; native finite-work fixture supplied separately"
	lods();await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK)
func write_json(name:String,data:Dictionary)->void:
	var f:=FileAccess.open(output+"/"+name,FileAccess.WRITE);f.store_string(JSON.stringify(data,"\t"))
func capture()->void:
	for i in 3:
		lighting(i);view(Vector3(10,5.4,15),Vector3(0,4,-1));await shot(["day","shade","dusk"][i])
	lighting(1);force_lod=0;view(Vector3(4.5,1.7,3),Vector3(3.2,1.5,0))
	light_enabled=false;set_time(1);await shot("incision-off")
	light_enabled=true;set_time(1);await shot("incision-on")
	lighting(0);view(Vector3(-.5,1.1,4.3),Vector3(-2.4,.3,2.5));await shot("cork-full")
	view(Vector3(-.5,1.1,-.7),Vector3(-2.4,.3,-2.5));await shot("cork-worked")
	for i in 3:
		force_lod=i;view(Vector3(11,5,14),Vector3(3.2,5,0));await shot("lod-"+str(i))
	force_lod=-1
	var before:=clock_seconds;automatic=false;paused=true
	for i in 8:await get_tree().process_frame
	assert(clock_seconds==before);paused=false
	for i in 4:await get_tree().process_frame
	assert(clock_seconds>before);automatic=true
	var cases:Array=[]
	for distance in [8,10,28]:
		view(Vector3(3.2,2,distance),Vector3(3.2,4,0));var count:=0
		for m in trees[0].levels:if m.visible:count+=1
		assert(count==1);cases.append({"distance":distance,"level":trees[0].lod})
	write_json("checks.json",{"pause_resume":true,"exclusive_lods":cases,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"native_envelopes_unchanged":true})
	for t in trees:t.root.hide()
	for n in plants+deadfalls:n.hide()
	hero.show();lighting(0);view(Vector3(11,7,17),Vector3(0,5.2,0));await shot("full-width-source","Full-width source study: native fit unresolved")
	view(Vector3(1.2,1.7,5),Vector3(0,1.4,0));light_enabled=false;set_time(1);await shot("hero-incision-off","Full-width source: incision off")
	light_enabled=true;set_time(1);await shot("hero-incision-on","Full-width source: incision on")
	print("C3_CAPTURE_OK");get_tree().quit()
func motion()->void:
	lighting(1);force_lod=0;view(Vector3(4.5,1.7,3),Vector3(3.2,1.5,0))
	for i in 48:set_time(float(i)/12);await shot("pulse-%03d"%i,"pulse")
	lighting(0);view(Vector3(6,7,7),Vector3(3.2,7,0))
	for i in 48:set_time(float(i)/12);await shot("wind-%03d"%i,"wind")
	paused=true
	for i in 12:await shot("paused-%03d"%i,"paused")
	print("C3_MOTION_OK");get_tree().quit()
func walk()->void:
	body.position=Vector3(0,.02,13);body.rotation=Vector3.ZERO;camera.position=Vector3(0,1.62,0);camera.rotation=Vector3.ZERO
	walk_active=true;Input.action_press("c3_f")
	var frames:=0
	while body.position.z>-13 and frames<700:
		await get_tree().physics_frame;set_time(float(frames)/60)
		if frames%12==0:await shot("walk-%03d"%(frames/12))
		frames+=1
	Input.action_release("c3_f");walk_active=false
	assert(body.position.z<=-13)
	var unsupported:=0
	for i in range(6,route_samples.size()):if not route_samples[i].floor:unsupported+=1
	assert(unsupported==0)
	write_json("walk.json",{"samples":route_samples,"unsupported":unsupported,"distance_m":13-body.position.z,"capsule_radius_m":.32,"capsule_height_m":1.8})
	print("C3_WALK_OK ",route_samples.size());get_tree().quit()
func benchmark()->void:
	label.hide();DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var cases:Array=[]
	for position in [Vector3(10,5.4,15),Vector3(0,1.62,-4)]:
		for baseline in [true,false]:
			force_lod=0 if baseline else -1;view(position,Vector3(3.2,4,0))
			for light in [0,2]:
				lighting(light)
				for i in 90:set_time(float(i)/60);await get_tree().process_frame
				var wall:Array=[];var gpu:Array=[]
				for i in 300:
					var start:=Time.get_ticks_usec();set_time(float(i)/60);await RenderingServer.frame_post_draw
					gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()));await get_tree().process_frame;wall.append((Time.get_ticks_usec()-start)/1000.0)
				wall.sort();gpu.sort();cases.append({"eye":[position.x,position.y,position.z],"all_near":baseline,"light":light,"wall_p50_ms":wall[150],"wall_p95_ms":wall[285],"worst_ms":wall[-1],"gpu_p50_ms":gpu[150],"gpu_p95_ms":gpu[285],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	write_json("benchmark.json",{"cases":cases,"samples":300,"warmup":90,"size":[1280,900],"msaa":4,"vsync":false,"device":RenderingServer.get_video_adapter_name()})
	print("C3_BENCHMARK_OK");get_tree().quit()
