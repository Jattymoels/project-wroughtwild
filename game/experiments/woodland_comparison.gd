extends Node3D
## Paired fixed-camera silhouette evidence, plus reproducibility checks.
var frame := 0
var checks := 0
var failures := 0
var old_root: Node3D
var new_root: Node3D
var caption: Label
var output := ""

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	get_window().size = Vector2i(1920,1080)
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/woodland")
	DirAccess.make_dir_recursive_absolute(output)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("24333e")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c2d0de")
	environment.environment.ambient_light_energy = 0.45
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-40,-25,0)
	sun.shadow_enabled = true
	add_child(sun)
	old_root = Node3D.new()
	new_root = Node3D.new()
	add_child(old_root)
	add_child(new_root)
	var profile := preload("res://art/woodland_look.tres")
	if OS.get_cmdline_user_args().has("--weathered-look"):
		profile = preload("res://art/weathered_woodland.tres")
		output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/woodland-weathered")
		DirAccess.make_dir_recursive_absolute(output)
		var atmosphere := preload("res://art/weathered_atmosphere.tres")
		sun.directional_shadow_max_distance = atmosphere.shadow_distance
		sun.shadow_bias = atmosphere.shadow_bias
		sun.shadow_normal_bias = atmosphere.shadow_normal_bias
	var old_meshes := [PropMesh.build_tree(41),PropMesh.build_pine(41),PropMesh.build_tree(41),PropMesh.build_snag(41)]
	var biomes := ["meadow","forest","fen","ember_wastes"]
	for i in 4:
		var mesh: ArrayMesh = profile.build_tree(biomes[i],41)
		var again: ArrayMesh = profile.build_tree(biomes[i],41)
		var other: ArrayMesh = profile.build_tree(biomes[i],42)
		var arrays := mesh.surface_get_arrays(0)
		check(arrays[Mesh.ARRAY_VERTEX] == again.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],"same seed reproduces "+biomes[i])
		check(arrays[Mesh.ARRAY_VERTEX] != other.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],"different seed changes "+biomes[i])
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var valid := true
		for j in range(0,vertices.size(),3):
			var n := (vertices[j+2]-vertices[j]).cross(vertices[j+1]-vertices[j]).normalized()
			valid = valid and n.length_squared() > 0.99 and n.dot(normals[j]) > 0.99
		check(valid,"all triangles have nondegenerate clockwise normals: "+biomes[i])
		check(vertices.size()/3 < 1400,"bounded tree mesh budget: "+biomes[i])
		for pair in [[old_root,old_meshes[i]],[new_root,mesh]]:
			var instance := MeshInstance3D.new()
			instance.mesh = pair[1]
			instance.material_override = PropMesh.material()
			if OS.get_cmdline_user_args().has("--weathered-look"):
				(instance.material_override as StandardMaterial3D).vertex_color_is_srgb = true
			instance.position = Vector3(i*6.5,0,0)
			pair[0].add_child(instance)
		var label := Label3D.new()
		label.text = ["MEADOW · spreading crown","FOREST · layered pine","FEN · low branches","WASTES · bare forks"][i]
		label.font_size = 32
		label.pixel_size = 0.008
		label.position = Vector3(i*6.5,-0.55,0)
		add_child(label)
	new_root.hide()
	var camera := Camera3D.new()
	add_child(camera)
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 27
	camera.position = Vector3(9.75,6.0,23)
	camera.look_at(Vector3(9.75,2.1,0))
	camera.current = true
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(40,30)
	caption.add_theme_font_size_override("font_size",25)
	caption.text = "WOODLAND SILHOUETTES · BEFORE\nExisting repaired props · same seed, camera, lighting and scale"
	layer.add_child(caption)

func _process(_delta: float) -> void:
	frame += 1
	if frame == 20:
		await capture("before")
		old_root.hide()
		new_root.show()
		caption.text = "WOODLAND SILHOUETTES · CANDIDATE\nBranching trunks · layered crowns · biome shapes · deterministic geometry"
	if frame == 40:
		await capture("after")
		print("Codex woodland: %d checks, %d failures" % [checks,failures])
		get_tree().quit(0 if failures == 0 else 1)

func capture(id: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK,"capture "+id)
