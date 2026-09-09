extends "res://tests/central_trial.gd"
## Real final-human damage drives death; earlier rooms force route outcomes.
const DEATH_SAVE := "user://lf6-central-death.json"
var death_hits := 0
var deaths := 0

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	sim.set_campaign_policy("living_frontier_wave4")
	world=preload("res://scenes/sandpit.tscn").instantiate()
	world.scene_file_path="" # Match the embedded route/render fixture.
	world.world_profile="living_frontier_wave3";world.world_seed=77
	get_tree().root.add_child(world);get_tree().current_scene=world
	player=world.player;trial=player.trial;arena=world.get_node("TrialArena")
	quiet_pairing()
	var manager:=SaveManager.new()
	if "--lf6-death-restart" in OS.get_cmdline_user_args():
		check(player.load_game(DEATH_SAVE),"fresh process restores actual Central death")
		quiet_pairing()
		var disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(DEATH_SAVE))
		check(JSON.parse_string(sim.export_json())==JSON.parse_string(disk.sim),"death restart preserves exact returned deposit and owned rewards")
		check_preserved(disk,manager.capture(player))
		check_controls(false)
		check(not sim.world_effect_active("forge_arc_complete") && not trial.active(),"death restart owns no ending or active fight")
		check(trial.begin_run("forge_capstone") && sim.boss().id=="conservator","ordinary Central retry remains available after death restart")
		return finish_central()
	check(player.load_game(CENTRAL_BOUNDARY),"ordinary load restores actual cleared Central boundary")
	quiet_pairing()
	var suspended:Dictionary=manager.capture(player)
	var held:Dictionary=JSON.parse_string(suspended.sim)
	var stored:Dictionary=sim.trial_run_state().duplicate(true)
	check(trial.continue_floor(),"normal Continue opens Central second floor")
	await _settle_player();await _settle_navigation(arena.dungeon)
	for index in range(4,8):
		var room:Dictionary=arena.dungeon.rooms["%d:0" % index]
		if not await _reach(room.door,"death fixture route %d" % index):return finish_central()
		player.interact()
		if not check(trial.state=="fighting","physical route opens before death test"):return finish_central()
		for enemy in trial.trial_enemies():enemy.set_physics_process(false)
		await frames(1)
		if index<7:
			await super._clear_encounter()
			if not await _reach(arena.dungeon.reward,"death fixture reward"):return finish_central()
			player.interact()
			if not trial.current_offer.is_empty():trial.skip_offer()
			continue
		var human:=trial.trial_enemies()[0] as Conservator
		if not check(human!=null,"death is against the actual human"):return finish_central()
		var destination:Vector3=arena.dungeon.to_global(room.centre+Vector3(0,0,5))
		for point in arena.dungeon.path(player.global_position,destination):
			if not await _walk_to(point,.3):return finish_central()
		player.combat.hit_taken.connect(func(_amount:float,_source:String):death_hits+=1)
		player.combat.died.connect(func():deaths+=1)
		player.combat.set_physics_process(true)
		player.combat.invulnerable_left=0
		player.test_walk=Vector2.ZERO
		human.set_physics_process(true)
		# No injected hit, life reduction, damage multiplier, skipped tell or
		# forced defeat. Deliberately standing in committed marks is fatal.
		for step in 60*180:
			if not trial.active():break
			await frames(1)
		check(deaths==1 && death_hits>0 && not trial.active(),"natural human releases cause one ordinary Trial death")
		print("LF6_LIVE_DEATH hits=",death_hits," deaths=",deaths," active=",trial.active())
		if trial.active():return finish_central()
	quiet_pairing()
	check(not sim.world_effect_active("forge_arc_complete") && not player.central_ending_save_pending,"death claims no ending or pending reward save")
	check_controls(false)
	var fallen:Dictionary=JSON.parse_string(sim.export_json())
	check(fallen.equipment==held.equipment && fallen.economy.pack_items==held.economy.pack_items,"human death preserves owned gear and pack items")
	check(fallen.economy.resonance==held.economy.resonance && fallen.economy.resonance_second==held.economy.resonance_second,"human death preserves both physical ledgers")
	check_preserved(suspended,manager.capture(player))
	check(player.save_game(DEATH_SAVE),"normal post-death save retains deposit for fresh process")
	var returned:=sim.export_json()
	check(trial.begin_run("forge_capstone") && sim.boss().id=="conservator","ordinary retry starts the dedicated Central run again")
	trial.on_player_died()
	check(sim.export_json()==returned,"retry then departure returns the exact deposit without ending or completion payout")
	check(player.load_game(CENTRAL_BOUNDARY),"ordinary boundary recovery remains valid after death and retry")
	quiet_pairing()
	check(JSON.parse_string(sim.export_json())==held && sim.trial_run_state()==stored,"boundary recovery restores the exact held haul and build")
	finish_central()
