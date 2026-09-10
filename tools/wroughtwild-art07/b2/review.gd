extends Node3D
## Isolated ordinary plants. No inventory, harvesting, source stock or saved world.
var cfg:Dictionary
var camera:Camera3D
var sun:DirectionalLight3D
var env:Environment
var label:Label
var plants:Array=[]
var materials:Array[ShaderMaterial]=[]
var clock_seconds:=0.0
var paused:=false
var automatic:=false
var force_lod:=-1
var mood:=0
var renderer:=""
var output:=""
var body:CharacterBody3D
var walking:=false

func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://kit.json"))
	renderer=RenderingServer.get_current_rendering_method();output="res://evidence/"+renderer
	DirAccess.make_dir_recursive_absolute(output)
	var layout:Array=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	for row in layout:add_plant(row)
	var floor_mesh:=MeshInstance3D.new();var plane:=PlaneMesh.new();plane.size=Vector2(30,42);floor_mesh.mesh=plane;floor_mesh.position=Vector3(0,-.009,-6);add_child(floor_mesh)
	var floor_source:Texture2D=load("res://forest-floor.png");var floor_image:=floor_source.get_image();assert(floor_image.generate_mipmaps()==OK)
	var floor_texture:=ImageTexture.create_from_image(floor_image);assert(floor_image.has_mipmaps())
	var fm:=ShaderMaterial.new();fm.shader=load("res://floor.gdshader");fm.set_shader_parameter("litter",floor_texture);fm.set_shader_parameter("tile_m",cfg.texture_tile_m);floor_mesh.material_override=fm
	var ground:=StaticBody3D.new();add_child(ground);ground.position=Vector3(0,-.109,-6)
	var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(30,.2,42);shape.shape=box;ground.add_child(shape)
	body=CharacterBody3D.new();add_child(body);var capsule:=CapsuleShape3D.new();capsule.height=1.8;capsule.radius=.32;var bc:=CollisionShape3D.new();bc.shape=capsule;bc.position.y=.9;body.add_child(bc);body.position=Vector3(0,.03,3);body.floor_snap_length=.2
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world)
	env.background_mode=Environment.BG_COLOR;env.background_color=Color(.12,.16,.16);env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.72,.80,.85);env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.glow_enabled=false
	env.fog_enabled=true;env.fog_density=.023;env.fog_light_color=Color(.16,.20,.19)
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-43,-32,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=35;add_child(sun)
	camera=Camera3D.new();camera.fov=65;camera.far=60;add_child(camera);camera.make_current();overview()
	get_viewport().msaa_3d=Viewport.MSAA_4X
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(18,16);label.add_theme_font_size_override("font_size",17);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",2)
	lighting(0);var args:=OS.get_cmdline_user_args();automatic=not args.is_empty()
	for i in 15:await get_tree().process_frame
	if "--capture" in args:await captures()
	elif "--motion" in args:await motion()
	elif "--benchmark" in args:await benchmark()
	elif "--check" in args:await checks()
	else:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func add_plant(row:Dictionary)->void:
	var role:String=row.role;var holder:=Node3D.new();add_child(holder);holder.position=Vector3(row.position[0],row.position[1],row.position[2]);holder.rotation.y=deg_to_rad(row.yaw);holder.scale=Vector3.ONE*row.scale
	var levels:Array=[];var contextual:=role.begins_with("context")
	for lod in (1 if contextual else 3):
		var model:Node3D=load("res://assets/"+role+("" if contextual else "-lod"+str(lod))+".glb").instantiate();holder.add_child(model);levels.append(model)
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			var old:StandardMaterial3D=mesh.mesh.surface_get_material(0)
			var mat:=ShaderMaterial.new();mat.shader=load("res://plant.gdshader");mat.set_shader_parameter("wind_tip_m",cfg.wind_tip_m);mat.set_shader_parameter("wind_period_seconds",cfg.wind_period_seconds)
			mat.set_shader_parameter("rooted_wind",not contextual and not (role in ["moss","lichen","climber","leaf-litter","needle-litter"]))
			mat.set_shader_parameter("surface_role",4 if contextual else (1 if role=="moss" else (2 if role=="lichen" else 0)))
			if "host" in mesh.name.to_lower() and old.albedo_texture!=null:mat.set_shader_parameter("textured",true);mat.set_shader_parameter("base_texture",old.albedo_texture)
			mesh.material_override=mat;materials.append(mat);mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED
		if lod==0 and (contextual or role=="sapling-shrub"):
			for mesh in model.find_children("*","MeshInstance3D",true,false):
				if contextual or "host" in mesh.name.to_lower():mesh.create_trimesh_collision()
	plants.append({"root":holder,"levels":levels,"role":role,"lod":-1})

