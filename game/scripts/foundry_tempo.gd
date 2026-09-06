class_name FoundryTempo
extends Node3D
## Authored footwork, attack sequences and spell memories. Native properties
## select operations; terminal packets never cast or enter contact hooks again.
const PROPERTIES := {
	"q_cinder":"identity_tempo_cinder_fraction", "q_frost":"identity_tempo_frost_buildup",
	"q_razor":"identity_tempo_razor_fraction", "q_long":"identity_tempo_long_push",
	"q_living":"identity_tempo_living_life", "q_iron":"identity_tempo_iron_push",
	"q_ward":"identity_tempo_ward_cleanse", "q_after":"identity_tempo_after_fraction",
	"s_cinder":"identity_tempo_s_cinder_fraction", "s_frost":"identity_tempo_s_frost_buildup",
	"s_double":"identity_tempo_s_double_fraction", "s_sweep":"identity_tempo_s_sweep_fraction",
	"s_sustain":"identity_tempo_s_sustain_life", "s_brace":"identity_tempo_s_brace_armour",
	"s_guard":"identity_tempo_s_guard_stagger", "s_step":"identity_tempo_s_step_refund",
	"c_ember":"identity_tempo_c_ember_fraction", "c_frost":"identity_tempo_c_frost_buildup",
	"c_blade":"identity_tempo_c_blade_fraction", "c_wide":"identity_tempo_c_wide_fraction",
	"c_living":"identity_tempo_c_living_life", "c_brace":"identity_tempo_c_brace_armour",
	"c_ward":"identity_tempo_c_ward_charges", "c_after":"identity_tempo_c_after_refund"
}
const CAST_MODES := ["q_frost","q_long","q_iron","q_ward","q_after","s_guard","s_step","c_brace","c_ward","c_after"]
const HIT_MODES := ["q_cinder","q_razor","q_living","s_cinder","s_frost","s_double","s_sweep","s_sustain","s_brace","c_ember","c_frost","c_blade","c_wide"]
var combat: PlayerCombat
var skill_id: StringName
var mode := ""
var rules: Dictionary
var target: Enemy
var origin := Vector3.ZERO
var endpoint := Vector3.ZERO
var heading := Vector3.FORWARD
var remaining := 0.0
var age := 0.0
var phase := 0
var count := 1
var visited := {}
var positions: Array[Vector3] = []
var visual: MeshInstance3D

static func contact(_combat: PlayerCombat, enemy: Enemy, _skill: StringName, _form: Dictionary, context: Dictionary) -> void:
	# Read before the base hit applies new ignite. Refrain rewards an established
	# burn, not its own on-hit buildup. The shared context belongs to one cast.
	context["tempo_burning_"+str(enemy.get_instance_id())] = enemy.burning_left > 0

static func landed(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName, form: Dictionary, context: Dictionary) -> void:
	if not is_instance_valid(enemy) or not bool(context.get("practice_allowed",false)): return
	for kind in ["q_long","s_guard"]:
		var memory := live(owner_combat,kind)
		if memory != null and memory.skill_id == skill and FoundryReactions._commit(owner_combat,context,"tempo_follow_"+kind,0):
			memory._hit(enemy,context)
	for kind in HIT_MODES:
		if not _compatible(owner_combat,skill,kind) or float(form.get(PROPERTIES[kind],0)) <= 0: continue
		if not FoundryReactions._commit(owner_combat,context,"tempo_hit_"+kind,0): continue
		var memory := live(owner_combat,kind)
		if memory != null:
			if memory.skill_id == skill: memory._hit(enemy,context)
			continue
		if not _seed(owner_combat,form,kind): continue
		memory = spawn(owner_combat,skill,kind,form,enemy)
		if memory != null: memory._first_hit(enemy)

static func cast(owner_combat: PlayerCombat, skill: StringName, _at: Vector3) -> void:
	# Root invokes this only for successful real input, after starting cooldown.
	# Consume existing sequences before seeding new ones. A later real cast can
	# start another opportunity only after the player-wide birth gate has elapsed.
	var existing: Array = owner_combat.get_tree().get_nodes_in_group("foundry_tempo")
	for node in existing:
		if _alive(node,owner_combat): node._cast(skill)
	var form := owner_combat.mutation(skill)
	for kind in CAST_MODES:
		if not _compatible(owner_combat,skill,kind) or float(form.get(PROPERTIES[kind],0)) <= 0 or live(owner_combat,kind) != null: continue
		if _seed(owner_combat,form,kind): spawn(owner_combat,skill,kind,form)

