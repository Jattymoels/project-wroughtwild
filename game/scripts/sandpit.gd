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
## Eras (D-019): the world's state, polled from the sim; a change reveals
## the era's nodes, shifts the light and tells the story.
var _era_index := 0
var _era_poll := 0.0
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
	# Life beyond hostiles: the peddler by the board, birds over the trees.
	var old_peddler := get_node_or_null("Peddler")
	if old_peddler != null:
		old_peddler.free()
	var peddler := Peddler.new()
	peddler.name = "Peddler"
	add_child(peddler)
	peddler.global_position = spawn + Vector3(-4.0, 0.0, 3.5)
	peddler.look_at(spawn + Vector3(0.0, 0.0, 0.0), Vector3.UP)
	for flock in get_tree().get_nodes_in_group("flocks"):
		flock.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 6:
		var fx := int(spawn.x) + rng.randi_range(-30, 30)
		var fz := int(spawn.z) + rng.randi_range(-30, 30)
		var flock := Flock.spawn(self, terrain.surface_position(clampi(fx, 1, terrain.map["width"] - 2), clampi(fz, 1, terrain.map["height"] - 2)), seed_value + i)
		flock.add_to_group("flocks")


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


func _physics_process(delta: float) -> void:
	_era_poll -= delta
	if _era_poll > 0.0 or terrain.map.is_empty():
		return
	_era_poll = 1.0
	var era: Dictionary = _sim().era()
	var index := int(era.get("index", 1))
	if _era_index == 0:
		_era_index = index
		mood.set_era(index)
		return
	if index == _era_index:
		return
	_era_index = index
	var revealed := terrain.reveal_era(index)
	mood.set_era(index)
	player.hud.notify("Era %d: %s. %s" % [index, era["display_name"], era["story"]])
	if revealed > 0:
		player.hud.notify("The strata have cracked: %d new veins surfaced in the deep." % revealed)


## SaveManager hook: a loaded save carries its own seed; rebuild the world
## when it differs. Placed blocks and stations are restored by the save
## after this runs, so nothing dynamic is lost.
func apply_world_seed(seed_value: int) -> void:
	if seed_value == world_seed:
		return
	_build_world(seed_value)
