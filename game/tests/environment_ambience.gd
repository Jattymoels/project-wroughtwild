extends Node3D
## INT-04B/C: actual profile payloads, bounded playback and quiet lifecycle paths.
## No user save, external asset or gameplay hearing behaviour is exercised.
const OUTPUT := "res://../captures/ambience"
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var terrain: Terrain
var ambience: EnvironmentAmbience
var sim: WroughtwildSim
var evidence := {}

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ENVIRONMENT_AMBIENCE: ", label)
	return ok

func _ready() -> void:
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	for child in player.get_children():
		if child is EnvironmentAmbience: ambience = child
	if ambience == null:
		ambience = EnvironmentAmbience.new()
		ambience.setup(player)
		player.add_child(ambience)
	ambience.set_process(false)
	sim = player.inventory.get_sim()
	_run.call_deferred()

func _run() -> void:
	_pcm()
	_profile_contracts()
	_local_lookup()
	_lifecycle()
	if "--ambience-review" in OS.get_cmdline_user_args(): _export()
	print("ENVIRONMENT_AMBIENCE %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func _pcm() -> void:
	var native_before := sim.export_json()
	var ambush_before := player.ambush_rng.state
	var fight_before := player.combat.fight_seed_source.state
	seed(4019)
	var expected_global := randi()
	seed(4019)
	# Exercise cold synthesis explicitly: scene preparation already cached its
	# normal palette, so this bounded fixture frees and reconstructs that cache.
	EnvironmentSound._clips.clear()
	var synthesis_usec := 0
	var fingerprints := {}
	for index in EnvironmentSound.BEDS.size() * EnvironmentSound.LOOK.variants:
		var bed: String = EnvironmentSound.BEDS[index / EnvironmentSound.LOOK.variants]
		var variant := index % EnvironmentSound.LOOK.variants
		var key := "%s:%d" % [bed, variant]
		var began := Time.get_ticks_usec()
		var stream := EnvironmentSound.clip(bed, variant)
		var count := stream.data.size() / 2
		synthesis_usec += Time.get_ticks_usec() - began
		check(stream != null and stream == EnvironmentSound.clip(bed, variant), key + " reuses a fixed stream")
		check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, key + " cannot sustain a repeated bed")
		check(count * 2 == stream.data.size() and not stream.stereo, key + " exact mono PCM bounds")
		check(stream.get_length() >= EnvironmentSound.LOOK.clip_seconds.x - .001 and stream.get_length() <= EnvironmentSound.LOOK.clip_seconds.y, key + " is a bounded short texture")
		check(stream.mix_rate == EnvironmentSound.LOOK.sample_rate, bed + " configured bandwidth")
		var peak := 0
		var total := 0.0
		var energy := 0.0
		for i in count:
			var value := stream.data.decode_s16(i * 2)
			peak = maxi(peak, absi(value))
			total += value
			energy += float(value) * value
		check(peak > 0 and peak <= 32767 * EnvironmentSound.LOOK.pcm_peak_fraction + 1, bed + " bounded nonempty PCM")
		check(absf(total / count) < sqrt(energy / count) * 0.03, bed + " no material DC offset")
		var seam := absf(float(stream.data.decode_s16(0) - stream.data.decode_s16(stream.data.size() - 2)))
		check(seam == 0 and stream.data.decode_s16(0) == 0, key + " begins and ends at exact silence")
		fingerprints[key] = stream.data.hex_encode().hash()
		evidence[key] = {"sample_rate":stream.mix_rate,"samples":count,"peak":peak,"edge_step":seam}
	evidence["cold_palette_ms"] = synthesis_usec / 1000.0
	check(EnvironmentSound.clip("lanternheart") == null and EnvironmentSound.clip("ventlung") == null, "rare discovery vocabulary is outside the bed palette")
	check(EnvironmentSound.clip("unknown") == null and EnvironmentSound._clips.size() == 12, "unknown input cannot expand the twelve-clip cache")
	var distinct := {}
	for key in fingerprints: distinct[fingerprints[key]] = true
	check(distinct.size() == 12, "all four textures and their variants differ")
	check(EnvironmentSound.clip("air", 300) == EnvironmentSound.clip("air", 0), "arbitrary variant requests reuse the bounded cache")
	check(randi() == expected_global, "cold synthesis preserves global RNG")
	check(sim.export_json() == native_before and player.ambush_rng.state == ambush_before and player.combat.fight_seed_source.state == fight_before,
		"cold synthesis preserves native economy and combat/gathering RNG")

