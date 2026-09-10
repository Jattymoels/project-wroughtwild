extends Node3D
## Static material inspection only. No game state, placement or source ownership.
var camera: Camera3D
var sun: DirectionalLight3D
var environment: Environment
var caption: Label
var families: Array = []
var renderer := ""
var samples: Array[float] = []
var counters: Array = []

func _ready() -> void:
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	renderer = RenderingServer.get_current_rendering_method()
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://materials.json"))
	families = cfg.families
	var model: Node3D = load("res://d5_proxies.glb").instantiate()
	add_child(model)
	var materials := {}
	for family: Dictionary in families:
		for role: String in ["face", "edge"]:
			var key: String = "d5_" + str(family.id) + "_" + role
			var material := StandardMaterial3D.new()
			material.resource_name = key
			material.albedo_texture = load("res://textures/" + key + "_albedo.png")
			material.normal_enabled = true
			material.normal_texture = load("res://textures/" + key + "_normal.png")
			material.roughness_texture = load("res://textures/" + key + "_orm.png")
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			material.texture_repeat = true
			if family.id == "cinderglass" and role == "face":
				material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				material.albedo_color.a = float(family.opacity)
			material.metallic = 0.0
			material.emission_enabled = false
			materials[key] = material
	var mesh_count := 0
	var triangles := 0
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		mesh_count += 1
		for i in mesh_node.mesh.get_surface_count():
			var original: Material = mesh_node.mesh.surface_get_material(i)
			assert(materials.has(original.resource_name), "Unknown material " + original.resource_name)
			# Release embedded review materials rather than retaining a second set
			# behind per-instance overrides. This mesh belongs to this isolated review.
			mesh_node.mesh.surface_set_material(i, materials[original.resource_name])
			var arrays := mesh_node.mesh.surface_get_arrays(i)
			triangles += arrays[Mesh.ARRAY_INDEX].size() / 3
	var audit: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://blender-audit.json"))
	assert(mesh_count == audit.proxies.size() and triangles == int(audit.triangles), "Imported topology differs")
	var stage := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	stage.mesh = plane
	stage.position.y = -0.018
	var neutral := StandardMaterial3D.new()
	neutral.albedo_color = Color(0.26, 0.28, 0.29)
	neutral.roughness = 0.82
	stage.material_override = neutral
	add_child(stage)
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.09, 0.105, 0.12)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color.WHITE
	environment.ambient_light_energy = 0.35
	environment.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	environment.glow_enabled = false
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_color = Color.WHITE
	sun.light_energy = 0.75
	sun.shadow_enabled = true
	add_child(sun)
	var sky := Sky.new()
	var sky_material := ProceduralSkyMaterial.new()
	sky_material.sky_top_color = Color(0.3,0.42,0.58)
	sky_material.sky_horizon_color = Color(0.7,0.7,0.66)
	sky.sky_material = sky_material
	environment.sky = sky
	environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
	# Fixed pane blocking uses the native full envelope; alpha never opens collision.
	var body := StaticBody3D.new()
	body.position = Vector3(3.875,1,-0.3)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1,1,.16)
	collision.shape = shape
	body.add_child(collision)
	add_child(body)
	for i in 4:
		var target := MeshInstance3D.new()
		var target_mesh := BoxMesh.new()
		target_mesh.size = Vector3(.19,.55,.06)
		target.mesh = target_mesh
		target.position = Vector3(3.875+(i-1.5)*.20,1,-.65)
		var target_mat := StandardMaterial3D.new()
		target_mat.albedo_color = Color(.75,.42,.12) if i%2==0 else Color(.11,.22,.31)
		target.material_override = target_mat
		add_child(target)
	await get_tree().physics_frame
	var ray := PhysicsRayQueryParameters3D.create(Vector3(3.875,1,1),Vector3(3.875,1,-1))
	assert(get_world_3d().direct_space_state.intersect_ray(ray).get("collider") == body)
	print("D5_FIXED_GLASS_BLOCKING_OK full 1x1x0.16 envelope, integral frame, opacity 0.72")
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 7.6
	add_child(camera)
	view_at(Vector3(4,7,13), Vector3(0,1,0), 7.6)
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24,20)
	caption.add_theme_font_size_override("font_size", 22)
	layer.add_child(caption)
	caption.text = "ART-07D5 / " + renderer + " / 1–8: family   0: overview   Esc: exit"
	var args := OS.get_cmdline_user_args()
	for i in 12: await get_tree().process_frame
	print("D5_IMPORT_OK meshes=%d triangles=%d renderer=%s device=%s" % [mesh_count,triangles,renderer,RenderingServer.get_video_adapter_name()])
	if args.has("--capture"):
		await capture("overview", "NEUTRAL / DRESSED · ROUGH · SLATE · FOSSIL · BRICK · BASALT · GLASS · FUEL")
		for i in families.size():
			family_view(i)
			await capture(str(families[i].id), str(families[i].name).to_upper() + " / surface, cut edge and repeat inspection")
		view_at(Vector3(4,7,13),Vector3(0,1,0),7.6)
		sun.light_energy = 1.2
		await capture("light", "LIGHT / opaque mineral and alpha glass response")
		sun.light_energy = 0.18
		environment.ambient_light_energy = 0.42
		await capture("shade", "NEUTRAL SHADE / emission disabled on every family")
		sun.light_energy = 0.08
		environment.ambient_light_energy = 0.0
		environment.ambient_light_energy = 0.07
		await capture("dark", "DARK / material edges remain physical")
		sun.light_energy = 0.0
		environment.ambient_light_energy = 0.0
		environment.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
		await capture("unlit", "ZERO LIGHT / no material emission")
		sun.light_energy = 0.75
		environment.ambient_light_energy = 0.35
		environment.reflected_light_source = Environment.REFLECTION_SOURCE_SKY
		view_at(Vector3(4,7,13),Vector3(0,1,0),12.0)
		await capture("far", "FAR / same geometry, mipmapped surfaces")
		get_tree().quit()
	elif args.has("--motion"):
		DirAccess.make_dir_recursive_absolute("res://evidence/"+renderer+"-motion")
		for i in 96:
			var x := lerpf(-5.425,5.425,float(i)/95.0)
			view_at(Vector3(x+1.05,2.5,3.7),Vector3(x,1,0),2.6)
			caption.text = "ART-07D5 / " + renderer + " / camera inspection · static, non-emissive materials"
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://evidence/"+renderer+"-motion/%04d.png" % i)
		get_tree().quit()
	elif args.has("--benchmark"):
		caption.text = "ART-07D5 / fixed view / benchmark without image capture"
		for i in 120: await get_tree().process_frame
		var previous := Time.get_ticks_usec()
		for i in 600:
			await get_tree().process_frame
			var now := Time.get_ticks_usec()
			samples.append(float(now-previous)/1000.0)
			previous = now
			if i % 60 == 0:
				counters.append({"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
		samples.sort()
		var result := {"renderer":renderer,"device":RenderingServer.get_video_adapter_name(),"frames":600,"warmup_frames":132,"size":get_viewport().size,"p50_ms":samples[300],"p95_ms":samples[570],"worst_ms":samples.back(),"counters":counters,"note":"Separate fixed-view run, no generation or screenshots; RTX result only."}
		DirAccess.make_dir_recursive_absolute("res://evidence")
		var file := FileAccess.open("res://evidence/"+renderer+"-benchmark.json",FileAccess.WRITE)
		file.store_string(JSON.stringify(result,"\t"))
		print("D5_BENCHMARK ",JSON.stringify(result))
		get_tree().quit()

func view_at(position_m: Vector3, target: Vector3, extent: float) -> void:
	camera.position = position_m
	camera.look_at(target)
	camera.size = extent

func family_view(index: int) -> void:
	var x := (index-3.5)*1.55
	view_at(Vector3(x+1.05,2.5,3.7),Vector3(x,1,0),2.45)

func capture(name_id: String, title: String) -> void:
	caption.text = "ART-07D5 / " + renderer + " / " + title
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://evidence")
	var code := get_viewport().get_texture().get_image().save_png("res://evidence/"+renderer+"-"+name_id+".png")
	assert(code == OK)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.is_pressed(): return
	if key.keycode == KEY_ESCAPE: get_tree().quit()
	if key.keycode == KEY_0: view_at(Vector3(4,7,13),Vector3(0,1,0),7.6)
	if key.keycode >= KEY_1 and key.keycode <= KEY_8: family_view(key.keycode-KEY_1)
