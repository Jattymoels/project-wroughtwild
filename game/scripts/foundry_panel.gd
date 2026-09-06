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
## The rail beside a row (its width) and above a column (its height).
const RAIL_WIDTH := 96
const RAIL_HEIGHT := 34

var sim: WroughtwildSim
var player: WroughtwildPlayer

var _root: PanelContainer
var _title: Label
var _grid: GridContainer
var _tray: VBoxContainer
var _effects: VBoxContainer
var _workings: VBoxContainer
var _preview: RichTextLabel
var _instructions: Label
var _effect_toggle: CheckButton
var _cell_buttons := {}
var _flow_overlay: FoundryFlowOverlay
var _message: Label
var _selected: StringName = &""
## The metal of the ingot picked from the tray (slice 10).
var _selected_metal := ""
## A skill picked from the tablet tray, to lay on the next empty cell.
var _selected_skill: StringName = &""
var _tablets: VBoxContainer
## A currency kind picked from the purse, to set on the next cell (D-023,
## the flow): a corner, or a far cell beyond one, never touching a socket.
var _subjects: VBoxContainer
var _selected_subject: StringName = &""
## The exterior (D-023 slice 9): the specialisation offer, the patterns
## known, and the rail selected for setting.
var _rails: VBoxContainer
var _rails_section: Label
var _list_scroll: ScrollContainer
var _selected_pattern: StringName = &""
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
var rail_count := 0


func _ready() -> void:
	layer = 10
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.set_anchors_preset(Control.PRESET_TOP_LEFT)
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
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 22)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(_title)
	var help := Button.new()
	help.text = "How to use"
	help.pressed.connect(_show_help)
	header.add_child(help)
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
	_instructions = Label.new()
	_instructions.modulate = UiTheme.MUTED
	_instructions.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_instructions.custom_minimum_size = Vector2(4 * CELL_SIZE.x + RAIL_WIDTH + 4 * 6, 0)
	left.add_child(_instructions)
	_preview = RichTextLabel.new()
	_preview.custom_minimum_size = Vector2(4 * CELL_SIZE.x + RAIL_WIDTH + 24, 88)
	_preview.bbcode_enabled = false
	_preview.scroll_active = true
	_preview.text = "Hover a transformed ingot to trace its flow."
	left.add_child(_preview)
	_flow_overlay = FoundryFlowOverlay.new()
	_flow_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flow_overlay)

	_list_scroll = ScrollContainer.new()
	_list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_scroll.custom_minimum_size = Vector2(440,440)
	_list_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_list_scroll)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# The lists wrap and clip inside a fixed column, so a plate full of forms
	# never pushes the panel past the window.
	right.custom_minimum_size = Vector2(420, 0)
	right.add_theme_constant_override("separation", 6)
	_list_scroll.add_child(right)
	right.add_child(_section("Your workings"))
	_workings = VBoxContainer.new()
	right.add_child(_workings)
	right.add_child(_section("Ingots in hand"))
	_tray = VBoxContainer.new()
	right.add_child(_tray)
	right.add_child(_section("Skills to lay"))
	_tablets = VBoxContainer.new()
	right.add_child(_tablets)
	right.add_child(_section("Kinds to set"))
	_subjects = VBoxContainer.new()
	right.add_child(_subjects)
	_rails_section = _section("Rails")
	right.add_child(_rails_section)
	_rails = VBoxContainer.new()
	right.add_child(_rails)
	_effect_toggle = CheckButton.new()
	_effect_toggle.text = "Full effect breakdown"
	right.add_child(_effect_toggle)
	_effects = VBoxContainer.new()
	_effects.hide()
	right.add_child(_effects)
	_effect_toggle.toggled.connect(_effects.set_visible)

	_message = Label.new()
	_message.modulate = UiTheme.MUTED
	_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
	_flow_overlay.visible = true
	_message.text = ""
	refresh()


func close_panel() -> void:
	if not is_open():
		return
	_root.visible = false
	_flow_overlay.visible = false
	closed.emit()


func message() -> String:
	return _message.text


func _show_help() -> void:
	_preview.text = "Lay skill tablets in sockets. Adjacent ingots support them.\nKinds transform ingots along an inward chain to a compatible skill.\nSelect a piece, then hover a cell to inspect before placing. Hover an existing piece for its full reading."
	_flow_overlay.paths = []
	_flow_overlay.queue_redraw()


