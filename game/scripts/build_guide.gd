class_name BuildGuide
extends VBoxContainer
## A page of the existing pack screen: discovery, mastery and Foundry paths.
signal changed
signal assign_requested(skill: String, slot: int)
signal recipe_requested(recipe: String)
signal build_requested(shape: String, kind: String)
var sim: WroughtwildSim
var page := "Getting established"
var ambition := "Home"
var material_id := ""
var has_home := false
var last_step: Dictionary = {}
var filter := "All"
var shown_skills: Array[String] = []
var shown_kinds: Array[String] = []

func refresh() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	shown_skills.clear()
	shown_kinds.clear()
	var tabs := HBoxContainer.new()
	add_child(tabs)
	for text in ["Getting established","Skills","Kinds","Progression","Wild finds"]:
		var button := Button.new()
		button.text = text
		button.toggle_mode = true
		button.button_pressed = page==text
		button.pressed.connect(select_page.bind(text))
		tabs.add_child(button)
	match page:
		"Getting established": _established()
		"Material": _material()
		"Skills": _skills()
		"Kinds": _kinds()
		"Progression": _progression()
		"Wild finds": _wild_finds()
	changed.emit()

func select_page(value: String) -> void:
	page = value
	refresh()

func _wild_finds() -> void:
	_text(self,"Follow unusual growth, light and grit. Every class can work these finite finds.")
	for info in sim.rare_resource_guide():
		var column := _card(String(info.display_name),String(info.use_preview))
		_text(column,"%d carried" % sim.material_count(info.id),UiTheme.SUN_WARM)
		var details := _details(column)
		_text(details,"Property: %s" % ", ".join(info.properties))
		_text(details,"Work: "+" → ".join(info.harvest_stages))
	_text(_details(self,"Making and connecting fixtures"),"Assemble at the workbench, then B → Tab to place the kit. Wind supplies energy; Stormglass carries a signal. Link a lever to a nearby lamp or winch, and a winch to its landing. Dismantling returns intact rare cores.")

func select_filter(value: String) -> void:
	page = "Skills"
	filter = value
	refresh()

func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _details(parent: Node, title := "Details") -> VBoxContainer:
	var button := Button.new()
	button.text = title
	button.toggle_mode = true
	parent.add_child(button)
	var body := VBoxContainer.new()
	body.visible = false
	body.add_theme_constant_override("separation",6)
	parent.add_child(body)
	button.toggled.connect(func(open: bool): body.visible = open; changed.emit())
	return body

func select_ambition(value: String) -> void:
	ambition = value
	page = "Getting established"
	refresh()

func show_material(id: String) -> void:
	material_id = id
	page = "Material"
	refresh()

func _material() -> void:
	var info := MaterialGuide.describe(sim,material_id)
	var column := _card(Hud.pretty(material_id).capitalize(),"%d carried" % sim.material_count(material_id))
	if info.is_empty(): return
	_text(column,info.source,UiTheme.FROST)
	_text(column,info.use)
	_text(_details(column,"Work and collection"),info.work)
	if info.recipe != "": _button(column,"View source recipe",func(): recipe_requested.emit(info.recipe))
	if info.shape != "" and sim.material_count(material_id)>0:
		_button(column,"Place this kit",func(): build_requested.emit(material_id,"kit"))
	if not info.uses.is_empty():
		var row := HFlowContainer.new()
		column.add_child(row)
		var more: VBoxContainer
		for index in info.uses.size():
			var id := String(info.uses[index])
			if index == 3: more = _details(column,"More uses")
			var destination: Node = row if index < 3 else more
			_button(destination,String(sim.recipe(id).get("display_name",id)),func(): recipe_requested.emit(id))

## These three ambitions are optional entry points into existing definitions.
## Recursing through missing recipe inputs chooses one immediate step; it
## never pays, pins, unlocks or predicts the outcome of a craft.
func _station_step(id: String, visited: Array[String]) -> Dictionary:
	var station: Dictionary = sim.station(id)
	if id == "" or station.is_empty() or bool(station.get("available",false)): return {}
	var kit := String(station.get("kit_item",""))
	if kit != "" and sim.material_count(kit)>0:
		return {"kind":"kit","id":kit,"next":"Place your %s, then use E at it." % station.display_name}
	return _recipe_step(MaterialGuide.producer(sim,kit),visited)

