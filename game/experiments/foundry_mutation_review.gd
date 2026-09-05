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
	var target_floor := SkillBurst.solid_ray(player.combat,at+Vector3.UP*2,at+Vector3.DOWN*8)
	if not target_floor.is_empty(): target.global_position=target_floor.position
	target.apply_ignite(100,0,0,sim.skill_mutation("prototype_ember_bolt"))
	FoundryReactions.contact(player.combat,target,&"prototype_ember_bolt",sim.skill_mutation("prototype_ember_bolt"),{})
	var field := FoundryCold.live(player.combat,"emberbed")
	field.set_physics_process(false)
	field.advance(0.6)
	review_title.text = "KEPT RIME\nSmoulder + Emberbed: the same stored burn shared over three pulses"
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
	await ember_builds_capture(world)
	await cold_builds_capture(world)
	print("CODEX_FOUNDRY_MUTATION_REVIEW 22 captures")
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
	target.queue_free()

func ember_builds_capture(world: Sandpit) -> void:
	var sim := player.combat.sim
	for event in ["first_kill:stone_husk","world_effect:stonecut_blocks"]: sim.foundry_event(event)
	var recipes := [
		{"first":"ember","second":"reach","name":"kindling-wildfire","title":"KINDLING + WILDFIRE","sentence":"Light a target with a fuse, then carry its flame into the next rank"},
		{"first":"edge","second":"haste","name":"cinder-flashfire","title":"CINDER EDGE + FLASHFIRE","sentence":"Spend stored burn early and cut a narrow seam through the rank behind"},
		{"first":"plate","second":"ward","name":"furnace-cautery","title":"FURNACE PLATE + CAUTERY","sentence":"Ignition readies an affliction ward; a follow-up hit heats your retaliation"},
	]
	for recipe in recipes:
		for group in ["foundry_fields","foundry_embers","foundry_cold","foundry_puffs","foundry_returns"]:
			for node in get_tree().get_nodes_in_group(group): node.free()
		for piece in sim.foundry().plate: sim.foundry_remove(piece.row,piece.col)
		sim.add_materials({"ember_catalyst":1,"iron_ingot":100})
		sim.foundry_place_skill(1,1,"prototype_heavy_strike")
		sim.foundry_place(1,0,recipe.first)
		sim.foundry_place(2,1,recipe.second)
		sim.foundry_place_kind(2,0,"ember_catalyst")
		player.combat._mutation_cache.clear()
		player.combat._reaction_ready.clear()
		player.combat._action_contexts.clear()
		review_title.visible = false
		get_window().size = Vector2i(1920,1080)
		player.foundry_panel.open_panel()
		for i in 8: await get_tree().process_frame
		player.foundry_panel._inspect_cell(2,0)
		await capture(recipe.name+"-foundry")
		player.foundry_panel.close_panel()
		get_window().size = Vector2i(1280,720)
		var at := player.global_position + Vector3(-1.2,-.65,-3.4)
		var target := Enemy.spawn(world,&"stone_husk",at)
		var other := Enemy.spawn(world,&"stone_husk",at+Vector3(1.5,0,-1.6))
		var rear := Enemy.spawn(world,&"stone_husk",at+Vector3(-1.7,0,-2.6))
		for actor in [target,other,rear]:
			actor.set_physics_process(false)
			actor.life = 1000
			var floor_hit := SkillBurst.solid_ray(player.combat,actor.global_position+Vector3.UP*2,actor.global_position+Vector3.DOWN*8)
			if not floor_hit.is_empty(): actor.global_position = floor_hit.position
		var form := player.combat.mutation(&"prototype_heavy_strike")
		target.apply_ignite(100,0,0,form)
		FoundryReactions.ignited(player.combat,target,form)
		FoundryReactions.contact(player.combat,target,&"prototype_heavy_strike",form,{})
		if recipe.first == "ember":
			FoundryReactions.contact(player.combat,rear,&"prototype_heavy_strike",form,{})
		for effect in get_tree().get_nodes_in_group("foundry_embers"):
			effect.set_physics_process(false)
			if effect.mode=="spark": effect.advance(.08)
			elif effect.mode=="fuse": effect.advance(.45)
			elif effect.mode in ["temper","cautery"]: effect.advance(.01)
		for puff in get_tree().get_nodes_in_group("foundry_puffs"):
			puff.set_process(false)
			puff.elapsed = .2
			puff._sample()
		equip("iron_mace")
		review_title.visible = true
		review_title.text = recipe.title + "  ·  HEAVY STRIKE\n" + recipe.sentence
		if recipe.first == "plate": review_title.text += "\n" + player.combat.verb_text()
		await capture(recipe.name+"-combat")
		for actor in [target,other,rear]: actor.queue_free()

