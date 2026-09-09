extends "res://tests/trial_balance.gd"
## Live configured pack/boss samples. Earlier stages are forced only to establish
## the isolated boss fixture. No immunity, forced damage or lucky build is used.
var pressure:=""

func _ready() -> void:
	process_physics_priority=-50
	Engine.physics_ticks_per_second=60
	Engine.max_physics_steps_per_frame=64
	var valley:=preload("res://scenes/spike_valley.tscn").instantiate()
	add_child(valley)
	player=valley.get_node("Player");combat=player.combat;sim=combat.sim;trial=player.trial
	player.placement.set_physics_process(false);player.set_physics_process(false)
	combat.set_physics_process(false);trial.set_process(false)
	pristine=preload("res://tests/central_fixture.gd").ready_rules(sim,sim.export_json())
	require(not pristine.is_empty(),"synthetic campaign access uses both native ledgers")
	combat.died.connect(func():
		if probing:sample.died=true;sample.minimum_life_fraction=0.0)
	combat.hit_taken.connect(func(damage:float,_source:String):
		if probing:sample.damage_taken+=damage)
	combat.hit_landed.connect(func(damage:float,_kills:int,_types:PackedStringArray):
		if probing:sample.direct_hit_damage+=damage)
	combat.skill_committed.connect(func(_id:StringName):
		if probing:sample.casts+=1)
	for class_id in ["warden","ranger","kindler"]:
		builds[class_id+"/starting"]=make_build(class_id,"starting")
	for class_id in ["warden","ranger","kindler"]:
		cohort=class_id+"/starting";ranged=class_id!="warden"
		for selected in ["crossfire","relentless_boss"]:
			pressure=selected
			for phase in ["pack","boss"]:await configured_probe(phase)
	write_report()
	print("LF7_COMBAT ",rows.size()," live samples, ",setup_errors.size()," setup failures")
	get_tree().quit(0 if setup_errors.is_empty() else 1)

func configured_probe(phase:String) -> void:
	require(sim.import_json(builds[cohort].save),"restore ordinary paid build")
	reset_combat()
	var candidates:=sim.trial_map_offers(1,pressure)
	var slot:=-1
	for i in candidates.size():
		if candidates[i].available:slot=i;break
	if slot<0:require(false,"compatible fixed offer");return
	var offer:Dictionary=candidates[slot]
	require(trial.begin_map(1,slot,pressure,String(offer.id)),"enter actual configured offer")
	if phase=="boss":
		for i in 4:
			arena_open(i)
			sim.trial_begin_room(0);sim.trial_resolve_room(true);sim.trial_skip_reward()
			trial.arena.dungeon.complete_stage(i)
		trial.show_doors()
	var stage:int=sim.trial_stage().index
	var room:Dictionary=trial.arena.dungeon.rooms["%d:0"%stage]
	player.global_position=trial.arena.dungeon.to_global(room.centre+Vector3(0,.7,7))
	player.rotation=Vector3.ZERO;player.spring_arm.rotation=Vector3.ZERO
	await settle(4)
	require(trial.enter_room(0),"start configured "+phase)
	sample={"cohort":cohort,"pressure":pressure,"offer_id":offer.id,"phase":phase,"boss_id":sim.boss().id,"conditions":trial.layout.conditions,"elapsed_seconds":0.0,"died":false,"cleared":false,"damage_taken":0.0,"direct_hit_damage":0.0,"casts":0,"kills":0,"max_live_enemies":0,"max_major_hazards":0,"boss_tells":0,"minimum_life_fraction":1.0,"remaining_enemy_life":0.0,"boss_min_distance_m":999.0,"boss_max_distance_m":0.0,"boss_chase_stalled_seconds":0.0}
	seen.clear();decision_left=0;probing=true
	trial.set_process(true);player.set_physics_process(true);combat.set_physics_process(true)
	while float(sample.elapsed_seconds)<180 && not sample.died && trial.state=="fighting":
		sample.max_major_hazards=maxi(sample.max_major_hazards,trial._hazards().size())
		await get_tree().physics_frame
	sample.cleared=not sample.died && trial.state=="reward";sample.boss_tells=trial.boss_tells
	require(sample.casts>0,"actual casts were committed")
	require(sample.max_live_enemies<=24 && sample.max_major_hazards<=2,"configured live population/hazard caps")
	rows.append(sample.duplicate(true))
	print("LF7_FIGHT ",cohort," ",pressure," ",phase," clear=",sample.cleared," died=",sample.died," seconds=",sample.elapsed_seconds," damage=",sample.damage_taken," casts=",sample.casts)
	probing=false;player.test_walk=Vector2.ZERO
	player.set_physics_process(false);combat.set_physics_process(false);trial.set_process(false)
	if trial.active():trial.on_player_died()
	await settle(4)

func arena_open(stage:int) -> void:
	trial.arena.dungeon.open_room(stage,0)

func write_report() -> void:
	var file:=FileAccess.open("res://../build/lf7/combat.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"purpose":"Live configured pack and boss fights at 60 Hz, ordinary paid starter weapon and hide vest, no Foundry or Catalyst. Synthetic campaign access and supplied recipe inputs. Four earlier rooms forced only for isolated boss setup. State-reading movement bot is not human balance acceptance.","samples":rows,"setup_errors":setup_errors},"  ",true,true));file.close()
