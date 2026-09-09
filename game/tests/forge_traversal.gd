extends Node3D
## Walk the native Forge route with the normal player capsule and E ray.
## Forced encounter clears isolate traversal and ownership, not combat balance.
const CHECKPOINT := "res://../build/intensives/forge-traversal.json"
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var trial: TrialController
var arena: TrialArena
var walked_metres := 0.0
var modules_seen := {}
var reward_refresh_msec: Array[float] = []


func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FORGE_TRAVERSAL: ", label)
	return ok


func frames(count := 3) -> void:
	for i in count: await get_tree().physics_frame


func _ready() -> void:
	_run.call_deferred()


func _run() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.combat.invulnerable_left = 100000
	trial = player.trial
	trial.set_process(false)
	sim = player.inventory.get_sim()
	arena = preload("res://scenes/trial_arena.tscn").instantiate()
	add_child(arena)
	if "--fixture-nav-audit" in OS.get_cmdline_user_args():
		await _dynamic_fixture_probe()
	else:
		await _native_route()
		print("FORGE_ROUTE_NAV reward_refresh_ms=", reward_refresh_msec)
	print("FORGE_TRAVERSAL %d checks, %d failures; %.1f m actual walking; %d module treatments" % [checks, failures, walked_metres, modules_seen.size()])
	get_tree().quit(1 if failures else 0)


func _settle_navigation(dungeon: ForgeDungeon) -> void:
	for i in 120:
		if NavigationServer3D.region_get_iteration_id(dungeon.region.get_rid()) > 0 \
			and NavigationServer3D.map_get_iteration_id(dungeon.navigation_map) > 1: return
		await frames(1)
	check(false, "current Forge navigation becomes ready")


func _settle_refresh(dungeon: ForgeDungeon, previous_build: int, previous_iteration: int) -> void:
	for i in 120:
		if dungeon.navigation_build_count > previous_build and NavigationServer3D.map_get_iteration_id(dungeon.navigation_map) > previous_iteration:
			await frames(2)
			return
		await frames(1)
	check(false, "runtime fixture change synchronises its current navigation mesh")


func _check_navigation_parity(dungeon: ForgeDungeon, label: String) -> void:
	# Retain the original complete-floor raster as an independent reference for
	# the eligible-cell cache. This is a refactor parity check, not an endpoint
	# tolerance; every walkable cell must agree with all current solid bodies.
	var expected := {}
	for rect in dungeon.floor_rects:
		for x in range(ceili(rect.position.x), floori(rect.end.x)):
			for z in range(ceili(rect.position.y), floori(rect.end.y)):
				var cell := Vector2i(x, z)
				if expected.has(cell): continue
				var blocked := false
				var margin: float = ForgeDungeon.LOOK.navigation_clearance
				for offset in [Vector2(-margin,-margin),Vector2(margin,-margin),Vector2(-margin,margin),Vector2(margin,margin)]:
					var inside := false
					for floor_rect in dungeon.floor_rects:
						if floor_rect.has_point(Vector2(x + .5, z + .5) + offset): inside = true; break
					if not inside: blocked = true; break
				for obstacle in dungeon.obstacles:
					if obstacle.grow(margin).intersects(Rect2(x, z, 1, 1)): blocked = true; break
				if not blocked: expected[cell] = true
	check(dungeon._walk_cells == expected, label + ": cached eligible cells exactly match the original complete-floor raster (%d cells)" % expected.size())


func _verify_floor_cache(dungeon: ForgeDungeon) -> void:
	var label := "native floor %d" % dungeon.floor_index
	var initial_cells := dungeon._walk_cells.duplicate()
	_check_navigation_parity(dungeon, label + " with its authored fixtures")
	var room: Dictionary = dungeon.rooms.values()[0]
	var before_build := dungeon.navigation_build_count
	var before_iteration := NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)
	var temporary := dungeon._fixture("reward", room.centre + Vector3(0, 0, 7), "Cache verification", "temporary test collider")
	await _settle_refresh(dungeon, before_build, before_iteration)
	_check_navigation_parity(dungeon, label + " with an added physical offering")
	before_build = dungeon.navigation_build_count
	before_iteration = NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)
	temporary.queue_free()
	await _settle_refresh(dungeon, before_build, before_iteration)
	_check_navigation_parity(dungeon, label + " after the offering is removed")
	check(dungeon._walk_cells == initial_cells, label + ": removal restores precisely the original traversable cells")


