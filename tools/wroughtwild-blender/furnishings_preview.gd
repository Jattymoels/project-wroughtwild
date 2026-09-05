extends SceneTree
## Actual imports: green is current game collision, amber is the fit proposal.
func _initialize() -> void:
	call_deferred("run")

func wire_box(contract: Dictionary, material: Material) -> MeshInstance3D:
	var size := Vector3(contract["size"][0],contract["size"][1],contract["size"][2])
	var centre := Vector3(contract.centre[0],contract.centre[1],contract.centre[2])
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES,material)
	for axis in 3:
		for a in [-1,1]:
			for b in [-1,1]:
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
	viewport.size = Vector2i(1800,1200)
	viewport.msaa_3d = Viewport.MSAA_4X
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var stage := Node3D.new()
	viewport.add_child(stage)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("262d2a")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("bcc5bb")
	environment.environment.ambient_light_energy = .75
	stage.add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-35,0)
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	stage.add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var floor_box := BoxMesh.new()
	floor_box.size = Vector3(8,.04,5.2)
	floor_mesh.mesh = floor_box
	floor_mesh.position.y = -.025
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("424a43")
	floor_material.roughness = 1
	floor_mesh.material_override = floor_material
	stage.add_child(floor_mesh)
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var placements := {"workbench":Vector3(-1.75,0,1.35),"mason_yard":Vector3(0,0,1.35),"chest":Vector3(1.75,0,1.35),
		"forge_basic":Vector3(-1.75,0,-1.3),"forge_improved":Vector3(0,0,-1.3),"campfire":Vector3(1.75,0,-1.3)}
	var names := {"workbench":"WORKBENCH", "mason_yard":"MASON'S YARD", "chest":"CHEST", "forge_basic":"BASIC FORGE", "forge_improved":"IMPROVED FORGE", "campfire":"CAMPFIRE"}
	var materials: Array[StandardMaterial3D] = []
	for colour in [Color("85d7b6"),Color("f1bc63")]:
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = colour
		material.no_depth_test = true
		materials.append(material)
	var wires: Array[Node3D] = []
	for id in placements:
		var data: Dictionary = report.assets[id]
		var at: Vector3 = placements[id] + Vector3(0,float(data.ground_lift),0)
		var visual: Node3D = load("res://"+id+".glb").instantiate()
		stage.add_child(visual)
		visual.position = at
		for i in 2:
			var contract: Variant = data.collision if i == 0 else data.candidate_collision
			if contract == null:
				continue
			var wire := wire_box(contract,materials[i])
			stage.add_child(wire)
			wire.position = at
			wires.append(wire)
	var camera := Camera3D.new()
	stage.add_child(camera)
	camera.position = Vector3(5.7,8.0,11)
	camera.look_at(Vector3(0,.6,0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 8.0
	camera.current = true
	var ui := CanvasLayer.new()
	stage.add_child(ui)
	var title := Label.new()
	title.text = "WROUGHTWILD / FURNISHINGS\nSix existing types - actual Godot imports at metre scale"
	title.position = Vector2(45,28)
	title.add_theme_font_size_override("font_size",25)
	ui.add_child(title)
	var note := Label.new()
	note.text = "GREEN: existing game bodies   |   AMBER: separate station fit proposals\nBench tops: 0.95 m. Existing station boxes: 2.00 m. Small tools are decorative.\nChest and campfire retain their existing collision and cell anchors."
	note.position = Vector2(45,1085)
	note.add_theme_font_size_override("font_size",22)
	ui.add_child(note)
	for frame in 8:
		await process_frame
	for id in placements:
		var label := Label.new()
		label.text = names[id]
		label.size.x = 240
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var label_offset := Vector3(0,2.16,0) if id.begins_with("forge_") else Vector3(0,-.03,.72)
		label.position = camera.unproject_position(placements[id]+label_offset)-Vector2(120,0)
		label.add_theme_font_size_override("font_size",19)
		ui.add_child(label)
	await process_frame
	await RenderingServer.frame_post_draw
	var result := viewport.get_texture().get_image().save_png("res://furnishings-collision.png")
	for wire in wires:
		wire.hide()
	note.text = "Chest / campfire / workbench / mason's yard / basic forge / improved forge\nStatic study meshes. Game interactions, fuel, storage and saves remain on their existing paths."
	await process_frame
	await RenderingServer.frame_post_draw
	result = maxi(result,viewport.get_texture().get_image().save_png("res://furnishings-godot.png"))
	print("BLENDER_FURNISHINGS_PREVIEW ",result)
	quit(result)