func refresh() -> void:
	if sim == null or not is_open():
		return
	var view: Dictionary = sim.foundry()
	_fit.call_deferred()
	var rows: int = view["rows"]
	var cols: int = view["cols"]
	_first_row = int(view.get("first_row", 0))
	_last_row = int(view.get("last_row", rows - 1))
	_sockets.clear()
	for s in view.get("sockets", []):
		_sockets[Vector2i(int(s[0]), int(s[1]))] = true
	_title.text = "The Foundry · era %d · rows %d–%d of %d×%d" % [view["era"], _first_row + 1, _last_row + 1, rows, cols]
	_instructions.text = "Select a piece; hover a cell to preview.\nLift: %s. Tablets lift free." % _cost_text(view.get("reforge_cost", {}))

	_cell_buttons.clear()
	_flow_overlay.paths = []
	_flow_overlay.queue_redraw()
	for child in _grid.get_children():
		child.queue_free()
	_grid.columns = cols + 1
	var rail_slots := {}
	for r in view.get("rails", []):
		rail_slots["%s:%d" % [String(r["axis"]), int(r["index"])]] = r
	var rails_allowed: int = int(view.get("rails_allowed", 0))
	var placed := {}
	var placed_metal := {}
	var tablets := {}
	var currencies := {}
	for p in view["plate"]:
		if String(p.get("skill", "")) != "":
			tablets[Vector2i(p["row"], p["col"])] = String(p["skill"])
		elif String(p.get("currency", "")) != "":
			currencies[Vector2i(p["row"], p["col"])] = String(p["currency"])
		else:
			placed[Vector2i(p["row"], p["col"])] = String(p["ingot"])
			placed_metal[Vector2i(p["row"], p["col"])] = String(p.get("metal", ""))
	# The metals (slice 10): name and reach by id; the default goes unsaid.
	var metal_names := {}
	var metal_reach := {}
	for m in view.get("metals", []):
		metal_names[String(m["id"])] = String(m["display_name"])
		metal_reach[String(m["id"])] = int(m["reach"])
	var default_metal := String(view.get("default_metal", ""))
	var kind_names := {}
	var kind_short := {}
	for k in view.get("kinds", []):
		kind_names[String(k["id"])] = String(k["display_name"])
		kind_short[String(k["id"])] = String(k.get("short_name", k["display_name"]))
	var flowing := {}
	for f in view.get("flows", []):
		flowing[Vector2i(int(f["row"]), int(f["col"]))] = bool(f["flows"])
	# Roles (D-023): every socket's four supports and four corners, named by
	# the tablet it holds or, bare, by its place on the frame, so no forged
	# cell is ever blank.
	var supports := {}
	var corners := {}
	for key in _sockets:
		var subject: String = "the empty socket at row %d, column %d" % [key.x + 1, key.y + 1]
		if tablets.has(key):
			subject = "the %s working" % sim.combat_skill(tablets[key]).get("display_name", tablets[key])
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
	var form_names := {}
	var effects: Array = sim.foundry_effects()
	for effect in effects:
		var position := Vector2i(int(effect.cell_row), int(effect.cell_col))
		var name := String(effect.get("form_name", ""))
		if name != "":
			if not form_names.has(position): form_names[position] = PackedStringArray()
			if not form_names[position].has(name): form_names[position].append(name)
		var kind: String = effect["kind"]
		if kind != "support" and kind != "added" and kind != "backing" and kind != "form" and kind != "link":
			continue
		var from := Vector2i(int(effect["cell_row"]), int(effect["cell_col"]))
		if not readings.has(from):
			readings[from] = []
		readings[from].append("%s: %s" % [effect["label"], effect["sentence"]])
	cell_count = 0
	frame_cell_count = 0
	rail_count = 0
	# The exterior (D-023 slice 9): a rail above every column, then the
	# corner; a rail beside every row after its cells.
	for c in cols:
		_grid.add_child(_rail_button(rail_slots.get("column:%d" % c, {}), rails_allowed, Vector2(CELL_SIZE.x, RAIL_HEIGHT)))
	var corner := Label.new()
	corner.text = ""
	_grid.add_child(corner)
	for r in rows:
		for c in cols:
			var cell := Button.new()
			cell.custom_minimum_size = CELL_SIZE
			cell.add_theme_font_size_override("font_size", 13)
			cell.clip_text = true
			var key := Vector2i(r, c)
			_cell_buttons[key] = cell
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
				cell.text = _cell_name(subject)
				cell.modulate = UiTheme.FROST
				lines.append("A socket holding the %s tablet: the ingots beside it support that skill. Click to lift (free)." % subject)
			elif currencies.has(key):
				var kind_name: String = kind_names.get(currencies[key], currencies[key])
				cell.text = "{ %s }" % kind_short.get(currencies[key], kind_name)
				cell.modulate = UiTheme.IRON_RUST if flowing.get(key, false) else Color(UiTheme.IRON_RUST, 0.45)
				if flowing.get(key, false):
					lines.append("This %s flows to a skill: its base counts, and its identity travels through every inward ingot. Click to lift (costs metal; it returns to your purse)." % kind_name)
				else:
					lines.append("This %s flows to nothing yet: no chain of pieces leads inward to a laid tablet. It gives nothing until one does." % kind_name)
				for effect in effects:
					if effect["kind"] == "augment" and int(effect["cell_row"]) == r and int(effect["cell_col"]) == c:
						lines.append("Its base: %s." % effect["sentence"])
			elif placed.has(key):
				var info: Dictionary = sim.foundry_ingot(placed[key])
				var metal: String = placed_metal.get(key, "")
				cell.text = info.get("display_name", placed[key]).replace(" Ingot", "")
				if form_names.has(key):
					cell.text = _cell_name(String(form_names[key][0]))
					if form_names[key].size() > 1:
						cell.text += "\n%d forms" % form_names[key].size()
						lines.append("%d separate effects share this cell." % form_names[key].size())
					lines.append("%s becomes %s." % [info.display_name, " / ".join(form_names[key])])
				if metal != "" and metal != default_metal:
					cell.text += "\n%s" % metal_names.get(metal, metal)
				lines.append(info.get("sentence", ""))
				if metal != "" and metal != default_metal:
					lines.append("Cast in %s: its backing and pairs are read %d cells out along its row and column." % [metal_names.get(metal, metal).to_lower(), int(metal_reach.get(metal, 1))])
				if supports.has(key):
					cell.modulate = UiTheme.SUN_WARM
			elif _sockets.has(key):
				cell.text = "[    ]"
				cell.modulate = UiTheme.FROST
				lines.append("A socket: lay a skill's tablet here and the four cells beside it become its supports.")
			else:
				cell.text = "·"
				cell.modulate = Color(1, 1, 1, 0.6)
			if supports.has(key) and not tablets.has(key) and not currencies.has(key):
				for subject in supports[key]:
					lines.append(("Beside %s: an ingot here is one of its supports." if not placed.has(key) else "Beside %s.") % subject)
				if placed.has(key) and not readings.has(key):
					lines.append("It does not read the skill beside it yet.")
			if corners.has(key) and not placed.has(key) and not tablets.has(key) and not currencies.has(key) and not _sockets.has(key):
				lines.append("A corner of %s: an ingot here pairs with the supports it touches; a kind here works them into forms." % ", ".join(PackedStringArray(corners[key])))
			if readings.has(key):
				for reading in readings[key]:
					lines.append(reading)
			if lines.is_empty():
				lines.append("Belongs to no working yet: room for a pair or a backing.")
			# Keep full native readings in the fixed inspector, not a tooltip
			# whose height grows with every operation in a branching chain.
			var unique_lines := PackedStringArray()
			for line in lines:
				if not unique_lines.has(line): unique_lines.append(line)
			cell.set_meta("reading_details", "\n".join(unique_lines))
			if tablets.has(key):
				cell.tooltip_text = "Click to lift tablet (free). Full reading below."
			elif placed.has(key) or currencies.has(key):
				cell.tooltip_text = "Click to lift: %s. Full reading below." % _cost_text(view.get("reforge_cost", {}))
			else:
				cell.tooltip_text = "Select a piece, then preview here."
			cell.pressed.connect(_on_cell.bind(r, c))
			cell.mouse_entered.connect(_inspect_cell.bind(r, c))
			_grid.add_child(cell)
		_grid.add_child(_rail_button(rail_slots.get("row:%d" % r, {}), rails_allowed, Vector2(RAIL_WIDTH, CELL_SIZE.y)))

	for child in _workings.get_children(): child.queue_free()
	for skill in tablets.values():
		var form: Dictionary = sim.skill_mutation(String(skill))
		var title := Label.new()
		title.text = sim.combat_skill(String(skill)).get("display_name", skill)
		title.modulate = UiTheme.SUN_WARM
		_workings.add_child(title)
		var text := Label.new()
		text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var lines := PackedStringArray()
		var resolved := _resolved_summary(String(skill), form)
		if resolved != "": lines.append(resolved)
		var shown := {}
		for entry in form.get("forms", []):
			var name := String(entry.form_name)
			if shown.has(name) or resolved.contains(name + ":"): continue
			shown[name] = true
			lines.append("%s — %s" % [name, entry.description])
		if lines.is_empty(): lines.append("Plain support. Add an inward Kind path to transform it.")
		text.text = "\n".join(lines)
		text.tooltip_text = "Equipment can read: " + ", ".join(form.get("tags", []))
		_workings.add_child(text)
	for child in _tray.get_children():
		child.queue_free()
	tray_count = 0
	var by_metal: Dictionary = view.get("unplaced_by_metal", {})
	var any := false
	for id in sim.foundry_ingot_ids():
		var counts: Dictionary = by_metal.get(id, {})
		if counts.is_empty():
			continue
		var info: Dictionary = sim.foundry_ingot(id)
		# One row per casting in hand (slice 10): the alloy named, iron unsaid.
		for m in view.get("metals", []):
			var metal := String(m["id"])
			var count: int = int(counts.get(metal, 0))
			if count <= 0:
				continue
			any = true
			var button := Button.new()
			var cast_name: String = "" if metal == default_metal else " (%s)" % String(m["display_name"]).to_lower()
			button.text = "%s%s  ×%d" % [info["display_name"], cast_name, count]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.clip_text = true
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.tooltip_text = "Select to read its effects, then hover a plate cell."
			if _selected == StringName(id) and _selected_metal == metal:
				button.modulate = UiTheme.GRASS_LIGHT
			button.pressed.connect(_on_tray.bind(id, metal))
			_tray.add_child(button)
			tray_count += 1
	if not any:
		var none := Label.new()
		none.text = "None in hand. Earn ingots from milestones."
		none.tooltip_text = "First bench, kills, smelt, dressed stone and the Tyrant each award ingots."
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
		button.clip_text = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if _selected_skill == StringName(String(t["id"])):
			button.modulate = UiTheme.GRASS_LIGHT
		button.pressed.connect(_on_tablet.bind(String(t["id"])))
		_tablets.add_child(button)
	if not laid_any:
		var none := Label.new()
		none.text = "Every skill you know is on the plate." if not view.get("tablets", []).is_empty() or not view["plate"].is_empty() else "Learn a skill and lay its tablet here."
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.modulate = UiTheme.MUTED
		_tablets.add_child(none)

	for child in _subjects.get_children():
		child.queue_free()
	var any_kind := false
	for k in view.get("kinds", []):
		if int(k["held"]) <= 0:
			continue
		any_kind = true
		var button := Button.new()
		button.text = "Set a %s  ×%d" % [k["display_name"], int(k["held"])]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.tooltip_text = "Select to read its effect, then preview an inward path."
		if _selected_subject == StringName(String(k["id"])):
			button.modulate = UiTheme.GRASS_LIGHT
		button.pressed.connect(_on_subject.bind(String(k["id"])))
		_subjects.add_child(button)
	if not any_kind:
		var none := Label.new()
		none.text = "No Kinds in your purse. Enemy families and the mine order award them."
		none.tooltip_text = "Whelps and wisps pay Catalysts; husks and knights pay Vanguards."
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.modulate = UiTheme.MUTED
		_subjects.add_child(none)

	for child in _rails.get_children():
		child.queue_free()
	_rails_section.text = "Rails  (%d of %d set)" % [int(view.get("rails_set", 0)), rails_allowed]
	if String(view.get("class", "")) == "":
		var none := Label.new()
		none.text = "Choose a class to see its rail patterns."
		none.modulate = UiTheme.MUTED
		none.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		none.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rails.add_child(none)
	else:
		if bool(view.get("can_specialise", false)):
			# The view (owner, 4 Sep 2026): what the surround can become.
			var offer := Label.new()
			offer.text = "Choose a specialisation once. Your rails change as shown below."
			offer.modulate = UiTheme.SUN_WARM
			offer.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			offer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_rails.add_child(offer)
			for s in view.get("specialisations", []):
				var button := Button.new()
				button.text = "Specialise as a %s" % s["display_name"]
				button.alignment = HORIZONTAL_ALIGNMENT_LEFT
				button.clip_text = true
				button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				button.pressed.connect(_on_specialise.bind(String(s["id"])))
				_rails.add_child(button)
				for b in s.get("becomes", []):
					var line := Label.new()
					line.text = "    %s becomes %s: %s." % [b["from"]["display_name"], b["to"]["display_name"], b["to"]["rule_text"]]
					line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
					line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					line.modulate = UiTheme.FROST
					_rails.add_child(line)
		var who := Label.new()
		var spec_name: String = String(view.get("specialisation_name", ""))
		who.text = "%s%s · choose a pattern, then an outer rail. One rail per pattern; up to %d this era." % [
			view.get("class_name", ""), " (%s)" % spec_name if spec_name != "" else "", rails_allowed]
		who.modulate = UiTheme.MUTED
		who.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		who.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_rails.add_child(who)
		for p in view.get("patterns", []):
			var button := Button.new()
			var taught: String = "  (the %ss' manner)" % p.get("teacher_name", "") if bool(p.get("manner", false)) else ""
			button.text = "Set %s (%s)%s   ·   %s - %s" % [p["display_name"], p["axis"], taught, p["condition_text"], p["rule_text"]]
			button.alignment = HORIZONTAL_ALIGNMENT_LEFT
			button.clip_text = true
			button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			button.tooltip_text = "%s, a %s pattern: %s.\nWhile it holds: %s." % [p["display_name"], p["axis"], p["condition_text"], p["rule_text"]]
			if _selected_pattern == StringName(String(p["id"])):
				button.modulate = UiTheme.GRASS_LIGHT
			button.pressed.connect(_on_pattern.bind(String(p["id"])))
			_rails.add_child(button)

	for child in _effects.get_children():
		child.queue_free()
	effect_count = 0
	for effect in effects:
		var line := Label.new()
		var kind: String = effect["kind"]
		line.text = "%s  ·  %s  —  %s" % [kind, effect["label"], effect["sentence"]]
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		if kind == "support" or kind == "added" or kind == "backing" or kind == "form":
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


