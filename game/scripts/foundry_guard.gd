class_name FoundryGuard
extends Node3D
## Sixteen bounded defensive decisions. Rules are sim-resolved snapshots;
## this node owns geometry, clocks and one-use charges, never another cast.
const CAST_MODES := {
	"guard_furnace":"identity_guard_furnace_absorb", "guard_rime":"identity_guard_rime_chill",
	"guard_blade":"identity_guard_blade_fraction", "guard_broad":"identity_guard_broad_push",
	"guard_living":"identity_guard_living_recovery", "guard_plate":"identity_guard_plate_absorb",
	"guard_post":"identity_guard_post_reduction", "guard_quick":"identity_guard_quick_absorb",
	"veil_ember":"identity_veil_ember_fraction", "veil_rime":"identity_veil_rime_chill",
	"veil_wide":"identity_veil_wide_screen", "veil_living":"identity_veil_living_life",
	"veil_iron":"identity_veil_iron_absorb", "veil_aegis":"identity_veil_aegis_threshold",
	"veil_fleeting":"identity_veil_fleeting_refund"
}
var combat: PlayerCombat
var skill_id: StringName
var mode := ""
var rules: Dictionary
var target: Enemy
var remaining := 0.0
var duration := 0.0
var radius := 0.0
var age := 0.0
var amount := 0.0
var quiet := 0.0
var direction := Vector3.FORWARD
var origin := Vector3.ZERO
var previous := {}
var visits := 0
var armed := false
var triggered := false
var picture: Node3D

static func cast(owner_combat: PlayerCombat, skill: StringName, at: Vector3) -> void:
	var form := owner_combat.mutation(skill)
	for kind in CAST_MODES:
		if float(form.get(CAST_MODES[kind],0)) <= 0 or live(owner_combat,kind) != null: continue
		if owner_combat.reaction_ready("identity_"+kind,float(form.limits.identity_guard_cooldown)):
			spawn(owner_combat,skill,kind,at,form)

static func contact(_owner_combat: PlayerCombat, _enemy: Enemy, _skill: StringName, _form: Dictionary, _context: Dictionary) -> void:
	# Preparations require a positive direct hit, not an immune collision.
	pass

static func landed(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName, form: Dictionary, context: Dictionary) -> void:
	if enemy.life <= 0 or not bool(context.get("practice_allowed",false)): return
	var riposte := live(owner_combat,"guard_blade")
	if riposte != null and riposte.skill_id == skill and riposte.target == enemy and riposte.armed:
		if FoundryReactions._commit(owner_combat,context,"identity_guard_riposte",float(form.limits.identity_guard_cooldown)):
			riposte.cancel()
			FoundryIdentity.damage(owner_combat,skill,enemy,FoundryIdentity.point(owner_combat),riposte.rules,"identity_guard_blade","physical")
			enemy.stagger(float(riposte.rules.limits.identity_guard_riposte_stagger)*riposte._boss_factor(enemy))
	var post := live(owner_combat,"guard_post")
	if post != null and post.skill_id == skill and not is_instance_valid(post.target) and post._inside(FoundryIdentity.point(owner_combat)):
		if FoundryReactions._commit(owner_combat,context,"identity_guard_designate",float(form.limits.identity_guard_cooldown)):
			post.target=enemy
			post.armed=true
	if float(form.get("identity_veil_razor_fraction",0)) > 0 and live(owner_combat,"veil_razor") == null:
		if FoundryReactions._commit(owner_combat,context,"identity_veil_razor",float(form.limits.identity_guard_cooldown)):
			var from := FoundryIdentity.point(owner_combat)
			var to := enemy.global_position+Vector3.UP*.5
			if SkillBurst.solid_ray(owner_combat,from,to).is_empty():
				var wire := spawn(owner_combat,skill,"veil_razor",from.lerp(to,.5),form)
				if wire != null:
					wire.direction=(to-from)*Vector3(1,0,1)
					if wire.direction.length_squared() > .0001: wire.direction=wire.direction.normalized()
					else: wire.direction=FoundryIdentity.direction(owner_combat)
					wire._sample()

static func killed(_owner_combat: PlayerCombat, _enemy: Enemy, _skill: StringName) -> void:
	# These defences respond to threats, contact or damage, never free kill procs.
	pass

