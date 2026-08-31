extends Node
## Autoload "Sim": the single gateway from the engine layer into the
## engine-neutral rules library (sim/, bound by the wroughtwild_sim
## GDExtension). Loads data/tuning at startup. Scripts route every economy
## change through `sim` instead of re-implementing rules (game/README.md).

var sim: WroughtwildSim = WroughtwildSim.new()
var loaded := false


func _init() -> void:
	loaded = sim.load_tuning(get_tuning_directory())
	if loaded:
		print("Sim tuning loaded: %d recipes, %d shapes" % [sim.recipe_ids().size(), sim.shape_ids().size()])
	else:
		push_error("Sim tuning failed to load: %s" % sim.last_error())


## Resolves the repository's data/tuning directory. The game project lives
## at game/, so tuning sits one level above the project root.
static func get_tuning_directory() -> String:
	return ProjectSettings.globalize_path("res://").path_join("../data/tuning")


## The shared rules instance when the autoload is in the tree, otherwise a
## fresh, fully loaded one (headless --script tests instantiate no autoloads,
## and isolated instances keep those tests independent of each other).
static func shared() -> WroughtwildSim:
	var loop := Engine.get_main_loop()
	if loop is SceneTree:
		var node := (loop as SceneTree).root.get_node_or_null("Sim")
		if node != null:
			return node.sim
	var fresh := WroughtwildSim.new()
	fresh.load_tuning(get_tuning_directory())
	return fresh
