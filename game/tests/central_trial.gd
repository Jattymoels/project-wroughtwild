extends "res://tests/pairing_trial.gd"
## Prior rooms force outcomes for route coverage; final human uses live casts.
const CENTRAL_BOUNDARY := "user://lf6-central-boundary.json"
const CENTRAL_ENDING := "user://lf6-central-ending.json"
const CENTRAL_AFTER_DEATH := "user://lf6-after-ending-death.json"
const FAILED_ENDING := "user://lf6-directory-that-does-not-exist/ending.json"
var before_world: Dictionary
var central_gate: StaticBody3D
var last_boundary_bytes: PackedByteArray

func _ready() -> void:
	# Restored pickups are new nodes. Freeze their cosmetic clocks immediately,
	# before the inherited boundary walk waits for navigation/physics frames.
	get_tree().node_added.connect(func(node:Node):
		if node is Pickup: node.ready.connect(func():node.set_physics_process(false),CONNECT_ONE_SHOT))
	super._ready()

func quiet_pairing() -> void:
	super.quiet_pairing()
	# Freeze loose-drop flight/age only for exact ownership comparisons.
	for pickup in get_tree().get_nodes_in_group("pickups"):pickup.set_physics_process(false)

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	sim.set_campaign_policy("living_frontier_wave4")
	world=preload("res://scenes/sandpit.tscn").instantiate()
	world.scene_file_path="" # Embedded deterministic fixture, not a fresh-launch chooser.
	world.world_profile="living_frontier_wave3";world.world_seed=77
	get_tree().root.add_child(world);get_tree().current_scene=world
	player=world.player;trial=player.trial;arena=world.get_node("TrialArena")
	quiet_pairing()
	var manager:=SaveManager.new()
	if "--lf6-control-visuals" in OS.get_cmdline_user_args():
		await capture_controls()
		return finish_central()
	if "--lf6-boundary" in OS.get_cmdline_user_args():
		check(player.load_game(CENTRAL_BOUNDARY),"fresh Central boundary loads normally")
		quiet_pairing()
		var disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(CENTRAL_BOUNDARY))
		check(trial.state=="boundary" && sim.boss().id=="conservator" && trial.layout.get("central_laboratory",false),"fresh boundary retains dedicated human and Central revision")
		check(JSON.parse_string(manager.capture(player).sim)==JSON.parse_string(disk.sim),"fresh boundary preserves exact native ownership")
		check(not sim.world_effect_active("forge_arc_complete"),"suspension does not resolve the ending")
		return finish_central()
	if "--lf6-ending" in OS.get_cmdline_user_args() or "--lf6-after-death" in OS.get_cmdline_user_args():
		var after_death:bool="--lf6-after-death" in OS.get_cmdline_user_args()
		var path:=CENTRAL_AFTER_DEATH if after_death else CENTRAL_ENDING
		check(player.load_game(path),"fresh ending loads normally")
		quiet_pairing()
		var disk:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		check(JSON.parse_string(manager.capture(player).sim)==JSON.parse_string(disk.sim),"fresh ending and all native rewards remain exact")
		check_preserved(disk,manager.capture(player))
		check_controls(true)
		check(sim.world_effect_active("forge_arc_complete") && int(sim.era().index)==3 && not sim.trial_start_story(12,"forge_capstone"),"completed human cannot return or cause a fourth era")
		check(not bool(sim.trial_map_progress().available),"optional configured experiments remain Wave 7")
		var once:=sim.export_json()
		for repeat in 2:
			player.show_central_control()
			check(not player.work_panel._custom_title.contains("last claim") && sim.export_json()==once,"reopening controls does not replay finale or repay")
			check(player.save_game() && player.load_game(),"ordinary repeated save/load retains ending")
			quiet_pairing()
			check(sim.export_json()==once,"repeat load pays nothing")
			check_controls(true)
		if not after_death:
			var owned:Dictionary=JSON.parse_string(once)
			var prior_drops:=WorldDrops.capture(world)
			# Inject a fatal open-world hit to isolate post-ending ownership. The
			# separate Central recovery fixture dies to natural human releases.
			player.combat.invulnerable_left=0
			player.combat.take_hit(1000000000,"physical","ending ownership fixture")
			var drops:=WorldDrops.capture(world)
			var expected_pack:Dictionary={}
			# Inventory may retain zero-count spent IDs; a death pack contains
			# positive owned quantities only, under the existing drop contract.
			for id in owned.economy.inventory:
				if int(owned.economy.inventory[id])>0:expected_pack[id]=int(owned.economy.inventory[id])
			check(drops.bundles.size()==prior_drops.bundles.size()+1 && drops.bundles.back().contents==expected_pack,"later death transfers every positive material quantity to one recoverable pack")
			var fallen:Dictionary=JSON.parse_string(sim.export_json())
			check(fallen.equipment==owned.equipment && fallen.economy.pack_items==owned.economy.pack_items && sim.world_effect_active("forge_arc_complete"),"world death retains ending, equipped gear and pack items")
			check_controls(true)
			check(player.save_game(CENTRAL_AFTER_DEATH),"normal save retains later death ownership for separate process")
		return finish_central()
	var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/lf5b-published-clear.json.gz")
	var file:=FileAccess.open("user://lf6-start.json",FileAccess.WRITE)
	file.store_string(packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8());file.close()
	if not check(manager.read("user://lf6-start.json",player),"frozen LF5B saved ownership restores"):return finish_central()
	quiet_pairing()
	check(ResonanceEvent.publish(player,"user://lf6-prepared.json").ok,"existing second publication opens Central")
	quiet_pairing()
	before_world=manager.capture(player)
	check_controls(false)
	check(sim.trial_story_runs().size()==3 && bool(sim.trial_story_runs()[2].available),"existing third site opens only after both physical awards")
	await _native_route()
	check(player.global_position.distance_to(annex_entry)<.15,"finale returns to the exact Central approach")
	check(sim.world_effect_active("forge_arc_complete") && int(sim.era().index)==3,"real final human fight resolves once without another era")
	check(player.work_panel._custom_title=="The last claim is released","normal final return presents the once-only story resolution")
	var settled:=sim.export_json()
	if "--lf6-save-failure" in OS.get_cmdline_user_args():
		check(player.central_ending_save_pending && not FileAccess.file_exists(FAILED_ENDING),"failed automatic ending write keeps live ownership visibly unsaved")
		check(FileAccess.get_file_as_bytes(checkpoint_path())==last_boundary_bytes,"failed ending write leaves preceding checkpoint intact")
		check(not player.save_game() && player.central_ending_save_pending,"failed ordinary save retains the retry state")
		check_controls(true,true)
		check(not sim.trial_start_story(12,"forge_capstone") && sim.export_json()==settled,"failed save cannot reopen or repay the ending")
		player.set_meta("active_world_save_path",checkpoint_path())
		player.show_central_control()
		var retry:Button
		for button:Button in player.work_panel.find_children("*","Button",true,false):
			if button.text=="Retry ending save":retry=button
		check(retry!=null && not retry.disabled,"failed ending exposes an enabled save-retry button")
		var retry_started:=Time.get_ticks_msec()
		if retry!=null:retry.pressed.emit()
		print("LF6_ENDING_RETRY checkpoint_and_panel_ms=",Time.get_ticks_msec()-retry_started)
		check(not player.central_ending_save_pending && sim.export_json()==settled,"actual retry button saves without repeating settlement")
	else:
		check(not player.central_ending_save_pending,"ordinary final return completes the ending checkpoint")
	var automatic:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(checkpoint_path()))
	check(JSON.parse_string(automatic.sim)==JSON.parse_string(settled) && automatic.get("trial_boundary",{}).is_empty(),"return checkpoint contains the exact ending and haul outside the Trial")
	check_controls(true)
	var after:=manager.capture(player)
	check_preserved(before_world,after)
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
	if "--lf6-save-failure" in OS.get_cmdline_user_args():
		last_boundary_bytes=FileAccess.get_file_as_bytes(checkpoint_path())
		player.set_meta("active_world_save_path",FAILED_ENDING)