static func damaged(owner_combat: PlayerCombat, enemy: Enemy, damage: float) -> void:
	if damage <= 0 or owner_combat.life <= 0 or not is_instance_valid(enemy): return
	var at := FoundryIdentity.point(owner_combat)
	for node in nodes(owner_combat):
		match node.mode:
			"guard_blade":
				if not node.armed and node._inside(enemy.global_position+Vector3.UP*.5):
					node.target=enemy
					node.armed=true
					node.remaining=minf(node.remaining,float(node.rules.limits.identity_guard_riposte_window))
			"guard_living":
				if node._inside(at):
					node.amount=minf(float(node.rules.identity_guard_living_recovery),node.amount+damage)
					node.quiet=0
					node.armed=true
			"veil_aegis":
				if owner_combat.life <= owner_combat.max_life*float(node.rules.identity_veil_aegis_threshold): node.armed=true

static func absorb(owner_combat: PlayerCombat, damage: float, enemy: Enemy) -> float:
	if damage <= 0 or not is_instance_valid(enemy): return damage
	var left := damage
	var at := FoundryIdentity.point(owner_combat)
	for node in nodes(owner_combat):
		if left <= 0: break
		match node.mode:
			"guard_furnace":
				if not node.triggered and node._inside(at):
					left=maxf(0,left-float(node.rules.identity_guard_furnace_absorb))
					node.triggered=true
					node.remaining=float(node.rules.limits.identity_guard_vent_delay)
			"guard_plate":
				if node.armed and node._settled(at):
					var blocked := minf(left,node.amount)
					left-=blocked
					node.amount-=blocked
					if node.amount <= 0: node.cancel()
			"guard_post":
				if node.target == enemy and node._inside(at): left*=1.0-clampf(float(node.rules.identity_guard_post_reduction),0,1)
			"guard_quick":
				var toward := (enemy.global_position-owner_combat.player.global_position)*Vector3(1,0,1)
				if toward.length_squared() > .0001 and toward.normalized().dot(node.direction) >= float(node.rules.limits.identity_guard_front_dot):
					left=maxf(0,left-float(node.rules.identity_guard_quick_absorb))
					node._refund_dash(float(node.rules.limits.identity_guard_quick_refund))
					node.cancel()
			"veil_iron_shell":
				if enemy.projectile_rules.is_empty():
					left=maxf(0,left-node.amount)
					node.cancel()
	return left

static func nodes(owner_combat: PlayerCombat) -> Array[FoundryGuard]:
	var result: Array[FoundryGuard]=[]
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_guard"):
		if node is FoundryGuard and node.combat == owner_combat and node.remaining > 0 and not node.is_queued_for_deletion(): result.append(node)
	return result

static func live(owner_combat: PlayerCombat, kind: String) -> FoundryGuard:
	for node in nodes(owner_combat):
		if node.mode == kind: return node
	return null

