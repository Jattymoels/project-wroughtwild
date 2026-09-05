extends Node3D
## Measured combat probe, separate from the forced-resolution lifecycle suite.
## Each case starts a fresh fixed build. Only the sampled pack/boss is fought;
## skipped native stages prepare the boss fixture and are never counted as clears.
const CONFIG = preload("res://tests/trial_balance_config.tres")
var player: WroughtwildPlayer
var combat: PlayerCombat
var sim: WroughtwildSim
var trial: TrialController
var pristine: String
var builds: Dictionary = {}
var rows: Array = []
var setup_errors: Array = []
var probing := false
var sample: Dictionary = {}
var seen: Dictionary = {}
var cohort := ""
var ranged := false
var decision_left := 0.0
var desired_distance := 0.0

func require(ok: bool, label: String) -> void:
	if not ok:
		setup_errors.append(label)
		printerr("FAIL: trial balance setup: ",label)

func settle(count := 3) -> void:
	for i in count: await get_tree().physics_frame

func _ready() -> void:
	process_physics_priority=-50
	Engine.physics_ticks_per_second=CONFIG.physics_ticks
	Engine.max_physics_steps_per_frame=64
	Engine.time_scale=CONFIG.time_scale
	var valley := preload("res://scenes/spike_valley.tscn").instantiate()
	add_child(valley)
	player=valley.get_node("Player")
	combat=player.combat
	sim=combat.sim
	trial=player.trial
	player.placement.set_physics_process(false)
	player.set_physics_process(false)
	combat.set_physics_process(false)
	trial.set_process(false)
	pristine=sim.export_json()
	combat.died.connect(func():
		if probing:
			sample["died"]=true
			sample["minimum_life_fraction"]=0.0)
	combat.hit_taken.connect(func(damage:float,_source:String):
		if probing: sample["damage_taken"]+=damage)
	combat.hit_landed.connect(func(damage:float,_kills:int,_types:PackedStringArray):
		if probing: sample["direct_hit_damage"]+=damage)
	combat.skill_committed.connect(func(_id:StringName):
		if probing: sample["casts"]+=1)
	for class_id in ["ranger","warden","kindler"]:
		for stage in ["starting","prepared","developed"]:
			builds[class_id+"/"+stage]=make_build(class_id,stage)
	var smoke := "--smoke" in OS.get_cmdline_user_args()
	var bosses_only := "--boss-only" in OS.get_cmdline_user_args()
	var diagnostic := "--diagnostic" in OS.get_cmdline_user_args()
	var pack_diagnostic := "--pack-diagnostic" in OS.get_cmdline_user_args()
	for class_id in ["ranger","warden","kindler"]:
		for stage in ["starting","prepared","developed"]:
			cohort=class_id+"/"+stage
			ranged=class_id!="warden"
			for tier in range(1,11):
				if smoke and (tier!=1 or stage!="prepared"): continue
				if diagnostic and (class_id!="ranger" or stage!="starting" or tier!=2): continue
				if pack_diagnostic and (class_id!="ranger" or stage!="starting" or tier!=1): continue
				for phase in ["pack","boss"]:
					if bosses_only and phase!="boss": continue
					if pack_diagnostic and phase!="pack": continue
					await probe(tier,phase)
				print("TRIAL_BALANCE_CASE ",cohort," tier ",tier," completed")
				write_report()
	write_report()
	print("TRIAL_BALANCE_DONE ",rows.size()," encounter samples; ",setup_errors.size()," setup errors")
	Engine.time_scale=1.0
	get_tree().quit(0 if setup_errors.is_empty() else 1)

func craft_and_equip(id:String) -> void:
	var result:Dictionary=sim.craft(id)
	require(bool(result.get("crafted",false)),"craft "+id+": "+str(result))
	if bool(result.get("crafted",false)):
		require(sim.equip_pack_item(sim.pack_items().size()-1),"equip "+id)

