class_name EnvironmentSound
extends RefCounted
## Four ordinary textures, each with three short non-looping PCM variants.
## Local noise never consumes gameplay RNG.
const LOOK = preload("res://art/environment_sound_look.tres")
const BEDS := ["air", "foliage", "reeds", "stone"]
static var _clips: Dictionary = {}

static func bed_for_surface(surface: String) -> String:
	match surface:
		"grass", "dirt": return "air"
		"forest_floor": return "foliage"
		"marsh": return "reeds"
		"rock", "ash", "stone", "bedrock": return "stone"
	return ""

static func prepare() -> void:
	for bed: String in BEDS:
		for variant in LOOK.variants: clip(bed, variant)

static func clip(bed: String, variant := 0) -> AudioStreamWAV:
	if bed not in BEDS: return null
	variant = posmod(variant, LOOK.variants)
	var key := "%s:%d" % [bed, variant]
	if _clips.has(key): return _clips[key]
	var profile: Array = LOOK.bed_profiles[bed]
	var rate: int = LOOK.sample_rate
	var rng := RandomNumberGenerator.new()
	rng.seed = int(key.hash())
	var seconds := rng.randf_range(LOOK.clip_seconds.x, LOOK.clip_seconds.y)
	var count := maxi(4, int(rate * seconds))
	var samples := PackedFloat32Array()
	samples.resize(count)
	var low := 0.0
	var bottom := 0.0
	var low_rate := 1.0 - exp(-TAU * float(profile[0]) / rate)
	var bottom_rate := 1.0 - exp(-TAU * float(profile[1]) / rate)
	for i in samples.size():
		var white := rng.randf_range(-1.0, 1.0)
		low = lerpf(low, white, low_rate)
		bottom = lerpf(bottom, low, bottom_rate)
		var value := lerpf(low - bottom, white - low, float(profile[2]))
		# A broad, uneven breath of noise; no tonal oscillator or cue rhythm.
		var swell := 1.0 + float(profile[3]) * sin(TAU * float(i) / count * (1.3 + variant * 0.35))
		var edge := clampf(minf(i, count - 1 - i) / (rate * LOOK.edge_seconds), 0.0, 1.0)
		samples[i] = value * swell * (0.5 - 0.5 * cos(PI * edge))
	var peak := 0.0001
	for i in count: peak = maxf(peak, absf(samples[i]))
	var gain: float = LOOK.pcm_peak_fraction * 32767.0 / peak
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	for i in count: bytes.encode_s16(i * 2, int(clampf(samples[i] * gain, -32767.0, 32767.0)))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = rate
	result.stereo = false
	result.loop_mode = AudioStreamWAV.LOOP_DISABLED
	result.data = bytes
	_clips[key] = result
	return result
