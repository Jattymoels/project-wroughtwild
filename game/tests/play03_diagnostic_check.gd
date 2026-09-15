extends Sandpit
## Recorder activation/use/exit only; unchanged paid-save/fauna evidence is reused.
const TRACE = preload("res://scripts/play03_trace.gd")
var checks := 0
var failures := 0
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL PLAY03 RECORDER: ",message)

func controls() -> Array:
	return [Input.mouse_mode,Engine.max_fps,player.is_physics_processing(),player.is_processing_unhandled_input(),DisplayServer.window_get_vsync_mode()]

func _ready() -> void:
	var output := OS.get_environment("WROUGHTWILD_PLAY03_OUTPUT")
	check(TRACE.install(self,[]) == null and not has_node("Play03Trace"), "default launch installs no recorder")
	check(terrain.play03_trace == null and player.play03_trace == null, "default production hooks are inactive")
	var before := controls()
	var trace: Node = TRACE.install(self,PackedStringArray(["--play03-trace="+output.path_join("manual")]))
	check(trace != null and trace.active, "explicit launch argument activates recording")
	check(controls() == before, "activation preserves input, physics, frame cap and VSync")
	check(TRACE.install(self,PackedStringArray(["--play03-trace="+output])) == trace, "repeated installation does not duplicate observers")
	_build_world(1)
	player.class_panel.choose("warden")
	for i in 12: await get_tree().physics_frame
	terrain.ensure_area(player.position,16.0)
	for i in 4: await get_tree().process_frame
	check(trace.rows.any(func(row: Dictionary) -> bool: return row.has("ensure_area_ms") and int(row.get("ensure_area_calls",0))>0), "synchronous area work is retained, including initialization")
	check(trace.rows.any(func(row: Dictionary) -> bool: return row.has("chunk_tick_ms") and row.has("resource_tick_ms")), "ordinary streaming timing reaches the recorder")
	check(trace.rows.any(func(row: Dictionary) -> bool: return row.has("player_physics_ms")), "unchanged player physics is observed")
	check(trace.rows.any(func(row: Dictionary) -> bool: return row.has("resource_arrival_max_ms")), "resource construction timing is retained")
	check(not FileAccess.file_exists(trace.output_path), "sampling performs no trace-file writes")
	var owned := _sim().export_json()
	before = controls()
	var saved_path: String = trace.output_path
	check(trace.stop("check_manual_stop"), "stop flushes a readable local trace")
	check(not trace.active and terrain.play03_trace == null and player.play03_trace == null, "stop disconnects production hooks")
	check(controls() == before and owned == _sim().export_json(), "stop preserves controls and exact native state")
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(saved_path))
	check(parsed is Dictionary and parsed.frames.size()>0 and parsed.metadata.stop_reason=="check_manual_stop", "file retains frames and the explicit stop reason")
	var manual_metadata: Dictionary = parsed.metadata
	var original_size: int = trace.rows.size()
	for i in 3: await get_tree().process_frame
	check(trace.rows.size() == original_size and not trace.stop(), "stopped recorder neither samples nor flushes twice")
	remove_child(trace)
	trace.free()
	var ring: Node = TRACE.new()
	for i in TRACE.MAX_FRAMES+3: ring._append({"n":i})
	var ordered: Array = ring._ordered_rows()
	check(ordered.size() == TRACE.MAX_FRAMES and int(ordered[0].n)==3 and int(ordered.back().n)==TRACE.MAX_FRAMES+2 and ring.overwritten==3, "ring retains exactly the latest bounded frames in order")
	ring.free()
	trace = TRACE.install(self,PackedStringArray(["--play03-trace="+output.path_join("exit")]))
	for i in 3: await get_tree().process_frame
	saved_path = trace.output_path
	# Same tree-exit hook used by a normal scene/game close; player remains live.
	remove_child(trace)
	trace.free()
	parsed = JSON.parse_string(FileAccess.get_file_as_string(saved_path))
	check(parsed is Dictionary and parsed.metadata.stop_reason=="scene_exit", "normal tree exit flushes the capture")
	check(terrain.play03_trace == null and player.play03_trace == null, "exit clears all production recorder references")
	check(not has_node("Play03Trace"), "exited recorder node is removed")
	var result := {"checks":checks,"failures":failures,"manual_trace":manual_metadata,"exit_trace":parsed.metadata,"scope":"Headless activation, unchanged normal world use, bounded ring, stop and tree-exit lifecycle. Not rendered performance or a paid-save replay."}
	FileAccess.open(output.path_join("check-report.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("PLAY03_RECORDER ",JSON.stringify(result))
	get_tree().quit(0 if failures == 0 else 1)
