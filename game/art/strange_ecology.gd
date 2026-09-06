extends Resource
## Presentation-only regional communities. Every budget is per bounded region;
## these plants and stones have no loot, collision or independent saved state.
@export_group("Composition and visibility")
## Small batches let the renderer retire a far grove without hiding its neighbour.
@export var batch_width_m := 32.0
## Ecological patches occupy most of the core while feathering into its boundary.
@export var core_fraction := 0.92
## Attempts find supported, spaced clusters without filling reserved approaches.
@export var cluster_candidates := 120
## Low growth retires first; trees remain part of the regional skyline.
@export var understory_distance_m := 100.0
@export var middle_distance_m := 155.0
@export var canopy_distance_m := 240.0
## Conservative bounds keep foliage and stone outside placed wall/roof volumes.
@export var building_clearance_m := 0.3
## Even the smallest hollow/rib/shelf keeps the established one-metre
## silhouette footprint; broader authored roots and stone use their full bounds.
@export var landmark_clearance_floor_m := 1.0
## Small buried bases connect roots and stones to the smoothed walking surface.
@export var base_bury_m := 0.06
## Looser small-growth support follows undulating ground without floating edges.
@export var small_support_rise_m := 0.7
@export var tree_support_rise_m := 1.1
@export_group("Rootvault woodland")
## Irregular groves create overlapping crowns with open glades between them.
@export var grove_count := 21
@export var grove_radius_m := 11.0
@export var grove_spacing_m := 12.0
@export var trees_per_grove := 7
@export var tree_spacing_m := 4.6
## Several height bands make saplings, mature trees and the rare elders distinct.
@export var tree_scale_range := Vector2(0.7,1.24)
@export var sapling_scale_range := Vector2(0.32,0.55)
@export var saplings_per_grove := 3
@export var elder_count := 6
@export var elder_scale_range := Vector2(0.76,1.04)
## Authored canopy joins the old bole at its upper living branch, not the ground.
@export var elder_crown_anchor := Vector3(-3.1,9.3,-0.65)
## Ferns collect inside the shade; moss and deadfall sit close to trunks.
@export var understory_per_grove := 43
@export var deadfall_per_grove := 2
@export_group("Lantern Fen")
## Water shapes are shallow irregular lobes, found only on supported flat ground.
@export var pool_count := 11
@export var pool_candidates := 240
@export var pool_radius_range_m := Vector2(3.6,6.5)
@export var pool_aspect_range := Vector2(0.55,0.85)
@export var pool_spacing_m := 3.0
@export var pool_surface_lift_m := 0.028
## Narrow shore bands put most reeds at water edges, leaving approaches open.
@export var shore_reed_count := 68
@export var shore_band_m := 2.1
@export var shore_scrub_count := 14
## Overlapping shoulder-high margins make water readable beyond small ground tufts.
@export var shore_height_scale := 1.4
## Dry islands carry smaller bent trees, broken hollows and sedge thickets.
@export var fen_patch_count := 19
@export var fen_patch_radius_m := 9.0
@export var fen_patch_spacing_m := 11.0
@export var fen_growth_per_patch := 40
## Taller sedge belongs to wet thickets; moss and scrub retain their own heights.
@export var fen_sedge_height_scale := 1.35
@export var fen_tree_count := 14
@export var fen_hollow_count := 10
@export_group("Glasswind Uplands")
## Low weathered shelves read as geology, with eroded ribs used sparingly.
@export var outcrop_cluster_count := 24
@export var outcrop_cluster_radius_m := 9.0
@export var outcrop_cluster_spacing_m := 10.0
@export var outcrops_per_cluster := 3
@export var rib_count := 7
## Scree gathers beside shelves; dry sedge grows in sheltered crescent patches.
@export var scree_per_cluster := 8
@export var tussocks_per_cluster := 23
@export var outcrop_scale_range := Vector2(0.95,2.1)
## Wind-shaped grass gives the lee of each shelf a readable middle-height layer.
@export var dry_sedge_height_scale := 1.65
