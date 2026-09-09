extends Node3D
## Isolated art setting. No extension, world save, gathering or combat state.
var cfg: Dictionary
var layout: Dictionary
var camera: Camera3D
var body: CharacterBody3D
var capsule: CapsuleShape3D
var sky: Environment
var sun: DirectionalLight3D
var caption: Label
var surface_materials: Array[ShaderMaterial] = []
var boar_material: ShaderMaterial
var tree_material: ShaderMaterial
var quiet_tree_material: ShaderMaterial
var rock_material: ShaderMaterial
var water_material: ShaderMaterial
var animations: Array[AnimationPlayer] = []
var shapes: Dictionary = {}
var scene_cache: Dictionary = {}
var automatic := false
var paused := false
var light_enabled := true
var clock := 0.0
var lighting := "day"
var pitch := 0.0
var route: Array = []
var records: Array = []
var material_names: Dictionary = {}
var output := "res://evidence"

func v(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])

func _ready() -> void:
	cfg = JSON.parse_string(FileAccess.get_file_as_string("res://grove.json"))
	layout = JSON.parse_string(FileAccess.get_file_as_string("res://layout.json"))
	route = layout.route
	DirAccess.make_dir_recursive_absolute(output)
	for i in 4:
		var mat := ShaderMaterial.new()
		mat.shader = load("res://grove_surface.gdshader")
		mat.set_shader_parameter("host", i)
		mat.set_shader_parameter("floor_texture",load("res://forest-floor.png"))
		for key in ["period_seconds", "peak_emission", "minimum_light"]:
			mat.set_shader_parameter(key, cfg.scar[key])
		surface_materials.append(mat)
	tree_material = _scar_material("tree-base.png", "tree-orm.png", "tree-scar.png", "tree-normal.png")
	quiet_tree_material = _scar_material("tree-base.png", "tree-orm.png", "tree-scar.png", "tree-normal.png")
	var quiet_mask := Image.create(1,1,false,Image.FORMAT_RGBA8)
	quiet_mask.fill(Color(0,0,0,1))
	quiet_tree_material.set_shader_parameter("scar_texture",ImageTexture.create_from_image(quiet_mask))
	quiet_tree_material.set_shader_parameter("pulse_mode",0)
	rock_material = _scar_material("rock-base.png", "rock-orm.png", "rock-scar.png", "")
	boar_material = _scar_material("base.png", "orm.png", "scar-mask.png", "normal.png")
	_build("terrain", Vector3.ZERO, 1, 0)
	for row in layout.instances:
		_build(row.role, v(row.position), row.scale, row.yaw)
	_water()
	var world := WorldEnvironment.new()
	sky = Environment.new()
	sky.background_mode = Environment.BG_SKY
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(.18,.31,.42)
	sky_material.sky_horizon_color = Color(.58,.66,.65)
	sky_material.ground_horizon_color = Color(.45,.51,.46)
	sky_material.ground_bottom_color = Color(.13,.17,.11)
	sky.sky = Sky.new()
	sky.sky.sky_material = sky_material
	sky.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.ambient_light_color = Color(.69,.78,.82)
	sky.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	sky.glow_enabled = false
	sky.ssao_enabled = true
	sky.ssao_radius = 1.0
	sky.ssao_intensity = 1.25
	sky.fog_enabled = true
	sky.fog_sky_affect = .12
	sky.fog_light_color = Color(.35,.45,.45)
	world.environment = sky
	add_child(world)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-47,-42,0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 70
	add_child(sun)
	body = CharacterBody3D.new()
	body.collision_mask = 3
	body.floor_snap_length = .35
	capsule = CapsuleShape3D.new()
	capsule.radius = .32
	capsule.height = 1.8
	var cs := CollisionShape3D.new()
	cs.shape = capsule
	cs.position.y = .90
	body.add_child(cs)
	add_child(body)
	camera = Camera3D.new()
	camera.fov = 72
	camera.near = .08
	camera.far = 120
	add_child(camera)
	camera.current = true
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var canvas := CanvasLayer.new()
	add_child(canvas)
	caption = Label.new()
	caption.position = Vector2(24,20)
	caption.add_theme_font_size_override("font_size",18)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",1)
	caption.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(caption)
	_lighting("day")
	var args := OS.get_cmdline_user_args()
	automatic = args.size() > 0
	await get_tree().physics_frame
	await get_tree().physics_frame
	body.position = _ground(v(route[0])) + Vector3.UP*.03
	camera.position = body.position + Vector3.UP*cfg.eye_height_m
	camera.look_at(_ground(v(route[15])) + Vector3.UP*cfg.eye_height_m)
	body.rotation.y = camera.rotation.y
	if "--check" in args:
		await _checks()
	elif "--capture" in args:
		await _captures()
	elif "--walk" in args:
		await _walk_capture()
	elif "--benchmark" in args:
		await _benchmark()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_caption()

