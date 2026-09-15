extends Node3D
## Species-only exported-asset fixture. It cannot recruit, deal damage or save.
var descriptor: Dictionary
var models: Array[Node3D] = []
var players: Array[AnimationPlayer] = []
var rigs: Array[Skeleton3D] = []
var materials: Array[ShaderMaterial] = []
var checks: Array[String] = []
var failures: Array[String] = []
var detail: Dictionary = {}
var label: Label
var capture := false
var output := ""

func check(ok: bool, message: String) -> void:
	if ok: checks.append(message)
	else:
		failures.append(message)
		push_error(message)

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	capture = "--capture" in OS.get_cmdline_user_args()
	output = ProjectSettings.globalize_path("res://../evidence")
	DirAccess.make_dir_recursive_absolute(output)
	descriptor = JSON.parse_string(FileAccess.get_file_as_string("res://assets/asset.json"))
	var scene: PackedScene = load("res://assets/model.glb")
	for index in range(2):
		var model: Node3D = scene.instantiate()
		add_child(model)
		models.append(model)
		var skeletons := model.find_children("*", "Skeleton3D", true, false)
		var animation_players := model.find_children("*", "AnimationPlayer", true, false)
		check(skeletons.size() == 1 and animation_players.size() == 1, "one skeleton/player per instance %d" % index)
		if skeletons.is_empty() or animation_players.is_empty():
			finish("state")
			return
		var rig: Skeleton3D = skeletons[0]
		var player: AnimationPlayer = animation_players[0]
		rigs.append(rig)
		players.append(player)
		player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
		check(String(model.get_path_to(rig)) == descriptor.skeleton_path, "documented skeleton path %d" % index)
		check(String(model.get_path_to(player)) == descriptor.animation_player_path, "documented animation player path %d" % index)
		check(rig.get_bone_count() == int(descriptor.bone_count), "16 fitted joints %d" % index)
		var material := ShaderMaterial.new()
		material.shader = load("res://assets/lifeline.gdshader")
		for kind in descriptor.maps:
			var tex: Texture2D = load("res://assets/" + str(descriptor.maps[kind]))
			check(tex != null and tex.get_width() == 2048, "required original map %s/%d" % [kind,index])
			material.set_shader_parameter(kind + "_texture", tex)
		for name in ["period_seconds","peak_emission","minimum_light","crest_width","pulse_mode"]:
			material.set_shader_parameter(name,descriptor.material[name])
		material.set_shader_parameter("core_colour",Color(.32,.71,.76))
		material.set_shader_parameter("damage_tint",Vector3(.16,.14,.12))
		materials.append(material)
		var triangles := 0
		for mesh: MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
			mesh.material_override = material
			mesh.set_instance_shader_parameter("phase_offset",float(index)*.37)
			mesh.extra_cull_margin = .5
			check(String(model.get_path_to(mesh)) in descriptor.mesh_paths, "documented mesh path " + String(model.get_path_to(mesh)))
			check(mesh.skin != null, "weighted exported mesh " + mesh.name)
			for surface in range(mesh.mesh.get_surface_count()):
				var arrays := mesh.mesh.surface_get_arrays(surface)
				triangles += arrays[Mesh.ARRAY_INDEX].size()/3
		check(triangles == int(descriptor.triangles), "actual imported triangle count %d" % index)
		for clip: String in descriptor.clips:
			check(player.has_animation(clip), "exported clip %s/%d" % [clip,index])
			var anim := player.get_animation(clip)
			check(absf(anim.length-float(descriptor.clips[clip].duration_seconds)) < .001, "clip duration %s/%d" % [clip,index])
			for track in range(anim.get_track_count()):
				check(anim.track_get_type(track) in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D], "pose-only track %s/%d" % [clip,track])
			# glTF has no portable loop flag; this is the documented adapter setup.
			anim.loop_mode = Animation.LOOP_LINEAR if descriptor.clips[clip].loop else Animation.LOOP_NONE
	await get_tree().process_frame
	if capture:
		await run_capture()
	else:
		await run_state()

func sample(which: int, clip: String, time: float) -> void:
	players[which].play(clip)
	players[which].seek(time,true)
	players[which].advance(0)
	rigs[which].force_update_all_bone_transforms()

func matrices(which: int) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for bone in range(rigs[which].get_bone_count()): result.append(rigs[which].get_bone_global_pose(bone))
	return result

