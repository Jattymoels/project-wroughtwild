class_name PlayerCombat
extends Node
## The player's real-time combat: life, skill cooldown timers, the dash window
## and hit application. Every number (max life, damage per hit, mitigation)
## is asked of the sim; this node only decides when and whom (ADR-0003).

signal life_changed(life: float, max_life: float)
signal died
## A player hit connected with at least one enemy (HUD hitmarker).
signal hit_landed(total_damage: float, kills: int)
## Damage got through to the player; the HUD names the source so a hit
## from out of sight is never a mystery.
signal hit_taken(damage: float, source_name: String)
## Known skills or the bar changed (page learned, slot assigned, game
## loaded); the action bar rebuilds itself from the sim.
signal loadout_changed

## The four starting skills, named for tests and legacy callers. Everything
## else arrives as a skill page and is addressed through the bar (D-016).
const AREA_SKILL := &"prototype_area_strike"
const HEAVY_SKILL := &"prototype_heavy_strike"
const DASH_SKILL := &"prototype_dash"
const ORB_SKILL := &"prototype_frost_orb"

var player: WroughtwildPlayer
var sim: WroughtwildSim

var max_life := 1.0
var life := 1.0
var skills := {}     # skill id -> sim view (base_damage, cooldown_seconds, ...)
var cooldowns := {}  # skill id -> seconds remaining
var invulnerable_left := 0.0
var melee_reach := 2.0
## First-person area-strike arc (D-012): "area" is the slice of the horde
## you are facing, so training mobs into a bunch is what makes it pay.
var cone_degrees := 360.0
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
	cone_degrees = rt["player"].get("cone_degrees", 360.0)
	dash_invulnerable = rt["dash"]["invulnerable_seconds"]
	dash_duration = rt["dash"]["duration_seconds"]
	fight_seed_source.randomize()
	restore_life()


func restore_life() -> void:
	max_life = sim.derived_stats()["max_life"]
	life = max_life
	life_changed.emit(life, max_life)


## --- shelter regen (Wave 4 building slice 3) ---
## Resting in an enclosed room regenerates life once you have gone the
## settle time without a hit. The sim decides what a shelter is and how
## fast it heals (world.json shelter); this owns the clocks: probing the
## room once a second and paying the regen per frame.
signal shelter_changed(sheltered: bool)
const SHELTER_PROBE_SECONDS := 1.0
var sheltered := false
var _shelter_probe_left := 0.0
var _settle_left := 0.0
var _regen_per_second := 0.0
var _settle_seconds := 0.0
## Home: the last shelter rested in. Encroachment settles on its fringe.
var has_home := false
var home_position := Vector3.ZERO
## Shelter regen multiplier from the world (1 clear, less in a nest's blight).
var rest_multiplier := 1.0


func _tick_shelter(delta: float) -> void:
	_settle_left = maxf(0.0, _settle_left - delta)
	_shelter_probe_left -= delta
	if _shelter_probe_left <= 0.0:
		_shelter_probe_left = SHELTER_PROBE_SECONDS
		if _regen_per_second <= 0.0 and sim != null:
			var rules: Dictionary = sim.shelter()
			var round_seconds: float = sim.realtime().get("round_seconds", 1.0)
			_regen_per_second = float(rules.get("regen_life_per_round", 0.0)) / maxf(round_seconds, 0.01)
			_settle_seconds = float(rules.get("settle_rounds", 0.0)) * round_seconds
		set_sheltered(_probe_shelter())
		if sheltered:
			has_home = true
			home_position = get_parent().global_position
			rest_multiplier = sim.encroachment_rest_multiplier(home_position)
	if sheltered and _settle_left <= 0.0 and life > 0.0 and life < max_life:
		life = minf(max_life, life + _regen_per_second * rest_multiplier * delta)
		life_changed.emit(life, max_life)


func _probe_shelter() -> bool:
	var player := get_parent()
	if player == null or not (player is WroughtwildPlayer):
		return false
	return (player as WroughtwildPlayer).placement.enclosure_at(player.global_position).get("enclosed", false)


func set_sheltered(value: bool) -> void:
	if value == sheltered:
		return
	sheltered = value
	shelter_changed.emit(sheltered)


## True while resting is actually paying out.
func resting() -> bool:
	return sheltered and _settle_left <= 0.0 and life < max_life


func regen_per_second() -> float:
	return _regen_per_second * rest_multiplier


## True while a nest's blight makes the rest uneasy.
func uneasy() -> bool:
	return sheltered and rest_multiplier < 1.0


func _physics_process(delta: float) -> void:
	for id in cooldowns:
		cooldowns[id] = maxf(0.0, cooldowns[id] - delta)
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	_tick_shelter(delta)
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


## The skill's cooldown after gear modifiers (the sim resolves it).
func cooldown_total(skill_id: StringName) -> float:
	if sim != null:
		return sim.skill_cooldown_seconds(String(skill_id))
	return skills.get(skill_id, {}).get("cooldown_seconds", 1.0)


func _spend(skill_id: StringName) -> void:
	cooldowns[skill_id] = cooldown_total(skill_id)


