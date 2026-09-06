extends "res://tests/frontier_polish_review.gd"
## Fixed normal-world frame with one shading source removed at a time.
## Inspect the five PNGs for seams; this is an art diagnostic, not a benchmark.

func _review() -> void:
	if "--wildland-fen-perf" in OS.get_cmdline_user_args():
		await _fen_performance()
		return
	output=ProjectSettings.globalize_path("res://../build/frontier-polish/diagnostic")
	DirAccess.make_dir_recursive_absolute(output)
	_setup_camera()
	var region: Dictionary=terrain.map.regions[0]
	var path: PackedVector3Array=region.approach
	var at: Vector3=path[maxi(0,path.size()-28)]
	await _settle(at,144.0)
	mood._target=mood.active_mood(mood._biome_under_player())
	mood._apply(1.0)
	review_camera.global_position=_ground(at)+Vector3.UP*1.65
	review_camera.look_at(Vector3(region.x+.5,region.y+3.0,region.z+.5))
	terrain.set_process(false)
	for variant in ["baseline","no_bump","no_ssao","no_shadow","no_bump_no_ssao"]:
		var no_bump: bool=variant.contains("no_bump")
		for material: ShaderMaterial in terrain._materials.values():
			material.set_shader_parameter("bump_height_m",0.0 if no_bump else terrain.frontier_look.bump_height_m)
			material.set_shader_parameter("rock_bump_m",0.0 if no_bump else terrain.frontier_look.rock_bump_m)
		$WorldEnvironment.environment.ssao_enabled=not variant.contains("no_ssao")
		$Sun.shadow_enabled=variant!="no_shadow"
		caption.text=variant.to_upper()
		await _capture(variant)


func _fen_performance() -> void:
	output=ProjectSettings.globalize_path("res://../build/frontier-polish/fen-perf")
	DirAccess.make_dir_recursive_absolute(output)
	_setup_camera()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	report["scope"]="Seed 1, same final static Fen pose, actual biome mood, fixed clock, 1440x900 Forward+, FOV75, uncapped. Prior Uplands pose is settled first as in the primary review. Four 600-frame windows per phase, with 90 warmup frames before each; only StrangeSites visibility changes. Terrain/resources remain fixed."
	for region: Dictionary in terrain.map.regions:
		var path: PackedVector3Array=region.approach
		var at: Vector3=path[maxi(0,path.size()-28)]
		await _settle(at,144.0)
		mood._target=mood.active_mood(mood._biome_under_player())
		mood._apply(1.0)
		review_camera.global_position=_ground(at)+Vector3.UP*1.65
		review_camera.look_at(Vector3(region.x+.5,region.y+3.0,region.z+.5))
		terrain.set_process(false)
		if region.id=="lantern_fen": break
		await _sample_frames()
		terrain.set_process(true)
	report["camera_transform"]=str(review_camera.transform)
	report["loaded_chunks"]=terrain.chunks.size()
	report["active_resources"]=terrain.resource_stream.active.size()
	report["phases"]=[]
	var dressing:=get_node("StrangeSites") as Node3D
	for phase in ["shown_initial","hidden","shown_return"]:
		dressing.visible=phase!="hidden"
		caption.text="LANTERN FEN · "+phase.to_upper()
		await _capture(phase)
		var windows: Array=[]
		for i in 4:
			windows.append(await _sample_frames())
		report.phases.append({"phase":phase,"windows":windows})
	dressing.show()
