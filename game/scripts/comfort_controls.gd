class_name ComfortControls
extends VBoxContainer
## Bounded contents of the existing help overlay, not a second modal stack.
var preferences: PlayerPreferences
var hud: Hud
var tabs: HBoxContainer
var page := "Camera"
var body: VBoxContainer
var scroll: ScrollContainer
var status: Label
var controls := {}
var binding_buttons := {}
var capture_action := ""
var _capture_button: Button
var _refreshing := false

func _ready() -> void:
	add_theme_constant_override("separation", 8)
	tabs = HBoxContainer.new()
	add_child(tabs)
	for title in ["Camera", "Sound", "Display", "Bindings", "Help"]:
		var button := Button.new()
		button.text = title
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.pressed.connect(show_page.bind(title))
		tabs.add_child(button)
	scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	body = VBoxContainer.new()
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation", 10)
	scroll.add_child(body)
	body.minimum_size_changed.connect(hud._fit_help.call_deferred)
	status = Label.new()
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.modulate = UiTheme.MUTED
	add_child(status)
	var footer := HBoxContainer.new()
	add_child(footer)
	var reset := Button.new()
	reset.text = "Reset all defaults"
	reset.pressed.connect(_reset)
	footer.add_child(reset)
	var close := Button.new()
	close.text = "Close · Esc"
	close.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	close.pressed.connect(hud.toggle_help)
	footer.add_child(close)
	preferences.changed.connect(refresh)
	show_page("Camera")

func show_page(title: String) -> void:
	cancel_capture()
	page = title
	controls.clear()
	binding_buttons.clear()
	for child in body.get_children():
		body.remove_child(child)
		child.queue_free()
	scroll.scroll_vertical = 0
	for button in tabs.get_children(): button.disabled = button.text == title
	if title == "Help":
		var label := _label("")
		InputPrompts.bind(label, Hud.HELP_TEXT)
		hud._help_body = label
	elif title == "Bindings":
		_label("Select a control, then press one key or mouse button. Escape cancels. Menu navigation and clicks retain their usual controls.")
		for action in preferences.actions:
			var row := HBoxContainer.new()
			body.add_child(row)
			var label := Label.new()
			label.text = preferences.actions[action]
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			row.add_child(label)
			var button := Button.new()
			button.custom_minimum_size.x = 150
			button.pressed.connect(begin_capture.bind(action))
			row.add_child(button)
			binding_buttons[action] = button
	else:
		for definition in preferences.definitions:
			if definition.page == title: _option(definition)
		if title == "Sound": hud._build_audio_controls(body)
	refresh()
	hud._fit_help.call_deferred()

func _label(content: String) -> Label:
	var label := Label.new()
	label.text = content
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(label)
	return label

func _option(definition: Dictionary) -> void:
	var column := VBoxContainer.new()
	body.add_child(column)
	var row := HBoxContainer.new()
	column.add_child(row)
	var name_label := Label.new()
	name_label.text = definition.label
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)
	var widget: Control
	var value_label: Label
	if definition.has("choices"):
		var choice := OptionButton.new()
		for title in definition.names: choice.add_item(title)
		choice.item_selected.connect(func(index: int): preferences.set_option(definition.id, definition.choices[index]))
		widget = choice
	elif definition.default is bool:
		var toggle := CheckBox.new()
		toggle.text = "Enabled"
		toggle.toggled.connect(func(value: bool): preferences.set_option(definition.id, value))
		widget = toggle
	else:
		var slider := HSlider.new()
		slider.min_value = definition.min
		slider.max_value = definition.max
		slider.step = definition.step
		slider.custom_minimum_size.x = 180
		slider.value_changed.connect(func(value: float): preferences.set_option(definition.id, value))
		widget = slider
		value_label = Label.new()
		value_label.custom_minimum_size.x = 56
	row.add_child(widget)
	if value_label: row.add_child(value_label)
	widget.tooltip_text = definition.help
	controls[definition.id] = {"widget":widget, "value":value_label, "definition":definition}
	var explanation := Label.new()
	explanation.text = definition.help
	explanation.modulate = UiTheme.MUTED
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(explanation)

func refresh() -> void:
	if _refreshing: return
	_refreshing = true
	for id in controls:
		var entry: Dictionary = controls[id]
		var value: Variant = preferences.values[id]
		if entry.widget is CheckBox: entry.widget.set_pressed_no_signal(value)
		elif entry.widget is OptionButton: entry.widget.select(entry.definition.choices.find(value))
		else:
			entry.widget.set_value_no_signal(value)
			entry.value.text = "%d%%" % roundi(value * 100.0) if entry.definition.suffix == "%" else ("%.1f×" % value if entry.definition.suffix == "×" else "%d°" % roundi(value))
	for action in binding_buttons:
		binding_buttons[action].text = "Press input…" if action == capture_action else InputPrompts.key(action)
	if capture_action.is_empty():
		status.text = preferences.binding_warning if not preferences.binding_warning.is_empty() else "Changes apply now and save on this device. The world keeps running."
		if preferences.last_error != OK: status.text = "Preference file unavailable. Changes apply now; check again after restarting."
	_refreshing = false

func begin_capture(action: String) -> void:
	capture_action = action
	_capture_button = binding_buttons[action]
	refresh()
	status.text = "Set %s: press one key or mouse button. Escape cancels." % preferences.actions[action]

func cancel_capture() -> void:
	capture_action = ""
	if is_instance_valid(_capture_button): _capture_button.grab_focus()
	_capture_button = null

func _input(event: InputEvent) -> void:
	if not hud.help_visible() or capture_action.is_empty(): return
	# Capture precedes all GUI shortcuts; the chosen key cannot also click a
	# button, close help, cast, move or save. Release events are swallowed too.
	get_viewport().set_input_as_handled()
	if not event.is_pressed() or event.is_echo(): return
	if event is InputEventKey and (event.keycode == KEY_ESCAPE or event.physical_keycode == KEY_ESCAPE):
		cancel_capture()
		refresh()
		return
	if not (event is InputEventKey or event is InputEventMouseButton): return
	var error := preferences.rebind(capture_action, event)
	if error.is_empty():
		cancel_capture()
		refresh()
	else: status.text = error

func _reset() -> void:
	cancel_capture()
	preferences.reset_defaults()
	refresh()
