extends Terrain
## Test-only observation of the unchanged production callback. No scheduling,
## resource ownership or mesh construction is replaced for this measurement.
var travel_sample: Dictionary = {}
var _frame_retire_ms := 0.0
var _frame_retire_count := 0
var _scene_stage := ""

func _build_chunk_phase(chunk_data: Dictionary, cell: float, phase: int, chunk: Node3D = null) -> Node3D:
	_scene_stage = chunk_stream.PREPARATION_STAGES[phase+1] if chunk_stream != null else "synchronous"
	return super._build_chunk_phase(chunk_data,cell,phase,chunk)

func _release_chunk(origin: Vector2i) -> bool:
	var began := Time.get_ticks_usec()
	var released := super._release_chunk(origin)
	_frame_retire_ms += (Time.get_ticks_usec()-began)/1000.0
	if released: _frame_retire_count += 1
	return released

func _process(delta: float) -> void:
	if chunk_stream == null or resource_stream == null:
		super._process(delta)
		return
	var stage := "idle"
	if not chunk_stream._job.is_empty():
		stage = chunk_stream.PREPARATION_STAGES[int(chunk_stream._job.phase)+1]
	elif not chunk_stream._pending.is_empty():
		stage = "payload"
	# The common observer also runs against preserved INT-07D code, where
	# scenery was rebuilt inside collision_refresh rather than its own slot.
	if chunk_stream.has_method("has_scenery_work") and chunk_stream.call("has_scenery_work"):
		stage = "leyline_refresh"
	var before_active: int = resource_stream.active.size()
	var before_pending: int = resource_stream._pending.size()
	var resource_refresh: bool = resource_stream._timer <= delta
	var terrain_refresh: bool = chunk_stream._timer <= delta
	var focus_before: Vector3 = chunk_stream._focus
	var job_was_empty := chunk_stream._job.is_empty()
	var history := get_parent().get_node_or_null("CataclysmSites")
	var has_scenery_queue := history != null and chunk_stream.has_method("has_scenery_work")
	var scenery_before: int = history._pending_traces.size() if has_scenery_queue else 0
	_frame_retire_ms = 0.0
	_frame_retire_count = 0
	_scene_stage = ""
	var began := Time.get_ticks_usec()
	super._process(delta)
	var elapsed := (Time.get_ticks_usec()-began)/1000.0
	var executed := _scene_stage
	if executed.is_empty() and job_was_empty and not chunk_stream._job.is_empty(): executed = "payload"
	if executed.is_empty() and has_scenery_queue and history._pending_traces.size() < scenery_before: executed = "leyline_refresh"
	travel_sample = {"frame": Engine.get_process_frames(), "terrain_callback_ms": elapsed,
		"terrain_focus_ran": focus_before != chunk_stream._focus,
		"resource_focus_ran": resource_refresh and resource_stream._timer > 0.0,
		"executed_stage": executed if not executed.is_empty() else "idle",
		"terrain_retire_ms": _frame_retire_ms, "terrain_retire_count": _frame_retire_count,
		"stage_before": stage, "terrain_refresh": terrain_refresh,
		"resource_refresh": resource_refresh, "active_before": before_active,
		"active_after": resource_stream.active.size(), "resource_pending_before": before_pending,
		"resource_pending_after": resource_stream._pending.size(),
		"last_phase_ms": chunk_stream.phase_build_ms.back() if not chunk_stream.phase_build_ms.is_empty() else 0.0,
		"collision": last_collision_profile.duplicate() if stage == "collision_refresh" else {},
		"scenery_pending": int(get_parent().get_node("CataclysmSites").get("_pending_traces").size()) if chunk_stream.has_method("has_scenery_work") and get_parent().has_node("CataclysmSites") else 0}
