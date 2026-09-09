class_name SaveManager
extends RefCounted
## Writes and restores the whole game in one file: the rules state (economy,
## equipment) as the sim's own SaveGame JSON, kept as opaque text so engine
## saves and text-playtest saves stay interchangeable, plus the engine-side
## world: placed shapes, finite resources, loose drops, death packs and pose.
##
## The schema is not yet declared stable (AGENTS.md); it may change until the
## vertical slice is accepted. v2 (Wave 4): placed pieces are saved by the
## lattice element they occupy, not by a transform.

const SCHEMA_VERSION := 2
const DEFAULT_PATH := "user://wroughtwild_save.json"
static func default_path() -> String:
	if OS.get_cmdline_user_args().has("--living-frontier-wave4") or OS.get_cmdline_user_args().has("--living-frontier-wave5") or OS.get_cmdline_user_args().has("--living-frontier-wave6") or OS.get_cmdline_user_args().has("--living-frontier-wave7"): return "user://living_frontier_wave4.json"
	if OS.get_cmdline_user_args().has("--living-frontier-wave3"): return "user://living_frontier_wave3.json"
	return "user://living_frontier_wave1.json" if OS.get_cmdline_user_args().has("--living-frontier") else DEFAULT_PATH

const RESOURCE_NODE_SCENE := preload("res://scenes/resource_node.tscn")

static func path_for(player: WroughtwildPlayer) -> String:
	if player.inventory.get_sim().campaign_policy()=="living_frontier_wave4":
		return String(player.get_meta("active_world_save_path","user://living_frontier_wave4.json"))
	return default_path()

var last_error := ""
var recovered_previous := false


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
		var entry := {
			"shape": String(block.shape_id),
			"family": String(block.material_family),
			"kind": String(block.element["kind"]),
			"axis": int(block.element["axis"]),
			"cell": [cell.x, cell.y, cell.z],
			"rotation_step": block.rotation_step,
		}
		if block.is_door():
			entry["door_open"] = block.open
		block_data.append(entry)

	var node_data: Array = []
	for node in nodes:
		if node.is_queued_for_deletion():
			continue
		node_data.append({
			"name": node.name,
			"resource_id": node.resource_id,
			"habitat_id": node.habitat_id,
			"presentation_label": node.presentation_label,
			"parent": String(root.get_path_to(node.get_parent())),
			"family": String(node.material_family),
			"visual": String(node.visual),
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
			"player_built": site.player_built,
			"station_key": site.station_key,
		})

	var data := {
		"schema_version": SCHEMA_VERSION,
		"sim": player.inventory.get_sim().export_json(),
		"contraptions": player.inventory.get_sim().contraption_save(),
		"leylines": player.inventory.get_sim().leyline_save(),
		"player": {
			"position": _vec(player.global_position),
			"yaw": player.rotation.y,
			"pitch": player.spring_arm.rotation.x,
		},
		"blocks": block_data,
		"resource_nodes": node_data,
		"stations": site_data,
		"world_drops": WorldDrops.capture(root),
	}
	# Generated worlds carry their seed so a load rebuilds the same terrain.
	if "world_seed" in root:
		data["world_seed"] = root.get("world_seed")
		data["world_profile"] = root.get("world_profile") if "world_profile" in root else "legacy_v1"
	if player.trial!=null and player.trial.active():
		data["trial_boundary"]=player.trial.capture_boundary()
	# The deterministic drop stream must continue across restarts. Saving
	# only the world seed replayed its early gear every time the game opened.
	var mob_packs := root.get_node_or_null("MobPacks") as MobPacks
	if mob_packs != null:
		data["loot_kill_counter"] = mob_packs.loot_kill_counter()
	# ...and every block the player dug out of it (Wave 3 digging).
	var terrain := root.get_node_or_null("Terrain") as Terrain
	if terrain != null and terrain.resource_stream != null:
		data["resource_nodes"]=terrain.resource_stream.capture()
	if terrain != null and not terrain.broken.is_empty():
		var broken_data: Array = []
		for v in terrain.broken:
			broken_data.append([v.x, v.y, v.z])
		data["broken_blocks"] = broken_data
	if terrain != null and not terrain.cracked.is_empty():
		data["cracked_blocks"] = terrain.cracked_packed_list()
	return data


