extends Node3D
## Posed C1 habitat on unchanged ART-02/B4 ground and water; native work is separate.
const Present=preload("res://present.gd")
var art:=Present.new()
var cfg:Dictionary
var entries:Array=[]
var camera:Camera3D
var env:Environment
var sun:DirectionalLight3D
var label:Label
var renderer:String
var output:String
var auto:=false
var force_lod:=-1
var mood:=0
var body:CharacterBody3D
var walk_active:=false
var samples:Array=[]

func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://kit.json"));renderer=RenderingServer.get_current_rendering_method();output="res://evidence/"+renderer;DirAccess.make_dir_recursive_absolute(output)
	auto=not OS.get_cmdline_user_args().is_empty();get_viewport().msaa_3d=Viewport.MSAA_4X
	for id in ["ground","water"]:
		var obj:Node3D=load("res://assets/"+id+".gltf").instantiate();add_child(obj);art.install(obj,id)
		if id=="ground":
			for m:MeshInstance3D in obj.find_children("*","MeshInstance3D",true,false):
				m.create_trimesh_collision()
				for c:StaticBody3D in m.find_children("*","StaticBody3D",true,false):c.collision_layer=2
	for row in [[-2.4,-4.5],[.6,4.2],[2.8,9.0],[-3.0,14.0]]:add_asset("bog-oak-full",row[0],row[1],0,false,Vector3(.7,3,.7))
	add_asset("bog-oak-worked",3.1,-2.5,0,false,Vector3(.7,3,.7))
	for row in [["clay-24",-3.3,1.0],["clay-12",-3.35,3.0],["clay-4",-3.5,5.0]]:add_asset(row[0],row[1],row[2],0,true,Vector3(1.8,.38,1.25))
	for row in [["reed-24",-3.4,-2.0],["reed-18",-4.1,0.0],["reed-12",-3.9,7.0],["reed-6",-3.8,9.0],["reed-24",-4.2,11.0],["reed-24",-4.7,13.0]]:add_asset(row[0],row[1],row[2],0,true,Vector3(1,1.3,1))
	add_asset("bog-oak-stump",2,-5.2,0,false);add_asset("clay-0",-2.8,-.5,0,true);add_asset("reed-0",-3.2,-.5,0,true)
	var rng:=RandomNumberGenerator.new();rng.seed=42
	for i in 40:
		var z:=rng.randf_range(-7,16);var x:=Present.river(z)+rng.randf_range(1.6,2.35)
		add_asset("fen-sedge",x,z,rng.randf_range(0,TAU),true)
	for row in [[-2.1,-3.9],[-2.5,7.1],[1.8,-4.8]]:add_asset("fungal-detritus",row[0],row[1],.4,false)
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world);env.background_mode=Environment.BG_SKY
	var sky:=Sky.new();var sm:=ProceduralSkyMaterial.new();sm.sky_top_color=Color(.24,.35,.42);sm.sky_horizon_color=Color(.56,.62,.61);sm.ground_bottom_color=Color(.12,.13,.11);sm.ground_horizon_color=sm.sky_horizon_color;sky.sky_material=sm;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.74,.82,.9);env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.glow_enabled=false
	sun=DirectionalLight3D.new();add_child(sun);sun.rotation_degrees=Vector3(-40,-32,0);sun.shadow_enabled=true;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL;sun.directional_shadow_max_distance=28
	camera=Camera3D.new();add_child(camera);camera.fov=66;camera.far=150;camera.make_current();overview()
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(20,18);label.add_theme_font_size_override("font_size",18);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_y",2)
	body=CharacterBody3D.new();add_child(body);body.collision_mask=3;body.floor_snap_length=.3
	var cs:=CollisionShape3D.new();var cap:=CapsuleShape3D.new();cap.radius=.32;cap.height=1.8;cs.shape=cap;cs.position.y=.9;body.add_child(cs);body.position=Vector3(-.8,Present.ground(-.8,-8)+.05,-8)
	lighting(0);for i in 12:await get_tree().physics_frame
	var args:=OS.get_cmdline_user_args()
	if "--capture" in args:await captures()
	elif "--motion" in args:await motion()
	elif "--benchmark" in args:await benchmark()
	elif "--check" in args:await checks();get_tree().quit()

