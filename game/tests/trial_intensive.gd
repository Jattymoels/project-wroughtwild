extends Node3D
## Spatial/lifecycle regression suite. Forced kills verify ownership and economy;
## they are deliberately separate from actual-build combat measurements.
const SAVE_PATH="res://../build/intensives/trial-checkpoint.json"
var player: WroughtwildPlayer
var sim: WroughtwildSim
var trial: TrialController
var checks:=0
var failures:=0
var boon_count:=0
var branches:=0
var tested_navigation:=false
var tested_boss_navigation:=false
var checked_floor_edges:Dictionary={}
var baseline_economy: String
var world_drop_snapshot: Dictionary

func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: trial intensive: ",label)

func settle(frames:=3)->void:
	for i in frames: await get_tree().physics_frame

func _ready()->void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_PATH).get_base_dir())
	var valley:=preload("res://scenes/spike_valley.tscn").instantiate()
	add_child(valley)
	player=valley.get_node("Player")
	sim=player.inventory.get_sim()
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	trial=player.trial
	trial.seed_source.seed=7147
	trial.set_process(false)
	await settle()
	baseline_economy=sim.export_json()
	prepare_world_drops()
	world_drop_snapshot=WorldDrops.capture(player.world_root())
	check(sim.trial_story_runs().size()==3,"three story identities")
	check(not sim.trial_map_progress().get("available",true),"repeatable gate locked before capstone")
	var prepared := identity_cleanup_probes()
	check(trial.begin_run("forge_tyrant"),"live Tyrant starts")
	check(WorldDrops.capture(player.world_root())==world_drop_snapshot,"trial entry keeps uncollected world material, gear, page and death bundle")
	check(prepared.all(func(effect): return effect.is_queued_for_deletion()),"trial entry cancels all four overworld identity groups")
	check(trial.spatial and trial.built_floor==0,"live gate uses a traversable first floor")
	await story(true)
	check(not trial.active(),"Tyrant completion extracts")
	check(WorldDrops.capture(player.world_root())==world_drop_snapshot,"trial extraction neither banks world drops nor materialises the native run ledger as pickups")
	WorldDrops.restore(player.world_root(),{"version":1,"pickups":[],"bundles":[]})
	check(boon_count==4 and branches>=2,"four blessings and two route decisions")
	check(not sim.world_effect_active("stonecut_blocks"),"boss keeps curio landmark transition")
	check(sim.set_curio("hill_cairn"),"Tyrant heart activates existing hill cairn")
	if not sim.world_effect_active("stonecut_blocks"): sim.record_world_effect("stonecut_blocks")
	check(trial.begin_run("deep_forge"),"Deeper Forge starts after landmark")
	await story(false)
	check(sim.set_curio("drowned_altar"),"Warden eye activates existing drowned altar")
	if not sim.world_effect_active("ash_tide"): sim.record_world_effect("ash_tide")
	check(trial.begin_run("forge_capstone"),"Ash Tide capstone starts")
	await story(false)
	check(sim.world_effect_active("forge_arc_complete"),"capstone records distinct arc flag")
	check(bool(sim.trial_map_progress().get("available",false)),"capstone opens repeatables")
	var first_offers: Array=sim.trial_map_offers(1)
	check(first_offers.size()==3,"three repeatable offers")
	sim.trial_map_offers(2)
	check(sim.trial_map_offers(1)==first_offers,"switching tiers cannot reroll offers")
	var gate_save:=sim.export_json()
	check(sim.import_json(gate_save) and sim.trial_map_offers(1)==first_offers,"offer batch survives reload")
	check(trial.begin_map(1,0),"selected map starts")
	check(int(trial.layout.get("floor_count",0))==1,"repeatable route has one floor")
	trial.on_player_died()
	check(int(sim.trial_map_progress().get("max_tier",0))==1,"failure retains access without unlocking next")
	check(sim.trial_map_offers(1)!=first_offers,"successful entry advances offer batch once")
	check(trial.begin_map(1,1),"another map can start after failure")
	boon_count=0
	var guard:=0
	while trial.active() and guard<16:
		guard+=1
		await clear_next()
	check(not trial.active() and boon_count==2,"repeatable completes with two boon opportunities")
	check(int(sim.trial_map_progress().get("max_tier",0))==2,"tier one clear unlocks tier two")
	check(not SaveManager.new().apply(player,{"schema_version":2,"world_profile":"unknown"}),"unknown generation profile rejected before restore")
	atomic_save_checks()
	print("TRIAL_INTENSIVE: ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func story(test_suspend:bool)->void:
	boon_count=0; branches=0
	var guard:=0
	while trial.active() and guard<12:
		guard+=1
		if trial.state=="boundary":
			check(trial.completed_encounters==4,"major encounter precedes floor transition")
			if test_suspend:
				await suspension()
				test_suspend=false
			var life:=player.combat.life
			check(trial.continue_floor(),"cleared lift continues")
			check(player.combat.life==life,"floor transition grants no healing")
			check(trial.built_floor==1,"second floor physically replaces first")
			await settle()
		else: await clear_next()
	check(guard<=10,"mandatory route completes independently of optional rooms")

func clear_next()->void:
	if not trial.active(): return
	check(trial.state=="exploring","progression returns to physical exploration")
	var stage: Dictionary=sim.trial_stage()
	var choices: Array=stage.get("choices",[])
	if choices.is_empty(): check(false,"reachable next route exists"); trial.on_player_died(); return
	if choices.size()>1: branches+=1
	var choice:=mini(int(stage.get("index",0))%2,choices.size()-1)
	var room: Dictionary=trial.arena.dungeon.rooms.get("%d:%d"%[int(stage["index"]),choice],{})
	check(not room.is_empty(),"authored room corresponds to selected choice")
	if room.is_empty(): trial.on_player_died(); return
	var door: TrialFixture=room["door"]
	player.global_position=door.global_position+Vector3(0,.6,1.5)
	trial.interact_fixture(door)
	check(trial.state=="fighting","physical route seal starts only its encounter")
	await settle()
	for frame in 120:
		var dungeon:=trial.arena.dungeon
		if NavigationServer3D.region_get_iteration_id(dungeon.region.get_rid())>0 and NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)>1: break
		await settle(1)
	var floor_key:="%s:%d"%[trial.layout.run_id,trial.built_floor]
	if not checked_floor_edges.has(floor_key):
		checked_floor_edges[floor_key]=true
		check_floor_edges()
	if not tested_navigation:
		tested_navigation=true
		await navigation(room)
	var route_path:=trial.arena.dungeon.path(trial.arena.dungeon.to_global(trial.arena.dungeon.entry),trial.arena.dungeon.to_global(room.reward_at))
	check(route_path.size()>1 and route_path[-1].distance_to(trial.arena.dungeon.to_global(room.reward_at))<2,"%s floor %s stage %s %s reward has a connected route: %s"%[trial.layout.run_id,trial.built_floor,stage.index,room.module,route_path])
	var max_alive:=trial.trial_enemies().size()
	var rounds:=0
	while (not trial.trial_enemies().is_empty() or not trial.wave_queue.is_empty()) and rounds<30:
		rounds+=1
		for enemy in trial.trial_enemies():
			enemy.set_physics_process(false)
			if enemy is Boss: await boss_checks(enemy)
			enemy.take_damage(1000000000)
		for hazard in trial._hazards(): hazard.cancel()
		trial._tick_spatial(1)
		max_alive=maxi(max_alive,trial.trial_enemies().size())
		await settle(1)
	check(max_alive<=24,"concurrent population remains bounded")
	for hazard in trial._hazards(): hazard.cancel()
	trial._process(0)
	check(trial.state=="reward","local completion exposes a physical offering")
	var reward: TrialFixture=trial.arena.dungeon.reward
	player.global_position=reward.global_position+Vector3(0,.6,1.5)
	trial.interact_fixture(reward)
	if not trial.current_offer.is_empty():
		check(trial.current_offer.size()==3,"blessing offers three compatible choices")
		boon_count+=1
		trial.accept_boon(String(trial.current_offer[0]["id"]))
	elif trial.state=="reward" and trial.active(): trial.skip_offer()
	await settle(1)

