extends Resource
## Ground contact presentation only: these controls never change movement,
## collision, stamina, resource state or the noise heard by enemies.

@export_group("Grounded cadence")
## Horizontal metres actually travelled between contacts; normal 5 m/s travel
## gives a quiet, brisk walking rhythm without a timer sounding against walls.
@export var step_distance_m := 1.85
## Submillimetre collision settling does not accumulate into footsteps.
@export var minimum_motion_m := 0.001
## Limit extremely fast travel to one short contact per interval.
@export var minimum_interval_s := 0.14
## External movement between physics ticks starts a fresh cadence, so loads,
## teleports and changes of floor cannot cash in the previous partial stride.
@export var discontinuity_m := 0.06
## A large movement or stalled tick is not treated as several walking steps.
@export var maximum_tick_motion_m := 1.25
@export var maximum_tick_seconds := 0.15
## Covers existing half-metre step handling while rejecting vertical jumps.
@export var maximum_ground_rise_m := 0.65

@export_group("Support sampling")
## Short downward rays at the capsule's foot and actual floor contacts read
## the supporting piece/voxel, including slopes and narrow constructed edges.
@export var probe_above_m := 0.3
@export var probe_below_m := 0.4
## Rounded capsule contacts can sit exactly on a ledge boundary. Move the
## contact ray slightly into that support so valid edge steps are not missed.
@export var contact_inset_m := 0.02

@export_group("Playback budget")
## Six surfaces with three deterministic variants keep the PCM cache finite.
@export var sample_rate := 22050
@export var variants := 3
## These quiet voices have their own cap and never displace action feedback.
@export var max_voices := 3
## Footfalls stay near the walker and leave room for combat and rare cues.
@export var gain_db := -22.0
@export var distance_m := 6.0
@export var unit_size_m := 1.8
## Short dry contacts avoid implying a continuous machine or an empty reverb.
@export var seconds := 0.24
@export var pcm_peak_fraction := 0.54

@export_group("Contact envelopes")
## Soft edges prevent digital clicks; the toe brushes after the initial weight.
@export var attack_seconds := 0.0025
@export var edge_fade_seconds := 0.015
@export var toe_delay_s := 0.055
@export var toe_gain := 0.37
## Small fixed changes reduce obvious repetition without gameplay randomness.
@export var pitch_variation := 0.06
@export var friction_variation := 0.04
## Inharmonic damping keeps timber and metal contacts physical rather than notes.
@export var overtone_gain := 0.14

@export_group("Surface timbres")
## Rows are [body Hz, friction fraction, low-pass Hz, decay seconds,
## overtone ratio]. Grass includes dry marsh/forest brushing, never a splash;
## earth crumbles, stone scuffs, timber knocks, fibre damps and metal rings briefly.
@export var surface_profiles: Dictionary = {
	"grass": [78.0, 0.91, 2300.0, 0.055, 2.31],
	"earth": [71.0, 0.82, 820.0, 0.04, 2.17],
	"stone": [138.0, 0.76, 3500.0, 0.032, 3.43],
	"timber": [115.0, 0.46, 1500.0, 0.042, 2.71],
	"fibre": [64.0, 0.9, 1150.0, 0.065, 2.13],
	"metal": [212.0, 0.57, 3100.0, 0.05, 3.71],
}
