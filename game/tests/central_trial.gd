extends "res://tests/pairing_trial.gd"
## Prior rooms force outcomes for route coverage; final human uses live casts.
const CENTRAL_BOUNDARY := "user://lf6-central-boundary.json"
const CENTRAL_ENDING := "user://lf6-central-ending.json"
var before_world: Dictionary
var central_gate: StaticBody3D

func quiet_pairing() -> void:
	super.quiet_pairing()
	# Freeze loose-drop flight/age only for exact ownership comparisons.
	for pickup in get_tree().get_nodes_in_group("pickups"):pickup.set_physics_process(false)

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	sim.set_campaign_policy("living_frontier_wave4")
	world=preload("res://scenes/sandpit.tscn").instantiate()
	world.world_profile="living_frontier_wave3";world.world_seed=77
	get_tree().root.add_child(world);get_tree().current_scene=world
	player=world.player;trial=player.trial;arena=world.get_node("TrialArena")
	quiet_pairing()
	var manager:=SaveManager.new()
	if "--lf6-boundary" in OS.get_cmdline_user_args():
		check(player.load_game(CENTRAL_BOUNDARY),"fresh Central boundary loads normally")
		quiet_pairing()
		var disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CENTRAL_BOUNDARY))
		check(trial.state=="boundary" && sim.boss().id=="conservator" && trial.layout.get("central_laboratory",false),"fresh boundary retains dedicated human and Central revision")
		check(JSON.parse_string(manager.capture(player).sim)==JSON.parse_string(disk.sim),"fresh boundary preserves exact native ownership")
		check(not sim.world_effect_active("forge_arc_complete"),"suspension does not resolve the ending")
		return finish_central()
	if "--lf6-ending" in OS.get_cmdline_user_args():
		check(player.load_game(CENTRAL_ENDING),"fresh ending loads normally")
		quiet_pairing()
		var disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CENTRAL_ENDING))
		var diagnostic:=FileAccess.open("res://../build/lf6/ending-actual.json",FileAccess.WRITE)
		diagnostic.store_string(manager.capture(player).sim);diagnostic.close()
		check(JSON.parse_string(manager.capture(player).sim)==JSON.parse_string(disk.sim),"fresh ending and all native rewards remain exact")
		check(sim.world_effect_active("forge_arc_complete") && int(sim.era().index)==3 && not sim.trial_start_story(12,"forge_capstone"),"completed human cannot return or cause a fourth era")
		check(not bool(sim.trial_map_progress().available),"optional configured experiments remain Wave 7")
		return finish_central()
	var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/lf5b-published-clear.json.gz")
	var file:=FileAccess.open("user://lf6-start.json",FileAccess.WRITE)
	file.store_string(packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8());file.close()
	if not check(manager.read("user://lf6-start.json",player),"frozen LF5B saved ownership restores"):return finish_central()
	quiet_pairing()
	check(ResonanceEvent.publish(player,"user://lf6-prepared.json").ok,"existing second publication opens Central")
	quiet_pairing()
	before_world=manager.capture(player)
	check(sim.trial_story_runs().size()==3 && bool(sim.trial_story_runs()[2].available),"existing third site opens only after both physical awards")
	await _native_route()
	check(player.global_position.distance_to(annex_entry)<.15,"finale returns to the exact Central approach")
	check(sim.world_effect_active("forge_arc_complete") && int(sim.era().index)==3,"real final human fight resolves once without another era")
	var after:=manager.capture(player)
	for key in ["blocks","stations","broken_blocks","cracked_blocks","contraptions","leylines","resource_nodes"]:
		check(JSON.parse_string(JSON.stringify(after.get(key)))==JSON.parse_string(JSON.stringify(before_world.get(key))),"ending preserves world ownership: "+key)
	var before_native:Dictionary=JSON.parse_string(before_world.sim).economy
	check(JSON.parse_string(sim.resonance_json())==before_native.resonance && JSON.parse_string(sim.resonance_second_json())==before_native.resonance_second,"ending preserves both physical event ledgers")
	check(manager.write(CENTRAL_ENDING,player),"retain actual finished battle for fresh-process recovery")
	check(not sim.trial_start_story(12,"forge_capstone") && not bool(sim.trial_map_progress().available),"story replay and Wave 7 maps remain unavailable")
	finish_central()

