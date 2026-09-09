extends Node3D
## B1 standalone review. Posed composition, not native geography or harvesting.
var cfg: Dictionary
var camera: Camera3D
var sun: DirectionalLight3D
var env: Environment
var label: Label
var clock_seconds:=0.0
var paused:=false
var automatic:=false
var light_on:=true
var mats:Array[ShaderMaterial]=[]
var trees:Array=[]
var bases:Dictionary={}
var force_lod:=-1
var mood_index:=0
var output:="res://evidence"
var renderer:=""

func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://kit.json"))
	renderer=RenderingServer.get_current_rendering_method()
	output+="/"+renderer
	DirAccess.make_dir_recursive_absolute(output)
	for species in ["broadleaf","pine"]:
		var probe:Node3D=load("res://assets/"+species+"-a-lod0.glb").instantiate()
		for mesh in probe.find_children("*","MeshInstance3D",true,false):
			if "trunk" in mesh.name.to_lower():bases[species]=mesh.mesh.surface_get_material(0)
		probe.free()
		assert(bases.has(species))
	for row in [["broadleaf-a",-4,0],["pine-a",4,0],["broadleaf-altered",0,-12],["pine-b",9,-13],["broadleaf-b",-12,-23],["pine-a",-17,-36],["broadleaf-a",18,-42],["pine-b",12,-68],["broadleaf-b",-20,-70]]:
		add_tree(row[0],Vector3(row[1],0,row[2]))
	for row in [["broadleaf-stump",-3,4],["pine-stump",3,4],["broadleaf-deadwood",-8,3],["pine-deadwood",8,5]]:
		var prop:Node3D=load("res://assets/"+row[0]+".glb").instantiate();add_child(prop);prop.position=Vector3(row[1],-(cfg.pine.burial_m if row[0].begins_with("pine") else cfg.broadleaf.burial_m) if "stump" in row[0] else 0.0,row[2])
	var floor_mesh:=MeshInstance3D.new();floor_mesh.mesh=PlaneMesh.new();floor_mesh.mesh.size=Vector2(180,180)
	var floor_mat:=StandardMaterial3D.new();floor_mat.albedo_texture=load("res://forest-floor.png");floor_mat.uv1_scale=Vector3(60,60,60);floor_mat.roughness=1;floor_mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	floor_mesh.material_override=floor_mat;add_child(floor_mesh);floor_mesh.position=Vector3(0,-.02,-35)
	var rock:Node3D=load("res://assets/fractured-rock.glb").instantiate();add_child(rock);rock.position=Vector3(-6,-.2,-1)
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world)
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(.25,.34,.39);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.72,.81,.88);env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.glow_enabled=false
	env.fog_enabled=true;env.fog_density=.003;env.fog_light_color=Color(.31,.39,.40)
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=90;add_child(sun)
	camera=Camera3D.new();camera.fov=65;camera.far=180;add_child(camera);camera.make_current();overview()
	get_viewport().msaa_3d=Viewport.MSAA_4X
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(20,18);label.add_theme_font_size_override("font_size",20);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",2)
	lighting(0)
	var args:=OS.get_cmdline_user_args();automatic=not args.is_empty()
	for i in 12:await get_tree().process_frame
	if "--capture" in args:await captures()
	elif "--motion" in args:await motion()
	elif "--benchmark" in args:await benchmark()
	elif "--check" in args:await checks()
	else:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func add_tree(role:String,at:Vector3)->Node3D:
	var species:="pine" if role.begins_with("pine") else "broadleaf"
	var holder:=Node3D.new();add_child(holder);holder.position=at;holder.position.y-=cfg[species].burial_m
	var levels:Array=[]
	for lod in 3:
		var model:Node3D=load("res://assets/"+role+"-lod"+str(lod)+".glb").instantiate();holder.add_child(model);levels.append(model)
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			var mat:=ShaderMaterial.new();mat.shader=load("res://canopy.gdshader")
			var part:=1 if "foliage" in mesh.name.to_lower() else (2 if "branchlets" in mesh.name.to_lower() else 0)
			mat.set_shader_parameter("role",part);mat.set_shader_parameter("base_texture",bases[species].albedo_texture)
			mat.set_shader_parameter("orm_texture",bases[species].roughness_texture)
			for key in ["peak_emission","period_seconds","minimum_light"]:mat.set_shader_parameter(key,cfg.scar[key])
			mat.set_shader_parameter("wind_tip_m",cfg.wind_tip_m);mat.set_shader_parameter("wind_period_seconds",cfg.wind_period_seconds)
			mesh.material_override=mat;mats.append(mat)
			mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
	trees.append({"root":holder,"levels":levels,"role":role,"lod":-1});return holder

