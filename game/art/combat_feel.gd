extends Resource
## Cosmetic only. These values never change hit timing, reach or damage.
@export var hit_seconds := 1.15
@export var hit_radius_fraction := 0.20
@export var hit_arc_degrees := 32.0
@export var hit_width := 5.0
@export var max_hit_directions := 6
@export var hit_colour := Color("d78970")
@export var unknown_colour := Color("b3a596")
@export var strike_seconds := 0.34
@export var sweep_seconds := 0.42
@export var nova_seconds := 0.48
@export var bow_seconds := 0.40
@export var spell_seconds := 0.38
@export var swing_metres := 0.22
@export var effect_seconds := 0.25
@export var max_cast_effects := 12
@export var weapon_scale := 0.72
@export var equipment_refresh_seconds := 0.2
@export var physical_colour := Color("b7aea0")
@export var fire_colour := Color("d99152")
@export var cold_colour := Color("95c5d2")
@export var bleed_colour := Color("a97267")

func profile(def: Dictionary, spatial: Dictionary = {}) -> String:
	var tags: PackedStringArray = def.get("tags", PackedStringArray())
	match String(def.get("delivery", "")):
		"strike": return "rend" if "bleed" in tags else "strike"
		"cone": return "nova" if float(spatial.get("cone_degrees", 0)) >= 359.0 else "sweep"
		"projectile": return "arrow" if "attack" in tags else "frost" if "cold" in tags else "ember"
	return String(def.get("delivery", ""))

func colour(def: Dictionary) -> Color:
	var tags: PackedStringArray = def.get("tags", PackedStringArray())
	return cold_colour if "cold" in tags else fire_colour if "fire" in tags else bleed_colour if "bleed" in tags else physical_colour

func seconds(profile_name: String) -> float:
	match profile_name:
		"strike", "rend": return strike_seconds
		"sweep": return sweep_seconds
		"nova": return nova_seconds
		"arrow": return bow_seconds
	return spell_seconds