func navigation(room:Dictionary)->void:
	var dungeon:=trial.arena.dungeon
	for frame in 120:
		if NavigationServer3D.region_get_iteration_id(dungeon.region.get_rid())>0 and NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)>1: break
		await settle(1)
	check(NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)>0,"navigation map becomes ready")
	var destination: Vector3=dungeon.to_global(room["spawn_at"])
	var path:=dungeon.path(player.global_position,destination)
	check(path.size()>=2 and path[-1].distance_to(destination)<2,"Godot navigation crosses doorway into room: %s -> %s = %s"%[player.global_position,destination,path])
	var secret_path:=dungeon.path(dungeon.to_global(dungeon.entry),dungeon.secret.global_position)
	check(secret_path.size()>=2,"secret store has a connected route from entry: %s"%[secret_path])
	if secret_path.size()>=2:
		# Solid fixtures now occupy navigation clearance. Prove that the path
		# ends at a usable place rather than demanding entry into that body.
		var saved_pose:=player.global_transform
		var saved_view:=player.camera.global_transform
		var capsule:=player.get_node("CollisionShape3D").shape as CapsuleShape3D
		player.global_position=secret_path[-1]+Vector3.UP*capsule.height*.5
		player.camera.look_at(dungeon.secret.global_position+Vector3.UP*1.05)
		check(player.aim_probe().get("target")==dungeon.secret,"real interaction ray reaches secret from its clear navigation endpoint")
		player.global_transform=saved_pose
		player.camera.global_transform=saved_view
	var enemy: Enemy=trial.trial_enemies()[0]
	for other in trial.trial_enemies(): other.set_physics_process(false)
	player.global_position=dungeon.to_global(room["centre"]+Vector3(5,.6,8))
	enemy.global_position=dungeon.to_global(room["centre"]+Vector3(-6,.6,-8))
	var start:=enemy.global_position.distance_to(player.global_position)
	player.combat.invulnerable_left=100
	enemy.set_physics_process(true)
	await settle(240)
	check(enemy.global_position.distance_to(player.global_position)<start-5,"enemy negotiates room cover in live physics")
	enemy.set_physics_process(false)
	player.combat.invulnerable_left=0
	var before_recovery:Vector3=dungeon.to_global(room.centre+Vector3(-13,-4,0))
	player.global_position=before_recovery
	trial._keep_everyone_in_the_room()
	check(dungeon.contains_world(player.global_position) and player.global_position.distance_to(before_recovery)<10,"floor rescue returns to nearby clear ground, not the entrance")
	var config:=trial.rules.duplicate(true)
	config["hazard_telegraph_seconds"]=1.0
	var hazard:=trial.spawn_hazard(player.global_position,config)
	hazard.set_physics_process(false)
	var life:=player.combat.life
	hazard.advance(.5)
	check(player.combat.life==life,"hazard warning cannot deal early damage")
	hazard.advance(.6)
	check(player.combat.life<life,"remaining on active warning causes typed damage")
	check(trial.spawn_hazard(player.global_position,config)!=null and trial.spawn_hazard(player.global_position,config)==null,"major hazard cap is two")
	for active in trial._hazards(): active.cancel()

