class_name GridPlacement
extends Node
## Grid snap-placement with a validity-coloured preview: the core interaction
## the ADR-0001 spike must demonstrate. Owned by the player; traces from the
## camera, snaps to the placement cell and previews valid (green) or invalid
## (red) placement before spending any material.

const PLACED_BLOCK_SCENE := preload("res://scenes/placed_block.tscn")

## Grid size and placement range are tunables read from
## data/tuning/construction.json at ready; shape costs and removal refunds are
## applied by the rules library, never computed here.
var grid_size: float = 1.0
var placement_range: float = 10.0
## Metres, from the selected shape's size_m; shapes shorter than the cell
## sit on the cell floor.
var shape_size := Vector3.ONE

@export var selected_shape: StringName = &"cube"
@export var selected_material_family: StringName = &"wood"

@export var camera: Camera3D
@export var inventory: WroughtwildInventory

var build_mode_enabled := false
var preview_valid := false
var preview_visible := false
var preview_location := Vector3.ZERO
var preview_rotation := 0.0

var _preview_mesh: MeshInstance3D
var _preview_material: StandardMaterial3D

const VALID_COLOR := Color(0.1, 0.9, 0.2, 0.5)
const INVALID_COLOR := Color(0.9, 0.1, 0.1, 0.5)


func _ready() -> void:
	grid_size = _sim().grid_size()
	placement_range = _sim().placement_range()
	select_shape(selected_shape)
	_create_preview_mesh()


func unlocked_shapes() -> PackedStringArray:
	var ids := PackedStringArray()
	for id in _sim().shape_ids():
		if _sim().shape_unlocked(id):
			ids.append(id)
	return ids


func select_shape(shape_id: StringName) -> bool:
	var info: Dictionary = _sim().shape(shape_id)
	if info.is_empty() or not info["unlocked"]:
		return false
	selected_shape = shape_id
	shape_size = info["size"]
	if _preview_mesh != null:
		(_preview_mesh.mesh as BoxMesh).size = shape_size
	return true


## Next unlocked shape in construction.json order.
func cycle_shape() -> StringName:
	var ids := unlocked_shapes()
	if ids.is_empty():
		return selected_shape
	var index := ids.find(String(selected_shape))
	select_shape(StringName(ids[(index + 1) % ids.size()]))
	return selected_shape


func _shape_offset() -> Vector3:
	return Vector3(0.0, (shape_size.y - grid_size) * 0.5, 0.0)


## The same rules instance the inventory draws on, so affordability, payment
## and refunds all touch one economy.
func _sim() -> WroughtwildSim:
	if inventory != null:
		return inventory.get_sim()
	return load("res://scripts/sim.gd").shared()


func _create_preview_mesh() -> void:
	_preview_material = StandardMaterial3D.new()
	_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.albedo_color = VALID_COLOR

	_preview_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = shape_size
	_preview_mesh.mesh = box
	_preview_mesh.material_override = _preview_material
	_preview_mesh.visible = false
	# Added top-level so the preview moves in world space, not with the player.
	add_child(_preview_mesh)
	_preview_mesh.top_level = true


func set_build_mode_enabled(enabled: bool) -> void:
	build_mode_enabled = enabled
	if not build_mode_enabled and _preview_mesh:
		_preview_mesh.visible = false
		preview_visible = false


func _physics_process(_delta: float) -> void:
	if build_mode_enabled:
		_update_preview()


func _get_view_trace() -> Dictionary:
	if camera == null:
		return {}
	var from := camera.global_position
	var to := from + (-camera.global_transform.basis.z) * placement_range
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [get_parent()]
	return camera.get_world_3d().direct_space_state.intersect_ray(query)


func _is_cell_free(cell_center: Vector3) -> bool:
	# Slightly smaller than the cell so face-adjacent neighbours don't collide.
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * (grid_size - 0.04)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, cell_center)
	query.exclude = [get_parent()]
	var space := (get_parent() as Node3D).get_world_3d().direct_space_state
	return space.intersect_shape(query, 1).is_empty()


func _update_preview() -> void:
	if _preview_mesh == null:
		return

	var hit := _get_view_trace()
	if hit.is_empty():
		_preview_mesh.visible = false
		preview_visible = false
		preview_valid = false
		return

	preview_location = WroughtwildGrid.placement_cell_center(
		hit["position"], hit["normal"], grid_size)

	var affordable: bool = _sim().can_afford_placement(selected_shape, selected_material_family)
	preview_valid = affordable and _is_cell_free(preview_location)

	_preview_mesh.global_position = preview_location + _shape_offset()
	_preview_mesh.rotation.y = preview_rotation
	_preview_mesh.visible = true
	preview_visible = true
	_preview_material.albedo_color = VALID_COLOR if preview_valid else INVALID_COLOR


## Places a block at the current preview cell when the preview is valid.
func try_place_block() -> bool:
	if not build_mode_enabled or not preview_visible or not preview_valid:
		return false
	if not _sim().pay_placement(selected_shape, selected_material_family):
		return false

	var block: PlacedBlock = PLACED_BLOCK_SCENE.instantiate()
	(get_parent() as WroughtwildPlayer).world_root().add_child(block)
	block.global_position = preview_location + _shape_offset()
	block.rotation.y = preview_rotation
	block.init_block(selected_shape, selected_material_family, shape_size)
	return true


## Removes an aimed-at placed block, refunding part of its material.
func try_remove_block() -> bool:
	if not build_mode_enabled:
		return false

	var hit := _get_view_trace()
	if hit.is_empty():
		return false

	var block := hit.get("collider") as PlacedBlock
	if block == null:
		return false

	_sim().refund_removal(block.shape_id, block.material_family)
	block.queue_free()
	return true


func rotate_preview() -> void:
	preview_rotation = fmod(preview_rotation + PI / 2.0, TAU)