func apply(player: WroughtwildPlayer, data: Dictionary) -> bool:
	last_error = ""
	recovered_previous = false
	var prepared := _prepare_restore(player, data)
	if prepared.is_empty(): return false
	return _apply_prepared(player, data, prepared)


func _prepare_restore(player: WroughtwildPlayer, data: Dictionary, restoring := true) -> Dictionary:
	if data.get("schema_version", -1) != SCHEMA_VERSION:
		last_error = "unsupported save schema %s" % str(data.get("schema_version"))
		return {}
	if not _valid_world_payload(data):
		last_error = "save contains invalid world or player fields"
		return {}
	var root: Node = player.world_root()
	# A generated world cannot restore an identity-less payload into the new
	# empty launch scene. Reject before importing economy or enabling movement;
	# seedless authored greybox saves remain supported by their authored hosts.
	if (root.has_method("apply_world_identity") or root.has_method("apply_world_seed")) and not data.has("world_seed"):
		last_error = "generated-world save is missing its world seed"
		return {}
	if data.has("world_seed") and (float(data.world_seed) < -2147483648.0 or float(data.world_seed) > 2147483647.0):
		last_error = "world seed is outside the native signed 32-bit range"
		return {}
	if String(data.get("world_profile", "legacy_v1")) in ["frontier_v6","living_frontier_wave1","living_frontier_wave3"] and int(data.get("world_seed", 0)) < 0:
		last_error = "new-world seed must be a nonnegative 31-bit number"
		return {}
	var sim: WroughtwildSim = player.inventory.get_sim()
	# Missing records in old schema-2 saves mean no recorded loose ownership.
	# Validate the entire new set before native import or any live-node removal.
	var drops: Variant = data.get("world_drops", {"version":1,"pickups":[],"bundles":[]})
	if not WorldDrops.valid(drops,sim):
		last_error = "invalid saved world drops"
		return {}
	# Validate the whole suspended payload and generation identity before either
	# the player's economy or their terrain changes. Old v2 saves stay legacy.
	var profile:=String(data.get("world_profile","legacy_v1"))
	if profile not in ["legacy_v1","frontier_v2","frontier_v3","frontier_v4","frontier_v5","frontier_v6","living_frontier_wave1","living_frontier_wave3"]:
		last_error="unknown world generation profile: "+profile
		return {}
	if not _valid_text(data.get("contraptions","")) or not sim.contraption_validate_world(String(data.get("contraptions","")), profile, int(data.get("world_seed",0))):
		last_error="invalid saved contraption state"
		return {}
	if not _valid_text(data.get("leylines","")) or not sim.leyline_validate_world(String(data.get("leylines","")),profile,int(data.get("world_seed",0))):
		last_error="invalid saved leyline lots or claims"
		return {}
	if not data.get("trial_boundary",{}) is Dictionary:
		last_error="invalid suspended trial boundary"
		return {}
	var boundary: Dictionary=data.get("trial_boundary",{})
	if data.has("trial_boundary"):
		if not _valid_integer(boundary.get("version")) or not _valid_integer(boundary.get("built_floor")) or not _valid_text(boundary.get("checkpoint")):
			last_error="invalid suspended trial fields"
			return {}
		for key in ["elapsed_seconds", "completed_encounters", "boss_tells"]:
			if boundary.has(key) and (not _valid_number(boundary[key]) or float(boundary[key])<0):
				last_error="invalid suspended trial progress"
				return {}
		if not boundary.get("combat") is Dictionary:
			last_error="invalid suspended combat state"
			return {}
		if int(boundary.get("version",0))!=1 or int(boundary.get("built_floor",-1))!=0 or not _valid_vec(boundary.get("return_position")) or not PlayerCombat.valid_trial_state(boundary["combat"]):
			last_error="invalid suspended trial boundary"
			return {}
		if boundary.has("combat_exact"):
			if not _valid_text(boundary["combat_exact"]):
				last_error="invalid exact suspended combat state"
				return {}
			# Godot 4.5's JSON parser can shift a binary64 value by one ULP even
			# with full-precision output. Keep the readable view, but restore the
			# checked binary companion. Object deserialization stays disabled.
			var exact:Variant=Marshalls.base64_to_variant(boundary["combat_exact"],false)
			if not exact is Dictionary or not PlayerCombat.valid_trial_state(exact):
				last_error="invalid exact suspended combat state"
				return {}
			var readable:Variant=JSON.parse_string(JSON.stringify(exact,"",true,true))
			if boundary["combat"]!=exact and boundary["combat"]!=readable:
				last_error="suspended combat representations do not match"
				return {}
			boundary=boundary.duplicate(true)
			boundary["combat"]=exact
		if not bool(sim.call("trial_checkpoint_valid",String(boundary.get("checkpoint","")))):
			last_error="unsupported or damaged suspended trial"
			return {}
		if not bool(sim.call("trial_checkpoint_matches",String(boundary.get("checkpoint","")),String(data.get("sim","")))):
			last_error="suspended trial does not match the saved player and world"
			return {}
		if restoring and (player.trial.active() or player.trial._find_arena()==null):
			last_error="cannot restore a suspended run into an active trial or a world without a trial arena"
			return {}
	# Prove that all saved pieces can coexist using the same native lattice as
	# restoration, before clearing a single live piece. Do not reapply current
	# terrain exposure, payment, recipe unlocks or new-placement restrictions.
	var candidate := WroughtwildSim.new()
	if not candidate.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()):
		last_error = "save validation could not load the existing rules"
		return {}
	if not candidate.import_json(String(data.sim)):
		last_error = "rules state rejected: " + candidate.last_error()
		return {}
	if not candidate.resonance_validate_world(profile,int(data.get("world_seed",0))):
		last_error = "saved resonance rejected: " + candidate.last_error()
		return {}
	for entry: Dictionary in data.get("blocks", []):
		var cell: Array = entry.cell
		var element := {"kind": String(entry.kind), "axis": int(entry.axis),
			"cell": Vector3i(int(cell[0]), int(cell[1]), int(cell[2]))}
		if not candidate.structure_place(element, String(entry.shape), String(entry.family), int(entry.get("rotation_step", 0))):
			last_error = "save contains unknown, misplaced or overlapping building pieces"
			return {}
	return {"profile": profile, "boundary": boundary, "drops": drops}


