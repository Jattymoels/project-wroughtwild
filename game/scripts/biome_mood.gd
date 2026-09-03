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

const MOODS := {
	"meadow": {           # storybook safe: warm bright sun, thin pale haze
		"sun_color": Color(1.0, 0.96, 0.88),
		"sun_energy": 1.35,
		"fog_color": Color(0.76, 0.82, 0.87),
		"fog_density": 0.005,
		"ambient": 0.75,
	},
	"rocky_hills": {      # crisp and exposed: neutral light, far views
		"sun_color": Color(0.96, 0.96, 1.0),
		"sun_energy": 1.2,
		"fog_color": Color(0.72, 0.76, 0.82),
		"fog_density": 0.004,
		"ambient": 0.65,
	},
	"forest": {           # closed-in and watchful: green-filtered, dimmer
		"sun_color": Color(0.88, 0.94, 0.8),
		"sun_energy": 1.0,
		"fog_color": Color(0.55, 0.66, 0.55),
		"fog_density": 0.014,
		"ambient": 0.55,
	},
	"fen": {              # low and damp: green-grey haze, softer sun
		"sun_color": Color(0.9, 0.95, 0.88),
		"sun_energy": 0.95,
		"fog_color": Color(0.58, 0.66, 0.6),
		"fog_density": 0.016,
		"ambient": 0.5,
	},
	"ember_wastes": {     # oppressive and burnt: weak amber sun, heavy haze
		"sun_color": Color(1.0, 0.62, 0.4),
		"sun_energy": 0.75,
		"fog_color": Color(0.38, 0.31, 0.29),
		"fog_density": 0.02,
		"ambient": 0.35,
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
	environment.ambient_light_sky_contribution = lerpf(
		environment.ambient_light_sky_contribution, _target["ambient"], weight)
	if sun != null:
		sun.light_color = sun.light_color.lerp(_target["sun_color"], weight)
		sun.light_energy = lerpf(sun.light_energy, _target["sun_energy"] * _era_sun_scale, weight)
