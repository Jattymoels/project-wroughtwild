extends "res://tests/pressure_workshop.gd"
## Repeated generated-world lifetimes. Review stock, scripted relocations and
## stream ticks are explicit; entry uses ordinary player physics and paid pieces.
const SAVE := "user://session-soak.json"
const MANIFEST := "user://session-soak.expected.json"
const WIDTH := 10
const DEPTH := 8
var cycles := 8
var began_usec := 0
var home_cell := Vector3i.ZERO
var chest_key := ""
var partial_id := ""
var spent_id := ""
var dig := Vector3i.ZERO
var crack := Vector3i.ZERO
var manager := SaveManager.new()
var expected: Dictionary = {}
var samples: Array = []
var relocated_metres := 0.0
var stream_metres := 0.0
var released_checks := 0
var resume_only := false
var phase := ""
var home_station_keys: Array[String] = []

func _ready() -> void:
	began_usec = Time.get_ticks_usec()
	world_profile = "frontier_v6"
	output = ProjectSettings.globalize_path("res://../build/session-reliability")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-profile="): world_profile = arg.get_slice("=", 1)
		if arg.begins_with("--review-seed="): world_seed = int(arg.get_slice("=", 1))
		if arg.begins_with("--review-output="): output = arg.trim_prefix("--review-output=")
		if arg.begins_with("--review-phase="): phase = arg.get_slice("=", 1)
		if arg.begins_with("--soak-cycles="): cycles = maxi(1, int(arg.get_slice("=", 1)))
		resume_only = resume_only or arg == "--soak-resume"
	DirAccess.make_dir_recursive_absolute(output)
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	mood.set_process(false)
	terrain.set_process(false)
	set_physics_process(false)
	await get_tree().physics_frame
	check(world_profile == "frontier_v6" and terrain.map.home_sites.size() == 4, "V6 provides the real home and approach guarantees")
	if failures: _finish(); return
	if resume_only:
		await _restart()
		_finish()
		return
	await _build_home()
	if failures: _finish(); return
	await _enter_home()
	await _start_work()
	if failures: _finish(); return
	await _alter_world()
	if failures: _finish(); return
	await _visit(_interior())
	_freeze_owned()
	expected = _durable()
	for cycle in cycles:
		await _circuit(cycle)
		if failures: break
	if not failures:
		var manifest := {"home": _array(home_cell), "chest": chest_key, "feeder": feeder_key,
			"partial": partial_id, "spent": spent_id, "dig": _array(dig), "crack": _array(crack),
			"stations": home_station_keys, "expected": expected}
		var file := FileAccess.open(MANIFEST, FileAccess.WRITE)
		check(file != null, "fresh-process expectations have an independent fixture file")
		if file != null: file.store_string(JSON.stringify(manifest, "", true, true)); file.close()
		await _enter_home()
	_finish()

static func _array(v: Vector3i) -> Array:
	return [v.x, v.y, v.z]

static func _cell(a: Array) -> Vector3i:
	return Vector3i(int(a[0]), int(a[1]), int(a[2]))

func _interior() -> Vector3:
	return Vector3(home_cell) + Vector3(2.5, 1.97, 2.5)

func _piece(shape: String) -> PlacedBlock:
	for child in get_children():
		if child is PlacedBlock and String(child.shape_id) == shape: return child
	return null

func _paid(shape: StringName, cell: Vector3i, kind := "volume", axis := 0) -> bool:
	var build := player.placement
	build.select_shape(shape)
	build.selected_material_family = &"wood"
	build.preview_rotation_step = 0
	var cost := int(_sim().shape_material_cost(shape))
	_sim().add_material("wood", cost)
	var before := int(_sim().material_count("wood"))
	player.position = Vector3(cell) + Vector3(-2, 1.97, -2)
	var element := {"kind": kind, "axis": axis, "cell": cell * 2}
	var refusal := build.element_refusal(element)
	check(refusal.is_empty(), "normal house target accepts %s at %s: %s" % [shape, cell, refusal])
	if not refusal.is_empty(): return false
	build.preview_element = element
	build.preview_visible = true
	var placed := build.try_place_block()
	check(placed and _sim().material_count("wood") == before - cost, "house pays exact native cost: " + String(shape))
	return placed

