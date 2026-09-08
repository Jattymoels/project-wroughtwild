class_name Enemy
extends CharacterBody3D
## A world enemy. Its numbers (life, damage, cadence) come from the sim's
## enemy definition and its movement, ranges and wind-up from the sim's
## realtime table (ADR-0003). It never computes damage: when an attack lands
## it hands the raw hit to the player's combat component, which asks the sim
## what actually gets through.

signal died(enemy: Enemy)
## Presentation event at the existing attack instant, including a missed blow.
signal attack_released(kind: String)
const SHOT_LOOK = preload("res://art/enemy_shot_look.tres")

## True for a trial room's own enemies: the room contains, counts and
## clears only these, never a roaming pack that wandered near the arena.
var trial_bound := false
var trial_encounter_id := ""
var trial_dungeon: Node3D
var trial_controller: Node
var trial_ward_radius := 0.0
var trial_ward_strength := 0.0
var trial_guard_multiplier := 1.0
var _trial_path := PackedVector3Array()
var _trial_path_left := 0.0
## Grazers (behaviour flees): run within aggro range, never attack.
var flees := false


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
var visual_id := ""
var influence := ""
var release_shape := ""
var release_seconds := 0.0
var release_distance := 0.0
var release_radius := 0.0
var recovery_seconds := 0.0
var _release_left := 0.0
var _release_hit := false
var _frontier_recovery_left := 0.0
var max_life := 1.0
var life := 1.0
var damage := 0.0
var damage_type := "physical"
var move_speed := 3.0
var attack_range := 1.5
var preferred_distance := 0.0
var aggro_range := 10.0
var base_aggro_range := 10.0
var windup_seconds := 0.3
var windup_advance := 0.0
var attack_arc_degrees := 360.0
var _strike_direction := Vector3.ZERO
## Spatial delivery is opted into by behaviour data, never by enemy id.
var projectile_rules: Dictionary = {}
var _shot_aim := Vector3.ZERO
var _shot_tell: MeshInstance3D
var _shot_clearance_shape: SphereShape3D
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
## Roaming (Wave 7 slice 1): an idle mob of a patrolling pack walks toward
## where its pack should be, at a walk, and stops when it gets there.
const ROAM_SPEED_FRACTION := 0.55
var roam_target := Vector3.ZERO
var _roaming := false
## The siege (Wave 7 slice 3): a mob that came to the lamp, gone with the
## dawn; and one pressed against a placed piece scratches at it - the
## house shakes and says so - and a breaker (an era mechanic) wears
## timber down until it gives.
var siege := false
var breaks_timber := false
var _scratch_timer := 0.0
## The verb (Wave 8 slice 1, equal threat, different shape): the one thing
## this family does that changes how you fight. The sim says which and how
## much (combat_realtime.json behaviours); this does it.
var verb := ""
var verb_seconds := 0.0
var verb_strength := 0.0
var verb_radius := 0.0
var verb_arc := 0.0
var verb_cap := 0.0
## Kindled by a wisp: the bonus its burning bite carries.
var kindled_bonus := 0.0
var _kindle_timer := 0.0
## How many allies a kindler lights at once (the deep's wisps light two).
var kindle_count := 1
var _aura: MeshInstance3D

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
## Seconds since something hurt this mob (packs sleep only when calm).
var since_hurt := 1e9
var _immune_statuses := PackedStringArray()
## The family's share of each packet type, its elite prefix's multiplied
## in (D-023 slice 2; world.json damage_taken): a hollow suit takes a
## quarter of fire, so a two-element hit lands mostly its other packet.
## Types not named land whole; 0 would be immunity.
var _damage_taken := {}
var _burst_damage := 0.0
## Sear (a form): how much faster the current burn ticks while walking and bleeding.
var _sear := 0.0
## A stagger (the Riposte rail, D-023 slice 9; melee, Wave 5 item 11):
## seconds the mob stands halted. A shove: the displacement still owed
## to a blow, paid over SHOVE_SECONDS.
var _stagger_left := 0.0
var _shove_left := Vector3.ZERO
const SHOVE_SECONDS := 0.12
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
var smoulder_slow := 0.0
var burn_release_ready := 0.0
var _rime_bind_left := 0.0
var _rime_bind_loss := 0.0
var _reservoir_left := 0.0
var _wound_memory_left := 0.0
var _wound_memory_used := false
var _foundry_marks := {}
var _burn_mutation := {}
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
	# Findable from the frame it appears (a scream in the same frame counts).
	MobGrid.register(self)


