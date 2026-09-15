extends Node3D
## Focused native recruitment/pose wiring. Source deformation evidence is reused.
var checks := 0
var failures := 0
var calls := 0
var effect_before_observer := false
var player_actor: WroughtwildPlayer
var enemy: Enemy
var motion: CreatureMotion
var crane: CranePresentation

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL CRANE NATIVE: ", label)

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
	await get_tree().process_frame

func stop(actor: Enemy) -> void:
	actor.set_physics_process(false)
	actor._mesh.get_node("Motion").set_physics_process(false)

func bones(presentation: CranePresentation) -> Array[Transform3D]:
	var result: Array[Transform3D] = []
	for i in presentation.rig.get_bone_count(): result.append(presentation.rig.get_bone_pose(i))
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
	enemy = Enemy.spawn(self,&"shrieker",Vector3.ZERO)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	crane = motion.finished as CranePresentation
	check(crane != null and crane.rig.get_bone_count() == 16,"normal Shrieker spawn selects exported crane")
	if crane == null: get_tree().quit(1); return
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	check(enemy.verb == "recruit" and enemy.max_life == sim.enemy("shrieker").max_life and enemy.damage == sim.enemy("shrieker").damage,"native identity and combat numbers retained")
	check(enemy._scream_period == sim.realtime().behaviours.shrieker.scream_period_seconds,"existing native call period")
	var radius := enemy._scream_radius
	var capsule: CapsuleShape3D = enemy.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.radius,.35) and is_equal_approx(capsule.height,1.3),"unchanged native collider")
	check(crane.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL and enemy._mesh.get_child_count() == 1,"one rig and manually sampled pose driver")
	check(is_equal_approx(crane.fit_scale,.8) and is_equal_approx(crane.settings.stride_m,.6133333333333334),"descriptor fit and actual-travel stride")
	check(crane.material.get_shader_parameter("core_colour").is_equal_approx(Color(.32,.71,.76)),"direct ART06C colour parameter")
	var nearby := Enemy.spawn(self,&"ember_whelp",Vector3(3,0,0))
	var outside := Enemy.spawn(self,&"ember_whelp",Vector3(radius+3,0,0))
	var dead := Enemy.spawn(self,&"ember_whelp",Vector3(-3,0,0))
	var busy := Enemy.spawn(self,&"ember_whelp",Vector3(0,0,4))
	for actor in [nearby,outside,dead,busy]: stop(actor)
	dead.life = 0
	busy.state = "recover"
	var recruit_ref: WeakRef = weakref(nearby)
	enemy.recruitment_called.connect(func():
		calls += 1
		var recruit: Enemy = recruit_ref.get_ref()
		effect_before_observer = is_instance_valid(recruit) and recruit.state == "chase" and enemy._scream_timer == enemy._scream_period)
	MobGrid.reset()
	for actor in [enemy,nearby,outside,dead,busy]: MobGrid.register(actor)
	enemy.force_scream()
	check(calls == 1 and crane.call_age == 0 and effect_before_observer,"one observer after actual native recruitment and timer reset")
	check(nearby.state == "chase" and outside.state == "idle" and dead.state == "idle" and busy.state == "recover","native recruitment keeps radius, life and idle eligibility")
	check(enemy._scream_radius == radius,"visual observer leaves native radius unchanged")
	var second := Enemy.spawn(self,&"shrieker",Vector3(9,0,0))
	stop(second)
	var other := (second._mesh.get_node("Motion") as CreatureMotion).finished as CranePresentation
	check(other.rig != crane.rig and other.material != crane.material and other.call_age < 0,"independent pose, material and call state")
	check(crane.model.get_node("CraneRig/Skeleton3D/CraneBody").mesh == other.model.get_node("CraneRig/Skeleton3D/CraneBody").mesh,"shared exported mesh resource")
	enemy.state = "chase"
	second.state = "chase"
	crane.sample(.25,.12,0,false,false,0)
	other.sample(.25,.12,0,false,false,0)
	var upper := ["neck","upper_neck","head","jaw","resonator"]
	var untouched := true
	var upper_changed := false
	for i in crane.rig.get_bone_count():
		var same := crane.rig.get_bone_pose(i).is_equal_approx(other.rig.get_bone_pose(i))
		if crane.rig.get_bone_name(i) in upper: upper_changed = upper_changed or not same
		else: untouched = untouched and same
	check(crane.pose == "walk" and crane.call_visible and upper_changed,"call articulates upper body over a walking base")
	check(untouched,"call leaves all non-call bones exactly on the locomotion pose")
	var before := bones(crane)
	crane.sample(.1,0,0,true,false,0)
	check(bones(crane) == before,"freeze holds exact layered pose")
	crane.sample(.01,0,0,false,true,0)
	check(crane.call_age < 0 and crane.peck_age < 0 and crane.pose == "idle","stagger cancels transient poses")
	enemy.force_scream()
	enemy.state = "windup"
	crane.sample(.2,0,.5,false,false,0)
	check(crane.pose == "windup" and not crane.call_visible,"native melee tell takes precedence over call")
	crane.sample(1.3,0,1,false,false,0)
	enemy.state = "chase"
	crane.sample(.01,0,0,false,false,0)
	check(crane.call_age < 0 and not crane.call_visible,"suppressed call expires without replay")
	var call_count := calls
	enemy.state = "windup"
	enemy._windup_left = .001
	enemy._scream_timer = 100
	player_actor.position = Vector3(0,1,-1.5)
	enemy.set_physics_process(true)
	await frames(2)
	stop(enemy)
	check(crane.peck_age >= 0 and calls == call_count,"actual melee release starts peck but never recruitment")
	crane.sample(.15,0,0,false,false,0)
	check(crane.pose == "release" and not crane.call_visible,"peck uses its authored release clip")
	enemy.apply_chill(10000)
	crane.sample(.01,0,0,true,false,0)
	check(crane.material.get_shader_parameter("status_active"),"native freeze suppresses ambient scar light")
	enemy.thaw()
	enemy._refresh_look()
	crane.sample(.01,0,0,false,true,0)
	check(not crane.material.get_shader_parameter("status_active"),"expired native status restores material")
	var prior_clock := crane.clock
	motion.set_physics_process(true)
	get_tree().paused = true
	for i in 3: await get_tree().process_frame
	check(crane.clock == prior_clock,"tree pause holds visual clock")
	get_tree().paused = false
	stop(enemy)
	enemy.configure(sim)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	crane = motion.finished
	check(crane.call_age < 0 and enemy.recruitment_called.get_connections().size() == 2 and enemy.attack_released.get_connections().size() == 2,"rebind resets visual state without duplicate callbacks")
	# One actual native timer call while the actor moves; captures show this wiring.
	for actor in [nearby,outside,dead,busy,second]: actor.queue_free()
	player_actor.position = Vector3(0,1,-12)
	enemy.position = Vector3.ZERO
	enemy.state = "chase"
	enemy._scream_timer = .1
	var timer_calls := calls
	motion.set_physics_process(true)
	enemy.set_physics_process(true)
	await frames(20)
	check(calls == timer_calls+1 and enemy._scream_timer > 0,"native timer emits exactly one call at its ordinary effect")
	check(enemy.position.length() > .1 and crane.stride > 0 and crane.pose == "walk" and crane.call_visible,"actual moving actor retains gait during the native call")
	if "--crane-capture" in OS.get_cmdline_user_args(): await capture()
	stop(enemy)
	var death_clock := crane.clock
	enemy.take_damage(enemy.max_life*2)
	crane.sample(.1,1,0,false,false,0)
	check(crane.clock == death_clock and crane.call_age < 0 and crane.peck_age < 0,"native death clears transient call and stops sampling")
	await frames(1)
	check(not is_instance_valid(enemy),"native death removes actor and presentation")
	print("CRANE_NATIVE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func capture() -> void:
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and get_window().unfocusable,"capture leaves mouse visible and window unfocusable")
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
	get_viewport().get_texture().get_image().save_png(OS.get_environment("WROUGHTWILD_CRANE_OUTPUT") + "/native-moving-call.png")
