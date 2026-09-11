extends Node3D
## Authored C4 habitat. Resources in this scene are static; native study is separate.
var cfg:Dictionary
var layout:Array
var templates:Dictionary={}
var materials:Array=[]
var entries:Array=[]
var camera:Camera3D
var body:CharacterBody3D
var sun:DirectionalLight3D
var env:Environment
var label:Label
var paused:=false
var clock_seconds:=0.0
var automatic:=false
var walk_active:=false
var forced_lod:=-1
var light_on:=true
var mood:=0
var output:=""
var renderer:=""
var walk_samples:Array=[]
var checks_count:=0

func check(ok:bool,message:String)->void:
	checks_count+=1
	if not ok:
		push_error("C4_FAIL "+message);get_tree().quit(1)
	assert(ok,message)
func analytic(x:float,z:float)->float:return .10*sin(x*.4)+.07*cos(z*.3)+maxf(0,absf(x)-9)*.10+1.8*exp(-pow((z-46)/9,2))
func ground(x:float,z:float)->float:
	var a:=floorf(x*2)*.5;var b:=floorf(z*2)*.5;var u:=(x-a)*2;var v:=(z-b)*2
	var h00:=analytic(a,b);var h10:=analytic(a+.5,b);var h01:=analytic(a,b+.5);var h11:=analytic(a+.5,b+.5)
	return h00+u*(h10-h00)+v*(h01-h00) if u+v<=1 else h11+(1-u)*(h01-h11)+(1-v)*(h10-h11)

