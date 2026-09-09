extends "res://tests/living_frontier_workshop_flow.gd"
## Fresh paid Wave 3 economy. Travel and formation time are compressed;
## no inventory, source stock, station, unlock or Catalyst grants are used.
const TRAIL_SAVE := "user://lf3-paid-trail.json"
var receipts: Array = []

func _ready() -> void:
	world_seed=77
	world_profile="living_frontier_wave3"
	_build_world(world_seed)
	player.class_panel.choose("warden")
	freeze_fixtures()
	set_physics_process(false)
	_run_lf.call_deferred()

func _run_lf() -> void:
	var manager:=SaveManager.new()
	if "--lf3-trail-restore" in OS.get_cmdline_user_args():
		var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(TRAIL_SAVE))
		if not check(manager.read(TRAIL_SAVE,player),"fresh process restores paid Wave 3 journey: "+manager.last_error): return finish_trail()
		freeze_fixtures()
		check(world_profile=="living_frontier_wave3" && _sim().leyline_save()==saved.leylines,"exact profile, outcomes, partial stock and formation survive")
		var restored: Dictionary=JSON.parse_string(_sim().export_json())
		var expected: Dictionary=JSON.parse_string(saved.sim)
		# The published importer omits empty (unearned) mastery lists. Compare
		# the owned state, retaining every actual earned entry and practice value.
		for state: Dictionary in [restored,expected]:
			for skill in state.economy.earned_mastery.keys():
				if state.economy.earned_mastery[skill].is_empty(): state.economy.earned_mastery.erase(skill)
		check(restored==expected,"manufactured ownership, paid gear, XP and host death exact")
		check(_sim().contraption_save()==saved.contraptions,"no incidental signal, work or heat mutation")
		check(kindling_active(),"manufactured Ember remains invested in persistent Kindling")
		check(JSON.parse_string(JSON.stringify(manager.capture(player).blocks))==saved.blocks,"paid host-reward bricks survive restart")
		check(terrain.map.laboratories.size()==3 && terrain.map.future_transformations.size()==2,"all sites and inactive regions retain identity")
		return finish_trail()
	check(_sim().inventory().is_empty() && _sim().foundry().plate.is_empty(),"empty opening; no supplied Catalyst or infrastructure")
	if not await gather("wood",70) or not craft("workbench_kit"): return finish_trail()
	bench=await place_station("workbench_kit",Vector2i(8,0))
	if bench==null: return finish_trail()
	bench.interact(player)
	var catalogue:=player.work_panel.catalogue
	catalogue.select_recipe("wooden_cudgel")
	catalogue.quantity=1
	catalogue._render_detail()
	var wood:=_sim().material_count("wood")
	var pack_count:=_sim().pack_items().size()
	check(not catalogue._action.disabled,"ordinary cudgel available from gathered wood")
	catalogue._action.pressed.emit()
	check(_sim().material_count("wood")==wood-4 && _sim().pack_items().size()==pack_count+1,"real catalogue pays for first weapon")
	check(_sim().equip_pack_item(pack_count),"equip the actually crafted ordinary cudgel")
	player.work_panel.close_panel()
	if not await hunt_red(): return finish_trail()
	check(_sim().material_count("red_salt")==4,"actual boar rewards four Salt")
	if not craft("timber_frame",2,bench) or not await gather("fieldstone",6) or not craft("mason_yard_kit",1,bench): return finish_trail()
	var yard:=await place_station("mason_yard_kit",Vector2i(8,4))
	if yard==null: return finish_trail()
	if not craft("timber_wedge",4) or not await gather("split_stone",16) or not craft("dress_stone",8,yard): return finish_trail()
	if not await gather("iron_ore",12) or not craft("forge_kit",1,bench): return finish_trail()
	forge=await place_station("forge_kit",Vector2i(8,8))
	if forge==null or not await gather("raw_clay",16): return finish_trail()
	if not craft("fire_red_brick",2,forge): return finish_trail()
	check(_sim().material_count("red_salt")==0 && _sim().material_count("rustclay_brick")==8,"the hunt funds useful ordinary bricks before any Catalyst")
	if not await place_paid_brick(player.spawn_position+Vector3(13,0,0)): return finish_trail()
	if not await place_paid_brick(player.spawn_position+Vector3(15,0,0)): return finish_trail()
	check(_sim().material_count("rustclay_brick")==4,"four reward-funded bricks pay two building cubes")
	# 22 ingots and 36 charcoal are the unchanged five-recipe total.
	if not await gather("wood",160): return finish_trail()
	for trip in 8:
		var batches:=mini(3,22-trip*3)
		if not await gather("iron_ore",batches*2) or not craft("smelt_iron",batches,forge): return finish_trail()
	if not craft("charcoal",18,forge): return finish_trail()
	for pair in [["red_home_margin","ember",7],["blue_home_margin","frost",6],["green_home_margin","preserving",6],["white_home_margin","impact",6]]:
		var source:=find_host(String(pair[0]))
		for lot in int(pair[2]):
			if not await draw_lot(source): return finish_trail()
		if not await paid_catalyst(String(pair[1])): return finish_trail()
	var white:=find_host("white_home_margin")
	for lot in 2:
		if not await draw_lot(white): return finish_trail()
	check(int(white.state().lot)==8 && white.state().claim.is_empty(),"first White manifestation fully exhausted and claimed")
	check(_sim().material_count("white_mineral")==32,"useful remaining White has one ordinary inventory owner")
	var blocked:=PackedStringArray()
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		if not source.supported(): blocked.append(source.source_id)
	check(not get_tree().paused && not player.trial.active() && player.combat.life>0,"formation proof uses active overworld state")
	for step in 60: _sim().leyline_tick(10,blocked)
	check(int(white.state().manifestation)==1,"accepted 600 active seconds form exactly one White manifestation")
	for lot in 4:
		if not await draw_lot(white): return finish_trail()
	if not await paid_catalyst("piercing"): return finish_trail()
	for id in ["ember","frost","preserving","impact","piercing"]:
		check(_sim().material_count(id+"_catalyst")==1,"all five choices owned entirely through paid manufacture: "+id)
	await demonstrate_foundry()
	await walk_trail()
	check(manager.write(TRAIL_SAVE,player),"save useful construction and complete no-luck progression")
	finish_trail()

