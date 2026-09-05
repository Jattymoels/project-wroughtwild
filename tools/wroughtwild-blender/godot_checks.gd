extends SceneTree
## Run in the isolated generated review project, never against a game save.
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

func mesh_bounds(instance: Node) -> AABB:
	var combined := AABB()
	var first := true
	for node in nodes_of(instance, "MeshInstance3D"):
		var box: AABB = node.global_transform * node.get_aabb()
		combined = box if first else combined.merge(box)
		first = false
	return combined

func run() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	for id in report.assets:
		var dims: Array = report.assets[id].size_godot_metres
		var size := Vector3(dims[0], dims[1], dims[2])
		var visual: Node3D = load("res://" + id + ".glb").instantiate()
		root.add_child(visual)
		var box := mesh_bounds(visual)
		check(box.size.is_equal_approx(size), id + " exported axes and size")
		check(box.get_center().is_zero_approx(), id + " centred pivot")
		check(nodes_of(visual, "CollisionShape3D").is_empty(), id + " visual has no accidental collision")
		var collider: Node3D = load("res://" + id + "_collision.glb").instantiate()
		root.add_child(collider)
		var shapes := nodes_of(collider, "CollisionShape3D")
		check(shapes.size() == 1, id + " one collision proxy")
		check(nodes_of(collider, "MeshInstance3D").is_empty(), id + " collision proxy is not visible")
		if shapes.size() == 1:
			var shape: CollisionShape3D = shapes[0]
			check(shape.get_parent() is StaticBody3D, id + " collider belongs to physics body")
			var bounds: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
			check(bounds.size.is_equal_approx(size), id + " collision matches envelope")
			check(bounds.get_center().is_zero_approx(), id + " collision matches pivot")
			await physics_frame
			await physics_frame
			var world := shape.get_world_3d().direct_space_state
			var centre_ray := PhysicsRayQueryParameters3D.create(Vector3(0, 0, -2), Vector3(0, 0, 2))
			check(not world.intersect_ray(centre_ray).is_empty(), id + " blocks centre ray")
			var miss_ray := PhysicsRayQueryParameters3D.create(Vector3(size.x / 2 + .03, 0, -2), Vector3(size.x / 2 + .03, 0, 2))
			check(world.intersect_ray(miss_ray).is_empty(), id + " no collision beyond silhouette")
		visual.free()
		collider.free()
	# Wall modules meet on the metre grid; board seams must never become holes.
	var wall: PackedScene = load("res://wall_panel_collision.glb")
	var left: Node3D = wall.instantiate()
	var right: Node3D = wall.instantiate()
	root.add_child(left)
	root.add_child(right)
	right.position.x = 1.0
	await physics_frame
	await physics_frame
	for x in [.499, .5, .501]:
		var ray := PhysicsRayQueryParameters3D.create(Vector3(x, 0, -1), Vector3(x, 0, 1))
		check(not left.get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "wall join blocks ray at " + str(x))
	right.free()
	left.rotation.y = PI / 2
	await physics_frame
	await physics_frame
	var rotated_ray := PhysicsRayQueryParameters3D.create(Vector3(-1, 0, 0), Vector3(1, 0, 0))
	check(not left.get_world_3d().direct_space_state.intersect_ray(rotated_ray).is_empty(), "rotated wall blocks the correct axis")
	left.free()
	print("BLENDER_GODOT_CHECKS ", count, " checks, ", failures, " failures")
	quit(0 if failures == 0 else 1)