func _build_home() -> void:
	var definition: Dictionary = terrain.map.home_sites[0]
	home_cell = Vector3i(int(definition.x) - WIDTH / 2, 0, int(definition.z) - DEPTH / 2)
	await _visit(Vector3(definition.x, definition.y, definition.z))
	for x in range(-1, WIDTH + 1):
		for z in range(-3, DEPTH + 1):
			home_cell.y = maxi(home_cell.y, ceili(terrain.surface_position(home_cell.x + x, home_cell.z + z).y))
	player.placement.set_build_mode_enabled(true)
	for x in WIDTH:
		for z in DEPTH:
			if not _paid(&"cube", home_cell + Vector3i(x, 0, z)): return
	for y in range(1, 4):
		for z in DEPTH:
			for x in [0, WIDTH]:
				if not _paid(&"wall_panel", home_cell + Vector3i(x, y, z), "face", 0): return
		for x in WIDTH:
			for z in [0, DEPTH]:
				if z == 0 and x == 2 and y < 3: continue
				if not _paid(&"wall_panel", home_cell + Vector3i(x, y, z), "face", 2): return
	if not _paid(&"door", home_cell + Vector3i(2, 1, 0), "face", 2): return
	for x in WIDTH:
		for z in DEPTH:
			if not _paid(&"floor_slab", home_cell + Vector3i(x, 4, z), "face", 1): return
	if not _paid(&"stairs", home_cell + Vector3i(2, 0, -1)): return
	for z in [-3, -2]:
		if not _paid(&"floor_slab", home_cell + Vector3i(2, 0, z), "face", 1): return
	if not _paid(&"chest", home_cell + Vector3i(7, 1, 5)): return
	chest_key = _piece("chest").store_key()
	_sim().add_material("wood", 17)
	check(_sim().store_deposit(chest_key, "wood", 17) == 17, "seventeen stored wood have exactly one owner")
	for kit: String in ["workbench_kit", "mason_yard_kit"]:
		_sim().add_material(kit, 1)
		player.placement._select_kit(StringName(kit))
		var cell := home_cell + Vector3i(1 if kit == "workbench_kit" else 4, 1, 5)
		player.position = _interior()
		var element := {"kind": "volume", "axis": 0, "cell": cell * 2}
		check(player.placement.element_refusal(element).is_empty(), "station footprint fits inside the complete home")
		player.placement.preview_element = element
		player.placement.preview_visible = true
		check(player.placement.try_place_block(), "home station consumes its ordinary kit")
	for site in get_tree().get_nodes_in_group("crafting_stations"):
		if site is StationSite and site.player_built: home_station_keys.append(site.station_key)
	player.placement.set_build_mode_enabled(false)
	await get_tree().physics_frame
	check(player.placement.enclosure_at(_interior()).enclosed, "complete 10 by 8 home provides native shelter")
	check(home_station_keys.size() == 2, "both indoor stations have persistent physical keys")

func _enter_home() -> void:
	await _visit(Vector3(home_cell) + Vector3(2.5, 1.105, -1.7))
	var door := _piece("door")
	check(door != null, "restored home has its physical doorway")
	if door == null: return
	door.set_door_open(false)
	await get_tree().physics_frame
	player.rotation = Vector3.ZERO
	player.spring_arm.rotation = Vector3.ZERO
	player.velocity = Vector3.ZERO
	player.camera.global_position = player.position + Vector3.UP * WroughtwildPlayer.FP_EYE_HEIGHT
	player.camera.look_at(door.leaf_point())
	check(player.aim_probe().get("target") == door, "ordinary aim ray reaches the home door")
	player.interact()
	check(door.open, "ordinary E opens the home door")
	if not door.open: return
	player.test_walk = Vector2(0, 1)
	player.set_physics_process(true)
	for frame in 160:
		await get_tree().physics_frame
		if player.position.z > home_cell.z + 2.6: break
	player.test_walk = Vector2.ZERO
	for frame in 4: await get_tree().physics_frame
	player.set_physics_process(false)
	check(player.position.z > home_cell.z + 2.5 and absf(player.position.y - home_cell.y - 1.96) < .08,
		"normal controller climbs stairs and enters the restored house: " + str(player.position - Vector3(home_cell)))
	check(player.placement.enclosure_at(player.position).enclosed, "actual occupied home is sheltered")
	var chest := _piece("chest")
	player.open_chest(chest)
	check(player.chest_panel.is_open() and player.chest_panel.store_key == chest_key, "return opens the correct native chest")
	check(_sim().store_contents(chest_key).get("wood", 0) == 17, "return retains stored supplies")
	player.chest_panel.close_panel()