func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://kit.json"))
	layout=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	renderer=RenderingServer.get_current_rendering_method();output="res://evidence/"+renderer
	DirAccess.make_dir_recursive_absolute(output)
	automatic=not OS.get_cmdline_user_args().is_empty()
	var st:=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ix in range(-64,64):
		for iz in range(-60,144):
			var x:=ix*.5;var z:=iz*.5
			var points:=[Vector2(x,z),Vector2(x+.5,z),Vector2(x,z+.5),Vector2(x+.5,z+.5)]
			# Godot front faces use clockwise winding.
			for index in [0,1,2,1,3,2]:
				var p:Vector2=points[index];st.set_uv(p/2.4);st.add_vertex(Vector3(p.x,ground(p.x,p.y),p.y))
	st.generate_normals()
	var floor_mesh:=MeshInstance3D.new();floor_mesh.mesh=st.commit();add_child(floor_mesh)
	var floor_mat:=ShaderMaterial.new();floor_mat.shader=load("res://surface.gdshader");floor_mat.set_shader_parameter("floor_surface",true);floor_mat.set_shader_parameter("albedo_map",load("res://forest-floor.png"));floor_mesh.material_override=floor_mat
	floor_mesh.create_trimesh_collision()
	for c in floor_mesh.find_children("*","StaticBody3D",true,false):c.collision_layer=2
	for row:Dictionary in layout:
		var root:=Node3D.new();add_child(root);root.position=Vector3(row.x,ground(row.x,row.z),row.z);root.rotation.y=row.yaw;root.scale=Vector3.ONE*row.scale
		var levels:Array=[]
		var rock:bool=row.role in ["rock-shelf","talus-pebbles"]
		for i in (1 if rock else 3):
			var key:String=row.role+"-lod"+str(0 if rock else i)
			var instance:Node3D=template(key).duplicate()
			root.add_child(instance);levels.append(instance)
		# Seat non-resource context from its actual exported underside.
		if rock or "felled" in row.role:
			var minimum:=INF
			for mesh:MeshInstance3D in levels[0].find_children("*","MeshInstance3D",true,false):
				for s in mesh.mesh.get_surface_count():
					for v:Vector3 in mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
						var point:Vector3=mesh.global_transform*v
						minimum=minf(minimum,point.y-ground(point.x,point.z))
			root.position.y-=minimum+.012
		entries.append({"row":row,"root":root,"levels":levels,"lod":-1})
		if row.role.begins_with("ash-") and not "felled" in row.role:
			var collider:=StaticBody3D.new();root.add_child(collider)
			collider.top_level=true;collider.global_position=root.global_position;collider.global_rotation.y=root.global_rotation.y
			var shape:=CollisionShape3D.new();var box:=BoxShape3D.new();box.size=Vector3(.6,2.6,.6);shape.shape=box;shape.position.y=1.3;collider.add_child(shape)
	body=CharacterBody3D.new();add_child(body);body.collision_mask=3;body.floor_snap_length=.3
	var cs:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=1.8;capsule.radius=.32;cs.shape=capsule;cs.position.y=.9;body.add_child(cs)
	camera=Camera3D.new();body.add_child(camera);camera.position.y=1.62;camera.fov=68;camera.far=110;camera.make_current()
	reset_walk()
	for pair in [["c4_forward",KEY_W],["c4_back",KEY_S],["c4_left",KEY_A],["c4_right",KEY_D]]:
		InputMap.add_action(pair[0]);var event:=InputEventKey.new();event.physical_keycode=pair[1];InputMap.action_add_event(pair[0],event)
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world)
	env.background_mode=Environment.BG_SKY;var sky:=Sky.new();var sky_mat:=ProceduralSkyMaterial.new()
	sky_mat.sky_top_color=Color(.28,.34,.38);sky_mat.sky_horizon_color=Color(.57,.56,.51);sky_mat.ground_bottom_color=Color(.12,.11,.09);sky_mat.ground_horizon_color=Color(.57,.56,.51);sky.sky_material=sky_mat;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.74,.78,.83);env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.glow_enabled=false
	sun=DirectionalLight3D.new();add_child(sun);sun.rotation_degrees=Vector3(-42,-28,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=32;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	get_viewport().msaa_3d=Viewport.MSAA_4X
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(22,18);label.add_theme_font_size_override("font_size",18);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",2);label.add_theme_constant_override("shadow_offset_y",2)
	lighting(0);set_time(0);update_lods()
	for i in 12:await get_tree().physics_frame
	var args:=OS.get_cmdline_user_args()
	if "--capture" in args:await captures()
	elif "--motion" in args:await motion()
	elif "--walk" in args:await walking()
	elif "--benchmark" in args:await benchmark()
	elif "--check" in args:await verify();get_tree().quit()
	else:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func template(key:String)->Node3D:
	if templates.has(key):return templates[key]
	var node:Node3D=load("res://assets/"+key+".gltf").instantiate()
	var plant:bool=key.begins_with("scrub") or key.begins_with("thorn") or key.begins_with("seed-grass")
	for mesh:MeshInstance3D in node.find_children("*","MeshInstance3D",true,false):
		if plant:mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for s in mesh.mesh.get_surface_count():
			var old:StandardMaterial3D=mesh.mesh.surface_get_material(s)
			var mat:=ShaderMaterial.new();mat.shader=load("res://surface.gdshader")
			mat.set_shader_parameter("textured",old.albedo_texture!=null);mat.set_shader_parameter("albedo_map",old.albedo_texture);mat.set_shader_parameter("base_colour",old.albedo_color);mat.set_shader_parameter("vertex_colour",old.vertex_color_use_as_albedo)
			mat.set_shader_parameter("has_orm",old.roughness_texture!=null);mat.set_shader_parameter("orm_map",old.roughness_texture)
			mat.set_shader_parameter("plant",plant);mat.set_shader_parameter("altered",key.begins_with("ash-altered"))
			mat.set_shader_parameter("wind_period_s",cfg.wind_period_s);mat.set_shader_parameter("plant_bend",cfg.wind_bend_m_per_m);mat.set_shader_parameter("pulse_period_s",cfg.pulse_period_s)
			mesh.set_surface_override_material(s,mat);materials.append(mat)
	templates[key]=node
	return node

func update_lods()->void:
	if camera==null:return
	for entry:Dictionary in entries:
		var distance:float=camera.global_position.distance_to(entry.root.global_position)
		var level:int=forced_lod if forced_lod>=0 else (0 if distance<cfg.lod_distances_m[0] else (1 if distance<cfg.lod_distances_m[1] else 2))
		level=mini(level,entry.levels.size()-1);entry.lod=level
		for i in entry.levels.size():entry.levels[i].visible=i==level

func set_time(value:float)->void:
	clock_seconds=value
	for mat:ShaderMaterial in materials:
		mat.set_shader_parameter("clock_seconds",value);mat.set_shader_parameter("light_enabled",light_on)

func _process(delta:float)->void:
	if not automatic and not paused:set_time(clock_seconds+delta)
	if not automatic:update_lods()

func _physics_process(delta:float)->void:
	if body==null:return
	if automatic and not walk_active:return
	if paused:return
	var input:=Input.get_vector("c4_left","c4_right","c4_forward","c4_back")
	var d:Vector3=body.basis*Vector3(input.x,0,input.y)
	body.velocity.x=d.x*2.4;body.velocity.z=d.z*2.4;body.velocity.y-=15*delta
	body.move_and_slide()
	if walk_active:walk_samples.append({"x":body.position.x,"y":body.position.y,"z":body.position.z,"supported":body.is_on_floor()})

func reset_walk()->void:
	body.position=Vector3(0,ground(0,-14)+.015,-14);body.rotation=Vector3(0,PI,0);body.velocity=Vector3.ZERO;camera.position=Vector3(0,1.62,0);camera.rotation=Vector3.ZERO
func viewpoint(at:Vector3,target:Vector3)->void:
	body.position=at-Vector3.UP*1.62;body.rotation=Vector3.ZERO;camera.rotation=Vector3.ZERO;camera.look_at(target);update_lods()
func lighting(which:int)->void:
	mood=which
	sun.light_energy=[2.0,.45,.85][which];env.ambient_light_energy=[.7,.78,.42][which]
	sun.light_color=Color(1,.95,.83) if which<2 else Color(1,.64,.40)
	sun.rotation_degrees.x=-42 if which<2 else -12
func _unhandled_input(event:InputEvent)->void:
	if event is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED and not automatic:
		body.rotate_y(-event.relative.x*.002);camera.rotation.x=clampf(camera.rotation.x-event.relative.y*.002,-1.3,1.3)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			KEY_SPACE:paused=not paused
			KEY_L:lighting((mood+1)%3)
			KEY_M:light_on=not light_on;set_time(clock_seconds)
			KEY_R:reset_walk()
			KEY_0:forced_lod=-1;update_lods()
			KEY_1,KEY_2,KEY_3:forced_lod=event.physical_keycode-KEY_1;update_lods()
	if event is InputEventMouseButton and event.pressed and not automatic:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func shot(name:String)->void:
	label.text="ART-07C4 • recovering wastes | "+renderer+" | "+name+"\nAuthored model study • WASD / L light / M scar / Space pause / 0–3 detail"
	await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"actual capture "+name)
