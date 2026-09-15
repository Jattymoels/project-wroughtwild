extends Node3D
## Focused native root/contact/interrupt checks and one Forward+ motion capture.
var checks := 0
var failures := 0
var labels: Dictionary = {}
var strikes := 0
var player_actor: WroughtwildPlayer
var enemy: Enemy
var motion: CreatureMotion
var nymph: NymphPresentation
var output: String
func check(ok: bool, label: String) -> void:
	checks += 1
	labels[label] = ok
	if not ok:
		failures += 1
		printerr("FAIL NYMPH NATIVE: ", label)
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
	await get_tree().process_frame
func stop(actor: Enemy) -> void:
	actor.set_physics_process(false)
	actor._mesh.get_node("Motion").set_physics_process(false)
func bones(presentation: FinishedFauna = null) -> Array[Transform3D]:
	if presentation == null: presentation = nymph
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
	output = OS.get_environment("WROUGHTWILD_NYMPH_OUTPUT")
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
	enemy = Enemy.spawn(self,&"bog_lurker",Vector3.ZERO)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	nymph = motion.finished as NymphPresentation
	check(nymph != null and nymph.rig.get_bone_count() == 27,"ordinary Bog Lurker selects 27-bone nymph")
	if nymph == null: get_tree().quit(1); return
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	check(enemy.behaviour == "lurker" and enemy.verb == "root" and enemy.max_life == sim.enemy("bog_lurker").max_life and enemy.damage == sim.enemy("bog_lurker").damage,"native root identity, life and damage")
	check(is_equal_approx(enemy.move_speed,1.8) and is_equal_approx(enemy.attack_range,2.4) and is_equal_approx(enemy.windup_seconds,.9) and enemy.windup_advance == 0,"native speed, range and stationary 0.9-second windup")
	var capsule: CapsuleShape3D = enemy.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.radius,.35) and is_equal_approx(capsule.height,1.3),"native upright collider retained")
	check(nymph.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL and enemy._mesh.get_child_count() == 1,"one manual animation driver")
	check(nymph.model.scale.is_equal_approx(Vector3.ONE*.82) and enemy._mesh.scale.is_equal_approx(Vector3.ONE*1.4),"uniform nymph fit with family size once and no humanoid reduction")
	check(nymph.model.global_transform.basis.z.normalized().dot(enemy.global_transform.basis.z.normalized()) < -.999,"source -Y exports to +Z, yaw 180 aligns native -Z forward")
	check(nymph.material.get_shader_parameter("core_colour").is_equal_approx(Color(.33,.65,.18)),"selected ART06C nymph palette")
	check(nymph.material.get_shader_parameter("damage_tint").is_equal_approx(Vector3(.16,.14,.12)),"texture-preserving damage tint")
	var part: MeshInstance3D = nymph.model.get_node("NymphRig/Skeleton3D/NymphSkin")
	var arrays := part.mesh.surface_get_arrays(0)
	check(part.material_override == nymph.material and arrays[Mesh.ARRAY_INDEX].size()/3 == 79995,"selected skinned runtime surface and triangle count")
	for kind: String in ["base","orm","scar"]:
		check(nymph.material.get_shader_parameter(kind+"_texture") is Texture2D,"retained " + kind + " texture imported")
	check(is_equal_approx(enemy.verb_seconds,1.2),"native root duration unchanged")
	enemy.apply_bleed(10000)
	check(enemy.bleeding_left == 0,"native bleed immunity retained")
	var peers: Array[Enemy] = []
	var peer := Enemy.spawn(self,&"bog_lurker",Vector3(8,0,0))
	stop(peer)
	peers.append(peer)
	var other_nymph := peers[0]._mesh.get_node("Motion").finished as NymphPresentation
	var other_bones := bones(other_nymph)
	var other_clock := other_nymph.clock
	check(nymph.material != other_nymph.material and nymph.rig != other_nymph.rig and part.mesh == other_nymph.model.get_node("NymphRig/Skeleton3D/NymphSkin").mesh,"independent pose/material with shared mesh")
	enemy.state = "chase"
	var prior_stride := nymph.stride
	motion.sample(.1,.2)
	check(nymph.pose == "walk" and is_equal_approx(nymph.stride-prior_stride,.2/(1.4*.9)),"distance uses cosmetic stride and native family scaling once")
	check(bones(other_nymph) == other_bones and other_nymph.clock == other_clock,"sampling one instance leaves another unchanged")
	enemy.state = "windup"
	motion.sample(.1,0,.5)
	check(nymph.pose == "windup" and is_equal_approx(nymph.player.current_animation_position,.45),"native normalized windup samples head and compact labium brace")
	enemy.stagger(.3)
	motion.sample(.01,0,0,0,false,enemy.staggered())
	check(enemy.state == "chase" and nymph.pose == "idle" and motion.release_left == 0,"stagger interrupts anticipation")
	enemy._stagger_left = 0
	enemy.attack_released.connect(func(kind: String):
		if kind == "strike": strikes += 1)
	player_actor.position = Vector3(0,1,-2.2)
	player_actor.combat._ensure_fight()
	var before_life := player_actor.combat.life
	sim.begin_fight(505)
	var expected := sim.enemy_hit_damage(enemy.bite_damage(),enemy.bite_type(),player_actor.combat.cast_armour()+player_actor.combat.still_armour())
	sim.begin_fight(505)
	await strike()
	check(strikes == 1 and motion.release_left > 0,"one actual native strike starts cosmetic recovery")
	check(is_equal_approx(before_life-player_actor.combat.life,expected),"authoritative release deals the native mitigated root hit: got %.6f expected %.6f invulnerable %.3f" % [before_life-player_actor.combat.life,expected,player_actor.combat.invulnerable_left])
	check(player_actor.combat.rooted() and is_equal_approx(player_actor.combat._root_left,enemy.verb_seconds),"confirmed native hit applies exact root duration")
	var root_before := player_actor.combat._root_left
	var held_position := player_actor.position
	player_actor.test_walk = Vector2(0,-1)
	player_actor.set_physics_process(true)
	await frames(3)
	player_actor.set_physics_process(false)
	check(Vector2(player_actor.position.x-held_position.x,player_actor.position.z-held_position.z).length() < .001,"native root holds attempted player walking")
	check(player_actor.combat._use_dash(&"prototype_dash"),"ordinary learned dash activates while rooted")
	player_actor.set_physics_process(true)
	await frames(3)
	player_actor.set_physics_process(false)
	check(not player_actor.combat.rooted() and player_actor.position.distance_to(held_position) > .1,"actual player dash movement breaks native root")
	player_actor.test_walk = Vector2.ZERO
	player_actor.combat._dash_left = 0
	player_actor.combat.invulnerable_left = 0
	player_actor.combat._root_left = root_before
	motion.sample(.11,0)
	motion.sample(0,0)
	check(nymph.pose == "release" and is_equal_approx(nymph.player.current_animation_position,.1125),"release samples existing cosmetic window at authored 40Hz duration")
	check(is_equal_approx(player_actor.combat._root_left,root_before),"sampling cosmetic recovery cannot reapply or extend root")
	player_actor.combat._physics_process(enemy.verb_seconds)
	check(not player_actor.combat.rooted(),"native combat clock expires root at unchanged duration")
	var held := bones()
	enemy.apply_chill(10000)
	motion.sample(.1,0,0,0,true,false)
	check(bones() == held and motion.release_left == 0,"freeze holds exact pose and clears follow-through")
	check(nymph.material.get_shader_parameter("status_active"),"native freeze overrides scars")
	enemy.thaw()
	enemy._refresh_look()
	motion.sample(.01,0)
	check(not nymph.material.get_shader_parameter("status_active"),"thaw restores scar material")
	var prior_clock := nymph.clock
	motion.set_physics_process(true)
	get_tree().paused = true
	for i in 3: await get_tree().process_frame
	check(nymph.clock == prior_clock,"pause holds ambient pulse and animation")
	get_tree().paused = false
	stop(enemy)
	before_life = player_actor.combat.life
	player_actor.position = Vector3(0,1,-3)
	await strike()
	check(strikes == 2 and player_actor.combat.life == before_life and not player_actor.combat.rooted(),"native missed release applies neither damage nor root")
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(3,3,.15)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0,1,-1.1)
	add_child(wall)
	player_actor.position = Vector3(0,1,-2.2)
	await frames(2)
	await strike()
	check(strikes == 3 and player_actor.combat.life == before_life and not player_actor.combat.rooted(),"native solid cover blocks both damage and root")
	wall.queue_free()
	for other in peers: other.queue_free()
	await frames(1)
	enemy.configure(sim)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	nymph = motion.finished
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
	check(enemy.position.length() > .1 and nymph.stride > 0 and nymph.pose == "walk","actual pursuit moves with six-leg gait: position %s stride %.3f pose %s grounded %s" % [enemy.position,nymph.stride,nymph.pose,enemy.is_on_floor()])
	stop(enemy)
	if "--nymph-capture" in OS.get_cmdline_user_args(): await capture()
	var death_clock := nymph.clock
	enemy.take_damage(enemy.max_life*2)
	motion.sample(.1,1)
	check(nymph.clock == death_clock and motion.release_left == 0,"native death stops sampling and clears recovery")
	await frames(1)
	check(not is_instance_valid(enemy),"native death removes actor and rig")
	var file := FileAccess.open(output+"/native-checks.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":labels,"passed":checks-failures,"failed":failures},"\t"))
	print("NYMPH_NATIVE %d checks, %d failures" % [checks,failures])
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
		if i == 150: player_actor.position = enemy.position+Vector3(0,1,-2.2)
		if i == 240: enemy.apply_chill(10000)
		label.text = "BOG LURKER  /  " + ("IDLE" if i<45 else "NATIVE PURSUIT" if i<150 else "NATIVE ROOT STRIKE" if i<240 else "FREEZE")
		camera.position = enemy.position+Vector3(2.9,2.05,-3.25)
		camera.look_at(enemy.position+Vector3(0,.34,0))
		await frames(2)
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		frame.save_png(output+"/frames/%04d.png" % i)
		if i == 27: frame.save_png(output+"/nymph-idle.png")
		if i>150 and not saved_windup and enemy.state == "windup" and enemy._windup_left < .25:
			frame.save_png(output+"/nymph-windup.png")
			saved_windup = true
	check(saved_windup and strikes > capture_start_strikes,"motion capture includes naturally timed windup and actual bites")
	stop(enemy)
