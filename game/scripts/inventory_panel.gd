class_name InventoryPanel
extends CanvasLayer
## The pack screen (I): materials and currency as tiles, gear in the pack as
## item cards, what is worn per slot, derived vitals and the active
## modifier set. It shows sim views only and each button calls one sim
## method (docs/systems/interface.md). Item cards read rarity, stats and
## per-modifier sentences straight from the sim (D-014).

signal closed

const COLUMNS := 5
const TILE_SIZE := Vector2(122, 66)
## The body scrolls once it outgrows this share of the window.
const MAX_HEIGHT_FRACTION := 0.8

var sim: WroughtwildSim
## Set by the player: bar assignments route through PlayerCombat so the
## action bar hears loadout_changed. The panel works sim-only without it.
var combat: PlayerCombat

var _root: PanelContainer
var _scroll: ScrollContainer
var _tiles: GridContainer
var _empty: Label
var _gear: VBoxContainer
var _skills: VBoxContainer
var _worn: VBoxContainer
var _vitals: Label
var _mods: VBoxContainer
var _debug: VBoxContainer
var _message: Label
## Test surface: tiles, gear cards and skill rows shown by the last refresh.
var tile_count := 0
var gear_count := 0
var skill_row_count := 0


func _ready() -> void:
	layer = 10
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.custom_minimum_size = Vector2(1040, 0)
	_root.visible = false
	add_child(_root)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 16)
	_root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	var title := Label.new()
	title.text = "Pack"
	title.add_theme_font_size_override("font_size", 22)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	var close := Button.new()
	close.text = "Close  (I / Esc)"
	close.pressed.connect(close_panel)
	header.add_child(close)

	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, 120)
	column.add_child(_scroll)
	var body := HBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 20)
	_scroll.add_child(body)

	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	left.add_child(_section("Carried"))
	_tiles = GridContainer.new()
	_tiles.columns = COLUMNS
	_tiles.add_theme_constant_override("h_separation", 6)
	_tiles.add_theme_constant_override("v_separation", 6)
	left.add_child(_tiles)
	_empty = Label.new()
	_empty.text = "Nothing carried yet. Harvest trees and boulders with E."
	_empty.modulate = UiTheme.MUTED
	left.add_child(_empty)
	left.add_child(_section("Gear in pack"))
	_gear = VBoxContainer.new()
	_gear.add_theme_constant_override("separation", 6)
	left.add_child(_gear)
	left.add_child(_section("Skills — press 1–4 to slot (Shift dashes)"))
	_skills = VBoxContainer.new()
	_skills.add_theme_constant_override("separation", 6)
	left.add_child(_skills)

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(360, 0)
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	right.add_child(_section("Wearing"))
	_worn = VBoxContainer.new()
	_worn.add_theme_constant_override("separation", 6)
	right.add_child(_worn)
	right.add_child(_section("Vitals"))
	_vitals = Label.new()
	_vitals.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	right.add_child(_vitals)
	right.add_child(_section("Active modifiers"))
	_mods = VBoxContainer.new()
	right.add_child(_mods)
	right.add_child(_section("Debug: force a modifier (F1–F3)"))
	_debug = VBoxContainer.new()
	right.add_child(_debug)

	_message = Label.new()
	_message.modulate = UiTheme.EMBER
	column.add_child(_message)


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	label.modulate = UiTheme.MUTED
	return label


func is_open() -> bool:
	return _root != null and _root.visible


func open_panel() -> void:
	_message.text = ""
	_root.visible = true
	refresh()


func close_panel() -> void:
	if not is_open():
		return
	_root.visible = false
	closed.emit()


func toggle() -> void:
	if is_open():
		close_panel()
	else:
		open_panel()


func message() -> String:
	return _message.text


# --- actions (also the test surface) ------------------------------------------

## Wear a plain (crafted, unrolled) item straight from its stack.
func wear(base_id: StringName) -> bool:
	var worn: bool = sim.equip_from_inventory(base_id)
	_message.text = "You strap it on." if worn else "You have none to wear."
	refresh()
	return worn


## Wear a rolled item from the gear list; whatever was worn goes back to
## the pack with its modifiers intact (D-014 rule 7).
func wear_pack_item(index: int) -> bool:
	var worn: bool = sim.equip_pack_item(index)
	_message.text = "You strap it on." if worn else "That is not in your pack."
	refresh()
	return worn


func take_off(slot: StringName) -> bool:
	var removed: bool = sim.unequip(slot)
	_message.text = "Back in the pack." if removed else "Nothing worn there."
	refresh()
	return removed


func set_mod_active(mod_id: StringName, active: bool) -> void:
	sim.set_skill_mod_active(String(mod_id), active)
	refresh()


