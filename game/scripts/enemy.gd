class_name Enemy
extends CharacterBody3D
## A world enemy. Its numbers (life, damage, cadence) come from the sim's
## enemy definition and its movement, ranges and wind-up from the sim's
## realtime table (ADR-0003). It never computes damage: when an attack lands
## it hands the raw hit to the player's combat component, which asks the sim
## what actually gets through.

signal died(enemy: Enemy)

@export var enemy_id: StringName = &"ember_whelp"

var display_name := ""
var behaviour := "melee"
var max_life := 1.0
var life := 1.0
var damage := 0.0
var damage_type := "physical"
var move_speed := 3.0
var attack_range := 1.5
var preferred_distance := 0.0
var aggro_range := 10.0
var windup_seconds := 0.3
var attack_period_seconds := 1.0
## D-012 stupid-zombie chase: once aggroed, press until the player stays
## beyond give_up_distance for give_up_seconds. 0 = never gives up.
var give_up_distance := 0.0
var give_up_seconds := 2.5
var separation_radius := 1.1
var separation_strength := 3.0

## idle | chase | windup
var state := "idle"

var _windup_left := 0.0
var _attack_cooldown := 0.0
var _give_up_timer := 0.0
var _flash_left := 0.0
var _material: StandardMaterial3D
var _player: WroughtwildPlayer

@onready var _label: Label3D = $Label3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D


## Spawns an enemy of enemy_id at a world position under root.
static func spawn(root: Node, id: StringName, at: Vector3) -> Enemy:
	var scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = scene.instantiate()
	enemy.enemy_id = id
	root.add_child(enemy)
	enemy.global_position = at
	return enemy


func _ready() -> void:
	add_to_group("enemies")
	configure(load("res://scripts/sim.gd").shared())


func configure(sim: WroughtwildSim) -> void:
	var def: Dictionary = sim.enemy(enemy_id)
	if def.is_empty():
		push_error("Enemy: unknown enemy id %s" % enemy_id)
		return
	display_name = def["display_name"]
	behaviour = def["behaviour"]
	max_life = def["max_life"]
	life = max_life
	damage = def["damage"]
	damage_type = def["damage_type"]

	var rt: Dictionary = sim.realtime()
	var b: Dictionary = rt["behaviours"].get(behaviour, {})
	# The hastened weakness quickens both feet and attacks in real time.
	var speed_multiplier: float = sim.combat_mods()["enemy_speed_multiplier"]
	move_speed = b.get("move_speed_mps", 3.0) * speed_multiplier
	attack_range = b.get("attack_range_m", 1.5)
	preferred_distance = b.get("preferred_distance_m", 0.0)
	aggro_range = b.get("aggro_range_m", 10.0)
	windup_seconds = b.get("windup_seconds", 0.3)
	attack_period_seconds = def["attack_period_rounds"] * rt["round_seconds"] / speed_multiplier
	give_up_distance = b.get("give_up_distance_m", 0.0)
	var horde: Dictionary = rt.get("horde", {})
	give_up_seconds = horde.get("give_up_seconds", 2.5)
	separation_radius = horde.get("separation_radius_m", 1.1)
	separation_strength = horde.get("separation_strength_mps", 3.0)

	_material = StandardMaterial3D.new()
	match behaviour:
		"ranged": _material.albedo_color = Color(0.8, 0.15, 0.1)
		"fast": _material.albedo_color = Color(0.25, 0.3, 0.45)
		_: _material.albedo_color = Color(0.9, 0.45, 0.1)
	_mesh.material_override = _material
	_refresh_label()


func _refresh_label() -> void:
	if _label != null:
		_label.text = "%s  %d / %d" % [display_name, ceili(life), ceili(max_life)]


func _find_player() -> WroughtwildPlayer:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	return _player


func _horizontal_distance_to(target: Node3D) -> float:
	var a := global_position
	var b := target.global_position
	return Vector2(a.x - b.x, a.z - b.z).length()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0 and _material != null:
			_material.emission_enabled = false
	var player := _find_player()
	if player == null:
		move_and_slide()
		return

	var distance := _horizontal_distance_to(player)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var planar := Vector3.ZERO

	match state:
		"idle":
			if distance <= aggro_range:
				state = "chase"
				_give_up_timer = 0.0
		"chase":
			# D-012: no leash. The chase only ends when the player genuinely
			# leaves - staying beyond give_up_distance for give_up_seconds.
			if give_up_distance > 0.0 and distance > give_up_distance:
				_give_up_timer += delta
				if _give_up_timer >= give_up_seconds:
					state = "idle"
					_give_up_timer = 0.0
			else:
				_give_up_timer = 0.0
			if state == "chase":
				if distance <= attack_range and _attack_cooldown <= 0.0:
					state = "windup"
					_windup_left = windup_seconds
				else:
					planar = _chase_direction(player, distance) * move_speed
		"windup":
			_windup_left -= delta
			if _windup_left <= 0.0:
				# The hit only lands if the player is still in reach: walking
				# out of the wind-up is a legitimate dodge.
				if distance <= attack_range * 1.15:
					player.combat.take_hit(damage, damage_type, display_name)
				_attack_cooldown = attack_period_seconds
				state = "chase"

	# Separation steering: chasers shoulder each other apart, so a trained
	# horde forms a physical train instead of a stack of ghosts (D-012).
	if state != "idle":
		planar += _separation_push()

	velocity.x = planar.x
	velocity.z = planar.z
	if planar.length_squared() > 0.0001 and distance > 0.05:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	move_and_slide()


func _separation_push() -> Vector3:
	var push := Vector3.ZERO
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not (node is Enemy) or not is_instance_valid(node):
			continue
		var away: Vector3 = global_position - (node as Enemy).global_position
		away.y = 0.0
		var d := away.length()
		if d < 0.001 or d >= separation_radius:
			continue
		push += (away / d) * (1.0 - d / separation_radius)
	return push * separation_strength


func _chase_direction(player: Node3D, distance: float) -> Vector3:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return Vector3.ZERO
	to_player = to_player.normalized()
	if preferred_distance > 0.0:
		# Ranged: hold a firing distance, backing off when crowded.
		if distance > preferred_distance + 0.5:
			return to_player
		if distance < preferred_distance - 1.5:
			return -to_player
		return Vector3.ZERO
	return to_player


## Test hook: resolves an attack immediately, ignoring range and wind-up.
func force_attack() -> float:
	var player := _find_player()
	if player == null:
		return 0.0
	_attack_cooldown = attack_period_seconds
	state = "chase"
	return player.combat.take_hit(damage, damage_type, display_name)


func take_damage(amount: float) -> void:
	if life <= 0.0:
		return
	life = maxf(0.0, life - amount)
	_refresh_label()
	# Hit feedback: a brief white-hot flash. Taking damage also wakes the
	# enemy - shooting a distant mob pulls it (D-012 stray-pull).
	if _material != null:
		_material.emission_enabled = true
		_material.emission = Color(1.0, 1.0, 0.9)
		_material.emission_energy_multiplier = 1.6
		_flash_left = 0.12
	if state == "idle":
		state = "chase"
		_give_up_timer = 0.0
	if life <= 0.0:
		died.emit(self)
		remove_from_group("enemies")
		queue_free()
