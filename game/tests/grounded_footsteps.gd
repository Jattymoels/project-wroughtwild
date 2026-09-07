extends Node3D
## Actual CharacterBody3D motion/contact, then normal save and trial boundaries.
## Inspection support/map isolates audio; no terrain generation or paid-build claim.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var terrain: Terrain
var ground: StaticBody3D
var emitted: Array[String] = []
var sim: WroughtwildSim

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL GROUNDED_FOOTSTEPS: ", label)

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func body(size: Vector3, at: Vector3) -> StaticBody3D:
	var result := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	result.add_child(collider)
	add_child(result)
	result.position = at
	return result

func _ready() -> void:
	_run.call_deferred()

func reset(at := Vector3(8,1.97,60)) -> void:
	player.test_walk = Vector2.ZERO
	player.position = at
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.footsteps.reset_context()
	await frames(6)
	emitted.clear()

func walk(count := 60) -> void:
	player.test_walk = Vector2(0,-1)
	await frames(count)
	player.test_walk = Vector2.ZERO
	await frames(2)

func settle_on_support(label: String) -> void:
	# A reset pose starts slightly above the support. Begin each special-contact
	# walk only after actual floor contact has settled, rather than treating an
	# airborne approach as part of its grounded walking distance.
	var stable := 0
	for i in 120:
		await frames(1)
		stable = stable + 1 if player.is_on_floor() else 0
		if stable >= 3: break
	check(stable >= 3, label + ": capsule settles on its actual support before walking")
	player.footsteps.reset_context()
	emitted.clear()

