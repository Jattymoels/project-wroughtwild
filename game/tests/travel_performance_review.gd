extends "res://tests/world_performance_review.gd"
## Common INT-07D frame attribution, identical on both preserved/current code.
## Bounded in-memory rows are written only after the timed route.
var _process_began := 0
var _draw_began := 0
var _draw_ended := 0
var _draw_sample: Dictionary = {}

func _build_world(seed_value: int) -> void:
	super._build_world(seed_value)
	if OS.get_cmdline_user_args().has("--review-no-hover"):
		player.hud.set_process(false)
		report["diagnostic_variant"] = "Hidden HUD processing disabled only to isolate hover material updates; excluded from matched normal-performance claims."
	get_tree().process_frame.connect(_measure_process_start)
	RenderingServer.frame_pre_draw.connect(_measure_draw_start)
	RenderingServer.frame_post_draw.connect(_measure_draw_end)

func _measure_process_start() -> void:
	_process_began = Time.get_ticks_usec()
	# The preceding post-draw -> process-signal interval includes the engine's
	# frame wait and unobserved engine/physics work. It is not a GPU-only timer.
	if _draw_ended > 0: _draw_sample["post_draw_to_process_ms"] = (_process_began-_draw_ended)/1000.0

func _measure_draw_start() -> void:
	_draw_began = Time.get_ticks_usec()
	_draw_sample = {"cpu_to_draw_ms": (_draw_began-_process_began)/1000.0}

func _measure_draw_end() -> void:
	_draw_sample["draw_wall_ms"] = (Time.get_ticks_usec()-_draw_began)/1000.0
	_draw_sample["render_setup_ms"] = RenderingServer.get_frame_setup_time_cpu()
	_draw_sample["pipeline_mesh"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_MESH)
	_draw_sample["pipeline_surface"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SURFACE)
	_draw_sample["pipeline_draw"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_DRAW)
	_draw_sample["pipeline_specialization"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SPECIALIZATION)
	_draw_ended = Time.get_ticks_usec()

func _finish_review() -> void:
	if terrain.chunk_stream != null and terrain.resource_stream != null:
		# Stationary CPU probes run after all frame windows and pictures. The
		# real callbacks are called unchanged; no diagnostic overlay edits them.
		var origins: Array[float] = []
		var terrain_focus: Array[float] = []
		var resources: Array[float] = []
		for i in 32:
			var began := Time.get_ticks_usec()
			terrain.chunk_stream._origins(terrain.chunk_stream._focus, 144.0)
			origins.append((Time.get_ticks_usec()-began)/1000.0)
			began = Time.get_ticks_usec()
			terrain.chunk_stream.focus(terrain.chunk_stream._focus)
			terrain_focus.append((Time.get_ticks_usec()-began)/1000.0)
			began = Time.get_ticks_usec()
			terrain.resource_stream.focus(terrain.resource_stream._focus)
			resources.append((Time.get_ticks_usec()-began)/1000.0)
		report["stationary_cpu_probes"] = {"origins": _stats(origins), "terrain_focus": _stats(terrain_focus), "resource_focus": _stats(resources)}
	super._finish_review()

func _paced_walk(route: PackedVector3Array, seconds: float) -> Dictionary:
	check(route.size() > 150, "native route supports a thirty-second outward walk")
	if route.size() < 2: return {}
	await _settle(route[0], 128)
	var distances: Array[float] = [0.0]
	for i in range(1, route.size()): distances.append(distances.back() + route[i-1].distance_to(route[i]))
	var cursor := 0
	var values: Array[float] = []
	var active: Array[float] = []
	var rows: Array[Dictionary] = []
	var began := Time.get_ticks_usec()
	var last := began
	while (Time.get_ticks_usec()-began)/1000000.0 < seconds:
		var travelled := minf(distances.back(), (Time.get_ticks_usec()-began)/1000000.0 * 5.0)
		while cursor+1 < distances.size()-1 and distances[cursor+1] < travelled: cursor += 1
		var weight := clampf((travelled-distances[cursor])/maxf(.001, distances[cursor+1]-distances[cursor]), 0, 1)
		_pose(route[cursor].lerp(route[cursor+1], weight), route[mini(cursor+6, route.size()-1)])
		var preparing := not terrain.chunk_stream._job.is_empty() or not terrain.chunk_stream._pending.is_empty()
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		var frame_ms := (now-last)/1000.0
		values.append(frame_ms)
		if preparing: active.append(frame_ms)
		if rows.size() < 6000:
			var row: Dictionary = terrain.get("travel_sample").duplicate(true)
			row.merge(_draw_sample)
			row["frame_ms"] = frame_ms
			row["metres"] = travelled
			row["process_ms"] = Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
			row["physics_ms"] = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
			row["draw_calls"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
			var hovered: Node = player.hud._hovered
			row["hovered"] = String(hovered.name) if is_instance_valid(hovered) else ""
			rows.append(row)
		last = now
	var file := FileAccess.open(output.path_join("travel-frames.json"), FileAccess.WRITE)
	check(file != null, "bounded frame attribution can be written")
	if file != null:
		file.store_string(JSON.stringify(rows))
		file.close()
	return {"all_frames": _stats(values), "preparing_frames": _stats(active), "metres": seconds*5,
		"chunks": terrain.chunks.size(), "engine_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"streaming_phases": _stats(terrain.chunk_stream.phase_build_ms.duplicate()),
		"synchronous_chunks": _stats(terrain.chunk_stream.chunk_build_ms.duplicate()),
		"chunk_retirements": _stats(terrain.chunk_stream.chunk_retire_ms.duplicate()),
		"attribution": "travel-frames.json: prior completed Terrain._process callback, unchanged production logic. Last-phase time is stale on idle frames. Engine process/physics monitors are sampled values, not individual callback timers. Up to 6000 rows retained in memory, no timed disk writes."}
