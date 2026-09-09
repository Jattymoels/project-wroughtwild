extends "res://tests/forge_traversal.gd"
var world: Sandpit
var specimens_seen: Dictionary={}
var annex_entry:=Vector3.ZERO
var baseline_nodes:=0

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	sim.set_campaign_policy("living_frontier_wave4")
	world=preload("res://scenes/sandpit.tscn").instantiate()
	world.world_profile="living_frontier_wave3"
	world.world_seed=77
	get_tree().root.add_child(world)
	get_tree().current_scene=world # Match the actual generated-world save host.
	world.set_physics_process(false)
	world.mob_packs.set_physics_process(false)
	player=world.player
	player.class_panel.choose("warden")
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.combat.invulnerable_left=100000
	trial=player.trial
	trial.set_process(false)
	arena=world.get_node("TrialArena")
	baseline_nodes=world.terrain.resource_stream.records.size()
	check(sim.trial_story_runs().size()==1,"successor exposes one bounded laboratory Trial")
	check(not sim.trial_start_story(7,"deep_forge") && not sim.trial_start(7,""),"older story and legacy bypass remain closed")
	await _native_route()
	check(specimens_seen.has("lf_red_boar") && specimens_seen.has("lf_blue_boar"),"both real single-influence specimen scenes encountered")
	check(player.global_position.distance_to(annex_entry)<.15,"Trial returns to the exact existing Annex approach")
	check(JSON.parse_string(sim.resonance_json()).phase=="dormant" && int(sim.era().index)==1,"LF-4B victory cannot yet trigger progression")
	print("LF4B_LABORATORY ",checks," checks, ",failures," failures; ",walked_metres," m actual walking")
	get_tree().quit(1 if failures else 0)

func _start_native_route() -> bool:
	var lab: Dictionary=world.terrain.map.laboratories[0]
	for site: Dictionary in world.terrain.map.laboratories:
		if String(site.id).contains("annex"): lab=site
	var at: Vector3=lab.position
	world.terrain.ensure_area(at,32)
	var approach: PackedVector3Array=lab.approach
	player.global_position=approach[-6]+Vector3.UP*1.2
	player.velocity=Vector3.ZERO
	player.set_physics_process(true)
	print("LF4B_APPROACH initial=",player.global_position," endpoint=",approach[-1]," help=",player.hud.help_visible())
	await _settle_player()
	for i in range(approach.size()-5,approach.size()):
		if not await _walk_to(approach[i],.2): return false
	var gate: StaticBody3D=get_tree().get_first_node_in_group("laboratory_gates")
	if not check(gate!=null,"existing Annex front body supplies the entry"): return false
	var aim:=gate.global_position
	var delta:=aim-player.camera.global_position
	player.look_at(Vector3(aim.x,player.global_position.y,aim.z))
	player.spring_arm.rotation.x=atan2(delta.y,Vector2(delta.x,delta.z).length())
	await frames(2)
	print("LF4B_DOOR player=",player.global_position," camera=",player.camera.global_position," gate=",gate.global_position," probe=",player.aim_probe())
	check(player.aim_probe().get("target")==gate,"ordinary E ray reaches the actual front door")
	player.interact()
	check(player.work_panel.is_open(),"physical Annex interaction opens Trial preview")
	annex_entry=player.global_position
	gate.call("_enter",player)
	if not check(trial.active() && bool(trial.layout.get("laboratory",false)),"door enters the policy-scoped laboratory"): return false
	await _settle_player()
	await _settle_navigation(arena.dungeon)
	var early_branches:=int(trial.layout.stages[0].choices.size()+trial.layout.stages[1].choices.size())
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
		if enemy.enemy_id in ["lf_red_boar","lf_blue_boar"]:
			specimens_seen[enemy.enemy_id]=true
			check(enemy.get_node_or_null("FrontierHostLook")!=null,"released specimen has its real influence presentation")
	await super._clear_encounter()

func checkpoint_path() -> String:
	return "user://lf4-laboratory-boundary.json"