func update_lods()->void:
	for tree in trees:
		var distance:float=camera.global_position.distance_to(tree.root.global_position)
		var lod:=force_lod if force_lod>=0 else (0 if distance<cfg.lod_distances_m[0] else (1 if distance<cfg.lod_distances_m[1] else 2))
		for i in 3:tree.levels[i].visible=i==lod
		tree.lod=lod

func set_time(value:float)->void:
	clock_seconds=value
	for mat in mats:mat.set_shader_parameter("clock_seconds",value);mat.set_shader_parameter("light_enabled",light_on)

func lighting(index:int)->void:
	mood_index=index
	sun.light_energy=[1.6,.35,.55][index];sun.light_color=[Color(1,.94,.84),Color(.78,.86,1),Color(1,.62,.35)][index];env.ambient_light_energy=[.7,.48,.32][index]
	label.text="ART-07B1  |  "+["DAY","SHADE","DUSK"][index]+"  |  "+renderer+"\nWASD + mouse: review flight • L: lighting • M: light • Space: pause • R: overview • Escape: cursor"

func overview()->void:
	camera.position=Vector3(10,4.8,14);camera.look_at(Vector3(0,3,-3))

func _process(delta:float)->void:
	if not automatic and not paused:
		set_time(clock_seconds+delta)
		var direction:=Vector3.ZERO
		if Input.is_physical_key_pressed(KEY_W):direction.z-=1
		if Input.is_physical_key_pressed(KEY_S):direction.z+=1
		if Input.is_physical_key_pressed(KEY_A):direction.x-=1
		if Input.is_physical_key_pressed(KEY_D):direction.x+=1
		camera.position+=camera.basis*direction*delta*6
	update_lods()

func _unhandled_input(event:InputEvent)->void:
	if automatic:return
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		camera.rotation.y-=event.relative.x*.002;camera.rotation.x=clampf(camera.rotation.x-event.relative.y*.002,-1.4,1.4)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_SPACE:paused=not paused
		if event.keycode==KEY_L:lighting((mood_index+1)%3)
		if event.keycode==KEY_M:light_on=not light_on;set_time(clock_seconds)
		if event.keycode==KEY_R:overview()
		if event.keycode==KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func shot(name:String)->void:
	update_lods()
	for i in 3:await RenderingServer.frame_post_draw
	var result:=get_viewport().get_texture().get_image().save_png(output+"/"+name+".png");assert(result==OK)

func captures()->void:
	for mood in 3:
		lighting(mood);overview();set_time(1.1);await shot("overview-"+["day","shade","dusk"][mood])
	lighting(1);camera.position=Vector3(1,2.4,-8);camera.look_at(Vector3(0,2.6,-12));force_lod=0
	light_on=false;set_time(1.0);await shot("scar-off");light_on=true;set_time(1.0);await shot("scar-on")
	camera.position=Vector3(-2,1.0,6);camera.look_at(Vector3(-3,.2,4));await shot("oak-stump")
	camera.position=Vector3(4,1.0,6);camera.look_at(Vector3(3,.2,4));await shot("pine-stump")
	lighting(0);label.visible=false
	# Matched camera compares each side of the actual distance transition.
	for pair in [[0,1,18.0],[1,2,55.0]]:
		camera.position=Vector3(-4,4.2,pair[2]);camera.look_at(Vector3(-4,4.2,0))
		for lod in [pair[0],pair[1]]:force_lod=lod;set_time(1);await shot("lod-"+str(int(pair[2]))+"-"+str(lod))
	force_lod=-1
	await checks(false)
	print("B1_CAPTURE_OK ",renderer);get_tree().quit()