func pose_difference(a: Array[Transform3D], b: Array[Transform3D]) -> float:
	var worst := 0.0
	for i in range(a.size()):
		worst=maxf(worst,a[i].origin.distance_to(b[i].origin))
		worst=maxf(worst,(a[i].basis.x-b[i].basis.x).length())
		worst=maxf(worst,(a[i].basis.y-b[i].basis.y).length())
		worst=maxf(worst,(a[i].basis.z-b[i].basis.z).length())
	return worst

func skin_vertices(which: int, mesh: MeshInstance3D) -> PackedVector3Array:
	var result := PackedVector3Array()
	var rig := rigs[which]
	var transforms: Array[Transform3D] = []
	for bind in range(mesh.skin.get_bind_count()):
		var bone := mesh.skin.get_bind_bone(bind)
		if bone < 0: bone=rig.find_bone(mesh.skin.get_bind_name(bind))
		transforms.append(rig.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bind))
	for surface in range(mesh.mesh.get_surface_count()):
		var a := mesh.mesh.surface_get_arrays(surface)
		var positions: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var joints: PackedInt32Array = a[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		for index in range(positions.size()):
			var p := Vector3.ZERO
			var total := 0.0
			for influence in range(4):
				var weight := weights[index*4+influence]
				p += transforms[joints[index*4+influence]]*positions[index]*weight
				total += weight
			if absf(total-1.0)>.0001: check(false,"invalid exported weight sum")
			result.append(p)
	return result

func run_state() -> void:
	check(rigs[0] != rigs[1] and materials[0] != materials[1], "independent instance skeletons and materials")
	sample(1,"idle",.2)
	var untouched := matrices(1)
	sample(0,"call",.35)
	check(pose_difference(untouched,matrices(1)) < .00001,"call on one instance leaves other pose unchanged")
	check(pose_difference(matrices(0),matrices(1)) > .05,"call visibly articulates neck and beak")
	for clip: String in ["idle","walk"]:
		var anim := players[0].get_animation(clip)
		anim.loop_mode=Animation.LOOP_NONE
		sample(0,clip,0)
		var start := matrices(0)
		sample(0,clip,anim.length)
		check(pose_difference(start,matrices(0)) < .0001,"seamless " + clip + " loop")
		anim.loop_mode=Animation.LOOP_LINEAR
	sample(0,"idle",0)
	var neutral := matrices(0)
	sample(0,"call",1.25)
	check(pose_difference(neutral,matrices(0)) < .0001,"call ends in full neutral pose")
	sample(0,"release",.3)
	check(pose_difference(neutral,matrices(0)) < .0001,"peck ends in full neutral pose")
	sample(0,"windup",.5)
	var anticipation := matrices(0)
	sample(0,"release",0)
	check(pose_difference(anticipation,matrices(0)) < .0001,"windup joins melee release")
	var sampled_bounds: Array = []
	for moment: Array in [["idle",0.0],["walk",.24],["walk",.84],["windup",.5],["release",.1],["call",.35]]:
		sample(0,moment[0],moment[1])
		for mesh: MeshInstance3D in models[0].find_children("*","MeshInstance3D",true,false):
			var vertices := skin_vertices(0,mesh)
			var low := Vector3(INF,INF,INF)
			var high := -low
			for p in vertices:
				low=low.min(p);high=high.max(p)
			check(low.is_finite() and high.is_finite(),"finite skin " + moment[0] + "/" + mesh.name)
			check(low.y > -.015,"skin stays above floor " + moment[0] + "/" + mesh.name)
			check(high.y < 2.3 and (high-low).length() < 3.3,"bounded skin " + moment[0] + "/" + mesh.name)
			sampled_bounds.append({"clip":moment[0],"time":moment[1],"mesh":mesh.name,"low":[low.x,low.y,low.z],"high":[high.x,high.y,high.z]})
	detail["sampled_skin_bounds"]=sampled_bounds
	# Exact shared vertices at the jaw root must remain attached while its tip opens.
	var body: MeshInstance3D=models[0].get_node(descriptor.mesh_paths[0])
	var jaw: MeshInstance3D=models[0].get_node(descriptor.mesh_paths[1])
	var ba: PackedVector3Array=body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var ja: PackedVector3Array=jaw.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var root_pairs: Array = []
	for j in range(ja.size()):
		if ja[j].z > .557: continue
		for i in range(ba.size()):
			if ja[j].distance_to(ba[i]) < .00001:
				root_pairs.append([i,j])
				break
	check(not root_pairs.is_empty(),"shared supporting jaw-root vertices exist")
	sample(0,"call",.35)
	var bp := skin_vertices(0,body)
	var jp := skin_vertices(0,jaw)
	var separation := 0.0
	for pair: Array in root_pairs:separation=maxf(separation,bp[pair[0]].distance_to(jp[pair[1]]))
	check(separation < .008,"lower beak root remains attached during call")
	detail["jaw_root_pairs"]=root_pairs.size()
	detail["max_jaw_root_gap_source_units"]=separation
	detail["skeleton_path"]=String(models[0].get_path_to(rigs[0]))
	detail["animations"]=Array(players[0].get_animation_list())
	finish("state")

func stage() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode=Environment.BG_COLOR
	env.background_color=Color(.085,.11,.135)
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color=Color(.64,.73,.8)
	env.ambient_light_energy=.65
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	environment.environment=env
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-42,-38,0)
	sun.light_color=Color(1,.89,.75)
	sun.light_energy=2.0
	sun.shadow_enabled=true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-25,145,0)
	fill.light_color=Color(.57,.76,1)
	fill.light_energy=.8
	add_child(fill)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size=Vector2(200,200)
	ground.mesh=plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(.105,.13,.14)
	mat.roughness=1
	ground.material_override=mat
	add_child(ground)
	models[0].position=Vector3(-.65,0,0)
	models[0].rotation_degrees.y=-30
	models[1].position=Vector3(1.1,0,-.30)
	models[1].rotation_degrees.y=122
	models[1].scale=Vector3.ONE*.82
	var camera := Camera3D.new()
	camera.position=Vector3(3.2,2.25,4.3)
	add_child(camera)
	camera.look_at(Vector3(.15,1.02,0))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL
	camera.size=3.4
	camera.current=true
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var title := Label.new()
	title.text="MOB-03  /  CRANE"
	title.position=Vector2(36,24)
	title.add_theme_font_size_override("font_size",27)
	canvas.add_child(title)
	label=Label.new()
	label.position=Vector2(36,63)
	label.add_theme_font_size_override("font_size",18)
	canvas.add_child(label)
	var footer := Label.new()
	footer.text="Actual exported skin  /  65,107 triangles  /  ART-06C living channels\nSpecies fixture  -  normal-game integration follows this handoff"
	footer.position=Vector2(36,695)
	footer.add_theme_font_size_override("font_size",16)
	canvas.add_child(footer)

