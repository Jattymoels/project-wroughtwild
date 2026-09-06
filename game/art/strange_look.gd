extends Resource
## Presentation budgets and physical composition, never harvesting rules.
@export_group("Regional silhouettes")
## Shared middle-distance features across each contiguous core.
@export var region_candidates := 180
## Root arches and stone ribs persist as distant landmarks.
@export var landmark_distance_m := 235.0
## Small husks, ferns and scar fragments fade before landmarks.
@export var detail_distance_m := 105.0
## Broad regional dressing budgets; preserves open spaces between compositions.
@export var root_arch_count := 7
## The authored arch's shoulder centreline and crown scale bury the living trunk
## base inside the supporting root, keeping the chamber underneath open.
@export var root_canopy_anchor := Vector3(-2.166667,6.8609,0.1827)
@export var root_canopy_scale := Vector3(1.6,1.4,1.6)
@export var hollow_trunk_count := 16
@export var stone_rib_count := 15
@export var ground_detail_count := 38
## Keep ordinary player paths and finite specimen work areas visually clear.
@export var approach_clearance_m := 2.0
@export var resource_clearance_m := 2.5
@export_group("Shallow fen")
## Search supported flat areas instead of forcing water over uneven terrain.
@export var pool_candidates := 160
@export var pool_count := 9
@export var pool_radius_m := 4.3
@export var pool_max_rise_m := 0.16
@export var water_colour := Color("65776b")
@export_group("Quiet motion and light")
## Papery growth moves centimetres without resembling a combat telegraph.
@export var paper_sway_m := 0.018
@export var paper_sway_rate := 0.65
## A pale warm interior remains visible in shaded daylight, not an area-wide glow.
@export var heart_emission := 0.72
@export var heart_light_energy := 0.65
@export var heart_light_range_m := 3.7
@export var heart_colour := Color("e5dcb0")
## Slow breathing indicates stored pressure; it has no hazard or damage timing.
@export var breath_rate := 0.72
@export var breath_fraction := 0.035
@export_group("Local sound clues")
## One nearby dry chime/creak at a time; never a global ambience or danger cue.
@export var clue_sound_distance_m := 12.0
@export var clue_interval_s := 9.0
@export var clue_volume_db := -25.0
## Brief synthesized work feedback decays before another contextual press.
@export var sound_duration_s := 0.65
