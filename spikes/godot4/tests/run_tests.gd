extends SceneTree
## Headless unit tests, run with:
##   godot --headless --path spikes/godot4 --script tests/run_tests.gd
## Exits non-zero on any failure. Frame-dependent behaviour (physics,
## placement raycasts) is covered by tests/integration.tscn instead.

var failures := 0
var checks := 0


func check(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: %s" % label)


func _initialize() -> void:
	_test_grid()
	_test_inventory()
	_test_tuning()
	_test_resource_node()
	_test_scene_instantiation()

	print("%d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)


func _test_grid() -> void:
	var grid := 1.0
	check(WroughtwildGrid.snap_to_cell_center(Vector3(0.1, 0.2, 0.3), grid) == Vector3(0.5, 0.5, 0.5),
		"grid: origin cell")
	check(WroughtwildGrid.snap_to_cell_center(Vector3(-0.1, -1.7, 0.0), grid) == Vector3(-0.5, -1.5, 0.5),
		"grid: negative coordinates")
	check(WroughtwildGrid.snap_to_cell_center(Vector3(0.5, 0.5, 0.5), grid) == Vector3(0.5, 0.5, 0.5),
		"grid: snapping is idempotent")
	check(WroughtwildGrid.placement_cell_center(Vector3(0.5, 1.0, 0.5), Vector3.UP, grid) == Vector3(0.5, 1.5, 0.5),
		"grid: face placement selects adjacent cell")


func _test_inventory() -> void:
	var inventory: WroughtwildInventory = WroughtwildInventory.new()
	check(inventory.get_count(&"wood") == 0, "inventory: starts empty")
	inventory.add_material(&"wood", 5)
	check(inventory.get_count(&"wood") == 5, "inventory: add")
	check(not inventory.consume_material(&"wood", 6), "inventory: refuses overdraw")
	check(inventory.get_count(&"wood") == 5, "inventory: overdraw consumes nothing")
	check(inventory.consume_material(&"wood", 3), "inventory: consume")
	check(inventory.get_count(&"wood") == 2, "inventory: count after consume")
	inventory.add_material(&"wood", -4)
	check(inventory.get_count(&"wood") == 2, "inventory: negative add ignored")
	inventory.free()


func _test_tuning() -> void:
	# The autoload is not instantiated in --script mode; test the class directly.
	var tuning: Node = load("res://scripts/tuning.gd").new()
	check(tuning.load_crafting_tuning(), "tuning: crafting.json loads from repo checkout")
	check(tuning.loaded, "tuning: loaded flag set")
	check(tuning.recipe_count >= 2, "tuning: recipes present")
	check(tuning.recipe_ids.has("smelt_iron"), "tuning: smelt_iron recipe present")
	check(tuning.recipe_ids.has("iron_fittings"), "tuning: iron_fittings recipe present")
	check(absf(tuning.salvage_return_fraction - 0.5) < 0.000001, "tuning: salvage fraction read")
	tuning.free()


func _test_resource_node() -> void:
	var node: ResourceNode = load("res://scenes/resource_node.tscn").instantiate()
	node.remaining_units = 5
	node.units_per_harvest = 2
	check(node.harvest() == 2, "resource: harvest grants units_per_harvest")
	check(node.remaining_units == 3, "resource: units deplete")
	check(node.harvest() == 2, "resource: second harvest")
	check(node.harvest() == 1, "resource: final partial harvest")
	check(node.harvest() == 0, "resource: depleted node grants nothing")
	node.free()


func _test_scene_instantiation() -> void:
	# The whole spike scene must instantiate without errors. @onready wiring
	# is not exercised here (ready is deferred in --script mode); the
	# integration test covers it inside a running tree.
	var scene: Node = load("res://scenes/spike_valley.tscn").instantiate()
	get_root().add_child(scene)
	var player: WroughtwildPlayer = scene.get_node("Player")
	check(player != null, "scene: player present")
	check(player.get_node("Placement") is GridPlacement, "scene: placement component present")
	check(player.get_node("Inventory") is WroughtwildInventory, "scene: inventory component present")
	check(scene.get_node("IronNode").material_family == &"iron_ore",
		"scene: per-instance material family override applies")
	check(scene.get_node("WoodNode1").material_family == &"wood",
		"scene: default material family")
	get_root().remove_child(scene)
	scene.free()
