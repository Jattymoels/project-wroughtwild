extends Resource
## Two original Blender clumps. The RF01 fitter still owns all final dimensions.
@export var colour_gain := Vector3(0.90, 0.95, 0.85)
@export var normal_up_mix := 0.64
@export var backlight := 0.13
@export var design_purpose: Dictionary = {}
var _sources: Dictionary = {}

func source(role: String) -> ArrayMesh:
	if _sources.has(role): return _sources[role]
	var packed: PackedScene = load("res://rf02/assets/" + role + ".glb")
	var root := packed.instantiate()
	var mesh := ArrayMesh.new()
	AuthoredAssets._collect(root, Transform3D.IDENTITY, mesh)
	root.free()
	_sources[role] = mesh
	return mesh

func material_for(old: Material) -> ShaderMaterial:
	# Register with the existing pause-aware clock; retain its period/bend bounds.
	var mat := R7Cover.material_for(old, 0.0)
	mat.set_shader_parameter("leaf_colour_gain", colour_gain)
	mat.set_shader_parameter("leaf_normal_up_mix", normal_up_mix)
	mat.set_shader_parameter("leaf_backlight", backlight)
	mat.set_meta("rf02_grass", true)
	return mat
