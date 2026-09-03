class_name Nest
extends StaticBody3D
## A mob nest (encroachment, D-018): a mound on the fringe of the player's
## home that fields a pack, grows a tier at a time and blights rest nearby.
## Nothing here damages a wall. Tearing it down (E, once its pack is dead)
## ends the nuisance and scars the spot; it drops nothing.

const TIER_NAMES := ["den", "warren", "hive", "hive"]

var nest_id := 0
var tier := 1
var _mesh: MeshInstance3D
var _label: Label3D
var _material: StandardMaterial3D


static func spawn(root: Node, at: Vector3, id: int, in_tier: int) -> Nest:
	var nest := Nest.new()
	nest.nest_id = id
	root.add_child(nest)
	nest.global_position = at
	nest.add_to_group("nests")
	nest.set_tier(in_tier)
	return nest


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.albedo_color = Color(0.22, 0.18, 0.17)
	_material.roughness = 1.0
	_mesh = MeshInstance3D.new()
	_mesh.material_override = _material
	add_child(_mesh)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.6, 0.9, 1.6)
	shape.shape = box
	shape.position = Vector3(0, 0.45, 0)
	add_child(shape)
	_label = Label3D.new()
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
	_label.pixel_size = 0.006
	_label.position = Vector3(0, 1.6, 0)
	_label.modulate = Color(0.95, 0.55, 0.35)
	add_child(_label)
	set_tier(tier)


func set_tier(in_tier: int) -> void:
	tier = in_tier
	if _mesh == null:
		return
	# A low mound that grows with its tier.
	var mound := SphereMesh.new()
	var size := 0.9 + 0.25 * float(tier)
	mound.radius = size
	mound.height = size * 0.9
	mound.radial_segments = 8
	mound.rings = 4
	_mesh.mesh = mound
	_mesh.position = Vector3(0, 0.05, 0)
	if _label != null:
		_label.text = display_name()


func display_name() -> String:
	var kind: String = TIER_NAMES[clampi(tier - 1, 0, TIER_NAMES.size() - 1)]
	return "%s (tier %d)" % [kind.capitalize(), tier]


## The nest's living pack members.
func defenders() -> Array:
	var alive: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if (enemy as Enemy).nest_id == nest_id and (enemy as Enemy).life > 0.0:
			alive.append(enemy)
	return alive


func interact_label() -> String:
	var count := defenders().size()
	if count > 0:
		return "%s — defended by %d" % [display_name(), count]
	return "%s — E to tear down" % display_name()


## E: tear the nest down when nothing defends it.
func interact(player: WroughtwildPlayer) -> bool:
	if not defenders().is_empty():
		player.hud.notify("The %s is still defended." % display_name().to_lower())
		return false
	var controller := get_tree().get_first_node_in_group("encroachment") as Encroachment
	if controller == null:
		return false
	return controller.clear_nest(self, player)
