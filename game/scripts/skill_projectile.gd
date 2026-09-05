class_name SkillProjectile
extends Node3D
## A projectile delivery (skill-grammar.md): flies until it meets an enemy,
## deals sim damage, applies whatever status payload the sim says the skill
## carries (chill for the Frost Orb, ignite for the Ember Bolt), then FORKS
## if the sim says so - spawning child projectiles at the impact aimed at
## the nearest untouched enemies. The sim owns every number (damage, buildup,
## fork count, decay per generation); this node owns flight, collision and
## who a fork jumps to (ADR-0003).

const LOOK = preload("res://art/combat_feel.tres")
var visual: Node3D
var visual_profile := ""

var skill_id: StringName = &"prototype_frost_orb"
var combat: PlayerCombat
var direction := Vector3.FORWARD
var generation := 0
var visited: Array = [] # enemy instance ids already hit by this cast chain

var _speed := 14.0
var _hit_radius := 0.55
var _range_left := 20.0
var _fork_range := 7.0
## Quarry (a rail, D-023 slice 9): enemies this projectile still flies on
## through. It forks when it finally stops.
var _pierce_left := 0
var sweep: ShapeCast3D
var spent := false
var allow_links := true
var impact_burst := false
var surface_offset := 0.08
var mutation: Dictionary
var field_emitted := false
var action_context: Dictionary


static func launch(in_skill: StringName, from_combat: PlayerCombat, root: Node, from: Vector3,
		dir: Vector3, in_generation: int, in_visited: Array, context := {}) -> SkillProjectile:
	var projectile := SkillProjectile.new()
	projectile.skill_id = in_skill
	projectile.combat = from_combat
	projectile.direction = dir.normalized()
	projectile.generation = in_generation
	projectile.visited = in_visited
	projectile.action_context = from_combat.action_context(in_skill) if context.is_empty() else context
	projectile.allow_links = from_combat._link_depth==0
	root.add_child(projectile)
	projectile.global_position = from
	return projectile


func _ready() -> void:
	var spatial: Dictionary = combat.sim.realtime().get("skills", {}).get(String(skill_id), {})
	_speed = spatial.get("speed_mps", 14.0)
	_hit_radius = spatial.get("hit_radius_m", 0.55)
	# Reach (D-023): a Reach ingot beside the skill's socket makes it fly further.
	_range_left = spatial.get("max_range_m", 20.0) * combat.sim.skill_reach(String(skill_id))
	_fork_range = spatial.get("fork_range_m", 7.0)
	_pierce_left = combat.sim.skill_pierce(String(skill_id))
	mutation = combat.mutation(skill_id).duplicate(true)
	impact_burst = float(spatial.get("impact_burst",0))>0 or float(mutation.get("impact_radius",0))>0
	var delivery := String(combat.skills[skill_id].get("delivery", ""))
	if delivery in ["strike", "cone"] and float(mutation.get("wave", 0)) > 0:
		_speed = float(mutation.limits.get("wave_speed", 16))
		_range_left = float(mutation.limits.get("wave_range", 12)) * combat.sim.skill_reach(String(skill_id))
	surface_offset = float(spatial.get("surface_offset_m",0.08))
	sweep = ShapeCast3D.new()
	var shape := SphereShape3D.new()
	shape.radius = _hit_radius
	sweep.shape = shape
	sweep.margin = 0.001
	add_child(sweep)
	add_to_group("player_projectiles")
	combat.died.connect(cancel)

	var def: Dictionary = combat.skills.get(skill_id,{})
	visual_profile = LOOK.profile(def,spatial)
	if float(mutation.get("smoulder_slow", 0)) > 0: visual_profile = "frost"
	var colour := Color("c9956d") if float(mutation.get("smoulder_slow",0)) > 0 else LOOK.colour(def)
	if delivery in ["strike", "cone"] and float(mutation.get("wave", 0)) > 0: visual_profile = "wave"
	visual = CombatVisuals.projectile(visual_profile,colour)
	if float(mutation.get("smoulder_slow",0)) > 0:
		var ember := CombatVisuals.projectile("coal", Color("d78043"))
		ember.scale = Vector3.ONE * 0.6
		visual.add_child(ember)
	if delivery in ["strike", "cone"] and float(mutation.get("wave", 0)) > 0:
		visual.scale = Vector3(1.3, 1.0, 1.0)
	add_child(visual)
	visual.quaternion = Quaternion(Vector3.FORWARD,direction)

func _process(delta: float) -> void:
	if visual_profile == "frost":
		visual.rotate_object_local(Vector3.FORWARD,delta*2.0)


func _physics_process(delta: float) -> void:
	advance(delta)


func cancel() -> void:
	spent = true
	queue_free()


