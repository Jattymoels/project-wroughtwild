class_name E2ForgeArt
extends RefCounted
## Copied-review adoption only. Static maps shared across tiers and all instances.
static var meshes := {}
static var materials := {}
static var settings := {}

static func look() -> Dictionary:
	if settings.is_empty(): settings = JSON.parse_string(FileAccess.get_file_as_string("res://e2/appearance.json"))
	return settings

static func tint(key: String) -> Color:
	var values: Array = look()[key]
	return Color(values[0],values[1],values[2])

static func mesh_for(id: StringName, level := "near") -> ArrayMesh:
	var key := String(id)+"_"+level
	if meshes.has(key): return meshes[key]
	var source: ArrayMesh = AuthoredAssets.mesh_for("e2/"+key)
	assert(source != null)
	for i in source.get_surface_count():
		var name := source.surface_get_material(i).resource_name
		if not materials.has(name): materials[name] = _material(name)
		source.surface_set_material(i, materials[name])
	source.set_meta("e2_tier", String(id))
	source.set_meta("e2_level", level)
	meshes[key] = source
	return source

static func _material(role: String) -> Material:
	if role == "Work":
		var shader := ShaderMaterial.new()
		shader.shader = preload("res://e2/work.gdshader")
		shader.resource_name = role
		shader.set_shader_parameter("scar_gain",look().scar_gain)
		shader.set_shader_parameter("scar_wave_per_m",look().scar_wave_per_m)
		return shader
	var stem := {"Stone":"d5_stone_edge", "Iron":"d6_iron", "Soot":"d6_iron", "Charcoal":"d5_charcoal_face"}
	assert(stem.has(role), "Unrecognized E2 surface: "+role)
	var material := StandardMaterial3D.new()
	material.resource_name = role
	material.albedo_texture = load("res://e2/textures/"+stem[role]+"_albedo.png")
	material.normal_enabled = true
	material.normal_scale = float(look().normal_strength)
	material.normal_texture = load("res://e2/textures/"+stem[role]+"_normal.png")
	material.roughness_texture = load("res://e2/textures/"+stem[role]+"_orm.png")
	material.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	material.metallic = 1.0 if role == "Iron" else (.3 if role == "Soot" else 0.0)
	material.albedo_color = tint("stone_tint") if role == "Stone" else (tint("soot_tint") if role == "Soot" else (tint("iron_tint") if role == "Iron" else Color.WHITE))
	return material

static func mount(site: StationSite) -> void:
	var state := site.get_node_or_null("E2State")
	if state == null:
		state = preload("res://e2/forge_state.gd").new()
		state.name = "E2State"
		site.add_child(state)
	state.bind_mesh()
