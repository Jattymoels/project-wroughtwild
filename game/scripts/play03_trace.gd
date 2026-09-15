extends Node
## Opt-in local ring recorder. Reads presentation state; never captures saves.
## No input bindings, quality changes, uploads or timed file writes.
const MAX_FRAMES := 7200 # Last ~60 seconds at 120fps; bounded at any play duration.
var world: Node3D
var terrain: Terrain
var player: WroughtwildPlayer
var destination := ""
var active := false
var rows: Array[Dictionary] = []
var cursor := 0
var overwritten := 0
var output_path := ""
var _interval := {}
var _last_usec := 0
var _started_usec := 0
var _physics_began := 0
var _process_began := 0
var _draw_began := 0
var _actor_next := 0
var _actor_count := 0
var _metadata := {}
var _end: Node

class PhysicsEnd extends Node:
	var observer: Node
	func _physics_process(_delta: float) -> void:
		if observer.active: observer.add_time("physics_callbacks_ms", observer._physics_began)

static func install(host: Node3D, args: PackedStringArray) -> Node:
	var directory := ""
	for arg in args:
		if arg.begins_with("--play03-trace="): directory = arg.trim_prefix("--play03-trace=")
	if directory.is_empty(): return null
	if host.has_node("Play03Trace"): return host.get_node("Play03Trace")
	# The prototype's retained diagnostic output belongs on D:, outside saves.
	directory = directory.replace("\\", "/").simplify_path()
	if not directory.to_lower().begins_with("d:/"):
		push_warning("PLAY03 trace needs an absolute D: output directory; recording stays off.")
		return null
	var trace: Node = load("res://scripts/play03_trace.gd").new()
	trace.name = "Play03Trace"
	trace.world = host
	trace.terrain = host.get_node("Terrain")
	trace.player = host.get_node("Player")
	trace.destination = directory
	host.add_child(trace)
	return trace

func _ready() -> void:
	if DirAccess.make_dir_recursive_absolute(destination) != OK:
		push_warning("PLAY03 trace cannot create its output directory; recording stays off.")
		return
	var stamp := Time.get_datetime_string_from_system().replace(":", "-")
	output_path = destination.path_join("play03-%s-%d-%d.json" % [stamp, OS.get_process_id(), Time.get_ticks_usec()])
	_metadata = {"format":1,"max_frames":MAX_FRAMES,"engine":Engine.get_version_info().string,
		"cpu":OS.get_processor_name(),"gpu":RenderingServer.get_video_adapter_name(),
		"rendering_method":RenderingServer.get_current_rendering_method(),
		"scope":"Consecutive process-frame intervals, including preceding idle/draw and following physics callbacks. Native surface_y is a reference, not a collision query. Engine monitors are sampled, draw_wall_ms is NOT GPU execution time. No save/inventory payloads. Normal controls and quality are unchanged."}
	terrain.play03_trace = self
	player.play03_trace = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_end = PhysicsEnd.new()
	_end.observer = self
	_end.process_physics_priority = 1000000
	add_child(_end)
	get_tree().process_frame.connect(_frame)
	get_tree().physics_frame.connect(_physics_start)
	RenderingServer.frame_pre_draw.connect(_draw_start)
	RenderingServer.frame_post_draw.connect(_draw_end)
	_started_usec = Time.get_ticks_usec()
	_last_usec = _started_usec
	_process_began = _started_usec
	active = true
	print("PLAY03_TRACE recording the last %d frames; close the game normally to write %s" % [MAX_FRAMES,output_path])

func add_time(key: String, began: int) -> void:
	_interval[key] = float(_interval.get(key,0.0)) + (Time.get_ticks_usec()-began)/1000.0

func note_stream(chunk_ms: float, resource_ms: float, stage: String) -> void:
	_interval["chunk_tick_ms"] = float(_interval.get("chunk_tick_ms",0.0)) + chunk_ms
	_interval["resource_tick_ms"] = float(_interval.get("resource_tick_ms",0.0)) + resource_ms
	_interval["stage_before"] = stage

func note_area(began: int, point: Vector3, radius: float, built: int) -> void:
	add_time("ensure_area_ms",began)
	_interval["ensure_area_calls"] = int(_interval.get("ensure_area_calls",0))+1
	_interval["ensure_area_built"] = int(_interval.get("ensure_area_built",0))+built
	_interval["last_area"] = [point.x,point.y,point.z,radius]

func note_resource(began: int, visual: String, streamed: bool) -> void:
	var ms := (Time.get_ticks_usec()-began)/1000.0
	_interval["resource_arrivals"] = int(_interval.get("resource_arrivals",0))+1
	if ms >= float(_interval.get("resource_arrival_max_ms",0.0)):
		_interval["resource_arrival_max_ms"] = ms
		_interval["resource_arrival_visual"] = visual
		_interval["resource_arrival_streamed"] = streamed

func _physics_start() -> void:
	_physics_began = Time.get_ticks_usec()
	_interval["physics_ticks"] = int(_interval.get("physics_ticks",0))+1

func _draw_start() -> void:
	_draw_began = Time.get_ticks_usec()
	_interval["process_to_draw_ms"] = (_draw_began-_process_began)/1000.0

