extends Resource
## The same restrained augmentation vocabulary belongs to land, ruins and craft.
@export var ground_tint_strength := 0.22 # Altered ground shows a pale mineral cast without masking biome danger.
@export var structure_distance_m := 210.0 # Ruins remain readable on approach before their small fittings appear.
@export var detail_distance_m := 95.0 # Close inlays and broken fragments retire before the main silhouette.
@export var support_tolerance_m := 0.8 # Hide unsupported ruins after excavation instead of floating their bases.
@export var bury_m := 0.09 # Rough wall feet meet the smoothed terrain without a daylight seam.
@export var impact_scale := Vector3(1.5, 2.4, 1.5) # A central buried fragment remains a landmark above its basin's broken floor.
@export var blacksmith_impact_scale := Vector3(.58,.8,.58) # The small strike breaches an old hearth without becoming another giant crater landmark.
@export var impact_exposed_fraction := 0.3 # Hide excavated fragments when too little remains above the highest supporting ground.
@export var trace_lift_m := 0.022 # Flush technological seams remain visible without a raised walking obstacle.
@export var trace_sample_m := 1.0 # Surface strips follow individual editable ground columns.
@export var trace_fragment_fraction := 0.56 # Broken trace fragments suggest a network without drawing continuous neon roads.
@export var trace_distance_m := 140.0 # Ground clues disappear naturally into the distant landscape.
@export var trace_width_fraction := 0.12 # Thin embedded seams leave ordinary earth dominant rather than resembling a tiled road.
@export var trace_conform_step_m := 0.2 # Small ribbon facets follow uneven terrain instead of bridging it like floating scraps.
@export var channel_colour := Color("626b5e") # Weathered channels belong to the host soil rather than reading as black decals.
@export var inlay_colour := Color("aaa68d") # Old pale alloy is visible by daylight and subordinate to combat effects.
@export var root_colour := Color("7c8762") # Growth/tension expresses the woodland's living amplification.
@export var fen_colour := Color("98aa91") # A quiet mineral-green thread ties light and pressure to wet habitats.
@export var upland_colour := Color("b4b6ad") # Desaturated charge/attraction stays distinct from cold-damage blue.
@export var canopy_height_gain := 0.48 # Native augmentation makes nearby woodland tower over its calmer surviving growth.
@export var understory_height_gain := 0.28 # Fern/reed colonies exaggerate local growth while reserved approaches stay clear.
@export var trace_max_step_m := 1.1 # Exposed strips break at large ground steps instead of bridging a dig or cave.
