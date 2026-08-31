class_name PlacedBlock
extends StaticBody3D
## A player-placed construction shape occupying one grid cell.

## Shape id from data/tuning/construction.json; its cost and refund come
## from the rules library, not from the block.
@export var shape_id: StringName = &"cube"
## Family the block was paid with, refunded (partially) on removal.
@export var material_family: StringName = &"wood"


func init_block(in_shape: StringName, in_family: StringName, grid_size: float) -> void:
	shape_id = in_shape
	material_family = in_family
	scale = Vector3.ONE * grid_size