func _start_work() -> void:
	var definition: Dictionary = terrain.map.pressure_pockets[0]
	source = PressurePocket.find_source(get_tree(), String(definition.id))
	check(source != null, "struck smithy has a finite source")
	if source == null: return
	var work: Vector3 = definition.work_position
	await _visit(work + Vector3(0, 1.2, 5))
	_sim().add_station("workbench")
	await _place_workshop(work)
	if feeder == null or forge == null: return
	feeder_key = feeder.machine_key
	check(feeder.attach_feeder(forge.station_key, source.source_id).ok, "paid feeder attaches to the old hearth and player forge")
	check(feeder.perform("charge").ok, "four finite strokes transfer into the drive store")
	_sim().add_materials({"raw_clay": 8, "wood": 1})
	check(_sim().contraption_deposit(feeder_key, "raw_clay", 8).moved == 8, "recipe clay enters the machine once")
	check(_sim().contraption_deposit(feeder_key, "wood", 1).moved == 1, "recipe fuel enters the machine once")
	check(feeder.perform("start").ok, "local handle reserves one real recipe")
	feeder._physics_process(2.375)
	check(_sim().contraption_state(feeder_key).cycle_seconds == 2.375, "test leaves a partially completed recipe, not free output")
	_freeze_owned()

func _alter_world() -> void:
	var spawn := player.spawn_position
	await _visit(spawn)
	var ids: Array[String] = []
	for id: String in terrain.resource_stream.records:
		var record: Dictionary = terrain.resource_stream.records[id]
		if record.visual == "boulder" and int(record.drive_presses) > 1 and int(record.heat_to_work) == 0 and SaveManager._unvec(record.position).distance_to(spawn) < 100:
			ids.append(id)
	check(ids.size() >= 2, "generated boulders support both partial work and depletion")
	if ids.size() < 2: return
	partial_id = ids[0]
	spent_id = ids[1]
	var partial := terrain.resource_stream.materialise(partial_id)
	partial.work(_sim())
	check(partial.drive_progress == 1, "normal contextual work records one unfinished press")
	var spent := terrain.resource_stream.materialise(spent_id)
	var amount := spent.remaining_units
	var removed := 0
	while spent.remaining_units > 0: removed += spent.harvest()
	check(removed == amount, "depletion removes exactly the finite source quantity")
	# The released units remain loose. Freeze their age/motion so this checks
	# ownership across travel, not the already separately tested expiry system.
	for drop in Pickup.scatter(self, spawn + Vector3(18, 2, 18), {String(spent.material_family): removed}, 17, spawn.y):
		drop.set_physics_process(false)
	var pack: DroppedBundle = preload("res://scenes/dropped_bundle.tscn").instantiate()
	add_child(pack)
	pack.position = spawn + Vector3(20, 0, 18)
	pack.contents = {"raw_clay": 3}
	dig = Vector3i(floori(spawn.x / 16) * 16, 0, floori(spawn.z / 16) * 16)
	dig.y = terrain.height_at(dig.x, dig.z) - 1
	terrain.cracked[dig] = true
	check(terrain.break_block(dig.x, dig.y, dig.z) != "", "real seam excavation removes one terrain cell")
	crack = dig + Vector3i(2, 0, 2)
	crack.y = terrain.height_at(crack.x, crack.z) - 1
	terrain.cracked[crack] = true
	mob_packs.restore_loot_counter(23)
	await get_tree().physics_frame
	check(not terrain.resource_stream.has_resource(spent_id), "finite depleted source leaves no live record")

func _freeze_owned() -> void:
	for node in get_tree().get_nodes_in_group("pickups"): node.set_physics_process(false)
	for node in get_tree().get_nodes_in_group("contraptions"): node.set_physics_process(false)
	feeder = ContraptionSite.find_site(get_tree(), feeder_key)

func _visit(at: Vector3) -> void:
	relocated_metres += player.position.distance_to(at)
	player.position = at
	terrain.ensure_area(at, 32)
	terrain.resource_stream.focus(at, true)
	terrain.chunk_stream._finish_job()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_bounded()

func _bounded() -> void:
	var status := terrain.chunk_stream.retention()
	check(int(status.resident_chunks) <= int(status.near_chunk_bound) + int(status.edited_chunk_bound),
		"resident terrain remains bounded by nearby chunks and actual excavations")
	var actual := 0
	for child in terrain.get_children():
		if String(child.name).begins_with("Chunk_"): actual += 1
	check(actual <= int(status.resident_chunks) + int(status.partial_chunks), "terrain retains no detached chunk scenes")

