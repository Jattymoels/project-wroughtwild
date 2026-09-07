extends "res://tests/leyline_visual_review.gd"
## Matched INT-02A evidence in isolated V6 worlds. This same fixture runs on the
## untouched baseline; production behaviour has no review-only feature switch.
var smithy: Dictionary = {}

func _ready() -> void:
	world_profile = "frontier_v6"
	world_seed = 77
	review_phase = "current"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--story-seed="): world_seed = int(arg.get_slice("=",1))
		if arg.begins_with("--story-phase="): review_phase = arg.get_slice("=",1)
	output = ProjectSettings.globalize_path("res://../captures/seed-%d" % world_seed)
	DirAccess.make_dir_recursive_absolute(output)
	var started := Time.get_ticks_msec()
	_build_world(world_seed)
	report.world_setup_ms = Time.get_ticks_msec()-started
	report.terrain_startup = terrain.build_profile.duplicate(true)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.hide()
	player.hud.hide()
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	mood.set_process(false)
	mood.set_physics_process(false)
	set_physics_process(false)
	_setup_camera()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	initial_native = _native_signature()
	report.native_signature = initial_native
	report.phase = review_phase
	report.seed = world_seed
	report.profile = world_profile
	report.scope = "Actual V6 world, 1440x900 Forward+, FOV75, grounded 1.65m eye, fixed daylight/dusk. Warm 600-frame samples exclude screenshots. Automated presentation and route checks; human discovery review remains pending."
	report.views = []
	_select_views()
	check(review_views.size()==8,"smithy arrival/breach/departure and all five clue families selected")
	var reference := ProjectSettings.globalize_path("res://../../baseline/captures/seed-%d/manifest.json" % world_seed)
	if review_phase != "baseline" and FileAccess.file_exists(reference):
		prior_report = JSON.parse_string(FileAccess.get_file_as_string(reference))
		check(initial_native==prior_report.get("native_signature",{}),"presentation preserves baseline native geography and pressure ledger")
	for view in review_views: await _review_view(view)
	await _route_check()
	check(_native_signature()==initial_native,"inspection, streaming and route review change no native geography or stock")
	report.checks = checks
	report.failures = failures
	var file := FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t",true,true))
	print("EXPLORATION_REVIEW %d checks, %d failures; %s seed %d" % [checks,failures,review_phase,world_seed])
	get_tree().quit(0 if failures==0 else 1)

func _native_signature() -> Dictionary:
	var result := super._native_signature()
	result.ruins = _digest(terrain.map.get("ruins",[]))
	return result

func _select_views() -> void:
	var pockets: Array = terrain.map.get("pressure_pockets",[])
	if pockets.is_empty(): return
	var source: Dictionary = pockets[0]
	for ruin: Dictionary in terrain.map.ruins:
		if String(ruin.id)==String(source.ruin_id): smithy=ruin; break
	if smithy.is_empty(): return
	var centre := terrain.surface_position(int(smithy.x),int(smithy.z))
	var path: PackedVector3Array = smithy.approach
	var departure: PackedVector3Array = smithy.discovery_route
	var hearth := Vector3(source.x+.5,source.y,source.z+.5)
	var work: Vector3 = source.work_position
	var away := Vector3(work.x-hearth.x,0,work.z-hearth.z).normalized()
	review_views.append({"id":"smithy_arrival","at":path[maxi(0,path.size()-10)],"target":centre,"target_height":1.0,"native_id":smithy.id,"timed":true})
	review_views.append({"id":"smithy_breach","at":hearth+away*4+away.cross(Vector3.UP)*1.8,"target":hearth,"target_height":.65,"native_id":source.id,"timed":false})
	review_views.append({"id":"smithy_departure","at":departure[0],"target":departure[mini(8,departure.size()-1)],"target_height":.6,"native_id":smithy.id,"timed":false})
	var seen := {}
	for site: Dictionary in terrain.map.rare_sites:
		var kind := String(site.resource_type)
		if seen.has(kind): continue
		var points: PackedVector3Array = site.get("clue_points",PackedVector3Array())
		if points.is_empty(): continue
		seen[kind] = true
		var clue: Vector3 = points[0]
		var target := Vector3(site.x+.5,site.y,site.z+.5)
		var along := Vector3(target.x-clue.x,0,target.z-clue.z).normalized()
		if along.length_squared()<.01: along=Vector3.FORWARD
		review_views.append({"id":"clue_"+kind,"at":clue-along*3+along.cross(Vector3.UP)*.65,"target":clue,"target_height":.12,"native_id":site.id,"timed":kind=="ventlung"})

func _review_view(view: Dictionary) -> void:
	terrain.set_process(true)
	await _settle(view.at,64)
	(get_node("CataclysmSites") as CataclysmSites).refresh_area(floori(view.target.x)-12,floori(view.target.z)-12,24)
	mood._target = mood.active_mood(mood._biome_under_player())
	mood._apply(1.0)
	var at := _ground(view.at)+Vector3.UP*1.65
	var toward := _ground(view.target)+Vector3.UP*float(view.target_height)
	check(at.is_finite() and toward.is_finite(),"grounded review pose "+String(view.id))
	if not at.is_finite() or not toward.is_finite(): return
	review_camera.global_position = at
	review_camera.look_at(toward)
	terrain.set_process(false)
	var entry := {"id":view.id,"native_id":view.native_id,"camera_position":[at.x,at.y,at.z],"target":[toward.x,toward.y,toward.z]}
	for prior: Dictionary in prior_report.get("views",[]):
		if prior.id==view.id:
			check(at.distance_to(Vector3(prior.camera_position[0],prior.camera_position[1],prior.camera_position[2]))<.0001 and toward.distance_to(Vector3(prior.target[0],prior.target[1],prior.target[2]))<.0001,"identical grounded before/after camera "+String(view.id))
	caption.text = String(view.id).replace("_"," ").to_upper()+" · SEED %d · DAYLIGHT" % world_seed
	if bool(view.timed): entry.day = await _sample_frames()
	if DisplayServer.get_name()!="headless": await _capture(String(view.id)+"-day")
	var sun: DirectionalLight3D = $Sun
	var energy := sun.light_energy
	var colour := sun.light_color
	sun.light_energy = energy*.48
	sun.light_color = Color("d9bd91")
	caption.text = String(view.id).replace("_"," ").to_upper()+" · SEED %d · DUSK" % world_seed
	if bool(view.timed): entry.dusk = await _sample_frames()
	if DisplayServer.get_name()!="headless": await _capture(String(view.id)+"-dusk")
	sun.light_energy = energy
	sun.light_color = colour
	report.views.append(entry)
	terrain.set_process(true)

func _route_check() -> void:
	if smithy.is_empty(): return
	var route: PackedVector3Array = smithy.discovery_route
	var capsule := CapsuleShape3D.new()
	capsule.radius = .42
	capsule.height = 1.92
	var samples := 0
	for at: Vector3 in route:
		await _settle(at,18)
		var ground := _ground(at)
		check(ground.is_finite(),"discovery route retains supported ground")
		if not ground.is_finite(): continue
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY,ground+Vector3.UP*1.04)
		query.exclude = [player]
		var obstructed := false
		for hit in get_world_3d().direct_space_state.intersect_shape(query,32):
			if hit.collider is Node and hit.collider.has_meta("cataclysm_solid"): obstructed=true
		check(not obstructed,"discovery route avoids solid ruin walls")
		samples+=1
	report.route = {"native_id":smithy.id,"samples":samples,"path_length":route.size(),"scope":"Ground and actual player-capsule samples along the native route; not a timed player journey."}