func configure(sim: WroughtwildSim) -> void:
	var def: Dictionary = sim.enemy(enemy_id)
	if def.is_empty():
		push_error("Enemy: unknown enemy id %s" % enemy_id)
		return
	display_name = def["display_name"]
	behaviour = def["behaviour"]
	visual_id = String(def.get("visual_id", ""))
	influence = String(def.get("influence", ""))
	max_life = def["max_life"]
	life = max_life
	damage = def["damage"]
	damage_type = def["damage_type"]

	var rt: Dictionary = sim.realtime()
	var b: Dictionary = rt["behaviours"].get(behaviour, {})
	release_shape = String(b.get("release_shape", ""))
	release_seconds = float(b.get("release_seconds", 0.0))
	release_distance = float(b.get("release_distance_m", 0.0))
	release_radius = float(b.get("release_radius_m", 0.0))
	recovery_seconds = float(b.get("recovery_seconds", 0.0))
	# The hastened weakness quickens both feet and attacks in real time.
	var speed_multiplier: float = sim.combat_mods()["enemy_speed_multiplier"]
	flees = b.get("flees", false)
	move_speed = b.get("move_speed_mps", 3.0) * speed_multiplier
	attack_range = b.get("attack_range_m", 1.5)
	preferred_distance = b.get("preferred_distance_m", 0.0)
	aggro_range = b.get("aggro_range_m", 10.0)
	base_aggro_range = aggro_range
	windup_seconds = b.get("windup_seconds", 0.3)
	windup_advance = b.get("windup_advance_m", 0.0)
	attack_arc_degrees = b.get("attack_arc_degrees", 360.0)
	projectile_rules = b.get("projectile", {})
	attack_period_seconds = def["attack_period_rounds"] * rt["round_seconds"] / speed_multiplier
	give_up_distance = b.get("give_up_distance_m", 0.0)
	verb = String(b.get("verb", ""))
	verb_seconds = float(b.get("verb_seconds", 0.0))
	verb_strength = float(b.get("verb_strength", 0.0))
	verb_radius = float(b.get("verb_radius_m", 0.0))
	verb_arc = float(b.get("verb_arc_degrees", 0.0))
	verb_cap = float(b.get("verb_cap", 0.0))
	_scream_period = b.get("scream_period_seconds", 0.0)
	_scream_radius = b.get("scream_radius_m", 0.0)
	# Era mechanics: the shriekers call further as the world wakes.
	_scream_radius += float(sim.era_mechanic(enemy_id, "scream_radius_bonus").get("value", 0.0))
	breaks_timber = not sim.era_mechanic(enemy_id, "breaks_timber").is_empty()
	# The eras transform the verbs (Wave 8 slice 3): the deep's husks guard
	# wider and its wisps light two; the tide's lurkers hold longer and its
	# knights ward harder.
	verb_arc += float(sim.era_mechanic(enemy_id, "guard_arc_bonus").get("value", 0.0))
	verb_seconds += float(sim.era_mechanic(enemy_id, "root_bonus_seconds").get("value", 0.0))
	verb_strength += float(sim.era_mechanic(enemy_id, "ward_bonus").get("value", 0.0))
	kindle_count = 1 + int(sim.era_mechanic(enemy_id, "kindle_two").get("value", 0.0))
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
		# The verbs read at a glance too (Wave 8 slice 1): the guard stone
		# grey, the swarm the dark's violet, the lurker bog green, the
		# kindler ember gold, the warden a pale iron.
		"guard": _material.albedo_color = Color(0.5, 0.5, 0.56)
		"swarm": _material.albedo_color = Color(0.32, 0.24, 0.42)
		"lurker": _material.albedo_color = Color(0.24, 0.42, 0.3)
		"skirmisher": _material.albedo_color = Color(0.95, 0.62, 0.2)
		"knight": _material.albedo_color = Color(0.62, 0.58, 0.72)
		_: _material.albedo_color = Color(0.9, 0.45, 0.1)
	_base_albedo = _material.albedo_color
	# A family's own look (world.json tint, size_scale) over the behaviour's default.
	# A family's own immunities (elites add theirs on top in make_elite).
	_immune_statuses = PackedStringArray(def.get("immune_statuses", PackedStringArray()))
	_damage_taken = Dictionary(def.get("damage_taken", {})).duplicate()
	var tint: String = def.get("tint", "")
	if tint != "":
		_material.albedo_color = Color(tint)
		_base_albedo = _material.albedo_color
	var size_scale: float = float(def.get("size_scale", 1.0))
	if _mesh != null:
		_mesh.scale = Vector3.ONE * size_scale
	_mesh.material_override = _material
	_mesh.mesh = preload("res://art/character_look.tres").build("grazer" if flees else behaviour)
	_mesh.position.y = 0.0
	# Humanoid roles fit the existing 1.3m body; beasts are authored at that height.
	if not behaviour in ["fast", "melee", "swarm", "lurker"] and not flees and visual_id.is_empty():
		_mesh.scale *= 0.76
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 1.0
	CreatureMotion.attach(_mesh,self,"grazer" if flees else behaviour)
	if not influence.is_empty(): FrontierHostLook.attach(self)
	_label.position.y = _mesh.mesh.get_aabb().end.y * _mesh.scale.y + 0.25
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
	_immune_statuses.append_array(mod.get("immune_statuses", PackedStringArray()))
	var taken: Dictionary = mod.get("damage_taken", {})
	for type in taken:
		_damage_taken[type] = float(_damage_taken.get(type, 1.0)) * float(taken[type])
	_burst_damage = mod.get("death_burst_damage", 0.0)
	_burst_radius = mod.get("death_burst_radius_m", 0.0)
	_burst_type = mod.get("death_burst_type", "fire")
	if _mesh != null:
		_mesh.scale *= 1.3
		_label.position.y = _mesh.mesh.get_aabb().end.y * _mesh.scale.y + 0.25
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
## quench (a form, D-023): a burning mob this freeze catches takes the
## rest of its burn at once.
func apply_chill(amount: float, quench: bool = false) -> void:
	if amount <= 0.0 or is_frozen() or life <= 0.0 or _immune_statuses.has("chill"):
		return
	chill += amount
	if chill >= _chill_max:
		chill = 0.0
		frozen_left = _freeze_duration * (float(_sim.combat_mods().get("ailment_duration_multiplier",1)) if trial_bound else 1.0)
		_on_frozen()
		if quench and burning_left > 0.0:
			var rest := _burn_dps * burning_left
			burning_left = 0.0
			take_typed(rest, "fire")
		_refresh_look()


