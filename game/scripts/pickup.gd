class_name Pickup
extends Node3D
## A physical drop: a small glowing chip that pops out with an arc, bounces
## to rest, then vacuums into the player who walks near (the Minecraft
## pickup feel). Absorbing it is what actually grants the thing through the
## sim; until then it is just a thing in the world. Three kinds: a material
## chip, a piece of rolled gear (remembers only its kill - the sim re-rolls
## the same item from enemy and seed on claim, D-016), and a skill page
## that teaches a skill the moment it is absorbed. No physics body - flight
## is manual, so a hundred of these cost nothing.

const MAGNET_RANGE := 3.2
const ABSORB_RANGE := 0.8
const MAGNET_ACCEL := 30.0
const MAGNET_MAX_SPEED := 13.0
const GRAVITY := 12.0
## Forgotten material chips eventually fade so old battlefields don't
## accumulate; gear and pages are rare enough to wait forever.
const MAX_AGE_SECONDS := 180.0

## material | gear | page
var kind := "material"
var family := "wood"
var amount := 1
## gear: the kill this item came from (the sim re-rolls it on claim).
var enemy_id := ""
var gear_seed := 0
## gear/page: what the HUD calls it before it is claimed.
var display_name := ""
var rarity := "plain"
## page: the skill the page teaches.
var page_skill := ""

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


## A piece of rolled gear where a mob fell. It stores only the kill
## (enemy + seed): claiming asks the sim to re-roll the identical item into
## the pack, so no item state ever lives in the world (D-016).
static func drop_gear(root: Node, at: Vector3, in_enemy_id: String, in_seed: int,
		preview: Dictionary, floor_y := NAN) -> Pickup:
	var pickup := Pickup.new()
	pickup.kind = "gear"
	pickup.enemy_id = in_enemy_id
	pickup.gear_seed = in_seed
	pickup.display_name = preview.get("display_name", "gear")
	pickup.rarity = preview.get("rarity", "plain")
	_launch_drop(pickup, root, at, in_seed, floor_y)
	return pickup


## A skill page where a mob fell; absorbing it teaches the skill (D-016:
## skills are found, not worn).
static func drop_page(root: Node, at: Vector3, skill_id: String, skill_name: String,
		floor_y := NAN) -> Pickup:
	var pickup := Pickup.new()
	pickup.kind = "page"
	pickup.page_skill = skill_id
	pickup.display_name = skill_name
	_launch_drop(pickup, root, at, skill_id.hash(), floor_y)
	return pickup


static func _launch_drop(pickup: Pickup, root: Node, at: Vector3, seed_value: int,
		floor_y: float) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var angle := rng.randf() * TAU
	pickup._floor_y = (at.y - 0.25) if is_nan(floor_y) else floor_y
	pickup._velocity = Vector3(
		cos(angle) * rng.randf_range(0.6, 1.5),
		rng.randf_range(2.6, 3.4),
		sin(angle) * rng.randf_range(0.6, 1.5))
	pickup.position = at
	root.add_child(pickup)
	pickup.global_position = at


## A stable colour per material family, so wood chips always look like wood
## chips without hand-listing every family.
static func family_color(of_family: String) -> Color:
	var hue := fposmod(float(of_family.hash() % 1024) / 1024.0 * 0.618034 * 7.0, 1.0)
	return Color.from_hsv(hue, 0.55, 0.95)


func _ready() -> void:
	add_to_group("pickups")
	_mesh = MeshInstance3D.new()
	var box := BoxMesh.new()
	var tint := Pickup.family_color(family)
	match kind:
		"gear":
			# A chunkier chip in its rarity's colour: worth walking back for.
			box.size = Vector3.ONE * 0.3
			tint = UiTheme.rarity_colour(rarity)
		"page":
			# A thin pale card: knowledge lying in the grass.
			box.size = Vector3(0.3, 0.04, 0.36)
			tint = Color(0.93, 0.88, 0.72)
		_:
			box.size = Vector3.ONE * 0.22
	var material := StandardMaterial3D.new()
	material.albedo_color = tint
	material.emission_enabled = true
	material.emission = tint
	material.emission_energy_multiplier = 1.4 if kind != "material" else 0.9
	box.material = material
	_mesh.mesh = box
	_mesh.position = Vector3(0, 0.12, 0)
	add_child(_mesh)
	_bob_phase = randf() * TAU


func _physics_process(delta: float) -> void:
	_age += delta
	if kind == "material" and _age > MAX_AGE_SECONDS:
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
	var sim: WroughtwildSim = wrought_player.inventory.get_sim()
	match kind:
		"gear":
			# The claim re-rolls the kill's gear straight into the pack: the
			# same (enemy, seed) always yields the same item, so the world
			# never carried item state at all.
			for entry in sim.claim_enemy_gear(enemy_id, gear_seed):
				if wrought_player.hud != null:
					wrought_player.hud.notify("Found: %s %s" % [
						String(entry.get("rarity", "plain")).capitalize(),
						entry.get("display_name", "gear")])
		"page":
			var skill_name := display_name if display_name != "" else Hud.pretty(page_skill)
			var learned := wrought_player.combat.learn_skill(page_skill)
			if wrought_player.hud != null:
				if not learned:
					wrought_player.hud.notify("A page on %s - already mastered." % skill_name)
				elif sim.skill_bar().has(page_skill):
					wrought_player.hud.notify("Skill page: you learn %s. It joins your bar." % skill_name)
				else:
					wrought_player.hud.notify("Skill page: you learn %s. Assign it in the pack screen (I)." % skill_name)
		_:
			sim.add_materials({family: amount})
			if wrought_player.hud != null:
				wrought_player.hud.notify_pickup(family, amount)
	queue_free()