func _run() -> void:
	terrain = Terrain.new()
	terrain.name = "Terrain"
	var biomes := PackedInt32Array()
	biomes.resize(16 * 80)
	var heights := PackedInt32Array()
	heights.resize(16 * 80)
	heights.fill(1)
	terrain.map = {"width":16,"height":80,"depth":4,"cell_size":1.0,"biomes":biomes,"heights":heights,
		"biome_defs":[{"id":"meadow","surface":"grass"}]}
	terrain._blocks.resize(16 * 80 * 4)
	for cell in 16 * 80: terrain._blocks[cell * 4] = 1
	add_child(terrain)
	ground = body(Vector3(16,1,80), Vector3(8,.5,40))
	ground.set_meta("terrain_chunk", true)
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(8,1.97,60)
	add_child(player)
	player.class_panel.choose("warden")
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.trial.set_process(false)
	player.footsteps.stepped.connect(func(surface: String, _at: Vector3): emitted.append(surface))
	sim = player.inventory.get_sim()
	var native_before := sim.export_json()
	await reset()
	await frames(60)
	check(emitted.is_empty(), "stationary support emits no steps")
	for row in [["grass","grass"],["forest_floor","grass"],["marsh","grass"],["ash","earth"],["rock","stone"]]:
		tterrain_surface(String(row[0]))
		await reset()
		await walk()
		check(player.position.z < 56 and player.is_on_floor(), String(row[0]) + ": real walk on contact")
		check(not emitted.is_empty() and emitted.all(func(s): return s == row[1]), String(row[0]) + ": truthful surface contacts")
	# The same column can expose a subsurface material after excavation; use the
	# real ray/cell lookup and current block field, not its original biome skin.
	for id in [2,3,4]:
		for cell in 16 * 80: terrain._blocks[cell * 4] = id
		await reset()
		await walk()
		check(not emitted.is_empty() and emitted.all(func(s): return s == ("earth" if id == 2 else "stone")), "current support block overrides biome " + str(id))
	for cell in 16 * 80: terrain._blocks[cell * 4] = 1
	# Standing on constructed material must override the generated ground below.
	for row in [["wood","timber"],["resinheart","timber"],["woven_reed","fibre"],["slate","stone"],["cinderglass","stone"]]:
		var slab := PlacedBlock.new()
		add_child(slab)
		slab.init_piece(&"cube",StringName(row[0]),{"kind":"block","axis":0,"cell":Vector3i(8,1,60)},0,"box",Vector3(8,.5,16),Vector3(8,1.25,56),0)
		await reset(Vector3(8,2.47,60))
		await walk()
		check(not emitted.is_empty() and emitted.all(func(s): return s == row[1]), String(row[0]) + ": placed support wins over terrain")
		slab.free()
	var threshold := PlacedBlock.new()
	add_child(threshold)
	threshold.init_piece(&"cube",&"wood",{"kind":"block","axis":0,"cell":Vector3i(8,1,55)},0,"box",Vector3(8,.5,8),Vector3(8,1.25,55),0)
	await reset()
	await walk(85)
	check(player.position.z < 54 and absf(player.position.y - 2.46) < .08, "original half-metre step handling climbs the constructed threshold")
	check(player.footsteps.last_surface == "timber" and absf(player.footsteps.last_position.y - 1.5) < .03, "step-up contact samples the new upper support")
	threshold.free()
	var ramp := PlacedBlock.new()
	add_child(ramp)
	ramp.init_piece(&"cube",&"wood",{"kind":"block","axis":0,"cell":Vector3i(8,1,56)},0,"box",Vector3(8,.2,10),Vector3(8,2.2,56),0)
	ramp.rotation.x = .12
	await reset(Vector3(8,2.85,60))
	await settle_on_support("sloped timber")
	await walk()
	check(player.is_on_floor() and player.position.y > 3.2, "real capsule climbs a shallow sloping constructed surface")
	check(not emitted.is_empty() and emitted.all(func(s): return s == "timber"), "slope contacts retain their actual material: %s at %s" % [str(emitted), str(player.position)])
	ramp.free()
	var edge := PlacedBlock.new()
	add_child(edge)
	edge.init_piece(&"cube",&"wood",{"kind":"block","axis":0,"cell":Vector3i(8,1,56)},0,"box",Vector3(.2,.5,16),Vector3(8,1.25,56),0)
	await reset(Vector3(8.23,2.47,60))
	await settle_on_support("narrow timber ledge")
	await walk()
	check(player.is_on_floor() and player.position.y > 2.4 and player.position.x > 8.1, "capsule remains supported with its centre beyond a narrow ledge")
	check(not emitted.is_empty() and emitted.all(func(s): return s == "timber"), "actual edge contact supplies footsteps when the centre ray misses: %s at %s" % [str(emitted), str(player.position)])
	edge.free()
	await reset()
	var wall := body(Vector3(8,4,.3),Vector3(8,3,57))
	await walk(90)
	emitted.clear()
	await walk(60)
	check(emitted.is_empty() and player.position.z > 57.3, "pushing an actual wall produces no repeated footfalls")
	wall.free()
	await reset()
	player.velocity.y = 5
	player.test_walk = Vector2(0,-1)
	await frames(22)
	check(not player.is_on_floor() and emitted.is_empty(), "airborne travel is silent")
	player.test_walk = Vector2.ZERO
	await frames(50)
	check(emitted.is_empty(), "landing does not invent a walking step or catch up air distance")
	await reset()
	player.combat._dash_left = 3
	player.combat._dash_velocity = Vector3(0,0,-8)
	await frames(60)
	check(player.position.z < 54 and emitted.is_empty(), "real grounded dash does not become a footstep burst")
	player.combat._dash_left = 0
	player.combat._dash_velocity = Vector3.ZERO
	await reset()
	player.test_walk = Vector2(0,-1)
	await frames(5)
	player.position.z -= 25
	player.test_walk = Vector2.ZERO
	await frames(3)
	check(emitted.is_empty(), "long teleport discards partial stride")
	await reset()
	player.test_walk = Vector2(0,-1)
	player.set_physics_process(false)
	await frames(60)
	check(emitted.is_empty(), "disabled chooser/play produces no footsteps")
	player.test_walk = Vector2.ZERO
	player.set_physics_process(true)
	await frames(5)
	check(emitted.is_empty(), "reenabling play has no catch-up footfall")
	for panel in [player.inventory_panel, player.work_panel, player.foundry_panel, player.chest_panel, player.build_palette]:
		await reset()
		if panel == player.inventory_panel: player.toggle_inventory()
		elif panel == player.work_panel: player.open_hand_crafting()
		elif panel == player.foundry_panel: player.toggle_foundry()
		elif panel == player.chest_panel: continue # Actual chest panel state is covered by home persistence.
		else: player.build_palette.open_panel()
		await walk(40)
		check(emitted.is_empty(), "open " + panel.get_class() + " panel does not accumulate steps")
		panel.close_panel()
	check(sim.export_json() == native_before, "walking, jumping, materials and presentation preserve native state")
	await reset()
	# Seedless save uses the normal existing support scene. No synthetic map is
	# passed to terrain restoration; generated restore is covered by regressions.
	terrain.free()
	terrain = null
	ground.remove_meta("terrain_chunk")
	var manager := SaveManager.new()
	var saved := manager.capture(player)
	player.footsteps.after_motion(player.position - Vector3(.5,0,0), true, false, 1.0/60)
	emitted.clear()
	check(manager.apply(player, JSON.parse_string(JSON.stringify(saved))), "same-position native/world save applies")
	await frames(5)
	check(emitted.is_empty(), "save restoration emits no step")
	check(manager.capture(player).sim == saved.sim, "restoration preserves native ownership")
	var arena := preload("res://scenes/trial_arena.tscn").instantiate()
	add_child(arena)
	arena.position = Vector3(200,0,200)
	check(player.trial.begin_legacy_run(), "real trial entry succeeds")
	player.work_panel.close_panel()
	await frames(12)
	check(emitted.is_empty(), "trial entry/settling does not produce relocation footsteps")
	await walk(50)
	check(not emitted.is_empty() and emitted.all(func(s): return s == "stone"), "actual trial floor contact remains audible")
	emitted.clear()
	player.trial.finish_run()
	await frames(6)
	check(emitted.is_empty(), "extraction clears partial trial stride")
	check(manager.capture(player).sim == saved.sim, "empty trial extraction preserves inventory and progression")
	print("GROUNDED_FOOTSTEPS %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func tterrain_surface(surface: String) -> void:
	terrain.map.biome_defs[0].surface = surface