func _settle_player() -> void:
	player.test_walk = Vector2.ZERO
	var stable := 0
	for i in 120:
		await frames(1)
		stable = stable + 1 if player.is_on_floor() else 0
		if stable >= 3: return
	check(false, "capsule settles on the actual Forge floor")


func _walk_to(target: Vector3, stop_distance := .18) -> bool:
	var initial := Vector2(target.x - player.global_position.x, target.z - player.global_position.z).length()
	var budget := ceili(initial / player.move_speed * Engine.physics_ticks_per_second) + 180
	for i in budget:
		var to := target - player.global_position
		to.y = 0.0
		if to.length() <= stop_distance:
			player.test_walk = Vector2.ZERO
			return true
		var direction := player.global_transform.basis.inverse() * to.normalized()
		player.test_walk = Vector2(direction.x, direction.z)
		var before := player.global_position
		await frames(1)
		walked_metres += Vector2(player.global_position.x - before.x, player.global_position.z - before.z).length()
	player.test_walk = Vector2.ZERO
	check(false, "capsule reaches path point %s from %s; stopped at %s" % [str(target), str(initial), str(player.global_position)])
	return false


func _reach(fixture: TrialFixture, label: String) -> bool:
	var dungeon := arena.dungeon
	await _settle_navigation(dungeon)
	var path := dungeon.path(player.global_position, fixture.global_position)
	if not check(path.size() >= 2, label + ": connected navigation route"): return false
	var path_end_gap := Vector2(path[-1].x - fixture.global_position.x, path[-1].z - fixture.global_position.z).length()
	for i in path.size():
		var final_point := i == path.size() - 1
		if not await _walk_to(path[i], maxf(.18, 1.3 - path_end_gap) if final_point else .18): return false
	await _settle_player()
	var aim := fixture.global_position + Vector3.UP * 1.05
	var offset := aim - player.camera.global_position
	player.look_at(Vector3(aim.x, player.global_position.y, aim.z))
	player.spring_arm.rotation.x = atan2(offset.y, Vector2(offset.x, offset.z).length())
	await frames(2)
	var probe := player.aim_probe()
	return check(probe.get("target") == fixture, label + ": real first-person E ray selects fixture from reachable ground at %s" % str(player.global_position))


func _native_route() -> void:
	trial.seed_source.seed = 7146
	if not check(await _start_native_route(), "normal native first Trial route starts"): return
	await _settle_player()
	await _settle_navigation(arena.dungeon)
	await _verify_floor_cache(arena.dungeon)
	# The optional store is an actual detour from the entrance, not a teleport.
	var secret := arena.dungeon.secret
	if await _reach(secret, "optional furnace store"):
		var before := sim.trial_loot().duplicate(true)
		player.interact()
		check(secret.claimed and sim.trial_loot() != before, "real E claims the existing optional store")
		var claimed := sim.trial_loot().duplicate(true)
		player.interact()
		check(sim.trial_loot() == claimed, "repeated E cannot duplicate the secret")
		modules_seen["secret_crucible"] = true
	var encountered := 0
	while trial.active() and encountered < 8:
		if trial.state == "boundary":
			await _boundary_restore()
			if not check(trial.continue_floor(), "existing cleared-floor Continue enters floor two"): return
			await _settle_player()
			await _settle_navigation(arena.dungeon)
			await _verify_floor_cache(arena.dungeon)
			continue
		if not check(trial.state == "exploring", "next stage waits for an actual route choice"): return
		var stage: Dictionary = sim.trial_stage()
		var index := int(stage.index)
		var choices: Array = stage.choices
		# Both plaques are physically approachable and readable before choosing.
		for choice in range(choices.size() - 1, -1, -1):
			var other: TrialFixture = arena.dungeon.rooms["%d:%d" % [index, choice]].door
			var before_choice := sim.trial_run_state().duplicate(true)
			if not await _reach(other, "stage %d route %d" % [index, choice]): return
			check(other.available and sim.trial_run_state() == before_choice, "inspecting a branch changes no route, encounter or rewards")
			var ray := PhysicsRayQueryParameters3D.create(player.camera.global_position, other.label.global_position)
			ray.exclude = [player, other]
			check(get_world_3d().direct_space_state.intersect_ray(ray).is_empty(), "route label centre is not buried behind a solid wall")
		var room: Dictionary = arena.dungeon.rooms["%d:0" % index]
		player.interact()
		if not check(trial.state == "fighting" and trial.current_stage_index == index, "real E opens exactly the selected route"): return
		for enemy in trial.trial_enemies(): enemy.set_physics_process(false)
		await frames()
		# Walk through its real doorway into the authored encounter space before
		# the forced clear; this checks the capsule, not only a navigation line.
		var destination: Vector3 = arena.dungeon.to_global(room.centre + Vector3(0, 0, 7))
		var path := arena.dungeon.path(player.global_position, destination)
		check(path.size() >= 2, "selected chamber has a connected doorway")
		for point in path:
			if not await _walk_to(point, .3): return
		check((room.rect as Rect2).has_point(Vector2(arena.dungeon.to_local(player.global_position).x, arena.dungeon.to_local(player.global_position).z)), "capsule enters the actual selected " + String(room.module))
		modules_seen[String(room.module)] = true
		await _clear_encounter()
		if not check(trial.state == "reward", "clearing exposes the existing physical reward"): return
		if not await _reach(arena.dungeon.reward, "stage %d recovered offering" % index): return
		reward_refresh_msec.append(arena.dungeon.navigation_last_build_usec / 1000.0)
		print("FORGE_ROUTE stage=%d floor=%d module=%s walked=%.1fm nav_refresh=%.3fms" % [index, arena.dungeon.floor_index, room.module, walked_metres, reward_refresh_msec[-1]])
		player.interact()
		if not trial.current_offer.is_empty(): trial.accept_boon(String(trial.current_offer[0].id))
		elif trial.state == "reward" and trial.active(): trial.skip_offer()
		encountered += 1
		await frames()
	check(encountered == 8 and not trial.active(), "actual route completes all eight native encounters and extracts at its existing boss reward")
	check(modules_seen.size() == 8, "physical walkthrough covers all eight existing module treatments")

