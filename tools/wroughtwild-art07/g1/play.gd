extends "res://scripts/sandpit.gd"
## A copied current game and isolated paid checkpoint; normal controls and saves.
func _ready() -> void:
	world_profile="living_frontier_wave3"
	world_seed=77
	_build_world(world_seed)
	player.class_panel.choose("warden")
	var manager:=SaveManager.new()
	var path: String="user://g1-play.json" if FileAccess.file_exists("user://g1-play.json") else "res://g1/paid-home.json"
	if FileAccess.file_exists(path):
		assert(manager.read(path,player),manager.last_error)
	player.set_meta("g1_save_path","user://g1-play.json")
	if "--smoke" in OS.get_cmdline_user_args():
		for frame in 120: await get_tree().physics_frame
		assert(player.placement.enclosure_at(player.position).enclosed)
		assert(_sim().structure_piece_count()>50)
		print("G1_PACKAGED_LAUNCH_OK")
		get_tree().quit()
