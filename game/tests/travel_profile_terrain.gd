extends Terrain
## Test-only observation of the unchanged production callback. No scheduling,
## resource ownership or mesh construction is replaced for this measurement.
var travel_sample: Dictionary = {}

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
	var began := Time.get_ticks_usec()
	super._process(delta)
	var elapsed := (Time.get_ticks_usec()-began)/1000.0
	travel_sample = {"frame": Engine.get_process_frames(), "terrain_callback_ms": elapsed,
		"stage_before": stage, "terrain_refresh": terrain_refresh,
		"resource_refresh": resource_refresh, "active_before": before_active,
		"active_after": resource_stream.active.size(), "resource_pending_before": before_pending,
		"resource_pending_after": resource_stream._pending.size(),
		"last_phase_ms": chunk_stream.phase_build_ms.back() if not chunk_stream.phase_build_ms.is_empty() else 0.0,
		"collision": last_collision_profile.duplicate() if stage == "collision_refresh" else {},
		"scenery_pending": int(get_parent().get_node("CataclysmSites").get("_pending_traces").size()) if chunk_stream.has_method("has_scenery_work") and get_parent().has_node("CataclysmSites") else 0}