func _fit() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree(): return
	var viewport := get_viewport().get_visible_rect().size
	_list_scroll.custom_minimum_size.y = minf(520,viewport.y*0.61)
	_root.reset_size()
	_root.position = (viewport-_root.size)*0.5


## A rail slot (D-023 slice 9): its pattern's name when set, lit while the
## line holds; dim and disabled until the first hall's test opens the
## exterior; dim on a row the era has not forged.
func _rail_button(slot: Dictionary, allowed: int, size: Vector2) -> Button:
	var button := Button.new()
	button.custom_minimum_size = size
	button.clip_text = true
	rail_count += 1
	var axis := String(slot.get("axis", "row"))
	var index := int(slot.get("index", 0))
	var where := "%s %d" % [axis, index + 1]
	if not bool(slot.get("forged", false)):
		button.text = "·"
		button.disabled = true
		button.modulate = Color(1, 1, 1, 0.25)
		button.tooltip_text = "The rail of %s: the era has not forged this row." % where
	elif allowed <= 0:
		button.text = "rail"
		button.disabled = true
		button.modulate = Color(1, 1, 1, 0.3)
		button.tooltip_text = "The rail of %s. The era allows no rails yet." % where
	elif String(slot.get("pattern", "")) == "":
		button.text = "rail"
		button.modulate = Color(1, 1, 1, 0.5)
		button.tooltip_text = "The rail of %s, empty. Pick a %s pattern and set it here; it reads the whole line." % [where, axis]
	else:
		button.text = String(slot.get("display_name", slot["pattern"]))
		var lines := PackedStringArray()
		lines.append("%s on %s: %s." % [slot["display_name"], where, slot["condition_text"]])
		if bool(slot.get("holds", false)):
			button.modulate = UiTheme.SUN_WARM
			lines.append("Lit: %s." % slot["rule_text"])
		else:
			button.modulate = Color(UiTheme.SUN_WARM, 0.45)
			lines.append("Not lit: %s" % _rail_why(slot))
		for b in slot.get("becomes", []):
			lines.append("As a %s it becomes %s: %s." % [b["display_name"], b["pattern"]["display_name"], b["pattern"]["rule_text"]])
		lines.append("Click to clear the rail.")
		button.tooltip_text = "\n".join(lines)
	if not button.disabled:
		button.pressed.connect(_on_rail.bind(axis, index))
	return button


