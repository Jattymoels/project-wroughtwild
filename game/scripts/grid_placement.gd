class_name GridPlacement
extends Node
## Lattice placement with a validity-coloured preview (Wave 4 building
## intensive, D-017). Every piece is anchored on one ELEMENT of the cubic
## grid - a cell, a face two cells share, or an edge four share - and the
## one placement rule is: the preview goes to the nearest free element of
## the piece's kind to the point you are looking at. Walls, floors, posts
## and beams take their orientation from the element; only oriented shapes
## (stairs, the roof wedge, a door's hinge side) turn with R.
##
## The sim owns the geometry (which elements sit around a hit, their poses,
## footprints on the finer registry) and the occupancy registry; this node
## owns the camera trace, what the engine's world knows (terrain, props,
## mobs) and the preview.

const PLACED_BLOCK_SCENE := preload("res://scenes/placed_block.tscn")
const STATION_SITE_SCENE := preload("res://scenes/station_site.tscn")
const KIT_PREVIEW_SIZE := Vector3(1.8, 1.2, 1.8)
## Kits stand in a whole cell: they target the lattice as this shape does.
const KIT_STAND_IN_SHAPE := &"cube"
## Metres between samples when the view ray reaches out into empty air.
const EXTEND_STEP := 0.25
## Corner trims: the post visual walls grow where they end or meet.
const TRIM_SIZE := 0.3
const TRIM_COLOUR := Color(0.66, 0.66, 0.69)

## Grid size and placement range are tunables read from
## data/tuning/construction.json at ready; shape costs and removal refunds are
## applied by the rules library, never computed here.
var grid_size: float = 1.0
var placement_range: float = 10.0
## The occupancy registry's cell (grid_size / lattice_divisions).
var registry_grid: float = 0.5
## Metres, from the selected shape's size_m.
var shape_size := Vector3.ONE
## Which kind of element the selected shape occupies (construction.json
## element): block, wall, floor, post or beam.
var shape_slot: StringName = &"block"
## construction.json form: box | stairs | wedge | door.
var shape_form := "box"
## True when R turns the selection.
var shape_oriented := false
## Fine mode (G): the selection is swapped for its half-scale twin - the
## same placement rule at half the cell. Shapes without a twin (stairs,
## door, wedge) stay full size.
var fine_mode := false
## full-size shape id -> its fine twin's id, from construction.json fine_of.
var _fine_twins: Dictionary = {}

@export var selected_shape: StringName = &"cube"
## The building family (construction.json materials) placements are paid
## in and look like; Q cycles the families whose source you carry.
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
## Quarter turns for oriented shapes (R). Ignored by every other shape.
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
	registry_grid = _sim().lattice_registry_grid()
	for id in _sim().shape_ids():
		var twin_of: String = _sim().shape(id).get("fine_of", "")
		if twin_of != "":
			_fine_twins[StringName(twin_of)] = StringName(id)
	_create_preview_mesh()
	select_shape(selected_shape)


func unlocked_shapes() -> PackedStringArray:
	var ids := PackedStringArray()
	for id in _sim().shape_ids():
		if _sim().shape_unlocked(id):
			ids.append(id)
	return ids


## Locked shapes may be selected (so the palette shows what exists and the
## chip says how to earn it); they never preview valid.
func select_shape(shape_id: StringName) -> bool:
	var info: Dictionary = _sim().shape(shape_id)
	if info.is_empty() or info.get("fine", false):
		return false
	selected_kit = &""
	selected_shape = shape_id
	_refresh_selection()
	return true


## Reads size, element kind, form and orientation from whichever shape the
## lattice will actually be asked about (the selection or its fine twin).
func _refresh_selection() -> void:
	if selected_kit != &"":
		shape_size = KIT_PREVIEW_SIZE
		shape_slot = &"block"
		shape_form = "box"
		shape_oriented = true
	else:
		var info: Dictionary = _sim().shape(_target_shape())
		shape_size = info["size"]
		shape_slot = StringName(info.get("element", "block"))
		shape_form = String(info.get("form", "box"))
		shape_oriented = bool(info.get("oriented", false))
	if _preview_mesh != null:
		_preview_mesh.mesh = PieceMesh.preview_mesh_for(shape_form, shape_size)