func _start_native_route() -> bool:
	return trial.begin_run("forge_tyrant")


func _clear_encounter() -> void:
	for pass_index in 20:
		for enemy in trial.trial_enemies():
			enemy.set_physics_process(false)
			enemy.take_damage(1000000000)
		for hazard in trial._hazards(): hazard.cancel()
		trial._tick_spatial(20.0)
		for enemy in trial.trial_enemies(): enemy.set_physics_process(false)
		await frames(1)
		if trial.trial_enemies().is_empty() and trial.wave_queue.is_empty(): break
	for hazard in trial._hazards(): hazard.cancel()
	trial._process(0.0)


func _boundary_restore() -> void:
	if not await _reach(arena.dungeon.boundary, "cleared-floor descent lift"): return
	player.interact()
	check(player.work_panel.is_open() and trial.state == "boundary", "actual lift E exposes Continue, bank and suspend")
	var path:=checkpoint_path()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path).get_base_dir())
	var economy := sim.export_json()
	var haul := sim.trial_loot().duplicate(true)
	var life := player.combat.life
	if not check(trial.suspend_to(path), "reached lift saves the exact cleared-floor checkpoint"): return
	trial.on_player_died()
	var manager:=SaveManager.new()
	if not check(manager.read(path, player), "normal save restore rebuilds the cleared floor: "+manager.last_error): return
	await _settle_player()
	check(sim.export_json() == economy and sim.trial_loot() == haul and player.combat.life == life, "restoring presentation preserves exact deposit, haul and life")
	check(arena.dungeon.secret.claimed, "restored optional store remains spent")
	if await _reach(arena.dungeon.boundary, "restored descent lift"):
		player.interact()
		check(player.work_panel.is_open() and trial.state == "boundary", "restored first-person pose can use the same physical lift")

func checkpoint_path() -> String:
	return CHECKPOINT