## Why a set rail is not lit, in words: which placed cell breaks it, how
## many ingots it still wants, what the line must hold.
func _rail_why(slot: Dictionary) -> String:
	var parts := PackedStringArray()
	var breaking: Array = slot.get("breaking", [])
	if not breaking.is_empty():
		var cells := PackedStringArray()
		for b in breaking:
			cells.append("row %d, column %d" % [int(b[0]) + 1, int(b[1]) + 1])
		parts.append("the ingot at %s breaks it" % ", ".join(cells))
	if int(slot.get("placed", 0)) < int(slot.get("minimum", 0)):
		parts.append("%d of the %d ingots it needs are placed" % [int(slot.get("placed", 0)), int(slot.get("minimum", 0))])
	if bool(slot.get("missing_skill", false)):
		parts.append("no skill of the right kind is laid in the line")
	if bool(slot.get("missing_kind", false)):
		parts.append("no kind of the right family rests in the line")
	return "; ".join(parts) + "." if not parts.is_empty() else "the line does not meet it yet."


func _on_pattern(id: String) -> void:
	_selected_pattern = StringName(id) if _selected_pattern != StringName(id) else &""
	_selected = &""
	_selected_skill = &""
	_selected_subject = &""
	var p: Dictionary = sim.foundry_pattern(id)
	_message.text = "Pick a %s's rail for %s." % [p.get("axis", "line"), p.get("display_name", id)] if _selected_pattern != &"" else ""
	refresh()


