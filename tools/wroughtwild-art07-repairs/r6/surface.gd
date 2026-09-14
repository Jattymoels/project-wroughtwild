extends RefCounted
## Material-only coverage on the authoritative GroundedSeam mesh.
static func attach(node: ResourceNode, row: Dictionary) -> ShaderMaterial:
	var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://r6/surface.json"))
	var mat := ShaderMaterial.new()
	mat.shader = load("res://r6/surface.gdshader")
	mat.set_shader_parameter("albedo_map", load("res://c5/textures/rock-albedo.png"))
	mat.set_shader_parameter("orm_map", load("res://c5/textures/rock-orm.png"))
	mat.set_shader_parameter("source_fields", load("res://r6/c5-surface-fields.png"))
	for key in ["host_tint", "mineral_colour"]:
		var rgb: Array = row.host_tint if key == "host_tint" else row.colour
		mat.set_shader_parameter(key, Vector3(rgb[0], rgb[1], rgb[2]))
	mat.set_shader_parameter("mineral_roughness", row.roughness)
	mat.set_shader_parameter("mineral_metallic", row.metallic)
	mat.set_shader_parameter("ore_kind", cfg.ids.find(row.id))
	mat.set_shader_parameter("along_x", node._visual_seed() % 2 == 0)
	for key in cfg.shader:
		mat.set_shader_parameter(key, cfg.shader[key])
	var mesh: MeshInstance3D = node.get_node("MeshInstance3D")
	# Reuse the retained surface and all its holes; no new vertex or collider.
	mesh.material_override = mat
	node._own_materials.append(mat)
	return mat
