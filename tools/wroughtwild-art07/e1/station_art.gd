class_name E1StationArt
extends RefCounted
## Read-only material/mesh adapter installed only in the copied game.
static var meshes := {}
static var materials := {}
static func mesh_for(id: StringName, level := "near") -> ArrayMesh:
	var key := String(id)+"_"+level
	if meshes.has(key): return meshes[key]
	var mesh: ArrayMesh = AuthoredAssets.mesh_for("e1/"+key)
	assert(mesh != null)
	for i in mesh.get_surface_count():
		var role := mesh.surface_get_material(i).resource_name
		if not materials.has(role): materials[role] = material_for(role)
		mesh.surface_set_material(i,materials[role])
	mesh.set_meta("e1_id",String(id))
	meshes[key] = mesh
	return mesh

static func material_for(role: String) -> Material:
	var mat := StandardMaterial3D.new()
	mat.resource_name = role
	var stems := {"Wood":"d4_wood_face","End":"d4_wood_edge","Fieldstone":"d5_fieldstone_edge","Stone":"d5_stone_edge"}
	if stems.has(role):
		var path: String = "res://e1/textures/"+stems[role]
		mat.albedo_texture = load(path+"_albedo.png")
		mat.normal_enabled = true
		var controls: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://e1/stations.json"))
		mat.normal_scale = float(controls.normal_strength)
		mat.normal_texture = load(path+"_normal.png")
		mat.roughness_texture = load(path+"_orm.png")
		mat.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	else:
		assert(role in ["Dust","Tool"])
		mat.albedo_color = Color(.19,.175,.14) if role == "Dust" else Color(.095,.10,.105)
		mat.metallic = 0 if role == "Dust" else .7
		mat.roughness = .85
	return mat