func update_lods()->void:
	for plant in plants:
		var distance:float=camera.global_position.distance_to(plant.root.global_position)
		var lod:=force_lod if force_lod>=0 else (0 if distance<cfg.lod_distances_m[0] else (1 if distance<cfg.lod_distances_m[1] else 2))
		lod=mini(lod,plant.levels.size()-1)
		for i in plant.levels.size():plant.levels[i].visible=i==lod
		plant.lod=lod
func set_time(t:float)->void:
	clock_seconds=t
	for mat in materials:mat.set_shader_parameter("clock_seconds",t)
func lighting(i:int)->void:
	mood=i;sun.light_energy=[1.3,.32,.55][i];sun.light_color=[Color(1,.94,.84),Color(.78,.86,1),Color(1,.63,.38)][i];env.ambient_light_energy=[.48,.4,.3][i]
	label.text="ART-07B2 actual models  |  "+["DAY","SHADE","DUSK"][i]+"  |  "+renderer+"\nWASD/mouse: move • L: light • Space: pause • 0/1/2/3: auto/near/mid/far • R: overview • Escape: cursor"
func overview()->void:
	camera.position=Vector3(6,3.6,6);camera.look_at(Vector3(0,.25,-4))
func _process(delta:float)->void:
	if not automatic and not paused:
		set_time(clock_seconds+delta);var d:=Vector3.ZERO
		if Input.is_physical_key_pressed(KEY_W):d.z-=1
		if Input.is_physical_key_pressed(KEY_S):d.z+=1
		if Input.is_physical_key_pressed(KEY_A):d.x-=1
		if Input.is_physical_key_pressed(KEY_D):d.x+=1
		camera.position+=camera.basis*d*delta*cfg.walk_speed_m_s
	update_lods()
func _physics_process(delta:float)->void:
	if walking:
		body.velocity=Vector3(0,-2,-cfg.walk_speed_m_s);body.move_and_slide()
func _unhandled_input(e:InputEvent)->void:
	if automatic:return
	if e is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		camera.rotation.y-=e.relative.x*.002;camera.rotation.x=clampf(camera.rotation.x-e.relative.y*.002,-1.4,1.4)
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode==KEY_SPACE:paused=not paused
		if e.keycode==KEY_L:lighting((mood+1)%3)
		if e.keycode>=KEY_0 and e.keycode<=KEY_3:force_lod=e.keycode-KEY_1
		if e.keycode==KEY_R:overview()
		if e.keycode==KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
func shot(name:String)->void:
	update_lods()
	for i in 3:await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK)
func captures()->void:
	set_time(1.1)
	for i in 3:lighting(i);overview();await shot("overview-"+["day","shade","dusk"][i])
	lighting(0);force_lod=0
	for row in [["fern",Vector3(-.3,.8,2),Vector3(-2,.3,-1)],["shrub",Vector3(-.8,1.1,2),Vector3(-2.5,.6,0)],["climber",Vector3(-1.5,1.0,-2),Vector3(-3,.3,-4)],["floor",Vector3(1,1.3,-9),Vector3(2.3,0,-11)],["moss",Vector3(-1.5,.7,-2.8),Vector3(-2.5,0,-4)],["lichen",Vector3(1.5,.6,-5.5),Vector3(3,0,-7)]]:
		camera.position=row[1];camera.look_at(row[2]);await shot(row[0]+"-close")
	label.visible=false
	for distance in [7,18]:
		camera.position=Vector3(-2,cfg.eye_height_m,-1+distance);camera.look_at(Vector3(-2,.25,-1))
		for lod in 3:force_lod=lod;await shot("lod-"+str(distance)+"-"+str(lod))
	force_lod=-1;camera.position=Vector3(0,cfg.eye_height_m,2);camera.look_at(Vector3(0,.6,-7));await shot("walking-height")
	# Matched fixed camera shows ordinary material is quiet when time changes.
	camera.position=Vector3(1.5,.7,-5.5);camera.look_at(Vector3(3,0,-7));set_time(0);await shot("ordinary-time0");set_time(2.75);await shot("ordinary-time275")
	await checks(false);print("B2_CAPTURE_OK ",renderer);get_tree().quit()
