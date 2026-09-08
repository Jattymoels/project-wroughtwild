extends "res://tests/audio_controls.gd"
## INT-08A: real viewport input, independent device data and lifecycle checks.
const WORLD := "res://../build/intensives/controls-world.json"
const PROBE := "res://../build/intensives/controls-probe.cfg"
const COMFORT_OUTPUT := "res://../captures/controls-comfort"
const COMFORT_PREFS := "res://../build/intensives/comfort-preferences.cfg"
var prefs: PlayerPreferences
var ui: ComfortControls

func _ready() -> void:
	# Even a direct headless invocation never writes the owner's device file.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COMFORT_PREFS).get_base_dir())
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	player = preload("res://scenes/player.tscn").instantiate()
	player.preferences.path = COMFORT_PREFS
	add_child(player)
	player.class_panel.open_panel()
	var launch_state := player.inventory.get_sim().export_json()
	var launch_key: InputEvent = PlayerPreferences.event_for(player.preferences.bindings.toggle_help)
	launch_key.pressed = true
	get_viewport().push_input(launch_key)
	check(player.hud.help_visible() and player.class_panel.is_open(), "settings opens above the initial class chooser")
	_key(KEY_ESCAPE)
	check(not player.hud.help_visible() and player.class_panel.is_open() and player.inventory.get_sim().export_json() == launch_state, "closing startup settings preserves the unchosen class")
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	ambience = player.environment_ambience
	ambience.set_process(false)
	sim = player.inventory.get_sim()
	_run.call_deferred()

func _run() -> void:
	prefs = player.preferences
	ui = player.hud.comfort
	if "--comfort-restore-only" in OS.get_cmdline_user_args():
		check(is_equal_approx(float(prefs.values.sensitivity), 1.7) and prefs.values.invert_y and player.camera.fov == 92.0, "restart applies camera preferences before play")
		check(InputPrompts.key("interact") == "J" and InputPrompts.key("toggle_help") == "K", "restart restores actual bindings")
		check(prefs.ambience_muted and is_equal_approx(prefs.ambience_level, .35), "restart retains old-file ambience preferences")
		check(SaveManager.new().read(WORLD, player), "fresh process restores isolated world")
		check(player.camera.fov == 92.0 and InputPrompts.key("interact") == "J", "world load cannot restore obsolete device choices")
		_key(KEY_K)
		check(player.hud.help_visible(), "restarted settings opens using remapped key")
		prefs.reset_defaults()
		_finish_comfort()
		return
	prefs.reset_defaults()
	preload("res://scripts/world_seed_controls.gd").show_identity(player, 77, "frontier_v6")
	_preference_values()
	prefs.load_saved()
	player._apply_preferences()
	var before := sim.export_json()
	var capture_before := SaveManager.new().capture(player)
	check(SaveManager.new().write(WORLD, player), "capture isolated world before settings")
	_key(KEY_H)
	check(player.hud.help_visible(), "physical H opens settings")
	await _layout()
	await _page("Camera")
	var slider: HSlider = ui.controls.sensitivity.widget
	_click(slider.get_global_rect().get_center())
	var selected: float = prefs.values.sensitivity
	check(selected > 1.0 and selected < 2.0, "mouse adjusts sensitivity slider")
	_key(KEY_RIGHT)
	check(is_equal_approx(prefs.values.sensitivity, selected + .1), "focused slider accepts keyboard steps")
	_click(ui.controls.invert_y.widget.get_global_rect().get_center())
	check(prefs.values.invert_y, "mouse toggles vertical inversion")
	_click(ui.controls.landing_motion.widget.get_global_rect().get_center())
	check(not prefs.values.landing_motion, "mouse disables landing dip")
	prefs.set_option("fov", 92.0)
	check(player.camera.fov == 92.0, "field of view applies to live camera")
	player._land_dip = .1
	prefs.set_option("landing_motion", false)
	check(player._land_dip == 0 and is_equal_approx(player.spring_arm.position.y, player.FP_EYE_HEIGHT), "disabling motion clears an in-flight landing dip")
	var hands: FirstPersonHands = player.camera.get_node("FirstPersonHands")
	hands.set_process(false)
	hands.remaining = 0
	hands.impact = 0
	hands.walk_phase = PI / 2.0
	prefs.set_option("hand_sway", false)
	hands.sample(0)
	check(is_equal_approx(hands.hands[0].position.y, hands.LOOK.hand_position.y), "disabled walking sway keeps idle wrist level")
	hands.present_work()
	hands.sample(0)
	check(hands.hands[1].position.y > hands.LOOK.hand_position.y, "motion comfort keeps actual work gestures")
	await _page("Sound")
	_click(ui.controls.master_muted.widget.get_global_rect().get_center())
	check(AudioServer.is_bus_mute(0), "master mute reaches the actual output bus")
	_click(ui.controls.master_muted.widget.get_global_rect().get_center())
	check(not AudioServer.is_bus_mute(0), "unmute retains selected master level")
	prefs.set_option("master_level", .5)
	check(is_equal_approx(AudioServer.get_bus_volume_linear(0), .5), "master level reaches actual audio bus")
	prefs.set_ambience(.35, true)
	check(not AudioServer.is_bus_mute(0) and is_equal_approx(AudioServer.get_bus_volume_linear(0), .5), "ambience mute stays independent of master")
	await _page("Display")
	var vsync: OptionButton = ui.controls.vsync.widget
	vsync.grab_focus()
	_key(KEY_SPACE)
	await _frames()
	_popup_key(vsync.get_popup(), KEY_DOWN)
	_popup_key(vsync.get_popup(), KEY_DOWN)
	await _frames()
	_popup_key(vsync.get_popup(), KEY_ENTER)
	await _frames()
	check(prefs.values.vsync == "off", "actual display menu selects VSync off")
	if DisplayServer.get_name() != "headless":
		check(DisplayServer.window_get_vsync_mode() == DisplayServer.VSYNC_DISABLED, "display backend receives VSync selection")
	for child in ui.get_child(ui.get_child_count()-1).get_children():
		if child is Button and child.text == "Reset all defaults": _click(child.get_global_rect().get_center())
	check(prefs.values.sensitivity == 1.0 and player.camera.fov == 75.0 and prefs.values.landing_motion and prefs.values.hand_sway and not prefs.ambience_muted and AudioServer.get_bus_volume_linear(0) == 1.0, "actual reset button restores camera, motion and sound defaults")
	prefs.set_option("invert_y", true)
	# Window mode is exercised without taking over the owner's monitor. Headless
	# checks validate its preference; a separate bounded rendered probe verifies it.
	await _bindings()
	check(sim.export_json() == before, "all settings and binding UI preserve native ownership and progression")
	check(SaveManager.new().capture(player) == capture_before, "settings do not change world/checkpoint capture")
	_key(KEY_ESCAPE)
	check(not player.hud.help_visible(), "Escape closes remapped settings")
	await _actual_play()
	prefs.set_option("sensitivity", 1.7)
	prefs.set_option("invert_y", true)
	prefs.set_option("fov", 92.0)
	prefs.set_ambience(.35, true)
	check(SaveManager.new().read(WORLD, player), "same process restores world after remapping")
	check(InputPrompts.key("interact") == "J" and player.camera.fov == 92.0 and prefs.ambience_muted, "world restore retains device choices")
	_finish_comfort()