func make_build(class_id:String,stage:String) -> Dictionary:
	require(sim.import_json(pristine),"reset fixed build")
	require(player.class_panel.choose(class_id),"choose "+class_id)
	sim.add_station("workbench")
	sim.add_materials({"wood":60,"hide":20})
	if stage=="starting":
		craft_and_equip({"ranger":"simple_bow","warden":"wooden_cudgel","kindler":"wooden_focus"}[class_id])
		craft_and_equip("hide_vest")
	else:
		sim.add_station("forge_basic")
		sim.add_station("forge_improved")
		var data:Dictionary=JSON.parse_string(sim.export_json())
		# Fixture progression states are explicit; equipment still uses real
		# station/ingredient/quality rules rather than injected item numbers.
		data.economy.skill_xp.blacksmithing=225 if stage=="prepared" else 300
		require(sim.import_json(JSON.stringify(data,"",true,true)),"load prepared craft skill")
		sim.add_materials({"iron_ingot":100,"charcoal":100,"bronze_ingot":80,"ember_catalyst":3,"frost_catalyst":3})
		if stage=="developed": sim.record_world_effect("stonecut_blocks")
		var recipe_id:String={"ranger":"hunting_bow","warden":"iron_mace","kindler":"charred_brand"}[class_id]
		if stage=="developed": recipe_id={"ranger":"bronze_longbow","warden":"iron_mace","kindler":"bronze_sceptre"}[class_id]
		craft_and_equip(recipe_id)
		craft_and_equip("iron_chest_armour" if stage=="prepared" else "bronze_mail")
		require(bool(sim.temper_basic().get("applied",false)),"baseline fire preparation")
		var primary:String=String(sim.skill_bar()[0])
		for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer","recipe:workbench_kit","first_kill:stone_husk","world_effect:stonecut_blocks","first_kill:ash_hound"]:
			sim.foundry_event(event)
		require(sim.foundry_place_skill(1,1,primary),"place fixed primary skill")
		require(sim.foundry_place(1,0,"ember"),"place fixed Ember support")
		if stage=="developed":
			require(sim.foundry_place_kind(2,0,"ember_catalyst"),"place fixed Ember mutation")
			require(sim.foundry_place(0,1,"frost"),"place fixed Frost support")
	# Trial access is fixture setup, not a claim that the starting cohort has
	# completed the campaign. Set all cases to the same late-era map context.
	sim.record_world_effect("stonecut_blocks")
	sim.record_world_effect("ash_tide")
	sim.record_world_effect("forge_arc_complete")
	var saved:Dictionary=JSON.parse_string(sim.export_json())
	saved.extra.trial_gate=JSON.stringify({"version":1,"batch_seed":str(CONFIG.batch_seed),"max_tier":10})
	require(sim.import_json(JSON.stringify(saved,"",true,true)),"set fixed tier offer batch")
	return {"save":sim.export_json(),"sheet":sim.derived_stats(),"equipment":sim.equipment(),"bar":Array(sim.skill_bar()),"foundry":sim.foundry().plate}

func reset_combat() -> void:
	combat.restore_life()
	combat.cooldowns.clear()
	for id in combat.skills: combat.cooldowns[id]=0.0
	combat._casts.clear()
	combat._reaction_ready.clear()
	combat._mutation_cache.clear()
	combat._action_contexts.clear()
	combat.clear_verbs()
	combat.clear_train()
	combat.clear_trial_effects()
	combat.invulnerable_left=0
	combat._cast_armour=0
	combat._cast_armour_left=0
	combat._haste_left=0
	combat._dash_left=0
	combat._dash_velocity=Vector3.ZERO
	combat.fight_active=false
	combat.fight_seed_source.seed=CONFIG.batch_seed
	player.test_walk=Vector2.ZERO
	player.velocity=Vector3.ZERO

