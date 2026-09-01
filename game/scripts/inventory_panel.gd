class_name InventoryPanel
extends CanvasLayer
## The pack screen (I): materials and currency as tiles, what is worn per
## slot, derived vitals and the active modifier set. It shows sim views only
## and each button calls one sim method (docs/systems/interface.md). Wave 2
## grows the "Wearing" column to weapon and charm slots and item cards.

signal closed

const COLUMNS := 5
const TILE_SIZE := Vector2(122, 66)
## Slice slots; items-and-modifiers.md proposes weapon and charm next.
const SLOTS := [&"chest"]
const WEARABLE := {&"chest": &"iron_chest_armour"}

var sim: WroughtwildSim

var _root: PanelContainer
var _tiles: GridContainer
var _empty: Label
var _worn: VBoxContainer
var _vitals: Label
var _mods: VBoxContainer
var _message: Label
## Test surface: tiles shown by the last refresh.
var tile_count := 0


func _ready() -> void:
	layer = 10
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.custom_minimum_size = Vector2(960, 0)
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

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	column.add_child(body)

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

	var right := VBoxContainer.new()
	right.custom_minimum_size = Vector2(300, 0)
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

func wear(base_id: StringName) -> bool:
	var worn: bool = sim.equip_from_inventory(base_id)
	_message.text = "You strap on the armour." if worn else "You have none to wear."
	refresh()
	return worn


func set_mod_active(mod_id: StringName, active: bool) -> void:
	sim.set_skill_mod_active(String(mod_id), active)
	refresh()


# --- rendering ---------------------------------------------------------------

func refresh() -> void:
	if sim == null:
		return
	_refresh_tiles()
	_refresh_worn()
	var ds: Dictionary = sim.derived_stats()
	_vitals.text = "Life %d  ·  armour %d  ·  fire resistance %d%%  ·  area +%d%%" % [
		int(ds.get("max_life", 0.0)), int(ds.get("armour", 0.0)),
		int(ds.get("fire_resistance_percent", 0.0)), int(ds.get("area_bonus", 0.0) * 100.0)]
	_refresh_mods()


func _clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


func _refresh_tiles() -> void:
	_clear(_tiles)
	tile_count = 0
	var held: Dictionary = sim.inventory()
	for id in held:
		if held[id] > 0:
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


func _refresh_worn() -> void:
	_clear(_worn)
	var equipment: Dictionary = sim.equipment()
	for slot in SLOTS:
		var item: Dictionary = equipment.get(String(slot), {})
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", UiTheme.card(not item.is_empty()))
		var column := VBoxContainer.new()
		card.add_child(column)
		var line := Label.new()
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if item.is_empty():
			line.text = "%s  —  nothing worn" % Hud.pretty(String(slot)).capitalize()
			line.modulate = UiTheme.MUTED
		else:
			line.text = "%s  —  %s\narmour %d  ·  fire resistance %d%%  ·  life +%d" % [
				Hud.pretty(String(slot)).capitalize(), item.get("display_name", "?"),
				int(item.get("armour", 0.0)), int(item.get("fire_resistance", 0.0)), int(item.get("max_life", 0.0))]
			for rolled in item.get("rolled", []):
				line.text += "\n  %s  tier %d  %d" % [Hud.pretty(String(rolled["property"])), int(rolled["tier"]), int(rolled["value"])]
		column.add_child(line)
		var base_id: StringName = WEARABLE.get(slot, &"")
		if base_id != &"" and sim.material_count(String(base_id)) > 0:
			var wear_button := Button.new()
			wear_button.text = "Wear %s  (%d in pack)" % [Hud.pretty(String(base_id)), sim.material_count(String(base_id))]
			wear_button.pressed.connect(wear.bind(base_id))
			column.add_child(wear_button)
		_worn.add_child(card)


## 1.0 reads as 1; 0.5 stays 0.5.
static func _number(value: Variant) -> String:
	if value is float and is_equal_approx(value, roundf(value)):
		return str(int(value))
	return str(value)


func _refresh_mods() -> void:
	_clear(_mods)
	var ids := sim.skill_mod_ids()
	if ids.is_empty():
		var none := Label.new()
		none.text = "None"
		none.modulate = UiTheme.MUTED
		_mods.add_child(none)
		return
	for id in ids:
		var mod: Dictionary = sim.skill_mod(id)
		var effects := PackedStringArray()
		var effect: Dictionary = mod.get("effect", {})
		for key in effect:
			effects.append("%s %s" % [Hud.pretty(String(key)), _number(effect[key])])
		var active: bool = mod.get("active", false)
		var toggle := Button.new()
		toggle.toggle_mode = true
		toggle.button_pressed = active
		toggle.alignment = HORIZONTAL_ALIGNMENT_LEFT
		toggle.text = "%s   %s  —  %s  (%s)" % ["ON " if active else "off", mod.get("display_name", id),
			" · ".join(effects), " ".join(mod.get("applies_to_tags", PackedStringArray()))]
		toggle.modulate = Color(1, 1, 1, 1.0) if active else Color(1, 1, 1, 0.7)
		toggle.toggled.connect(func(on: bool) -> void: set_mod_active(StringName(id), on))
		_mods.add_child(toggle)
