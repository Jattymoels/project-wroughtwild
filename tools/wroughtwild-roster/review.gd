extends Node3D
## Isolated unrigged-source gallery. No game, sim, save, input-map or combat imports.
var config: Dictionary
var selected := 0
var older := false
var clay := false
var rotating := false
var holder: Node3D
var camera: Camera3D
var label: Label
var yaw := -0.65
var pitch := 0.23
var checks: Array[String] = []
var review_meshes: Array[MeshInstance3D] = []

func require(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		get_tree().quit(1)
		assert(ok, message)
	checks.append(message)

func _ready() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://roster.json"))
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("30363b")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bdc8d2")
	env.ambient_light_energy = 0.65
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	for spec in [[Vector3(-3,5,4),1.5],[Vector3(4,3,2),0.8],[Vector3(1,4,-4),1.1]]:
		var light := DirectionalLight3D.new()
		add_child(light)
		light.position = spec[0]
		light.look_at(Vector3(0,1,0))
		light.light_energy = spec[1]
		light.shadow_enabled = false
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200,200)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("373d40")
	material.roughness = 1.0
	ground.material_override = material
	ground.position.y = -0.006
	add_child(ground)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = float(config.review_ortho_size)
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(18,14)
	label.add_theme_font_size_override("font_size",18)
	canvas.add_child(label)
	load_asset()
	if "--check" in OS.get_cmdline_user_args():
		await check_all()
	elif "--capture" in OS.get_cmdline_user_args():
		await capture_all()

func mesh_nodes(root: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if root is MeshInstance3D: found.append(root)
	for child in root.get_children(): found.append_array(mesh_nodes(child))
	return found

func load_asset() -> void:
	if is_instance_valid(holder): holder.free()
	holder = Node3D.new()
	add_child(holder)
	var row: Dictionary = config.assets[selected]
	var path := "res://assets/%s-%s.glb" % [row.id, row.previous if older else row.version]
	var packed := load(path) as PackedScene
	require(packed != null,"Packed source exists: "+path)
	var actor := packed.instantiate() as Node3D
	holder.add_child(actor)
	review_meshes = mesh_nodes(actor)
	require(not review_meshes.is_empty(),"Visible mesh exists: "+path)
	var lo := Vector3(INF,INF,INF)
	var hi := Vector3(-INF,-INF,-INF)
	var triangles := 0
	for mesh in review_meshes:
		var box := mesh.get_aabb()
		var local := holder.global_transform.affine_inverse()*mesh.global_transform
		for i in 8:
			var point: Vector3 = local*box.get_endpoint(i)
			lo = lo.min(point)
			hi = hi.max(point)
		require(mesh.mesh.get_surface_count()>0,"Nonempty mesh surface: "+path)
		for surface in mesh.mesh.get_surface_count():
			var arrays := mesh.mesh.surface_get_arrays(surface)
			var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			for point in positions:
				if not point.is_finite(): require(false,"Nonfinite source position: "+path)
			triangles += int(mesh.mesh.surface_get_array_index_len(surface)/3)
			var native_material := mesh.get_active_material(surface) as StandardMaterial3D
			require(native_material != null and native_material.albedo_texture != null,"Source texture bound: "+path)
		require(mesh.skin==null,"Source honestly unrigged: "+path)
	var extent := hi-lo
	require(extent.is_finite() and extent.x>0 and extent.y>0 and extent.z>0 and triangles>0,"Finite nonempty source bounds: "+path)
	var scale_factor := float(config.review_longest_dimension)/maxf(extent.x,maxf(extent.y,extent.z))
	actor.scale *= scale_factor
	actor.position = -Vector3((lo.x+hi.x)/2,lo.y,(lo.z+hi.z)/2)*scale_factor
	var target := Vector3(0,extent.y*scale_factor*0.5,0)
	camera.set_meta("target",target)
	set_camera()
	set_clay()
	label.text = "%s — %s\n%s | %s | %d source triangles\n1–6 choose · B earlier/stronger · C clay · Space rotate · Arrows orbit\nUNRIGGED SOURCE STUDY · uniform review size, not gameplay scale\n%s" % [row.animal,String(row.id).replace("_"," "),row.previous if older else row.version,row.role,triangles,row.review_focus]

func set_camera() -> void:
	var target: Vector3 = camera.get_meta("target",Vector3.UP)
	camera.position = target + Vector3(sin(yaw)*cos(pitch),sin(pitch),cos(yaw)*cos(pitch))*5
	camera.look_at(target)

func set_clay() -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("9b9fa4")
	mat.roughness = 0.85
	for mesh in review_meshes: mesh.material_override = mat if clay else null

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode>=KEY_1 and event.keycode<=KEY_6:
		selected = event.keycode-KEY_1
		load_asset()
	elif event.keycode==KEY_B:
		older = not older
		load_asset()
	elif event.keycode==KEY_C:
		clay = not clay
		set_clay()
	elif event.keycode==KEY_SPACE: rotating = not rotating
	elif event.keycode==KEY_ESCAPE: get_tree().quit()

func _process(delta: float) -> void:
	if not is_instance_valid(camera): return
	if rotating: yaw += delta*0.3
	if Input.is_key_pressed(KEY_LEFT): yaw -= delta
	if Input.is_key_pressed(KEY_RIGHT): yaw += delta
	if Input.is_key_pressed(KEY_UP): pitch = minf(pitch+delta,1.45)
	if Input.is_key_pressed(KEY_DOWN): pitch = maxf(pitch-delta,-1.2)
	set_camera()

func check_all() -> void:
	for i in config.assets.size():
		selected = i
		for previous in [false,true]:
			older = previous
			load_asset()
			clay = true
			set_clay()
			require(review_meshes[0].material_override!=null,"Clay comparison binds")
			clay = false
			set_clay()
			require(review_meshes[0].material_override==null,"Native material comparison restores")
			await get_tree().process_frame
			await RenderingServer.frame_post_draw
	var result := {"checks":checks.size(),"passed":checks,"renderer":RenderingServer.get_current_rendering_method(),"scope":"12 static raw source imports; no animation, scar pulse or native gameplay claim"}
	var file := FileAccess.open("res://checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"  "))
	file.close()
	print("ROSTER_SOURCE_CHECKS ",checks.size())
	get_tree().quit()

func capture_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	for i in config.assets.size():
		selected = i
		older = false
		load_asset()
		for j in 4: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var error := get_viewport().get_texture().get_image().save_png("res://captures/"+String(config.assets[i].id)+".png")
		require(error==OK,"Engine image written")
	print("ROSTER_SOURCE_CAPTURED")
	get_tree().quit()
