extends "res://tests/environment_ambience.gd"
## Actual help GUI input and isolated device-preference persistence.
const CHECKPOINT := "res://audio-controls-world.json"

func _run() -> void:
	# INT-08A retains these controls on the explicit Sound page.
	player.hud.comfort.show_page("Sound")
	var prefs := player.audio_preferences
	if "--audio-restore-only" in OS.get_cmdline_user_args():
		check(is_equal_approx(prefs.ambience_level, .35) and prefs.ambience_muted, "fresh process loads saved level and mute before building the HUD")
		check(SaveManager.new().read(CHECKPOINT, player), "fresh process restores independent world checkpoint")
		check(is_equal_approx(prefs.ambience_level, .35) and prefs.ambience_muted, "world restore retains device preferences")
		check(player.hud._ambience_mute.button_pressed and player.hud._ambience_slider.value == 35, "restarted HUD displays the saved selection")
		prefs.set_ambience(1.0, false) # Restore this isolated suite's default for other scenes.
		_finish()
		return
	_preference_contract()
	prefs.set_ambience(1.0, false)
	var snapshot := sim.export_json()
	check(SaveManager.new().write(CHECKPOINT, player), "capture world before changing device settings")
	_action("toggle_help")
	check(player.hud.help_visible(), "H opens sound controls through the viewport input path")
	if DisplayServer.get_name() != "headless": check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "H releases the captured cursor")
	for resolution in [Vector2i(960,540), Vector2i(1280,720), Vector2i(1920,1080)]:
		get_window().size = resolution
		for frame in 12: await get_tree().process_frame
		var bounds := get_viewport().get_visible_rect()
		var panel := player.hud._help.get_global_rect()
		check(bounds.encloses(panel), "help fits viewport " + str(resolution))
		check(panel.encloses(player.hud._ambience_slider.get_global_rect()) and panel.encloses(player.hud._ambience_mute.get_global_rect()), "sound controls stay inside help " + str(resolution))
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
			var directory := ProjectSettings.globalize_path("res://../captures/quiet-ambience")
			DirAccess.make_dir_recursive_absolute(directory)
			check(get_viewport().get_texture().get_image().save_png(directory.path_join("help-%d.png" % resolution.y)) == OK, "capture help " + str(resolution))
	var slider := player.hud._ambience_slider
	_click(slider.get_global_rect().get_center())
	check(prefs.ambience_level >= .45 and prefs.ambience_level <= .55, "mouse click adjusts actual slider")
	var selected := prefs.ambience_level
	_key(KEY_LEFT)
	check(is_equal_approx(prefs.ambience_level, selected - .05), "keyboard changes focused slider by one visible step")
	_small_map()
	_settle()
	check(ambience._target == 0, "enabled ambience can play while controls are open")
	var master := AudioServer.get_bus_index(&"Master")
	var master_before := AudioServer.get_bus_volume_db(master)
	_click(player.hud._ambience_mute.get_global_rect().get_center())
	check(prefs.ambience_muted and prefs.gain() == 0.0 and ambience._target == -1 and not ambience._voices[0].playing, "clicking mute immediately stops current ambience")
	check(is_equal_approx(prefs.ambience_level, selected - .05) and AudioServer.get_bus_volume_db(master) == master_before and not AudioServer.is_bus_mute(master), "mute retains selected level and leaves Master unchanged")
	var work_voice := InteractionSound.play(self, player.position, "work_wood")
	var step_voice := FootstepSound.play(self, player.position, "stone")
	check(work_voice != null and work_voice.playing and is_equal_approx(work_voice.volume_db, InteractionSound.LOOK.work_gain_db), "ambient mute leaves work feedback audible at its own gain")
	check(step_voice != null and step_voice.playing and is_equal_approx(step_voice.volume_db, FootstepSound.LOOK.gain_db), "ambient mute leaves footstep playback at its own gain")
	if work_voice != null: work_voice.free()
	if step_voice != null: step_voice.free()
	_click(player.hud._ambience_mute.get_global_rect().get_center())
	ambience._process(.1)
	check(not prefs.ambience_muted and ambience._target == -1 and ambience._quiet_left >= 12.0, "unmute starts quietly at the retained level")
	prefs.set_ambience(0.0, false)
	_settle()
	check(ambience._target == -1, "zero percent remains silent without checking mute")
	player.set_physics_process(false)
	var build_before := player.placement.build_mode_enabled
	var rotation_before := player.rotation
	for action in ["primary_action", "toggle_build_mode", "save_game", "load_game", "toggle_inventory", "toggle_foundry", "skill_slot_1", "jump"]: _action(action)
	var motion := InputEventMouseMotion.new()
	motion.relative = Vector2(90, 80)
	get_viewport().push_input(motion)
	check(player.rotation == rotation_before and player.placement.build_mode_enabled == build_before, "help blocks world look and building")
	check(not player.inventory_panel.is_open() and not player.foundry_panel.is_open() and not FileAccess.file_exists(SaveManager.DEFAULT_PATH), "help blocks panel and save shortcuts")
	player.test_walk = Vector2(1,1)
	player._physics_process(.016)
	check(player.velocity.x == 0.0 and player.velocity.z == 0.0 and player._jump_buffer_left == 0.0, "help suppresses movement and buffered jumping")
	player.test_walk = Vector2.ZERO
	check(sim.export_json() == snapshot, "all control clicks and blocked actions preserve exact native ownership")
	_action("ui_cancel")
	check(not player.hud.help_visible(), "Escape closes focused sound controls")
	if DisplayServer.get_name() != "headless": check(Input.mouse_mode == Input.MOUSE_MODE_CAPTURED, "closing help returns mouse look")
	player.inventory_panel.open_panel()
	_action("toggle_help")
	for frame in 12: await get_tree().process_frame
	_click(player.inventory_panel._guide_button.get_global_rect().get_center())
	check(not player.inventory_panel.guide.visible, "help prevents clicks reaching an underlying pack button")
	_click(slider.get_global_rect().get_center())
	check(prefs.ambience_level >= .45 and prefs.ambience_level <= .55, "sound control stays usable over another panel")
	_action("toggle_help")
	check(player.inventory_panel.is_open() and not player.hud.help_visible(), "H closes over an existing pack without closing it")
	if DisplayServer.get_name() != "headless": check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "underlying pack retains the cursor")
	_click(player.inventory_panel._guide_button.get_global_rect().get_center())
	check(player.inventory_panel.guide.visible, "closing help returns input to the underlying pack")
	player.inventory_panel.close_panel()
	prefs.path = "res://absent-audio-directory/preferences.cfg"
	prefs.set_ambience(.4, true)
	check(prefs.last_error != OK and player.hud._audio_status.text.contains("unavailable"), "failed preference write is visible and keeps the live choice")
	prefs.path = AudioPreferences.PATH
	prefs.set_ambience(.35, true)
	check(prefs.last_error == OK, "save final restart probe")
	terrain.map.clear() # Restore the authored empty host used by the checkpoint.
	check(SaveManager.new().read(CHECKPOINT, player), "restore world after changing sound")
	check(prefs.ambience_muted and is_equal_approx(prefs.ambience_level, .35), "same-process world restore preserves current sound choice")
	_finish()

