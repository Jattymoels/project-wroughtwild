extends Node3D
## Codex (OpenAI), 5 Sep 2026. Isolate the existing winding repair.
## Before reconstructs precisely the reversed tree/boulder triangle order;
## positions, colours, camera and lighting remain identical. No save IO.

var props: Array[MeshInstance3D] = []
var repaired: Array[ArrayMesh] = []
var frame := 0
var output := ""

func _ready() -> void:
	get_window().size = Vector2i(1920, 1080)
	output = ProjectSettings.globalize_path("res://../build/codex-aesthetic/prop-repair")
	DirAccess.make_dir_recursive_absolute(output)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("9badb8")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b6c9dc")
	environment.environment.ambient_light_energy = 0.45
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-42, -30, 0)
	sun.light_energy = 1.5
	sun.shadow_enabled = true
	add_child(sun)
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(200, 200)
	ground.mesh = plane
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("758376")
	ground.material_override = ground_material
	add_child(ground)
	_add_prop(PropMesh.build_tree(19), Vector3(-1.6, 0, 0), 1.0)
	_add_prop(PropMesh.build_boulder(23), Vector3(2.1, 0, 0), 1.8)
	var camera := Camera3D.new()
	camera.position = Vector3(7, 4.5, 11)
	camera.fov = 42
	add_child(camera)
	camera.look_at(Vector3(0, 2, 0))
	camera.make_current()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _add_prop(mesh: ArrayMesh, at: Vector3, size: float) -> void:
	var prop := MeshInstance3D.new()
	prop.mesh = _before_repair(mesh)
	prop.material_override = PropMesh.material()
	prop.position = at
	prop.scale = Vector3.ONE * size
	add_child(prop)
	props.append(prop)
	repaired.append(mesh)

func _before_repair(mesh: ArrayMesh) -> ArrayMesh:
	var arrays := mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var colours: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var indices := PackedInt32Array()
	if arrays[Mesh.ARRAY_INDEX] != null:
		indices = arrays[Mesh.ARRAY_INDEX]
	var count := indices.size() if not indices.is_empty() else vertices.size()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for triangle in range(0, count, 3):
		for offset in [0, 2, 1]:
			var index: int = indices[triangle + offset] if not indices.is_empty() else triangle + offset
			surface.set_color(colours[index])
			surface.add_vertex(vertices[index])
	surface.generate_normals()
	return surface.commit()

func _process(_delta: float) -> void:
	frame += 1
	if frame != 15 and frame != 30:
		return
	await RenderingServer.frame_post_draw
	var name := "before" if frame == 15 else "after"
	var result := get_viewport().get_texture().get_image().save_png(output.path_join(name + ".png"))
	if result != OK:
		push_error("Prop repair capture failed")
		get_tree().quit(1)
		return
	if frame == 15:
		for i in props.size():
			props[i].mesh = repaired[i]
	else:
		print("CODEX_PROP_REPAIR captured before/after: identical vertices and colours; reversed triangle winding only")
		get_tree().quit(0)
