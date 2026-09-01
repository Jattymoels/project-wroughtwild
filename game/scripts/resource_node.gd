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


## Yield when the node first appeared, so the visual shrink tracks the
## fraction actually taken (feel: you can SEE a node is nearly spent).
var _initial_units := 0
## Materials created for this node's own meshes; safe to tint for the
## look-at highlight because they are never shared between nodes.
var _own_materials: Array = []


func _ready() -> void:
	_initial_units = maxi(remaining_units, 1)
	_apply_visual()


func _textured(texture_path: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture_path)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 1.0
	material.emission = Color(0.85, 0.85, 0.6)
	material.emission_energy_multiplier = 0.35
	_own_materials.append(material)
	return material


## Crosshair-hover feedback: a soft glow on the node you would harvest.
func set_highlight(on: bool) -> void:
	for material in _own_materials:
		material.emission_enabled = on


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
		_deplete()
	elif is_inside_tree():
		_play_harvest_punch()
	return granted


## Feel: each harvest gives the node a quick squash-and-settle, landing on a
## scale that tracks how much yield is left - a half-spent tree looks it.
func _play_harvest_punch() -> void:
	var target := _scale_for_remaining()
	scale = target * 0.86
	var tween := create_tween()
	tween.tween_property(self, "scale", target, 0.18) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _scale_for_remaining() -> Vector3:
	var fraction := float(remaining_units) / float(maxi(_initial_units, 1))
	return Vector3.ONE * lerpf(0.6, 1.0, fraction)


## The last harvest shrinks the node away instead of blinking it out.
## Collision goes immediately so the space is usable at once.
func _deplete() -> void:
	if not is_inside_tree():
		queue_free()
		return
	var collider: CollisionShape3D = get_node_or_null("CollisionShape3D")
	if collider != null:
		collider.set_deferred("disabled", true)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3.ONE * 0.02, 0.3) \
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)
