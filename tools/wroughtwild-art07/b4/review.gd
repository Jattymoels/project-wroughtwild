extends Node3D
## Isolated ART-02 landform and B1-B3 source composition. No native game/save objects.
const Sound = preload("res://art/environment_sound.gd")
const SoundLook = preload("res://art/environment_sound_look.tres")
var cfg:Dictionary
var layout:Array
var templates:Dictionary={}
var materials:Dictionary={}
var trees:Array=[]
var batches:Array=[]
var tree_batches:Array=[]
var rocks:Array=[]
var visible_tree_counts:Dictionary={}
var camera:Camera3D
var body:CharacterBody3D
var sun:DirectionalLight3D
var env:Environment
var label:Label
var voice:AudioStreamPlayer
var rng:=RandomNumberGenerator.new()
var quiet_left:=15.0
var clip_left:=0.0
var last_variant:=-1
var muted:=false
var paused:=false
var automated:=false
var walking:=false
var clock_seconds:=0.0
var light_on:=true
var force_lod:=-1
var cost_baseline:=false
var mood:=0
var renderer:=""
var output:=""
var route_samples:Array=[]
var audio_events:Array=[]

func analytic_ground(x:float,z:float)->float:
	var r:=absf(x-river(z))
	return 1.25*(1.0-exp(-pow(r/3.0,4.0)))-.8+.13*sin(x*.31+z*.19)+.10*cos(z*.34-x*.22)+maxf(0,absf(x)-9)*.035+3.4*exp(-pow((z-34)/10.0,2.0))
func ground(x:float,z:float)->float:
	var a:=floorf(x*2)*.5;var b:=floorf(z*2)*.5;var u:=(x-a)*2;var v:=(z-b)*2
	var h00:=analytic_ground(a,b);var h10:=analytic_ground(a+.5,b);var h01:=analytic_ground(a,b+.5);var h11:=analytic_ground(a+.5,b+.5)
	return h00+u*(h10-h00)+v*(h01-h00) if u+v<=1 else h11+(1-u)*(h01-h11)+(1-v)*(h10-h11)
func river(z:float)->float:return -5.8+sin(z*.12)+.35*sin(z*.31)
func route(z:float)->float:return .9*sin(z*.15)+.35*sin(z*.33)