func check_floor_edges()->void:
	var dungeon:=trial.arena.dungeon
	for rect in dungeon.floor_rects:
		var edges:=[[rect.position,Vector2(rect.end.x,rect.position.y),Vector2.UP],[Vector2(rect.position.x,rect.end.y),rect.end,Vector2.DOWN],[rect.position,Vector2(rect.position.x,rect.end.y),Vector2.LEFT],[Vector2(rect.end.x,rect.position.y),rect.end,Vector2.RIGHT]]
		for edge in edges:
			var count:=ceili(edge[0].distance_to(edge[1]))
			for i in count:
				var at:Vector2=edge[0].lerp(edge[1],(i+.5)/count)
				var inside:Vector2=at-edge[2]*.75
				var outside:Vector2=at+edge[2]*.75
				if not dungeon._on_floor(inside) or dungeon._on_floor(outside): continue
				var ray:=PhysicsRayQueryParameters3D.create(dungeon.to_global(Vector3(inside.x,1.5,inside.y)),dungeon.to_global(Vector3(outside.x,1.5,outside.y)))
				ray.exclude=[player]
				var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
				check(not hit.is_empty() and hit.get("collider") is StaticBody3D,"solid wall closes floor boundary at %s in %s/%s"%[at,trial.layout.run_id,trial.built_floor])

