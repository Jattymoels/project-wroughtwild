class_name MobPacks
extends Node
## Roaming mob packs of the sandpit. Each pack from the sim's world map is a
## dormant spawn point; when the player first comes near, its enemies appear
## and hold their ground (aggro is the enemies' own behaviour). Kills roll
## the sim's loot tables and scatter physical pickups where the mob fell -
## fighting always pays into the survival economy, and walking through
## your battlefield hoovers up the reward.

## How close the player must come before a pack takes shape. Far enough to
## feel discovered, near enough that distant packs cost nothing.
const ACTIVATION_RANGE_M := 28.0
const CHECK_SECONDS := 0.4

var terrain: Terrain
var packs: Array = []          # {enemies, x, z, spawned}
var world_seed := 0
var _kill_counter := 0
var _check_timer := 0.0


func setup(from_terrain: Terrain, seed_value: int) -> void:
	terrain = from_terrain
	world_seed = seed_value
	packs = []
	for pack in terrain.map.get("packs", []):
		packs.append({
			"enemies": pack["enemies"],
			"x": pack["x"],
			"z": pack["z"],
			"spawned": false,
		})


func _physics_process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_SECONDS
	var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player == null or terrain == null:
		return
	for pack in packs:
		if pack["spawned"]:
			continue
		var at := terrain.surface_position(pack["x"], pack["z"])
		if at.distance_to(player.global_position) <= ACTIVATION_RANGE_M:
			_spawn_pack(pack, at)


func _spawn_pack(pack: Dictionary, at: Vector3) -> void:
	pack["spawned"] = true
	var ids: PackedStringArray = pack["enemies"]
	for i in ids.size():
		var angle := TAU * float(i) / float(maxi(ids.size(), 1))
		var offset := Vector3(cos(angle), 0.5, sin(angle)) * 1.6
		var enemy := Enemy.spawn(get_parent(), StringName(ids[i]), at + offset)
		enemy.died.connect(_on_enemy_died)


func _on_enemy_died(enemy: Enemy) -> void:
	_kill_counter += 1
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	# Per-kill deterministic seed: replaying a save replays its luck. The
	# three loot kinds (materials, gear, pages) roll independent streams off
	# this one seed inside the sim.
	var kill_seed := world_seed + _kill_counter * 7919
	var at := enemy.global_position
	var from := at + Vector3(0, 0.5, 0)
	var floor_y := at.y + 0.02
	var drops: Dictionary = sim.enemy_loot(enemy.enemy_id, kill_seed)
	if not drops.is_empty():
		Pickup.scatter(get_parent(), from, drops, kill_seed, floor_y)
	# Gear: one pickup per kill, previewing the roll; the sim re-rolls the
	# identical item on claim, so the pickup remembers only the kill.
	var gear: Array = sim.enemy_gear_loot(enemy.enemy_id, kill_seed)
	if not gear.is_empty():
		Pickup.drop_gear(get_parent(), from, enemy.enemy_id, kill_seed, gear[0], floor_y)
	var page: String = sim.enemy_skill_page(enemy.enemy_id, kill_seed)
	if page != "":
		var view: Dictionary = sim.combat_skill(page)
		Pickup.drop_page(get_parent(), from, page, view.get("display_name", page), floor_y)
