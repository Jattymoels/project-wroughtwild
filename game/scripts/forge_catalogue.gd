class_name ForgeCatalogue
extends VBoxContainer
## Catalogue/selection/action layout shared in spirit with the building picker.
## All payment, roll ranges, eligibility and comparisons come from native views.
var work: WorkPanel
var category := "Equipment"
var selection := ""
var aim := ""
var quality := 1
var potency_choice := 1
var quantity := 1
var operation := "Make"
var query := ""
var history: Array[String] = []
var pinned := ""
var card_count := 0
var last_preview: Dictionary = {}
var _cards: VBoxContainer
var _detail: VBoxContainer
var _action: Button
var _next: Label
var _cost_summary: Label
var _detail_scroll: ScrollContainer
var _pin_hud: Label
var _pin_clock := 0.0
var _opened_where: Array[String] = []

func _ready() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation",10)
	_pin_hud = Label.new()
	_pin_hud.theme = UiTheme.theme()
	_pin_hud.position = Vector2(24,145)
	_pin_hud.custom_minimum_size.x = 330
	_pin_hud.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_pin_hud.add_theme_font_size_override("font_size",14)
	work.add_child(_pin_hud)

func _process(delta: float) -> void:
	_pin_clock -= delta
	if _pin_clock > 0: return
	_pin_clock = 0.5
	_pin_hud.visible = not work.is_open() and pinned != ""
	if pinned == "" or work.sim == null: return
	var preview: Dictionary = work.sim.craft_preview(pinned)
	var parts := PackedStringArray()
	for cost in preview.get("costs",[]):
		if int(cost.have) < int(cost.need): parts.append("%s %d/%d" % [Hud.pretty(cost.id),cost.have,cost.need])
	if int(preview.get("fuel_available",0)) < int(preview.get("fuel",0)): parts.append("Fuel %d/%d" % [preview.fuel_available,preview.fuel])
	_pin_hud.text = "PINNED · %s\n%s" % [work.sim.recipe(pinned).get("display_name",pinned)," · ".join(parts) if not parts.is_empty() else String(preview.get("next_action",""))]

