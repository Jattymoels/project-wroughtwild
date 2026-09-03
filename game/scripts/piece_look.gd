class_name PieceLook
## How a building family looks (construction.json materials: texture key
## and tint): one StandardMaterial3D per family, shared by every placed
## piece and trim of that family. Rules say what a family IS; this only
## says what it looks like.

const TEXTURE_DIR := "res://assets/textures/"

static var _cache: Dictionary = {}


static func material_for(sim: WroughtwildSim, family: StringName) -> StandardMaterial3D:
	var key := String(family)
	if _cache.has(key):
		return _cache[key]
	var info: Dictionary = sim.build_material(key)
	var material := StandardMaterial3D.new()
	material.roughness = 0.95
	var texture_key: String = info.get("texture", "")
	var path := TEXTURE_DIR + texture_key + ".png"
	if texture_key != "" and ResourceLoader.exists(path):
		material.albedo_texture = load(path)
		material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		material.uv1_triplanar = true
		material.uv1_scale = Vector3.ONE * 1.0
	else:
		material.albedo_color = UiTheme.family_colour(key)
	var tint: String = info.get("tint", "")
	if tint != "":
		material.albedo_color = Color(tint)
	_cache[key] = material
	return material