static func killed(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName) -> void:
	var form := owner_combat.mutation(skill)
	if not _compatible(owner_combat,skill,"c_living") or float(form.get(PROPERTIES.c_living,0)) <= 0: return
	if live(owner_combat,"c_living") == null and _seed(owner_combat,form,"c_living"):
		var memory := spawn(owner_combat,skill,"c_living",form)
		if memory != null:
			memory.global_position = enemy.global_position + Vector3.UP * .5
			memory.origin = memory.global_position

static func damaged(owner_combat: PlayerCombat, enemy: Enemy, amount: float) -> void:
	if amount <= 0: return
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_tempo"):
		if not _alive(node,owner_combat): continue
		match node.mode:
			"s_sustain": node.cancel()
			"q_ward": node.phase = 1
			"s_guard":
				node.target = enemy
				node.phase = 1
			"q_iron":
				if is_instance_valid(enemy) and node._moved(node._limit("spacing")) and node._near_enemy(enemy,node._limit("target_range")):
					enemy.shove(enemy.global_position-owner_combat.player.global_position,node._value()*node._boss(enemy))
					node.cancel()

static func _compatible(owner_combat: PlayerCombat, skill: StringName, kind: String) -> bool:
	var tags = owner_combat.skills.get(skill,{}).get("tags",[])
	return (not kind.begins_with("s_") or "attack" in tags) and (not kind.begins_with("c_") or "spell" in tags)

static func _alive(node: Node, owner_combat: PlayerCombat) -> bool:
	return is_instance_valid(node) and node.combat == owner_combat and node.remaining > 0 and not node.is_queued_for_deletion()

static func live(owner_combat: PlayerCombat, kind: String) -> FoundryTempo:
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_tempo"):
		if _alive(node,owner_combat) and node.mode == kind: return node
	return null

static func _seed(owner_combat: PlayerCombat, form: Dictionary, kind: String) -> bool:
	return FoundryReactions._commit(owner_combat,{},"tempo_seed_"+kind,float(form.limits.identity_tempo_gate_seconds))

static func spawn(owner_combat: PlayerCombat, skill: StringName, kind: String, form: Dictionary, victim: Enemy = null) -> FoundryTempo:
	if live(owner_combat,kind) != null or not FoundryIdentity.admit(owner_combat,"foundry_tempo",int(form.limits.identity_tempo_live_cap)): return null
	var node := FoundryTempo.new()
	node.combat = owner_combat
	node.skill_id = skill
	node.mode = kind
	node.rules = form.duplicate(true)
	node.target = victim
	node.origin = FoundryIdentity.point(owner_combat)
	node.endpoint = node.origin
	node.heading = FoundryIdentity.direction(owner_combat)
	node.positions.append(node.origin)
	node.remaining = float(form.limits.identity_tempo_window_seconds)
	owner_combat.get_tree().current_scene.add_child(node)
	node.global_position = node.origin
	node.add_to_group("foundry_tempo")
	owner_combat.died.connect(node.cancel)
	node._make_visual()
	return node

func _limit(key: String) -> float:
	return float(rules.limits["identity_tempo_"+key])

func _value() -> float:
	return float(rules.get(PROPERTIES[mode],0))

func _point(victim: Enemy) -> Vector3:
	return victim.global_position + Vector3.UP * .5

func _moved(distance: float) -> bool:
	return _flat(FoundryIdentity.point(combat)-origin).length() >= distance

static func _flat(vector: Vector3) -> Vector3:
	return vector * Vector3(1,0,1)

func _boss(victim: Enemy) -> float:
	return _limit("boss_control_factor") if victim is Boss else 1.0

func _near_enemy(victim: Enemy, distance: float) -> bool:
	return victim.life > 0 and FoundryIdentity.inside(combat,FoundryIdentity.point(combat),_point(victim),distance)

func _first_hit(victim: Enemy) -> void:
	var at := _point(victim)
	match mode:
		"q_cinder": visited[victim.get_instance_id()] = true
		"q_razor": heading = _flat(origin-at).normalized()
		"s_sweep": endpoint = at
		"c_ember":
			global_position = at
			for other in combat.alive_enemies():
				if FoundryIdentity.inside(combat,at,_point(other),_radius("radius")): visited[other.get_instance_id()] = true
		"c_blade":
			endpoint = origin + (at-origin).limit_length(_limit("line_max"))
			visited[victim.get_instance_id()] = true
			_draw_line(origin,endpoint)
		"c_wide": global_position = at