func _scar_material(base: String, orm: String, scar: String, normal: String) -> ShaderMaterial:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://boar_scar.gdshader")
	mat.set_shader_parameter("base_texture",load("res://"+base))
	mat.set_shader_parameter("orm_texture",load("res://"+orm))
	mat.set_shader_parameter("scar_texture",load("res://"+scar))
	if not normal.is_empty():
		mat.set_shader_parameter("normal_texture",load("res://"+normal))
		mat.set_shader_parameter("use_normal_map",true)
	mat.set_shader_parameter("core_colour",Color(1,.12,.012).linear_to_srgb())
	mat.set_shader_parameter("peak_emission",cfg.scar.peak_emission)
	mat.set_shader_parameter("minimum_light",cfg.scar.minimum_light)
	mat.set_shader_parameter("period_seconds",cfg.scar.period_seconds)
	mat.set_shader_parameter("pulse_mode",3)
	return mat

func _build(role: String, at: Vector3, scale_value: float, yaw: float) -> void:
	var key := "boar-mid" if role == "boar" else role
	if not scene_cache.has(key):
		scene_cache[key] = load("res://"+key+".glb")
	assert(scene_cache[key] != null)
	var instance: Node3D = scene_cache[key].instantiate()
	add_child(instance)
	instance.position = at
	instance.scale = Vector3.ONE*scale_value
	instance.rotation_degrees.y = yaw
	if role.ends_with("tree"):
		for detail in ["canopy","canopy-far"]:
			if not scene_cache.has(detail):
				scene_cache[detail] = load("res://"+detail+".glb")
			var canopy: Node3D = scene_cache[detail].instantiate()
			instance.add_child(canopy)
			for leaf_mesh in canopy.find_children("*","MeshInstance3D",true,false):
				if detail == "canopy":
					leaf_mesh.visibility_range_end = cfg.canopy_detail_distance_m
					leaf_mesh.visibility_range_end_margin = cfg.canopy_detail_fade_m
				else:
					leaf_mesh.visibility_range_begin = cfg.canopy_detail_distance_m
					leaf_mesh.visibility_range_begin_margin = cfg.canopy_detail_fade_m
				leaf_mesh.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	for node in instance.find_children("*", "MeshInstance3D", true, false):
		var mesh: MeshInstance3D = node
		var name := mesh.mesh.surface_get_material(0).resource_name
		material_names[role+"/"+mesh.name] = name
		var material_index := ["Bark","Rock","Soil","Leaf"].find(name)
		if material_index >= 0:
			mesh.material_override = surface_materials[material_index]
		elif role == "boar":
			mesh.material_override = boar_material
		elif role == "altered-tree" or role == "root-bank":
			mesh.material_override = tree_material
		elif role == "quiet-tree":
			mesh.material_override = quiet_tree_material
		elif role == "fractured-rock" and at.z > 8:
			mesh.material_override = rock_material
		if name == "Leaf" or role == "understory" or mesh.name.contains("twigs") or role == "boar":
			continue
		var mesh_id := mesh.mesh.get_instance_id()
		if not shapes.has(mesh_id):
			shapes[mesh_id] = mesh.mesh.create_trimesh_shape()
		var static_body := StaticBody3D.new()
		static_body.collision_layer = 2 if role == "terrain" else 1
		var shape := CollisionShape3D.new()
		shape.shape = shapes[mesh_id]
		static_body.add_child(shape)
		mesh.add_child(static_body)
	for node in instance.find_children("*","AnimationPlayer",true,false):
		var player: AnimationPlayer = node
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		player.play("root")
		player.seek(0,true)
		player.advance(0)
		animations.append(player)