func _recipe_step(id: String, visited: Array[String]) -> Dictionary:
	if id == "" or visited.has(id): return {}
	var path: Array[String] = visited.duplicate()
	path.append(id)
	var row: Dictionary = sim.recipe(id)
	if row.is_empty(): return {}
	var station_step := _station_step(String(row.get("station","")),path)
	if not station_step.is_empty(): return station_step
	var preview: Dictionary = sim.craft_preview(id)
	for cost in preview.get("costs",[]):
		if int(cost.have)>=int(cost.need): continue
		var input_id := String(cost.id)
		# A seam's existing consumable is explained before asking for its
		# output; owning split stone never adds a retroactive wedge gate.
		if input_id == "split_stone" and sim.material_count("timber_wedge") == 0:
			var wedge_step := _recipe_step(MaterialGuide.producer(sim,"timber_wedge"),path)
			if not wedge_step.is_empty(): return wedge_step
		var producer := MaterialGuide.producer(sim,input_id)
		if producer != "":
			var step := _recipe_step(producer,path)
			if not step.is_empty(): return step
	var station_id := String(row.get("station",""))
	var where := "by hand" if station_id == "" else "at your " + String(sim.station(station_id).get("display_name",station_id))
	return {"kind":"recipe","id":id,"preview":preview,"next":"%s · %s." % [row.display_name,where]}

func ambition_view(value: String) -> Dictionary:
	if value == "Home":
		var shape := "chest" if has_home else "wall_panel"
		return {"kind":"shape","id":shape,"next":"Add storage to your home." if has_home else "Choose walls, a doorway and a slab roof."}
	if value == "Stone": return _recipe_step(MaterialGuide.producer(sim,"stone"),[])
	var forge := _station_step("forge_basic",[])
	return forge if not forge.is_empty() else _recipe_step(MaterialGuide.producer(sim,"iron_ingot"),[])

func _established() -> void:
	_text(self,"Choose something useful to make. These are ideas, not required objectives.")
	var choices := HFlowContainer.new()
	add_child(choices)
	for pair in [["Home","Make a first home"],["Stone","Work stone"],["Forge","Set up a forge"]]:
		var button := _button(choices,pair[1],select_ambition.bind(pair[0]))
		button.toggle_mode = true
		button.button_pressed = ambition==pair[0]
	var outcomes := {"Home":"A sheltered place to recover and keep supplies.","Stone":"Turn rough seam stone into masonry you can build with.","Forge":"Turn gathered ore into useful metal."}
	var column := _card(outcomes.get(ambition,""),"")
	last_step = ambition_view(ambition)
	if last_step.is_empty(): return
	_text(column,String(last_step.next),UiTheme.PARCHMENT,16)
	match String(last_step.kind):
		"recipe":
			var preview: Dictionary = last_step.preview
			var requirements := PackedStringArray()
			for cost in preview.get("costs",[]):
				requirements.append("%s %d/%d" % [Hud.pretty(cost.id),int(cost.have),int(cost.need)])
			if int(preview.get("fuel",0))>0: requirements.append("Heat %d/%d" % [int(preview.get("fuel_available",0)),int(preview.fuel)])
			_text(column," · ".join(requirements))
			_text(column,String(preview.get("next_action","")),UiTheme.GRASS_LIGHT if bool(preview.get("ready",false)) else UiTheme.MUTED)
			_button(column,"View recipe",func(): recipe_requested.emit(last_step.id))
			var details := _details(column,"Where to find the materials")
			for cost in preview.get("costs",[]):
				var info := MaterialGuide.describe(sim,String(cost.id))
				if not info.is_empty():
					_text(details,"%s · %s" % [Hud.pretty(cost.id),info.source])
					_button(details,"About " + Hud.pretty(cost.id),show_material.bind(String(cost.id)))
		"kit": _button(column,"Place kit",func(): build_requested.emit(last_step.id,"kit"))
		"shape":
			var row := HFlowContainer.new()
			column.add_child(row)
			for shape_id in ["wall_panel","door","floor_slab","chest"]:
				var shape: Dictionary = sim.shape(shape_id)
				var ready := sim.can_afford_placement(shape_id,"wood") and sim.shape_unlocked(shape_id)
				var button := _button(row,"%s · %d wood" % [shape.get("display_name",shape_id),sim.shape_material_cost(shape_id)],func(): build_requested.emit(shape_id,"shape"))
				button.modulate = UiTheme.GRASS_LIGHT if ready else UiTheme.MUTED
			_text(column,"Build directly with carried timber. You do not need a bench first.")
	var help := _details(column,"How the steps connect")
	_text(help,"Harvesting frees a physical drop; move close to collect it. Recipe counts use your pack, so take stored materials from a chest first.")
	_text(help,"Crafted kits stay in your pack until placed: B → Tab → choose the kit → LMB. Use E at the placed station.")
	_text(help,"Enclose a room with a door and roof. Three wall panels above the walking floor leave headroom; keep the doorway flush with that floor. Slabs make an early roof; pitched roofs unlock later. Build mode marks shelter leaks.")

