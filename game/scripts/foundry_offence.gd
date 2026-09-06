class_name FoundryOffence
extends Node3D
## Passage and impact events. Each named operation has a distinct spatial or
## contact prerequisite. All damage is terminal and resolved by the native sim.
const OPERATIONS := {
	"lance":"identity_lance_fraction", "ice":"identity_ice_buildup",
	"razor":"identity_razor_fraction", "through":"identity_through_fraction",
	"thread":"identity_thread_life", "breach":"identity_breach_push",
	"needle":"identity_needle_seconds", "quick":"identity_quick_refund",
	"firebreak":"identity_firebreak_fraction", "glacier":"identity_glacier_push",
	"concussion":"identity_concussion_fraction", "shock":"identity_shock_fraction",
	"heartbreak":"identity_heartbreak_fraction", "anvil":"identity_anvil_fraction",
	"sealbreak":"identity_sealbreak_seconds", "snap":"identity_snap_fraction"}
var combat: PlayerCombat
var skill_id: StringName
var mode := "lance"
var rules: Dictionary
var target: Enemy
var remaining := 0.0
var duration := 0.0
var origin := Vector3.ZERO
var heading := Vector3.FORWARD
var radius := 1.0
var visited := {}
var context_ref: Dictionary
var visual_mesh: MeshInstance3D

static func contact(owner_combat: PlayerCombat, enemy: Enemy, _skill: StringName, _form: Dictionary, context: Dictionary) -> void:
	if not bool(context.get("practice_allowed",false)): return
	context["offence_before_"+str(enemy.get_instance_id())] = {
		"chilled":enemy.chill>0 or enemy.is_frozen(),
		"guard":enemy.guards_against(FoundryIdentity.point(owner_combat)),
		"warden":enemy.warded_by(),
		"low":enemy.life/maxf(enemy.max_life,1),
		"still":owner_combat._still_seconds}

static func landed(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName, form: Dictionary, context: Dictionary) -> void:
	if not bool(context.get("practice_allowed",false)): return
	var before: Dictionary = context.get("offence_before_"+str(enemy.get_instance_id()),{})
	if before.is_empty(): return
	var at := enemy.global_position+Vector3.UP*.5
	var limits: Dictionary = form.limits
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_offence"):
		if node.combat != owner_combat or node.skill_id != skill or node.remaining<=0 or node.is_queued_for_deletion(): continue
		if node.mode == "thread" and enemy != node.target:
			var line: Vector3 = at-node.global_position
			if line.dot(node.heading)>0 and (line-node.heading*line.dot(node.heading)).length()<=float(limits.identity_offence_width) and FoundryIdentity.inside(owner_combat,node.global_position,at,float(limits.identity_offence_length)):
				if SkillBurst.solid_ray(owner_combat,at,FoundryIdentity.point(owner_combat)).is_empty(): owner_combat.heal(float(node.rules.identity_thread_life))
				node.cancel()
		elif node.mode == "quick" and enemy != node.target and not is_same(node.context_ref,context) and node.origin.distance_to(at)>=float(limits.identity_quick_distance):
			owner_combat.cooldowns[skill]=maxf(0,float(owner_combat.cooldowns.get(skill,0))-float(node.rules.identity_quick_refund))
			node.cancel()
		elif node.mode == "concussion" and enemy == node.target and not is_same(node.context_ref,context):
			FoundryIdentity.damage(owner_combat,skill,enemy,at,node.rules,"identity_concussion","physical")
			enemy.stagger(float(limits.identity_concussion_stagger)*(float(limits.identity_offence_boss_factor) if enemy is Boss else 1.0))
			node.cancel()
	for kind in OPERATIONS:
		if float(form.get(OPERATIONS[kind],0))<=0: continue
		if kind=="breach" and not bool(before.guard): continue
		if kind=="glacier" and not bool(before.chilled): continue
		if kind in ["needle","sealbreak"] and not is_instance_valid(before.warden): continue
		if kind=="heartbreak" and float(before.low)>float(limits.identity_heartbreak_threshold): continue
		if kind=="anvil" and float(before.still)<float(limits.identity_anvil_settle): continue
		if kind=="through":
			if not context.has("identity_through_origin"):
				context.identity_through_origin=at
				context.identity_through_first=enemy.get_instance_id()
				continue
			if int(context.identity_through_first)==enemy.get_instance_id(): continue
		if not FoundryReactions._commit(owner_combat,context,"offence_"+kind,float(limits.identity_offence_cooldown)): continue
		var node := spawn(owner_combat,skill,kind,at,form,enemy)
		if node==null: continue
		node.context_ref=context
		if kind=="through":
			node.origin=context.identity_through_origin
			node.visited[int(context.identity_through_first)]=true
			node.visited[enemy.get_instance_id()]=true
			var axis: Vector3=at-node.origin
			if axis.length_squared()>.0001:
				node.heading=axis.normalized()
				node.visual_mesh.position=-axis*.5
				node.visual_mesh.quaternion=Quaternion(Vector3.RIGHT,node.heading)
				node.visual_mesh.scale.x=axis.length()/(node.radius*2)
		elif kind in ["needle","sealbreak"]:
			node.target=before.warden
			if kind=="sealbreak": node.global_position=node.target.global_position+Vector3.UP*.5
		elif kind=="breach":
			enemy.stagger(float(limits.identity_breach_stagger)*(float(limits.identity_offence_boss_factor) if enemy is Boss else 1.0))
			enemy.shove(node.heading,float(form.identity_breach_push)*(float(limits.identity_offence_boss_factor) if enemy is Boss else 1.0))
		elif kind=="glacier":
			for other in owner_combat.alive_enemies():
				if FoundryIdentity.inside(owner_combat,at,other.global_position+Vector3.UP*.5,node.radius):
					var away: Vector3 = (other.global_position+Vector3.UP*.5-at).normalized()
					if away.is_zero_approx(): away=node.heading
					other.shove(away,float(form.identity_glacier_push)*(float(limits.identity_offence_boss_factor) if other is Boss else 1.0))

