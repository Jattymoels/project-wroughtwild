class_name WorkPanel
extends CanvasLayer
## One panel for every "work" interaction in the valley: crafting at a station,
## delivering to an order board, and the trial's doors and offers. Rows are
## cards built from the sim's tuning views — what it is, what it needs with
## have/need coloured, one button — inside a scroll area so a fully upgraded
## forge never pushes the close button off screen (docs/systems/interface.md).
## Every button routes back into the sim, so the panel never computes a rule;
## it only shows what the rules say.

signal closed

const MAX_HEIGHT_FRACTION := 0.6

var sim: WroughtwildSim

var _root: PanelContainer
var _title: Label
var _scroll: ScrollContainer
var _body: VBoxContainer
var _message: Label
var catalogue: ForgeCatalogue
var _column: VBoxContainer

var _mode := ""  # "crafting" | "order" | "custom" | ""
var _station: StationSite
var _order_id := ""
var _custom_title := ""
var _custom_rows: Array = []


func _ready() -> void:
	layer = 10
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.custom_minimum_size = Vector2(780, 0)
	_root.visible = false
	add_child(_root)
	_root.resized.connect(_centre_catalogue)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	_root.add_child(margin)

	var column := VBoxContainer.new()
	_column = column
	column.add_theme_constant_override("separation", 8)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close := Button.new()
	close.text = "Close  (Esc)"
	close.pressed.connect(close_panel)
	header.add_child(close)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, 80)
	column.add_child(_scroll)
	_body = VBoxContainer.new()
	_body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_body.add_theme_constant_override("separation", 6)
	_scroll.add_child(_body)

	_message = Label.new()
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_message.modulate = Color(1.0, 0.9, 0.5)
	column.add_child(_message)
	catalogue = ForgeCatalogue.new()
	catalogue.work = self
	catalogue.visible = false
	column.add_child(catalogue)
	column.move_child(catalogue, 1)
	get_viewport().size_changed.connect(_layout_catalogue)


func is_open() -> bool:
	return _root != null and _root.visible


func open_crafting(station: StationSite) -> void:
	_mode = "crafting"
	_station = station
	catalogue.open_station()
	_message.text = ""
	_root.visible = true
	refresh()


## Field crafting: what bare hands can make anywhere (recipes with no
## station). The start-with-nothing entry point.
func open_hand_crafting() -> void:
	_mode = "crafting"
	_station = null
	catalogue.open_station()
	_message.text = ""
	_root.visible = true
	refresh()


func open_order(order_id: StringName) -> void:
	_mode = "order"
	_order_id = order_id
	_message.text = ""
	_root.visible = true
	refresh()


func _open_foundry() -> void:
	var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player != null:
		player.open_foundry()


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


## Test surface: rows shown by the last refresh.
func row_count() -> int:
	return catalogue.card_count if _mode == "crafting" and catalogue != null else _body.get_child_count()


## "iron ore 2 (have 5), wood 1 (have 0)"
static func cost_text(cost: Dictionary, sim_ref: WroughtwildSim) -> String:
	var parts := PackedStringArray()
	for id in cost:
		var have: int = maxi(sim_ref.material_count(id), sim_ref.currency_count(id))
		parts.append("%s %d (have %d)" % [Hud.pretty(id), cost[id], have])
	return ", ".join(parts)


## The same, coloured per requirement: met in grass-light, short in cinder.
static func cost_bbcode(cost: Dictionary, sim_ref: WroughtwildSim) -> String:
	var parts := PackedStringArray()
	for id in cost:
		var have: int = maxi(sim_ref.material_count(id), sim_ref.currency_count(id))
		var colour: Color = UiTheme.GRASS_LIGHT if have >= int(cost[id]) else UiTheme.CINDER
		parts.append("[color=#%s]%s %d (have %d)[/color]" % [colour.to_html(false), Hud.pretty(id), cost[id], have])
	return ", ".join(parts)


