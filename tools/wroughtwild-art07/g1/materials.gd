class_name G1Materials
extends RefCounted
## The published 19 families, using their metric map scales and colour spaces.
static var families: Dictionary = {}
static var cache: Dictionary = {}
static var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://g1/settings.json"))

static func material_for(family: String, role: String) -> Material:
	if families.is_empty():
		for id in ["d4","d5","d6"]:
			var cfg: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://"+id+"/materials.json"))
			for row: Dictionary in cfg.families: families[row.id]={"slice":id,"row":row}
	var key:=family+":"+role
	if cache.has(key): return cache[key]
	assert(families.has(family),"Unowned material "+family)
	var entry: Dictionary=families[family]
	var row: Dictionary=entry.row
	var stem: String="res://"+entry.slice+"/textures/"+entry.slice+"_"+family+("" if entry.slice=="d6" else "_face")
	var mat:=StandardMaterial3D.new()
	mat.resource_name="G1 "+key
	mat.albedo_texture=load(stem+"_albedo.png")
	mat.normal_enabled=true
	mat.normal_texture=load(stem+"_normal.png")
	mat.normal_scale=float(settings.material_normal_strength)
	mat.roughness_texture=load(stem+"_orm.png")
	mat.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN
	mat.metallic=1.0 if entry.slice=="d6" else 0.0
	if entry.slice=="d6":
		mat.metallic_texture=mat.roughness_texture
		mat.metallic_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_BLUE
	mat.uv1_triplanar=true
	var tile: Array=row.get("tile_metres",[.5,.5])
	mat.uv1_scale=Vector3(1.0/float(tile[0]),1.0/float(tile[1]),1.0/float(tile[0]))
	mat.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	if role=="frame": mat.albedo_color=Color.WHITE*float(settings.frame_shade);mat.albedo_color.a=1.0
	if family=="cinderglass":
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA_DEPTH_PRE_PASS
		mat.albedo_color.a=float(row.get("opacity",.48))
	cache[key]=mat
	return mat
