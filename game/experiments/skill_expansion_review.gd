extends "res://experiments/combat_feel_review.gd"
## Actual game UI and casts. Fixture discoveries never write a player save.
const EXPANSION := [&"prototype_fan_shot",&"prototype_bodkin_shot",&"prototype_driving_blow",&"prototype_reaping_sweep",&"prototype_cinderburst",&"prototype_ashfall"]

func _ready() -> void:
	get_window().size=Vector2i(1280,720)
	output=ProjectSettings.globalize_path("res://../build/codex-aesthetic/skills")
	DirAccess.make_dir_recursive_absolute(output)
	var world: Sandpit=preload("res://scenes/sandpit.tscn").instantiate()
	add_child(world)
	player=world.player
	player.class_panel.choose("ranger")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.set_process_unhandled_input(false)
	world.set_process(false)
	world.mob_packs.set_process(false)
	world.mob_packs.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	player.rotation.y=0
	player.spring_arm.rotation.x=-0.22
	hands=player.camera.get_node("FirstPersonHands")
	hands.set_process(false)
	var sim:=player.combat.sim
	for id in EXPANSION: sim.learn_skill(id)
	for i in 26: sim.note_skill_use("prototype_fan_shot")
	for i in 4: sim.set_bar_slot(i,EXPANSION[i])
	player.combat.loadout_changed.emit()
	player.inventory_panel.open_panel()
	player.inventory_panel.show_guide(true)
	var guide:=player.inventory_panel.guide
	guide.select_filter("Attacks")
	await scroll_to("Fan Shot")
	await capture("skills-720")
	guide.select_page("Kinds")
	await scroll_to("Piercing Catalyst")
	await capture("kinds-720")
	guide.select_page("Progression")
	get_window().size=Vector2i(1920,1080)
	player.inventory_panel._scroll.scroll_vertical=0
	player.inventory_panel._fit_height()
	await capture("progression-1080")
	player.inventory_panel.close_panel()
	get_window().size=Vector2i(1280,720)
	sim.foundry_event("first_kill:cinder_archer")
	sim.add_material("piercing_catalyst",1)
	sim.foundry_place_skill(1,1,"prototype_fan_shot")
	sim.foundry_place(1,0,"reach")
	sim.foundry_place_kind(2,0,"piercing_catalyst")
	player.foundry_panel.open_panel()
	await capture("foundry-720")
	player.foundry_panel.close_panel()
	equip("hunting_bow")
	cast(EXPANSION[0])
	for projectile in get_tree().get_nodes_in_group("player_projectiles"):
		projectile.set_physics_process(false)
		projectile.advance(0.045)
	await capture("fan-shot")
	equip("iron_mace")
	cast(EXPANSION[2])
	await capture("driving-blow")
	cast(EXPANSION[3])
	await capture("reaping-sweep")
	equip("frost_sceptre")
	cast(EXPANSION[4])
	for projectile in get_tree().get_nodes_in_group("player_projectiles"):
		projectile.set_physics_process(false)
		projectile.advance(0.09)
	await capture("cinderburst")
	player.spring_arm.rotation.x=-0.38
	cast(EXPANSION[5])
	var marks:=get_tree().get_nodes_in_group("skill_bursts")
	for mark in marks: mark.set_physics_process(false)
	if marks.is_empty():
		printerr("FAIL: review Ashfall surface cast did not commit")
		get_tree().quit(1)
		return
	marks[0].advance(0.45)
	await capture("ashfall-mark")
	marks[0].advance(0.45)
	await capture("ashfall-burst")
	print("CODEX_SKILL_EXPANSION_REVIEW 10 captures")
	get_tree().quit()

func scroll_to(title: String) -> void:
	for i in 5: await get_tree().process_frame
	var guide:=player.inventory_panel.guide
	for card in guide.get_children():
		if card is PanelContainer:
			var label: Label=card.get_child(0).get_child(0)
			if label.text.begins_with(title):
				player.inventory_panel._scroll.scroll_vertical=int(card.position.y)
				return

func clear_effects() -> void:
	for group in ["skill_cast_effects","player_projectiles","skill_bursts"]:
		for effect in get_tree().get_nodes_in_group(group):
			effect.get_parent().remove_child(effect)
			effect.queue_free()