static func amounts_text(amounts: Dictionary) -> String:
	var parts := PackedStringArray()
	for id in amounts:
		parts.append("%s %d" % [Hud.pretty(id), amounts[id]])
	return ", ".join(parts)


# --- actions (also the test surface) ------------------------------------------

## aim_kind (D-023 slice 3): a currency kind added to a gear craft, spent
## to draw the roll's first modifier from its family.
func craft(recipe_id: StringName, aim_kind: String = "", quality: int = 1, quantity: int = 1) -> Dictionary:
	var for_order: bool = sim.recipe_feeds_open_order(recipe_id)
	var recipe: Dictionary = sim.recipe(recipe_id)
	# The first dressed block is a beat (the stone accomplishment pass, 4
	# Sep 2026): none of its output in the pack before the craft.
	var first_dressed := String(recipe_id) == "dress_stone"
	for output_id in recipe.get("outputs", {}):
		if sim.material_count(String(output_id)) > 0:
			first_dressed = false
	var result: Dictionary = sim.craft(recipe_id, for_order, aim_kind, quality, quantity)
	if result["crafted"]:
		var note := "Crafted %s" % recipe.get("display_name", recipe_id)
		if quantity > 1: note += " ×%d" % quantity
		if int(result.xp_granted) > 0: note += " (+%d xp%s)" % [result.xp_granted, ", repetition reduced" if float(result.xp_multiplier) < 1.0 else ""]
		if aim_kind != "": note += " · " + Hud.pretty(aim_kind)
		_message.text = note + "."

		if first_dressed:
			var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
			if player != null and player.hud != null:
				player.hud.notify("Your first dressed block. Split from the seam, squared at the yard: stone is yours to build with now, and the forge's eight blocks are a real ambition.")
	else:
		match result.get("failure", ""):
			"station_unavailable": _message.text = "You need a %s for that." % Hud.pretty(recipe.get("station", "station"))
			"skill_too_low": _message.text = "Your Blacksmithing is too low."
			"incompatible_kind": _message.text = "This Kind cannot imprint a compatible modifier at this potency."
			"quality_unavailable": _message.text = "This grade needs its refining process, skill and era."
			"invalid_quantity": _message.text = "Choose a smaller material batch."
			"missing_kind": _message.text = "You hold no %s to aim the roll with." % Hud.pretty(aim_kind)
			"missing_inputs": _message.text = "Not enough materials."
			"missing_fuel": _message.text = "The forge is cold: it needs fuel (wood or charcoal)."
			_: _message.text = "Cannot craft that."
	refresh()
	return result


## Re-casts one ingot in hand in a wider metal (slice 10) through the sim.
func recast(ingot_id: String, metal_id: String) -> bool:
	var ok: bool = sim.foundry_recast(ingot_id, metal_id)
	if ok:
		var info: Dictionary = sim.foundry_ingot(ingot_id)
		_message.text = "The %s is re-cast in %s. F opens the plate." % [info.get("display_name", ingot_id), metal_id]
		var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
		if player != null and player.hud != null:
			player.hud.refresh()
	else:
		_message.text = "Re-casting needs the alloy in the pack, the era that smelts it, and the ingot in hand."
	refresh()
	return ok


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
		_message.text = "Stored %s: %d%% (was %d%%). Check the item for its expressed value and any held-back potential." % [
			p["property_display_name"], int(result["rolled_value"]), int(result["previous_value"])]
	else:
		match result.get("reason", ""):
			"no_armour": _message.text = "Wear your armour first."
			"station_unavailable": _message.text = "Ember-tempering needs the Improved Forge."
			"missing_catalyst": _message.text = "Refine a Stable Ember Catalyst at the Improved Forge."
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
	if catalogue != null:
		catalogue.visible = _mode == "crafting"
		_scroll.visible = _mode != "crafting"
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()
	match _mode:
		"crafting":
			_title.text = "Field Crafting" if _station == null else String(sim.station(_station.current_station_id(sim)).get("display_name", "Workshop"))
			catalogue.refresh()
			_layout_catalogue()
		"order": _render_order()
		"custom": _render_custom()
	_fit_height.call_deferred()


