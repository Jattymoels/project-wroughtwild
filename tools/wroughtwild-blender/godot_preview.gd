extends SceneTree
## Actual imported visuals, with exact collision envelopes drawn beside them.
func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# An explicit render target stays full-sized even when Windows hides the window.
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1440, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("202923")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b4c0b6")
	environment.environment.ambient_light_energy = .6
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, -30, 0)
	sun.light_energy = 1.5
	stage.add_child(sun)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("74e0bd")
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var index := 0
	for id in ["wall_panel", "pillar", "beam"]:
		var visual: Node3D = load("res://" + id + ".glb").instantiate()
		stage.add_child(visual)
		visual.position = Vector3((index - 1) * 1.7, .8, 0)
		var size: Array = report.assets[id].size_godot_metres
		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINES, material)
		for axis in 3:
			for a in [-1, 1]:
				for b in [-1, 1]:
					var p := Vector3.ZERO
					p[axis] = -size[axis] / 2
					p[(axis+1)%3] = a * size[(axis+1)%3] / 2
					p[(axis+2)%3] = b * size[(axis+2)%3] / 2
					mesh.surface_add_vertex(p)
					p[axis] *= -1
					mesh.surface_add_vertex(p)
		mesh.surface_end()
		var wire := MeshInstance3D.new()
		wire.mesh = mesh
		wire.position = visual.position + Vector3(0, -1.4, 0)
		stage.add_child(wire)
		index += 1
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(2.5, 2.7, 7)
	camera.look_at(Vector3.ZERO)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 6.6
	camera.current = true
	var ui := CanvasLayer.new()
	stage.add_child(ui)
	var title := Label.new()
	title.text = "WROUGHTWILD / BLENDER BUILDING STUDY\nGodot 4.5 imports: visible meshes above, collision envelopes below"
	title.position = Vector2(48, 35)
	title.add_theme_font_size_override("font_size", 23)
	ui.add_child(title)
	var note := Label.new()
	note.text = "Wall  1 x 1 x 0.25 m       /       Post  0.3 x 1 x 0.3 m       /       Beam  1 x 0.4 x 0.4 m\nExisting grid dimensions and centred pivots. Surface detail does not add collision."
	note.position = Vector2(48, 795)
	note.add_theme_font_size_override("font_size", 20)
	ui.add_child(note)
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var error := viewport.get_texture().get_image().save_png("res://godot-review.png")
	print("BLENDER_GODOT_PREVIEW ", error)
	quit(error)
