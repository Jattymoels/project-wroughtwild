extends "res://tests/wide_terrain_stream.gd"
## Scheduling capacity, not a benchmark of an older CPU. Full native routes,
## full Cataclysm scenery and real collision remain active at sparse ticks.
var history: CataclysmSites
var samples: Array[Dictionary] = []

func _exercise() -> void:
	history = CataclysmSites.build(self, terrain)
	var stock := JSON.stringify(terrain.resource_stream.capture())
	# 15/10 fps expose sustained preparation debt. The irregular case adds a
	# 180 ms pause every 47 ticks at 30 fps, matching the earlier gap's scale.
	var cadences := [{"id":"15fps", "fps":15.0}, {"id":"10fps", "fps":10.0},
		{"id":"irregular30", "fps":30.0, "stall_every":47, "stall_seconds":.18}]
	for cadence in cadences:
		for region: Dictionary in terrain.map.regions:
			await _route(region, cadence)
	check(JSON.stringify(terrain.resource_stream.capture()) == stock, "sparse updates preserve every finite source and partial-work record")

func _route(region: Dictionary, cadence: Dictionary) -> void:
	var path: PackedVector3Array = region.approach
	var distances: Array[float] = [0.0]
	for i in range(1,path.size()): distances.append(distances.back()+path[i-1].distance_to(path[i]))
	var length := minf(300.0, distances.back())
	check(length > 100, "native region approach provides a substantial sparse-tick journey")
	terrain.ensure_area(path[0],128)
	terrain.resource_stream.focus(path[0],true)
	var refills_before := terrain.chunk_stream.safety_refills_total
	var metres := 0.0
	var cursor := 0
	var frame := 0
	var next_ray := 0.0
	var pending_max := 0
	var scenery_max := 0
	var source_pending_max := 0
	while metres < length:
		var delta: float = 1.0/cadence.fps
		if frame > 0 and frame%int(cadence.get("stall_every",2147483647)) == 0:
			delta += float(cadence.get("stall_seconds",0.0))
		metres = minf(length,metres+delta*5.0)
		while cursor+1 < distances.size()-1 and distances[cursor+1] < metres: cursor += 1
		var at := path[cursor].lerp(path[cursor+1],clampf((metres-distances[cursor])/maxf(.001,distances[cursor+1]-distances[cursor]),0,1))
		terrain._tick_streaming(delta,at)
		pending_max = maxi(pending_max,terrain.chunk_stream._pending.size())
		scenery_max = maxi(scenery_max,history._pending_traces.size())
		source_pending_max = maxi(source_pending_max,terrain.resource_stream._pending.size())
		at.y = terrain.height_at(floori(at.x),floori(at.z))
		var supported := is_finite(terrain.rendered_height(at.x,at.z,at.y))
		check(supported, "%s %s has completed walking support at %.2fm" % [cadence.id,region.id,metres])
		if not supported: break
		if metres >= next_ray:
			await get_tree().physics_frame
			await get_tree().physics_frame
			_physical_surface(at, "%s %s %.2fm" % [cadence.id,region.id,metres])
			next_ray = metres+10.0
		frame += 1
	var row := {"cadence":cadence.id,"region":region.id,"metres":metres,
		"expected_metres":length,"frames":frame,"max_pending_terrain":pending_max,
		"max_pending_scenery":scenery_max,"max_pending_resources":source_pending_max,
		"safety_refills":terrain.chunk_stream.safety_refills_total-refills_before}
	samples.append(row)
	print("STREAM_CAPACITY_ROUTE ",JSON.stringify(row))
	terrain.chunk_stream._finish_job()
	check(not terrain.chunk_stream.has_scenery_work(), "explicit arrival can finish all queued scenery after sparse updates")
	_bounded("after "+String(cadence.id)+" "+String(region.id))

func _finish() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-output="):
			var path := arg.trim_prefix("--review-output=")
			var file := FileAccess.open(path.path_join("stream-capacity.json"), FileAccess.WRITE)
			check(file != null,"isolated sparse-cadence report is writable")
			if file != null:
				file.store_string(JSON.stringify({"profile":profile,"seed":1,"checks":checks,"failures":failures,
					"scope":"Simulated sparse/jittered cadence with full generated scenery and periodic physical rays; not measured hardware FPS or owner playtesting.","routes":samples},"\t"))
				file.close()
	if is_instance_valid(history): history.free()
	if is_instance_valid(terrain): terrain.free()
	print("STREAM_CAPACITY %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
