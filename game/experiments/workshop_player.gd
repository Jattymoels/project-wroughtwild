extends "res://scripts/player.gd"
## This lab cannot read or overwrite the ordinary game's save through F5/F9.
const LAB_SAVE := "user://codex_workshop_study.json"
func _study_save() -> String:
	if OS.get_cmdline_user_args().has("--workshop-smoke"):
		return ProjectSettings.globalize_path("res://../build/codex-aesthetic/roof-workshop/interactive-save.json")
	return LAB_SAVE
func save_game(_path: String = LAB_SAVE) -> bool:
	return super.save_game(_study_save())
func load_game(_path: String = LAB_SAVE) -> bool:
	var ok := super.load_game(_study_save())
	if ok:
		world_root().call("_dress")
	return ok
