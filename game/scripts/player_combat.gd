class_name PlayerCombat
extends Node
## The player's real-time combat: life, skill cooldown timers, the dash window
## and hit application. Every number (max life, damage per hit, mitigation)
## is asked of the sim; this node only decides when and whom (ADR-0003).

signal life_changed(life: float, max_life: float)
signal died

const AREA_SKILL := &"prototype_area_strike"
const HEAVY_SKILL := &"prototype_heavy_strike"
const DASH_SKILL := &"prototype_dash"

var player: WroughtwildPlayer
var sim: WroughtwildSim

var max_life := 1.0
var life := 1.0
var skills := {}     # skill id -> sim view (base_damage, cooldown_seconds, ...)
var cooldowns := {}  # skill id -> seconds remaining
var invulnerable_left := 0.0
var melee_reach := 2.0
var dash_invulnerable := 0.3
var dash_duration := 0.25
var fight_active := false
## Seeds each fight's damage stream; tests set a fixed seed for replay.
var fight_seed_source := RandomNumberGenerator.new()
var last_hit_dealt := 0.0
var last_hit_taken := 0.0

var _dash_left := 0.0
var _dash_velocity := Vector3.ZERO


func setup(in_player: WroughtwildPlayer, in_sim: WroughtwildSim) -> void:
	player = in_player
	sim = in_sim
	for id in sim.combat_skill_ids():
		skills[id] = sim.combat_skill(id)
		cooldowns[id] = 0.0
	var rt: Dictionary = sim.realtime()
	melee_reach = rt["player"]["melee_reach_m"]
	dash_invulnerable = rt["dash"]["invulnerable_seconds"]
	dash_duration = rt["dash"]["duration_seconds"]
	fight_seed_source.randomize()
	restore_life()


func restore_life() -> void:
	max_life = sim.derived_stats()["max_life"]
	life = max_life
	life_changed.emit(life, max_life)


func _physics_process(delta: float) -> void:
	for id in cooldowns:
		cooldowns[id] = maxf(0.0, cooldowns[id] - delta)
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	_dash_left = maxf(0.0, _dash_left - delta)
	if fight_active and alive_enemies().is_empty():
		fight_active = false


func is_ready(skill_id: StringName) -> bool:
	return cooldowns.get(skill_id, 1.0) <= 0.0


func cooldown_left(skill_id: StringName) -> float:
	return cooldowns.get(skill_id, 0.0)


## Horizontal velocity the player should adopt while a dash is in progress.
func dash_velocity() -> Vector3:
	return _dash_velocity if _dash_left > 0.0 else Vector3.ZERO


func alive_enemies() -> Array:
	var alive: Array = []
	for node in player.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is Enemy and node.life > 0.0:
			alive.append(node)
	return alive


func _ensure_fight() -> void:
	if not fight_active:
		fight_active = true
		sim.begin_fight(int(fight_seed_source.randi() & 0x7fffffff))


func _planar_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


func _spend(skill_id: StringName) -> void:
	cooldowns[skill_id] = skills[skill_id].get("cooldown_seconds", 1.0)


## Area strike: every living enemy inside the radius takes one hit. Returns
## how many were hit.
func use_area() -> int:
	if not is_ready(AREA_SKILL):
		return 0
	_spend(AREA_SKILL)
	var enemies := alive_enemies()
	if enemies.is_empty():
		return 0
	_ensure_fight()
	var isolated := enemies.size() == 1
	var radius: float = skills[AREA_SKILL]["base_area_radius"] * (1.0 + sim.derived_stats()["area_bonus"])
	if isolated:
		radius *= sim.combat_mods()["isolated_area_multiplier"]
	var hits := 0
	for enemy in enemies:
		if _planar_distance(enemy.global_position, player.global_position) <= radius:
			last_hit_dealt = sim.player_hit_damage(AREA_SKILL, isolated)
			enemy.take_damage(last_hit_dealt)
			hits += 1
	return hits


## Heavy strike: the nearest living enemy in front within melee reach.
func use_heavy() -> bool:
	if not is_ready(HEAVY_SKILL):
		return false
	_spend(HEAVY_SKILL)
	var target := _nearest_enemy_in_front(melee_reach)
	if target == null:
		return false
	_ensure_fight()
	last_hit_dealt = sim.player_hit_damage(HEAVY_SKILL, alive_enemies().size() == 1)
	target.take_damage(last_hit_dealt)
	return true


func _nearest_enemy_in_front(reach: float) -> Enemy:
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var best: Enemy = null
	var best_distance := INF
	for enemy in alive_enemies():
		var to_enemy: Vector3 = enemy.global_position - player.global_position
		to_enemy.y = 0.0
		var distance := to_enemy.length()
		if distance > reach or distance < 0.001:
			continue
		if forward.dot(to_enemy / distance) < 0.2:
			continue
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


## Dash: a burst forward with a short invulnerability window.
func use_dash() -> bool:
	if not is_ready(DASH_SKILL):
		return false
	_spend(DASH_SKILL)
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	_dash_velocity = forward * (skills[DASH_SKILL].get("distance", 4.0) / dash_duration)
	_dash_left = dash_duration
	invulnerable_left = dash_invulnerable
	return true


## An enemy's raw hit arrives here; the sim decides what gets through.
func take_hit(raw_damage: float, damage_type: String, _source_name := "") -> float:
	if invulnerable_left > 0.0 or life <= 0.0:
		return 0.0
	_ensure_fight()
	last_hit_taken = sim.enemy_hit_damage(raw_damage, damage_type)
	life = maxf(0.0, life - last_hit_taken)
	life_changed.emit(life, max_life)
	if life <= 0.0:
		died.emit()
	return last_hit_taken
