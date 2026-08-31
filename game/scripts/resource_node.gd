class_name ResourceNode
extends StaticBody3D
## A harvestable world resource (wood or iron in the slice). Depletes and
## frees itself; a respawn policy is a later design question, not spiked.

## Material family granted per harvest, matching data/tuning ids
## (e.g. "wood", "iron_ore").
@export var material_family: StringName = &"wood"
@export var remaining_units: int = 20
@export var units_per_harvest: int = 2
## Gathering site in data/tuning/world.json this node belongs to; drives
## ambush chance and which enemies arrive. Empty means never ambushed.
@export var gather_site_id: StringName = &""
## Greybox look from worldgen.json's node visual key: tree | boulder |
## iron_vein. Empty keeps the scene's default cylinder.
@export var visual: StringName = &""


func _ready() -> void:
	_apply_visual()


static func _textured(texture_path: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture_path)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 1.0
	return material


func _apply_visual() -> void:
	var mesh_instance: MeshInstance3D = get_node_or_null("MeshInstance3D")
	var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if mesh_instance == null or collider == null:
		return
	match visual:
		&"tree":
			var trunk := BoxMesh.new()
			trunk.size = Vector3(0.6, 3.0, 0.6)
			trunk.material = _textured("res://assets/textures/bark.png")
			mesh_instance.mesh = trunk
			mesh_instance.position = Vector3(0, 1.5, 0)
			var crown := MeshInstance3D.new()
			var leaves := BoxMesh.new()
			leaves.size = Vector3(2.2, 1.8, 2.2)
			leaves.material = _textured("res://assets/textures/leaves.png")
			crown.mesh = leaves
			crown.position = Vector3(0, 3.6, 0)
			add_child(crown)
			var shape := BoxShape3D.new()
			shape.size = Vector3(0.7, 3.0, 0.7)
			collider.shape = shape
			collider.position = Vector3(0, 1.5, 0)
		&"boulder":
			var rock := BoxMesh.new()
			rock.size = Vector3(1.4, 1.0, 1.2)
			rock.material = _textured("res://assets/textures/stone_node.png")
			mesh_instance.mesh = rock
			mesh_instance.position = Vector3(0, 0.5, 0)
			mesh_instance.rotation.y = 0.5
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.4, 1.0, 1.2)
			collider.shape = shape
			collider.position = Vector3(0, 0.5, 0)
		&"iron_vein":
			var vein := BoxMesh.new()
			vein.size = Vector3(1.2, 0.9, 1.2)
			vein.material = _textured("res://assets/textures/iron_vein.png")
			mesh_instance.mesh = vein
			mesh_instance.position = Vector3(0, 0.45, 0)
			mesh_instance.rotation.y = -0.35
			var shape := BoxShape3D.new()
			shape.size = Vector3(1.2, 0.9, 1.2)
			collider.shape = shape
			collider.position = Vector3(0, 0.45, 0)


## Returns the units actually granted (0 when depleted).
func harvest() -> int:
	if remaining_units <= 0:
		return 0

	var granted: int = mini(units_per_harvest, remaining_units)
	remaining_units -= granted

	if remaining_units <= 0:
		queue_free()
	return granted