func _hit(victim: Enemy, context: Dictionary) -> void:
	if remaining <= 0: return
	var at := _point(victim)
	match mode:
		"q_long":
			if _moved(_limit("spacing")) and _flat(at-origin).length() >= _limit("far_distance") and FoundryIdentity.inside(combat,origin,at,_limit("target_range")):
				victim.shove(origin-at,_value()*_boss(victim))
				cancel()
		"s_cinder":
			if victim == target and bool(context.get("tempo_burning_"+str(victim.get_instance_id()),false)):
				var away := _flat(at-FoundryIdentity.point(combat)).normalized()
				var behind := at + away * _limit("behind_offset")
				# Both the anchor and recipients must be visible; no behind-wall burst.
				if SkillBurst.solid_ray(combat,at,behind).is_empty():
					visited[victim.get_instance_id()] = true
					_area_damage(behind,_radius("radius"),"identity_tempo_s_cinder","fire")
				cancel()
		"s_frost":
			if victim != target and is_instance_valid(target) and target.life > 0 and phase == 0:
				phase = 1
				global_position = at
		"s_double":
			if victim == target and age >= _limit("double_min_seconds") and age <= _limit("double_max_seconds"):
				FoundryIdentity.damage(combat,skill_id,victim,FoundryIdentity.point(combat),rules,"identity_tempo_s_double","physical")
				cancel()
		"s_sweep":
			if victim != target and _flat(at-endpoint).length() <= _limit("line_max"):
				visited[victim.get_instance_id()] = true
				if is_instance_valid(target): visited[target.get_instance_id()] = true
				_line_damage(endpoint,at,"identity_tempo_s_sweep","physical")
				cancel()
		"s_sustain":
			count += 1
			if count >= int(_limit("sequence_count")):
				combat.heal(_value())
				cancel()
		"s_brace":
			if _moved(_limit("still_distance")): cancel()
			elif age >= _limit("brace_seconds"):
				_armour()
				cancel()
		"s_guard":
			if phase == 1 and victim == target:
				victim.stagger(_value()*_boss(victim))
				_clear_control(combat)
				cancel()

