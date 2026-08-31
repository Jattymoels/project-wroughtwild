class_name WorkPanel
extends CanvasLayer
## One panel for every "work" interaction in the valley: crafting at a station
## and delivering to an order board. Rows are built from the sim's tuning
## views and every button routes back into the sim, so the panel never
## computes a rule; it only shows what the rules say.

signal closed

var sim: WroughtwildSim

var _root: PanelContainer
var _title: Label
var _body: VBoxContainer
var _message: Label

var _mode := ""  # "crafting" | "order" | "custom" | ""
var _station: StationSite
var _order_id := ""
var _custom_title := ""
var _custom_rows: Array = []


func _ready() -> void:
	layer = 10
	_root = PanelContainer.new()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.custom_minimum_size = Vector2(680, 0)
	_root.visible = false
	add_child(_root)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	_root.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	column.add_child(_title)

	_body = VBoxContainer.new()
	_body.add_theme_constant_override("separation", 6)
	column.add_child(_body)

	_message = Label.new()
	_message.modulate = Color(1.0, 0.9, 0.5)
	column.add_child(_message)

	var close := Button.new()
	close.text = "Close  (Esc)"
	close.pressed.connect(close_panel)
	column.add_child(close)


func is_open() -> bool:
	return _root != null and _root.visible


func open_crafting(station: StationSite) -> void:
	_mode = "crafting"
	_station = station
	_message.text = ""
	_root.visible = true
	refresh()


## Field crafting: what bare hands can make anywhere (recipes with no
## station). The start-with-nothing entry point.
func open_hand_crafting() -> void:
	_mode = "crafting"
	_station = null
	_message.text = ""
	_root.visible = true
	refresh()


func open_order(order_id: StringName) -> void:
	_mode = "order"
	_order_id = order_id
	_message.text = ""
	_root.visible = true
	refresh()


## Arbitrary choice list: rows are {text, button, enabled (optional),
## callback (Callable)}. Used for trial doors and offers.
func open_custom(title: String, rows: Array, message_text: String = "") -> void:
	_mode = "custom"
	_custom_title = title
	_custom_rows = rows
	_message.text = message_text
	_root.visible = true
	refresh()


func close_panel() -> void:
	if not is_open():
		return
	_root.visible = false
	_mode = ""
	closed.emit()


func message() -> String:
	return _message.text


## "iron ore 2 (have 5), wood 1 (have 0)"
static func cost_text(cost: Dictionary, sim_ref: WroughtwildSim) -> String:
	var parts := PackedStringArray()
	for id in cost:
		var have: int = maxi(sim_ref.material_count(id), sim_ref.currency_count(id))
		parts.append("%s %d (have %d)" % [Hud.pretty(id), cost[id], have])
	return ", ".join(parts)


