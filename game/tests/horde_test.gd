extends Node
## D-012 horde behaviour test, run with:
##   godot --headless --path game res://tests/horde.tscn
## Drives real enemies across physics frames and asserts the Wave 1.5
## contract: aggro starts a persistent chase (no leash), chasers spread into
## a train, a genuine escape ends the chase after give_up_seconds, re-entry
## re-aggroes, the area strike is a facing cone, damage pulls idle strays,
## and dash carries no invulnerability. Quits non-zero on failure.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var _player: WroughtwildPlayer
var _pack: Array = []
var _frame := 0
var _failures := 0
var _checks := 0


func check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: %s" % label)


func _ready() -> void:
	var floor_body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(220, 1, 220)
	collider.shape = shape
	floor_body.add_child(collider)
	add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.global_position = Vector3(0, 1.1, 0)


func _all_state(expected: String) -> bool:
	for enemy in _pack:
		if not is_instance_valid(enemy) or enemy.state != expected:
			return false
	return true


func _min_pack_spacing() -> float:
	var closest := INF
	for i in _pack.size():
		for j in range(i + 1, _pack.size()):
			closest = minf(closest,
				_pack[i].global_position.distance_to(_pack[j].global_position))
	return closest


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			# A tight cluster inside aggro range: the train-to-be.
			for i in 3:
				var enemy := Enemy.spawn(self, &"ember_whelp", Vector3(0.3 * i, 0.6, 8.0 + 0.2 * i))
				_pack.append(enemy)
		40:
			check(_all_state("chase"), "horde: aggro starts the chase")
			# Step out to 20 m: beyond the OLD leash (aggro * 1.5 = 18) but
			# inside give_up_distance (26). D-012: they must keep coming.
			_player.global_position = Vector3(0, 1.1, -12)
		240:
			check(_all_state("chase"), "horde: no leash - chase persists inside give-up range")
			check(_min_pack_spacing() > 0.5, "horde: separation spreads the cluster into a train")
			# A genuine escape: far beyond give_up_distance.
			_player.global_position = Vector3(0, 1.1, -45)
		460:
			check(_all_state("idle"), "horde: chase given up after a real escape")
			# Walk back in: the world stays dangerous.
			_player.global_position = _pack[0].global_position + Vector3(0, 1.0, 5.0)
		500:
			check(_all_state("chase"), "horde: returning re-aggroes the pack")
			_run_cone_and_dash_checks()
		510:
			_run_shrieker_and_elite_checks()
			# The 3D-world rule (owner playtest 2 Sep 2026): a mob under the
			# floor, 2 m away horizontally, must NOT aggro through the rock.
			_player.global_position = Vector3(80, 1.1, -80)
			_pack = [Enemy.spawn(self, &"gloom_crawler", Vector3(80, -6.0, -78))]
		522:
			check(_pack[0].state == "idle", "reach: a crawler beneath the floor cannot aggro through it")
			_pack[0].global_position = _player.global_position + Vector3(0, -0.5, 2.0)
		530:
			check(_pack[0].state != "idle", "reach: the same crawler on your level aggroes (%s)" % _pack[0].state)
			_pack[0].take_damage(100000.0)
			# A one-block ledge across the chase path (owner playtest: stuck
			# mobs were free kills). The whelp must hop it, not grind on it.
			var ledge := StaticBody3D.new()
			var ledge_shape := CollisionShape3D.new()
			var box := BoxShape3D.new()
			box.size = Vector3(8, 1, 1)
			ledge_shape.shape = box
			ledge.add_child(ledge_shape)
			add_child(ledge)
			ledge.global_position = Vector3(80, 0.5, -83.5)
			_player.global_position = Vector3(80, 1.1, -78)
			_pack = [Enemy.spawn(self, &"ember_whelp", Vector3(80, 0.6, -88))]
		680:
			check(is_instance_valid(_pack[0]) and _pack[0].global_position.z > -83.0,
				"hop: a chaser clears a one-block ledge (z %.1f)" % _pack[0].global_position.z)
		682:
			print("%d checks, %d failures" % [_checks, _failures])
			get_tree().quit(0 if _failures == 0 else 1)


