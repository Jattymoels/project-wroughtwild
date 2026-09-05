extends "res://experiments/workshop_lab.gd"
## Editable architecture study: ordinary addresses, real roof pieces, own save.
var playable := false
var roof_pieces: Array[PlacedBlock] = []
var roof_samples: Array[PlacedBlock] = []
var start_ticks := 0
var _style_dirty := false

func review_id() -> String:
	return "roof-workshop"

func shape_fixtures() -> Array:
	var fixtures := super.shape_fixtures()
	fixtures.append_array(JSON.parse_string(FileAccess.get_file_as_string("res://experiments/roof_shapes.json"))["shapes"])
	return fixtures

func _ready() -> void:
	start_ticks = Time.get_ticks_msec()
	super._ready()
	playable = OS.get_cmdline_user_args().has("--workshop-play")
	if playable:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		player.position = Vector3(7, 2.2, 6)
		player.camera.make_current()
		player.hud.show()
		player.class_panel.choose("warden")
		for family in sim.build_material_ids():
			sim.add_material(String(sim.build_material(family)["source"]),500)
		player.placement.select_shape(&"codex_roof_slope")
		caption.text = "WORKSHOP STUDY · WASD / mouse · B build · Tab shape · R rotate · X remove\nF5 / F9 save this workshop separately · Esc releases the mouse"
		caption.add_theme_font_size_override("font_size", 17)
		caption.position = Vector2(36, 220)
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		child_entered_tree.connect(func(_node: Node): _style_dirty = true)

func _process(_delta: float) -> void:
	if _style_dirty:
		_style_dirty = false
		_dress()

func _add_roof_cap() -> void:
	# Square hipped upper roof over an octagonal lower eave. A shallow pitch
	# permits half-grid rise using exactly the existing placement addresses.
	for x in range(3, 11):
		for z in range(3, 11):
			var distances := [z-3, 10-x, 10-z, x-3]
			var ring: int = distances.min()
			var edges: Array[int] = []
			for i in 4:
				if distances[i] == ring:
					edges.append(i)
			var shape: StringName = &"codex_roof_slope"
			var turn: int = [0,3,2,1][edges[0]]
			if edges.size() == 2:
				shape = &"codex_roof_hip"
				# Local high +x/+z: NW=0, NE=3, SE=2, SW=1.
				turn = 0 if x < 7 and z < 7 else (3 if x >= 7 and z < 7 else (2 if x >= 7 else 1))
			var piece := player.placement.place_piece({"kind":"volume", "axis":0,
				"cell":Vector3i(x*2,10+ring,z*2)},shape,&"pine",turn)
			check(piece != null,"modular roof places on half-grid rise")
			if piece != null:
				roof_pieces.append(piece)
	# Transition samples are outside the house so all four turns can be probed.
	for form in [&"codex_roof_hip", &"codex_roof_valley"]:
		for turn in 4:
			var x := 17 + turn * 2
			var z := 5 if form == &"codex_roof_hip" else 8
			_put(Vector3i(x,0,z),&"cube",0,&"stone")
			roof_samples.append(_put(Vector3i(x,1,z),form,turn))

func _dress() -> void:
	super._dress()
	var wood := ShaderMaterial.new()
	wood.shader = preload("res://art/workshop_wood.gdshader")
	wood.set_shader_parameter("timber",Color("ab8e5f"))
	var ceiling := ShaderMaterial.new()
	ceiling.shader = wood.shader
	ceiling.set_shader_parameter("timber",Color("735132"))
	var roof_material := StandardMaterial3D.new()
	roof_material.albedo_color = Color("344d58")
	roof_material.roughness = 1.0
	for piece in get_children():
		if piece is PlacedBlock and String(piece.shape_id).begins_with("codex_roof_"):
			piece._mesh.material_override = roof_material
		elif piece is PlacedBlock and piece.material_family == &"pine":
			piece._mesh.material_override = ceiling if piece.element["kind"] == "face" else wood
		elif piece is StationSite:
			_dress_station(piece)
	# Add a floor to orient eye-level views and a landing at the door. These
	# objects are scene context, not secretly included in the player's building.
	if has_node("StudyGround"):
		return
	var ground := StaticBody3D.new()
	ground.name = "StudyGround"
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(60,0.2,60)
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("2e5429")
	material.roughness = 1.0
	mesh.material_override = material
	ground.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	ground.add_child(collision)
	ground.position = Vector3(7,-0.15,7)
	add_child(ground)
	_put(Vector3i(6,0,-1),&"stairs",0,&"pine")
	# Interior framing is clearly decorative, just like the earlier exterior
	# trims. It does not add collision, shelter, payment or saved pieces.
	var details := Node3D.new()
	details.name = "InteriorFraming"
	add_child(details)
	for x in [4.0,7.0,10.0]:
		_box(details,Vector3(x,4.8,7),Vector3(0.16,0.3,8),Color("4d3b2e"))
	var glow := OmniLight3D.new()
	glow.position = Vector3(7,3.9,7)
	glow.light_color = Color("fff5e0")
	glow.light_energy = 1.5
	glow.omni_range = 8
	glow.shadow_enabled = true
	details.add_child(glow)
	_box(details,Vector3(7,4.05,7),Vector3(0.25,0.45,0.25),Color("c4ae82"))

