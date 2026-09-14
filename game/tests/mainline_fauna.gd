extends Node3D
## One actual-actor fixture: native motion/status/tells and one optional capture.
var checks := 0
var failures := 0
var actors: Array[Enemy] = []
var player: WroughtwildPlayer
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL A2: ", label)
func poses(motion: CreatureMotion) -> Array:
	var result := []
	for i in motion.rig.get_bone_count(): result.append(motion.rig.get_bone_pose(i))
	return result
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	var ground := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100, 1, 100)
	shape.shape = box
	shape.position.y = -0.5
	ground.add_child(shape)
	add_child(ground)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100,100)
	floor_mesh.mesh = plane
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("505c4b")
	floor_mesh.material_override = paint
	add_child(floor_mesh)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	player.position = Vector3(0,0,30)
	player.hud.hide()
	if "--a2-capture-only" in OS.get_cmdline_user_args():
		for id in ["ember_whelp","ash_hound","valley_elk"]:
			var enemy := Enemy.spawn(self,StringName(id),Vector3(actors.size()*3,0,0))
			enemy.set_physics_process(false)
			actors.append(enemy)
		await capture()
		print("A2_CAPTURE %d checks, %d failures" % [checks,failures])
		get_tree().quit(0 if failures == 0 else 1)
		return
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	for id in ["ember_whelp","ash_hound","valley_elk","lf_red_boar","lf_blue_boar","lf_paired_boar","lf_white_stag","marsh_wisp","cinder_wisp","lf_green_moth"]:
		var enemy := Enemy.spawn(self,StringName(id),Vector3(actors.size()*4-4,0.1,0))
		actors.append(enemy)
		var motion := enemy._mesh.get_node("Motion") as CreatureMotion
		var moth: bool = "wisp" in id or id == "lf_green_moth"
		check((motion.finished == null) == moth, id + " selects finished family or retained moth")
		check(is_equal_approx(enemy.get_node("CollisionShape3D").shape.radius, 0.35), id + " keeps native capsule")
		check(enemy.damage == sim.enemy(id).damage and enemy.max_life == sim.enemy(id).max_life, id + " retains native numbers")
		if not moth:
			check(motion.rig.get_bone_count() in [16,17], id + " loads delivered skin")
			check(motion.finished.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL, id + " clips have no independent clock")
			enemy.stop_roaming()
			enemy.roam_to(enemy.position + Vector3(0,0,-3))
	var starts := []
	for enemy in actors: starts.append(enemy.position)
	await frames(60)
	for i in 3:
		var enemy := actors[i]
		var motion := enemy._mesh.get_node("Motion") as CreatureMotion
		check(enemy.position.distance_to(starts[i]) > 0.1 and motion.finished.stride > 0.0, String(enemy.enemy_id) + " native travel drives walk")
		print("A2_FIT ", enemy.enemy_id, " ", motion.finished.fit_scale)
	for enemy in actors:
		enemy.stop_roaming()
		enemy.set_physics_process(false)
	var boar := actors[3]
	var motion := boar._mesh.get_node("Motion") as CreatureMotion
	var look := boar.get_node("FrontierHostLook") as FrontierHostLook
	player.position = boar.position + Vector3(0,0,-1.5)
	boar.set_physics_process(true)
	for i in 100:
		await frames(1)
		if boar.state == "windup": break
	await frames(2)
	check(boar.state == "windup" and look.tell.visible and motion.finished.pose == "windup", "native attack exposes matching clip and existing tell")
	var remaining := boar._windup_left
	var release_tick := -1
	for i in 120:
		await frames(1)
		if boar.state == "release":
			release_tick = i+1
			break
	check(release_tick > 0 and absf(release_tick/60.0-remaining) < 0.04, "native release follows unchanged remaining windup")
	check(motion.finished.pose == "release" and not look.tell.visible, "release clip follows actual charge")
	boar.set_physics_process(false)
	boar.apply_chill(10000)
	motion._physics_process(0.016)
	var held := poses(motion)
	motion._physics_process(0.1)
	check(boar.is_frozen() and poses(motion) == held, "native freeze holds exact pose")
	check(motion.finished.material.get_shader_parameter("status_active"), "ice overrides scar light")
	boar.thaw()
	boar.stagger(1.0)
	motion._physics_process(0.016)
	check(motion.release_left == 0.0 and motion.finished.pose == "idle", "native stagger cancels presentation follow-through")
	boar._stagger_left = 0.0
	boar.apply_ignite(10000)
	boar.apply_bleed(10000)
	boar.take_damage(1)
	motion._physics_process(0.016)
	check(motion.finished.material.get_shader_parameter("status_emission") == boar._material.emission * boar._material.emission_energy_multiplier, "hit emission wins over burn and bleed")
	boar._flash_left = 0.0
	boar._refresh_look()
	motion._physics_process(0.016)
	check(motion.finished.material.get_shader_parameter("status_active") and boar.burning_left > 0, "burn wins over bleed and scars")
	boar.burning_left = 0.0
	boar._refresh_look()
	motion._physics_process(0.016)
	check(motion.finished.material.get_shader_parameter("status_active") and motion.finished.material.get_shader_parameter("status_emission") == Color.BLACK, "bleed suppresses cosmetic emission")
	boar.bleeding_left = 0.0
	boar._refresh_look()
	motion._physics_process(0.016)
	check(not motion.finished.material.get_shader_parameter("status_active"), "expired statuses restore local scars")
	var other := actors[0]._mesh.get_node("Motion") as CreatureMotion
	check(other.finished.material != motion.finished.material and other.rig != motion.rig, "individual materials and poses")
	var a: MeshInstance3D = other.finished.model.find_children("*","MeshInstance3D",true,false)[0]
	var b: MeshInstance3D = motion.finished.model.find_children("*","MeshInstance3D",true,false)[0]
	check(a.mesh == b.mesh and other.finished.material.get_shader_parameter("base_texture") == motion.finished.material.get_shader_parameter("base_texture"), "mesh and textures shared")
	var before := motion.finished.clock
	get_tree().paused = true
	for i in 3: await get_tree().process_frame
	check(motion.finished.clock == before, "pause stops cosmetic clock")
	get_tree().paused = false
	var stag := actors[2]
	player.position = stag.position + Vector3(0,0,-2)
	stag.set_physics_process(true)
	await frames(20)
	check(stag.flees and stag.state == "flee" and stag._windup_left == 0.0, "stag flees without attacking")
	stag.set_physics_process(false)
	boar.configure(sim)
	check(boar._mesh.get_child_count() == 1 and boar.attack_released.get_connections().size() == 1, "reconfigure leaves one visual and one release hook")
	if "--a2-capture" in OS.get_cmdline_user_args(): await capture()
	for enemy in actors: enemy.free()
	player.free()
	print("A2_ACTORS %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
func capture() -> void:
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and get_window().unfocusable, "capture leaves pointer free and window unfocusable")
	player.hide()
	for i in actors.size():
		var enemy := actors[i]
		enemy.position = Vector3((i-1)*3,0,0)
		enemy.rotation = Vector3.ZERO
		if i >= 3: enemy.hide()
		enemy._label.hide()
		enemy.state = "idle"
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(3.8,2.7,-8)
	camera.look_at(Vector3(0,0.7,0))
	camera.current = true
	camera.fov = 48
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-45,-25,0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	var sky := WorldEnvironment.new()
	sky.environment = Environment.new()
	sky.environment.background_mode = Environment.BG_COLOR
	sky.environment.background_color = Color("7e9194")
	sky.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	sky.environment.ambient_light_color = Color("c0ccdb")
	sky.environment.ambient_light_energy = 0.6
	add_child(sky)
	await frames(12)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../build/a2/fauna.png")