func _ready()->void:
	cfg=JSON.parse_string(FileAccess.get_file_as_string("res://scene.json"));layout=JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	renderer=RenderingServer.get_current_rendering_method();output="res://evidence/"+renderer;DirAccess.make_dir_recursive_absolute(output)
	rng.seed=cfg.seed
	var args:=OS.get_cmdline_user_args();automated=not args.is_empty()
	var ground_node:Node3D=load("res://assets/ground.gltf").instantiate();add_child(ground_node)
	for mesh in ground_node.find_children("*","MeshInstance3D",true,false):
		var fm:=ShaderMaterial.new();fm.shader=load("res://surface.gdshader");fm.set_shader_parameter("role",5)
		fm.set_shader_parameter("albedo_map",load("res://forest-floor.png"));mesh.material_override=fm;materials.ground=fm;mesh.create_trimesh_collision()
		for collider in mesh.find_children("*","StaticBody3D",true,false):collider.collision_layer=2
	var wn:Node3D=load("res://assets/water.gltf").instantiate();add_child(wn)
	for mesh in wn.find_children("*","MeshInstance3D",true,false):
		var wm:=ShaderMaterial.new();wm.shader=load("res://surface.gdshader");wm.set_shader_parameter("role",6);wm.set_shader_parameter("water_flow",cfg.water_flow_m_s);mesh.material_override=wm;materials.water=wm
	var grouped:Dictionary={}
	for row:Dictionary in layout:
		if row.role in ["broadleaf-a","broadleaf-altered","pine-a"]:add_tree(row)
		elif row.role in ["river-bank","rock-shelf","rock-shelf-altered","talus-pebbles"]:add_rock(row)
		else:
			var key:String=row.role+":"+str(floori(row.x/cfg.plant_batch_m))+":"+str(floori(row.z/cfg.plant_batch_m))
			if not grouped.has(key):grouped[key]=[]
			grouped[key].append(row)
	for key:String in grouped:add_batch(grouped[key])
	add_tree_batches()
	add_rock_batches()
	body=CharacterBody3D.new();body.name="ReviewCapsule";add_child(body);body.floor_snap_length=.3;body.collision_mask=3
	var cs:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.height=1.8;capsule.radius=.32;cs.shape=capsule;cs.position.y=.9;body.add_child(cs)
	camera=Camera3D.new();body.add_child(camera);camera.position.y=1.62;camera.fov=68;camera.far=130;camera.make_current();reset_walk()
	for pair in [["b4_forward",KEY_W],["b4_back",KEY_S],["b4_left",KEY_A],["b4_right",KEY_D]]:
		InputMap.add_action(pair[0]);var event:=InputEventKey.new();event.physical_keycode=pair[1];InputMap.action_add_event(pair[0],event)
	var world:=WorldEnvironment.new();env=Environment.new();world.environment=env;add_child(world)
	env.background_mode=Environment.BG_SKY;var sky:=Sky.new();var sky_mat:=ProceduralSkyMaterial.new();sky_mat.sky_top_color=Color(.24,.37,.46);sky_mat.sky_horizon_color=Color(.55,.61,.59);sky_mat.ground_bottom_color=Color(.12,.13,.10);sky_mat.ground_horizon_color=Color(.55,.61,.59);sky.sky_material=sky_mat;env.sky=sky
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color(.69,.8,.86);env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;env.glow_enabled=false
	sun=DirectionalLight3D.new();add_child(sun);sun.rotation_degrees=Vector3(-38,-35,0);sun.shadow_enabled=true;sun.directional_shadow_max_distance=cfg.shadow_view_m;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_ORTHOGONAL
	get_viewport().msaa_3d=Viewport.MSAA_4X
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(22,18);label.add_theme_font_size_override("font_size",18);label.add_theme_color_override("font_shadow_color",Color.BLACK);label.add_theme_constant_override("shadow_offset_x",1);label.add_theme_constant_override("shadow_offset_y",2)
	voice=AudioStreamPlayer.new();add_child(voice);voice.volume_db=SoundLook.outdoor_gain_db
	Sound.prepare();lighting(0);set_time(0)
	for i in 16:await get_tree().physics_frame
	if "--capture" in args:await captures()
	elif "--walk" in args:await walk_capture()
	elif "--motion" in args:await motion()
	elif "--benchmark" in args:await benchmark()
	elif "--check" in args:await checks();get_tree().quit()
	else:Input.mouse_mode=Input.MOUSE_MODE_CAPTURED

