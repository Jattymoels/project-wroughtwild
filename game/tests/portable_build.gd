extends SceneTree
## External --script driver; excluded from the shipped PCK. The Python helper
## copies this file and isolated fixtures outside the repository before launch.
var checks := 0
var failures := 0
var world: Sandpit
var player: WroughtwildPlayer
var mode := OS.get_environment("WW_CHECK_MODE")
var output := OS.get_environment("WW_CHECK_OUTPUT")

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL PORTABLE: ", label)
	return ok

func frames(count := 3) -> void:
	for i in count: await process_frame

func freeze() -> void:
	world.set_physics_process(false)
	world.mob_packs.set_physics_process(false)
	world.mob_packs.set_process(false)
	for subject in [player, player.combat, player.placement, player.spring_arm]:
		subject.set_physics_process(false)
	player.trial.set_process(false)
	for enemy in get_nodes_in_group("enemies"): enemy.set_physics_process(false)

func capture_picture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(root.get_texture().get_image().save_png(output.path_join(name + ".png")) == OK, "rendered " + name)

func _run() -> void:
	root.size = Vector2i(1280, 720)
	var gateway = root.get_node_or_null("Sim")
	if not check(gateway != null and gateway.loaded, "native tuning loads"):
		return finish()
	if not OS.has_feature("editor"):
		check(gateway.get_tuning_directory() == OS.get_executable_path().get_base_dir().path_join("data/tuning"), "export resolves sibling tuning")
		check(not FileAccess.file_exists("res://tests/run_tests.gd") and not ResourceLoader.exists("res://experiments/roof_workshop.tscn"), "review scenes excluded")
	check(FileAccess.file_exists("res://settings.json"), "settings JSON packaged")
	check(FileAccess.file_exists("res://assets/authored/mobs/manifest.json"), "dynamic actor manifest packaged")
	# Dynamically loaded art must survive export, not just statically referenced scenes.
	var assets: Array = JSON.parse_string(FileAccess.get_file_as_string(output.path_join("assets.json")))
	for asset in assets:
		check(ResourceLoader.load(String(asset)) != null, "packaged asset: " + String(asset))
	if not check(change_scene_to_file("res://scenes/sandpit.tscn") == OK, "normal main scene loads"): return finish()
	await frames()
	world = current_scene as Sandpit
	player = world.player
	check(player.class_panel.is_open(), "initial class/continue panel visible")
	if DisplayServer.get_name() != "headless":
		check(world.seed_controls._column != null and world.seed_controls._scroll != null and world.seed_controls._scroll.is_inside_tree(), "startup seed controls finish layout wiring")
	check(player.preferences.definitions.size() == 9, "comfort defaults load from packaged data")
	if mode == "fresh" or mode == "prepare-trial":
		check(not FileAccess.file_exists(SaveManager.DEFAULT_PATH), "first launch has no inherited save")
		if world.seed_controls != null:
			world.seed_controls.field.text = "77"
			await capture_picture("first-launch")
		player.class_panel.choose("warden")
		for i in 300:
			if not world.terrain.map.is_empty(): break
			await frames(1)
		freeze()
		check(world.world_seed == 77 and world.world_profile == "frontier_v6", "chosen generated identity")
		if mode == "prepare-trial":
			await prepare_trial()
		else:
			await gather_and_craft()
			player.preferences.set_option("fov", 86.0)
			check(player.preferences.last_error == OK, "save independent camera preference")
			check(player.save_game(), "fresh built world saves")
	else:
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveManager.DEFAULT_PATH))
		var manager := SaveManager.new()
		freeze()
		var loaded: bool = world.seed_controls.continue_saved() if world.seed_controls != null else player.load_game()
		if not check(loaded, "Continue restores isolated checkpoint"): return finish()
		freeze()
		# Compare the same JSON representation used by SaveManager. Godot's
		# JSON parser can shift a binary64 by one ULP; comparing parsed disk
		# numbers directly with unencoded live values tests the parser round trip.
		# No tolerance is used, and the trial's combat_exact payload stays exact.
		var now: Dictionary = JSON.parse_string(JSON.stringify(manager.capture(player), "", true, true))
		var inspected := FileAccess.open(output.path_join("restored.json"), FileAccess.WRITE)
		inspected.store_string(JSON.stringify(now, "", true, true))
		inspected.close()
		check(JSON.parse_string(now.sim) == JSON.parse_string(saved.sim), "exact persistent inventory, equipment, progression and deposit")
		check(JSON.parse_string(now.contraptions) == JSON.parse_string(saved.contraptions), "exact finite fixture/source ownership")
		check(now.blocks == saved.blocks, "all paid building elements retained")
		var expected_stations: Array = saved.stations.duplicate(true)
		for station in expected_stations: station.name = String(station.name).validate_node_name()
		check(now.stations == expected_stations, "all paid station poses retained")
		check(now.resource_nodes == saved.resource_nodes, "exact finite depletion and partial work")
		check(now.world_profile == saved.world_profile and now.world_seed == saved.world_seed, "saved geography retained")
		check(now.world_drops == saved.world_drops, "exact loose item owners")
		if mode == "restart":
			check(player.camera.fov == 86.0, "fresh process retains independent preference")
		if mode == "trial":
			check(player.trial.active() and player.trial.state == "boundary", "suspended trial resumes at cleared lift")
			check(same_boundary(now.trial_boundary, saved.trial_boundary), "exact checkpoint, loot, choices, life and clocks")
			check(player.save_game(), "restored boundary suspends again")
			check(same_boundary(JSON.parse_string(FileAccess.get_file_as_string(SaveManager.DEFAULT_PATH)).trial_boundary, saved.trial_boundary), "resuspension does not heal or duplicate")
			check(player.trial.continue_floor() and player.trial.built_floor == 1, "resumed lift enters next playable floor")
		else:
			check(player.save_game(), "restored world saves again")
	await frames()
	player.hud.toggle_help()
	await frames()
	var title: Label = player.hud._help.get_child(0).get_child(0).get_child(0)
	var version := String(ProjectSettings.get_setting("application/config/version", ""))
	if not OS.has_feature("editor"):
		check(not version.is_empty() and version in title.text, "help exposes build identity")
	check(player.hud._help.size.x <= root.size.x and player.hud._help.size.y <= root.size.y, "build identity and settings fit viewport: %s within %s" % [player.hud._help.size, root.size])
	await capture_picture(mode)
	finish()