func add_asset(id:String,x:float,z:float,yaw:float,conform:bool,collision:=Vector3.ZERO)->void:
	var anchor:=Node3D.new();add_child(anchor);anchor.position=Vector3(x,Present.ground(x,z),z);anchor.rotation.y=yaw
	var levels:Array=[]
	for lod in 3:
		var obj:Node3D=load("res://assets/"+id+"-lod%d.gltf"%lod).instantiate();anchor.add_child(obj);art.install(obj,id,conform);levels.append(obj)
		for mesh:MeshInstance3D in obj.find_children("*","MeshInstance3D",true,false):
			if id=="fen-sedge":mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if collision!=Vector3.ZERO:
		var cb:=StaticBody3D.new();anchor.add_child(cb);cb.collision_layer=1;var cs:=CollisionShape3D.new();cs.shape=BoxShape3D.new();cs.shape.size=collision;cs.position.y=collision.y/2;cb.add_child(cs)
	entries.append({"id":id,"anchor":anchor,"levels":levels,"conform":conform,"native_body":collision})
func update_lods()->void:
	for e:Dictionary in entries:
		var d:=camera.global_position.distance_to(e.anchor.position);var distances:Array=cfg.tree_lod_m if e.id.begins_with("bog-oak") else cfg.small_lod_m
		var lod:=force_lod if force_lod>=0 else (0 if d<distances[0] else (1 if d<distances[1] else 2))
		for i in 3:e.levels[i].visible=i==lod
func _process(delta:float)->void:
	if not auto:art.tick(delta)
	update_lods()
	if not auto and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		var d:=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		camera.position+=camera.basis*d*delta*4
func _physics_process(delta:float)->void:
	if body==null:return
	body.velocity=Vector3(0,body.velocity.y-18*delta,2 if walk_active else 0);body.move_and_slide()
	if walk_active:samples.append({"p":var_to_str(body.position),"floor":body.is_on_floor()})
func _unhandled_input(e:InputEvent)->void:
	if auto:return
	if e is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:camera.rotation.y-=e.relative.x*.002;camera.rotation.x=clampf(camera.rotation.x-e.relative.y*.002,-1.4,1.4)
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode==KEY_SPACE:art.paused=not art.paused
		if e.keycode==KEY_L:lighting((mood+1)%3)
		if e.keycode==KEY_R:overview()
		if e.keycode>=KEY_0 and e.keycode<=KEY_3:force_lod=e.keycode-KEY_1
		if e.keycode==KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
func view(at:Vector3,target:Vector3)->void:camera.position=at;camera.look_at(target)
func overview()->void:view(Vector3(7,4,-12),Vector3(-1.2,2.2,3.5))
func lighting(i:int)->void:
	mood=i;sun.light_energy=[1.65,.40,.65][i];sun.light_color=[Color(1,.94,.82),Color(.73,.82,.91),Color(1,.59,.34)][i];env.ambient_light_energy=[.8,.5,.38][i]
	label.text="ART-07C1 · Lantern Fen / Rustwater | "+["day","shade","dusk"][i]+"\nPosed art review; native harvesting/reload is a separate fixture. L light · Space pause · 0–3 detail · WASD/QE camera"
func write_json(name:String,value:Variant)->void:
	var f:=FileAccess.open(output+"/"+name,FileAccess.WRITE);assert(f!=null);f.store_string(JSON.stringify(value,"\t"));f.close()
func shot(name:String)->void:
	update_lods();for i in 3:await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK)
func captures()->void:
	for i in 3:lighting(i);overview();art.set_time(1.1);await shot(["day","shade","dusk"][i])
	lighting(0);force_lod=0
	view(Vector3(-.7,1.7,-2.8),Vector3(-3.3,.2,1));await shot("clay-bank-contact")
	view(Vector3(-1.7,1.7,-4.6),Vector3(-3.5,.25,-1));await shot("reeds-and-sedge")
	view(Vector3(-.8,1.1,-6.2),Vector3(-2.4,.5,-4.3));await shot("oak-root-and-fungi")
	view(Vector3(4.5,1.25,-4.7),Vector3(3.1,.8,-2.5));await shot("oak-work-wound")
	view(Vector3(8,7,-10),Vector3(-1,3,2));for lod in 3:force_lod=lod;await shot("detail-%d"%lod)
	force_lod=-1;await checks();print("C1_CAPTURE_OK");get_tree().quit()
func motion()->void:
	lighting(0);force_lod=0;view(Vector3(-1.7,1.7,-4.6),Vector3(-3.5,.25,-1))
	for i in 66:art.set_time(i/12.0);await shot("wind-%03d"%i)
	art.paused=true
	for i in 12:art.tick(.1);await shot("paused-%03d"%i)
	art.paused=false;art.tick(.5);await shot("resumed");print("C1_MOTION_OK");get_tree().quit()