func run_capture() -> void:
	stage()
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"capture leaves pointer visible")
	check(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"capture window cannot take focus")
	var frames_dir := output+"/frames"
	DirAccess.make_dir_recursive_absolute(frames_dir)
	for frame in range(160):
		var t := frame/20.0
		var clip := "idle"
		var local_time := t
		var title := "Quiet breathing / planted stance"
		if t>=2.0 and t<4.4:
			clip="walk";local_time=fposmod(t-2.0,1.2);title="Grounded walk / two supporting legs"
		elif t>=4.4 and t<5.65:
			clip="call";local_time=t-4.4;title="Recruitment call / supported throat and beak"
		elif t>=5.8 and t<6.3:
			clip="windup";local_time=t-5.8;title="Weak close attack / anticipation"
		elif t>=6.3 and t<6.6:
			clip="release";local_time=t-6.3;title="Weak close attack / small peck"
		sample(0,clip,local_time)
		if clip=="walk":sample(1,"walk",fposmod(local_time+.6,1.2))
		elif clip=="call":sample(1,"call",local_time)
		else:sample(1,"idle",fposmod(t+.8,4.0))
		label.text=title
		for material in materials:material.set_shader_parameter("scar_clock",t)
		await RenderingServer.frame_post_draw
		var im := get_viewport().get_texture().get_image()
		check(im.save_png(frames_dir+"/%04d.png" % frame)==OK,"saved frame %d" % frame)
		if frame==22: im.save_png(output+"/crane-idle.png")
		if frame==94: im.save_png(output+"/crane-call.png")
		if frame==55: im.save_png(output+"/crane-walk.png")
		await get_tree().process_frame
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"pointer remains visible after capture")
	detail["frames"]=160
	detail["fps"]=20
	detail["renderer"]=RenderingServer.get_current_rendering_method()
	check(detail.renderer=="forward_plus","Forward+ capture")
	finish("capture")

func finish(mode: String) -> void:
	var f := FileAccess.open(output+"/"+mode+"-report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks.size(),"failures":failures,"detail":detail},"\t"))
	f.close()
	if failures.is_empty():print("MOB03_"+mode.to_upper()+"_OK "+str(checks.size()))
	else:print("MOB03_"+mode.to_upper()+"_FAILED "+str(failures))
	get_tree().quit(0 if failures.is_empty() else 1)