func _on_specialise(id: String) -> void:
	if sim.foundry_specialise(id):
		_message.text = "You are a %s. Your rails have become what they showed; the patterns under Rails are the grown ones." % sim.foundry().get("specialisation_name", id)
		_after_change()
	else:
		_message.text = "The choice is not open."
		refresh()


func _on_rail(axis: String, index: int) -> void:
	var view: Dictionary = sim.foundry()
	if _selected_pattern != &"":
		if sim.foundry_set_rail(axis, index, String(_selected_pattern)):
			_selected_pattern = &""
			_message.text = ""
			_after_change()
		else:
			var p: Dictionary = sim.foundry_pattern(String(_selected_pattern))
			if String(p.get("axis", "")) != axis:
				_message.text = "%s reads a %s, not a %s." % [p.get("display_name", ""), p.get("axis", ""), axis]
			elif int(view.get("rails_set", 0)) >= int(view.get("rails_allowed", 0)):
				_message.text = "Every rail the era allows is set (%d). Clear one first." % int(view.get("rails_allowed", 0))
			else:
				_message.text = "That pattern is already set in another rail."
			refresh()
		return
	if sim.foundry_clear_rail(axis, index):
		_message.text = "The rail is cleared."
		_after_change()
	else:
		_message.text = "Pick a pattern to set in a rail."
		refresh()