func _clear(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()

func _label(parent: Node, text: String, colour: Color = UiTheme.PARCHMENT, font_size: int = 14) -> Label:
	var label := Label.new()
	label.text = text
	label.modulate = colour
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size",font_size)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, callback: Callable, enabled := true) -> Button:
	var button := Button.new()
	button.text = text
	button.disabled = not enabled
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func _where() -> Array[String]:
	var chain: Array[String] = [""]
	if work._station != null:
		chain.append(String(work._station.station_id))
		if work._station.upgrade_station_id != &"": chain.append(String(work._station.upgrade_station_id))
	return chain

func open_station() -> void:
	var here := _where()
	if here == _opened_where: return
	_opened_where = here
	selection = ""
	history.clear()
	query = ""
	aim = ""
	quality = 1
	potency_choice = 1
	quantity = 1
	operation = "Make"
	# Bare-hand work has no equipment category. Start with a real local list
	# instead of carrying an empty or unrelated list over from the last bench.
	var categories: Array[String] = []
	for id in work.sim.recipe_ids():
		var recipe: Dictionary = work.sim.recipe(id)
		if _local_quality(recipe) > 0:
			var local_category := _category(recipe)
			if not categories.has(local_category): categories.append(local_category)
	if not categories.has(category):
		for fallback in ["Equipment","Materials","Stations & upgrades"]:
			if categories.has(fallback):
				category = fallback
				break

func _local_quality(recipe: Dictionary) -> int:
	if _where().has(String(recipe.station)): return 1
	# Better fittings are existing forge work, including wooden equipment whose
	# rough assembly belongs to the bench. Ingredient ownership never hides it.
	if work._station != null and _category(recipe) == "Equipment":
		var station := String(work._station.current_station_id(work.sim))
		var preview: Dictionary = work.sim.craft_preview(String(recipe.id))
		for grade in preview.grades:
			if int(grade.tier)>1 and String(grade.station)==station: return int(grade.tier)
	return 0

func _category(recipe: Dictionary) -> String:
	for output in recipe.outputs:
		if not work.sim.item_base(output).is_empty(): return "Equipment"
		if String(output).ends_with("_kit"): return "Stations & upgrades"
	return "Materials"

func refresh() -> void:
	if not is_inside_tree() or work.sim == null: return
	_clear(self)
	card_count = 0
	var rail := HBoxContainer.new()
	add_child(rail)
	for text in ["Equipment","Materials","Stations & upgrades"]:
		var button := _button(rail,text,func(): category = text; selection = ""; query = ""; aim = ""; quality = 1; quantity = 1; refresh())
		button.toggle_mode = true
		button.button_pressed = category == text
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rail.add_child(spacer)
	_button(rail,"Foundry  F",work._open_foundry)
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation",18)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(columns)
	var catalogue := VBoxContainer.new()
	catalogue.custom_minimum_size.x = 330
	columns.add_child(catalogue)
	var search := LineEdit.new()
	search.placeholder_text = "Find a recipe…"
	search.text = query
	search.text_changed.connect(func(value: String): query = value; _render_cards())
	catalogue.add_child(search)
	var card_scroll := ScrollContainer.new()
	card_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	card_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	catalogue.add_child(card_scroll)
	_cards = VBoxContainer.new()
	_cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_scroll.add_child(_cards)
	var side := VBoxContainer.new()
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_child(side)
	_detail_scroll = ScrollContainer.new()
	_detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	side.add_child(_detail_scroll)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation",9)
	_detail.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_scroll.add_child(_detail)
	_cost_summary = _label(side,"",UiTheme.GRASS_LIGHT,13)
	_next = _label(side,"",UiTheme.SUN_WARM)
	_action = _button(side,"Make 1",_make)
	_action.custom_minimum_size.y = 42
	_render_cards()
	_render_detail()

func _render_cards() -> void:
	_clear(_cards)
	card_count = 0
	var ids: Array[String] = []
	var rows := {}
	for id in work.sim.recipe_ids():
		var recipe: Dictionary = work.sim.recipe(id)
		if _category(recipe) != category: continue
		if query != "" and not String(recipe.display_name).to_lower().contains(query.to_lower()): continue
		var local_quality := _local_quality(recipe)
		if local_quality == 0: continue
		ids.append(String(id))
		# Native preview reserves inputs before fuel and includes skill/era gates.
		# A recipe with all its wood committed cannot also count it as spare heat.
		rows[String(id)] = {"recipe":recipe,"preview":work.sim.craft_preview(id,"",local_quality),"quality":local_quality}
	ids.sort_custom(func(a: String,b: String) -> bool:
		var ready_a := bool(rows[a].preview.ready)
		var ready_b := bool(rows[b].preview.ready)
		if ready_a != ready_b: return ready_a
		var name_a := String(rows[a].recipe.display_name)
		var name_b := String(rows[b].recipe.display_name)
		return name_a < name_b if name_a != name_b else a < b)
	if category == "Stations & upgrades" and work._station != null and work._station.upgrade_station_id != &"":
		_button(_cards,"Improve this forge",func(): selection = "@upgrade"; _render_detail())
		_button(_cards,"Recast Foundry alloys",func(): selection = "@alloys"; _render_detail())
	if selection == "" and not ids.is_empty():
		selection = ids[0]
		quality = int(rows[selection].quality)
	for id in ids:
		var recipe: Dictionary = rows[id].recipe
		var preview: Dictionary = rows[id].preview
		var card := Button.new()
		card.set_meta("recipe_id",id)
		card.custom_minimum_size = Vector2(318,86)
		card.toggle_mode = true
		card.button_pressed = selection == id
		card.pressed.connect(select_recipe.bind(id))
		_cards.add_child(card)
		var icon := ForgeIcon.new()
		icon.item_id = String(recipe.outputs.keys()[0])
		icon.material_id = String(work.sim.item_base(icon.item_id).get("material","iron"))
		icon.position = Vector2(4,5)
		icon.size = Vector2(70,74)
		card.add_child(icon)
		var text := VBoxContainer.new()
		text.mouse_filter = Control.MOUSE_FILTER_IGNORE
		text.position = Vector2(78,10)
		text.size = Vector2(225,68)
		card.add_child(text)
		_label(text,String(recipe.display_name),UiTheme.PARCHMENT,15).mouse_filter = Control.MOUSE_FILTER_IGNORE
		var ready := bool(preview.ready)
		var status := "Ready here" if ready else String(preview.next_action).replace("_"," ")
		if int(rows[id].quality)>1: status = String(preview.grades[int(rows[id].quality)-1].quality)+" forging · "+status
		_label(text,status,UiTheme.GRASS_LIGHT if ready else UiTheme.MUTED,12).mouse_filter = Control.MOUSE_FILTER_IGNORE
		card_count += 1

func select_recipe(id: String, remember := false) -> void:
	if remember and selection != "" and selection != id: history.append(selection)
	selection = id
	aim = ""
	potency_choice = 1
	quality = maxi(1,_local_quality(work.sim.recipe(id)))
	quantity = 1
	operation = "Make"
	category = _category(work.sim.recipe(id))
	query = ""
	refresh()

func _render_detail() -> void:
	_clear(_detail)
	_action.visible = false
	_next.text = ""
	_cost_summary.text = ""
	if selection.begins_with("@"):
		_render_station()
		return
	var recipe: Dictionary = work.sim.recipe(selection)
	if recipe.is_empty():
		_label(_detail,"Select a recipe to inspect its requirements.")
		return
	last_preview = work.sim.craft_preview(selection,aim,quality,quantity)
	var preview := last_preview
	var head := HBoxContainer.new()
	_detail.add_child(head)
	var icon := ForgeIcon.new()
	icon.custom_minimum_size = Vector2(58,58)
	icon.item_id = String(recipe.outputs.keys()[0])
	icon.material_id = String(work.sim.item_base(icon.item_id).get("material","iron"))
	head.add_child(icon)
	var title := VBoxContainer.new()
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(title)
	_label(title,String(recipe.display_name),UiTheme.PARCHMENT,23)
	_label(title,"By hand" if recipe.station == "" else Hud.pretty(recipe.station),UiTheme.MUTED,13)
	var navigation := HBoxContainer.new()
	_detail.add_child(navigation)
	if not history.is_empty(): _button(navigation,"← Back to item",func(): var id: String = history.pop_back(); select_recipe(id))
	_button(navigation,"Unpin recipe" if pinned == selection else "Pin requirements",func(): pinned = "" if pinned == selection else selection; _render_detail())
	var gear := String(preview.base_id) != ""
	if gear:
		var tabs := HBoxContainer.new()
		_detail.add_child(tabs)
		for text in ["Make","Improve","Transfer"]:
			var tab := _button(tabs,text,func(): operation = text; _render_detail())
			tab.toggle_mode = true
			tab.button_pressed = operation == text
		if operation != "Make":
			_render_improve(operation)
			return
		_render_equipment(preview)
	else:
		var count := HBoxContainer.new()
		_detail.add_child(count)
		_label(count,"Batches",UiTheme.MUTED)
		var amount := SpinBox.new()
		amount.min_value = 1
		amount.max_value = int(preview.batch_maximum)
		amount.value = quantity
		amount.value_changed.connect(func(value: float): quantity = int(value); _render_detail())
		count.add_child(amount)
		_label(_detail,"Produces %s" % WorkPanel.amounts_text(_multiplied(recipe.outputs,quantity)),UiTheme.GRASS_LIGHT)
	_label(_detail,"REQUIREMENTS",UiTheme.MUTED,12)
	for cost in preview.costs:
		var row := HBoxContainer.new()
		_detail.add_child(row)
		var missing := int(cost.have) < int(cost.need)
		_label(row,"%s  %d / %d" % [Hud.pretty(cost.id),cost.have,cost.need],UiTheme.CINDER if missing else UiTheme.GRASS_LIGHT)
		if String(cost.recipe) != "" and String(cost.recipe) != selection:
			_button(row,"View recipe",select_recipe.bind(String(cost.recipe),true))
	if int(preview.fuel)>0:
		_label(_detail,"Fuel after reserving ingredients  %d / %d" % [preview.fuel_available,preview.fuel],UiTheme.GRASS_LIGHT if int(preview.fuel_available)>=int(preview.fuel) else UiTheme.CINDER)
		_label(_detail,"Wood burns as 1; charcoal as 4. The whole batch is checked before anything is spent.",UiTheme.MUTED,12)
	var cost_parts := PackedStringArray()
	var all_costs_met := true
	for cost in preview.costs:
		cost_parts.append("%s %d/%d" % [Hud.pretty(cost.id),cost.have,cost.need])
		all_costs_met = all_costs_met and int(cost.have)>=int(cost.need)
	if int(preview.fuel)>0: cost_parts.append("Fuel %d/%d" % [preview.fuel_available,preview.fuel])
	_cost_summary.text = " · ".join(cost_parts)
	_cost_summary.modulate = UiTheme.GRASS_LIGHT if all_costs_met and int(preview.fuel_available)>=int(preview.fuel) else UiTheme.CINDER
	var here := _where().has(String(recipe.station))
	# Better-quality work is physically performed at the forge, even for a wooden base.
	if gear and maxi(quality,int(preview.potency)) > 1: here = _where().has("forge_improved")
	_next.text = String(preview.next_action).replace("_"," ") if here else "Take these materials to %s." % ("the Improved Forge" if gear and maxi(quality,int(preview.potency))>1 else Hud.pretty(recipe.station))
	_action.text = "Make %d" % quantity
	_action.disabled = not bool(preview.ready) or not here
	_action.visible = true

func _render_equipment(preview: Dictionary) -> void:
	var comparison: Dictionary = preview.comparison
	var candidate: Dictionary = comparison.get("candidate",{})
	var current: Dictionary = comparison.get("current",{})
	_label(_detail,"Guaranteed base · %s" % Hud.pretty(comparison.get("slot","equipment")),UiTheme.GRASS_LIGHT)
	for mod in candidate.get("mods",[]): _label(_detail,String(mod.sentence),UiTheme.PARCHMENT)
	if float(candidate.get("armour",0))>0: _label(_detail,"%g armour" % float(candidate.armour))
	_label(_detail,"Wearing: %s · base comparison before random rolls" % current.get("display_name","nothing in this slot"),UiTheme.MUTED,12)
	for skill in comparison.get("skills",[]):
		var before := float(skill.before.get("hit_payload",0))
		var after := float(skill.after.get("hit_payload",0))
		if not is_equal_approx(before,after): _label(_detail,"%s hit: %.1f → %.1f" % [skill.display_name,before,after],UiTheme.MUTED,12)
	var grade_row := HBoxContainer.new()
	_detail.add_child(grade_row)
	_label(grade_row,"Workpiece",UiTheme.MUTED)
	var grade_select := OptionButton.new()
	for grade in preview.grades: grade_select.add_item("%s · tier %d%s" % [grade.quality,grade.tier,"" if grade.available else " · locked"])
	grade_select.select(quality-1)
	grade_select.item_selected.connect(func(index: int): quality = index+1; _render_detail())
	grade_row.add_child(grade_select)
	_label(_detail,"Expresses up to tier %d; stronger rolls keep their stored potential." % quality,UiTheme.MUTED,12)
	var kind_row := HBoxContainer.new()
	_detail.add_child(kind_row)
	_label(kind_row,"Imprint",UiTheme.MUTED).custom_minimum_size.x = 76
	var kinds := OptionButton.new()
	kinds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	kinds.fit_to_longest_item = false
	kinds.clip_text = true
	kinds.add_item("No Kind · random Faint rolls")
	kinds.set_item_metadata(0,"")
	var canonical := ""
	if aim != "":
		for kind in preview.kinds:
			if String(kind.id) == aim:
				canonical = String(kind.canonical_kind)
				potency_choice = int(kind.potency)
	var index := 1
	for kind in preview.kinds:
		if int(kind.potency) != potency_choice: continue
		kinds.add_item("%s · have %d%s" % [Hud.pretty(kind.canonical_kind),kind.held,"" if kind.compatible else " · incompatible"])
		kinds.set_item_metadata(index,String(kind.id))
		kinds.set_item_disabled(index,not bool(kind.compatible))
		if String(kind.id)==aim: kinds.select(index)
		index += 1
	kinds.item_selected.connect(func(i: int): aim = String(kinds.get_item_metadata(i)); _render_detail())
	kind_row.add_child(kinds)
	var potency := OptionButton.new()
	for grade in preview.grades: potency.add_item(String(grade.potency))
	potency.select(potency_choice-1)
	potency.item_selected.connect(func(i: int):
		potency_choice = i+1
		if canonical != "":
			for kind in preview.kinds:
				if String(kind.canonical_kind)==canonical and int(kind.potency)==potency_choice: aim = String(kind.id)
		_render_detail())
	kind_row.add_child(potency)
	var chance := PackedStringArray()
	for outcome in preview.outcomes: chance.append("%s %d%% (%d mods)" % [outcome.name,roundi(float(outcome.chance)*100),outcome.count])
	_label(_detail," · ".join(chance),UiTheme.SUN_WARM,12)
	_label(_detail,"First roll is drawn from the Kind's family. Rarity counts modifiers; potency sets their strength.",UiTheme.MUTED,12)
	for modifier in preview.modifiers:
		if not modifier.eligible: continue
		var band: Dictionary = modifier.bands[int(preview.potency)-1]
		_label(_detail,"If rolled: %s → %s" % [band.minimum_sentence,band.maximum_sentence],UiTheme.FROST,12)
		if band.held_back: _label(_detail,"On this workpiece: up to %s. The stronger roll stays stored." % band.expressed_sentence,UiTheme.SUN_WARM,12)
		break
	var potentials := Button.new()
	potentials.text = "Inspect modifier ranges & next grades"
	_detail.add_child(potentials)
	var ranges := VBoxContainer.new()
	ranges.visible = false
	_detail.add_child(ranges)
	potentials.pressed.connect(func(): ranges.visible = not ranges.visible)
	for modifier in preview.modifiers:
		_label(ranges,String(modifier.name),UiTheme.PARCHMENT,14)
		for band in modifier.bands:
			if not band.eligible: continue
			var text := "%s: %s → %s" % [preview.grades[int(band.tier)-1].potency,band.minimum_sentence,band.maximum_sentence]
			if band.held_back: text += "\nOn this base: up to %s; stronger potential stays stored." % band.expressed_sentence
			for threshold_text in band.breakpoints: text += "\nAt full expression: " + String(threshold_text)
			_label(ranges,text,UiTheme.MUTED,12)
	# Keep the next actual upgrade visible before opening the exhaustive ranges.
	var next_tier := mini(3,maxi(quality,int(preview.potency))+1)
	var next_grade: Dictionary = preview.grades[next_tier-1]
	_label(_detail,"Next: %s workpiece / %s imprint · Blacksmithing %d · Era %d · %s" % [next_grade.quality,next_grade.potency,next_grade.skill,next_grade.era,Hud.pretty(next_grade.station)],UiTheme.FROST,12)
	var links := HBoxContainer.new()
	_detail.add_child(links)
	if String(next_grade.recipe)!="": _button(links,"Better ironwork",select_recipe.bind(String(next_grade.recipe),true))
	for kind in preview.kinds:
		if String(kind.canonical_kind)==canonical and int(kind.potency)==mini(3,int(preview.potency)+1) and String(kind.recipe)!="": _button(links,"Better catalyst",select_recipe.bind(String(kind.recipe),true))

func _render_improve(mode: String) -> void:
	if not _where().has("forge_basic"):
		_label(_detail,"Take the worn item and its materials to a forge for this work.")
		return
	if mode == "Transfer":
		var process: Dictionary = work.sim.catalyst_process("preserving_transfer")
		_label(_detail,"Move the worn item's exact modifiers onto a base of the same slot in your pack. The old base and one Preserving Catalyst are spent; stored potency survives.")
		var targets: Array = work.sim.transfer_targets("preserving_transfer")
		if targets.is_empty(): _label(_detail,"Wear the item to preserve and carry a replacement base with the same slot.",UiTheme.MUTED)
		for target in targets:
			_label(_detail,"%s → %s · capacity %d" % [target.worn_display_name,target.display_name,target.tier_cap])
			_button(_detail,"Transfer",work.transfer_catalyst.bind(&"preserving_transfer",int(target.index)),process.station_available and process.skill_met and int(process.catalyst_held)>0)
	else:
		var quench: Dictionary = work.sim.basic_temper_info()
		_label(_detail,"Quench worn chest armour · at least %g%% fire resistance. Fixed baseline; never lowers a better roll." % float(quench.value))
		_button(_detail,"Quench",work.temper_basic,quench.armour_equipped and quench.station_available)
		var temper: Dictionary = work.sim.catalyst_process("ember_catalyst_tempering")
		_label(_detail,"Ember-temper worn chest armour · %g–%g%% fire resistance; skill raises the floor to %g%%. Requires Blacksmithing 5, Improved Forge and one Stable Ember Catalyst (have %d)." % [temper.tier_minimum,temper.tier_maximum,temper.floor_at_skill,temper.catalyst_held])
		_button(_detail,"Ember-temper",work.temper_catalyst.bind(&"ember_catalyst_tempering"),temper.armour_equipped and temper.station_available and temper.skill_met and int(temper.catalyst_held)>0)

func _render_station() -> void:
	if selection == "@upgrade":
		var target := String(work._station.upgrade_station_id)
		var station: Dictionary = work.sim.station(target)
		_label(_detail,String(station.display_name),UiTheme.PARCHMENT,22)
		_label(_detail,"Sound ironwork and Stable catalyst refining. Fetch bog iron from the fen, finish useful fittings, and invest the mine payment.")
		_label(_detail,WorkPanel.cost_text(station.get("upgrade_cost",{}),work.sim))
		_button(_detail,"Improve forge",work.upgrade,work.sim.can_build_station(target) and not work.sim.has_station(target))
	else:
		_label(_detail,"Foundry alloys",UiTheme.PARCHMENT,22)
		_label(_detail,"Recasting increases how far an ingot reads on the plate. It is separate from equipment workpiece quality.",UiTheme.MUTED)
		var view: Dictionary = work.sim.foundry()
		for metal in view.get("metals",[]):
			if not metal.available: continue
			for id in work.sim.foundry_ingot_ids():
				if work.sim.can_recast(id,String(metal.id)):
					_button(_detail,"Recast %s in %s" % [work.sim.foundry_ingot(id).get("display_name",id),metal.display_name],work.recast.bind(id,String(metal.id)))

func _make() -> void:
	work.craft(StringName(selection),aim,quality,quantity)

static func _multiplied(cost: Dictionary, count: int) -> Dictionary:
	var result := {}
	for id in cost: result[id] = int(cost[id])*count
	return result