## Fine mode on or off; returns the new state.
func toggle_fine() -> bool:
	fine_mode = not fine_mode
	_refresh_selection()
	return fine_mode


## True when the current selection has a half-scale twin fine mode would use.
func has_fine_twin() -> bool:
	return selected_kit == &"" and _fine_twins.has(selected_shape)


## Everything Tab can select: unlocked full-size shapes (fine twins ride
## along on G), then crafted kits in the pack.
func placeables() -> Array:
	var entries: Array = []
	for id in _sim().shape_ids():
		if _sim().shape(id).get("fine", false):
			continue
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
	_refresh_selection()


## The shape the lattice is asked about (and paid for): the selection, its
## fine twin in fine mode, or the kit's whole-cell stand-in.
func _target_shape() -> StringName:
	if selected_kit != &"":
		return KIT_STAND_IN_SHAPE
	if fine_mode and _fine_twins.has(selected_shape):
		return _fine_twins[selected_shape]
	return selected_shape


## The shape a placement pays for and records.
func placing_shape() -> StringName:
	return _target_shape()


## What the HUD should call the current selection.
func selection_label() -> String:
	if selected_kit != &"":
		return Hud.pretty(selected_kit)
	var shape := _target_shape()
	var name: String = _sim().shape(shape).get("display_name", String(shape))
	return name + "  (fine)" if fine_mode and shape != selected_shape else name


## True when R does anything for the selection.
func rotatable() -> bool:
	return shape_oriented


## Families the player could build in right now: every family whose
## source item is in the pack, or the current one when none is.
func carried_materials() -> PackedStringArray:
	var ids := PackedStringArray()
	for id in _sim().build_material_ids():
		if _sim().build_material(id).get("carried", 0) > 0:
			ids.append(id)
	if ids.is_empty():
		ids.append(String(selected_material_family))
	return ids


## Next carried family (Q); returns the new selection.
func cycle_material() -> StringName:
	var ids := carried_materials()
	var index := 0
	for i in ids.size():
		if ids[i] == String(selected_material_family):
			index = (i + 1) % ids.size()
	selected_material_family = StringName(ids[index])
	return selected_material_family


func material_label() -> String:
	return _sim().build_material(selected_material_family).get("display_name", String(selected_material_family))


## True when the selected family can be worked into the selected shape.
func family_allowed() -> bool:
	return selected_kit != &"" or _sim().shape_allows_family(_target_shape(), selected_material_family)


## True when the selected shape is still gated (a world effect not yet won).
func locked() -> bool:
	return selected_kit == &"" and not _sim().shape_unlocked(_target_shape())


## What the HUD says while the selection is locked; "" when it is not.
func lock_reason() -> String:
	if not locked():
		return ""
	var hint: String = _sim().shape(_target_shape()).get("unlock_hint", "")
	return hint if hint != "" else "locked"


## Why the family is refused, for the HUD ("needs joinery"); "" when fine.
func family_refusal() -> String:
	if family_allowed():
		return ""
	var traits: PackedStringArray = _sim().shape(_target_shape()).get("requires_traits", PackedStringArray())
	return "needs " + ", ".join(traits)


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
	_preview_mesh.mesh = PieceMesh.preview_mesh_for(shape_form, shape_size)
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