func _preference_contract() -> void:
	var prefs := AudioPreferences.new()
	prefs.path = "res://audio-preferences-probe.cfg"
	if FileAccess.file_exists(prefs.path): DirAccess.remove_absolute(prefs.path)
	prefs.load_saved()
	check(prefs.last_error == OK and prefs.gain() == 1.0, "missing preference file keeps the quieter new default")
	var config := ConfigFile.new()
	config.set_value("audio", "ambience_level", 8)
	config.set_value("audio", "ambience_muted", "invalid")
	config.set_value("unrelated", "retained", 17)
	config.save(prefs.path)
	prefs.load_saved()
	check(prefs.gain() == 1.0 and not prefs.ambience_muted, "out-of-range level clamps and invalid mute uses default")
	prefs.set_ambience(-8, true)
	prefs.load_saved()
	check(prefs.gain() == 0.0 and prefs.ambience_level == 0.0 and prefs.ambience_muted, "bounded level and explicit mute persist independently")
	config.load(prefs.path)
	check(config.get_value("unrelated", "retained") == 17, "changing audio preserves other preference fields")
	prefs.set_ambience(NAN, false)
	check(prefs.ambience_muted and prefs.ambience_level == 0.0, "nonfinite changes cannot corrupt saved preference")
	config.set_value("audio", "ambience_level", "invalid")
	config.save(prefs.path)
	prefs.load_saved()
	check(prefs.ambience_level == 1.0 and prefs.ambience_muted, "invalid level retains default without losing valid mute")

func _action(action: String) -> void:
	if not check(InputMap.has_action(action), "fixture uses real action " + action): return
	for pressed in [true, false]:
		var event := InputEventAction.new()
		event.action = action
		event.pressed = pressed
		get_viewport().push_input(event)

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = code
		event.pressed = pressed
		get_viewport().push_input(event)

func _click(at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = pressed
		get_viewport().push_input(event)

func _finish() -> void:
	print("AUDIO_CONTROLS %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
