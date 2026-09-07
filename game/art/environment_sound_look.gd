extends Resource
## Brief local air and vegetation textures; no resource, threat or hearing rules.

@export_group("Small playback budget")
## Low-bandwidth mono is sufficient for quiet broadband air and rustle.
@export var sample_rate := 11025
## Short non-looping breaths leave work and movement audible between events.
@export var clip_seconds := Vector2(1.6, 2.4)
## Three bounded noise/envelope variations avoid the same repeated rustle.
@export var variants := 3
## Smooth edges avoid clicks without a sustained low-frequency bed.
@export var edge_seconds := 0.45
## A completed clip is followed by this much silence; no back-to-back playback.
@export var quiet_seconds := Vector2(12.0, 24.0)
## Leaves ample room for footsteps, work, combat and the quieter rare clues.
@export var outdoor_gain_db := -36.0
## Existing enclosed shelter attenuates the outside without adding a room sound.
@export var shelter_attenuation_db := 18.0
## Smooth changes to outside/shelter level during a short clip.
@export var fade_seconds := 0.3
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
	"air": [950.0, 240.0, 0.08, 0.15],
	"foliage": [2100.0, 480.0, 0.22, 0.25],
	"reeds": [2800.0, 700.0, 0.32, 0.22],
	"stone": [1400.0, 360.0, 0.12, 0.12],
}
