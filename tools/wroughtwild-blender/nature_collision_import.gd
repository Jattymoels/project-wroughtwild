@tool
extends EditorScenePostImport
## These proxies represent existing BoxShape3D contracts. Keep them as boxes,
## avoiding approximation from automatic convex hull generation.
func _post_import(scene: Node) -> Object:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var id := get_source_file().get_file().trim_suffix("_collision.glb")
	var candidate := id.ends_with("_fit")
	id = id.trim_suffix("_fit")
	var contract: Dictionary = report.assets[id].candidate_collision if candidate else report.assets[id].collision
	for child in scene.get_children():
		child.free()
	if scene is Node3D:
		scene.transform = Transform3D.IDENTITY
	var body: StaticBody3D = scene as StaticBody3D
	if body == null:
		body = StaticBody3D.new()
		body.name = "ResourceBody"
		scene.add_child(body)
		body.owner = scene
	var shape := CollisionShape3D.new()
	shape.name = "CollisionShape3D"
	shape.shape = BoxShape3D.new()
	shape.shape.size = Vector3(contract["size"][0], contract["size"][1], contract["size"][2])
	shape.position = Vector3(contract.centre[0], contract.centre[1], contract.centre[2])
	body.add_child(shape)
	shape.owner = scene
	return scene
