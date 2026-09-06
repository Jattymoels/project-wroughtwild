extends Node3D
## Actual catalogue cards, native previews and Make buttons; no saved game.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var panel: WorkPanel
var catalogue: ForgeCatalogue

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)

func station(id: StringName, upgrade: StringName = &"") -> StationSite:
	var site := preload("res://scenes/station_site.tscn").instantiate() as StationSite
	site.station_id = id
	site.upgrade_station_id = upgrade
	add_child(site)
	return site

func stock(id: String, amount: int) -> void:
	sim.consume_material(id,sim.material_count(id))
	if amount > 0: sim.add_material(id,amount)

func cards() -> Array[String]:
	var ids: Array[String] = []
	for card in catalogue._cards.get_children():
		if card.has_meta("recipe_id"): ids.append(String(card.get_meta("recipe_id")))
	return ids

func category(name: String) -> void:
	catalogue.category = name
	catalogue.selection = ""
	catalogue.query = ""
	panel.refresh()

func ready_first() -> void:
	var blocked_seen := false
	var ordered := true
	for id in cards():
		var preview: Dictionary = sim.craft_preview(id,"",catalogue._local_quality(sim.recipe(id)))
		if not bool(preview.ready): blocked_seen = true
		elif blocked_seen: ordered = false
	check(ordered,"every native-ready recipe precedes blocked recipes in "+catalogue.category)

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	sim = player.combat.sim
	panel = player.work_panel
	catalogue = panel.catalogue
	sim.add_station("workbench")
	sim.add_station("forge_basic")
	sim.add_station("mason_yard")
	stock("wood",4)
	stock("hide",0)
	var bench := station(&"workbench")
	var forge := station(&"forge_basic",&"forge_improved")
	var yard := station(&"mason_yard")
	panel.open_crafting(bench)
	category("Equipment")
	var ids := cards()
	check(ids.has("wooden_cudgel") and ids.has("hide_vest"),"bench keeps affordable and missing-material equipment visible")
	check(not ids.has("iron_mace") and not ids.has("iron_chest_armour"),"bench hides another station's equipment despite its global forge unlock")
	check(ids[0]=="wooden_cudgel" and ids[1]=="wooden_focus","craftable wooden tools precede alphabetically earlier blocked hide equipment")
	ready_first()
	catalogue.select_recipe("simple_bow")
	check(catalogue.last_preview.grades.size()==3 and not catalogue.last_preview.grades[1].available,"locked equipment grades remain inspectable at the original bench")
	stock("hide",3)
	panel.refresh()
	ready_first()
	check(cards()[0]=="hide_quiver","refresh moves newly affordable equipment into the sorted ready group")
	category("Stations & upgrades")
	check(cards().has("assemble_pressure_feeder") and cards().has("assemble_lantern_lamp"),"undiscovered rare-component projects remain visible at their bench")
	check(cards().has("workbench_kit"),"hand assembly remains available while at a station")

	# Explicit ingredient references preserve the D-026 return path, but do
	# not add the other station's recipe to this bench's normal catalogue.
	catalogue.select_recipe("forge_kit")
	catalogue.select_recipe("smelt_iron",true)
	check(catalogue.history.back().selection=="forge_kit" and catalogue.selection=="smelt_iron","explicit ingredient inspection retains its parent recipe")
	check(not cards().has("smelt_iron") and catalogue._action.disabled,"off-station reference is inspectable but absent from bench cards and cannot be made here")
	check(catalogue._next.text.contains("forge"),"off-station reference says where its actual work belongs")
	catalogue.query = "smelt"
	panel.open_crafting(yard)
	check(catalogue.query.is_empty() and catalogue.history.is_empty() and catalogue.selection!="smelt_iron","changing station clears stale search and reference selection")
	category("Materials")
	check(cards().has("dress_stone") and cards().has("refine_vitrified_basalt"),"yard retains common and rare local masonry")
	check(not cards().has("charcoal") and not cards().has("refine_woven_reed"),"yard hides forge and bench refinements")

	catalogue.category = "Equipment"
	panel.open_hand_crafting()
	check(not cards().is_empty() and catalogue.category!="Equipment","field crafting opens a nonempty hand-work category")
	check(cards().all(func(id: String) -> bool: return String(sim.recipe(id).station).is_empty()),"field cards stay hand-only after other stations were built")
	stock("wood",1)
	catalogue.select_recipe("timber_wedge")
	var wedges := sim.material_count("timber_wedge")
	check(not catalogue._action.disabled,"one timber affords the native hand-wedge recipe")
	catalogue._action.pressed.emit()
	check(sim.material_count("wood")==0 and sim.material_count("timber_wedge")==wedges+2,"normal Make button pays one wood for the existing two hand wedges")

	panel.open_crafting(forge)
	category("Materials")
	check(cards().has("smelt_steel") and cards().has("work_excellent_iron"),"same forge family's locked future work remains visible")
	stock("iron_ingot",2)
	stock("iron_ore",2)
	stock("wood",2)
	stock("charcoal",0)
	stock("raw_clay",0)
	stock("cinderglass_shard",0)
	stock("silver_ingot",0)
	stock("copper_ore",0)
	stock("silver_ore",0)
	panel.refresh()
	check(sim.recipe("smelt_iron").inputs_met and not sim.craft_preview("smelt_iron").ready,"smelting fixture has its inputs but lacks fuel after reserving its wood")
	check(cards()[0]=="iron_fittings","actually affordable fittings precede a smelt whose input wood cannot also burn")
	ready_first()
	catalogue.select_recipe("smelt_iron")
	var before := sim.export_json()
	check(catalogue._action.disabled,"fuel-short recipe stays disabled under the exact native preview")
	check(not panel.craft("smelt_iron").crafted and sim.export_json()==before,"native craft validation still rejects fuel shortage without payment")
	stock("wood",3)
	panel.refresh()
	check(not catalogue._action.disabled,"one additional fuel wood enables the real smelting action")
	var iron_before := sim.material_count("iron_ingot")
	catalogue._action.pressed.emit()
	check(sim.material_count("wood")==0 and sim.material_count("iron_ore")==0 and sim.material_count("iron_ingot")==iron_before+1,"normal smelt reserves and consumes separate input and fuel exactly")

	sim.add_station("forge_improved")
	panel.open_crafting(forge)
	category("Equipment")
	check(cards().has("wooden_focus"),"Improved Forge lists its existing higher-grade work on wooden bases")
	catalogue.select_recipe("wooden_focus")
	check(catalogue.quality==2 and catalogue._action.disabled,"forge-local wooden work opens at Sound grade while missing inputs and skill remain visible")
	var save: Dictionary = JSON.parse_string(sim.export_json())
	save.economy.skill_xp.blacksmithing = 1000
	check(sim.import_json(JSON.stringify(save)),"prepare existing smithing progression for the positive upgrade path")
	stock("wood",4)
	stock("sound_iron_ingot",1)
	panel.refresh()
	check(not catalogue._action.disabled,"Sound wooden forging is ready at the actual Improved Forge")
	ready_first()
	catalogue._action.pressed.emit()
	check(sim.pack_items().back().workpiece_tier==2 and sim.material_count("sound_iron_ingot")==0,"forge-local higher-grade wooden recipe preserves its native payment and quality")
	panel.open_crafting(bench)
	catalogue.select_recipe("wooden_focus")
	check(catalogue.quality==1,"returning to the bench restores ordinary Rough assembly")
	await _project_context(yard,forge)
	print("CRAFTING_CATALOGUE %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _project_context(yard: StationSite, forge: StationSite) -> void:
	panel.open_crafting(yard)
	stock("split_stone",5)
	catalogue.select_recipe("dress_stone")
	catalogue.quantity = 4
	catalogue.query = "dress"
	catalogue._render_detail()
	var untouched := sim.export_json()
	var project := catalogue.selection_state()
	catalogue.toggle_pin()
	check(catalogue.pinned_preview()==sim.craft_preview("dress_stone","",1,4),"pin reads the selected four-batch plan rather than one default batch")
	catalogue.inspect_ingredient("split_stone")
	check(not catalogue._action.visible and catalogue.history.back()==project,"raw material help retains the full parent and offers no remote Make")
	check(MaterialGuide.describe(sim,"split_stone").get("work","")!="","early raw ingredient has requested work notes")
	catalogue.go_back()
	check(catalogue.selection_state()==project,"raw ingredient Back restores the parent's batch and search")
	check(sim.export_json()==untouched,"pinning, field notes and Back leave inventory, XP and equipment unchanged")
	catalogue.quantity = 1
	catalogue._render_detail()
	check(int(catalogue.pinned.quantity)==4,"later browsing cannot mutate the stored project")
	stock("split_stone",20)
	check(catalogue.pinned_preview()==sim.craft_preview("dress_stone","",1,4) and catalogue.pinned_preview().ready,"pinned requirements update from current stock against the original batch")
	panel.close_panel()
	catalogue._pin_clock = 0
	catalogue._process(0.5)
	check(catalogue._pin_hud.visible and catalogue._pin_hud.text.contains("4 batches"),"play HUD identifies the pinned batch")
	panel.open_crafting(forge)
	stock("wood",15)
	stock("iron_ore",8)
	catalogue.select_recipe("smelt_iron")
	catalogue.quantity = 3
	catalogue._render_detail()
	catalogue.toggle_pin()
	var expected: Dictionary = sim.craft_preview("smelt_iron","",1,3)
	check(catalogue.pinned_preview().fuel==expected.fuel and catalogue.pinned_preview().fuel_available==expected.fuel_available,"multi-batch pin uses native fuel after ingredient reservation")
	stock("wood",3)
	expected = sim.craft_preview("smelt_iron","",1,3)
	check(not expected.ready and catalogue.pinned_preview()==expected,"pin reports the current native shortfall without borrowing ingredient wood")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size=resolution
		panel.refresh()
		for i in 8: await get_tree().process_frame
		check(catalogue._action.is_visible_in_tree() and catalogue._action.get_global_rect().end.y<=resolution.y,"action remains visible outside recipe scroll at "+str(resolution))
		check(catalogue._cost_summary.is_visible_in_tree() and catalogue._next.is_visible_in_tree(),"current cost and native blocker stay visible at "+str(resolution))
	panel.close_panel()
	player.inventory_panel.open_panel()
	catalogue._pin_clock = 0
	catalogue._process(0.5)
	check(not catalogue._pin_hud.visible,"recipe pin does not overlay the pack or guides")
	player.inventory_panel.close_panel()
	player.foundry_panel.open_panel()
	catalogue._pin_clock = 0
	catalogue._process(0.5)
	check(not catalogue._pin_hud.visible,"recipe pin does not overlay the Foundry")
	player.foundry_panel.close_panel()
	player.hud.toggle_help()
	catalogue._pin_clock = 0
	catalogue._process(0.5)
	check(not catalogue._pin_hud.visible,"recipe pin does not overlay requested help")
	player.hud.toggle_help()
	catalogue._pin_clock = 0
	catalogue._process(0.5)
	check(catalogue._pin_hud.visible,"same session pin returns after closing other panels")
	catalogue.pinned = {}
