class_name InteractionSound
extends RefCounted
## Finite local action palette: fixed cached PCM, cosmetic variation and bounded
## voices. Call only after an accepted action; visual/save refresh never calls it.
const LOOK = preload("res://art/interaction_sound_look.tres")
const HOSTS := ["wood", "fibre", "earth", "stone", "lanternheart", "thrumroot", "stormglass", "pullstone", "ventlung"]
const CRAFT_HOSTS := ["field", "bench", "yard", "forge"]
const VOICE_GROUP := &"interaction_sounds"
const COLLECT_META := &"interaction_sound_collect_ms"
const VARIANT_META := &"interaction_sound_variant"
static var _clips: Dictionary = {}
static var _voice_sequence := 0


static func resource_cue(visual: String, released: bool) -> String:
	var host := "stone"
	if visual in ["tree", "resinheart_tree", "corkbark_deadfall"]:
		host = "wood"
	elif visual == "reed_bed":
		host = "fibre"
	elif visual == "clay_bank":
		host = "earth"
	elif visual in HOSTS:
		host = visual
	return ("release_" if released else "work_") + host


static func craft_cue(station_id: String) -> String:
	match station_id:
		"", "field", "hand": return "craft_field"
		"workbench": return "craft_bench"
		"mason_yard": return "craft_yard"
		"forge_basic", "forge_improved": return "craft_forge"
	return ""


static func _host(cue: String) -> String:
	if cue == "collect": return "collect"
	if cue.begins_with("craft_"):
		var host := cue.trim_prefix("craft_")
		return host if host in CRAFT_HOSTS else ""
	for prefix in ["work_", "release_"]:
		if cue.begins_with(prefix):
			var host := cue.trim_prefix(prefix)
			return host if host in HOSTS else ""
	return ""


static func _duration(cue: String) -> float:
	if cue == "collect": return LOOK.collect_seconds
	if cue.begins_with("craft_"): return LOOK.craft_seconds
	if cue.begins_with("release_"): return LOOK.release_seconds
	return LOOK.work_seconds


static func clip(cue: String, variant: int = 0) -> AudioStreamWAV:
	var host := _host(cue)
	if host.is_empty(): return null
	# Clamped variant indexing keeps the fixed palette's cache bounded even when
	# a caller supplies a negative or very large cosmetic sequence index.
	var version := posmod(variant, clampi(LOOK.variants, 1, 3))
	var key := cue + ":" + str(version)
	if _clips.has(key): return _clips[key]
	var profile: Array = LOOK.host_profiles[host]
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cue.hash()) + version * 104729
	var pitch: float = float(profile[0]) * (1.0 + rng.randf_range(-LOOK.pitch_variation, LOOK.pitch_variation))
	var friction := clampf(float(profile[1]) + rng.randf_range(-LOOK.noise_variation, LOOK.noise_variation), 0.0, 1.0)
	var seconds := _duration(cue)
	var rate: int = LOOK.sample_rate
	var count := maxi(2, int(seconds * rate))
	var samples := PackedFloat32Array()
	samples.resize(count)
	var low := 0.0
	var phase := 0.0
	var peak := 0.0
	var released := cue.begins_with("release_")
	var crafted := cue.begins_with("craft_")
	var smoothing := 1.0 - exp(-TAU * float(profile[2]) / rate)
	var decay := maxf(float(profile[3]) * seconds, 1.0 / rate)
	for i in count:
		var time := float(i) / rate
		var white := rng.randf_range(-1.0, 1.0)
		low = lerpf(low, white, smoothing)
		var bend: float = 1.0 - LOOK.release_pitch_fall * time / seconds if released else 1.0
		phase += TAU * pitch * bend / rate
		var ring: float = (sin(phase) + LOOK.overtone_gain * sin(phase * float(profile[4]))) / (1.0 + LOOK.overtone_gain)
		var envelope := exp(-time / decay)
		if crafted and time >= LOOK.craft_second_contact_s:
			envelope += LOOK.craft_second_gain * exp(-(time - LOOK.craft_second_contact_s) / decay)
		var value := lerpf(ring, low, friction) * envelope
		if released:
			value += (white - low) * LOOK.release_fracture_gain * exp(-time / LOOK.release_fracture_seconds)
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


static func play(root: Node, at: Vector3, cue: String) -> AudioStreamPlayer3D:
	if not is_instance_valid(root) or not root.is_inside_tree() or root.is_queued_for_deletion() or _host(cue).is_empty():
		return null
	var now := Time.get_ticks_msec()
	if cue == "collect":
		if root.has_meta(COLLECT_META) and now - int(root.get_meta(COLLECT_META)) < int(LOOK.collection_interval_s * 1000.0):
			return null
		root.set_meta(COLLECT_META, now)
	var sequence := int(root.get_meta(VARIANT_META, 0))
	var version := posmod(sequence, clampi(LOOK.variants, 1, 3))
	root.set_meta(VARIANT_META, (version + 1) % clampi(LOOK.variants, 1, 3))
	var stream := clip(cue, version)
	var active: Array[Node] = []
	for candidate: Node in root.get_tree().get_nodes_in_group(VOICE_GROUP):
		if not candidate.is_queued_for_deletion():
			active.append(candidate)
	# Station parents and the player's world root need not be the same node.
	# Their voices still share one budget and the oldest yields across roots.
	# Group traversal follows scene hierarchy, so compare actual creation order.
	active.sort_custom(func(a: Node, b: Node) -> bool:
		return int(a.get_meta("voice_sequence")) < int(b.get_meta("voice_sequence")))
	while active.size() >= clampi(LOOK.max_voices, 1, 8):
		var oldest := active.pop_front() as AudioStreamPlayer3D
		oldest.stop()
		oldest.remove_from_group(VOICE_GROUP)
		oldest.queue_free()
	var voice := AudioStreamPlayer3D.new()
	voice.name = "InteractionSound"
	voice.stream = stream
	voice.unit_size = LOOK.unit_size_m
	voice.volume_db = LOOK.work_gain_db
	voice.max_distance = LOOK.work_distance_m
	if cue == "collect":
		voice.volume_db = LOOK.collect_gain_db
		voice.max_distance = LOOK.collect_distance_m
	elif cue.begins_with("release_"):
		voice.volume_db = LOOK.release_gain_db
		voice.max_distance = LOOK.release_distance_m
	elif cue.begins_with("craft_"):
		voice.volume_db = LOOK.craft_gain_db
		voice.max_distance = LOOK.craft_distance_m
	root.add_child(voice)
	voice.global_position = at
	voice.set_meta("cue", cue)
	voice.set_meta("variant", version)
	voice.set_meta("voice_sequence", _voice_sequence)
	_voice_sequence += 1
	voice.add_to_group(VOICE_GROUP)
	voice.finished.connect(func() -> void:
		voice.remove_from_group(VOICE_GROUP)
		voice.queue_free())
	voice.play()
	return voice
