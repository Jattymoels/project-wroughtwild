class_name Flock
extends Node3D
## A few birds wheeling over the trees: life beyond hostiles, purely
## presentation. Each bird is a swept-wing silhouette on its own orbit about the
## flock's centre, drifting slowly so the sky is never still.

const BIRDS := 5
const RADIUS := 6.0
const HEIGHT := 11.0
## Decorative wingspan in metres; the flock's route and count are unchanged.
@export var wingspan := 0.8
## Wingbeat cycles per second; shader motion affects no collision or rules.
@export var wingbeat_hz := 1.2
## Vertical travel at the wingtip in metres.
@export var wing_lift := 0.22

var _birds: Array[MeshInstance3D] = []
var _phases: PackedFloat32Array = PackedFloat32Array()
var _time := 0.0
var _seed := 0


static func spawn(root: Node, at: Vector3, seed_value: int) -> Flock:
	var flock := Flock.new()
	flock._seed = seed_value
	root.add_child(flock)
	flock.global_position = at + Vector3(0, HEIGHT, 0)
	return flock


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/bird.gdshader")
	material.set_shader_parameter("wingbeat_hz",wingbeat_hz)
	material.set_shader_parameter("wing_lift",wing_lift)
	var shape := SurfaceTool.new()
	shape.begin(Mesh.PRIMITIVE_TRIANGLES)
	for side in [-1.0,1.0]:
		var triangles := [Vector3(0,0,-0.2),Vector3(side*wingspan*0.24,0,-0.09),Vector3(0,0,0.12),
			Vector3(side*wingspan*0.24,0,-0.09),Vector3(side*wingspan*0.5,0,0.12),Vector3(0,0,0.12),
			Vector3(0,0,0.08),Vector3(side*0.08,0,0.3),Vector3(0,0,0.25)]
		for vertex: Vector3 in triangles:
			shape.set_normal(Vector3.UP)
			shape.set_uv(Vector2(clampf(absf(vertex.x)/(wingspan*0.5),0.0,1.0),0.0))
			shape.add_vertex(vertex)
	var bird_mesh := shape.commit()
	for i in BIRDS:
		var bird := MeshInstance3D.new()
		bird.mesh = bird_mesh
		bird.material_override = material
		add_child(bird)
		_birds.append(bird)
		_phases.append(rng.randf() * TAU)
		bird.set_instance_shader_parameter("phase",_phases[-1])
		bird.extra_cull_margin = wing_lift
	_time = rng.randf() * 100.0


func _process(delta: float) -> void:
	_time += delta
	for i in _birds.size():
		var angle := _time * 0.45 + _phases[i]
		var r := RADIUS + sin(_time * 0.3 + _phases[i] * 2.0) * 1.5
		var pos := Vector3(cos(angle) * r, sin(_time * 0.8 + _phases[i]) * 0.6, sin(angle) * r)
		_birds[i].position = pos
		_birds[i].rotation.y = -angle
