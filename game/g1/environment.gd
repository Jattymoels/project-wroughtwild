class_name G1Environment
extends Node
## Decorate existing scenery only; native poses, collision and stock stay owned.
var adapter: RefCounted
var clock := 0.0

static func install(owner_world: Node3D) -> void:
	var previous := owner_world.get_node_or_null("G1Environment")
	if previous != null: previous.free()
	var root := G1Environment.new()
	root.name = "G1Environment"
	owner_world.add_child(root)
	root.adapter = load("res://c6/adapter.gd").new()
	root.adapter.install(owner_world)

static func cover_mesh(entry: Dictionary) -> ArrayMesh:
	return R7Cover.ground(entry)

func _process(delta: float) -> void:
	clock += delta
	R7Cover.tick(clock)
	var camera := get_viewport().get_camera_3d()
	if adapter != null and camera != null: adapter.tick(delta, camera)
