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
## construction.json form: box | stairs | wedge | door.
var form := "box"
var size := Vector3.ONE
## Doors: swung open (no collision) or shut.
var open := false

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