static func spawn(owner_combat: PlayerCombat, skill: StringName, kind: String, at: Vector3, form: Dictionary) -> FoundryGuard:
	if live(owner_combat,kind) != null: return null
	if not FoundryIdentity.admit(owner_combat,"foundry_guard",int(form.limits.identity_guard_max_nodes)): return null
	var node := FoundryGuard.new()
	node.combat=owner_combat
	node.skill_id=skill
	node.mode=kind
	node.rules=form.duplicate(true)
	node.direction=FoundryIdentity.direction(owner_combat)
	node.origin=FoundryIdentity.point(owner_combat)
	node.duration=float(form.limits.identity_guard_seconds)
	node.radius=owner_combat.mutation_radius(skill,float(form.limits.identity_guard_radius))
	if kind == "guard_quick": node.duration=float(form.limits.identity_guard_quick_seconds)
	elif kind == "veil_rime": node.duration=float(form.limits.identity_veil_rime_seconds)
	elif kind == "veil_aegis": node.duration=float(form.limits.identity_veil_aegis_seconds)
	elif kind == "veil_fleeting": node.duration=float(form.limits.identity_veil_fleeting_seconds)
	node.remaining=node.duration
	if kind == "guard_plate": node.amount=float(form.identity_guard_plate_absorb)
	if kind == "veil_rime": node.radius=owner_combat.mutation_radius(skill,float(form.limits.identity_veil_rime_start_radius))
	owner_combat.player.world_root().add_child(node)
	node.global_position=at
	if kind in ["guard_furnace","guard_rime","guard_living","guard_post","veil_ember","veil_living","veil_iron","veil_fleeting"]:
		node.global_position.y=node.origin.y
	elif kind == "guard_broad": node.global_position=node.origin+node.direction*float(form.limits.identity_guard_broad_offset)
	elif kind == "veil_wide":
		var end := node.origin+node.direction*float(form.limits.identity_veil_wide_distance)
		var cover := SkillBurst.solid_ray(owner_combat,node.origin,end)
		node.global_position=(cover.position-node.direction*float(form.limits.identity_guard_cover_margin)) if not cover.is_empty() else end
	if kind in ["guard_rime","guard_broad"]:
		for enemy in owner_combat.alive_enemies():
			var inside := node._bar_inside(enemy.global_position+Vector3.UP*.5) if kind == "guard_broad" else node._inside(enemy.global_position+Vector3.UP*.5)
			if inside: node.previous[enemy.get_instance_id()]=true
	node.picture=Node3D.new()
	node.add_child(node.picture)
	node._make_visual()
	node._sample()
	return node

func _ready() -> void:
	add_to_group("foundry_guard")
	combat.died.connect(cancel)

func cancel() -> void:
	remaining=0
	queue_free()

func _physics_process(delta: float) -> void:
	advance(delta)

func _inside(point: Vector3) -> bool:
	return FoundryIdentity.inside(combat,global_position,point,radius)

func _settled(point: Vector3) -> bool:
	return origin.distance_to(point) <= float(rules.limits.identity_guard_settle_move)

func _bar_inside(point: Vector3) -> bool:
	var offset := point-global_position
	return absf(offset.dot(direction)) <= float(rules.limits.identity_guard_bar_depth) and absf(offset.dot(direction.cross(Vector3.UP))) <= radius and absf(offset.y) <= float(rules.limits.identity_guard_bar_height) and SkillBurst.solid_ray(combat,global_position,point).is_empty()

func _boss_factor(enemy: Enemy) -> float:
	return float(rules.limits.identity_guard_boss_control) if enemy is Boss else 1.0

func advance(delta: float) -> void:
	if is_queued_for_deletion(): return
	if not is_instance_valid(combat) or combat.life <= 0:
		cancel()
		return
	var step := minf(maxf(delta,0),remaining)
	remaining=maxf(0,remaining-step)
	age+=step
	# A late frame cannot collect an expired opportunity. Only a deliberately
	# delayed vent/fuse releases its terminal payload at the end of its clock.
	if remaining <= 0 and mode not in ["guard_furnace", "veil_ember_fuse"]:
		cancel()
		return
	var at := FoundryIdentity.point(combat)
	match mode:
		"guard_furnace":
			if triggered and remaining <= 0:
				for enemy in combat.alive_enemies():
					if _inside(enemy.global_position+Vector3.UP*.5): FoundryIdentity.damage(combat,skill_id,enemy,global_position,rules,"identity_guard_furnace","fire")
		"guard_rime", "guard_broad":
			if remaining > 0:
				for enemy in combat.alive_enemies():
					if previous.has(enemy.get_instance_id()): continue
					var inside := _bar_inside(enemy.global_position+Vector3.UP*.5) if mode == "guard_broad" else _inside(enemy.global_position+Vector3.UP*.5)
					if not inside: continue
					previous[enemy.get_instance_id()]=true
					visits+=1
					if mode == "guard_rime":
						enemy.apply_chill(float(rules.identity_guard_rime_chill_boss if enemy is Boss else rules.identity_guard_rime_chill))
						enemy.stagger(float(rules.limits.identity_guard_rime_stagger)*_boss_factor(enemy))
					else:
						enemy.shove(direction,float(rules.identity_guard_broad_push)*_boss_factor(enemy))
					if visits >= int(rules.limits.identity_guard_crossing_cap):
						cancel()
						break
		"guard_living":
			if armed:
				if not _inside(at): cancel()
				else:
					quiet+=step
					if quiet >= float(rules.limits.identity_guard_quiet_seconds):
						combat.heal(amount)
						cancel()
		"guard_plate":
			if not _settled(at): cancel()
			elif age >= float(rules.limits.identity_guard_settle_seconds): armed=true
		"veil_rime":
			radius=combat.mutation_radius(skill_id,lerpf(float(rules.limits.identity_veil_rime_start_radius),float(rules.limits.identity_veil_rime_end_radius),clampf(age/duration,0,1)))
		"veil_aegis":
			global_position=at
			if combat.life <= combat.max_life*float(rules.identity_veil_aegis_threshold): armed=true
		"veil_fleeting":
			if global_position.distance_to(at) >= float(rules.limits.identity_veil_fleeting_leave): armed=true
		"veil_iron_shell", "guard_blade", "guard_quick": global_position=at
		"veil_ember_fuse":
			if remaining <= 0:
				for enemy in combat.alive_enemies():
					if _inside(enemy.global_position+Vector3.UP*.5): FoundryIdentity.damage(combat,skill_id,enemy,global_position,rules,"identity_veil_ember","fire")
		"veil_living_pickup":
			if FoundryIdentity.inside(combat,global_position,at,float(rules.limits.identity_veil_pickup_radius)):
				combat.heal(float(rules.identity_veil_living_life))
				cancel()
	_sample()
	if remaining <= 0: cancel()

