extends "res://tests/laboratory_trial.gd"
## Forced outcomes prove routes and transactions. See the separate live hybrid fights.
var first_event := ""

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	sim.set_campaign_policy("living_frontier_wave4")
	world=preload("res://scenes/sandpit.tscn").instantiate()
	world.world_profile="living_frontier_wave3"
	world.world_seed=77
	get_tree().root.add_child(world)
	get_tree().current_scene=world
	player=world.player
	trial=player.trial
	arena=world.get_node("TrialArena")
	quiet_pairing()
	var manager:=SaveManager.new()
	if "--lf5b-boundary" in OS.get_cmdline_user_args():
		check(manager.read("user://lf5-pairing-suspended.json",player),"fresh Pairing boundary: "+manager.last_error)
		quiet_pairing()
		check(trial.active() && trial.state=="boundary" && String(trial.layout.run_id)=="deep_forge","fresh process restores the second laboratory, not Annex")
		check(not sim.world_effect_active("lf5_pairing_victory") && sim.material_count("warden_eye")==0,"suspension is not victory")
		var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://lf5-pairing-suspended.json"))
		check(JSON.parse_string(manager.capture(player).sim)==JSON.parse_string(disk.sim),"fresh boundary retains exact native ownership")
		return finish_pairing()
	var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/lf4-published-applied.json.gz")
	var file:=FileAccess.open("user://lf5b-start.json",FileAccess.WRITE)
	file.store_string(packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	file.close()
	if not check(manager.read("user://lf5b-start.json",player),"published LF4 applied save opens Pairing: "+manager.last_error):return finish_pairing()
	quiet_pairing()
	first_event=sim.resonance_json()
	check(sim.trial_story_runs().size()==2 && bool(sim.trial_story_runs()[1].available),"only two laboratories are exposed after first publication")
	check(not sim.trial_start_story(2,"forge_capstone") && not bool(sim.trial_map_progress().available),"human finale and configured trials remain closed")
	await _native_route()
	check(specimens_seen.has("lf_paired_boar"),"ordered specimen actually instantiated in Pairing encounters")
	check(player.global_position.distance_to(annex_entry)<.15,"exact return to physical Pairing site")
	await frames(4)
	check(sim.resonance_json()==first_event && int(sim.era().index)==3 && JSON.parse_string(sim.resonance_second_json()).phase=="applied","normal Pairing return publishes second event and preserves the first")
	check(sim.world_effect_active("lf5_pairing_victory") && sim.material_count("warden_eye")==1,"one useful Trial settlement and first-clear Eye")
	check(manager.write("user://lf5b-clear.json",player),"save completed Pairing ownership")
	var pending: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(checkpoint_path()+".previous"))
	check(JSON.parse_string(pending.sim).economy.resonance_second.phase=="pending","actual safe return retained a second pending checkpoint")
	check(manager.write_data("user://lf5c-real-return-pending.json",pending),"retain normal-return pending evidence")
	finish_pairing()

func quiet_pairing() -> void:
	world.set_physics_process(false)
	world.mob_packs.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.combat.invulnerable_left=100000 # route fixture only
	trial.set_process(false)

func finish_pairing() -> void:
	print("LF5B_PAIRING ",checks," checks, ",failures," failures; ",walked_metres," m actual movement; encounter outcomes forced; publication_ms=",world.get_meta("last_resonance_publication_ms",0))
	get_tree().quit(1 if failures else 0)

func _start_native_route() -> bool:
	var lab: Dictionary=world.terrain.map.laboratories[1]
	for site: Dictionary in world.terrain.map.laboratories:
		if String(site.id).contains("pairing"): lab=site
	var at: Vector3=lab.position
	world.terrain.ensure_area(at,32)
	var approach: PackedVector3Array=lab.approach
	player.global_position=approach[-6]+Vector3.UP*1.2
	player.velocity=Vector3.ZERO
	player.set_physics_process(true)
	print("LF5B_APPROACH initial=",player.global_position," endpoint=",approach[-1]," help=",player.hud.help_visible())
	await _settle_player()
	for i in range(approach.size()-5,approach.size()):
		if not await _walk_to(approach[i],.2): return false
	var gate: StaticBody3D
	for door in get_tree().get_nodes_in_group("laboratory_gates"):
		if String(door.get_meta("run_id",""))=="deep_forge": gate=door
	if not check(gate!=null,"existing Pairing front body supplies the entry"): return false
	var aim:=gate.global_position
	var delta:=aim-player.camera.global_position
	player.look_at(Vector3(aim.x,player.global_position.y,aim.z))
	player.spring_arm.rotation.x=atan2(delta.y,Vector2(delta.x,delta.z).length())
	await frames(2)
	print("LF5B_DOOR player=",player.global_position," camera=",player.camera.global_position," gate=",gate.global_position," probe=",player.aim_probe())
	check(player.aim_probe().get("target")==gate,"ordinary E ray reaches the actual front door")
	player.interact()
	check(player.work_panel.is_open(),"physical Pairing interaction opens Trial preview")
	annex_entry=player.global_position
	gate.call("_enter",player)
	if not check(trial.active() && bool(trial.layout.get("laboratory",false)),"door enters the policy-scoped laboratory"): return false
	await _settle_player()
	await _settle_navigation(arena.dungeon)
	var early_branches:=0
	for stage: Dictionary in trial.layout.stages:
		if int(stage.index)<=2: early_branches+=stage.choices.size()
	check(arena.dungeon.laboratory_apparatus.size()==early_branches,"solid containment apparatus dresses every early branch")
	check(arena.dungeon.laboratory_records.size()==3,"collection, later human intervention and failsafe evidence precede victory")
	for fixture: TrialFixture in arena.dungeon.laboratory_records:
		var before:=sim.export_json()
		if not await _reach(fixture,"laboratory evidence "+fixture.title): return false
		player.interact()
		check(player.work_panel.is_open() && sim.export_json()==before,"E inspection is readable and pays no reward")
		player.work_panel.close_panel()
	return true

func _clear_encounter() -> void:
	for enemy in trial.trial_enemies():
		if enemy.enemy_id=="lf_paired_boar":
			specimens_seen[enemy.enemy_id]=true
			check(enemy.get_node_or_null("FrontierHostLook")!=null,"paired specimen has its actual tells")
	await super._clear_encounter()

func checkpoint_path() -> String:
	return "user://lf5-pairing-boundary.json"

func _boundary_restore() -> void:
	await super._boundary_restore()
	var manager:=SaveManager.new()
	check(manager.write_data("user://lf5-pairing-suspended.json",manager.capture(player)),"retain exact suspended checkpoint before normal-return publication overwrites the active path")
