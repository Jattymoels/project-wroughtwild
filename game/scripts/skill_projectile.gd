class_name SkillProjectile
extends Node3D
## A projectile delivery (skill-grammar.md): flies until it meets an enemy,
## deals sim damage, applies whatever status payload the sim says the skill
## carries (chill for the Frost Orb, ignite for the Ember Bolt), then FORKS
## if the sim says so - spawning child projectiles at the impact aimed at
## the nearest untouched enemies. The sim owns every number (damage, buildup,
## fork count, decay per generation); this node owns flight, collision and
## who a fork jumps to (ADR-0003).

## Greybox looks per skill: tint and size of the flying sphere.
const LOOKS := {
	&"prototype_frost_orb": {"colour": Color(0.55, 0.8, 1.0), "radius": 0.18},
	&"prototype_ember_bolt": {"colour": Color(1.0, 0.55, 0.15), "radius": 0.13},
}

var skill_id: StringName = &"prototype_frost_orb"
var combat: PlayerCombat
var direction := Vector3.FORWARD
var generation := 0
var visited: Array = [] # enemy instance ids already hit by this cast chain

var _speed := 14.0
var _hit_radius := 0.55
var _range_left := 20.0
var _fork_range := 7.0


static func launch(in_skill: StringName, from_combat: PlayerCombat, root: Node, from: Vector3,
		dir: Vector3, in_generation: int, in_visited: Array) -> SkillProjectile:
	var projectile := SkillProjectile.new()
	projectile.skill_id = in_skill
	projectile.combat = from_combat
	projectile.direction = dir.normalized()
	projectile.generation = in_generation
	projectile.visited = in_visited
	root.add_child(projectile)
	projectile.global_position = from
	return projectile


func _ready() -> void:
	var spatial: Dictionary = combat.sim.realtime().get("skills", {}).get(String(skill_id), {})
	_speed = spatial.get("speed_mps", 14.0)
	_hit_radius = spatial.get("hit_radius_m", 0.55)
	_range_left = spatial.get("max_range_m", 20.0)
	_fork_range = spatial.get("fork_range_m", 7.0)

	var look: Dictionary = LOOKS.get(skill_id, {"colour": Color(0.9, 0.9, 0.9), "radius": 0.15})
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = look["radius"]
	sphere.height = look["radius"] * 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = look["colour"]
	material.emission_enabled = true
	material.emission = look["colour"]
	material.emission_energy_multiplier = 2.0
	sphere.material = material
	mesh.mesh = sphere
	add_child(mesh)


func _physics_process(delta: float) -> void:
	var step := _speed * delta
	global_position += direction * step
	_range_left -= step
	if _range_left <= 0.0:
		queue_free()
		return

	var target := _enemy_in_radius()
	if target != null:
		_hit(target)


func _enemy_in_radius() -> Enemy:
	var shape := SphereShape3D.new()
	shape.radius = _hit_radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, global_position)
	for hit in get_world_3d().direct_space_state.intersect_shape(query, 8):
		var collider: Object = hit.get("collider")
		if collider is Enemy and (collider as Enemy).life > 0.0 \
				and not visited.has(collider.get_instance_id()):
			return collider as Enemy
	return null


func _hit(enemy: Enemy) -> void:
	visited.append(enemy.get_instance_id())
	var id := String(skill_id)
	var is_boss := enemy is Boss

	# The sim decides the numbers; the fork generation decays the damage.
	var damage: float = combat.sim.player_hit_damage(id, combat.alive_enemies().size() == 1)
	damage *= combat.sim.fork_damage_fraction(id, generation)
	combat.last_hit_dealt = damage
	# Payload: whichever statuses the skill carries (0 for the rest).
	enemy.apply_chill(combat.sim.chill_applied(id, is_boss))
	enemy.apply_ignite(combat.sim.ignite_applied(id, is_boss))
	enemy.apply_bleed(combat.sim.bleed_applied(id, is_boss))
	enemy.take_damage(damage)
	combat.hit_landed.emit(damage, 1 if enemy.life <= 0.0 else 0)

	# Fork: the sim says how many; space says to whom (nearest untouched).
	var forks: int = combat.sim.fork_count(id)
	if forks > 0:
		var targets := _nearest_untouched(forks)
		for target in targets:
			var to_target: Vector3 = target.global_position + Vector3(0, 0.5, 0) - global_position
			SkillProjectile.launch(skill_id, combat, get_parent(), global_position,
				to_target, generation + 1, visited)
	queue_free()


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
