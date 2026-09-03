class_name Enemy
extends CharacterBody3D
## A world enemy. Its numbers (life, damage, cadence) come from the sim's
## enemy definition and its movement, ranges and wind-up from the sim's
## realtime table (ADR-0003). It never computes damage: when an attack lands
## it hands the raw hit to the player's combat component, which asks the sim
## what actually gets through.

signal died(enemy: Enemy)

## The nest that fielded this mob (encroachment), 0 for a roaming pack.
var nest_id := 0


## Era mechanic (eras.json burning_ground): where this family dies, the
## ground burns for a while. The sim says whether and how much.
func _leave_burning_ground() -> void:
	if _sim == null:
		return
	var params: Dictionary = _sim.era_mechanic(enemy_id, "burning_ground")
	if params.is_empty() or get_parent() == null:
		return
	BurningGround.spawn(get_parent(), global_position, params, float(_sim.realtime().get("round_seconds", 1.0)))

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
## Vertical band within which a mob can aggro on and reach the player.
var vertical_reach := 2.5
## Take-off speed for hopping a one-block ledge in the chase path.
var jump_speed := 5.0
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
var _sim: WroughtwildSim

## Status grammar: buildup toward each threshold comes from the sim's
## *_applied numbers; the rules (max, decay, durations, ticks) from
## chill_status/ignite_status/bleed_status. A frozen enemy is a solid,
## harmless block of ice; a burning one ticks fire damage; a bleeding one
## bleeds harder while it walks. Boss shares all of this via the
## _configure_statuses/_tick_statuses helpers.
## Elite prefix (Wave 3): "" for a plain mob. make_elite applies the
## modifier's multipliers, immunities and death burst; loot rolls carry
## the id so elites pay their bounty.
var elite_id := ""
var _immune_statuses := PackedStringArray()
var _burst_damage := 0.0
var _burst_radius := 0.0
var _burst_type := "fire"

## Shrieker fields (0 for everything else): while aggroed it screams every
## period, waking idle mobs in radius (D-012's aggro chain).
var _scream_period := 0.0
var _scream_radius := 0.0
var _scream_timer := 0.0

var chill := 0.0
var frozen_left := 0.0
var ignite := 0.0
var burning_left := 0.0
var bleed := 0.0
var bleeding_left := 0.0
var _chill_max := 100.0
var _chill_decay := 30.0
var _freeze_duration := 2.5
var _ignite_max := 100.0
var _ignite_decay := 8.0
var _burn_dps := 0.0
var _bleed_max := 100.0
var _bleed_decay := 8.0
var _bleed_dps := 0.0
var _bleed_move_mult := 1.0
var _base_albedo := Color.WHITE

@onready var _label: Label3D = $Label3D
@onready var _mesh: MeshInstance3D = $MeshInstance3D


## Spawns an enemy of enemy_id at a world position under root.
static func spawn(root: Node, id: StringName, at: Vector3) -> Enemy:
	var scene: PackedScene = load("res://scenes/enemy.tscn")
	var enemy: Enemy = scene.instantiate()
	enemy.enemy_id = id
	# Position before add_child: the physics body must never spend a frame at
	# the parent's origin, or it depenetrates (and platform-carries) whatever
	# stands there - the player, usually.
	enemy.position = at
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
	_scream_period = b.get("scream_period_seconds", 0.0)
	_scream_radius = b.get("scream_radius_m", 0.0)
	_scream_timer = _scream_period
	var horde: Dictionary = rt.get("horde", {})
	give_up_seconds = horde.get("give_up_seconds", 2.5)
	vertical_reach = horde.get("vertical_reach_m", 2.5)
	jump_speed = horde.get("jump_speed_mps", 5.0)
	separation_radius = horde.get("separation_radius_m", 1.1)
	separation_strength = horde.get("separation_strength_mps", 3.0)

	_configure_statuses(sim)

	_material = StandardMaterial3D.new()
	match behaviour:
		"ranged": _material.albedo_color = Color(0.8, 0.15, 0.1)
		"fast": _material.albedo_color = Color(0.25, 0.3, 0.45)
		# The recruiter reads sickly yellow: kill-it-first at a glance.
		"shrieker": _material.albedo_color = Color(0.8, 0.75, 0.25)
		_: _material.albedo_color = Color(0.9, 0.45, 0.1)
	_base_albedo = _material.albedo_color
	_mesh.material_override = _material
	_refresh_label()