## Interrupts whatever the enemy was doing when it froze. Boss extends this
## to cancel an inhale.
func _on_frozen() -> void:
	_windup_left = 0.0
	if not release_shape.is_empty(): _cancel_release()

func _cancel_release() -> void:
	_release_left = 0.0
	_release_hit = true
	_frontier_recovery_left = recovery_seconds
	state = "recover"


## Ignite buildup; crossing the threshold sets the mob burning. Duration and
## tick are snapshotted from the sim at ignition, so the burn a mob carries
## reflects the gear that lit it. Re-igniting refreshes, never stacks.
## sear (a form, D-023): the burn this ignition lights ticks that much
## faster while the mob walks and bleeds; snapshotted like the tick.
## spread (the Pyre rail, D-023 slice 9): when this ignition crosses the
## threshold, the fire proliferates at once at this fraction of the
## death-spread; the mobs it reaches get no spread of their own.
func apply_ignite(amount: float, sear: float = 0.0, spread: float = 0.0, mutation := {}) -> void:
	if amount <= 0.0 or life <= 0.0 or _immune_statuses.has("ignite"):
		return
	ignite += amount
	if ignite >= _ignite_max:
		ignite = 0.0
		var rules: Dictionary = _sim.ignite_status() if _sim != null else {}
		burning_left = float(mutation.get("burn_seconds", rules.get("duration_s", 4.0)))
		if trial_bound: burning_left*=float(_sim.combat_mods().get("ailment_duration_multiplier",1))
		_burn_dps = float(mutation.get("burn_dps", rules.get("damage_per_s", 0.0)))
		_burn_mutation = mutation.duplicate(true)
		smoulder_slow = float(mutation.get("smoulder_slow", 0))
		if self is Boss: smoulder_slow *= float(mutation.get("limits", {}).get("boss_slow_factor", 0.25))
		if _immune_statuses.has("chill"): smoulder_slow = 0.0
		_sear = sear
		_refresh_look()
		if spread > 0.0:
			_proliferate(spread)


## A stagger (the Riposte rail, D-023 slice 9): the mob halts for a moment
## and loses its wind-up. A freeze still outranks it.
func stagger(seconds: float) -> void:
	if seconds <= 0.0 or life <= 0.0:
		return
	_stagger_left = maxf(_stagger_left, seconds)
	if not release_shape.is_empty():
		_cancel_release()
		return
	_windup_left = 0.0
	if state == "windup":
		state = "chase"


## True while a blow has this mob halted (tests, and the HUD's tells).
func staggered() -> bool:
	return _stagger_left > 0.0


## A shove (melee, Wave 5 item 11): the mob owes `metres` of movement along
## `direction`, paid over the next SHOVE_SECONDS whatever it was doing -
## staggered or not. The sim says how far; this pays it.
func shove(direction: Vector3, metres: float) -> void:
	if metres <= 0.0 or life <= 0.0:
		return
	var planar := Vector3(direction.x, 0.0, direction.z)
	if planar.length_squared() < 0.0001:
		return
	_shove_left += planar.normalized() * metres


