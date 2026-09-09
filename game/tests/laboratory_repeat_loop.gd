extends "res://tests/laboratory_experiment.gd"
## Full five-room live combat plus separate forced failure/settlement fixtures.
const LOOP_SAVE:="user://lf7-loop.json"
const LOOP_END:="user://lf7-completed.json"
const LOOP_DEATH:="user://lf7-death.json"
var bot:Node3D
var live_samples:Array=[]
var run_inventory:Dictionary
var run_currency:Dictionary
var run_items:=0

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	world=preload("res://scenes/sandpit.tscn").instantiate()
	world.scene_file_path="";world.world_profile="living_frontier_wave3";world.world_seed=77
	get_tree().root.add_child(world);get_tree().current_scene=world
	player=world.player;trial=player.trial;arena=world.get_node("TrialArena")
	quiet_pairing()
	if "--lf7-restart" in OS.get_cmdline_user_args():
		await restart_checks()
		return finish_loop()
	var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/lf6-published-ending.json.gz")
	var file:=FileAccess.open(LOOP_SAVE,FileAccess.WRITE)
	file.store_string(packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8());file.close()
	if not check(player.load_game(LOOP_SAVE),"archived completed campaign supplies synthetic access"):return finish_loop()
	quiet_pairing()
	# Supplied ordinary inputs isolate combat preparation; every craft pays its
	# real recipe, leaving all previous equipment and world ownership retained.
	sim.add_materials({"iron_ingot":30,"bronze_ingot":20,"charcoal":20,"hide":20,"wood":20})
	sim.add_station("forge_basic");sim.add_station("forge_improved")
	for recipe in ["iron_mace","bronze_mail"]:
		var crafted:=sim.craft(recipe)
		check(bool(crafted.get("crafted",false)),"paid ordinary prepared kit: "+recipe)
		if bool(crafted.get("crafted",false)):check(sim.equip_pack_item(sim.pack_items().size()-1),"equip paid "+recipe)
	check(bool(sim.temper_basic().get("applied",false)),"ordinary fire-resistance temper without a Catalyst")
	# A deliberate ordinary Catalyst purchase, not an intact-find shortcut.
	# The separate all-paid field journey obtains these same inputs itself.
	sim.add_materials({"red_salt":96,"iron_ingot":4,"charcoal":8})
	var salt_before:=sim.material_count("red_salt")
	var catalysts_before:=sim.material_count("ember_catalyst")
	check(bool(sim.craft("forge_faint_ember").get("crafted",false)),"ordinary costly Ember manufacture for the prepared run")
	check(sim.material_count("red_salt")==salt_before-96 && sim.material_count("ember_catalyst")==catalysts_before+1,"crafted Catalyst pays the full raw-material price")
	sim.add_materials({"silver_ingot":3,"hide":6,"charcoal":6})
	for i in sim.exchange_rate():check(bool(sim.craft("cast_marrow").get("crafted",false)),"pay ordinary Marrow manufacture")
	check(sim.exchange("marrow","sipping_marrow"),"pay three-for-one recovery Kind exchange")
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer","recipe:workbench_kit","first_kill:stone_husk","world_effect:stonecut_blocks","first_kill:ash_hound"]:sim.foundry_event(event)
	check(sim.foundry_place_skill(1,1,String(sim.skill_bar()[0])),"place existing primary skill on earned plate")
	check(sim.foundry_place(1,0,"vigour") && sim.foundry_place(2,1,"edge"),"ordinary Vigour/Edge ingots prepare the existing recovery build")
	check(sim.foundry_place_kind(2,0,"sipping_marrow"),"newly manufactured and exchanged Marrow works the persistent route")
	check(sim.foundry_place_skill(2,2,String(sim.skill_bar()[1])),"second existing attack joins the same paid recovery route")
	before_world=SaveManager.new().capture(player)
	check(player.save_game(LOOP_SAVE),"prepared owned world checkpoint")
	await reach_central();player.interact();await press_button("Configure experiment");await select_compatible()
	# Complete the base configuration first. Added-pressure live combat is
	# measured independently; this full journey retains its two rolled risks.
	var slot:=int(selected_offer.slot)
	await press_button("No extra pressure")
	selected_pressure="";selected_offer=sim.trial_map_offers(1)[slot];selected_offer.slot=slot
	run_inventory=sim.inventory().duplicate(true);run_currency=sim.currency().duplicate(true);run_items=sim.pack_items().size()
	await press_button("Enter run %d"%int(selected_offer.slot+1))
	if not check(trial.active(),"configured full run enters physically"):return finish_loop()
	await _settle_player();await _settle_navigation(arena.dungeon)
	bot=load("res://tests/laboratory_experiment_combat.gd").new()
	bot.player=player;bot.combat=player.combat;bot.sim=sim;bot.trial=trial;bot.ranged=false;bot.cohort="archived_melee/iron_mace_bronze_mail/paid_recovery"
	player.combat.fight_seed_source.seed=bot.CONFIG.batch_seed
	player.combat.hit_taken.connect(func(damage:float,_source:String):
		if is_instance_valid(bot) && bot.probing:bot.sample.damage_taken+=damage)
	player.combat.skill_committed.connect(func(_id:StringName):
		if is_instance_valid(bot) && bot.probing:bot.sample.casts+=1)
	player.combat.hit_landed.connect(func(damage:float,_kills:int,_types:PackedStringArray):
		if is_instance_valid(bot) && bot.probing:bot.sample.direct_hit_damage+=damage)
	player.combat.died.connect(func():
		if is_instance_valid(bot) && bot.probing:bot.sample.died=true)
	var secret:TrialFixture
	for fixture:TrialFixture in arena.dungeon.fixtures:
		if fixture.fixture_kind=="secret":secret=fixture
	if check(secret!=null,"existing optional secret is reachable") && await _reach(secret,"configured secret"):
		player.interact()
		check(sim.trial_loot()==selected_offer.secret_materials,"actual secret pays the stated target once")
	for stage in 5:
		var marker:TrialFixture
		for fixture:TrialFixture in arena.dungeon.fixtures:
			if fixture.fixture_kind=="route" && fixture.stage_index==stage:marker=fixture
		if not check(marker!=null,"configured stage has physical route") || not await _reach(marker,"configured route "+str(stage)):return finish_loop()
		player.combat.invulnerable_left=0;player.combat.set_physics_process(true)
		player.interact()
		if not check(trial.state=="fighting","physical E starts live stage "+str(stage)):return finish_loop()
		await fight_live(stage)
		if not check(trial.active() && trial.state=="reward","live stage cleared without forced outcome "+str(stage)):return finish_loop()
		player.combat.set_physics_process(false)
		if not await _reach(arena.dungeon.reward,"configured actual reward "+str(stage)):return finish_loop()
		if stage==1:check(trial._pending_outcome.materials==selected_offer.cache_materials,"actual combat cache matches its preview")
		if stage==3:check(trial._pending_outcome.reward_type=="equipment" && not trial._pending_outcome.catalyst_recovered,"equipment reward cannot invent a Catalyst")
		if stage==4:check(trial._pending_outcome.materials==selected_offer.completion_components,"actual boss awards exactly its advertised core")
		player.interact()
		if not trial.current_offer.is_empty():await press_button("Accept")
		await frames(3)
	check(not trial.active() && live_samples.size()==5,"all five rooms finish through actual combat and physical offerings")
	check(not player.experiment_save_pending && player.work_panel._custom_title=="Laboratory return","normal completion returns to saved reconfiguration page")
	check_rewards()
	await snapshot_loop("completed-return")
	check_preserved(before_world,SaveManager.new().capture(player))
	var completed:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LOOP_SAVE))
	check(JSON.parse_string(completed.sim)==JSON.parse_string(sim.export_json()) && completed.get("trial_boundary",{}).is_empty(),"automatic checkpoint owns exact rewards, next batch and settings")
	check(SaveManager.new().write(LOOP_END,player),"retain live completion for fresh-process proof")
	print("LF7_TRANSITION completion_checkpoint_ms=",player.get_meta("last_experiment_checkpoint_ms",-1))
	await failure_paths()
	finish_loop()