func draw_lot(source: LeylineSource) -> bool:
	await aim_at(source)
	if not check(source.supported(),"ordinary source is accessible: "+source.source_id): return false
	player.interact()
	var before:=_sim().inventory().duplicate(true)
	for step in int(source.state().steps)-int(source.state().work):
		if not await press(String(source.state().next_work)): return false
	var s:=source.state()
	if not check(s.claim.size()==1 && s.claim.has(s.material),"selected drought lot has no rare Catalyst result"): return false
	if not await press("Collect "+Hud.pretty(String(s.material))): return false
	check(_sim().material_count(String(s.material))==int(before.get(s.material,0))+16,"exact raw lot transfers through normal controls")
	for id in ["ember","frost","preserving","impact","piercing"]:
		check(_sim().material_count(id+"_catalyst")==int(before.get(id+"_catalyst",0)),"extraction added zero found Catalysts")
	player.work_panel.close_panel()
	return true

func paid_catalyst(id: String) -> bool:
	if not await forge_catalyst(id): return false
	receipts.append({"identity":id,"inputs":_sim().recipe("forge_faint_"+id).inputs,"found_catalysts":0})
	return true

func hunt_red() -> bool:
	var h: Dictionary=terrain.map.frontier_hosts[0]
	terrain.ensure_area(h.position,28)
	player.global_position=h.position+Vector3(0,1,5)
	player.velocity=Vector3.ZERO
	var pack: Dictionary={}
	for p: Dictionary in mob_packs.packs:
		if String(p.get("frontier_host_id",""))==String(h.id): pack=p
	mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
	var host: Enemy=pack.members[0]
	player.set_physics_process(true)
	player.combat.set_physics_process(true)
	var casts:=0
	for frame in 60*45:
		if not is_instance_valid(host) or host.life<=0 or player.combat.life<=0: break
		var to: Vector3=(host.global_position-player.global_position)*Vector3(1,0,1)
		var distance:=to.length()
		var forward:=to.normalized()
		player.look_at(player.global_position+forward)
		player.camera.look_at(host.global_position+Vector3.UP*.7)
		var move:=forward if distance>1.5 else Vector3.ZERO
		if host.state in ["windup","release"]: move=-forward if distance<host.release_radius+.35 else Vector3.ZERO
		var local:=player.global_basis.inverse()*move
		player.test_walk=Vector2(local.x,local.z)
		for skill in _sim().skill_bar():
			var definition: Dictionary=player.combat.skills.get(skill,{})
			if definition.get("delivery","")=="dash": continue
			if definition.get("delivery","") in ["cone","strike"] and distance>player.combat.strike_reach(skill): continue
			if player.combat.use_skill(skill): casts+=1; break
		await get_tree().physics_frame
	player.test_walk=Vector2.ZERO
	freeze_fixtures()
	var dead:=not is_instance_valid(host) or host.life<=0
	check(dead && player.combat.life>0 && casts>0,"ordinary paid starting build defeats real habitat Red boar")
	print("LF3_PAID_HUNT casts=",casts," life=",player.combat.life)
	await collect()
	return dead && player.combat.life>0

