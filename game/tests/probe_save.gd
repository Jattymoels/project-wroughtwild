extends SceneTree
## Headless shelter probe over a save file: rebuilds the structure in the
## sim, runs the enclosure fill from the saved player position and says
## whether it is a shelter, and if not, where the fill escaped.
##   godot --headless --path game --script res://tests/probe_save.gd -- <save.json>


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var path: String = args[0] if args.size() > 0 else OS.get_user_data_dir() + "/wroughtwild_save.json"
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		print("no save at ", path)
		quit(1)
		return
	var data: Dictionary = JSON.parse_string(text)
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var seed_value: int = int(data.get("world_seed", 1))
	var player: Dictionary = data.get("player", {})
	var pos_a: Array = player.get("position", [0, 0, 0])
	var at := Vector3(pos_a[0], pos_a[1], pos_a[2])
	print("seed ", seed_value, "  player at ", at, "  keys ", player.keys())

	sim.structure_clear()
	var placed := 0
	var near: Array = []
	for entry in data.get("blocks", []):
		var c: Array = entry["cell"]
		var element := {"kind": String(entry["kind"]), "axis": int(entry["axis"]), "cell": Vector3i(int(c[0]), int(c[1]), int(c[2]))}
		if sim.structure_place(element, StringName(entry["shape"]), StringName(entry["family"]), int(entry.get("rotation_step", 0))):
			placed += 1
		var world_cell := Vector3(c[0], c[1], c[2]) * 0.5
		if world_cell.distance_to(at) < 7.0:
			near.append("%s %s/%s axis %d cell %s" % [entry["shape"], entry["kind"], entry["family"], int(entry["axis"]), str(c)])
	print("pieces placed ", placed, " of ", data.get("blocks", []).size(), "; within 7 m of the player: ", near.size())
	for line in near:
		print("   ", line)

	var removed := PackedInt32Array()
	for v in data.get("broken_blocks", []):
		removed.append(int(v[0])); removed.append(int(v[1])); removed.append(int(v[2]))
	var map: Dictionary = sim.world_map(seed_value)
	var cs: float = map["cell_size"]
	var cx := floori(at.x / cs)
	var cz := floori(at.z / cs)
	var heights: PackedInt32Array = map["heights"]
	print("ground height at the player's column: ", heights[cz * int(map["width"]) + cx], " (player y ", at.y, ")")

	for dy in [0.0, 0.5, 1.0, -0.5]:
		var probe: Dictionary = sim.structure_enclosure(seed_value, removed, at + Vector3(0, dy, 0))
		print("probe y%+.1f: enclosed=%s cells=%d reason=%s leak=%s" % [dy, str(probe.get("enclosed")), int(probe.get("cells", 0)), str(probe.get("reason", "")), str(probe.get("leak", "-"))])
	print("shelter rules: ", sim.shelter())
	quit(0)
