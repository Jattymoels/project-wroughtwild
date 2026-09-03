extends Node
## World-feel test, run with:
##   godot --headless --path game res://tests/feel.tscn
## Drives the pickup loop through real physics frames: scattered drops rest
## where they fall, vacuum into a player who walks near, and grant through
## the sim only on absorb; harvesting pops chips, punches the node's scale
## and shrinks it away on depletion; the aim probe names the target; jump
## still fires through the buffered path. Quits non-zero on failure.

const PLAYER_SCENE := preload("res://scenes/player.tscn")
const RESOURCE_NODE_SCENE := preload("res://scenes/resource_node.tscn")

var _player: WroughtwildPlayer
var _sim: WroughtwildSim
var _frame := 0
var _failures := 0
var _checks := 0

var _wood_start := 0
var _iron_start := 0
var _tree: ResourceNode


func check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: %s" % label)


func _ready() -> void:
	var floor_body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(120, 1, 120)
	collider.shape = shape
	floor_body.add_child(collider)
	add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.global_position = Vector3(0, 1.1, 0)
	_sim = _player.inventory.get_sim()


func _pickup_count() -> int:
	return get_tree().get_nodes_in_group("pickups").size()


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			_wood_start = _sim.material_count("wood")
			_iron_start = _sim.material_count("iron_ore")
			# Drops 6 m out: beyond the magnet, so they must rest and wait.
			var spawned: Array = Pickup.scatter(self, Vector3(0, 0.8, -6.0),
				{"wood": 3, "iron_ore": 2}, 42, 0.0)
			check(spawned.size() == 2 and _pickup_count() == 2,
				"pickup: one chip per material family scattered")
		90:
			check(_pickup_count() == 2, "pickup: chips rest out of magnet range")
			check(_sim.material_count("wood") == _wood_start,
				"pickup: nothing granted until absorbed")
			# Walk into magnet range.
			_player.global_position = Vector3(0, 1.1, -4.5)
			_player.velocity = Vector3.ZERO
		150:
			check(_pickup_count() == 0, "pickup: nearby chips vacuumed into the player")
			check(_sim.material_count("wood") == _wood_start + 3
				and _sim.material_count("iron_ore") == _iron_start + 2,
				"pickup: absorb granted the materials through the sim")
			check(_player.hud._pickup_label.text != "", "pickup: HUD ticker shows the gain")
			_player.global_position = Vector3(0, 1.1, 0)
			_player.velocity = Vector3.ZERO
			_player.rotation.y = 0.0
			_player.spring_arm.rotation.x = 0.0
			_tree = RESOURCE_NODE_SCENE.instantiate()
			_tree.material_family = &"wood"
			_tree.remaining_units = 4
			_tree.units_per_harvest = 2
			_tree.visual = &"tree"
			_tree.position = Vector3(0, 0, -2.5)
			add_child(_tree)
		160:
			var probe: Dictionary = _player.aim_probe()
			check(probe["state"] == "interact" and probe["target"] == _tree,
				"aim: probe sees the tree in front")
			check(String(probe["label"]).contains("wood"), "aim: probe label names the material")
			_player.interact()
			check(_tree.remaining_units == 2, "harvest: two units taken")
			check(_pickup_count() == 1, "harvest: yield pops out as a chip")
			check(not _tree.scale.is_equal_approx(Vector3.ONE),
				"harvest: node scale punched to show wear")
		220:
			check(_sim.material_count("wood") == _wood_start + 5,
				"harvest: chip vacuumed in and granted (+2 wood)")
			_player.interact()
			check(_tree.remaining_units == 0, "harvest: node emptied")
		280:
			check(not is_instance_valid(_tree), "harvest: depleted node shrinks away and frees")
			check(_sim.material_count("wood") == _wood_start + 7,
				"harvest: final yield granted (+2 wood)")
		290:
			# Feed the jump buffer directly (headless input frame-accounting
			# makes a simulated just-pressed unreliable); the buffered path
			# with coyote time is what real input feeds.
			_player._jump_buffer_left = 0.2
		292:
			check(_player.velocity.y > 3.0, "jump: buffered jump fires from the floor")
		300:
			# Step-up: a row of half cubes ahead is a step, not a wall - the
			# player walks up onto it (stairs and half cubes, building slice 4).
			_player.global_position = Vector3(0, 1.1, 0)
			_player.velocity = Vector3.ZERO
			_player.rotation.y = 0.0
			for z in range(-6, -2):
				for x in [-1, 0]:
					_player.placement.place_piece({"kind": "volume", "axis": 0, "cell": Vector3i(x, 0, z)},
						&"half_cube", &"wood")
			_player.test_walk = Vector2(0, -1)
		322:
			check(_player.global_position.y > 1.45 and _player.global_position.z < -1.0,
				"step: the player walked up onto the half cubes (y %.2f, z %.2f)" % [
					_player.global_position.y, _player.global_position.z])
			_player.test_walk = Vector2.ZERO
		330:
			print("%d checks, %d failures" % [_checks, _failures])
			get_tree().quit(0 if _failures == 0 else 1)