func boss_checks(boss:Boss)->void:
	if not tested_boss_navigation:
		tested_boss_navigation=true
		var centre:Vector3=trial.room_space.centre
		boss.global_position=trial.arena.dungeon.to_global(centre+Vector3(-6,.6,-8))
		player.global_position=trial.arena.dungeon.to_global(centre+Vector3(6,.6,8))
		var start:=boss.global_position.distance_to(player.global_position)
		boss._breath_timer=100
		player.combat.invulnerable_left=100
		boss.set_physics_process(true)
		await settle(360)
		check(boss.global_position.distance_to(player.global_position)<start-8,"boss capsule negotiates Forge cover without sticking: %s -> %s"%[start,boss.global_position.distance_to(player.global_position)])
		boss.set_physics_process(false)
		player.combat.invulnerable_left=0
	player.global_position=boss.global_position+Vector3(0,0,-4)
	boss.look_at(player.global_position)
	boss.force_inhale()
	boss._begin_trial_tell()
	check(is_instance_valid(boss._floor_tell),"boss exposes committed floor tell")
	player.global_position=boss.global_position+Vector3(4,0,1)
	var life:=player.combat.life
	boss.breathe(player)
	check(player.combat.life==life and boss._recovery_left>0,"leaving committed arc avoids hit and opens recovery")
	if String(trial.layout.get("run_id",""))=="forge_capstone":
		check(trial.conduits.size()==3,"capstone has three physical ward conduits")
		var before:=trial.target_multiplier(boss)
		for conduit in trial.conduits:
			player.global_position=conduit.global_position+Vector3(0,.6,1)
			trial.interact_fixture(conduit)
		check(trial.target_multiplier(boss)>before,"any class can open conduit vulnerability")