func _text(parent: Node, text: String, colour := UiTheme.MUTED, font_size := 14) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = colour
	label.add_theme_font_size_override("font_size",font_size)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(label)
	return label

func _card(title: String, subtitle: String) -> VBoxContainer:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",UiTheme.card(false))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_child(card)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation",6)
	card.add_child(column)
	_text(column,title,UiTheme.PARCHMENT,18)
	if subtitle!="": _text(column,subtitle)
	return column

func _skills() -> void:
	var known := sim.known_skill_ids()
	_text(self,"%d / %d skills discovered · Choose a learned skill for your bar." % [known.size(),sim.combat_skill_ids().size()])
	_text(_details(self,"Learning and shaping skills"),"Pages teach skills you do not know. Any class can learn any page. Support a learned skill's tablet in the Foundry (F).")
	var filters := HBoxContainer.new()
	add_child(filters)
	for value in ["All","Attacks","Spells","Undiscovered"]:
		var button := Button.new()
		button.text = value
		button.toggle_mode = true
		button.button_pressed = filter==value
		button.pressed.connect(select_filter.bind(value))
		filters.add_child(button)
	var bar := sim.skill_bar()
	for id in sim.combat_skill_ids():
		var skill: Dictionary = sim.combat_skill(id)
		var tags: PackedStringArray = skill.get("tags",PackedStringArray())
		var learned := known.has(id)
		if filter=="Attacks" and not "attack" in tags: continue
		if filter=="Spells" and not "spell" in tags: continue
		if filter=="Undiscovered" and learned: continue
		shown_skills.append(id)
		var status := "Discovered" if learned else "Find its page"
		var column := _card("%s · %s" % [skill.display_name,status],"")
		var details := _details(column)
		_text(details,String(skill.get("description","")))
		if learned:
			var working: Dictionary = sim.skill_mutation(id)
			for form in working.get("forms", []): _text(details, "%s — %s" % [form.form_name, form.description], UiTheme.SUN_WARM)
		var recovery := sim.skill_cooldown_seconds(id)
		if String(skill.get("delivery",""))=="dash":
			recovery /= 1.0+float(sim.derived_stats().get("dash_recovery",0))
		_text(column,"%s · %.2f s recovery" % [" / ".join(tags),recovery],UiTheme.FROST)
		var uses := int(skill.get("practice",0))
		var next: Dictionary = {}
		for perk in skill.get("mastery",[]):
			_text(details,"%s %s · %d practice" % ["✓" if perk.unlocked else "◇",perk.text,int(perk.uses)],UiTheme.GRASS_LIGHT if perk.unlocked else UiTheme.MUTED)
			if next.is_empty() and not perk.unlocked: next = perk
		if learned:
			if not next.is_empty():
				_text(column,"Mastery · %d / %d practice toward the next milestone" % [uses,int(next.uses)],UiTheme.SUN_WARM)
				var progress := ProgressBar.new()
				progress.max_value = int(next.uses)
				progress.value = uses
				progress.show_percentage = false
				progress.custom_minimum_size.y = 5
				column.add_child(progress)
			var row := HBoxContainer.new()
			column.add_child(row)
			for slot in bar.size():
				var button := Button.new()
				button.text = "Slot %d%s" % [slot+1," · equipped" if bar[slot]==id else ""]
				button.pressed.connect(func(): assign_requested.emit("" if bar[slot]==id else String(id),slot))
				row.add_child(button)
		else:
			_text(details,"Drops as an unknown skill page from roaming enemies and trial fights. Learning it is permanent; mastery starts when you use it.")