func _draw_end() -> void:
	_interval["draw_wall_ms"] = (Time.get_ticks_usec()-_draw_began)/1000.0
	_interval["render_setup_cpu_ms"] = RenderingServer.get_frame_setup_time_cpu()

func _frame() -> void:
	var now := Time.get_ticks_usec()
	var row := _interval
	_interval = {}
	row["frame"] = Engine.get_process_frames()
	row["elapsed_s"] = (now-_started_usec)/1000000.0
	row["frame_ms"] = (now-_last_usec)/1000.0
	row["position"] = [player.position.x,player.position.y,player.position.z]
	row["velocity"] = [player.velocity.x,player.velocity.y,player.velocity.z]
	row["floor"] = player.is_on_floor()
	row["player_physics_enabled"] = player.is_physics_processing()
	row["trial"] = player.trial.active()
	row["process_monitor_ms"] = Performance.get_monitor(Performance.TIME_PROCESS)*1000.0
	row["physics_monitor_ms"] = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0
	row["fps_cap"] = Engine.max_fps
	row["window_size"] = [DisplayServer.window_get_size().x,DisplayServer.window_get_size().y]
	row["vsync"] = DisplayServer.window_get_vsync_mode()
	row["draw_calls"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME)
	row["primitives"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME)
	row["pipeline_surface"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SURFACE)
	row["pipeline_mesh"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_MESH)
	row["pipeline_specialization"] = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_PIPELINE_COMPILATIONS_SPECIALIZATION)
	if now >= _actor_next:
		_actor_count = get_tree().get_nodes_in_group("enemies").size()
		_actor_next = now+1000000
	row["enemies_sampled_1hz"] = _actor_count
	if not terrain.map.is_empty():
		var at := terrain.to_local(player.global_position)
		row["seed"] = terrain.seed_value()
		row["profile"] = terrain.world_profile()
		row["surface_y"] = terrain.height_at(floori(at.x),floori(at.z))
		row["below_surface_m"] = float(row.surface_y)-at.y
		row["edits"] = terrain.broken.size()
	if terrain.chunk_stream != null:
		var stream := terrain.chunk_stream
		row["chunks"] = terrain.chunks.size()
		row["chunks_built_total"] = stream.chunks_built_total
		row["chunks_retired_total"] = stream.chunks_retired_total
		row["safety_refills_total"] = stream.safety_refills_total
		row["terrain_pending"] = stream._pending.size()
		row["phase_after"] = int(stream._job.get("phase",-1))
	if terrain.resource_stream != null:
		row["resource_active"] = terrain.resource_stream.active.size()
		row["resource_pending"] = terrain.resource_stream._pending.size()
		row["projection_pending"] = terrain.resource_stream._projection_pending.size()
	_append(row)
	row["observer_frame_ms"] = (Time.get_ticks_usec()-now)/1000.0
	_last_usec = now
	_process_began = now

func _append(row: Dictionary) -> void:
	if rows.size() < MAX_FRAMES: rows.append(row)
	else:
		rows[cursor] = row
		cursor = (cursor+1)%MAX_FRAMES
		overwritten += 1

func _ordered_rows() -> Array[Dictionary]:
	var ordered: Array[Dictionary] = []
	for i in rows.size(): ordered.append(rows[(cursor+i)%rows.size()])
	return ordered

func stop(reason := "manual") -> bool:
	if not active: return false
	# Disconnect before JSON/disk work, so flush cost cannot enter the trace.
	_frame()
	active = false
	if is_instance_valid(terrain) and terrain.play03_trace == self: terrain.play03_trace = null
	if is_instance_valid(player) and player.play03_trace == self: player.play03_trace = null
	get_tree().process_frame.disconnect(_frame)
	get_tree().physics_frame.disconnect(_physics_start)
	RenderingServer.frame_pre_draw.disconnect(_draw_start)
	RenderingServer.frame_post_draw.disconnect(_draw_end)
	_end.set_physics_process(false)
	var ordered := _ordered_rows()
	var times: Array[float] = []
	var overhead: Array[float] = []
	for row in ordered:
		times.append(float(row.frame_ms))
		overhead.append(float(row.observer_frame_ms))
	times.sort()
	overhead.sort()
	_metadata["stop_reason"] = reason
	_metadata["overwritten_frames"] = overwritten
	_metadata["retained_frames"] = ordered.size()
	_metadata["frame_p95_ms"] = times[mini(times.size()-1,floori(times.size()*0.95))]
	_metadata["frame_max_ms"] = times.back()
	_metadata["observer_frame_max_ms"] = overhead.back()
	_metadata["observer_scope"] = "observer_frame_ms measures row collection including the 1Hz actor count; excludes small timing-hook overhead, storage allocations between callbacks, and post-stop JSON/file writing. This is an instrumented session, not an overhead-free benchmark."
	var file := FileAccess.open(output_path,FileAccess.WRITE)
	if file == null:
		push_warning("PLAY03 trace could not write its output file. No saved-game data was changed.")
		return false
	file.store_string(JSON.stringify({"metadata":_metadata,"frames":ordered}))
	file.close()
	print("PLAY03_TRACE saved ",output_path)
	return true

func _exit_tree() -> void:
	if active: stop("scene_exit")