## Adds this frame's share of the shove to the velocity, called before
## every move_and_slide so a halted or fleeing mob is shoved too.
func _apply_shove(delta: float) -> void:
	if _shove_left.length_squared() < 0.000001:
		_shove_left = Vector3.ZERO
		return
	var share := minf(1.0, delta / SHOVE_SECONDS)
	var step := _shove_left * share
	_shove_left -= step
	velocity.x += step.x / maxf(delta, 0.0001)
	velocity.z += step.z / maxf(delta, 0.0001)


## True while this mob is moving toward the point (the Hound's Manner).
func approaching(point: Vector3) -> bool:
	var planar := Vector2(velocity.x, velocity.z)
	if planar.length() < 0.5:
		return false
	return planar.dot(Vector2(point.x - global_position.x, point.z - global_position.z)) > 0.0


## Bleed buildup; crossing the threshold opens a wound that ticks harder
## while the mob walks (the chasing train pays for chasing).
func apply_bleed(amount: float) -> void:
	if amount <= 0.0 or life <= 0.0 or _immune_statuses.has("bleed"):
		return
	bleed += amount
	if bleed >= _bleed_max:
		bleed = 0.0
		if bleeding_left<=0:
			_wound_memory_used=false
			_wound_memory_left=0
		var rules: Dictionary = _sim.bleed_status() if _sim != null else {}
		bleeding_left = rules.get("duration_s", 5.0)
		if trial_bound: bleeding_left*=float(_sim.combat_mods().get("ailment_duration_multiplier",1))
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
	var held_chill := minf(maxf(delta,0),_reservoir_left)
	_reservoir_left=maxf(0,_reservoir_left-maxf(delta,0))
	_rime_bind_left=maxf(0,_rime_bind_left-maxf(delta,0))
	if _flash_left > 0.0:
		_flash_left -= delta
		if _flash_left <= 0.0:
			_refresh_look()

	# DoTs tick even through ice: freeze holds the mob, not the fire.
	var walking := Vector2(velocity.x, velocity.z).length() > 0.5
	if burning_left > 0.0:
		var burn_elapsed := minf(maxf(delta, 0), burning_left)
		burning_left -= burn_elapsed
		var burn_rate := _burn_dps
		if _sear > 0.0 and walking and bleeding_left > 0.0:
			burn_rate *= 1.0 + _sear
		take_typed(burn_rate * burn_elapsed, "fire", false)
		if burning_left <= 0.0:
			_refresh_look()
	else:
		ignite = maxf(0.0, ignite - _ignite_decay * delta)
	if bleeding_left > 0.0:
		var moving := Vector2(velocity.x, velocity.z).length() > 0.5
		var held := minf(maxf(delta,0),_wound_memory_left) if not moving else 0.0
		_wound_memory_left-=held
		var elapsed := minf(maxf(delta-held,0),bleeding_left)
		bleeding_left-=elapsed
		var mult := _bleed_move_mult if moving else 1.0
		take_damage(_bleed_dps * mult * elapsed, false)
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
	chill = maxf(0.0, chill - _chill_decay * maxf(0,delta-held_chill))
	# Staggered: halted like a freeze, briefly, without the ice.
	_stagger_left = maxf(0.0, _stagger_left - delta)
	return _stagger_left > 0.0


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
	elif burning_left > 0.0 and smoulder_slow > 0.0:
		_material.albedo_color = _base_albedo.lerp(Color("839b9b"), 0.5)
		_material.emission_enabled = true
		_material.emission = Color("b25d36")
		_material.emission_energy_multiplier = 0.7
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
	RecoveredActorArt.refresh_material(self)


## A burning mob's death spreads its fire (the proliferate hook): every mob
## within the sim's radius receives spread buildup, bosses through their
## resistance. A dense pack burns down from one kill.
func _proliferate(fraction: float = 1.0) -> void:
	if _sim == null:
		return
	var params: Dictionary = _sim.proliferate_for()
	if not params.get("enabled", false):
		return
	var radius: float = params.get("radius_m", 0.0)
	for node in MobGrid.near(global_position, radius, self):
		if not (node is Enemy):
			continue
		var other := node as Enemy
		if global_position.distance_to(other.global_position) > radius:
			continue
		var key := "spread_buildup_boss" if other is Boss else "spread_buildup"
		other.apply_ignite(float(params.get(key, 0.0)) * fraction, _sear, 0.0, _burn_mutation)


## True while nothing is happening to this mob: a pack of these may sleep.
func calm() -> bool:
	return (state == "idle" or state == "flee") and life > 0.0 and not trial_bound


## The night widens the wake (Wave 6 slice 5): the packs' multiplier over
## the behaviour's aggro range.
func set_aggro_multiplier(multiplier: float) -> void:
	aggro_range = base_aggro_range * multiplier


