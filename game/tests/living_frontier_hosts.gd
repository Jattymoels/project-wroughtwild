extends "res://tests/enemy_contact_review.gd"
## Actual controller/casts and physical releases. Ordinary gear ingredients are
## explicit combat fixtures; the separate paid journey proves acquisition.
var pristine := ""
var release_count := 0

func _contact_cases() -> void:
	if "--host-visuals" in OS.get_cmdline_user_args():
		await capture_hosts()
		return
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(0,1,0)
	add_child(player)
	player.placement.set_physics_process(false)
	player.trial.set_process(false)
	sim = player.inventory.get_sim()
	pristine = sim.export_json()
	await frames(4)
	for ticks in [20,60]:
		Engine.physics_ticks_per_second = ticks
		for id in [&"lf_red_boar", &"lf_blue_boar"]:
			for mode in ["stand", "back", "side", "cover", "stagger", "freeze"]:
				await contact_case(id, mode, ticks)
	Engine.physics_ticks_per_second = 60
	for class_id in ["warden", "ranger", "kindler"]:
		for id in [&"lf_red_boar", &"lf_blue_boar"]:
			await combat_case(class_id, id)
	var file := FileAccess.open("res://../build/lf3/hosts.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "samples": results}, "  "))
	file.close()
	print("LF3_HOSTS %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func reset_case(class_id := "warden") -> void:
	check(sim.import_json(pristine), "reset unmodified class fixture")
	check(player.class_panel.choose(class_id), "starting class " + class_id)
	player.combat.restore_life()
	player.combat.cooldowns.clear()
	for skill in player.combat.skills: player.combat.cooldowns[skill] = 0.0
	player.combat.clear_train()
	player.combat._casts.clear()
	player.combat._mutation_cache.clear()
	player.position = Vector3(0,1,0)
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.camera.rotation = Vector3.ZERO
	player.test_walk = Vector2.ZERO
	await frames(3)

func capture_hosts() -> void:
	var floor_mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(35,.1,30)
	floor_mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("4a5142")
	floor_mesh.material_override = material
	floor_mesh.position.y = -.05
	add_child(floor_mesh)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-35,0)
	light.light_energy = 1.1
	add_child(light)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color("596570")
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color("bac6c8")
	world.environment.ambient_light_energy = .65
	add_child(world)
	var camera := Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.position = Vector3(8,6,9)
	camera.look_at(Vector3(0,.5,-1))
	for i in 2:
		var host := Enemy.spawn(self, &"lf_red_boar" if i == 0 else &"lf_blue_boar", Vector3(-4 if i == 0 else 4,0,0))
		host.set_physics_process(false)
		host.state = "windup"
		host._windup_left = .35
		host._strike_direction = Vector3.FORWARD
		print("LF3_LOOK ",host.influence," ",host.get_node("FrontierHostLook").tell != null," ",host.get_node("FrontierHostLook").scar != null)
	await frames(8)
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf3"))
	get_viewport().get_texture().get_image().save_png("res://../captures/lf3/boar-tells.png")
	print("LF3_HOST_VISUALS captured existing boar ancestry and actual warning shapes")
	get_tree().quit()

func contact_case(id: StringName, mode: String, ticks: int) -> void:
	await reset_case()
	enemy = Enemy.spawn(self,id,Vector3(0,.02,1.8))
	enemy.state = "chase"
	release_count = 0
	enemy.attack_released.connect(func(_kind: String): release_count += 1)
	for step in ticks:
		if enemy.state == "windup": break
		await frames(1)
	check(enemy.state == "windup", "real windup starts " + String(id))
	check(enemy.visual_id == "ember_whelp" and enemy.get_node("MeshInstance3D").get_meta("authored_actor_id") == "ember_whelp", "related boars retain authored ancestry")
	var direction := enemy._strike_direction
	var start := enemy.position
	var before := player.combat.life
	var wall: StaticBody3D
	for step in ceili(1.7*ticks):
		var seconds := float(step)/ticks
		if seconds >= .65:
			if mode == "back": player.test_walk = Vector2(0,-1)
			if mode == "side": player.test_walk = Vector2(1,0)
			if mode == "stagger" and step == ceili(.65*ticks): enemy.stagger(2)
			if mode == "freeze" and step == ceili(.65*ticks): enemy.apply_chill(100)
			if mode == "cover" and wall == null:
				wall = StaticBody3D.new()
				var collision := CollisionShape3D.new()
				var box := BoxShape3D.new()
				box.size = Vector3(6,4,.2)
				collision.shape = box
				wall.add_child(collision)
				wall.position = Vector3(0,2,.85)
				add_child(wall)
		await frames(1)
	var damage := before - player.combat.life
	if mode in ["stand", "back", "side"]: check(release_count == 1, "exactly one release " + mode)
	if mode == "stand": check(damage > 0 and damage <= 6.61, "one real native damage contact within existing ten-percent hit variance")
	if mode in ["cover", "stagger", "freeze"]: check(damage == 0, "contact prevented by " + mode)
	if mode in ["stagger", "freeze"]: check(release_count == 0, "interruption cancels release")
	if mode == "side": check((damage > 0) == (id == &"lf_red_boar"), "late lateral movement clears Blue lane but remains in Red ring")
	if mode == "back": check((damage > 0) == (id == &"lf_blue_boar"), "late retreat clears Red ring but Blue charge catches it")
	check(enemy._strike_direction == direction, "release never retargets")
	if id == &"lf_blue_boar": check(enemy.position.distance_to(start) <= enemy.release_distance+.05, "charge distance bounded")
	if mode == "cover": check(enemy.position.z > .85, "physical body stays behind cover")
	results.append({"enemy":id,"mode":mode,"ticks":ticks,"damage":damage,"releases":release_count,"travel":enemy.position.distance_to(start)})
	player.test_walk = Vector2.ZERO
	enemy.free()
	if wall != null: wall.free()
	await frames(2)

func combat_case(class_id: String, id: StringName) -> void:
	await reset_case(class_id)
	sim.add_station("workbench")
	sim.add_materials({"wood":30,"hide":8})
	var recipe: String = {"warden":"wooden_cudgel","ranger":"simple_bow","kindler":"wooden_focus"}[class_id]
	check(bool(sim.craft(recipe).get("crafted",false)), "ordinary starting weapon paid")
	check(sim.equip_pack_item(sim.pack_items().size()-1), "equip ordinary starting weapon")
	check(sim.foundry().plate.is_empty(), "no Catalyst or support fixture")
	check(player.combat.invulnerable_left == 0 and player.combat.is_physics_processing(), "incoming damage is live without invulnerability")
	enemy = Enemy.spawn(self,id,Vector3(0,.02,5))
	enemy.state = "chase"
	release_count = 0
	enemy.attack_released.connect(func(_kind: String): release_count += 1)
	var casts := 0
	var seconds := 0.0
	for step in 60*45:
		if not is_instance_valid(enemy) or enemy.life <= 0 or player.combat.life <= 0: break
		var to := (enemy.position-player.position)*Vector3(1,0,1)
		var forward := to.normalized()
		player.look_at(player.position+forward)
		player.camera.look_at(enemy.position+Vector3.UP*.7)
		var move := Vector3.ZERO
		var distance := to.length()
		var target_distance := 1.5 if class_id == "warden" else 5.0
		if distance > target_distance: move = forward
		if enemy.state in ["windup","release_warning","release"]:
			if enemy.release_shape in ["radial","held_burst"]:
				move = -forward if distance < enemy.release_radius+.35 else Vector3.ZERO
			else: move = Vector3(-forward.z,0,forward.x)
		var local := player.global_basis.inverse()*move
		player.test_walk = Vector2(local.x,local.z)
		for skill in sim.skill_bar():
			var definition: Dictionary = player.combat.skills.get(skill,{})
			if definition.get("delivery","") == "dash": continue
			if definition.get("delivery","") in ["cone","strike"] and distance > player.combat.strike_reach(skill): continue
			if player.combat.use_skill(skill): casts += 1; break
		await frames(1)
		seconds += 1.0/60
	var remaining := enemy.life if is_instance_valid(enemy) else 0.0
	check(remaining <= 0 and player.combat.life > 0, "starting " + class_id + " defeats " + String(id))
	check(casts > 0, "actual starting casts used")
	check(player.combat.invulnerable_left == 0, "combat completed without invulnerability")
	results.append({"class":class_id,"enemy":id,"seconds":seconds,"life":player.combat.life,"casts":casts,"releases":release_count,"remaining":remaining})
	print("LF3_COMBAT ",JSON.stringify(results.back()))
	player.test_walk = Vector2.ZERO
	if is_instance_valid(enemy): enemy.free()
	for projectile in get_tree().get_nodes_in_group("projectiles"): projectile.queue_free()
	await frames(3)
