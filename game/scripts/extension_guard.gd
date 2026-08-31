extends Node
## Autoload "ExtensionGuard": makes a broken rules setup impossible to miss.
##
## The whole interactive game (harvest, forge, placement, trial) runs through
## the WroughtwildSim GDExtension. When the compiled library is missing, every
## script typed against WroughtwildSim silently fails to load and the world
## degrades to "I can walk around but nothing is interactable". When the
## library loads but data/tuning cannot be found, interactions no-op the same
## way. This script deliberately never references the WroughtwildSim type, so
## it always parses and can report both failures on screen.

const BUILD_HELP := """WROUGHTWILD - RULES EXTENSION NOT LOADED

The compiled rules library (WroughtwildSim GDExtension) was not found,
so nothing in the world can be interacted with.

Fix (from the repository root, once per checkout):

  git submodule update --init
  cmake -S game/extensions/wroughtwild_sim -B build/gdext -DCMAKE_BUILD_TYPE=Release
  cmake --build build/gdext -j
      (Windows/MinGW: add  -G "MinGW Makefiles"  to the first cmake command)

Then restart the game. Full steps: game/README.md."""

const TUNING_HELP := """WROUGHTWILD - TUNING DATA NOT LOADED

The rules extension is built and loaded, but data/tuning could not be
read, so every interaction is disabled.

Expected location: the data/tuning directory of the repository,
one level above the game/ project (%s).

Run the game from a full repository checkout (godot --path game),
not from a copied-out game folder.

Details: %s"""


func _ready() -> void:
	# Sim's own autoload _init runs before this _ready, so its state is final.
	if not ClassDB.class_exists("WroughtwildSim"):
		_fail(BUILD_HELP)
		return
	var sim_autoload := get_tree().root.get_node_or_null("Sim")
	if sim_autoload == null:
		_fail(BUILD_HELP)
		return
	if not sim_autoload.loaded:
		var details: String = "unknown"
		var sim_object: Object = sim_autoload.get("sim")
		if sim_object != null and sim_object.has_method("last_error"):
			details = str(sim_object.call("last_error"))
		_fail(TUNING_HELP % [sim_autoload.call("get_tuning_directory"), details])


func _fail(message: String) -> void:
	push_error(message)
	printerr(message)
	if DisplayServer.get_name() == "headless":
		return

	var layer := CanvasLayer.new()
	layer.layer = 100
	add_child(layer)

	var backdrop := ColorRect.new()
	backdrop.color = Color(0.08, 0.02, 0.02, 0.92)
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(backdrop)

	var label := Label.new()
	label.text = message
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.7))
	layer.add_child(label)
