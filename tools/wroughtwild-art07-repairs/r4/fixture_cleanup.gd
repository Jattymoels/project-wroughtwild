extends RefCounted
## Terminal teardown for the eight isolated review fixtures, never live game cleanup.
## Stop/free only descendants of a completed fixture, then observe the pinned
## engine's audio mixer/main-thread handoff before its normal SceneTree.quit().
const OPTIONS := preload("res://r4/cleanup_options.gd")

static func counts() -> Dictionary:
	return {
		"objects":int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"resources":int(Performance.get_monitor(Performance.OBJECT_RESOURCE_COUNT)),
		"nodes":int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
		"orphans":int(Performance.get_monitor(Performance.OBJECT_ORPHAN_NODE_COUNT)),
		"static_bytes":int(Performance.get_monitor(Performance.MEMORY_STATIC)),
		"cached_action_clips":InteractionSound._clips.size()
	}

static func _alive(refs: Array[WeakRef]) -> int:
	var count := 0
	for ref in refs:
		if ref.get_ref() != null: count += 1
	return count

static func dispose(fixture: Node) -> Dictionary:
	assert(is_instance_valid(fixture) and fixture.is_inside_tree())
	var tree := fixture.get_tree()
	var started := Time.get_ticks_usec()
	var result := {"fixture":fixture.get_script().resource_path if fixture.get_script()!=null else str(fixture.name),
		"before":counts(),"voices":[]}
	var playbacks: Array[WeakRef] = []
	# This is terminal disposal after work/save assertions, not a pause or restore.
	fixture.process_mode = Node.PROCESS_MODE_DISABLED
	result["frame_waiters_before"]=tree.get_signal_connection_list("process_frame").size()
	for frame in OPTIONS.PREDISPOSE_FRAMES: await tree.process_frame
	result["frame_waiters_before_free"]=tree.get_signal_connection_list("process_frame").size()
	for node in fixture.find_children("*","AudioStreamPlayer3D",true,false):
		var voice := node as AudioStreamPlayer3D
		var entry := {"node_id":voice.get_instance_id(),"name":str(voice.name),
			"cue":str(voice.get_meta("cue","")),"stream_id":0,"playback_id":0}
		if voice.stream != null: entry.stream_id=voice.stream.get_instance_id()
		if voice.has_stream_playback():
			var playback := voice.get_stream_playback()
			entry.playback_id=playback.get_instance_id()
			playbacks.append(weakref(playback))
			playback=null # The observer must not keep the last playback alive across await.
		result.voices.append(entry)
		voice.stop()
		voice.stream=null # Drop this player's reference; the reusable PCM cache stays live.
	for child in fixture.get_children(): child.queue_free()
	var passes := 0
	var frames := 0
	var previous_age := AudioServer.get_time_since_last_mix()
	# --fixed-fps advances scene time faster than the audio thread. A SceneTreeTimer
	# or two immediate process_frames alone does not prove a real mixer handoff.
	while passes < OPTIONS.MIX_PASSES or frames < OPTIONS.MAIN_FRAMES or _alive(playbacks)>0 or fixture.get_child_count()>0:
		assert(Time.get_ticks_usec()-started < int(OPTIONS.TIMEOUT_SECONDS*1000000),
			"R4 owned fixture teardown did not release audio before its deadline")
		OS.delay_msec(OPTIONS.POLL_SLEEP_MS)
		await tree.process_frame
		frames+=1
		var age := AudioServer.get_time_since_last_mix()
		if age < previous_age: passes+=1
		previous_age=age
	for frame in OPTIONS.MAIN_FRAMES: await tree.process_frame
	assert(_alive(playbacks)==0 and fixture.get_child_count()==0,
		"R4 fixture descendants and observed playback references must be released")
	result["mix_passes"]=passes
	result["poll_frames"]=frames
	result["playbacks_after"]=_alive(playbacks)
	result["children_after"]=fixture.get_child_count()
	result["after"]=counts()
	result["seconds"]=float(Time.get_ticks_usec()-started)/1000000.0
	print("R4_CLEANUP ",JSON.stringify(result))
	return result

static func finish(fixture: Node, exit_code: int) -> void:
	await dispose(fixture)
	fixture.get_tree().quit.call_deferred(exit_code) # Unwind the completion coroutine before normal quit.
