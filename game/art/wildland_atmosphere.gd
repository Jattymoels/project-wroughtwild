extends "res://art/weathered_atmosphere.gd"
## V3-only readable daylight. Existing era/day clocks continue to drive colour.
## Tight local occlusion seats roots, stones and furnishings on the ground.
@export var contact_radius_m := 1.35
@export var contact_intensity := 1.35
@export var contact_power := 1.20
@export var contact_detail := 0.65
## Thin aerial fog separates distances without bleaching the entire sky.
@export var sky_fog_fraction := 0.08
## Quiet distant cloud banks break up the empty horizon; they do not cast
## gameplay shadows or introduce a simulated weather state.
@export var cloud_coverage := 0.61
@export var cloud_opacity := 0.40
@export var cloud_scale := 7.6
@export var cloud_colour := Color(0.83, 0.83, 0.78)
@export var ground_sky_colour := Color(0.20, 0.23, 0.18)
## Update lighting colours four times a second rather than rebuilding a sky
## cubemap every display frame; existing biome/day blending remains smooth.
@export var sky_update_seconds := 0.25


func configure(environment: Environment) -> void:
	environment.ssao_enabled = true
	environment.ssao_radius = contact_radius_m
	environment.ssao_intensity = contact_intensity
	environment.ssao_power = contact_power
	environment.ssao_detail = contact_detail
	environment.fog_sky_affect = sky_fog_fraction
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/wildland_sky.gdshader")
	material.set_meta("wildland_sky", true)
	material.set_shader_parameter("sky_top", moods.get("meadow", {}).get("sky_top", Color(0.26, 0.41, 0.59)))
	material.set_shader_parameter("sky_horizon", moods.get("meadow", {}).get("sky_horizon", Color(0.65, 0.71, 0.71)))
	for property in ["cloud_coverage", "cloud_opacity", "cloud_scale", "cloud_colour"]:
		material.set_shader_parameter(property, get(property))
	material.set_shader_parameter("ground_colour", ground_sky_colour)
	var sky := Sky.new()
	sky.sky_material = material
	sky.radiance_size = Sky.RADIANCE_SIZE_128
	sky.process_mode = Sky.PROCESS_MODE_INCREMENTAL
	environment.sky = sky
