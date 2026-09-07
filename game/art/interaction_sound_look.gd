extends Resource
## Short local action feedback. These values never change work or enemy hearing.

@export_group("Playback budget")
## Mono samples keep the complete fixed palette small enough to cache locally.
@export var sample_rate := 22050
## Three repeatable timbres soften repeated contact without using game RNG.
@export var variants := 3
## The oldest voice yields across all roots in the scene; capped at eight.
@export var max_voices := 8
## A burst of absorbed chips gives one quiet collection cue, not a chord.
@export var collection_interval_s := 0.16
## Work stays close; releasing material and finishing a craft can carry farther.
@export var work_distance_m := 9.0
@export var release_distance_m := 14.0
@export var craft_distance_m := 11.0
@export var collect_distance_m := 5.0
## Full close gain reaches roughly arm's length before spatial attenuation.
@export var unit_size_m := 1.5
## Even eight coherent voices at the loudest default gain reach only 0.814
## of full PCM scale. This leaves headroom for combat and nearby rare clues;
## other audio is separate and human review still needs the complete mix.
@export var work_gain_db := -18.0
@export var release_gain_db := -16.5
@export var craft_gain_db := -17.0
@export var collect_gain_db := -22.0

@export_group("Physical envelopes")
## Contact ends quickly; release has room for the host's loosened resonance.
@export var work_seconds := 0.19
@export var release_seconds := 0.49
@export var craft_seconds := 0.38
@export var collect_seconds := 0.11
## Short attack and final taper remove digital clicks from the PCM boundaries.
@export var attack_seconds := 0.0025
@export var edge_fade_seconds := 0.012
## Small fixed variations change resonance and friction, without changing gain.
@export var pitch_variation := 0.045
@export var noise_variation := 0.07
## Release bends downward slightly as a host relaxes, instead of replaying a tap.
@export var release_pitch_fall := 0.13
## Two quieter impacts suggest a short completed operation, never ongoing work.
@export var craft_second_contact_s := 0.115
@export var craft_second_gain := 0.58
## Release starts with a short fracture before its slower settling tail.
@export var release_fracture_seconds := 0.035
@export var release_fracture_gain := 0.22
## Inharmonic overtones make resonance read as a physical host rather than a note.
@export var overtone_gain := 0.24
## PCM headroom prevents individual voices clipping before spatial playback.
@export var pcm_peak_fraction := 0.68

@export_group("Host timbres")
## Each row is [resonance Hz, friction mix, low-pass Hz, decay fraction,
## overtone ratio]. Friction and damping separate woody knocks, fibrous tears,
## clay crumbs and mineral chips; rare hosts retain their established pitches.
@export var host_profiles: Dictionary = {
	"wood": [175.0, 0.56, 1700.0, 0.20, 2.43],
	"fibre": [135.0, 0.94, 3100.0, 0.36, 3.17],
	"earth": [105.0, 0.85, 850.0, 0.24, 2.19],
	"stone": [740.0, 0.66, 4900.0, 0.17, 3.61],
	"lanternheart": [620.0, 0.48, 2900.0, 0.32, 2.73],
	"thrumroot": [92.0, 0.35, 950.0, 0.37, 1.73],
	"stormglass": [1160.0, 0.24, 5100.0, 0.39, 4.17],
	"pullstone": [170.0, 0.58, 1800.0, 0.27, 2.73],
	"ventlung": [74.0, 0.82, 1800.0, 0.46, 1.41],
	"field": [210.0, 0.83, 2100.0, 0.19, 2.43],
	"bench": [185.0, 0.52, 1500.0, 0.20, 2.43],
	"yard": [650.0, 0.63, 3800.0, 0.20, 3.61],
	"forge": [940.0, 0.30, 4300.0, 0.32, 2.73],
	"collect": [430.0, 0.76, 1600.0, 0.20, 2.19],
}
