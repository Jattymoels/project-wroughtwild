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
var _custom_context := ""
var _keyed_context := ""
var _custom_cards: Dictionary = {}
var _layout_revision := 0
## A working feeder refreshes its status while this panel stays open.
## Keep an explanation readable across that refresh; never persist it.
var _expanded_details: Dictionary = {}


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
## callback (Callable), details (optional explanatory text)}. Used for trial doors and offers.
## A live page may opt in with a machine/page context and a unique stable `id`
## on every row. IDs name actions, not changing captions or quantities.
func open_custom(title: String, rows: Array, message_text: String = "", context_id: String = "") -> void:
	var same_page := _mode == "custom" and _custom_context == context_id and (not context_id.is_empty() or _custom_title == title)
	if not same_page: _expanded_details.clear()
	_mode = "custom"
	_custom_title = title
	_custom_context = context_id
	_custom_rows = rows
	_message.text = message_text
	_root.visible = true
	refresh()


func close_panel() -> void:
	if not is_open():
		return
	_root.visible = false
	_mode = ""
	_layout_revision += 1
	_invalidate_custom_cards()
	_custom_context = ""
	_expanded_details.clear()
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
		_craft_feedback(recipe, aim_kind, quality)
		var note := "Crafted %s" % recipe.get("display_name", recipe_id)
		if quantity > 1: note += " ×%d" % quantity
		if int(result.xp_granted) > 0: note += " (+%d xp%s)" % [result.xp_granted, ", repetition reduced" if float(result.xp_multiplier) < 1.0 else ""]
		if aim_kind != "": note += " · " + Hud.pretty(aim_kind)
		_message.text = note + "."
		for output_id in recipe.get("outputs", {}):
			if sim.kit_item_ids().has(String(output_id)):
				_message.text += InputPrompts.text(" Kit in pack: close → {toggle_build_mode} → {cycle_shape} → choose the kit → Use selection → {primary_action} place → {interact} use.")
				break

		if first_dressed:
			var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
			if player != null and player.hud != null:
				player.hud.notify("First dressed stone: ready for building and forge kits.")
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


## One response to one successful native transaction, including a batch.
## Panel refresh, replayed save state and known remote station recipes never
## pretend an idle station has worked. Field work stays at the player's hands.
func _craft_feedback(recipe: Dictionary, aim_kind: String, quality: int) -> void:
	if _mode != "crafting" or not is_open(): return
	var required_station := String(recipe.get("station", ""))
	if quality > 1 or not aim_kind.is_empty():
		var preview: Dictionary = sim.craft_preview(String(recipe.id), aim_kind, quality)
		var grades: Array = preview.get("grades", [])
		var process_grade := maxi(quality, int(preview.get("potency", 1)))
		if not String(preview.get("base_id", "")).is_empty() and process_grade > 1 and process_grade <= grades.size():
			required_station = String(grades[process_grade - 1].station)
	if _station != null:
		if is_instance_valid(_station) and _station.is_inside_tree() and not _station.is_queued_for_deletion() and required_station in ["", String(_station.station_id), String(_station.current_station_id(sim))]:
			_station.craft_completed(sim)
		return
	if required_station != "": return
	var player := get_parent() as WroughtwildPlayer
	if player == null: return
	var scene := player.world_root()
	if scene != null:
		InteractionSound.play(scene, player.global_position, InteractionSound.craft_cue(""))


## Re-casts one ingot in hand in a wider metal (slice 10) through the sim.
func recast(ingot_id: String, metal_id: String) -> bool:
	var ok: bool = sim.foundry_recast(ingot_id, metal_id)
	if ok:
		var info: Dictionary = sim.foundry_ingot(ingot_id)
		_message.text = InputPrompts.formatted("The %s is re-cast in %s. {toggle_foundry} opens the plate.", [info.get("display_name", ingot_id), metal_id])
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
		_message.text = "Order delivered. The mine is reinforced and your reward is in the pack."
	elif result.get("already_fulfilled", false):
		_message.text = "This order is already complete."
	else:
		_message.text = "You have not made enough yet."
	refresh()
	return result


# --- rendering ---------------------------------------------------------------

func refresh() -> void:
	_layout_revision += 1
	if catalogue != null:
		catalogue.visible = _mode == "crafting"
		_scroll.visible = _mode != "crafting"
	var keyed := _mode == "custom" and _custom_rows_are_keyed()
	if not keyed or _keyed_context != _custom_context:
		_clear_rows()
		if keyed: _scroll.scroll_vertical = 0
	if keyed:
		_keyed_context = _custom_context
		_render_keyed_custom()
		_fit_height.call_deferred()
		return
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
	var revision := _layout_revision
	await tree.process_frame
	await tree.process_frame
	if _scroll == null or not is_inside_tree() or not is_open() or _mode == "crafting" or revision != _layout_revision:
		return
	var cap := get_viewport().get_visible_rect().size.y * MAX_HEIGHT_FRACTION
	_scroll.custom_minimum_size.y = clampf(_body.size.y + 4.0, 40.0, cap)
	_root.size = Vector2.ZERO
	_centre_catalogue.call_deferred()


func _render_custom() -> void:
	_title.text = _custom_title
	for row in _custom_rows:
		_add_row(row.get("text", ""), row.get("button", ""), row.get("enabled", true), row.get("callback", Callable()), row.get("details", ""))