func _kinds() -> void:
	_text(self,"Use Kinds to aim a gear craft or shape a skill in the Foundry.")
	_text(_details(self,"Placing and recovering Kinds"),"Place a Kind in a Foundry corner. A chain of pieces must carry it inward to a skill. Lift it for the normal re-forging cost to recover it.")
	for kind in sim.currency_kinds():
		shown_kinds.append(String(kind.id))
		var description := String(kind.get("description",""))
		if description=="": description = "Works adjacent supports into %s forms. Aimed gear crafts favour %s modifiers." % [kind.family,kind.get("craft_tag",kind.family)]
		var column := _card("%s · held %d" % [kind.display_name,int(kind.held)],"")
		var details := _details(column)
		_text(details,description)
		var sources: PackedStringArray = kind.get("sources",PackedStringArray())
		if not sources.is_empty(): _text(details,"Hunt: "+", ".join(sources),UiTheme.FROST)
		if kind.exchangeable: _text(details,"Peddler: exchange %d of another listed Kind for one." % sim.exchange_rate(),UiTheme.SUN_WARM)

func _progression() -> void:
	var era: Dictionary = sim.era()
	var foundry: Dictionary = sim.foundry()
	var column := _card("Era %d · %s" % [int(era.index),era.display_name],"")
	_text(_details(column,"This era"),String(era.story))
	_text(column,"%d forged rows · two skill sockets · %d of %d rails set" % [int(foundry.last_row)-int(foundry.first_row)+1,int(foundry.rails_set),int(foundry.rails_allowed)],UiTheme.FROST)
	column = _card("Discover → practise → shape","Find skills, practise them, then shape their workings in the Foundry (F).")
	var details := _details(column)
	_text(details,"Find a page, use its skill to reach the listed mastery milestones, then lay its tablet in a Foundry socket. Ingots beside it support it; specific Kinds transform every ingot along an inward path.")
	_text(details,"Milestones forge permanent ingots: useful crafts, first encounters, exploration and trials. Arrange the same pieces differently to try a different build.")
	column = _card("Forge a wider working","New eras and available alloys broaden your existing pieces.")
	details = _details(column)
	_text(details,"Eras add rows to the plate. At a built forge, re-cast an ingot in hand in an available alloy for richer direct support readings as well as longer backing/pair reach. Bronze Reach adds pierce; steel adds a fork. Supports still touch the skill.")
	for metal in foundry.get("metals",[]):
		_text(details,"%s · reach %d %s · available from era %d" % [metal.display_name,int(metal.reach),"cell" if int(metal.reach)==1 else "cells",int(metal.era)],UiTheme.SUN_WARM)
	column = _card("Choose when the world advances","Take a trial curio to the landmark it names when you are ready.")
	details = _details(column)
	_text(details,"Setting a curio there turns the era; time and skill uses do not advance it. Your existing equipment, skills and buildings carry forward.")
	for hint in sim.curio_hints(): _text(details,String(hint),UiTheme.FROST)
	if bool(foundry.get("can_specialise",false)):
		_text(column,"Your trial specialisation is ready. Open the Foundry (F) to compare and choose it.",UiTheme.GRASS_LIGHT)