func _circuit(cycle: int) -> void:
	var weak_door: WeakRef = weakref(_piece("door"))
	var weak_feeder: WeakRef = weakref(feeder)
	var old_chunk: Node3D = terrain.chunks.values()[0]
	var weak_chunk: WeakRef = weakref(old_chunk)
	var key := String(old_chunk.name).trim_prefix("Chunk_")
	old_chunk = null
	var ledger := _sim().contraption_save()
	for definition: Dictionary in terrain.map.regions:
		var route: PackedVector3Array = definition.approach
		var begin := maxi(0, route.size() - 65)
		await _visit(route[begin] + Vector3.UP * 1.2)
		# Native route steps exercise normal staged prefetch. The .2 seconds
		# supplied to each stream is accelerated; no walking or elapsed-time claim.
		for index in range(begin + 1, route.size()):
			var at := route[index] + Vector3.UP * 1.2
			stream_metres += player.position.distance_to(at)
			player.position = at
			terrain.chunk_stream.tick(.2, at)
			terrain.resource_stream.tick(.2, at)
			await get_tree().process_frame
		feeder._physics_process(60.0)
		check(_sim().contraption_save() == ledger, "distant workshop gains no offline or catch-up production")
	await _visit(_interior())
	check(not terrain.chunks.has(key) or weak_chunk.get_ref() == null, "distant travel releases the old unedited chunk object")
	check(_sim().contraption_save() == ledger, "return preserves source stock, recipe escrow and exact active time")
	check(terrain.block_at(dig.x, dig.y, dig.z) == 0 and terrain.cracked.has(crack), "return retains the hole and unfinished excavation")
	check(not terrain.resource_stream.has_resource(spent_id), "return never regenerates the spent source")
	check(int(terrain.resource_stream.records[partial_id].drive_progress) == 1, "return retains unfinished harvest work")
	_same_durable(expected, "travel preserves the complete durable ownership set")
	var write_at := Time.get_ticks_usec()
	check(manager.write(SAVE, player), "whole world writes atomically: " + manager.last_error)
	var write_ms := (Time.get_ticks_usec() - write_at) / 1000.0
	_sim().add_material("raw_clay", 1)
	player.position += Vector3(3, 0, 0)
	var load_at := Time.get_ticks_usec()
	check(manager.read(SAVE, player), "whole world restores through ordinary validation: " + manager.last_error)
	var load_ms := (Time.get_ticks_usec() - load_at) / 1000.0
	_freeze_owned()
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(weak_door.get_ref() == null and weak_feeder.get_ref() == null, "replaced house and workshop nodes are freed")
	released_checks += 1
	_same_durable(expected, "save/load restores all ownership, geometry, pose and RNG counter together")
	check(player.placement.enclosure_at(_interior()).enclosed, "restored large home still seals shelter")
	_bounded()
	var row := {"cycle": cycle + 1, "write_ms": write_ms, "load_ms": load_ms,
		"memory_bytes": OS.get_static_memory_usage(), "objects": Performance.get_monitor(Performance.OBJECT_COUNT),
		"nodes": get_tree().get_node_count(), "orphans": Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT),
		"resources": terrain.resource_stream.records.size(), "active_resources": terrain.resource_stream.active.size(),
		"retention": terrain.chunk_stream.retention()}
	samples.append(row)
	print("SESSION_CYCLE ", JSON.stringify(row))

func _durable() -> Dictionary:
	var data := manager.capture(player)
	var result := {}
	for field in ["sim", "contraptions", "blocks", "player", "world_profile", "world_seed", "world_drops", "broken_blocks", "cracked_blocks", "loot_kill_counter"]:
		result[field] = data.get(field)
	var stations: Array = []
	for site: Dictionary in data.stations:
		var stable := site.duplicate(true)
		stable.erase("name") # Godot sanitizes generated @ names on recreation.
		stations.append(stable)
	result.stations = stations
	var resources := {}
	for record: Dictionary in data.resource_nodes:
		var stable := record.duplicate(true)
		# Re-grounding changes only the presentation's sampled Y, not the source.
		stable.erase("position")
		resources[String(record.resource_id)] = stable
	result.resources = resources
	# Live work promotes tool labels to StringName; disk JSON stores String.
	# Compare the full-precision disk representation on both sides, retaining
	# opaque native rule/ledger strings byte-for-byte and every ownership field.
	return JSON.parse_string(JSON.stringify(result, "", true, true))

