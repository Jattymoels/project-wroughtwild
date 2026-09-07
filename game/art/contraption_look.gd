extends Resource
## Local fixture presentation. Economic capacity, energy and ranges live in
## data/tuning/contraptions.json; these values describe space and visible work.
## Nearby machines advance only while present; no offline time is accumulated.
@export var active_distance_m := 64.0
## The cable crosses the authored top bars and keeps its basket above the floor.
@export var cable_height_m := 1.7
## A travelling basket needs actual room, rather than only a clear centre ray.
@export var basket_clearance_radius_m := 0.3
## Feet must continue resting on terrain or built support at both endpoints.
@export var support_probe_above_m := 0.15
@export var support_probe_below_m := 0.4
## Cable remains fine enough that a small workshop is readable.
@export var cable_radius_m := 0.014
@export var cable_colour := Color("696555")
## A pulse travels visibly from the operated lever to its receiver.
@export var pulse_seconds := 0.65
@export var pulse_radius_m := 0.065
@export var pulse_colour := Color("c9e6ce")
## The arrival light and drum rotation explain whether winding remains.
@export var receiver_colour := Color("d6bd7a")
@export var receiver_radius_m := 0.075
@export var drum_turns_per_trip := 3.0
## A few representative chips reveal both output routes without spawning items.
@export var sort_visual_units := 6
@export var sort_cycle_seconds := 0.7
## The pressure flash travels to the exact resource receiving the existing hit.
@export var pressure_pulse_seconds := 0.4
@export var iron_chip_colour := Color("8c8c7b")
@export var ordinary_chip_colour := Color("ad9469")
## Quiet local one-shots reinforce the visible pulse and hand operation.
@export var pulse_volume_db := -18.0
@export var work_volume_db := -25.0
## Collider dimensions follow the authored housings, not a hidden unit cube.
@export var winch_bounds := Vector3(1.4, 1.83, 1.15)
@export var sorter_bounds := Vector3(1.3, 1.3, 0.85)
@export var bellows_bounds := Vector3(0.92, 0.97, 1.15)
@export var lever_bounds := Vector3(0.65, 0.95, 0.5)
@export var lamp_bounds := Vector3(0.55, 1.06, 0.45)
## A compact hopper, tension drum and pressure chamber beside the player's forge.
@export var feeder_bounds := Vector3(1.5, 1.45, 1.45)
## Existing authored parts fitted into distinct hopper, drive and output roles.
@export var feeder_parts: Array[Dictionary] = [
	{"asset":"winch","name":"Housing","at":Vector3.ZERO,"size":Vector3(1.25,1.15,1.05)},
	{"asset":"basket","name":"Hopper","at":Vector3(0,1.05,-.26),"size":Vector3(.65,.35,.55)},
	{"asset":"ventlung","name":"Bellows","at":Vector3(-.31,.32,.1),"size":Vector3(.42,.5,.46)},
	{"asset":"drum","name":"Drum","at":Vector3(.33,.66,.02),"size":Vector3(.46,.48,.46)},
	{"asset":"basket","name":"OutputTray","at":Vector3(.12,.17,.3),"size":Vector3(.74,.18,.62)}]
## Separate representative shares show actual clay and fuel, including fuel alone.
## Their combined extent stays inside the existing hopper; they create no items.
@export var feeder_hopper_load := Vector3(-.14,1.24,-.26)
@export var feeder_hopper_size := Vector3(.23,.12,.4)
@export var feeder_fuel_load := Vector3(.14,1.24,-.26)
@export var feeder_fuel_size := Vector3(.23,.12,.4)
@export var feeder_output_load := Vector3(.12,.33,.3)
@export var feeder_output_size := Vector3(.56,.12,.43)
@export var feeder_clay_colour := Color("8c6550")
@export var feeder_fuel_colour := Color("494337") # A dark fuel share remains distinct from warm raw clay.
@export var feeder_forge_link_colour := Color("986c4b") # Warm feed connection identifies the player's hot forge.
@export var feeder_pressure_link_colour := Color("697f78") # Cool casing metal identifies finite pressure, without emission or flow.
@export var feeder_link_height_m := 0.85 # Local connections stay above the floor and below the hopper rim.
@export var feeder_link_radius_m := 0.045 # The short rigid connection must clear real walls and supports.
@export var feeder_support_half_width_m := 0.46 # Four feet must retain support after digging or building removal.
@export var station_support_half_width_m := 0.32 # The existing forge's four feet must keep resting on a floor.
@export var feeder_vent_seconds := 0.6 # Dismantling visibly releases unused drive without creating an item or hazard.
@export var feeder_panel_refresh_seconds := 0.5 # Cached aimed status and open inspection follow work without per-frame native previews.
@export var feeder_vent_colour := Color("a8b5a8") # Quiet pale pressure stays distinct from fire damage.
## The source reuses a damaged older hearth and a small split casing, never a free crafting station.
@export var pocket_bounds := Vector3(1.05,1.25,1.05)
@export var pocket_hearth_scale := 0.84
@export var pocket_casing_offset := Vector3(0,.56,0)
@export var pocket_casing_scale := 0.5
@export var pocket_membrane_scale := 0.34
@export var pocket_inlay_offset := Vector3(-.3,.32,.45)
@export var pocket_inlay_scale := Vector3(.32,.6,.4)
@export var pocket_support_tolerance_m := 0.65 # A dug-away source stays finite but cannot supply a floating connection.
