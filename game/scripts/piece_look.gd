class_name PieceLook
## Shared building materials by family and visual role: continuous timber,
## dark framing/roofs and calm stone, with the existing fallback for metals.
## Rules say what a family IS; this only says what it looks like.

const TEXTURE_DIR := "res://assets/textures/"
const LIBRARY = preload("res://art/material_library.tres")

static var _cache: Dictionary = {}


static func material_for(sim: WroughtwildSim, family: StringName, role: String="surface") -> Material:
	var key := String(family)+":"+role
	if _cache.has(key):
		return _cache[key]
	var info: Dictionary = sim.build_material(String(family))
	var art := preload("res://art/building_look.tres")
	if LIBRARY.profiles.has(String(family)):
		var profile: Dictionary = LIBRARY.profiles[String(family)]
		if family == &"cinderglass":
			var glass := StandardMaterial3D.new()
			glass.albedo_color = profile.base
			glass.albedo_color.a = 0.48
			glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
			glass.roughness = profile.roughness
			glass.cull_mode = BaseMaterial3D.CULL_DISABLED
			_cache[key] = glass
			return glass
		var surface := ShaderMaterial.new()
		surface.shader = preload("res://art/building_surface.gdshader")
		for parameter in ["base","accent","pattern","spacing","grain","roughness"]:
			surface.set_shader_parameter(parameter,profile[parameter])
		surface.set_shader_parameter("object_space",role in ["door","roof"])
		surface.set_shader_parameter("roof",role=="roof")
		surface.set_shader_parameter("frame_shade",art.frame_shade if role=="frame" else 1.0)
		surface.set_shader_parameter("joint_width",0.0 if role=="frame" else art.seam_width)
		_cache[key] = surface
		return surface
	if "timber" in info.get("traits",[]):
		var boards := ShaderMaterial.new()
		boards.shader = preload("res://art/workshop_wood.gdshader")
		var colour: Color = art.roof_colour if role=="roof" else art.wood_colour(String(family))
		if role=="frame":
			colour *= Color(art.frame_shade,art.frame_shade,art.frame_shade,1)
		boards.set_shader_parameter("timber",colour)
		boards.set_shader_parameter("board_width",art.board_width)
		boards.set_shader_parameter("seam_width",0.0 if role=="frame" else art.seam_width)
		boards.set_shader_parameter("object_space",role=="door")
		boards.set_shader_parameter("underside_shade",art.underside_shade)
		_cache[key] = boards
		return boards
	var material := StandardMaterial3D.new()
	material.roughness = 0.95
	if family==&"stone":
		material.albedo_color = art.stone
		_cache[key] = material
		return material
	var texture_key: String = info.get("texture", "")
	var path := TEXTURE_DIR + texture_key + ".png"
	if texture_key != "" and ResourceLoader.exists(path):
		material.albedo_texture = load(path)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.uv1_triplanar = true
		material.uv1_scale = Vector3.ONE * 1.0
	else:
		material.albedo_color = UiTheme.family_colour(String(family))
	var tint: String = info.get("tint", "")
	if tint != "":
		material.albedo_color = Color(tint)
	_cache[key] = material
	return material


static func swatch_for(family: StringName) -> Color:
	return LIBRARY.profiles.get(String(family),{}).get("base",UiTheme.family_colour(String(family)))


## Mesh selection is shared by the placed piece, catalogue and placement ghost.
## Curated wall/post/beam details fit the existing full and fine envelopes.
static func mesh_for(shape_id: StringName, form: String, size: Vector3, family: StringName = &"wood") -> Mesh:
	if family in [&"wood",&"pine",&"bog_oak",&"ash_wood",&"resinheart"]:
		var id := {"half_wall":"wall_panel","half_pillar":"pillar","half_beam":"beam"}.get(String(shape_id),String(shape_id)) as String
		var reference := {"wall_panel":Vector3(1,1,0.25),"pillar":Vector3(0.3,1,0.3),"beam":Vector3(1,0.4,0.4)}
		if reference.has(id):
			var authored := AuthoredAssets.scaled_mesh(id,size/reference[id])
			if authored != null:
				return authored
	if form in ["chest","fire"]:
		var authored := AuthoredAssets.mesh_for("campfire" if form=="fire" else "chest")
		if authored != null:
			return authored
	return PieceMesh.mesh_for(form,size)


static func apply_to(mesh: MeshInstance3D, form: String, family: StringName, material: Material) -> void:
	for i in mesh.get_surface_override_material_count():
		mesh.set_surface_override_material(i,null)
	mesh.material_override = material
	if form in ["glazed_window","light_panel"]:
		mesh.material_override = null
		mesh.set_surface_override_material(0,material)
		var frame := StandardMaterial3D.new()
		frame.albedo_color = LIBRARY.profiles.get(String(family),{}).get("accent",Color("40372e"))
		frame.roughness = 0.92
		mesh.set_surface_override_material(1,frame)
	elif form in ["chest","fire"]:
		# Authored furnishings retain their embedded wood, iron and ember surfaces.
		mesh.material_override = null