func write_json(name:String,value:Variant)->void:
	var f:=FileAccess.open(output+"/"+name,FileAccess.WRITE);f.store_string(JSON.stringify(value,"\t"))

func verify()->void:
	var errors:Array=[]
	var solid_contacts:Array=[]
	for entry:Dictionary in entries:
		var count:=0
		for level:Node3D in entry.levels:if level.visible:count+=1
		check(count==1,"one visible detail")
		var r:Dictionary=entry.row
		var q:=PhysicsRayQueryParameters3D.create(Vector3(r.x,2,r.z),Vector3(r.x,-2,r.z),2);q.exclude=[body.get_rid()]
		var hit:=get_world_3d().direct_space_state.intersect_ray(q)
		check(not hit.is_empty(),"ground support")
		var error:float=absf(hit.position.y-ground(r.x,r.z));check(error<.001,"ground interpolation");errors.append(error)
		if r.role in ["rock-shelf","talus-pebbles"] or "felled" in r.role:
			var minimum:=INF
			for mesh:MeshInstance3D in entry.levels[0].find_children("*","MeshInstance3D",true,false):
				for s in mesh.mesh.get_surface_count():
					for v:Vector3 in mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
						var p:Vector3=mesh.global_transform*v;minimum=minf(minimum,p.y-ground(p.x,p.z))
			check(absf(minimum+.012)<.001,"context contact from actual underside")
			solid_contacts.append({"role":r.role,"min_ground_gap_m":minimum})
		if r.role.begins_with("ash-") and not "felled" in r.role:
			for mesh:MeshInstance3D in entry.levels[0].find_children("*","MeshInstance3D",true,false):
				for s in mesh.mesh.get_surface_count():
					for v:Vector3 in mesh.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]:
						if v.y>=0 and v.y<=2.6:check(Vector2(v.x,v.z).length()<=.2901,"actual lower wood fits native body")
	var before:=clock_seconds;var before_auto:=automatic;automatic=false;paused=true;_process(1)
	check(clock_seconds==before,"pause freezes shader clock")
	paused=false;_process(.1);check(clock_seconds>before,"resume advances")
	automatic=before_auto;set_time(before)
	write_json("checks.json",{"assertions":checks_count,"failures":0,"ground_contacts":errors,"solid_contacts":solid_contacts,"models":entries.size(),"pause_resume":true,"device":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()})
	print("C4_REVIEW_CHECKS_OK ",checks_count)