func fight_live(stage:int) -> void:
	bot.sample={"stage":stage,"elapsed_seconds":0.0,"died":false,"damage_taken":0.0,"casts":0,"kills":0,"direct_hit_damage":0.0,"minimum_life_fraction":1.0,"remaining_enemy_life":0.0,"max_live_enemies":0,"boss_min_distance_m":999.0,"boss_max_distance_m":0.0,"boss_chase_stalled_seconds":0.0}
	bot.seen.clear();bot.decision_left=0;bot.probing=true
	var room:Dictionary=arena.dungeon.rooms["%d:0"%stage]
	var path:=arena.dungeon.path(player.global_position,arena.dungeon.to_global(room.centre+Vector3(0,0,7)))
	var path_index:=0
	var pursuit:=PackedVector3Array()
	var pursuit_clock:=0
	while bot.sample.elapsed_seconds<180 && not bot.sample.died && trial.state=="fighting":
		bot._physics_process(1.0/60)
		var immediate_danger:=false
		for foe:Enemy in trial.trial_enemies():
			if foe is Boss && foe.state=="inhale":immediate_danger=true
		for hazard in trial._hazards():
			if hazard.global_position.distance_to(player.global_position)<4.2:immediate_danger=true
		if path_index<path.size() && not immediate_danger:
			var to:Vector3=(path[path_index]-player.global_position)*Vector3(1,0,1)
			if to.length()<.6:path_index+=1
			else:
				var local:=player.global_basis.inverse()*to.normalized();player.test_walk=Vector2(local.x,local.z)
		elif path_index>=path.size():
			# The isolated open-room bot steers directly at targets. The full
			# laboratory also has real cabinets/cover: follow native floor paths
			# to a distant target without overriding an immediate danger escape.
			var foes:=trial.trial_enemies()
			var nearest:Enemy
			var distance:=INF
			var danger:=false
			for foe:Enemy in foes:
				var gap:=player.global_position.distance_to(foe.global_position)
				if gap<distance:nearest=foe;distance=gap
				if foe is Boss && foe.state=="inhale":danger=true
			for hazard in trial._hazards():
				if hazard.global_position.distance_to(player.global_position)<4.2:danger=true
			pursuit_clock-=1
			if is_instance_valid(nearest) && distance>3.0 && not danger:
				if pursuit_clock<=0:
					pursuit=arena.dungeon.path(player.global_position,nearest.global_position);pursuit_clock=12
				while not pursuit.is_empty() && ((pursuit[0]-player.global_position)*Vector3(1,0,1)).length()<.6:pursuit.remove_at(0)
				if not pursuit.is_empty():
					var direction:Vector3=(pursuit[0]-player.global_position)*Vector3(1,0,1)
					var local:=player.global_basis.inverse()*direction.normalized();player.test_walk=Vector2(local.x,local.z)
		trial._process(1.0/60)
		check(trial.trial_enemies().size()<=24 && trial._hazards().size()<=2,"live population and hazard cap")
		await frames(1)
	bot.probing=false;player.test_walk=Vector2.ZERO
	bot.sample.cleared=trial.state=="reward" && not bot.sample.died
	bot.sample.remaining_enemy_life=0.0
	for foe:Enemy in trial.trial_enemies():bot.sample.remaining_enemy_life+=foe.life
	live_samples.append(bot.sample.duplicate(true))
	print("LF7_FULL_ROOM ",JSON.stringify(bot.sample))