## Sweep all of this frame's travel, including an initial overlap. Piercing
## arrows resolve enemies and cover in travel order even on a long frame.
func advance(delta: float) -> void:
	if spent: return
	if not is_instance_valid(combat) or not is_instance_valid(combat.player):
		cancel()
		return
	var travel := minf(_speed*maxf(delta,0),_range_left)
	for _contact in combat.alive_enemies().size()+1:
		sweep.clear_exceptions()
		sweep.add_exception(combat.player)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if enemy is Enemy and (enemy.life<=0 or visited.has(enemy.get_instance_id())): sweep.add_exception(enemy)
		sweep.target_position = Vector3.ZERO
		sweep.force_shapecast_update()
		if not sweep.is_colliding():
			sweep.target_position = direction*travel
			sweep.force_shapecast_update()
		if not sweep.is_colliding():
			global_position += direction*travel
			_range_left -= travel
			break
		var moved := travel*sweep.get_closest_collision_safe_fraction()
		global_position += direction*moved
		_range_left -= moved
		travel -= moved
		var target := sweep.get_collider(0)
		if target is Enemy and target.life>0:
			_hit(target)
			if spent: return
		else:
			_hit_world({"collider":target,"position":sweep.get_collision_point(0),"normal":sweep.get_collision_normal(0)})
			return
	if _range_left<=0:
		if impact_burst: _burst()
		_leave_field()
		cancel()


func _burst() -> void:
	var radius := combat.area_radius(skill_id)
	SkillBurst.hit_area(combat,skill_id,global_position,radius,combat.sim.fork_damage_fraction(String(skill_id),generation),visited,allow_links,false,action_context)
	SkillBurst.flash(combat,skill_id,global_position,radius)


func _hit_world(hit: Dictionary) -> void:
	_leave_field()
	if impact_burst:
		global_position = hit.position+hit.normal*surface_offset
		_burst()
	var terrain := combat.player._find_terrain()
	var id := String(skill_id)
	if terrain != null and terrain.is_terrain_body(hit.get("collider")):
		if combat.sim.chill_applied(id, false) > 0.0:
			var radius: float = terrain.fire_rules.get("quench_radius_m", 2.5)
			var cracked_count: int = terrain.quench_at(hit["position"], radius)
			if cracked_count > 0:
				combat.world_worked.emit("cracked", cracked_count)
		if combat.sim.ignite_applied(id, false) > 0.0:
			var cell: Vector3i = terrain.block_from_surface_hit(hit)
			if terrain.kind_at(cell.x, cell.y, cell.z) == "":
				cell = terrain.block_from_hit(hit["position"], -hit["normal"])
			if terrain.heat_block(cell, 1):
				combat.world_worked.emit("heated", 1)
	cancel()


func _hit(enemy: Enemy) -> void:
	var id := String(skill_id)
	var is_boss := enemy is Boss
	_leave_field()

	# Payload: whichever statuses the skill carries (0 for the rest). It
	# lands before the damage so a killing blow that ignites leaves a
	# burning corpse for proliferate.
	if impact_burst:
		_burst()
	else:
		visited.append(enemy.get_instance_id())
		var shatter: Dictionary = combat.sim.shatter_for(id)
		if enemy.is_frozen() and shatter.get("enabled",false):
			if enemy.life > 0 and not enemy.flees: combat.practice_contact(skill_id, action_context)
			var cascade := combat._shatter_cascade([enemy],shatter,combat.sim.skill_nova_chill(id))
			combat._reap(skill_id,int(cascade.kills))
			combat.hit_landed.emit(float(cascade.damage),int(cascade.kills),PackedStringArray([String(shatter.get("nova_damage_type","cold"))]))
		else:
			var crossed := combat.apply_payload(enemy, skill_id, is_boss, 1.0, false, action_context)
			# The sim decides the numbers, packet by packet; forks decay all alike.
			var landed := combat.deal(enemy, skill_id, combat.alive_enemies().size() == 1,
				combat.sim.fork_damage_fraction(id, generation), false, action_context)
			combat.hit_landed.emit(landed["damage"], 1 if landed["kill"] else 0, landed["types"])
			combat._space_control(enemy,skill_id,direction)
			if allow_links: combat.fire_links(skill_id, crossed, enemy)

	# Pierce (the Quarry rail): fly on through this one; the enemy is
	# visited, so the same bolt never bites it twice.
	if _pierce_left > 0:
		_pierce_left -= 1
		return

	# Fork: the sim says how many; space says to whom (nearest untouched).
	var forks: int = combat.sim.fork_count(id)
	if forks > 0:
		var targets := _nearest_untouched(forks)
		for target in targets:
			var to_target: Vector3 = target.global_position + Vector3(0, 0.5, 0) - global_position
			var fork := SkillProjectile.launch(skill_id, combat, get_parent(), global_position,
				to_target, generation + 1, visited, action_context)
			fork.allow_links = allow_links
	cancel()


func _nearest_untouched(count: int) -> Array:
	var candidates: Array = []
	for node in get_tree().get_nodes_in_group("enemies"):
		if not (node is Enemy) or not is_instance_valid(node):
			continue
		var enemy := node as Enemy
		if enemy.life <= 0.0 or visited.has(enemy.get_instance_id()):
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance <= _fork_range:
			candidates.append({"enemy": enemy, "distance": distance})
	candidates.sort_custom(func(a, b): return a["distance"] < b["distance"])
	var targets: Array = []
	for i in mini(count, candidates.size()):
		targets.append(candidates[i]["enemy"])
	return targets


func _leave_field() -> void:
	if field_emitted or generation > 0: return
	field_emitted = true
	combat.mutation_impact(skill_id,global_position,mutation)
