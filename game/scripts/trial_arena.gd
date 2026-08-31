class_name TrialArena
extends Node3D
## The greybox room every trial encounter is fought in. Rooms are authored
## by data (trial.json), so one arena rearranged per room is enough for the
## slice; geometry variety is a later concern.

@onready var player_spawn: Marker3D = $PlayerSpawn
@onready var boss_spawn: Marker3D = $BossSpawn


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
