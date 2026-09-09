extends "res://tests/forge_traversal.gd"
var world: Sandpit
var specimens_seen: Dictionary={}
var annex_entry:=Vector3.ZERO
var baseline_nodes:=0
const FIRST_RETURN := "user://lf4c-first-return.json"
const CAMPAIGN_SAVE := "user://lf4c-campaign.json"
const RESONANCE := preload("res://scripts/resonance_event.gd")

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
	if "--lf4c-settlement" in OS.get_cmdline_user_args():
		if check(SaveManager.new().read(checkpoint_path(),player),"restore the real first publication for focused settlement checks"):
			await campaign_evidence()
		return finish_campaign()
	if "--lf4c-pending" in OS.get_cmdline_user_args() or "--lf4c-applied" in OS.get_cmdline_user_args():
		await restart_campaign()
		return finish_campaign()
	check(sim.trial_story_runs().size()==1,"successor exposes one bounded laboratory Trial")
	check(not sim.trial_start_story(7,"deep_forge") && not sim.trial_start(7,""),"older story and legacy bypass remain closed")
	await _native_route()
	check(specimens_seen.has("lf_red_boar") && specimens_seen.has("lf_blue_boar"),"both real single-influence specimen scenes encountered")
	check(player.global_position.distance_to(annex_entry)<.15,"Trial returns to the exact existing Annex approach")
	check(RESONANCE.phase(sim)=="applied" && int(sim.era().index)==2,"safe return publishes the real era-two transformation")
	await campaign_evidence()
	finish_campaign()

func finish_campaign() -> void:
	print("LF4C_LABORATORY ",checks," checks, ",failures," failures; ",walked_metres," m actual walking; publication_ms=",world.get_meta("last_resonance_publication_ms",0))
	get_tree().quit(1 if failures else 0)

func campaign_evidence() -> void:
	var manager:=SaveManager.new()
	var pending: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(checkpoint_path()+".previous"))
	var pending_rules: Dictionary=JSON.parse_string(pending.sim).economy
	check(pending_rules.resonance.phase=="pending" && pending_rules.inventory.get("tyrant_heart",0)==1 && not pending_rules.world_effects.has("stonecut_blocks"),"previous checkpoint is the real first-return pending event and one payout")
	check(manager.write_data(FIRST_RETURN,pending),"retain actual first-return checkpoint for fresh-process restart")
	check(sim.material_count("tyrant_heart")==1 && sim.world_effect_active("lf4_annex_victory") && bool(sim.foundry().can_specialise),"one trophy, victory receipt and existing era-two Foundry consequence")
	check(world.terrain.resource_stream.records.size()==baseline_nodes+4 && world.terrain.map.frontier_hosts.size()==5,"four finite ore lots and one extra existing Blue expression")
	var settled:=sim.export_json()
	world.settle_resonance()
	check(not RESONANCE.publish(player,SaveManager.path_for(player)).ok && sim.export_json()==settled,"repeated publication cannot transform or pay again")
	check(sim.set_curio("hill_cairn") && not sim.set_curio("hill_cairn") && int(sim.era().index)==2,"optional remembrance consumes one trophy and changes no era")
	await work_new_ore()
	var pack: Dictionary={}
	for candidate: Dictionary in world.mob_packs.packs:
		if String(candidate.get("frontier_host_id",""))=="lf4_retained_fen_blue": pack=candidate
	if check(not pack.is_empty(),"new host has a distinct finite identity"):
		var at:=world.mob_packs.pack_position(pack)
		world.terrain.ensure_area(at,20)
		world.mob_packs._spawn_pack(pack,at)
		check(pack.members.size()==1,"transformed habitat supplies exactly one Blue host")
		if not pack.members.is_empty():
			var host: Enemy=pack.members[0]
			host.set_physics_process(false)
			host.take_damage(1000000000)
			var once:=WorldDrops.capture(world)
			world.mob_packs._on_enemy_died(host)
			check(WorldDrops.capture(world)==once && sim.world_effect_active("host_defeated:lf4_retained_fen_blue"),"duplicate host callback cannot pay twice")
	check(manager.write(CAMPAIGN_SAVE,player),"save applied terrain, spent trophy, ore depletion and finite host death")
	var complete:=manager.capture(player)
	var mixed:=complete.duplicate(true)
	var broken_rules: Dictionary=JSON.parse_string(mixed.sim)
	broken_rules.economy.world_effects.erase("stonecut_blocks")
	mixed.sim=JSON.stringify(broken_rules)
	check(not manager.apply(player,mixed) && sim.export_json()==complete.sim,"mixed terrain/era candidate rejected before mutation")

