extends "res://experiments/aesthetic_comparison.gd"
## Codex continuation: two fresh-world profiles, identical cameras and materials.

static func prepare_tuning() -> String:
	var source: String = load("res://scripts/sim.gd").get_tuning_directory()
	var destination := ProjectSettings.globalize_path("res://../build/codex-aesthetic/landform-tuning")
	DirAccess.make_dir_recursive_absolute(destination)
	for file in DirAccess.get_files_at(source):
		if file.ends_with(".json"):
			assert(DirAccess.copy_absolute(source.path_join(file), destination.path_join(file)) == OK)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(destination.path_join("worldgen.json")))
	var profile: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://experiments/landform_profile.json"))
	data["map"].merge(profile["map"], true)
	var file := FileAccess.open(destination.path_join("worldgen.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()
	return destination

func _ready() -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var baseline: Dictionary = sim.world_map(1)
	var candidate := WroughtwildSim.new()
	assert(candidate.load_tuning(prepare_tuning()))
	var altered: Dictionary = candidate.world_map(1)
	var use_candidate := OS.get_cmdline_user_args().has("--landform-look")
	if use_candidate:
		assert(sim.load_tuning(prepare_tuning()))
	super._ready()
	variant = "landform-candidate" if use_candidate else "landform-control"
	if OS.get_cmdline_user_args().has("--faceted-look"):
		variant = "landform-faceted"
	if OS.get_cmdline_user_args().has("--crafted-look"):
		variant = "landform-crafted"
	if world.terrain.weathered:
		variant = "landform-weathered"
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/" + variant)
	DirAccess.make_dir_recursive_absolute(output)
	# Fixed seed-1 anchors taken from the first review. Raise both variants'
	# camera to the higher local surface so neither camera is underground.
	views.clear()
	var anchors := {
		"spawn": [Vector2i(160, 160), Vector2i(160, 145), 2.4],
		"overlook": [Vector2i(172, 182), Vector2i(145, 125), 18.0],
		"forest": [Vector2i(197, 256), Vector2i(197, 242), 5.0],
		"fen": [Vector2i(78, 146), Vector2i(78, 132), 5.0],
		"ember_wastes": [Vector2i(132, 200), Vector2i(132, 186), 5.0]}
	for key in anchors:
		var eye: Vector2i = anchors[key][0]
		var target: Vector2i = anchors[key][1]
		var eye_y := maxf(_height(baseline, eye), _height(altered, eye)) + float(anchors[key][2])
		var target_y := (_height(baseline, target) + _height(altered, target)) * 0.5 + 1.4
		views.append({"name": key, "eye": Vector3(eye.x + 0.5, eye_y, eye.y + 0.5),
			"target": Vector3(target.x + 0.5, target_y, target.y + 0.5)})
	_set_view()

static func _height(map: Dictionary, cell: Vector2i) -> float:
	return float(map["heights"][cell.y * int(map["width"]) + cell.x])
