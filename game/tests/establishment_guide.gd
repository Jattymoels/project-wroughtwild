extends Node3D
## Seeded UI cases, not the fresh-stock journey. No user save files.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var pack: InventoryPanel
var guide: BuildGuide

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func settle() -> void:
	for i in 8: await get_tree().process_frame

func buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in node.get_children():
		if child is Button: result.append(child)
		result.append_array(buttons(child))
	return result

func visible_text(node: Node) -> String:
	var text := ""
	for child in node.get_children():
		if child is Label and child.is_visible_in_tree(): text += child.text + "\n"
		text += visible_text(child)
	return text

func stock(id: String, amount: int) -> void:
	sim.consume_material(id,sim.material_count(id))
	if amount>0: sim.add_material(id,amount)

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	sim = player.combat.sim
	pack = player.inventory_panel
	guide = pack.guide
	var initial := sim.export_json()
	pack.open_panel()
	check(not guide.visible,"guide never opens automatically with the pack")
	pack.show_guide(true)
	check(guide.page=="Getting established" and guide.last_step.kind=="shape","optional guide starts with home building independently of station gates")
	player.placement.toggle_fine()
	player.build_palette.group = "Corners & roofs"
	player.build_palette.group_picker.select(1)
	check(pack.open_build("wall_panel") and not player.placement.fine_mode and player.placement.placing_shape()==&"wall_panel","guide's full-size wall does not inherit an earlier half-size selection")
	check(player.build_palette.cards.has("wall_panel") and player.build_palette.group=="All pieces","guide reveals the selected wall after an earlier roof-only filter")
	check(sim.export_json()==initial,"guide building selection changes no inventory or progression")
	player.build_palette.close_panel()
	player.placement.set_build_mode_enabled(false)
	pack.open_panel()
	pack.show_guide(true)
	for id in MaterialGuide.EARLY:
		var info := MaterialGuide.describe(sim,id)
		check(not info.source.is_empty() and not info.work.is_empty() and not info.use.is_empty(),"early material explains source/work/use: "+id)
		if info.recipe != "": check(sim.recipe(info.recipe).outputs.has(id),"producer is an actual native output: "+id)
		for consumer in info.uses: check(sim.recipe(consumer).inputs.has(id),"use is a native ingredient consumer: "+consumer)
	check(MaterialGuide.describe(sim,"stone").recipe=="dress_stone","dressed stone points at the actual yard refinement")
	check(MaterialGuide.describe(sim,"iron_ingot").use.contains("Build with it"),"construction use resolves the iron family's iron_ingot source")
	check(MaterialGuide.describe(sim,"fieldstone").recipe=="" and MaterialGuide.describe(sim,"fieldstone").work.contains("rough stone"),"fieldstone remains gathered rough stone, not a dressed-stone recipe")
	check(MaterialGuide.describe(sim,"wood").work.contains("not pine"),"exact recipe wood does not imply timber-species substitution")
	check(MaterialGuide.describe(sim,"split_stone").work.contains("impact") and not MaterialGuide.describe(sim,"iron_ore").work.contains("cold"),"early gathering descriptions introduce no cold-class gate")
	guide.select_ambition("Stone")
	check(guide.last_step.id=="workbench_kit" and guide.last_step.preview==sim.craft_preview("workbench_kit"),"stone ambition first exposes the real hand-bench recipe and authoritative preview")
	guide.select_ambition("Forge")
	check(guide.last_step.id=="workbench_kit","forge ambition begins with its real missing bench dependency")
	check(sim.export_json()==initial,"reading materials and choosing ambitions changes no economy, progression or loadout")
	stock("workbench_kit",1)
	guide.refresh()
	check(guide.last_step.kind=="kit" and guide.last_step.id=="workbench_kit","held kit becomes a placement handoff rather than another craft")
	var before := sim.export_json()
	player.build_palette.group = "Corners & roofs"
	player.build_palette.group_picker.select(1)
	check(pack.open_build("workbench_kit","kit") and player.build_palette.is_open() and player.placement.selected_kit==&"workbench_kit","guide opens actual held-kit selection in the building palette")
	check(player.build_palette.cards.has("workbench_kit"),"held-kit link is visible despite an earlier roof-only filter")
	check(sim.export_json()==before,"selecting a kit never pays or marks a station built")
	player.build_palette.close_panel()
	player.placement.set_build_mode_enabled(false)
	stock("workbench_kit",0)
	sim.add_station("workbench")
	stock("timber_frame",1)
	stock("fieldstone",6)
	pack.open_panel()
	pack.show_guide(true)
	guide.select_ambition("Stone")
	check(guide.last_step.id=="mason_yard_kit" and guide.last_step.preview==sim.craft_preview("mason_yard_kit"),"built bench and carried frame advance to the yard's exact recipe")
	sim.add_station("mason_yard")
	stock("split_stone",0)
	stock("timber_wedge",0)
	guide.refresh()
	check(guide.last_step.id=="timber_wedge","missing seam stock explains the existing hand wedge before dressing stone")
	stock("split_stone",2)
	guide.refresh()
	check(guide.last_step.id=="dress_stone" and guide.last_step.preview==sim.craft_preview("dress_stone"),"already carried split stone can be dressed without a retroactive wedge requirement")
	stock("split_stone",1)
	guide.refresh()
	check(guide.last_step.id=="timber_wedge","guide rereads changed carried stock")
	stock("split_stone",2)
	stock("stone",8)
	stock("iron_ore",4)
	guide.select_ambition("Forge")
	check(guide.last_step.id=="forge_kit" and guide.last_step.preview==sim.craft_preview("forge_kit"),"forge kit readiness comes from native costs")
	sim.add_station("forge_basic")
	stock("wood",2)
	stock("iron_ore",2)
	guide.refresh()
	check(guide.last_step.id=="smelt_iron" and not guide.last_step.preview.ready,"built forge suggests useful smelting while preserving ingredient/fuel reservation shortage")
	stock("wood",3)
	guide.refresh()
	check(guide.last_step.preview==sim.craft_preview("smelt_iron") and guide.last_step.preview.ready,"live extra fuel updates the same native preview")
	before = sim.export_json()
	check(pack.inspect_material("iron_ingot") and guide.page=="Material","a carried-material request opens shared source/use detail")
	check(pack.open_recipe("smelt_iron") and player.work_panel.is_open() and player.work_panel._station==null,"material recipe link opens an explicit hand-context reference")
	check(player.work_panel.catalogue._action.disabled and player.work_panel.catalogue._next.text.to_lower().contains("forge"),"global forge ownership cannot enable remote crafting from the guide")
	check(sim.export_json()==before,"material navigation and physical-station refusal preserve all native state")
	player.work_panel.close_panel()
	pack.open_panel()
	pack.show_guide(true)
	for page in ["Skills","Kinds","Progression","Wild finds"]:
		guide.select_page(page)
		check(guide.get_child_count()>1,"existing guide remains reachable: "+page)
	guide.select_filter("Attacks")
	check(guide.page=="Skills" and not guide.shown_skills.is_empty(),"existing skill filter API selects its skill page")
	player.combat.has_home = true
	pack.refresh()
	check(guide.ambition_view("Home").id=="chest","a returning homeowner receives storage guidance without a new completion flag")
	# Native rolled item views exercise the shared cards used in both pack
	# and comparison; this is supplied gear, not a drop or crafting journey.
	var gear_index := sim.roll_item_into_pack("frost_sceptre","wrought",3,117)
	var comparison: Dictionary = sim.compare_equipment(gear_index)
	check(not comparison.candidate.mods.is_empty(),"comparison fixture has actual native rolled modifier sentences")
	pack.show_guide(false)
	pack.refresh()
	for mod in comparison.candidate.mods:
		check(visible_text(pack._gear).contains(String(mod.sentence)),"pack shows the currently expressed effect without opening Details")
		if bool(mod.get("held_back",false)):
			check(visible_text(pack._gear).contains(String(mod.sentence)+" · held back"),"pack marks limited current effect while keeping its potential explanation optional")
	before = sim.export_json()
	check(pack.compare_item(gear_index),"normal pack comparison opens the native rolled candidate")
	for mod in comparison.candidate.mods:
		check(visible_text(pack.comparison).contains(String(mod.sentence)),"comparison exposes actual candidate behaviour without opening Details")
		if bool(mod.get("held_back",false)):
			check(not visible_text(pack.comparison).contains("held back by"),"long stored-potential explanation stays behind comparison Details")
	check(sim.export_json()==before,"reading current and potential equipment effects is read-only")
	pack._back_to_pack()
	# Stress the same actual panels at both review sizes, including expanded
	# debug prose; stock here is deliberately supplied for layout coverage.
	for id in MaterialGuide.EARLY: stock(id,12)
	for viewport_size in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = viewport_size
		for page in ["Pack","Getting established","Material","Progression","Wild finds"]:
			pack.show_guide(page!="Pack")
			if page=="Material": guide.show_material("wood")
			elif page!="Pack": guide.select_page(page)
			pack.refresh()
			await settle()
			var rect := pack._root.get_global_rect()
			check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=viewport_size.x+1 and rect.end.y<=viewport_size.y+1,"panel fits %s at %s (%s)" % [page,viewport_size,rect])
		pack.show_guide(false)
		for button in buttons(pack._root):
			if button.text=="Debug modifiers (F1–F3)": button.button_pressed = true
		await settle()
		var expanded := pack._root.get_global_rect()
		check(expanded.position.x>=0 and expanded.end.x<=viewport_size.x+1,"expanded debug text wraps without forcing width at %s (%s)" % [viewport_size,expanded])
		for button in buttons(pack._root):
			if button.text=="Debug modifiers (F1–F3)": button.button_pressed = false
	print("ESTABLISHMENT_GUIDE %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
