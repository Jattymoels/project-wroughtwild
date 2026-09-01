class_name Pickup
extends Node3D
## A physical dropped material: a small glowing chip that pops out with an
## arc, bounces to rest, then vacuums into the player who walks near
## (the Minecraft pickup feel). Absorbing it is what actually grants the
## material through the sim; until then it is just a thing in the world.
## No physics body - flight is manual, so a hundred of these cost nothing.

const MAGNET_RANGE := 3.2
const ABSORB_RANGE := 0.8
const MAGNET_ACCEL := 30.0
const MAGNET_MAX_SPEED := 13.0
const GRAVITY := 12.0
## Forgotten drops eventually fade so old battlefields don't accumulate.
const MAX_AGE_SECONDS := 180.0

var family := "wood"
var amount := 1

var _velocity := Vector3.ZERO
var _floor_y := 0.0
var _bounces := 0
var _resting := false
var _age := 0.0
var _bob_phase := 0.0
var _mesh: MeshInstance3D


## Spawns one pickup per material family in contents, scattered from `at`
## with deterministic arcs (same seed, same luck - saves replay cleanly).
## floor_y is the ground the chips settle on; NAN means just below `at`.
static func scatter(root: Node, at: Vector3, contents: Dictionary, seed_value: int,
		floor_y := NAN) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var spawned: Array = []
	for key in contents:
		if int(contents[key]) <= 0:
			continue
		var pickup := Pickup.new()
		pickup.family = String(key)
		pickup.amount = int(contents[key])
		pickup._floor_y = (at.y - 0.25) if is_nan(floor_y) else floor_y
		var angle := rng.randf() * TAU
		pickup._velocity = Vector3(
			cos(angle) * rng.randf_range(0.6, 1.5),
			rng.randf_range(2.6, 3.4),
			sin(angle) * rng.randf_range(0.6, 1.5))
		pickup.position = at
		root.add_child(pickup)
		pickup.global_position = at
		spawned.append(pickup)
	return spawned


## A stable colour per material family, so wood chips always look like wood
## chips without hand-listing every family.
static func family_color(of_family: String) -> Color:
	var hue := fposmod(float(of_family.hash() % 1024) / 1024.0 * 0.618034 * 7.0, 1.0)
	return Color.from_hsv(hue, 0.55, 0.95)


func _ready() -> void:
	add_to_group("pickups")
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * 0.22
	var material := StandardMaterial3D.new()
	var tint := Pickup.family_color(family)
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 0.9
	box.material = material
	_mesh.mesh = box
	_mesh.position = Vector3(0, 0.12, 0)
	add_child(_mesh)
	_bob_phase = randf() * TAU


func _physics_process(delta: float) -> void:
	_age += delta
	if _age > MAX_AGE_SECONDS:
		queue_free()
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player != null:
		var to_player: Vector3 = player.global_position + Vector3(0, 0.6, 0) - global_position
		var distance := to_player.length()
		if distance <= ABSORB_RANGE:
			_absorb(player)
			return
		if distance <= MAGNET_RANGE:
			# Vacuum: accelerate straight at the player, ignoring gravity.
			_velocity = _velocity.move_toward(
				to_player / distance * MAGNET_MAX_SPEED, MAGNET_ACCEL * delta)
			global_position += _velocity * delta
			return

	if _resting:
		# Idle juice: a slow spin and bob says "come get me" from afar.
		_bob_phase += delta * 2.2
		rotate_y(delta * 1.6)
		_mesh.position.y = 0.12 + sin(_bob_phase) * 0.045
		return

	_velocity.y -= GRAVITY * delta
	global_position += _velocity * delta
	if global_position.y <= _floor_y and _velocity.y < 0.0:
		global_position.y = _floor_y
		_bounces += 1
		if _bounces >= 2 or absf(_velocity.y) < 1.2:
			_resting = true
			_velocity = Vector3.ZERO
		else:
			_velocity.y = -_velocity.y * 0.45
			_velocity.x *= 0.55
			_velocity.z *= 0.55


func _absorb(player: Node3D) -> void:
	var wrought_player := player as WroughtwildPlayer
	if wrought_player == null:
		return
	wrought_player.inventory.get_sim().add_materials({family: amount})
	if wrought_player.hud != null:
		wrought_player.hud.notify_pickup(family, amount)
	queue_free()
