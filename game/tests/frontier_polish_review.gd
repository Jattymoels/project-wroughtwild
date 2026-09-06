extends "res://tests/strange_frontier_review.gd"
## Matched normal-gameplay views. Compare the exact same seed, camera and hour;
## let each region use its actual mood rather than carrying spawn lighting.

func _review() -> void:
	var perf_check:="--polish-perf-check" in OS.get_cmdline_user_args()
	var label:="perf-check" if perf_check else "before" if "--polish-before" in OS.get_cmdline_user_args() else "after"
	output=ProjectSettings.globalize_path("res://../build/frontier-polish/"+label)
	DirAccess.make_dir_recursive_absolute(output)
	_setup_camera()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	report["scope"]="Seed 1, actual region mood, fixed clock, 1440x900 Forward+, FOV75, uncapped, same camera transforms. Settled static views; streaming work is completed before samples."
	report["views"]=[]
	for region:Dictionary in terrain.map.regions:
		if perf_check and region.id!="glasswind_uplands": continue
		var path:PackedVector3Array=region.approach
		var at:Vector3=path[maxi(0,path.size()-28)]
		await _settle(at,144.0)
		mood._target=mood.active_mood(mood._biome_under_player())
		mood._apply(1.0)
		review_camera.global_position=_ground(at)+Vector3.UP*1.65
		review_camera.look_at(Vector3(region.x+.5,region.y+3.0,region.z+.5))
		caption.text=String(region.id).replace("_"," ").to_upper()+" · "+label.to_upper()
		terrain.set_process(false)
		await _capture(String(region.id)+"-day")
		var metrics:=await _sample_frames()
		metrics["id"]=region.id
		metrics["camera_transform"]=str(review_camera.transform)
		if perf_check:
			# A flagged first-view p95 gets independent windows at the same pose;
			# keep the original before/after data intact, including its regression.
			metrics["repeat_windows"]=[]
			for i in 3: metrics.repeat_windows.append(await _sample_frames())
		report.views.append(metrics)
		var energy:float=$Sun.light_energy
		var sun_colour:Color=$Sun.light_color
		$Sun.light_energy=energy*.48
		$Sun.light_color=Color("d9bd91")
		await _capture(String(region.id)+"-dusk")
		$Sun.light_energy=energy
		$Sun.light_color=sun_colour
		terrain.set_process(true)
	if perf_check: return
	var seen:Dictionary={}
	for site:Dictionary in terrain.map.rare_sites:
		var id:=String(site.resource_type)
		if seen.has(id): continue
		seen[id]=true
		var path:PackedVector3Array=site.approach
		var at:Vector3=path[maxi(0,path.size()-5)]
		await _settle(at)
		mood._target=mood.active_mood(mood._biome_under_player())
		mood._apply(1.0)
		review_camera.global_position=_ground(at)+Vector3.UP*1.65
		review_camera.look_at(Vector3(site.x+.5,site.y+.5,site.z+.5))
		caption.text=id.to_upper()+" · "+label.to_upper()
		await _capture("find-"+id)

func _sample_frames() -> Dictionary:
	for i in 90: await get_tree().process_frame
	var times:Array[float]=[]
	var last:=Time.get_ticks_usec()
	for i in 600:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec()
		times.append(float(now-last)/1000.0)
		last=now
	times.sort()
	return {"samples":times.size(),"median_ms":times[times.size()/2],"p95_ms":times[int(times.size()*.95)],
		"p99_ms":times[int(times.size()*.99)],"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"static_memory_bytes":Performance.get_monitor(Performance.MEMORY_STATIC)}
