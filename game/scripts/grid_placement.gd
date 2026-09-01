class_name GridPlacement
extends Node
## Grid snap-placement with a validity-coloured preview: the core interaction
## the ADR-0001 spike must demonstrate. Owned by the player; traces from the
## camera, snaps to the placement cell and previews valid (green) or invalid
## (red) placement before spending any material.

const PLACED_BLOCK_SCENE := preload("res://scenes/placed_block.tscn")
const STATION_SITE_SCENE := preload("res://scenes/station_site.tscn")
const KIT_PREVIEW_SIZE := Vector3(1.8, 1.2, 1.8)

## Grid size and placement range are tunables read from
## data/tuning/construction.json at ready; shape costs and removal refunds are
## applied by the rules library, never computed here.
var grid_size: float = 1.0
var placement_range: float = 10.0
## Metres, from the selected shape's size_m; shapes shorter than the cell
## sit on the cell floor.
var shape_size := Vector3.ONE
## Where the selected shape sits in its cell (construction.json anchor):
## centre, or flush to the face/corner the preview rotation selects.
var shape_anchor: StringName = &"centre"

@export var selected_shape: StringName = &"cube"
@export var selected_material_family: StringName = &"wood"
## When non-empty, build mode is placing this crafted station kit instead of
## a shape: placing consumes the kit item and founds its station.
var selected_kit: StringName = &""

@export var camera: Camera3D
@export var inventory: WroughtwildInventory

var build_mode_enabled := false
var preview_valid := false
var preview_visible := false
var preview_location := Vector3.ZERO
var preview_rotation := 0.0

var _preview_mesh: MeshInstance3D
var _preview_material: StandardMaterial3D
## The generated terrain, when the scene has one: ground placement snaps to
## its block heights instead of the ramped heightmap collision.
var _terrain: Terrain

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
	selected_kit = &""
	selected_shape = shape_id
	shape_size = info["size"]
	shape_anchor = StringName(info.get("anchor", "centre"))
	if _preview_mesh != null:
		(_preview_mesh.mesh as BoxMesh).size = shape_size
	return true


## Everything Tab can select: unlocked shapes, then crafted kits in the pack.
func placeables() -> Array:
	var entries: Array = []
	for id in unlocked_shapes():
		entries.append({"kind": "shape", "id": StringName(id)})
	for id in _sim().kit_item_ids():
		if _sim().material_count(id) > 0:
			entries.append({"kind": "kit", "id": StringName(id)})
	return entries


## Next placeable (shape or held kit) in order; returns the new selection id.
func cycle_shape() -> StringName:
	var entries := placeables()
	if entries.is_empty():
		return selected_shape
	var current: StringName = selected_kit if selected_kit != &"" else selected_shape
	var index := 0
	for i in entries.size():
		if entries[i]["id"] == current:
			index = (i + 1) % entries.size()
	var next: Dictionary = entries[index]
	if next["kind"] == "kit":
		_select_kit(next["id"])
	else:
		select_shape(next["id"])
	return next["id"]


func _select_kit(kit_id: StringName) -> void:
	selected_kit = kit_id
	shape_size = KIT_PREVIEW_SIZE
	shape_anchor = &"centre"
	if _preview_mesh != null:
		(_preview_mesh.mesh as BoxMesh).size = shape_size


## What the HUD should call the current selection.
func selection_label() -> String:
	if selected_kit != &"":
		return Hud.pretty(selected_kit)
	return _sim().shape(selected_shape).get("display_name", String(selected_shape))


func _shape_offset() -> Vector3:
	return WroughtwildGrid.shape_offset(shape_size, shape_anchor, preview_rotation, grid_size)


func _find_terrain() -> Terrain:
	if _terrain == null or not is_instance_valid(_terrain):
		_terrain = null
		for child in (get_parent() as WroughtwildPlayer).world_root().get_children():
			if child is Terrain:
				_terrain = child
				break
	return _terrain


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