func checks()->void:
	var contacts:Array=[];var max_error:=0.0;var footprints:Array=[]
	for e:Dictionary in entries:
		var p:Vector3=e.anchor.position;var q:=PhysicsRayQueryParameters3D.create(p+Vector3.UP*4,p-Vector3.UP*4,2);var hit:=get_world_3d().direct_space_state.intersect_ray(q)
		assert(not hit.is_empty(),"ground contact ray");var error:float=absf(hit.position.y-p.y);assert(error<.0001,"retained terrain interpolation");max_error=maxf(max_error,error);contacts.append({"id":e.id,"anchor":var_to_str(p),"support_error_m":error})
		if e.conform:
			var roots:=0;var gap:=0.0;var peak:=-INF;var buried:=0.0
			for mesh:MeshInstance3D in e.levels[0].find_children("*","MeshInstance3D",true,false):
				for surface in mesh.mesh.get_surface_count():
					var vertices:PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
					for v:Vector3 in vertices:
						var w:Vector3=mesh.global_transform*v;var dy:=Present.ground(w.x,w.z)-p.y
						if e.id.begins_with("clay"):w.y=minf(w.y+dy,p.y+cfg.clay_seated_top_m)
						else:w.y+=dy*(1-smoothstep(cfg.plant_seating_fade_m[0],cfg.plant_seating_fade_m[1],v.y))
						peak=maxf(peak,w.y-p.y);buried=minf(buried,w.y-Present.ground(w.x,w.z))
						if v.y<=.03 and v.y>=-.001:
							roots+=1;gap=maxf(gap,maxf(0,w.y-Present.ground(w.x,w.z)))
			assert(roots>0 and gap<=.031,"actual rooted footprint remains on retained bank")
			if e.native_body!=Vector3.ZERO:assert(peak<=e.native_body.y+.0001,"seated upper geometry fits original native height")
			footprints.append({"id":e.id,"root_vertices":roots,"max_positive_root_gap_m":gap,"max_height_above_body_origin_m":peak,"max_burial_m":-buried,"method":"Actual imported vertices and same shader seating formula, against retained triangle terrain; no stock/body/geography adjustment."})
		for lod in 3:
			force_lod=lod;update_lods();var visible_count:=0
			for l:Node3D in e.levels:if l.visible:visible_count+=1
			assert(visible_count==1)
	var t:=art.clock_seconds;art.paused=true;art.tick(1);assert(art.clock_seconds==t);art.paused=false;art.tick(.5);assert(art.clock_seconds==t+.5)
	walk_active=true
	while body.position.z<8 and samples.size()<650:await get_tree().physics_frame
	walk_active=false;assert(body.position.z>=8,"native-sized bodies leave route open")
	for sample:Dictionary in samples:assert(sample.floor,"supported walk")
	write_json("checks.json",{"contacts":contacts,"footprints":footprints,"max_support_error_m":max_error,"walk_samples":samples.size(),"walk_end":var_to_str(body.position),"capsule":[.32,1.8],"exclusive_lods":true,"pause_resume":true,"materials":art.materials.size(),"device":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()})
	force_lod=-1;print("C1_CHECKS_OK ",contacts.size()," contacts ",samples.size()," supported walking samples")
func benchmark()->void:
	overview();label.hide();DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var cases:Array=[]
	for near in [true,false]:
		force_lod=0 if near else -1;update_lods()
		for light in [0,2]:
			lighting(light);label.hide()
			for i in 120:art.set_time(i/60.0);await get_tree().process_frame
			var wall:Array=[];var gpu:Array=[]
			for i in 600:
				var start:=Time.get_ticks_usec();art.set_time(i/60.0);await RenderingServer.frame_post_draw;gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()));await get_tree().process_frame;wall.append((Time.get_ticks_usec()-start)/1000.0)
			wall.sort();gpu.sort();cases.append({"all_near":near,"lighting":light,"wall_p50_ms":wall[300],"wall_p95_ms":wall[570],"worst_ms":wall[-1],"gpu_p50_ms":gpu[300],"gpu_p95_ms":gpu[570],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	write_json("benchmark.json",{"cases":cases,"adapter":RenderingServer.get_video_adapter_name(),"renderer":renderer,"size":[1440,900],"msaa":4,"vsync":false,"samples":600,"warmup":120});print("C1_BENCHMARK_OK");get_tree().quit()