func _run_cone_and_dash_checks() -> void:
	# A clear corner of the floor, facing -Z (rotation 0).
	_player.global_position = Vector3(60, 1.1, 60)
	_player.rotation.y = 0.0
	_player.spring_arm.rotation.x = 0.0

	var front_a := Enemy.spawn(self, &"ember_whelp", Vector3(60.3, 0.6, 58.2))
	var front_b := Enemy.spawn(self, &"ember_whelp", Vector3(59.6, 0.6, 58.0))
	var behind := Enemy.spawn(self, &"ember_whelp", Vector3(60, 0.6, 62.0))

	var hits: int = _player.combat.use_area()
	check(hits == 2, "cone: area strike hits the two in front (%d)" % hits)
	check(front_a.life < front_a.max_life and front_b.life < front_b.max_life,
		"cone: facing targets take the hit")
	check(is_equal_approx(behind.life, behind.max_life),
		"cone: the enemy behind is untouched - area is the slice you face")

	# Dash is pure movement now (D-012): no invulnerability window.
	check(_player.combat.use_dash(), "dash: still fires as a movement burst")
	check(_player.combat.invulnerable_left <= 0.0, "dash: carries no invulnerability frames")

	# Damage pulls an idle stray far outside aggro range (D-012 stray-pull).
	var stray := Enemy.spawn(self, &"ember_whelp", Vector3(60, 0.6, 80))
	check(stray.state == "idle", "stray: spawns unaware at 20 m")
	stray.take_damage(1.0)
	check(stray.state == "chase", "stray: taking a hit pulls it into the fight")


## Wave 3: the shrieker's aggro chain and the elite modifiers.
func _run_shrieker_and_elite_checks() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		(enemy as Enemy).take_damage(100000.0)
	_pack.clear()
	_player.combat.restore_life()
	_player.global_position = Vector3(-60, 1.1, -60)
	var sim: WroughtwildSim = _player.inventory.get_sim()

	# The scream: an idle mob far outside its own aggro joins the chase.
	var shrieker := Enemy.spawn(self, &"shrieker", Vector3(-60, 0.6, -52))
	var sleeper := Enemy.spawn(self, &"ember_whelp", Vector3(-60, 0.6, -42))
	check(shrieker.behaviour == "shrieker" and shrieker._scream_radius > 0.0,
		"shrieker: behaviour and scream tuned from the sim")
	sleeper.state = "idle"
	check(sleeper.state == "idle", "shrieker: the sleeper starts unaware")
	shrieker.force_scream()
	check(sleeper.state == "chase", "shrieker: the scream recruits the sleeper")

	# Unfreezable: chill that would freeze anything slides off.
	var elite := Enemy.spawn(self, &"ember_whelp", Vector3(-58, 0.6, -60))
	var plain_life: float = elite.max_life
	elite.make_elite(sim.elite_modifier("unfreezable"))
	check(elite.display_name.begins_with("Unfreezable") and elite.max_life > plain_life,
		"elite: the crown renames and toughens")
	check(elite.elite_id == "unfreezable", "elite: kills will carry the bounty id")
	elite.apply_chill(100000.0)
	check(not elite.is_frozen(), "elite: unfreezable never freezes")
	elite.apply_bleed(100000.0)
	check(elite.bleeding_left > 0.0, "elite: other statuses still land")

	# Cinder-blooded: no burn, and the death burst catches a close player.
	var cinder := Enemy.spawn(self, &"ember_whelp", Vector3(-60.5, 0.6, -60))
	cinder.make_elite(sim.elite_modifier("cinder_blooded"))
	cinder.apply_ignite(100000.0)
	check(cinder.burning_left <= 0.0, "elite: cinder-blooded will not burn")
	var life_before: float = _player.combat.life
	cinder.take_damage(100000.0)
	check(_player.combat.life < life_before, "elite: the death burst catches a player standing in it")
