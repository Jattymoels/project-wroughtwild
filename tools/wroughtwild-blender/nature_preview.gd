extends SceneTree
## Godot's imported meshes at actual size, with gameplay envelopes visible.
func _initialize() -> void:
	call_deferred("run")

func wire_box(size: Vector3, centre: Vector3, material: Material) -> MeshInstance3D:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
	for axis in 3:
		for a in [-1, 1]:
			for b in [-1, 1]:
				var p := Vector3.ZERO
				p[axis] = -size[axis]/2
				p[(axis+1)%3] = a*size[(axis+1)%3]/2
				p[(axis+2)%3] = b*size[(axis+2)%3]/2
				mesh.surface_add_vertex(p+centre)
				p[axis] *= -1
				mesh.surface_add_vertex(p+centre)
	mesh.surface_end()
	var instance := MeshInstance3D.new()
	instance.mesh = mesh
	return instance

func run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 1100)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("262f2b")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("bcc5bb")
	environment.environment.ambient_light_energy = .65
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -35, 0)
	sun.light_energy = 1.7
	stage.add_child(sun)
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var placements := {"broadleaf_tree": Vector3(-2, 0, 0), "field_boulder": Vector3(.6, 0, -.1),
		"shrub": Vector3(2.5, 0, -.7), "fern_bed": Vector3(.35, 0, 1.5),
		"deadfall": Vector3(1.7, 0, 1.55), "stump": Vector3(3.1, 0, 1.25)}
	var wire_material := StandardMaterial3D.new()
	wire_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	wire_material.albedo_color = Color("82e4c1")
	wire_material.no_depth_test = true
	for id in placements:
		var visual: Node3D = load("res://"+id+".glb").instantiate()
		stage.add_child(visual)
		visual.position = placements[id]
		var contract: Variant = report.assets[id].collision
		if contract != null:
			var size := Vector3(contract["size"][0], contract["size"][1], contract["size"][2])
			var centre := Vector3(contract.centre[0], contract.centre[1], contract.centre[2])
			var wire := wire_box(size, centre, wire_material)
			stage.add_child(wire)
			wire.position = placements[id]
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(5, 4.5, 10)
	camera.look_at(Vector3(.2, 1.7, .1))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 9.0
	camera.current = true
	var ui := CanvasLayer.new()
	stage.add_child(ui)
	var title := Label.new()
	title.text = "WROUGHTWILD / LAND & NATURE FIXTURES\nActual Godot 4.5 imports at metre scale"
	title.position = Vector2(48, 30)
	title.add_theme_font_size_override("font_size", 25)
	ui.add_child(title)
	var note := Label.new()
	note.text = "SOLID: tree trunk + harvestable boulder (green envelopes)\nDECORATIVE: brush, ferns, short deadfall + stump\nCanopies and small cover leave movement and projectile paths clear."
	note.position = Vector2(48, 950)
	note.add_theme_font_size_override("font_size", 23)
	ui.add_child(note)
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://nature-godot.png")
	print("BLENDER_NATURE_PREVIEW ", result)
	quit(result)