func suspension()->void:
	check(not trial.suspend_to(SAVE_PATH),"suspension requires physically reaching descent lift")
	var secret:TrialFixture=trial.arena.dungeon.secret
	player.global_position=secret.global_position+Vector3(0,.6,1.5)
	var before_secret:=sim.trial_loot().duplicate(true)
	trial.interact_fixture(secret)
	check(secret.claimed and sim.trial_loot()!=before_secret,"cleared floor permits backtracking to its optional secret")
	var secret_loot:=sim.trial_loot().duplicate(true)
	trial.interact_fixture(secret)
	check(sim.trial_loot()==secret_loot,"physical secret cannot award twice")
	player.global_position=trial.arena.dungeon.boundary.global_position+Vector3(0,.6,1.5)
	trial_drop_guards()
	player.combat.life=player.combat.max_life*.4312345678901234
	player.combat.cooldowns[&"prototype_dash"]=2.751234567890123
	player.combat._trial_dash_armour=9
	player.combat._trial_dash_armour_left=.8512345678901234
	trial.elapsed_seconds=123.5
	var life:=player.combat.life
	var economy:=sim.export_json()
	var prepared := identity_cleanup_probes()
	check(not trial.suspend_to(SAVE_PATH) and trial.capture_boundary().is_empty(),"fresh boundary casts cannot silently lose an unrepresented charge on suspension")
	check(player.combat.life==life and sim.export_json()==economy,"refused suspension preserves exact life, loot and build")
	trial._cancel_transients()
	check(prepared.all(func(effect): return effect.is_queued_for_deletion()),"floor cleanup removes all new identity groups without payout")
	var loot:=sim.trial_loot().duplicate(true)
	var choices:=sim.trial_run_state().duplicate(true)
	# INT-08A: device settings cannot enter or alter the owned run checkpoint.
	var boundary_before := trial.capture_boundary()
	var original_preference_path := player.preferences.path
	player.preferences.path = "res://../build/intensives/trial-comfort.cfg"
	player.preferences.set_option("fov", 89.0)
	var comfort_key := InputEventKey.new()
	comfort_key.physical_keycode = KEY_J
	check(player.preferences.rebind("interact", comfort_key).is_empty(), "trial permits a separate device binding change")
	player.hud.toggle_help()
	player.hud.toggle_help()
	check(trial.capture_boundary() == boundary_before and sim.export_json() == economy, "settings preserve exact trial boundary, timers, life and native ownership")
	check(trial.suspend_to(SAVE_PATH),"cleared floor saves atomically")
	var file: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	var checkpoint:=String(file.get("trial_boundary",{}).get("checkpoint",""))
	check(not checkpoint.is_empty(),"suspension includes native checkpoint")
	var readable_drops:Dictionary=JSON.parse_string(JSON.stringify(world_drop_snapshot,"",true,true))
	check(file.get("world_drops",{})==readable_drops,"paired suspension records all four uncollected world ownership kinds")
	trial.on_player_died()
	check(not trial.active(),"fixture abandons prior in-memory run")
	check(WorldDrops.capture(player.world_root())==world_drop_snapshot,"trial death loses only the native run haul and leaves world drops untouched")
	# Reproduce a fresh process with no live nodes, then restore the same paired
	# file. A checkpoint's native run loot must not also appear as physical chips.
	WorldDrops.restore(player.world_root(),{"version":1,"pickups":[],"bundles":[]})
	var manager:=SaveManager.new()
	check(manager.read(SAVE_PATH,player),"paired checkpoint validates and restores: "+manager.last_error)
	check(WorldDrops.capture(player.world_root())==world_drop_snapshot,"paired checkpoint recreates exact uncollected world drops without automatic collection")
	freeze_world_drops()
	check(trial.active() and trial.state=="boundary","restore resumes same cleared boundary")
	check(trial.arena.dungeon.secret.claimed,"claimed secret presentation survives suspension")
	for stage in 4:
		var key:="%d:%d"%[stage,int(trial.layout.route[stage])]
		check(not trial.arena.dungeon.rooms[key].seal.visible,"restore keeps completed route door open")
	check(not bool(sim.trial_claim_secret().get("claimed",false)),"restored checkpoint cannot claim secret again")
	check(sim.export_json()==economy,"persistent build and deposited economy restore exactly")
	check(sim.trial_loot()==loot and sim.trial_run_state()==choices,"unbanked loot and choices restore exactly")
	check(player.combat.life==life and player.combat.cooldowns[&"prototype_dash"]==2.751234567890123,"restore grants no life/cooldown reset, including full binary64 precision")
	check(player.combat._trial_dash_armour==9 and player.combat._trial_dash_armour_left==.8512345678901234,"temporary effect clocks restore exactly: armour=%.17f timer=%.17f expected=%.17f"%[player.combat._trial_dash_armour,player.combat._trial_dash_armour_left,.8512345678901234])
	check(trial.elapsed_seconds==123.5,"loose-drop restoration does not advance or reset the suspended run clock")
	check(player.camera.fov == 89.0 and InputPrompts.key("interact") == "J", "trial restore retains current device settings")
	player.preferences.path = original_preference_path
	player.preferences.load_saved()
	player._apply_preferences()
	check(not sim.trial_restore_checkpoint(checkpoint),"active checkpoint cannot redeposit inventory")
	var malformed:=file.duplicate(true)
	malformed["trial_boundary"]["combat"]["life"]="bad"
	check(not manager.apply(player,malformed),"damaged checkpoint fails before economy mutation")
	check(sim.export_json()==economy,"failed restore does not alter valid live economy")
	malformed=file.duplicate(true)
	malformed["sim"]=baseline_economy
	check(not manager.apply(player,malformed),"checkpoint rejects a different saved persistent build")
	check(sim.export_json()==economy,"mismatched paired state leaves live economy intact")
	malformed=file.duplicate(true)
	malformed.trial_boundary.combat_exact=Marshalls.variant_to_base64(7,false)
	check(not manager.apply(player,malformed) and "combat" in manager.last_error,"exact combat companion rejects non-dictionary payload")
	malformed=file.duplicate(true)
	var wrong_combat:Dictionary=Marshalls.base64_to_variant(malformed.trial_boundary.combat_exact,false)
	wrong_combat.life+=1
	malformed.trial_boundary.combat_exact=Marshalls.variant_to_base64(wrong_combat,false)
	check(not manager.apply(player,malformed) and "representations" in manager.last_error,"readable and exact combat state must agree")
	check(sim.export_json()==economy,"rejected exact payload leaves the live economy intact")
	check(WorldDrops.capture(player.world_root())==world_drop_snapshot,"rejected boundary restores preserve the complete live world drop set")
	# Old schema-2 boundaries did not record loose drops. Their missing field
	# means an empty saved set, not permission to retain newer unsaved nodes.
	trial.on_player_died()
	var legacy:=file.duplicate(true)
	legacy.erase("world_drops")
	check(manager.apply(player,legacy),"old suspension without loose-drop records still restores its valid paired checkpoint")
	check(WorldDrops.capture(player.world_root())=={"version":1,"pickups":[],"bundles":[]},"old boundary replaces stale live drops with its empty recorded set")
	check(sim.export_json()==economy and sim.trial_loot()==loot and sim.trial_run_state()==choices,"old boundary preserves native deposit, run haul and choices without another payout")
	check(player.combat.life==life and player.combat.cooldowns[&"prototype_dash"]==2.751234567890123 and trial.elapsed_seconds==123.5,"old boundary compatibility preserves life and clocks")
	trial.on_player_died()
	check(manager.apply(player,file),"current boundary can restore after the compatibility probe")
	freeze_world_drops()
	check(WorldDrops.capture(player.world_root())==world_drop_snapshot and sim.trial_loot()==loot,"repeated validated restore has one exact world set and one native run ledger")
	check(not sim.trial_restore_checkpoint(checkpoint),"restored current boundary remains protected against duplicate deposit")

