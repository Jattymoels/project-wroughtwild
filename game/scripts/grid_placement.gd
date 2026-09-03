class_name GridPlacement
extends Node
## Lattice placement with a validity-coloured preview (Wave 4, building
## intensive slice 1). Every piece occupies one ELEMENT of the cubic grid -
## a cell, a face two cells share, or an edge four share - and the one
## placement rule is: the preview goes to the nearest free element of the
## piece's kind to the point you are looking at. Walls, floors, posts and
## beams take their orientation from the element; only oriented blocks (the
## step) still turn with R.
##
## The sim owns the geometry (which elements sit around a hit, their poses)
## and the occupancy registry; this node owns the camera trace, what the
## engine's world knows (terrain, props, mobs) and the preview.

const PLACED_BLOCK_SCENE := preload("res://scenes/placed_block.tscn")
const STATION_SITE_SCENE := preload("res://scenes/station_site.tscn")
const KIT_PREVIEW_SIZE := Vector3(1.8, 1.2, 1.8)
## Corner trims: the post visual walls grow where they end or meet.
const TRIM_SIZE := 0.3
const TRIM_COLOUR := Color(0.66, 0.66, 0.69)

## Grid size and placement range are tunables read from
## data/tuning/construction.json at ready; shape costs and removal refunds are
## applied by the rules library, never computed here.
var grid_size: float = 1.0
var placement_range: float = 10.0
## Metres, from the selected shape's size_m.
var shape_size := Vector3.ONE
## Which kind of element the selected shape occupies (construction.json
## element): block, wall, floor, post or beam.
var shape_slot: StringName = &"block"

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
## The element the preview targets ({kind, axis, cell}); empty when hidden.
var preview_element: Dictionary = {}
## Quarter turns for oriented blocks (R). Ignored by every other slot.
var preview_rotation_step := 0

var _preview_mesh: MeshInstance3D
var _preview_material: StandardMaterial3D
## The generated terrain, when the scene has one: its block field decides
## which cells are rock and which are open.
var _terrain: Terrain
## Corner trim meshes by edge key.
var _trims: Dictionary = {}
var _trims_root: Node3D
var _trim_material: StandardMaterial3D

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
	shape_slot = StringName(info.get("element", "block"))
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
	shape_slot = &"block"
	if _preview_mesh != null:
		(_preview_mesh.mesh as BoxMesh).size = shape_size


## What the HUD should call the current selection.
func selection_label() -> String:
	if selected_kit != &"":
		return Hud.pretty(selected_kit)
	return _sim().shape(selected_shape).get("display_name", String(selected_shape))


## True when R does anything for the selection: an oriented block (one that
## does not fill its cell). Faces and edges orient themselves.
func rotatable() -> bool:
	return selected_kit == &"" and shape_slot == &"block" and not shape_size.is_equal_approx(Vector3.ONE * grid_size)


func _find_terrain() -> Terrain:
	if _terrain == null or not is_instance_valid(_terrain):
		_terrain = null
		for child in _world_root().get_children():
			if child is Terrain:
				_terrain = child
				break
	return _terrain


func _world_root() -> Node:
	return (get_parent() as WroughtwildPlayer).world_root()


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
		preview_element = {}


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


## Where a piece of `size` stands on an element: the element's centre and
## yaw from the sim, blocks shorter than the cell resting on the cell floor,
## oriented blocks turned by their rotation step.
func piece_pose(element: Dictionary, size: Vector3, rotation_step: int) -> Dictionary:
	var pose: Dictionary = _sim().lattice_pose(element)
	if pose.is_empty():
		return {}
	var centre: Vector3 = pose["centre"]
	var yaw: float = float(pose["yaw_turns"]) * PI / 2.0
	if element["kind"] == "volume":
		centre.y -= (grid_size - size.y) * 0.5
		yaw += float(rotation_step) * PI / 2.0
	return {"centre": centre, "yaw": yaw}


## The terrain's verdict on an element: a block cannot go into rock, and a
## face or edge with rock on every side has nothing to stand against. A face
## between rock and open air is fair game - planking a mine wall.
func _buried(element: Dictionary) -> bool:
	var terrain := _find_terrain()
	if terrain == null or terrain.map.is_empty():
		return false
	var c: Vector3i = element["cell"]
	var cells: Array[Vector3i] = []
	match String(element["kind"]):
		"volume":
			cells = [c]
		"face":
			var back := c
			back[int(element["axis"])] -= 1
			cells = [c, back]
		"edge":
			var a1 := (int(element["axis"]) + 1) % 3
			var a2 := (int(element["axis"]) + 2) % 3
			for s1 in 2:
				for s2 in 2:
					var n := c
					n[a1] -= s1
					n[a2] -= s2
					cells.append(n)
	for cell in cells:
		if terrain.block_at(cell.x, cell.y, cell.z) == 0:
			return false
	return true


## Whether the selected shape may stand on this element: the element must be
## free in the sim's structure, open to the terrain, and the piece's box must
## not overlap anything else in the world (nodes, stations, mobs, pickups).
## Other placed pieces never block - the structure decides those conflicts.
func element_accepts(element: Dictionary) -> bool:
	if element.is_empty() or not _sim().lattice_slot_accepts(shape_slot, element):
		return false
	if _sim().structure_occupied(element):
		return false
	if _buried(element):
		return false
	var pose := piece_pose(element, shape_size, preview_rotation_step)
	if pose.is_empty():
		return false
	var terrain := _find_terrain()
	var shape := BoxShape3D.new()
	# Slightly smaller than the piece so face-adjacent neighbours do not touch.
	shape.size = shape_size * 0.9
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(Vector3.UP, pose["yaw"]), pose["centre"])
	query.exclude = [get_parent()]
	var space := (get_parent() as Node3D).get_world_3d().direct_space_state
	for result in space.intersect_shape(query, 32):
		var collider: Object = result["collider"]
		if collider is PlacedBlock:
			continue
		if terrain != null and terrain.is_terrain_body(collider):
			continue
		return false
	return true