func _preference_values() -> void:
	var probe := PlayerPreferences.new()
	probe.path = PROBE
	if FileAccess.file_exists(PROBE): DirAccess.remove_absolute(PROBE)
	probe.load_saved()
	check(probe.last_error == OK and probe.values.fov == 75.0 and probe.values.sensitivity == 1.0, "missing preferences preserve camera defaults")
	var config := ConfigFile.new()
	config.set_value("audio", "ambience_level", .35)
	config.set_value("audio", "ambience_muted", true)
	config.set_value("unrelated", "keep", 43)
	config.set_value("comfort", "fov", 9000.0)
	config.set_value("comfort", "sensitivity", NAN)
	config.set_value("comfort", "invert_y", "false")
	config.set_value("comfort", "window_mode", "unsupported")
	config.save(PROBE)
	probe.load_saved()
	check(probe.ambience_muted and is_equal_approx(probe.ambience_level, .35), "existing ambience file upgrades without losing owner's choice")
	check(probe.values.fov == 100.0 and probe.values.sensitivity == 1.0 and not probe.values.invert_y and probe.values.window_mode == "current", "invalid comfort data defaults or clamps")
	probe.set_option("fov", 85.0)
	config.load(PROBE)
	check(config.get_value("unrelated", "keep") == 43, "saving new controls retains unrelated preference fields")
	for record in [{"key":KEY_ESCAPE}, {"key":KEY_NONE}, {"key":999999999}, {"mouse":4}, {"key":"J"}, {"key":KEY_J,"mouse":1}]:
		config.set_value("bindings", "interact", record)
		config.save(PROBE)
		probe.load_saved()
		check(not probe.binding_warning.is_empty() and InputPrompts.key("interact") == "E", "malformed binding safely restores complete defaults " + str(record))
	config.set_value("bindings", "interact", {"key":KEY_W})
	config.save(PROBE)
	probe.load_saved()
	check(not probe.binding_warning.is_empty() and InputPrompts.key("move_forward") == "W" and InputPrompts.key("interact") == "E", "conflicting saved map cannot strand a movement action")
	var rebound := InputEventKey.new()
	rebound.physical_keycode = KEY_J
	check(probe.rebind("interact", rebound).is_empty(), "recovered map accepts a valid change")
	probe.load_saved()
	check(probe.binding_warning.is_empty() and InputPrompts.key("interact") == "J", "valid change repairs persisted conflicting map")
	probe.reset_defaults()
	config.load(PROBE)
	check(config.get_value("unrelated", "keep") == 43 and not probe.ambience_muted and probe.values.fov == 75.0, "reset restores known defaults while retaining unrelated fields")
	probe.path = "res://missing-controls-folder/preferences.cfg"
	probe.set_option("fov", 90.0)
	check(probe.last_error != OK and probe.values.fov == 90.0, "write failure preserves live setting and exposes error")