func _custom_rows_are_keyed() -> bool:
	if _custom_context.is_empty(): return false
	var seen := {}
	for row: Dictionary in _custom_rows:
		var id := String(row.get("id", ""))
		if id.is_empty() or seen.has(id): return false
		seen[id] = true
	return true


func _invalidate_custom_cards() -> void:
	for card: PanelContainer in _custom_cards.values():
		if not is_instance_valid(card): continue
		var view: Dictionary = card.get_meta("custom_view")
		view.callback = Callable()
		(view.button as Button).disabled = true
	_custom_cards.clear()
	_keyed_context = ""


func _clear_rows() -> void:
	_invalidate_custom_cards()
	for child in _body.get_children():
		_body.remove_child(child)
		child.queue_free()


func _render_keyed_custom() -> void:
	_title.text = _custom_title
	var live := {}
	for index in _custom_rows.size():
		var row: Dictionary = _custom_rows[index]
		var id := String(row.id)
		live[id] = true
		var card: PanelContainer = _custom_cards.get(id)
		if card == null:
			card = _new_keyed_card(id)
			_custom_cards[id] = card
		_update_keyed_card(card, row)
		_body.move_child(card, index)
	for id in _custom_cards.keys():
		if live.has(id): continue
		var card: PanelContainer = _custom_cards[id]
		var view: Dictionary = card.get_meta("custom_view")
		view.callback = Callable()
		(view.button as Button).disabled = true
		_body.remove_child(card)
		card.queue_free()
		_custom_cards.erase(id)
		_expanded_details.erase(id)


func _new_keyed_card(id: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(label)
	var toggle := Button.new()
	toggle.toggle_mode = true
	toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	words.add_child(toggle)
	var more := RichTextLabel.new()
	more.bbcode_enabled = true
	more.fit_content = true
	more.scroll_active = false
	more.modulate = UiTheme.MUTED
	words.add_child(more)
	var button := Button.new()
	button.custom_minimum_size = Vector2(110, 0)
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(button)
	card.set_meta("custom_view", {"id":id, "context":_custom_context, "label":label,
		"toggle":toggle, "more":more, "button":button, "callback":Callable()})
	# One connection reads the current action. Refreshing never stacks captured
	# transactions; removed pages and disabled actions are inert even this frame.
	button.pressed.connect(func() -> void:
		if not _keyed_card_current(card) or button.disabled or not button.visible: return
		var callback: Callable = card.get_meta("custom_view").callback
		if callback.is_valid(): callback.call())
	toggle.toggled.connect(func(open: bool) -> void:
		if not _keyed_card_current(card): return
		_expanded_details[id] = open
		more.visible = open and not more.text.is_empty()
		toggle.text = "Less detail" if open else "Details"
		_fit_height.call_deferred())
	_body.add_child(card)
	return card


func _keyed_card_current(card: PanelContainer) -> bool:
	if not is_open() or _mode != "custom" or not is_instance_valid(card) or card.get_parent() != _body: return false
	var view: Dictionary = card.get_meta("custom_view")
	return view.context == _custom_context and _custom_cards.get(view.id) == card


func _update_keyed_card(card: PanelContainer, row: Dictionary) -> void:
	var view: Dictionary = card.get_meta("custom_view")
	(view.label as RichTextLabel).text = String(row.get("text", ""))
	var button: Button = view.button
	button.text = String(row.get("button", ""))
	button.visible = not button.text.is_empty()
	button.disabled = not bool(row.get("enabled", true))
	view.callback = row.get("callback", Callable())
	card.add_theme_stylebox_override("panel", UiTheme.card(button.visible and not button.disabled))
	var explanation := String(row.get("details", ""))
	var expanded := bool(_expanded_details.get(view.id, false))
	var toggle: Button = view.toggle
	toggle.visible = not explanation.is_empty()
	toggle.set_pressed_no_signal(expanded)
	toggle.text = "Less detail" if expanded else "Details"
	var more: RichTextLabel = view.more
	more.text = explanation
	more.visible = expanded and not explanation.is_empty()


## One card: text (bbcode allowed) and, optionally, a button.
func _add_row(text: String, button_text: String = "", enabled := false, on_pressed: Callable = Callable(), explanation: String = "") -> void:
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiTheme.card(button_text != "" and enabled))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	card.add_child(row)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(words)
	var label := RichTextLabel.new()
	label.bbcode_enabled = true
	label.fit_content = true
	label.scroll_active = false
	label.text = text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_child(label)
	if not explanation.is_empty():
		var detail_key := button_text + "\n" + explanation
		var expanded: bool = _expanded_details.get(detail_key,false)
		var toggle := Button.new()
		toggle.text = "Less detail" if expanded else "Details"
		toggle.toggle_mode = true
		toggle.button_pressed = expanded
		toggle.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		words.add_child(toggle)
		var more := RichTextLabel.new()
		more.bbcode_enabled = true
		more.fit_content = true
		more.scroll_active = false
		more.text = explanation
		more.modulate = UiTheme.MUTED
		more.visible = expanded
		words.add_child(more)
		toggle.toggled.connect(func(open: bool) -> void:
			_expanded_details[detail_key] = open
			more.visible = open
			toggle.text = "Less detail" if open else "Details"
			_fit_height.call_deferred())
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