func _boundary_restore() -> void:
	await super._boundary_restore()
	for pickup in get_tree().get_nodes_in_group("pickups"):pickup.set_physics_process(false)
	check(SaveManager.new().write_data(CENTRAL_BOUNDARY,SaveManager.new().capture(player)),"retain Central boundary for separate process")

func checkpoint_path() -> String:
	return "user://lf6-active-boundary.json"

func check_controls(captured:bool, pending:bool=false) -> void:
	var sites:=world.get_node("FrontierSites") as FrontierSites
	check(sites.control_label!=null && sites.control_label.text.contains("CONTROL: YOURS" if captured else "CONTROL: LOCKED"),"existing outer door visibly reflects saved control ownership")
	check(sites.control_label.text.contains("SAVE NEEDED")==pending && player.central_ending_save_pending==pending,"control panel accurately reports unsaved ending")
	check(is_equal_approx(sites.control_lever.rotation.z,PI*.5 if captured else 0.0),"physical control handle retains the released orientation")

func check_preserved(before:Dictionary, after:Dictionary) -> void:
	for key in ["blocks","stations","broken_blocks","cracked_blocks","contraptions","leylines","resource_nodes","world_seed","world_profile","loot_kill_counter"]:
		check(JSON.parse_string(JSON.stringify(after.get(key)))==JSON.parse_string(JSON.stringify(before.get(key))),"ending preserves world ownership: "+key)
	var comparator:Node=load("res://tests/second_resonance_terrain.gd").new()
	check(comparator.same_drops(before.world_drops,after.world_drops),"loose drops and death packs preserve exact ownership and float32 pose tolerance")
	comparator.free()

func capture_controls() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf6"))
	for phase in ["before","captured"]:
		check(player.load_game("user://lf6-prepared.json" if phase=="before" else CENTRAL_ENDING),"rendered control state restores through normal load")
		quiet_pairing()
		player.work_panel.close_panel()
		var lab:Dictionary=world.terrain.map.laboratories[2]
		world.terrain.ensure_area(lab.position,32)
		player.global_position=lab.approach[-1]+Vector3.UP*.1
		player.velocity=Vector3.ZERO
		player.set_physics_process(true)
		await frames(10)
		var aim:Vector3=lab.position+Vector3(0,1.7,lab.size.z*.5)
		player.look_at(Vector3(aim.x,player.global_position.y,aim.z))
		var offset:=aim-player.camera.global_position
		player.spring_arm.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
		await frames(4)
		check_controls(phase=="captured")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../captures/lf6/control-"+phase+".png")
		player.interact()
		check(player.work_panel.is_open(),"rendered control page opens through physical E")
		for i in 8:await get_tree().process_frame
		check(player.work_panel._root.get_global_rect().size.y<get_viewport().get_visible_rect().size.y && player.work_panel._title.global_position.y>0,"control page settles inside the viewport")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../captures/lf6/control-"+phase+"-page.png")
	player.show_central_control(true)
	for i in 8:await get_tree().process_frame
	check(player.work_panel._root.get_global_rect().size.y<get_viewport().get_visible_rect().size.y,"finale fits the viewport")
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../captures/lf6/finale-page.png")

func finish_central() -> void:
	print("LF6_CENTRAL ",checks," checks, ",failures," failures; ",walked_metres," m actual route; prior encounters forced, final human live")
	get_tree().quit(1 if failures else 0)
