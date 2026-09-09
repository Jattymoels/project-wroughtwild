extends "res://tests/living_frontier_flow.gd"
const HABITAT_SAVE := "user://lf3-habitat.json"

func _ready() -> void:
	world_seed = 77
	world_profile = "living_frontier_wave3"
	_build_world(world_seed)
	player.class_panel.choose("warden")
	freeze_fixtures()
	set_physics_process(false)
	if "--lf3-trail-visuals" in OS.get_cmdline_user_args(): _trail_visuals.call_deferred()
	elif "--lf3-visuals" in OS.get_cmdline_user_args(): _visuals.call_deferred()
	else: _run_habitat.call_deferred()

func _run_habitat() -> void:
	var manager := SaveManager.new()
	if "--lf3-restore" in OS.get_cmdline_user_args():
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(HABITAT_SAVE))
		check(manager.read(HABITAT_SAVE,player),"fresh process restores new profile: "+manager.last_error)
		freeze_fixtures()
		check(world_profile=="living_frontier_wave3" && _sim().leyline_save()==saved.leylines,"saved identity and exact source ownership survive launch")
		check(_sim().contraption_save()==saved.contraptions,"separate machinery state exact on restart")
		check(JSON.parse_string(JSON.stringify(manager.capture(player).blocks))==saved.blocks,"paid regional construction survives fresh process")
		for h: Dictionary in terrain.map.frontier_hosts:
			check(_sim().world_effect_active("host_defeated:"+String(h.id)),"defeated finite host remains defeated")
			var p := host_pack(String(h.id))
			mob_packs._spawn_pack(p,mob_packs.pack_position(p))
			check(p.members.is_empty(),"no restart repopulation or second loot")
		var pickups: Array = []
		var bundles: Array = []
		WorldDrops._collect(self,pickups,bundles)
		check(bundles.size()==saved.world_drops.bundles.size() && bundles.size()==1,"one unrecovered bundle survives restart")
		for bundle: DroppedBundle in bundles:
			check(JSON.parse_string(JSON.stringify(bundle.contents))==saved.world_drops.bundles[0].contents,"unrecovered death bundle retains exact contents")
			bundle.interact(player)
			bundle.interact(player)
		for raw in ["red_salt","white_mineral","blue_flake","green_resin"]:
			check(_sim().material_count(raw)==4,"recover each material exactly once: "+raw)
		return finish_habitat()
	check(_sim().inventory().is_empty(),"no supplied inventory")
	check(terrain.map.frontier_hosts.size()==4 && terrain.map.laboratories.size()==3 && terrain.map.future_transformations.size()==2,"complete bounded first-save geography")
	var source_before := _sim().leyline_save()
	for h: Dictionary in terrain.map.frontier_hosts:
		terrain.ensure_area(h.position,24)
		player.global_position = h.position + Vector3(0,1.2,22)
		var p := host_pack(String(h.id))
		mob_packs._spawn_pack(p,mob_packs.pack_position(p))
		check(p.members.size()==1,"one isolated member")
		var host: Enemy = p.members[0]
		var look := host.get_node("FrontierHostLook") as FrontierHostLook
		check(host.influence==h.influence && not host.visual_id.is_empty() && look.scar!=null,"familiar authored skin and local matching scar")
		for i in 150: await get_tree().physics_frame
		check(host.state=="idle" && host.life==host.max_life,"calm habit precedes contact")
		check(host._habit_index>0 && host.global_position.distance_to(h.position)<5,"visits nearby habit point without leaving its clearing")
		if String(h.influence) in ["white","green"]:
			player.global_position = host.global_position+Vector3(0,0,3)
			for i in 50: await get_tree().physics_frame
			check(host.state=="flee" && player.combat.life==100,"passive host flees without attack")
		host.set_physics_process(false)
		player.global_position = h.position+Vector3(0,1,24)
		host.take_typed(host.max_life*2,"physical")
		var drops_before := WorldDrops.capture(self)
		mob_packs._on_enemy_died(host)
		check(WorldDrops.capture(self)==drops_before,"duplicate death callback pays nothing")
		check(_sim().world_effect_active("host_defeated:"+String(h.id)),"finite identity claimed before loot callbacks")
		if String(h.influence)=="red":
			check(manager.write(HABITAT_SAVE,player) && manager.read(HABITAT_SAVE,player),"red death and loose rewards cross actual save/load")
			freeze_fixtures()
			p=host_pack(String(h.id))
			mob_packs._spawn_pack(p,mob_packs.pack_position(p))
			check(p.members.is_empty(),"saved killed host cannot respawn before collection")
		await collect()
	check(_sim().leyline_save()==source_before,"host life, loot, saves and collection never touch source lots or outcomes")
	for raw in ["red_salt","white_mineral","blue_flake","green_resin"]:
		check(_sim().material_count(raw)==4,"physical pickup supplies four useful raw units: "+raw)
	check(_sim().material_count("hide")==4 && _sim().material_count("raw_reed")==2,"ordinary animal ancestry remains in drops")
	for data: Dictionary in terrain.map.laboratories:
		terrain.ensure_area(data.position,16)
		var end: Vector3=data.position+Vector3(0,1.5,0)
		var start: Vector3=end+Vector3(0,0,8)
		await get_tree().physics_frame
		var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(start,end,1))
		check(not hit.is_empty() && hit.collider.name=="ExteriorBody","laboratory is an actual visible solid exterior")
	if not await gather("wood",20): return finish_habitat()
	for region: Dictionary in terrain.map.future_transformations:
		check(not region.active,"future region remains inactive")
		var at: Vector3=region.position
		terrain.ensure_area(at,16)
		var y:=terrain.surface_position(floori(at.x),floori(at.z)).y
		player.global_position=Vector3(at.x,y+1.2,at.z+3)
		check(place(&"block",Vector3i(floori(at.x),ceili(y),floori(at.z))),"ordinary paid construction inside future region")
	var owned_blocks: Array=manager.capture(player).blocks
	check(manager.write(HABITAT_SAVE,player) && manager.read(HABITAT_SAVE,player),"paid regional construction crosses reload")
	freeze_fixtures()
	check(JSON.parse_string(JSON.stringify(manager.capture(player).blocks))==JSON.parse_string(JSON.stringify(owned_blocks)),"lab and region composition preserves paid occupied space")
	var bad:=manager.capture(player)
	bad.leylines=""
	check(not manager.apply(player,bad) && _sim().leyline_save()==source_before,"missing mandatory source owner refuses atomically")
	player.combat.take_hit(10000,"physical")
	await get_tree().process_frame
	check(_sim().material_count("red_salt")==0,"death transfers host rewards out of inventory")
	check(manager.write(HABITAT_SAVE,player),"save finite deaths, sources and unrecovered bundle")
	finish_habitat()