func work_new_ore() -> void:
	# Fixture supplies only ordinary forge inputs/fuel. The copper and tin must
	# come from the physically published finite bank and its real heat/work path.
	sim.add_material("charcoal",12)
	for id in ["lf4_fen_ore_0","lf4_fen_ore_1"]:
		var record: Dictionary=world.terrain.resource_stream.records[id]
		var p:=SaveManager._unvec(record.position)
		world.terrain.ensure_area(p,24)
		var node:=world.terrain.resource_stream.materialise(id)
		check(node!=null && not node.workable(),"new alloy deposit retains its charcoal-heat gate")
		player.global_position=p+Vector3(0,1.2,3)
		player.set_physics_process(false)
		var build:=player.placement
		build.set_build_mode_enabled(true)
		player.build_palette.open_panel()
		player.build_palette.select_entry(&"campfire","shape")
		player.build_palette.select_material(&"charcoal")
		player.build_palette.close_panel()
		var before_fuel:=sim.material_count("charcoal")
		var placed:=false
		for offset: Vector2i in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,-1),Vector2i(1,-1),Vector2i(-1,1)]:
			var cell:=Vector3i(floori(p.x)+offset.x,ceili(p.y),floori(p.z)+offset.y)
			cell.y=maxi(cell.y,world.terrain.height_at(cell.x,cell.z))
			build.preview_element={"kind":"volume","axis":0,"cell":cell*2}
			build.preview_visible=true
			if build.try_place_block(): placed=true;break
		build.set_build_mode_enabled(false)
		if not check(placed && sim.material_count("charcoal")==before_fuel-3,"actual charcoal fire pays its existing fuel cost: "+build.preview_reason): return
		var fire: PlacedBlock
		var blocks: Array=[];var nodes: Array=[];var sites: Array=[]
		SaveManager._walk(world,blocks,nodes,sites)
		for block: PlacedBlock in blocks:
			if block.is_fire() and block.global_position.distance_to(p)<3: fire=block
		if not check(fire!=null,"paid physical fire exists beside new ore"): return
		fire.set_process(false)
		fire._process(5)
		check(node.workable(),"ordinary fire heats the actual new deposit")
		var presses:=4 if id.ends_with("0") else 1
		for i in presses:
			fire._process(1)
			var result:=node.work(sim)
			check(int(result.get("granted",0))==2,"contextual work releases two real event ore")
			player._apply_work(node,result)
			for pickup in get_tree().get_nodes_in_group("pickups"):
				if pickup.is_queued_for_deletion(): continue
				player.global_position=pickup.global_position-Vector3(0,.6,0)
				pickup._physics_process(1.0/60.0)
			await frames(1)
		fire._burn_out()
		await frames(2)
	world.terrain.resource_stream.capture()
	check(not world.terrain.resource_stream.records.has("lf4_fen_ore_0") && world.terrain.resource_stream.records["lf4_fen_ore_1"].remaining_units==6,"depleted and partial event lots retain finite ownership")
	sim.add_station("forge_basic")
	sim.add_materials({"iron_ore":32,"wood":70})
	check(bool(sim.craft("smelt_iron",true,"",1,16).crafted),"ordinary mine-order inputs smelt at the basic forge")
	check(bool(sim.craft("iron_fittings",true,"",1,6).crafted) && bool(sim.fulfill_order("reinforce_old_mine").fulfilled),"existing useful mine order earns the bronze recipe's skill requirement")
	var copper:=sim.material_count("copper_ore")
	var tin:=sim.material_count("tin_ore")
	var bronze:=sim.craft("smelt_bronze")
	print("LF4C_BRONZE copper=",copper," tin=",tin," smithing=",sim.skill_level("blacksmithing")," result=",bronze)
	check(bool(bronze.crafted) && sim.material_count("copper_ore")==copper-2 && sim.material_count("tin_ore")==tin-1,"new exploration material makes useful bronze through the existing paid recipe")

func restart_campaign() -> void:
	var manager:=SaveManager.new()
	var pending: bool="--lf4c-pending" in OS.get_cmdline_user_args()
	var path:=FIRST_RETURN if pending else CAMPAIGN_SAVE
	if not check(player.load_game(path),"fresh-process campaign restore"): return
	if pending:
		check(RESONANCE.phase(sim)=="pending" && sim.material_count("tyrant_heart")==1 && int(sim.era().index)==1,"restart first restores pending ownership before deferred safe publication")
		await frames(3)
		check(RESONANCE.phase(sim)=="applied" && int(sim.era().index)==2 && sim.material_count("tyrant_heart")==1,"normal load resumes one complete safe publication")
		check(SaveManager.path_for(player)==path && JSON.parse_string(JSON.parse_string(FileAccess.get_file_as_string(path)).sim).economy.resonance.phase=="applied","publication follows the restored world path")
	else:
		var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
		await frames(3)
		check(JSON.parse_string(sim.export_json())==JSON.parse_string(disk.sim),"applied restart retains exact inventory, milestone and terrain ledger")
		check(not world.terrain.resource_stream.records.has("lf4_fen_ore_0") && world.terrain.resource_stream.records["lf4_fen_ore_1"].remaining_units==6,"restart never regenerates depleted or partial event ore")
		check(sim.material_count("tyrant_heart")==0 && sim.world_effect_active("lf4_heart_remembrance"),"spent first-clear trophy cannot reappear")
		for pack: Dictionary in world.mob_packs.packs:
			if String(pack.get("frontier_host_id",""))=="lf4_retained_fen_blue":
				world.mob_packs._spawn_pack(pack,world.mob_packs.pack_position(pack))
				check(pack.members.is_empty(),"saved finite host death cannot respawn or pay again")
		var before:=sim.export_json()
		world.settle_resonance()
		check(not RESONANCE.publish(player,path).ok && sim.export_json()==before,"applied restart cannot duplicate transformation or milestone")

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