func _start_native_route() -> bool:
	var lab:Dictionary=world.terrain.map.laboratories[2]
	for site:Dictionary in world.terrain.map.laboratories:
		if String(site.id).contains("central"):lab=site
	world.terrain.ensure_area(lab.position,32)
	var approach:PackedVector3Array=lab.approach
	player.global_position=approach[-6]+Vector3.UP*1.2
	player.velocity=Vector3.ZERO;player.set_physics_process(true)
	await _settle_player()
	for i in range(approach.size()-5,approach.size()):
		if not await _walk_to(approach[i],.2):return false
	for gate in get_tree().get_nodes_in_group("laboratory_gates"):
		if String(gate.get_meta("run_id",""))=="forge_capstone":central_gate=gate
	if not check(central_gate!=null,"existing Central body supplies its real door"):return false
	var aim:=central_gate.global_position
	var offset:=aim-player.camera.global_position
	player.look_at(Vector3(aim.x,player.global_position.y,aim.z))
	player.spring_arm.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
	await frames(2)
	check(player.aim_probe().get("target")==central_gate,"ordinary E ray reaches Central")
	player.interact()
	check(player.work_panel.is_open(),"Central preview opens physically")
	annex_entry=player.global_position
	central_gate.call("_enter",player)
	if not check(trial.active() && trial.layout.get("central_laboratory",false) && sim.boss().id=="conservator","door enters actual Central and human kit"):return false
	await _settle_player();await _settle_navigation(arena.dungeon)
	check(arena.dungeon.laboratory_records.size()==3,"human, emergency releases and final circuit are inspectable")
	for record:TrialFixture in arena.dungeon.laboratory_records:
		if not await _reach(record,"Central record "+record.title):return false
		var before:=sim.export_json();player.interact()
		check(player.work_panel.is_open() && sim.export_json()==before,"records grant no items or progression")
		player.work_panel.close_panel()
	return true

func _clear_encounter() -> void:
	if trial.current_stage_index!=7:
		await super._clear_encounter()
		return
	var human:=trial.trial_enemies()[0] as Conservator
	if not check(human!=null && trial.trial_enemies().size()==1,"final room is the dedicated human alone"):return
	check(trial.conduits.size()==2 && human.verb=="" && trial._hazards().is_empty(),"two emergency releases replace Warden protection and furnace hazards")
	for pedestal:TrialFixture in trial.conduits:
		if not await _reach(pedestal,"physical emergency release"):return
		human.set_physics_process(true)
		for i in 300:
			if not human.channel.is_empty():break
			await frames(1)
		var before:=sim.export_json();var drains:=human.drains
		player.interact()
		check(human.drains==drains+1 && human.channel.is_empty() && human.recovery_left>2.9,"actual E drains the current channel and creates recovery")
		check(sim.export_json()==before && not trial.conduits[0].available && not trial.conduits[1].available,"drain creates no items and cools both controls")
		human.set_physics_process(false)
		# Explicit clock acceleration for apparatus cooldown only, not combat.
		trial._tick_spatial(float(trial.rules.conservator_release_cooldown_seconds)+.01)
		check(pedestal.available,"cooled apparatus becomes available again")
	player.combat.set_physics_process(true);player.combat.invulnerable_left=0
	player.combat.restore_life()
	human.set_physics_process(true)
	var casts:=0;var seconds:=0.0
	var release_receipt:Dictionary={"count":0}
	human.attack_released.connect(func(_kind:String):release_receipt.count+=1)
	for step in 60*120:
		if not is_instance_valid(human) or human.life<=0 or player.combat.life<=0:break
		var delta:Vector3=(human.global_position-player.global_position)*Vector3(1,0,1)
		var forward:=delta.normalized();var distance:=delta.length()
		player.look_at(player.global_position+forward)
		player.camera.look_at(human.global_position+Vector3.UP*1.4)
		var move:=forward if distance>1.5 else Vector3.ZERO
		if human.channel=="white":move=Vector3(-forward.z,0,forward.x)
		elif human.channel in ["blue","red"]:
			var away:Vector3=(player.global_position-human.committed_mark)*Vector3(1,0,1)
			move=away.normalized() if away.length()>.2 else Vector3(-forward.z,0,forward.x)
			if away.length()>human.rule("mark_radius_m")+.5:move=Vector3.ZERO
		elif human.channel=="green":move=Vector3.ZERO
		var local:=player.global_basis.inverse()*move;player.test_walk=Vector2(local.x,local.z)
		for skill in sim.skill_bar():
			var definition:Dictionary=player.combat.skills.get(skill,{})
			if definition.get("delivery","")=="dash":continue
			if definition.get("delivery","") in ["strike","cone"] && distance>player.combat.strike_reach(skill):continue
			if player.combat.use_skill(skill):casts+=1;break
		await frames(1);seconds+=1.0/60
	player.test_walk=Vector2.ZERO
	check((not is_instance_valid(human) or human.life<=0) && player.combat.life>0 && casts>0,"actual final-chamber casts defeat human with incoming damage live")
	print("LF6_CHAMBER seconds=",seconds," casts=",casts," life=",player.combat.life," releases=",release_receipt.count," forced_prior_rooms=true")
	player.combat.set_physics_process(false)
	trial._process(1.0/60)
	await frames(2)

func _boundary_restore() -> void:
	await super._boundary_restore()
	for pickup in get_tree().get_nodes_in_group("pickups"):pickup.set_physics_process(false)
	check(SaveManager.new().write_data(CENTRAL_BOUNDARY,SaveManager.new().capture(player)),"retain Central boundary for separate process")

func checkpoint_path() -> String:
	return "user://lf6-active-boundary.json"

func finish_central() -> void:
	print("LF6_CENTRAL ",checks," checks, ",failures," failures; ",walked_metres," m actual route; prior encounters forced, final human live")
	get_tree().quit(1 if failures else 0)