func _refresh_label() -> void:
	if _label != null:
		_label.text = "%s  %d / %d" % [display_name, ceili(life), ceili(max_life)]


## Crowns this mob with an elite modifier (sim.elite_modifier view): the
## prefix joins the name, the multipliers land, immunities arm, and a
## death burst may too. Bigger and gold-named so the bounty reads at a
## glance (D-013: menace must be legible).
func make_elite(mod: Dictionary) -> void:
	if mod.is_empty():
		return
	elite_id = mod["id"]
	display_name = "%s %s" % [mod["display_name"], display_name]
	max_life *= mod.get("life_multiplier", 1.0)
	life = max_life
	damage *= mod.get("damage_multiplier", 1.0)
	move_speed *= mod.get("speed_multiplier", 1.0)
	_immune_statuses = mod.get("immune_statuses", PackedStringArray())
	_burst_damage = mod.get("death_burst_damage", 0.0)
	_burst_radius = mod.get("death_burst_radius_m", 0.0)
	_burst_type = mod.get("death_burst_type", "fire")
	if _mesh != null:
		_mesh.scale = Vector3.ONE * 1.3
	if _label != null:
		_label.modulate = Color(1.0, 0.85, 0.3)
	_refresh_label()


func _find_player() -> WroughtwildPlayer:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	return _player


func _horizontal_distance_to(target: Node3D) -> float:
	var a := global_position
	var b := target.global_position
	return Vector2(a.x - b.x, a.z - b.z).length()


func _vertical_gap_to(target: Node3D) -> float:
	return absf(global_position.y - target.global_position.y)


func is_frozen() -> bool:
	return frozen_left > 0.0


## Reads every status rule from the sim. Boss calls this too: statuses are
## the one piece of enemy behaviour the whole bestiary shares.
func _configure_statuses(sim: WroughtwildSim) -> void:
	_sim = sim
	var chill_rules: Dictionary = sim.chill_status()
	_chill_max = chill_rules.get("buildup_max", 100.0)
	_chill_decay = chill_rules.get("decay_per_s", 30.0)
	_freeze_duration = chill_rules.get("freeze_duration_s", 2.5)
	var ignite_rules: Dictionary = sim.ignite_status()
	_ignite_max = ignite_rules.get("buildup_max", 100.0)
	_ignite_decay = ignite_rules.get("decay_per_s", 8.0)
	var bleed_rules: Dictionary = sim.bleed_status()
	_bleed_max = bleed_rules.get("buildup_max", 100.0)
	_bleed_decay = bleed_rules.get("decay_per_s", 8.0)


## Chill from the sim's numbers; crossing the threshold freezes solid.
func apply_chill(amount: float) -> void:
	if amount <= 0.0 or is_frozen() or life <= 0.0 or _immune_statuses.has("chill"):
		return
	chill += amount
	if chill >= _chill_max:
		chill = 0.0
		frozen_left = _freeze_duration
		_on_frozen()
		_refresh_look()


## Interrupts whatever the enemy was doing when it froze. Boss extends this
## to cancel an inhale.
func _on_frozen() -> void:
	_windup_left = 0.0


## Ignite buildup; crossing the threshold sets the mob burning. Duration and
## tick are snapshotted from the sim at ignition, so the burn a mob carries
## reflects the gear that lit it. Re-igniting refreshes, never stacks.
func apply_ignite(amount: float) -> void:
	if amount <= 0.0 or life <= 0.0 or _immune_statuses.has("ignite"):
		return
	ignite += amount
	if ignite >= _ignite_max:
		ignite = 0.0
		var rules: Dictionary = _sim.ignite_status() if _sim != null else {}
		burning_left = rules.get("duration_s", 4.0)
		_burn_dps = rules.get("damage_per_s", 0.0)
		_refresh_look()


## Bleed buildup; crossing the threshold opens a wound that ticks harder
## while the mob walks (the chasing train pays for chasing).
func apply_bleed(amount: float) -> void:
	if amount <= 0.0 or life <= 0.0 or _immune_statuses.has("bleed"):
		return
	bleed += amount
	if bleed >= _bleed_max:
		bleed = 0.0
		var rules: Dictionary = _sim.bleed_status() if _sim != null else {}
		bleeding_left = rules.get("duration_s", 5.0)
		_bleed_dps = rules.get("damage_per_s", 0.0)
		_bleed_move_mult = rules.get("moving_multiplier", 1.0)
		_refresh_look()


