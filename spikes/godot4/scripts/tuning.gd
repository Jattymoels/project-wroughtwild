extends Node
## Autoload "Tuning": loads the engine-neutral tuning files from data/tuning
## at startup, proving the "core tuning values are externalised from game
## logic" acceptance criterion inside Godot. Only what the spike needs is
## exposed; full rules live in the portable sim/ library.

var loaded := false
var recipe_count := 0
var salvage_return_fraction := 0.0


func _ready() -> void:
	load_crafting_tuning()


## Resolves the repository's data/tuning directory. The spike project lives
## at spikes/godot4/, so tuning sits two levels above the project root.
static func get_tuning_directory() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../../data/tuning")


## Parses crafting.json; returns false (and logs) when missing or invalid.
func load_crafting_tuning() -> bool:
	loaded = false

	var path := get_tuning_directory().path_join("crafting.json")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("Cannot read tuning file: %s" % path)
		return false

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid JSON in tuning file: %s" % path)
		return false

	var root: Dictionary = parsed
	if not (root.get("recipes") is Array) or not (root.get("salvage_return_fraction") is float):
		push_warning("Missing expected fields in %s" % path)
		return false

	recipe_count = (root["recipes"] as Array).size()
	salvage_return_fraction = root["salvage_return_fraction"]
	loaded = true
	print("Loaded crafting tuning: %d recipes" % recipe_count)
	return true