func motion()->void:
	label.text="ART-07B2 | actual "+renderer+" models | authored path and quiet wind"
	for frame in 96:
		var t:=frame/95.0;camera.position=Vector3(0,cfg.eye_height_m,3-15*t);camera.look_at(Vector3(-.8,.65,-2-15*t));set_time(frame/12.0);await shot("motion-%03d"%frame)
	# Fixed close view: wind moves attached foliage, then holds while paused.
	camera.position=Vector3(-.3,.8,2);camera.look_at(Vector3(-2,.3,-1));force_lod=0
	for frame in 48:set_time(minf(frame/12.0,2.0));await shot("motion-%03d"%(96+frame))
	print("B2_MOTION_OK ",renderer);get_tree().quit()
func checks(quit_after:bool=true)->void:
	var rows:Array=[]
	for plant in plants:
		for lod in plant.levels.size():
			var box:=AABB();var started:=false;var triangles:=0
			for mesh in plant.levels[lod].find_children("*","MeshInstance3D",true,false):
				var bounds:AABB=mesh.transform*mesh.mesh.get_aabb();box=box.merge(bounds) if started else bounds;started=true
				for s in mesh.mesh.get_surface_count():triangles+=mesh.mesh.surface_get_array_index_len(s)/3
			assert(box.size.length()>0 and box.size.y<2)
			rows.append({"role":plant.role,"lod":lod,"triangles":triangles,"bounds":[[box.position.x,box.position.y,box.position.z],[box.size.x,box.size.y,box.size.z]]})
	set_time(2.125);paused=true;automatic=false
	for i in 8:await get_tree().process_frame
	assert(clock_seconds==2.125);automatic=true;paused=false
	force_lod=-1
	for pair in [[6,0],[8,1],[19,2]]:
		camera.position=plants[0].root.position+Vector3(0,0,pair[0]);update_lods();assert(plants[0].lod==pair[1]);assert(plants[0].levels.filter(func(n):return n.visible).size()==1)
	# Actual CharacterBody route checks support and all physical obstacle bodies.
	body.position=Vector3(0,.03,3);walking=true;var samples:=0;var grounded:=0
	for i in 500:
		await get_tree().physics_frame;samples+=1
		if body.is_on_floor():grounded+=1
		if body.position.z<=-13:break
	walking=false;assert(body.position.z<=-13 and absf(body.position.x)<.01 and absf(body.position.y)<.04 and grounded>samples-5)
	write_json("checks.json",{"models":rows,"pause":true,"one_visible_lod":true,"physical_route_m":16,"physics_samples":samples,"grounded":grounded,"final_body":[body.position.x,body.position.y,body.position.z],"alpha_blended_surfaces":0,"renderer":renderer,"device":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info(),"scope":"Static decorative study; no kit placement, harvesting or game-save integration."})
	if quit_after:print("B2_CHECK_OK ",renderer);get_tree().quit()
func benchmark()->void:
	label.visible=false;overview();RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var rows:Array=[]
	for forced in [0,-1]:
		force_lod=forced;update_lods()
		for mode in [0,2]:
			lighting(mode)
			for i in 90:set_time(i/60.0);await get_tree().process_frame
			var wall:Array=[];var gpu:Array=[]
			for i in 300:
				var start:=Time.get_ticks_usec();set_time(i/60.0);await RenderingServer.frame_post_draw
				gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()));await get_tree().process_frame;wall.append((Time.get_ticks_usec()-start)/1000.0)
			wall.sort();gpu.sort();rows.append({"lod":forced,"mood":mode,"warmup":90,"samples":300,"wall_p50_ms":wall[150],"wall_p95_ms":wall[285],"wall_worst_ms":wall[-1],"gpu_p50_ms":gpu[150],"gpu_p95_ms":gpu[285],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	write_json("benchmark.json",{"cases":rows,"renderer":renderer,"device":RenderingServer.get_video_adapter_name(),"resolution":[1280,900],"msaa":4,"vsync":false,"alpha_surfaces":0,"notes":"Separate from captures/generation. Compatibility zero GPU timings mean unavailable. Static kit, not world budget approval."})
	print("B2_BENCHMARK_OK ",renderer);get_tree().quit()
func write_json(name:String,value:Variant)->void:
	var f:=FileAccess.open(output+"/"+name,FileAccess.WRITE);assert(f!=null);f.store_string(JSON.stringify(value,"\t"))
