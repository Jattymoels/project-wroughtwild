extends "res://tests/home_door_persistence.gd"
## Recovery probes use the existing paid-door fixture and isolated files.
## Each rejected candidate differs from live inventory/pose, so accepting a
## partial restoration cannot pass just because nothing visible changed.
var recovery_cases: Array[Dictionary] = []

func _run() -> void:
	await _create_doors()
	if cases.size() != 8: _finish(); return
	var original := manager.capture(player)
	var original_rules := sim.export_json()
	var original_pose := player.global_position
	sim.add_material("stone", 7)
	player.position += Vector3(0, 0, 3)
	var newer := manager.capture(player)
	var newer_rules := sim.export_json()
	for mode: String in ["normal", "missing", "truncated", "invalid_pose", "invalid_rules", "unknown_shape", "duplicate_piece", "future_schema", "future_profile"]:
		var path := "user://recovery-" + mode + ".json"
		check(manager.write_data(path, original), mode + ": write first complete checkpoint")
		check(manager.write_data(path, newer), mode + ": atomically retain first checkpoint as previous")
		var previous_bytes := FileAccess.get_file_as_bytes(path + ".previous")
		var broken := newer.duplicate(true)
		match mode:
			"missing":
				check(DirAccess.remove_absolute(path) == OK, "simulate interrupted final rename")
				_raw(path + ".pending", JSON.stringify(newer))
			"truncated": _raw(path, "{\"schema_version\":2,")
			"invalid_pose": broken.player.position = [0, "damaged", 3]
			"invalid_rules": broken.sim = "{"
			"unknown_shape": broken.blocks[-1].shape = "missing_shape"
			"duplicate_piece": broken.blocks.append(broken.blocks[0].duplicate(true))
			"future_schema": broken.schema_version = 999
			"future_profile": broken.world_profile = "frontier_future"
		if mode not in ["normal", "missing", "truncated"]: _raw(path, JSON.stringify(broken))
		# Change live possessions and pose before reading either valid file.
		sim.add_material("raw_clay", 1)
		player.position += Vector3(2, 0, 0)
		var before := manager.capture(player)
		var first_id := _door(cases[0]).get_instance_id()
		var began := Time.get_ticks_usec()
		var loaded := manager.read(path, player)
		recovery_cases.append({"case": mode, "loaded": loaded, "milliseconds": (Time.get_ticks_usec()-began)/1000.0, "error": manager.last_error})
		if mode in ["future_schema", "future_profile"]:
			check(not loaded, "future schema/profile is not silently replaced with an older checkpoint")
			check(manager.capture(player) == before and _door(cases[0]).get_instance_id() == first_id, "unsupported future save leaves the live world untouched")
		else:
			check(loaded, mode + ": normal read restores the intact eligible checkpoint")
			check(manager.get("recovered_previous") == (mode != "normal"), mode + ": caller can explain which checkpoint was loaded")
			check(manager.last_error.is_empty(), mode + ": successful load clears prior failure reasons")
			var expected := newer if mode == "normal" else original
			check(sim.export_json() == (newer_rules if mode == "normal" else original_rules), mode + ": exact rules ownership comes from the selected complete checkpoint")
			check(manager.capture(player).blocks == expected.blocks, mode + ": all pieces and door poses restore together")
			if mode != "normal": check(player.global_position.is_equal_approx(original_pose), mode + ": pose comes from the same previous checkpoint")
		check(FileAccess.get_file_as_bytes(path + ".previous") == previous_bytes, mode + ": reading never rewrites the retained previous file")
		if mode not in ["normal", "future_schema", "future_profile"]:
			# Normal player saves construct a new manager each time. Recovery
			# must still protect the good file from the damaged current one.
			var writer := SaveManager.new()
			check(writer.write(path, player), mode + ": normal save after recovery succeeds")
			check(FileAccess.get_file_as_bytes(path + ".previous") == previous_bytes, mode + ": saving after recovery retains the intact previous checkpoint")
		check(manager.apply(player, newer), mode + ": reset through valid restoration for the next independent case")
		await get_tree().physics_frame
	await _reject_invalid_builds(newer)
	_write_failures(newer)
	_finish()

func _raw(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	check(file != null, "fixture can stage the exact damaged candidate")
	if file != null: file.store_string(text); file.close()

func _reject_invalid_builds(saved: Dictionary) -> void:
	for mode: String in ["unknown_shape", "duplicate_piece", "wrong_slot", "out_of_range"]:
		var bad := saved.duplicate(true)
		match mode:
			"unknown_shape": bad.blocks[-1].shape = "missing_shape"
			"duplicate_piece": bad.blocks.append(bad.blocks[0].duplicate(true))
			"wrong_slot": bad.blocks[-1].kind = "volume"
			"out_of_range": bad.blocks[-1].cell = [4294967296, 0, 0]
		sim.add_material("raw_clay", 1)
		player.position += Vector3(1, 0, 0)
		var before := manager.capture(player)
		var id := _door(cases[0]).get_instance_id()
		check(not manager.apply(player, bad), mode + ": reject the whole invalid building set")
		check(manager.capture(player) == before and _door(cases[0]).get_instance_id() == id, mode + ": reject before changing rules, buildings or player pose")
		check(manager.apply(player, saved), mode + ": valid checkpoint remains loadable")
		await get_tree().physics_frame

func _write_failures(saved: Dictionary) -> void:
	var path := "user://blocked-write.json"
	check(manager.write_data(path, saved), "create isolated last-good file")
	var before := FileAccess.get_file_as_bytes(path)
	check(DirAccess.make_dir_absolute(path + ".pending") == OK, "block staging with one fixture-owned empty directory")
	check(not manager.write_data(path, saved), "failed staging refuses the write")
	check(FileAccess.get_file_as_bytes(path) == before, "failed write retains last good bytes")
	check(DirAccess.remove_absolute(path + ".pending") == OK, "remove only the fixture-owned empty staging directory")
	check(manager.write_data(path, saved), "retry after removing obstruction succeeds")
	check(manager.last_error.is_empty(), "a successful retry clears the stale failure reason")
	_raw(path, "{")
	_raw(path + ".previous", "{")
	var live := manager.capture(player)
	check(not manager.read(path, player), "two damaged candidates refuse restoration")
	check(manager.capture(player) == live, "failed recovery leaves the complete live state unchanged")

func _finish() -> void:
	print("SAVE_RECOVERY_CASES ", JSON.stringify(recovery_cases))
	print("SAVE_RECOVERY %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
