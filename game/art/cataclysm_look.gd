extends Resource
## The same restrained augmentation vocabulary belongs to land, ruins and craft.
## Exposed fracture settings now live in leyline_look.gd; the earlier short inert
## strips are retained only in the pre-pass captures, not as inactive tuning.
@export var ground_tint_strength := 0.22 # Altered ground shows a pale mineral cast without masking biome danger.
@export var structure_distance_m := 210.0 # Ruins remain readable on approach before their small fittings appear.
@export var detail_distance_m := 95.0 # Close inlays and broken fragments retire before the main silhouette.
@export var support_tolerance_m := 0.8 # Hide unsupported ruins after excavation instead of floating their bases.
@export var bury_m := 0.09 # Rough wall feet meet the smoothed terrain without a daylight seam.
@export var impact_scale := Vector3(1.5, 2.4, 1.5) # A central buried fragment remains a landmark above its basin's broken floor.
@export var blacksmith_impact_scale := Vector3(.58,.8,.58) # The small strike breaches an old hearth without becoming another giant crater landmark.
@export var impact_exposed_fraction := 0.3 # Hide excavated fragments when too little remains above the highest supporting ground.
@export var canopy_height_gain := 0.48 # Native augmentation makes nearby woodland tower over its calmer surviving growth.
@export var understory_height_gain := 0.28 # Fern/reed colonies exaggerate local growth while reserved approaches stay clear.