func probe(tier:int,phase:String) -> void:
	require(sim.import_json(builds[cohort].save),"restore fixed cohort "+cohort)
	reset_combat()
	require(trial.begin_map(tier,CONFIG.offer_index),"enter fixed offer tier "+str(tier))
	if phase=="boss":
		# Establish the final-room fixture without simulating or reporting the
		# four preceding rooms. No boon is accepted during this fixture setup.
		for i in 4:
			trial.arena.dungeon.open_room(i,0)
			sim.trial_begin_room(0)
			sim.trial_resolve_room(true)
			sim.trial_skip_reward()
			trial.arena.dungeon.complete_stage(i)
		trial.show_doors()
	var stage:int=int(sim.trial_stage().get("index",0))
	var room:Dictionary=trial.arena.dungeon.rooms["%d:0"%stage]
	var centre:Vector3=room.centre
	player.global_position=trial.arena.dungeon.to_global(centre+Vector3(0,.7,7))
	player.rotation=Vector3.ZERO
	player.spring_arm.rotation=Vector3.ZERO
	player.camera.rotation=Vector3.ZERO
	await settle(4)
	require(trial.enter_room(0),"start sampled "+phase)
	sample={"cohort":cohort,"tier":tier,"phase":phase,"boss_id":String(sim.boss().id),"conditions":trial.layout.get("conditions",[]),"elapsed_seconds":0.0,"died":false,"cleared":false,"damage_taken":0.0,"direct_hit_damage":0.0,"casts":0,"kills":0,"max_live_enemies":0,"boss_tells":0,"minimum_life_fraction":1.0,"remaining_enemy_life":0.0,"boss_min_distance_m":999.0,"boss_max_distance_m":0.0,"boss_chase_stalled_seconds":0.0}
	seen.clear()
	decision_left=0
	probing=true
	trial.set_process(true)
	player.set_physics_process(true)
	combat.set_physics_process(true)
	while float(sample.elapsed_seconds)<CONFIG.exposure_seconds and not bool(sample.died) and trial.state=="fighting":
		await get_tree().physics_frame
	sample.cleared=not bool(sample.died) and trial.state=="reward"
	sample.boss_tells=trial.boss_tells
	if not sample.died:
		var remaining:=0.0
		for enemy in trial.trial_enemies(): remaining+=enemy.life
		sample.remaining_enemy_life=remaining
	require(int(sample.casts)>0,"sample policy actually casts "+cohort+" "+phase)
	rows.append(sample.duplicate(true))
	probing=false
	player.test_walk=Vector2.ZERO
	player.set_physics_process(false)
	combat.set_physics_process(false)
	trial.set_process(false)
	if trial.active(): trial.on_player_died()
	await settle(4)

