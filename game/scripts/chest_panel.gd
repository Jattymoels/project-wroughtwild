class_name ChestPanel
extends CanvasLayer
## A chest's store (Wave 6 slice 6; the owner, 4 Sep 2026: "would
## definitely need chests/storage solutions"). E at a placed chest opens
## it: one row per family in the pack or the chest, the counts each side,
## and buttons that move a stack across. Every button calls one sim
## method; the sim decides the pack's cap and the chest's room.

signal closed

var sim: WroughtwildSim
var player: WroughtwildPlayer

var _root: PanelContainer
var _title: Label
var _rows: VBoxContainer
var _empty: Label
var _message: Label
## The chest open now: its store key in the sim, and the piece in the world.
var store_key := ""
var chest: PlacedBlock
## Test surface.
var row_count := 0


func _ready() -> void:
	layer = 11
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.custom_minimum_size = Vector2(820, 0)
	_root.visible = false
	add_child(_root)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	_root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var header := HBoxContainer.new()
	column.add_child(header)
	_title = Label.new()
	_title.text = "Chest"
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close := Button.new()
	close.text = "Close  (Esc)"
	close.pressed.connect(close_panel)
	header.add_child(close)

	var how := Label.new()
	how.text = "What you haul from the ground stops at your pack's cap per family; the chest holds a bounded store of anything together. Fill in the field, empty at home."
	how.modulate = UiTheme.MUTED
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size = Vector2(780, 0)
	column.add_child(how)

	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 4)
	column.add_child(_rows)
	_empty = Label.new()
	_empty.text = "Nothing in the pack and nothing in the chest."
	_empty.modulate = UiTheme.MUTED
	column.add_child(_empty)

	_message = Label.new()
	_message.modulate = UiTheme.MUTED
	column.add_child(_message)


func is_open() -> bool:
	return _root != null and _root.visible


## Opens on a placed chest: its store key is the piece's element.
func open_at(block: PlacedBlock) -> void:
	if block == null or not block.is_chest():
		return
	chest = block
	store_key = block.store_key()
	_root.visible = true
	_message.text = ""
	refresh()


func close_panel() -> void:
	if not is_open():
		return
	_root.visible = false
	chest = null
	store_key = ""
	closed.emit()


func message() -> String:
	return _message.text


## Pack to chest. Returns what moved.
func store(family: StringName, count: int) -> int:
	var moved: int = sim.store_deposit(store_key, family, count)
	if moved > 0:
		_message.text = "Stored %d %s." % [moved, Hud.pretty(String(family))]
	elif sim.store_room(store_key) <= 0:
		_message.text = "The chest is full."
	else:
		_message.text = "Nothing to store."
	refresh()
	return moved


## Chest to pack. Returns what moved.
func take(family: StringName, count: int) -> int:
	var moved: int = sim.store_withdraw(store_key, family, count)
	if moved > 0:
		_message.text = "Took %d %s." % [moved, Hud.pretty(String(family))]
	elif sim.carry_room(family) <= 0:
		_message.text = "Your pack can carry no more %s." % Hud.pretty(String(family))
	else:
		_message.text = "Nothing to take."
	refresh()
	return moved


func refresh() -> void:
	if sim == null or not is_open():
		return
	var rules: Dictionary = sim.hauling_rules()
	_title.text = "Chest  ·  %d / %d" % [sim.store_units(store_key), int(rules.get("chest_units", 0))]
	for child in _rows.get_children():
		_rows.remove_child(child)
		child.free()
	row_count = 0
	var families := {}
	var bases := sim.item_base_ids()
	var held: Dictionary = sim.inventory()
	for id in held:
		if held[id] > 0 and not bases.has(String(id)):
			families[String(id)] = true
	var contents: Dictionary = sim.store_contents(store_key)
	for id in contents:
		families[String(id)] = true
	var ids := families.keys()
	ids.sort()
	for id in ids:
		_add_row(String(id), int(held.get(id, 0)), int(contents.get(id, 0)))
	_empty.visible = row_count == 0


func _add_row(id: String, in_pack: int, in_chest: int) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	var swatch := ColorRect.new()
	swatch.color = UiTheme.family_colour(id)
	swatch.custom_minimum_size = Vector2(6, 22)
	row.add_child(swatch)
	var name := Label.new()
	name.text = Hud.pretty(id)
	name.custom_minimum_size = Vector2(170, 0)
	row.add_child(name)
	var cap: int = sim.carry_cap(id)
	var pack := Label.new()
	pack.text = "pack %d / %d" % [in_pack, cap] if cap > 0 else "pack %d" % in_pack
	pack.custom_minimum_size = Vector2(130, 0)
	pack.modulate = UiTheme.MUTED
	row.add_child(pack)
	var store_all := Button.new()
	store_all.text = "Store all  »"
	store_all.disabled = in_pack <= 0
	store_all.pressed.connect(store.bind(StringName(id), in_pack))
	row.add_child(store_all)
	var store_ten := Button.new()
	store_ten.text = "10  »"
	store_ten.disabled = in_pack <= 0
	store_ten.pressed.connect(store.bind(StringName(id), 10))
	row.add_child(store_ten)
	var chest_label := Label.new()
	chest_label.text = "chest %d" % in_chest
	chest_label.custom_minimum_size = Vector2(90, 0)
	chest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	row.add_child(chest_label)
	var take_ten := Button.new()
	take_ten.text = "«  10"
	take_ten.disabled = in_chest <= 0
	take_ten.pressed.connect(take.bind(StringName(id), 10))
	row.add_child(take_ten)
	var take_all := Button.new()
	take_all.text = "«  Take all"
	take_all.disabled = in_chest <= 0
	take_all.pressed.connect(take.bind(StringName(id), in_chest))
	row.add_child(take_all)
	_rows.add_child(row)
	row_count += 1