func host_pack(id: String) -> Dictionary:
	for pack: Dictionary in mob_packs.packs:
		if String(pack.get("frontier_host_id",""))==id: return pack
	return {}

func finish_habitat() -> void:
	print("LF3_HABITAT ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func _visuals() -> void:
	get_window().size=Vector2i(1280,720)
	player.hud.hide()
	player.hide()
	var camera:=Camera3D.new()
	add_child(camera)
	camera.current=true
	camera.fov=55
	var folder:=ProjectSettings.globalize_path("res://../captures/lf3")
	DirAccess.make_dir_recursive_absolute(folder)
	for h: Dictionary in terrain.map.frontier_hosts:
		terrain.ensure_area(h.position,32)
		player.global_position=h.position+Vector3(0,1,26)
		var pack:=host_pack(String(h.id))
		mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
		camera.global_position=h.position+Vector3(6,3.8,7)
		camera.look_at(h.position+Vector3.UP*.7)
		for i in 20: await get_tree().process_frame
		for enemy: Enemy in pack.members: enemy.set_physics_process(false)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder+"/habitat-"+String(h.influence)+".png")
	for lab: Dictionary in terrain.map.laboratories:
		player.global_position=lab.position+Vector3(9,1,13)
		terrain.ensure_area(lab.position,28)
		camera.global_position=lab.position+Vector3(9,6,13)
		camera.look_at(lab.position+Vector3.UP*1.8)
		for i in 15: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder+"/"+String(lab.id)+".png")
	print("LF3_HABITAT_VISUALS seven actual-world views")
	get_tree().quit()

func freeze_fixtures() -> void:
	super.freeze_fixtures()
	for actor in [player,player.placement,player.combat,player.spring_arm,mob_packs]: actor.set_physics_process(false)
	mob_packs.set_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)

func _trail_visuals() -> void:
	get_window().size=Vector2i(1280,720)
	player.hide()
	player.hud.hide()
	var camera:=Camera3D.new()
	add_child(camera)
	camera.current=true
	camera.fov=60
	var sites:=get_node("FrontierSites") as FrontierSites
	var folder:=ProjectSettings.globalize_path("res://../captures/lf3")
	DirAccess.make_dir_recursive_absolute(folder)
	for pair in [["trail-origin",0],["trail-middle",sites.trail_marks.size()/2],["trail-laboratory",sites.trail_marks.size()-1]]:
		var mark: MeshInstance3D=sites.trail_marks[int(pair[1])]
		var at: Vector3=mark.get_meta("walk_position")
		player.global_position=at+Vector3.UP*1.2
		terrain.ensure_area(at,28)
		camera.global_position=at+Vector3(5,3,6)
		camera.look_at(at+Vector3.UP*.65)
		if String(pair[0])=="trail-laboratory": camera.look_at(terrain.map.laboratories[0].position+Vector3.UP*1.7)
		for i in 20: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(folder+"/"+String(pair[0])+".png")
	camera.current=false
	player.hud.show()
	var source:=find_source_for_picture()
	await aim_at(source)
	player.interact()
	for i in 10: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/field-reading.png")
	var details: Array=player.work_panel.find_children("*","Button",true,false)
	details.reverse()
	for button: Button in details:
		if button.text=="Details" and button.is_visible_in_tree():
			await reveal_control(button)
			button.button_pressed=true
			break
	for i in 10: await get_tree().process_frame
	player.work_panel._scroll.scroll_vertical=int(player.work_panel._scroll.get_v_scroll_bar().max_value)
	for i in 2: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"/field-manufacture.png")
	print("LF3_TRAIL_VISUALS actual field origin, middle, terminus and source information")
	get_tree().quit()

func find_source_for_picture() -> LeylineSource:
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		if source.source_id=="red_home_margin": return source
	return null
