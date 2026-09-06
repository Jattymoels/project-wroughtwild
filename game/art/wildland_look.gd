extends "res://art/frontier_look.gd"
## V3-only material treatment; the inherited cover/mesh settings retain their
## existing budgets. No placement, generation or harvesting values live here.
## Broad irregular worn patches let the ground tell moss, loam and dry turf apart.
@export var soil_exposure := 0.70
@export var stone_moss := 0.24
@export var loam_colour := Color(0.30, 0.25, 0.17)
@export var moss_colour := Color(0.25, 0.31, 0.17)
@export var dry_colour := Color(0.40, 0.38, 0.25)
## Centimetres of apparent granular relief, with no displaced geometry.
@export var bump_height_m := 0.018
## Larger, calmer stone weathering makes highlights follow the material grain.
@export var rock_bump_m := 0.04
## Matte mineral response; never mirror-like wet terrain.
@export var rock_roughness := 0.78


func terrain_material(kind: String, _cell: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/wildland_terrain.gdshader")
	material.set_shader_parameter("top_colour", top_colours.get(kind, Color("74747a")))
	material.set_shader_parameter("side_colour", side_colours.get(kind, top_colours.get(kind, Color("565860"))))
	for property in ["patch_metres", "colour_variation", "soil_exposure", "stone_moss", "loam_colour", "moss_colour", "dry_colour", "grain_metres", "bump_height_m", "rock_bump_m", "rock_roughness", "blend_materials"]:
		material.set_shader_parameter(property, get(property))
	material.set_shader_parameter("grassy", kind in ["grass", "forest_floor", "marsh"])
	material.set_shader_parameter("stony", kind in ["rock", "stone", "bedrock"])
	return material
