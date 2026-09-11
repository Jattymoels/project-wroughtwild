extends Node3D
## C2 isolated source composition. Native work uses the separate copied-game fixture.
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
var art_root:Node3D
var grass_roots:Array=[]
func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://kit.json"));output="res://evidence/"+RenderingServer.get_current_rendering_method();DirAccess.make_dir_recursive_absolute(output)
	art_root=Node3D.new();add_child(art_root)
	for family in ["slate","shellstone"]:
		var z:=1.4 if family=="slate" else -1.4
		for i in 4:add_asset(family+"-v0-"+["full","worked","last","recovered"][i],Vector3(-3+i*2.4,0,z),true)
	# An authored quarry approach, with context explicitly outside the native work lanes.
	for i in 7:
		var n:=add_asset("rock-shelf",Vector3(-7 if i%2==0 else 7,-.05,-3-i*2.6),false);n.rotation.y=.14*sin(i*2.0)
	add_asset("rock-shelf-altered",Vector3(4.2,-.04,-5.5),false)
	for i in 5:
		var n:=add_asset("pine-context",Vector3(-10 if i%2==0 else 11,-.55,-7-i*3.1),false);n.rotation.y=i*.8
	var rng:=RandomNumberGenerator.new();rng.seed=42
	for i in 110:
		var x:=rng.randf_range(-8,8);var z:=rng.randf_range(-16,6)
		if absf(x)<1.2 and z< -3:continue
		var clear:=true
		for entry in entries:
			if entry.id.begins_with("slate") or entry.id.begins_with("shellstone"):
				if absf(x-entry.root.position.x)<1.4 and absf(z-entry.root.position.z)<1.05:clear=false
		if clear:
			var n:=add_asset("upland-tussock-v%d"%(i%3),Vector3(x,0,z),true);n.rotation.y=rng.randf_range(-.25,.25);grass_roots.append(n)
	var ground:=MeshInstance3D.new();ground.mesh=PlaneMesh.new();ground.mesh.size=Vector2(90,90);ground.position.y=-.007
	var gm:=StandardMaterial3D.new();gm.albedo_color=Color(.25,.245,.205);gm.roughness=1;ground.material_override=gm;add_child(ground)
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world);env.background_mode=Environment.BG_COLOR;env.background_color=Color(.34,.41,.46);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.75,.83,.9);env.glow_enabled=false
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-48,-30,0);sun.shadow_enabled=true;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;sun.directional_shadow_max_distance=32;add_child(sun)
	camera=Camera3D.new();add_child(camera);camera.fov=58;camera.make_current();overview();get_viewport().msaa_3d=Viewport.MSAA_4X
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(20,18);label.add_theme_font_size_override("font_size",19);lighting(0)
	for i in 12:await get_tree().process_frame
	var args:=OS.get_cmdline_user_args()
	if "--capture" in args:automatic=true;await capture();get_tree().quit()
	elif "--motion" in args:automatic=true;await motion();get_tree().quit()
	elif "--benchmark" in args:automatic=true;await benchmark();get_tree().quit()
func add_asset(id:String,at:Vector3,has_lods:bool)->Node3D:
	var root:=Node3D.new();art_root.add_child(root);root.position=at;var levels:Array=[]
	for lod in (3 if has_lods else 1):
		var path:="res://assets/"+id+("-lod%d"%lod if has_lods else "")+".gltf"
		var model:Node3D=load(path).instantiate();root.add_child(model);levels.append(model)
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			if id.begins_with("upland"):
				var mat:=ShaderMaterial.new();mat.shader=load("res://wind.gdshader");mat.set_shader_parameter("period",cfg.wind_period_s);mat.set_shader_parameter("tip",cfg.wind_tip_m);mesh.material_override=mat;mats.append(mat);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			elif id=="rock-shelf-altered":
				for s in mesh.mesh.get_surface_count():
					var base:StandardMaterial3D=mesh.mesh.surface_get_material(s);var mat:=ShaderMaterial.new();mat.shader=load("res://scar.gdshader");mat.set_shader_parameter("albedo_map",base.albedo_texture);mat.set_shader_parameter("orm_map",base.roughness_texture);mat.set_shader_parameter("period",cfg.pulse_period_s);mat.set_shader_parameter("peak",cfg.pulse_peak);mesh.set_surface_override_material(s,mat);mats.append(mat)
	entries.append({"id":id,"root":root,"levels":levels});return root
func overview()->void:camera.position=Vector3(7,5.5,10);camera.look_at(Vector3(0,.3,-2))
func view(at:Vector3,target:Vector3)->void:camera.position=at;camera.look_at(target)
func set_time(value:float)->void:
	clock_seconds=value
	for mat in mats:mat.set_shader_parameter("clock_seconds",value);mat.set_shader_parameter("light_enabled",light_on)
func update_lods()->void:
	for entry in entries:
		var d:=camera.position.distance_to(entry.root.position);var lod:=force_lod if force_lod>=0 else (0 if d<cfg.lod_distances_m[0] else (1 if d<cfg.lod_distances_m[1] else 2));lod=mini(lod,entry.levels.size()-1)
		for i in entry.levels.size():entry.levels[i].visible=i==lod