func _cast(skill: StringName) -> void:
	var same := skill == skill_id
	match mode:
		"q_ward":
			if same and phase == 1:
				_clear_control(combat)
				cancel()
		"q_after":
			if same and _moved(_limit("spacing")):
				_area_damage(origin,_radius("radius"),"identity_tempo_after",_damage_type())
				# Existing terminal visual only: the echo has already paid its one
				# native packet. The flash cannot deliver a second hit or payload.
				SkillBurst.flash(combat,skill_id,origin,_radius("radius"))
				cancel()
		"s_step":
			if not same: return
			var at := FoundryIdentity.point(combat)
			for previous in positions:
				if _flat(at-previous).length() < _limit("spacing"): return
			positions.append(at)
			if positions.size() >= int(_limit("sequence_count")):
				_refund_movement()
				cancel()
		"c_living":
			if not same and _compatible(combat,skill,"c_living"): phase = 1
		"c_after":
			if _compatible(combat,skill,"c_after") and _flat(global_position-origin).length() >= _limit("spacing") and FoundryIdentity.inside(combat,global_position,FoundryIdentity.point(combat),_limit("metronome_radius")):
				combat.cooldowns[skill] = maxf(0,float(combat.cooldowns.get(skill,0))-_value())
				cancel()

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if remaining <= 0 or not is_instance_valid(combat) or combat.life <= 0:
		cancel()
		return
	var step := minf(maxf(delta,0),remaining)
	age += step
	remaining -= step
	# A conditional memory is no longer collectible at its deadline. Scheduled
	# releases retain their terminal tick: their paid delay/brace completed within
	# the window, whereas movement, pursuit and mote arrival require a live one.
	if remaining <= 0 and mode not in ["c_ember","c_frost","c_blade","c_wide","c_brace"]:
		cancel()
		return
	match mode:
		"q_cinder":
			if phase == 0 and _moved(_limit("spacing")):
				endpoint = origin + (FoundryIdentity.point(combat)-origin).limit_length(_limit("line_max"))
				origin = _ground(origin)
				endpoint = _ground(endpoint)
				if not SkillBurst.solid_ray(combat,origin,endpoint).is_empty(): cancel()
				else:
					phase = 1
					remaining = minf(remaining,_limit("seam_seconds"))
					_draw_line(origin,endpoint)
			if phase == 1: _line_damage(origin,endpoint,"identity_tempo_cinder","fire")
		"q_frost":
			if _moved(_limit("spacing")): phase = 1
			if phase == 1:
				for victim in combat.alive_enemies():
					if FoundryIdentity.inside(combat,origin,_point(victim),_radius("footprint_radius")) and not victim._immune_statuses.has("chill"):
						_chill(victim,"identity_tempo_frost")
						cancel()
						break
		"q_razor":
			if is_instance_valid(target) and _near_enemy(target,_limit("orbit_range")):
				var opposite := _flat(FoundryIdentity.point(combat)-_point(target)).normalized()
				if opposite.dot(heading) <= -_limit("orbit_dot"):
					FoundryIdentity.damage(combat,skill_id,target,FoundryIdentity.point(combat),rules,"identity_tempo_razor","physical")
					cancel()
		"q_living":
			if _moved(_limit("spacing")) and SkillBurst.solid_ray(combat,origin,FoundryIdentity.point(combat)).is_empty():
				combat.heal(_value())
				cancel()
		"s_frost":
			if phase == 1: _return_to_target(step)
		"s_brace", "c_brace":
			if _moved(_limit("still_distance")): cancel()
			elif mode == "c_brace" and age >= _limit("brace_seconds"):
				_armour()
				cancel()
		"c_ember", "c_frost", "c_blade", "c_wide":
			if age >= _limit("echo_delay_seconds"):
				match mode:
					"c_ember": _area_damage(global_position,_radius("radius"),"identity_tempo_c_ember","fire")
					"c_frost":
						for victim in combat.alive_enemies():
							if FoundryIdentity.inside(combat,origin,_point(victim),_radius("radius")): _chill(victim,"identity_tempo_c_frost")
					"c_blade": _line_damage(origin,endpoint,"identity_tempo_c_blade","physical")
					"c_wide": _area_damage(global_position,_radius("ring_outer"),"identity_tempo_c_wide",_damage_type(),_radius("ring_inner"))
				cancel()
		"c_living":
			if phase == 1:
				var end := FoundryIdentity.point(combat)
				var next := global_position.move_toward(end,_limit("mote_speed")*step)
				if not SkillBurst.solid_ray(combat,global_position,next).is_empty(): cancel()
				else:
					global_position = next
					if global_position.distance_to(end) <= _limit("mote_arrival"):
						combat.heal(_value())
						cancel()
		"c_after":
			if age >= _limit("metronome_wait_seconds"):
				var next := origin + heading * minf(_limit("metronome_distance"),(age-_limit("metronome_wait_seconds"))*_limit("metronome_speed"))
				if not SkillBurst.solid_ray(combat,global_position,next).is_empty(): cancel()
				else: global_position = next
	if remaining <= 0: cancel()

func _chill(victim: Enemy, prefix: String) -> void:
	# Native compilation includes this skill's increased/more cold investment.
	var suffix := "_chill_boss" if victim is Boss else "_chill"
	victim.apply_chill(float(rules.get(prefix+suffix,0)))

func _return_to_target(step: float) -> void:
	if not is_instance_valid(target) or target.life <= 0:
		cancel()
		return
	var end := _point(target)
	var next := global_position.move_toward(end,_limit("mote_speed")*step)
	if not SkillBurst.solid_ray(combat,global_position,next).is_empty():
		cancel()
		return
	global_position = next
	if global_position.distance_to(end) <= _limit("mote_arrival"):
		_chill(target,"identity_tempo_s_frost")
		cancel()

func _damage_type() -> String:
	var tags = combat.skills.get(skill_id,{}).get("tags",[])
	for type in ["physical","fire","cold"]:
		if type in tags: return type
	return "physical"

func _radius(key: String) -> float:
	return combat.mutation_radius(skill_id,_limit(key))

func _area_damage(at: Vector3, radius: float, prefix: String, type: String, inner := 0.0) -> void:
	for victim in combat.alive_enemies():
		if visited.has(victim.get_instance_id()): continue
		var centre := _point(victim)
		if centre.distance_to(at) < inner or not FoundryIdentity.inside(combat,at,centre,radius): continue
		visited[victim.get_instance_id()] = true
		FoundryIdentity.damage(combat,skill_id,victim,at,rules,prefix,type)

func _line_damage(from: Vector3, to: Vector3, prefix: String, type: String) -> void:
	if not SkillBurst.solid_ray(combat,from,to).is_empty(): return
	for victim in combat.alive_enemies():
		if visited.has(victim.get_instance_id()): continue
		var centre := _point(victim)
		var closest := Geometry3D.get_closest_point_to_segment(Vector3(centre.x,from.y,centre.z),from,to)
		if _flat(centre-closest).length() <= _radius("line_half_width") and absf(centre.y-closest.y) <= _limit("line_height") and SkillBurst.solid_ray(combat,closest,centre).is_empty():
			visited[victim.get_instance_id()] = true
			FoundryIdentity.damage(combat,skill_id,victim,closest,rules,prefix,type)