static func spawn(owner_combat: PlayerCombat, skill: StringName, kind: String, at: Vector3, form: Dictionary, victim: Enemy = null) -> FoundryOffence:
	if not FoundryIdentity.admit(owner_combat,"foundry_offence",int(form.limits.identity_offence_cap)): return null
	for old in owner_combat.get_tree().get_nodes_in_group("foundry_offence"):
		if old.combat==owner_combat and old.mode==kind and old.remaining>0 and not old.is_queued_for_deletion(): return null
	var node := FoundryOffence.new()
	node.combat=owner_combat
	node.skill_id=skill
	node.mode=kind
	node.rules=form.duplicate(true)
	node.target=victim
	node.origin=FoundryIdentity.point(owner_combat)
	node.heading=((at-node.origin)*Vector3(1,0,1)).normalized()
	if node.heading.is_zero_approx(): node.heading=FoundryIdentity.direction(owner_combat)
	node.duration=float(form.limits.identity_offence_delay)
	if kind in ["thread","quick","concussion","snap"]: node.duration=float(form.limits.identity_offence_memory)
	if kind in ["lance","ice","razor","needle","shock"]: node.duration=float(form.limits.identity_offence_flight)
	if kind=="anvil": node.duration=float(form.limits.identity_anvil_delay)
	node.remaining=node.duration
	node.radius=owner_combat.mutation_radius(skill,float(form.limits.identity_offence_radius))
	owner_combat.player.world_root().add_child(node)
	node.global_position=at
	if victim!=null: node.visited[victim.get_instance_id()]=true
	var colour := Color("e1b96b")
	if kind in ["ice","glacier"]: colour=Color("8ac6dc")
	elif kind in ["lance","firebreak","heartbreak"]: colour=Color("d78055")
	elif kind in ["needle","sealbreak"]: colour=Color("a5d7b8")
	var shape := "ring" if kind in ["shock","glacier","snap","heartbreak"] else "bar" if kind in ["through","razor","thread"] else "spike"
	node.visual_mesh=FoundryIdentity.visual(node,shape,colour,.3 if kind in ["lance","ice","needle"] else node.radius)
	if kind in ["through","razor","thread"]: node.visual_mesh.quaternion=Quaternion(Vector3.RIGHT,node.heading)
	return node

func _ready() -> void:
	add_to_group("foundry_offence")
	combat.died.connect(cancel)

func cancel() -> void:
	remaining=0
	queue_free()

func _physics_process(delta: float) -> void:
	advance(delta)

func _hit(enemy: Enemy, type: String) -> void:
	FoundryIdentity.damage(combat,skill_id,enemy,global_position,rules,"identity_"+mode,type)