func _refund_dash(seconds: float) -> void:
	var selected: StringName=&""
	var longest := 0.0
	for id in combat.cooldowns:
		if String(combat.skills.get(id,{}).get("delivery","")) == "dash" and float(combat.cooldowns[id]) > longest:
			selected=id
			longest=float(combat.cooldowns[id])
	if not selected.is_empty(): combat.cooldowns[selected]=maxf(0,longest-seconds)

func _projectile_ready() -> bool:
	if remaining <= 0 or is_queued_for_deletion(): return false
	if mode in ["veil_aegis","veil_fleeting"]: return armed
	return mode in ["veil_ember","veil_rime","veil_razor","veil_wide","veil_living","veil_iron"]

## Query first, consume only the winning ward after comparing every family.
## `from..to` MUST already stop at the world's earliest collision.
static func projectile_candidate(owner_combat: PlayerCombat, from: Vector3, to: Vector3, _shooter: Enemy = null) -> Dictionary:
	var first := INF
	var winner: FoundryGuard
	for node in nodes(owner_combat):
		if not node._projectile_ready(): continue
		var t := node.crossing(from,to)
		if t < first:
			first=t
			winner=node
	return {} if winner == null else {"at":first,"node":winner}

func crossing(from: Vector3, to: Vector3) -> float:
	var segment := to-from
	var t := INF
	if mode in ["veil_razor","veil_wide"]:
		var toward := segment.dot(direction)
		if absf(toward) < .000001 or (mode == "veil_wide" and toward >= 0): return INF
		t=(global_position-from).dot(direction)/toward
		if t < 0 or t > 1 or not _bar_inside(from+segment*t): return INF
	else:
		var offset := from-global_position
		var a := segment.length_squared()
		var b := offset.dot(segment)
		var c := offset.length_squared()-radius*radius
		if c <= 0: t=0
		elif a > .000001 and b*b-a*c >= 0: t=(-b-sqrt(b*b-a*c))/a
		if t < 0 or t > 1: return INF
	return t if SkillBurst.solid_ray(combat,global_position,from+segment*t).is_empty() else INF

