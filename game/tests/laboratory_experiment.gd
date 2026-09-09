extends "res://tests/central_trial.gd"
## Actual Central E and keyboard UI controls; synthetic archived campaign access.
const EXPERIMENT_SAVE:="user://lf7-experiment.json"
var selected_offer:Dictionary
var selected_pressure:=""

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	world=preload("res://scenes/sandpit.tscn").instantiate()
	world.scene_file_path="";world.world_profile="living_frontier_wave3";world.world_seed=77
	get_tree().root.add_child(world);get_tree().current_scene=world
	player=world.player;trial=player.trial;arena=world.get_node("TrialArena")
	quiet_pairing()
	var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/lf6-published-ending.json.gz")
	var file:=FileAccess.open("user://lf7-archive.json",FileAccess.WRITE)
	file.store_string(packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8());file.close()
	var started:=Time.get_ticks_msec()
	if not check(player.load_game("user://lf7-archive.json"),"published Wave 6 ending loads normally"):return finish_experiment()
	print("LF7_TRANSITION archive_load_ms=",Time.get_ticks_msec()-started)
	quiet_pairing()
	check_controls(true)
	check(bool(sim.trial_map_progress().available) && int(sim.era().index)==3,"captured apparatus opens configured runs without changing era")
	check(not sim.trial_start_story(77,"forge_capstone"),"human story remains once-only")
	before_world=SaveManager.new().capture(player)
	await reach_central()
	var prior:=sim.export_json()
	var old_offers:=sim.trial_map_offers(1)
	player.interact()
	check(player.work_panel._custom_title.contains("your controls"),"actual E opens captured apparatus")
	await press_button("Configure experiment")
	check(player.work_panel._custom_title.contains("Controlled laboratory"),"physical configuration button reaches the combined offer/tier page")
	check(sim.export_json()==prior && sim.trial_map_offers(1)==old_offers,"opening apparatus consumes no resources or saved roll")
	await press_button("Crossfire")
	check(sim.export_json()==prior,"draft pressure is free and uncommitted")
	await press_button("No extra pressure")
	check(sim.trial_map_offers(1)==old_offers,"switching pressures cannot reroll any unopened offer")
	player.work_panel.close_panel()
	check(player.save_game(EXPERIMENT_SAVE) && player.load_game(EXPERIMENT_SAVE),"ordinary save/reload retains unopened offers")
	quiet_pairing()
	check(sim.trial_map_offers(1)==old_offers,"complete saved offer identities survive normal restore")
	await reach_central()
	player.interact();await press_button("Configure experiment")
	await select_compatible()
	if "--lf7-visuals" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf7"))
		for i in 8:await get_tree().process_frame
		check(player.work_panel._root.get_global_rect().size.y<get_viewport().get_visible_rect().size.y,"combined controls fit the viewport")
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../captures/lf7/configuration.png")
		for button:Button in player.work_panel.find_children("*","Button",true,false):
			if button.text=="Enter run %d"%int(selected_offer.slot+1):
				button.grab_focus()
				for scroll:ScrollContainer in player.work_panel.find_children("*","ScrollContainer",true,false):scroll.ensure_control_visible(button.get_parent().get_parent())
		for i in 8:await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../captures/lf7/reward-preview.png")
	var seed_before:String=JSON.parse_string(sim.export_json()).extra.trial_gate
	check(not sim.trial_start_map(1,0,"invalid",String(old_offers[0].id)) && not sim.trial_start_map(1,0,"","stale_offer"),"invalid pressure and stale identity refuse before entry")
	check(JSON.parse_string(sim.export_json()).extra.trial_gate==seed_before,"refused entry leaves saved batch and remembered settings intact")
	var entered:=Time.get_ticks_msec()
	await press_button("Enter run %d"%int(selected_offer.slot+1))
	print("LF7_TRANSITION entry_ms=",Time.get_ticks_msec()-entered)
	if not check(trial.active(),"actual selected Enter control starts the laboratory"):return finish_experiment()
	await _settle_navigation(arena.dungeon)
	check(trial.layout.laboratory_experiment && not trial.layout.get("central_laboratory",false) && sim.boss().id!="conservator","repeat uses a contained creature, never the defeated human")
	check(trial.layout.run_id==selected_offer.id && trial.layout.pressure==selected_pressure && trial.layout.conditions==selected_offer.conditions,"successful entry freezes the exact previewed identity and conditions")
	check(float(trial.layout.target_haul_multiplier)==1.25 && float(trial.layout.reward_multiplier)==float(selected_offer.reward_multiplier),"only targeted haul receives the configured bonus")
	check(String(sim.trial_map_progress().last_pressure)==selected_pressure && JSON.parse_string(sim.export_json()).extra.trial_gate!=seed_before,"entry commits remembered setting and consumes one saved batch")
	check(not sim.trial_start_map(1,0,"",String(old_offers[0].id)),"active run cannot be replaced with another setting")
	check(not player.save_game(EXPERIMENT_SAVE),"active experiment cannot create a misleading resumable checkpoint")
	trial.on_player_died() # Forced return isolates entry/ownership; separate combat proof uses live damage.
	quiet_pairing()
	check_preserved(before_world,SaveManager.new().capture(player))
	check(sim.world_effect_active("forge_arc_complete") && int(sim.era().index)==3,"configured entry and forced exit retain campaign continuity")
	finish_experiment()