## Put a known skill in a bar slot ("" clears it). Routes through
## PlayerCombat when wired so the action bar rebuilds.
func assign_skill(skill_id: String, slot: int) -> bool:
	var ok := combat.assign_bar_slot(slot, skill_id) if combat != null \
		else sim.set_bar_slot(slot, skill_id)
	if not ok:
		_message.text = "That cannot go there."
	elif skill_id == "":
		_message.text = "Slot %d cleared." % (slot + 1)
	else:
		_message.text = "Slot %d set." % (slot + 1)
	refresh()
	return ok


# --- rendering ---------------------------------------------------------------

func refresh() -> void:
	if sim == null:
		return
	_refresh_tiles()
	_refresh_gear()
	_refresh_skills()
	_refresh_worn()
	var ds: Dictionary = sim.derived_stats()
	_vitals.text = "Life %d  ·  armour %d  ·  fire resistance %d%%  ·  area +%d%%" % [
		int(ds.get("max_life", 0.0)), int(ds.get("armour", 0.0)),
		int(ds.get("fire_resistance_percent", 0.0)), int(ds.get("area_bonus", 0.0) * 100.0)]
	_refresh_mods()
	_fit_height.call_deferred()


## Grow with the content up to a share of the window, then scroll (the
## same rule as the work panel): measured after layout has run.
func _fit_height() -> void:
	if _scroll == null or not is_inside_tree():
		return
	var tree := get_tree()
	await tree.process_frame
	await tree.process_frame
	if _scroll == null or not is_inside_tree():
		return
	var cap := get_viewport().get_visible_rect().size.y * MAX_HEIGHT_FRACTION
	var body := _scroll.get_child(0) as Control
	_scroll.custom_minimum_size.y = clampf(body.size.y + 4.0, 120.0, cap)


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _refresh_tiles() -> void:
	_clear(_tiles)
	tile_count = 0
	var held: Dictionary = sim.inventory()
	var bases := sim.item_base_ids()
	for id in held:
		# Plain gear stacks are shown as gear cards, not material tiles.
		if held[id] > 0 and not bases.has(String(id)):
			_add_tile(String(id), int(held[id]))
	var coins: Dictionary = sim.currency()
	for id in coins:
		if coins[id] > 0:
			_add_tile(String(id), int(coins[id]))
	_empty.visible = tile_count == 0


func _add_tile(id: String, count: int) -> void:
	var tile := PanelContainer.new()
	tile.custom_minimum_size = TILE_SIZE
	tile.add_theme_stylebox_override("panel",
		UiTheme.flat(Color(UiTheme.ASH, 0.85), Color(UiTheme.family_colour(id), 0.8), 5))
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	tile.add_child(column)
	var swatch := ColorRect.new()
	swatch.color = UiTheme.family_colour(id)
	swatch.custom_minimum_size = Vector2(0, 4)
	column.add_child(swatch)
	var name := Label.new()
	name.text = Hud.pretty(id)
	name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name.add_theme_font_size_override("font_size", 12)
	name.modulate = UiTheme.MUTED
	column.add_child(name)
	var amount := Label.new()
	amount.text = str(count)
	amount.add_theme_font_size_override("font_size", 18)
	amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	column.add_child(amount)
	_tiles.add_child(tile)
	tile_count += 1


## An item card: rarity-coloured edge, name and slot, stats, one sentence
## per modifier, and one button.
func _item_card(item: Dictionary, button_text: String, on_pressed: Callable) -> PanelContainer:
	var rarity := String(item.get("rarity", "plain"))
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel",
		UiTheme.flat(Color(UiTheme.ASH, 0.75), Color(UiTheme.rarity_colour(rarity), 0.85), 5))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var column := VBoxContainer.new()
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 1)
	row.add_child(column)
	var title := Label.new()
	title.text = "%s %s  —  %s" % [rarity.capitalize(), item.get("display_name", "?"), Hud.pretty(String(item.get("slot", "")))]
	title.modulate = UiTheme.rarity_colour(rarity)
	column.add_child(title)
	var stats := PackedStringArray()
	if int(item.get("armour", 0.0)) > 0:
		stats.append("armour %d" % int(item["armour"]))
	if int(item.get("fire_resistance", 0.0)) > 0:
		stats.append("fire resistance %d%%" % int(item["fire_resistance"]))
	if int(item.get("max_life", 0.0)) > 0:
		stats.append("life +%d" % int(item["max_life"]))
	if float(item.get("area_size", 0.0)) > 0.0:
		stats.append("area +%d%%" % int(float(item["area_size"]) * 100.0))
	if not stats.is_empty():
		var stat_line := Label.new()
		stat_line.text = "  ".join(stats)
		stat_line.add_theme_font_size_override("font_size", 13)
		column.add_child(stat_line)
	for mod in item.get("mods", []):
		var line := Label.new()
		line.text = "  %s%s" % [mod["sentence"], "  (implicit)" if mod.get("source", "") == "implicit" else ""]
		line.add_theme_font_size_override("font_size", 13)
		line.modulate = UiTheme.PARCHMENT if mod.get("source", "") != "implicit" else UiTheme.MUTED
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		column.add_child(line)
	if button_text != "":
		var button := Button.new()
		button.text = button_text
		button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		button.pressed.connect(on_pressed)
		row.add_child(button)
	return card


