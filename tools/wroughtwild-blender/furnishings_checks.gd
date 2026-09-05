extends SceneTree
## Independent baseline collision comparison, rotated player sweeps and lid pivot.
var failures := 0
var count := 0

func check(ok: bool, message: String) -> void:
	count += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func _initialize() -> void:
	call_deferred("run")

func nodes_of(node: Node, kind: String) -> Array[Node]:
	var found: Array[Node] = []
	if node.is_class(kind):
		found.append(node)
	for child in node.get_children():
		found.append_array(nodes_of(child, kind))
	return found

func vector(value: Array) -> Vector3:
	return Vector3(value[0], value[1], value[2])

func source_vector(source: String, key: String) -> Vector3:
	var regex := RegEx.new()
	regex.compile(key + " = Vector3\\(([^)]+)")
	var numbers := regex.search(source).get_string(1).split(",")
	return Vector3(float(numbers[0]), float(numbers[1]), float(numbers[2]))

func sweep(world: World3D, capsule: CapsuleShape3D, pose: Transform3D, x: float, lift: float = 0) -> float:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(pose.basis, pose * Vector3(x, capsule.height/2+lift, 2))
	query.motion = pose.basis * Vector3(0, 0, -4)
	return world.direct_space_state.cast_motion(query)[0]

