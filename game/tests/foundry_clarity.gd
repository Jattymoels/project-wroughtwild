extends "res://tests/foundry_flow_review.gd"
## Real controls with native transactions as the oracle. Supplied milestones
## isolate presentation; forge_progression checks combat's practice eligibility.
const SAVE_DIR := "user://foundry-clarity"
const CLASSES := ["warden", "ranger", "kindler"]
var captures := ""

func button_named(root: Node, caption: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node.text == caption and not node.is_queued_for_deletion(): return node
	return null

func visible_text(root: Node) -> String:
	var result := ""
	for node in root.find_children("*", "Control", true, false):
		if node.is_visible_in_tree() and not node.is_queued_for_deletion() and (node is Label or node is RichTextLabel): result += node.text + "\n"
	return result

func hover(control: Control) -> void:
	var event := InputEventMouseMotion.new()
	event.position = control.get_global_rect().get_center()
	get_viewport().push_input(event)
	await settle()

func click(control: Control, mouse_button := MOUSE_BUTTON_LEFT) -> void:
	check(control != null, "requested control exists")
	if control == null: return
	await hover(control)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = control.get_global_rect().get_center()
		event.button_index = mouse_button
		event.pressed = down
		get_viewport().push_input(event)
	await settle()

func click_rail_text(caption: String) -> void:
	var button := button_named(panel._rails, caption)
	check(button != null, "rail action available: " + caption)
	if button == null: return
	panel._list_scroll.ensure_control_visible(button)
	await settle()
	check(panel._list_scroll.get_global_rect().encloses(button.get_global_rect()), "rail action reachable by scrolling")
	await click(button)

func rail_button(axis: String, index: int) -> Button:
	var where := "%s %d" % [axis,index+1]
	for control in panel._grid.get_children():
		if control is Button and (control.tooltip_text.begins_with("The rail of " + where + ",") or control.tooltip_text.contains(" on " + where + ":")): return control
	return null

func held_rail(axis: String, index: int) -> Dictionary:
	for slot in sim.foundry().rails:
		if slot.axis == axis and slot.index == index: return slot
	return {}

func capture(name: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(captures.path_join(name + ".png")) == OK, "capture " + name)

func supply() -> void:
	for event in ["recipe:workbench_kit", "recipe:smelt_iron", "first_kill:ember_whelp", "first_kill:ash_hound", "first_kill:stone_husk", "first_kill:cinder_archer", "first_kill:gloom_crawler", "work:strike_split", "world_effect:old_mine_reinforced"]: sim.foundry_event(event)
	sim.add_materials({"iron_ingot":100,"vanguard":3,"frost_catalyst":3,"preserving_catalyst":3})

func _run() -> void:
	get_window().size = Vector2i(1280,720)
	captures = ProjectSettings.globalize_path("res://../captures/clarity")
	DirAccess.make_dir_recursive_absolute(captures)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	sim = player.inventory.get_sim()
	panel = player.foundry_panel
	player.class_panel.open_panel()
	player._release_mouse()
	await settle()
	check(get_viewport().get_visible_rect().encloses(player.class_panel._root.get_global_rect()), "class explanation and choices fit 720p")
	await capture("class-choice-720")
	get_window().size = Vector2i(1920,1080)
	await settle()
	check(get_viewport().get_visible_rect().encloses(player.class_panel._root.get_global_rect()), "class choices also fit 1080p")
	await capture("class-choice-1080")
	get_window().size = Vector2i(1280,720)
	await settle()
	var fresh := sim.export_json()
	await click(button_named(player.class_panel._choices,"Warden"))
	check(sim.foundry().class == "warden", "actual class choice still works")
	if "--foundry-restore-only" in OS.get_cmdline_user_args():
		for id in ["bulwark","sentinel","sharpshooter","fletcher","pyromancer","hearthkeeper"]:
			check(SaveManager.new().read(SAVE_DIR.path_join(id + ".json"),player), "fresh process restores " + id)
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_DIR.path_join(id + "-expected.json")))
			check(sim.export_json() == expected.sim, "exact native ownership, mastery, class and rails survive restart: " + id)
			check(JSON.stringify(sim.foundry_effects()) == expected.effects, "exact effects survive restart: " + id)
			panel.open_panel()
			await settle()
			check(sim.foundry().specialisation == id and visible_text(panel._rails).contains("set and clear patterns freely"), "restored choice retains its arrangement explanation")
			panel.close_panel()
	else:
		supply()
		sim.record_world_effect("stonecut_blocks")
		sim.learn_skill("prototype_ember_bolt")
		for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row,piece.col), "clear inspection plate")
		check(sim.foundry_place_skill(1,1,"prototype_heavy_strike") and sim.foundry_place_skill(2,2,"prototype_ember_bolt"), "two receiving sockets")
		check(sim.foundry_place(1,2,"ember") and sim.foundry_place_kind(1,3,"frost_catalyst") and sim.foundry_place_kind(0,3,"preserving_catalyst") and sim.foundry_place(0,2,"edge"), "branched native route")
		panel.open_panel()
		player._release_mouse()
		await settle()
		var before := sim.export_json()
		var workings := visible_text(panel._workings)
		await click(panel._cell_buttons[Vector2i(1,2)],MOUSE_BUTTON_RIGHT)
		var reading := panel._preview.text
		await hover(panel._cell_buttons[Vector2i(0,0)])
		check(panel._inspection_pin.button_pressed and panel._preview.text == reading, "right-click pins a cell through other hover events")
		await click(panel._inspection_details)
		check(panel._preview.text.contains("CURRENT FLOW") and panel._preview.text.contains("Lift:"), "Details retains state and exact lifting cost")
		for effect in sim.foundry_effects():
			if String(effect.get("form_name","")) != "": check(panel._preview.text.contains(String(effect.description)), "complete native branched description remains readable")
		var right_scroll := panel._list_scroll.scroll_vertical
		await click(panel._preview,MOUSE_BUTTON_WHEEL_DOWN)
		await click(panel._preview,MOUSE_BUTTON_WHEEL_DOWN)
		check(panel._preview.get_v_scroll_bar().value > 0 and panel._list_scroll.scroll_vertical == right_scroll, "inspector wheel scroll is independent of workings")
		await capture("branched-details-720")
		await click(panel._inspection_pin)
		panel._cell_buttons[Vector2i(0,0)].grab_focus()
		await settle()
		check(panel._inspected_cell == Vector2i(0,0) and not panel._inspection_details.button_pressed, "keyboard focus selects another cell and resets detail")
		check(sim.export_json() == before and visible_text(panel._workings) == workings, "inspection controls preserve native state and useful workings")
		panel._on_tray("frost","iron")
		await settle()
		await hover(panel._cell_buttons[Vector2i(1,2)])
		check(panel._preview.text.contains("PLACEMENT REFUSED") and sim.export_json() == before, "occupied preview gives refusal without spending")
		await capture("refusal-720")
		var preview: Dictionary = sim.foundry_preview(2,1,"frost","iron")
		await hover(panel._cell_buttons[Vector2i(2,1)])
		check(bool(preview.valid) and panel._preview.text.contains("AFTER PLACEMENT") and sim.export_json() == before, "legal native preview is explicitly hypothetical and free")
		await capture("preview-720")
		var oracle := WroughtwildSim.new()
		check(oracle.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()), "load native oracle tuning")
		check(oracle.import_json(before) and oracle.foundry_place(2,1,"frost","iron"), "prepare expected native transaction")
		await click(panel._cell_buttons[Vector2i(2,1)])
		check(sim.export_json() == oracle.export_json() and sim.foundry_effects() == preview.effects, "real placement matches native ownership and preview effects exactly")
		sim.consume_material("iron_ingot",sim.material_count("iron_ingot"))
		before = sim.export_json()
		await click(panel._cell_buttons[Vector2i(2,1)])
		check(sim.export_json() == before and panel.message().contains("Re-forging needs"), "unaffordable lifting preserves every piece")
		sim.add_material("iron_ingot",100)
		check(oracle.import_json(sim.export_json()) and oracle.foundry_remove(2,1), "prepare expected paid lift")
		await click(panel._cell_buttons[Vector2i(2,1)])
		check(sim.export_json() == oracle.export_json(), "real paid lifting matches native conservation exactly")
		panel.close_panel()
		for class_id in CLASSES:
			check(sim.import_json(fresh) and sim.foundry_choose_class(class_id), "fresh class " + class_id)
			supply()
			panel.open_panel()
			await settle()
			check(visible_text(panel._rails).contains("unlocks after the Tyrant") and button_named(panel._rails,"Compare Bulwark") == null, "locked specialisation explains its gate")
			sim.record_world_effect("stonecut_blocks")
			for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row,piece.col), "clear class route")
			var pattern := ""
			var axis := ""
			var index := 0
			match class_id:
				"warden":
					pattern = "riposte"; axis = "column"
					check(sim.foundry_place(0,0,"edge") and sim.foundry_place(2,0,"edge"), "Riposte has its native line")
				"ranger":
					pattern = "volley"; axis = "column"; index = 1
					check(sim.foundry_place_skill(1,1,"prototype_bow_shot") and sim.foundry_place(2,1,"reach"), "Volley has its native line")
				"kindler":
					pattern = "pyre"; axis = "row"; index = 1
					check(sim.foundry_place(1,0,"ember") and sim.foundry_place(1,2,"ember"), "Pyre has its native line")
			check(sim.foundry_set_rail(axis,index,pattern), "set native class rail")
			var class_state := sim.export_json()
			var choices: Array = sim.foundry().specialisations
			check(choices.size() == 2, "exactly two native specialisations offered")
			for choice in choices:
				check(sim.import_json(class_state), "restore pre-choice class")
				panel.refresh()
				await settle()
				before = sim.export_json()
				await click_rail_text("Compare " + String(choice.display_name))
				var explanation := visible_text(panel._rails)
				check(explanation.contains("This cannot be changed later"), "permanence precedes committing")
				check(panel._list_scroll.get_global_rect().encloses(panel._specialisation_review.get_global_rect()), "comparison scroll reveals its permanent-choice warning")
				for change in choice.becomes:
					check(explanation.contains(String(change.from.display_name)) and explanation.contains(String(change.to.display_name)) and explanation.contains(String(change.from.condition_text)) and explanation.contains(String(change.from.rule_text)) and explanation.contains(String(change.to.rule_text)), "both native before/after rules and condition shown")
				check(sim.export_json() == before, "comparison cannot spend or specialise")
				await capture(String(choice.id) + "-comparison-720")
				get_window().size = Vector2i(1920,1080)
				await settle()
				check(get_viewport().get_visible_rect().encloses(panel._root.get_global_rect()), "expanded comparison fits 1080p")
				await capture(String(choice.id) + "-comparison-1080")
				get_window().size = Vector2i(1280,720)
				await settle()
				await click_rail_text("Keep comparing")
				check(sim.export_json() == before and panel._pending_specialisation == "", "cancel comparison changes nothing")
				await click_rail_text("Compare " + String(choice.display_name))
				check(oracle.import_json(before) and oracle.foundry_specialise(String(choice.id)), "native specialisation oracle")
				await click_rail_text("Choose " + String(choice.display_name) + " permanently")
				check(sim.export_json() == oracle.export_json() and sim.foundry_effects() == oracle.foundry_effects(), "confirmation applies exactly the native change")
				check(not sim.foundry().can_specialise and sim.foundry().specialisation == choice.id, "committed choice is permanent")
				var inventory: Dictionary = sim.inventory().duplicate(true)
				check(bool(held_rail(axis,index).holds), "grown rail retains its actual native holding condition")
				await click(rail_button(axis,index))
				check(sim.inventory() == inventory and sim.foundry().rails_set == 0, "clearing a grown rail is free")
				var grown: String = ""
				for change in choice.becomes:
					if change.from.id == pattern: grown = String(change.to.id)
				var pattern_button: Button
				for control in panel._rails.get_children():
					if control is Button and control.text.begins_with("Set " + String(sim.foundry_pattern(grown).display_name) + " ("): pattern_button = control
				if pattern_button != null: await click_rail_text(pattern_button.text)
				else: check(false,"grown pattern has its real selection control")
				await click(rail_button(axis,index))
				check(sim.inventory() == inventory and sim.foundry().rails_set == 1, "setting the grown rail is free and does not activate every rail")
				var holding := sim.export_json()
				var breaker := Vector2i(0,0) if class_id == "warden" else Vector2i(2,1) if class_id == "ranger" else Vector2i(1,0)
				check(oracle.import_json(holding) and oracle.foundry_remove(breaker.x,breaker.y), "native broken-line oracle")
				await click(panel._cell_buttons[breaker])
				check(not bool(held_rail(axis,index).holds) and sim.foundry_effects() == oracle.foundry_effects() and sim.export_json() == oracle.export_json(), "grown rail stops when its real condition breaks; no unconditional specialisation power")
				check(rail_button(axis,index).tooltip_text.contains("Not lit:"), "unmet native condition stays explicit on the rail")
				check(sim.import_json(holding), "restore holding line for restart review")
				# Native practice is separate from choice and arrangement; combat qualification has its own suite.
				sim.learn_skill("prototype_frost_orb")
				for practice in 225: sim.note_skill_use("prototype_frost_orb")
				check(sim.combat_skill("prototype_frost_orb").mastery[0].unlocked, "automatic practice unlocks a native milestone without a perk choice")
				check(SaveManager.new().write(SAVE_DIR.path_join(String(choice.id) + ".json"),player), "save class, mastery and rail for separate process")
				var expected := FileAccess.open(SAVE_DIR.path_join(String(choice.id) + "-expected.json"),FileAccess.WRITE)
				expected.store_string(JSON.stringify({"sim":sim.export_json(),"effects":JSON.stringify(sim.foundry_effects())}))
				expected.close()
			panel.close_panel()
			panel.open_panel()
			await settle()
		panel.close_panel()
		var pack := player.inventory_panel
		pack.open_panel()
		pack.show_guide(true)
		await settle()
		before = sim.export_json()
		await click(button_named(pack.guide,"Skills"))
		check(visible_text(pack.guide).contains("Mastery is automatic") and visible_text(pack.guide).contains("You do not choose between perks"), "skill guide explains automatic milestones")
		await click(button_named(pack.guide,"What counts as practice?"))
		check(visible_text(pack.guide).contains("Empty casts, automatic repeats and secondary ticks"), "practice disclosure explains qualifying use")
		await capture("mastery-guide-720")
		await click(button_named(pack.guide,"Progression"))
		var progression := visible_text(pack.guide)
		check(progression.contains("permanent") and progression.contains("freely") and progression.contains("condition"), "progression distinguishes permanent choice and conditional arrangement")
		await capture("progression-guide-720")
		check(sim.export_json() == before, "guide browsing spends nothing")
	print("FOUNDRY_CLARITY %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
