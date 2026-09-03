class_name FoundryPanel
extends CanvasLayer
## The Foundry (D-019): the plate of ingots. Opened at a built forge. The
## plate is a grid of cells; the tray lists the ingots you own but have not
## placed; the effects list is what the arrangement is doing right now.
## Click a tray ingot to pick it up, an empty cell to set it, a filled
## cell to lift it (re-forging, paid in metal). Every button calls one sim
## method; nothing here computes a rule.

signal closed

const CELL_SIZE := Vector2(104, 76)

var sim: WroughtwildSim
var player: WroughtwildPlayer

var _root: PanelContainer
var _title: Label
var _grid: GridContainer
var _tray: VBoxContainer
var _effects: VBoxContainer
var _message: Label
var _selected: StringName = &""
## Test surface: what the last refresh showed.
var cell_count := 0
var tray_count := 0
var effect_count := 0


func _ready() -> void:
	layer = 10
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.custom_minimum_size = Vector2(900, 0)
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
	_title = Label.new()
	_title.text = "The Foundry"
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var close := Button.new()
	close.text = "Close  (Esc)"
	close.pressed.connect(close_panel)
	header.add_child(close)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	column.add_child(body)

	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 6)
	body.add_child(left)
	left.add_child(_section("The plate"))
	_grid = GridContainer.new()
	_grid.add_theme_constant_override("h_separation", 6)
	_grid.add_theme_constant_override("v_separation", 6)
	left.add_child(_grid)
	var how := Label.new()
	how.text = "Beside: a pair makes its mechanic.  In a line of three: the verb again.\nLift an ingot to re-forge; it costs a little metal."
	how.modulate = UiTheme.MUTED
	left.add_child(how)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	right.add_child(_section("Ingots in hand"))
	_tray = VBoxContainer.new()
	right.add_child(_tray)
	right.add_child(_section("What the plate does"))
	_effects = VBoxContainer.new()
	right.add_child(_effects)

	_message = Label.new()
	_message.modulate = UiTheme.MUTED
	column.add_child(_message)


func _section(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 16)
	return label


func is_open() -> bool:
	return _root != null and _root.visible


func open_panel() -> void:
	_root.visible = true
	_message.text = ""
	refresh()


func close_panel() -> void:
	if not is_open():
		return
	_root.visible = false
	closed.emit()


func message() -> String:
	return _message.text


func refresh() -> void:
	if sim == null or not is_open():
		return
	var view: Dictionary = sim.foundry()
	var rows: int = view["rows"]
	var cols: int = view["cols"]
	_title.text = "The Foundry  —  a %d×%d plate (era %d)" % [rows, cols, view["era"]]

	for child in _grid.get_children():
		child.queue_free()
	_grid.columns = cols
	var placed := {}
	for p in view["plate"]:
		placed[Vector2i(p["row"], p["col"])] = String(p["ingot"])
	cell_count = 0
	for r in rows:
		for c in cols:
			var cell := Button.new()
			cell.custom_minimum_size = CELL_SIZE
			var key := Vector2i(r, c)
			if placed.has(key):
				var info: Dictionary = sim.foundry_ingot(placed[key])
				cell.text = info.get("display_name", placed[key]).replace(" Ingot", "")
				cell.tooltip_text = info.get("sentence", "")
			else:
				cell.text = "·"
				cell.modulate = Color(1, 1, 1, 0.6)
			cell.pressed.connect(_on_cell.bind(r, c))
			_grid.add_child(cell)
			cell_count += 1

	for child in _tray.get_children():
		child.queue_free()
	tray_count = 0
	var unplaced: Dictionary = view["unplaced"]
	var any := false
	for id in sim.foundry_ingot_ids():
		var count: int = unplaced.get(id, 0)
		if count <= 0:
			continue
		any = true
		var info: Dictionary = sim.foundry_ingot(id)
		var button := Button.new()
		button.text = "%s  ×%d   %s" % [info["display_name"], count, info["sentence"]]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if _selected == StringName(id):
			button.modulate = UiTheme.GRASS_LIGHT
		button.pressed.connect(_on_tray.bind(id))
		_tray.add_child(button)
		tray_count += 1
	if not any:
		var none := Label.new()
		none.text = "None in hand. Milestones forge them: first kills, first smelts, the mine, the Tyrant."
		none.modulate = UiTheme.MUTED
		_tray.add_child(none)

	for child in _effects.get_children():
		child.queue_free()
	effect_count = 0
	for effect in sim.foundry_effects():
		var line := Label.new()
		var kind: String = effect["kind"]
		var prefix := "pair" if kind == "pair" else ("line" if kind == "line" else "ingot")
		line.text = "%s  ·  %s  —  %s" % [prefix, effect["label"], effect["sentence"]]
		if kind != "ingot":
			line.modulate = UiTheme.SUN_WARM
		_effects.add_child(line)
		effect_count += 1
	if effect_count == 0:
		var none := Label.new()
		none.text = "The plate is bare."
		none.modulate = UiTheme.MUTED
		_effects.add_child(none)


func _on_tray(id: String) -> void:
	_selected = StringName(id) if _selected != StringName(id) else &""
	_message.text = "Pick a cell for the %s." % sim.foundry_ingot(id).get("display_name", id) if _selected != &"" else ""
	refresh()


func _on_cell(row: int, col: int) -> void:
	var view: Dictionary = sim.foundry()
	for p in view["plate"]:
		if int(p["row"]) == row and int(p["col"]) == col:
			if sim.foundry_remove(row, col):
				_message.text = "Lifted. The metal is spent."
				_after_change()
			else:
				_message.text = "Re-forging needs %s." % _cost_text(view.get("reforge_cost", {}))
				refresh()
			return
	if _selected == &"":
		_message.text = "Pick an ingot from the tray first."
		refresh()
		return
	if sim.foundry_place(row, col, String(_selected)):
		if int(view["unplaced"].get(String(_selected), 0)) <= 1:
			_selected = &""
		_message.text = ""
		_after_change()
	else:
		_message.text = "That ingot cannot go there."
		refresh()


func _cost_text(cost: Dictionary) -> String:
	var parts := PackedStringArray()
	for item in cost:
		parts.append("%d %s" % [int(cost[item]), Hud.pretty(item)])
	return ", ".join(parts) if not parts.is_empty() else "nothing"


## The plate changed: stats and skill numbers may have moved.
func _after_change() -> void:
	if player != null:
		player.combat.refresh_stats()
		if player.hud != null:
			player.hud.refresh()
	refresh()


## Test surface: place through the panel.
func set_selected(id: StringName) -> void:
	_selected = id


func press_cell(row: int, col: int) -> void:
	_on_cell(row, col)
