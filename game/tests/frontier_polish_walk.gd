extends "res://tests/strange_frontier_review.gd"
## Walking-height evidence plus a separate uncapped traversal sample. PNG readback
## is deliberately absent from the timing pass; it otherwise dominates p95.

func _review() -> void:
	var interior_only:="--polish-interior-only" in OS.get_cmdline_user_args()
	var timing_only:="--polish-walk-perf" in OS.get_cmdline_user_args()
	output=ProjectSettings.globalize_path("res://../build/frontier-polish/"+("interior" if interior_only else "walk-perf" if timing_only else "walk"))
	if "--cataclysm" in OS.get_cmdline_user_args() and timing_only:
		output=ProjectSettings.globalize_path("res://../build/cataclysm/v3-perf-"+("unbounded" if "--cat-unbounded-refresh" in OS.get_cmdline_user_args() else "bounded"))
		if "--cat-warm-view" in OS.get_cmdline_user_args(): output=ProjectSettings.globalize_path("res://../build/cataclysm/v3-perf-warmed")
	DirAccess.make_dir_recursive_absolute(output)
	_setup_camera()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	report["scope"]="Seed 1, 1440x900 Forward+, 5m/s scripted travel. Uncapped timing is collected before the separate four-images-per-second visual walk. Terrain and resource streaming remain active. Captures are not timed."
	if interior_only: report["scope"]="Normal lattice construction, same seed-1 material workshop, 1440x900 Forward+, 1.65m eye height. Dedicated post-fix interior inspection."
	report["routes"]=[]
	for region: Dictionary in terrain.map.regions:
		if interior_only: break
		if timing_only and region.id!="glasswind_uplands": continue
		var path: PackedVector3Array=region.approach
		var start:=maxi(0,path.size()-58)
		await _settle(path[start],64)
		mood._target=mood.active_mood(mood._biome_under_player())
		mood._apply(1.0)
		caption.text=String(region.id).replace("_"," ").to_upper()+" · WALKING APPROACH"
		var measured:=await _timed_walk(path,start)
		measured["id"]=region.id
		if not timing_only: measured["walk"]=await _walk(String(region.id),path)
		report.routes.append(measured)
	if timing_only: return
	if not interior_only: await _water_view()
	await _settle(terrain.surface_position(int(terrain.map.spawn_x)+11,int(terrain.map.spawn_z)+8))
	mood._target=mood.active_mood(mood._biome_under_player())
	mood._apply(1.0)
	await _interior()

func _timed_walk(path: PackedVector3Array, start: int) -> Dictionary:
	var times: Array[float]=[]
	var distance:=0.0
	var previous:=Time.get_ticks_usec()
	var slow_frames:=0
	var slow_events: Array=[]
	review_camera.global_position=_ground(path[start])+Vector3.UP*1.65
	var warmup: Array[float]=[]
	var warmup_stream_state: Dictionary={}
	if "--cat-warm-view" in OS.get_cmdline_user_args():
		# Diagnostic only: retain the first presentation cost separately rather
		# than silently excluding it from the original cold-camera measurement.
		review_camera.look_at(path[mini(path.size()-1,start+6)]+Vector3.UP*1.65)
		var was_processing:=terrain.is_processing()
		warmup_stream_state={"pending_before":terrain.chunk_stream._pending.size(),"job_phase_before":terrain.chunk_stream._job.get("phase",-1)}
		terrain.set_process(false)
		for frame in 60:
			var began:=Time.get_ticks_usec()
			await get_tree().process_frame
			warmup.append(float(Time.get_ticks_usec()-began)/1000.0)
		warmup_stream_state.pending_after=terrain.chunk_stream._pending.size()
		warmup_stream_state.job_phase_after=terrain.chunk_stream._job.get("phase",-1)
		terrain.set_process(was_processing)
		previous=Time.get_ticks_usec()
	for index in range(start+1,path.size()-3):
		var target: Vector3=path[index]
		while Vector2(review_camera.position.x-target.x,review_camera.position.z-target.z).length()>.05:
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			var ms:=float(now-previous)/1000.0
			previous=now
			times.append(ms)
			if ms>16.667:
				slow_frames+=1
				slow_events.append({"frame":times.size(),"ms":ms,"distance_m":distance,"route_index":index-start})
			var current:=Vector3(review_camera.position.x,0,review_camera.position.z)
			var step:=current.move_toward(Vector3(target.x,0,target.z),5.0*minf(ms/1000.0,.05))
			distance+=current.distance_to(step)
			var ground:=_ground(step)
			check(ground.is_finite(),"timed route has an actual walking surface")
			if not ground.is_finite(): break
			review_camera.global_position=ground+Vector3.UP*1.65
			player.global_position=ground+Vector3.UP*1.2
			var ahead: Vector3=path[mini(path.size()-1,index+5)]+Vector3.UP*1.65
			if ahead.distance_to(review_camera.global_position)>.1: review_camera.look_at(ahead)
	var total:=0.0
	for ms in times: total+=ms
	times.sort()
	return {"distance_m":distance,"seconds":total/1000.0,"samples":times.size(),"median_ms":times[times.size()/2],
		"initial_view_warmup_frames_ms":warmup,
		"warmup_stream_state":warmup_stream_state,
		"p95_ms":times[int(times.size()*.95)],"p99_ms":times[int(times.size()*.99)],"max_ms":times.back(),"frames_over_16_667_ms":slow_frames,"slow_events":slow_events}

func _water_view() -> void:
	var fen:=get_node("StrangeSites/lantern_fen")
	for part in fen.get_children():
		if not part.has_meta("pool_support"): continue
		var shore: Vector3=part.global_position+Vector3(0,0,float(part.get_meta("pool_radius",6))+2)
		await _settle(shore)
		mood._target=mood.active_mood(mood._biome_under_player())
		mood._apply(1.0)
		review_camera.global_position=_ground(shore)+Vector3.UP*1.65
		review_camera.look_at(part.global_position)
		caption.text="LANTERN FEN · SHORELINE AT WALKING HEIGHT"
		await _capture("shoreline")
		return
	check(false,"fen shoreline exists for normal-height review")
