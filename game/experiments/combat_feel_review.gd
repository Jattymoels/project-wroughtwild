extends Node3D
## Real game presentation with paused actors and effects for inspection.
var player: WroughtwildPlayer
var hands: FirstPersonHands
var output := ""

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/combat-feel")
	DirAccess.make_dir_recursive_absolute(output)
	var world: Sandpit = preload("res://scenes/sandpit.tscn").instantiate()
	add_child(world)
	player = world.player
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.set_process_unhandled_input(false)
	world.set_process(false)
	world.mob_packs.set_process(false)
	world.mob_packs.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		enemy.set_physics_process(false)
	player.rotation.y = 0
	player.spring_arm.rotation.x = -0.12
	hands = player.camera.get_node("FirstPersonHands")
	hands.set_process(false)
	hands._process(0.0)
	equip("iron_mace")
	var attacker := Enemy.spawn(self,&"cinder_archer",player.global_position+Vector3(-3,-0.9,3))
	attacker.set_physics_process(false)
	attacker.force_attack()
	player.hud.damage_compass.set_process(false)
	await capture("incoming")
	get_window().size = Vector2i(1920,1080)
	await capture("incoming-1080")
	get_window().size = Vector2i(1280,720)
	player.hud.damage_compass.clear()
	attacker.queue_free()
	cast("prototype_heavy_strike")
	await capture("strike")
	cast("prototype_area_strike")
	await capture("sweep")
	equip("hunting_bow")
	cast("prototype_bow_shot")
	await capture("bow")
	equip("frost_sceptre")
	cast("prototype_frost_nova")
	await capture("nova")
	clear_effects()
	player.combat.sim.unequip("weapon")
	hands.refresh_weapon()
	hands.sample(2.0)
	# Inspect the actual three projectile models side-on, not replacement
	# display meshes, since a head-on arrow is necessarily a small point.
	for i in 3:
		var id: StringName = [&"prototype_bow_shot",&"prototype_ember_bolt",&"prototype_frost_orb"][i]
		var at := player.global_position+Vector3((i-1)*1.5,0.6,-3.4)
		var shot := SkillProjectile.launch(id,player.combat,self,at,Vector3(1,0,-0.2),0,[])
		shot.set_physics_process(false)
		shot.set_process(false)
		var label := Label3D.new()
		label.text = player.combat.skills[id].display_name
		label.font_size = 30
		label.pixel_size = 0.0025
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)
		label.global_position = at+Vector3(0,0.35,0)
	player.hud.notify("Arrow · ember lance · rotating frost shards: existing projectile rules, distinct shapes.")
	await capture("projectiles")
	print("CODEX_COMBAT_FEEL_REVIEW 7 captures")
	get_tree().quit()

func equip(base: String) -> void:
	var sim := player.combat.sim
	sim.equip_pack_item(sim.roll_item_into_pack(base,"plain",1,19))
	hands.refresh_weapon()
	hands.sample(0.0)

func clear_effects() -> void:
	for effect in get_tree().get_nodes_in_group("skill_cast_effects"):
		effect.get_parent().remove_child(effect)
		effect.queue_free()
	for child in get_children():
		if child is SkillProjectile:
			remove_child(child)
			child.queue_free()

func cast(id: StringName) -> void:
	clear_effects()
	player.combat.cooldowns[id] = 0.0
	player.combat.use_skill(id)
	hands.sample(0.06)
	for effect in get_tree().get_nodes_in_group("skill_cast_effects"):
		effect._process(0.04)
		effect.set_process(false)
	for child in get_children():
		if child is SkillProjectile:
			child.set_physics_process(false)
	player.hud.notify("%s · normal committed cast, paused for inspection" % player.combat.skills[id].display_name)

func capture(id: String) -> void:
	for i in 5:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	if get_viewport().get_texture().get_image().save_png(output.path_join(id+".png")) != OK:
		printerr("FAIL: screenshot ",id)
		get_tree().quit(1)
