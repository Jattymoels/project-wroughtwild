extends Node3D
## Normal kit placement and save restoration, in a small lit inspection scene.
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	var player: WroughtwildPlayer = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.hud.hide()
	player.class_panel.close_panel()
	player.camera.get_node("FirstPersonHands").set_process(false)
	player.camera.get_node("FirstPersonHands").hide()
	var sim := player.inventory.get_sim()
	for i in 3:
		var kit: String = ["forge_kit","mason_yard_kit","workbench_kit"][i]
		sim.add_material(kit,1)
		player.placement.selected_kit = StringName(kit)
		player.placement.preview_element = {"kind":"volume","axis":0,"cell":Vector3i((i-1)*4,0,0)}
		check(player.placement._place_kit(),"normal placement consumes "+kit)
		check(sim.material_count(kit)==0,"kit consumed once: "+kit)
	var saved := SaveManager.new().capture(player)
	check(SaveManager.new().apply(player,JSON.parse_string(JSON.stringify(saved))),"normal station save restores")
	var models := {}
	for site in get_children():
		if site is StationSite:
			models[site.station_id] = site.get_node("Mesh").mesh
			check(site.get_node("Mesh").mesh is ArrayMesh and not site.has_node("StudyDetails"),"restored station has shared model without lab dressing")
	check(models.size()==3 and models[&"workbench"]!=models[&"mason_yard"],"three distinct normal station models")
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(30,30)
	ground.mesh = plane
	var floor_material := StandardMaterial3D.new()
	floor_material.albedo_color = Color("4c5245")
	ground.material_override = floor_material
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-25,0)
	sun.shadow_enabled = true
	add_child(sun)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("6b777d")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("a1abb0")
	environment.environment.ambient_light_energy = 0.5
	add_child(environment)
	var camera := Camera3D.new()
	camera.fov = 45
	camera.position = Vector3(0.5,2.4,-6)
	add_child(camera)
	camera.look_at(Vector3(0.5,0.8,0.5))
	camera.make_current()
	if DisplayServer.get_name()!="headless":
		for i in 5:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var directory := ProjectSettings.globalize_path("res://../build/codex-aesthetic/stations")
		DirAccess.make_dir_recursive_absolute(directory)
		check(get_viewport().get_texture().get_image().save_png(directory.path_join("normal-stations.png"))==OK,"capture actual restored station models")
	# Upgrading changes only presentation, without changing saved station identity.
	sim.add_station("forge_improved")
	for site in get_children():
		if site is StationSite and site.station_id==&"forge_basic":
			site.refresh_visual(sim)
			check(site.get_node("Mesh").mesh!=models[&"forge_basic"] and site.current_station_id(sim)==&"forge_improved","forge upgrade has a distinct hood and retains site identity")
	print("CODEX_STATIONS %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
