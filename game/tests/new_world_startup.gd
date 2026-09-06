extends Node3D
## The real class chooser and SaveManager from an empty world. Test files live
## in the isolated review project; no default/user save is read or changed.
const CONTROLS := preload("res://scripts/world_seed_controls.gd")
const SAVE := "res://new_world_startup_test.json"
var checks := 0
var failures := 0

class LaunchWorld extends Sandpit:
	var generations := 0
	var fail_generation := false
	func _ready() -> void: pass # Exercise the normal pre-generation state explicitly in headless.
	func _build_world(value: int) -> void:
		generations += 1
		if fail_generation:
			terrain.map.clear()
			return
		super._build_world(value)

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)

func launch(seed_text: String, path: String) -> LaunchWorld:
	var world := preload("res://scenes/sandpit.tscn").instantiate()
	world.set_script(LaunchWorld)
	check(world.world_profile=="frontier_v6","fresh normal Sandpit defaults to V6 before this historical fixture selects V5")
	world.world_profile = "frontier_v5" # Real historical world and finite pressure ledger.
	get_tree().root.add_child(world)
	get_tree().current_scene = world # Match normal player.world_root() capture/restore.
	world.set_physics_process(false)
	var controls := CONTROLS.new()
	world.add_child(controls)
	world.seed_controls = controls
	controls.configure(world,seed_text,path)
	return world

func freeze(world: LaunchWorld) -> void:
	world.player.set_physics_process(false)
	world.player.combat.set_physics_process(false)
	world.player.placement.set_physics_process(false)
	world.mob_packs.set_physics_process(false)
	world.terrain.set_process(false)

func reach_boundary(world: LaunchWorld) -> bool:
	# Normal physical route/reward interactions; forced hostile kills are the
	# existing lifecycle fixture technique, not a build/difficulty measurement.
	var trial := world.player.trial
	var sim: WroughtwildSim = world.player.combat.sim
	trial.seed_source.seed = 7147
	trial.set_process(false)
	if not trial.begin_run("forge_tyrant"): return false
	for stage_index in 4:
		if trial.state!="exploring": return false
		var room: Dictionary = trial.arena.dungeon.rooms.get("%d:0" % stage_index,{})
		if room.is_empty(): return false
		world.player.global_position = room.door.global_position+Vector3(0,.6,1.5)
		trial.interact_fixture(room.door)
		for round_index in 30:
			if trial.trial_enemies().is_empty() and trial.wave_queue.is_empty(): break
			for enemy in trial.trial_enemies():
				enemy.set_physics_process(false)
				enemy.take_damage(1000000000)
			for hazard in trial._hazards(): hazard.cancel()
			trial._tick_spatial(1)
			await get_tree().physics_frame
		for hazard in trial._hazards(): hazard.cancel()
		trial._process(0)
		if trial.state!="reward": return false
		world.player.global_position = trial.arena.dungeon.reward.global_position+Vector3(0,.6,1.5)
		trial.interact_fixture(trial.arena.dungeon.reward)
		if not trial.current_offer.is_empty(): trial.accept_boon(String(trial.current_offer[0].id))
		elif trial.state=="reward": trial.skip_offer()
		await get_tree().physics_frame
	return trial.state=="boundary" and not String(sim.trial_checkpoint()).is_empty()

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	_run.call_deferred()

