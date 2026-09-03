class_name SaveManager
extends RefCounted
## Writes and restores the whole game in one file: the rules state (economy,
## equipment) as the sim's own SaveGame JSON, kept as opaque text so engine
## saves and text-playtest saves stay interchangeable, plus the engine-side
## world: placed shapes, resource nodes and the player's pose.
##
## The schema is not yet declared stable (AGENTS.md); it may change until the
## vertical slice is accepted. v2 (Wave 4): placed pieces are saved by the
## lattice element they occupy, not by a transform.

const SCHEMA_VERSION := 2
const DEFAULT_PATH := "user://wroughtwild_save.json"
const RESOURCE_NODE_SCENE := preload("res://scenes/resource_node.tscn")

var last_error := ""


static func _vec(v: Vector3) -> Array:
	return [v.x, v.y, v.z]


static func _unvec(a: Array) -> Vector3:
	return Vector3(a[0], a[1], a[2])


## Collects placed blocks, resource nodes and station sites anywhere under root.
static func _walk(node: Node, blocks: Array, nodes: Array, sites: Array) -> void:
	for child in node.get_children():
		if child is PlacedBlock:
			blocks.append(child)
		elif child is ResourceNode:
			nodes.append(child)
		elif child is StationSite:
			sites.append(child)
		_walk(child, blocks, nodes, sites)


func capture(player: WroughtwildPlayer) -> Dictionary:
	var root: Node = player.world_root()
	var blocks: Array = []
	var nodes: Array = []
	var sites: Array = []
	_walk(root, blocks, nodes, sites)

	var block_data: Array = []
	for block in blocks:
		if block.is_fire():
			continue  # a fire is fuel, not a building: it is out when you return
		var cell: Vector3i = block.element["cell"]
		block_data.append({
			"shape": String(block.shape_id),
			"family": String(block.material_family),
			"kind": String(block.element["kind"]),
			"axis": int(block.element["axis"]),
			"cell": [cell.x, cell.y, cell.z],
			"rotation_step": block.rotation_step,
		})

	var node_data: Array = []
	for node in nodes:
		if node.is_queued_for_deletion():
			continue
		node_data.append({
			"name": node.name,
			"parent": String(root.get_path_to(node.get_parent())),
			"family": String(node.material_family),
			"position": _vec(node.global_position),
			"remaining_units": node.remaining_units,
			"units_per_harvest": node.units_per_harvest,
			"heat_to_work": node.heat_to_work,
			"cracked": node.cracked,
			"tool_item": String(node.tool_item),
			"drive_presses": node.drive_presses,
			"wedge_set": node.wedge_set,
			"drive_progress": node.drive_progress,
		})

	var site_data: Array = []
	for site in sites:
		site_data.append({
			"name": String(site.name),
			"parent": String(root.get_path_to(site.get_parent())),
			"station_id": String(site.station_id),
			"upgrade_station_id": String(site.upgrade_station_id),
			"position": _vec(site.global_position),
			"rotation_y": site.rotation.y,
		})

	var data := {
		"schema_version": SCHEMA_VERSION,
		"sim": player.inventory.get_sim().export_json(),
		"player": {
			"position": _vec(player.global_position),
			"yaw": player.rotation.y,
			"pitch": player.spring_arm.rotation.x,
		},
		"blocks": block_data,
		"resource_nodes": node_data,
		"stations": site_data,
	}
	# Generated worlds carry their seed so a load rebuilds the same terrain.
	if "world_seed" in root:
		data["world_seed"] = root.get("world_seed")
	# ...and every block the player dug out of it (Wave 3 digging).
	var terrain := root.get_node_or_null("Terrain") as Terrain
	if terrain != null and not terrain.broken.is_empty():
		var broken_data: Array = []
		for v in terrain.broken:
			broken_data.append([v.x, v.y, v.z])
		data["broken_blocks"] = broken_data
	if terrain != null and not terrain.cracked.is_empty():
		data["cracked_blocks"] = terrain.cracked_packed_list()
	return data


