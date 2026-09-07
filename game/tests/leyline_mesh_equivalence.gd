extends "res://tests/wide_terrain_stream.gd"
## Every native fissure tile against a fixed real terrain footprint. Compare
## these geometry/metadata hashes with the preserved implementation, then use
## trace_surface_cache for excavation/building/retirement invalidation.
var rows: Array[Dictionary] = []
var output := ""

func _exercise() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="): output = arg.trim_prefix("--review-output=")
	terrain.chunk_stream._finish_job()
	terrain.chunk_stream._pending.clear()
	var history := CataclysmSites.new()
	history.terrain = terrain
	add_child(history)
	var sources := terrain.resource_stream.capture()
	for line: Dictionary in terrain.map.leylines:
		for record: Dictionary in history._trace_records(line):
			var trace := MeshInstance3D.new()
			trace.set_meta("record",record)
			history.add_child(trace)
			var began := Time.get_ticks_usec()
			history._trace(trace)
			var elapsed := (Time.get_ticks_usec()-began)/1000.0
			var parts: Array = []
			if trace.mesh != null:
				for surface in trace.mesh.get_surface_count(): parts.append(trace.mesh.surface_get_arrays(surface))
			for key in ["xz_bounds","fragment_count","fissure_branch_count","fissure_triangle_count","fissure_exposure_only"]:
				parts.append(trace.get_meta(key,null))
			var digest := HashingContext.new()
			digest.start(HashingContext.HASH_SHA256)
			digest.update(var_to_bytes(parts))
			rows.append({"id":record.id,"sha256":digest.finish().hex_encode(),"triangles":int(trace.get_meta("fissure_triangle_count",0)),"ms":elapsed})
			trace.free()
	check(rows.size()>10,"full native network contributes multiple independent tiles")
	check(terrain.resource_stream.capture()==sources,"mesh assembly does not change finite source state")
	history.free()

func _finish() -> void:
	if not output.is_empty():
		var file := FileAccess.open(output.path_join("leyline-meshes.json"),FileAccess.WRITE)
		if file != null: file.store_string(JSON.stringify({"profile":profile,"rows":rows,"checks":checks,"failures":failures},"\t"))
	if is_instance_valid(terrain): terrain.free()
	print("LEYLINE_MESH_EQUIVALENCE %d checks, %d failures; %d native tiles" % [checks,failures,rows.size()])
	get_tree().quit(0 if failures==0 else 1)
