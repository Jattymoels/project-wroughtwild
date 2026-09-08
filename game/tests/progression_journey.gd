extends "res://tests/power_progression_review.gd"
## Full story combat attempts: actual deaths/clears, no skipped encounters,
## no accepted boons, healing injections, forced kills or refreshed cooldowns.
func _ready() -> void:
	initialize()
	await settle(4)
	for class_id in ["warden","ranger","kindler"]:
		for stage in ["starting","prepared","developed"]:
			cohort=class_id+"/"+stage
			ranged=class_id!="warden"
			builds[cohort]=fixed_build(class_id,stage,"recovery" if class_id=="warden" else "clear")
			meter.primary_only=""
			await journey()
	var file:=FileAccess.open("res://../build/intensives/progression-journey.json",FileAccess.WRITE)
	require(file!=null,"journey report")
	if file!=null:
		file.store_string(JSON.stringify({"attempts":measured_rows,"setup_errors":setup_errors,"limits":"Full Forge Tyrant story combat attempts, fixed seed and first route choices, permanent full class bars, no temporary boons. Starts at normal life; preserves life/cooldowns between encounters and floors. Movement within fights uses the normal controller. Travel to room entry is posed and excluded from timing: these are combat-sequence attempts, not traversal or full-run-duration evidence. Each encounter has a 90-second limit; deaths and timeouts stop the attempt, never count as completion. Developed/prepared weapon/armour and fixed arrangements follow power_progression_review."},"\t",true,true))
	Engine.time_scale=1
	print("PROGRESSION_JOURNEY ",measured_rows.size()," attempts; ",setup_errors.size()," setup errors")
	get_tree().quit(0 if setup_errors.is_empty() else 1)

func journey() -> void:
	require(sim.import_json(builds[cohort].save),"restore full story cohort")
	reset_combat()
	trial.seed_source.seed=CONFIG.batch_seed
	require(trial.begin_run("forge_tyrant"),"start full story attempt")
	var encounters: Array=[]
	var status:="timeout"
	var total_seconds:=0.0
	while trial.active():
		if trial.state=="boundary": require(trial.continue_floor(),"carry actual life/cooldowns to next floor")
		var stage:int=int(sim.trial_stage().get("index",0))
		var room:Dictionary=trial.arena.dungeon.rooms["%d:0"%stage]
		player.global_position=trial.arena.dungeon.to_global(room.centre+Vector3(0,.7,7))
		player.rotation=Vector3.ZERO
		player.spring_arm.rotation=Vector3.ZERO
		player.camera.rotation=Vector3.ZERO
		player.velocity=Vector3.ZERO
		await settle(4)
		require(trial.enter_room(0),"enter actual story encounter")
		sample={"cohort":cohort,"stage":stage,"elapsed_seconds":0.0,"died":false,"cleared":false,"damage_taken":0.0,"casts":0,"kills":0,"max_live_enemies":0,"minimum_life_fraction":combat.life/combat.max_life,"boss_min_distance_m":999.0,"boss_max_distance_m":0.0,"boss_chase_stalled_seconds":0.0,"starting_life":combat.life}
		seen.clear(); observed.clear(); decision_left=0
		meter.reset_metrics()
		probing=true
		trial.set_process(true); player.set_physics_process(true); combat.set_physics_process(true)
		while sample.elapsed_seconds<90 and not sample.died and trial.state=="fighting": await get_tree().physics_frame
		probing=false
		player.test_walk=Vector2.ZERO
		player.set_physics_process(false); combat.set_physics_process(false); trial.set_process(false)
		sample.cleared=not sample.died and trial.state=="reward"
		sample["ending_life"]=0.0 if sample.died else combat.life
		sample["boss_tells"]=trial.boss_tells
		sample.merge(meter.metrics,true)
		sample.direct_targets=meter.metrics.direct_targets.size()
		encounters.append(sample.duplicate(true))
		total_seconds+=float(sample.elapsed_seconds)
		if not sample.cleared:
			status="death" if sample.died else "timeout"
			break
		trial.skip_offer()
		if not trial.active(): status="complete"
	measured_rows.append({"cohort":cohort,"status":status,"combat_seconds":total_seconds,"encounters":encounters})
	if trial.active(): trial.on_player_died()
	await settle(4)
	print("STORY_ATTEMPT ",cohort," ",status," encounters ",encounters.size())