## Public: the shatter hook thaws a nova'd boss from outside.
func thaw() -> void:
	frozen_left = 0.0
	_refresh_look()


## One tick of the shared status clocks: freeze countdown, buildup decay,
## burn and bleed damage. Returns true while frozen - the caller must stand
## still and skip its brain. Boss calls this from its own _physics_process.
func _tick_statuses(delta: float) -> bool:
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_refresh_look()

	# DoTs tick even through ice: freeze holds the mob, not the fire.
	if burning_left > 0.0:
		burning_left -= delta
		take_damage(_burn_dps * delta, false)
		if burning_left <= 0.0:
			_refresh_look()
	else:
		ignite = maxf(0.0, ignite - _ignite_decay * delta)
	if bleeding_left > 0.0:
		bleeding_left -= delta
		var moving := Vector2(velocity.x, velocity.z).length() > 0.5
		var mult := _bleed_move_mult if moving else 1.0
		take_damage(_bleed_dps * mult * delta, false)
		if bleeding_left <= 0.0:
			_refresh_look()
	else:
		bleed = maxf(0.0, bleed - _bleed_decay * delta)

	# Frozen: a solid, harmless block. Trains pile up behind it (D-012:
	# your damage builds walls); no thinking, no attacking, no walking.
	if is_frozen():
		frozen_left -= delta
		if frozen_left <= 0.0:
			thaw()
		return frozen_left > 0.0
	chill = maxf(0.0, chill - _chill_decay * delta)
	return false


## The one place the material is decided. Priority: ice, then the hit
## flash, then fire, then blood, then the behaviour's base colour.
func _refresh_look() -> void:
	if _material == null:
		return
	if is_frozen():
		_material.albedo_color = Color(0.55, 0.82, 1.0)
		_material.emission_enabled = true
		_material.emission = Color(0.5, 0.8, 1.0)
		_material.emission_energy_multiplier = 0.8
	elif _flash_left > 0.0:
		_material.albedo_color = _base_albedo
		_material.emission_enabled = true
		_material.emission = Color(1.0, 1.0, 0.9)
		_material.emission_energy_multiplier = 1.6
	elif burning_left > 0.0:
		_material.albedo_color = _base_albedo.lerp(Color(1.0, 0.4, 0.05), 0.55)
		_material.emission_enabled = true
		_material.emission = Color(1.0, 0.35, 0.05)
		_material.emission_energy_multiplier = 1.1
	elif bleeding_left > 0.0:
		_material.albedo_color = _base_albedo.lerp(Color(0.5, 0.02, 0.02), 0.6)
		_material.emission_enabled = false
	else:
		_material.albedo_color = _base_albedo
		_material.emission_enabled = false


## A burning mob's death spreads its fire (the proliferate hook): every mob
## within the sim's radius receives spread buildup, bosses through their
## resistance. A dense pack burns down from one kill.
func _proliferate() -> void:
	if _sim == null:
		return
	var params: Dictionary = _sim.proliferate_for()
	if not params.get("enabled", false):
		return
	var radius: float = params.get("radius_m", 0.0)
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not (node is Enemy) or not is_instance_valid(node):
			continue
		var other := node as Enemy
		if global_position.distance_to(other.global_position) > radius:
			continue
		var key := "spread_buildup_boss" if other is Boss else "spread_buildup"
		other.apply_ignite(params.get(key, 0.0))


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta
	if _tick_statuses(delta):
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	var player := _find_player()
	if player == null:
		move_and_slide()
		return

	var distance := _horizontal_distance_to(player)
	# The 3D world's rule: a floor or a cliff between us means no aggro, no
	# bite, and (after give_up_seconds) no interest. Cave dwellers under
	# your feet stay in their cave until you drop in.
	var in_reach := _vertical_gap_to(player) <= vertical_reach
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var planar := Vector3.ZERO

	match state:
		"idle":
			if distance <= aggro_range and in_reach:
				state = "chase"
				_give_up_timer = 0.0
		"chase":
			# D-012: no leash. The chase only ends when the player genuinely
			# leaves - staying beyond give_up_distance (or out of vertical
			# reach) for give_up_seconds.
			if (give_up_distance > 0.0 and distance > give_up_distance) or not in_reach:
				_give_up_timer += delta
				if _give_up_timer >= give_up_seconds:
					state = "idle"
					_give_up_timer = 0.0
			else:
				_give_up_timer = 0.0
			if state == "chase":
				if distance <= attack_range and in_reach and _attack_cooldown <= 0.0:
					state = "windup"
					_windup_left = windup_seconds
				else:
					planar = _chase_direction(player, distance) * move_speed
		"windup":
			_windup_left -= delta
			if _windup_left <= 0.0:
				# The hit only lands if the player is still in reach: walking
				# out of the wind-up is a legitimate dodge.
				if distance <= attack_range * 1.15 and in_reach:
					player.combat.take_hit(damage, damage_type, display_name)
				_attack_cooldown = attack_period_seconds
				state = "chase"

	# Separation steering: chasers shoulder each other apart, so a trained
	# horde forms a physical train instead of a stack of ghosts (D-012).
	if state != "idle":
		planar += _separation_push()
		# Shrieker: the aggro chain. While it fights, it recruits.
		if _scream_period > 0.0:
			_scream_timer -= delta
			if _scream_timer <= 0.0:
				force_scream()

	velocity.x = planar.x
	velocity.z = planar.z
	_hop_if_blocked(planar)
	if planar.length_squared() > 0.0001 and distance > 0.05:
		look_at(Vector3(player.global_position.x, global_position.y, player.global_position.z), Vector3.UP)
	move_and_slide()