func _box(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	mesh.material_override = material
	parent.add_child(mesh)
	return mesh

func _dress_station(site: StationSite) -> void:
	if site.has_node("StudyDetails"):
		return
	site.get_node("Mesh").hide()
	var details := Node3D.new()
	details.name = "StudyDetails"
	site.add_child(details)
	# All silhouettes fit the existing station's one-cell collision envelope.
	if site.station_id == &"forge_basic":
		_box(details,Vector3(0,0.4,0),Vector3(0.9,0.8,0.9),Color("565860"))
		for x in [-0.36,0.36]:
			_box(details,Vector3(x,1.1,0),Vector3(0.18,0.7,0.9),Color("74747a"))
		_box(details,Vector3(0,1.5,0),Vector3(0.95,0.15,0.95),Color("565860"))
		_box(details,Vector3(0,0.95,0.35),Vector3(0.6,0.3,0.16),Color("402c1a"))
		var coal := _box(details,Vector3(0,0.82,0),Vector3(0.6,0.05,0.55),Color("ec6e1e"))
		coal.material_override.emission_enabled = true
		coal.material_override.emission = Color("ec6e1e")
		var fire := OmniLight3D.new()
		fire.position = Vector3(0,1.05,-0.3)
		fire.light_color = Color("ff9e66")
		fire.light_energy = 1.2
		fire.omni_range = 3.5
		details.add_child(fire)
	else:
		var colour := Color("735132") if site.station_id==&"workbench" else Color("74747a")
		_box(details,Vector3(0,0.86,0),Vector3(0.94,0.18,0.92),colour)
		for x in [-0.32,0.32]:
			for z in [-0.32,0.32]:
				_box(details,Vector3(x,0.4,z),Vector3(0.16,0.8,0.16),Color("4d3b2e"))
		_box(details,Vector3(0,1.02,0.12),Vector3(0.5,0.14,0.3),colour.darkened(0.2))
	var label := Label3D.new()
	label.text = "WORKBENCH" if site.station_id==&"workbench" else ("MASON'S YARD" if site.station_id==&"mason_yard" else "FORGE")
	label.position = Vector3(0,1.7,0)
	label.font_size = 28
	label.pixel_size = 0.004
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	details.add_child(label)

func _setup_view() -> void:
	super._setup_view()
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 48
	camera.position = Vector3(20,12,-12)
	camera.look_at(Vector3(7,3.5,7))
	caption.text = "THE WORKSHOP · MODULAR ROOF STUDY\n64 removable roof pieces · ordinary grid · separate playable lab"

func _probe() -> void:
	check(player.placement.enclosure_at(CENTRE)["enclosed"],"modular workshop shelters")
	check(player.placement.enclosure_at(Vector3(3.8,2.5,3.8))["enclosed"],"diagonal usable corner shelters")
	check(station_count == 3,"existing three stations are available")
	var recipe: Dictionary = sim.recipe("smelt_iron")
	for material in recipe["inputs"]:
		sim.add_material(material,recipe["inputs"][material])
	sim.add_material("wood",int(recipe["fuel_cost"]))
	check(sim.craft("smelt_iron")["crafted"],"real forge uses fuel and recipe")
	# The same ray -> preview -> payment path used by the player, not only
	# the uncharged placement helper used to assemble and restore fixtures.
	var placement := player.placement
	var old_camera := placement.camera
	var old_position := camera.position
	var old_rotation := camera.rotation
	camera.position = Vector3(18.5,4,12.5)
	camera.look_at(Vector3(18.5,0,12.5),Vector3.FORWARD)
	placement.camera = camera
	placement.set_build_mode_enabled(true)
	placement.select_shape(&"codex_roof_hip")
	placement.selected_material_family = &"pine"
	sim.add_material("pine",2)
	var before := sim.material_count("pine")
	placement._update_preview()
	check(placement.preview_valid,"roof hip has a valid surface-ray preview")
	check(placement.try_place_block(),"player placement path builds a roof hip")
	check(sim.material_count("pine")==before-1,"player placement pays the fixture's stated cost")
	placement.set_build_mode_enabled(false)
	placement.camera = old_camera
	camera.position = old_position
	camera.rotation = old_rotation
	# Rays at interior points distinguish a hip from a convex-filled valley.
	var physics := get_world_3d().direct_space_state
	for piece in roof_samples:
		var arrays := piece._mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var planar := true
		for i in range(0,vertices.size(),3):
			var normal := (vertices[i+2]-vertices[i]).cross(vertices[i+1]-vertices[i]).normalized()
			for j in 3:
				planar = planar and normal.dot(normals[i+j])>0.999
		check(planar,"roof transition keeps hard normals at construction creases")
		for point in [Vector2(0.22,0.71),Vector2(0.73,0.28),Vector2(0.64,0.81)]:
			var local := Vector3(point.x-0.5,0,point.y-0.5)
			var at := piece.global_transform * local
			var hit := physics.intersect_ray(PhysicsRayQueryParameters3D.create(at+Vector3.UP*2,at-Vector3.UP*2))
			var height := minf(point.x,point.y) if piece.form == "roof_hip" else maxf(point.x,point.y)
			var expected := piece.position.y - 0.25 + height * 0.5
			check(hit.get("collider") == piece,"ray selects rotated roof transition")
			check(not hit.is_empty() and absf(hit.position.y-expected)<0.002,"roof collision follows exact sloping surface")
	var piece := roof_pieces[0]
	var address := piece.element.duplicate()
	var id := piece.shape_id
	var turn := piece.rotation_step
	check(player.placement.remove_piece(piece),"roof piece removes through normal building controls")
	check(player.placement.place_piece(address,id,&"pine",turn)!=null,"roof piece rebuilds at same address")
	# Test a lower-roof hole outside the raised cap: it must really leak.
	var slab: PlacedBlock
	for node in get_children():
		if node is PlacedBlock and node.shape_id == &"floor_slab" and node.element["cell"] == Vector3i(12,10,2):
			slab = node
	check(slab != null,"lower eave ceiling sample exists")
	if slab != null:
		var at := slab.element.duplicate()
		player.placement.remove_piece(slab)
		check(not player.placement.enclosure_at(CENTRE)["enclosed"],"lower roof hole leaks despite raised roof")
		player.placement.place_piece(at,&"floor_slab",&"pine")
		check(player.placement.enclosure_at(CENTRE)["enclosed"],"repair restores shelter")
	observations = {"roof_pieces":64,"roof_forms":["slope","hip","valley"],
		"save_scope":"lab catalogue and separate workshop file", "roof_occupancy":"whole block, as existing wedge",
		"shelter":"saved lower ceiling plus roof blocks; lower eave hole leaks"}

func _physics_process(_delta: float) -> void:
	if playable:
		if OS.get_cmdline_user_args().has("--workshop-smoke"):
			frame += 1
			if frame==30:
				check(player.is_on_floor(),"playable workshop player settles on the floor")
				check(player.save_game(),"playable lab writes its isolated smoke save")
				check(player.load_game(),"playable lab reloads its isolated smoke save")
				check(sim.shape_unlocked("codex_roof_hip"),"roof shapes are selectable in playable lab")
			if frame==50:
				await _capture("playable")
				print("Codex playable workshop: %d checks, %d failures" % [checks,failures])
				get_tree().quit(0 if failures==0 else 1)
		return
	frame += 1
	if frame == 5:
		_probe()
	if frame == 15:
		_save_roundtrip()
	if frame == 30:
		await _capture("exterior")
		camera.position = Vector3(7,2.85,-5)
		camera.look_at(Vector3(7,3.1,7))
		caption.text = "THE WORKSHOP · EYE LEVEL\nSheltered corner space · working forge and storage · pitched roof on the lattice"
	if frame == 45:
		await _capture("entrance")
		camera.position = Vector3(7,2.85,4.3)
		camera.fov = 85
		camera.look_at(Vector3(7.2,2.6,9))
		caption.text = "THE WORKSHOP · INSIDE\nThe ceiling stays visible here · build, remove and save in the playable lab"
	if frame == 60:
		await _capture("interior")
		observations["elapsed_ms"] = Time.get_ticks_msec()-start_ticks
		var file := FileAccess.open(output.path_join("observations.json"),FileAccess.WRITE)
		file.store_string(JSON.stringify(observations,"  "))
		print("CODEX_ROOF_WORKSHOP ",JSON.stringify(observations))
		print("%d checks, %d failures" % [checks,failures])
		get_tree().quit(0 if failures == 0 else 1)
