extends "res://tests/wide_terrain_stream.gd"
## Real V6 terrain and one native fissure tile. Forced rebuilding remains the
## output oracle; the cache may only omit work when sampled inputs are equal.
var history: CataclysmSites
var trace: MeshInstance3D

func _exercise() -> void:
	terrain.chunk_stream._finish_job()
	terrain.chunk_stream._pending.clear()
	history = CataclysmSites.new()
	history.name = "CataclysmSites"
	history.terrain = terrain
	add_child(history)
	check(history.has_method("_trace_surface_ids"), "current history exposes bounded surface identity computation")
	if not history.has_method("_trace_surface_ids"): return
	for line: Dictionary in terrain.map.leylines:
		for record: Dictionary in history._trace_records(line):
			var exposed: PackedByteArray = record.exposure
			if not exposed.has(2): continue
			var points: PackedVector3Array = record.points
			if points.size() < 2: continue
			var middle := points[0].lerp(points[1], .5)
			terrain.ensure_area(middle, 32)
			trace = MeshInstance3D.new()
			trace.set_meta("record", record)
			history.add_child(trace)
			history._trace(trace)
			if trace.mesh != null: break
			trace.free()
			trace = null
		if trace != null: break
	check(trace != null and trace.mesh != null, "actual generated exposed tile has complete inspectable geometry")
	if trace == null or trace.mesh == null: return
	history.traces.append(trace)
	var first: Vector3 = trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0]
	var origin := Vector2i(floori(first.x/16)*16, floori(first.z/16)*16)
	var source_records := terrain.resource_stream.capture()
	_unchanged_refresh(origin)
	_relevant_return(origin)
	await _dig_refresh(first)
	_building_refresh()
	check(terrain.resource_stream.capture() == source_records, "cache, excavation and building refresh do not harvest or refill sources")
	var ids: Variant = trace.get_meta("sampled_chunk_ids")
	check(ids is PackedInt64Array, "cache stores integer identities without node or sampler references")
	check(int(trace.get_meta("sampled_seed")) == terrain.seed_value() and String(trace.get_meta("sampled_profile")) == profile, "cache belongs to this world's full identity")

func _snapshot() -> String:
	var parts: Array = []
	if trace.mesh != null:
		for surface in trace.mesh.get_surface_count(): parts.append(trace.mesh.surface_get_arrays(surface))
	for key in ["xz_bounds", "fragment_count", "fissure_branch_count", "fissure_triangle_count", "fissure_exposure_only"]:
		parts.append(trace.get_meta(key, null))
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(var_to_bytes(parts))
	return digest.finish().hex_encode()

func _mesh_id() -> int:
	return trace.mesh.get_instance_id() if trace.mesh != null else 0

func _matches_forced(label: String) -> void:
	var expected := _snapshot()
	history._trace(trace, StrangeSites._building_index(terrain))
	check(_snapshot() == expected, label + ": cached/event result equals complete forced geometry and metadata")

func _unchanged_refresh(origin: Vector2i) -> void:
	var before := _snapshot()
	var mesh_id := _mesh_id()
	var ids: PackedInt64Array = history.call("_trace_surface_ids", trace)
	history.refresh_area(origin.x, origin.y, 16)
	check(_mesh_id() == mesh_id and _snapshot() == before, "unchanged overlapping refresh reuses the same completed mesh")
	# A broad 5m refresh rectangle may overlap a tile whose narrower sampled
	# footprint does not include the newly published chunk. Exercise such a
	# native tile when available, otherwise an explicit unrelated arrival.
	var outside := Vector2i((int(ids[3])+1)*16, int(ids[2])*16)
	var overlap := false
	var bounds: Rect2 = trace.get_meta("xz_bounds")
	for z in range(int(ids[2])-1, int(ids[4])+2):
		for x in range(int(ids[1])-1, int(ids[3])+2):
			if x >= int(ids[1]) and x <= int(ids[3]) and z >= int(ids[2]) and z <= int(ids[4]): continue
			if Rect2(Vector2(x*16-5, z*16-5), Vector2.ONE*26).intersects(bounds):
				outside = Vector2i(x*16,z*16)
				overlap = true
				break
		if overlap: break
	check(outside.x >= 0 and outside.y >= 0 and outside.x < int(terrain.map.width) and outside.y < int(terrain.map.height), "unrelated arrival lies in the finite native world")
	if outside.x < 0 or outside.y < 0 or outside.x >= int(terrain.map.width) or outside.y >= int(terrain.map.height): return
	terrain.chunk_stream._retire(outside)
	history._trace(trace)
	mesh_id = _mesh_id()
	before = _snapshot()
	terrain.chunk_stream._build(outside)
	history.call("_trace", trace, StrangeSites._building_index(terrain), true)
	check(_mesh_id() == mesh_id and _snapshot() == before, "real out-of-footprint chunk arrival cannot rebuild or change the fissure")
	print("TRACE_CACHE_UNRELATED overlap_refresh_margin=", overlap, " chunk=", outside)
	_matches_forced("unrelated arrival")

