extends Node3D
## Disclosure is presentation only: changing what is expanded must never
## craft, spend a Kind, enter a trial, or lose a selected effect's destination.
var checks := 0
var failures := 0
var actions := 0
var player: WroughtwildPlayer

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func settle() -> void:
	for i in 5: await get_tree().process_frame

func button_named(root: Node, caption: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if node.text == caption: return node
	return null

func visible_text(root: Node) -> String:
	var parts := PackedStringArray()
	for node in root.find_children("*", "Control", true, false):
		if not node.is_visible_in_tree(): continue
		if node is Label or node is RichTextLabel: parts.append(node.text)
	return "\n".join(parts)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_window().size = Vector2i(1280,720)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	var sim := player.inventory.get_sim()
	var work := player.work_panel
	var before_inventory: Dictionary = sim.inventory().duplicate(true)
	var action := func(): actions += 1
	work.open_custom("Disclosure fixture", [
		{"text":"Requires clay 2; have 1.","button":"Work","enabled":false,"callback":action,"details":"Where clay is found."},
		{"text":"Completed output remains in the tray.","button":"Collect","enabled":true,"callback":action},
	])
	await settle()
	check(work.row_count()==2, "disclosure keeps one action card per supplied row")
	check(visible_text(work._body).contains("Requires clay 2; have 1.") and not visible_text(work._body).contains("Where clay is found."), "cost and blocker remain visible while optional explanation starts collapsed")
	var details := button_named(work._body,"Details")
	check(details!=null, "an authored explanation has a disclosure control")
	if details!=null: details.button_pressed=true
	await settle()
	check(visible_text(work._body).contains("Where clay is found."), "disclosure reveals the complete explanation")
	var refreshed: Array=work._custom_rows.duplicate(true)
	refreshed[0].text="Requires clay 2; have 1. Machine status refreshed."
	work.open_custom("Disclosure fixture",refreshed)
	await settle()
	check(visible_text(work._body).contains("Machine status refreshed.") and visible_text(work._body).contains("Where clay is found."), "live machine refresh updates status without collapsing the explanation being read")
	details=button_named(work._body,"Less detail")
	check(button_named(work._body,"Work").disabled and not button_named(work._body,"Collect").disabled, "disclosure preserves native action availability")
	check(actions==0 and sim.inventory()==before_inventory, "opening and expanding cannot execute work or move inventory")
	button_named(work._body,"Collect").pressed.emit()
	check(actions==1, "the original enabled action callback is retained exactly once")
	if details!=null: details.button_pressed=false
	await settle()
	check(not visible_text(work._body).contains("Where clay is found."), "explanation collapses without removing requirements")
	check(work._root.get_global_rect().end.y<=720, "expanded work card remains inside the small viewport")
	work.close_panel()
	work.open_custom("Disclosure fixture",refreshed)
	await settle()
	check(not visible_text(work._body).contains("Where clay is found."), "closing the panel clears temporary disclosure state")
	work.close_panel()

	# A real craft gives a carried kit, followed by the existing placement flow.
	var recipe: Dictionary = sim.recipe("workbench_kit")
	sim.add_materials(recipe.inputs)
	var kit_before := sim.material_count("workbench_kit")
	var station_before := sim.has_station("workbench")
	work.open_hand_crafting()
	var crafted := work.craft("workbench_kit")
	check(bool(crafted.crafted) and sim.material_count("workbench_kit")==kit_before+int(recipe.outputs.workbench_kit), "kit handoff follows an actual native craft with the exact output")
	check(sim.has_station("workbench")==station_before and player.placement.placeables().has({"kind":"kit","id":&"workbench_kit"}), "crafting leaves a selectable kit instead of auto-placing a station")
	check(work.message().contains(InputPrompts.text("{toggle_build_mode} → {cycle_shape}")) and work.message().contains(InputPrompts.key("primary_action")) and work.message().contains(InputPrompts.text("{interact} use")), "successful kit craft supplies the full build and operate handoff with current controls")
	work.close_panel()

	# A shared support reads two real skill sockets, with one identity body.
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer","first_kill:stone_husk"]:
		sim.foundry_event(event)
	sim.add_materials({"iron_ingot":30,"vanguard":2})
	for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row,piece.col), "fixture lifts starting plate")
	sim.learn_skill("prototype_ember_bolt")
	check(sim.foundry_place_skill(1,1,"prototype_heavy_strike") and sim.foundry_place_skill(2,2,"prototype_ember_bolt") and sim.foundry_place(1,2,"ember") and sim.foundry_place_kind(1,3,"vanguard"), "native shared support reaches two compatible skill sockets")
	var foundry := player.foundry_panel
	foundry.open_panel()
	await settle()
	var plate_before: Dictionary = sim.foundry().duplicate(true)
	var effects_before: Array = sim.foundry_effects().duplicate(true)
	before_inventory = sim.inventory().duplicate(true)
	check(not foundry._effects.visible and foundry.effect_count==effects_before.size(), "full breakdown begins collapsed without discarding effects")
	var resolved: Dictionary = sim.skill_mutation("prototype_heavy_strike")
	check(not resolved.forms.is_empty(), "shared support produces actual named mutation operations")
	var unique_descriptions := {}
	for form: Dictionary in resolved.get("forms", []): unique_descriptions[String(form.description)] = true
	var working_text := visible_text(foundry._workings)
	for description: String in unique_descriptions:
		check(working_text.count(description)==2, "each skill working shows the shared identity description once")
	foundry._effect_toggle.button_pressed=true
	await settle()
	check(foundry._effects.is_visible_in_tree(), "full native effect breakdown is available on request")
	foundry._effect_toggle.button_pressed=false
	foundry._inspect_cell(1,2)
	var strike_name: String=sim.combat_skill("prototype_heavy_strike").display_name
	var bolt_name: String=sim.combat_skill("prototype_ember_bolt").display_name
	check(foundry._preview.text.contains("→ "+strike_name) and foundry._preview.text.contains("→ "+bolt_name), "hover names both destinations of the shared support")
	for description: String in unique_descriptions:
		check(foundry._preview.text.count(description)==1, "shared-path inspector deduplicates the body, not its destination labels")
	foundry._on_tray("frost","iron")
	check(foundry._preview.text.contains(String(sim.foundry_ingot("frost").sentence)), "selecting an ingot exposes its actual native effect before placement")
	for cell: Vector2i in [Vector2i(1,1),Vector2i(1,2),Vector2i(1,3)]:
		var refusal: Dictionary=sim.foundry_preview(cell.x,cell.y,"frost","iron")
		foundry._inspect_cell(cell.x,cell.y)
		foundry._inspection_details.button_pressed = true
		check(not bool(refusal.valid) and foundry._preview.text.contains(String(refusal.reason)) and foundry._preview.text.contains(String(foundry._cell_buttons[cell].get_meta("reading_details"))), "occupied-cell refusal preserves the current tablet, ingot or Kind reading")
	foundry._on_subject("vanguard")
	for kind: Dictionary in sim.foundry().kinds:
		if kind.id=="vanguard": check(foundry._preview.text.contains(String(kind.base_sentence)), "selected Kind retains its native base effect")
	foundry._show_help()
	check(sim.foundry()==plate_before and sim.foundry_effects()==effects_before and sim.inventory()==before_inventory, "disclosures, selections, refusals and help preserve exact Foundry ownership and effects")
	foundry.close_panel()

	# Gate and safe-boundary presentation retain consequences in default rows.
	var gate := TrialGate.new()
	add_child(gate)
	var offers_before: Dictionary=sim.trial_map_progress().duplicate(true)
	gate.interact(player)
	await settle()
	check(work.message().contains("lockers") and work.message().contains("unbanked") and work.message().contains("risk"), "gate deposit and loot-risk contract is visible without a disclosure")
	check(button_named(work._body,"Details")==null and work.row_count()==sim.trial_story_runs().size()+1, "story entry actions and requirements stay in default cards")
	check(not sim.trial_active() and sim.trial_map_progress()==offers_before and sim.inventory()==before_inventory, "reviewing the gate cannot enter a run or deposit possessions")
	player.trial.spatial=true
	player.trial.state="boundary"
	player.trial.show_boundary()
	await settle()
	check(button_named(work._body,"Continue")!=null and button_named(work._body,"Bank and leave")!=null and button_named(work._body,"Suspend and quit")!=null, "all three cleared-floor actions remain available")
	check(work.message().contains("no healing or extraction") and visible_text(work._body).contains("at-risk loot"), "suspension consequences remain visible by default")
	player.trial.spatial=false
	player.trial.state="idle"
	work.close_panel()

	# Many legitimate families used to grow the chest beyond the screen.
	# Build a real chest, then retain held-only, stored-only and mixed rows.
	sim.add_material("wood",30)
	var chest := player.placement.place_piece({"kind":"volume","axis":0,"cell":Vector3i(10,0,10)},&"chest",&"wood")
	check(chest!=null, "layout fixture pays the ordinary chest construction cost")
	if chest!=null:
		var families: PackedStringArray=sim.build_material_ids()
		for raw in ["raw_slate","raw_shellstone","raw_clay","raw_reed","resinheart_log","raw_corkbark","lanternheart","thrumroot","stormglass","pullstone","ventlung","fieldstone","split_stone","iron_ore"]:
			if not families.has(raw): families.append(raw)
		for i in families.size():
			sim.add_material(families[i],2)
			if i%3==0: sim.store_deposit(chest.store_key(),families[i],sim.material_count(families[i]))
			elif i%3==1: sim.store_deposit(chest.store_key(),families[i],1)
		var chest_ui:=player.chest_panel
		var expected_ids: Dictionary={}
		var bases:=sim.item_base_ids()
		for id: String in sim.inventory():
			if int(sim.inventory()[id])>0 and not bases.has(id): expected_ids[id]=true
		for id: String in sim.store_contents(chest.store_key()): expected_ids[id]=true
		for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1920,1080)]:
			get_window().size=resolution
			before_inventory=sim.inventory().duplicate(true)
			var stored_before: Dictionary=sim.store_contents(chest.store_key()).duplicate(true)
			chest_ui.open_at(chest)
			await settle()
			check(chest_ui.row_count==expected_ids.size(), "chest retains the full held/stored family union at %dp" % resolution.y)
			var panel_rect:=chest_ui._root.get_global_rect()
			check(panel_rect.position.x>=0 and panel_rect.position.y>=0 and panel_rect.end.x<=resolution.x and panel_rect.end.y<=resolution.y, "chest remains entirely inside %dp" % resolution.y)
			var close_button:=button_named(chest_ui._root,"Close  (Esc)")
			check(close_button!=null and panel_rect.encloses(close_button.get_global_rect()) and panel_rect.encloses(chest_ui._title.get_global_rect()), "chest title and close action remain accessible at %dp" % resolution.y)
			check(chest_ui._scroll.get_v_scroll_bar().max_value>chest_ui._scroll.size.y, "large chest inventory scrolls at %dp" % resolution.y)
			chest_ui._scroll.scroll_vertical=int(chest_ui._scroll.get_v_scroll_bar().max_value)
			await settle()
			var last_row: Control=chest_ui._rows.get_child(chest_ui._rows.get_child_count()-1)
			var last_store:=button_named(last_row,"Store all  »")
			var last_take:=button_named(last_row,"«  Take all")
			check(last_store!=null and last_take!=null and chest_ui._scroll.get_global_rect().intersects(last_store.get_global_rect()) and chest_ui._scroll.get_global_rect().intersects(last_take.get_global_rect()), "last family's transfer buttons are reachable by scrolling at %dp" % resolution.y)
			check(sim.inventory()==before_inventory and sim.store_contents(chest.store_key())==stored_before, "resizing and scrolling preserve exact chest and pack contents at %dp" % resolution.y)
			chest_ui.close_panel()
		chest_ui.open_at(chest)
		sim.add_material("wood",5)
		var wood_before:=sim.material_count("wood")
		var stock_before:=int(sim.store_contents(chest.store_key()).get("wood",0))
		var room_before:=sim.store_room(chest.store_key())
		var moved:=chest_ui.store(&"wood",5)
		check(moved==mini(5,room_before) and sim.material_count("wood")==wood_before-moved and int(sim.store_contents(chest.store_key()).get("wood",0))==int(stock_before)+moved, "scrolled chest still transfers only native capacity with exact conservation")
		chest_ui.close_panel()

	var flat := PackedVector2Array([Vector2.ZERO,Vector2(1,1),Vector2(2,2)])
	check(not BuildThumbnail.projected_face_has_area(flat), "edge-on projected face is omitted")
	check(not BuildThumbnail.projected_face_has_area(PackedVector2Array([Vector2.ONE,Vector2.ONE,Vector2.ONE])), "repeated projected vertices are omitted")
	var face := PackedVector2Array([Vector2.ZERO,Vector2(2,0),Vector2(0,1)])
	check(BuildThumbnail.projected_face_has_area(face), "ordinary triangle survives projection")
	face.reverse()
	check(BuildThumbnail.projected_face_has_area(face), "opposite winding remains visible for two-sided thumbnail geometry")
	# Exercise the actual draw path too when root invokes this scene rendered.
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var column := HFlowContainer.new()
	column.size=Vector2(1100,300)
	canvas.add_child(column)
	for kit: String in sim.kit_item_ids():
		var thumbnail := BuildThumbnail.new()
		thumbnail.custom_minimum_size=Vector2(88,88)
		thumbnail.mesh=player.build_palette._mesh(StringName(kit),true)
		column.add_child(thumbnail)
		check(thumbnail.mesh!=null and not thumbnail.mesh.get_faces().is_empty(), "actual kit thumbnail retains imported geometry: "+kit)
	await settle()
	print("CODEX_PANEL_DENSITY %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