func _dynamic_fixture_probe() -> void:
	# Isolated diagnostic for the existing runtime conduit body: no encounter
	# difficulty, damage, reward or generation data is modified by this probe.
	var layout := {"seed": 7146, "stages": [{"index": 0, "floor_index": 0,
		"choices": [{"module": "heart_forge", "display_name": "Heart Forge", "encounter": [], "reward": "completion"}]}]}
	var dungeon := arena.build_floor(layout, 0)
	await _settle_navigation(dungeon)
	var room: Dictionary = dungeon.rooms["0:0"]
	var centre: Vector3 = room.centre
	var original_map := dungeon.navigation_map
	var original_region := dungeon.region.get_instance_id()
	var before_build := dungeon.navigation_build_count
	var before_iteration := NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)
	var conduit_cell := Vector2i(centre.x, centre.z - 9)
	check(dungeon._walk_cells.has(conduit_cell), "runtime conduit starts on genuinely traversable ground")
	var fixture := dungeon._fixture("conduit", centre + Vector3(0, 0, -9), "Ward conduit", "cool the ward")
	fixture.available = true
	fixture.refresh()
	for x in [-7.0, 7.0]: dungeon._fixture("conduit", centre + Vector3(x, 0, 7), "Ward conduit", "cool the ward")
	await _settle_refresh(dungeon, before_build, before_iteration)
	check(dungeon.navigation_build_count == before_build + 1, "three runtime conduits coalesce into one navigation refresh")
	check(dungeon.navigation_map == original_map and dungeon.region.get_instance_id() == original_region, "runtime refresh reuses the floor's map and region")
	check(not dungeon._walk_cells.has(conduit_cell), "runtime conduit removes its actual solid footprint from navigation")
	_check_navigation_parity(dungeon, "live conduit batch")
	var conduit_build_usec := dungeon.navigation_last_build_usec
	player.global_position = dungeon.to_global(centre + Vector3(0, 1, -11))
	await _settle_player()
	player.combat.invulnerable_left = 100000
	var boss := Boss.spawn_boss(self, dungeon.to_global(centre + Vector3(0, .5, -4)))
	boss.trial_bound = true
	boss.trial_dungeon = dungeon
	boss.jump_speed = 0.0
	boss._breath_timer = 100.0
	var start := boss.global_position.distance_to(player.global_position)
	await frames(480)
	var final_distance := boss.global_position.distance_to(player.global_position)
	var route := dungeon.path(boss.global_position, player.global_position)
	print("FIXTURE_NAV_AUDIT start=", start, " end=", final_distance, " claw_range=", boss.attack_range, " boss=", boss.global_position, " fixture=", fixture.global_position, " path=", route)
	check(final_distance <= boss.attack_range, "existing boss capsule negotiates a live conduit and reaches its actual claw range")
	boss.free()
	var reward_cell := Vector2i(room.reward_at.x, room.reward_at.z)
	check(dungeon._walk_cells.has(reward_cell), "offering starts on clear room floor")
	before_build = dungeon.navigation_build_count
	before_iteration = NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)
	var offering := dungeon.place_reward(room, "existing material haul")
	await _settle_refresh(dungeon, before_build, before_iteration)
	check(not dungeon._walk_cells.has(reward_cell), "physical reward adds its current solid footprint")
	var reward_build_usec := dungeon.navigation_last_build_usec
	var moved_room := room.duplicate()
	moved_room.reward_at = centre + Vector3(0, 0, 6)
	var moved_cell := Vector2i(moved_room.reward_at.x, moved_room.reward_at.z)
	check(dungeon._walk_cells.has(moved_cell), "replacement offering destination begins clear")
	before_build = dungeon.navigation_build_count
	before_iteration = NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)
	var old_offering_id := offering.get_instance_id()
	offering = dungeon.place_reward(moved_room, "next existing haul")
	await _settle_refresh(dungeon, before_build, before_iteration)
	check(dungeon.navigation_build_count == before_build + 1, "replacing a reward coalesces its addition and queued removal")
	check(dungeon._walk_cells.has(reward_cell) and not dungeon._walk_cells.has(moved_cell), "replacement restores old cells and excludes only the current reward")
	check(not dungeon._navigation_fixture_ids.has(old_offering_id), "queued-free reward has no stale collider in navigation")
	before_build = dungeon.navigation_build_count
	before_iteration = NavigationServer3D.map_get_iteration_id(dungeon.navigation_map)
	offering.queue_free()
	await _settle_refresh(dungeon, before_build, before_iteration)
	check(dungeon._walk_cells.has(moved_cell), "removing a reward restores its previously blocked cells")
	_check_navigation_parity(dungeon, "after dynamic offering removal")
	check(dungeon.navigation_map == original_map and dungeon.region.get_instance_id() == original_region, "all fixture replacements retain one map and region")
	print("FIXTURE_NAV_TIMING conduit_ms=%.3f reward_ms=%.3f peak_ms=%.3f builds=%d cells=%d" % [conduit_build_usec / 1000.0, reward_build_usec / 1000.0, dungeon.navigation_peak_build_usec / 1000.0, dungeon.navigation_build_count, dungeon._walk_cells.size()])
	before_build = dungeon.navigation_build_count
	dungeon._fixture("reward", centre + Vector3(0, 0, 6), "Transient", "floor leaving")
	player.set_physics_process(false)
	arena.clear_floor()
	check(not dungeon.navigation_map.is_valid() and not dungeon._navigation_refresh_queued and dungeon.navigation_build_count == before_build, "floor exit cancels its pending refresh and releases its navigation map")
	await frames(3)
