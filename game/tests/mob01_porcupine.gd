extends Node3D
## Focused native Cinder Archer fixture. No presentation code launches attacks.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var enemy: Enemy
var motion: CreatureMotion
var released := 0
var captures := false
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL MOB01: ",label)
func frames(n: int) -> void:
	for i in n: await get_tree().physics_frame
func poses() -> Array:
	var out := []
	for i in motion.rig.get_bone_count(): out.append(motion.rig.get_bone_pose(i))
	return out
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	captures = "--mob01-capture" in OS.get_cmdline_user_args()
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100,1,100)
	shape.shape = box
	shape.position.y = -0.5
	floor_body.add_child(shape)
	add_child(floor_body)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100,100)
	ground.mesh = plane
	var paint := StandardMaterial3D.new()
	paint.albedo_color = Color("555d43")
	ground.material_override = paint
	add_child(ground)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	for node in [player,player.combat,player.placement,player.spring_arm]: node.set_physics_process(false)
	player.position = Vector3(0,1,30)
	player.hud.hide()
	enemy = Enemy.spawn(self,&"cinder_archer",Vector3.ZERO)
	motion = enemy._mesh.get_node("Motion")
	enemy.attack_released.connect(func(_kind: String): released += 1)
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	check(motion.finished is PorcupinePresentation and motion.rig.get_bone_count() == 17,"normal spawn selects fitted porcupine")
	check(enemy.behaviour == "ranged" and enemy.verb == "mark" and enemy.max_life == sim.enemy("cinder_archer").max_life and enemy.damage == sim.enemy("cinder_archer").damage,"native ranged identity and numbers")
	check(enemy.projectile_rules == sim.realtime().behaviours.ranged.projectile and enemy.windup_seconds == sim.realtime().behaviours.ranged.windup_seconds,"native muzzle, speed, radius, range and windup retained")
	var capsule: CapsuleShape3D = enemy.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.radius,0.35) and is_equal_approx(capsule.height,1.3),"original upright collision body")
	check(motion.finished.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL,"one manually sampled clip driver")
	check(motion.finished.player.has_animation("idle") and motion.finished.player.has_animation("walk") and motion.finished.player.has_animation("windup") and motion.finished.player.has_animation("release"),"four imported clips")
	var hosts := 0
	for part: MeshInstance3D in motion.finished.model.find_children("*","MeshInstance3D",true,false):
		if part.material_override == motion.finished.material: hosts += 1
	check(hosts == 1 and (motion.finished as PorcupinePresentation).face_materials.size() == 12,"only host uses ART06C scar; twelve fitted face parts")
	for face: StandardMaterial3D in (motion.finished as PorcupinePresentation).face_materials: check(not face.emission_enabled,"face attachment never emits")
	await frames(3)
	if captures: await setup_camera()
	var start := enemy.position
	enemy.roam_to(start + Vector3(0,0,-2))
	await frames(25)
	check(enemy.position.distance_to(start) > 0.15 and motion.finished.stride > 0 and motion.finished.pose == "walk","actual native roam drives walk")
	enemy.stop_roaming()
	enemy.position = Vector3.ZERO
	enemy.rotation = Vector3.ZERO
	player.position = Vector3(0,1,-7)
	for i in 100:
		await frames(1)
		if enemy.state == "windup": break
	await frames(1)
	check(enemy.state == "windup" and motion.finished.pose == "windup" and enemy._shot_tell.visible,"committed tell and brace follow native windup")
	var aim := enemy._shot_aim
	var left := enemy._windup_left
	var count := released
	player.position.x = 3
	var ticks := 0
	while released == count and ticks < 90:
		await frames(1)
		ticks += 1
	check(released == count+1 and absf(ticks/60.0-left) < 0.045,"one native release at committed windup boundary")
	check(enemy._shot_aim == aim and motion.finished.pose == "release","aim stays committed when player sidesteps; signal starts recoil")
	var shots := get_tree().get_nodes_in_group("enemy_projectiles")
	check(shots.size() == 1,"one projectile; animation does not add a volley")
	if shots.size() == 1:
		var shot: EnemyProjectile = shots[0]
		var origin := enemy.global_position + Vector3.UP * float(enemy.projectile_rules.muzzle_height_m)
		check(shot.direction.dot(origin.direction_to(aim)) > 0.9999 and shot.speed == float(enemy.projectile_rules.speed_mps),"native committed straight shot direction and speed")
		check(shot.global_position.distance_to(origin) < 0.65,"shot originates at native shoulder-height muzzle")
	enemy.set_physics_process(false)
	await frames(35)
	check(not player.combat.marked(),"clear lateral sidestep avoids the existing mark")
	var cover := StaticBody3D.new()
	var cover_shape := CollisionShape3D.new()
	var cover_box := BoxShape3D.new()
	cover_box.size = Vector3(6,3,.5)
	cover_shape.shape = cover_box
	cover.add_child(cover_shape)
	add_child(cover)
	cover.position = Vector3(0,1,-2)
	await frames(2)
	check(not enemy._attack_line_clear(player),"actual native sphere clearance respects solid cover")
	var cover_shot := EnemyProjectile.launch(enemy,player.global_position,enemy.projectile_rules)
	await frames(30)
	check(not is_instance_valid(cover_shot),"existing projectile stops at physical cover")
	cover.queue_free()
	enemy.apply_chill(10000)
	motion._physics_process(.016)
	var held := poses()
	motion._physics_process(.1)
	check(enemy.is_frozen() and poses() == held,"freeze holds exact bone pose")
	check(motion.finished.material.get_shader_parameter("status_active"),"frozen surface suppresses ambient scars")
	enemy.thaw()
	enemy.stagger(1)
	motion._physics_process(.016)
	check(motion.release_left == 0 and motion.finished.pose == "idle","stagger cancels recoil")
	enemy._stagger_left = 0
	enemy.apply_ignite(10000)
	enemy.apply_bleed(10000)
	enemy.take_damage(1)
	motion._physics_process(.016)
	check(motion.finished.material.get_shader_parameter("status_emission") == enemy._material.emission * enemy._material.emission_energy_multiplier,"hit priority over burn, bleed and scars")
	enemy._flash_left = 0
	enemy._refresh_look()
	motion._physics_process(.016)
	check(motion.finished.material.get_shader_parameter("status_active") and enemy.burning_left > 0,"burn overrides scar light")
	enemy.burning_left = 0
	enemy._refresh_look()
	motion._physics_process(.016)
	check(motion.finished.material.get_shader_parameter("status_active") and motion.finished.material.get_shader_parameter("status_emission") == Color.BLACK,"bleed suppresses scar emission")
	enemy.bleeding_left = 0
	enemy._refresh_look()
	motion._physics_process(.016)
	check(not motion.finished.material.get_shader_parameter("status_active"),"expired statuses restore connected pulse")
	var other := Enemy.spawn(self,&"cinder_archer",Vector3(8,0,0))
	other.set_physics_process(false)
	var other_motion: CreatureMotion = other._mesh.get_node("Motion")
	var part_a: MeshInstance3D = motion.finished.model.find_children("*runtime*","MeshInstance3D",true,false)[0]
	var part_b: MeshInstance3D = other_motion.finished.model.find_children("*runtime*","MeshInstance3D",true,false)[0]
	check(part_a.mesh == part_b.mesh and motion.finished.material.get_shader_parameter("base_texture") == other_motion.finished.material.get_shader_parameter("base_texture"),"meshes and textures shared")
	check(motion.rig != other_motion.rig and motion.finished.material != other_motion.finished.material,"actor poses and scar/status material independent")
	var before := motion.finished.clock
	get_tree().paused = true
	for i in 3: await get_tree().process_frame
	check(motion.finished.clock == before,"pause freezes ambient clock and driver")
	get_tree().paused = false
	other.queue_free()
	var boar := Enemy.spawn(self,&"ember_whelp",Vector3(-8,0,0))
	var boar_motion: CreatureMotion = boar._mesh.get_node("Motion")
	check(boar_motion.finished != null and not boar_motion.finished is PorcupinePresentation and boar_motion.rig.get_bone_count() in [16,17],"shared dispatch still selects finished A2 boar")
	boar.queue_free()
	if captures: await capture_motion()
	enemy.configure(sim)
	check(enemy._mesh.get_child_count() == 1 and enemy.attack_released.get_connections().size() == 2,"reconfigure leaves one visual and release hook plus fixture observer")
	print("MOB01_ACTORS %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func setup_camera() -> void:
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and get_window().unfocusable,"rendered fixture leaves pointer visible and window unfocusable")
	player.hide()
	enemy._label.hide()
	enemy._label.set_process(false)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(4.4,2.7,-5.2)
	camera.look_at(Vector3(0,.7,-.35))
	camera.fov = 45
	camera.current = true
	var sun := DirectionalLight3D.new()
	add_child(sun)
	sun.rotation_degrees = Vector3(-42,-32,0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("899899")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("bbcbd8")
	environment.environment.ambient_light_energy = .65
	add_child(environment)
	var fill := DirectionalLight3D.new()
	add_child(fill)
	fill.rotation_degrees = Vector3(-30,145,0)
	fill.light_energy = 0.85
	await frames(6)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("res://../build/mob01/porcupine-idle.png")

func capture_motion() -> void:
	# Scripted route; actual Enemy movement, commitment and release drive every frame.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../build/mob01/frames"))
	enemy.position = Vector3(0,0,.5)
	enemy.rotation = Vector3.ZERO
	enemy.state = "idle"
	player.position = Vector3(0,1,30)
	enemy.set_physics_process(true)
	enemy.roam_to(Vector3(0,0,-1.5))
	for i in 100:
		if i == 35:
			enemy.stop_roaming()
			player.position = enemy.position + Vector3(0,1,-7)
			enemy._attack_cooldown = 0.0
		await frames(2)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../build/mob01/frames/%03d.png" % i)
		if enemy.state == "windup" and enemy._windup_left < .18:
			get_viewport().get_texture().get_image().save_png("res://../build/mob01/porcupine-brace.png")
	enemy.set_physics_process(false)
