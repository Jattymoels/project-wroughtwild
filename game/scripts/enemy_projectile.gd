class_name EnemyProjectile
extends Node3D
## Straight, committed enemy shot. The engine resolves contact; PlayerCombat
## still delegates mitigation to the sim. No homing, splash or invulnerability.
var direction := Vector3.FORWARD
var speed := 1.0
var remaining := 1.0
var raw_damage := 0.0
var damage_type := "physical"
var source_name := ""
var source_ref: WeakRef
var sweep: ShapeCast3D
var spent := false

static func make_head(rules: Dictionary) -> MeshInstance3D:
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = float(rules["radius_m"])
	sphere.height = sphere.radius * 2.0
	sphere.radial_segments = 12
	sphere.rings = 6
	head.mesh = sphere
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/enemy_shot.gdshader")
	material.set_shader_parameter("shot_colour", Color(String(rules["colour"])))
	material.set_shader_parameter("glow_energy", float(rules["glow_energy"]))
	head.material_override = material
	head.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return head

static func launch(shooter: Enemy, aim: Vector3, rules: Dictionary) -> EnemyProjectile:
	var shot := EnemyProjectile.new()
	shot.position = shooter.global_position + Vector3.UP * float(rules["muzzle_height_m"])
	shot.direction = shot.position.direction_to(aim)
	if shot.direction.is_zero_approx():
		shot.direction = Vector3.FORWARD
	shot.speed = float(rules["speed_mps"])
	shot.remaining = float(rules["max_range_m"])
	shot.raw_damage = shooter.bite_damage()
	shot.damage_type = shooter.bite_type()
	shot.source_name = shooter.display_name
	shot.source_ref = weakref(shooter)
	shot.sweep = ShapeCast3D.new()
	var shape := SphereShape3D.new()
	shape.radius = float(rules["radius_m"])
	shot.sweep.shape = shape
	shot.sweep.collision_mask = shooter.collision_mask
	shot.sweep.margin = 0.001
	shot.sweep.add_exception(shooter)
	shot.add_child(shot.sweep)
	var head := make_head(rules)
	shot.add_child(head)
	# A tapered tail keeps the direction readable without a point
	# light or per-frame particles for every member of a ranged pack.
	var tail := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = shape.radius * 0.65
	mesh.bottom_radius = 0.0
	mesh.height = float(rules["trail_length_m"])
	mesh.radial_segments = 8
	tail.mesh = mesh
	tail.material_override = head.material_override
	tail.position = -shot.direction * mesh.height * 0.5
	tail.quaternion = Quaternion(Vector3.UP, shot.direction)
	tail.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	shot.add_child(tail)
	var origin := shot.position
	shooter.get_parent().add_child(shot)
	shot.global_position = origin
	shot.add_to_group("enemy_projectiles")
	return shot

func _physics_process(delta: float) -> void:
	advance(delta)

## Sweeps the full sphere along this frame's travel, including an initial
## overlap. A thin wall cannot be skipped by a long frame or fast projectile.
func advance(delta: float) -> void:
	if spent:
		return
	var travel := minf(speed * maxf(delta, 0.0), remaining)
	# Godot's motion cast can ignore shapes already overlapping its origin.
	# Probe there first, then sweep, so a muzzle inside a wall is blocked.
	sweep.target_position = Vector3.ZERO
	sweep.force_shapecast_update()
	if not sweep.is_colliding():
		sweep.target_position = direction * travel
		sweep.force_shapecast_update()
	var unobstructed := travel * sweep.get_closest_collision_safe_fraction() if sweep.is_colliding() else travel
	if FoundryField.intercept(get_tree(), global_position, global_position + direction * unobstructed):
		spent = true
		queue_free()
		return
	if sweep.is_colliding():
		spent = true
		var body := sweep.get_collider(0)
		if body is WroughtwildPlayer:
			var source := source_ref.get_ref() as Node
			body.combat.take_hit(raw_damage, damage_type, source_name, source, -direction)
		queue_free()
		return
	global_position += direction * travel
	remaining -= travel
	if remaining <= 0.0:
		spent = true
		queue_free()
