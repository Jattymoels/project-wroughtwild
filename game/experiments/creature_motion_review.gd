extends Node3D
## Fixed-camera pose playback of actual rigs; AI paused. FieldRoute tests live AI.
var actors: Array[Enemy] = []
var motions: Array[CreatureMotion] = []
var heading: Label
var frame := 0
var capturing := false
var output := ""

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/creature-motion")
	DirAccess.make_dir_recursive_absolute(output)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("28373e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("bbc3c0")
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-30,0)
	sun.light_color = Color("fff0d7")
	sun.shadow_enabled = true
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30,20)
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(3,-0.02,0)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("555953")
	material.roughness = 1.0
	floor_mesh.material_override = material
	add_child(floor_mesh)
	for i in 3:
		var enemy := Enemy.spawn(self,[&"ember_whelp",&"gloom_crawler",&"stone_husk"][i],Vector3(i*2.6,0,0))
		enemy.rotation.y = PI-0.65
		enemy.set_physics_process(false)
		enemy._label.set_process(false)
		enemy._label.hide()
		actors.append(enemy)
		var motion := enemy._mesh.get_node("Motion") as CreatureMotion
		motion.set_physics_process(false)
		motion.phase = 0.0
		motion.idle_phase = 0.0
		motions.append(motion)
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 5.0
	camera.position = Vector3(2.6,3.2,10)
	camera.look_at(Vector3(2.6,0.6,0))
	camera.make_current()
	heading = Label.new()
	heading.position = Vector2(36,28)
	heading.add_theme_font_size_override("font_size",22)
	add_child(heading)
	for enemy in actors:
		var label := Label.new()
		label.text = enemy.display_name
		label.add_theme_font_size_override("font_size",18)
		label.size = Vector2(220,30)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = camera.unproject_position(enemy.position)+Vector2(-110,28)
		add_child(label)
	var note := Label.new()
	note.text = "Actual game meshes / fixed camera / sampled poses with AI paused\nMovement, wind-up and release are driven by live actors during gameplay."
	note.position = Vector2(36,630)
	note.add_theme_font_size_override("font_size",17)
	add_child(note)

func _process(_delta: float) -> void:
	if capturing:
		return
	capturing = true
	var stage := "Walk / trot / alternating tripod" if frame<24 else "Wind-up" if frame<36 else "Release and recovery" if frame<48 else "Frozen pose" if frame<60 else "Settled"
	heading.text = "WROUGHTWILD / CREATURE MOTION\n"+stage
	for i in motions.size():
		var motion := motions[i]
		if frame<24:
			motion.sample(1.0/12.0,0.13)
		elif frame<36:
			motion.sample(1.0/12.0,0.0,float(frame-24)/11.0)
		elif frame<48:
			if frame==36:
				actors[i].attack_released.emit("strike")
			motion.sample(1.0/12.0,0.0)
		elif frame<60:
			if frame==48:
				motion.sample(1.0/12.0,0.15,0.7)
			motion.sample(1.0/12.0,0.15,0.0,0.0,true)
		else:
			motion.sample(1.0/12.0,0.0)
	await RenderingServer.frame_post_draw
	var capture := get_viewport().get_texture().get_image()
	var error := capture.save_png(output.path_join("frame-%02d.png" % frame))
	if error!=OK:
		printerr("FAIL: motion capture ",error)
		get_tree().quit(1)
		return
	if frame==35:
		capture.save_png(output.path_join("windup.png"))
	if frame==36:
		capture.save_png(output.path_join("release.png"))
	frame += 1
	if frame==72:
		print("CODEX_CREATURE_MOTION_REVIEW 72 rendered frames, 12 fps playback, 6 seconds; AI paused")
		get_tree().quit()
	capturing = false
