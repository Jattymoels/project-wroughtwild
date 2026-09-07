extends "res://tests/world_performance_review.gd"
## Common INT-07D frame attribution, identical on both preserved/current code.
## Bounded in-memory rows are written only after the timed route.
var _process_began := 0
var _draw_began := 0
var _draw_ended := 0
var _draw_sample: Dictionary = {}
var _physics_began := 0
var _physics_first := 0
var _physics_ended := 0
var _physics_count := 0
var _physics_callbacks_usec := 0
var _settled_count := 600 # Review-only length; extended captures look for rare pauses.

class PhysicsEnd extends Node:
	var observer: Node
	func _physics_process(_delta: float) -> void:
		observer._measure_physics_end()

func _build_world(seed_value: int) -> void:
	super._build_world(seed_value)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--review-settle-frames="):
			_settled_count = clampi(int(arg.trim_prefix("--review-settle-frames=")), 60, 7200)
		if arg.begins_with("--review-fps="):
			Engine.max_fps = clampi(int(arg.trim_prefix("--review-fps=")), 15, 240)
		if arg.begins_with("--review-resolution=") and DisplayServer.get_name() != "headless":
			var size := arg.trim_prefix("--review-resolution=").split("x")
			if size.size() == 2:
				DisplayServer.window_set_size(Vector2i(clampi(int(size[0]), 640, 3840), clampi(int(size[1]), 360, 2160)))
	report["hardware"] = {"gpu": RenderingServer.get_video_adapter_name(),
		"vendor": RenderingServer.get_video_adapter_vendor(), "api": RenderingServer.get_video_adapter_api_version(),
		"cpu": OS.get_processor_name(), "logical_processors": OS.get_processor_count(),
		"engine": Engine.get_version_info().string, "engine_arguments": OS.get_cmdline_args(),
		"low_processor_mode": OS.low_processor_usage_mode, "settled_frames": _settled_count}
	if OS.get_cmdline_user_args().has("--review-no-hover"):
		player.hud.set_process(false)
		report["diagnostic_variant"] = "Hidden HUD processing disabled only to isolate hover material updates; excluded from matched normal-performance claims."
	get_tree().process_frame.connect(_measure_process_start)
	get_tree().physics_frame.connect(_measure_physics_start)
	var physics_end := PhysicsEnd.new()
	physics_end.observer = self
	physics_end.process_mode = Node.PROCESS_MODE_ALWAYS
	physics_end.process_physics_priority = 1000000
	add_child(physics_end)
	RenderingServer.frame_pre_draw.connect(_measure_draw_start)
	RenderingServer.frame_post_draw.connect(_measure_draw_end)

func _measure_process_start() -> void:
	var now := Time.get_ticks_usec()
	# The preceding post-draw -> process-signal interval includes the engine's
	# frame wait and unobserved engine/physics work. It is not a GPU-only timer.
	if _draw_ended > 0:
		_draw_sample["post_draw_to_process_ms"] = (now-_draw_ended)/1000.0
		_draw_sample["process_to_process_ms"] = (now-_process_began)/1000.0
		_draw_sample["physics_ticks"] = _physics_count
		_draw_sample["physics_callbacks_ms"] = _physics_callbacks_usec/1000.0
		_draw_sample["post_draw_to_first_physics_ms"] = (_physics_first-_draw_ended)/1000.0 if _physics_count > 0 else -1.0
		_draw_sample["last_physics_to_process_ms"] = (now-_physics_ended)/1000.0 if _physics_count > 0 else -1.0
	_physics_count = 0
	_physics_callbacks_usec = 0
	_process_began = now

func _measure_physics_start() -> void:
	_physics_began = Time.get_ticks_usec()
	if _physics_count == 0: _physics_first = _physics_began
	_physics_count += 1

func _measure_physics_end() -> void:
	_physics_ended = Time.get_ticks_usec()
	_physics_callbacks_usec += _physics_ended-_physics_began

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
	_draw_sample["draw_observation_ms"] = (_draw_ended-_draw_began)/1000.0

func _frame_row(frame_ms: float) -> Dictionary:
	var row: Dictionary = terrain.get("travel_sample").duplicate(true)
	row.merge(_draw_sample)
	row["frame_ms"] = frame_ms
	row["process_ms"] = Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
	row["physics_ms"] = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
	row["draw_calls"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	var hovered: Node = player.hud._hovered
	row["hovered"] = String(hovered.name) if is_instance_valid(hovered) else ""
	return row

func _sample_frames(_count: int) -> Dictionary:
	# Retain warmup separately too: the old aggregate window could hide a pause
	# there. Timed windows do no disk writes or captures, and have a fixed bound.
	var rows: Array[Dictionary] = []
	var values: Array[float] = []
	for i in _settled_count+90:
		var began := Time.get_ticks_usec()
		await get_tree().process_frame
		var frame_ms := (Time.get_ticks_usec()-began)/1000.0
		var row := _frame_row(frame_ms)
		row["window"] = "warmup" if i < 90 else "settled"
		rows.append(row)
		if i >= 90: values.append(frame_ms)
	var file := FileAccess.open(output.path_join("settled-frames.json"), FileAccess.WRITE)
	check(file != null, "bounded settled-frame attribution can be written")
	if file != null:
		file.store_string(JSON.stringify(rows))
		file.close()
	var result := _stats(values)
	result.draw_calls = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	result.primitives = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	return result

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
			var row := _frame_row(frame_ms)
			row["metres"] = travelled
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
