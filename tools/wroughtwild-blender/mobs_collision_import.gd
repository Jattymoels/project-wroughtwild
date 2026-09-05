@tool
extends EditorScenePostImport
## Keep the source actor's CapsuleShape3D and CharacterBody3D type exactly.
func _post_import(scene: Node) -> Object:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var id := get_source_file().get_file().trim_suffix("_collision.glb")
	var contract: Dictionary = report.assets[id].collision
	var actor := CharacterBody3D.new()
	actor.name = scene.name
	scene.free()
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	var shape := CapsuleShape3D.new()
	shape.radius = contract.radius
	shape.height = contract.height
	collider.shape = shape
	collider.position = Vector3(contract.centre[0],contract.centre[1],contract.centre[2])
	actor.add_child(collider)
	collider.owner = actor
	return actor