func _profile_contracts() -> void:
	var prior := sim.world_profile()
	for profile in ["legacy_v1", "frontier_v2", "frontier_v3", "frontier_v4", "frontier_v5", "frontier_v6"]:
		check(sim.set_world_profile(profile), profile + " remains selectable")
		terrain.map.clear()
		var map := sim.world_map(1)
		if not check(not map.is_empty(), profile + " supplies actual native geography"): continue
		terrain.map = map
		terrain._world_profile = profile
		terrain._seed = 1
		var width := int(map.width)
		var height := int(map.height)
		check((map.biomes as PackedInt32Array).size() == width * height, profile + " shares the row-major biome contract")
		var sample_cells := [Vector2i.ZERO, Vector2i(width - 1, height - 1), Vector2i(width >> 1, height >> 1), Vector2i(int(map.spawn_x), int(map.spawn_z))]
		for cell: Vector2i in sample_cells:
			var def: Dictionary = map.biome_defs[map.biomes[cell.y * width + cell.x]]
			var expected := EnvironmentSound.bed_for_surface(String(def.surface))
			var at := Vector3((cell.x + 0.5) * float(map.cell_size), 50, (cell.y + 0.5) * float(map.cell_size))
			check(not expected.is_empty() and EnvironmentAmbience.bed_at(terrain, at) == expected, profile + " samples its own selected surface " + str(cell))
		# Optional discovery content cannot become a hidden sound requirement.
		for field in ["habitats", "regions", "rare_sites", "nodes", "pressure_pockets"]: terrain.map.erase(field)
		check(not EnvironmentAmbience.bed_at(terrain, Vector3.ONE * 0.5).is_empty(), profile + " requires no resource/site ledger")
		terrain.map.clear()
	check(sim.set_world_profile(prior), "restore fixture profile")

func _small_map() -> void:
	terrain.position = Vector3.ZERO
	terrain._world_profile = "frontier_v6"
	terrain._seed = 4
	terrain.map = {"width":4,"height":2,"cell_size":2.0,"biomes":PackedInt32Array([0,1,2,3,3,2,1,0]),
		"biome_defs":[{"surface":"grass"},{"surface":"forest_floor"},{"surface":"marsh"},{"surface":"rock"}]}
	player.position = Vector3(1,2,1)
	player.velocity = Vector3.ZERO
	player.combat.sheltered = false
	player.set_physics_process(true)
	ambience.reset_context()

func _local_lookup() -> void:
	_small_map()
	for x in 4:
		check(EnvironmentAmbience.bed_at(terrain, Vector3(x * 2 + 0.5,3,0.5)) == EnvironmentSound.BEDS[x], "actual cell size selects each ordinary surface")
	for at in [Vector3(-0.01,2,1),Vector3(1,2,-0.01),Vector3(8,2,1),Vector3(1,2,4),Vector3(INF,2,1)]:
		check(EnvironmentAmbience.bed_at(terrain, at).is_empty(), "out-of-map position stays silent " + str(at))
	terrain.position = Vector3(-30,5,70)
	check(EnvironmentAmbience.bed_at(terrain, terrain.to_global(Vector3(3,2,1))) == "foliage", "translated terrain uses local coordinates")
	terrain.position = Vector3.ZERO
	terrain.map.biomes[0] = -1
	check(EnvironmentAmbience.bed_at(terrain, Vector3.ONE).is_empty(), "invalid biome index stays quiet")
	terrain.map.biomes = PackedInt32Array([0])
	check(EnvironmentAmbience.bed_at(terrain, Vector3.ONE).is_empty(), "incomplete map payload stays quiet")
	terrain.map.clear()
	check(EnvironmentAmbience.bed_at(terrain, Vector3.ONE).is_empty(), "unbuilt chooser has no bed")
	_small_map()

func _quiet(label: String) -> void:
	check(ambience.active_bed.is_empty() and ambience._target == -1, label + " clears previous place")
	for voice in ambience._voices:
		check(not voice.playing and is_zero_approx(voice.volume_linear), label + " stops and silences retained voice")

func _settle() -> void:
	# Advance the new quiet gap without forcing a private playback function.
	for attempt in 3:
		ambience._process(EnvironmentSound.LOOK.quiet_seconds.y + .1)
		if ambience._target >= 0: return