func _reach(fixture:TrialFixture,label:String) -> bool:
	# The combat probe aims the camera directly; restore the production camera
	# hierarchy before the inherited real first-person route/interaction probe.
	player.camera.rotation=Vector3.ZERO
	var reached:=await super._reach(fixture,label)
	if not reached:print("LF7_RAY_DIAGNOSTIC ",label," fixture=",fixture.global_position," player=",player.global_position," camera=",player.camera.global_position," forward=",-player.camera.global_basis.z," probe=",player.aim_probe()," spring=",player.spring_arm.rotation)
	return reached

func check_rewards() -> void:
	var earned:Dictionary={}
	for reward:Dictionary in [selected_offer.cache_materials,selected_offer.secret_materials,selected_offer.completion_components]:
		for id in reward:earned[id]=int(earned.get(id,0))+int(reward[id])
	check_material_sum(run_inventory,run_currency,earned,"full run delivers exact advertised quantities once")
	check(sim.pack_items().size()==run_items+3,"full run delivers exactly three advertised equipment rolls")
	for i in 3:
		var item:Dictionary=sim.pack_items()[run_items+i]
		var preview:Dictionary=selected_offer.equipment_rewards[i]
		check(item.rarity==preview.rarity && not item.rolled.is_empty(),"actual equipment has advertised rarity and rolled modifiers")
		for property:Dictionary in item.rolled:check(int(property.tier)>0 && int(property.tier)<=int(preview.tier),"actual modifier respects advertised roll tier and available definitions")
	check(int(sim.trial_map_progress().max_tier)==2 && String(sim.trial_map_progress().last_pressure)==selected_pressure,"only boss clear unlocks next tier and retains selected setting")
	var once:=sim.export_json()
	sim.trial_resolve_room(true);sim.trial_claim_secret();sim.trial_end()
	check(sim.export_json()==once,"repeated completion cannot replay rewards after return")

