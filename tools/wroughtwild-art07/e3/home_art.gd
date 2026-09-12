class_name E3HomeArt
extends RefCounted
## Isolated-copy mesh substitution. Does not change bodies or native ownership.
static var meshes := {}
static var surfaces := {}
static var settings := {}
static func look() -> Dictionary:
	if settings.is_empty(): settings = JSON.parse_string(FileAccess.get_file_as_string("res://e3/appearance.json"))
	return settings
static func surface(role: String) -> Material:
	if surfaces.has(role): return surfaces[role]
	var m := StandardMaterial3D.new()
	m.resource_name = role
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	if role in ["Ash", "Ember"]:
		m.albedo_color = Color(.28,.26,.235) if role == "Ash" else Color(.035,.013,.006)
		m.roughness = .94
	else:
		assert(role.begins_with("d4_") or role.begins_with("d5_") or role.begins_with("d6_"), role)
		m.albedo_texture = load("res://e3/textures/"+role+"_albedo.png")
		m.normal_enabled = true
		m.normal_scale = float(look().normal_strength)
		m.normal_texture = load("res://e3/textures/"+role+"_normal.png")
		m.roughness_texture = load("res://e3/textures/"+role+"_orm.png")
		m.roughness_texture_channel = BaseMaterial3D.TEXTURE_CHANNEL_GREEN
		m.metallic = 1.0 if role.begins_with("d6_") else 0.0
	surfaces[role] = m
	return m
static func part(id: String) -> ArrayMesh:
	if meshes.has(id): return meshes[id]
	var m := AuthoredAssets.mesh_for("e3/"+id)
	assert(m != null, id)
	for i in m.get_surface_count():
		m.surface_set_material(i,surface(m.surface_get_material(i).resource_name))
	meshes[id] = m
	return m
static func closed(form: String, family: StringName) -> ArrayMesh:
	# Catalogue can momentarily preview an ineligible family while switching shape.
	# Keep its original proxy; the unchanged native gate still refuses payment.
	var candidate := ("chest_"+String(family)+"_body") if form == "chest" else ("fire_"+String(family)+"_fuel")
	if not ResourceLoader.exists("res://assets/authored/e3/"+candidate+".glb"):
		return AuthoredAssets.mesh_for("chest" if form == "chest" else "campfire")
	var key := "closed_"+form+"_"+String(family)
	if meshes.has(key): return meshes[key]
	var result := ArrayMesh.new()
	var parts: Array = ["chest_"+String(family)+"_body","chest_"+String(family)+"_lid"] if form == "chest" else ["fire_"+String(family)+"_fuel"]
	for id in parts:
		var m := part(id)
		for i in m.get_surface_count():
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			st.append_from(m,i,Transform3D.IDENTITY)
			st.set_material(m.surface_get_material(i))
			st.commit(result)
	meshes[key] = result
	return result
static func mount(block: PlacedBlock) -> void:
	if not block.is_chest() and not block.is_fire(): return
	block._mesh.visible = false
	if block.is_fire() and block._ember != null: block._ember.visible = false
	var view := preload("res://e3/home_state.gd").new()
	view.name = "E3View"
	block.add_child(view)
	view.bind()