func advance(delta: float) -> void:
	if is_queued_for_deletion(): return
	if not is_instance_valid(combat) or combat.life<=0:
		cancel()
		return
	var elapsed := minf(maxf(delta,0),remaining)
	remaining=maxf(0,remaining-elapsed)
	var limits: Dictionary=rules.limits
	if mode in ["lance","razor","needle"]:
		var end := global_position+heading*float(limits.identity_offence_speed)*elapsed
		if mode=="razor": end=global_position.move_toward(origin,float(limits.identity_offence_speed)*elapsed)
		if mode=="needle":
			if not is_instance_valid(target) or target.life<=0:
				cancel()
				return
			end=global_position.move_toward(target.global_position+Vector3.UP*.5,float(limits.identity_offence_speed)*elapsed)
		var cover := SkillBurst.solid_ray(combat,global_position,end)
		if not cover.is_empty(): end=cover.position
		for enemy in combat.alive_enemies():
			var at: Vector3=enemy.global_position+Vector3.UP*.5
			var nearest := Geometry3D.get_closest_point_to_segment(at,global_position,end)
			if at.distance_to(nearest)>float(limits.identity_offence_width) or not FoundryIdentity.inside(combat,nearest,at,float(limits.identity_offence_width)): continue
			if mode=="needle":
				if enemy==target:
					enemy.stagger(float(rules.identity_needle_seconds)*(float(limits.identity_offence_boss_factor) if enemy is Boss else 1.0))
					remaining=0
			elif not visited.has(enemy.get_instance_id()):
				visited[enemy.get_instance_id()]=true
				_hit(enemy,"fire" if mode=="lance" else "physical")
		global_position=end
		if not cover.is_empty() or mode=="razor" and end.distance_to(origin)<.01: remaining=0
	elif mode=="ice" and remaining<=0:
		var farthest: Enemy
		var distance := 0.0
		for enemy in combat.alive_enemies():
			var at: Vector3=enemy.global_position+Vector3.UP*.5
			var offset := at-global_position
			var along := offset.dot(heading)
			if along<=distance or along>float(limits.identity_offence_length) or (offset-heading*along).length()>float(limits.identity_offence_width): continue
			if not FoundryIdentity.inside(combat,global_position,at,float(limits.identity_offence_length)): continue
			farthest=enemy
			distance=along
		if farthest!=null: farthest.apply_chill(float(rules.get("identity_ice_chill_boss" if farthest is Boss else "identity_ice_chill",0)))
	elif mode=="through" and remaining<=0:
		for enemy in combat.alive_enemies():
			if visited.has(enemy.get_instance_id()): continue
			var at: Vector3=enemy.global_position+Vector3.UP*.5
			var nearest := Geometry3D.get_closest_point_to_segment(at,origin,global_position)
			if at.distance_to(nearest)<=float(limits.identity_offence_width) and SkillBurst.solid_ray(combat,origin,at).is_empty(): _hit(enemy,"physical")
	elif mode=="shock":
		var edge := radius*(1-remaining/duration)
		visual_mesh.scale=Vector3.ONE*maxf(.05,edge/radius)
		for enemy in combat.alive_enemies():
			if visited.has(enemy.get_instance_id()) or not FoundryIdentity.inside(combat,global_position,enemy.global_position+Vector3.UP*.5,edge): continue
			visited[enemy.get_instance_id()]=true
			_hit(enemy,"physical")
	elif mode in ["firebreak","heartbreak","anvil","sealbreak"] and remaining<=0:
		for enemy in combat.alive_enemies():
			var at: Vector3=enemy.global_position+Vector3.UP*.5
			if not FoundryIdentity.inside(combat,global_position,at,radius): continue
			if mode=="firebreak" and (visited.has(enemy.get_instance_id()) or (at-global_position).dot(heading)<=0): continue
			if mode=="sealbreak":
				if enemy.wards(): enemy.stagger(float(rules.identity_sealbreak_seconds)*(float(limits.identity_offence_boss_factor) if enemy is Boss else 1.0))
			else:
				_hit(enemy,"fire" if mode=="firebreak" else "physical")
				if mode=="anvil": enemy.shove(heading,float(limits.identity_anvil_push)*(float(limits.identity_offence_boss_factor) if enemy is Boss else 1.0))
	elif mode=="snap" and remaining>0:
		if FoundryIdentity.inside(combat,global_position,FoundryIdentity.point(combat),float(limits.identity_snap_distance)):
			for enemy in combat.alive_enemies():
				if FoundryIdentity.inside(combat,global_position,enemy.global_position+Vector3.UP*.5,radius): _hit(enemy,"physical")
			remaining=0
	if remaining<=0: cancel()