func model(key:String)->Node3D:
	if not templates.has(key):
		var t:Node3D=load("res://assets/"+key+".gltf").instantiate()
		for m in t.find_children("*","MeshInstance3D",true,false):
			var name_lower:String=m.name.to_lower();var role:=4
			if key.begins_with("broadleaf") or key.begins_with("pine"):role=1 if "foliage" in name_lower else (2 if "branchlets" in name_lower else 0)
			elif key in ["fern-lush","fern-sparse","grass-meadow","grass-edge","moss","leaf-litter","sapling-shrub"]:role=3
			var old:StandardMaterial3D=m.mesh.surface_get_material(0)
			var tex:Texture2D=old.albedo_texture
			var altered:bool="altered" in key
			var conformed:bool=role==3
			var still:bool=key in ["moss","leaf-litter"]
			var mk:=str(role)+":"+str(altered)+":"+str(still)+":"+(tex.resource_path if tex!=null else "vertex")
			if not materials.has(mk):
				var mat:=ShaderMaterial.new();mat.shader=load("res://surface.gdshader");mat.set_shader_parameter("role",role);mat.set_shader_parameter("altered",altered);mat.set_shader_parameter("ground_conform",conformed);mat.set_shader_parameter("textured",tex!=null)
				if tex!=null:mat.set_shader_parameter("albedo_map",tex)
				if old.roughness_texture!=null:mat.set_shader_parameter("orm_map",old.roughness_texture);mat.set_shader_parameter("has_orm",true)
				mat.set_shader_parameter("leaf_colour_gain",Vector3(cfg.leaf_colour_gain[0],cfg.leaf_colour_gain[1],cfg.leaf_colour_gain[2]))
				mat.set_shader_parameter("wind_period_s",cfg.wind_period_s);mat.set_shader_parameter("leaf_tip_m",cfg.leaf_tip_m);mat.set_shader_parameter("plant_bend",cfg.plant_bend_m_per_m if key not in ["moss","leaf-litter"] else 0.0);mat.set_shader_parameter("pulse_period_s",cfg.pulse_period_s)
				materials[mk]=mat
			m.material_override=materials[mk]
		# These parts share one shader material: concatenate real triangles once.
		if key.begins_with("talus-pebbles") or key in ["fern-lush","fern-sparse"]:
			var parts:=t.find_children("*","MeshInstance3D",true,false)
			var combined:=SurfaceTool.new();combined.begin(Mesh.PRIMITIVE_TRIANGLES)
			for part:MeshInstance3D in parts:
				assert(part.material_override==parts[0].material_override)
				combined.append_from(part.mesh,0,part.transform)
			var joined:=MeshInstance3D.new();joined.name="SharedTalus";joined.mesh=combined.commit();joined.material_override=parts[0].material_override;t.add_child(joined)
			for part:MeshInstance3D in parts:part.get_parent().remove_child(part);part.free()
		templates[key]=t
	return templates[key].duplicate()

func pose(node:Node3D,row:Dictionary)->void:
	node.position=Vector3(row.x,row.y,row.z);node.rotation.y=row.yaw;node.scale=Vector3.ONE*float(row.scale)
func add_tree(row:Dictionary)->void:
	var root:=Node3D.new();add_child(root);pose(root,row);var levels:Array=[]
	for i in 3:
		var t:=model(row.role+"-"+str(i));root.add_child(t);levels.append(t)
		if i==0:
			for mesh in t.find_children("*","MeshInstance3D",true,false):
				if "foliage" not in mesh.name.to_lower() and "branchlets" not in mesh.name.to_lower():mesh.create_trimesh_collision()
	trees.append({"root":root,"levels":levels,"role":row.role,"lod":-1})
func add_tree_batches()->void:
	for family in ["broadleaf-a","broadleaf-altered","pine-a"]:
		var members:=trees.filter(func(t):return t.role==family)
		for level in 4:
			var meshes:Array=members[0].levels[mini(level,2)].find_children("*","MeshInstance3D",true,false)
			for surface in meshes.size():
				var mesh:MeshInstance3D=meshes[surface]
				var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh.mesh;mm.instance_count=members.size();mm.visible_instance_count=0
				var instance:=MultiMeshInstance3D.new();instance.multimesh=mm;instance.material_override=mesh.material_override;add_child(instance)
				instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY if level==3 else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
				tree_batches.append({"node":instance,"level":level,"members":members,"transform":mesh.transform,"first_surface":surface==0})
func add_rock(row:Dictionary)->void:
	var key:String=row.role+"-"+("0" if "altered" in row.role or row.scale<2 else "1")
	var t:=model(key);add_child(t);pose(t,row);rocks.append({"root":t,"key":key})
	if row.role!="talus-pebbles":
		for mesh in t.find_children("*","MeshInstance3D",true,false):mesh.create_trimesh_collision()
func add_rock_batches()->void:
	var groups:Dictionary={}
	for rock:Dictionary in rocks:
		if not groups.has(rock.key):groups[rock.key]=[]
		groups[rock.key].append(rock.root);rock.root.visible=false
	for group:Array in groups.values():
		for mesh in group[0].find_children("*","MeshInstance3D",true,false):
			var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh.mesh;mm.instance_count=group.size()
			for i in group.size():mm.set_instance_transform(i,group[i].transform*mesh.transform)
			var instance:=MultiMeshInstance3D.new();instance.multimesh=mm;instance.material_override=mesh.material_override;add_child(instance)