func apply(player: WroughtwildPlayer, data: Dictionary) -> bool:
	if data.get("schema_version", -1) != SCHEMA_VERSION:
		last_error = "unsupported save schema %s" % str(data.get("schema_version"))
		return false
	var sim: WroughtwildSim = player.inventory.get_sim()
	if not sim.import_json(data.get("sim", "")):
		last_error = "rules state rejected: %s" % sim.last_error()
		return false

	var root: Node = player.world_root()
	# A save from a different generated world rebuilds that world first, so
	# the node names below resolve against the right terrain.
	if data.has("world_seed") and root.has_method("apply_world_seed"):
		root.call("apply_world_seed", int(data["world_seed"]))
	# Dug blocks become exactly the save's: holes it has are carved, holes
	# dug since are filled back in.
	var terrain := root.get_node_or_null("Terrain") as Terrain
	if terrain != null and not terrain.map.is_empty():
		terrain.apply_broken_blocks(data.get("broken_blocks", []))
		terrain.apply_cracked(data.get("cracked_blocks", []))

	var blocks: Array = []
	var nodes: Array = []
	var sites: Array = []
	_walk(root, blocks, nodes, sites)
	# Placed pieces: the structure registry and its nodes both rebuild from
	# the save, so what stands where is exactly what was saved.
	for block in blocks:
		block.get_parent().remove_child(block)
		block.free()
	sim.structure_clear()
	for entry in data.get("blocks", []):
		var c: Array = entry["cell"]
		var element := {
			"kind": String(entry["kind"]),
			"axis": int(entry["axis"]),
			"cell": Vector3i(int(c[0]), int(c[1]), int(c[2])),
		}
		player.placement.place_piece(element, StringName(entry["shape"]), StringName(entry["family"]),
			int(entry.get("rotation_step", 0)))
	player.placement.refresh_trims()

	# Resource nodes: restore units, respawn ones depleted since the save,
	# and drop ones the save no longer knows about (depleted before the save).
	var saved_names := {}
	for entry in data.get("resource_nodes", []):
		saved_names[entry["name"]] = true
		var parent: Node = root.get_node_or_null(NodePath(entry["parent"]))
		if parent == null:
			parent = root
		var node: ResourceNode = null
		for candidate in nodes:
			if candidate.name == entry["name"]:
				node = candidate
		if node == null:
			node = RESOURCE_NODE_SCENE.instantiate()
			node.name = entry["name"]
			node.material_family = StringName(entry["family"])
			parent.add_child(node)
			node.global_position = _unvec(entry["position"])
		node.remaining_units = int(entry["remaining_units"])
		node.units_per_harvest = int(entry["units_per_harvest"])
		node.heat_to_work = int(entry.get("heat_to_work", node.heat_to_work))
		node.cracked = bool(entry.get("cracked", false))
		node.tool_item = StringName(String(entry.get("tool_item", String(node.tool_item))))
		node.drive_presses = int(entry.get("drive_presses", node.drive_presses))
		node.wedge_set = bool(entry.get("wedge_set", false))
		node.drive_progress = int(entry.get("drive_progress", 0))
		if node.is_inside_tree():
			node._refresh_wedge_look()
	for node in nodes:
		if not saved_names.has(node.name):
			node.get_parent().remove_child(node)
			node.free()

	# Placed station sites: rebuild the set from the save. Saves without the
	# key (pre-sandpit) keep whatever sites the scene authored.
	if data.has("stations"):
		var station_scene: PackedScene = load("res://scenes/station_site.tscn")
		for site in sites:
			site.get_parent().remove_child(site)
			site.free()
		sites = []
		for entry in data["stations"]:
			var site: StationSite = station_scene.instantiate()
			if entry.has("name"):
				site.name = entry["name"]
			site.station_id = StringName(entry["station_id"])
			site.upgrade_station_id = StringName(entry["upgrade_station_id"])
			var parent: Node = root
			if entry.has("parent"):
				parent = root.get_node_or_null(NodePath(entry["parent"]))
				if parent == null:
					parent = root
			parent.add_child(site)
			site.global_position = _unvec(entry["position"])
			site.rotation.y = entry.get("rotation_y", 0.0)
			sites.append(site)

	var pose: Dictionary = data.get("player", {})
	if not pose.is_empty():
		player.global_position = _unvec(pose["position"])
		player.rotation.y = pose["yaw"]
		player.spring_arm.rotation.x = pose["pitch"]
		player.velocity = Vector3.ZERO

	for site in sites:
		site.refresh_visual(sim)
	if player.hud != null:
		player.hud.refresh()
	return true


func write(path: String, player: WroughtwildPlayer) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		last_error = "cannot open %s for writing (%s)" % [path, error_string(FileAccess.get_open_error())]
		return false
	file.store_string(JSON.stringify(capture(player), "  "))
	file.close()
	return true


func read(path: String, player: WroughtwildPlayer) -> bool:
	if not FileAccess.file_exists(path):
		last_error = "no save at %s" % path
		return false
	var text := FileAccess.get_file_as_string(path)
	var parsed: Variant = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		last_error = "save file is not valid JSON"
		return false
	return apply(player, parsed)