func _apply_prepared(player: WroughtwildPlayer, data: Dictionary, prepared: Dictionary) -> bool:
	var root: Node = player.world_root()
	var sim: WroughtwildSim = player.inventory.get_sim()
	var profile: String = prepared.profile
	var boundary: Dictionary = prepared.boundary
	var drops: Dictionary = prepared.drops
	if not sim.import_json(data.get("sim", "")):
		last_error = "rules state rejected: %s" % sim.last_error()
		return false
	if not sim.contraption_load_world(String(data.get("contraptions","")), profile, int(data.get("world_seed",0))):
		last_error="contraption state rejected: "+sim.last_error()
		return false
	if not sim.leyline_load_world(String(data.get("leylines","")),profile,int(data.get("world_seed",0))):
		last_error="leyline state rejected"
		return false

	# In-flight casts belong to the previous live state, never to a loaded save.
	for group in ["skill_bursts", "foundry_fields", "foundry_returns", "foundry_echoes", "foundry_embers", "foundry_cold", "foundry_offence", "foundry_guard", "foundry_sustain", "foundry_tempo", "player_projectiles"]:
		for effect in root.get_tree().get_nodes_in_group(group):
			effect.cancel()
	player.combat._mutation_cache.clear()
	player.combat._casts.clear()
	for puff in player.get_tree().get_nodes_in_group("foundry_puffs"): puff.queue_free()
	player.combat._action_contexts.clear()
	player.combat._reaction_ready.clear()
	# A save from a different generated world rebuilds that world first, so
	# the node names below resolve against the right terrain.
	if data.has("world_seed") and root.has_method("apply_world_identity"):
		if not root.call("apply_world_identity",int(data["world_seed"]),profile):
			last_error="world generation profile could not be restored"
			return false
	elif data.has("world_seed") and root.has_method("apply_world_seed"):
		root.call("apply_world_seed", int(data["world_seed"]))
	var mob_packs := root.get_node_or_null("MobPacks") as MobPacks
	if mob_packs != null:
		# Older v2 saves have no recoverable history: start at zero once.
		# Subsequent saves preserve the exact sequence, including on F9 load.
		mob_packs.restore_loot_counter(int(data.get("loot_kill_counter", 0)))
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
		var block := player.placement.place_piece(element, StringName(entry["shape"]), StringName(entry["family"]),
			int(entry.get("rotation_step", 0)))
		if block != null and block.is_door():
			# Older schema-2 saves have no leaf pose and retain their closed
			# default. Set once; replaying a load must never toggle a door.
			block.set_door_open(bool(entry.get("door_open", false)))
	player.placement.refresh_trims()

	# Resource nodes: restore units, respawn ones depleted since the save,
	# and drop ones the save no longer knows about (depleted before the save).
	if terrain != null and terrain.resource_stream != null:
		terrain.resource_stream.restore(data.get("resource_nodes",[]))
	else:
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
				node.resource_id=String(entry.get("resource_id",entry["name"]))
				node.habitat_id=String(entry.get("habitat_id",""))
				node.presentation_label=String(entry.get("presentation_label",""))
				node.material_family = StringName(entry["family"])
				node.visual = StringName(entry.get("visual", ""))
				# Older schema-2 saves did not store the visual. Recover generated
				# nodes from their stable name instead of restoring a default cylinder.
				if node.visual==&"" and terrain != null:
					for def in terrain.map.get("nodes",[]):
						if "wn_%s_%d_%d_%d" % [def["type"],def["x"],def["y"],def["z"]] == String(node.name):
							node.visual = StringName(def["visual"])
							break
				node.position = (parent as Node3D).to_local(_unvec(entry["position"])) if parent is Node3D else _unvec(entry["position"])
				node.remaining_units = int(entry["remaining_units"])
				parent.add_child(node)
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
			site.player_built = bool(entry.get("player_built", false))
			site.station_key = String(entry.get("station_key", ""))
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
	ContraptionSite.restore_all(root,sim)
	if terrain != null: terrain.ensure_area(terrain.to_local(player.global_position))
	if terrain != null and terrain.resource_stream != null:
		terrain.resource_stream.focus(terrain.to_local(player.global_position),true)
	player.placement.refresh_ecology()
	if not boundary.is_empty() and not player.trial.restore_boundary(boundary):
		last_error="suspended trial could not be restored"
		return false
	# Replace only after the world and any trial checkpoint have restored. This
	# is loose world ownership, never a second deposit or trial reward payout.
	WorldDrops.restore(root,drops)
	player.reset_environment_feedback()
	if player.hud != null:
		player.hud.refresh()
	# Release only publication's own stop, after terrain, placed bodies, trial
	# state and loose ownership are all installed. Every refusal keeps it.
	player.finish_world_recovery()
	player.central_ending_save_pending=false
	player.refresh_central_control()
	return true


