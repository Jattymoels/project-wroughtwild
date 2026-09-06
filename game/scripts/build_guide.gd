class_name BuildGuide
extends VBoxContainer
## A page of the existing pack screen: discovery, mastery and Foundry paths.
signal changed
signal assign_requested(skill: String, slot: int)
var sim: WroughtwildSim
var page := "Skills"
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
	for text in ["Skills","Kinds","Progression","Wild finds"]:
		var button := Button.new()
		button.text = text
		button.toggle_mode = true
		button.button_pressed = page==text
		button.pressed.connect(select_page.bind(text))
		tabs.add_child(button)
	match page:
		"Skills": _skills()
		"Kinds": _kinds()
		"Progression": _progression()
		"Wild finds": _wild_finds()
	changed.emit()

func select_page(value: String) -> void:
	page = value
	refresh()

func _wild_finds() -> void:
	_text(self,"The fallen technology drives growth, tension, light and pressure beyond their old limits. Follow husks, bent roots, ringing splinters and unusual grit. Ordinary interaction works for every class. Assemble your finds at a workbench, then use B and Tab to place the kit.")
	for info in sim.rare_resource_guide():
		var column := _card(String(info.display_name),String(info.use_preview))
		_text(column,"Property: %s · %d carried" % [", ".join(info.properties),sim.material_count(info.id)],UiTheme.SUN_WARM)
		_text(column,"Work: "+" → ".join(info.harvest_stages))
	_text(self,"Wind supplies energy. Stormglass carries a signal. Link a lever to a nearby lamp or winch; link the winch to a landing. Dismantling returns intact rare cores.")

func select_filter(value: String) -> void:
	filter = value
	refresh()

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
	_text(self,"%d / %d skills discovered · Pages teach skills you do not know. Any class can learn any page. Equip a learned skill below; support its tablet in the Foundry (F)." % [known.size(),sim.combat_skill_ids().size()])
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
		var column := _card("%s · %s" % [skill.display_name,status],String(skill.get("description","")))
		if learned:
			var working: Dictionary = sim.skill_mutation(id)
			for form in working.get("forms", []): _text(column, "%s — %s" % [form.form_name, form.description], UiTheme.SUN_WARM)
		var recovery := sim.skill_cooldown_seconds(id)
		if String(skill.get("delivery",""))=="dash":
			recovery /= 1.0+float(sim.derived_stats().get("dash_recovery",0))
		_text(column,"%s · %.2f s recovery" % [" / ".join(tags),recovery],UiTheme.FROST)
		var uses := int(skill.get("practice",0))
		var next: Dictionary = {}
		for perk in skill.get("mastery",[]):
			_text(column,"%s %s · %d practice" % ["✓" if perk.unlocked else "◇",perk.text,int(perk.uses)],UiTheme.GRASS_LIGHT if perk.unlocked else UiTheme.MUTED)
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
			_text(column,"Drops as an unknown skill page from roaming enemies and trial fights. Learning it is permanent; mastery starts when you use it.")

func _kinds() -> void:
	_text(self,"Kinds have two jobs: spend one to aim a gear craft, or place it in a Foundry corner. A chain of pieces must carry it inward to a skill. Lift it for the normal re-forging cost to recover it.")
	for kind in sim.currency_kinds():
		shown_kinds.append(String(kind.id))
		var description := String(kind.get("description",""))
		if description=="": description = "Works adjacent supports into %s forms. Aimed gear crafts favour %s modifiers." % [kind.family,kind.get("craft_tag",kind.family)]
		var column := _card("%s · held %d" % [kind.display_name,int(kind.held)],description)
		var sources: PackedStringArray = kind.get("sources",PackedStringArray())
		if not sources.is_empty(): _text(column,"Hunt: "+", ".join(sources),UiTheme.FROST)
		if kind.exchangeable: _text(column,"Peddler: exchange %d of another listed Kind for one." % sim.exchange_rate(),UiTheme.SUN_WARM)

func _progression() -> void:
	var era: Dictionary = sim.era()
	var foundry: Dictionary = sim.foundry()
	var column := _card("Era %d · %s" % [int(era.index),era.display_name],String(era.story))
	_text(column,"%d forged rows · two skill sockets · %d of %d rails set" % [int(foundry.last_row)-int(foundry.first_row)+1,int(foundry.rails_set),int(foundry.rails_allowed)],UiTheme.FROST)
	column = _card("Discover → practise → shape","Find a page, use its skill to reach the listed mastery milestones, then lay its tablet in a Foundry socket. Ingots beside it support it; specific Kinds transform every ingot along an inward path.")
	_text(column,"Milestones forge permanent ingots: useful crafts, first encounters, exploration and trials. Arrange the same pieces differently to try a different build.")
	column = _card("Forge a wider working","Eras add rows to the plate. At a built forge, re-cast an ingot in hand in an available alloy for richer direct support readings as well as longer backing/pair reach. Bronze Reach adds pierce; steel adds a fork. Supports still touch the skill.")
	for metal in foundry.get("metals",[]):
		_text(column,"%s · reach %d %s · available from era %d" % [metal.display_name,int(metal.reach),"cell" if int(metal.reach)==1 else "cells",int(metal.era)],UiTheme.SUN_WARM)
	column = _card("Choose when the world advances","Trial curios name the place that can receive them. Setting a curio there turns the era; time and skill uses do not advance it. Your existing equipment, skills and buildings carry forward.")
	for hint in sim.curio_hints(): _text(column,String(hint),UiTheme.FROST)
	if bool(foundry.get("can_specialise",false)):
		_text(column,"Your trial specialisation is ready. Open the Foundry (F) to compare and choose it.",UiTheme.GRASS_LIGHT)
