extends "res://tests/power_progression_review.gd"
## Controlled upper-bound throughput, no incoming damage or hostile kindlers.
## Real cooldowns, packets, projectiles, burn/bleed and terminal effects.
var targets: Array=[]
var controlled:=false
var clock:=0.0
var first_kill:=-1.0
var cast_count:=0

func _ready() -> void:
	initialize()
	combat.skill_committed.connect(func(_id:StringName):
		if controlled: cast_count+=1)
	await settle(4)
	for class_id in ["warden","ranger","kindler"]:
		for stage in ["starting","prepared","developed"]:
			for pattern in ["plain","clear_ingots","clear","single_ingots","single","recovery_ingots","recovery"]:
				if stage!="starting" and (pattern=="plain" or pattern.ends_with("_ingots")): continue
				cohort=class_id+"/"+stage+"/"+pattern
				builds[cohort]=fixed_build(class_id,stage,pattern)
				for count in [1,6]: await controlled_probe(count)
	var file:=FileAccess.open("res://../build/intensives/progression-controlled.json",FileAccess.WRITE)
	require(file!=null,"controlled report")
	if file!=null:
		file.store_string(JSON.stringify({"samples":measured_rows,"setup_errors":setup_errors,"limits":"Stationary ordinary whelps, native life/resistance, six-target 1.2 m grid or one target. Player walks are replaced by a fixed 1.7 m attack position at each decision. No incoming damage; starts at 20 life to expose healing. Native skills/cooldowns, projectiles and statuses run at 30 simulated steps/s, 20-second budget. Upper bound on perfect contact, not live balance or boss difficulty. Secondary damage excludes enemy self-burning because these whelps cannot kindle allies."},"\t",true,true))
	Engine.time_scale=1
	print("CONTROLLED_REVIEW ",measured_rows.size()," samples; ",setup_errors.size()," setup errors")
	get_tree().quit(0 if setup_errors.is_empty() else 1)

func controlled_probe(count: int) -> void:
	trial._cancel_transients()
	for node in get_tree().get_nodes_in_group("enemies"): node.queue_free()
	await settle(4)
	require(sim.import_json(builds[cohort].save),"restore controlled gear/plate")
	reset_combat()
	sim.begin_fight(CONFIG.batch_seed)
	combat.fight_active=true
	combat.life=20
	meter.reset_metrics()
	meter.primary_only=builds[cohort].primary
	player.global_position=Vector3(0,300,0)
	player.rotation=Vector3.ZERO
	player.spring_arm.rotation=Vector3.ZERO
	player.camera.rotation=Vector3.ZERO
	targets=[]
	for i in count:
		var enemy:=Enemy.spawn(self,&"ember_whelp",Vector3((i%3)*1.2,300,-2-floori(i/3.0)*1.2))
		enemy.set_physics_process(false)
		targets.append(enemy)
		enemy.died.connect(func(_enemy: Enemy):
			if controlled and first_kill<0: first_kill=clock)
	clock=0; first_kill=-1; cast_count=0; decision_left=0
	combat.set_physics_process(true)
	controlled=true
	while clock<20 and not live_targets().is_empty(): await get_tree().physics_frame
	controlled=false
	combat.set_physics_process(false)
	var total:=0.0
	var damaged:=0
	for target in targets:
		var remaining: float=target.life if is_instance_valid(target) else 0.0
		var loss: float=float(sim.enemy("ember_whelp").max_life)-remaining
		total+=loss
		if loss>0: damaged+=1
	var row: Dictionary=meter.metrics.duplicate(true)
	row.direct_targets=meter.metrics.direct_targets.size()
	row.merge({"cohort":cohort,"targets":count,"casts":cast_count,"cleared":live_targets().is_empty(),"elapsed_seconds":clock,"first_kill_seconds":first_kill,"effective_total_damage":total,"secondary_damage":maxf(0,total-float(row.direct_damage)),"damaged_targets":damaged,"cooldown_seconds":sim.skill_cooldown_seconds(builds[cohort].primary),"life":combat.life},true)
	measured_rows.append(row)
	print("CONTROLLED_CASE ",cohort," targets ",count)

func live_targets() -> Array:
	return targets.filter(func(target): return is_instance_valid(target) and target.life>0)

func _physics_process(delta: float) -> void:
	if not controlled: return
	clock+=delta
	for enemy in live_targets(): enemy._tick_statuses(delta)
	decision_left-=delta
	var living:=live_targets()
	if living.is_empty() or decision_left>0: return
	decision_left=CONFIG.decision_seconds
	var target: Enemy=living[0]
	player.global_position=target.global_position+Vector3(0,0,1.7)
	player.look_at(target.global_position)
	player.camera.look_at(target.global_position+Vector3.UP*.65)
	combat.use_skill(StringName(builds[cohort].primary))