func write(path: String, player: WroughtwildPlayer) -> bool:
	var data:=capture(player)
	if player.trial.active() and data.get("trial_boundary",{}).is_empty():
		last_error="only a fully cleared story-floor boundary can be suspended"
		return false
	# SaveManager instances are short-lived; the live player remembers only the
	# path recovered on their last successful load. After recovery, a normal F5
	# must not rotate the damaged current file over the intact previous one.
	var recovery_path := String(player.get_meta("recovered_save_path", ""))
	var preserve_previous := false
	if recovery_path == ProjectSettings.globalize_path(path) and FileAccess.file_exists(path + ".previous"):
		var current: Variant = _read_payload(path)
		preserve_previous = not current is Dictionary or _prepare_restore(player, current, false).is_empty()
	var written := _write_staged(path, data, preserve_previous)
	if written and player.inventory.get_sim().campaign_policy()=="living_frontier_wave4": player.set_meta("active_world_save_path",path)
	if written and recovery_path == ProjectSettings.globalize_path(path):
		player.remove_meta("recovered_save_path")
	if written:
		player.central_ending_save_pending=false
		player.refresh_central_control()
	return written

static func _valid_vec(value: Variant) -> bool:
	if not value is Array or value.size()!=3: return false
	for number in value:
		if not (number is float or number is int) or not is_finite(float(number)): return false
	return true

static func _valid_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _valid_integer(value: Variant) -> bool:
	return _valid_number(value) and float(value)==floorf(float(value))

static func _valid_text(value: Variant) -> bool:
	return value is String or value is StringName

static func _valid_cell(value: Variant) -> bool:
	if not _valid_vec(value): return false
	for number in value:
		if not _valid_integer(number) or float(number)<-2147483648.0 or float(number)>2147483647.0: return false
	return true

