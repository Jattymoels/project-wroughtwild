extends "res://tests/environment_ambience.gd"
## Demonstrate the pre-INT-08A prompt gap without adding production behaviour.
func _run() -> void:
	var key := InputEventKey.new()
	key.physical_keycode = KEY_J
	InputMap.action_erase_events("interact")
	InputMap.action_add_event("interact", key)
	player.hud.toggle_help()
	var comfort: Variant = player.hud.get("comfort")
	if comfort != null: comfort.show_page("Help")
	for frame in 12: await get_tree().process_frame
	check(player.hud._help_body.text.contains("J interact"), "help reflects the actual J interaction binding")
	check(player.get("preferences") != null, "runtime camera and binding preferences exist")
	print("CONTROLS_BASELINE %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)