func walk_trail() -> void:
	var sites:=get_node("FrontierSites") as FrontierSites
	check(sites.trail_marks.size()>2,"repeated artificial marks form one complete trail")
	var sources:=_sim().leyline_save()
	var ownership:=_sim().export_json()
	var machines:=_sim().contraption_save()
	for mark: MeshInstance3D in sites.trail_marks:
		var at: Vector3=mark.get_meta("walk_position")
		terrain.ensure_area(at,10)
		player.global_position=at+Vector3.UP*1.2
		check(mark.visible && mark.get_child_count()==0,"visible non-blocking mark along real approach")
	var lab: Dictionary=terrain.map.laboratories[0]
	check(player.global_position.distance_to(lab.position)<8,"following marks reaches Collection Annex exterior")
	check(_sim().leyline_save()==sources && _sim().export_json()==ownership && _sim().contraption_save()==machines,"trail gives no free reward, stock, work, heat or campaign advance")
	await snap("trail-terminus")
	var mark: MeshInstance3D=sites.trail_marks[2]
	var at:=mark.position
	var ground:=terrain.surface_position(floori(at.x),floori(at.z))
	terrain.ensure_area(ground,16)
	player.global_position=ground+Vector3(0,1.2,3)
	check(place(&"block",Vector3i(floori(at.x),ceili(ground.y),floori(at.z))),"ordinary paid block can occupy a later trail mark")
	await get_tree().process_frame
	sites.refresh_buildings()
	check(not mark.visible,"artificial dressing yields to the player's paid construction")

func snap(label: String) -> void:
	if DisplayServer.get_name()=="headless": return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf3"))
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../captures/lf3/"+label+".png")

func finish_trail() -> void:
	var file:=FileAccess.open("res://../build/lf3/paid-trail-restart.json" if "--lf3-trail-restore" in OS.get_cmdline_user_args() else "res://../build/lf3/paid-trail.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"manufactured":receipts},"  "))
	file.close()
	print("LF3_PAID_TRAIL ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func freeze_fixtures() -> void:
	super.freeze_fixtures()
	for actor in [player,player.placement,player.combat,player.spring_arm,mob_packs]: actor.set_physics_process(false)
	mob_packs.set_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
