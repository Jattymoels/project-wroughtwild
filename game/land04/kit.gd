class_name LAND04Kit
extends RefCounted
## Immutable authored growth meshes/materials are retained at actual entry.
static var ready := false
static var meshes: Dictionary = {}
static var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://land04/settings.json"))
static func prepare_resources() -> void:
	if ready: return
	for role: String in ["blue-sheaths","blue-lamination","white-brace","green-root-fan","green-steppe-colony","blue-bracts-dry"]:
		var scene: PackedScene = load("res://land04/assets/"+role+".glb")
		var root: Node3D = scene.instantiate()
		var mesh := ArrayMesh.new()
		AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh)
		root.free()
		var material := ShaderMaterial.new()
		material.shader = preload("res://land04/host.gdshader")
		material.set_shader_parameter("channel",1 if role.begins_with("white") else 2 if role.begins_with("blue") else 3)
		material.set_shader_parameter("pulse_strength",float(settings.pulse_strength))
		material.set_shader_parameter("plant_bend",float(settings.wind_bend_per_m) if role in ["blue-sheaths","blue-bracts-dry"] else 0.0)
		for surface in mesh.get_surface_count(): mesh.surface_set_material(surface,material)
		mesh.set_meta("land04_material",material)
		meshes[role] = mesh
	ready = true
