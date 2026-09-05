class_name GatheringImpact
extends Node3D
## Cosmetic only: flakes expire in flight, never become loose ground stones.
const LOOK = preload("res://art/gathering_look.tres")
var age := 0.0
var velocities: Array[Vector3] = []

static func spawn(root: Node, at: Vector3, normal: Vector3, wood: bool, seed_value: int) -> GatheringImpact:
	var active := root.get_tree().get_nodes_in_group("gathering_impacts")
	if active.size() >= LOOK.max_bursts:
		active[0].remove_from_group("gathering_impacts")
		active[0].queue_free()
	var burst := GatheringImpact.new()
	root.add_child(burst)
	burst.add_to_group("gathering_impacts")
	burst.global_position = at
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in LOOK.fragment_count:
		var flake := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.025, 0.008, 0.08) if wood else Vector3(0.04, 0.009, 0.045)
		flake.mesh = box
		var material := StandardMaterial3D.new()
		material.albedo_color = (LOOK.wood_colour if wood else LOOK.stone_colour).darkened(rng.randf_range(0.0, 0.25))
		material.roughness = 1.0
		flake.material_override = material
		flake.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		flake.rotation = Vector3(rng.randf(), rng.randf(), rng.randf()) * TAU
		burst.add_child(flake)
		burst.velocities.append((normal.normalized() + Vector3(rng.randf_range(-0.6,0.6), rng.randf_range(0.2,0.8), rng.randf_range(-0.6,0.6))) * LOOK.speed)
	return burst

func _process(delta: float) -> void:
	age += delta
	if age >= LOOK.lifetime:
		queue_free()
		return
	for i in get_child_count():
		var flake := get_child(i) as MeshInstance3D
		velocities[i].y -= LOOK.gravity * delta
		flake.position += velocities[i] * delta
		flake.rotation.x += delta * 4.0
		flake.scale = Vector3.ONE * (1.0 - age / LOOK.lifetime)