func _same_durable(baseline: Dictionary, label: String) -> void:
	var actual := _durable()
	if actual != baseline:
		var differences: Array = []
		_differences(actual, baseline, "", differences)
		print("SESSION_DIFFERENCES ", JSON.stringify(differences))
	check(actual == baseline, label)

func _differences(actual: Variant, baseline: Variant, path: String, rows: Array) -> void:
	if actual == baseline or rows.size() >= 12: return
	var count_before := rows.size()
	if actual is Dictionary and baseline is Dictionary:
		for key in baseline: _differences(actual.get(key), baseline[key], path + "/" + str(key), rows)
		for key in actual:
			if not baseline.has(key): rows.append({"path": path + "/" + str(key), "change": "added"})
	elif actual is Array and baseline is Array and actual.size() == baseline.size():
		for i in actual.size(): _differences(actual[i], baseline[i], path + "/" + str(i), rows)
	else:
		rows.append({"path": path, "actual": str(actual).left(160), "expected": str(baseline).left(160)})
	if rows.size() == count_before:
		rows.append({"path": path, "actual_type": type_string(typeof(actual)), "expected_type": type_string(typeof(baseline)),
			"same_json": JSON.stringify(actual, "", true, true) == JSON.stringify(baseline, "", true, true)})

func _restart() -> void:
	var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	check(manifest is Dictionary, "fresh process has the previous process's ground truth")
	if not manifest is Dictionary: return
	home_cell = _cell(manifest.home)
	chest_key = String(manifest.chest)
	feeder_key = String(manifest.feeder)
	partial_id = String(manifest.partial)
	spent_id = String(manifest.spent)
	dig = _cell(manifest.dig)
	crack = _cell(manifest.crack)
	for key: String in manifest.stations: home_station_keys.append(key)
	check(manager.read(SAVE, player), "fresh process restores the normal saved world: " + manager.last_error)
	_freeze_owned()
	await get_tree().physics_frame
	await get_tree().physics_frame
	_same_durable(manifest.expected, "fresh process retains exact ownership, buildings, work, holes and pose")
	check(_sim().contraption_state(feeder_key).cycle_seconds == 2.375, "restart grants no production catch-up")
	check(not terrain.resource_stream.has_resource(spent_id), "restart keeps depleted source absent")
	await _enter_home()
	# Finish the reserved cycle at its actual workstation after returning.
	await _visit(feeder.position + Vector3(0, 1.2, 3))
	feeder._physics_process(8.0)
	var state: Dictionary = _sim().contraption_state(feeder_key)
	check(state.completed_cycles == 1 and state.output == {"rustclay_brick": 4}, "resumed reserved recipe produces exactly four bricks")
	check(_sim().contraption_withdraw(feeder_key, "output", "rustclay_brick", 4).moved == 4, "one output collection succeeds")
	check(not _sim().contraption_withdraw(feeder_key, "output", "rustclay_brick", 4).ok, "second output collection cannot duplicate bricks")

func _finish() -> void:
	var report := {"phase": phase, "profile": world_profile, "seed": world_seed, "checks": checks, "failures": failures,
		"elapsed_seconds": (Time.get_ticks_usec() - began_usec) / 1000000.0,
		"fresh_process": resume_only, "cycles_requested": cycles, "cycles_completed": samples.size(),
		"house_pieces": _sim().structure_piece_count(), "released_node_sets": released_checks,
		"relocation_distance_m": relocated_metres, "staged_route_distance_m": stream_metres,
		"startup": terrain.build_profile, "samples": samples,
		"scope": "Generated V6, seeded review supplies, paid placement, actual door entry, accelerated route ticks and distant relocations. Frozen loose-drop age and explicit machine ticks. Not owner playtesting, combat or an elapsed-hours claim."}
	var file := FileAccess.open(output.path_join("session-restart.json" if resume_only else "session-soak.json"), FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(report, "\t")); file.close()
	print("SESSION_SOAK %d checks, %d failures; %.2fs; %d completed circuits; fresh_process=%s" % [checks, failures, report.elapsed_seconds, samples.size(), resume_only])
	get_tree().quit(0 if failures == 0 else 1)