func motion()->void:
	lighting(0);label.text="ART-07B1 actual Godot models | wind, attached crowns and 18 m / 55 m transitions | "+renderer
	for frame in 84:
		var t:=float(frame)/83.0
		camera.position=Vector3(12*(1-t),3.2,64-60*t);camera.look_at(Vector3(-1,4,-3));set_time(float(frame)/12)
		await shot("motion-%03d"%frame)
	lighting(1);force_lod=0;camera.position=Vector3(1,2.4,-8);camera.look_at(Vector3(0,2.6,-12))
	label.text="ART-07B1 actual recessed oak | pause-aware four-second pulse | "+renderer
	for frame in 48:
		set_time(float(frame)/12);await shot("motion-%03d"%(84+frame))
	print("B1_MOTION_OK ",renderer);get_tree().quit()

func checks(quit_after:bool=true)->void:
	var rows:Array=[]
	for tree in trees:
		for i in 3:
			var meshes:Array=tree.levels[i].find_children("*","MeshInstance3D",true,false);assert(meshes.size()==3)
			var box:=AABB();var started:=false
			for mesh in meshes:
				var bounds:AABB=mesh.transform*mesh.mesh.get_aabb();box=box.merge(bounds) if started else bounds;started=true
			assert(box.size.y>8 and box.size.y<10.5)
			rows.append({"role":tree.role,"lod":i,"bounds_godot_m":[[box.position.x,box.position.y,box.position.z],[box.size.x,box.size.y,box.size.z]]})
	set_time(2.125);paused=true;automatic=false
	var before:=clock_seconds
	for i in 8:await get_tree().process_frame
	assert(clock_seconds==before);automatic=true;paused=false
	var prior:=camera.position
	for pair in [[17.0,0],[19.0,1],[56.0,2]]:
		camera.position=trees[0].root.position+Vector3(0,0,pair[0]);update_lods();assert(trees[0].lod==pair[1]);assert(trees[0].levels.filter(func(n):return n.visible).size()==1)
	camera.position=prior
	write_json("checks.json",{"models":rows,"pause_clock_unchanged":true,"exactly_one_visible_lod":true,"renderer":renderer,"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),"scope":"Static source-kit composition; native resource checks are separate."})
	print("B1_REVIEW_CHECKS_OK ",renderer)
	if quit_after:get_tree().quit()

func benchmark()->void:
	label.visible=false;overview();RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var rows:Array=[]
	for forced in [0,-1]:
		force_lod=forced;update_lods()
		for mood in [0,2]:
			lighting(mood)
			for i in 90:set_time(float(i)/60);await get_tree().process_frame
			var wall:Array=[];var gpu:Array=[]
			for i in 300:
				var start:=Time.get_ticks_usec();set_time(float(i)/60);await RenderingServer.frame_post_draw
				gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()));await get_tree().process_frame;wall.append((Time.get_ticks_usec()-start)/1000.0)
			wall.sort();gpu.sort();rows.append({"lod":"near-only" if forced==0 else "distance","mood":mood,"samples":300,"warmup":90,"wall_p50_ms":wall[150],"wall_p95_ms":wall[285],"wall_worst_ms":wall[-1],"gpu_p50_ms":gpu[150],"gpu_p95_ms":gpu[285],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	write_json("benchmark.json",{"cases":rows,"renderer":renderer,"adapter":RenderingServer.get_video_adapter_name(),"size":[1440,900],"msaa":4,"bloom":false,"vsync":false,"notes":"Nine posed trees. No capture readback or competing generator. Compatibility GPU timings may be unavailable (zero). Not full-world or lower-spec approval."})
	print("B1_BENCHMARK_OK ",renderer);get_tree().quit()

func write_json(name:String,value:Variant)->void:
	var file:=FileAccess.open(output+"/"+name,FileAccess.WRITE);assert(file!=null);file.store_string(JSON.stringify(value,"\t"))