## The scroll area grows with its rows up to a fraction of the window, so
## short lists sit tight and long forges scroll. Rows wrap their text, so
## their real height is only known once layout has run: measure after two
## frames rather than trusting the pre-layout minimum size.
func _layout_catalogue() -> void:
	if _mode != "crafting": return
	var viewport_size := get_viewport().get_visible_rect().size
	_root.custom_minimum_size = Vector2(minf(1120, viewport_size.x - 40), 0)
	catalogue.custom_minimum_size.y = clampf(viewport_size.y - 180, 420, 680)
	_root.size = Vector2.ZERO
	_settle_catalogue.call_deferred()


func _settle_catalogue() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _mode != "crafting": return
	# Wrapped labels first measure against their previous width. Shrink only
	# after the new catalogue columns have received their actual widths.
	_root.size = _root.get_combined_minimum_size()
	_centre_catalogue()


func _centre_catalogue() -> void:
	if _root != null:
		_root.position = (get_viewport().get_visible_rect().size - _root.size) * 0.5


func _fit_height() -> void:
	if _mode == "crafting": return
	_root.custom_minimum_size.x = 780
	if _scroll == null or not is_inside_tree():
		return
	var tree := get_tree()
	await tree.process_frame
	await tree.process_frame
	if _scroll == null or not is_inside_tree():
		return
	var cap := get_viewport().get_visible_rect().size.y * MAX_HEIGHT_FRACTION
	_scroll.custom_minimum_size.y = clampf(_body.size.y + 4.0, 40.0, cap)
	_root.size = Vector2.ZERO
	_centre_catalogue.call_deferred()


func _render_custom() -> void:
	_title.text = _custom_title
	for row in _custom_rows:
		_add_row(row.get("text", ""), row.get("button", ""), row.get("enabled", true), row.get("callback", Callable()))


## One card: text (bbcode allowed) and, optionally, a button.
func _add_row(text: String, button_text: String = "", enabled := false, on_pressed: Callable = Callable()) -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.card(button_text != "" and enabled))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	if button_text != "":
		var button := Button.new()
		button.text = button_text
		button.disabled = not enabled
		button.custom_minimum_size = Vector2(110, 0)
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		if on_pressed.is_valid():
			button.pressed.connect(on_pressed)
		row.add_child(button)
	_body.add_child(card)


func transfer_catalyst(process_id: StringName, target_index: int) -> Dictionary:
	var result: Dictionary = sim.transfer_with_catalyst(process_id, target_index)
	if result["applied"]:
		_message.text = "The catalyst holds the metal's memory as it moves: %d modifiers carried across. Wear the new base from your pack." % int(result["moved"])
	else:
		match result.get("reason", ""):
			"no_source": _message.text = "Wear the item whose modifiers you want to move."
			"missing_catalyst": _message.text = "You need a Preserving Catalyst."
			"skill_too_low": _message.text = "The transfer is beyond your skill."
			"station_unavailable": _message.text = "This forge cannot hold a transfer."
			_: _message.text = "The transfer will not take."
	refresh()
	return result


func _render_order() -> void:
	var o: Dictionary = sim.order(_order_id)
	_title.text = o.get("display_name", "Order")
	if o.get("fulfilled", false):
		_add_row("Complete. The old mine is reinforced.")
		return
	_add_row("Deliver: %s" % cost_bbcode(o["required_outputs"], sim))
	_add_row("Reward: %s" % amounts_text(o["rewards"]))
	var can_deliver := true
	for id in o["required_outputs"]:
		if sim.material_count(id) < o["required_outputs"][id]:
			can_deliver = false
	_add_row("The mine crew will haul the fittings away and shore up the tunnels.", "Deliver", can_deliver, deliver)