func _physics_process(delta: float) -> void:
	MobGrid.register(self)
	since_hurt += delta
	_refresh_aura()
	if not is_on_floor():
		velocity += get_gravity() * delta
	if _tick_statuses(delta):
		_update_shot_tell()
		velocity.x = 0.0
		velocity.z = 0.0
		_apply_shove(delta)
		move_and_slide()
		return

	var player := _find_player()
	if player == null:
		_apply_shove(delta)
		move_and_slide()
		return

	var distance := _horizontal_distance_to(player)
	# The 3D world's rule: a floor or a cliff between us means no aggro, no
	# bite, and (after give_up_seconds) no interest. Cave dwellers under
	# your feet stay in their cave until you drop in.
	var in_reach := _vertical_gap_to(player) <= vertical_reach
	_attack_cooldown = maxf(0.0, _attack_cooldown - delta)
	var planar := Vector3.ZERO
	var release_strike := false
	var release_contact := false
	var release_from := global_position

	# Grazers: the state machine turned around. Near you they bolt, far
	# from you they settle, and they never wind up a bite.
	if flees:
		if state == "chase" or state == "windup":
			state = "flee"
		if state == "idle" and distance <= aggro_range and in_reach:
			state = "flee"
		elif state == "flee" and distance > give_up_distance:
			state = "idle"
		if state == "flee":
			planar = -_chase_direction(player, distance) * move_speed + _separation_push()
		planar *= status_move_multiplier()
		velocity.x = planar.x
		velocity.z = planar.z
		_hop_if_blocked(planar)
		if planar.length_squared() > 0.0001:
			look_at(global_position + Vector3(planar.x, 0.0, planar.z), Vector3.UP)
		_apply_shove(delta)
		move_and_slide()
		return

	match state:
		"idle":
			if distance <= aggro_range and in_reach:
				state = "chase"
				_give_up_timer = 0.0
			elif _roaming:
				planar = _roam_step()
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
				var ready_to_attack := distance <= attack_range and in_reach and _attack_cooldown <= 0.0
				var blocked_attack := ready_to_attack and not _attack_line_clear(player)
				if ready_to_attack and not blocked_attack:
					state = "windup"
					_windup_left = windup_seconds
					_strike_direction = (player.global_position - global_position) * Vector3(1,0,1)
					_strike_direction = _strike_direction.normalized()
					if not projectile_rules.is_empty():
						_shot_aim = player.global_position
				else:
					planar = _chase_direction(player, distance, blocked_attack) * move_speed * chase_speed_multiplier(player)
		"windup":
			# A short physical step along the direction shown at commitment.
			# Slow, collision and stagger still apply; neither the step nor bite tracks a dodge.
			if projectile_rules.is_empty() and windup_advance > 0.0:
				planar = _strike_direction * windup_advance / windup_seconds * minf(delta, maxf(0.0, _windup_left)) / delta
			_windup_left -= delta
			if _windup_left <= 0.0:
				# The hit only lands if the player is still in reach: walking
				# out of the wind-up is a legitimate dodge.
				if not release_shape.is_empty():
					_release_left = release_seconds
					_release_hit = false
					state = "release"
					attack_released.emit(release_shape)
					# Radial contact belongs to the warned release instant.
					release_contact = release_shape == "radial"
				elif not projectile_rules.is_empty():
					attack_released.emit("projectile")
					EnemyProjectile.launch(self, _shot_aim, projectile_rules)
					if trial_bound:
						var mods: Dictionary=_sim.combat_mods()
						var extra:=int(mods.get("crossfire_extra_projectiles",0))
						for shot_index in extra:
							var angle:=deg_to_rad(float(mods.get("crossfire_fan_degrees",0)))*(float(shot_index)-float(extra-1)*.5)
							if is_zero_approx(angle): angle=deg_to_rad(float(mods.get("crossfire_fan_degrees",0)))
							EnemyProjectile.launch(self,global_position+(_shot_aim-global_position).rotated(Vector3.UP,angle),projectile_rules)
				else:
					release_strike = true
				_attack_cooldown = attack_period_seconds
				if release_shape.is_empty(): state = "chase"
		"release":
			if release_shape == "charge":
				planar = _strike_direction * release_distance / release_seconds * minf(delta, _release_left) / delta
				release_contact = true
			_release_left = maxf(0.0, _release_left - delta)
			if _release_left <= 0.0:
				_frontier_recovery_left = recovery_seconds
				state = "recover"
		"recover":
			_frontier_recovery_left = maxf(0.0, _frontier_recovery_left - delta)
			if _frontier_recovery_left <= 0.0: state = "chase"

	# Separation steering: chasers shoulder each other apart, so a trained
	# horde forms a physical train instead of a stack of ghosts (D-012).
	if state != "idle" and (release_shape.is_empty() or state == "chase"):
		planar += _separation_push()
		# The kindler lights an ally now and then while it fights.
		if verb == "kindle":
			_kindle_timer -= delta
			if _kindle_timer <= 0.0:
				_kindle_timer = verb_seconds
				kindle_nearest()
		# Shrieker: the aggro chain. While it fights, it recruits.
		if _scream_period > 0.0:
			_scream_timer -= delta
			if _scream_timer <= 0.0:
				force_scream()

	planar *= status_move_multiplier()
	velocity.x = planar.x
	velocity.z = planar.z
	_hop_if_blocked(planar)
	# A charge stops at physical cover instead of climbing over it.
	if release_contact and release_shape == "charge": velocity.y = minf(velocity.y, 0.0)
	_scratch_if_blocked(delta)
	if planar.length_squared() > 0.0001 and distance > 0.05:
		var face := roam_target if state == "idle" and _roaming else player.global_position
		look_at(Vector3(face.x, global_position.y, face.z), Vector3.UP)
	if state == "windup" and not projectile_rules.is_empty():
		var committed_face := Vector3(_shot_aim.x, global_position.y, _shot_aim.z)
		if global_position.distance_squared_to(committed_face) > 0.001:
			look_at(committed_face, Vector3.UP)
	elif (state == "windup" or state == "release" or release_strike or release_contact) and (windup_advance > 0.0 or not release_shape.is_empty()) and not _strike_direction.is_zero_approx():
		look_at(global_position + _strike_direction, Vector3.UP)
	_apply_shove(delta)
	move_and_slide()
	if release_contact and not _release_hit:
		var closest := global_position
		if release_shape == "charge":
			var swept := Geometry2D.get_closest_point_to_segment(Vector2(player.global_position.x, player.global_position.z), Vector2(release_from.x, release_from.z), Vector2(global_position.x, global_position.z))
			closest = Vector3(swept.x, global_position.y, swept.y)
		var offset := (player.global_position - closest) * Vector3(1,0,1)
		if offset.length() <= release_radius and _vertical_gap_to(player) <= vertical_reach and _attack_line_clear(player):
			_release_hit = true
			player.combat.take_hit(bite_damage(), bite_type(), display_name, self)
	if release_strike:
		attack_released.emit("strike")
		var to_player := (player.global_position - global_position) * Vector3(1,0,1)
		var in_arc := attack_arc_degrees >= 360.0 or to_player.is_zero_approx() or _strike_direction.dot(to_player.normalized()) >= cos(deg_to_rad(attack_arc_degrees * .5))
		if to_player.length() <= attack_range * 1.15 and _vertical_gap_to(player) <= vertical_reach and in_arc and _attack_line_clear(player):
			player.combat.take_hit(bite_damage(), bite_type(), display_name, self)
	_update_shot_tell()