func failure_paths() -> void:
	# Forced room outcomes isolate exit/checkpoint accounting. The primary run
	# above is fully live; natural death below uses actual released enemy hits.
	player.set_meta("active_world_save_path",LOOP_SAVE)
	await press_button("Configure next experiment")
	await press_button("Tier 2")
	await press_button("No extra pressure")
	var bank_offer:Dictionary=sim.trial_map_offers(2)[0]
	var deposit:=sim.inventory().duplicate(true)
	var purse:=sim.currency().duplicate(true)
	var batch_before:String=JSON.parse_string(sim.export_json()).extra.trial_gate
	await press_button("Enter run 1")
	check(trial.active() && trial.layout.tier==2 && trial.layout.pressure=="" && trial.layout.run_id==bank_offer.id,"actual return page selects another tier and configuration")
	await force_rooms(4)
	var earned:=sim.trial_loot().duplicate(true)
	check(bool(sim.trial_stage().can_bank_and_exit),"four completed rooms permit early bank")
	if await _reach(arena.dungeon.boundary,"real laboratory bank exit"):
		player.interact();await snapshot_loop("physical-exit");await press_button("Bank and leave")
	check(not trial.active() && not player.experiment_save_pending,"actual exit banks and saves")
	check_material_sum(deposit,purse,earned,"bank preserves exactly earned quantities")
	check(int(sim.trial_map_progress().max_tier)==2 && JSON.parse_string(sim.export_json()).extra.trial_gate!=batch_before,"bank consumes entry batch but cannot unlock a tier")
	var banked:=SaveManager.new().capture(player)
	check(player.load_game(LOOP_SAVE),"ordinary bank checkpoint reloads")
	quiet_pairing();check_preserved(banked,SaveManager.new().capture(player))
	check(JSON.parse_string(sim.export_json())==JSON.parse_string(banked.sim),"banked native inventory/equipment/gate remain exact")
	await reach_central();player.interact();await press_button("Configure experiment")
	await press_button("No extra pressure")
	deposit=sim.inventory().duplicate(true)
	purse=sim.currency().duplicate(true)
	await press_button("Enter run 1")
	await _settle_navigation(arena.dungeon)
	if await _reach(arena.dungeon.boundary,"real abandonment exit"):
		player.interact()
		var bank_disabled:=false
		for button:Button in player.work_panel.find_children("*","Button",true,false):
			if button.text=="Bank and leave":bank_disabled=button.disabled
		check(bank_disabled,"unearned bank action is physically disabled")
		# A real unwritable destination leaves the valid preceding checkpoint.
		var disk_before:=FileAccess.get_file_as_bytes(LOOP_SAVE)
		player.set_meta("active_world_save_path","user://lf7-missing-directory/return.json")
		await press_button("Abandon experiment")
		check(not trial.active() && player.experiment_save_pending && sim.inventory()==deposit && sim.currency()==purse,"abandon returns exact deposit/purse and visibly retains failed save")
		await snapshot_loop("return-save-retry")
		check(FileAccess.get_file_as_bytes(LOOP_SAVE)==disk_before,"failed return write preserves previous checkpoint bytes")
		var settled:=sim.export_json()
		check(not player.save_game() && player.experiment_save_pending,"another failed ordinary write retains retry warning")
		player.set_meta("active_world_save_path",LOOP_SAVE)
		await press_button("Retry experiment save")
		check(not player.experiment_save_pending && sim.export_json()==settled,"actual retry saves without any repeated settlement")
		check(player.work_panel._custom_title=="Laboratory return","save retry returns to reconfiguration")
	await press_button("Configure next experiment")
	await press_button("No extra pressure")
	deposit=sim.inventory().duplicate(true)
	purse=sim.currency().duplicate(true)
	var items:=sim.pack_items().duplicate(true)
	player.set_meta("active_world_save_path",LOOP_DEATH)
	await press_button("Enter run 1")
	await force_rooms(4)
	var boss_room:Dictionary=arena.dungeon.rooms["4:0"]
	player.global_position=arena.dungeon.to_global(boss_room.centre+Vector3(0,.7,3))
	player.velocity=Vector3.ZERO
	check(trial.enter_room(0),"natural-death specimen starts after forced setup rooms")
	player.combat.restore_life();player.combat.invulnerable_left=0;player.combat.set_physics_process(true)
	var damage:={"hits":0,"amount":0.0}
	var count_hit:=func(amount:float,_source:String):damage.hits+=1;damage.amount+=amount
	player.combat.hit_taken.connect(count_hit)
	var seconds:=0.0
	while trial.active() && seconds<90:
		trial._process(1.0/60);await frames(1);seconds+=1.0/60
	player.combat.hit_taken.disconnect(count_hit)
	check(not trial.active() && damage.hits>0 && damage.amount>=100,"actual released attacks cause one ordinary Trial death")
	quiet_pairing()
	check(sim.inventory()==deposit && sim.currency()==purse && sim.pack_items()==items,"natural death restores deposited ownership/purse and loses unbanked gear/haul")
	check(not player.experiment_save_pending && sim.world_effect_active("forge_arc_complete") && int(sim.trial_map_progress().max_tier)==2,"natural-death checkpoint retains ending and unlocked tier")
	print("LF7_NATURAL_DEATH seconds=",seconds," hits=",damage.hits," damage=",damage.amount," forced_setup_rooms=4")
	check_preserved(before_world,SaveManager.new().capture(player))
	await press_button("Configure next experiment")
	check(player.work_panel._custom_title.contains("Controlled laboratory"),"death permits another configuration")
	var offers:=sim.trial_map_offers(1)
	check(player.load_game(LOOP_DEATH),"ordinary natural-death checkpoint loads")
	quiet_pairing();check(sim.trial_map_offers(1)==offers,"death/retry cannot reroll unopened offers")