func cold_builds_capture(world: Sandpit) -> void:
	var combat := player.combat
	var sim := combat.sim
	var recipes := [
		{"kind":"frost_catalyst","skill":"prototype_bow_shot","first":"reach","second":"ward","name":"whiteout-stillwater","title":"WHITEOUT + STILLWATER","sentence":"Mist slows incoming shots; a well-timed cast leaves a one-shot ice mirror"},
		{"kind":"frost_catalyst","skill":"prototype_heavy_strike","first":"edge","second":"haste","name":"rime-hoarfrost","title":"RIME EDGE + HOARFROST","sentence":"Cut across the chilled target's flanks and recover movement to reposition"},
		{"kind":"preserving_catalyst","skill":"prototype_heavy_strike","first":"ember","second":"reach","name":"emberbed-afterfield","title":"EMBERBED + AFTERFIELD","sentence":"Store part of the burn in the ground; draw new enemies into the remembered hit"},
		{"kind":"preserving_catalyst","skill":"prototype_bow_shot","first":"vigour","second":"haste","name":"lifebed-lingering","title":"LIFEBED + LINGERING STEP","sentence":"Leave your casting mark, switch skills, then return for a small recovery"},
	]
	for recipe in recipes:
		for group in ["foundry_fields","foundry_embers","foundry_cold","foundry_puffs","foundry_returns","player_projectiles","enemy_projectiles"]:
			for node in get_tree().get_nodes_in_group(group): node.free()
		for piece in sim.foundry().plate: sim.foundry_remove(piece.row,piece.col)
		sim.add_materials({recipe.kind:1,"iron_ingot":100})
		sim.foundry_place_skill(1,1,recipe.skill)
		sim.foundry_place(1,0,recipe.first)
		sim.foundry_place(2,1,recipe.second)
		sim.foundry_place_kind(2,0,recipe.kind)
		combat._mutation_cache.clear()
		combat._reaction_ready.clear()
		combat._action_contexts.clear()
		for id in combat.cooldowns: combat.cooldowns[id]=0
		review_title.visible=false
		get_window().size=Vector2i(1920,1080)
		player.foundry_panel.open_panel()
		for i in 8: await get_tree().process_frame
		player.foundry_panel._inspect_cell(2,0)
		await capture(recipe.name+"-foundry")
		player.foundry_panel.close_panel()
		get_window().size=Vector2i(1280,720)
		equip("hunting_bow" if recipe.skill=="prototype_bow_shot" else "iron_mace")
		var at := player.global_position+Vector3(-.6,-.65,-3.5)
		var target := Enemy.spawn(world,&"stone_husk",at)
		var other := Enemy.spawn(world,&"stone_husk",at+Vector3(1.4,0,0))
		var flank := Enemy.spawn(world,&"stone_husk",at+Vector3(-1.4,0,0))
		for actor in [target,other,flank]:
			actor.set_physics_process(false)
			actor.life=1000
			var floor_hit := SkillBurst.solid_ray(combat,actor.global_position+Vector3.UP*2,actor.global_position+Vector3.DOWN*8)
			if not floor_hit.is_empty(): actor.global_position=floor_hit.position
		var form := combat.mutation(StringName(recipe.skill))
		if recipe.kind=="frost_catalyst": target.apply_chill(35)
		elif recipe.first=="ember": target.apply_ignite(100,0,0,form)
		FoundryReactions.contact(combat,target,StringName(recipe.skill),form,{})
		if recipe.skill=="prototype_bow_shot": combat.use_skill(StringName(recipe.skill))
		for node in get_tree().get_nodes_in_group("player_projectiles"): node.set_physics_process(false)
		var old_position := player.global_position
		var old_pitch := player.spring_arm.rotation.x
		var old_yaw := player.rotation.y
		if recipe.first=="vigour":
			player.global_position+=Vector3(2.4,0,2.5)
			player.rotation.y=.65
			player.spring_arm.rotation.x=-.55
			combat.cooldowns[StringName(recipe.skill)]=1.5
		for effect in get_tree().get_nodes_in_group("foundry_cold"):
			effect.set_physics_process(false)
			effect.advance(.08 if effect.mode=="edge" else .1)
		for puff in get_tree().get_nodes_in_group("foundry_puffs"):
			puff.set_process(false)
			puff.elapsed=.2
			puff._sample()
		review_title.visible=true
		review_title.text=recipe.title+"\n"+recipe.sentence
		if recipe.first=="vigour": review_title.text+="\n"+combat.verb_text()
		await capture(recipe.name+"-combat")
		player.global_position=old_position
		player.spring_arm.rotation.x=old_pitch
		player.rotation.y=old_yaw
		for actor in [target,other,flank]: actor.queue_free()
