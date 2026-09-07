class_name AudioPreferences
extends RefCounted
## Device preference, deliberately separate from any world/checkpoint ownership.
signal changed
const PATH := "user://audio-preferences.cfg"
var path := PATH
var ambience_level := 1.0
var ambience_muted := false
var last_error := OK
var _config := ConfigFile.new()

func load_saved() -> void:
	ambience_level = 1.0
	ambience_muted = false
	_config = ConfigFile.new()
	last_error = _config.load(path)
	if last_error == ERR_FILE_NOT_FOUND: last_error = OK
	if last_error != OK: return
	var level: Variant = _config.get_value("audio", "ambience_level", 1.0)
	var muted: Variant = _config.get_value("audio", "ambience_muted", false)
	if (level is float or level is int) and is_finite(float(level)):
		ambience_level = clampf(float(level), 0.0, 1.0)
	if muted is bool: ambience_muted = muted

func gain() -> float:
	return 0.0 if ambience_muted else ambience_level

func set_ambience(level: float, muted: bool) -> void:
	if not is_finite(level): return
	ambience_level = clampf(level, 0.0, 1.0)
	ambience_muted = muted
	_config.set_value("audio", "ambience_level", ambience_level)
	_config.set_value("audio", "ambience_muted", ambience_muted)
	last_error = _config.save(path)
	changed.emit()