func reach_central() -> void:
	var lab:Dictionary=world.terrain.map.laboratories[2]
	for candidate:Dictionary in world.terrain.map.laboratories:
		if String(candidate.id).contains("central"):lab=candidate
	world.terrain.ensure_area(lab.position,32)
	player.global_position=lab.approach[-3]+Vector3.UP*.4;player.velocity=Vector3.ZERO
	player.set_physics_process(true);await _settle_player()
	for point in lab.approach.slice(-2):
		if not await _walk_to(point,.2):return
	for gate in get_tree().get_nodes_in_group("laboratory_gates"):
		if String(gate.get_meta("run_id",""))=="forge_capstone":central_gate=gate
	var aim:=central_gate.global_position
	var offset:=aim-player.camera.global_position
	player.look_at(Vector3(aim.x,player.global_position.y,aim.z))
	player.spring_arm.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
	await frames(3)
	check(player.aim_probe().get("target")==central_gate,"real Central ray reaches the captured physical controls")

func press_button(prefix:String) -> void:
	var button:Button
	for candidate:Button in player.work_panel.find_children("*","Button",true,false):
		if candidate.text.begins_with(prefix) && not candidate.disabled:button=candidate;break
	if not check(button!=null,"available physical UI button: "+prefix):return
	button.grab_focus()
	for i in 3:await get_tree().process_frame
	var down:=InputEventKey.new();down.keycode=KEY_ENTER;down.physical_keycode=KEY_ENTER;down.pressed=true
	Input.parse_input_event(down)
	await get_tree().process_frame
	var up:=InputEventKey.new();up.keycode=KEY_ENTER;up.physical_keycode=KEY_ENTER;up.pressed=false
	Input.parse_input_event(up)
	for i in 3:await get_tree().process_frame

func select_compatible() -> void:
	for pressure:Dictionary in sim.trial_map_progress().pressures:
		var offers:=sim.trial_map_offers(1,String(pressure.id))
		for i in offers.size():
			if not bool(offers[i].available):continue
			selected_pressure=String(pressure.id)
			await press_button(String(pressure.display_name))
			selected_offer=offers[i].duplicate(true);selected_offer.slot=i
			return
	check(false,"at least one pressure is compatible with the saved tier-one batch")

func finish_experiment() -> void:
	print("LF7_EXPERIMENT ",checks," checks, ",failures," failures; ",walked_metres," m actual approach; synthetic archived campaign access")
	get_tree().quit(1 if failures else 0)
