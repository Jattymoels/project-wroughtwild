extends "res://tests/living_frontier_hosts.gd"
## Only releases through live Enemy physics and native player casts count here.

func _contact_cases() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(0,1,0)
	add_child(player)
	player.placement.set_physics_process(false)
	player.trial.set_process(false)
	sim = player.inventory.get_sim()
	pristine = sim.export_json()
	await frames(4)
	if "--hybrid-visuals" in OS.get_cmdline_user_args():
		await capture_pairing()
		return
	for ticks in [20,60]:
		Engine.physics_ticks_per_second = ticks
		for mode in ["stand","side","back","return","cover","hold_stagger","red_stagger","red_freeze","death"]:
			await pairing_contact(mode,ticks)
	Engine.physics_ticks_per_second = 60
	for class_id in ["warden","ranger","kindler"]:
		await combat_case(class_id,&"lf_paired_boar")
	var file := FileAccess.open("res://../build/lf5/hybrid.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":results},"  "))
	file.close()
	print("LF5_HYBRID ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func pairing_contact(mode: String,ticks: int) -> void:
	await reset_case()
	enemy = Enemy.spawn(self,&"lf_paired_boar",Vector3(0,.02,1.8))
	enemy.state = "chase"
	release_count = 0
	enemy.attack_released.connect(func(_kind: String): release_count += 1)
	for i in ticks:
		if enemy.state == "windup": break
		await frames(1)
	check(enemy.state == "windup","Blue hold begins")
	var held := enemy._held_position
	var before := player.combat.life
	var red_frames := 0
	var hold_frames := 0
	var recovery_frames := 0
	var wall: StaticBody3D
	var interrupted := false
	for step in ceili(3.3*ticks):
		var seconds := float(step)/ticks
		if enemy.state == "windup": hold_frames += 1
		if enemy.state == "release_warning":
			red_frames += 1
			check(release_count == 0,"Red warning precedes damage release")
		if enemy.state == "recover": recovery_frames += 1
		if mode in ["side","back"] and seconds >= 1.15:
			player.test_walk = Vector2(1,0) if mode == "side" else Vector2(0,-1)
		if mode == "return":
			player.test_walk = Vector2(1,0) if seconds < .5 else (Vector2(-1,0) if seconds < 1.0 else Vector2.ZERO)
		if mode == "cover" and wall == null and seconds >= 1.1:
			wall = StaticBody3D.new()
			var collision := CollisionShape3D.new()
			var shape := BoxShape3D.new()
			shape.size = Vector3(6,4,.2)
			collision.shape = shape
			wall.add_child(collision)
			wall.position = Vector3(0,2,.85)
			add_child(wall)
		if not interrupted and ((mode == "hold_stagger" and seconds >= .5) or (mode in ["red_stagger","red_freeze","death"] and seconds >= 1.2)):
			if mode == "red_freeze": enemy.apply_chill(100)
			elif mode == "death": enemy.take_typed(1000,"physical") # cancellation fixture only
			else: enemy.stagger(3)
			interrupted = true
		if is_instance_valid(enemy): check(enemy._held_position == held,"mark cannot follow movement")
		await frames(1)
		if not is_instance_valid(enemy): break
	var damage := before-player.combat.life
	if mode in ["stand","return"]: check(damage > 0 and damage <= 6.61,"staying / returning into held mark takes one native hit")
	else: check(damage == 0,"ordinary counterplay prevents contact: "+mode)
	check(release_count == (0 if interrupted else 1),"one release or complete cancellation")
	if not interrupted:
		check(hold_frames >= ticks-1 and red_frames >= ticks-1,"both full separate warning windows")
		check(recovery_frames >= ticks,"exposed recovery remains after release")
	results.append({"mode":mode,"ticks":ticks,"damage":damage,"releases":release_count,"blue_seconds":float(hold_frames)/ticks,"red_seconds":float(red_frames)/ticks,"recovery_seconds_observed":float(recovery_frames)/ticks,"forced_outcome":mode=="death"})
	print("LF5_CONTACT ",JSON.stringify(results.back()))
	player.test_walk = Vector2.ZERO
	if is_instance_valid(enemy): enemy.free()
	if wall != null: wall.free()
	await frames(3)

func capture_pairing() -> void:
	await reset_case()
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(30,.1,30)
	floor_mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("4a5142")
	floor_mesh.material_override = material
	floor_mesh.position.y = -.05
	add_child(floor_mesh)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-35,0)
	add_child(light)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("596570")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("bac6c8")
	environment.environment.ambient_light_energy = .65
	add_child(environment)
	player.look_at(Vector3(0,1,3))
	player.camera.rotation.x = -.25
	enemy = Enemy.spawn(self,&"lf_paired_boar",Vector3(0,.02,2.8))
	enemy.state = "chase"
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(6,5,7)
	camera.look_at(Vector3(0,.6,2))
	camera.current = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf5"))
	for phase in ["windup","release_warning","recover"]:
		for i in 240:
			if enemy.state == phase: break
			await frames(1)
		check(enemy.state == phase,"capture live "+phase)
		await frames(6)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../captures/lf5/hybrid-"+phase+".png")
	print("LF5_HYBRID_VISUALS ",checks," checks, ",failures," failures; live phases, unprotected player")
	get_tree().quit(1 if failures else 0)