func add_batch(rows:Array)->void:
	var t:=model(rows[0].role);var center:=Vector3.ZERO
	for row:Dictionary in rows:center+=Vector3(row.x,row.y,row.z)
	center/=rows.size()
	for mesh in t.find_children("*","MeshInstance3D",true,false):
		var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh.mesh;mm.instance_count=rows.size()
		for i in rows.size():
			var row:Dictionary=rows[i];var tr:=Transform3D(Basis(Vector3.UP,row.yaw).scaled(Vector3.ONE*float(row.scale)),Vector3(row.x,row.y,row.z));mm.set_instance_transform(i,tr*mesh.transform)
		var instance:=MultiMeshInstance3D.new();instance.multimesh=mm;instance.material_override=mesh.material_override;add_child(instance);instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		batches.append({"node":instance,"center":center,"role":rows[0].role,"count":rows.size()})
	t.free()

func update_lods()->void:
	if camera==null:return
	visible_tree_counts.clear()
	for tree:Dictionary in trees:
		var distance:float=camera.global_position.distance_to(tree.root.global_position)
		var lod:int=force_lod if force_lod>=0 else (0 if distance<cfg.tree_lod_m[0] else (1 if distance<cfg.tree_lod_m[1] else 2))
		if cost_baseline:lod=0
		for i in 3:
			tree.levels[i].visible=cost_baseline and i==0
			for mesh in tree.levels[i].find_children("*","MeshInstance3D",true,false):mesh.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED if cost_baseline else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		tree.lod=lod
	for batch:Dictionary in tree_batches:
		var count:=0
		for tree:Dictionary in batch.members:
			var selected:bool=tree.lod==batch.level if batch.level<3 else camera.global_position.distance_to(tree.root.global_position)<cfg.shadow_distance_m
			if selected and not cost_baseline:
				batch.node.multimesh.set_instance_transform(count,tree.root.transform*batch.transform);count+=1
				if batch.level<3 and batch.first_surface:visible_tree_counts[tree.root.get_instance_id()]=int(visible_tree_counts.get(tree.root.get_instance_id(),0))+1
		batch.node.multimesh.visible_instance_count=count;batch.node.visible=count>0
	for batch:Dictionary in batches:
		batch.node.visible=cost_baseline or camera.global_position.distance_to(batch.center)<cfg.plant_cutoff_m+cfg.plant_batch_m/sqrt(2.0)
		batch.node.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_DOUBLE_SIDED if cost_baseline else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
func set_time(t:float)->void:
	clock_seconds=t
	for mat:ShaderMaterial in materials.values():mat.set_shader_parameter("clock_seconds",t);mat.set_shader_parameter("light_enabled",light_on)
func lighting(i:int)->void:
	mood=i;sun.light_energy=[1.5,.3,.62][i];sun.light_color=[Color(1,.94,.83),Color(.78,.86,1),Color(1,.64,.38)][i];env.ambient_light_energy=[.68,.58,.42][i]
	label.text="ART-07B4 • actual composed models • "+["DAY","SHADE","DUSK"][i]+" • "+renderer+"\nWASD/mouse walk • L light • M scars • Space pause • Q quiet/mute • R start • 0–3 detail"
func reset_walk()->void:
	body.position=Vector3(route(cfg.route_start_z),ground(route(cfg.route_start_z),cfg.route_start_z)+.05,cfg.route_start_z);body.rotation=Vector3(0,PI,0);body.velocity=Vector3.ZERO;camera.position=Vector3(0,1.62,0);camera.rotation=Vector3(-.025,0,0)
func view(at:Vector3,target:Vector3)->void:
	camera.global_position=at;camera.look_at(target)