## The element the selected shape would take for a surface hit: the nearest
## acceptable candidate, or the nearest of all when none is (for the red
## preview). Empty when the sim has nothing to offer.
func target_element(point: Vector3, normal: Vector3) -> Dictionary:
	var candidates: Array = _sim().lattice_candidates(shape_slot, point, normal)
	for candidate in candidates:
		if element_accepts(candidate):
			return candidate
	return candidates[0] if not candidates.is_empty() else {}


func _update_preview() -> void:
	if _preview_mesh == null:
		return

	var hit := _get_view_trace()
	if hit.is_empty():
		_hide_preview()
		return

	var element := target_element(hit["position"], hit["normal"])
	if element.is_empty():
		_hide_preview()
		return
	preview_element = element
	var pose := piece_pose(element, shape_size, preview_rotation_step)

	var affordable: bool
	if selected_kit != &"":
		affordable = _sim().material_count(selected_kit) > 0
	else:
		affordable = _sim().can_afford_placement(selected_shape, selected_material_family)
	preview_valid = affordable and element_accepts(element)

	_preview_mesh.global_position = pose["centre"]
	_preview_mesh.rotation.y = pose["yaw"]
	_preview_mesh.visible = true
	preview_visible = true
	_preview_material.albedo_color = VALID_COLOR if preview_valid else INVALID_COLOR


func _hide_preview() -> void:
	_preview_mesh.visible = false
	preview_visible = false
	preview_valid = false
	preview_element = {}


## Places the selected piece (or founds a station from a kit) on the
## previewed element, paying for it through the sim.
func try_place_block() -> bool:
	if not build_mode_enabled or not preview_visible or not preview_valid:
		return false
	if selected_kit != &"":
		return _place_kit()
	if not _sim().pay_placement(selected_shape, selected_material_family):
		return false
	return place_piece(preview_element, selected_shape, selected_material_family, preview_rotation_step) != null


## Registers a piece on an element and raises it in the world (no payment:
## try_place_block pays, loading a save does not). Null when the element is
## taken or the shape may not stand there.
func place_piece(element: Dictionary, shape_id: StringName, family: StringName,
		rotation_step: int = 0) -> PlacedBlock:
	var info: Dictionary = _sim().shape(shape_id)
	if info.is_empty():
		return null
	if not _sim().structure_place(element, shape_id, family, rotation_step):
		return null
	var size: Vector3 = info["size"]
	var pose := piece_pose(element, size, rotation_step)
	var block: PlacedBlock = PLACED_BLOCK_SCENE.instantiate()
	_world_root().add_child(block)
	block.init_piece(shape_id, family, element, rotation_step, size, pose["centre"], pose["yaw"])
	refresh_trims()
	return block


## Takes a piece out of the structure and the world. False when the sim did
## not know it (already gone).
func remove_piece(block: PlacedBlock) -> bool:
	if block == null or not _sim().structure_remove(block.element):
		return false
	block.get_parent().remove_child(block)
	block.queue_free()
	refresh_trims()
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
	_world_root().add_child(site)
	var pose := piece_pose(preview_element, Vector3.ONE * grid_size, 0)
	site.global_position = pose["centre"] + Vector3(0.0, -grid_size * 0.5, 0.0)
	site.rotation.y = float(preview_rotation_step) * PI / 2.0
	site.refresh_visual(_sim())

	# The pack may hold more kits; fall back to shapes when this was the last.
	if _sim().material_count(selected_kit) <= 0:
		select_shape(selected_shape if selected_shape != &"" else &"cube")
	return true


## Removes an aimed-at placed piece, refunding part of its material.
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
	return remove_piece(block)


func rotate_preview() -> void:
	preview_rotation_step = (preview_rotation_step + 1) % 4


## Corner trims: the sim says which vertical edges want a post visual (walls
## ending or meeting at an angle with no real post); this keeps one slim
## mesh per such edge and drops the rest. Purely presentation - trims are
## never saved, never collide, never cost.
func refresh_trims() -> void:
	if _trims_root == null or not is_instance_valid(_trims_root):
		_trims_root = Node3D.new()
		_trims_root.name = "WallTrims"
		_world_root().add_child(_trims_root)
		_trim_material = StandardMaterial3D.new()
		_trim_material.albedo_color = TRIM_COLOUR
	var wanted := {}
	for edge in _sim().structure_trim_edges():
		var cell: Vector3i = edge["cell"]
		var key := "%d_%d_%d" % [cell.x, cell.y, cell.z]
		wanted[key] = true
		if _trims.has(key):
			continue
		var trim := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(TRIM_SIZE, grid_size, TRIM_SIZE)
		trim.mesh = box
		trim.material_override = _trim_material
		_trims_root.add_child(trim)
		trim.global_position = edge["centre"]
		_trims[key] = trim
	for key in _trims.keys():
		if not wanted.has(key):
			_trims[key].queue_free()
			_trims.erase(key)


func trim_count() -> int:
	return _trims.size()