func _attack_line_clear(player: Node3D) -> bool:
	if not projectile_rules.is_empty():
		# A thin sight ray can clear a corner that still catches the physical shot.
		if _shot_clearance_shape == null:
			_shot_clearance_shape = SphereShape3D.new()
			_shot_clearance_shape.radius = float(projectile_rules["radius_m"])
		var shot_query := PhysicsShapeQueryParameters3D.new()
		shot_query.shape = _shot_clearance_shape
		shot_query.transform = Transform3D(Basis.IDENTITY,global_position+Vector3.UP*float(projectile_rules["muzzle_height_m"]))
		shot_query.motion = player.global_position-shot_query.transform.origin
		shot_query.collision_mask = collision_mask
		shot_query.exclude = [get_rid(),player.get_rid()]
		var space := get_world_3d().direct_space_state
		if not space.intersect_shape(shot_query,1).is_empty(): return false
		return space.cast_motion(shot_query)[0] >= 1.0
	# Body-centre line: floors/walls/cover must stop a bite as they stop a shot.
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * .65, player.global_position)
	query.exclude = [self]
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return hit.is_empty() or hit.get("collider") == player


func _update_shot_tell() -> void:
	if projectile_rules.is_empty():
		return
	if not is_instance_valid(_shot_tell):
		_shot_tell = EnemyProjectile.make_head(projectile_rules)
		add_child(_shot_tell)
		_shot_tell.position = Vector3(0, float(projectile_rules["muzzle_height_m"]), 0)
	_shot_tell.visible = state == "windup" and life > 0.0 and not staggered()
	var charge := clampf(1.0 - _windup_left / maxf(windup_seconds, 0.001), 0.0, 1.0)
	_shot_tell.scale = Vector3.ONE * lerpf(SHOT_LOOK.charge_start_scale, SHOT_LOOK.charge_end_scale, charge)