func tick_audio(delta:float)->void:
	if paused or muted:return
	if clip_left>0:clip_left=maxf(0,clip_left-delta);return
	quiet_left-=delta
	if quiet_left<=0:
		var variant:=(last_variant+1+rng.randi_range(0,1))%3;last_variant=variant
		voice.stream=Sound.clip("foliage",variant);clip_left=voice.stream.get_length();quiet_left=rng.randf_range(SoundLook.quiet_seconds.x,SoundLook.quiet_seconds.y);voice.play()
		audio_events.append({"time":clock_seconds,"duration":clip_left,"next_quiet":quiet_left,"variant":variant,"gain_db":voice.volume_db})
func _process(delta:float)->void:
	if not paused and (not automated or walking):set_time(clock_seconds+delta);tick_audio(delta)
	update_lods()
func _physics_process(delta:float)->void:
	if body==null or paused:return
	if walking:
		var z:float=body.position.z;var target:=Vector3(route(z+1),body.position.y,z+1)
		body.look_at(target,Vector3.UP)
	if walking or not automated:
		var input:=Input.get_vector("b4_left","b4_right","b4_forward","b4_back")
		var direction:=body.basis*Vector3(input.x,0,input.y)
		body.velocity.x=direction.x*cfg.walk_speed_m_s;body.velocity.z=direction.z*cfg.walk_speed_m_s
	else:body.velocity.x=0;body.velocity.z=0
	body.velocity.y-=18*delta;body.move_and_slide()
	if walking:route_samples.append({"p":[body.position.x,body.position.y,body.position.z],"floor":body.is_on_floor(),"speed":Vector2(body.velocity.x,body.velocity.z).length()})
func _unhandled_input(e:InputEvent)->void:
	if automated:return
	if e is InputEventMouseMotion and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		body.rotation.y-=e.relative.x*.002;camera.rotation.x=clampf(camera.rotation.x-e.relative.y*.002,-1.4,1.4)
	if e is InputEventKey and e.pressed and not e.echo:
		if e.keycode==KEY_SPACE:paused=not paused;voice.stream_paused=paused
		if e.keycode==KEY_L:lighting((mood+1)%3)
		if e.keycode==KEY_M:light_on=not light_on;set_time(clock_seconds)
		if e.keycode==KEY_Q:muted=not muted;voice.stop();clip_left=0;quiet_left=15
		if e.keycode==KEY_R:reset_walk()
		if e.keycode>=KEY_0 and e.keycode<=KEY_3:force_lod=e.keycode-KEY_1
		if e.keycode==KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if Input.mouse_mode==Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED
func write_json(name:String,value:Variant)->void:
	var f:=FileAccess.open(output+"/"+name,FileAccess.WRITE);assert(f!=null);f.store_string(JSON.stringify(value,"\t"))
func shot(name:String)->void:
	set_time(clock_seconds);update_lods();for i in 3:await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK)

func captures()->void:
	for i in 3:
		lighting(i);reset_walk();set_time(1.1);await shot("walk-"+["day","shade","dusk"][i])
	lighting(1);view(Vector3(3.6,2.2,5.8),Vector3(4.8,2.3,0));force_lod=0
	light_on=false;set_time(1.0);await shot("tree-scar-off");light_on=true;await shot("tree-scar-on")
	view(Vector3(2.4,1.6,-.8),Vector3(2.9,.8,-2.8));light_on=false;await shot("rock-scar-off");light_on=true;await shot("rock-scar-on")
	lighting(0);view(Vector3(-2.1,1.4,10),Vector3(-5.9,-.4,6));await shot("water-bank-contact")
	view(Vector3(2,1.2,12),Vector3(4.9,.4,14));await shot("root-contact")
	view(Vector3(.1,.95,9),Vector3(2.3,.6,7));await shot("ground-contact")
	view(Vector3(.3,2.1,-18),Vector3(-.2,3,15));force_lod=-1;await shot("distance-auto")
	for lod in 3:force_lod=lod;await shot("distance-"+str(lod))
	force_lod=-1;await checks();print("B4_CAPTURE_OK ",renderer);get_tree().quit()

