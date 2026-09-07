extends "res://tests/wide_terrain_stream.gd"
## Actual generated resources and terrain, using the normal shared callback.
## stream_scheduling separately checks sustained 30/60 fps route coverage.
var history: CataclysmSites

func _exercise() -> void:
	history = CataclysmSites.build(self, terrain)
	var stream := terrain.chunk_stream
	var resources := terrain.resource_stream
	var spawn := terrain.surface_position(int(terrain.map.spawn_x),int(terrain.map.spawn_z))
	terrain.ensure_area(spawn,128)
	resources.focus(spawn,true)
	stream._finish_job()
	var source_state := JSON.stringify(resources.capture())
	var at := spawn+Vector3(2,0,0)
	var phases_before := stream.phase_build_ms.duplicate()
	var active_before := resources.active.size()
	stream._timer = 0
	resources._timer = 0
	terrain._tick_streaming(1.0/60,at)
	check(stream._focus == at, "coincident timers scan terrain around the new walking position first")
	check(resources._focus == spawn and resources._timer < 0, "deferred resource scan retains its due timer and previous focus")
	check(stream._job.is_empty() and stream.phase_build_ms == phases_before, "terrain focus does not also begin native preparation")
	check(resources.active.size() == active_before, "terrain focus does not also change resource scene ownership")
	# Remove one ordinary live presentation without harvesting. The next real
	# bucket scan must rediscover it, but cannot recreate it on that scan frame.
	var id: String = resources.active.keys()[0]
	var old: ResourceNode = resources.active[id]
	old.get_parent().remove_child(old)
	old.free()
	active_before = resources.active.size()
	terrain._tick_streaming(1.0/60,at)
	check(resources._focus == at and resources._timer > 0, "stationary next frame performs the deferred resource scan")
	check(resources._pending.has(id) and not resources.active.has(id), "resource scan queues an actual unloaded source without creating it")
	check(resources.active.size() == active_before, "a resource scan does not also create arrivals")
	check(stream._job.is_empty() and stream.phase_build_ms == phases_before, "resource scan does not also begin terrain or leyline preparation")
	var pending_before := resources._pending.size()
	terrain._tick_streaming(1.0/60,at)
	check(not stream._job.is_empty(), "following frame begins the nearest native terrain job")
	check(resources._pending.size() < pending_before and resources.active.size() > active_before, "following frame materialises complete nearby resource scenes")
	check(JSON.stringify(resources.capture()) == source_state, "scan separation and recreation preserve every finite source record")
	var built_before := stream.chunks_built_total
	for frame in 120: terrain._tick_streaming(1.0/60,at)
	check(stream.chunks_built_total > built_before, "repeated stationary refreshes do not starve terrain preparation")
	check(resources.active.has(id), "pending source eventually returns through ordinary budgeted creation")
	check(resources._pending.is_empty(), "stationary resource queue eventually drains")
	_bounded("after shared focus and preparation frames")
	_late_frame_progress(at)
	# A due resource scan must never suppress the synchronous teleport guard.
	var far := terrain.surface_position(32,32)
	resources._timer = 0
	stream._timer = 0
	terrain._tick_streaming(1.0/60,far)
	check(stream._focus == far and stream._job.is_empty(), "teleport receives complete synchronous terrain even with another scan due")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_physical_surface(far, "teleport while resource scan waits")
	check(resources._timer < 0, "teleport does not discard the resource refresh debt")
	# Restoration and explicit visits still request an immediate complete set.
	resources.restore(resources.capture())
	resources.focus(far,true)
	check(resources._pending.is_empty() and not resources.active.is_empty(), "explicit restoration bypasses ordinary focus/creation separation")
	check(JSON.stringify(resources.capture()) == source_state, "teleport and explicit restoration keep the same finite source state")
	stream._finish_job()
	check(not stream.has_scenery_work(), "explicit completion leaves no stranded cosmetic arrivals")

func _late_frame_progress(at: Vector3) -> void:
	var stream := terrain.chunk_stream
	var resources := terrain.resource_stream
	stream._finish_job()
	resources.restore(resources.capture())
	var phases := stream.phase_build_ms.duplicate()
	check(not stream._pending.is_empty(), "late-frame case has real remaining terrain to prepare")
	# Repeated overdue timers model refresh debt after slow frames. Nearby
	# movement keeps both scans useful; neither may monopolise every tick.
	for frame in 24:
		stream._timer = 0
		resources._timer = 0
		terrain._tick_streaming(1.0/30,at+Vector3(2 if frame%2 == 0 else -2,0,0))
	check(stream.phase_build_ms != phases, "continuously overdue scans still allow terrain preparation")
	check(not resources.active.is_empty(), "continuously overdue scans still materialise finite resources")

func _finish() -> void:
	if is_instance_valid(history): history.free()
	if is_instance_valid(terrain): terrain.free()
	print("FOCUS_SCHEDULING %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