## Where a shape stands when anchored on an element: the footprint's centre
## and yaw from the sim; blocks shorter than the cell rest on the cell
## floor; oriented blocks turn by the rotation step, oriented faces (a
## door) flip their hinge to the other side on odd steps.
func piece_pose(shape_id: StringName, element: Dictionary, rotation_step: int) -> Dictionary:
	var info: Dictionary = _sim().shape(shape_id)
	var pose: Dictionary = _sim().lattice_pose(shape_id, element)
	if info.is_empty() or pose.is_empty():
		return {}
	var size: Vector3 = info["size"]
	var centre: Vector3 = pose["centre"]
	var yaw: float = float(pose["yaw_turns"]) * PI / 2.0
	var oriented: bool = info.get("oriented", false)
	if element["kind"] == "volume":
		var cell_height: float = grid_size if not info.get("fine", false) else registry_grid
		centre.y -= (cell_height - size.y) * 0.5
		if oriented:
			yaw += float(rotation_step) * PI / 2.0
	elif oriented:
		yaw += float(rotation_step % 2) * PI
	return {"centre": centre, "yaw": yaw}


## The build-grid cell a registry cell lies in.
func _build_cell(registry_cell: Vector3i) -> Vector3i:
	var div := maxi(1, roundi(grid_size / registry_grid))
	return Vector3i(floori(float(registry_cell.x) / div), floori(float(registry_cell.y) / div),
		floori(float(registry_cell.z) / div))


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
		var b := _build_cell(cell)
		if terrain.block_at(b.x, b.y, b.z) == 0:
			return false
	return true


## Whether the selected shape may anchor on this element: the right kind of
## element for it, its whole footprint free in the sim's structure, open to
## the terrain, and the piece's box clear of everything else in the world
## (nodes, stations, mobs, pickups). Other placed pieces never block - the
## structure decides those conflicts.
func element_accepts(element: Dictionary) -> bool:
	var shape := _target_shape()
	if element.is_empty() or not _sim().shape_accepts(shape, element):
		return false
	if not _sim().structure_free_for(shape, element):
		return false
	if _buried(element):
		return false
	var pose := piece_pose(shape, element, preview_rotation_step)
	if pose.is_empty():
		return false
	var terrain := _find_terrain()
	var shape_box := BoxShape3D.new()
	# Slightly smaller than the piece so face-adjacent neighbours do not touch.
	shape_box.size = shape_size * 0.9
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape_box
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
func target_element(point: Vector3, normal: Vector3, fine_grid: bool = false) -> Dictionary:
	var candidates: Array = _sim().lattice_candidates(_target_shape(), point, normal, fine_grid)
	for candidate in candidates:
		if element_accepts(candidate):
			return candidate
	return candidates[0] if not candidates.is_empty() else {}


## The piece you build on decides the grid: a hit on a fine piece, or on a
## piece standing off the build grid, targets the registry lattice so a
## full-size piece can sit on a half-scale one.
func _hit_on_fine_grid(hit: Dictionary) -> bool:
	var block := hit.get("collider") as PlacedBlock
	if block == null or block.element.is_empty():
		return false
	if _sim().shape(block.shape_id).get("fine", false):
		return true
	var cell: Vector3i = block.element["cell"]
	var div := maxi(1, roundi(grid_size / registry_grid))
	return cell.x % div != 0 or cell.y % div != 0 or cell.z % div != 0


## Reaching out into empty air: walk the view ray from the player outward
## in EXTEND_STEP hops. Once the ray has passed within a registry cell of
## something built, the first acceptable element that touches the
## structure wins - so aiming along a beam's line continues the beam, and
## aiming past a wall's edge extends the wall over nothing. Empty when the
## ray never brushes the structure before `reach`. `start` is how far
## along the ray sampling begins (the camera sits behind the player).
func extend_target(from: Vector3, dir: Vector3, reach: float, start: float = 0.0) -> Dictionary:
	if _sim().structure_piece_count() == 0:
		return {}
	var shape := _target_shape()
	var d := start + EXTEND_STEP
	var passed := false
	while d < reach - EXTEND_STEP * 0.5:
		var p := from + dir * d
		if not passed:
			passed = _sim().structure_near_point(p)
		else:
			for candidate in _sim().lattice_candidates(shape, p, Vector3.ZERO, false):
				if _sim().structure_touches(shape, candidate) and element_accepts(candidate):
					return candidate
		d += EXTEND_STEP
	return {}


