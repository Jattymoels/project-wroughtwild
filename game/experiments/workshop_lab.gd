extends "res://experiments/octagon_lab.gd"
## Codex (OpenAI), not Claude. A complete lab workshop on existing addresses.

var roof_cap: MeshInstance3D
var saved: Dictionary
var first_corner: PlacedBlock
var floor_corner: PlacedBlock
var station_count := 0
var chest_key := ""
const CENTRE := Vector3(7, 2.5, 7)

func review_id() -> String:
	return "workshop"

func shape_fixtures() -> Array:
	var fixtures := super.shape_fixtures()
	fixtures.append(JSON.parse_string(FileAccess.get_file_as_string("res://experiments/workshop_floor.json")))
	return fixtures

func _put(cell: Vector3i, shape: StringName = &"cube", turn: int = 0, family: StringName = &"pine", kind: String = "volume", axis: int = 0) -> PlacedBlock:
	var piece := player.placement.place_piece({"kind": kind, "axis": axis, "cell": cell * 2}, shape, family, turn)
	check(piece != null, "workshop place %s at %s" % [shape, cell])
	return piece

func _build_room() -> void:
	# A band: outside triangular row, full middle row, inside triangular row.
	# This gives both sides a continuous diagonal instead of an exterior sawtooth.
	for x in 14:
		for z in 14:
			var distances := [x + z, 13 - x + z, 26 - x - z, x + 13 - z]
			var nearest: int = distances.min()
			if nearest < 4:
				continue
			var turn: int = [3, 2, 1, 0][distances.find(nearest)]
			var outer := nearest == 4
			var inner := nearest == 6 and x not in [0, 13] and z not in [0, 13]
			var slab: StringName = &"codex_corner_floor" if outer else &"floor_slab"
			var slab_turn := (turn + 2) % 4 if outer else 0
			var floor := _put(Vector3i(x, 1, z), slab, slab_turn, &"stone", "face", 1)
			if x == 2 and z == 2:
				floor_corner = floor
			roofs.append(_put(Vector3i(x, 5, z), slab, slab_turn, &"pine", "face", 1))
			for y in range(1, 5):
				if x == 6 and z == 0 and y < 3:
					continue
				var family: StringName = &"stone" if y == 1 else &"pine"
				if outer or inner:
					var corner_turn := (turn + 2) % 4 if outer else turn
					var block := _put(Vector3i(x, y, z), &"codex_corner", corner_turn, family)
					if x == 3 and z == 3 and y == 2:
						first_corner = block
				elif nearest == 5 or x in [0, 13] or z in [0, 13]:
					_put(Vector3i(x, y, z), &"cube", 0, family)
	door = _put(Vector3i(6, 1, 1), &"door", 0, &"bog_oak", "face", 2)
	# Working stations and stored materials use the existing sim and save paths.
	for entry in [["workbench", Vector3(5, 1.13, 9)], ["mason_yard", Vector3(8, 1.13, 9)], ["forge_basic", Vector3(9, 1.13, 7)]]:
		var id := String(entry[0])
		if sim.station(id).is_empty():
			continue
		sim.add_station(id)
		var site: StationSite = preload("res://scenes/station_site.tscn").instantiate()
		site.station_id = StringName(id)
		site.upgrade_station_id = &""
		site.name = "Workshop_" + id
		add_child(site)
		site.position = entry[1]
		station_count += 1
	var chest := _put(Vector3i(5, 1, 7), &"chest", 0, &"bog_oak")
	chest_key = chest.store_key()
	sim.add_material("wood", 5)
	check(sim.store_deposit(chest_key, "wood", 5) == 5, "workshop chest holds real materials")
	player.position = Vector3(7, 1.2, 6)
	_add_roof_cap()
	_dress()

func _add_roof_cap() -> void:
	# Lab roof dressing over a fully saved, collidable octagonal ceiling.
	# Deliberately not exposed as a build piece or a new save representation.
	var outline := [Vector3(0, 5.12, 5), Vector3(5, 5.12, 0), Vector3(9, 5.12, 0), Vector3(14, 5.12, 5),
		Vector3(14, 5.12, 9), Vector3(9, 5.12, 14), Vector3(5, 5.12, 14), Vector3(0, 5.12, 9)]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 8:
		var a: Vector3 = outline[i]
		var b: Vector3 = outline[(i + 1) % 8]
		var peak := Vector3(7, 8, 7)
		var normal := (peak - a).cross(b - a).normalized()
		for vertex in [a, peak, b]:
			st.set_normal(normal)
			st.set_color(Color("344d58").lightened(0.055 * float(i % 3)))
			st.add_vertex(vertex)
	roof_cap = MeshInstance3D.new()
	roof_cap.mesh = st.commit()
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.roughness = 1.0
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	roof_cap.material_override = material
	add_child(roof_cap)

func _dress() -> void:
	for piece in get_children():
		if not piece is PlacedBlock:
			continue
		var material := StandardMaterial3D.new()
		material.roughness = 1.0
		match String(piece.material_family):
			"stone": material.albedo_color = Color("74747a")
			"bog_oak": material.albedo_color = Color("4d3b2e")
			_: material.albedo_color = Color("c4ae82")
		piece._mesh.material_override = material
	# Exposed framing uses existing beam/post meshes; decorative, not paid parts.
	if has_node("Dressing"):
		return
	var dressing := Node3D.new()
	dressing.name = "Dressing"
	add_child(dressing)
	var outline := [Vector3(0, 0, 5), Vector3(5, 0, 0), Vector3(9, 0, 0), Vector3(14, 0, 5),
		Vector3(14, 0, 9), Vector3(9, 0, 14), Vector3(5, 0, 14), Vector3(0, 0, 9)]
	for i in 8:
		var a: Vector3 = outline[i]
		var b: Vector3 = outline[(i + 1) % 8]
		for y in [2.05, 4.92]:
			var beam := MeshInstance3D.new()
			var box := BoxMesh.new()
			box.size = Vector3(0.18, 0.18, a.distance_to(b) + 0.18)
			beam.mesh = box
			dressing.add_child(beam)
			beam.position = (a + b) * 0.5 + Vector3.UP * float(y)
			beam.look_at(b + Vector3.UP * float(y))
			var dark := StandardMaterial3D.new()
			dark.albedo_color = Color("4d3b2e")
			beam.material_override = dark
		var post := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.22, 3, 0.22)
		post.mesh = mesh
		post.position = a + Vector3(0, 3.5, 0)
		var material := StandardMaterial3D.new()
		material.albedo_color = Color("4d3b2e")
		post.material_override = material
		dressing.add_child(post)

