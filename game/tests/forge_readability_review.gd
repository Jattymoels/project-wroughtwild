extends Node3D
## Common preserved/current review using the actual world lighting, player rig,
## native story routes and real effects. Forced clears/held poses are inspection
## evidence, not combat calibration or a normal-duration playthrough.
var checks := 0
var failures := 0
var world: Sandpit
var player: WroughtwildPlayer
var trial: TrialController
var sim: WroughtwildSim
var output := ""
var report := {"captures":[],"route_labels":[]}
var form: Dictionary = {}
var samples: Array[float] = []
var measuring := false
var previous := 0
var cpu := Vector3.ZERO

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FORGE_READABILITY_REVIEW: ",label)

func _ready() -> void:
	_run.call_deferred()

func _process(_delta: float) -> void:
	if is_instance_valid(player): player.combat.invulnerable_left = 100
	if not measuring: return
	var now := Time.get_ticks_usec()
	if previous > 0: samples.append(float(now - previous) / 1000.0)
	previous = now
	cpu += Vector3(Performance.get_monitor(Performance.TIME_PROCESS)*1000,
		Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))

func frames(count := 3) -> void:
	for i in count: await get_tree().process_frame

func pose(local_at: Vector3, local_target: Vector3) -> void:
	var dungeon := trial.arena.dungeon
	player.global_position = dungeon.to_global(local_at - Vector3.UP * .72)
	player.velocity = Vector3.ZERO
	player.camera.global_position = dungeon.to_global(local_at)
	player.camera.look_at(dungeon.to_global(local_target))
	player.camera.make_current()
	player.hud._notice_timer = 0
	player.hud._notice.text = ""
	player.hud._refresh_crosshair()

func snap(id: String, description: String) -> void:
	if DisplayServer.get_name() == "headless": return
	# Fixture state jumps can finish before the normal 0.1-second HUD cadence.
	# Render the actual current state, not a previous room's cached objective.
	player.hud.refresh()
	await frames(4)
	await RenderingServer.frame_post_draw
	var file := id + ".png"
	check(get_viewport().get_texture().get_image().save_png(output.path_join(file)) == OK,"capture " + id)
	report.captures.append({"file":file,"description":description})