func _update_preview() -> void:
	if _preview_mesh == null:
		return

	var hit := _get_view_trace()
	var from := camera.global_position
	var dir := -camera.global_transform.basis.z
	var reach := placement_range if hit.is_empty() else from.distance_to(hit["position"])
	var element := extend_target(from, dir, reach, from.distance_to((get_parent() as Node3D).global_position))
	if element.is_empty() and not hit.is_empty():
		element = target_element(hit["position"], hit["normal"], _hit_on_fine_grid(hit))
	if element.is_empty():
		_hide_preview()
		return
	preview_element = element
	var pose := piece_pose(_target_shape(), element, preview_rotation_step)
	if selected_kit != &"":
		# The kit preview is a stand-in box on the cell floor, not a shape.
		pose["centre"].y += (KIT_PREVIEW_SIZE.y - grid_size) * 0.5

	var affordable: bool
	if selected_kit != &"":
		affordable = _sim().material_count(selected_kit) > 0
	else:
		affordable = _sim().can_afford_placement(_target_shape(), selected_material_family)
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
	var shape := _target_shape()
	if not _sim().pay_placement(shape, selected_material_family):
		return false
	return place_piece(preview_element, shape, selected_material_family, preview_rotation_step) != null


## Registers a piece on an element and raises it in the world (no payment:
## try_place_block pays, loading a save does not). Null when the footprint
## is taken or the shape may not anchor there.
func place_piece(element: Dictionary, shape_id: StringName, family: StringName,
		rotation_step: int = 0) -> PlacedBlock:
	var info: Dictionary = _sim().shape(shape_id)
	if info.is_empty():
		return null
	if not _sim().structure_place(element, shape_id, family, rotation_step):
		return null
	var pose := piece_pose(shape_id, element, rotation_step)
	var block: PlacedBlock = PLACED_BLOCK_SCENE.instantiate()
	_world_root().add_child(block)
	block.init_piece(shape_id, family, element, rotation_step, String(info.get("form", "box")),
		info["size"], pose["centre"], pose["yaw"], PieceLook.material_for(_sim(), family))
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
	var pose := piece_pose(KIT_STAND_IN_SHAPE, preview_element, 0)
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

	# A fire's fuel is spent the moment it is lit: no refund.
	if not block.is_fire():
		_sim().refund_removal(block.shape_id, block.material_family)
	return remove_piece(block)


func rotate_preview() -> void:
	preview_rotation_step = (preview_rotation_step + 1) % 4


## Corner trims: the sim says which vertical registry edges want a post
## visual (walls ending or meeting at an angle with no real post); this
## keeps one slim mesh per such edge and drops the rest. Purely
## presentation - trims are never saved, never collide, never cost.
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
		box.size = Vector3(TRIM_SIZE, registry_grid, TRIM_SIZE)
		trim.mesh = box
		var family: String = edge.get("family", "")
		trim.material_override = PieceLook.material_for(_sim(), StringName(family)) if family != "" else _trim_material
		_trims_root.add_child(trim)
		trim.global_position = edge["centre"]
		_trims[key] = trim
	for key in _trims.keys():
		if not wanted.has(key):
			_trims[key].queue_free()
			_trims.erase(key)


func trim_count() -> int:
	return _trims.size()


## Shelter: is this world position inside an enclosed room of the player's
## structure (or of the terrain, roofed by it)? The sim flood-fills from
## the position; this only supplies what the engine knows - the terrain's
## seed and its dug blocks. {enclosed, cells}; never enclosed with nothing
## built, so the common case costs nothing.
func enclosure_at(position: Vector3) -> Dictionary:
	if _sim().structure_piece_count() == 0:
		return {"enclosed": false, "cells": 0}
	var terrain := _find_terrain()
	var seed_value := -1
	var removed := PackedInt32Array()
	if terrain != null and not terrain.map.is_empty():
		seed_value = terrain.seed_value()
		removed = terrain.broken_packed()
	return _sim().structure_enclosure(seed_value, removed, position)