func _bindings() -> void:
	await _page("Bindings")
	await _bind_click("interact")
	_key(KEY_W)
	check(ui.capture_action == "interact" and ui.status.text.contains("Move forward") and InputPrompts.key("interact") == "E", "conflict names existing owner and retains both controls")
	_key(KEY_ESCAPE)
	check(ui.capture_action.is_empty() and player.hud.help_visible(), "Escape cancels capture without closing settings")
	await _bind_click("interact")
	_mouse(MOUSE_BUTTON_WHEEL_UP, Vector2(3,3))
	check(ui.capture_action == "interact" and ui.status.text.contains("wheel"), "wheel input is explained and cannot silently replace a control")
	var chord := InputEventKey.new()
	chord.physical_keycode = KEY_J
	chord.keycode = KEY_J
	chord.shift_pressed = true
	chord.pressed = true
	get_viewport().push_input(chord)
	check(ui.capture_action == "interact" and InputPrompts.key("interact") == "E", "modifier chord refuses without changing the existing action")
	chord.shift_pressed = false
	chord.echo = true
	get_viewport().push_input(chord)
	check(ui.capture_action == "interact", "key repeat does not complete capture")
	_key(KEY_J)
	check(ui.capture_action.is_empty() and InputPrompts.key("interact") == "J", "actual capture remaps interaction")
	await _bind_click("primary_action")
	_click(Vector2(3,3)) # LMB remains its own current binding.
	check(InputPrompts.key("primary_action") == "LMB", "mouse capture accepts current binding without clicking the world")
	await _bind_click("skill_slot_1")
	_mouse(MOUSE_BUTTON_RIGHT, Vector2(3,3))
	check(InputPrompts.key("skill_slot_1") == "RMB", "actual capture supports mouse skill binding")
	await _bind_click("remove_block")
	_key(KEY_Z)
	check(InputPrompts.key("remove_block") == "Z" and InputPrompts.key("blow_horn") == "Z", "contextual removal and horn retain one shared binding")
	await _bind_click("toggle_help")
	_key(KEY_K)
	check(player.hud.help_visible() and InputPrompts.key("toggle_help") == "K", "binding help shortcut does not close the capturing panel")
	await _bind_click("move_forward")
	_key(KEY_UP)
	check(InputPrompts.key("move_forward") == "Up", "movement can use an arrow key while menu navigation stays fixed")
	await _page("Help")
	check(player.hud._help_body.text.contains("J interact") and player.hud._help_body.text.contains("K this help") and player.hud._help_body.text.contains("RMB/2/3/4"), "help resolves all remapped prompts")
	check(_texts(player.hud.action_bar).contains("RMB"), "action bar displays actual mouse binding")
	check(MaterialGuide.describe(sim,"wood").work.contains("with J"), "resource guide follows interaction binding")
	var piece := PlacedBlock.new()
	piece.shape_id = &"door"
	piece.form = "door"
	check(piece.interact_label().begins_with("J "), "door prompt follows interaction binding")
	piece.free()
	prefs.path = "res://missing-controls-folder/preferences.cfg"
	prefs.set_option("fov", 90.0)
	check(ui.status.text.contains("unavailable"), "UI reports failed preference persistence")
	prefs.path = COMFORT_PREFS
	prefs.set_option("fov", 92.0)