func _on_tray(id: String, metal: String = "") -> void:
	var same := _selected == StringName(id) and _selected_metal == metal
	_selected = &"" if same else StringName(id)
	_selected_metal = "" if same else metal
	_selected_skill = &""
	_selected_subject = &""
	_selected_pattern = &""
	_message.text = "Pick a cell for the %s." % sim.foundry_ingot(id).get("display_name", id) if _selected != &"" else ""
	if _selected != &"":
		var info: Dictionary = sim.foundry_ingot(id)
		_preview.text = "%s\n%s" % [info.get("display_name",id), info.get("sentence","")]
		# These are native descriptions of the selected ingot, before any
		# cell is chosen. The hover preview then shows its actual placement.
		for key in ["skill_sentence", "added_sentence"]:
			if String(info.get(key, "")) != "": _preview.text += "\n" + String(info[key])
		for alloy: Dictionary in sim.foundry().get("metals", []):
			if String(alloy.id)==metal:
				_preview.text += "\n%s · backing and pairs read %d cells out." % [alloy.display_name,int(alloy.reach)]
	refresh()


func _on_subject(id: String) -> void:
	_selected_subject = StringName(id) if _selected_subject != StringName(id) else &""
	_selected = &""
	_selected_skill = &""
	_selected_pattern = &""
	_message.text = "Pick a corner or an outer cell with an inward path." if _selected_subject != &"" else ""
	if _selected_subject != &"":
		for kind: Dictionary in sim.foundry().get("kinds", []):
			if String(kind.id)==id: _preview.text = "%s\n%s" % [kind.display_name,kind.base_sentence]
		for kind: Dictionary in sim.currency_kinds():
			if String(kind.id)==id and String(kind.get("description",""))!="":
				_preview.text += "\n"+String(kind.description)
	refresh()


func _on_tablet(id: String) -> void:
	_selected_skill = StringName(id) if _selected_skill != StringName(id) else &""
	_selected = &""
	_selected_subject = &""
	_selected_pattern = &""
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
			var was_kind: bool = String(p.get("currency", "")) != ""
			if sim.foundry_remove(row, col):
				if was_tablet:
					_message.text = "Lifted."
				elif was_kind:
					_message.text = "Lifted. The metal is spent; the %s returns to your purse." % Hud.pretty(String(p["currency"]))
				else:
					_message.text = "Lifted. The metal is spent."
				_after_change()
			else:
				_message.text = "Re-forging needs %s." % _cost_text(view.get("reforge_cost", {}))
				refresh()
			return
	if _selected_subject != &"":
		if sim.foundry_place_kind(row, col, String(_selected_subject)):
			_selected_subject = &""
			_message.text = ""
			_after_change()
		else:
			_message.text = "A kind goes in a corner, where it cannot touch a socket." if _sockets.has(Vector2i(row, col)) or _beside_socket(row, col) else "That cell will not take it."
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
	if sim.foundry_place(row, col, String(_selected), _selected_metal):
		var left: int = int(view["unplaced"].get(String(_selected), 0))
		if _selected_metal != "":
			left = int(view.get("unplaced_by_metal", {}).get(String(_selected), {}).get(_selected_metal, 0))
		if left <= 1:
			_selected = &""
			_selected_metal = ""
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
func set_selected(id: StringName, metal: String = "") -> void:
	_selected = id
	_selected_metal = metal
	_selected_skill = &""


func set_selected_skill(id: StringName) -> void:
	_selected_skill = id
	_selected = &""
	_selected_subject = &""


func set_selected_subject(id: StringName) -> void:
	_selected_subject = id
	_selected = &""
	_selected_skill = &""


## True when the cell is orthogonally beside a socket (a support cell).
func _beside_socket(row: int, col: int) -> bool:
	for d in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		if _sockets.has(Vector2i(row, col) + d):
			return true
	return false


func press_cell(row: int, col: int) -> void:
	_on_cell(row, col)


