class_name Sandpit
extends Node3D
## The Wave 1 open world. Builds everything from the sim's seed-generated
## world map: blocky biome terrain, scattered resource nodes, dormant mob
## packs, the trial gate far out in the wastes and the prospector's order
## board at the spawn clearing. You start with nothing; the first workbench
## is hand-crafted from gathered wood (see docs/prototype/roadmap-waves.md).

const TRIAL_GATE_SCENE := preload("res://scenes/trial_gate.tscn")
const ORDER_BOARD_SCENE := preload("res://scenes/order_board.tscn")

## The world to generate; matches worldgen.json's default_seed on a new game
## and is overwritten by saves so a loaded game rebuilds its own world.
@export var world_seed: int = 1

@onready var terrain: Terrain = $Terrain
@onready var mob_packs: MobPacks = $MobPacks
## Base threat as pressure (D-018): nests on the fringe of the player's home.
var encroachment: Encroachment
@onready var mood: BiomeMood = $Mood
@onready var player: WroughtwildPlayer = $Player


func _ready() -> void:
	_build_world(world_seed)


func _sim() -> WroughtwildSim:
	return player.inventory.get_sim()


func _build_world(seed_value: int) -> void:
	world_seed = seed_value
	terrain.build(_sim(), seed_value)
	if terrain.map.is_empty():
		return
	mob_packs.setup(terrain, seed_value)
	if encroachment == null:
		encroachment = Encroachment.new()
		encroachment.name = "Encroachment"
		add_child(encroachment)
	encroachment.setup(mob_packs, seed_value)

	var spawn := terrain.surface_position(terrain.map["spawn_x"], terrain.map["spawn_z"])
	player.global_position = spawn + Vector3(0, 1.2, 0)
	player.spawn_position = player.global_position
	player.velocity = Vector3.ZERO
	# The art direction's mood dial (D-013): light follows the biome.
	mood.setup(terrain, $WorldEnvironment.environment, $Sun)

	_replace_named(TRIAL_GATE_SCENE, "TrialGate",
		terrain.surface_position(terrain.map["gate_x"], terrain.map["gate_z"]))
	var board := _replace_named(ORDER_BOARD_SCENE, "OrderBoard", spawn + Vector3(4.0, 0.0, 3.0))
	board.look_at(spawn + Vector3(0.0, board.global_position.y - spawn.y, 0.0), Vector3.UP)


func _replace_named(scene: PackedScene, node_name: String, at: Vector3) -> Node3D:
	var existing := get_node_or_null(node_name)
	if existing != null:
		remove_child(existing)
		existing.free()
	var node: Node3D = scene.instantiate()
	node.name = node_name
	add_child(node)
	node.global_position = at
	return node


## SaveManager hook: a loaded save carries its own seed; rebuild the world
## when it differs. Placed blocks and stations are restored by the save
## after this runs, so nothing dynamic is lost.
func apply_world_seed(seed_value: int) -> void:
	if seed_value == world_seed:
		return
	_build_world(seed_value)