func _relevant_return(origin: Vector2i) -> void:
	var key := "%d_%d" % [origin.x,origin.y]
	check(terrain.chunks.has(key), "trace begins over a real published exact chunk")
	if not terrain.chunks.has(key): return
	var pristine := _snapshot()
	var old_chunk: WeakRef = weakref(terrain.chunks[key])
	var old_sampler: WeakRef = weakref(terrain.chunks[key].get_meta("surface_sampler"))
	var ids: PackedInt64Array = history.call("_trace_surface_ids", trace)
	terrain.chunk_stream._retire(origin)
	check(old_chunk.get_ref() == null and old_sampler.get_ref() == null, "surface identity cache cannot retain retired geometry or sampler")
	check(history.call("_trace_surface_ids", trace) != ids, "relevant retirement changes the sampled identity")
	history.refresh_area(origin.x, origin.y, 16)
	_matches_forced("relevant retirement")
	var retired_ids: PackedInt64Array = trace.get_meta("sampled_chunk_ids")
	terrain.chunk_stream._build(origin)
	check(trace.get_meta("sampled_chunk_ids") != retired_ids, "real publication refresh records the returned exact chunk")
	check(_snapshot() == pristine, "return restores the exact prior fissure geometry and branch layout")
	_matches_forced("relevant arrival")

func _dig_refresh(at: Vector3) -> void:
	var x := floori(at.x)
	var z := floori(at.z)
	var y := terrain.height_at(x,z)-1
	var ids: PackedInt64Array = trace.get_meta("sampled_chunk_ids")
	terrain.cracked[Vector3i(x,y,z)] = true
	check(terrain.break_block(x,y,z) != "", "normal excavation replaces a sampled terrain chunk")
	await get_tree().process_frame
	check(trace.get_meta("sampled_chunk_ids") != ids, "deferred excavation refresh captures the new sampled geometry")
	_matches_forced("excavation")
	terrain.apply_broken_blocks([])
	await get_tree().process_frame
	_matches_forced("saved pristine terrain restoration")

func _building_refresh() -> void:
	check(trace.mesh != null, "restored tile supports a native building footprint probe")
	if trace.mesh == null: return
	var at: Vector3 = trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0]
	var grid := sim.lattice_registry_grid()
	var element := {"kind":"volume", "axis":0, "cell":Vector3i(floori(at.x/grid),floori(at.y/grid),floori(at.z/grid))}
	var pristine := _snapshot()
	var ids: PackedInt64Array = trace.get_meta("sampled_chunk_ids")
	# Native registry footprint only; paid first-person placement is covered
	# by the home/building regression scenes, not claimed by this probe.
	check(sim.structure_place(element, "cube", "wood", 0), "real native structure footprint can overlap the sampled fissure")
	if sim.structure_piece_count() == 0: return
	history.refresh_buildings()
	check(trace.get_meta("sampled_chunk_ids") == ids, "building suppression does not require a terrain identity change")
	check(_snapshot() != pristine, "forced building refresh suppresses the overlapping fissure")
	_matches_forced("building suppression")
	check(sim.structure_remove(element), "native footprint can be removed")
	history.refresh_buildings()
	check(_snapshot() == pristine, "building removal forces exact fissure restoration despite unchanged terrain IDs")

func _finish() -> void:
	if is_instance_valid(history): history.free()
	if is_instance_valid(terrain): terrain.free()
	print("TRACE_SURFACE_CACHE %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
