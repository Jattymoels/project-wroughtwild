extends Node
## Offline listening arrangement, at configured gains before spatial attenuation.
## This is neither a recorded sound device mix nor a gameplay resource promise.
const RATE := 22050
const SECONDS := 20.0
const RARE = preload("res://art/strange_sound.gd")
var samples := PackedFloat32Array()
var entries: Array[Dictionary] = []
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ENVIRONMENT_MIX: ",label)

func mix_clip(clip: AudioStreamWAV, at: float, db: float) -> void:
	var count := clip.data.size() / 2
	var length := float(count) / clip.mix_rate
	var offset := int(at * RATE)
	for i in int(length * RATE):
		if offset + i >= samples.size(): break
		# Linear reconstruction for the 11,025 Hz ambience, exact samples for the
		# existing 22,050 Hz contacts. Every clip plays once, without wrapping.
		var source := float(i) * clip.mix_rate / RATE
		var index := mini(floori(source), count - 1)
		var value := lerpf(float(clip.data.decode_s16(index * 2)), float(clip.data.decode_s16(mini(index + 1, count - 1) * 2)), fposmod(source, 1.0)) / 32767.0
		samples[offset + i] += value * db_to_linear(db)

func _ready() -> void:
	samples.resize(int(RATE * SECONDS))
	for section in 4:
		var at := float(section) * 5
		var bed: String = EnvironmentSound.BEDS[section]
		var surface: String = ["grass","timber","fibre","stone"][section]
		var gain: float = EnvironmentSound.LOOK.outdoor_gain_db
		mix_clip(EnvironmentSound.clip(bed),at,gain)
		for step in 10:
			mix_clip(FootstepSound.clip(surface,step % 3),at + .5 + step * .37,FootstepSound.LOOK.gain_db)
		var cue := "work_wood" if section < 2 else "work_stone"
		mix_clip(InteractionSound.clip(cue),at + 2.2,InteractionSound.LOOK.work_gain_db)
		entries.append({"from_s":at,"to_s":at+5,"bed":bed,"footsteps":surface,"work":cue})
	mix_clip(RARE._clip("lanternheart"),3.0,RARE.LOOK.clue_volume_db)
	mix_clip(RARE._clip("thrumroot"),8.0,RARE.LOOK.clue_volume_db)
	var peak := 0.0
	for value in samples: peak = maxf(peak,absf(value))
	check(peak > 0.0 and peak < 1.0,"configured simultaneous sources retain PCM headroom")
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size(): bytes.encode_s16(i * 2,int(clampf(samples[i],-1,1)*32767))
	var stream := AudioStreamWAV.new()
	stream.mix_rate = RATE
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.data = bytes
	var directory := ProjectSettings.globalize_path("res://../captures/footsteps")
	DirAccess.make_dir_recursive_absolute(directory)
	check(stream.save_to_wav(directory.path_join("environment-mixed-reel.wav")) == OK,"export configured-gain mixed reel")
	var report := {"checks":checks,"failures":failures,"seconds":SECONDS,"peak_fraction":peak,"segments":entries,
		"scope":"Compressed palette comparison, not gameplay cadence. Offline configured-gain arrangement before 3D attenuation, Master volume and device effects; no normalization. Existing rare clues at 3 and 8 s are included only to assess separation, not emitted by biome ambience. quiet_ambience exports the actual quiet-gap schedule."}
	var file := FileAccess.open(directory.path_join("environment-mixed-reel.json"),FileAccess.WRITE)
	check(file != null,"write isolated listening manifest")
	if file != null: file.store_string(JSON.stringify(report,"  ")); file.close()
	print("ENVIRONMENT_MIX %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
