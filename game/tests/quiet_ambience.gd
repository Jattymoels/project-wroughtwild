extends "res://tests/environment_ambience.gd"
## Actual listener scheduling, with accelerated elapsed time and offline PCM.
## Dummy audio does not establish comfort on the owner's speakers.
var elapsed := 0.0
var events: Array[Dictionary] = []
var mix: Node

func _run() -> void:
	_small_map()
	player.audio_preferences.path = "res://quiet-ambience-prefs.cfg"
	player.audio_preferences.set_ambience(1.0, false)
	ambience._rng.seed = 40819
	ambience.clip_started.connect(_started)
	var native_before := sim.export_json()
	var ambush_before := player.ambush_rng.state
	var fight_before := player.combat.fight_seed_source.state
	seed(8083)
	var expected_global := randi()
	seed(8083)
	var directory := ProjectSettings.globalize_path("res://../captures/quiet-ambience")
	DirAccess.make_dir_recursive_absolute(directory)
	var report := []
	for context in ["meadow", "vegetation", "exposed_stone", "shelter"]:
		player.position.x = 3 if context == "vegetation" else (7 if context == "exposed_stone" else 1)
		player.combat.sheltered = context == "shelter"
		ambience.reset_context()
		events.clear()
		mix = preload("res://tests/environment_mix.gd").new()
		mix.samples.resize(180 * mix.RATE)
		for tick in 1800:
			elapsed = tick * .1
			ambience._process(.1)
		var sounding := 0.0
		var previous_end := 0.0
		var previous_variant := -1
		for event in events:
			var gap: float = event.at - previous_end
			check(gap >= 12.0 - .001 and gap <= 24.2, context + " each complete quiet gap stays within its configured range")
			check(event.variant != previous_variant, context + " adjacent textures vary")
			check(event.bed == ("foliage" if context == "vegetation" else ("stone" if context == "exposed_stone" else "air")), context + " texture matches local ground")
			var expected := db_to_linear(EnvironmentSound.LOOK.outdoor_gain_db - (18.0 if context == "shelter" else 0.0))
			check(is_equal_approx(event.gain, expected), context + " configured gain reaches playback")
			sounding += minf(event.seconds, 180.0 - event.at)
			previous_end = event.at + event.seconds
			previous_variant = event.variant
		check(events.size() >= 6 and sounding <= 36.0, context + " has intermittent sound and at least 80 percent ambient silence")
		check(ambience.get_child_count() == 1, context + " keeps only one retained voice")
		var ambient_path := _write_mix(directory.path_join(context + "-ambience.wav"))
		# Existing work and footsteps at their configured gains, without new cues.
		var surface := "timber" if context == "shelter" else ("stone" if context == "exposed_stone" else "grass")
		for step in 80: mix.mix_clip(FootstepSound.clip(surface, step % 3), 30.0 + step * .42, FootstepSound.LOOK.gain_db)
		for work in 8: mix.mix_clip(InteractionSound.clip("work_stone" if context == "exposed_stone" else "work_wood", work % 3), 95.0 + work * 1.2, InteractionSound.LOOK.work_gain_db)
		var mixed_path := _write_mix(directory.path_join(context + "-work-and-walking.wav"))
		report.append({"context":context,"seconds":180,"sounding_seconds":sounding,"quiet_fraction":1.0-sounding/180.0,"events":events.duplicate(true),"ambience":ambient_path,"mixed":mixed_path})
		mix.free()
		mix = null
	check(randi() == expected_global, "scheduling and reel generation preserve global RNG")
	check(sim.export_json() == native_before and player.ambush_rng.state == ambush_before and player.combat.fight_seed_source.state == fight_before, "scheduling preserves native ownership and gameplay RNG")
	# A delayed frame neither replays missed clips nor schedules a burst.
	events.clear()
	ambience.reset_context()
	ambience._process(.1)
	ambience._process(60.0)
	check(events.size() == 1, "one long frame starts at most one clip")
	ambience._process(60.0)
	check(events.size() == 1 and ambience._target == -1 and ambience._quiet_left >= 12.0, "next delayed frame ends clip and starts a full quiet gap")
	var file := FileAccess.open(directory.path_join("listening-manifest.json"), FileAccess.WRITE)
	check(file != null, "write labelled normal-gain listening manifest")
	if file != null:
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"contexts":report,"scope":"Actual listener event schedule with accelerated elapsed time; offline PCM at configured gains, without normalization, spatial attenuation, Master/device processing or hardware audition. Mixed copies add existing footsteps at 30–64 s and work at 95–104 s. No combat sounds are invented."}, "  "))
		file.close()
	print("QUIET_AMBIENCE %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func _started(bed: String, variant: int, stream: AudioStreamWAV, gain: float) -> void:
	events.append({"at":elapsed,"bed":bed,"variant":variant,"seconds":stream.get_length(),"gain":gain})
	if mix != null: mix.mix_clip(stream, elapsed, linear_to_db(gain))

func _write_mix(path: String) -> String:
	var bytes := PackedByteArray()
	bytes.resize(mix.samples.size() * 2)
	var peak := 0.0
	for i in mix.samples.size():
		peak = maxf(peak, absf(mix.samples[i]))
		bytes.encode_s16(i * 2, int(clampf(mix.samples[i], -1.0, 1.0) * 32767))
	check(peak > 0.0 and peak < 1.0, "normal-gain reel stays nonempty without clipping")
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = mix.RATE
	stream.data = bytes
	check(stream.save_to_wav(path) == OK, "export " + path.get_file())
	return path.get_file()
