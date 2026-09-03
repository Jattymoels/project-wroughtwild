class_name PlacedBlock
extends StaticBody3D
## A player-placed construction piece standing on one element of the
## building lattice (Wave 4): a cell, a face two cells share, or an edge
## four share. The sim's structure registry is the authority on what
## occupies what; this node is its shape in the world.

## Shape id from data/tuning/construction.json; its cost and refund come
## from the rules library, not from the block.
@export var shape_id: StringName = &"cube"
## Family the block was paid with, refunded (partially) on removal.
@export var material_family: StringName = &"wood"

## The lattice element this piece occupies: {kind, axis, cell}.
var element: Dictionary = {}
## Quarter turns the player gave an oriented block (R); 0 for everything else.
var rotation_step := 0


## size comes from the shape's size_m (the scene's mesh and collision are
## unit cubes); pose is the element's centre and yaw, from the sim.
func init_piece(in_shape: StringName, in_family: StringName, in_element: Dictionary,
		in_rotation_step: int, size: Vector3, centre: Vector3, yaw: float) -> void:
	shape_id = in_shape
	material_family = in_family
	element = in_element.duplicate()
	rotation_step = in_rotation_step
	global_position = centre
	rotation.y = yaw
	scale = size
