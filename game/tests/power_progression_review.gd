extends "res://tests/trial_balance.gd"
## Paired legal arrangements, using production gear, damage, enemies and bot.
## Fixture resources/unlocks are explicit; no owner save or gear is imported.
var meter: Node
var observed := {}
var measured_rows: Array=[]
var boundary := {}
var gear_stage := "starting"
var gear_class := "warden"
const PATTERNS={"clear":["ember","reach","ember_catalyst"],"single":["edge","haste","ember_catalyst"],"recovery":["vigour","edge","sipping_marrow"]}

func initialize() -> void:
	process_physics_priority=-50
	Engine.physics_ticks_per_second=CONFIG.physics_ticks
	Engine.max_physics_steps_per_frame=64
	Engine.time_scale=CONFIG.time_scale
	var valley:=preload("res://scenes/spike_valley.tscn").instantiate()
	valley.get_node("Player/Combat").set_script(preload("res://tests/progression_meter.gd"))
	add_child(valley)
	player=valley.get_node("Player")
	combat=player.combat
	meter=combat
	sim=combat.sim
	trial=player.trial
	player.placement.set_physics_process(false)
	player.set_physics_process(false)
	combat.set_physics_process(false)
	trial.set_process(false)
	pristine=sim.export_json()
	combat.died.connect(func():
		if probing: sample.died=true; sample.minimum_life_fraction=0.0)
	combat.hit_taken.connect(func(damage:float,_source:String):
		if probing: sample.damage_taken+=damage)
	combat.skill_committed.connect(func(_id:StringName):
		if probing: sample.casts+=1)

func fixed_build(class_id: String, stage: String, pattern: String) -> Dictionary:
	gear_stage=stage
	gear_class=class_id
	var result:=make_build(class_id,stage)
	for piece in sim.foundry().plate: require(sim.foundry_remove(piece.row,piece.col),"remove benchmark support")
	# Poor-gear causal cases are unarmoured, with the same 100 starting life.
	if stage=="starting":
		require(sim.unequip("chest"),"remove starter armour")
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer","recipe:workbench_kit","first_kill:stone_husk","world_effect:stonecut_blocks","first_kill:ash_hound"]: sim.foundry_event(event)
	var primary:=String(sim.skill_bar()[0])
	require(sim.foundry_place_skill(1,1,primary),"place paired primary")
	if pattern!="plain":
		var key:=pattern.trim_suffix("_ingots")
		var pieces: Array=PATTERNS[key]
		sim.add_material(pieces[2],1)
		require(sim.foundry_place(1,0,pieces[0]) and sim.foundry_place(2,1,pieces[1]),"two iron ingots "+pattern)
		if not pattern.ends_with("_ingots"): require(sim.foundry_place_kind(2,0,pieces[2]),"one compatible Kind "+pattern)
	result={"save":sim.export_json(),"sheet":sim.derived_stats(),"equipment":sim.equipment(),"bar":Array(sim.skill_bar()),"foundry":sim.foundry().plate,"mutation":sim.skill_mutation(primary),"primary":primary}
	return result

func craft_and_equip(id: String) -> void:
	if gear_stage=="starting":
		super.craft_and_equip(id)
		return
	# Real quality/potency investments, not the old benchmark's Rough,
	# unaimed crafts. Explicit fixture progression/materials still go through
	# native preview, payment, rolling, capacity and equipment ownership.
	var saved: Dictionary=JSON.parse_string(sim.export_json())
	saved.economy.skill_xp.blacksmithing=1000
	require(sim.import_json(JSON.stringify(saved,"",true,true)),"experienced graded smith fixture")
	if gear_stage=="developed":
		sim.record_world_effect("stonecut_blocks")
		sim.record_world_effect("ash_tide")
	var quality:=2 if gear_stage=="prepared" else 3
	var potency:="stable_" if quality==2 else "potent_"
	var recipe:=id
	if id=="bronze_sceptre": recipe="charred_brand" # Keep investment relevant to the unchanged fire skill.
	var kind: String=potency+({"warden":"impact_catalyst","ranger":"piercing_catalyst","kindler":"ember_catalyst"}[gear_class] if id not in ["iron_chest_armour","bronze_mail"] else "vanguard")
	sim.add_materials({"sound_iron_ingot":4,"excellent_iron_ingot":4})
	sim.add_material(kind,1)
	var result: Dictionary=sim.craft(recipe,false,kind,quality)
	require(bool(result.get("crafted",false)),"graded aimed craft "+recipe+": "+str(result))
	if bool(result.get("crafted",false)):
		require(sim.equip_pack_item(sim.pack_items().size()-1),"equip graded "+recipe)