func gather_and_craft() -> void:
	var sim := player.inventory.get_sim()
	check(sim.inventory().is_empty(), "no starting material grants")
	for attempt in 100:
		if sim.material_count("wood") >= 12: break
		var source: ResourceNode
		for id in world.terrain.resource_stream.records:
			var record: Dictionary = world.terrain.resource_stream.records[id]
			if record.family == "wood" and int(record.remaining_units) > 0:
				source = world.terrain.resource_stream.materialise(id)
				break
		if not check(source != null, "finite wood source available"): return
		player.global_position = source.global_position + Vector3(0, 1.1, 1.4)
		var result := source.work(sim)
		if not check(not result.has("refusal"), "normal contextual gathering accepts work"): return
		var before := sim.material_count("wood")
		player._apply_work(source, result)
		check(sim.material_count("wood") == before, "work releases physical stock without inventory grant")
		for pickup in get_nodes_in_group("pickups"):
			if pickup.is_queued_for_deletion(): continue
			player.global_position = pickup.global_position - Vector3(0, .6, 0)
			pickup._physics_process(1.0 / 60.0)
		await frames(1)
	check(sim.material_count("wood") >= 12, "real pickup collects finite wood")
	player.work_panel.open_hand_crafting()
	var catalogue := player.work_panel.catalogue
	catalogue.select_recipe("workbench_kit")
	catalogue._render_detail()
	if not check(not catalogue._action.disabled, "hand recipe available from gathered stock"): return
	var before := sim.material_count("wood")
	var cost := int(sim.recipe("workbench_kit").inputs.wood)
	catalogue._action.pressed.emit()
	check(sim.material_count("workbench_kit") == 1 and sim.material_count("wood") == before - cost, "craft pays exact wood and creates one kit")
	player.work_panel.close_panel()
	var build := player.placement
	build.set_build_mode_enabled(true)
	player.build_palette.open_panel()
	player.build_palette.select_entry(&"workbench_kit", "kit")
	player.build_palette.close_panel()
	var placed := false
	for offset in range(8, 20):
		var at := player.spawn_position + Vector3(offset, 0, 0)
		world.terrain.ensure_area(at)
		var cell := Vector3i(floori(at.x), ceili(world.terrain.surface_position(floori(at.x), floori(at.z)).y), floori(at.z))
		player.global_position = Vector3(cell) + Vector3(-2, 2, -2)
		build.preview_element = {"kind": "volume", "axis": 0, "cell": cell * 2}
		build.preview_visible = true
		if build.try_place_block():
			placed = true
			break
		check(sim.material_count("workbench_kit") == 1, "refused kit placement retains ownership")
	check(placed and sim.material_count("workbench_kit") == 0, "successful placement pays exactly one kit")
	var stations := 0
	for station in get_nodes_in_group("crafting_stations"):
		if station.player_built and station.station_id == &"workbench":
			stations += 1
			check(station.is_built(sim) and station.visible, "one visible usable workbench")
			station.interact(player)
			check(player.work_panel.is_open(), "placed station opens crafting")
			player.work_panel.close_panel()
	check(stations == 1, "one scene owns crafted workbench")
	build.set_build_mode_enabled(false)

