class_name FoundryPanel
extends CanvasLayer
## The Foundry (D-019, D-023): the plate of ingots, opened anywhere with F.
## The plate is a frame whose rows the era has forged; the unforged rows
## are drawn as its unworked edge. Sockets take a skill's tablet; the four
## cells beside a laid tablet are its supports and the diagonals its
## corners, and every reading is written on its cell. The tray lists the
## ingots you own but have not placed; the effects list is what the
## arrangement is doing right now. Click a tray ingot to pick it up, an
## empty cell to set it, a filled cell to lift it (re-forging, paid in
## metal). Every button calls one sim method; nothing here computes a rule.

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
## A skill picked from the tablet tray, to lay on the next empty cell.
var _selected_skill: StringName = &""
var _tablets: VBoxContainer
## The frame as the last refresh saw it (D-023).
var _sockets := {}
var _first_row := 0
var _last_row := 0
## Test surface: what the last refresh showed. cell_count is the forged
## cells; frame_cell_count every cell of the frame.
var cell_count := 0
var frame_cell_count := 0
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
	how.text = "A socket takes a skill's tablet; the four cells beside it are its supports, the diagonals its corners.\nBeside: a pair makes its mechanic. A matching ingot touching a support backs it: the support counts again.\nLift an ingot to re-forge; it costs a little metal. Tablets lift free."
	how.modulate = UiTheme.MUTED
	left.add_child(how)

	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	body.add_child(right)
	right.add_child(_section("Ingots in hand"))
	_tray = VBoxContainer.new()
	right.add_child(_tray)
	right.add_child(_section("Skills to lay"))
	_tablets = VBoxContainer.new()
	right.add_child(_tablets)
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
	_first_row = int(view.get("first_row", 0))
	_last_row = int(view.get("last_row", rows - 1))
	_sockets.clear()
	for s in view.get("sockets", []):
		_sockets[Vector2i(int(s[0]), int(s[1]))] = true
	_title.text = "The Foundry  —  era %d: rows %d to %d of the %d×%d frame are forged" % [view["era"], _first_row + 1, _last_row + 1, rows, cols]

	for child in _grid.get_children():
		child.queue_free()
	_grid.columns = cols
	var placed := {}
	var tablets := {}
	for p in view["plate"]:
		if String(p.get("skill", "")) != "":
			tablets[Vector2i(p["row"], p["col"])] = String(p["skill"])
		else:
			placed[Vector2i(p["row"], p["col"])] = String(p["ingot"])
	# Roles (D-023): a laid subject's four supports and four corners.
	var supports := {}
	var corners := {}
	for key in tablets:
		if not _sockets.has(key):
			continue
		var subject: String = sim.combat_skill(tablets[key]).get("display_name", tablets[key])
		for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
			var side: Vector2i = key + d
			if not supports.has(side):
				supports[side] = []
			supports[side].append(subject)
		for d in [Vector2i(1, 1), Vector2i(1, -1), Vector2i(-1, 1), Vector2i(-1, -1)]:
			var corner: Vector2i = key + d
			if not corners.has(corner):
				corners[corner] = []
			corners[corner].append(subject)
	# Every reading written on its cell: what a support or a backing does.
	var readings := {}
	var effects: Array = sim.foundry_effects()
	for effect in effects:
		var kind: String = effect["kind"]
		if kind != "support" and kind != "backing":
			continue
		var from := Vector2i(int(effect["cell_row"]), int(effect["cell_col"]))
		if not readings.has(from):
			readings[from] = []
		readings[from].append("%s: %s" % [effect["label"], effect["sentence"]])
	cell_count = 0
	frame_cell_count = 0
	for r in rows:
		for c in cols:
			var cell := Button.new()
			cell.custom_minimum_size = CELL_SIZE
			var key := Vector2i(r, c)
			frame_cell_count += 1
			if r < _first_row or r > _last_row:
				# The plate's unworked edge: the era has not forged this row.
				cell.text = "unforged"
				cell.disabled = true
				cell.modulate = Color(1, 1, 1, 0.35)
				cell.tooltip_text = "Unforged: the era has not worked this row yet."
				_grid.add_child(cell)
				continue
			cell_count += 1
			var lines := PackedStringArray()
			if tablets.has(key):
				var skill: Dictionary = sim.combat_skill(tablets[key])
				var subject: String = skill.get("display_name", tablets[key])
				cell.text = "[ %s ]" % subject
				cell.modulate = UiTheme.FROST
				lines.append("A socket holding the %s tablet: the ingots beside it support that skill. Click to lift (free)." % subject)
			elif placed.has(key):
				var info: Dictionary = sim.foundry_ingot(placed[key])
				cell.text = info.get("display_name", placed[key]).replace(" Ingot", "")
				lines.append(info.get("sentence", ""))
				if supports.has(key):
					cell.modulate = UiTheme.SUN_WARM
			elif _sockets.has(key):
				cell.text = "[    ]"
				cell.modulate = UiTheme.FROST
				lines.append("A socket: lay a skill's tablet here and the four cells beside it become its supports.")
			else:
				cell.text = "·"
				cell.modulate = Color(1, 1, 1, 0.6)
			if supports.has(key) and not tablets.has(key):
				for subject in supports[key]:
					lines.append(("Beside %s: an ingot here supports it." if not placed.has(key) else "Beside %s.") % subject)
				if placed.has(key) and not readings.has(key):
					lines.append("It does not read the skill beside it yet.")
			if corners.has(key) and not placed.has(key) and not tablets.has(key) and not _sockets.has(key):
				lines.append("A corner of the %s working: an ingot here pairs with the supports it touches." % ", ".join(PackedStringArray(corners[key])))
			if readings.has(key):
				for reading in readings[key]:
					lines.append(reading)
			cell.tooltip_text = "\n".join(lines)
			cell.pressed.connect(_on_cell.bind(r, c))
			_grid.add_child(cell)

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
		none.text = "None in hand. Milestones forge them: the first bench, first kills, the first smelt, the first dressed block, the Tyrant."
		none.modulate = UiTheme.MUTED
		_tray.add_child(none)

	for child in _tablets.get_children():
		child.queue_free()
	var laid_any := false
	for t in view.get("tablets", []):
		laid_any = true
		var button := Button.new()
		button.text = "Lay %s" % t["display_name"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		if _selected_skill == StringName(String(t["id"])):
			button.modulate = UiTheme.GRASS_LIGHT
		button.pressed.connect(_on_tablet.bind(String(t["id"])))
		_tablets.add_child(button)
	if not laid_any:
		var none := Label.new()
		none.text = "Every skill you know is on the plate." if not view.get("tablets", []).is_empty() or not view["plate"].is_empty() else "Learn a skill and lay its tablet here."
		none.modulate = UiTheme.MUTED
		_tablets.add_child(none)

	for child in _effects.get_children():
		child.queue_free()
	effect_count = 0
	for effect in effects:
		var line := Label.new()
		var kind: String = effect["kind"]
		line.text = "%s  ·  %s  —  %s" % [kind, effect["label"], effect["sentence"]]
		if kind == "support" or kind == "backing":
			line.modulate = UiTheme.FROST
		elif kind != "ingot":
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
	_selected_skill = &""
	_message.text = "Pick a cell for the %s." % sim.foundry_ingot(id).get("display_name", id) if _selected != &"" else ""
	refresh()


func _on_tablet(id: String) -> void:
	_selected_skill = StringName(id) if _selected_skill != StringName(id) else &""
	_selected = &""
	_message.text = "Pick a cell for the %s tablet; the ingots beside it will support it." % sim.combat_skill(id).get("display_name", id) if _selected_skill != &"" else ""
	refresh()


func _on_cell(row: int, col: int) -> void:
	if row < _first_row or row > _last_row:
		_message.text = "The era has not forged this row."
		refresh()
		return
	var view: Dictionary = sim.foundry()
	for p in view["plate"]:
		if int(p["row"]) == row and int(p["col"]) == col:
			var was_tablet: bool = String(p.get("skill", "")) != ""
			if sim.foundry_remove(row, col):
				_message.text = "Lifted." if was_tablet else "Lifted. The metal is spent."
				_after_change()
			else:
				_message.text = "Re-forging needs %s." % _cost_text(view.get("reforge_cost", {}))
				refresh()
			return
	if _selected_skill != &"":
		if sim.foundry_place_skill(row, col, String(_selected_skill)):
			_selected_skill = &""
			_message.text = ""
			_after_change()
		else:
			_message.text = "A tablet goes in a socket." if not _sockets.has(Vector2i(row, col)) else "That tablet cannot go there."
			refresh()
		return
	if _selected == &"":
		_message.text = "Pick an ingot from the tray, or a skill to lay."
		refresh()
		return
	if sim.foundry_place(row, col, String(_selected)):
		if int(view["unplaced"].get(String(_selected), 0)) <= 1:
			_selected = &""
		_message.text = ""
		_after_change()
	else:
		_message.text = "A socket takes a tablet, not an ingot." if _sockets.has(Vector2i(row, col)) else "That ingot cannot go there."
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
	_selected_skill = &""


func set_selected_skill(id: StringName) -> void:
	_selected_skill = id
	_selected = &""


func press_cell(row: int, col: int) -> void:
	_on_cell(row, col)
