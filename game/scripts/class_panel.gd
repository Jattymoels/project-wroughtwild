class_name ClassPanel
extends CanvasLayer
## The class, chosen before play begins (D-004; D-023 slice 9, owner 4 Sep
## 2026: "before you actually begin the game you choose a class, and in
## era 1 you can still access the plate/foundry, so that base plate's
## surrounding modifiers are determined by that first selection"). The
## sandpit opens this when no class is chosen; a save that carries one
## never sees it. Each class is its two rail patterns, written out, and
## the ways it may specialise after the first trial. One click, once.
## Every button calls one sim method; nothing here computes a rule.

signal closed

var sim: WroughtwildSim
var player: WroughtwildPlayer

var _root: PanelContainer
var _choices: VBoxContainer
var _message: Label

## Test surface.
var class_count := 0


func _ready() -> void:
	layer = 11
	_root = PanelContainer.new()
	_root.theme = UiTheme.theme()
	_root.set_anchors_preset(Control.PRESET_CENTER)
	_root.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_root.grow_vertical = Control.GROW_DIRECTION_BOTH
	_root.custom_minimum_size = Vector2(980, 0)
	_root.visible = false
	add_child(_root)

	var margin := MarginContainer.new()
	for side in ["margin_left", "margin_right", "margin_top", "margin_bottom"]:
		margin.add_theme_constant_override(side, 18)
	_root.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title := Label.new()
	title.text = "Choose your class"
	title.add_theme_font_size_override("font_size", 22)
	column.add_child(title)
	var how := Label.new()
	how.text = "Before you set out. Your class decides the plate's surround: two patterns for the rails outside the Foundry's rows and columns, yours from the first era. A pattern set in a rail reads the whole line and bends a rule while the line meets it. Complete the Tyrant's forge and you specialise further, and see what each pattern can become."
	how.modulate = UiTheme.MUTED
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size = Vector2(940, 0)
	column.add_child(how)

	_choices = VBoxContainer.new()
	_choices.add_theme_constant_override("separation", 8)
	column.add_child(_choices)

	_message = Label.new()
	_message.modulate = UiTheme.MUTED
	column.add_child(_message)


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
	for child in _choices.get_children():
		child.queue_free()
	class_count = 0
	for c in sim.foundry().get("classes", []):
		var box := VBoxContainer.new()
		box.add_theme_constant_override("separation", 2)
		_choices.add_child(box)
		var button := Button.new()
		button.text = "%s" % c["display_name"]
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(_on_choose.bind(String(c["id"])))
		box.add_child(button)
		for p in c.get("patterns", []):
			var line := Label.new()
			line.text = "    %s (%s): %s - %s." % [p["display_name"], p["axis"], p["condition_text"], p["rule_text"]]
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			line.modulate = UiTheme.FROST
			box.add_child(line)
		var names := PackedStringArray()
		for s in c.get("specialisations", []):
			names.append(String(s["display_name"]))
		if not names.is_empty():
			var later := Label.new()
			later.text = "    After the forge: %s." % ", ".join(names)
			later.modulate = UiTheme.MUTED
			box.add_child(later)
		class_count += 1


func _on_choose(id: String) -> void:
	choose(id)


## Chooses the class through the sim and closes on success. Returns
## whether the choice was taken (false once one stands).
func choose(id: String) -> bool:
	if sim == null or not sim.foundry_choose_class(id):
		_message.text = "The choice is made."
		return false
	var view: Dictionary = sim.foundry()
	var names := PackedStringArray()
	for p in view.get("patterns", []):
		names.append(String(p["display_name"]))
	if player != null and player.hud != null:
		player.hud.notify("You are a %s. Your rails hold %s from the first era; F opens the plate." % [view.get("class_name", id), " and ".join(names)])
	close_panel()
	return true