func prepare_trial() -> void:
	# Forced kills only prepare a compatibility fixture; no balance claim.
	var trial := player.trial
	var sim := player.inventory.get_sim()
	trial.seed_source.seed = 7147
	check(trial.begin_run("forge_tyrant"), "prepare existing story trial")
	for encounter in 8:
		if trial.state == "boundary": break
		var stage := sim.trial_stage()
		var room: Dictionary = trial.arena.dungeon.rooms.get("%d:0" % int(stage.index), {})
		if not check(not room.is_empty(), "fixture route exists"): return
		player.global_position = room.door.global_position + Vector3(0, .6, 1.5)
		trial.interact_fixture(room.door)
		for round_index in 40:
			for enemy in trial.trial_enemies():
				enemy.set_physics_process(false)
				enemy.take_damage(1000000000)
			for hazard in trial._hazards(): hazard.cancel()
			trial._tick_spatial(1)
			await frames(1)
			if trial.trial_enemies().is_empty() and trial.wave_queue.is_empty(): break
		trial._process(0)
		if not check(trial.state == "reward", "fixture encounter clears"): return
		player.global_position = trial.arena.dungeon.reward.global_position + Vector3(0, .6, 1.5)
		trial.interact_fixture(trial.arena.dungeon.reward)
		if not trial.current_offer.is_empty(): trial.accept_boon(String(trial.current_offer[0].id))
		elif trial.state == "reward" and trial.active(): trial.skip_offer()
		await frames(1)
	check(trial.state == "boundary", "fixture reaches cleared lift")
	player.global_position = trial.arena.dungeon.boundary.global_position + Vector3(0, .6, 1.5)
	trial._cancel_transients()
	player.combat.life = player.combat.max_life * .4312345678901234
	player.combat.cooldowns[&"prototype_dash"] = 2.751234567890123
	trial.elapsed_seconds = 123.5
	check(player.save_game(), "pre-export generated trial suspends")

func same_boundary(left: Dictionary, right: Dictionary) -> bool:
	# Restoring converts cooldown keys from String to StringName. Compare the
	# decoded exact values, not Variant encoder tags for equivalent key types.
	# Return positions are Vector3 (binary32) in the engine; compare that exact
	# representation, avoiding a second JSON binary64 parse of the same position.
	if Marshalls.base64_to_variant(left.combat_exact, false) != Marshalls.base64_to_variant(right.combat_exact, false): return false
	var a: Array = left.return_position
	var b: Array = right.return_position
	if Vector3(a[0], a[1], a[2]) != Vector3(b[0], b[1], b[2]): return false
	left = left.duplicate(true)
	right = right.duplicate(true)
	for key in ["combat_exact", "return_position"]:
		left.erase(key)
		right.erase(key)
	return left == right

func finish() -> void:
	var report := {"mode": mode, "checks": checks, "failures": failures, "engine": Engine.get_version_info(),
		"user_data": OS.get_user_data_dir(), "executable": OS.get_executable_path()}
	var file := FileAccess.open(output.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "  "))
	print("PORTABLE_BUILD ", mode, ": ", checks, " checks, ", failures, " failures")
	quit(1 if failures else 0)