## A chaser pressing into a ledge hops it (one block, not two): the 3D
## world's steps must not be free kills. Reads last frame's wall contact.
func _hop_if_blocked(planar: Vector3) -> void:
	if jump_speed <= 0.0 or not is_on_floor() or not is_on_wall():
		return
	if planar.length_squared() < 0.01:
		return
	if get_wall_normal().dot(planar.normalized()) < -0.5:
		velocity.y = jump_speed


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


## The scream: every idle enemy within radius joins the chase (D-012's
## Zombies-wave builder). Public as the test hook too.
func force_scream() -> void:
	_scream_timer = _scream_period
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not (node is Enemy) or not is_instance_valid(node):
			continue
		var other := node as Enemy
		if other.state != "idle" or other.life <= 0.0:
			continue
		if _horizontal_distance_to(other) > _scream_radius:
			continue
		other.state = "chase"
	_pulse_ring(_scream_radius, Color(1.0, 0.9, 0.35, 0.4))


## An expanding translucent ring (scream, death burst): greybox VFX that
## tells the radius honestly.
func _pulse_ring(radius: float, colour: Color) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = Color(colour.r, colour.g, colour.b)
	sphere.material = material
	mesh.mesh = sphere
	get_parent().add_child(mesh)
	mesh.global_position = global_position + Vector3(0, 0.5, 0)
	var tween := mesh.create_tween()
	tween.tween_property(mesh, "scale", Vector3.ONE * radius * 2.0, 0.3)
	tween.parallel().tween_property(mesh, "transparency", 1.0, 0.3)
	tween.tween_callback(mesh.queue_free)


## An elite's death burst: fire (usually) at the corpse. Positioning is
## the counter - the player eats it only by standing in it.
func _death_burst() -> void:
	_pulse_ring(_burst_radius, Color(1.0, 0.45, 0.1, 0.5))
	var player := _find_player()
	if player == null:
		return
	if _horizontal_distance_to(player) <= _burst_radius:
		player.combat.take_hit(_burst_damage, _burst_type, display_name)


## Test hook: resolves an attack immediately, ignoring range and wind-up.
func force_attack() -> float:
	var player := _find_player()
	if player == null:
		return 0.0
	_attack_cooldown = attack_period_seconds
	state = "chase"
	return player.combat.take_hit(damage, damage_type, display_name)


func take_damage(amount: float, flash: bool = true) -> void:
	if life <= 0.0:
		return
	life = maxf(0.0, life - amount)
	_refresh_label()
	# Hit feedback: a brief white-hot flash (DoT ticks pass flash=false so a
	# burn does not strobe). Taking damage also wakes the enemy - shooting a
	# distant mob pulls it (D-012 stray-pull).
	if flash:
		_flash_left = 0.12
		_refresh_look()
	if state == "idle":
		state = "chase"
		_give_up_timer = 0.0
	if life <= 0.0:
		if burning_left > 0.0:
			_proliferate()
		if _burst_damage > 0.0:
			_death_burst()
		_leave_burning_ground()
		died.emit(self)
		remove_from_group("enemies")
		queue_free()