func _setup_view() -> void:
	super._setup_view()
	camera.size = 19
	camera.position = Vector3(23, 18, -15)
	camera.look_at(Vector3(7, 3.5, 7))
	caption.text = "CODEX / OCTAGON WORKSHOP\nStone footing · timber frame · hipped roof study"

func _probe() -> void:
	check(player.placement.enclosure_at(CENTRE)["enclosed"], "workshop centre is sheltered")
	check(station_count == 3, "three real workshop stations exist")
	var recipe: Dictionary = sim.recipe("smelt_iron")
	for material in recipe["inputs"]:
		sim.add_material(material, recipe["inputs"][material])
	sim.add_material("wood", int(recipe["fuel_cost"]))
	check(sim.craft("smelt_iron")["crafted"], "workshop forge crafts through existing recipe and fuel rules")
	check(player.placement.enclosure_at(Vector3(3.8, 2.5, 3.8))["enclosed"], "inner corner's usable half shelters")
	check(not player.placement.enclosure_at(Vector3(3.1, 2.5, 3.1))["enclosed"], "inside the timber is not shelter air")
	var physics := get_world_3d().direct_space_state
	var ray := physics.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(4, 2.5, 4), Vector3(3.1, 2.5, 3.1)))
	check(ray.get("collider") == first_corner, "inner chamfer ray hits the physical wall")
	var outside := physics.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(1, 2.5, 1), Vector3(2.8, 2.5, 2.8)))
	check(not outside.is_empty(), "outer chamfer is collidable")
	var floor_air := physics.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(2.1, 1.8, 2.1), Vector3(2.1, 0.5, 2.1)))
	check(floor_air.is_empty(), "clipped floor has no square corner hanging outside the wall")
	var element := first_corner.element.duplicate()
	check(player.placement.remove_piece(first_corner), "inner corner can be removed")
	check(player.placement.place_piece(element, &"codex_corner", &"pine", 3) != null, "inner corner snaps back to its saved address")
	var roof: PlacedBlock
	for piece in roofs:
		if piece.element["cell"] == Vector3i(14, 10, 14):
			roof = piece
	var address := roof.element.duplicate()
	player.placement.remove_piece(roof)
	check(not player.placement.enclosure_at(CENTRE)["enclosed"], "missing ceiling opens the workshop despite decorative roof cap")
	player.placement.place_piece(address, &"floor_slab", &"pine")
	check(player.placement.enclosure_at(CENTRE)["enclosed"], "repair restores shelter")
	door.toggle()
	check(player.placement.enclosure_at(CENTRE)["enclosed"], "door ajar still shelters by accepted rule")
	door.toggle()
	observations = {"empty_half_sheltered": true, "inner_and_outer_diagonals": true,
		"clipped_floor": true, "stations": station_count, "roof_cap": "lab dressing; saved ceiling provides shelter"}

func _save_roundtrip() -> void:
	var manager := SaveManager.new()
	saved = manager.capture(player)
	check(manager.apply(player, JSON.parse_string(JSON.stringify(saved))), "workshop restores through existing save schema")
	var restored := manager.capture(player)
	check(JSON.stringify(saved["blocks"]) == JSON.stringify(restored["blocks"]), "workshop pieces, materials and rotations survive serialization")
	check(saved["stations"].size() == restored["stations"].size(), "workshop station sites survive restoration")
	check(sim.store_contents(chest_key).get("wood", 0) == 5, "stored materials survive workshop restoration")
	check(player.placement.enclosure_at(Vector3(3.8, 2.5, 3.8))["enclosed"], "usable corner half shelters after save restore")
	_dress()

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		_probe()
	if frame == 15:
		_save_roundtrip()
	if frame == 30:
		await _capture("exterior")
		roof_cap.hide()
		for piece in get_children():
			if piece is PlacedBlock and piece.element["kind"] == "face" and piece.element["axis"] == 1 and piece.element["cell"].y == 10:
				piece.hide()
		caption.text = "CODEX / OCTAGON WORKSHOP\nCutaway · both wall faces are diagonal · usable corner space shelters"
	if frame == 45:
		await _capture("cutaway")
		camera.projection = Camera3D.PROJECTION_PERSPECTIVE
		camera.fov = 80
		camera.position = Vector3(7, 2.8, 5)
		camera.look_at(Vector3(7, 2.2, 10))
		caption.text = "CODEX / OCTAGON WORKSHOP\nInterior · bench, mason's yard, forge and storage"
	if frame == 60:
		await _capture("interior")
		var file := FileAccess.open(output.path_join("observations.json"), FileAccess.WRITE)
		file.store_string(JSON.stringify(observations, "  "))
		print("CODEX_WORKSHOP ", JSON.stringify(observations))
		print("%d checks, %d failures" % [checks, failures])
		get_tree().quit(0 if failures == 0 else 1)

func _capture(view: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output.path_join(view + ".png")) == OK, "capture " + view)
