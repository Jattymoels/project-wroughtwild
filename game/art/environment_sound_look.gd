extends Resource
## Soft local air and vegetation beds; no resource, threat or hearing rules.

@export_group("Small playback budget")
## Low-bandwidth mono is sufficient for quiet broadband air and rustle.
@export var sample_rate := 11025
## A short seamless recording is shared by every listener, with four beds only.
@export var loop_seconds := 3.0
## Overlap the end into the beginning to avoid a repeated digital seam.
@export var loop_overlap_seconds := 0.15
## Leaves ample room for footsteps, work, combat and the quieter rare clues.
@export var outdoor_gain_db := -32.0
## Existing enclosed shelter attenuates the outside without adding a room sound.
@export var shelter_attenuation_db := 18.0
## Fade from silence and between neighbouring surfaces rather than switch abruptly.
@export var fade_seconds := 1.4
## No PCM reaches full scale; soft beds retain generous combined mix headroom.
@export var pcm_peak_fraction := 0.58

@export_group("Local sampling")
## Biome surface is sampled four times per second, never scanned across the world.
@export var sample_interval_seconds := 0.25
## Large relocation discards the previous place immediately instead of carrying it home.
@export var teleport_distance_m := 12.0

@export_group("Broadband textures")
## Each row is [low-pass Hz, lower band cut Hz, high-band blend, slow swell depth].
## Air, foliage, reeds and bare stone differ through friction, never rare notes,
## splashes, animal calls, mechanical pulses or invented extraction activity.
@export var bed_profiles: Dictionary = {
	"air": [680.0, 55.0, 0.05, 0.08],
	"foliage": [1650.0, 160.0, 0.16, 0.14],
	"reeds": [2400.0, 420.0, 0.30, 0.12],
	"stone": [1050.0, 100.0, 0.10, 0.07],
}