## Whether the selected shape may go in this cell. Placed blocks share a
## cell by slot (a wall on two faces plus a corner pillar is fine; a cube
## takes the whole cell); generated terrain is judged by its block heights,
## because its collision ramps between cells; anything else in the cell
## (nodes, stations, mobs, pickups) blocks it.
func cell_accepts(cell_center: Vector3) -> bool:
	var terrain := _find_terrain()
	if terrain != null and not terrain.cell_clear_of_ground(cell_center, grid_size):
		return false
	# Slightly smaller than the cell so face-adjacent neighbours don't collide.
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * (grid_size - 0.04)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, cell_center)
	query.exclude = [get_parent()]
	var space := (get_parent() as Node3D).get_world_3d().direct_space_state
	var new_slot := WroughtwildGrid.slot_id(shape_anchor, preview_rotation)
	var new_fills := WroughtwildGrid.fills_cell(shape_size, grid_size)
	for result in space.intersect_shape(query, 32):
		var collider: Object = result["collider"]
		if terrain != null and collider is Node and (collider as Node).get_parent() == terrain:
			continue
		if collider is PlacedBlock:
			var block := collider as PlacedBlock
			if WroughtwildGrid.slots_conflict(block.slot, block.fills_cell, new_slot, new_fills):
				return false
			continue
		return false
	return true


func _update_preview() -> void:
	if _preview_mesh == null:
		return

	var hit := _get_view_trace()
	if hit.is_empty():
		_preview_mesh.visible = false
		preview_visible = false
		preview_valid = false
		return

	var terrain := _find_terrain()
	var collider := hit.get("collider") as Node
	if terrain != null and collider != null and collider.get_parent() == terrain:
		preview_location = terrain.build_cell_center(hit["position"], grid_size)
	else:
		preview_location = WroughtwildGrid.placement_cell_center(
			hit["position"], hit["normal"], grid_size)

	var affordable: bool
	if selected_kit != &"":
		affordable = _sim().material_count(selected_kit) > 0
	else:
		affordable = _sim().can_afford_placement(selected_shape, selected_material_family)
	preview_valid = affordable and cell_accepts(preview_location)

	_preview_mesh.global_position = preview_location + _shape_offset()
	_preview_mesh.rotation.y = preview_rotation
	_preview_mesh.visible = true
	preview_visible = true
	_preview_material.albedo_color = VALID_COLOR if preview_valid else INVALID_COLOR


## Places a block (or founds a station from a kit) at the preview cell.
func try_place_block() -> bool:
	if not build_mode_enabled or not preview_visible or not preview_valid:
		return false
	if selected_kit != &"":
		return _place_kit()
	if not _sim().pay_placement(selected_shape, selected_material_family):
		return false

	var block: PlacedBlock = PLACED_BLOCK_SCENE.instantiate()
	(get_parent() as WroughtwildPlayer).world_root().add_child(block)
	block.global_position = preview_location + _shape_offset()
	block.rotation.y = preview_rotation
	block.init_block(selected_shape, selected_material_family, shape_size, shape_anchor, grid_size)
	return true


## Consumes the kit item, founds its station in the rules, and raises the
## station site in the world where the player can work at it.
func _place_kit() -> bool:
	var station_id := StringName(_sim().kit_station(selected_kit))
	if station_id == &"" or not _sim().consume_material(selected_kit, 1):
		return false
	_sim().add_station(station_id)

	var site: StationSite = STATION_SITE_SCENE.instantiate()
	site.station_id = station_id
	site.upgrade_station_id = &""
	# When another station upgrades this one in place, the site offers it.
	for other_id in _sim().station_ids():
		if _sim().station(other_id).get("upgrade_from", "") == String(station_id):
			site.upgrade_station_id = StringName(other_id)
	(get_parent() as WroughtwildPlayer).world_root().add_child(site)
	site.global_position = preview_location + Vector3(0.0, -grid_size * 0.5, 0.0)
	site.rotation.y = preview_rotation
	site.refresh_visual(_sim())

	# The pack may hold more kits; fall back to shapes when this was the last.
	if _sim().material_count(selected_kit) <= 0:
		select_shape(selected_shape if selected_shape != &"" else &"cube")
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
