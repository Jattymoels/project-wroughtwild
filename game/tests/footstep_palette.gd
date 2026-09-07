extends Node
## INT-04B bounded palette and ownership checks; actual physical walking is
## covered separately by grounded_footsteps. No scene reads an owner's save.
const OUTPUT := "res://../captures/footsteps"
const RARE_SOUND = preload("res://art/strange_sound.gd")
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var evidence := {}


func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FOOTSTEP PALETTE: ", label)
	return ok


func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	sim = player.inventory.get_sim()
	_run.call_deferred()


func _run() -> void:
	_pcm_and_rng()
	_combined_peak_budget()
	_materials_and_terrain()
	await _voice_lifecycle()
	if "--footsteps-review" in OS.get_cmdline_user_args():
		_export_listening()
		evidence.checks = checks
		evidence.failures = failures
		var file := FileAccess.open(ProjectSettings.globalize_path(OUTPUT).path_join("palette-checks.json"), FileAccess.WRITE)
		if check(file != null, "write isolated palette review evidence"):
			file.store_string(JSON.stringify(evidence, "  "))
	print("FOOTSTEP_PALETTE %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)


func _voices() -> Array:
	var result := []
	for voice in get_tree().get_nodes_in_group(FootstepSound.VOICE_GROUP):
		if not voice.is_queued_for_deletion(): result.append(voice)
	return result


func _clear_voices() -> void:
	for voice in _voices(): voice.free()


func _pcm_and_rng() -> void:
	FootstepSound._clips.clear()
	var rules := sim.export_json()
	var ambush_state := player.ambush_rng.state
	var fight_state := player.combat.fight_seed_source.state
	seed(748931)
	var expected := randi()
	seed(748931)
	var recordings := []
	var cold_us := []
	# Time only synthesis. Sample inspection, exports and assertions happen
	# afterwards, so their work cannot masquerade as first-play synthesis cost.
	for surface in FootstepSound.SURFACES:
		for variant in 3:
			var began := Time.get_ticks_usec()
			var clip := FootstepSound.clip(surface, variant)
			var elapsed := Time.get_ticks_usec() - began
			recordings.append({"surface": surface, "variant": variant, "clip": clip})
			cold_us.append({"surface": surface, "variant": variant, "synthesis_us": elapsed})
	check(randi() == expected, "complete cold palette uses no global gameplay randomness")
	check(player.ambush_rng.state == ambush_state and player.combat.fight_seed_source.state == fight_state,
		"synthesis leaves encounter and gathering RNG streams unchanged")
	check(sim.export_json() == rules, "synthesis changes no native inventory, trial or progression state")
	var fingerprints := {}
	var total_bytes := 0
	for row in recordings:
		var clip: AudioStreamWAV = row.clip
		var label := "%s variant %d" % [row.surface, row.variant]
		if not check(clip != null, label + " exists"): continue
		check(clip.format == AudioStreamWAV.FORMAT_16_BITS and not clip.stereo and clip.loop_mode == AudioStreamWAV.LOOP_DISABLED,
			label + " is finite mono 16-bit PCM")
		check(clip.mix_rate == FootstepSound.LOOK.sample_rate and clip.get_length() <= .3,
			label + " is a short local contact")
		var bytes := clip.data
		var peak := 0
		for i in range(0, bytes.size(), 2): peak = maxi(peak, absi(bytes.decode_s16(i)))
		check(peak > 0 and peak <= int(FootstepSound.LOOK.pcm_peak_fraction * 32767) + 1, label + " has bounded nonzero PCM")
		check(bytes.decode_s16(0) == 0 and bytes.decode_s16(bytes.size() - 2) == 0, label + " has click-free sample boundaries")
		var fingerprint := hash(bytes)
		check(not fingerprints.has(fingerprint), label + " is distinct across the full palette")
		fingerprints[fingerprint] = true
		check(clip == FootstepSound.clip(row.surface, row.variant + 3000)
			and clip == FootstepSound.clip(row.surface, row.variant - 3000), label + " has bounded positive/negative variant keys")
		total_bytes += bytes.size()
	var cache_size := FootstepSound._clips.size()
	for unknown in ["", "splash", "rare_ore", "grass_unknown"]:
		check(FootstepSound.clip(unknown) == null and FootstepSound.play(self, Vector3.ZERO, unknown) == null,
			"unknown surface cannot allocate PCM or a voice: " + unknown)
	check(cache_size == 18 and FootstepSound._clips.size() == 18, "six surfaces and three variants bound the entire cache to eighteen clips")
	check(total_bytes < 200000, "complete default palette occupies less than 200 kB of PCM")
	var exact: PackedByteArray = FootstepSound.clip("timber", 2).data.duplicate()
	FootstepSound._clips.erase("timber:2")
	check(FootstepSound.clip("timber", 2).data == exact, "fresh synthesis reproduces the exact same contact")
	evidence.cold_synthesis_only = cold_us
	evidence.distinct_pcm_count = fingerprints.size()
	evidence.cached_clips = FootstepSound._clips.size()
	evidence.pcm_bytes = total_bytes


func _combined_peak_budget() -> void:
	var interaction: Resource = InteractionSound.LOOK
	var interaction_gain := maxf(maxf(interaction.work_gain_db, interaction.release_gain_db),
		maxf(interaction.craft_gain_db, interaction.collect_gain_db))
	var interaction_peak := clampi(interaction.max_voices, 1, 8) * float(interaction.pcm_peak_fraction) * db_to_linear(interaction_gain)
	var step_peak := clampi(FootstepSound.LOOK.max_voices, 1, 3) * float(FootstepSound.LOOK.pcm_peak_fraction) * db_to_linear(FootstepSound.LOOK.gain_db)
	var ambient: Resource = preload("res://art/environment_sound_look.tres")
	# The two retained beds crossfade within one outside level, rather than
	# adding two full-level beds. The ambience fixture checks this live bound.
	var ambient_peak := float(ambient.pcm_peak_fraction) * db_to_linear(ambient.outdoor_gain_db)
	var rare_look: Resource = preload("res://art/strange_look.tres")
	var rare_sample_peak := 0
	for kind in ["lanternheart", "thrumroot", "stormglass", "pullstone", "ventlung"]:
		var bytes: PackedByteArray = RARE_SOUND._clip(kind).data
		for i in range(0, bytes.size(), 2): rare_sample_peak = maxi(rare_sample_peak, absi(bytes.decode_s16(i)))
	var rare_peak := float(rare_sample_peak) / 32767.0 * db_to_linear(rare_look.clue_volume_db)
	var combined := interaction_peak + step_peak + ambient_peak + rare_peak
	check(combined < 1.0, "configured interaction, step, combined ambient and one discovery clue peaks fit below full scale")
	evidence.local_feedback_peak_bound = {"interaction": interaction_peak, "footsteps": step_peak,
		"ambience_combined": ambient_peak, "single_discovery_clue": rare_peak, "sum": combined,
		"scope": "Coherent worst-case local feedback sources at configured close gain. Combat and hardware/master processing remain separate mix review."}


func _materials_and_terrain() -> void:
	var expected := {
		"wood": "timber", "pine": "timber", "bog_oak": "timber", "ash_wood": "timber", "resinheart": "timber",
		"iron": "metal", "bronze": "metal", "steel": "metal", "silver": "metal",
		"woven_reed": "fibre", "corkbark": "fibre",
		"stone": "stone", "fieldstone": "stone", "slate": "stone", "shellstone": "stone",
		"rustclay_brick": "stone", "vitrified_basalt": "stone", "cinderglass": "stone", "charcoal": "stone",
	}
	for id in sim.build_material_ids():
		check(expected.has(id), "review covers existing construction family " + id)
		check(FootstepSound.material_surface(sim.build_material(id)) == expected.get(id), id + " follows its actual existing material traits")
	check(FootstepSound.material_surface({}) == "stone", "unknown solid material has a quiet neutral contact")
	var expected_ground := {"grass": "grass", "forest_floor": "grass", "marsh": "grass", "dirt": "earth", "ash": "earth",
		"rock": "stone", "stone": "stone", "bedrock": "stone"}
	for kind in expected_ground:
		check(FootstepSound.terrain_surface(kind) == expected_ground[kind], kind + " uses existing dry ground, without inferred water")
	# Deliberately put the hit position in the wrong column: face_index must
	# select the exact voxel represented by the slanted collision triangle.
	var terrain := Terrain.new()
	terrain.name = "Terrain"
	terrain.faceted_surface = true
	terrain.map = {"width": 2, "height": 1, "depth": 6, "cell_size": 1.0,
		"biomes": PackedInt32Array([0, 1]), "biome_defs": [{"surface": "grass"}, {"surface": "ash"}]}
	terrain._blocks.resize(12)
	terrain._blocks.fill(0)
	terrain._blocks[3] = 1
	terrain._blocks[8] = 2
	add_child(terrain)
	var body := StaticBody3D.new()
	body.set_meta("terrain_chunk", true)
	body.set_meta("surface_cells", PackedVector3Array([Vector3(1, 2, 0), Vector3(0, 3, 0)]))
	terrain.add_child(body)
	var hit := {"collider": body, "position": Vector3(.25, 4, .25), "normal": Vector3(.2, .9, .1).normalized(), "face_index": 0}
	check(player.footsteps._surface_for(hit) == "earth", "faceted collision reads exposed dirt from its exact voxel instead of grassy map height")
	terrain._blocks[8] = 3
	check(player.footsteps._surface_for(hit) == "stone", "exposed stone remains mineral despite the biome surface")
	terrain._blocks[8] = 1
	check(player.footsteps._surface_for(hit) == "earth", "native ash topsoil resolves through the actual column biome")
	hit.face_index = 1
	check(player.footsteps._surface_for(hit) == "grass", "another triangle resolves its own grass column")
	var piece := PlacedBlock.new()
	piece.material_family = &"pine"
	add_child(piece)
	hit.collider = piece
	check(player.footsteps._surface_for(hit) == "timber", "a placed timber support takes priority over ground below it")
	piece.material_family = &"steel"
	check(player.footsteps._surface_for(hit) == "metal", "placed alloy support reads actual native metal traits")
	piece.free()
	hit.collider = self
	check(player.footsteps._surface_for(hit) == "stone", "unlabelled authored trial support uses neutral stone")
	terrain.free()


func _voice_lifecycle() -> void:
	_clear_voices()
	var outside := Node.new()
	check(FootstepSound.play(outside, Vector3.ZERO, "grass") == null, "unattached owners do not create dangling playback")
	outside.free()
	check(FootstepSound.play(null, Vector3.ZERO, "grass") == null, "missing owner is quiet")
	var retiring := Node.new()
	add_child(retiring)
	retiring.queue_free()
	check(FootstepSound.play(retiring, Vector3.ZERO, "grass") == null, "queued owner rejects new sound")
	var sound_owner := Node3D.new()
	add_child(sound_owner)
	var at := Vector3(3, 0, 2)
	var planted := FootstepSound.play(sound_owner, at, "stone")
	check(planted != null and planted.global_position.is_equal_approx(at), "contact starts at its actual world support")
	sound_owner.position += Vector3(20, 0, 0)
	check(planted.global_position.is_equal_approx(at), "finished foot contact stays at its ground position as owner moves")
	check(planted.bus == &"Master" and planted.process_mode == Node.PROCESS_MODE_INHERIT, "contact uses the normal Master bus and inherited processing")
	var master := AudioServer.get_bus_index(&"Master")
	var was_muted := AudioServer.is_bus_mute(master)
	AudioServer.set_bus_mute(master, true)
	var muted := FootstepSound.play(sound_owner, at, "grass")
	check(muted != null and muted.bus == &"Master" and AudioServer.is_bus_mute(master), "new contacts remain on the owner's muted Master bus")
	AudioServer.set_bus_mute(master, was_muted)
	sound_owner.free()
	check(not is_instance_valid(planted) and not is_instance_valid(muted) and _voices().is_empty(), "owner teardown removes its sounds and budget entries")
	var interactions := []
	for i in 8:
		interactions.append(InteractionSound.play(self, Vector3.ZERO, "work_wood"))
	var sibling := Node.new()
	get_tree().root.add_child(sibling)
	var first := FootstepSound.play(self, Vector3.ZERO, "grass")
	for i in 40:
		FootstepSound.play(sibling if i % 2 else self, Vector3(float(i), 0, 0), FootstepSound.SURFACES[i % 6], i)
	check(first.is_queued_for_deletion(), "shared budget retires the oldest contact across owner hierarchies")
	check(_voices().size() == 3, "forty rapid contacts under multiple roots cap at three live voices")
	for voice in interactions:
		check(is_instance_valid(voice) and not voice.is_queued_for_deletion(), "footstep burst preserves each existing interaction voice")
	check(get_tree().get_nodes_in_group(InteractionSound.VOICE_GROUP).size() == 8, "interaction budget remains independent from contact voices")
	check(3 * float(FootstepSound.LOOK.pcm_peak_fraction) * db_to_linear(FootstepSound.LOOK.gain_db) < .13,
		"three worst-case coherent contacts leave ample headroom for existing sounds")
	await get_tree().create_timer(1.0).timeout
	check(_voices().is_empty() and sibling.get_child_count() == 0, "actual short playback finishes and frees all contact owners' voices")
	sibling.free()
	var before_count := player.footsteps.step_count
	player.footsteps._distance = 1.6
	FootstepSound.play(player.footsteps, Vector3.ZERO, "timber")
	player.footsteps.reset_context()
	check(_voices().is_empty() and player.footsteps._distance == 0 and player.footsteps._previous_frame == -1,
		"context reset discards pending stride and previous sound tails")
	check(player.footsteps.step_count == before_count, "context reset grants no synthetic step or counter event")
	player.footsteps._distance = 1.6
	FootstepSound.play(player.footsteps, Vector3.ZERO, "timber")
	get_tree().paused = true
	await get_tree().create_timer(.05, true).timeout
	check(_voices().is_empty() and player.footsteps._distance == 0, "pause removes stale contact tails and pending distance")
	get_tree().paused = false
	await get_tree().process_frame
	check(_voices().is_empty() and player.footsteps.step_count == before_count, "resume creates no contact or delayed playback")


func _export_listening() -> void:
	var out := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(out)
	var reel := AudioStreamWAV.new()
	reel.format = AudioStreamWAV.FORMAT_16_BITS
	reel.stereo = false
	reel.mix_rate = FootstepSound.LOOK.sample_rate
	var bytes := PackedByteArray()
	var silence := PackedByteArray()
	silence.resize(int(.34 * reel.mix_rate) * 2)
	silence.fill(0)
	var manifest := []
	var gain := db_to_linear(FootstepSound.LOOK.gain_db)
	for surface in FootstepSound.SURFACES:
		for variant in 3:
			var clip := FootstepSound.clip(surface, variant)
			var filename := "%s-%d.wav" % [surface, variant]
			check(clip.save_to_wav(out.path_join(filename)) == OK, "export raw " + filename)
			manifest.append({"surface": surface, "variant": variant, "file": filename,
				"start_seconds": float(bytes.size()) / (reel.mix_rate * 2), "duration_seconds": clip.get_length()})
			var scaled := clip.data.duplicate()
			for i in range(0, scaled.size(), 2): scaled.encode_s16(i, int(scaled.decode_s16(i) * gain))
			bytes.append_array(scaled)
			bytes.append_array(silence)
	reel.data = bytes
	check(reel.save_to_wav(out.path_join("footstep-listening-reel.wav")) == OK, "export configured-gain listening reel")
	var file := FileAccess.open(out.path_join("listening-manifest.json"), FileAccess.WRITE)
	if check(file != null, "write labelled listening manifest"):
		file.store_string(JSON.stringify({"scope": "All six surfaces and three variants. Individual files are raw source PCM; the reel applies the configured contact gain. No spatial attenuation, hardware volume, other sounds or human comfort acceptance is implied.",
			"reel": "footstep-listening-reel.wav", "reel_gain_db": FootstepSound.LOOK.gain_db, "silence_between_contacts_s": .34, "clips": manifest}, "  "))