## --- the skill bar (D-016) ---------------------------------------------------
## Skills are learned, not worn: the sim owns which are known and which sit
## on the four bar slots; the keys 1-4 cast whatever sits there, dispatched
## by the skill's delivery shape.

func bar_skills() -> PackedStringArray:
	return sim.skill_bar()


## Casts whatever sits in bar slot `slot` (0-based). False for an empty
## slot, an unknown skill or one still on cooldown.
func use_slot(slot: int) -> bool:
	var bar := sim.skill_bar()
	if slot < 0 or slot >= bar.size() or bar[slot] == "":
		return false
	return use_skill(StringName(bar[slot]))


## The bar slot holding a dash-delivery skill, or -1: Shift is an alias for
## it, so movement keeps its reflex key wherever Dash is slotted.
func dash_slot() -> int:
	var bar := sim.skill_bar()
	for i in bar.size():
		if skills.get(StringName(bar[i]), {}).get("delivery", "") == "dash":
			return i
	return -1


## Casts one skill by id, dispatching on its delivery. The sim owns every
## number; each delivery shape owns its space (ADR-0003).
func use_skill(skill_id: StringName) -> bool:
	var def: Dictionary = skills.get(skill_id, {})
	if def.is_empty() or not is_ready(skill_id):
		return false
	match String(def.get("delivery", "")):
		"cone":
			_use_cone(skill_id)
			return true
		"strike":
			return _use_strike(skill_id)
		"projectile":
			return _use_projectile(skill_id)
		"dash":
			return _use_dash(skill_id)
	return false


## Bar assignment and page learning route through here so the HUD hears
## about it (loadout_changed).
func assign_bar_slot(slot: int, skill_id: String) -> bool:
	if not sim.set_bar_slot(slot, skill_id):
		return false
	loadout_changed.emit()
	return true


func learn_skill(skill_id: String) -> bool:
	if not sim.learn_skill(skill_id):
		return false
	loadout_changed.emit()
	return true


## Named wrappers for the starting four (tests, legacy callers).
func use_area() -> int:
	return _use_cone(AREA_SKILL)


func use_heavy() -> bool:
	return _use_strike(HEAVY_SKILL)


func use_orb() -> bool:
	return _use_projectile(ORB_SKILL)


func use_dash() -> bool:
	return _use_dash(DASH_SKILL)


## Applies the skill's status payload to a struck enemy. Skills without a
## payload apply 0s; a matching add_*_buildup gear roll can still give them
## one (a Frostbite mace chills with plain strikes). Payload lands before
## the damage so a killing blow that ignites leaves a burning corpse for
## proliferate.
func _apply_payload(enemy: Enemy, skill_id: StringName, is_boss: bool) -> void:
	var id := String(skill_id)
	enemy.apply_chill(sim.chill_applied(id, is_boss))
	enemy.apply_ignite(sim.ignite_applied(id, is_boss))
	enemy.apply_bleed(sim.bleed_applied(id, is_boss))


## Cone delivery: every living enemy inside the radius AND inside the arc
## takes one hit (D-012: area is the slice of the horde you are facing).
## A per-skill cone_degrees in combat_realtime.json overrides the player's
## first-person arc - 360 turns the cone into a nova ring. Returns hits.
func _use_cone(skill_id: StringName) -> int:
	if not is_ready(skill_id):
		return 0
	_spend(skill_id)
	var enemies := alive_enemies()
	if enemies.is_empty():
		return 0
	_ensure_fight()
	var isolated := enemies.size() == 1
	var radius: float = skills[skill_id]["base_area_radius"] * (1.0 + sim.derived_stats()["area_bonus"])
	if isolated:
		radius *= sim.combat_mods()["isolated_area_multiplier"]
	var spatial: Dictionary = sim.realtime().get("skills", {}).get(String(skill_id), {})
	var arc: float = spatial.get("cone_degrees", cone_degrees)
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var cone_cos := cos(deg_to_rad(arc / 2.0))
	var hits := 0
	var kills := 0
	var total := 0.0
	var to_shatter: Array = []
	var shatter: Dictionary = sim.shatter_for(String(skill_id))
	for enemy in enemies:
		var to_enemy: Vector3 = enemy.global_position - player.global_position
		to_enemy.y = 0.0
		var distance := to_enemy.length()
		if distance > radius:
			continue
		# Point-blank targets always count; beyond that, the arc decides.
		if distance > 0.6 and forward.dot(to_enemy / distance) < cone_cos:
			continue
		# The shatter hook: frozen enemies hit by a trigger skill shatter
		# instead of taking the ordinary hit.
		if shatter.get("enabled", false) and enemy.is_frozen():
			to_shatter.append(enemy)
			hits += 1
			continue
		_apply_payload(enemy, skill_id, enemy is Boss)
		last_hit_dealt = sim.player_hit_damage(skill_id, isolated)
		total += last_hit_dealt
		enemy.take_damage(last_hit_dealt)
		if enemy.life <= 0.0:
			kills += 1
		hits += 1

	var cascade := _shatter_cascade(to_shatter, shatter)
	total += cascade["damage"]
	kills += cascade["kills"]
	if hits > 0:
		hit_landed.emit(total, kills)
	return hits