func _process(delta:float)->void:
	if not paused and not automatic:set_time(clock_seconds+delta)
	if not automatic and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		var v:=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		camera.position+=camera.basis*v*delta*5
	update_lods()
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
	label.text="ART-07C2 | "+["DAY","SHADE","DUSK"][index]+" | "+RenderingServer.get_current_rendering_method()+"\nSource study • WASD/QE flight • L light • M inherited scar • Space pause • 0–3 detail • R overview"
func shot(name:String)->void:
	set_time(clock_seconds);update_lods()
	for i in 3:await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK)
func write_json(name:String,data:Variant)->void:
	var f:=FileAccess.open(output+"/"+name,FileAccess.WRITE);f.store_string(JSON.stringify(data,"\t"))
func capture()->void:
	force_lod=0
	for index in 3:lighting(index);overview();await shot(["day","shade","dusk"][index])
	lighting(0)
	for row in [["slate-layers",Vector3(-1,1.5,3.2),Vector3(-3,.24,1.4)],["shellstone-fossils",Vector3(-3,.9,1),Vector3(-3,.26,-1.4)],["work-states",Vector3(3.5,4,6),Vector3(0,.25,0)],["approach",Vector3(0,1.62,-17),Vector3(0,1,-1)]]:
		view(row[1],row[2]);await shot(row[0])
	view(Vector3(6.7,1.7,-3.4),Vector3(4.2,.4,-5.5));lighting(1);light_on=false;await shot("scar-off");light_on=true;set_time(1);await shot("scar-on")
	lighting(0);overview()
	for lod in 3:force_lod=lod;await shot("lod-%d"%lod)
	force_lod=-1;view(Vector3(0,2,30),Vector3(0,.6,-3));await shot("far")
	await checks();print("C2_CAPTURE_OK")
func checks()->void:
	var before:=clock_seconds;automatic=false;paused=true
	for i in 10:await get_tree().process_frame
	assert(clock_seconds==before)
	for mat in mats:assert(mat.get_shader_parameter("clock_seconds")==before)
	paused=false
	for i in 4:await get_tree().process_frame
	assert(clock_seconds>before);automatic=true
	var lod_checks:Array=[]
	for distance in [8,10,24]:
		camera.position=entries[0].root.position+Vector3(0,0,distance);force_lod=-1;update_lods();var expected:=0 if distance<9 else (1 if distance<23 else 2)
		assert(entries[0].levels[expected].visible)
		for entry in entries:
			var count:=0
			for level in entry.levels:if level.visible:count+=1
			assert(count==1)
		lod_checks.append({"distance":distance,"expected":expected})
	var maximum:=0.0
	for n in grass_roots:maximum=maxf(maximum,absf(n.position.y))
	assert(maximum<.00001);assert(art_root.find_children("*","CollisionObject3D",true,false).is_empty())
	write_json("checks.json",{"pause_resume":true,"lod_cases":lod_checks,"grass_ground_origins":grass_roots.size(),"max_origin_error_m":maximum,"extra_colliders":0,"scope":"Authored flat quarry composition, separate native work/body/contact fixture. No ordinary-world adoption."})
func motion()->void:
	force_lod=0;lighting(0);view(Vector3(-1,1.5,3.2),Vector3(-3,.24,1.4))
	for i in 36:
		set_time(float(i)/9);camera.position.x=-1+sin(i*.08)*.6;camera.look_at(Vector3(-3,.24,1.4));await shot("orbit-%03d"%i)
	view(grass_roots[0].position+Vector3(.65,.4,.75),grass_roots[0].position+Vector3(0,.12,0))
	for i in 48:set_time(float(i)/12);await shot("wind-%03d"%i)
	paused=true
	for i in 8:await shot("paused-%03d"%i)
	paused=false;lighting(1);view(Vector3(6.7,1.7,-3.4),Vector3(4.2,.4,-5.5))
	for i in 48:set_time(float(i)/12);await shot("pulse-%03d"%i)
	print("C2_MOTION_OK")
func benchmark()->void:
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true);var cases:Array=[]
	for viewpoint in ["overview","quarry-close","approach"]:
		if viewpoint=="overview":overview()
		elif viewpoint=="quarry-close":view(Vector3(-1,1.5,3.2),Vector3(-3,.24,1.4))
		else:view(Vector3(0,1.62,-17),Vector3(0,1,-1))
		for hidden in [true,false]:
			art_root.visible=not hidden;force_lod=-1;lighting(0);label.hide()
			for i in 120:set_time(float(i)/60);await get_tree().process_frame
			var wall:Array=[];var gpu:Array=[]
			for i in 600:
				var start:=Time.get_ticks_usec();set_time(float(i)/60);await RenderingServer.frame_post_draw;gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()));await get_tree().process_frame;wall.append((Time.get_ticks_usec()-start)/1000.0)
			wall.sort();gpu.sort();cases.append({"view":viewpoint,"art_hidden":hidden,"wall_p50_ms":wall[300],"wall_p95_ms":wall[570],"wall_worst_ms":wall[-1],"gpu_p50_ms":gpu[300],"gpu_p95_ms":gpu[570],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	write_json("benchmark.json",{"cases":cases,"warmup":120,"samples":600,"viewport":[1440,900],"msaa":4,"vsync":false,"device":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"scope":"C2 authored habitat at three fixed views. Hidden comparison retains textures. No other-device or full-world budget."});print("C2_BENCHMARK_OK")
