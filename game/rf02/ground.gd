extends Resource
## Only visual data, reconstructed from the loaded world's existing biome map.
const PROFILES := ["frontier_v6","frontier_v7","frontier_v8","frontier_v9","frontier_v10", "living_frontier_wave1", "living_frontier_wave3"]
const SURFACES := ["grass", "forest_floor", "dirt"]
@export var meadow_albedo: Texture2D
@export var meadow_detail: Texture2D
@export var woodland_albedo: Texture2D
@export var woodland_detail: Texture2D
@export var tile_metres := 2.4
@export var detail_strength := 0.32
@export var broad_variation := 0.16
@export var design_purpose: Dictionary = {}

func mask_for(map: Dictionary, profile: String) -> ImageTexture:
	if profile not in PROFILES: return null
	var pixels := PackedByteArray()
	pixels.resize(int(map.width) * int(map.height) * 2)
	var definitions: Array = map.biome_defs
	for i in map.biomes.size():
		var biome: String = definitions[int(map.biomes[i])].id
		pixels[i * 2] = 255 if biome in ["meadow", "forest","gallery_woodland"] else 0
		pixels[i * 2 + 1] = 255 if biome in ["forest","gallery_woodland"] else 0
	return ImageTexture.create_from_image(Image.create_from_data(int(map.width), int(map.height), false, Image.FORMAT_RG8, pixels))

func bind(material: ShaderMaterial, kind: String, mask: ImageTexture, map: Dictionary) -> void:
	if mask == null or kind not in SURFACES: return
	material.set_shader_parameter("rf02_enabled", true)
	material.set_shader_parameter("rf02_soil_only", kind == "dirt")
	material.set_shader_parameter("rf02_biome_mask", mask)
	material.set_shader_parameter("rf02_cell_m", float(map.cell_size))
	for field in ["meadow_albedo", "meadow_detail", "woodland_albedo", "woodland_detail", "tile_metres", "detail_strength", "broad_variation"]:
		material.set_shader_parameter("rf02_" + field, get(field))
	material.set_meta("rf02_ground", true)
