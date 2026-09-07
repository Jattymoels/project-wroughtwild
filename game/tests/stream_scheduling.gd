extends "res://tests/trace_surface_cache.gd"
## Exercise real generated geometry, finite resources and interruption. The
## inherited cache oracle includes excavation and paid-footprint suppression.

func _exercise() -> void:
	await super._exercise()
	if trace == null or trace.mesh == null: return
	_add_nearby_tile()
	if history.traces.size() < 2: return
	var stream := terrain.chunk_stream
	stream._finish_job()
	stream._pending.clear()
	var records := JSON.stringify(terrain.resource_stream.capture())
	_queue_network()
	var pending := history._pending_traces.size()
	check(pending == history.traces.size(), "all actual test tiles are eligible for queued regrounding")
	for i in 32: _queue_network()
	check(history._pending_traces.size() == pending, "repeated chunk arrivals coalesce to one pending entry per existing tile")
	for id in history._pending_traces:
		check(id is int and history._pending_traces[id] is int, "pending scenery stores only bounded integer identities")
	var point: Vector3 = trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX][0]
	var origin := Vector2i(floori(point.x/16)*16, floori(point.z/16)*16)
	stream._retire(origin)
	stream._pending = [origin]
	stream._step_job()
	check(not stream._job.is_empty(), "real native preparation can coexist with cosmetic arrivals")
	var phase_before := int(stream._job.phase)
	stream._timer = 1000
	stream.tick(0, stream._focus)
	check(history._pending_traces.size() == pending-1, "one normal frame processes one complete queued tile")
	check(int(stream._job.phase) == phase_before, "cosmetic work consumes the terrain slot instead of stacking on it")
	while history.step_trace_refresh(): pass
	_matches_forced("queued work after supporting terrain retirement")
	stream.tick(0, stream._focus)
	check(int(stream._job.phase) > phase_before, "terrain preparation resumes after the finite cosmetic queue drains")
	_queue_network()
	terrain.ensure_area(point, 16)
	check(history._pending_traces.is_empty() and stream._job.is_empty(), "synchronous area preparation finishes geometry and drains cosmetic work")
	_matches_forced("synchronous area completion")
	_queue_network()
	_building_refresh()
	check(history._pending_traces.is_empty(), "building actions reconcile and cancel queued cosmetic work immediately")
	_queue_network()
	await _dig_refresh(point)
	check(history._pending_traces.is_empty(), "excavation and restoration leave no obsolete cosmetic work")
	check(JSON.stringify(terrain.resource_stream.capture()) == records, "queued geometry and explicit refreshes preserve every finite source")
	await _cancel_prepared_collision()
	_resource_budget()
	_queue_network()
	var obsolete: WeakRef = weakref(history)
	remove_child(history)
	history.free()
	history = CataclysmSites.build(self, terrain)
	check(obsolete.get_ref() == null and history._pending_traces.is_empty(), "replacing world scenery frees the old queue and starts with current complete output")
	check(not stream.has_scenery_work(), "old-world queued identities cannot execute in the replacement scenery")
	await _paced_coverage()

func _paced_coverage() -> void:
	# Simulated frame cadence checks scheduling throughput, not lower-spec
	# frame performance. Query actual collision periodically after physics sync.
	var route: PackedVector3Array = terrain.map.regions[0].approach
	var distances: Array[float] = [0.0]
	for i in range(1, route.size()): distances.append(distances.back()+route[i-1].distance_to(route[i]))
	var metres := minf(300.0, distances.back())
	for fps in [30, 60]:
		terrain.ensure_area(route[0], 128)
		terrain.resource_stream.focus(route[0], true)
		terrain.chunk_stream._timer = 0
		var cursor := 0
		var max_pending := 0
		for frame in ceili(metres/5.0*fps):
			var travelled := minf(metres, float(frame+1)*5.0/fps)
			while cursor+1 < distances.size()-1 and distances[cursor+1] < travelled: cursor += 1
			var at := route[cursor].lerp(route[cursor+1], clampf((travelled-distances[cursor])/maxf(.001,distances[cursor+1]-distances[cursor]),0,1))
			_advance_streams(1.0/fps, at)
			max_pending = maxi(max_pending, history._pending_traces.size())
			at.y = terrain.height_at(floori(at.x), floori(at.z))
			var supported := is_finite(terrain.rendered_height(at.x,at.z,at.y))
			check(supported, "ground is ready before the walking position at %d simulated fps, frame %d" % [fps,frame])
			if not supported: break
			if frame % (fps*2) == 0:
				await get_tree().physics_frame
				await get_tree().physics_frame
				_physical_surface(at, "%d fps staged route" % fps)
		terrain.chunk_stream._finish_job()
		check(history._pending_traces.is_empty(), "paced route can finish without stranded cosmetic work")
		_bounded("after %d fps paced route" % fps)
		print("STREAM_SCHEDULING_ROUTE fps=",fps," metres=",metres," max_pending_tiles=",max_pending)

