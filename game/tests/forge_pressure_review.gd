extends "res://tests/forge_traversal.gd"
## Shared baseline/current reproduction of real native grouping and arrival safety.
## Inherits only the existing navigation wait and forced-clear ownership helpers.
var report := {}

func _run() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.combat.invulnerable_left = 100000
	trial = player.trial
	trial.set_process(false)
	sim = player.inventory.get_sim()
	arena = preload("res://scenes/trial_arena.tscn").instantiate()
	add_child(arena)
	trial.seed_source.seed = 193
	check(trial.begin_run("forge_tyrant"),"begin native pressure fixture")
	await _settle_navigation(arena.dungeon)
	check(trial.enter_room(0),"enter native threshold")
	await frames(2)
	var first := trial.trial_enemies()
	for e in first: e.set_physics_process(false)
	report.initial_ids = first.map(func(e):return String(e.enemy_id))
	report.native_total = trial.current_room.encounter.size()
	report.reserves = trial.wave_queue.size()
	check(first.any(func(e):return not e.projectile_rules.is_empty()),"opening group mixes contact and ranged pressure")
	check(not trial.wave_queue.is_empty(),"ordinary story encounter has a later reinforcement group")
	# Stand at a previously occupied spawn and retain all surviving bodies.
	# Force a reserve wave even on baseline, which normally has none here.
	player.global_position = first[0].global_position + Vector3.UP
	trial.wave_queue = ["ash_hound","cinder_archer","ember_whelp","marsh_wisp","ash_hound","ember_whelp"]
	trial._release_wave()
	var added := trial.trial_enemies().filter(func(e):return e not in first)
	var minimum_player := INF
	var minimum_survivor := INF
	for e in added:
		e.set_physics_process(false)
		minimum_player = minf(minimum_player,e._horizontal_distance_to(player))
		for old in first:
			minimum_survivor = minf(minimum_survivor,Vector2(e.global_position.x-old.global_position.x,e.global_position.z-old.global_position.z).length())
	report.arrival_player_distance = minimum_player
	report.arrival_survivor_distance = minimum_survivor
	check(not added.is_empty(),"safe alternate floor positions can admit reserves")
	check(minimum_player >= 4.0,"reinforcements do not appear on the player")
	check(minimum_survivor >= 1.0,"reinforcements do not stack inside surviving capsules")
	# Fill without kills: reservations must remain owned by the queue at the cap.
	trial.wave_queue.clear()
	for i in 40: trial.wave_queue.append("ash_hound")
	for i in 8:
		trial._release_wave()
		for e in trial.trial_enemies(): e.set_physics_process(false)
		check(trial.trial_enemies().size() <= 24,"every arrival respects 24 living cap")
	check(trial.trial_enemies().size()+trial.wave_queue.size() == first.size()+added.size()+40,"blocked arrivals lose or duplicate no queued enemies")
	report.at_cap = trial.trial_enemies().size()
	await _clear_encounter()
	check(trial.state == "reward","all reserve groups must clear before the single reward")
	var loot := sim.trial_loot().duplicate(true)
	trial._process(0)
	check(sim.trial_loot() == loot,"repeated clear polling cannot duplicate loot")
	trial.skip_offer()
	# Preserve an actual old-version boundary for a fresh current-process import.
	for i in 3:
		check(trial.enter_room(0),"native route advances toward cleared boundary")
		await _clear_encounter()
		trial.skip_offer()
	check(trial.state == "boundary","original floor boundary is unchanged")
	var output := ProjectSettings.globalize_path("res://../captures/pressure")
	DirAccess.make_dir_recursive_absolute(output)
	var boundary := FileAccess.open(output.path_join("boundary.json"),FileAccess.WRITE)
	boundary.store_string(JSON.stringify(trial.capture_boundary()))
	boundary.close()
	var economy := FileAccess.open(output.path_join("economy.json"),FileAccess.WRITE)
	economy.store_string(sim.export_json())
	economy.close()
	report.checks = checks
	report.failures = failures
	var file := FileAccess.open(output.path_join("pressure.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	print("FORGE_PRESSURE_REVIEW ",JSON.stringify(report))
	print("FORGE_PRESSURE_REVIEW %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