func walk_capture()->void:
	reset_walk();lighting(0);set_time(0);for i in 20:await get_tree().physics_frame
	walking=true;Input.action_press("b4_forward");var frame:=0
	while body.position.z<cfg.route_end_z and route_samples.size()<1600:
		for i in 8:await get_tree().physics_frame
		await shot("walk-%03d"%frame);frame+=1
	Input.action_release("b4_forward");walking=false
	assert(body.position.z>=cfg.route_end_z,"route blocked")
	var length:=0.0;var unsupported:=0;var error:=0.0
	for i in route_samples.size():
		var s:Dictionary=route_samples[i];if not s.floor:unsupported+=1
		error=maxf(error,absf(s.p[0]-route(s.p[2])))
		if i>0:length+=Vector3(s.p[0],s.p[1],s.p[2]).distance_to(Vector3(route_samples[i-1].p[0],route_samples[i-1].p[1],route_samples[i-1].p[2]))
	assert(unsupported==0);assert(error<.45)
	write_json("walk.json",{"samples":route_samples,"length_m":length,"unsupported":unsupported,"route_error_m":error,"frames":frame,"capsule_radius_m":.32,"capsule_height_m":1.8,"input":"Input.action_press; CharacterBody3D.move_and_slide; no route teleports","audio_events":audio_events})
	print("B4_WALK_OK ",length," m ",route_samples.size()," supported samples");get_tree().quit()

func motion()->void:
	lighting(1);force_lod=0;view(Vector3(3.6,2.2,5.8),Vector3(4.8,2.3,0))
	for i in 48:set_time(float(i)/12);await shot("pulse-%03d"%i)
	lighting(0);view(Vector3(-1.5,1.4,10),Vector3(-5,.1,6))
	for i in 48:set_time(float(i)/12);await shot("water-wind-%03d"%i)
	paused=true;for i in 12:await shot("paused-%03d"%i)
	print("B4_MOTION_OK");get_tree().quit()