func force_rooms(count:int) -> void:
	quiet_pairing()
	for stage in count:
		check(trial.enter_room(0),"forced settlement fixture room begins")
		trial._despawn_enemies()
		for hazard in trial._hazards():hazard.cancel()
		sim.trial_resolve_room(true);sim.trial_skip_reward()
		arena.dungeon.complete_stage(stage)
		trial._clear_conduits();trial._cancel_transients();trial.show_doors()
		await frames(2)

func check_material_sum(deposit:Dictionary,purse:Dictionary,earned:Dictionary,label:String) -> void:
	var expected:=deposit.duplicate(true)
	var expected_purse:=purse.duplicate(true)
	var crafting:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(load("res://scripts/sim.gd").get_tuning_directory().path_join("crafting.json")))
	for id in earned:
		if id in crafting.currencies:expected_purse[id]=int(expected_purse.get(id,0))+int(earned[id])
		else:expected[id]=int(expected.get(id,0))+int(earned[id])
	check_inventory(expected,label)
	check(sim.currency()==expected_purse,label+" including exact separate Kind purse")

func check_inventory(expected:Dictionary,label:String) -> void:
	var actual:=sim.inventory()
	if actual!=expected:print("LF7_INVENTORY_DIAGNOSTIC ",label," expected=",JSON.stringify(expected)," actual=",JSON.stringify(actual))
	check(actual==expected,label)

