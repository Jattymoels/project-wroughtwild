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

## INT-02A: bounded, inert evidence in the existing accidentally struck smithy.
@export var smithy_craft_offset_m := Vector2(-2.65, 0.0) # The collapsed old work surface occupies the non-source wall alcove.
@export var smithy_craft_bounds_m := Vector3(1.3, .8, 1.8) # Keep the fallen bench recognisable at hand height without invading the central working strip.
@export var smithy_craft_roll_degrees := 68.0 # A tipped, unusable work surface reads as abandoned craft, not a free station.
@export var smithy_remnant_offsets_m: PackedVector2Array = PackedVector2Array([Vector2(-2.7, -2.8), Vector2(2.7, 2.7)]) # Two existing wall margins hold displaced roof timbers, away from the source breach.
@export var smithy_remnant_bounds_m := Vector3(1.0, .3, .65) # Small broken timbers describe damage without becoming another obstacle or landmark.
@export var smithy_paving_distances_m: PackedFloat32Array = PackedFloat32Array([2.3, 4.0]) # Short worn sequences near arrival and departure connect the ruin to its existing journeys.
@export var smithy_paving_side_m := 2.05 # Paving follows the edge of the open working strip rather than filling its middle.
@export var smithy_paving_bounds_m := Vector3(.85, .075, 1.05) # Low, separated remnants remain visibly old paving and introduce no step or collision.
@export var smithy_footprint_inset_m := .1 # Keep every added remnant inside the already reserved native ruin footprint.
@export var smithy_work_strip_half_width_m := 1.5 # Preserve the existing three-metre walking and workshop strip at every height.
@export var smithy_source_clearance_m := .6 # Leave additional space beyond the native pressure pocket's radius for its existing inspection ray.
@export var smithy_bury_height_fraction := .2 # Bury only a fifth of thin remnant height so worn paving remains above the ground.
@export var smithy_support_height_fraction := .5 # Low paving rejects even small support changes; thicker fallen craft can settle on mildly uneven ground.
