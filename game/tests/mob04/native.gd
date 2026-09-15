extends Node3D
## Focused native swarm/contact/interrupt checks and one Forward+ motion capture.
var checks := 0
var failures := 0
var labels: Dictionary = {}
var strikes := 0
var player_actor: WroughtwildPlayer
var enemy: Enemy
var motion: CreatureMotion
var beetle: BeetlePresentation
var output: String
func check(ok: bool, label: String) -> void:
	checks += 1
	labels[label] = ok
	if not ok:
		failures += 1
		printerr("FAIL BEETLE NATIVE: ", label)
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
	await get_tree().process_frame
func stop(actor: Enemy) -> void:
	actor.set_physics_process(false)
	actor._mesh.get_node("Motion").set_physics_process(false)
func bones(presentation: FinishedFauna = null) -> Array[Transform3D]:
	if presentation == null: presentation = beetle
	var result: Array[Transform3D] = []
	for i in presentation.rig.get_bone_count(): result.append(presentation.rig.get_bone_pose(i))
	return result
func _ready() -> void: _run.call_deferred()
func strike() -> void:
	enemy.state = "windup"
	enemy._windup_left = .001
	enemy.set_physics_process(true)
	await frames(2)
	stop(enemy)
func _run() -> void:
	output = OS.get_environment("WROUGHTWILD_BEETLE_OUTPUT")
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
	enemy = Enemy.spawn(self,&"gloom_crawler",Vector3.ZERO)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	beetle = motion.finished as BeetlePresentation
	check(beetle != null and beetle.rig.get_bone_count() == 25,"ordinary Gloom Crawler selects 25-bone beetle")
	if beetle == null: get_tree().quit(1); return
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	check(enemy.behaviour == "swarm" and enemy.verb == "swarm" and enemy.max_life == sim.enemy("gloom_crawler").max_life and enemy.damage == sim.enemy("gloom_crawler").damage,"native swarm identity, life and damage")
	check(is_equal_approx(enemy.move_speed,5) and is_equal_approx(enemy.attack_range,1.5) and is_equal_approx(enemy.windup_seconds,.25) and enemy.windup_advance == 0,"native speed, range and stationary quarter-second windup")
	var capsule: CapsuleShape3D = enemy.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.radius,.35) and is_equal_approx(capsule.height,1.3),"native upright collider retained")
	check(beetle.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL and enemy._mesh.get_child_count() == 1,"one manual animation driver")
	check(beetle.model.scale.is_equal_approx(Vector3.ONE*.72) and enemy._mesh.scale.is_equal_approx(Vector3.ONE),"uniform beetle fit without humanoid reduction")
	check(beetle.model.global_transform.basis.z.normalized().dot(enemy.global_transform.basis.z.normalized()) > .999,"source +Y exports to native -Z forward")
	check(beetle.material.get_shader_parameter("core_colour").is_equal_approx(Color(.26,.54,.62)),"selected ART06C beetle palette")
	check(beetle.material.get_shader_parameter("damage_tint").is_equal_approx(Vector3(.16,.14,.12)),"texture-preserving damage tint")
	var part: MeshInstance3D = beetle.model.get_node("BeetleRig/Skeleton3D/BeetleSkin")
	var arrays := part.mesh.surface_get_arrays(0)
	check(part.material_override == beetle.material and arrays[Mesh.ARRAY_INDEX].size()/3 == 79997,"selected skinned runtime surface and triangle count")
	for kind: String in ["base","orm","scar"]:
		check(beetle.material.get_shader_parameter(kind+"_texture") is Texture2D,"retained " + kind + " texture imported")
	check(is_equal_approx(enemy.swarm_multiplier(),1) and is_equal_approx(enemy.bite_damage(),enemy.damage),"lone crawler native bite")
	var peers: Array[Enemy] = []
	for i in 5:
		var other := Enemy.spawn(self,&"gloom_crawler",Vector3(2+i*.2,0,0))
		stop(other)
		peers.append(other)
		check(is_equal_approx(enemy.bite_damage(),enemy.damage*(1+minf(.6,.15*(i+1)))),"living swarm count %d changes native bite up to cap" % (i+1))
	for other in peers: other.position = Vector3(12,0,0)
	peers[0].position = Vector3(4,0,0)
	check(is_equal_approx(enemy.swarm_multiplier(),1.15),"four-metre inclusive native swarm radius")
	peers[0].position.x = 4.01
	check(is_equal_approx(enemy.swarm_multiplier(),1),"outside native swarm radius excluded")
	peers[0].position = Vector3(3,0,0)
	peers[0].life = 0
	check(is_equal_approx(enemy.swarm_multiplier(),1),"dead neighbour excluded")
	peers[0].life = peers[0].max_life
	peers[0].stagger(.5)
	check(is_equal_approx(enemy.swarm_multiplier(),1.15),"living staggered neighbour still follows native eligibility")
	peers[1].position = Vector3(3,0,0)
	peers[1].verb = "none"
	check(is_equal_approx(enemy.swarm_multiplier(),1.15),"non-swarm neighbour excluded")
	var other_beetle := peers[0]._mesh.get_node("Motion").finished as BeetlePresentation
	var other_bones := bones(other_beetle)
	var other_clock := other_beetle.clock
	check(beetle.material != other_beetle.material and beetle.rig != other_beetle.rig and part.mesh == other_beetle.model.get_node("BeetleRig/Skeleton3D/BeetleSkin").mesh,"independent pose/material with shared mesh")
	enemy.state = "chase"
	var prior_stride := beetle.stride
	motion.sample(.1,.2)
	check(beetle.pose == "walk" and is_equal_approx(beetle.stride-prior_stride,.2),"distance drives one-metre insect cadence")
	check(bones(other_beetle) == other_bones and other_beetle.clock == other_clock,"sampling one instance leaves another unchanged")
	enemy.state = "windup"
	motion.sample(.1,0,.5)
	check(beetle.pose == "windup" and is_equal_approx(beetle.player.current_animation_position,.125),"native normalized windup samples mandibular brace")
	enemy.stagger(.3)
	motion.sample(.01,0,0,0,false,enemy.staggered())
	check(enemy.state == "chase" and beetle.pose == "idle" and motion.release_left == 0,"stagger interrupts anticipation")
	enemy._stagger_left = 0
	enemy.attack_released.connect(func(kind: String):
		if kind == "strike": strikes += 1)
	player_actor.position = Vector3(0,1,-1.3)
	player_actor.combat._ensure_fight()
	var before_life := player_actor.combat.life
	sim.begin_fight(404)
	var expected := sim.enemy_hit_damage(enemy.bite_damage(),enemy.bite_type(),player_actor.combat.cast_armour()+player_actor.combat.still_armour())
	sim.begin_fight(404)
	await strike()
	check(strikes == 1 and motion.release_left > 0,"one actual native strike starts cosmetic recovery")
	check(is_equal_approx(before_life-player_actor.combat.life,expected),"authoritative release deals the swarm-scaled native mitigated hit: got %.6f expected %.6f invulnerable %.3f" % [before_life-player_actor.combat.life,expected,player_actor.combat.invulnerable_left])
	motion.sample(.11,0)
	motion.sample(0,0)
	check(beetle.pose == "release" and is_equal_approx(beetle.player.current_animation_position,.1125),"release samples existing cosmetic window at authored 40Hz duration")
	var held := bones()
	enemy.apply_chill(10000)
	motion.sample(.1,0,0,0,true,false)
	check(bones() == held and motion.release_left == 0,"freeze holds exact pose and clears follow-through")
	check(beetle.material.get_shader_parameter("status_active"),"native freeze overrides scars")
	enemy.thaw()
	enemy._refresh_look()
	motion.sample(.01,0)
	check(not beetle.material.get_shader_parameter("status_active"),"thaw restores scar material")
	var prior_clock := beetle.clock
	motion.set_physics_process(true)
	get_tree().paused = true
	for i in 3: await get_tree().process_frame
	check(beetle.clock == prior_clock,"pause holds ambient pulse and animation")
	get_tree().paused = false
	stop(enemy)
	before_life = player_actor.combat.life
	player_actor.position = Vector3(0,1,-3)
	await strike()
	check(strikes == 2 and player_actor.combat.life == before_life,"native out-of-reach release deals no hit")
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(3,3,.15)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0,1,-.65)
	add_child(wall)
	player_actor.position = Vector3(0,1,-1.3)
	await frames(2)
	await strike()
	check(strikes == 3 and player_actor.combat.life == before_life,"native solid cover blocks contact")
	wall.queue_free()
	for other in peers: other.queue_free()
	await frames(1)
	enemy.configure(sim)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	beetle = motion.finished
	check(motion.release_left == 0 and enemy.attack_released.get_connections().size() == 2,"rebind retains one motion observer and resets action")
	player_actor.position = Vector3(0,1,-40)
	enemy.position = Vector3.ZERO
	enemy.velocity = Vector3.ZERO
	enemy.state = "idle"
	motion.set_physics_process(true)
	enemy.set_physics_process(true)
	# One stationary physics step refreshes CharacterBody's cached wall contact
	# after the cover fixture is removed; otherwise native hop uses that old wall.
	await frames(2)
	check(not enemy.is_on_wall(),"cover-fixture contact cleared before pursuit")
	player_actor.position = Vector3(0,1,-12)
	enemy.state = "chase"
	await frames(20)
	check(enemy.position.length() > .1 and beetle.stride > 0 and beetle.pose == "walk","actual pursuit moves with six-leg gait: position %s stride %.3f pose %s grounded %s" % [enemy.position,beetle.stride,beetle.pose,enemy.is_on_floor()])
	stop(enemy)
	if "--beetle-capture" in OS.get_cmdline_user_args(): await capture()
	var death_clock := beetle.clock
	enemy.take_damage(enemy.max_life*2)
	motion.sample(.1,1)
	check(beetle.clock == death_clock and motion.release_left == 0,"native death stops sampling and clears recovery")
	await frames(1)
	check(not is_instance_valid(enemy),"native death removes actor and rig")
	var file := FileAccess.open(output+"/native-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":labels,"passed":checks-failures,"failed":failures},"\t"))
	print("BEETLE_NATIVE %d checks, %d failures" % [checks,failures])
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
	mat.albedo_color = Color("525e4c")
	ground.material_override = mat
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-32,0)
	sun.light_energy = 1.7
	sun.shadow_enabled = true
	add_child(sun)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-25,145,0)
	fill.light_energy = .85
	add_child(fill)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("64787e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("b3c5cb")
	env.environment.ambient_light_energy = .7
	add_child(env)
	var camera := Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 40
	var layer := CanvasLayer.new()
	add_child(layer)
	var label := Label.new()
	label.position = Vector2(28,24)
	label.add_theme_font_size_override("font_size",24)
	layer.add_child(label)
	enemy.position = Vector3.ZERO
	enemy.velocity = Vector3.ZERO
	enemy.state = "idle"
	enemy._attack_cooldown = 0
	motion.release_left = 0
	player_actor.position = Vector3(0,1,-40)
	enemy.set_physics_process(true)
	motion.set_physics_process(true)
	DirAccess.make_dir_recursive_absolute(output+"/frames")
	var saved_windup := false
	var capture_start_strikes := strikes
	for i in 270:
		if i == 45: enemy.state = "chase"
		if i >= 45 and i < 150: player_actor.position = enemy.position+Vector3(0,1,-6)
		if i == 150: player_actor.position = enemy.position+Vector3(0,1,-1.3)
		if i == 240: enemy.apply_chill(10000)
		label.text = "GLOOM CRAWLER  /  " + ("IDLE" if i<45 else "NATIVE PURSUIT" if i<150 else "NATIVE BITE" if i<240 else "FREEZE")
		camera.position = enemy.position+Vector3(1.65,1.3,-1.8)
		camera.look_at(enemy.position+Vector3(0,.30,0))
		await frames(2)
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		frame.save_png(output+"/frames/%04d.png" % i)
		if i == 25: frame.save_png(output+"/beetle-idle.png")
		if i>150 and not saved_windup and enemy.state == "windup" and enemy._windup_left < .12:
			frame.save_png(output+"/beetle-windup.png")
			saved_windup = true
	check(saved_windup and strikes > capture_start_strikes,"motion capture includes naturally timed windup and actual bites")
	stop(enemy)
