extends Node3D
## Focused actual-role wiring. Reuse the worker's exported deformation checks.
var checks := 0
var failures := 0
var strikes := 0
var player_actor: WroughtwildPlayer
var enemy: Enemy
var motion: CreatureMotion
var ram: RamPresentation

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL RAM NATIVE: ",label)

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
	await get_tree().process_frame

func stop(actor: Enemy) -> void:
	actor.set_physics_process(false)
	actor._mesh.get_node("Motion").set_physics_process(false)

func bones() -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for i in ram.rig.get_bone_count(): result.append(ram.rig.get_bone_pose(i))
	return result

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(100,1,100)
	shape.shape = box
	shape.position.y = -.5
	floor_body.add_child(shape)
	add_child(floor_body)
	player_actor = preload("res://scenes/player.tscn").instantiate()
	add_child(player_actor)
	player_actor.class_panel.choose("warden")
	for node in [player_actor,player_actor.combat,player_actor.placement,player_actor.spring_arm]: node.set_physics_process(false)
	player_actor.position = Vector3(0,1,-12)
	player_actor.hud.hide()
	enemy = Enemy.spawn(self,&"stone_husk",Vector3.ZERO)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	ram = motion.finished as RamPresentation
	check(ram != null and ram.rig.get_bone_count() == 23,"ordinary Stone Husk spawn selects fitted ram")
	if ram == null: get_tree().quit(1); return
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	check(enemy.verb == "guard" and enemy.max_life == sim.enemy("stone_husk").max_life and enemy.damage == sim.enemy("stone_husk").damage,"native identity, health and damage retained")
	check(is_equal_approx(enemy.move_speed,2.8) and is_equal_approx(enemy.attack_range,1.9) and is_equal_approx(enemy.windup_seconds,.6),"native locomotion, reach and attack tell unchanged")
	var capsule: CapsuleShape3D = enemy.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.radius,.35) and is_equal_approx(capsule.height,1.3),"native upright collision retained")
	check(ram.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL and enemy._mesh.get_child_count() == 1,"one manually sampled rig")
	check(is_equal_approx(ram.model.scale.x * enemy._mesh.scale.x,.85),"ram size compensates the humanoid reduction exactly once")
	check(ram.model.global_transform.basis.z.normalized().dot(-enemy.global_transform.basis.z.normalized()) > .999,"source forehead faces native guard direction")
	check(ram.material.get_shader_parameter("core_colour").is_equal_approx(Color(.57,.76,.91)),"approved ART06C colour bound directly")
	var part: MeshInstance3D = ram.model.get_node("RamRig/Skeleton3D/RamSkin")
	check(part.material_override == ram.material,"scar/status material reaches the actual RamSkin")
	enemy.rotation.y = .4
	var forward := -enemy.global_transform.basis.z.normalized()
	check(enemy.guards_against(enemy.position + forward * 2) and not enemy.guards_against(enemy.position - forward * 2),"native guard protects front, not rear")
	check(enemy.guards_against(enemy.position + forward.rotated(Vector3.UP,deg_to_rad(54)) * 2) and not enemy.guards_against(enemy.position + forward.rotated(Vector3.UP,deg_to_rad(56)) * 2),"native 110 degree guard boundary")
	enemy.state = "idle"
	motion.sample(.1,0)
	check(ram.pose == "idle","quiet native idle")
	enemy.state = "chase"
	motion.sample(.06,0)
	check(ram.pose == "guard" and not ram._rest_from.is_empty(),"stationary alert starts short brace blend")
	motion.sample(.08,0)
	check(ram.pose == "guard" and ram._rest_from.is_empty(),"brace blend finishes without a gameplay state")
	motion.sample(.1,.15)
	check(ram.pose == "walk" and is_equal_approx(ram.stride,.1),"moving alert uses gait and deliberate 1.5 metre cosmetic stride")
	enemy.state = "windup"
	motion.sample(.1,0,.5)
	check(ram.pose == "windup" and is_equal_approx(ram.player.current_animation_position,.3),"native windup fraction samples authored forehead tell")
	enemy.stagger(.3)
	motion.sample(.01,0,0,0,false,enemy.staggered())
	check(not enemy.guards_against(enemy.position + forward * 2) and enemy.state == "chase" and ram.pose == "idle","native stagger cancels guard eligibility and attack pose")
	enemy._stagger_left = 0
	check(enemy.guards_against(enemy.position + forward * 2),"native guard returns on stagger expiry")
	enemy.attack_released.connect(func(kind: String):
		if kind == "strike": strikes += 1)
	enemy.rotation = Vector3.ZERO
	enemy.state = "windup"
	enemy._windup_left = .001
	player_actor.position = Vector3(0,1,-1.5)
	enemy.set_physics_process(true)
	await frames(2)
	stop(enemy)
	check(strikes == 1 and motion.release_left > 0,"actual native melee event starts one cosmetic recovery")
	motion.sample(.11,0)
	motion.sample(0,0)
	check(ram.pose == "release" and is_equal_approx(ram.player.current_animation_position,.16),"full authored strike resampled into existing .22 second window")
	var held := bones()
	enemy.apply_chill(10000)
	motion.sample(.1,0,0,0,true,false)
	check(bones() == held and motion.release_left == 0,"freeze holds exact bones and cancels follow-through")
	check(ram.material.get_shader_parameter("status_active"),"native freeze takes priority over ambient scars")
	enemy.thaw()
	enemy._refresh_look()
	motion.sample(.01,0)
	check(not ram.material.get_shader_parameter("status_active"),"expired native status restores scar material")
	var prior_clock := ram.clock
	motion.set_physics_process(true)
	get_tree().paused = true
	for i in 3: await get_tree().process_frame
	check(ram.clock == prior_clock,"pause holds cosmetic clock")
	get_tree().paused = false
	stop(enemy)
	enemy.configure(sim)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	ram = motion.finished
	check(motion.release_left == 0 and enemy.attack_released.get_connections().size() == 2,"rebind has one motion observer plus fixture observer")
	player_actor.position = Vector3(0,1,-12)
	enemy.position = Vector3.ZERO
	enemy.state = "chase"
	motion.set_physics_process(true)
	enemy.set_physics_process(true)
	await frames(20)
	check(enemy.position.length() > .1 and ram.stride > 0 and ram.pose == "walk","real pursuit keeps moving with the ram gait")
	stop(enemy)
	if "--ram-capture" in OS.get_cmdline_user_args(): await capture()
	var death_clock := ram.clock
	enemy.take_damage(enemy.max_life*2)
	motion.sample(.1,1)
	check(ram.clock == death_clock and motion.release_left == 0,"native death stops sampling and clears release")
	await frames(1)
	check(not is_instance_valid(enemy),"native death removes actor and rig")
	print("RAM_NATIVE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func capture() -> void:
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and get_window().unfocusable,"capture keeps pointer visible and window unfocusable")
	player_actor.hide()
	enemy._label.hide()
	enemy._label.set_process(false)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(100,100)
	ground.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("58624e")
	ground.material_override = mat
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-32,0)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("879da6")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("bbcbd8")
	env.environment.ambient_light_energy = .7
	add_child(env)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = enemy.position + Vector3(3.2,2.1,-3.8)
	camera.look_at(enemy.position + Vector3(0,.8,0))
	camera.current = true
	await frames(3)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_environment("WROUGHTWILD_RAM_OUTPUT") + "/native-ram.png")
