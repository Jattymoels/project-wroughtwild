extends Node3D
## Common baseline/current active-work timing. Fixed inspection stock, no save
## access, no gameplay RNG assertions replaced by timing, no new game rules.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var resource: ResourceNode
var station: StationSite
var sim: WroughtwildSim
var event_us: Array[float] = []
var max_voices := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL INTERACTION_ROUTE: ", label)

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_window().size = Vector2i(1280,720)
	Engine.max_fps = 0
	if DisplayServer.get_name() != "headless": DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position = Vector3(0,1,4)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	player.placement.set_physics_process(false)
	sim = player.inventory.get_sim()
	sim.add_materials({"raw_reed":200})
	sim.add_station("workbench")
	resource = ResourceNode.new()
	resource.visual = &"boulder"
	resource.material_family = &"stone"
	resource.remaining_units = 100
	resource.units_per_harvest = 1
	resource.drive_presses = 2
	resource.position = Vector3(-1,0,0)
	add_child(resource)
	station = preload("res://scenes/station_site.tscn").instantiate()
	station.station_id = &"workbench"
	station.upgrade_station_id = &""
	station.position = Vector3(1,0,0)
	add_child(station)
	var floor := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(12,12)
	floor.mesh = plane
	add_child(floor)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-30,0)
	add_child(sun)
	player.camera.look_at(Vector3(0,1,0))
	player.camera.make_current()
	for frame in 3: await get_tree().physics_frame
	var cold_started := Time.get_ticks_usec()
	_work_cycle()
	var cold_us := Time.get_ticks_usec()-cold_started
	# Three variants can warm without contaminating steady event measurements.
	for frame in 120:
		await get_tree().process_frame
		if frame%40 == 0: _work_cycle()
	event_us.clear()
	var times: Array[float] = []
	var previous := Time.get_ticks_usec()
	for frame in 720:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		times.append(float(now-previous)/1000.0)
		previous = now
		if frame%60 == 0:
			var started := Time.get_ticks_usec()
			_work_cycle()
			event_us.append(float(Time.get_ticks_usec()-started))
		max_voices = maxi(max_voices,get_tree().get_nodes_in_group("interaction_sounds").size())
	times.sort()
	event_us.sort()
	check(sim.material_count("woven_reed") == 64 and sim.material_count("stone") == 16,
		"sixteen native work/haul/craft cycles retain exact output")
	var report := {"checks":checks,"failures":failures,"frames":720,"warmup_frames":120,
		"frame_median_ms":times[360],"frame_p95_ms":times[683],"cold_cycle_us":cold_us,
		"warm_cycle_median_us":event_us[6],"warm_cycle_max_us":event_us[-1],"max_voices":max_voices,
		"scope":"Authored 720p active gathering/release/haul/bench sequence; 12 measured cycles, faster than play; Dummy audio, no device latency or world generation measurement."}
	var directory := ProjectSettings.globalize_path("res://../captures/feedback")
	DirAccess.make_dir_recursive_absolute(directory)
	var file := FileAccess.open(directory.path_join("active-route.json"),FileAccess.WRITE)
	check(file != null,"timing report opens in isolated copy")
	if file != null: file.store_string(JSON.stringify(report,"  ")); file.close()
	print("INTERACTION_ROUTE %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _work_cycle() -> void:
	for press in 2:
		player._apply_work(resource,resource.work(sim),{"position":resource.global_position+Vector3.UP,"normal":Vector3.FORWARD})
	for drop in get_tree().get_nodes_in_group("pickups"):
		if drop is Pickup and not drop.is_queued_for_deletion(): drop._absorb(player)
	player.work_panel.open_crafting(station)
	check(player.work_panel.craft(&"refine_woven_reed").get("crafted",false),"native bench batch succeeds")
	player.work_panel.close_panel()