func captures()->void:
	reset_walk();update_lods()
	for light in 3:lighting(light);await shot(["day","shade","dusk"][light])
	lighting(0)
	viewpoint(Vector3(-3.3,1.65,-11.4),Vector3(-2.5,1.5,-9));light_on=false;set_time(1.3);await shot("ash-scar-off");light_on=true;set_time(1.3);await shot("ash-scar-on")
	viewpoint(Vector3(-1.0,1.0,-6),Vector3(-3.7,.45,-5));await shot("felled-wood")
	viewpoint(Vector3(1.2,1.05,-4),Vector3(3,.45,-5));await shot("scrub-close")
	viewpoint(Vector3(-1,2,-4),Vector3(-4,1.7,-2))
	for i in 3:forced_lod=i;update_lods();await shot("lod-"+str(i))
	forced_lod=-1;update_lods();await verify();get_tree().quit()

func motion()->void:
	lighting(2);viewpoint(Vector3(-2.5,1.6,-10.8),Vector3(-2.5,1.5,-9))
	for i in 48:set_time(i*4.0/48);await shot("pulse-%03d"%i)
	lighting(0);viewpoint(Vector3(1.2,.8,-3.7),Vector3(3,.4,-5))
	for i in 48:set_time(i*5.5/48);await shot("wind-%03d"%i)
	paused=true
	for i in 12:await shot("paused-%03d"%i)
	paused=false
	write_json("motion.json",{"pulse_frames":48,"wind_frames":48,"paused_frames":12,"sampled_clock_not_fps":true})
	get_tree().quit()

func walking()->void:
	reset_walk();lighting(0);walk_active=true
	for i in 8:await get_tree().physics_frame
	walk_samples.clear();Input.action_press("c4_forward")
	var start:=body.position
	for i in 910:
		await get_tree().physics_frame;set_time(i/60.0);update_lods()
		if i%10==0:await shot("walk-%03d"%(i/10))
	Input.action_release("c4_forward");walk_active=false
	check(body.position.z-start.z>35,"physical 36 metre walk")
	check(walk_samples.all(func(r):return r.supported),"supported throughout route")
	check(walk_samples.all(func(r):return absf(r.x)<.08),"route clears native trunk bodies")
	write_json("walk.json",{"distance_m":body.position.distance_to(start),"samples":walk_samples,"assertions":checks_count,"fixture":"Input.action_press and CharacterBody move_and_slide; authored terrain and unchanged trunk body dimensions."})
	print("C4_WALK_OK ",body.position.distance_to(start));get_tree().quit()

func benchmark()->void:
	reset_walk();label.hide();DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var cases:Array=[]
	for force in [0,-1]:
		forced_lod=force;update_lods()
		for light in [0,2]:
			lighting(light)
			for i in 120:set_time(i/60.0);await get_tree().process_frame
			var wall:Array=[];var gpu:Array=[]
			for i in 600:
				var start:=Time.get_ticks_usec();set_time(i/60.0);await RenderingServer.frame_post_draw
				gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()));await get_tree().process_frame;wall.append((Time.get_ticks_usec()-start)/1000.0)
			wall.sort();gpu.sort()
			cases.append({"all_near":force==0,"lighting":light,"wall_p50_ms":wall[300],"wall_p95_ms":wall[570],"wall_worst_ms":wall[-1],"gpu_p50_ms":gpu[300],"gpu_p95_ms":gpu[570],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	write_json("benchmark.json",{"cases":cases,"device":RenderingServer.get_video_adapter_name(),"renderer":renderer,"viewport":[1440,900],"msaa":4,"vsync":false,"shadows":"32m orthogonal; plants off","samples":600,"warmup":120,"scope":"Small C4 authored fixed view; no whole-world or lower-spec budget approval."})
	print("C4_BENCHMARK_OK");get_tree().quit()

func _exit_tree()->void:
	for t:Node3D in templates.values():t.free()