func _advance_streams(delta: float, at: Vector3) -> void:
	if terrain.has_method("_tick_streaming"):
		terrain.call("_tick_streaming", delta, at)
	else:
		terrain.chunk_stream.tick(delta, at)
		terrain.resource_stream.tick(delta, at)

func _queue_network() -> void:
	history.refresh_area(0, 0, maxi(int(terrain.map.width), int(terrain.map.height)), true)

func _add_nearby_tile() -> void:
	var centre: Vector3 = trace.get_meta("record").points[0]
	for line: Dictionary in terrain.map.leylines:
		for record: Dictionary in history._trace_records(line):
			if record.id == trace.get_meta("record").id or not record.exposure.has(2): continue
			if record.points[0].distance_to(centre) > 48: continue
			terrain.ensure_area(record.points[0], 32)
			var second := MeshInstance3D.new()
			second.set_meta("record", record)
			history.add_child(second)
			history._trace(second)
			if second.mesh == null:
				second.free()
				continue
			history.traces.append(second)
			check(true, "second nearby generated tile supplies a real multi-tile queue")
			return
	check(false, "second nearby generated tile must be available")

func _cancel_prepared_collision() -> void:
	var stream := terrain.chunk_stream
	stream._finish_job()
	var spawn := terrain.surface_position(int(terrain.map.spawn_x), int(terrain.map.spawn_z))
	var origin := Vector2i(floori(spawn.x/16)*16, floori(spawn.z/16)*16)
	stream._retire(origin)
	stream._pending = [origin]
	stream._step_job()
	for i in 16:
		if is_instance_valid(stream._job.get("node")) and stream._job.node.has_meta("prepared_collision"): break
		if stream._job.is_empty(): break
		stream._step_job()
	check(not stream._job.is_empty() and is_instance_valid(stream._job.get("node")), "collision preparation can be interrupted before publication")
	if stream._job.is_empty() or not is_instance_valid(stream._job.get("node")): return
	var partial: Node3D = stream._job.node
	check(partial.has_meta("prepared_collision"), "unpublished chunk owns the completed triangle shape")
	if not partial.has_meta("prepared_collision"): return
	var shape: WeakRef = weakref(partial.get_meta("prepared_collision"))
	var chunk: WeakRef = weakref(partial)
	var sampler: WeakRef = weakref(partial.get_meta("surface_sampler"))
	check(not partial.visible and partial.find_children("*", "CollisionObject3D", true, false).is_empty(), "prepared shape creates no visible geometry or active physics body")
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(_floor_hit(spawn).is_empty(), "completed unpublished shape cannot catch a physical ray")
	stream.cancel_chunk(origin)
	check(shape.get_ref() == null and chunk.get_ref() == null and sampler.get_ref() == null, "cancellation releases the prepared shape, partial scene and sampler together")
	terrain.ensure_area(spawn, 16)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_physical_surface(spawn, "replacement after prepared-shape cancellation")

func _resource_budget() -> void:
	var resources := terrain.resource_stream
	var spawn := terrain.surface_position(int(terrain.map.spawn_x), int(terrain.map.spawn_z))
	var saved := resources.capture()
	resources.restore(saved)
	resources.focus(spawn)
	resources._timer = 1000
	check(resources._pending.size() > 12, "real nearby resources exceed one creation batch")
	var first := resources._pending[0]
	var budget := resources.resource_build_budget_ms
	# Zero makes the elapsed-time boundary deterministic without mocking the
	# engine clock. A whole real node must finish before that boundary is read.
	resources.resource_build_budget_ms = 0
	resources.tick(0, spawn)
	check(resources.active.size() == 1 and resources.active.has(first), "time budget stops a batch after one complete nearest resource")
	var node: ResourceNode = resources.active[first]
	node.remaining_units -= 1
	node.cracked = true
	var partial := resources.capture()
	var expected := JSON.stringify(partial)
	resources.restore(partial)
	resources.focus(spawn, true)
	check(resources._pending.is_empty() and resources.active.size() > 12, "explicit immediate restoration finishes resources despite the ordinary travel budget")
	check(JSON.stringify(resources.capture()) == expected, "budgeting and immediate restore preserve exact partially worked source records")
	node = resources.active[first]
	node.remaining_units = 0
	resources.capture()
	var depleted := resources.capture()
	resources.restore(depleted)
	resources.focus(spawn)
	for i in 16: resources.tick(0, spawn)
	check(not resources.records.has(first) and not resources.active.has(first), "later budgeted arrivals cannot replenish a depleted source")
	resources.resource_build_budget_ms = budget
	resources.restore(saved)
	resources.focus(spawn, true)

func _finish() -> void:
	if is_instance_valid(history): history.free()
	if is_instance_valid(terrain): terrain.free()
	print("STREAM_SCHEDULING %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