func _water() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for i in 177:
		var z := -44.0+i*.5
		var x := -5.8+sin(z*.12)+.35*sin(z*.31)
		for side in [-1,1]:
			vertices.append(Vector3(x+side*1.8,-.40,z))
			normals.append(Vector3.UP)
		if i < 176:
			var a := i*2
			indices.append_array(PackedInt32Array([a,a+1,a+2,a+1,a+3,a+2]))
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var water := MeshInstance3D.new()
	water.mesh = mesh
	water_material = ShaderMaterial.new()
	water_material.shader = load("res://water.gdshader")
	water.material_override = water_material
	add_child(water)

func _ground(point: Vector3) -> Vector3:
	var ray := PhysicsRayQueryParameters3D.create(Vector3(point.x,15,point.z),Vector3(point.x,-5,point.z),2,[body.get_rid()])
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	assert(not hit.is_empty(), "Missing route support")
	return hit.position

func _lighting(value: String) -> void:
	lighting = value
	var setting: Dictionary = cfg.lighting[value]
	sun.light_energy = setting.sun
	sun.light_color = Color(setting.sun_colour[0],setting.sun_colour[1],setting.sun_colour[2])
	sky.ambient_light_energy = setting.ambient
	sky.fog_density = setting.fog
	_caption()

func _caption() -> void:
	caption.text = "EMBERROOT GROVE / ART-02\n%s · eye height 1.65 m · bloom off\nWASD walk   Mouse look   L lighting   M scars   Space pause   R return   Esc release" % lighting.capitalize()

func _time(value: float) -> void:
	clock = value
	for mat in surface_materials:
		mat.set_shader_parameter("scar_clock",clock)
		mat.set_shader_parameter("light_enabled",light_enabled)
	for mat in [tree_material,boar_material,rock_material]:
		mat.set_shader_parameter("scar_clock",clock)
		mat.set_shader_parameter("pulse_mode",3 if light_enabled else 0)
	water_material.set_shader_parameter("scar_clock",clock)
	for player in animations:
		player.seek(fmod(clock,player.get_animation("root").length),true)
		player.advance(0)

func _physics_process(delta: float) -> void:
	if automatic or paused:
		return
	_advance(delta)
	var input := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
	var direction := camera.global_basis * Vector3(input.x,0,input.y)
	direction.y = 0
	direction = direction.normalized()
	body.velocity.x = direction.x*cfg.walk_speed_m_s
	body.velocity.z = direction.z*cfg.walk_speed_m_s
	body.velocity.y -= 20*delta
	body.move_and_slide()
	camera.position = body.position + Vector3.UP*cfg.eye_height_m

func _advance(delta: float) -> void:
	if not paused:
		_time(clock+delta)

func _unhandled_input(event: InputEvent) -> void:
	if automatic:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera.rotation.y -= event.relative.x*.002
		pitch = clampf(pitch-event.relative.y*.002,-1.2,1.2)
		camera.rotation.x = pitch
	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE: Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			KEY_SPACE: paused = not paused
			KEY_M:
				light_enabled = not light_enabled
				_time(clock)
			KEY_L: _lighting(["day","shade","dusk"][( ["day","shade","dusk"].find(lighting)+1)%3])
			KEY_R: body.position = _ground(v(route[0]))+Vector3.UP*.03

