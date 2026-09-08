extends "res://tests/forge_traversal.gd"
## Current-only invariants: warning, exact queues, physical cover navigation and old boundaries.
var contacts := 0
var contact_enemy: Enemy

func _run() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	trial = player.trial
	trial.set_process(false)
	sim = player.inventory.get_sim()
	arena = preload("res://scenes/trial_arena.tscn").instantiate()
	add_child(arena)
	if "--restore-baseline" in OS.get_cmdline_user_args():
		await _old_boundary()
	else:
		await _waves()
		await _cover_navigation()
		await _bite_commitment()
	print("FORGE_PRESSURE_CHECKS %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _old_boundary() -> void:
	var base := "res://../../baseline/captures/pressure/"
	var economy := FileAccess.get_file_as_string(base+"economy.json")
	var boundary: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base+"boundary.json"))
	check(sim.import_json(economy),"fresh process imports pre-05B native ownership")
	check(trial.restore_boundary(boundary),"pre-05B suspended floor restores with current rosters")
	check(sim.export_json() == economy,"old boundary restore preserves exact native economy")
	check(sim.call("trial_checkpoint") == boundary.checkpoint,"old checkpoint retains exact seed, route, deposits, loot, boons and weaknesses")
	check(player.combat.capture_trial_state() == boundary.combat,"old boundary preserves life and combat clocks without healing")
	check(trial.continue_floor(),"old boundary continues into the same next floor")
	check(trial.enter_room(0) and trial.current_room.encounter.size() == 12,"next uncleared encounter uses the current mixed population")
	trial.on_player_died()

func _waves() -> void:
	check(trial.begin_run("forge_tyrant") and trial.enter_room(0),"native warning fixture starts")
	for e in trial.trial_enemies(): e.set_physics_process(false)
	var opening := trial.trial_enemies().size()
	var reserve := trial.wave_queue.size()
	var notice := float(trial.rules.reinforcement_notice_seconds)
	trial._tick_spatial(float(trial.rules.reinforcement_delay_seconds)-notice+.01)
	check(trial._wave_announced and player.hud._notice.text.contains("Reinforcements approaching"),"actual HUD warns before reserves exist")
	check(trial.trial_enemies().size() == opening and trial.wave_queue.size() == reserve,"warning spends no queued enemy")
	trial._tick_spatial(notice-.01)
	check(trial.trial_enemies().size() == opening,"full warning interval remains available to move")
	trial._tick_spatial(.02)
	for e in trial.trial_enemies(): e.set_physics_process(false)
	check(trial.trial_enemies().size() == opening+reserve and trial.wave_queue.is_empty(),"one warned arrival consumes exactly its native reserves")
	var cells := arena.dungeon._walk_cells
	arena.dungeon._walk_cells = {}
	trial.wave_queue = ["ash_hound"]
	trial._release_wave()
	check(trial.wave_queue == ["ash_hound"] and trial.trial_enemies().size() == opening+reserve,"no safe floor means retained reserve, never a fallback inside collision")
	arena.dungeon._walk_cells = cells
	trial.on_player_died()
	check(trial.wave_queue.is_empty(),"leaving a run cancels every outstanding arrival")
	await frames(3)

func _cover_navigation() -> void:
	var dungeon := arena.build_floor({"stages":[{"index":0,"floor_index":0,"choices":[{"module":"kiln_hall"}]}],"floor_count":1},0)
	dungeon.open_room(0,0)
	await _settle_navigation(dungeon)
	var centre: Vector3 = dungeon.rooms["0:0"].centre
	player.global_position = dungeon.to_global(centre+Vector3(0,1,-8))
	player.combat.hit_taken.connect(func(_damage:float,_source:String): contacts+=1)
	for id in [&"ash_hound",&"cinder_archer",&"marsh_wisp"]:
		player.combat.life = player.combat.max_life
		player.combat.invulnerable_left = 0
		contacts = 0
		contact_enemy = Enemy.spawn(self,id,dungeon.to_global(centre+Vector3(0,.02,7)))
		contact_enemy.trial_bound = true
		contact_enemy.trial_dungeon = dungeon
		contact_enemy.state = "chase"
		var releases := [0]
		contact_enemy.attack_released.connect(func(_kind:String): releases[0]+=1)
		await frames(2)
		check(not contact_enemy._attack_line_clear(player),"kiln starts between real bodies: "+String(id))
		var path := dungeon.path(contact_enemy.global_position,player.global_position)
		check(path.size() > 2,"route bends around kiln cover: "+String(id))
		var walked := 0.0
		for frame in 900:
			var prior := contact_enemy.global_position
			await frames(1)
			walked += prior.distance_to(contact_enemy.global_position)
			if contacts>0: break
		check(contacts>0,"real enemy follows cover route to actual contact: "+String(id))
		print("FORGE_CONTACT_NAV ",id," walked=",walked," hit_distance=",contact_enemy._horizontal_distance_to(player)," contacts=",contacts," releases=",releases[0]," at=",contact_enemy.global_position," target=",player.global_position," line=",contact_enemy._attack_line_clear(player))
		contact_enemy.free()
		for shot in get_tree().get_nodes_in_group("enemy_projectiles"): shot.free()
		await frames(2)
	arena.clear_floor()
	await frames(3)

func _bite_commitment() -> void:
	# No ground is needed for manual planar checks; disable gravity between ticks.
	player.global_position = Vector3(0,1,0)
	var original_ticks := Engine.physics_ticks_per_second
	for fps in [20,60]:
		Engine.physics_ticks_per_second = fps
		await frames(2)
		var e := Enemy.spawn(self,&"ash_hound",Vector3(0,0,1.5))
		e.set_physics_process(false)
		await frames(2)
		e.state = "chase"
		e._physics_process(1.0/fps)
		check(e.state == "windup" and not e._strike_direction.is_zero_approx(),"actual bite commits before movement at %d FPS"%fps)
		var committed := e._strike_direction
		var start := e.global_position
		player.position.x = 3
		# Publish the target's new collider and use the real physics step size:
		# move_and_slide integrates the engine clock, not an arbitrary manual delta.
		await frames(2)
		for i in ceili(e.windup_seconds*fps)+1:
			if e.state != "windup": break
			e.velocity.y = 0
			e._physics_process(1.0/fps)
		check(e._strike_direction == committed,"bite never retargets its committed direction at %d FPS"%fps)
		check(absf(Vector2(e.position.x-start.x,e.position.z-start.z).length()-e.windup_advance) < .02,"unobstructed bite delivers exactly its bounded step at %d FPS"%fps)
		print("BITE_STEP fps=",fps," metres=",Vector2(e.position.x-start.x,e.position.z-start.z).length())
		player.position.x = 0
		await frames(2)
		e.position = Vector3(0,0,1.5)
		e.state = "chase"
		e._attack_cooldown = 0
		e._physics_process(1.0/fps)
		e.stagger(1)
		var halted := e.position
		e._physics_process(.3)
		check(e.state == "chase" and Vector2(e.position.x-halted.x,e.position.z-halted.z).length()<.01,"stagger cancels the committed step")
		e.free()
	Engine.physics_ticks_per_second = original_ticks
