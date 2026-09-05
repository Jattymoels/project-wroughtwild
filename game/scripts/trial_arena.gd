class_name TrialArena
extends Node3D
## Hosts the current connected Forge floor. Collision, route seals, rewards
## and navigation are built together by ForgeDungeon. The original small
## arena is retained for the established economy/physics regression fixtures.

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var boss_spawn: Marker3D = $BossSpawn

## Half-width of the square floor, metres.
const HALF_SIZE := 14.0

var dungeon: ForgeDungeon

func build_floor(layout: Dictionary, floor_index: int) -> ForgeDungeon:
	clear_floor()
	for child in get_children():
		if child is Marker3D: continue
		if child is Node3D: child.visible = false
		_disable_collision(child, true)
	dungeon = ForgeDungeon.new()
	add_child(dungeon)
	dungeon.build(layout, floor_index)
	player_spawn.position = dungeon.entry
	return dungeon

func clear_floor() -> void:
	if is_instance_valid(dungeon):
		remove_child(dungeon)
		dungeon.queue_free()
	dungeon = null

func _disable_collision(node: Node, disabled: bool) -> void:
	if node is CollisionShape3D: node.set_deferred("disabled", disabled)
	for child in node.get_children(): _disable_collision(child, disabled)

func restore_legacy() -> void:
	clear_floor()
	for child in get_children():
		if child is Node3D: child.visible = true
		_disable_collision(child, false)
	player_spawn.position = Vector3(0, .5, 9)


## True when a point is on or above the arena floor (with slack for the
## floor's thickness and a jump).
func contains(point: Vector3) -> bool:
	if is_instance_valid(dungeon): return dungeon.contains_world(point)
	var local := to_local(point)
	return local.y > -3.0 and absf(local.x) <= HALF_SIZE + 1.0 and absf(local.z) <= HALF_SIZE + 1.0


## The nearest floor point to a position that left the room.
func clamp_to_floor(point: Vector3) -> Vector3:
	if is_instance_valid(dungeon): return dungeon.nearest_floor(point)
	var local := to_local(point)
	local.x = clampf(local.x, -HALF_SIZE + 1.5, HALF_SIZE - 1.5)
	local.z = clampf(local.z, -HALF_SIZE + 1.5, HALF_SIZE - 1.5)
	local.y = 0.5
	return to_global(local)


func _ready() -> void:
	add_to_group("trial_arena")


## Spawn points for an encounter of `count` ordinary enemies, spread in an
## arc in front of the player spawn.
func enemy_spawn_points(count: int) -> Array:
	var points: Array = []
	var centre := player_spawn.global_position + Vector3(0, 0, -7)
	for i in count:
		var angle := PI * (0.25 + 0.5 * float(i) / float(maxi(count - 1, 1)))
		points.append(centre + Vector3(cos(angle) * 4.0, 0.0, -sin(angle) * 2.0))
	return points
