extends Node3D
## Truthful action boundaries using real resources, player, native hauling and
## SaveManager. Fixture stock does not measure gathering/economy pacing.
const RESOURCE := preload("res://scenes/resource_node.tscn")
const OUTPUT := "res://../captures/feedback"
const RARES := ["lanternheart", "thrumroot", "stormglass", "pullstone", "ventlung"]
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var initial_rules := ""
var manager := SaveManager.new()
var evidence := {}

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: interaction feedback: ", label)
	return ok

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.global_position = Vector3(100, 10, 100)
	sim = player.inventory.get_sim()
	initial_rules = sim.export_json()
	_run.call_deferred()

func _run() -> void:
	_work_boundaries()
	_resource_palette()
	_collection()
	_silent_restore()
	_pcm_and_rng()
	await _voice_lifetime()
	if "--feedback-review" in OS.get_cmdline_user_args():
		_export_listening()
		if DisplayServer.get_name() != "headless": await _capture_work()
	evidence.checks = checks
	evidence.failures = failures
	if "--feedback-review" in OS.get_cmdline_user_args():
		var out := ProjectSettings.globalize_path(OUTPUT)
		DirAccess.make_dir_recursive_absolute(out)
		var file := FileAccess.open(out.path_join("feedback-checks.json"), FileAccess.WRITE)
		if check(file != null, "write isolated review evidence"):
			file.store_string(JSON.stringify(evidence, "  "))
	print("INTERACTION_FEEDBACK %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func _voices() -> Array:
	var result := []
	for voice in get_tree().get_nodes_in_group("interaction_sounds"):
		if is_ancestor_of(voice) and not voice.is_queued_for_deletion(): result.append(voice)
	return result

func _clear_voices() -> void:
	for voice in _voices(): voice.free()

func _reset() -> void:
	_clear_voices()
	for node in get_tree().get_nodes_in_group("resources"):
		if is_ancestor_of(node): node.free()
	WorldDrops.restore(self, {"version": 1, "pickups": [], "bundles": []})
	check(sim.import_json(initial_rules), "reset isolated native inventory")

func _resource(visual: String, family := "fieldstone", presses := 3) -> ResourceNode:
	var node: ResourceNode = RESOURCE.instantiate()
	node.visual = StringName(visual)
	node.material_family = StringName(family)
	node.name = "Feedback_" + visual
	node.remaining_units = 4
	node.units_per_harvest = 4
	node.drive_presses = presses
	node.position = Vector3(0, 0, -3)
	add_child(node)
	return node

func _expect_cue(cue: String, label: String) -> void:
	var voices := _voices()
	if not check(voices.size() == 1, label + ": one cue"): return
	check(String(voices[0].get_meta("cue", "")) == cue, label + ": correct event identity")
	check(voices[0].get_parent() == self, label + ": sound belongs to the world")

func _work_boundaries() -> void:
	_reset()
	var seam := _resource("seam", "split_stone", 4)
	seam.tool_item = &"timber_wedge"
	var hands := player.camera.get_node("FirstPersonHands") as FirstPersonHands
	hands.remaining = 0
	var stock := sim.export_json()
	player._apply_work(seam, seam.work(sim))
	check(_voices().is_empty() and hands.remaining == 0, "missing wedge plays no work success")
	check(sim.export_json() == stock and not seam.wedge_set, "refusal changes no native inventory or seam state")
	player._apply_work(seam, seam.strike())
	check(_voices().is_empty(), "strike without a wedge remains quiet")
	sim.add_material("timber_wedge", 1)
	player._apply_work(seam, seam.work(sim))
	_expect_cue(InteractionSound.resource_cue("seam", false), "accepted wedge seating")
	check(seam.wedge_set and sim.material_count("timber_wedge") == 0, "one native wedge cost precedes contact")
	_clear_voices()
	player._apply_work(seam, seam.strike())
	_expect_cue(InteractionSound.resource_cue("seam", true), "heavy strike release")
	check(seam.remaining_units == 0 and sim.material_count("split_stone") == 0, "released stone is still outside the pack")
	_clear_voices()
	player._apply_work(seam, {})
	player._apply_work(seam, {"granted": 0})
	player._apply_work(seam, seam.work(sim))
	check(_voices().is_empty(), "empty, zero-yield and exhausted work do not claim success")
	var ore := _resource("ember_vein", "ember_ore")
	ore.heat_to_work = 2
	player._apply_work(ore, ore.work(sim))
	check(_voices().is_empty() and ore.drive_progress == 0, "cold gated ore plays no success cue")
	ore.soak(1, 30)
	player._apply_work(ore, ore.work(sim))
	check(_voices().is_empty(), "insufficient heat remains quiet")
	ore.soak(2, 30)
	player._apply_work(ore, ore.strike())
	_expect_cue(InteractionSound.resource_cue("ember_vein", false), "successful thermal fracture")
	check(ore.cracked and ore.remaining_units == 4, "fracture feedback does not invent a material payout")

func _resource_palette() -> void:
	for visual in ["tree", "resinheart_tree", "corkbark_deadfall", "reed_bed", "clay_bank", "boulder"] + RARES:
		_reset()
		var node := _resource(visual, "wood" if visual in ["tree", "resinheart_tree", "corkbark_deadfall"] else "fieldstone")
		var before := sim.export_json()
		var work_cue := InteractionSound.resource_cue(visual, false)
		var release_cue := InteractionSound.resource_cue(visual, true)
		check(work_cue != release_cue, visual + " separates work from release")
		var hit := {"position": node.global_position + Vector3(0, .7, .1), "normal": Vector3.BACK}
		player._apply_work(node, node.work(sim), hit)
		_expect_cue(work_cue, visual + " first accepted work")
		check(node.drive_progress == 1 and node.remaining_units == 4 and sim.export_json() == before, visual + " contact grants no early material")
		if visual in ["tree", "resinheart_tree", "corkbark_deadfall"]:
			var impacts := get_tree().get_nodes_in_group("gathering_impacts")
			var flake := impacts.back().get_child(0) as MeshInstance3D
			check((flake.mesh as BoxMesh).size.z > (flake.mesh as BoxMesh).size.x * 2, visual + " uses timber splinters")
		_clear_voices()
		player._apply_work(node, node.work(sim))
		_expect_cue(work_cue, visual + " second accepted work")
		_clear_voices()
		player._apply_work(node, node.work(sim))
		_expect_cue(release_cue, visual + " final release")
		check(node.remaining_units == 0 and sim.export_json() == before, visual + " depleted source has not deposited its physical drop")
		var drops: Array = WorldDrops.capture(self).pickups
		check(drops.size() == 1 and int(drops[0].amount) == 4, visual + " release retains exact physical ownership")
		var voice: AudioStreamPlayer3D = _voices()[0]
		node.free()
		check(is_instance_valid(voice) and voice.get_parent() == self, visual + " release survives source removal")
	for visual in ["iron_vein", "copper_vein", "tin_vein", "silver_vein", "ember_vein", "slate_seam", "shellstone_seam"]:
		check(InteractionSound.resource_cue(visual, false) == InteractionSound.resource_cue("boulder", false), visual + " has mineral contact")
	check(InteractionSound.resource_cue("reed_bed", false) != InteractionSound.resource_cue("tree", false), "fibre rustle differs from timber contact")
	check(InteractionSound.resource_cue("clay_bank", false) != InteractionSound.resource_cue("boulder", false), "earth contact differs from mineral contact")

func _chip(amount: int) -> Pickup:
	var chip: Pickup = Pickup.scatter(self, Vector3(20, 0, 20), {"wood": amount}, 719, 0)[0]
	chip.set_physics_process(false)
	return chip

func _collection() -> void:
	_reset()
	var cap := sim.carry_cap("wood")
	sim.add_material("wood", cap)
	var chip := _chip(9)
	chip._absorb(player)
	check(_voices().is_empty() and chip.amount == 9, "a full pack cannot play a collection success")
	check(sim.consume_material("wood", 3), "make three units of real capacity")
	chip._absorb(player)
	_expect_cue("collect", "partial native haul")
	check(chip.amount == 6 and not chip._claimed and sim.material_count("wood") == cap, "partial collection owns three in pack and six on ground")
	var first_id: int = _voices()[0].get_instance_id()
	chip._absorb(player)
	check(_voices().size() == 1 and _voices()[0].get_instance_id() == first_id, "same-frame full-pack retry emits no extra cue")
	_clear_voices()
	check(sim.consume_material("wood", 6), "make room for the entire remainder")
	chip._absorb(player)
	check(chip._claimed and chip.amount == 0 and sim.material_count("wood") == cap, "rapid second native haul still grants exact remainder")
	check(_voices().is_empty(), "nearby successful chips coalesce inside the collection cooldown")
	chip._absorb(player)
	check(_voices().is_empty() and sim.material_count("wood") == cap, "terminal duplicate absorption cannot sound or award again")

func _silent_restore() -> void:
	_reset()
	var rare := _resource("thrumroot", "thrumroot", 4)
	player._apply_work(rare, rare.work(sim))
	var saved := manager.capture(player)
	_clear_voices()
	for progress in [0.0, .75, .25, 1.0, .5]:
		StrangeResourceArt.update(rare, progress)
		rare.set_highlight(true)
		rare.set_highlight(false)
	check(_voices().is_empty() and rare.get_children().filter(func(node): return node is AudioStreamPlayer3D).is_empty(), "visual progress and hovering never replay work")
	# Increase the saved pose from the live zero pose: this used to emit rare work.
	rare.drive_progress = 0
	rare._refresh_wedge_look()
	for attempt in 3:
		check(manager.apply(player, JSON.parse_string(JSON.stringify(saved))), "apply exact partial rare checkpoint " + str(attempt))
		check(_voices().is_empty() and rare.drive_progress == 1 and rare.remaining_units == 4, "restored partial work is exact and silent")
	check(not JSON.stringify(saved).contains("interaction_sounds"), "presentation voices are absent from the save payload")

func _cue_labels() -> Array:
	var rows := []
	for pair in [["tree", "Timber"], ["reed_bed", "Woven fibre"], ["clay_bank", "Earth"], ["boulder", "Mineral"]]:
		for released in [false, true]:
			rows.append({"cue": InteractionSound.resource_cue(pair[0], released), "label": pair[1] + (" release" if released else " work")})
	for rare in RARES:
		for released in [false, true]:
			rows.append({"cue": InteractionSound.resource_cue(rare, released), "label": rare.capitalize() + (" release" if released else " work")})
	rows.append({"cue": "collect", "label": "Physical material collection"})
	for station in ["field", "workbench", "mason_yard", "forge_basic"]:
		rows.append({"cue": InteractionSound.craft_cue(station), "label": station.replace("_", " ").capitalize() + " completion"})
	return rows

func _pcm_and_rng() -> void:
	_clear_voices()
	var rules := sim.export_json()
	var ambush_state := player.ambush_rng.state
	seed(49721)
	var expected := randi()
	seed(49721)
	var hashes := {}
	var cold_us := []
	for row in _cue_labels():
		var started := Time.get_ticks_usec()
		var clip := InteractionSound.clip(row.cue, 0)
		cold_us.append(Time.get_ticks_usec() - started)
		check(clip != null and clip.format == AudioStreamWAV.FORMAT_16_BITS and not clip.stereo, row.label + " is a mono PCM clip")
		if clip == null: continue
		check(clip.data.size() > 0 and clip.get_length() < 1.5, row.label + " is a finite short cue")
		check(InteractionSound.clip(row.cue, 0) == clip, row.label + " reuses its cached stream")
		var fingerprint := hash(clip.data)
		check(not hashes.has(fingerprint), row.label + " has distinct PCM from other event identities")
		hashes[fingerprint] = true
		var peak := 0
		for i in range(0, clip.data.size(), 2): peak = maxi(peak, absi(clip.data.decode_s16(i)))
		check(peak > 0 and peak < 32767, row.label + " has nonzero content without clipped PCM samples")
		InteractionSound.play(self, Vector3.ZERO, row.cue)
	check(randi() == expected, "clip construction and cosmetic variation leave global game RNG untouched")
	check(player.ambush_rng.state == ambush_state and sim.export_json() == rules, "audio leaves ambush and native rule state untouched")
	var reference := InteractionSound.clip("release_thrumroot", 2).data.duplicate()
	_clear_voices()
	InteractionSound._clips.clear()
	check(InteractionSound.clip("release_thrumroot", 2).data == reference, "fresh synthesis reproduces exact PCM for the same cue and variant")
	for row in _cue_labels():
		for variant in 3:
			var clip := InteractionSound.clip(row.cue, variant)
			check(clip == InteractionSound.clip(row.cue, variant + 3000) and clip == InteractionSound.clip(row.cue, variant - 3000), row.label + " wraps variant cache keys")
	var cached := InteractionSound._clips.size()
	for unknown in ["", "invalid", "work_unknown", "release_unknown", "craft_unknown"]:
		check(InteractionSound.clip(unknown) == null and InteractionSound.play(self, Vector3.ZERO, unknown) == null, "unknown cue is quiet: " + unknown)
	check(cached <= 69 and InteractionSound._clips.size() == cached, "full three-variant palette and invalid inputs keep cache at most 69 clips")
	evidence.clip_first_access_us = cold_us
	evidence.distinct_event_pcm_count = hashes.size()
	evidence.cached_clips = cached

func _voice_lifetime() -> void:
	_clear_voices()
	for i in 40:
		InteractionSound.play(self, Vector3(float(i), 0, 0), InteractionSound.resource_cue("tree", false))
	check(_voices().size() <= 8, "rapid input is bounded to eight live interaction voices")
	check(_voices().size() > 0, "headless Dummy audio still exercises real player nodes")
	var count := _voices().size()
	var oldest: AudioStreamPlayer3D = _voices()[0]
	var other_root := Node3D.new()
	get_tree().root.add_child(other_root)
	var sibling_voice := InteractionSound.play(other_root, Vector3.ZERO, "release_stone")
	check(sibling_voice != null and sibling_voice.get_parent() == other_root and oldest.is_queued_for_deletion(), "a ninth voice under another world root retires the oldest shared voice")
	check(get_tree().get_nodes_in_group("interaction_sounds").size() <= 8, "nested and sibling sound owners share the same total voice budget")
	var look: Resource = InteractionSound.LOOK
	var loudest := maxf(maxf(look.work_gain_db, look.release_gain_db), maxf(look.craft_gain_db, look.collect_gain_db))
	check(8 * float(look.pcm_peak_fraction) * db_to_linear(loudest) < 1.0, "eight worst-case coherent interaction peaks retain mixer headroom before other game audio")
	await get_tree().create_timer(2.0).timeout
	check(_voices().is_empty(), "real playback/timed cleanup retires all short voices")
	check(other_root.get_child_count() == 0, "sibling-owned voice also expires")
	other_root.free()
	evidence.burst_peak_voices = count

func _export_listening() -> void:
	var out := ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(out)
	var reel := AudioStreamWAV.new()
	reel.format = AudioStreamWAV.FORMAT_16_BITS
	reel.stereo = false
	var bytes := PackedByteArray()
	var silence := PackedByteArray()
	var manifest := []
	for row in _cue_labels():
		var clip := InteractionSound.clip(row.cue, 0)
		reel.mix_rate = clip.mix_rate
		silence.resize(int(.45 * clip.mix_rate) * 2)
		silence.fill(0)
		var filename: String = row.cue + ".wav"
		check(clip.save_to_wav(out.path_join(filename)) == OK, "export " + row.label)
		manifest.append({"label": row.label, "cue": row.cue, "file": filename, "start_seconds": float(bytes.size()) / (clip.mix_rate * 2), "duration_seconds": clip.get_length()})
		bytes.append_array(clip.data)
		bytes.append_array(silence)
	reel.data = bytes
	check(reel.save_to_wav(out.path_join("interaction-listening-reel.wav")) == OK, "export labeled listening reel")
	var file := FileAccess.open(out.path_join("listening-manifest.json"), FileAccess.WRITE)
	if check(file != null, "write listening manifest"):
		file.store_string(JSON.stringify({"scope": "Procedural source PCM, variant zero. Spatial attenuation, in-game mix, repetition comfort and human listening acceptance are not certified by this file.", "reel": "interaction-listening-reel.wav", "clips": manifest}, "  "))

func _clear_review_feedback() -> void:
	# These are separate capture setups, not a continuation of the haul fixture.
	# Keep the real HUD and interaction path, with no stale event overlay.
	player.hud._pickup_totals.clear()
	player.hud._pickup_timer = 0.0
	player.hud._pickup_label.text = ""
	player.hud._notice_timer = 0.0
	player.hud._notice.text = ""
	for impact in get_tree().get_nodes_in_group("gathering_impacts"):
		if is_ancestor_of(impact): impact.free()
	_clear_voices()

func _capture_work() -> void:
	_reset()
	_clear_review_feedback()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("667985")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a7b4bf")
	environment.environment.ambient_light_energy = .65
	add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-48, -25, 0)
	light.shadow_enabled = true
	add_child(light)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	ground.mesh = plane
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("727457")
	ground.material_override = material
	add_child(ground)
	player.global_position = Vector3(0, 1.1, 0)
	player.rotation = Vector3.ZERO
	var node := _resource("tree", "wood", 6)
	for frame in 3: await get_tree().physics_frame
	check(player.aim_probe().target == node, "render review aims through the normal camera at the tree")
	player.interact()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(OUTPUT).path_join("accepted-timber-work.png")
	check(get_viewport().get_texture().get_image().save_png(path) == OK, "capture accepted timber work, hands, fragments and HUD")
	node.free()
	_clear_review_feedback()
	node = _resource("thrumroot", "thrumroot", 4)
	player.spring_arm.rotation.x = atan2(node.global_position.y + .45 - player.camera.global_position.y, 3.0)
	for frame in 3: await get_tree().physics_frame
	# Aim probe records whether this authored core is the actual visible target.
	check(player.aim_probe().target == node, "render review aims through the normal camera at Thrumroot")
	player.interact()
	await RenderingServer.frame_post_draw
	path = ProjectSettings.globalize_path(OUTPUT).path_join("accepted-thrumroot-work.png")
	check(get_viewport().get_texture().get_image().save_png(path) == OK, "capture accepted rare work and partial core pose")