func prepare_world_drops()->void:
	var root:=player.world_root()
	var drops:=Pickup.scatter(root,Vector3(24,.75,20),{"wood":7},9081,0)
	var gear_seed:=1+56*7919
	var gear:=sim.enemy_gear_loot("ember_whelp",gear_seed)
	check(not gear.is_empty(),"world gear fixture uses a real deterministic enemy roll")
	if not gear.is_empty():
		drops.append(Pickup.drop_gear(root,Vector3(26,.75,20),"ember_whelp",gear_seed,gear[0],0))
	drops.append(Pickup.drop_page(root,Vector3(28,.75,20),"prototype_frost_orb","Frost Orb",0))
	for index in drops.size():
		var pickup:Pickup=drops[index]
		pickup.set_physics_process(false)
		pickup._age=8.5+index
		pickup._bob_phase=.5+index
		pickup._velocity=Vector3(1.25,2.5,-.75)
		pickup.rotation.y=.25
	var bundle:=preload("res://scenes/dropped_bundle.tscn").instantiate() as DroppedBundle
	bundle.contents={"wood":9,"split_stone":4}
	root.add_child(bundle)
	bundle.global_position=Vector3(30,0,20)
	bundle.rotation.y=.5
	var snapshot:=WorldDrops.capture(root)
	check(snapshot.pickups.size()==3 and snapshot.bundles.size()==1,"world fixture has material, gear, page and death bundle independent of the trial ledger")

func freeze_world_drops()->void:
	for node in get_tree().get_nodes_in_group("pickups"):
		if player.world_root().is_ancestor_of(node) and not node.is_queued_for_deletion():
			node.set_physics_process(false)