func _refresh_gear() -> void:
	_clear(_gear)
	gear_count = 0
	for item in sim.pack_items():
		_gear.add_child(_item_card(item, "Wear", wear_pack_item.bind(int(item["index"]))))
		gear_count += 1
	# Plain crafted gear still sits in stacks; offer to wear one of each.
	for base_id in sim.item_base_ids():
		var held: int = sim.material_count(base_id)
		if held > 0:
			var base: Dictionary = sim.item_base(base_id)
			var plain := {"display_name": "%s ×%d" % [base.get("display_name", base_id), held], "slot": base.get("slot", ""),
				"rarity": "plain", "mods": base.get("implicit_modifiers", []),
				"armour": base.get("implicit_properties", {}).get("armour", 0.0)}
			_gear.add_child(_item_card(plain, "Wear", wear.bind(StringName(base_id))))
			gear_count += 1
	if gear_count == 0:
		var none := Label.new()
		none.text = "No gear carried. Craft a mace or armour at the forge; the trial's deeper rooms drop keen and wrought pieces."
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.modulate = UiTheme.MUTED
		_gear.add_child(none)


## One row per known skill (D-016: skills are found, not worn): name,
## delivery and tags, then a button per bar slot. The lit button is where
## the skill sits; pressing it again clears the slot, pressing another
## number moves the skill there.
func _refresh_skills() -> void:
	_clear(_skills)
	skill_row_count = 0
	var bar := sim.skill_bar()
	for id in sim.known_skill_ids():
		var view: Dictionary = sim.combat_skill(id)
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiTheme.card(false))
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		card.add_child(row)
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 1)
		row.add_child(column)
		var title := Label.new()
		title.text = view.get("display_name", id)
		column.add_child(title)
		var detail := Label.new()
		var tags: PackedStringArray = view.get("tags", PackedStringArray())
		detail.text = "%s  ·  %s" % [view.get("delivery", "?"), " / ".join(tags)]
		detail.add_theme_font_size_override("font_size", 12)
		detail.modulate = UiTheme.MUTED
		column.add_child(detail)
		var in_slot := bar.find(id)
		for slot in bar.size():
			var button := Button.new()
			button.text = str(slot + 1)
			button.toggle_mode = true
			button.button_pressed = slot == in_slot
			button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			button.pressed.connect(_on_skill_slot_button.bind(String(id), slot))
			row.add_child(button)
		_skills.add_child(card)
		skill_row_count += 1


func _on_skill_slot_button(skill_id: String, slot: int) -> void:
	var bar := sim.skill_bar()
	if slot < bar.size() and bar[slot] == skill_id:
		assign_skill("", slot)
	else:
		assign_skill(skill_id, slot)


func _refresh_worn() -> void:
	_clear(_worn)
	var equipment: Dictionary = sim.equipment()
	for slot in sim.slot_ids():
		if equipment.has(slot):
			_worn.add_child(_item_card(equipment[slot], "Take off", take_off.bind(StringName(slot))))
		else:
			var card := PanelContainer.new()
			card.add_theme_stylebox_override("panel", UiTheme.card(false))
			var line := Label.new()
			line.text = "%s  —  nothing worn" % Hud.pretty(String(slot)).capitalize()
			line.modulate = UiTheme.MUTED
			card.add_child(line)
			_worn.add_child(card)


func _refresh_mods() -> void:
	_clear(_mods)
	var active: Array = sim.active_modifiers()
	if active.is_empty():
		var none := Label.new()
		none.text = "None — your gear carries no modifiers yet."
		none.modulate = UiTheme.MUTED
		_mods.add_child(none)
	for mod in active:
		var line := Label.new()
		line.text = "%s   (%s)" % [mod["sentence"], Hud.pretty(String(mod.get("source", "")))]
		line.add_theme_font_size_override("font_size", 13)
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_mods.add_child(line)

	_clear(_debug)
	for id in sim.skill_mod_ids():
		var mod: Dictionary = sim.skill_mod(id)
		var is_on: bool = mod.get("active", false)
		var toggle := Button.new()
		toggle.toggle_mode = true
		toggle.button_pressed = is_on
		toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
		toggle.text = "%s   %s" % ["ON " if is_on else "off", mod.get("sentence", mod.get("display_name", id))]
		toggle.add_theme_font_size_override("font_size", 12)
		toggle.modulate = Color(1, 1, 1, 1.0) if is_on else Color(1, 1, 1, 0.6)
		toggle.toggled.connect(func(on: bool) -> void: set_mod_active(StringName(id), on))
		_debug.add_child(toggle)
