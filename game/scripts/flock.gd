class_name Flock
extends Node3D
## A few birds wheeling over the trees: life beyond hostiles, purely
## presentation. Each bird is a small dark wedge on its own orbit about the
## flock's centre, drifting slowly so the sky is never still.

const BIRDS := 5
const RADIUS := 6.0
const HEIGHT := 11.0

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
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.12, 0.1, 0.12)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for i in BIRDS:
		var bird := MeshInstance3D.new()
		var wedge := PrismMesh.new()
		wedge.size = Vector3(0.9, 0.12, 0.5)
		bird.mesh = wedge
		bird.material_override = material
		add_child(bird)
		_birds.append(bird)
		_phases.append(rng.randf() * TAU)
	_time = rng.randf() * 100.0


func _process(delta: float) -> void:
	_time += delta
	for i in _birds.size():
		var angle := _time * 0.45 + _phases[i]
		var r := RADIUS + sin(_time * 0.3 + _phases[i] * 2.0) * 1.5
		var pos := Vector3(cos(angle) * r, sin(_time * 0.8 + _phases[i]) * 0.6, sin(angle) * r)
		_birds[i].position = pos
		_birds[i].rotation.y = -angle