func set_selected_pattern(id: StringName) -> void:
	_selected_pattern = id
	_selected = &""
	_selected_skill = &""
	_selected_subject = &""


func press_rail(axis: String, index: int) -> void:
	_on_rail(axis, index)


func specialise(id: String) -> void:
	_on_specialise(id)


func _inspect_cell(row: int, col: int) -> void:
	if not is_open(): return
	var selected := String(_selected_subject if _selected_subject != &"" else _selected_skill if _selected_skill != &"" else _selected)
	var effects: Array = sim.foundry_effects()
	var lines := PackedStringArray()
	if selected != "":
		var preview: Dictionary = sim.foundry_preview(row, col, selected, _selected_metal)
		if not bool(preview.get("valid", false)):
			_preview.text = String(preview.get("reason", "This cell cannot take the selected piece."))
			var current: Button = _cell_buttons.get(Vector2i(row,col))
			if current != null and current.has_meta("reading_details"):
				_preview.text += "\nCURRENT READING\n" + String(current.get_meta("reading_details"))
			_flow_overlay.paths = []
			_flow_overlay.queue_redraw()
			return
		effects = preview.get("effects", [])
		lines.append("AFTER PLACEMENT · no material spent")
	else:
		lines.append("CURRENT FLOW")
		var button: Button = _cell_buttons.get(Vector2i(row,col))
		if button != null: lines.append(String(button.get_meta("reading_details", "")))
	var shown := {}
	var paths: Array = []
	for effect in effects:
		if String(effect.get("form_name", "")) == "": continue
		var involved := int(effect.cell_row) == row and int(effect.cell_col) == col
		var points := PackedVector2Array()
		for step in effect.get("path", []):
			var cell := Vector2i(int(step[0]), int(step[1]))
			if cell == Vector2i(row, col): involved = true
			if _cell_buttons.has(cell): points.append((_cell_buttons[cell] as Button).get_global_rect().get_center())
		if not involved: continue
		var key := "%s:%s:%s" % [effect.form_name, effect.skill, effect.get("source_kind", "")]
		if shown.has(key): continue
		shown[key] = true
		paths.append(points)
		var skill: Dictionary = sim.combat_skill(String(effect.skill))
		lines.append("%s → %s" % [effect.form_name, skill.get("display_name", effect.skill)])
		if not "\n".join(lines).contains(String(effect.description)):
			lines.append(String(effect.description))
	if shown.is_empty(): lines.append("No compatible mutation through this cell.")
	_preview.text = "\n".join(lines)
	_flow_overlay.paths = paths
	_flow_overlay.queue_redraw()