## A chaser pressed against a placed piece scratches at it once a second.
func _scratch_if_blocked(delta: float) -> void:
	_scratch_timer = maxf(0.0, _scratch_timer - delta)
	if state == "idle" or _scratch_timer > 0.0 or not is_on_wall():
		return
	for i in get_slide_collision_count():
		var block := get_slide_collision(i).get_collider() as PlacedBlock
		if block == null:
			continue
		_scratch_timer = 1.0
		block.scratch(breaks_timber)
		return


## The pack says where it should be; an idle member walks there.
func roam_to(target: Vector3) -> void:
	roam_target = target
	_roaming = true


func stop_roaming() -> void:
	_roaming = false


func roaming() -> bool:
	return _roaming


func _roam_step() -> Vector3:
	var to := roam_target - global_position
	to.y = 0.0
	if to.length() < 1.2:
		return Vector3.ZERO
	return to.normalized() * move_speed * ROAM_SPEED_FRACTION


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
	for node in MobGrid.near(global_position, separation_radius, self):
		if not (node is Enemy):
			continue
		var away: Vector3 = global_position - (node as Enemy).global_position
		away.y = 0.0
		var d := away.length()
		if d < 0.001 or d >= separation_radius:
			continue
		push += (away / d) * (1.0 - d / separation_radius)
	return push * separation_strength


func _chase_direction(player: Node3D, distance: float, blocked_attack := false) -> Vector3:
	var to_player := player.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() < 0.0001:
		return Vector3.ZERO
	to_player = to_player.normalized()
	if trial_bound and is_instance_valid(trial_dungeon):
		var needs_path := blocked_attack or preferred_distance<=0 or distance>preferred_distance+.5
		# Melee, distant shooters and known blocked attacks already require a path.
		# Only test sight when it can change that decision.
		if not needs_path:
			var ray:=PhysicsRayQueryParameters3D.create(global_position+Vector3.UP,player.global_position+Vector3.UP)
			ray.exclude=[self]
			var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
			needs_path = not hit.is_empty() and hit.get("collider")!=player
		if needs_path:
			_trial_path_left-=get_physics_process_delta_time()
			if _trial_path_left<=0:
				_trial_path=trial_dungeon.path(global_position,player.global_position)
				_trial_path_left=preload("res://art/forge_look.tres").path_refresh_seconds
			while _trial_path.size()>1 and Vector2(_trial_path[0].x-global_position.x,_trial_path[0].z-global_position.z).length()<preload("res://art/forge_look.tres").path_arrival_distance:
				_trial_path.remove_at(0)
			if not _trial_path.is_empty():
				var toward:=_trial_path[0]-global_position
				toward.y=0
				if toward.length_squared()>.04: return toward.normalized()
	if preferred_distance > 0.0 and not blocked_attack:
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
	for node in MobGrid.near(global_position, _scream_radius, self):
		if not (node is Enemy):
			continue
		var other := node as Enemy
		if other.state != "idle" or other.life <= 0.0:
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
		player.combat.take_hit(_burst_damage, _burst_type, display_name, self)


## Test hook: resolves an attack immediately, ignoring range and wind-up.
func force_attack() -> float:
	var player := _find_player()
	if player == null:
		return 0.0
	_attack_cooldown = attack_period_seconds
	state = "chase"
	return player.combat.take_hit(bite_damage(), bite_type(), display_name, self)


## --- the verbs (Wave 8 slice 1) ---
## What this bite is worth right now: the swarm's allies and the kindle's
## fire on top of the family's damage.
func bite_damage() -> float:
	var out := damage * swarm_multiplier()
	if burning_left > 0.0 and kindled_bonus > 0.0:
		out *= 1.0 + kindled_bonus
	return out


## A kindled, burning mob bites with fire.
func bite_type() -> String:
	return "fire" if burning_left > 0.0 and kindled_bonus > 0.0 else damage_type


## Marked by an archer, the hunters (the harriers, the kindlers) sprint.
func chase_speed_multiplier(player: Node) -> float:
	if player == null or not (player is WroughtwildPlayer) or (verb != "harry" and verb != "kindle"):
		return 1.0
	return (player as WroughtwildPlayer).combat.marked_sprint()


## Guard: its front takes less from a hit that comes from `from`, until a
## stagger drops the guard.
func guards_against(from: Vector3) -> bool:
	if verb != "guard" or staggered() or life <= 0.0:
		return false
	var facing := -global_transform.basis.z
	facing.y = 0.0
	var to := from - global_position
	to.y = 0.0
	if facing.length_squared() < 0.0001 or to.length_squared() < 0.0001:
		return false
	return facing.normalized().angle_to(to.normalized()) <= deg_to_rad(verb_arc) * 0.5


## Ward: this mob shields the allies within its reach while it stands unstaggered.
func wards() -> bool:
	return (verb == "ward" or trial_ward_radius>0) and not staggered() and life > 0.0


