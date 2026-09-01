class_name WroughtwildGrid
## Grid snapping used by the placement preview and the headless tests.
## Kept as static functions so rules stay testable without a scene
## (AGENTS.md: separate simulation rules from presentation).

## How far a hit point is pushed along its surface normal before snapping:
## enough to leave the surface's own cell, small enough that the top of a
## slab or the face of a panel (both inside their cell) still targets the
## cell the surface belongs to rather than skipping one.
const SURFACE_EPSILON := 0.02
## Tolerance when deciding whether a shape fills its whole cell.
const FILL_EPSILON := 0.001


## Snaps a world position to the centre of its grid cell.
static func snap_to_cell_center(location: Vector3, grid_size: float) -> Vector3:
	var cell := Vector3(
		floorf(location.x / grid_size),
		floorf(location.y / grid_size),
		floorf(location.z / grid_size))
	return cell * grid_size + Vector3.ONE * (grid_size * 0.5)


## Cell the placement targets: the hit surface pushed slightly along its
## normal so building against a face lands in the adjacent cell.
static func placement_cell_center(impact_point: Vector3, impact_normal: Vector3, grid_size: float) -> Vector3:
	return snap_to_cell_center(impact_point + impact_normal * SURFACE_EPSILON, grid_size)


## Quarter-turn step (0..3) of a yaw produced by rotate_preview.
static func rotation_step(rotation_y: float) -> int:
	return posmod(roundi(rotation_y / (PI / 2.0)), 4)


## Where a shape sits inside its cell, as a world-space offset from the cell
## centre. Shapes shorter than the cell rest on the cell floor. "face" shapes
## press flush against the side the rotation step points at, "corner" shapes
## tuck into that step's corner, "centre" shapes stay centred - so panels,
## beams and pillars in neighbouring cells meet instead of floating mid-cell.
static func shape_offset(size: Vector3, anchor: StringName, rotation_y: float, grid_size: float) -> Vector3:
	var local := Vector3(0.0, (size.y - grid_size) * 0.5, 0.0)
	match anchor:
		&"face":
			local.z = -(grid_size - size.z) * 0.5
		&"corner":
			local.x = -(grid_size - size.x) * 0.5
			local.z = -(grid_size - size.z) * 0.5
	return Basis(Vector3.UP, rotation_y) * local


## The slot a shape claims in its cell: the centre, or the face/corner its
## rotation step selects.
static func slot_id(anchor: StringName, rotation_y: float) -> StringName:
	match anchor:
		&"face":
			return StringName("face_%d" % rotation_step(rotation_y))
		&"corner":
			return StringName("corner_%d" % rotation_step(rotation_y))
	return &"centre"


## True for shapes that take the whole cell (the cube), which exclude
## everything else from it.
static func fills_cell(size: Vector3, grid_size: float) -> bool:
	var limit := grid_size - FILL_EPSILON
	return size.x >= limit and size.y >= limit and size.z >= limit


## Two shapes may share a cell unless one fills it or both claim one slot.
static func slots_conflict(slot_a: StringName, fills_a: bool, slot_b: StringName, fills_b: bool) -> bool:
	return fills_a or fills_b or slot_a == slot_b


## Cell index of a shape placed at `position` with `offset` already applied
## (the inverse of cell centre + shape_offset).
static func cell_of(position: Vector3, offset: Vector3, grid_size: float) -> Vector3i:
	var centre := position - offset
	return Vector3i(
		floori(centre.x / grid_size),
		floori(centre.y / grid_size),
		floori(centre.z / grid_size))
