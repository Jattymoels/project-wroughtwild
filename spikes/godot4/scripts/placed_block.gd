class_name PlacedBlock
extends StaticBody3D
## A player-placed construction block occupying one grid cell.

## Family the block was paid with, refunded (partially) on removal.
@export var material_family: StringName = &"wood"
@export var material_cost: int = 1


func init_block(in_family: StringName, in_cost: int, grid_size: float) -> void:
	material_family = in_family
	material_cost = in_cost
	scale = Vector3.ONE * grid_size
