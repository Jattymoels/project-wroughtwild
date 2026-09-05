extends SceneTree
## Imported assets plus actual player-sized physics sweeps in an isolated world.
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

func sweep(world: World3D, capsule: CapsuleShape3D, x: float) -> float:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	query.transform = Transform3D(Basis.IDENTITY, Vector3(x, capsule.height/2, -2))
	query.motion = Vector3(0, 0, 4)
	return world.direct_space_state.cast_motion(query)[0]

func run() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var capsule := CapsuleShape3D.new()
	capsule.radius = report.player_capsule.radius
	capsule.height = report.player_capsule.height
	for id in report.assets:
		var data: Dictionary = report.assets[id]
		var visual: Node3D = load("res://" + id + ".glb").instantiate()
		root.add_child(visual)
		var meshes := nodes_of(visual, "MeshInstance3D")
		check(meshes.size() == 1, id + " single mesh")
		check(nodes_of(visual, "CollisionShape3D").is_empty(), id + " visual collision-free")
		check(visual.position.is_zero_approx(), id + " surface pivot preserved")
		if meshes.size() == 1:
			var instance: MeshInstance3D = meshes[0]
			check(instance.mesh.get_surface_count() == 1, id + " single material surface")
			var bounds: AABB = instance.global_transform * instance.get_aabb()
			check(bounds.position.is_equal_approx(vector(data.visual_bounds[0])), id + " minimum bound matches Blender")
			check(bounds.end.is_equal_approx(vector(data.visual_bounds[1])), id + " maximum bound matches Blender")
			check(bounds.position.y <= 0.0, id + " embedded ground contact")
			var arrays: Array = instance.mesh.surface_get_arrays(0)
			var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
			check(not colours.is_empty(), id + " vertex colours survive export")
			var material: StandardMaterial3D = instance.mesh.surface_get_material(0)
			check(material.vertex_color_use_as_albedo, id + " imported material reads vertex colour")
			var finite := true
			for vertex: Vector3 in arrays[Mesh.ARRAY_VERTEX]:
				finite = finite and vertex.is_finite()
			check(finite, id + " finite imported geometry")
		if data.collision == null:
			check(not FileAccess.file_exists("res://"+id+"_collision.glb"), id + " no decorative collision export")
			check(float(data.horizontal_radius) <= float(data.habitat_radius), id + " fits existing habitat placement radius")
			await physics_frame
			await physics_frame
			check(is_equal_approx(sweep(visual.get_world_3d(), capsule, 0), 1.0), id + " player capsule passes through decoration")
		else:
			var collision: Node3D = load("res://" + id + "_collision.glb").instantiate()
			root.add_child(collision)
			var shapes := nodes_of(collision, "CollisionShape3D")
			check(shapes.size() == 1, id + " single existing collision envelope")
			check(nodes_of(collision, "MeshInstance3D").is_empty(), id + " invisible collision proxy")
			if shapes.size() == 1:
				var shape: CollisionShape3D = shapes[0]
				check(shape.get_parent() is StaticBody3D, id + " collider owned by physics body")
				check(shape.shape is BoxShape3D, id + " retains existing primitive body type")
				var box_shape: BoxShape3D = shape.shape
				var bounds: AABB = shape.global_transform * AABB(-box_shape.size/2, box_shape.size)
				check(bounds.size.is_equal_approx(vector(data.collision["size"])), id + " baseline collision size")
				check(bounds.get_center().is_equal_approx(vector(data.collision.centre)), id + " baseline collision offset")
				await physics_frame
				await physics_frame
				check(sweep(collision.get_world_3d(), capsule, 0) < 1.0, id + " player capsule blocked by solid resource")
				var outside: float = float(data.collision["size"][0])/2+capsule.radius+.06
				check(is_equal_approx(sweep(collision.get_world_3d(), capsule, outside), 1.0), id + " player passes beside envelope")
				if id == "broadleaf_tree":
					check(is_equal_approx(sweep(collision.get_world_3d(), capsule, 1.05), 1.0), "player can walk below leaf canopy")
					var ray := PhysicsRayQueryParameters3D.create(Vector3(1.05, 2.6, -3), Vector3(1.05, 2.6, 3))
					check(collision.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "foliage does not block projectiles")
			collision.free()
		visual.free()
	print("BLENDER_NATURE_CHECKS ", count, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