func checks()->void:
	for tree:Dictionary in trees:
		if tree.role=="broadleaf-altered":
			for mesh in tree.levels[0].find_children("*","MeshInstance3D",true,false):
				var mat:ShaderMaterial=mesh.material_override
				if mat.get_shader_parameter("role")==0:
					assert(mat.get_shader_parameter("altered"))
					var uv:PackedVector2Array=mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV2]
					var maximum:=0.0;for p in uv:maximum=maxf(maximum,p.x)
					assert(maximum>.85 and maximum<1.01)
					print("B4_SCAR_UV ",mesh.name," max_core ",maximum," root_rotation ",tree.root.rotation)
	var before:=clock_seconds;paused=true;var old_auto:=automated;automated=false
	for i in 10:await get_tree().process_frame
	assert(clock_seconds==before)
	for mat:ShaderMaterial in materials.values():assert(mat.get_shader_parameter("clock_seconds")==before)
	paused=false;for i in 4:await get_tree().process_frame
	assert(clock_seconds>before);automated=old_auto
	var cases:Array=[]
	for distance in [cfg.tree_lod_m[0]-1,cfg.tree_lod_m[0]+1,cfg.tree_lod_m[1]+1]:
		camera.global_position=trees[0].root.global_position+Vector3(0,0,distance);force_lod=-1;update_lods()
		assert(visible_tree_counts.size()==trees.size())
		for count:int in visible_tree_counts.values():assert(count==1)
		var expected:=0 if distance<cfg.tree_lod_m[0] else (1 if distance<cfg.tree_lod_m[1] else 2);assert(trees[0].lod==expected);cases.append({"distance":distance,"lod":expected})
	# The shader's support is checked against actual sampled terrain collision.
	var gaps:Array=[];var max_error:=0.0
	for row:Dictionary in layout:
		var query:=PhysicsRayQueryParameters3D.create(Vector3(row.x,12,row.z),Vector3(row.x,-4,row.z))
		query.exclude=[body.get_rid()]
		var hit:=get_world_3d().direct_space_state.intersect_ray(query)
		assert(not hit.is_empty())
		# Plant terrain contacts need terrain-only rays; rocks/trunks may overhang them.
		if row.role in ["fern-lush","fern-sparse","grass-meadow","grass-edge","moss","leaf-litter"]:
			var terrain_error:float=absf(ground(row.x,row.z)-row.y);assert(terrain_error<.00001)
			gaps.append({"role":row.role,"origin_ground_error":terrain_error})
	# Isolate the unchanged ART-02 sampled mesh with direct triangle interpolation.
	for x in range(-4,5):
		for z in range(-20,21):
			var px:float=x+.23;var pz:float=z+.17
			var q:=PhysicsRayQueryParameters3D.create(Vector3(px,ground(px,pz)+.06,pz),Vector3(px,ground(px,pz)-.1,pz))
			q.exclude=[body.get_rid()];q.collision_mask=2;var hit:=get_world_3d().direct_space_state.intersect_ray(q)
			assert(not hit.is_empty());max_error=maxf(max_error,absf(hit.position.y-ground(px,pz)))
	assert(max_error<.012)
	# Exercise this scene's actual scheduling function over three accelerated minutes.
	quiet_left=15;clip_left=0;audio_events.clear();last_variant=-1;rng.seed=42
	for i in 3600:set_time(float(i)*.05);tick_audio(.05)
	assert(audio_events.size()>=6 and audio_events.size()<=12)
	for i in audio_events.size():
		var event:Dictionary=audio_events[i];assert(event.duration>=1.6 and event.duration<=2.4)
		assert(Sound.clip("foliage",event.variant).loop_mode==AudioStreamWAV.LOOP_DISABLED)
		if i>0:
			var gap:float=event.time-audio_events[i-1].time-audio_events[i-1].duration
			assert(gap>=12 and gap<=24.11);assert(event.variant!=audio_events[i-1].variant)
	var q:=quiet_left;var c:=clip_left;paused=true;tick_audio(5);assert(quiet_left==q and clip_left==c);paused=false;voice.stop()
	write_json("checks.json",{"pause_resume":true,"exclusive_lods":cases,"plant_origins":gaps,"terrain_max_error_m":max_error,"quiet_pcm_schedule":audio_events,"materials_shared":materials.size(),"plant_batches":batches.size(),"trees":trees.size(),"renderer":renderer,"device":RenderingServer.get_video_adapter_name(),"engine":Engine.get_version_info()})
	print("B4_CHECKS_OK ",gaps.size()," contacts, terrain ",max_error)

func benchmark()->void:
	label.visible=false;reset_walk();DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var cases:Array=[]
	for baseline in [true,false]:
		cost_baseline=baseline;sun.directional_shadow_mode=DirectionalLight3D.SHADOW_PARALLEL_4_SPLITS if baseline else DirectionalLight3D.SHADOW_ORTHOGONAL;sun.directional_shadow_max_distance=45 if baseline else cfg.shadow_view_m;update_lods()
		for light in [0,2]:
			lighting(light);label.visible=false
			for i in 120:set_time(float(i)/60);await get_tree().process_frame
			var wall:Array=[];var gpu:Array=[]
			for i in 600:
				var start:=Time.get_ticks_usec();set_time(float(i)/60);await RenderingServer.frame_post_draw
				gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()));await get_tree().process_frame;wall.append((Time.get_ticks_usec()-start)/1000.0)
			wall.sort();gpu.sort()
			cases.append({"all_near_and_shadows":baseline,"lighting":light,"wall_p50_ms":wall[300],"wall_p95_ms":wall[570],"wall_worst_ms":wall[-1],"gpu_p50_ms":gpu[300],"gpu_p95_ms":gpu[570],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	write_json("benchmark.json",{"cases":cases,"warmup":120,"samples":600,"size":[1440,900],"msaa":4,"vsync":false,"adapter":RenderingServer.get_video_adapter_name(),"renderer":renderer,"budget":cfg.candidate_budget})
	print("B4_BENCHMARK_OK");get_tree().quit()

func _exit_tree()->void:
	if is_instance_valid(voice):voice.stop()
	Sound._clips.clear()
	for template:Node3D in templates.values():template.free()
