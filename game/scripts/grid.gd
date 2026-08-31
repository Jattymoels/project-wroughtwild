class_name WroughtwildGrid
## Grid snapping used by the placement preview and the headless tests.
## Kept as static functions so rules stay testable without a scene
## (AGENTS.md: separate simulation rules from presentation).


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
	return snap_to_cell_center(impact_point + impact_normal * (grid_size * 0.25), grid_size)
