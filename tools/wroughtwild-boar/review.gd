extends Node3D
## Isolated art review. Never loads the game, its extension or a normal save.

var material: ShaderMaterial
var actors: Array[Node3D] = []
var players: Array[AnimationPlayer] = []
var camera: Camera3D
var sunlight: DirectionalLight3D
var environment: Environment
var caption: Label
var clock := 0.0
var pose_clock := 0.0
var paused := false
var automatic := false
var pose_name := "idle"
var mode := 3
var shade := false
var lod := "near"
var minimum := 0.25
var period := 4.0
var status := false
var orbit := 0.0
var distance_metres := 3.2
var config: Dictionary
var output := "res://evidence"
const POSES := ["idle", "walk", "root", "turn", "windup", "release"]
const MODES := ["Light off", "Steady", "Breathing", "Travelling"]

func _ready() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://boar-study.json"))
	minimum = config.scar.minimum_light
	period = config.scar.period_seconds
	material = ShaderMaterial.new()
	material.shader = load("res://boar_scar.gdshader")
	for pair in [["base_texture", "base.png"], ["orm_texture", "orm.png"], ["scar_texture", "scar-mask.png"], ["normal_texture", "normal.png"]]:
		var texture: Texture2D = load("res://" + pair[1])
		assert(texture != null, "Missing texture: " + pair[1])
		material.set_shader_parameter(pair[0], texture)
	material.set_shader_parameter("use_normal_map", true)
	material.set_shader_parameter("peak_emission", config.scar.peak_emission)
	material.set_shader_parameter("crest_width", config.scar.crest_width)
	var c: Array = config.scar.colour
	# The Blender study stores linear light; source_color uniforms expect sRGB.
	material.set_shader_parameter("core_colour", Color(c[0], c[1], c[2]).linear_to_srgb())
	var world_environment := WorldEnvironment.new()
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.085, 0.105, 0.12)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.72, 0.78, 0.85)
	environment.ambient_light_energy = 0.55
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.glow_enabled = false
	world_environment.environment = environment
	add_child(world_environment)
	sunlight = DirectionalLight3D.new()
	sunlight.rotation_degrees = Vector3(-48, -35, 0)
	sunlight.light_color = Color(1.0, 0.91, 0.79)
	sunlight.light_energy = 1.5
	sunlight.shadow_enabled = true
	add_child(sunlight)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90, 90)
	floor_mesh.mesh = plane
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.24, 0.265, 0.25)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	add_child(floor_mesh)
	camera = Camera3D.new()
	camera.fov = 40.0
	camera.near = 0.05
	add_child(camera)
	camera.current = true
	get_viewport().msaa_3d = Viewport.MSAA_4X
	_build_actor_set(1)
	_camera_view()
	var canvas := CanvasLayer.new()
	add_child(canvas)
	caption = Label.new()
	caption.position = Vector2(24, 20)
	caption.add_theme_font_size_override("font_size", 20)
	caption.add_theme_color_override("font_shadow_color", Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x", 1)
	caption.add_theme_constant_override("shadow_offset_y", 2)
	canvas.add_child(caption)
	_apply_settings()
	var args := OS.get_cmdline_user_args()
	if "--check" in args:
		automatic = true
		await get_tree().process_frame
		get_tree().quit(0 if _checks() else 1)
	elif "--capture" in args:
		automatic = true
		await _capture_suite()
		get_tree().quit()
	elif "--benchmark" in args:
		automatic = true
		await _benchmark_suite()
		get_tree().quit()

func _build_actor_set(count: int) -> void:
	var names := ["far-base.png", "far-orm.png", "far-scar.png", "far-normal.png"] if lod == "far" else ["base.png", "orm.png", "scar-mask.png", "normal.png"]
	var parameters := ["base_texture", "orm_texture", "scar_texture", "normal_texture"]
	for i in 4:
		var texture: Texture2D = load("res://" + names[i])
		assert(texture != null)
		material.set_shader_parameter(parameters[i], texture)
	for actor in actors:
		remove_child(actor)
		actor.queue_free()
	actors.clear()
	players.clear()
	var scene: PackedScene = load("res://boar-" + lod + ".glb")
	for index in count:
		var actor: Node3D = scene.instantiate()
		add_child(actor)
		actors.append(actor)
		if count > 1:
			actor.position = Vector3((index % 6 - 2.5) * 1.6, 0, (index / 6 - 1.5) * 2.0)
		for node in actor.find_children("*", "MeshInstance3D", true, false):
			node.material_override = material
			node.set_instance_shader_parameter("phase_offset", fmod(index * 0.381966, 1.0))
		var list := actor.find_children("*", "AnimationPlayer", true, false)
		assert(list.size() == 1)
		var player: AnimationPlayer = list[0]
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		players.append(player)
	_set_pose(pose_name, 0.0)

func _set_pose(value: String, time: float) -> void:
	pose_name = value
	pose_clock = time
	for player in players:
		assert(player.has_animation(value))
		player.play(value)
		player.seek(minf(time, player.get_animation(value).length), true)
		player.advance(0.0)

func _camera_view() -> void:
	var target := Vector3(0, 0.56, 0)
	var direction := Vector3(-0.67, 0.30, -0.68).normalized().rotated(Vector3.UP, orbit)
	camera.position = target + direction * distance_metres
	camera.look_at(target)

func _apply_settings() -> void:
	material.set_shader_parameter("pulse_mode", mode)
	material.set_shader_parameter("minimum_light", minimum)
	material.set_shader_parameter("period_seconds", period)
	material.set_shader_parameter("scar_clock", clock)
	material.set_shader_parameter("status_tint", Color(0.22, 0.7, 1, 0.9) if status else Color(1, 1, 1, 0))
	material.set_shader_parameter("status_emission", Vector3(0.08, 0.24, 0.4) if status else Vector3.ZERO)
	sunlight.light_energy = 0.15 if shade else 1.5
	environment.ambient_light_energy = 0.22 if shade else 0.55
	caption.text = "KILNBACK / LIVING SCARS\n%s · %s · %s · %s\n%s · %.1fs · minimum %d%% · bloom off\n\nSpace pause    M light    A pose    L day/shade\nP period    B minimum    D detail    S status\nArrow keys orbit / distance    R reset" % [MODES[mode], "Shade" if shade else "Day", pose_name.capitalize(), lod, "Paused" if paused else "Running", period, roundi(minimum * 100)]

func _process(delta: float) -> void:
	if automatic or paused:
		return
	clock += delta
	pose_clock += delta
	material.set_shader_parameter("scar_clock", clock)
	for player in players:
		player.seek(fmod(pose_clock, player.get_animation(pose_name).length), true)
		player.advance(0.0)

func _unhandled_key_input(event: InputEvent) -> void:
	if automatic or not event.is_pressed() or event.is_echo():
		return
	match event.keycode:
		KEY_SPACE: paused = not paused
		KEY_M: mode = (mode + 1) % 4
		KEY_A: _set_pose(POSES[(POSES.find(pose_name) + 1) % POSES.size()], 0.0)
		KEY_L: shade = not shade
		KEY_P: period = 2.5 if period == 4.0 else 4.0
		KEY_B: minimum = 0.5 if minimum == 0.25 else 0.25
		KEY_S: status = not status
		KEY_D:
			lod = ["near", "mid", "far"][(["near", "mid", "far"].find(lod) + 1) % 3]
			_build_actor_set(1)
		KEY_LEFT: orbit -= 0.2
		KEY_RIGHT: orbit += 0.2
		KEY_UP: distance_metres = maxf(1.8, distance_metres - 0.5)
		KEY_DOWN: distance_metres += 0.5
		KEY_R:
			orbit = 0.0
			distance_metres = 3.2
	_camera_view()
	_apply_settings()

func _checks() -> bool:
	var rig: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://rig-report.json"))
	var results: Array = []
	for detail in ["near", "mid", "far"]:
		lod = detail
		_build_actor_set(1)
		var actor := actors[0]
		var skeletons := actor.find_children("*", "Skeleton3D", true, false)
		assert(skeletons.size() == 1)
		var skeleton: Skeleton3D = skeletons[0]
		assert(skeleton.get_bone_count() == 16)
		var meshes := actor.find_children("*", "MeshInstance3D", true, false)
		assert(meshes.size() == 1)
		var mesh: MeshInstance3D = meshes[0]
		assert(mesh.skin != null and mesh.mesh.get_surface_count() == 1)
		var arrays := mesh.mesh.surface_get_arrays(0)
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		assert(weights.size() > 0 and weights.size() % 4 == 0)
		for i in range(0, weights.size(), 4):
			var total := 0.0
			for j in 4:
				assert(is_finite(weights[i+j]) and weights[i+j] >= 0)
				total += weights[i+j]
			assert(absf(total - 1) < 0.0001)
		for clip in POSES:
			var animation := players[0].get_animation(clip)
			assert(absf(animation.length - rig.clips_seconds[clip]) < 0.0001)
			for sample in 9:
				_set_pose(clip, animation.length * sample / 8.0)
				for bone in skeleton.get_bone_count():
					assert(skeleton.get_bone_global_pose(bone).is_finite())
					if skeleton.get_bone_name(bone).ends_with("_hoof"):
						var hoof_y := skeleton.get_bone_global_pose(bone).origin.y
						if clip != "walk":
							assert(absf(hoof_y - 0.1) < 0.001, "%s %s hoof height %f" % [detail, clip, hoof_y])
						else:
							assert(hoof_y >= 0.099 and hoof_y <= 0.166)
		results.append({"lod": detail, "skin_vertices": weights.size()/4, "bones": 16, "clips_checked": POSES, "aabb": str(mesh.get_aabb())})
	_build_actor_set(2)
	var first: MeshInstance3D = actors[0].find_children("*", "MeshInstance3D", true, false)[0]
	var second: MeshInstance3D = actors[1].find_children("*", "MeshInstance3D", true, false)[0]
	assert(first.material_override == second.material_override)
	assert(not is_equal_approx(first.get_instance_shader_parameter("phase_offset"), second.get_instance_shader_parameter("phase_offset")))
	automatic = false
	paused = true
	var before := clock
	var pose_before := pose_clock
	_process(0.5)
	assert(clock == before and pose_clock == pose_before)
	paused = false
	_process(0.5)
	assert(is_equal_approx(clock, before + 0.5))
	assert(is_equal_approx(pose_clock, pose_before + 0.5))
	automatic = true
	_write_json("engine-checks.json", {"variants": results, "pause_resume": true, "shared_material_independent_phase": true, "bloom": false, "game_loaded": false, "engine": Engine.get_version_info()})
	print("BOAR_ENGINE_CHECKS_OK")
	return true

func _write_json(name: String, value: Variant) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var file := FileAccess.open(output.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t") + "\n")

func _capture(name: String) -> void:
	_apply_settings()
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var image := get_viewport().get_texture().get_image()
	assert(not image.is_empty())
	assert(image.save_png(output.path_join(name + ".png")) == OK)

func _capture_suite() -> void:
	for lighting in [false, true]:
		shade = lighting
		for style in [0, 1, 3]:
			mode = style
			clock = 1.6
			_set_pose("idle", 0.0)
			await _capture(("shade" if shade else "day") + "-" + str(style))
	mode = 3
	shade = false
	for clip in POSES:
		_set_pose(clip, players[0].get_animation(clip).length * 0.5)
		await _capture("pose-" + clip)
	status = true
	await _capture("status-priority")
	status = false
	_set_pose("idle", 0.0)
	for view in [["front", -PI/4], ["side", PI/4], ["rear", 3*PI/4], ["right", -PI/2]]:
		orbit = view[1]
		_camera_view()
		await _capture("view-" + view[0])
	orbit = 0.0
	_camera_view()
	for detail in ["near", "mid", "far"]:
		lod = detail
		_build_actor_set(1)
		for distance in [3.2, 8.0, 18.0]:
			distance_metres = distance
			_camera_view()
			await _capture("lod-" + detail + "-" + str(distance))
	lod = "near"
	_build_actor_set(1)
	distance_metres = 3.2
	_camera_view()
	# Eight seconds closes both the 1.6-second gait and 4-second current loops.
	for lighting in [false, true]:
		shade = lighting
		for frame in 192:
			clock = frame / 24.0
			_set_pose("walk", fmod(clock, 1.6))
			await _capture(("shade" if shade else "day") + "-frame-%03d" % frame)
	_write_json("capture-setup.json", {"resolution": [1280,960], "camera": str(camera.transform), "fov": camera.fov, "distance_metres": distance_metres, "sun_rotation_degrees": str(sunlight.rotation_degrees), "day_sun_energy": 1.5, "shade_sun_energy": 0.15, "bloom": false, "frames_per_second": 24, "duration_seconds": 8, "description": "Deterministically sampled engine frames, not a real-time FPS claim."})
	print("BOAR_CAPTURES_OK")

func _benchmark_suite() -> void:
	caption.visible = false
	var rid := get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(rid, true)
	var result: Array = []
	for count in [1, 24]:
		for detail in ["near", "mid", "far"]:
			lod = detail
			_build_actor_set(count)
			distance_metres = 3.2 if count == 1 else 17.0
			_camera_view()
			for skinning in [false, true]:
				for style in [0, 3]:
					mode = style
					_apply_settings()
					var cpu: Array[float] = []
					var gpu: Array[float] = []
					var frames: Array[float] = []
					var last := Time.get_ticks_usec()
					for frame in 240:
						clock = frame / 60.0
						material.set_shader_parameter("scar_clock", clock)
						if skinning:
							_set_pose("walk", fmod(clock, 1.6))
						await RenderingServer.frame_post_draw
						var now := Time.get_ticks_usec()
						if frame >= 60:
							frames.append((now - last) / 1000.0)
							cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(rid))
							gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(rid))
						last = now
					result.append({"count":count,"lod":detail,"animated":skinning,"mode":style,"frame_ms":_summary(frames),"render_cpu_ms":_summary(cpu),"render_gpu_ms":_summary(gpu),"draw_calls_visible":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"draw_calls_shadow":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"texture_bytes_project":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED)})
	_write_json("performance.json", {"renderer":"Forward+", "adapter":RenderingServer.get_video_adapter_name(), "resolution":[1280,960], "warmup_frames":60, "sample_frames":180, "cases":result, "limitations":"Isolated actors and floor; no native game simulation, world streaming or lower-spec measurement. Static posed skin versus updated animation is not an unskinned-mesh GPU comparison."})
	print("BOAR_BENCHMARK_OK")

func _summary(samples: Array[float]) -> Dictionary:
	samples.sort()
	return {"median":samples[samples.size()/2],"p95":samples[int(samples.size()*0.95)]}