func run() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var construction: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://construction.json"))
	var source := FileAccess.get_file_as_string("res://station_source.txt")
	var capsule := CapsuleShape3D.new()
	capsule.radius = report.player_capsule.radius
	capsule.height = report.player_capsule.height
	check(report.assets.size() == 6, "complete existing six-role furnishing catalogue")
	for id in report.assets:
		var data: Dictionary = report.assets[id]
		var expected_size := source_vector(source, "size")
		var expected_centre := source_vector(source, "position")
		if id in ["chest", "campfire"]:
			for row: Dictionary in construction.shapes:
				if row.id == id:
					var baseline: Array = PieceMesh.collision_for(row.form, vector(row.size_m))
					expected_size = baseline[0].shape.size
					expected_centre = baseline[0].transform.origin
		var visual: Node3D = load("res://"+id+".glb").instantiate()
		root.add_child(visual)
		var meshes := nodes_of(visual, "MeshInstance3D")
		check(meshes.size() == int(data.mesh_parts), id+" expected mesh count")
		check(nodes_of(visual, "CollisionShape3D").is_empty(), id+" no collision in visual export")
		check(visual.transform.is_equal_approx(Transform3D.IDENTITY), id+" original game pivot and unit scale")
		var bounds := AABB()
		var first := true
		var surfaces := 0
		for instance: MeshInstance3D in meshes:
			var part: AABB = instance.global_transform * instance.get_aabb()
			bounds = part if first else bounds.merge(part)
			first = false
			for surface in instance.mesh.get_surface_count():
				surfaces += 1
				var arrays: Array = instance.mesh.surface_get_arrays(surface)
				var finite := true
				for point: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
					finite = finite and point.is_finite()
				check(finite, id+" finite surface geometry")
				var material: StandardMaterial3D = instance.mesh.surface_get_material(surface)
				check(material != null, id+" imported material")
				if material != null and not material.emission_enabled:
					check(material.albedo_texture != null, id+" embedded surface texture")
		check(surfaces == int(data.material_surfaces), id+" material slots survive export")
		check(bounds.position.is_equal_approx(vector(data.visual_bounds[0])), id+" imported minimum bound")
		check(bounds.end.is_equal_approx(vector(data.visual_bounds[1])), id+" imported maximum bound")
		check(absf(bounds.position.y-float(data.floor_y)) < .01, id+" cell/surface anchor preserved")
		if id == "chest":
			var lid: Node3D = visual.find_child("chest_lid_hinge", true, false)
			check(lid != null, "chest independent lid mesh")
			if lid != null:
				check(lid.global_position.is_equal_approx(vector(data.lid_hinge)), "chest rear hinge origin")
				var hinge := lid.global_position
				lid.rotation.x = -PI/2
				check(lid.global_position.is_equal_approx(hinge), "lid rotates about hinge without root translation")
				var open_bounds: AABB = lid.global_transform * (lid as MeshInstance3D).get_aabb()
				check(open_bounds.end.y > bounds.end.y+.4, "opened lid clears the storage body")
		visual.free()
		var collision: Node3D = load("res://"+id+"_collision.glb").instantiate()
		root.add_child(collision)
		var shapes := nodes_of(collision,"CollisionShape3D")
		check(shapes.size() == 1, id+" one collision body")
		check(nodes_of(collision,"MeshInstance3D").is_empty(), id+" proxy has no visible mesh")
		if shapes.size() == 1:
			var collider: CollisionShape3D = shapes[0]
			check(collider.shape is BoxShape3D, id+" original box primitive")
			check(collider.get_parent() is StaticBody3D, id+" static physics owner")
			check(collider.shape.size.is_equal_approx(expected_size), id+" size matches actual game source")
			check(collider.position.is_equal_approx(expected_centre), id+" offset matches actual game source")
			for turn in 4:
				collision.transform = Transform3D(Basis(Vector3.UP, turn*PI/2), Vector3(0, -float(data.floor_y), 0))
				await physics_frame
				await physics_frame
				# The sweep's frame is grounded, while the collider's frame retains
				# chest/fire's local cell offset. This exercises actual placement.
				var pose := Transform3D(collision.basis, Vector3.ZERO)
				var world := collision.get_world_3d()
				check(sweep(world,capsule,pose,0) < 1, id+" player blocked at turn "+str(turn))
				check(is_equal_approx(sweep(world,capsule,pose,expected_size.x/2+capsule.radius+.06),1), id+" side clearance at turn "+str(turn))
				var ray := PhysicsRayQueryParameters3D.create(pose*Vector3(0,.12,2),pose*Vector3(0,.12,-2))
				check(not world.direct_space_state.intersect_ray(ray).is_empty(), id+" interaction ray reaches existing body at turn "+str(turn))
				if id == "campfire":
					check(is_equal_approx(sweep(world,capsule,pose,0,.30),1), "campfire low pile clear above 0.30 m at turn "+str(turn))
		collision.free()
		if data.candidate_collision != null:
			var candidate: Node3D = load("res://"+id+"_fit_collision.glb").instantiate()
			root.add_child(candidate)
			var fitted := nodes_of(candidate,"CollisionShape3D")
			check(fitted.size() == 1, id+" candidate retains one primitive")
			check(nodes_of(candidate,"MeshInstance3D").is_empty(), id+" candidate is invisible")
			if fitted.size() == 1:
				var shape: CollisionShape3D = fitted[0]
				var target_height: float = .95 if id in ["workbench","mason_yard"] else bounds.end.y
				check(shape.shape is BoxShape3D, id+" candidate remains a box")
				check(is_equal_approx(shape.shape.size.y,target_height),id+" candidate top matches work surface or silhouette")
				check(is_equal_approx(shape.shape.size.x,expected_size.x) and is_equal_approx(shape.shape.size.z,expected_size.z),id+" candidate retains horizontal obstruction")
				for turn in 4:
					candidate.rotation.y = turn*PI/2
					await physics_frame
					await physics_frame
					var pose := Transform3D(candidate.basis,Vector3.ZERO)
					var world := candidate.get_world_3d()
					check(sweep(world,capsule,pose,0) < 1,id+" candidate still blocks walking at turn "+str(turn))
					check(is_equal_approx(sweep(world,capsule,pose,expected_size.x/2+capsule.radius+.06),1),id+" candidate keeps side clearance at turn "+str(turn))
					var ray := PhysicsRayQueryParameters3D.create(pose*Vector3(0,target_height+.02,2),pose*Vector3(0,target_height+.02,-2))
					check(world.direct_space_state.intersect_ray(ray).is_empty(),id+" candidate removes obstruction above surface at turn "+str(turn))
			candidate.free()
	print("BLENDER_FURNISHINGS_CHECKS ",count," checks, ",failures," failures")
	quit(0 if failures == 0 else 1)