static func consume_projectile(node: FoundryGuard, at: Vector3, _shooter: Enemy = null) -> bool:
	if not is_instance_valid(node) or not node._projectile_ready(): return false
	# Switch out of the interception mode before doing anything that can emit a
	# signal. A second shot in this same frame cannot spend this charge again.
	var before := node.mode
	match before:
		"veil_ember":
			node.mode="veil_ember_fuse"
			node.global_position=at
			node.remaining=float(node.rules.limits.identity_veil_fuse_seconds)
			node.radius=node.combat.mutation_radius(node.skill_id,float(node.rules.limits.identity_veil_fuse_radius))
		"veil_rime":
			node.cancel()
			for enemy in node.combat.alive_enemies():
				if FoundryIdentity.inside(node.combat,at,enemy.global_position+Vector3.UP*.5,float(node.rules.limits.identity_veil_rime_burst_radius)):
					enemy.apply_chill(float(node.rules.identity_veil_rime_chill_boss if enemy is Boss else node.rules.identity_veil_rime_chill))
		"veil_razor":
			node.cancel()
			for enemy in node.combat.alive_enemies():
				if node._bar_inside(enemy.global_position+Vector3.UP*.5): FoundryIdentity.damage(node.combat,node.skill_id,enemy,node.global_position,node.rules,"identity_veil_razor","physical")
		"veil_living":
			node.mode="veil_living_pickup"
			node.global_position=at
			node.remaining=float(node.rules.limits.identity_veil_pickup_seconds)
		"veil_iron":
			node.mode="veil_iron_shell"
			node.amount=float(node.rules.identity_veil_iron_absorb)
			node.remaining=float(node.rules.limits.identity_veil_shell_seconds)
		"veil_fleeting":
			node._refund_dash(float(node.rules.identity_veil_fleeting_refund))
			node.cancel()
		_: node.cancel()
	if not node.is_queued_for_deletion():
		for child in node.picture.get_children(): child.queue_free()
		node._make_visual()
		node._sample()
	return true

static func intercept(owner_combat: PlayerCombat, from: Vector3, to: Vector3, shooter: Enemy = null) -> bool:
	var candidate := projectile_candidate(owner_combat,from,to,shooter)
	return not candidate.is_empty() and consume_projectile(candidate.node,from+(to-from)*float(candidate.at),shooter)

func _make_visual() -> void:
	var shape := "ring"
	var colour := Color("d1bb86")
	match mode:
		"guard_furnace", "veil_ember", "veil_ember_fuse":
			shape="spike"
			colour=Color("ce844f")
		"guard_rime", "veil_rime": colour=Color("94b9ce")
		"guard_blade", "veil_razor":
			shape="bar"
			colour=Color("c7bbb0")
		"guard_broad", "veil_wide": shape="bar"
		"guard_living", "veil_living", "veil_living_pickup":
			shape="orb" if mode == "veil_living_pickup" else "ring"
			colour=Color("b0c98b")
		"guard_plate", "veil_iron", "veil_iron_shell":
			shape="bar"
			colour=Color("acb8bc")
		"guard_post", "veil_aegis":
			shape="spike"
			colour=Color("ddcb96")
		"guard_quick", "veil_fleeting":
			shape="orb"
			colour=Color("b8a6d0")
	var mesh := FoundryIdentity.visual(picture,shape,colour,1.0)
	if shape == "ring":
		# Body-height interception stays visible without an opaque band across aim.
		mesh.scale.y=float(rules.limits.identity_guard_ring_height_ratio)
		var material := mesh.material_override as StandardMaterial3D
		material.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a=float(rules.limits.identity_guard_ring_opacity)
	# A second perpendicular rib distinguishes bodily charges from ground rings.
	if mode in ["guard_plate","guard_blade","veil_iron_shell","veil_aegis"]:
		var rib := Node3D.new()
		picture.add_child(rib)
		rib.rotation.z=PI*.5
		FoundryIdentity.visual(rib,"bar",colour,.7)

func _sample() -> void:
	if picture == null: return
	var size := radius
	if mode in ["guard_blade","guard_plate","guard_quick","veil_iron_shell","veil_aegis"]: size=float(rules.limits.identity_guard_personal_visual_radius)
	elif mode == "veil_living_pickup": size=float(rules.limits.identity_veil_pickup_visual_radius)
	if mode == "veil_rime": size=radius
	picture.scale=Vector3.ONE*size
	if mode in ["guard_broad","veil_razor","veil_wide"]:
		picture.rotation.y=atan2(-direction.x,-direction.z)
		picture.scale.z=float(rules.limits.identity_guard_bar_depth)
	if mode in ["guard_furnace","veil_ember_fuse"] and triggered: picture.scale*=1.0+.15*sin(age*TAU*3)
	if mode in ["guard_plate","guard_post","guard_blade","veil_aegis","veil_fleeting"] and not armed: picture.scale*=.55
