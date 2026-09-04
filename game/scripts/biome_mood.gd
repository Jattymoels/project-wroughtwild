class_name BiomeMood
extends Node
## The art direction made playable (D-013 "Bright frontier, dark
## thresholds"): light and fog crossfade toward the biome the player stands
## in, so safe country reads bright and saturated while the Ember Wastes
## feel wrong before the first pack appears. Danger is told by light
## draining out of the world, never by gore.
##
## Colours come from the master palette (docs/art/art-direction.md); keep
## this table in sync with it and generate_textures.py.

## The expansive pass (Wave 6 slice 4, 4 Sep 2026) added the sky's two
## colours and the aerial haze (fog_aerial_perspective: how much the far
## distance dissolves into the sky) per biome, and warmed, darkened or
## bleached each palette so the five read as five countries.
const MOODS := {
	"meadow": {           # storybook safe: warm bright sun, thin pale haze, a high blue sky
		"sun_color": Color(1.0, 0.95, 0.84),
		"sun_energy": 1.4,
		"fog_color": Color(0.78, 0.84, 0.9),
		"fog_density": 0.004,
		"ambient": 0.78,
		"sky_top": Color(0.34, 0.56, 0.88),
		"sky_horizon": Color(0.8, 0.86, 0.92),
		"aerial": 0.45,
	},
	"rocky_hills": {      # crisp and exposed: grey-blue light, the farthest views
		"sun_color": Color(0.95, 0.96, 1.0),
		"sun_energy": 1.25,
		"fog_color": Color(0.68, 0.74, 0.84),
		"fog_density": 0.0025,
		"ambient": 0.68,
		"sky_top": Color(0.3, 0.48, 0.8),
		"sky_horizon": Color(0.74, 0.8, 0.9),
		"aerial": 0.7,
	},
	"forest": {           # closed-in and watchful: green-filtered, dark, near
		"sun_color": Color(0.84, 0.92, 0.74),
		"sun_energy": 0.9,
		"fog_color": Color(0.44, 0.58, 0.44),
		"fog_density": 0.02,
		"ambient": 0.48,
		"sky_top": Color(0.3, 0.46, 0.66),
		"sky_horizon": Color(0.6, 0.7, 0.62),
		"aerial": 0.3,
	},
	"fen": {              # low and damp: teal-grey haze, softer sun
		"sun_color": Color(0.88, 0.95, 0.9),
		"sun_energy": 0.9,
		"fog_color": Color(0.5, 0.63, 0.62),
		"fog_density": 0.02,
		"ambient": 0.5,
		"sky_top": Color(0.4, 0.55, 0.66),
		"sky_horizon": Color(0.66, 0.76, 0.76),
		"aerial": 0.5,
	},
	"ember_wastes": {     # oppressive and burnt: weak amber sun, ochre-black haze
		"sun_color": Color(1.0, 0.6, 0.36),
		"sun_energy": 0.7,
		"fog_color": Color(0.34, 0.27, 0.23),
		"fog_density": 0.026,
		"ambient": 0.32,
		"sky_top": Color(0.36, 0.28, 0.26),
		"sky_horizon": Color(0.58, 0.44, 0.32),
		"aerial": 0.6,
	},
}
const DEFAULT_BIOME := "meadow"

const CHECK_SECONDS := 0.4
## Exponential approach rate: ~2 s to visibly settle into a new biome.
const BLEND_PER_SECOND := 1.6

var terrain: Terrain
var environment: Environment
var sun: DirectionalLight3D
var _check_timer := 0.0
var _target: Dictionary = MOODS[DEFAULT_BIOME]
## Era shift (D-019): from era two the light warms and thickens a little
## everywhere - the world has changed, and it should be felt before read.
var _era_fog_tint := Color.WHITE
var _era_sun_scale := 1.0


func set_era(index: int) -> void:
	_era_fog_tint = Color.WHITE if index < 2 else Color(0.9, 0.82, 0.8)
	_era_sun_scale = 1.0 if index < 2 else 0.9


## The mood for a biome id, falling back to the safe default. Static so
## tests can assert the design contract without a scene.
static func mood_for(biome_id: String) -> Dictionary:
	return MOODS.get(biome_id, MOODS[DEFAULT_BIOME])


func setup(from_terrain: Terrain, env: Environment, light: DirectionalLight3D) -> void:
	terrain = from_terrain
	environment = env
	sun = light
	_target = mood_for(_biome_under_player())
	_apply(1.0)


func _biome_under_player() -> String:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or terrain == null or terrain.map.is_empty():
		return DEFAULT_BIOME
	var cell: float = terrain.map["cell_size"]
	var x := int(player.global_position.x / cell)
	var z := int(player.global_position.z / cell)
	if x < 0 or z < 0 or x >= int(terrain.map["width"]) or z >= int(terrain.map["height"]):
		return DEFAULT_BIOME
	var index: int = (terrain.map["biomes"] as PackedInt32Array)[z * int(terrain.map["width"]) + x]
	return String(terrain.map["biome_defs"][index]["id"])


func _process(delta: float) -> void:
	if environment == null:
		return
	_check_timer -= delta
	if _check_timer <= 0.0:
		_check_timer = CHECK_SECONDS
		_target = mood_for(_biome_under_player())
	_apply(1.0 - exp(-BLEND_PER_SECOND * delta))


func _apply(weight: float) -> void:
	environment.fog_light_color = environment.fog_light_color.lerp(_target["fog_color"] * _era_fog_tint, weight)
	environment.fog_density = lerpf(environment.fog_density, _target["fog_density"], weight)
	# The far distance dissolves into the sky (the expansive pass): more in
	# open country, less under the trees.
	environment.fog_aerial_perspective = lerpf(environment.fog_aerial_perspective, float(_target.get("aerial", 0.5)), weight)
	var sky: ProceduralSkyMaterial = (environment.sky.sky_material as ProceduralSkyMaterial) if environment.sky != null else null
	if sky != null:
		sky.sky_top_color = sky.sky_top_color.lerp(_target.get("sky_top", sky.sky_top_color) * _era_fog_tint, weight)
		sky.sky_horizon_color = sky.sky_horizon_color.lerp(_target.get("sky_horizon", sky.sky_horizon_color) * _era_fog_tint, weight)
		sky.ground_horizon_color = sky.sky_horizon_color
	environment.ambient_light_sky_contribution = lerpf(
		environment.ambient_light_sky_contribution, _target["ambient"], weight)
	if sun != null:
		sun.light_color = sun.light_color.lerp(_target["sun_color"], weight)
		sun.light_energy = lerpf(sun.light_energy, _target["sun_energy"] * _era_sun_scale, weight)
