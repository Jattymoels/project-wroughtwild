extends "res://experiments/combat_feel_review.gd"
## Captures actual committed Foundry rules and runtime effects. No save writes.
var review_title: Label

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/foundry")
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
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	player.rotation.y = 0
	player.spring_arm.rotation.x = -0.3
	hands = player.camera.get_node("FirstPersonHands")
	hands.set_process(false)
	var sim := player.combat.sim
	for skill in ["prototype_ember_bolt","prototype_bow_shot"]: sim.learn_skill(skill)
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer"]: sim.foundry_event(event)
	sim.add_materials({"frost_catalyst":2,"preserving_catalyst":2,"piercing_catalyst":2,"warding_vanguard":2,"iron_ingot":100})
	sim.foundry_place_skill(1,1,"prototype_ember_bolt")
	sim.foundry_place(1,0,"ember")
	sim.foundry_place_kind(2,0,"frost_catalyst")
	player.foundry_panel.open_panel()
	for i in 8: await get_tree().process_frame
	player.foundry_panel._inspect_cell(1,0)
	await capture("smoulder-foundry-720")
	sim.record_world_effect("stonecut_blocks")
	sim.foundry_remove(1,1)
	sim.foundry_remove(1,0)
	sim.foundry_remove(2,0)
	sim.foundry_place_skill(2,2,"prototype_ember_bolt")
	sim.foundry_place(1,2,"ember")
	sim.foundry_place_kind(0,3,"frost_catalyst")
	sim.foundry_place_kind(1,3,"preserving_catalyst")
	get_window().size = Vector2i(1920,1080)
	player.foundry_panel.refresh()
	for i in 8: await get_tree().process_frame
	player.foundry_panel._inspect_cell(0,3)
	await capture("kept-rime-foundry-1080")
	player.foundry_panel.close_panel()
	player.hud.visible = false
	get_window().size = Vector2i(1280,720)
	var caption := CanvasLayer.new()
	add_child(caption)
	review_title = Label.new()
	review_title.position = Vector2(28,30)
	review_title.add_theme_font_size_override("font_size",24)
	caption.add_child(review_title)
	equip("ember_wand")
	player.combat._mutation_cache.clear()
	var at := player.global_position + Vector3(0,-0.65,-4.5)
	var target := Enemy.spawn(world,&"stone_husk",at)
	target.set_physics_process(false)
	target.life = 1000
	target.apply_ignite(100,0,0,sim.skill_mutation("prototype_ember_bolt"))
	var field := FoundryField.spawn(player.combat,&"prototype_ember_bolt",at,"impact",sim.skill_mutation("prototype_ember_bolt"))
	field.set_physics_process(false)
	field.advance(0.6)
	review_title.text = "KEPT RIME\nSmoulder burn + retained impact field"
	await capture("kept-rime-combat")
	target.queue_free()
	field.cancel()
	for piece in sim.foundry().plate: sim.foundry_remove(piece.row,piece.col)
	sim.foundry_place_skill(1,1,"prototype_heavy_strike")
	sim.foundry_place(1,0,"edge")
	sim.foundry_place_kind(2,0,"piercing_catalyst")
	player.combat._mutation_cache.clear()
	equip("iron_mace")
	var wave := SkillProjectile.launch(&"prototype_heavy_strike",player.combat,world,player.global_position+Vector3(0,0.0,-3.2),Vector3(0.25,0,-1),0,[])
	wave.set_physics_process(false)
	review_title.text = "RAZOR WAVE\nA melee strike becomes a piercing projectile"
	await capture("razor-wave")
	wave.cancel()
	for piece in sim.foundry().plate: sim.foundry_remove(piece.row,piece.col)
	sim.foundry_place_skill(1,1,"prototype_bow_shot")
	sim.foundry_place(1,0,"frost")
	sim.foundry_place_kind(2,0,"warding_vanguard")
	player.combat._mutation_cache.clear()
	equip("hunting_bow")
	var ward := FoundryField.spawn(player.combat,&"prototype_bow_shot",player.global_position-Vector3(0,0.7,2),"guard",sim.skill_mutation("prototype_bow_shot"))
	ward.set_physics_process(false)
	review_title.text = "RIME VEIL\nA bow cast plants a projectile-catching ward"
	await capture("rime-veil")
	ward.cancel()
	await evolution_capture(world)
	print("CODEX_FOUNDRY_MUTATION_REVIEW 8 captures")
	get_tree().quit()

func evolution_capture(world: Sandpit) -> void:
	var sim := player.combat.sim
	for piece in sim.foundry().plate: sim.foundry_remove(piece.row,piece.col)
	for event in ["recipe:workbench_kit","first_kill:ash_hound"]: sim.foundry_event(event)
	sim.add_materials({"ember_catalyst":3,"frost_catalyst":2,"iron_ingot":100})
	sim.foundry_place_skill(1,1,"prototype_heavy_strike")
	sim.foundry_place(1,0,"haste")
	sim.foundry_place(2,1,"vigour")
	sim.foundry_place_kind(2,0,"ember_catalyst")
	player.combat._mutation_cache.clear()
	review_title.visible = false
	get_window().size = Vector2i(1920,1080)
	player.foundry_panel.open_panel()
	for i in 8: await get_tree().process_frame
	player.foundry_panel._inspect_cell(2,0)
	await capture("ember-workings-1080")
	player.foundry_panel.close_panel()
	get_window().size = Vector2i(1280,720)
	equip("iron_mace")
	var target := Enemy.spawn(world,&"stone_husk",player.global_position+Vector3(0,-.65,-3.5))
	target.set_physics_process(false)
	target.life = 1000
	var form := sim.skill_mutation("prototype_heavy_strike")
	target.apply_ignite(100,0,0,form)
	FoundryReactions.ignited(player.combat,target,form)
	FoundryReactions.contact(player.combat,target,&"prototype_heavy_strike",form,{})
	for puff in get_tree().get_nodes_in_group("foundry_puffs"):
		puff.set_process(false)
		puff.elapsed = .22
		puff._sample()
	for mote in get_tree().get_nodes_in_group("foundry_returns"): mote.set_physics_process(false)
	review_title.visible = true
	review_title.text = "FLASHFIRE + BLOODFIRE\nRelease stored burn; move in to collect its warm cinder"
	await capture("ember-recovery-combat")
	for group in ["foundry_puffs","foundry_returns"]:
		for node in get_tree().get_nodes_in_group(group): node.free()
	for piece in sim.foundry().plate: sim.foundry_remove(piece.row,piece.col)
	sim.foundry_place_skill(2,2,"prototype_heavy_strike")
	sim.foundry_place(1,2,"ember")
	sim.foundry_place_kind(0,3,"frost_catalyst")
	sim.foundry_place_kind(1,3,"ember_catalyst")
	player.combat._mutation_cache.clear()
	form = player.combat.mutation(&"prototype_heavy_strike")
	FoundryReactions.contact(player.combat,target,&"prototype_heavy_strike",form,{})
	for field in get_tree().get_nodes_in_group("foundry_fields"):
		if field.mode != "steam": continue
		field.set_physics_process(false)
		field.advance(.81)
	for puff in get_tree().get_nodes_in_group("foundry_puffs"):
		puff.set_process(false)
		puff.elapsed = .30
		puff._sample()
	target._flash_left = 0
	target._refresh_look()
	review_title.text = "STEAM PLUME\nSmoulder evolves through Ember into three fire/cold eruptions"
	await capture("steam-plume-combat")