func restart_checks() -> void:
	check(player.load_game(LOOP_END),"fresh process restores actual completed experiment")
	quiet_pairing()
	var disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LOOP_END))
	check(JSON.parse_string(sim.export_json())==JSON.parse_string(disk.sim),"fresh native rewards and committed gate match saved completion")
	check_preserved(disk,SaveManager.new().capture(player))
	check(bool(sim.trial_map_progress().available) && int(sim.trial_map_progress().max_tier)==2 && sim.world_effect_active("forge_arc_complete"),"fresh completion opens reconfiguration without repeating ending")
	await reach_central();player.interact();await press_button("Configure experiment")
	check(player.work_panel._custom_title.contains("Controlled laboratory"),"fresh completed controls remain physically usable")
	for path in [LOOP_SAVE,LOOP_DEATH]:
		check(player.load_game(path),"fresh process restores retry/death: "+path)
		quiet_pairing()
		var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		check(JSON.parse_string(sim.export_json())==JSON.parse_string(saved.sim),"fresh retry/death native rewards/settings match disk")
		check_preserved(saved,SaveManager.new().capture(player))
		check(not player.experiment_save_pending && sim.world_effect_active("forge_arc_complete") && int(sim.era().index)==3,"fresh retry/death retains campaign and finished checkpoint")

func finish_loop() -> void:
	if is_instance_valid(bot):bot.free()
	var file:=FileAccess.open("res://../build/lf7/full-loop-restart.json" if "--lf7-restart" in OS.get_cmdline_user_args() else "res://../build/lf7/full-loop.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"rooms":live_samples,"offer":selected_offer,"combat_seed":741103,"limits":"Archived synthetic campaign access and earned-ingot fixture; supplied ordinary metal/hide/fuel/raw inputs and forge facilities. Preserves the historical classless heavy-strike/area-strike/frost-nova/dash bar. Paid iron mace, bronze mail, temper and three Marrows exchanged for Sipping Marrow. The two existing attacks share Vigour/Edge and the manufactured recovery Kind. A separately manufactured Faint Ember stays owned and unused. Base tier-one configuration retains rolled risks. Real damage/casts and telegraph-aware movement; no lucky Catalyst use, forced kill, healing reset or immunity in the full run. Failure fixtures are separately labelled."},"  ",true,true));file.close()
	print("LF7_LOOP ",checks," checks, ",failures," failures; ",walked_metres," m approach/gallery travel; ",live_samples.size()," fully live rooms")
	get_tree().quit(1 if failures else 0)

func snapshot_loop(name:String) -> void:
	if "--lf7-loop-visuals" not in OS.get_cmdline_user_args():return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf7"))
	for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../captures/lf7/"+name+".png")