func _ready() -> void:
	initialize()
	await settle(4)
	await recovery_boundary()
	if "--boundary-only" not in OS.get_cmdline_user_args():
		for class_id in ["warden","ranger","kindler"]:
			for stage in ["starting","prepared","developed"]:
				for pattern in ["plain","clear_ingots","clear","single_ingots","single","recovery_ingots","recovery"]:
					if stage!="starting" and (pattern=="plain" or pattern.ends_with("_ingots")): continue
					cohort=class_id+"/"+stage+"/"+pattern
					ranged=class_id!="warden"
					builds[cohort]=fixed_build(class_id,stage,pattern)
					meter.primary_only=builds[cohort].primary
					for phase in ["pack","boss"]:
						meter.reset_metrics()
						observed.clear()
						await probe(1,phase)
						var row: Dictionary=rows.back().duplicate(true)
						row.merge(meter.metrics,true)
						row.direct_targets=meter.metrics.direct_targets.size()
						var total:=0.0
						var damaged:=0
						for target in observed.values():
							total+=target.initial-target.remaining
							if target.remaining<target.initial: damaged+=1
						row["effective_total_damage"]=total
						row["secondary_damage"]=maxf(0,total-float(row.direct_damage))
						row["damaged_targets"]=damaged
						measured_rows.append(row)
					write_power_report()
					print("POWER_CASE ",cohort)
	write_power_report()
	Engine.time_scale=1
	print("POWER_REVIEW ",measured_rows.size()," samples; ",setup_errors.size()," setup errors; boundary ",boundary)
	get_tree().quit(0 if setup_errors.is_empty() else 1)

func _physics_process(delta: float) -> void:
	if probing:
		for enemy in trial.trial_enemies():
			var key:=str(enemy.get_instance_id())
			if not observed.has(key):
				observed[key]={"initial":enemy.max_life,"remaining":enemy.life}
				enemy.died.connect(func(_enemy: Enemy):
					if probing and observed.has(key): observed[key].remaining=0.0)
			observed[key].remaining=maxf(0,enemy.life)
	super._physics_process(delta)

func recovery_boundary() -> void:
	fixed_build("warden","starting","recovery")
	reset_combat()
	meter.reset_metrics()
	combat.life=20
	var victim:=Enemy.spawn(self,&"ember_whelp",player.global_position+Vector3(0,0,-2))
	victim.set_physics_process(false)
	victim.life=1
	var id:=StringName(sim.skill_bar()[0])
	var first:=combat.deal(victim,id,false)
	var before:=combat.life
	var again:=combat.deal(victim,id,false)
	boundary={"first_kill":first.kill,"repeat_damage":again.damage,"repeat_kill":again.kill,"repeat_healing":combat.life-before}
	var fresh:=Enemy.spawn(self,&"ember_whelp",player.global_position+Vector3(0,0,-3))
	fresh.set_physics_process(false)
	fresh.life=1
	var new_before:=combat.life
	var new_hit:=combat.deal(fresh,id,false)
	require(new_hit.kill and combat.life>new_before,"a different live kill still pays normal hit/kill recovery")
	if "--expect-fixed" in OS.get_cmdline_user_args():
		require(first.kill and not again.kill and again.damage==0 and boundary.repeat_healing==0,"dead-target replay cannot pay or report a second kill")
	await settle(4)
	# A real pre-payload Flashfire can kill before the ordinary packet. It
	# must retain its burn-release payoff without pretending to be a direct kill.
	fixed_build("warden","starting","single")
	sim.add_material("iron_ingot",1)
	require(sim.foundry_remove(1,0) and sim.foundry_place(1,0,"vigour"),"legal Flashfire plus kill-recovery arrangement")
	reset_combat()
	combat.life=20
	var burning:=Enemy.spawn(self,&"ember_whelp",player.global_position+Vector3(0,0,-2))
	burning.set_physics_process(false)
	burning.apply_ignite(100)
	burning.life=1
	var pre_payload:=combat.life
	combat.apply_payload(burning,id,false,1,false,{"practice_allowed":true})
	boundary["reaction_killed"]=burning.life<=0
	var reaction_hit:=combat.deal(burning,id,false)
	boundary["reaction_direct_kill"]=reaction_hit.kill
	boundary["reaction_kill_healing"]=combat.life-pre_payload
	require(boundary.reaction_killed,"real Flashfire consumes existing burn to kill")
	if "--expect-fixed" in OS.get_cmdline_user_args():
		require(not reaction_hit.kill and boundary.reaction_kill_healing==0,"terminal reaction cannot claim direct kill recovery")
	await settle(4)

func write_power_report() -> void:
	# The fast regression is part of the ordinary suite and needs no artifact
	# directory. Full measurement reports belong to the isolated review helper.
	if "--boundary-only" in OS.get_cmdline_user_args(): return
	var views: Dictionary={}
	for key in builds:
		views[key]=builds[key].duplicate(true)
		views[key].erase("save")
	var report={"purpose":"Representative, primary-skill-only paired T1 pack/boss comparisons. Same route, native offer, life and class skill within each gear stage. No temporary boons. Starting has a wooden weapon and no armour; prepared/developed use native Sound/Stable and Excellent/Potent aimed crafts. Exact owner build unknown.","limits":"Scripted movement, one seed, 30-second encounter limit. Direct effective damage observes deal; selected patterns do not use Brittle/shatter. Secondary is residual enemy life loss, including enemy kindlers burning their own allies: use progression_controlled for isolated player attribution. Trigger counter is direct payload threshold events; propagation is included in coverage. Full packet overkill is excluded. No claim of human difficulty or full-run duration.","builds":views,"samples":measured_rows,"recovery_boundary":boundary,"setup_errors":setup_errors}
	var file:=FileAccess.open("res://../build/intensives/power-progression.json",FileAccess.WRITE)
	require(file!=null,"open power report")
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
