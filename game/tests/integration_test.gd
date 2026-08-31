extends Node
## In-engine integration test, run with:
##   godot --headless --path game res://tests/integration.tscn
## Instances the real spike scene and drives the placement loop across
## physics frames: preview validity (unaffordable -> red, affordable -> green),
## block placement consuming material, and removal with partial refund.
## Quits with a non-zero exit code on failure.

var _scene: Node3D
var _player: WroughtwildPlayer
var _frame := 0
var _failures := 0
var _checks := 0


func check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: %s" % label)


func _ready() -> void:
	_scene = (load("res://scenes/spike_valley.tscn") as PackedScene).instantiate()
	add_child(_scene)
	_player = _scene.get_node("Player")
	# Tilt the camera arm down so the view ray hits the floor within range,
	# and nudge the player off x = 0 so the ray does not graze a cell boundary.
	(_player.get_node("SpringArm3D") as SpringArm3D).rotation.x = -0.6
	_player.position.x = 0.3


func _count_placed_blocks() -> int:
	# Placement spawns blocks under the current scene root.
	var count := 0
	for child in get_tree().current_scene.get_children():
		if child is PlacedBlock:
			count += 1
	return count


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		2:
			# Build mode with an empty inventory: preview must show invalid.
			_player.placement.material_cost_per_block = 2
			_player.placement.set_build_mode_enabled(true)
		4:
			check(_player.placement.preview_visible, "integration: preview visible over floor")
			check(not _player.placement.preview_valid, "integration: unaffordable preview is invalid")
			check(not _player.placement.try_place_block(), "integration: invalid preview refuses placement")
			_player.inventory.add_material(&"wood", 10)
		6:
			check(_player.placement.preview_valid, "integration: affordable free cell is valid")
			check(_player.placement.try_place_block(), "integration: placement succeeds")
			check(_player.inventory.get_count(&"wood") == 8, "integration: material consumed")
			check(_count_placed_blocks() == 1, "integration: block spawned into scene")
		8:
			# The placed block is now in the physics space and in the view ray.
			check(_player.placement.try_remove_block(), "integration: removal hits placed block")
			check(_player.inventory.get_count(&"wood") == 9,
				"integration: partial refund applied (floor(2 * 0.5) = 1)")
		10:
			check(_count_placed_blocks() == 0, "integration: removed block left the scene")
			print("%d checks, %d failures" % [_checks, _failures])
			get_tree().quit(0 if _failures == 0 else 1)
