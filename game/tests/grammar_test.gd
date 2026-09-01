extends Node
## Grammar-spike engine test, run with:
##   godot --headless --path game res://tests/grammar.tscn
## Drives the one full grammar sentence through real physics frames: a Frost
## Orb flies and forks down a line of whelps, chill builds to a freeze, and
## the cone strike shatters the frozen with a nova that chains. The sim owns
## every number; this test asserts the engine wiring obeys them (ADR-0003).
## Quits non-zero on failure.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var _player: WroughtwildPlayer
var _sim: WroughtwildSim
var _frame := 0
var _failures := 0
var _checks := 0

# Phase A/B actors, checked a few dozen frames after the cast.
var _line: Array = []


func check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: %s" % label)


func _ready() -> void:
	var floor_body := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(120, 1, 120)
	collider.shape = shape
	floor_body.add_child(collider)
	add_child(floor_body)
	floor_body.global_position = Vector3(0, -0.5, 0)

	_player = PLAYER_SCENE.instantiate()
	add_child(_player)
	_player.global_position = Vector3(0, 1.1, 0)
	_sim = _player.inventory.get_sim()


func _face_down_range() -> void:
	# Each phase re-pins the player at the origin facing -Z, with a slight
	# downward pitch so a flat-flying orb meets the whelp capsules instead
	# of skimming over their heads.
	_player.global_position = Vector3(0.0, 1.1, 0.0)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = 0.0
	_player.spring_arm.rotation.x = -0.08


func _clear_enemies() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Enemy and is_instance_valid(node):
			(node as Enemy).take_damage(100000.0)
	_player.combat.restore_life()
	_line.clear()


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		5:
			_phase_a_cast()
		80:
			_phase_a_checks()
		100:
			_phase_b_cast()
		175:
			_phase_b_checks()
		185:
			_phase_c_freeze_breakpoints()
		195:
			_phase_d_shatter_cascade()
		205:
			print("%d checks, %d failures" % [_checks, _failures])
			get_tree().quit(0 if _failures == 0 else 1)


## Phase A - bare cast: the orb hits the first whelp, one fork reaches the
## second, and the third (beyond fork range) is untouched.
func _phase_a_cast() -> void:
	_face_down_range()
	_line = [
		Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, -8.0)),
		Enemy.spawn(self, &"ember_whelp", Vector3(0.5, 0.6, -11.0)),
		Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, -22.0)),
	]
	check(_player.combat.use_orb(), "orb: cast fires")
	check(not _player.combat.is_ready(PlayerCombat.ORB_SKILL), "orb: cast spends the cooldown")


func _phase_a_checks() -> void:
	var a: Enemy = _line[0]
	var b: Enemy = _line[1]
	var c: Enemy = _line[2]
	check(is_instance_valid(a) and a.life < a.max_life, "orb: first whelp in the line is hit")
	check(is_instance_valid(a) and a.chill > 0.0, "orb: the hit applies sim chill buildup")
	check(is_instance_valid(b) and b.life < b.max_life, "fork: one fork reaches the second whelp")
	check(is_instance_valid(c) and is_equal_approx(c.life, c.max_life),
		"fork: the whelp beyond fork range is untouched")
	_clear_enemies()


## Phase B - Forked Lattice on: two forks from the first impact light up
## both remaining whelps in one cast.
func _phase_b_cast() -> void:
	_sim.set_skill_mod_active("forked_lattice", true)
	_player.combat.cooldowns[PlayerCombat.ORB_SKILL] = 0.0
	_face_down_range()
	_line = [
		Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, -8.0)),
		Enemy.spawn(self, &"ember_whelp", Vector3(0.4, 0.6, -11.0)),
		Enemy.spawn(self, &"ember_whelp", Vector3(-0.5, 0.6, -11.5)),
	]
	check(_player.combat.use_orb(), "lattice: cast fires")


func _phase_b_checks() -> void:
	for i in _line.size():
		var enemy: Enemy = _line[i]
		check(is_instance_valid(enemy) and enemy.life < enemy.max_life,
			"lattice: whelp %d of 3 hit by the doubled fork" % (i + 1))
	_clear_enemies()
	_sim.set_skill_mod_active("forked_lattice", false)


## Phase C - freeze breakpoints, applied same-frame so decay cannot blur
## them: three bare applications freeze, two with Deep Frost.
func _phase_c_freeze_breakpoints() -> void:
	var bare: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, -3.0))
	var amount: float = _sim.chill_applied("prototype_frost_orb", false)
	bare.apply_chill(amount)
	bare.apply_chill(amount)
	check(not bare.is_frozen(), "freeze: two bare orb chills do not freeze")
	bare.apply_chill(amount)
	check(bare.is_frozen(), "freeze: the third bare chill crosses the threshold")

	_sim.set_skill_mod_active("deep_frost", true)
	var deep: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(1.0, 0.6, -3.0))
	var deep_amount: float = _sim.chill_applied("prototype_frost_orb", false)
	check(deep_amount > amount, "freeze: Deep Frost raises the applied buildup")
	deep.apply_chill(deep_amount)
	check(not deep.is_frozen(), "freeze: one Deep Frost chill is not enough")
	deep.apply_chill(deep_amount)
	check(deep.is_frozen(), "freeze: Deep Frost freezes on the second hit")
	_sim.set_skill_mod_active("deep_frost", false)
	_clear_enemies()


## Phase D - the shatter hook, same-frame so nobody moves: the cone strike
## executes frozen whelps, the nova chains to a frozen neighbour, and a
## bystander outside the cone (but inside the first nova) takes nova damage.
func _phase_d_shatter_cascade() -> void:
	_face_down_range()
	var first: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, -2.0))
	var chained: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(0.9, 0.6, -2.2))
	var bystander: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(-1.8, 0.6, -1.0))
	first.apply_chill(1000.0)
	chained.apply_chill(1000.0)
	check(first.is_frozen() and chained.is_frozen(), "shatter: both line whelps frozen solid")
	check(not bystander.is_frozen(), "shatter: the bystander is not frozen")

	_player.combat.cooldowns[PlayerCombat.AREA_SKILL] = 0.0
	var hits: int = _player.combat.use_area()
	check(hits == 2, "shatter: the cone strike connects with the two frozen (%d)" % hits)
	check(first.life <= 0.0, "shatter: the struck frozen whelp is executed")
	check(chained.life <= 0.0, "shatter: the nova chains the frozen neighbour into shattering")
	var nova_damage: float = _sim.shatter_for("prototype_area_strike")["nova_damage"]
	check(bystander.life > 0.0 and is_equal_approx(bystander.life, bystander.max_life - nova_damage),
		"shatter: the out-of-cone bystander takes exactly one nova (%0.1f)" % bystander.life)
	_clear_enemies()
