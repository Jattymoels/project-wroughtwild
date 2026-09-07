extends Node3D
## Real controller, boss and damage clocks; presentation never supplies a hit.
var player: WroughtwildPlayer
var sim: WroughtwildSim
var trial: TrialController
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: forge tells: ", message)

func near(actual: float, expected: float, message: String) -> void:
	check(absf(actual - expected) < 0.0001, message)

func settle(frames := 3) -> void:
	for i in frames: await get_tree().physics_frame

func _ready() -> void:
	_body(Vector3(0, -0.25, 0), Vector3(50, 0.5, 50))
	var arena := preload("res://scenes/trial_arena.tscn").instantiate()
	arena.position = Vector3(90, 0, 0)
	add_child(arena)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	trial = player.trial
	trial.set_process(false)
	trial.seed_source.seed = 7147
	sim = player.inventory.get_sim()
	await settle()
	for run in ["forge_tyrant", "deep_forge", "forge_capstone"]:
		if run == "deep_forge": sim.record_world_effect("stonecut_blocks")
		if run == "forge_capstone": sim.record_world_effect("ash_tide")
		check(trial.begin_run(run), "actual story controller begins " + run)
		await _boss(run)
		if run == "forge_tyrant": await _hazards()
		trial.on_player_died()
		await settle()
	await _burning_ground()
	_cache_budget()
	print("FORGE_TELLS %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _body(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	return body

func _boss(run: String) -> void:
	player.position = Vector3(0, 0.96, -5)
	player.combat.restore_life()
	player.combat.invulnerable_left = 0
	var boss := Boss.spawn_boss(self, Vector3.ZERO)
	boss.set_physics_process(false)
	trial._make_relentless(boss)
	boss.look_at(Vector3(0, 0, -5))
	await settle()
	var definition := sim.boss()
	near(boss.breath_damage, float(definition.breath_damage) * float(trial.run_mods.get("enemy_damage_multiplier", 1)), run + " native breath damage retained")
	var dimensions := Vector2(boss.breath_range, boss.breath_cone_degrees)
	var collision_before: Transform3D = boss.get_node("CollisionShape3D").transform
	var saved := sim.export_json()
	var lives := player.combat.life
	boss._breath_timer = 0
	boss._physics_process(0.01)
	check(boss.state == "inhale" and is_instance_valid(boss._floor_tell), run + " normal state machine begins a committed warning")
	check(boss._label.text.contains("(FIRE)" if run == "forge_tyrant" else "(SWEEP)") and not boss._label.text.contains("INHALING"), run + " names the actual committed attack")
	var tell := boss._tell_boundary
	near(tell.warning_progress, 0, run + " warning starts with the full unchanged interval")
	_check_outline(tell, func(p: Vector2) -> bool:
		return p.length() <= dimensions.x + 0.0001 and (p.length() <= 0.001 or absf(atan2(p.x, -p.y)) <= deg_to_rad(dimensions.y * 0.5) + 0.0001), run + " cone")
	check(boss._floor_tell.material_override.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, run + " warning fill remains readable without local lighting")
	check(boss.get_node("CollisionShape3D").transform == collision_before and Vector2(boss.breath_range, boss.breath_cone_degrees) == dimensions, run + " presentation leaves attack/body extents unchanged")
	var fixed_facing := boss.global_basis
	player.position.x = 4
	boss._physics_process(boss.breath_telegraph_seconds * 0.25)
	near(tell.warning_progress, 0.25, run + " edge follows existing warning clock")
	check(boss.global_basis.is_equal_approx(fixed_facing), run + " moving player does not redirect the committed cone")
	near(player.combat.life, lives, run + " warning cannot deal early damage")
	var left := boss._telegraph_left
	var progress := tell.warning_progress
	boss.stagger(0.5)
	boss._physics_process(0.2)
	near(boss._telegraph_left, left, run + " existing stagger pauses rather than cancels inhale")
	near(tell.warning_progress, progress, run + " presentation pauses with the staggered clock")
	boss._physics_process(0.31)
	check(boss.state == "inhale" and tell.warning_progress > progress, run + " warning resumes when existing stagger ends")
	# Freeze is the existing interrupt and must remove the old warning now.
	var frozen_tell := boss._floor_tell
	boss.apply_chill(boss._chill_max)
	check(boss.is_frozen() and boss.state == "chase" and boss._floor_tell == null, run + " freeze cancels the committed attack and its marker")
	check(not frozen_tell.visible and frozen_tell.is_queued_for_deletion(), run + " canceled marker is immediately hidden")
	near(player.combat.life, lives, run + " interrupted warning pays no hit")
	boss.thaw()
	await settle()
	boss.force_inhale()
	boss._begin_trial_tell()
	player.position = Vector3(5, 0.96, 1)
	boss._physics_process(boss.breath_telegraph_seconds)
	near(player.combat.life, lives, run + " leaving the full marked arc avoids the hit")
	check(boss._floor_tell == null and boss._label.text.contains("(RECOVERING)"), run + " release replaces warning with the current recovery state")
	near(boss._recovery_left, float(trial.rules.boss_recovery_seconds) * float(trial.run_mods.get("boss_recovery_multiplier", 1)), run + " native recovery duration is unchanged")
	check(not boss.guards_against(boss.global_position + Vector3.FORWARD * 4), run + " recovery label agrees with existing guard downtime")
	var recovery := boss._recovery_left
	boss._physics_process(recovery - 0.001)
	check(boss._label.text.contains("(RECOVERING)"), run + " label lasts through the recovery interval")
	boss._physics_process(0.0011)
	check(not boss._label.text.contains("RECOVERING"), run + " recovery label ends at existing expiry")
	if run != "forge_tyrant":
		check(boss.guards_against(boss.global_position - boss.global_basis.z * 4), run + " frontal guard resumes after its opening")
	# A live hit and a blocked ray use the same old predicates and damage path.
	player.position = boss.global_position + Vector3(0, 0.96, -5)
	boss.look_at(Vector3(player.position.x, boss.position.y, player.position.z))
	boss.force_inhale()
	boss._begin_trial_tell()
	var before_hit := player.combat.life
	boss.breathe(player)
	check(player.combat.life < before_hit, run + " inside arc still receives the existing committed hit")
	player.combat.restore_life()
	var cover := _body(Vector3(0, 1.0, -2.5), Vector3(2, 2.5, 0.3))
	await settle()
	boss.force_inhale()
	boss._begin_trial_tell()
	before_hit = player.combat.life
	boss.breathe(player)
	near(player.combat.life, before_hit, run + " solid cover still blocks the existing attack")
	cover.queue_free()
	boss.force_inhale()
	boss._begin_trial_tell()
	var death_tell := boss._floor_tell
	boss.take_damage(boss.life + 1, false)
	check(boss._floor_tell == null and not death_tell.visible, run + " dead owner cannot leave a pending danger marker")
	check(sim.export_json() == saved, run + " geometry and tested clocks leave the native run/economy unchanged")
	await settle()

func _check_outline(tell: ForgeTell, contains: Callable, label: String) -> void:
	check(tell.get_child_count() == 2, label + " has exactly two bounded edge meshes")
	var all_inside := true
	var vertices := 0
	for edge: MeshInstance3D in tell.get_children():
		var array: PackedVector3Array = edge.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in array:
			vertices += 1
			all_inside = all_inside and bool(contains.call(Vector2(vertex.x, vertex.z)))
		check(edge.cast_shadow == GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, label + " edge casts no distracting floor shadow")
	check(vertices > 0 and vertices <= 12 * (ForgeTell.LOOK.arc_segments + 2), label + " mesh tessellation remains bounded")
	check(all_inside, label + " every edge vertex stays inside the actual affected footprint")
	check(not (tell.get_node("DarkEdge").material_override as BaseMaterial3D).no_depth_test, label + " dark edge respects solid cover")
	check(not ForgeTell.EDGE.code.contains("depth_test_disabled"), label + " progress shader keeps depth testing")

func _hazards() -> void:
	var config: Dictionary = trial.rules.duplicate(true)
	for size in [Vector2.ZERO, Vector2(16, 2.8), Vector2(2.8, 16)]:
		player.combat.restore_life()
		player.combat.invulnerable_left = 0
		player.position = Vector3(6, 0.96, 0)
		var hazard := trial.spawn_hazard(Vector3(6, 0, 0), config, size)
		hazard.set_physics_process(false)
		var label := "disc" if size == Vector2.ZERO else "lane " + str(size)
		var dimensions := Vector3(hazard.radius, hazard.lane_size.x, hazard.lane_size.y)
		_check_outline(hazard.boundary, func(p: Vector2) -> bool:
			return p.length() <= hazard.radius + 0.0001 if size == Vector2.ZERO else absf(p.x) <= size.x * 0.5 + 0.0001 and absf(p.y) <= size.y * 0.5 + 0.0001, label)
		near(hazard.boundary.warning_progress, 0, label + " warning begins at zero elapsed")
		var inside := Vector3(hazard.radius - 0.001, 0, 0) if size == Vector2.ZERO else Vector3(size.x * 0.5 - 0.001, 0, 0)
		var outside := inside + Vector3.RIGHT * 0.002
		check(hazard.contains_point(hazard.to_global(inside)) and not hazard.contains_point(hazard.to_global(outside)), label + " exact old boundary predicate remains")
		var life := player.combat.life
		var total := hazard.tell_left
		var active_time := hazard.active_left
		hazard.advance(total * 0.5)
		near(hazard.boundary.warning_progress, 0.5, label + " visible progress uses exact existing clock")
		near(player.combat.life, life, label + " warning does no damage")
		near(hazard.active_left, active_time, label + " warning cannot consume active duration")
		hazard.advance(total * 0.5)
		check(hazard.boundary.active and hazard.material.albedo_color == ForgeTell.LOOK.active_fill, label + " exact warning boundary switches to active appearance")
		near(player.combat.life, life, label + " no hit is invented at a zero-leftover clock boundary")
		hazard.advance(0.01)
		check(player.combat.life < life, label + " first active interval retains existing damage")
		life = player.combat.life
		hazard.advance(hazard.tick_seconds * 0.5)
		near(player.combat.life, life, label + " extra visual progress cannot add damage ticks")
		check(Vector3(hazard.radius, hazard.lane_size.x, hazard.lane_size.y) == dimensions, label + " active phase never expands or shrinks damage extent")
		player.position.x = 25
		hazard.advance(hazard.active_left + 0.01)
		check(hazard.spent and not hazard.mesh.visible and not hazard.is_in_group("trial_hazards"), label + " expiry immediately clears active appearance and hazard ownership")
		await settle()
	config.hazard_telegraph_seconds = 0.0
	var instant := trial.spawn_hazard(Vector3.ZERO, config)
	instant.set_physics_process(false)
	check(instant.boundary.active and instant.material.albedo_color == ForgeTell.LOOK.active_fill, "an existing zero-warning configuration never advertises a false preparation interval")
	instant.cancel()
	await settle()

func _burning_ground() -> void:
	player.combat.restore_life()
	player.combat.invulnerable_left = 0
	player.position = Vector3(2.9, 0.96, 0)
	var ground := BurningGround.spawn(self, Vector3.ZERO,
		{"radius_m": 3.0, "seconds": 5.0, "damage_per_round": 2.0}, 1.0)
	ground.set_process(false)
	var original := ground._mesh.mesh.get_aabb()
	var life := player.combat.life
	ground._process(4.0)
	check(player.combat.life < life, "late burning ground still affects the original outer radius")
	check(ground._mesh.scale == Vector3.ONE and ground._mesh.mesh.get_aabb() == original, "late burning ground still shows its full affected radius")
	near(ground._mesh.material_override.albedo_color.a, ForgeTell.LOOK.burning_ground_initial_alpha * 0.2, "burning ground fades opacity with existing remaining life")
	ground._process(1.01)
	check(ground.is_queued_for_deletion(), "burning ground keeps its existing expiry")
	await settle()

func _cache_budget() -> void:
	var fixture := MeshInstance3D.new()
	add_child(fixture)
	var first := ForgeTell.attach(fixture, ForgeTell.disc(2.8))
	var second := ForgeTell.attach(fixture, ForgeTell.disc(2.8))
	check(first.get_node("DarkEdge").mesh == second.get_node("DarkEdge").mesh, "equal danger extents share outline geometry")
	first.set_warning(0.25, 1.0)
	near(second.warning_progress, 0.0, "shared geometry keeps per-warning progress independent")
	for i in 40:
		var tell := ForgeTell.attach(fixture, ForgeTell.disc(1.0 + i))
		tell.free()
	check(ForgeTell._meshes.size() <= ForgeTell.LOOK.mesh_cache_limit, "unusual preview dimensions cannot grow the mesh cache without bound")
	fixture.queue_free()