func _actual_play() -> void:
	# Verify dispatched controls with real physical-key/mouse events, not direct
	# calls to the action being checked. The authored plane supplies capsule floor.
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30,1,30)
	shape.shape = box
	floor_body.position.y = -1.5
	floor_body.add_child(shape)
	add_child(floor_body)
	player.position = Vector3.ZERO
	await get_tree().physics_frame
	if DisplayServer.get_name() != "headless":
		player.rotation = Vector3.ZERO
		player.spring_arm.rotation = Vector3.ZERO
		prefs.set_option("sensitivity", 2.0)
		var motion := InputEventMouseMotion.new()
		motion.relative = Vector2(10, 10)
		get_viewport().push_input(motion)
		check(is_equal_approx(player.rotation.y, -.06) and is_equal_approx(player.spring_arm.rotation.x, .06), "actual captured mouse applies sensitivity and inverted pitch")
	player.rotation = Vector3.ZERO
	_physical(KEY_W, true)
	player._physics_process(.016)
	check(player.velocity.x == 0 and player.velocity.z == 0, "old forward key no longer moves")
	_physical(KEY_W, false)
	_physical(KEY_UP, true)
	player._physics_process(.016)
	check(player.velocity.z < 0, "remapped physical forward key moves capsule")
	_key(KEY_K)
	player._physics_process(.016)
	check(player.velocity.z == 0, "settings suppresses a held movement key")
	_key(KEY_ESCAPE)
	player._physics_process(.016)
	check(player.velocity.z == 0, "closing settings cannot leak held captured input")
	_physical(KEY_UP, false)
	_key(KEY_B)
	check(player.placement.build_mode_enabled, "build shortcut still dispatches")
	_key(KEY_TAB)
	check(player.build_palette.is_open(), "actual catalogue shortcut opens build panel")
	_key(KEY_K)
	check(player.hud.help_visible(), "settings can cover build catalogue")
	_key(KEY_ESCAPE)
	check(not player.hud.help_visible() and player.build_palette.is_open(), "Escape closes only settings above catalogue")
	_key(KEY_ESCAPE)
	check(not player.build_palette.is_open(), "next Escape returns from catalogue")
	player.placement.set_build_mode_enabled(false)
	var station: StationSite = preload("res://scenes/station_site.tscn").instantiate()
	sim.add_station("workbench")
	station.station_id = &"workbench"
	station.upgrade_station_id = &""
	station.position = Vector3(0, -.9, -2)
	add_child(station)
	player.position = Vector3.ZERO
	player.spring_arm.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	await get_tree().physics_frame
	check(player.aim_probe().get("target") == station, "real camera ray reaches the station before interaction")
	_key(KEY_E)
	check(not player.work_panel.is_open(), "old interaction key no longer opens station")
	_key(KEY_J)
	check(player.work_panel.is_open(), "remapped interaction key opens actual station")
	_key(KEY_K)
	check(player.hud.help_visible() and player.work_panel.is_open(), "settings overlays actual station without losing its panel")
	_key(KEY_ESCAPE)
	check(player.work_panel.is_open(), "closing settings retains actual station panel")
	_key(KEY_ESCAPE)
	check(not player.work_panel.is_open(), "next Escape returns from station")
	station.queue_free()
	var slot_id: StringName = player.combat.bar_skills()[0]
	player.combat.cooldowns[slot_id] = 0.0
	_mouse(MOUSE_BUTTON_RIGHT, Vector2(3,3))
	check(player.combat.cooldown_left(slot_id) > 0.0, "remapped mouse skill performs the actual cast")
	floor_body.queue_free()

func _physical(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		get_viewport().push_input(event)

func _popup_key(popup: PopupMenu, code: Key) -> void:
	# Native popups are separate viewports, just as OS focus dispatches to them.
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		event.window_id = popup.get_window_id()
		Input.parse_input_event(event)
		Input.flush_buffered_events()

func _mouse(button: MouseButton, at: Vector2) -> void:
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = button
		event.pressed = pressed
		event.position = at
		get_viewport().push_input(event)

func _texts(node: Node) -> String:
	var result := String(node.get("text")) if node is Label or node is Button else ""
	for child in node.get_children(): result += "\n" + _texts(child)
	return result

func _bind_click(action: String) -> void:
	var button: Button = ui.binding_buttons[action]
	ui.scroll.ensure_control_visible(button)
	await _frames()
	_click(button.get_global_rect().get_center())
	check(ui.capture_action == action, "actual binding button starts capture " + action)

func _page(title: String) -> void:
	for button in ui.tabs.get_children():
		if button.text == title and not button.disabled: _click(button.get_global_rect().get_center())
	await _frames()
	check(ui.page == title, "actual settings tab opens " + title)

func _frames() -> void:
	for frame in 12: await get_tree().process_frame

func _layout() -> void:
	for resolution in [Vector2i(960,540),Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution
		await _frames()
		for page in ["Camera","Sound","Display","Bindings","Help"]:
			await _page(page)
			var bounds := get_viewport().get_visible_rect()
			check(bounds.encloses(player.hud._help.get_global_rect()), "settings stays within " + str(resolution) + " " + page)
			check(player.hud._help.get_global_rect().encloses(ui.get_child(ui.get_child_count()-1).get_global_rect()), "reset and close stay reachable " + page)
			check(_texts(player.hud._help).contains("World seed: 77 · frontier_v6"), "existing world identity remains visible " + page)
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COMFORT_OUTPUT))
				check(get_viewport().get_texture().get_image().save_png(COMFORT_OUTPUT.path_join("%s-%d.png" % [page.to_lower(),resolution.y])) == OK, "capture " + page)

func _finish_comfort() -> void:
	print("CONTROLS_COMFORT %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
