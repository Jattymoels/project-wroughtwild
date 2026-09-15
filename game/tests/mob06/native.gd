extends Node3D
## Focused native ward/melee/interrupt checks and one Forward+ motion capture.
var checks := 0
var failures := 0
var labels: Dictionary = {}
var strikes := 0
var player_actor: WroughtwildPlayer
var enemy: Enemy
var motion: CreatureMotion
var tortoise: TortoisePresentation
var output: String
func check(ok: bool, label: String) -> void:
	checks += 1
	labels[label] = ok
	if not ok:
		failures += 1
		printerr("FAIL TORTOISE NATIVE: ", label)
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
	await get_tree().process_frame
func stop(actor: Enemy) -> void:
	actor.set_physics_process(false)
	actor._mesh.get_node("Motion").set_physics_process(false)
func bones(presentation: FinishedFauna = null) -> Array[Transform3D]:
	if presentation == null: presentation = tortoise
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
	output = OS.get_environment("WROUGHTWILD_TORTOISE_OUTPUT")
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
	enemy = Enemy.spawn(self,&"hollow_knight",Vector3.ZERO)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	tortoise = motion.finished as TortoisePresentation
	check(tortoise != null and tortoise.rig.get_bone_count() == 17,"ordinary Hollow Knight selects 17-bone tortoise")
	if tortoise == null: get_tree().quit(1); return
	if "--tortoise-capture-only" in OS.get_cmdline_user_args():
		enemy.attack_released.connect(func(kind: String):
			if kind == "strike": strikes += 1)
		await capture()
		finish()
		return
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	check(enemy.behaviour == "knight" and enemy.verb == "ward" and enemy.max_life == sim.enemy("hollow_knight").max_life and enemy.damage == sim.enemy("hollow_knight").damage,"native ward identity, life and damage")
	check(is_equal_approx(enemy.move_speed,2.6) and is_equal_approx(enemy.attack_range,2.0) and is_equal_approx(enemy.windup_seconds,.7) and enemy.windup_advance == 0,"native speed, range and stationary 0.7-second windup")
	var capsule: CapsuleShape3D = enemy.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.radius,.35) and is_equal_approx(capsule.height,1.3),"native upright collider retained")
	check(tortoise.player.callback_mode_process == AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL and enemy._mesh.get_child_count() == 1,"one manual animation driver")
	check(tortoise.model.scale.is_equal_approx(Vector3.ONE*(.9/.76)) and enemy._mesh.scale.is_equal_approx(Vector3.ONE*(1.25*.76)),"uniform fit cancels legacy shrink with native family size once")
	check(tortoise.model.global_transform.basis.z.normalized().dot(enemy.global_transform.basis.z.normalized()) < -.999,"source -Y exports to +Z, yaw 180 aligns native -Z forward")
	check(tortoise.material.get_shader_parameter("core_colour").is_equal_approx(Color(.82,.85,.64)),"selected ART06C tortoise palette")
	check(tortoise.material.get_shader_parameter("damage_tint").is_equal_approx(Vector3(.16,.14,.12)),"texture-preserving damage tint")
	var part: MeshInstance3D = tortoise.model.get_node("TortoiseRig/Skeleton3D/TortoiseSkin")
	var arrays := part.mesh.surface_get_arrays(0)
	check(part.material_override == tortoise.material and arrays[Mesh.ARRAY_INDEX].size()/3 == 79997,"selected skinned runtime surface and triangle count")
	for kind: String in ["base","orm","scar"]:
		check(tortoise.material.get_shader_parameter(kind+"_texture") is Texture2D,"retained " + kind + " texture imported")
	check(is_equal_approx(enemy.verb_radius,5) and is_equal_approx(enemy.verb_strength,.3),"native five-metre, thirty-percent ally ward")
	enemy.apply_ignite(10000)
	check(enemy.ignite == 0 and enemy.burning_left == 0,"native ignite immunity retained")
	var old_life := enemy.life
	var fire_damage := enemy.take_typed(40,"fire",false)
	check(is_equal_approx(fire_damage,10) and is_equal_approx(old_life-enemy.life,10),"native quarter fire damage retained")
	old_life = enemy.life
	check(is_equal_approx(enemy.take_typed(10,"physical",false),10) and is_equal_approx(old_life-enemy.life,10),"shell art adds no physical resistance")
	enemy.life = enemy.max_life
	enemy._refresh_aura()
	check(enemy.wards() and not enemy.warded() and enemy._aura.visible and is_equal_approx((enemy._aura.mesh as SphereMesh).radius,5),"ordinary native aura is visible and cannot ward itself")
	var ally := Enemy.spawn(self,&"bog_lurker",Vector3(5,0,0))
	stop(ally)
	check(ally.warded_by() == enemy,"ward includes an ally at its five-metre boundary")
	ally.position.x = 5.01
	check(ally.warded_by() == null,"ward excludes an ally outside its native radius")
	ally.position.x = 4
	ally.trial_bound = true
	check(ally.warded_by() == null,"ordinary ward does not cross into a trial")
	enemy.trial_bound = true
	check(ally.warded_by() == enemy,"matching native trial boundary can ward")
	enemy.trial_bound = false
	ally.trial_bound = false
	player_actor.combat._ensure_fight()
	ally.position.x = 5.01
	sim.begin_fight(606)
	var unwarded: float = player_actor.combat.deal(ally,&"prototype_heavy_strike",true,.1,true).damage
	ally.position.x = 4
	sim.begin_fight(606)
	var warded: float = player_actor.combat.deal(ally,&"prototype_heavy_strike",true,.1,true).damage
	check(unwarded > 0 and is_equal_approx(warded,unwarded*.7),"actual native player packet is reduced by thirty percent for the nearby ally")
	enemy.stagger(.3)
	enemy._refresh_aura()
	sim.begin_fight(606)
	var interrupted: float = player_actor.combat.deal(ally,&"prototype_heavy_strike",true,.1,true).damage
	check(not enemy.wards() and not enemy._aura.visible and is_equal_approx(interrupted,unwarded),"native stagger hides aura and removes actual ward reduction")
	enemy._stagger_left = 0
	enemy._refresh_aura()
	check(enemy._aura.visible and ally.warded_by() == enemy,"native ward resumes after stagger")
	ally.queue_free()
	await frames(1)
	var peers: Array[Enemy] = []
	var peer := Enemy.spawn(self,&"hollow_knight",Vector3(8,0,0))
	stop(peer)
	peers.append(peer)
	var other_tortoise := peers[0]._mesh.get_node("Motion").finished as TortoisePresentation
	peers[0].make_elite({"id":"fixture_size","display_name":"Fixture"})
	check(peers[0]._mesh.scale.is_equal_approx(Vector3.ONE*(1.25*.76*1.3)) and other_tortoise.model.scale.is_equal_approx(tortoise.model.scale),"native elite scale applies once above unchanged uniform skin fit")
	var other_bones := bones(other_tortoise)
	var other_clock := other_tortoise.clock
	check(tortoise.material != other_tortoise.material and tortoise.rig != other_tortoise.rig and part.mesh == other_tortoise.model.get_node("TortoiseRig/Skeleton3D/TortoiseSkin").mesh,"independent pose/material with shared mesh")
	enemy.state = "chase"
	var prior_stride := tortoise.stride
	motion.sample(.1,.2)
	check(tortoise.pose == "walk" and is_equal_approx(tortoise.stride-prior_stride,.2/(1.25*1.5)),"distance uses cosmetic stride and native family scaling once")
	check(bones(other_tortoise) == other_bones and other_tortoise.clock == other_clock,"sampling one instance leaves another unchanged")
	enemy.state = "windup"
	motion.sample(.1,0,.5)
	check(tortoise.pose == "windup" and is_equal_approx(tortoise.player.current_animation_position,.35),"native normalized windup samples supported neck/head brace")
	enemy.stagger(.3)
	motion.sample(.01,0,0,0,false,enemy.staggered())
	check(enemy.state == "chase" and tortoise.pose == "idle" and motion.release_left == 0,"stagger interrupts anticipation")
	enemy._stagger_left = 0
	enemy.attack_released.connect(func(kind: String):
		if kind == "strike": strikes += 1)
	player_actor.position = Vector3(0,1,-1.8)
	player_actor.combat._ensure_fight()
	var before_life := player_actor.combat.life
	sim.begin_fight(505)
	var expected := sim.enemy_hit_damage(enemy.bite_damage(),enemy.bite_type(),player_actor.combat.cast_armour()+player_actor.combat.still_armour())
	sim.begin_fight(505)
	await strike()
	check(strikes == 1 and motion.release_left > 0,"one actual native strike starts cosmetic recovery")
	check(is_equal_approx(before_life-player_actor.combat.life,expected),"authoritative release deals the native mitigated physical hit: got %.6f expected %.6f invulnerable %.3f" % [before_life-player_actor.combat.life,expected,player_actor.combat.invulnerable_left])
	check(not player_actor.combat.rooted(),"Hollow Knight melee adds no root or grab")
	motion.sample(.11,0)
	motion.sample(0,0)
	check(tortoise.pose == "release" and is_equal_approx(tortoise.player.current_animation_position,.1125),"release samples existing cosmetic window at authored 40Hz duration")
	check(is_equal_approx(before_life-player_actor.combat.life,expected),"cosmetic neck release cannot deal another hit")
	var held := bones()
	enemy.apply_chill(10000)
	motion.sample(.1,0,0,0,true,false)
	check(bones() == held and motion.release_left == 0,"freeze holds exact pose and clears follow-through")
	check(tortoise.material.get_shader_parameter("status_active"),"native freeze overrides scars")
	enemy._refresh_aura()
	check(enemy.wards() and enemy._aura.visible,"native freeze preserves the existing ward rule")
	enemy.thaw()
	enemy._refresh_look()
	motion.sample(.01,0)
	check(not tortoise.material.get_shader_parameter("status_active"),"thaw restores scar material")
	var prior_clock := tortoise.clock
	motion.set_physics_process(true)
	get_tree().paused = true
	for i in 3: await get_tree().process_frame
	check(tortoise.clock == prior_clock,"pause holds ambient pulse and animation")
	get_tree().paused = false
	stop(enemy)
	before_life = player_actor.combat.life
	player_actor.position = Vector3(0,1,-3)
	await strike()
	check(strikes == 2 and player_actor.combat.life == before_life and not player_actor.combat.rooted(),"native missed melee release deals no damage")
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size = Vector3(3,3,.15)
	wall_shape.shape = wall_box
	wall.add_child(wall_shape)
	wall.position = Vector3(0,1,-1.1)
	add_child(wall)
	player_actor.position = Vector3(0,1,-1.8)
	await frames(2)
	await strike()
	check(strikes == 3 and player_actor.combat.life == before_life and not player_actor.combat.rooted(),"native solid cover blocks melee damage")
	wall.queue_free()
	for other in peers: other.queue_free()
	await frames(1)
	enemy.configure(sim)
	stop(enemy)
	motion = enemy._mesh.get_node("Motion")
	tortoise = motion.finished
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
	check(enemy.position.length() > .1 and tortoise.stride > 0 and tortoise.pose == "walk","actual pursuit moves with four-leg gait: position %s stride %.3f pose %s grounded %s" % [enemy.position,tortoise.stride,tortoise.pose,enemy.is_on_floor()])
	stop(enemy)
	if "--tortoise-capture" in OS.get_cmdline_user_args(): await capture()
	var death_clock := tortoise.clock
	enemy.take_damage(enemy.max_life*2)
	motion.sample(.1,1)
	check(tortoise.clock == death_clock and motion.release_left == 0 and not enemy.wards(),"native death stops sampling, clears recovery and ends ward")
	await frames(1)
	check(not is_instance_valid(enemy),"native death removes actor and rig")
	finish()