func _ground(at: Vector3) -> Vector3:
	var support := SkillBurst.solid_ray(combat,at,at-Vector3.UP*_limit("ground_probe_depth"))
	return (support.position+Vector3.UP*_limit("ground_offset")) if not support.is_empty() else at

func _armour() -> void:
	combat._cast_armour = maxf(combat._cast_armour,_value())
	combat._cast_armour_left = maxf(combat._cast_armour_left,_limit("armour_seconds"))

static func _clear_control(owner_combat: PlayerCombat) -> void:
	# Exactly one control, in the same severity order shown by the movement HUD.
	if owner_combat._root_left > 0: owner_combat._root_left = 0
	elif owner_combat._slow_left > 0: owner_combat._slow_left = 0
	elif owner_combat._marked_left > 0: owner_combat._marked_left = 0

func _refund_movement() -> void:
	var longest: StringName = &""
	var seconds := 0.0
	for id in combat.cooldowns:
		if String(combat.skills.get(id,{}).get("delivery","")) == "dash" and float(combat.cooldowns[id]) > seconds:
			longest = id
			seconds = float(combat.cooldowns[id])
	if not longest.is_empty(): combat.cooldowns[longest] = maxf(0,seconds-_value())

static func projectile_candidate(owner_combat: PlayerCombat, from: Vector3, to: Vector3, _shooter: Enemy) -> Dictionary:
	var node := live(owner_combat,"c_ward")
	if node == null or node.age < node._limit("echo_delay_seconds"): return {}
	var segment := to-from
	var offset := from-node.global_position
	var radius := node._radius("screen_radius")
	var a := segment.length_squared()
	var c := offset.length_squared()-radius*radius
	var at := 0.0
	if c > 0:
		if a <= 0: return {}
		var b := offset.dot(segment)
		var discriminant := b*b-a*c
		if discriminant < 0: return {}
		at = (-b-sqrt(discriminant))/a
		if at < 0 or at > 1: return {}
	if not SkillBurst.solid_ray(owner_combat,node.global_position,from+segment*at).is_empty(): return {}
	return {"at":at,"node":node}

static func consume_projectile(node: FoundryTempo, _point_at: Vector3, _shooter: Enemy) -> bool:
	if not is_instance_valid(node) or node.remaining <= 0 or node.is_queued_for_deletion() or node.mode != "c_ward" or node.age < node._limit("echo_delay_seconds"): return false
	node.cancel()
	return true

func _make_visual() -> void:
	var colour := Color(.72,.82,1)
	if mode in ["q_cinder","s_cinder","c_ember"]: colour = Color(1,.27,.08)
	elif mode in ["q_frost","s_frost","c_frost"]: colour = Color(.32,.84,1)
	elif mode in ["q_living","s_sustain","c_living"]: colour = Color(.45,1,.54)
	var shape := "ring"
	if mode in ["q_razor","s_double","s_sweep","c_blade"]: shape = "spike"
	elif mode in ["s_frost","c_living","c_after"]: shape = "orb"
	visual = FoundryIdentity.visual(self,shape,colour,_limit("mark_radius"))
	if mode == "c_wide":
		visual.scale = Vector3.ONE * _radius("ring_outer")/_limit("mark_radius")
		FoundryIdentity.visual(self,"ring",colour,_radius("ring_inner"))
	elif mode == "q_after": FoundryIdentity.visual(self,"ring",colour,_limit("mark_radius")*_limit("echo_mark_ratio"))
	elif mode in ["q_frost","c_frost"]: visual.scale = Vector3.ONE * _radius("footprint_radius")/_limit("mark_radius")
	elif mode == "c_ward": visual.scale = Vector3.ONE * _radius("screen_radius")/_limit("mark_radius")

func _draw_line(from: Vector3, to: Vector3) -> void:
	if is_instance_valid(visual): visual.queue_free()
	visual = FoundryIdentity.visual(self,"bar",Color(1,.3,.12) if mode == "q_cinder" else Color(.7,.8,1),from.distance_to(to)*.5)
	global_position = (from+to)*.5
	visual.rotation.y = -atan2(to.z-from.z,to.x-from.x)

func cancel() -> void:
	remaining = 0
	queue_free()
