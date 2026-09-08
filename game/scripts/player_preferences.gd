class_name PlayerPreferences
extends AudioPreferences
signal bindings_changed
## Extend the existing device file in place; old ambience preferences and
## unrelated sections survive. No world/checkpoint serializer references this.
const DATA_PATH := "res://settings.json"
var definitions: Array = []
var actions: Dictionary = {}
var values: Dictionary = {}
var bindings: Dictionary = {}
var binding_warning := ""
var _launch_mode := DisplayServer.WINDOW_MODE_WINDOWED
var _launch_vsync := DisplayServer.VSYNC_ENABLED

func _init() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(DATA_PATH))
	definitions = data.options
	actions = data.actions
	if DisplayServer.get_name() != "headless":
		_launch_mode = DisplayServer.window_get_mode()
		_launch_vsync = DisplayServer.window_get_vsync_mode()

func load_saved() -> void:
	super.load_saved()
	values.clear()
	for definition in definitions:
		values[definition.id] = _validated(definition, _config.get_value("comfort", definition.id, definition.default))
	bindings = default_bindings()
	binding_warning = ""
	var candidate := bindings.duplicate(true)
	for action in actions:
		var record: Variant = _config.get_value("bindings", action, candidate[action])
		if not _valid_record(record):
			binding_warning = "Some saved controls were invalid. Default controls restored."
			break
		candidate[action] = record
	if binding_warning.is_empty() and not _unique(candidate):
		binding_warning = "Saved controls conflicted. Default controls restored."
	if binding_warning.is_empty(): bindings = candidate
	else:
		# Keep the recovered map on the next deliberate save as well; an invalid
		# stale record must not discard the player's subsequent valid rebinding.
		for action in actions: _config.set_value("bindings", action, bindings[action])
	apply_bindings()

func default_bindings() -> Dictionary:
	var result := {}
	for action in actions:
		var entry: Dictionary = ProjectSettings.get_setting("input/" + action)
		result[action] = record_for(entry.events[0])
	return result

func _validated(definition: Dictionary, value: Variant) -> Variant:
	if definition.has("choices"):
		return value if value is String and value in definition.choices else definition.default
	if definition.default is bool: return value if value is bool else definition.default
	if (value is float or value is int) and is_finite(float(value)):
		return clampf(float(value), float(definition.min), float(definition.max))
	return definition.default

func set_option(id: String, value: Variant) -> void:
	for definition in definitions:
		if definition.id != id: continue
		values[id] = _validated(definition, value)
		_config.set_value("comfort", id, values[id])
		_save()
		return

func apply_device() -> void:
	var master := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_linear(master, float(values.master_level))
	AudioServer.set_bus_mute(master, bool(values.master_muted) or float(values.master_level) == 0.0)
	if DisplayServer.get_name() == "headless": return
	var mode: int = _launch_mode
	if values.window_mode == "windowed": mode = DisplayServer.WINDOW_MODE_WINDOWED
	elif values.window_mode == "fullscreen": mode = DisplayServer.WINDOW_MODE_FULLSCREEN
	if DisplayServer.window_get_mode() != mode: DisplayServer.window_set_mode(mode)
	var vsync: int = _launch_vsync
	if values.vsync == "on": vsync = DisplayServer.VSYNC_ENABLED
	elif values.vsync == "off": vsync = DisplayServer.VSYNC_DISABLED
	if DisplayServer.window_get_vsync_mode() != vsync: DisplayServer.window_set_vsync_mode(vsync)

func rebind(action: String, event: InputEvent) -> String:
	if not actions.has(action): return "Unknown action."
	var record := record_for(event)
	if not _valid_record(record): return "Use one key or mouse button. Escape cancels; chords and wheel inputs are not supported."
	for other in bindings:
		if other != action and bindings[other] == record:
			return "Already used by %s. Change that control first." % actions[other]
	bindings[action] = record
	_config.set_value("bindings", action, record)
	binding_warning = ""
	apply_bindings()
	_save()
	return ""

func apply_bindings() -> void:
	for action in bindings:
		Input.action_release(action)
		InputMap.action_erase_events(action)
		InputMap.action_add_event(action, event_for(bindings[action]))
	# One contextual action, deliberately kept in sync with the old alias.
	Input.action_release("blow_horn")
	InputMap.action_erase_events("blow_horn")
	InputMap.action_add_event("blow_horn", event_for(bindings.remove_block))
	bindings_changed.emit()

func reset_defaults() -> void:
	for definition in definitions:
		values[definition.id] = definition.default
		_config.set_value("comfort", definition.id, definition.default)
	bindings = default_bindings()
	for action in actions: _config.set_value("bindings", action, bindings[action])
	apply_bindings()
	binding_warning = ""
	# The inherited setter saves both old audio keys and the extended sections.
	set_ambience(1.0, false)

func _save() -> void:
	last_error = _config.save(path)
	changed.emit()

static func record_for(event: InputEvent) -> Dictionary:
	if event is InputEventKey:
		var code: int = event.physical_keycode if event.physical_keycode else event.keycode
		if (event.ctrl_pressed and code != KEY_CTRL) or (event.alt_pressed and code != KEY_ALT) or (event.shift_pressed and code != KEY_SHIFT) or (event.meta_pressed and code != KEY_META): return {}
		return {"key": code}
	if event is InputEventMouseButton and not (event.ctrl_pressed or event.alt_pressed or event.shift_pressed or event.meta_pressed):
		return {"mouse": event.button_index}
	return {}

static func event_for(record: Dictionary) -> InputEvent:
	if record.has("key"):
		var key := InputEventKey.new()
		key.physical_keycode = int(record.key)
		return key
	var mouse := InputEventMouseButton.new()
	mouse.button_index = int(record.mouse)
	return mouse

static func _valid_record(record: Variant) -> bool:
	if not record is Dictionary or record.size() != 1: return false
	if record.has("mouse"): return record.mouse is int and record.mouse in [1, 2, 3, 8, 9]
	if not record.has("key") or not record.key is int: return false
	var code: int = record.key
	if code == KEY_ESCAPE or code == KEY_NONE: return false
	if not ((code >= KEY_SPACE and code <= KEY_ASCIITILDE) or (code >= KEY_TAB and code <= KEY_LAUNCHF)): return false
	# A round trip rejects unknown key codes without accepting serialized objects.
	return OS.find_keycode_from_string(OS.get_keycode_string(code)) == code

static func _unique(candidate: Dictionary) -> bool:
	var seen := []
	for record in candidate.values():
		if record in seen: return false
		seen.append(record)
	return true