func _run() -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var pristine := sim.export_json()
	for text in ["0","1","2147483647"," 31 "]:
		check(CONTROLS.parse_seed(text).valid,"valid seed is accepted: "+text)
	for text in ["","-1","2147483648","99999999999999999999","1.5","1e2","words"]:
		check(not CONTROLS.parse_seed(text).valid,"invalid seed is refused without coercion: "+text)
	var empty_argument := CONTROLS.argument_seed(PackedStringArray(["--world-seed="]))
	check(empty_argument.provided and not CONTROLS.parse_seed(empty_argument.text).valid,"empty explicit CLI seed cannot silently become random")
	check(not CONTROLS.argument_seed(PackedStringArray()).provided,"missing CLI seed is distinguishable from malformed input")
	check(CONTROLS.argument_seed(PackedStringArray(["--world-seed=0"])).text=="0","explicit zero survives CLI parsing")
	var samples := {}
	for i in 16:
		var value := CONTROLS.random_seed()
		check(value>=0 and value<=CONTROLS.MAX_SEED,"random seed stays in the exact saved range")
		samples[value] = true
	check(samples.size()>1,"fresh random choices are not a fixed seed or preset slot")
	var failed_world := launch("314",SAVE)
	# Reusing a host is the important ownership boundary: failed generation
	# must retain its drops, and only a successful explicit New World clears it.
	var old_drop_owner:=Node3D.new()
	failed_world.add_child(old_drop_owner)
	var old_pickup:Pickup=Pickup.scatter(old_drop_owner,Vector3(20,1,20),{"wood":11},73,0)[0]
	old_pickup.set_physics_process(false)
	var old_bundle:=preload("res://scenes/dropped_bundle.tscn").instantiate() as DroppedBundle
	old_bundle.contents={"split_stone":5}
	old_drop_owner.add_child(old_bundle)
	old_bundle.global_position=Vector3(22,0,20)
	var prior_drops:=WorldDrops.capture(failed_world)
	var unrelated_owner:=Node3D.new()
	get_tree().root.add_child(unrelated_owner)
	var unrelated_pickup:Pickup=Pickup.scatter(unrelated_owner,Vector3(50,1,50),{"wood":2},74,0)[0]
	unrelated_pickup.set_physics_process(false)
	var unrelated_drops:=WorldDrops.capture(unrelated_owner)
	failed_world.fail_generation = true
	var before_failed_choice := sim.export_json()
	var before_failed_bar := failed_world.player.combat.bar_skills()
	check(failed_world.player.class_panel.choose("ranger"),"real class choice can precede a controlled generation failure")
	check(failed_world.seed_controls.loading and failed_world.seed_controls._preparing.is_visible_in_tree() and failed_world.generations==0,"preparing feedback appears before synchronous generation begins")
	await get_tree().process_frame
	await get_tree().process_frame
	check(failed_world.generations==1 and failed_world.terrain.map.is_empty(),"controlled failed generation leaves an empty world")
	check(WorldDrops.capture(failed_world)==prior_drops,"failed new-world generation retains the old host's nested pickup and death bundle")
	check(sim.export_json()==before_failed_choice and failed_world.player.combat.bar_skills()==before_failed_bar,"failed launch restores exact pre-choice class, economy and skill loadout")
	check(not failed_world.player.is_physics_processing() and not failed_world.player.combat.is_physics_processing() and not failed_world.player.is_processing_unhandled_input(),"failed launch keeps movement, combat and save hotkeys paused")
	check(failed_world.player.class_panel.is_open() and failed_world.seed_controls._backdrop.is_visible_in_tree() and not failed_world.seed_controls.finished,"failed launch reopens the same class chooser over its backdrop")
	check(failed_world.seed_controls.field.text=="314" and failed_world.seed_controls.message.text.contains("Choose another seed"),"failed launch keeps the chosen seed and displays an actionable error without rerolling")
	check(failed_world.player.class_panel.choose("kindler"),"failure restored the ability to choose a different class")
	await get_tree().process_frame
	await get_tree().process_frame
	check(failed_world.generations==2 and sim.export_json()==before_failed_choice and failed_world.player.combat.bar_skills()==before_failed_bar,"a second failed class choice cannot accumulate kits or progression")
	check(WorldDrops.capture(failed_world)==prior_drops,"retrying a refused new world cannot discard its existing loose ownership")
	failed_world.fail_generation = false
	failed_world.seed_controls.field.text = "77"
	failed_world.seed_controls._validate()
	check(failed_world.player.class_panel.choose("warden"),"the same failed-launch chooser accepts a deliberate new seed and class")
	await get_tree().process_frame
	await get_tree().process_frame
	freeze(failed_world)
	check(failed_world.generations==3 and failed_world.world_seed==77 and not failed_world.terrain.map.is_empty() and failed_world.seed_controls.finished,"retry prepares the new selected world once after two refused attempts")
	check(not failed_world.player.class_panel.is_open() and failed_world.player.is_processing_unhandled_input(),"successful retry releases normal play from the same chooser")
	check(WorldDrops.capture(failed_world)=={"version":1,"pickups":[],"bundles":[]},"successful explicit new-world start removes prior owned pickups and death bundles, including nested ones")
	check(is_instance_valid(old_drop_owner) and WorldDrops.capture(unrelated_owner)==unrelated_drops,"new-world cleanup preserves unrelated scene nodes and another root's loose drops")
	failed_world.free()
	unrelated_owner.free()
	check(sim.import_json(pristine),"fresh fixture state after the controlled failure and successful retry")
	var world := launch("bad seed",SAVE)
	check(world.generations==0 and world.terrain.map.is_empty(),"chooser does not generate a speculative world")
	check(not world.player.is_physics_processing() and not world.player.is_processing_unhandled_input(),"empty-world chooser prevents movement and save/load hotkeys")
	check(world.player.class_panel.is_open(),"seed controls share the existing class decision")
	var buttons: Array = []
	for choice in world.player.class_panel._choices.get_children(): buttons.append(choice.get_child(0))
	check(buttons.all(func(button: Button): return button.disabled),"malformed seed disables class launch buttons")
	world.seed_controls.field.text = "2147483647"
	world.seed_controls._validate()
	check(buttons.all(func(button: Button): return not button.disabled),"valid chosen seed re-enables every class option")
	await get_tree().process_frame
	await get_tree().process_frame
	var rect: Rect2 = world.player.class_panel._root.get_global_rect()
	var viewport := get_viewport().get_visible_rect()
	check(rect.position.y>=viewport.position.y and rect.end.y<=viewport.end.y+1,"initial seed/class chooser fits the normal viewport (%s in %s)" % [rect,viewport])
	check(world.player.class_panel.choose("warden"),"normal class API accepts the starting class")
	check(world.generations==0 and world.seed_controls.loading,"successful launch also presents its preparing frame before generation")
	await get_tree().process_frame
	await get_tree().process_frame
	freeze(world)
	check(world.generations==1 and world.world_seed==2147483647 and not world.terrain.map.is_empty(),"one class choice generates exactly the upper-range selected seed once")
	check(not world.player.class_panel.is_open() and world.player.is_processing_unhandled_input(),"launch releases normal play without another class or Continue prompt")
	check(world.player.hud._help.find_child("WorldIdentity",true,false).text.contains("World seed: 2147483647"),"current seed is visible in existing Help metadata")
	sim.add_material("wood",17)
	world.player.global_position += Vector3(2,0,0)
	var saved_position := world.player.global_position
	var saved_economy := sim.export_json()
	check(world.player.save_game(SAVE),"real save operation writes the selected world's state to an isolated test path")
	var bytes_before := FileAccess.get_file_as_bytes(SAVE)
	world.free()
	check(sim.import_json(pristine),"fixture starts a clean simulated launch")
	world = launch("0",SAVE)
	check(world.seed_controls.continue_button!=null,"existing ordinary save appears in the same chooser")
	var continued: bool = world.seed_controls.continue_saved()
	check(continued,"Continue uses normal validated load from the empty world: "+world.player.hud._notice.text)
	freeze(world)
	check(world.generations==1 and world.world_seed==2147483647 and world.world_profile=="frontier_v5","Continue generates the saved V5 identity once, ignoring the proposed fresh seed")
	check(world.player.global_position==saved_position and sim.export_json()==saved_economy,"Continue preserves exact saved player position, class and economy")
	check(FileAccess.get_file_as_bytes(SAVE)==bytes_before,"Continue does not rewrite or replace its source save")
	check(not world.player.class_panel.is_open() and world.player.is_processing_unhandled_input(),"restored class skips duplicate class decision and releases controls")
	var identity := world.player.hud._help.find_child("WorldIdentity",true,false) as Label
	check(identity!=null and identity.text.contains("World seed: 2147483647"),"restored Help shows saved seed rather than pending fresh seed")
	check(await reach_boundary(world),"normal Tyrant route and reward APIs reach a valid suspension boundary")
	var trial := world.player.trial
	world.player.global_position = trial.arena.dungeon.boundary.global_position+Vector3(0,.6,1.5)
	world.player.combat.life = world.player.combat.max_life*.4312345678901234
	world.player.combat.cooldowns[&"prototype_dash"] = 2.751234567890123
	var boundary_life := world.player.combat.life
	var boundary_economy := sim.export_json()
	var boundary_loot := sim.trial_loot().duplicate(true)
	var boundary_choices := sim.trial_run_state().duplicate(true)
	check(world.player.save_game(SAVE+".trial"),"normal save_game suspends the actual cleared boundary")
	var boundary_bytes := FileAccess.get_file_as_bytes(SAVE+".trial")
	var boundary_file: Dictionary = JSON.parse_string(boundary_bytes.get_string_from_utf8())
	trial.on_player_died() # Abandon only this fixture's in-memory run before fresh launch.
	world.free()
	check(sim.import_json(pristine),"clear player state before suspended-run startup")
	world = launch("123",SAVE+".trial")
	check(world.seed_controls.continue_button!=null and world.generations==0,"suspended save uses the same Continue button without generating a fresh map")
	continued = world.seed_controls.continue_saved()
	check(continued,"Continue validates and restores the real suspended payload: "+world.player.hud._notice.text)
	freeze(world)
	world.player.trial.set_process(false)
	check(world.generations==1 and world.world_seed==2147483647 and world.world_profile=="frontier_v5","suspended Continue builds only its saved V5 identity")
	check(world.player.trial.active() and world.player.trial.state=="boundary" and not world.player.class_panel.is_open(),"valid suspension restores the cleared run without duplicate class decision")
	check(world.player.combat.life==boundary_life and world.player.combat.cooldowns[&"prototype_dash"]==2.751234567890123,"startup suspension grants no life or cooldown reset")
	check(sim.export_json()==boundary_economy and sim.trial_loot()==boundary_loot and sim.trial_run_state()==boundary_choices,"startup suspension preserves exact deposited economy, unbanked loot and temporary choices")
	check(FileAccess.get_file_as_bytes(SAVE+".trial")==boundary_bytes,"suspended Continue leaves source checkpoint bytes untouched")
	check(not sim.trial_restore_checkpoint(boundary_file.trial_boundary.checkpoint),"active restored checkpoint cannot redeposit its inventory")
	world.player.trial.on_player_died()
	world.free()
	check(sim.import_json(pristine),"clean launch state restored before invalid-suspension probe")
	var manager := SaveManager.new()
	var invalid: Dictionary = JSON.parse_string(bytes_before.get_string_from_utf8())
	invalid.world_seed = 6442450943
	check(manager.write_data(SAVE+".overflow",invalid),"fixture writes a seed that would wrap to the saved seed in signed32")
	world = launch("66",SAVE+".overflow")
	check(not world.seed_controls.continue_saved(),"Continue rejects an overflowing outer seed despite an intact matching wrapped ledger")
	check(world.generations==0 and sim.export_json()==pristine and not world.player.is_physics_processing(),"overflow refusal precedes economy import, terrain generation and physics release")
	world.free()
	invalid.world_seed = 2147483647
	invalid["trial_boundary"] = {"version":1,"built_floor":0,"checkpoint":"invalid"}
	check(manager.write_data(SAVE+".invalid",invalid),"fixture writes a deliberately invalid suspended payload")
	world = launch("77",SAVE+".invalid")
	check(not world.seed_controls.continue_saved(),"Continue refuses invalid suspended trial through the real validator")
	check(world.generations==0 and world.terrain.map.is_empty() and sim.export_json()==pristine,"invalid suspension mutates neither world generation nor class/economy")
	check(world.player.class_panel.is_open() and not world.player.is_physics_processing(),"failed Continue leaves the same seed/class decision available")
	world.free()
	invalid.erase("trial_boundary")
	invalid.erase("contraptions")
	check(manager.write_data(SAVE+".missing-ledger",invalid),"fixture writes a V5 save with missing finite pressure state")
	world = launch("88",SAVE+".missing-ledger")
	check(not world.seed_controls.continue_saved(),"Continue refuses missing pressure ledger through the real validator")
	check(world.generations==0 and sim.export_json()==pristine,"missing finite-source state cannot refill or mutate the starting player")
	world.free()
	invalid.erase("world_seed")
	invalid.erase("world_profile")
	invalid.erase("resource_nodes")
	check(manager.write_data(SAVE+".seedless",invalid),"fixture writes a seedless legacy schema-2 payload")
	world = launch("99",SAVE+".seedless")
	check(not world.seed_controls.continue_saved(),"empty generated host refuses a seedless save before importing the player")
	check(world.generations==0 and sim.export_json()==pristine and not world.player.is_physics_processing(),"seedless generated-world refusal preserves economy and the pending chooser")
	world.free()
	for path in [SAVE,SAVE+".previous",SAVE+".invalid",SAVE+".invalid.previous",SAVE+".missing-ledger",SAVE+".missing-ledger.previous",SAVE+".seedless",SAVE+".seedless.previous",SAVE+".overflow",SAVE+".overflow.previous",SAVE+".trial",SAVE+".trial.previous"]:
		if FileAccess.file_exists(path): DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	print("NEW_WORLD_STARTUP: %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