static func amounts_text(amounts: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in amounts:
		parts.append("%s %d" % [Hud.pretty(id), amounts[id]])
	return ", ".join(parts)


# --- actions (also the test surface) ------------------------------------------

func craft(recipe_id: StringName) -> Dictionary:
	var for_order: bool = sim.recipe_feeds_open_order(recipe_id)
	var result: Dictionary = sim.craft(recipe_id, for_order)
	var recipe: Dictionary = sim.recipe(recipe_id)
	if result["crafted"]:
		var note := "Crafted %s  (+%d xp" % [recipe.get("display_name", recipe_id), result["xp_granted"]]
		if result["xp_multiplier"] < 1.0:
			note += ", reduced: this work serves no real demand"
		_message.text = note + ")"
	else:
		match result.get("failure", ""):
			"station_unavailable": _message.text = "You need a %s for that." % Hud.pretty(recipe.get("station", "station"))
			"skill_too_low": _message.text = "Your Blacksmithing is too low."
			"missing_inputs": _message.text = "Not enough materials."
			"missing_fuel": _message.text = "The forge is cold: it needs fuel (wood or charcoal)."
			_: _message.text = "Cannot craft that."
	refresh()
	return result


func upgrade() -> bool:
	if _station == null:
		return false
	var target: StringName = _station.upgrade_station_id
	var built: bool = sim.build_station(target)
	if built:
		_station.refresh_visual(sim)
		_message.text = "Upgraded to %s." % sim.station(target).get("display_name", target)
	else:
		_message.text = "Upgrade needs %s." % cost_text(sim.station(target).get("upgrade_cost", {}), sim)
	refresh()
	return built


func equip(base_id: StringName) -> bool:
	var worn: bool = sim.equip_from_inventory(base_id)
	_message.text = "You strap on the armour." if worn else "You have none to wear."
	refresh()
	return worn


func temper_basic() -> Dictionary:
	var result: Dictionary = sim.temper_basic()
	if result["applied"]:
		_message.text = "You quench the plates carefully. %s is now %d%%." % [
			sim.basic_temper_info()["property_display_name"], int(result["value"])]
	else:
		match result.get("reason", ""):
			"no_armour": _message.text = "Wear your armour first."
			"station_unavailable": _message.text = "Quenching needs the Improved Forge."
			_: _message.text = "Nothing to quench."
	refresh()
	return result


func temper_catalyst(process_id: StringName) -> Dictionary:
	var result: Dictionary = sim.temper_with_catalyst(process_id)
	var p: Dictionary = sim.catalyst_process(process_id)
	if result["applied"]:
		_message.text = "The catalyst flares as it burns into the metal. %s is now %d%% (was %d%%)." % [
			p["property_display_name"], int(result["rolled_value"]), int(result["previous_value"])]
	else:
		match result.get("reason", ""):
			"no_armour": _message.text = "Wear your armour first."
			"station_unavailable": _message.text = "Ember-tempering needs the Improved Forge."
			"missing_catalyst": _message.text = "You need an Ember Catalyst; the trial holds them."
			"skill_too_low": _message.text = "The catalyst's heat is beyond your skill."
			_: _message.text = "The catalyst will not take."
	refresh()
	return result


func deliver() -> Dictionary:
	var result: Dictionary = sim.fulfill_order(_order_id)
	if result["fulfilled"]:
		_message.text = "The crew hauls your work away. The old mine is reinforced; its tunnels are safe and the foreman pays well."
	elif result.get("already_fulfilled", false):
		_message.text = "This order is already complete."
	else:
		_message.text = "You have not made enough yet."
	refresh()
	return result


# --- rendering ---------------------------------------------------------------

func refresh() -> void:
	for child in _body.get_children():
		child.queue_free()
	match _mode:
		"crafting": _render_crafting()
		"order": _render_order()
		"custom": _render_custom()


func _render_custom() -> void:
	_title.text = _custom_title
	for row in _custom_rows:
		_add_row(row.get("text", ""), row.get("button", ""), row.get("enabled", true), row.get("callback", Callable()))


func _add_row(text: String, button_text: String = "", enabled := false, on_pressed: Callable = Callable()) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	if button_text != "":
		var button := Button.new()
		button.text = button_text
		button.disabled = not enabled
		button.custom_minimum_size = Vector2(110, 0)
		if on_pressed.is_valid():
			button.pressed.connect(on_pressed)
		row.add_child(button)
	_body.add_child(row)


func _render_crafting() -> void:
	# The stations this panel works at: none for field crafting, or the
	# site's built chain (a forge keeps its basic recipes when improved).
	var chain: Array = []
	if _station == null:
		_title.text = "Field Crafting"
		_add_row("What bare hands can make. A placed workbench unlocks assembly; a forge unlocks metalwork.")
	else:
		var station_id: StringName = _station.current_station_id(sim)
		_title.text = sim.station(station_id).get("display_name", "Forge")
		chain.append(String(_station.station_id))
		if _station.upgrade_station_id != &"":
			chain.append(String(_station.upgrade_station_id))

	var skill: Dictionary = sim.skill_progress("blacksmithing")
	var next: String = "max" if skill["next_level_xp"] < 0 else str(skill["next_level_xp"])
	_add_row("%s level %d  (%d / %s xp)" % [skill["display_name"], skill["level"], skill["xp"], next])

	var shows_fuel := false
	for recipe_id in sim.recipe_ids():
		var r: Dictionary = sim.recipe(recipe_id)
		if _station == null and not r["hand_craftable"]:
			continue
		if _station != null and not (r["hand_craftable"] or chain.has(String(r["station"]))):
			continue
		var skill_text := ""
		for skill_id in r["minimum_skill"]:
			skill_text += "%s %d" % [Hud.pretty(skill_id), r["minimum_skill"][skill_id]]
		var where: String = "by hand" if r["hand_craftable"] else Hud.pretty(r["station"])
		var line := "%s  —  %s%s\n    %s  →  %s" % [
			r["display_name"], where, ("" if skill_text == "" else ", " + skill_text),
			cost_text(r["inputs"], sim), amounts_text(r["outputs"])]
		if int(r["fuel_cost"]) > 0:
			line += "\n    burns %d fuel" % int(r["fuel_cost"])
			shows_fuel = true
		if sim.recipe_feeds_open_order(recipe_id):
			line += "\n    ★ feeds an open order: full XP"
		var craftable: bool = r["station_available"] and r["skill_met"] and r["inputs_met"] and r["fuel_met"]
		_add_row(line, "Craft", craftable, craft.bind(recipe_id))

	if shows_fuel:
		_add_row("Fuel on hand: %d  (wood burns as 1, charcoal as 4)" % sim.fuel_value_held())

	if _station == null:
		return

	var upgrade_id: StringName = _station.upgrade_station_id
	if upgrade_id != &"" and not sim.has_station(upgrade_id):
		var target: Dictionary = sim.station(upgrade_id)
		_add_row("Upgrade to %s  —  %s" % [target.get("display_name", upgrade_id), cost_text(target.get("upgrade_cost", {}), sim)],
			"Upgrade", sim.can_build_station(upgrade_id), upgrade)

	# Armour work belongs to the forge; the workbench stops here.
	if _station.station_id != &"forge_basic":
		return

	# Armour: wear it, then temper it here. The effect of each temper is
	# stated before anything is consumed.
	var worn: Dictionary = sim.equipment().get("chest", {})
	if worn.is_empty():
		_add_row("Wearing nothing. Craft Iron Chest Armour, then wear it here.")
	else:
		_add_row("Wearing %s  —  armour %d, fire resistance %d%%" % [
			worn["display_name"], int(worn["armour"]), int(worn["fire_resistance"])])
	var armour_held: int = sim.material_count("iron_chest_armour")
	if armour_held > 0:
		_add_row("Iron Chest Armour in your pack (%d)" % armour_held, "Wear", true, equip.bind(&"iron_chest_armour"))

	var quench: Dictionary = sim.basic_temper_info()
	_add_row("Quench  —  sets %s to at least %d%% (a fixed baseline, no roll). Needs a forge that supports %s%s." % [
		quench["property_display_name"], int(quench["value"]), Hud.pretty(quench["process"]),
		"" if quench["station_available"] else " (upgrade first)"],
		"Quench", quench["armour_equipped"] and quench["station_available"], temper_basic)

	for process_id in sim.catalyst_process_ids():
		var p: Dictionary = sim.catalyst_process(process_id)
		var skill_text := ""
		for skill_id in p["minimum_skill"]:
			skill_text = "%s %d" % [Hud.pretty(skill_id), p["minimum_skill"][skill_id]]
		var line := "%s  —  consumes 1 %s. Guarantees %s tier %d: a roll between %d%% and %d%%, floor %d%% at %s; never lowers an existing roll. Needs %s. Catalysts held: %d." % [
			p["display_name"], Hud.pretty(p["catalyst"]), p["property_display_name"], p["result_tier"],
			int(p["tier_minimum"]), int(p["tier_maximum"]), int(p["floor_at_skill"]), skill_text,
			Hud.pretty(p["station"]), p["catalyst_held"]]
		var can_temper: bool = p["armour_equipped"] and p["station_available"] and p["skill_met"] and p["catalyst_held"] > 0
		_add_row(line, "Temper", can_temper, temper_catalyst.bind(StringName(process_id)))


func _render_order() -> void:
	var o: Dictionary = sim.order(_order_id)
	_title.text = o.get("display_name", "Order")
	if o.get("fulfilled", false):
		_add_row("Complete. The old mine is reinforced.")
		return
	_add_row("Deliver: %s" % cost_text(o["required_outputs"], sim))
	_add_row("Reward: %s" % amounts_text(o["rewards"]))
	var can_deliver := true
	for id in o["required_outputs"]:
		if sim.material_count(id) < o["required_outputs"][id]:
			can_deliver = false
	_add_row("The mine crew will haul the fittings away and shore up the tunnels.", "Deliver", can_deliver, deliver)
