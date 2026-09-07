class_name FootstepSound
extends RefCounted
## Short finite surface palette. Cosmetic samples and voice ownership stay
## separate from work/release sounds and from all simulation hearing rules.
const LOOK = preload("res://art/footstep_sound_look.tres")
const SURFACES := ["grass", "earth", "stone", "timber", "fibre", "metal"]
const VOICE_GROUP := &"footstep_sounds"
static var _clips: Dictionary = {}
static var _voice_sequence := 0


static func terrain_surface(kind: String) -> String:
	match kind:
		"grass", "forest_floor", "marsh": return "grass"
		"dirt", "ash": return "earth"
	return "stone"


static func material_surface(material: Dictionary) -> String:
	var traits: Variant = material.get("traits", [])
	if "timber" in traits: return "timber"
	if "metal" in traits: return "metal"
	if "masonry" in traits or "rough" in traits or "glazing" in traits: return "stone"
	if "covering" in traits: return "fibre"
	return "stone"


static func clip(surface: String, variant: int = 0) -> AudioStreamWAV:
	if surface not in SURFACES: return null
	var version := posmod(variant, clampi(LOOK.variants, 1, 3))
	var key := surface + ":" + str(version)
	if _clips.has(key): return _clips[key]
	var profile: Array = LOOK.surface_profiles[surface]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(surface.hash()) + version * 104729
	var pitch: float = float(profile[0]) * (1.0 + rng.randf_range(-LOOK.pitch_variation, LOOK.pitch_variation))
	var friction := clampf(float(profile[1]) + rng.randf_range(-LOOK.friction_variation, LOOK.friction_variation), 0.0, 1.0)
	var rate: int = LOOK.sample_rate
	var count := maxi(2, int(LOOK.seconds * rate))
	var samples := PackedFloat32Array()
	samples.resize(count)
	var low := 0.0
	var peak := 0.0
	var smoothing := 1.0 - exp(-TAU * float(profile[2]) / rate)
	var decay := maxf(float(profile[3]), 1.0 / rate)
	for i in count:
		var time := float(i) / rate
		low = lerpf(low, rng.randf_range(-1.0, 1.0), smoothing)
		var phase := TAU * pitch * time
		var body: float = (sin(phase) + LOOK.overtone_gain * sin(phase * float(profile[4]))) / (1.0 + LOOK.overtone_gain)
		var weight := exp(-time / decay)
		var brush := weight
		if time >= LOOK.toe_delay_s:
			brush += LOOK.toe_gain * exp(-(time - LOOK.toe_delay_s) / decay)
		var value := body * weight * (1.0 - friction) + low * brush * friction
		var edge := minf(1.0, time / LOOK.attack_seconds) * clampf(float(count - 1 - i) / rate / LOOK.edge_fade_seconds, 0.0, 1.0)
		value *= edge
		samples[i] = value
		peak = maxf(peak, absf(value))
	var bytes := PackedByteArray()
	bytes.resize(count * 2)
	var gain: float = LOOK.pcm_peak_fraction * 32767.0 / maxf(peak, 0.0001)
	for i in count:
		bytes.encode_s16(i * 2, int(clampf(samples[i] * gain, -32767.0, 32767.0)))
	var result := AudioStreamWAV.new()
	result.format = AudioStreamWAV.FORMAT_16_BITS
	result.mix_rate = rate
	result.stereo = false
	result.data = bytes
	_clips[key] = result
	return result


static func play(owner: Node, at: Vector3, surface: String, variant: int = 0) -> AudioStreamPlayer3D:
	if not is_instance_valid(owner) or not owner.is_inside_tree() or owner.is_queued_for_deletion() or surface not in SURFACES:
		return null
	var active: Array[Node] = []
	for candidate: Node in owner.get_tree().get_nodes_in_group(VOICE_GROUP):
		if not candidate.is_queued_for_deletion(): active.append(candidate)
	active.sort_custom(func(a: Node, b: Node) -> bool:
		return int(a.get_meta("voice_sequence")) < int(b.get_meta("voice_sequence")))
	while active.size() >= clampi(LOOK.max_voices, 1, 3):
		var oldest := active.pop_front() as AudioStreamPlayer3D
		oldest.stop()
		oldest.remove_from_group(VOICE_GROUP)
		oldest.queue_free()
	var voice := AudioStreamPlayer3D.new()
	voice.name = "FootstepSound"
	voice.stream = clip(surface, variant)
	voice.top_level = true
	voice.volume_db = LOOK.gain_db
	voice.max_distance = LOOK.distance_m
	voice.unit_size = LOOK.unit_size_m
	owner.add_child(voice)
	voice.global_position = at
	voice.set_meta("surface", surface)
	voice.set_meta("variant", posmod(variant, clampi(LOOK.variants, 1, 3)))
	voice.set_meta("voice_sequence", _voice_sequence)
	_voice_sequence += 1
	voice.add_to_group(VOICE_GROUP)
	voice.finished.connect(func() -> void:
		voice.remove_from_group(VOICE_GROUP)
		voice.queue_free())
	voice.play()
	return voice