func _physics_process(delta:float) -> void:
	if not probing: return
	sample.elapsed_seconds+=delta
	sample.minimum_life_fraction=minf(float(sample.minimum_life_fraction),combat.life/maxf(1,combat.max_life))
	var enemies:Array=trial.trial_enemies()
	if not trial.arena.contains(player.global_position):
		sample["floor_rescue_frames"]=int(sample.get("floor_rescue_frames",0))+1
		if not sample.has("first_floor_rescue_position"):
			sample["first_floor_rescue_position"]=[player.global_position.x,player.global_position.y,player.global_position.z]
	if not sample.died:
		var remaining:=0.0
		for enemy in enemies: remaining+=enemy.life
		sample.remaining_enemy_life=remaining
	sample.max_live_enemies=maxi(sample.max_live_enemies,enemies.size())
	for enemy in enemies:
		if enemy is Boss:
			var distance:float=player.global_position.distance_to(enemy.global_position)
			sample.boss_min_distance_m=minf(sample.boss_min_distance_m,distance)
			sample.boss_max_distance_m=maxf(sample.boss_max_distance_m,distance)
			if enemy.state=="chase" and enemy._recovery_left<=0 and not enemy.is_frozen() and not enemy.staggered() and distance>enemy.attack_range and Vector2(enemy.velocity.x,enemy.velocity.z).length()<.05:
				sample.boss_chase_stalled_seconds+=delta
				if not sample.has("stall_snapshot") and float(sample.boss_chase_stalled_seconds)>5:
					var path:Array=[]
					for point in enemy._trial_path.slice(0,3): path.append([point.x,point.y,point.z])
					sample["stall_snapshot"]={"boss":[enemy.global_position.x,enemy.global_position.y,enemy.global_position.z],"player":[player.global_position.x,player.global_position.y,player.global_position.z],"state":enemy.state,"velocity":[enemy.velocity.x,enemy.velocity.y,enemy.velocity.z],"on_wall":enemy.is_on_wall(),"on_floor":enemy.is_on_floor(),"path":path,"path_refresh_left":enemy._trial_path_left,"breath_timer":enemy._breath_timer,"recovery":enemy._recovery_left}
		if not seen.has(enemy.get_instance_id()):
			seen[enemy.get_instance_id()]=true
			enemy.died.connect(func(_e:Enemy):
				if probing: sample.kills+=1)
	decision_left-=delta
	if decision_left>0 or enemies.is_empty(): return
	decision_left=CONFIG.decision_seconds
	var target:Enemy=enemies[0]
	var score:float=INF
	for enemy in enemies:
		var candidate:float=player.global_position.distance_to(enemy.global_position)
		if enemy.wards() or enemy.verb in ["ward","kindle"]: candidate*=.45
		if enemy is Boss and enemies.size()>1: candidate+=40
		if candidate<score: score=candidate; target=enemy
	var to:Vector3=target.global_position-player.global_position
	to.y=0
	if to.length()<.01: return
	player.look_at(player.global_position+to)
	player.camera.look_at(target.global_position+Vector3.UP*.85)
	var forward:Vector3=to.normalized()
	var lateral:=Vector3(-forward.z,0,forward.x)
	var move:=Vector3.ZERO
	desired_distance=CONFIG.ranged_distance if ranged else CONFIG.melee_distance
	if to.length()>desired_distance+.5: move+=forward
	elif to.length()<desired_distance-.5: move-=forward
	move+=lateral*.35
	var danger:=false
	for hazard in trial._hazards():
		if player.global_position.distance_to(hazard.global_position)<4.2:
			var away:Vector3=player.global_position-hazard.global_position
			away.y=0
			move+=away.normalized()*2
			danger=true
	if target is Boss and target.state=="inhale":
		move=lateral
		danger=true
	if danger and combat.is_ready(&"prototype_dash"):
		var facing:=player.rotation.y
		player.look_at(player.global_position+move.normalized())
		combat.use_dash()
		player.rotation.y=facing
		player.camera.look_at(target.global_position+Vector3.UP*.85)
	var local:Vector3=player.global_basis.inverse()*move.normalized()
	player.test_walk=Vector2(local.x,local.z)
	# Use only the permanent class bar, at real cooldowns and actual range.
	for skill in sim.skill_bar():
		var id:=StringName(skill)
		var definition:Dictionary=combat.skills.get(id,{})
		var delivery:String=definition.get("delivery","")
		if delivery=="dash": continue
		if delivery in ["cone","strike"] and to.length()>combat.strike_reach(id): continue
		if combat.use_skill(id): break

func write_report() -> void:
	var build_views:Dictionary={}
	for id in builds:
		build_views[id]=builds[id].duplicate(true)
		build_views[id].erase("save")
	var report={"purpose":"Actual fixed-build encounter samples. No forced enemy kills. Skipped route stages only set up the isolated boss fixture; their elapsed time and rewards do not count as combat evidence.","limitations":"One deterministic gate batch/offer per tier, scripted movement and skill policy, one pack and one boss encounter per cohort/tier. Does not certify whole-run duration, all condition combinations or human balance. Higher tiers unverified.","physics_step_seconds":CONFIG.time_scale/CONFIG.physics_ticks,"exposure_limit_seconds":CONFIG.exposure_seconds,"batch_seed":CONFIG.batch_seed,"offer_index":CONFIG.offer_index,"builds":build_views,"samples":rows,"setup_errors":setup_errors}
	var suffix:="-diagnostic" if "--diagnostic" in OS.get_cmdline_user_args() else "-pack-diagnostic" if "--pack-diagnostic" in OS.get_cmdline_user_args() else ""
	var file:=FileAccess.open("res://../build/intensives/trial-balance%s.json"%suffix,FileAccess.WRITE)
	if file!=null: file.store_string(JSON.stringify(report,"\t",true,true)); file.close()
