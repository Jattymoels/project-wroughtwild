class_name Boss
extends Enemy
## The Forge Tyrant. Numbers come from the sim's boss definition (life, claw,
## breath, periods) and the realtime boss table (speed, ranges, telegraph).
## Claws on its own cadence when in reach; on a slower schedule it inhales
## (the telegraph) and then breathes fire over a cone. Dashing through the
## telegraph, or being outside the cone, avoids the breath; resistance is
## what makes the hits you cannot avoid survivable.

var breath_damage := 0.0
var breath_damage_type := "fire"
var breath_period_seconds := 2.0
var breath_range := 9.0
var breath_cone_degrees := 70.0
var breath_telegraph_seconds := 1.0

## chase | windup | inhale
var _breath_timer := 0.0
var _telegraph_left := 0.0
var _base_material: StandardMaterial3D
var _telegraph_material: StandardMaterial3D


static func spawn_boss(root: Node, at: Vector3) -> Boss:
	var scene: PackedScene = load("res://scenes/boss.tscn")
	var boss: Boss = scene.instantiate()
	root.add_child(boss)
	boss.global_position = at
	return boss


func configure(sim: WroughtwildSim) -> void:
	var def: Dictionary = sim.boss()
	var rt: Dictionary = sim.realtime()
	var boss_rt: Dictionary = rt["boss"]
	var speed_multiplier: float = sim.combat_mods()["enemy_speed_multiplier"]

	enemy_id = def["id"]
	display_name = def["display_name"]
	behaviour = "boss"
	max_life = def["max_life"]
	life = max_life
	damage = def["claw_damage"]
	damage_type = def["claw_damage_type"]
	attack_period_seconds = def["claw_period_rounds"] * rt["round_seconds"] / speed_multiplier
	move_speed = boss_rt["move_speed_mps"] * speed_multiplier
	attack_range = boss_rt["claw_range_m"]
	windup_seconds = boss_rt["claw_windup_seconds"]
	aggro_range = 40.0

	breath_damage = def["breath_damage"]
	breath_damage_type = def["breath_damage_type"]
	breath_period_seconds = def["breath_period_rounds"] * rt["round_seconds"]
	breath_range = boss_rt["breath_range_m"]
	breath_cone_degrees = boss_rt["breath_cone_degrees"]
	breath_telegraph_seconds = boss_rt["breath_telegraph_seconds"]
	_breath_timer = breath_period_seconds

	_base_material = StandardMaterial3D.new()
	_base_material.albedo_color = Color(0.45, 0.08, 0.05)
	_telegraph_material = StandardMaterial3D.new()
	_telegraph_material.albedo_color = Color(1.0, 0.5, 0.1)
	_telegraph_material.emission_enabled = true
	_telegraph_material.emission = Color(1.0, 0.4, 0.05)
	_telegraph_material.emission_energy_multiplier = 3.0
	_mesh.material_override = _base_material
	state = "chase"
	_refresh_label()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	var player := _find_player()
	if player == null:
		move_and_slide()
		return

	var distance := _horizontal_distance_to(player)
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var planar := Vector3.ZERO

	match state:
		"chase":
			_breath_timer -= delta
			if _breath_timer <= 0.0 and distance <= breath_range * 1.2:
				state = "inhale"
				_telegraph_left = breath_telegraph_seconds
				_mesh.material_override = _telegraph_material
				_refresh_label()
				player.hud.notify("%s inhales deeply. Fire is coming!" % display_name)
			elif distance <= attack_range and _attack_cooldown <= 0.0:
				state = "windup"
				_windup_left = windup_seconds
			else:
				planar = _chase_direction(player, distance) * move_speed
		"windup":
			_windup_left -= delta
			if _windup_left <= 0.0:
				if distance <= attack_range * 1.15:
					player.combat.take_hit(damage, damage_type, display_name)
				_attack_cooldown = attack_period_seconds
				state = "chase"
		"inhale":
			_telegraph_left -= delta
			if _telegraph_left <= 0.0:
				breathe(player)

	velocity.x = planar.x
	velocity.z = planar.z
	if state != "inhale":
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	move_and_slide()


func _in_breath_cone(player: Node3D) -> bool:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length() > breath_range or to_player.length() < 0.001:
		return false
	var angle := rad_to_deg(forward.normalized().angle_to(to_player.normalized()))
	return angle <= breath_cone_degrees * 0.5


## Ends the telegraph: fire lands on a player inside the cone. Returns the
## damage the player actually took (0 when out of the cone or dashing).
func breathe(player: WroughtwildPlayer) -> float:
	state = "chase"
	_breath_timer = breath_period_seconds
	_mesh.material_override = _base_material
	_refresh_label()
	if not _in_breath_cone(player):
		player.hud.notify("The fire washes past you.")
		return 0.0
	return player.combat.take_hit(breath_damage, breath_damage_type, display_name)


## Test hook: begin the telegraph immediately.
func force_inhale() -> void:
	state = "inhale"
	_telegraph_left = breath_telegraph_seconds
	_mesh.material_override = _telegraph_material


func _refresh_label() -> void:
	if _label != null:
		var tag := "  (INHALING)" if state == "inhale" else ""
		_label.text = "%s  %d / %d%s" % [display_name, ceili(life), ceili(max_life), tag]
