class_name PlacedBlock
extends StaticBody3D
## A player-placed construction piece anchored on one element of the
## building lattice (Wave 4, D-017): a cell, a face two cells share, or an
## edge four share. The sim's structure registry is the authority on what
## occupies what; this node is the piece's shape in the world, built from
## its form (PieceMesh): a box, stairs, a wedge, or a door that swings.

## Shape id from data/tuning/construction.json; its cost and refund come
## from the rules library, not from the block.
@export var shape_id: StringName = &"cube"
## Family the block was paid with, refunded (partially) on removal.
@export var material_family: StringName = &"wood"

## The lattice element this piece is anchored on: {kind, axis, cell}
## (registry coordinates).
var element: Dictionary = {}
## Quarter turns the player gave an oriented piece (R); 0 for the rest.
var rotation_step := 0
## construction.json form: box | stairs | wedge | door | arch | fire.
var form := "box"
var size := Vector3.ONE
## Doors: swung open (no collision) or shut.
var open := false
## Fires (D-020 fire-setting): seconds of fuel left, the heat the fuel
## burns at, and the soak clock before the rock beside it counts as hot.
var burn_left := 0.0
var fire_heat := 0
var _soaked := 0.0
var _heat_tick := 0.0
var _ember: MeshInstance3D
var _light: OmniLight3D

## Doors hang their leaf from a pivot on the hinge edge so opening is one
## rotation; every other form builds straight under the body.
var _pivot: Node3D
var _collision_shapes: Array[CollisionShape3D] = []
var _look: Material


## Builds the piece at its pose. size comes from the shape's size_m; centre
## and yaw from the sim's lattice pose (plus the rotation step, applied by
## the placement script).
func init_piece(in_shape: StringName, in_family: StringName, in_element: Dictionary,
		in_rotation_step: int, in_form: String, in_size: Vector3, centre: Vector3, yaw: float,
		look: Material = null) -> void:
	shape_id = in_shape
	material_family = in_family
	element = in_element.duplicate()
	rotation_step = in_rotation_step
	form = in_form
	size = in_size
	global_position = centre
	rotation.y = yaw
	_look = look
	_build()


func is_door() -> bool:
	return form == "door"


func is_fire() -> bool:
	return form == "fire"


func _build() -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	_collision_shapes.clear()
	var parent: Node3D = self
	if is_door():
		# Hinge on the local -x edge; the leaf sits half a width out from it.
		_pivot = Node3D.new()
		add_child(_pivot)
		_pivot.position = Vector3(-size.x * 0.5, 0.0, 0.0)
		parent = _pivot
	var mesh := MeshInstance3D.new()
	mesh.mesh = PieceMesh.mesh_for(form, size)
	if _look != null:
		mesh.material_override = _look
	parent.add_child(mesh)
	if is_door():
		mesh.position = Vector3(size.x * 0.5, 0.0, 0.0)
	# Collision shapes must be direct children of the body (Godot ignores
	# shapes under an intermediate node), so the door's leaf collides from
	# here and swings with the mesh: an open door still catches E at the
	# doorway's edge, which is how it gets shut again.
	for entry in PieceMesh.collision_for(form, size):
		var shape := CollisionShape3D.new()
		shape.shape = entry["shape"]
		shape.transform = entry["transform"]
		add_child(shape)
		_collision_shapes.append(shape)
	_swing(open)
	if is_fire():
		_light_fire()


## The fuel decides the burn (worldgen.json fire_setting fuels, by the
## family the fire was laid in): how long, how hot. The ember heap glows
## and a small light warms the rock face while it lasts.
func _light_fire() -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var rules: Dictionary = sim.fire_setting()
	var fuel: Dictionary = rules.get("fuels", {}).get(String(material_family), {})
	burn_left = float(fuel.get("burn_seconds", 30.0))
	fire_heat = int(fuel.get("heat", 1))
	_soaked = 0.0
	_heat_tick = 0.0
	_ember = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(size.x * 0.36, size.y * 0.32, size.z * 0.36)
	var glow := StandardMaterial3D.new()
	glow.albedo_color = Color(1.0, 0.5, 0.12)
	glow.emission_enabled = true
	glow.emission = Color(1.0, 0.45, 0.08) if fire_heat < 2 else Color(1.0, 0.75, 0.3)
	glow.emission_energy_multiplier = 2.5
	box.material = glow
	_ember.mesh = box
	_ember.position = Vector3(0.0, -size.y * 0.5 + size.y * 0.2, 0.0)
	add_child(_ember)
	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.6, 0.25)
	_light.light_energy = 1.6 if fire_heat < 2 else 2.4
	_light.omni_range = 5.0
	_light.position = Vector3(0.0, 0.4, 0.0)
	add_child(_light)


func _process(delta: float) -> void:
	if not is_fire() or burn_left <= 0.0:
		return
	burn_left -= delta
	_soaked += delta
	var rules: Dictionary = _fire_rules()
	if _soaked >= float(rules.get("soak_seconds", 4.0)):
		_heat_tick -= delta
		if _heat_tick <= 0.0:
			_heat_tick = 1.0
			var terrain := _terrain()
			if terrain != null and not terrain.map.is_empty():
				var cs: float = terrain.map["cell_size"]
				var cell := Vector3i(floori(global_position.x / cs), floori((global_position.y - size.y * 0.5 + 0.05) / cs), floori(global_position.z / cs))
				terrain.heat_around(cell, fire_heat, int(rules.get("reach_cells", 1)))
	if _light != null:
		_light.light_energy = (1.6 if fire_heat < 2 else 2.4) * (0.85 + 0.15 * sin(Time.get_ticks_msec() * 0.02))
	if burn_left <= 0.0:
		_burn_out()


func _fire_rules() -> Dictionary:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	return sim.fire_setting()


func _terrain() -> Terrain:
	var scene := get_tree().current_scene
	if scene == null:
		return null
	return scene.get_node_or_null("Terrain") as Terrain


## The fuel is ash: the piece leaves the structure registry and the world.
## No refund (the wood burned), which is what makes a quarry cost fuel.
func _burn_out() -> void:
	burn_left = 0.0
	var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player != null and player.placement != null:
		player.placement.remove_piece(self)
		return
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	sim.structure_remove(element)
	queue_free()


## Doors: swing the leaf open or shut. Open doors have no collision, so a
## mob can follow you through. Returns the new state.
func toggle() -> bool:
	if not is_door():
		return false
	open = not open
	_swing(open)
	return open


## Puts the leaf (mesh and collision) shut across the opening or swung a
## quarter turn about its hinge, standing along the doorway's side.
func _swing(is_open: bool) -> void:
	if not is_door():
		return
	var hinge := Transform3D(Basis(Vector3.UP, -PI / 2.0 if is_open else 0.0), Vector3(-size.x * 0.5, 0.0, 0.0))
	var leaf := Transform3D(Basis.IDENTITY, Vector3(size.x * 0.5, 0.0, 0.0))
	if _pivot != null:
		_pivot.transform = hinge
	for shape in _collision_shapes:
		shape.transform = hinge * leaf


## Where the leaf's centre is in the world right now (tests aim at it).
func leaf_point() -> Vector3:
	if _collision_shapes.is_empty():
		return global_position
	return _collision_shapes[0].global_position


## What the crosshair label should offer for this piece ("" for nothing).
func interact_label() -> String:
	if is_door():
		return "E close the door" if open else "E open the door"
	return ""
