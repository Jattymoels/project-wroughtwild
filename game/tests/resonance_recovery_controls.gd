extends "res://tests/second_resonance_terrain.gd"
## Actual input and movement, with no traversal helper restoring physics.
const RECOVERY_SAVE := "user://lf5-r1-controls.json"

func done() -> void:
	print("LF5_R1_CONTROLS ",checks," checks, ",failures," failures; injected host faults, ordinary load and actual input movement")
	get_tree().quit(1 if failures else 0)

func input_distance() -> float:
	var start := player.global_position
	Input.action_press("move_back")
	for i in 30: await get_tree().physics_frame
	Input.action_release("move_back")
	return Vector2(player.global_position.x-start.x,player.global_position.z-start.z).length()

func freeze_drops() -> void:
	for pickup in get_tree().get_nodes_in_group("pickups"): pickup.set_physics_process(false)

func _run_terrain() -> void:
	var manager := SaveManager.new()
	var restart := "--lf5-r1-restart" in OS.get_cmdline_user_args()
	if not restart: load_frozen("lf5b-published-clear",manager)
	player.class_panel.close_panel()
	player.work_panel.close_panel()
	# The inherited scene initially disables its fixture. Enable exactly once,
	# before the tested lifecycle; every later recovery must be production code.
	player.set_physics_process(true)
	player.rotation.y = 0.0
	if not restart:
		var baseline := await input_distance()
		check(baseline>1.0,"ordinary movement works before failure")
		print("LF5_R1_BASELINE moved_m=",baseline)
		var before := manager.capture(player)
		reject_publication = 2
		var result := ResonanceEvent.publish(player,RECOVERY_SAVE)
		check(not result.ok && reject_publication==0 && _sim().export_json()==before.sim && int(_sim().era().index)==2,"both host failures keep prior native ownership and era")
		check(not player.is_physics_processing() && await input_distance()<0.001,"publication recovery stops actual movement")
		check(not player.load_game("user://absent-lf5-r1/save.json") && not player.is_physics_processing(),"missing ordinary load retains recovery stop")
		reject_publication = 1
		check(not player.load_game(RECOVERY_SAVE) && reject_publication==0 && not player.is_physics_processing(),"physical ordinary load failure retains recovery stop")
		check(await input_distance()<0.001,"failed loads cannot resume movement")
		# Repeated requests must not overwrite the initially working controller.
		player.stop_for_world_recovery()
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(RECOVERY_SAVE))
	check(JSON.parse_string(disk.sim).economy.resonance_second.phase=="applied","complete applied checkpoint remains recoverable on disk")
	check(player.load_game(RECOVERY_SAVE),"ordinary load installs the complete saved world")
	freeze_drops()
	check(player.is_physics_processing(),"complete restore releases only recovery's stop")
	check(JSON.parse_string(_sim().export_json())==JSON.parse_string(disk.sim) && int(_sim().era().index)==3,"both event ledgers, milestones, rewards and all native ownership match disk")
	ownership(disk,manager.capture(player))
	var moved := await input_distance()
	check(moved>1.0,"ordinary input moves after successful recovery without a physics helper")
	print("LF5_R1_RECOVERED restart=",restart," moved_m=",moved)
	check(player.load_game(RECOVERY_SAVE),"repeated normal load succeeds")
	freeze_drops()
	check(await input_distance()>1.0,"normal load retains a working controller")
	if not restart:
		player.set_physics_process(false) # Deliberate unrelated presentation stop.
		player.stop_for_world_recovery()
		check(player.load_game(RECOVERY_SAVE) && not player.is_physics_processing(),"recovery preserves a previously disabled controller")
		check(player.load_game(RECOVERY_SAVE) && not player.is_physics_processing(),"ordinary load without recovery preserves unrelated stop")
	done()