func trial_drop_guards()->void:
	# Deposits usually leave the in-run inventory empty. Give this API probe one
	# known stack so refusal proves it precedes consumption, then remove only it.
	var before:=sim.export_json()
	sim.add_material("wood",3)
	var with_stack:=sim.export_json()
	var rng_state:=player.ambush_rng.state
	check(not player.drop_material(&"wood",2),"active trial refuses the ordinary inventory Drop action")
	check(sim.export_json()==with_stack and player.ambush_rng.state==rng_state,"refused trial Drop consumes neither carried materials nor the world scatter seed")
	check(WorldDrops.capture(player.world_root())==world_drop_snapshot,"refused Drop cannot create an unbanked chip outside the native trial ledger")
	# consume_material retains a zero-valued native inventory key. A suspended
	# run requires the actual empty inventory, so clear just this injected stack
	# through the existing inventory API, without spawning a pickup or bundle.
	check(sim.drop_inventory()=={"wood":3} and sim.export_json()==before,"fixture removes only its injected ownership probe")
	for node in get_tree().get_nodes_in_group("pickups"):
		if node is Pickup and player.world_root().is_ancestor_of(node) and not node.is_queued_for_deletion():
			node._absorb(player)
	for node in player.world_root().get_children():
		if node is DroppedBundle and not node.is_queued_for_deletion(): node.interact(player)
	check(sim.export_json()==before,"world material, gear, page and death bundle cannot enter an active trial's inventory or permanent build")
	check(WorldDrops.capture(player.world_root())==world_drop_snapshot,"trial collection refusal preserves every loose owner and its complete contents")
	# World time continues during runs: block attraction/collection, not age or
	# ordinary flight. A resting chip at absorb range remains there and ages.
	for node in get_tree().get_nodes_in_group("pickups"):
		if node is Pickup and node.kind=="material" and not node.is_queued_for_deletion():
			var position_before:Vector3=node.global_position
			var velocity_before:Vector3=node._velocity
			var rotation_before:Vector3=node.rotation
			var phase_before:float=node._bob_phase
			var mesh_y_before:float=node._mesh.position.y
			node.global_position=player.global_position+Vector3(0,.6,0)
			node._resting=true
			var age_before:float=node._age
			var at:Vector3=node.global_position
			node._physics_process(.25)
			check(not node.is_queued_for_deletion() and node.global_position==at and node.amount==7 and sim.export_json()==before,"world chip at absorb range cannot magnetise or collect during a run")
			check(node._age==age_before+.25,"world material lifetime keeps advancing during trial ownership isolation")
			node.global_position=position_before
			node._resting=false
			node._velocity=velocity_before
			# Return the manually moved probe to its original visual pose, while
			# retaining the elapsed age whose suspension persistence is checked.
			node.rotation=rotation_before
			node._bob_phase=phase_before
			node._mesh.position.y=mesh_y_before
			break
	world_drop_snapshot=WorldDrops.capture(player.world_root())

func identity_cleanup_probes() -> Array:
	# Lifecycle probes deliberately contain no ability payload. Actual native
	# preparation, collection and combat are covered by the four role suites.
	var probes: Array=[FoundryOffence.new(),FoundryGuard.new(),FoundrySustain.new(),FoundryTempo.new()]
	for effect in probes:
		effect.combat=player.combat
		effect.remaining=1
		effect.set_physics_process(false)
		add_child(effect)
		if effect is FoundryTempo: effect.add_to_group("foundry_tempo")
	return probes

func atomic_save_checks()->void:
	var path:="res://../build/intensives/atomic-check.json"
	var manager:=SaveManager.new()
	check(manager.write_data(path,{"revision":1}),"initial atomic save succeeds")
	check(manager.write_data(path,{"revision":2}),"replacement atomic save succeeds")
	check(JSON.parse_string(FileAccess.get_file_as_string(path+".previous")).revision==1,"previous good save retained")
	var previous:=FileAccess.get_file_as_string(path)
	check(DirAccess.make_dir_absolute(path+".pending")==OK,"fixture obstructs only its own pending save path")
	check(not manager.write_data(path,{"revision":3}),"pending write failure is reported")
	check(FileAccess.get_file_as_string(path)==previous,"failed save keeps exact last good file")
	DirAccess.remove_absolute(path+".pending")
