extends Node3D
## Common baseline/current contact measurements with the real player controller,
## live enemy physics, native unarmoured hits and no defensive Foundry fixture.
var player: WroughtwildPlayer
var sim: WroughtwildSim
var enemy: Enemy
var checks := 0
var failures := 0
var elapsed := 0.0
var sample := {}
var results: Array = []
var dungeon: ForgeDungeon

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL CONTACT: ",label)

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	_make_ground()
	await frames(8)
	await _contact_cases()

func _make_ground() -> void:
	if "--forge-contact" in OS.get_cmdline_user_args():
		dungeon = ForgeDungeon.new()
		dungeon.position = Vector3(18,0,12)
		add_child(dungeon)
		dungeon.build({"stages":[{"index":0,"floor_index":0,"choices":[{"id":"contact","module":"threshold_gallery"}]}],"floor_count":1},0)
		dungeon.open_room(0,0)
		return
	var floor_body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(220,1,220)
	shape.shape = box
	floor_body.add_child(shape)
	floor_body.position.y = -.5
	add_child(floor_body)

func _contact_cases() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(0,1,0)
	add_child(player)
	player.class_panel.choose("warden")
	player.placement.set_physics_process(false)
	player.trial.set_process(false)
	sim = player.inventory.get_sim()
	player.combat.hit_taken.connect(func(damage: float, _source: String):
		if sample.is_empty(): return
		sample.hits += 1
		sample.damage += damage
		sample.contacts.append({"time":elapsed,"distance":enemy._horizontal_distance_to(player),"capsule_gap":maxf(0,enemy._horizontal_distance_to(player)-.77),"damage":damage,"flight_seconds":elapsed-float(sample.releases[-1].time) if not enemy.projectile_rules.is_empty() and not sample.releases.is_empty() else 0.0})
	)
	await frames(8)
	var combat_before := player.combat.capture_trial_state()
	var native_before := sim.export_json()
	for id in [&"ash_hound",&"cinder_archer",&"marsh_wisp"]:
		for mode in ["stationary","retreat","evade","cover"]:
			player.test_walk = Vector2.ZERO
			player.position = Vector3(0,1,0)
			player.velocity = Vector3.ZERO
			player.rotation = Vector3.ZERO
			player.combat.restore_trial_state(combat_before)
			await frames(3)
			var start_distance := 2.3 if id == &"ash_hound" else 7.0
			var cover: StaticBody3D
			if mode == "cover":
				cover = StaticBody3D.new()
				var collider := CollisionShape3D.new()
				var barrier := BoxShape3D.new()
				barrier.size = Vector3(8,4,.1)
				collider.shape = barrier
				cover.add_child(collider)
				cover.position = Vector3(0,2,start_distance*.5)
				add_child(cover)
				await frames(2)
			enemy = Enemy.spawn(self,id,Vector3(0,.02,start_distance))
			if dungeon != null:
				enemy.trial_bound = true
				enemy.trial_dungeon = dungeon
			enemy.state = "chase"
			enemy.attack_released.connect(func(kind: String):
				sample.releases.append({"time":elapsed,"distance":enemy._horizontal_distance_to(player),"kind":kind,"position":str(enemy.global_position),"target":str(player.global_position)})
			)
			sample = {"enemy":String(id),"mode":mode,"starts":[],"releases":[],"contacts":[],"hits":0,"damage":0.0,"distance_walked":0.0,"min_distance":999.0}
			var prior_state := enemy.state
			var dodge_left := 0.0
			var dodge_direction := Vector2.ZERO
			elapsed = 0
			for step in 600:
				var before := player.global_position
				if mode == "retreat": player.test_walk = Vector2(0,-1)
				elif mode == "evade":
					# React to a visible windup with a normal lateral walk, then settle.
					if enemy.state == "windup" and prior_state != "windup":
						dodge_left = 1.25
						var away := player.global_position - enemy.global_position
						dodge_direction = Vector2(-away.z,away.x).normalized()
						# Choose the inward sidestep rather than blindly walking into a room wall.
						if dodge_direction.dot(Vector2(player.position.x,player.position.z)) > 0: dodge_direction = -dodge_direction
						if dungeon != null:
							var forward_clear := _dodge_clearance(dodge_direction)
							if _dodge_clearance(-dodge_direction) > forward_clear: dodge_direction = -dodge_direction
					player.test_walk = dodge_direction if dodge_left > 0 else Vector2.ZERO
				prior_state = enemy.state
				await frames(1)
				elapsed += 1.0/60.0
				dodge_left -= 1.0/60.0
				sample.distance_walked += player.global_position.distance_to(before)
				sample.min_distance = minf(sample.min_distance,enemy._horizontal_distance_to(player))
				if enemy.state == "windup" and prior_state != "windup":
					sample.starts.append({"time":elapsed,"distance":enemy._horizontal_distance_to(player),"capsule_gap":maxf(0,enemy._horizontal_distance_to(player)-.77),"windup":enemy.windup_seconds,"committed_toward":str(player.global_position-enemy.global_position)})
				if player.combat.life <= 0: break
			sample.final_distance = enemy._horizontal_distance_to(player)
			if mode != "cover": check(sample.releases.size() > 0,"real attacks attempted: %s %s" % [id,mode])
			if mode == "stationary": check(sample.hits > 0,"stationary target is threatened: " + String(id))
			if id == &"ash_hound" and mode == "retreat": check(sample.hits > 0,"hound can catch inattentive straight retreat")
			if mode == "evade": check(sample.hits == 0,"active lateral evasion remains effective: " + String(id))
			if mode == "cover": check(sample.hits == 0,"solid cover blocks actual contact: " + String(id))
			results.append(sample.duplicate(true))
			print("CONTACT ",JSON.stringify(sample))
			sample = {}
			enemy.free()
			if cover != null: cover.free()
			for shot in get_tree().get_nodes_in_group("enemy_projectiles"): shot.free()
			player.test_walk = Vector2.ZERO
			await frames(2)
	check(sim.export_json() == native_before,"contact audit changes no native ownership or progression")
	var path := ProjectSettings.globalize_path("res://../captures/contact-forge" if dungeon != null else "res://../captures/contact")
	DirAccess.make_dir_recursive_absolute(path)
	var file := FileAccess.open(path.path_join("contact.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":results},"  "))
	file.close()
	print("ENEMY_CONTACT_REVIEW %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _dodge_clearance(direction: Vector2) -> float:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.get_node("CollisionShape3D").shape
	query.transform = player.global_transform
	query.motion = Vector3(direction.x,0,direction.y) * player.move_speed * 1.25
	query.exclude = [player.get_rid()]
	var fractions := get_world_3d().direct_space_state.cast_motion(query)
	return fractions[0]