func _lifecycle() -> void:
	_small_map()
	var native_before := sim.export_json()
	var ambush_before := player.ambush_rng.state
	var fight_before := player.combat.fight_seed_source.state
	_settle()
	check(ambience.active_bed == "air", "enabled live player receives ordinary local air")
	check(ambience._voices.size() == 1 and ambience.get_child_count() == 1, "only one retained player exists")
	var voice_id := ambience._voices[0].get_instance_id()
	var outside := db_to_linear(EnvironmentSound.LOOK.outdoor_gain_db)
	check(is_equal_approx(ambience._levels[ambience._target], outside), "settled outdoor gain uses presentation setting")
	player.combat.sheltered = true
	_settle()
	check(is_equal_approx(ambience._levels[ambience._target], db_to_linear(EnvironmentSound.LOOK.outdoor_gain_db - EnvironmentSound.LOOK.shelter_attenuation_db)), "existing shelter quiets the outdoor bed")
	player.combat.sheltered = false
	for repeat in 12:
		for x in 4:
			player.position.x = x * 2 + 1
			ambience._process(EnvironmentSound.LOOK.sample_interval_seconds)
			check(ambience.active_bed == EnvironmentSound.BEDS[x], "repeated crossing selects the next local surface")
			check(ambience._voices[0].get_instance_id() == voice_id, "crossing never adds or replaces a voice")
			check(ambience._levels[0] <= outside + 0.00001, "surface transition keeps gain bounded")
	var master := AudioServer.get_bus_index(&"Master")
	var old_mute := AudioServer.is_bus_mute(master)
	var old_db := AudioServer.get_bus_volume_db(master)
	AudioServer.set_bus_mute(master, true)
	_settle()
	check(AudioServer.is_bus_mute(master) and AudioServer.get_bus_volume_db(master) == old_db, "ambience respects existing Master mute and level")
	for voice in ambience._voices: check(voice.bus == &"Master", "each voice routes through the owner's Master bus")
	AudioServer.set_bus_mute(master, old_mute)
	player.set_physics_process(false)
	ambience._process(0.01)
	_quiet("disabled class/seed movement")
	player.set_physics_process(true)
	_settle()
	get_tree().paused = true
	_quiet("paused scene tree")
	get_tree().paused = false
	_settle()
	player.combat.life = 0.0
	ambience._process(0.01)
	_quiet("nonliving player")
	player.combat.restore_life()
	_settle()
	check(player.combat.died.is_connected(ambience.reset_context), "actual death signal resets ambience")
	player.combat.died.emit()
	_quiet("actual death callback")
	_small_map()
	_settle()
	check(sim.trial_start(91), "fixture enters an actual native trial")
	ambience._process(0.01)
	_quiet("trial shares the world scene")
	sim.trial_abandon()
	check(sim.trial_end(), "fixture closes trial through its normal abandonment contract")
	_settle()
	ambience.reset_context()
	_quiet("same-coordinate restore hook")
	ambience._process(0.0)
	check(not ambience.active_bed.is_empty() and is_zero_approx(ambience._levels[ambience._target]), "restore restarts from silence without a burst")
	_settle()
	terrain._seed += 1
	ambience._process(0.0)
	check(is_zero_approx(ambience._levels[ambience._target]), "same-position new seed clears previous gain")
	_settle()
	terrain._world_profile = "legacy_v1"
	ambience._process(0.0)
	check(is_zero_approx(ambience._levels[ambience._target]), "same-position profile change clears previous gain")
	_settle()
	# An in-bounds vertical relocation is enough: biome identity alone cannot
	# detect a move from the surface to a deep cave or a respawn overhead.
	player.position.y += EnvironmentSound.LOOK.teleport_distance_m + 1
	ambience._process(0.0)
	check(is_zero_approx(ambience._levels[ambience._target]), "large in-map relocation clears old gain")
	player.position.x = -0.01
	ambience._process(0.01)
	_quiet("leaving finite map")
	check(sim.export_json() == native_before and player.ambush_rng.state == ambush_before and player.combat.fight_seed_source.state == fight_before,
		"ambient context does not alter inventory, choices or gameplay RNG")
	check(EnvironmentSound._clips.size() == 12, "crossings and lifecycle retain a bounded twelve-clip cache")
	player.set_physics_process(false)

func _export() -> void:
	var directory := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(directory)
	for bed: String in EnvironmentSound.BEDS:
		for variant in EnvironmentSound.LOOK.variants:
			check(EnvironmentSound.clip(bed, variant).save_to_wav(directory.path_join("%s-%d.wav" % [bed, variant])) == OK, "export " + bed + " short texture")
	evidence["checks"] = checks
	evidence["failures"] = failures
	var file := FileAccess.open(directory.path_join("ambience-checks.json"), FileAccess.WRITE)
	if check(file != null, "write local ambience evidence"): file.store_string(JSON.stringify(evidence, "  "))
