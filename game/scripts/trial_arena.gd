class_name TrialArena
extends Node3D
## The greybox room every trial encounter is fought in. Rooms are authored
## by data (trial.json), so one arena rearranged per room is enough for the
## slice; geometry variety is a later concern. Walls on all four sides have
## collision: a retreating archer or a shoved hound must never leave the
## room, because a room whose last enemy fell into the void can never clear.

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var boss_spawn: Marker3D = $BossSpawn

## Half-width of the square floor, metres.
const HALF_SIZE := 14.0


## True when a point is on or above the arena floor (with slack for the
## floor's thickness and a jump).
func contains(point: Vector3) -> bool:
	var local := to_local(point)
	return local.y > -3.0 and absf(local.x) <= HALF_SIZE + 1.0 and absf(local.z) <= HALF_SIZE + 1.0


## The nearest floor point to a position that left the room.
func clamp_to_floor(point: Vector3) -> Vector3:
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
