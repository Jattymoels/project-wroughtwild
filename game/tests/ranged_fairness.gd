extends Node3D
var checks := 0
var failures := 0
var player: WroughtwildPlayer

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", label)

func settle() -> void:
	for i in 3:
		await get_tree().physics_frame

func clear_shots() -> void:
	for shot in get_tree().get_nodes_in_group("enemy_projectiles"):
		shot.free()

func reset_target() -> void:
	player.position = Vector3(0, 1, 7)
	player.combat.life = player.combat.max_life
	player.combat._marked_left = 0.0
	player.combat._train_hits.clear()
	player.combat.invulnerable_left = 0.0

func shot_from(enemy: Enemy) -> EnemyProjectile:
	var shot := EnemyProjectile.launch(enemy, player.global_position, enemy.projectile_rules)
	shot.set_physics_process(false)
	return shot

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	reset_target()
	for id in [&"cinder_archer", &"marsh_wisp", &"cinder_wisp"]:
		var enemy := Enemy.spawn(self, id, Vector3.ZERO)
		enemy.set_physics_process(false)
		await settle()
		check(not enemy.projectile_rules.is_empty(), "%s uses spatial delivery" % id)
		reset_target()
		var full := player.combat.life
		enemy.state = "chase"
		enemy._attack_cooldown = 0.0
		enemy._physics_process(0.01)
		check(enemy.state == "windup" and enemy._shot_tell.visible, "%s visibly charges" % id)
		var aim := enemy._shot_aim
		# Move laterally while remaining inside the old unavoidable radius.
		player.position.x += 2.0
		await settle()
		enemy._physics_process(enemy.windup_seconds + 0.01)
		check(enemy._shot_aim == aim, "%s does not track during its windup" % id)
		check(player.combat.life == full, "%s release is not instant damage" % id)
		var shots := get_tree().get_nodes_in_group("enemy_projectiles")
		check(shots.size() == 1, "%s releases one shot" % id)
		for shot in shots:
			shot.set_physics_process(false)
			shot.advance(3.0)
		check(player.combat.life == full and player.combat._marked_left == 0.0, "%s windup sidestep avoids damage and mark" % id)
		clear_shots()
		reset_target()
		await settle()
		var shot := shot_from(enemy)
		shot.advance(0.1)
		check(player.combat.life == full, "%s has real flight time" % id)
		shot.advance(1.0)
		check(player.combat.life < full and shot.spent, "%s stationary target is hit by swept contact" % id)
		var after := player.combat.life
		shot.advance(1.0)
		check(player.combat.life == after, "%s cannot hit twice" % id)
		if enemy.verb == "mark":
			check(player.combat._marked_left > 0.0, "archer mark arrives on contact")
		clear_shots()
		# Walking only after release also evades at the actual player speed.
		for fps in [20, 60]:
			reset_target()
			await settle()
			shot = shot_from(enemy)
			for frame in fps:
				player.position.x += player.move_speed / float(fps)
				await get_tree().physics_frame
				# A faster finite shot can expire before the one-second walk ends.
				if is_instance_valid(shot): shot.advance(1.0 / float(fps))
			check(player.combat.life == full, "%s flight sidestep at %d FPS avoids damage" % [id, fps])
			clear_shots()
		# Thin solid cover and initial overlap are both checked by the sweep.
		reset_target()
		var wall := StaticBody3D.new()
		var collision := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(4, 4, 0.05)
		collision.shape = box
		wall.add_child(collision)
		wall.position = Vector3(0, 1, 3)
		add_child(wall)
		await settle()
		shot = shot_from(enemy)
		shot.advance(2.0)
		check(shot.spent and player.combat.life == full, "%s cannot tunnel through a thin wall on a long frame" % id)
		clear_shots()
		wall.position.z = enemy.position.z
		await settle()
		shot = shot_from(enemy)
		shot.advance(2.0)
		check(shot.spent and player.combat.life == full, "%s starting in cover cannot shoot out through it" % id)
		clear_shots()
		wall.free()
		reset_target()
		await settle()
		enemy.state = "chase"
		enemy._attack_cooldown = 0.0
		enemy._physics_process(0.01)
		enemy.stagger(1.0)
		enemy._physics_process(0.1)
		check(get_tree().get_nodes_in_group("enemy_projectiles").is_empty() and not enemy._shot_tell.visible, "%s stagger cancels shot and tell" % id)
		shot = shot_from(enemy)
		enemy.free()
		shot.advance(2.0)
		check(shot.spent and player.combat.life < full, "%s released shot survives source deletion safely" % id)
		clear_shots()
	await removal_input()
	print("CODEX_RANGED_FAIRNESS %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func removal_input() -> void:
	var build := player.placement
	var sim := player.inventory.get_sim()
	sim.add_material("shrieker_horn", 1)
	build.set_build_mode_enabled(true)
	var element := {"kind":"volume", "axis":0, "cell":Vector3i(0,0,6)}
	var block := build.place_piece(element, &"cube", &"wood", 0)
	player.position = Vector3(0.5, 1.1, 6)
	player.camera.look_at(block.global_position, Vector3.UP)
	await settle()
	check(build._get_view_trace().get("collider") == block, "X fixture aims at a real placed block")
	var x := InputEventKey.new()
	x.physical_keycode = KEY_X
	x.pressed = true
	check(x.is_action_pressed("remove_block") and x.is_action_pressed("blow_horn"), "physical X reproduces both bindings")
	var before := sim.material_count("wood")
	player._unhandled_input(x)
	check(block.get_parent() == null and sim.material_count("wood") > before, "X removes and refunds the aimed build")
	check(player.horn_cooldown_left() == 0.0, "removing with a carried horn never blows it")
	await settle()
	player._unhandled_input(x)
	check(player.horn_cooldown_left() == 0.0, "X on empty space in build mode never blows horn")
	build.set_build_mode_enabled(false)
	player.inventory_panel.open_panel()
	player._unhandled_input(x)
	check(player.horn_cooldown_left() == 0.0, "X in an inventory panel never blows horn")
	player.inventory_panel.close_panel()
	player._unhandled_input(x)
	check(player.horn_cooldown_left() > 0.0, "X outside build mode still blows a carried horn")
