class_name PieceLook
## Shared building materials by family and visual role: continuous timber,
## dark framing/roofs and calm stone, with the existing fallback for metals.
## Rules say what a family IS; this only says what it looks like.

const TEXTURE_DIR := "res://assets/textures/"

static var _cache: Dictionary = {}


static func material_for(sim: WroughtwildSim, family: StringName, role: String="surface") -> Material:
	var key := String(family)+":"+role
	if _cache.has(key):
		return _cache[key]
	var info: Dictionary = sim.build_material(String(family))
	var art := preload("res://art/building_look.tres")
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