func _checks() -> void:
	var failures: Array = []
	var points: Array = []
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = capsule
	shape_query.collision_mask = 3
	shape_query.exclude = [body.get_rid()]
	for raw in route:
		var point := _ground(v(raw))
		shape_query.transform = Transform3D(Basis.IDENTITY,point+Vector3.UP*.94)
		var overlaps := get_world_3d().direct_space_state.intersect_shape(shape_query)
		if not overlaps.is_empty(): failures.append({"point":point,"overlaps":overlaps.size()})
		if not points.is_empty():
			shape_query.transform.origin = v(points[-1])+Vector3.UP*.94
			shape_query.motion = point-v(points[-1])
			var sweep := get_world_3d().direct_space_state.cast_motion(shape_query)
			if sweep[0] < .999: failures.append({"point":point,"sweep":sweep[0]})
		points.append([point.x,point.y,point.z])
	shape_query.motion = Vector3.ZERO
	assert(animations.size()==1 and animations[0].has_animation("root"))
	assert(scene_cache.has("quiet-tree") and scene_cache.has("altered-tree"))
	assert(not sky.glow_enabled)
	var before := clock
	paused = true
	_advance(1.0)
	await get_tree().physics_frame
	assert(clock == before)
	assert(tree_material.get_shader_parameter("scar_clock") == before or before == 0.0)
	paused = false
	var walked := await _physical_walk()
	if not walked.completed: failures.append({"physical_walk":walked})
	var data := {"route_points":points.size(),"route_support_and_capsule_failures":failures,"capsule_radius_m":.32,"capsule_height_m":1.8,"eye_height_m":cfg.eye_height_m,"pause_clock_unchanged":clock==before,"bloom":sky.glow_enabled,"isolated_no_game_extension":not ClassDB.class_exists("WroughtwildSim"),"sampled_ground":points}
	data.physical_walk = walked
	_write("checks.json",data)
	_write("material-names.json",material_names)
	print("GROVE_CHECK_OK" if failures.is_empty() else "GROVE_CHECK_FAILED "+str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)

func _physical_walk() -> Dictionary:
	body.position = _ground(v(route[0]))+Vector3.UP*.04
	body.velocity = Vector3.ZERO
	var index := 1
	var grounded := 0
	var samples := 0
	var maximum_height_error := 0.0
	for step in 1600:
		await get_tree().physics_frame
		var target := _ground(v(route[index]))
		var direction := target-body.position
		direction.y = 0
		if direction.length() < .12:
			index += 1
			if index == route.size(): break
			target = _ground(v(route[index]))
			direction = target-body.position
			direction.y = 0
		direction = direction.normalized()
		body.velocity.x = direction.x*cfg.walk_speed_m_s
		body.velocity.z = direction.z*cfg.walk_speed_m_s
		body.velocity.y -= 20.0/60.0
		body.move_and_slide()
		samples += 1
		if body.is_on_floor(): grounded += 1
		maximum_height_error = maxf(maximum_height_error,absf(body.position.y-_ground(body.position).y))
	return {"completed":index==route.size(),"physics_steps":samples,"grounded_steps":grounded,"maximum_support_error_m":maximum_height_error,"end":[body.position.x,body.position.y,body.position.z],"method":"Actual CharacterBody3D move_and_slide toward route points at 60 physics ticks/s."}

func _view(name: String) -> void:
	var at: Vector3
	var target: Vector3
	match name:
		"approach":
			at = Vector3(-.7,0,-14)
			target = Vector3(1.5,2.6,-3)
		"clearing":
			at = Vector3(-.3,0,-1)
			target = Vector3(4,2.1,6)
		"scar":
			at = Vector3(1.4,0,7)
			target = Vector3(5.0,1.7,7)
		"downstream":
			at = Vector3(.4,0,13)
			target = Vector3(-2,2.2,23)
	camera.position = _ground(at)+Vector3.UP*cfg.eye_height_m
	camera.look_at(target)