## Strike delivery: the nearest living enemy in front within melee reach.
func _use_strike(skill_id: StringName) -> bool:
	if not is_ready(skill_id):
		return false
	_spend(skill_id)
	var target := _nearest_enemy_in_front(melee_reach)
	if target == null:
		return false
	_ensure_fight()
	# An attack on a frozen target cashes in the shatter combo instead.
	var shatter: Dictionary = sim.shatter_for(String(skill_id))
	if shatter.get("enabled", false) and target.is_frozen():
		var cascade := _shatter_cascade([target], shatter)
		hit_landed.emit(cascade["damage"], cascade["kills"])
		return true
	_apply_payload(target, skill_id, target is Boss)
	last_hit_dealt = sim.player_hit_damage(skill_id, alive_enemies().size() == 1)
	target.take_damage(last_hit_dealt)
	hit_landed.emit(last_hit_dealt, 1 if target.life <= 0.0 else 0)
	return true


## Projectile delivery: fires from the eyes so first-person aim is the
## delivery; flight, forks and payload live in SkillProjectile.
func _use_projectile(skill_id: StringName) -> bool:
	if not is_ready(skill_id):
		return false
	_spend(skill_id)
	_ensure_fight()
	var from: Vector3 = player.camera.global_position - player.camera.global_transform.basis.z * 0.6
	var dir: Vector3 = -player.camera.global_transform.basis.z
	SkillProjectile.launch(skill_id, self, player.world_root(), from, dir, 0, [])
	return true


## Dash delivery: a burst forward. Pure movement (D-012) - position, not
## i-frames, is the defence.
func _use_dash(skill_id: StringName) -> bool:
	if not is_ready(skill_id):
		return false
	_spend(skill_id)
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	_dash_velocity = forward * (skills[skill_id].get("distance", 4.0) / dash_duration)
	_dash_left = dash_duration
	invulnerable_left = dash_invulnerable
	return true


## Shatter cascade: each shattered mob dies releasing a cold nova; other
## FROZEN mobs inside the nova shatter too, so a frozen train chains down
## its own line. Every mob shatters at most once. A frozen boss takes the
## nova and thaws instead of dying, unless executes_boss is tuned on - the
## freeze window is the reward, not a one-shot.
func _shatter_cascade(to_shatter: Array, shatter: Dictionary) -> Dictionary:
	var total := 0.0
	var kills := 0
	var shattered := {}
	while not to_shatter.is_empty():
		var victim: Enemy = to_shatter.pop_front()
		if not is_instance_valid(victim) or shattered.has(victim.get_instance_id()):
			continue
		shattered[victim.get_instance_id()] = true
		var at: Vector3 = victim.global_position
		_spawn_nova(at, shatter["nova_radius_m"])
		var executes: bool = shatter.get("executes_frozen", true) \
			and (shatter.get("executes_boss", false) or not (victim is Boss))
		if executes:
			total += victim.life
			victim.take_damage(victim.life)
			kills += 1
		else:
			victim.thaw()
			total += shatter["nova_damage"]
			victim.take_damage(shatter["nova_damage"])
			if victim.life <= 0.0:
				kills += 1
		for other in alive_enemies():
			if shattered.has(other.get_instance_id()) or to_shatter.has(other):
				continue
			if _planar_distance(other.global_position, at) > shatter["nova_radius_m"]:
				continue
			if other.is_frozen():
				to_shatter.append(other)
			else:
				total += shatter["nova_damage"]
				other.take_damage(shatter["nova_damage"])
				if other.life <= 0.0:
					kills += 1
	return {"damage": total, "kills": kills}


## A brief expanding ice sphere where a mob shattered (greybox VFX).
func _spawn_nova(at: Vector3, radius: float) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.6, 0.85, 1.0, 0.55)
	material.emission_enabled = true
	material.emission = Color(0.6, 0.85, 1.0)
	sphere.material = material
	mesh.mesh = sphere
	player.world_root().add_child(mesh)
	mesh.global_position = at + Vector3(0, 0.5, 0)
	var tween := mesh.create_tween()
	tween.tween_property(mesh, "scale", Vector3.ONE * radius * 2.0, 0.22)
	tween.parallel().tween_property(mesh, "transparency", 1.0, 0.22)
	tween.tween_callback(mesh.queue_free)


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


## An enemy's raw hit arrives here; the sim decides what gets through.
func take_hit(raw_damage: float, damage_type: String, source_name := "") -> float:
	if invulnerable_left > 0.0 or life <= 0.0:
		return 0.0
	_ensure_fight()
	last_hit_taken = sim.enemy_hit_damage(raw_damage, damage_type)
	life = maxf(0.0, life - last_hit_taken)
	_settle_left = _settle_seconds
	life_changed.emit(life, max_life)
	hit_taken.emit(last_hit_taken, source_name)
	if life <= 0.0:
		died.emit()
	return last_hit_taken