## Validate the fields consumed by world restoration before importing economy
## or removing live nodes. JSON can parse successfully while still being an
## incomplete synced save. Missing optional fields retain schema-2 defaults.
static func _valid_world_payload(data: Dictionary) -> bool:
	if not _valid_text(data.get("sim")): return false
	for key in ["world_seed", "loot_kill_counter"]:
		if data.has(key) and not _valid_integer(data[key]): return false
	if data.has("world_profile") and not _valid_text(data["world_profile"]): return false
	for key in ["blocks", "resource_nodes", "stations", "broken_blocks", "cracked_blocks"]:
		if data.has(key) and not data[key] is Array: return false
	var pose: Variant=data.get("player",{})
	if not pose is Dictionary: return false
	if not pose.is_empty() and (not _valid_vec(pose.get("position")) or not _valid_number(pose.get("yaw")) or not _valid_number(pose.get("pitch"))): return false
	for entry in data.get("blocks",[]):
		if not entry is Dictionary or not _valid_cell(entry.get("cell")) or not _valid_integer(entry.get("axis")): return false
		for key in ["shape", "family", "kind"]:
			if not _valid_text(entry.get(key)) or String(entry[key]).is_empty(): return false
		if entry["kind"] not in ["volume", "face", "edge"] or int(entry["axis"]) not in [0,1,2]: return false
		if entry.has("rotation_step") and not _valid_integer(entry["rotation_step"]): return false
		if entry.has("door_open") and not entry["door_open"] is bool: return false
	for entry in data.get("resource_nodes",[]):
		if not entry is Dictionary or not _valid_vec(entry.get("position")): return false
		for key in ["name", "parent", "family"]:
			if not _valid_text(entry.get(key)) or String(entry[key]).is_empty(): return false
		for key in ["resource_id", "habitat_id", "presentation_label", "visual", "tool_item"]:
			if entry.has(key) and not _valid_text(entry[key]): return false
		for key in ["remaining_units", "units_per_harvest"]:
			if not _valid_integer(entry.get(key)) or int(entry[key])<0: return false
		for key in ["heat_to_work", "drive_presses", "drive_progress"]:
			if entry.has(key) and (not _valid_integer(entry[key]) or int(entry[key])<0): return false
		for key in ["cracked", "wedge_set"]:
			if entry.has(key) and not entry[key] is bool: return false
	var station_keys: Dictionary = {}
	for entry in data.get("stations",[]):
		if not entry is Dictionary or not _valid_vec(entry.get("position")): return false
		for key in ["station_id", "upgrade_station_id"]:
			if not _valid_text(entry.get(key)): return false
		for key in ["parent", "name"]:
			if entry.has(key) and not _valid_text(entry[key]): return false
		if entry.has("rotation_y") and not _valid_number(entry["rotation_y"]): return false
		if entry.has("player_built") and not entry["player_built"] is bool: return false
		if entry.has("station_key") and not _valid_text(entry["station_key"]): return false
		var station_key := String(entry.get("station_key", ""))
		if bool(entry.get("player_built", false)) and station_key.is_empty(): return false
		if not station_key.is_empty():
			if station_keys.has(station_key): return false
			station_keys[station_key] = true
	for key in ["broken_blocks", "cracked_blocks"]:
		for cell in data.get(key,[]):
			if not _valid_cell(cell): return false
	return true

func write_data(path: String, data: Dictionary) -> bool:
	return _write_staged(path, data, false)


func _write_staged(path: String, data: Dictionary, preserve_previous: bool) -> bool:
	last_error = ""
	var temporary:=path+".pending"
	var backup:=path+".previous"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		last_error = "cannot open %s for writing (%s)" % [path, error_string(FileAccess.get_open_error())]
		return false
	file.store_string(JSON.stringify(data, "  ", true, true))
	file.flush()
	var error:=file.get_error()
	file.close()
	if error!=OK:
		last_error="save write failed: "+error_string(error)
		return false
	# The previous good file remains available throughout replacement, including
	# on Windows where rename cannot overwrite an existing destination.
	var had_previous:=FileAccess.file_exists(path)
	if had_previous and preserve_previous:
		# Staging is already flushed. A failed installation or interruption now
		# leaves the validated previous checkpoint in place for normal recovery.
		error = DirAccess.remove_absolute(path)
		if error != OK:
			last_error = "cannot replace damaged save: " + error_string(error)
			return false
	elif had_previous:
		if FileAccess.file_exists(backup): DirAccess.remove_absolute(backup)
		error=DirAccess.rename_absolute(path,backup)
		if error!=OK:
			last_error="cannot preserve previous save: "+error_string(error)
			return false
	error=DirAccess.rename_absolute(temporary,path)
	if error!=OK:
		if had_previous and not preserve_previous: DirAccess.rename_absolute(backup,path)
		last_error="cannot install save: "+error_string(error)
		return false
	return true


