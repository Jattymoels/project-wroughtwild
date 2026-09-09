extends "res://tests/forge_traversal.gd"
## Physical geometry matrix, not combat: each existing module is presented in
## every laboratory room position. Native outcomes are explicitly forced.
const MODULES:=["threshold_gallery","loading_yard","fuel_chamber","kiln_hall","ward_gallery","cistern","secret_crucible","heart_forge"]

func _run() -> void:
	player=preload("res://scenes/player.tscn").instantiate();add_child(player)
	player.class_panel.choose("warden");player.placement.set_physics_process(false)
	player.combat.set_physics_process(false);player.combat.invulnerable_left=100000
	sim=player.inventory.get_sim();trial=player.trial;trial.set_process(false)
	arena=preload("res://scenes/trial_arena.tscn").instantiate();add_child(arena)
	var archive:Dictionary=JSON.parse_string(FileAccess.get_file_as_bytes("res://tests/fixtures/lf6-published-ending.json.gz").decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	for module in MODULES:
		if not check(sim.import_json(archive.sim) && trial.begin_map(1,0),"geometry fixture enters a native laboratory"):break
		# Only presentation module selection changes in this matrix. The native
		# run still drives stage, reward, physical route and availability states.
		for stage:Dictionary in trial.layout.stages:
			for choice:Dictionary in stage.choices:choice.module=module
		arena.build_floor(trial.layout,0);trial.show_doors()
		player.global_position=arena.player_spawn.global_position;player.velocity=Vector3.ZERO
		await _settle_player();await _settle_navigation(arena.dungeon)
		if not await _reach(arena.dungeon.boundary,module+" initial exit"):break
		check("Suspend" not in " ".join(arena.dungeon.boundary.world_lines()),"captured exit never promises suspension")
		for index in 5:
			var room:Dictionary=arena.dungeon.rooms["%d:0"%index]
			if not await _reach(room.door,module+" route "+str(index)):return finish_routes()
			player.interact()
			check(trial.state=="fighting" && not arena.dungeon.boundary.available,"actual route enters and seals extraction during fight")
			trial._despawn_enemies()
			for hazard in trial._hazards():hazard.cancel()
			var previous_build:=arena.dungeon.navigation_build_count
			var previous_iteration:=NavigationServer3D.map_get_iteration_id(arena.dungeon.navigation_map)
			trial._room_won() # Forced native outcome, never counted as combat.
			await _settle_refresh(arena.dungeon,previous_build,previous_iteration)
			if not await _reach(arena.dungeon.reward,module+" offering "+str(index)):return finish_routes()
			if index==4:break # Completion/automatic save is covered by the live world fixture.
			player.interact()
			if not trial.current_offer.is_empty():trial.skip_offer()
			await frames(3)
			if index==3:
				check(sim.trial_stage().can_bank_and_exit,"earned bank opens before boss")
				if not await _reach(arena.dungeon.boundary,module+" earned exit"):return finish_routes()
		# Dispose the completed synthetic native session without a world save.
		sim.trial_end();trial.state="idle";trial.spatial=false;trial.layout={}
		arena.clear_floor();player.work_panel.close_panel();await frames(3)
	finish_routes()

func finish_routes() -> void:
	print("LF7_ROUTES ",checks," checks, ",failures," failures; ",walked_metres," m actual capsule travel; 8 modules x 5 positions, outcomes forced")
	get_tree().quit(1 if failures else 0)
