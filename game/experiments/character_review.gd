extends Node3D
## Studio evidence using actual actor meshes/materials, with brains paused.
## This is a silhouette review, not a gameplay or animation demonstration.
var frame := 0
var captions: Array = []
var camera: Camera3D

func _ready() -> void:
	get_window().size = Vector2i(1920,1080)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("28373e")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("bbc3c0")
	env.environment.ambient_light_energy = 0.65
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42,-30,0)
	sun.light_color = Color("fff0d7")
	sun.shadow_enabled = true
	add_child(sun)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(40,24)
	floor_mesh.mesh = plane
	floor_mesh.position = Vector3(7.5,-0.02,0)
	floor_mesh.material_override = preload("res://art/weathered_look.tres").terrain_material("rock",1.0)
	add_child(floor_mesh)
	var peddler := Peddler.new()
	add_child(peddler)
	peddler.rotation.y = PI-0.3
	peddler._label.hide()
	peddler._label.set_process(false)
	captions.append([peddler,"Peddler"])
	var ids := [&"ember_whelp",&"gloom_crawler",&"stone_husk",&"cinder_wisp",&"hollow_knight"]
	for i in ids.size():
		var enemy := Enemy.spawn(self,ids[i],Vector3(float(i+1)*2.1,0,0))
		enemy.set_physics_process(false)
		enemy.rotation.y = PI-0.3
		enemy._label.hide()
		enemy._label.set_process(false)
		captions.append([enemy,enemy.display_name])
	var boss := Boss.spawn_boss(self,Vector3(13.4,0,-0.1))
	boss.rotation.y = PI-0.3
	boss.set_physics_process(false)
	boss._label.hide()
	boss._label.set_process(false)
	captions.append([boss,boss.display_name])
	camera = Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 10.2
	camera.position = Vector3(6.5,4.8,14.8)
	camera.look_at(Vector3(6.5,0.8,0))
	camera.make_current()
	var heading := Label.new()
	heading.text = "WROUGHTWILD / CHARACTER SILHOUETTES\nLive game meshes · paused poses · collision and combat rules unchanged"
	heading.position = Vector2(40,35)
	heading.add_theme_font_size_override("font_size",24)
	add_child(heading)
	for entry in captions:
		var label := Label.new()
		label.text = entry[1]
		label.add_theme_font_size_override("font_size",18)
		label.size = Vector2(200,30)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = camera.unproject_position(entry[0].position+Vector3(0,-0.1,0))+Vector2(-100,20)
		add_child(label)

func _process(_delta: float) -> void:
	frame += 1
	if frame!=15:
		return
	await RenderingServer.frame_post_draw
	var output := ProjectSettings.globalize_path("res://../build/codex-aesthetic/characters")
	DirAccess.make_dir_recursive_absolute(output)
	var error := get_viewport().get_texture().get_image().save_png(output.path_join("silhouettes.png"))
	print("CODEX_CHARACTERS capture ",error)
	get_tree().quit(0 if error==OK else 1)