func _run() -> void:
	get_window().size = Vector2i(1280,720)
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	output = ProjectSettings.globalize_path("res://../captures/forge")
	DirAccess.make_dir_recursive_absolute(output)
	var start := Time.get_ticks_msec()
	world = preload("res://scenes/sandpit.tscn").instantiate()
	world.world_seed = 77
	add_child(world)
	report.world_startup_ms = Time.get_ticks_msec() - start
	player = world.player
	player.class_panel.choose("kindler")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	world.set_physics_process(false)
	world.mob_packs.set_physics_process(false)
	world.terrain.set_process(false)
	world.mood.set_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	sim = player.inventory.get_sim()
	trial = player.trial
	trial.set_process(false)
	trial.seed_source.seed = 193
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer"]: sim.foundry_event(event)
	sim.add_materials({"frost_catalyst":2,"preserving_catalyst":2,"iron_ingot":100})
	sim.foundry_place_skill(1,1,"prototype_ember_bolt")
	sim.foundry_place(1,0,"ember")
	sim.foundry_place_kind(2,0,"frost_catalyst")
	player.combat._mutation_cache.clear()
	form = sim.skill_mutation("prototype_ember_bolt")
	if "--performance-only" not in OS.get_cmdline_user_args():
		for run_id in ["forge_tyrant","deep_forge","forge_capstone"]:
			check(trial.begin_run(run_id),"start actual " + run_id)
			if trial.active(): await story(run_id)
			if run_id == "forge_tyrant": check(sim.set_curio("hill_cairn"),"existing Tyrant landmark transition")
			elif run_id == "deep_forge": check(sim.set_curio("drowned_altar"),"existing Warden landmark transition")
		check(sim.world_effect_active("forge_arc_complete"),"presentation walkthrough reaches existing capstone flag")
	if "--skip-performance" not in OS.get_cmdline_user_args(): await dense()
	report.checks = checks
	report.failures = failures
	report.scope = "Matched seed-77 actual world lighting/player rig/native Forge routes. Inspected poses and forced clears preserve existing rules but do not certify difficulty, human navigation or duration. Dense timing is separate, with no screenshot readbacks."
	var report_file := "performance.json" if "--performance-only" in OS.get_cmdline_user_args() else "manifest.json"
	var out := FileAccess.open(output.path_join(report_file),FileAccess.WRITE)
	check(out != null,"write isolated review manifest")
	if out != null: out.store_string(JSON.stringify(report,"  ")); out.close()
	print("FORGE_READABILITY_REVIEW %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func story(run_id: String) -> void:
	var guard := 0
	while trial.active() and guard < 12:
		guard += 1
		var dungeon := trial.arena.dungeon
		if trial.state == "boundary":
			var at := dungeon.boundary.position
			pose(at + Vector3(0,1.68,5),at + Vector3.UP*1.35)
			await snap(run_id + "-lift","Existing cleared-floor transition marker")
			trial.show_boundary()
			await snap(run_id + "-boundary-options","Continue, bank or suspend at the real cleared boundary")
			check(trial.continue_floor(),"continue actual " + run_id)
			continue
		var stage: Dictionary = sim.trial_stage()
		var index := int(stage.get("index",0))
		var choices: Array = stage.get("choices",[])
		if choices.is_empty(): check(false,"actual stage provides route choices"); break
		if run_id == "forge_tyrant" and index < 2:
			for c in choices.size():
				var room: Dictionary = dungeon.rooms["%d:%d" % [index,c]]
				var sign_side := signf(room.centre.x)
				pose(Vector3(0,1.68,room.centre.z + 10),Vector3(sign_side*6,1.4,room.centre.z + 4))
				var fixture: TrialFixture = room.door
				var query := PhysicsRayQueryParameters3D.create(player.camera.global_position,fixture.label.global_position)
				query.exclude = [player]
				var hit := get_world_3d().direct_space_state.intersect_ray(query)
				report.route_labels.append({"stage":index,"choice":c,"label":fixture.label.text,"ray_to_label_blocked":not hit.is_empty(),"collider":str(hit.get("collider",""))})
				await snap("junction-%d-%d" % [index,c],"Fixed first-person gallery approach, before entering a physical route")
		var selected := index % choices.size()
		var room: Dictionary = dungeon.rooms["%d:%d" % [index,selected]]
		check(trial.enter_room(selected),"native route enters existing chamber")
		for enemy in trial.trial_enemies(): enemy.set_physics_process(false)
		if index == 0 and run_id == "forge_tyrant":
			pose(room.centre + Vector3(6,1.68,8),room.centre + Vector3(0,1.3,-3))
			await snap("threshold-chamber","Existing module and live encounter, normal first-person height")
			if "--pressure-captures" in OS.get_cmdline_user_args():
				pose(room.centre + Vector3(0,1.68,8),room.centre + Vector3(0,1.3,-2))
				trial._tick_spatial(float(trial.rules.reinforcement_delay_seconds)-float(trial.rules.reinforcement_notice_seconds)+.01)
				await snap("reinforcement-warning","Actual HUD warning before the native reserve group arrives")
				trial._tick_spatial(float(trial.rules.reinforcement_notice_seconds)+.01)
				for enemy in trial.trial_enemies(): enemy.set_physics_process(false)
				await snap("mixed-reinforcements","Two native groups occupy entry lanes and rear cover inside the original chamber")
		for enemy in trial.trial_enemies():
			if enemy is Boss: await boss_views(run_id,enemy,room)
		var waves := 0
		while (not trial.trial_enemies().is_empty() or not trial.wave_queue.is_empty()) and waves < 30:
			waves += 1
			for enemy in trial.trial_enemies(): enemy.set_physics_process(false); enemy.take_damage(1000000000)
			for hazard in trial._hazards(): hazard.cancel()
			trial._tick_spatial(10)
			await frames(1)
		for hazard in trial._hazards(): hazard.cancel()
		trial._process(0)
		check(trial.state == "reward","clear exposes real physical offering")
		var offering: TrialFixture = dungeon.reward
		pose(offering.position + Vector3(-signf(room.centre.x)*2,1.68,3),offering.position + Vector3.UP*1.2)
		if run_id == "forge_tyrant" and index == 0: await snap("cleared-offering","Physical boon opportunity in its existing cleared chamber")
		trial.interact_fixture(offering)
		if trial.active() and trial.state == "reward": trial.skip_offer()
		await frames(1)
	check(not trial.active(),"story exits through its existing completion " + run_id)

func boss_views(run_id: String, boss: Boss, room: Dictionary) -> void:
	var dungeon := trial.arena.dungeon
	var centre: Vector3 = room.centre
	boss.global_position = dungeon.to_global(centre + Vector3(0,0,-4))
	boss.rotation = Vector3(0,PI,0)
	boss.velocity = Vector3.ZERO
	pose(centre + Vector3(4,1.68,8),centre + Vector3(0,1.2,-2))
	var field := FoundryField.spawn(player.combat,&"prototype_ember_bolt",dungeon.to_global(centre + Vector3(0,.08,1)),"rime",form)
	field.remaining = 100
	field.set_process(false)
	var fire := BurningGround.spawn(self,dungeon.to_global(centre + Vector3(2,0,1)),{"damage_per_round":0,"seconds":8,"radius_m":2.8},1)
	fire.set_process(false)
	fire._process(6)
	boss.force_inhale()
	boss._refresh_label()
	boss._begin_trial_tell()
	await snap(run_id + "-warning","Existing committed boss footprint against real Foundry and late burning-ground effects")
	boss._telegraph_left = boss.breath_telegraph_seconds * .35
	boss._physics_process(0)
	FoundryPuff.spawn(player.combat,dungeon.to_global(centre + Vector3(0,.15,1)),1.8,true)
	for puff in get_tree().get_nodes_in_group("foundry_puffs"): puff.elapsed = .3; puff._sample(); puff.set_process(false)
	await snap(run_id + "-late-warning","Late warning and real pressure vapour; original clock inspected without speeding an attack")
	boss.breathe(player)
	await snap(run_id + "-recovery","Existing recovery window after the committed attack")
	var lane := trial.spawn_hazard(dungeon.to_global(centre + Vector3(-2,0,0)),trial.rules,Vector2(2.6,12))
	lane.set_physics_process(false)
	lane.advance(float(trial.rules.hazard_telegraph_seconds) * .5)
	await snap(run_id + "-vent-warning","Existing furnace lane warning with overlapping owned fields")
	lane.advance(float(trial.rules.hazard_telegraph_seconds) * .5 + .01)
	await snap(run_id + "-vent-active","Active furnace footprint retains its original extent")
	lane.cancel()
	field.cancel()
	fire.queue_free()
	for puff in get_tree().get_nodes_in_group("foundry_puffs"): puff.queue_free()

func dense() -> void:
	check(trial.begin_run("forge_tyrant"),"dense fixture opens existing Forge")
	trial.set_process(false)
	var room: Dictionary = trial.arena.dungeon.rooms["0:0"]
	trial.arena.dungeon.open_room(0,0)
	var centre: Vector3 = room.centre
	pose(centre + Vector3(0,1.68,10),centre + Vector3(0,1,-2))
	var cohort: Array[Enemy] = []
	for i in 24:
		var enemy := Enemy.spawn(self,[&"ash_hound",&"ember_whelp",&"cinder_archer"][i%3],trial.arena.dungeon.to_global(centre + Vector3(-3.75+(i%6)*1.5,.5,-7+int(i/6)*1.5)))
		enemy.trial_bound = true
		enemy.trial_dungeon = trial.arena.dungeon
		enemy.aggro_range = 100
		enemy.give_up_distance = 0
		enemy.state = "chase"
		if i%3 == 0: enemy.apply_ignite(100,0,0,form)
		cohort.append(enemy)
	for x in [-2.5,2.5]:
		for z in [-3.5,.5]:
			var field := FoundryField.spawn(player.combat,&"prototype_ember_bolt",trial.arena.dungeon.to_global(centre + Vector3(x,.08,z)),"rime",form)
			field.remaining = 100
	var hazards := []
	for x in [-3.0,3.0]:
		var hazard := trial.spawn_hazard(trial.arena.dungeon.to_global(centre + Vector3(x,0,0)),trial.rules,Vector2(2.6,12))
		hazard.set_physics_process(false)
		hazard.advance(.5)
		hazards.append(hazard)
	# Warm for actual elapsed time so Godot's one-second performance monitors
	# no longer report scene construction or screenshot readback work.
	var warm_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - warm_start < 3000: await frames(1)
	samples.clear()
	previous = 0
	cpu = Vector3.ZERO
	measuring = true
	var sample_start := Time.get_ticks_msec()
	while Time.get_ticks_msec() - sample_start < 5000: await frames(1)
	measuring = false
	samples.sort()
	check(cohort.size() == 24 and cohort.all(func(e): return is_instance_valid(e) and e.life > 0),"dense population remains at original cap")
	report.dense = {"frames":samples.size(),"median_ms":samples[samples.size()/2],"p95_ms":samples[ceili(samples.size()*.95)-1],
		"mean_process_ms":cpu.x/samples.size(),"mean_physics_ms":cpu.y/samples.size(),"mean_draw_calls":cpu.z/samples.size(),
		"enemies":24,"ignites":8,"foundry_fields":4,"major_hazards":hazards.size(),"warmup_ms":3000,"sample_ms":Time.get_ticks_msec()-sample_start,"capture_readbacks":0}
	await snap("dense-encounter","Matched 24-enemy cohort, eight ignites, four Foundry fields and two fixed existing warning footprints")
	for enemy in cohort: enemy.queue_free()
