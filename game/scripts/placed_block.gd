class_name PlacedBlock
extends StaticBody3D
## A player-placed construction shape occupying one slot of one grid cell.

## Shape id from data/tuning/construction.json; its cost and refund come
## from the rules library, not from the block.
@export var shape_id: StringName = &"cube"
## Family the block was paid with, refunded (partially) on removal.
@export var material_family: StringName = &"wood"
## Where the shape sits in its cell (construction.json anchor).
@export var anchor: StringName = &"centre"

## Grid cell this block belongs to and the slot it claims there; placement
## uses them to decide what else may share the cell.
var cell := Vector3i.ZERO
var slot: StringName = &"centre"
var fills_cell := true


## size and anchor come from the shape's size_m and anchor in
## construction.json (the scene's mesh and collision are unit cubes). Call
## after the block's position and yaw are set: the cell is read back from
## them so loaded saves land in the same slots as fresh placements.
func init_block(in_shape: StringName, in_family: StringName, size: Vector3,
		in_anchor: StringName = &"centre", grid_size: float = 1.0) -> void:
	shape_id = in_shape
	material_family = in_family
	anchor = in_anchor
	scale = size
	var offset := WroughtwildGrid.shape_offset(size, anchor, rotation.y, grid_size)
	cell = WroughtwildGrid.cell_of(global_position, offset, grid_size)
	slot = WroughtwildGrid.slot_id(anchor, rotation.y)
	fills_cell = WroughtwildGrid.fills_cell(size, grid_size)
