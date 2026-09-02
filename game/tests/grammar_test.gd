extends Node
## Grammar engine test, run with:
##   godot --headless --path game res://tests/grammar.tscn
## Drives the grammar sentences through real physics frames: a Frost Orb
## flies and forks down a line of whelps, chill builds to a freeze, the cone
## strike shatters the frozen with a nova that chains; ignite burns over
## real frames, bleed punishes walking, a learned Frost Nova page rings from
## its bar slot, a burning death proliferates, and a frozen boss survives a
## shatter as a nova plus a thaw (D-016). The sim owns every number; this
## test asserts the engine wiring obeys them (ADR-0003). Quits non-zero on
## failure.

const PLAYER_SCENE := preload("res://scenes/player.tscn")

var _player: WroughtwildPlayer
var _sim: WroughtwildSim
var _frame := 0
var _failures := 0
var _checks := 0

# Actors cast in one phase and checked frames later.
var _line: Array = []
var _burn_life := 0.0
var _bleed_baseline: Array = []


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
			_phase_e_ignite()
		245:
			_phase_e_checks()
		250:
			_phase_f_bleed()
		290:
			_phase_f_checks()
		300:
			_phase_g_nova_page()
		310:
			_phase_h_proliferate_and_boss()
		320:
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


## Phase E - ignite: three bolt-strength applications set a whelp burning;
## over the following real frames the burn ticks fire damage on its own.
func _phase_e_ignite() -> void:
	_face_down_range()
	var whelp: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, -6.0))
	var amount: float = _sim.ignite_applied("prototype_ember_bolt", false)
	whelp.apply_ignite(amount)
	whelp.apply_ignite(amount)
	check(whelp.burning_left <= 0.0, "ignite: two bolts do not ignite")
	whelp.apply_ignite(amount)
	check(whelp.burning_left > 0.0, "ignite: the third bolt sets the whelp burning")
	_line = [whelp]
	_burn_life = whelp.life


func _phase_e_checks() -> void:
	var whelp: Enemy = _line[0]
	check(is_instance_valid(whelp) and whelp.life < _burn_life,
		"ignite: the burn ticks fire damage over real frames")
	check(is_instance_valid(whelp) and whelp.life > 0.0,
		"ignite: the base burn does not kill a whelp outright")
	_clear_enemies()


## Phase F - bleed: two rend-strength applications open the wound; a whelp
## that keeps walking bleeds moving_multiplier times harder than one held
## still (frozen zeroes its feet, so it pays the standing rate).
func _phase_f_bleed() -> void:
	_face_down_range()
	var mover: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(-1.0, 0.6, -9.0))
	var stander: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(1.0, 0.6, -9.0))
	stander.apply_chill(1000.0)
	var amount: float = _sim.bleed_applied("prototype_rend", false)
	for node in [mover, stander]:
		var enemy := node as Enemy
		enemy.apply_bleed(amount)
		check(enemy.bleeding_left <= 0.0, "bleed: one rend does not open the wound")
		enemy.apply_bleed(amount)
		check(enemy.bleeding_left > 0.0, "bleed: the second rend does")
	_line = [mover, stander]
	_bleed_baseline = [mover.life, stander.life]


func _phase_f_checks() -> void:
	var mover: Enemy = _line[0]
	var stander: Enemy = _line[1]
	check(is_instance_valid(mover) and mover.life < _bleed_baseline[0], "bleed: the walking whelp bleeds")
	check(is_instance_valid(stander) and stander.life < _bleed_baseline[1], "bleed: the held whelp bleeds too")
	if is_instance_valid(mover) and is_instance_valid(stander):
		var moving_loss: float = _bleed_baseline[0] - mover.life
		var standing_loss: float = _bleed_baseline[1] - stander.life
		check(moving_loss > standing_loss * 1.8,
			"bleed: walking multiplies the tick (%.1f vs %.1f)" % [moving_loss, standing_loss])
	_clear_enemies()


## Phase G - a skill page in play (D-016): Frost Nova is learned through the
## combat wrapper, assigned to bar slot 2, and cast from it; its 360-degree
## ring chills in front AND behind, which no first-person cone can.
func _phase_g_nova_page() -> void:
	_face_down_range()
	check(not _sim.knows_skill("prototype_frost_nova"), "page: frost nova starts unknown")
	check(_player.combat.learn_skill("prototype_frost_nova"), "page: learned through the combat wrapper")
	check(_player.combat.assign_bar_slot(1, "prototype_frost_nova"), "page: nova assigned to slot 2")
	check(_player.hud.action_bar.slots[1]["skill"] == &"prototype_frost_nova",
		"page: the action bar rebuilt to show it")
	var ahead: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, -2.2))
	var behind: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, 2.2))
	check(_player.combat.use_slot(1), "nova: cast fires from its bar slot")
	check(ahead.chill > 0.0, "nova: chills the whelp in front")
	check(behind.chill > 0.0, "nova: the ring chills the whelp behind too")
	check(ahead.life < ahead.max_life and behind.life < behind.max_life, "nova: the ring also damages")
	_clear_enemies()


## Phase H - proliferate and the boss shatter rule: a burning death spreads
## its fire to the pack; a frozen boss hit by an attack takes one nova and
## thaws instead of being executed (executes_boss false).
func _phase_h_proliferate_and_boss() -> void:
	_face_down_range()
	var carrier: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(0.0, 0.6, -4.0))
	var neighbour: Enemy = Enemy.spawn(self, &"ember_whelp", Vector3(1.5, 0.6, -4.0))
	carrier.apply_ignite(1000.0)
	check(carrier.burning_left > 0.0, "proliferate: the carrier burns")
	carrier.take_damage(100000.0)
	check(neighbour.burning_left > 0.0, "proliferate: the burning death ignites the neighbour outright")
	neighbour.take_damage(100000.0)

	var boss: Boss = Boss.spawn_boss(self, Vector3(0.0, 0.6, -2.0))
	boss.apply_chill(100000.0)
	check(boss.is_frozen(), "boss: enough chill freezes even the boss")
	_player.combat.cooldowns[PlayerCombat.AREA_SKILL] = 0.0
	var hits: int = _player.combat.use_area()
	check(hits == 1, "boss: the strike connects with the frozen boss (%d)" % hits)
	var nova_damage: float = _sim.shatter_for("prototype_area_strike")["nova_damage"]
	check(is_instance_valid(boss) and boss.life > 0.0, "boss: shatter never executes the boss")
	check(is_instance_valid(boss) and not boss.is_frozen(), "boss: the nova breaks the ice instead")
	check(is_instance_valid(boss) and is_equal_approx(boss.life, boss.max_life - nova_damage),
		"boss: the boss takes exactly one nova (%.1f)" % boss.life)
	_clear_enemies()
