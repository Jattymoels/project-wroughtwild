class_name EnvironmentSound
extends RefCounted
## A closed four-bed PCM palette. Local noise never consumes gameplay RNG.
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
	for bed: String in BEDS: clip(bed)

static func clip(bed: String) -> AudioStreamWAV:
	if bed not in BEDS: return null
	if _clips.has(bed): return _clips[bed]
	var profile: Array = LOOK.bed_profiles[bed]
	var rate: int = LOOK.sample_rate
	var count := maxi(4, int(rate * LOOK.loop_seconds))
	var overlap := clampi(int(rate * LOOK.loop_overlap_seconds), 2, count >> 1)
	var samples := PackedFloat32Array()
	samples.resize(count + overlap)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(bed.hash())
	var low := 0.0
	var bottom := 0.0
	var low_rate := 1.0 - exp(-TAU * float(profile[0]) / rate)
	var bottom_rate := 1.0 - exp(-TAU * float(profile[1]) / rate)
	for i in samples.size():
		var white := rng.randf_range(-1.0, 1.0)
		low = lerpf(low, white, low_rate)
		bottom = lerpf(bottom, low, bottom_rate)
		var value := lerpf(low - bottom, white - low, float(profile[2]))
		# This slow amplitude motion is not a pitched oscillator or signal.
		var swell := 1.0 + float(profile[3]) * sin(TAU * float(i) / count)
		samples[i] = value * swell
	# The start follows the last ordinary sample, then softly rejoins the head.
	# No zero pad, onset sound or per-loop release advertises a false interaction.
	for i in overlap:
		var blend := 0.5 - 0.5 * cos(PI * float(i) / (overlap - 1))
		samples[i] = lerpf(samples[count + i], samples[i], blend)
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
	result.loop_mode = AudioStreamWAV.LOOP_FORWARD
	result.loop_begin = 0
	result.loop_end = count
	result.data = bytes
	_clips[bed] = result
	return result
