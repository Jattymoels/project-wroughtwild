class_name GridPlacement
extends Node
## Grid snap-placement with a validity-coloured preview: the core interaction
## the ADR-0001 spike must demonstrate. Owned by the player; traces from the
## camera, snaps to the placement cell and previews valid (green) or invalid
## (red) placement before spending any material.

const PLACED_BLOCK_SCENE := preload("res://scenes/placed_block.tscn")

## Tunable: balance between Minecraft-like constraint and detail
## (construction spec, "Grid size"). Final value is an open question.
@export var grid_size: float = 1.0

## Tunable: building pace and need for scaffolding ("Placement range").
## Measured from the camera, which sits ~4.5 m behind the player, so the
## value must cover camera-to-player distance plus reach in front.
@export var placement_range: float = 10.0

## Tunable: experimentation freedom versus commitment ("Removal refund").
## Mirrors salvage_return_fraction in data/tuning/crafting.json.
@export var removal_refund_fraction: float = 0.5

@export var selected_material_family: StringName = &"wood"
@export var material_cost_per_block: int = 1

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
	_create_preview_mesh()


func _create_preview_mesh() -> void:
	_preview_material = StandardMaterial3D.new()
	_preview_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_preview_material.albedo_color = VALID_COLOR

	_preview_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * grid_size
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

	var affordable: bool = inventory != null \
		and inventory.get_count(selected_material_family) >= material_cost_per_block
	preview_valid = affordable and _is_cell_free(preview_location)

	_preview_mesh.global_position = preview_location
	_preview_mesh.rotation.y = preview_rotation
	_preview_mesh.visible = true
	preview_visible = true
	_preview_material.albedo_color = VALID_COLOR if preview_valid else INVALID_COLOR


## Places a block at the current preview cell when the preview is valid.
func try_place_block() -> bool:
	if not build_mode_enabled or not preview_visible or not preview_valid:
		return false
	if inventory == null or not inventory.consume_material(selected_material_family, material_cost_per_block):
		return false

	var block: PlacedBlock = PLACED_BLOCK_SCENE.instantiate()
	get_tree().current_scene.add_child(block)
	block.global_position = preview_location
	block.rotation.y = preview_rotation
	block.init_block(selected_material_family, material_cost_per_block, grid_size)
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

	if inventory != null:
		var refund := int(floorf(block.material_cost * removal_refund_fraction))
		inventory.add_material(block.material_family, refund)
	block.queue_free()
	return true


func rotate_preview() -> void:
	preview_rotation = fmod(preview_rotation + PI / 2.0, TAU)
