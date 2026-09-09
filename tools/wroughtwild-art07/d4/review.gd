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
	var model: Node3D = load("res://d4_proxies.glb").instantiate()
	add_child(model)
	var materials := {}
	for family: Dictionary in families:
		for role: String in ["face", "edge"]:
			var key: String = "d4_" + str(family.id) + "_" + role
			var material := StandardMaterial3D.new()
			material.resource_name = key
			material.albedo_texture = load("res://textures/" + key + "_albedo.png")
			material.normal_enabled = true
			material.normal_texture = load("res://textures/" + key + "_normal.png")
			material.roughness_texture = load("res://textures/" + key + "_orm.png")
			material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
			material.texture_repeat = true
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
	assert(mesh_count == 26 and triangles == 312, "Imported proxy topology differs")
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
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.5
	add_child(camera)
	view_at(Vector3(4,7,13), Vector3(0,1,0), 6.5)
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24,20)
	caption.add_theme_font_size_override("font_size", 22)
	layer.add_child(caption)
	caption.text = "ART-07D4 / " + renderer + " / 1–7: family   0: overview   Esc: exit"
	var args := OS.get_cmdline_user_args()
	for i in 12: await get_tree().process_frame
	print("D4_IMPORT_OK meshes=%d triangles=%d renderer=%s device=%s" % [mesh_count,triangles,renderer,RenderingServer.get_video_adapter_name()])
	if args.has("--capture"):
		await capture("overview", "NEUTRAL / TIMBER · PINE · BOG OAK · ASH · RESINHEART · REED · CORK")
		for i in families.size():
			family_view(i)
			await capture(str(families[i].id), str(families[i].name).to_upper() + " / coarse, fine and cut direction")
		view_at(Vector3(4,7,13),Vector3(0,1,0),6.5)
		sun.light_energy = 0.18
		environment.ambient_light_energy = 0.42
		await capture("shade", "NEUTRAL SHADE / emission disabled on every family")
		sun.light_energy = 0.0
		environment.ambient_light_energy = 0.0
		await capture("unlit", "ZERO LIGHT / no material emission")
		get_tree().quit()
	elif args.has("--motion"):
		DirAccess.make_dir_recursive_absolute("res://evidence/"+renderer+"-motion")
		for i in 96:
			var x := lerpf(-4.65,4.65,float(i)/95.0)
			view_at(Vector3(x+1.05,2.5,3.7),Vector3(x,1,0),2.6)
			caption.text = "ART-07D4 / " + renderer + " / camera inspection · static, non-emissive materials"
			await RenderingServer.frame_post_draw
			get_viewport().get_texture().get_image().save_png("res://evidence/"+renderer+"-motion/%04d.png" % i)
		get_tree().quit()
	elif args.has("--benchmark"):
		caption.text = "ART-07D4 / fixed view / benchmark without image capture"
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
		print("D4_BENCHMARK ",JSON.stringify(result))
		get_tree().quit()

func view_at(position_m: Vector3, target: Vector3, extent: float) -> void:
	camera.position = position_m
	camera.look_at(target)
	camera.size = extent

func family_view(index: int) -> void:
	var x := (index-3)*1.55
	view_at(Vector3(x+1.05,2.5,3.7),Vector3(x,1,0),2.45)

func capture(name_id: String, title: String) -> void:
	caption.text = "ART-07D4 / " + renderer + " / " + title
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute("res://evidence")
	var code := get_viewport().get_texture().get_image().save_png("res://evidence/"+renderer+"-"+name_id+".png")
	assert(code == OK)

func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key == null or not key.is_pressed(): return
	if key.keycode == KEY_ESCAPE: get_tree().quit()
	if key.keycode == KEY_0: view_at(Vector3(4,7,13),Vector3(0,1,0),6.5)
	if key.keycode >= KEY_1 and key.keycode <= KEY_7: family_view(key.keycode-KEY_1)