func _resolved_summary(skill: String, form: Dictionary) -> String:
	var parts := PackedStringArray()
	var shown_identities := {}
	for effect in form.get("forms",[]):
		if not String(effect.get("modifier","")).begins_with("mutation_identity_"): continue
		var name := String(effect.get("form_name",""))
		if shown_identities.has(name): continue
		shown_identities[name]=true
		parts.append(name+": "+String(effect.get("description","")))
	var memory := float(form.get("memory_extension",0))
	if float(form.get("rime_ring_buildup",0))>0:
		parts.append("Rimewell: an expanding ring carries %.0f chill once; no extra damage" % float(form.rime_ring_chill))
	if float(form.get("rime_edge_fraction",0))>0:
		parts.append("Rime Edge: a chilled target opens lateral cuts for %.1f cold; original victim excluded" % float(form.rime_edge_cold_damage))
	if float(form.get("whiteout_slow",0))>0:
		parts.append("Whiteout: a chilled target leaves mist; crossing enemy shots lose %.0f%% speed" % (float(form.whiteout_slow)*100))
	if float(form.get("cold_sap_absorb",0))>0:
		parts.append("Cold Sap: a chilled hit stores %.0f protection against your next enemy hit" % float(form.cold_sap_absorb))
	if float(form.get("permafrost_seconds",0))>0:
		parts.append("Permafrost: bind a chilled target's feet for %.2f s; it can still attack" % float(form.permafrost_seconds))
	if float(form.get("stillwater_fraction",0))>0:
		parts.append("Stillwater: casting leaves a one-shot mirror; returns %.1f cold + %.0f chill to the shooter" % [float(form.stillwater_cold_damage),float(form.stillwater_chill)])
	if float(form.get("hoarfrost_refund",0))>0:
		parts.append("Hoarfrost: a chilled hit recovers %.2f s of your movement cooldown" % float(form.hoarfrost_refund))
	if float(form.get("emberbed_seconds",0))>0:
		parts.append("Emberbed: move %.2f s of an existing burn into %d ground pulses; same burn budget" % [float(form.emberbed_seconds),int(form.limits.emberbed_pulses)+int(floor(memory/float(form.limits.pulse_interval)))])
	if float(form.get("reservoir_seconds",0))>0:
		parts.append("Cold Reservoir: hold chill decay for %.1f s; freeze duration stays the same" % (float(form.reservoir_seconds)+memory))
	if float(form.get("wound_memory_seconds",0))>0:
		parts.append("Wound Memory: save up to %.1f s of a stationary victim's bleed for when it moves" % float(form.wound_memory_seconds))
	if float(form.get("afterfield_fraction",0))>0:
		parts.append("Afterfield: retain %.0f%% of the native hit for new arrivals; original occupants excluded" % (float(form.afterfield_fraction)*100))
	if float(form.get("lifebed_life",0))>0:
		parts.append("Lifebed: leave and return to your cast's mark to collect %.0f life once" % float(form.lifebed_life))
	if float(form.get("held_ground_push",0))>0:
		parts.append("Held Ground: your cast's seal pushes its first new arrival %.1f m outward" % float(form.held_ground_push))
	if float(form.get("sanctuary_charges",0))>0:
		parts.append("Sanctuary: a direct kill leaves a ward that catches one enemy shot")
	if float(form.get("lingering_refund",0))>0:
		parts.append("Lingering Step: use a different skill within %.1f s to recover %.2f s of this skill" % [float(form.limits.memory_seconds)+memory,float(form.lingering_refund)])
	if memory>0: parts.append("Kept Rime: +%.1f s to memory windows; longer Emberbed shares the same stored damage" % memory)
	if float(form.get("fuse_buildup",0)) > 0:
		parts.append("Kindling: a %.1f s fuse delivers %.0f ignite" % [float(form.limits.fuse_delay),float(form.fuse_ignite)])
	if float(form.get("rake_fraction",0)) > 0:
		parts.append("Cinder Edge: %.1f fire through a narrow seam behind a burning or bleeding target" % float(form.rake_fire_damage))
	if float(form.get("ember_hop_buildup",0)) > 0:
		parts.append("Wildfire: one spark carries %.0f ignite up to %.1f m" % [float(form.ember_hop_ignite),float(form.ember_hop_range)])
	if float(form.get("temper_push",0)) > 0:
		parts.append("Furnace Plate: heat on a burning target; the next hit you take pushes the pack %.1f m" % float(form.temper_push))
	if float(form.get("cautery_charges",0)) > 0:
		parts.append("Cautery: ignition clears one affliction, or guards against the next")
	if float(form.get("steam_fraction", 0)) > 0:
		parts.append("Steam Plume: 3 pulses · %.1f fire + %.1f cold each · first target per cast" % [float(form.steam_fire_damage), float(form.steam_cold_damage)])
	if float(form.get("burn_release_seconds", 0)) > 0:
		parts.append("Flashfire: spend %.2f s of an existing burn immediately" % float(form.burn_release_seconds))
	if float(form.get("warm_cinder_life", 0)) > 0:
		parts.append("Bloodfire: collect %.1f life from a newly ignited target" % float(form.warm_cinder_life))
	if float(form.get("steam_stagger", 0)) > 0:
		parts.append("Steambrand: chilled targets release an interrupting puff")
	if float(form.get("smoulder_slow", 0)) > 0:
		parts.append("%.0f%% slow · %.0f ignite / %.0f chill per hit" % [float(form.smoulder_slow) * 100, sim.ignite_applied(skill,false), sim.chill_applied(skill,false)])
	if float(form.get("field_fraction", 0)) > 0:
		parts.append("Field: %.0f%% hit every %.1f s for %.1f s" % [float(form.field_fraction)*100, float(form.limits.pulse_interval), float(form.field_seconds)])
	if float(form.get("zone_armour", 0)) > 0: parts.append("Seal: +%.0f armour inside" % float(form.zone_armour))
	if float(form.get("ward_charges", 0)) > 0: parts.append("Veil: catches %d shots" % int(form.ward_charges))
	if sim.skill_echo_every(skill) > 0: parts.append("Repeats every %d uses after %.2f s" % [sim.skill_echo_every(skill), float(form.get("echo_delay",0))])
	if not parts.is_empty() and String(sim.combat_skill(skill).get("delivery",""))=="dash":
		parts.append("Movement has no hit: only cast-triggered protection, recovery and switching can activate here")
	return "\n".join(parts)

func _cell_name(name: String) -> String:
	# Split long form names at a word boundary before they clip in the plate.
	var font := _root.get_theme_default_font()
	if font.get_string_size(name,HORIZONTAL_ALIGNMENT_LEFT,-1,13).x <= CELL_SIZE.x-20: return name
	var split := -1
	for i in name.length():
		if name[i]==" " and (split<0 or absf(i-name.length()*.5)<absf(split-name.length()*.5)): split = i
	return name.substr(0,split)+"\n"+name.substr(split+1) if split>0 else name