## Parse errors are expected recovery input, not engine errors. Object-free JSON
## parsing never executes saved content or treats a .pending file as committed.
static func _read_payload(path: String) -> Variant:
	if not FileAccess.file_exists(path): return null
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK: return null
	return parser.data


func read(path: String, player: WroughtwildPlayer) -> bool:
	last_error = ""
	recovered_previous = false
	if player.trial != null and player.trial.active():
		last_error = "cannot load inside an active trial"
		return false
	var parsed: Variant = _read_payload(path)
	if parsed is Dictionary:
		var rules_parser:=JSON.new()
		var rules: Variant=null
		if rules_parser.parse(String(parsed.get("sim","")))==OK: rules=rules_parser.data
		if rules is Dictionary and rules.get("economy") is Dictionary:
			var policy:=String(rules.economy.get("campaign_policy","legacy"))
			var resonance: Variant=rules.economy.get("resonance",{})
			var second: Variant=rules.economy.get("resonance_second",{})
			if policy not in ["legacy","living_frontier_wave4"] or (resonance is Dictionary and int(resonance.get("version",1))>1) or (second is Dictionary and int(second.get("version",1))>1):
				last_error="unsupported campaign or resonance save version"
				return false
		# A newer format/profile needs its matching game, not an automatic rewind.
		if parsed.get("contraptions", "") is String and not String(parsed.get("contraptions", "")).is_empty():
			var machine_data: Variant = JSON.parse_string(parsed.contraptions)
			if machine_data is Dictionary and _valid_integer(machine_data.get("schema")) and int(machine_data.schema) > 5:
				last_error = "unsupported contraption save version"
				return false
		if parsed.get("leylines", "") is String and not String(parsed.get("leylines", "")).is_empty():
			var leyline_data: Variant = JSON.parse_string(parsed.leylines)
			if leyline_data is Dictionary and _valid_integer(leyline_data.get("version")) and int(leyline_data.version) > 4:
				last_error = "unsupported leyline save version"
				return false
		if parsed.has("schema_version") and _valid_integer(parsed.schema_version) and int(parsed.schema_version)>SCHEMA_VERSION:
			last_error = "unsupported save schema %s" % str(parsed.schema_version)
			return false
		if parsed.has("world_profile") and _valid_text(parsed.world_profile) and String(parsed.world_profile) not in ["legacy_v1","frontier_v2","frontier_v3","frontier_v4","frontier_v5","frontier_v6","living_frontier_wave1","living_frontier_wave3"]:
			last_error = "unknown world generation profile: " + String(parsed.world_profile)
			return false
		var prepared := _prepare_restore(player, parsed)
		if not prepared.is_empty():
			var loaded := _apply_prepared(player, parsed, prepared)
			if loaded: player.set_meta("active_world_save_path",path)
			if loaded and player.has_meta("recovered_save_path"): player.remove_meta("recovered_save_path")
			return loaded
	else:
		last_error = "save file is missing or is not valid JSON"
	var original_error := last_error
	# Fall back only after validation rejected the current candidate without
	# mutation. Runtime failure after restoration begins must never try to merge
	# another checkpoint into partially applied state. Reading rewrites no file.
	if not path.ends_with(".previous"):
		var previous: Variant = _read_payload(path + ".previous")
		if previous is Dictionary:
			var prepared := _prepare_restore(player, previous)
			if not prepared.is_empty():
				last_error = ""
				var loaded := _apply_prepared(player, previous, prepared)
				if loaded: player.set_meta("active_world_save_path",path)
				recovered_previous = loaded
				if loaded: player.set_meta("recovered_save_path", ProjectSettings.globalize_path(path))
				return loaded
	last_error = original_error
	return false