func _save_frame(name: String) -> void:
	await RenderingServer.frame_post_draw
	var picture := get_viewport().get_texture().get_image()
	assert(picture.save_png(output+"/"+name+".png") == OK)
	records.append({"name":name,"camera":[camera.position.x,camera.position.y,camera.position.z],"rotation":str(camera.rotation),"lighting":lighting,"clock":clock,"scars":light_enabled})

func _captures() -> void:
	caption.visible = false
	for mood in ["day","shade","dusk"]:
		_lighting(mood)
		for name in ["approach","clearing","scar","downstream"]:
			_view(name)
			_time(1.65)
			for frame in 8: await get_tree().process_frame
			await _save_frame(name+"-"+mood)
	_lighting("shade")
	_view("scar")
	light_enabled = false
	_time(1.65)
	for frame in 8: await get_tree().process_frame
	await _save_frame("scar-unlit")
	_write("capture-manifest.json",records)
	print("GROVE_CAPTURE_OK")
	get_tree().quit()

func _walk_capture() -> void:
	caption.visible = false
	var length := 0.0
	for i in range(1,route.size()):length += v(route[i]).distance_to(v(route[i-1]))
	var duration: float = length/cfg.walk_speed_m_s
	var frames := ceili(duration*12)
	for mood in ["day","dusk"]:
		_lighting(mood)
		DirAccess.make_dir_recursive_absolute(output+"/walk-"+mood)
		for i in frames:
			var index := float(i)/float(frames-1)*(route.size()-1)
			var lo := floori(index)
			var at := v(route[lo]).lerp(v(route[mini(lo+1,route.size()-1)]),index-lo)
			camera.position = _ground(at)+Vector3.UP*cfg.eye_height_m
			var target := _ground(v(route[mini(lo+18,route.size()-1)]))+Vector3.UP*1.65
			if lo > 65 and lo < 105: target = target.lerp(Vector3(5,1.8,7),sin(float(lo-65)/40*PI)*.50)
			if target.distance_to(camera.position)<.1:target.z += 1
			camera.look_at(target)
			_time(float(i)/12)
			await get_tree().process_frame
			await _save_frame("walk-"+mood+"/%04d"%i)
	_write("walk-manifest.json",{"frames_per_mood":frames,"fps":12,"duration_seconds":duration,"route_length_m":length,"motion":"Scripted camera samples over physically checked support; not human input or measured FPS.","views":records})
	print("GROVE_WALK_OK")
	get_tree().quit()

func _benchmark() -> void:
	caption.visible = false
	RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var results: Array = []
	for mood in ["day","dusk"]:
		_lighting(mood)
		_view("clearing")
		for i in 90:
			_time(float(i)/60)
			await get_tree().process_frame
		var wall: Array = []
		var gpu: Array = []
		for i in 300:
			var started := Time.get_ticks_usec()
			_time(float(i)/60)
			await RenderingServer.frame_post_draw
			gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
			await get_tree().process_frame
			wall.append((Time.get_ticks_usec()-started)/1000.0)
		wall.sort()
		gpu.sort()
		results.append({"lighting":mood,"samples":300,"warmup":90,"wall_median_ms":wall[150],"wall_p95_ms":wall[285],"gpu_median_ms":gpu[150],"gpu_p95_ms":gpu[285],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)})
	_write("benchmark.json",{"engine":Engine.get_version_info(),"adapter":RenderingServer.get_video_adapter_name(),"size":[1440,900],"renderer":"Forward+","msaa":4,"cases":results,"scope":"Complete isolated grove. No game simulation or ordinary-world performance claim."})
	print("GROVE_BENCHMARK_OK")
	get_tree().quit()

func _write(name: String, data: Variant) -> void:
	var file := FileAccess.open(output+"/"+name,FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(data,"\t")+"\n")
