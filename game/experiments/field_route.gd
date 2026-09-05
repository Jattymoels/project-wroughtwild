extends Node3D
## Bounded 34-second field profile. Real controller, AI, skills and terrain;
## repeated gentle path and a supplied mob pack, not an economy/balance test.
var world: Sandpit
var player: WroughtwildPlayer
var frame := 0
var elapsed := 0.0
var previous := Vector3.ZERO
var distance := 0.0
var direction := 1.0
var peaks := 0
var casts := 0
var hits := 0
var output := ""
var samples: Dictionary = {"walk":[],"combat":[]}
var physics_samples: Dictionary = {"walk":[],"combat":[]}
var spawned := false
var capturing := false
var last_wall := 0
var packet: Array[Enemy] = []
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	get_window().size = Vector2i(1920,1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/field-route")
	DirAccess.make_dir_recursive_absolute(output)
	seed(193)
	world = preload("res://scenes/sandpit.tscn").instantiate()
	# The review must be able to match the original route's exact geography
	# after newer generation profiles become the new-game default.
	if OS.get_cmdline_user_args().has("--legacy-route"):
		world.world_profile = "legacy_v1"
	add_child(world)
	player = world.player
	player.class_panel.choose("warden")
	player.combat.fight_seed_source.seed = 193
	player.set_process_unhandled_input(false)
	player.position = Vector3(154.5,world.terrain.height_at(154,165)+1.05,165.5)
	player.rotation.y = -PI/2
	previous = player.position
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	last_wall = Time.get_ticks_usec()

func _physics_process(delta: float) -> void:
	frame += 1
	elapsed += delta
	if elapsed<2.0:
		return
	var planar := Vector2(player.position.x-previous.x,player.position.z-previous.z).length()
	distance += planar
	previous = player.position
	if player.position.x>167.0:
		direction = -1.0
	elif player.position.x<154.5:
		direction = 1.0
	player.rotation.y = -PI/2 if direction>0 else PI/2
	player.test_walk = Vector2(0,-1)
	# Keep the fixture alive so the intended load runs for the full interval.
	# This is explicitly NOT evidence of ordinary survivability or balance.
	if player.combat.life<player.combat.max_life:
		hits += 1
	player.combat.restore_life()
	if elapsed>=18.0 and not spawned:
		spawned = true
		for i in 24:
			var x := 156.0+float(i%6)*1.6
			var z := 160.0+float(i/6)*1.6
			var enemy := Enemy.spawn(world,&"ember_whelp" if i%3 else &"gloom_crawler",Vector3(x,world.terrain.height_at(int(x),int(z))+0.65,z))
			packet.append(enemy)
	if spawned and frame%18==0:
		if player.combat.use_slot(1):
			casts += 1
		if player.combat.use_slot(2):
			casts += 1
	peaks = maxi(peaks,get_tree().get_nodes_in_group("enemies").size())
	if frame==600 or frame==1380:
		capture("walk" if frame==600 else "combat")
	if elapsed>=34.0:
		set_physics_process(false)
		player.test_walk = Vector2.ZERO
		finish()

func _process(_delta: float) -> void:
	var now := Time.get_ticks_usec()
	var interval := float(now-last_wall)/1000.0
	last_wall = now
	if elapsed<2.0 or elapsed>=34.0 or capturing:
		return
	var stage := "walk" if elapsed<18.0 else "combat"
	samples[stage].append(interval)
	physics_samples[stage].append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)

func capture(id: String) -> void:
	capturing = true
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK,"capture real player view: "+id)
	last_wall = Time.get_ticks_usec()
	capturing = false

func distribution(values: Array) -> Dictionary:
	values.sort()
	if values.is_empty():
		return {}
	return {"samples":values.size(),"median_ms":values[values.size()/2],"p95_ms":values[ceili(values.size()*0.95)-1],"p99_ms":values[ceili(values.size()*0.99)-1],"max_ms":values[-1]}

func finish() -> void:
	check(distance>85.0,"controller traverses over 85 metres on the repeated slope route")
	check(peaks>=24,"profile includes at least 24 live enemies")
	check(casts>=8,"combat profile exercises actual skill casts")
	check(hits>0,"real enemies land attacks during the fixture")
	check(player.position.y>world.terrain.height_at(int(player.position.x),int(player.position.z))-1,"player remains above terrain after the route")
	var result := {"seed":1,"fixture_seed":193,"seconds":elapsed,"distance_m":distance,"peak_enemies":peaks,"casts":casts,"damage_frames":hits,
		"generation_profile":world.world_profile,
		"terrain_build":world.terrain.build_profile,
		"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1920,1080],"fps_cap":120,
		"scope":"two 16-second samples after settling; full generated world, repeated 13m gentle path, supplied 24-mob pack, fixture healing, no save IO; frame intervals include pacing, not isolated GPU time",
		"walk":distribution(samples.walk),"combat":distribution(samples.combat),"walk_physics":distribution(physics_samples.walk),"combat_physics":distribution(physics_samples.combat)}
	var file := FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	print("CODEX_FIELD_ROUTE ",JSON.stringify(result))
	print("%d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