## The warden shielding this mob right now (null for none).
func warded_by() -> Enemy:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not (node is Enemy):
			continue
		var other := node as Enemy
		if other.wards() and other.trial_bound==trial_bound and other.global_position.distance_to(global_position) <= maxf(other.verb_radius,other.trial_ward_radius):
			return other
	return null


func warded() -> bool:
	return warded_by() != null


## Swarm: each other swarmer within reach adds to the bite, to the cap.
func swarm_multiplier() -> float:
	if verb != "swarm":
		return 1.0
	var allies := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node == self or not (node is Enemy):
			continue
		var other := node as Enemy
		if other.verb == "swarm" and other.life > 0.0 and other.global_position.distance_to(global_position) <= verb_radius:
			allies += 1
	return 1.0 + minf(verb_cap, verb_strength * allies)


## Kindle: lights the nearest unlit allies within reach - one, or two once
## the deep wakes. Returns the first lit (null for none).
func kindle_nearest() -> Enemy:
	if verb != "kindle":
		return null
	var first: Enemy = null
	for i in kindle_count:
		var best: Enemy = null
		var best_d := verb_radius
		for node in get_tree().get_nodes_in_group("enemies"):
			if node == self or not (node is Enemy):
				continue
			var other := node as Enemy
			if other.life <= 0.0 or other.verb == "kindle" or other.burning_left > 0.0:
				continue
			var d := other.global_position.distance_to(global_position)
			if d <= best_d:
				best_d = d
				best = other
		if best == null:
			break
		best.kindle(verb_strength)
		if is_inside_tree():
			PulseRing.burst(get_parent(), best.global_position + Vector3(0, 0.3, 0), 1.2, Color(1.0, 0.6, 0.2, 0.5), 0.5)
		if first == null:
			first = best
	return first


## Lit by a wisp: it burns, and its bites burn while it does.
func kindle(bonus: float) -> void:
	kindled_bonus = bonus
	apply_ignite(_ignite_max)


## The warden's aura: a translucent sphere at its reach while it wards.
func _refresh_aura() -> void:
	if verb != "ward":
		return
	if _aura == null:
		_aura = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = verb_radius
		sphere.height = verb_radius * 2.0
		var material := StandardMaterial3D.new()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color = Color(0.7, 0.7, 0.95, 0.12)
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
		sphere.material = material
		_aura.mesh = sphere
		_aura.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_aura)
	_aura.visible = wards()


## One typed packet of a player's hit (D-023 slice 2), scaled by this
## mob's share of the type. Returns what landed.
func take_typed(amount: float, type: String, flash: bool = true) -> float:
	var landed := amount * damage_taken(type)
	if trial_bound and is_instance_valid(trial_controller):
		landed *= trial_controller.target_multiplier(self)
	if landed <= 0.0 or life <= 0.0:
		return 0.0
	take_damage(landed, flash)
	return landed


## This mob's share of a packet type: 1 for a type not named.
func damage_taken(type: String) -> float:
	return float(_damage_taken.get(type, 1.0))


## The statuses this mob carries right now, for the Ward reading: chill
## building or a freeze, a burn, a wound.
func carried_statuses() -> PackedStringArray:
	var carried := PackedStringArray()
	if chill > 0.0 or is_frozen():
		carried.append("chill")
	if burning_left > 0.0:
		carried.append("ignite")
		if smoulder_slow > 0.0:
			carried.append("smoulder")
			if not carried.has("chill"): carried.append("chill")
	if bleeding_left > 0.0:
		carried.append("bleed")
	return carried


func take_damage(amount: float, flash: bool = true) -> void:
	if life <= 0.0:
		return
	since_hurt = 0.0
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
		if trial_bound: _trial_spread_ailments()
		if burning_left > 0.0:
			_proliferate()
		if _burst_damage > 0.0:
			_death_burst()
		_leave_burning_ground()
		died.emit(self)
		remove_from_group("enemies")
		queue_free()

func _trial_spread_ailments() -> void:
	if _sim==null: return
	var mods: Dictionary=_sim.combat_mods()
	var radius:=float(mods.get("ailment_spread_radius_m",0))
	if radius<=0: return
	var fraction:=float(mods.get("ailment_spread_fraction",0))
	for other in MobGrid.near(global_position,radius,self):
		if not (other is Enemy) or not other.trial_bound or other.life<=0: continue
		if burning_left>0: other.apply_ignite(other._ignite_max*fraction)
		if bleeding_left>0: other.apply_bleed(other._bleed_max*fraction)
		if frozen_left>0 or chill>0: other.apply_chill(other._chill_max*fraction)


func status_move_multiplier() -> float:
	var multiplier := 1.0-smoulder_slow if burning_left>0 else 1.0
	return multiplier*(1.0-_rime_bind_loss) if _rime_bind_left>0 else multiplier