func finish() -> void:
	var report := "capture-checks.json" if "--tortoise-capture-only" in OS.get_cmdline_user_args() else "native-checks.json"
	var file := FileAccess.open(output+"/"+report,FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":labels,"passed":checks-failures,"failed":failures},"\t"))
	print("TORTOISE_NATIVE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)

func capture() -> void:
	var comfortable := Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and get_window().unfocusable
	var details := FileAccess.open(output+"/capture-comfort.json",FileAccess.WRITE)
	details.store_string(JSON.stringify({"mouse_mode":Input.mouse_mode,"mouse_visible":Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"unfocusable":get_window().unfocusable,"viewport":[get_viewport().size.x,get_viewport().size.y]},"\t"))
	check(comfortable,"capture keeps pointer visible and window unfocusable")
	if not comfortable: stop(enemy); return
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
		if i == 150: player_actor.position = enemy.position+Vector3(0,1,-1.8)
		if i == 240: enemy.apply_chill(10000)
		label.text = "HOLLOW KNIGHT  /  " + ("IDLE" if i<45 else "NATIVE PURSUIT" if i<150 else "NATIVE MELEE STRIKE" if i<240 else "FREEZE")
		camera.position = enemy.position+Vector3(3.0,2.1,-3.7)
		camera.look_at(enemy.position+Vector3(0,.70,0))
		await frames(2)
		await RenderingServer.frame_post_draw
		var frame := get_viewport().get_texture().get_image()
		frame.save_png(output+"/frames/%04d.png" % i)
		if i == 17: frame.save_png(output+"/tortoise-idle.png")
		if i == 93: frame.save_png(output+"/tortoise-walk.png")
		if i>150 and not saved_windup and enemy.state == "windup" and enemy._windup_left < .25:
			frame.save_png(output+"/tortoise-windup.png")
			saved_windup = true
	check(saved_windup and strikes > capture_start_strikes,"motion capture includes naturally timed windup and actual melee releases")
	stop(enemy)
