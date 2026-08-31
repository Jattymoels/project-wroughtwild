class_name PlacedBlock
extends StaticBody3D
## A player-placed construction shape occupying one grid cell.

## Shape id from data/tuning/construction.json; its cost and refund come
## from the rules library, not from the block.
@export var shape_id: StringName = &"cube"
## Family the block was paid with, refunded (partially) on removal.
@export var material_family: StringName = &"wood"


## size comes from the shape's size_m in construction.json (the scene's mesh
## and collision are unit cubes).
func init_block(in_shape: StringName, in_family: StringName, size: Vector3) -> void:
	shape_id = in_shape
	material_family = in_family
	scale = size
