extends Node
## Whole native mesh payloads are compared with the preserved DLL, including
## exact vertex/normal/colour ordering and source-cell picking after edits.
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL WORLD MESH: ", label)

func _ready() -> void:
	var output := ProjectSettings.globalize_path("user://mesh-equivalence.json")
	var baseline := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--mesh-output="): output = arg.trim_prefix("--mesh-output=")
		if arg.begins_with("--mesh-baseline="): baseline = arg.trim_prefix("--mesh-baseline=")
	var expected := {}
	if not baseline.is_empty():
		var source = JSON.parse_string(FileAccess.get_file_as_string(baseline))
		check(source is Dictionary and source.get("failures", 1) == 0, "preserved payload report is valid")
		if source is Dictionary: expected = source.get("payloads", {})
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var payloads := {}
	var timings := {}
	var palette: Dictionary = preload("res://art/frontier_look.tres").top_colours
	for profile in ["legacy_v1", "frontier_v2", "frontier_v3", "frontier_v4", "frontier_v5", "frontier_v6"]:
		check(sim.set_world_profile(profile), "select " + profile)
		var map: Dictionary = sim.world_map(1)
		var origins: Array[Vector2i] = [Vector2i.ZERO,
			Vector2i(int(map.spawn_x) / 16 * 16, int(map.spawn_z) / 16 * 16),
			Vector2i(int(map.gate_x) / 16 * 16, int(map.gate_z) / 16 * 16),
			Vector2i(int(map.width) - 16, int(map.height) - 16)]
		if not map.get("regions", []).is_empty():
			var region: Dictionary = map.regions[0]
			origins.append(Vector2i(int(region.x) / 16 * 16, int(region.z) / 16 * 16))
		var samples: Array[float] = []
		for origin in origins:
			var x := mini(origin.x + 15, int(map.width) - 1)
			var z := mini(origin.y + 15, int(map.height) - 1)
			var y := int(map.heights[z * int(map.width) + x]) - 1
			var edits := PackedInt32Array([x, y, z, x + 1, y, z, x, y - 1, z, -1, 0, -1])
			for variant in 3:
				var removed := PackedInt32Array() if variant == 0 else edits
				var began := Time.get_ticks_usec()
				var chunk: Dictionary = sim.world_mesh_chunk(1, 16, origin.x, origin.y, removed, variant != 1, palette if variant != 1 else {})
				samples.append((Time.get_ticks_usec() - began) / 1000.0)
				var id := "%s:%d:%d:%d" % [profile, origin.x, origin.y, variant]
				var digest := HashingContext.new()
				digest.start(HashingContext.HASH_SHA256)
				digest.update(var_to_bytes(chunk))
				payloads[id] = digest.finish().hex_encode()
				check(chunk.x == origin.x and chunk.z == origin.y, "payload origin " + id)
				if variant != 1:
					check(chunk.source_cells.size() * 3 == chunk.faces.size(), "source-cell ownership " + id)
				if not baseline.is_empty(): check(expected.get(id, "") == payloads[id], "complete preserved payload " + id)
			timings[profile] = samples
	if not baseline.is_empty(): check(expected.size() == payloads.size(), "same complete payload case set")
	var file := FileAccess.open(output, FileAccess.WRITE)
	check(file != null, "write isolated payload report")
	if file != null:
		file.store_string(JSON.stringify({"checks": checks, "failures": failures, "payloads": payloads, "preparation_ms": timings}, "\t"))
		file.close()
	print("WORLD_MESH_EQUIVALENCE %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
