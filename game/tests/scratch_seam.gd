extends Node3D
## Scratch (D-021): the nearest stone seam to spawn with a wedge set in it,
## a fieldstone footing and dry wall beside it. Run windowed:
##   godot --path game --resolution 1152x648 res://tests/scratch_seam.tscn

var t := 0.0
var shot := 0


func _ready() -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var terrain := Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build(sim, 5)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.9
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.6, 0.75)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.65, 0.7)
	e.ambient_light_energy = 0.6
	env.environment = e
	add_child(env)

	var sx: int = terrain.map["spawn_x"]
	var sz: int = terrain.map["spawn_z"]
	var cs: float = terrain.map["cell_size"]
	var spawn := Vector3((sx + 0.5) * cs, 0.0, (sz + 0.5) * cs)
	var seam: ResourceNode = null
	var best_d := 1e9
	var seams := 0
	for node in terrain.nodes_root.get_children():
		if node is ResourceNode and (node as ResourceNode).visual == &"seam":
			seams += 1
			var d := Vector2(node.position.x - spawn.x, node.position.z - spawn.z).length()
			if d < best_d:
				best_d = d
				seam = node
	print("seams in world: ", seams, "; nearest ", best_d, " m from spawn at ", seam.position)
	sim.add_material("timber_wedge", 2)
	print("set wedge: ", seam.work(sim), " label: ", seam.interact_label(sim))

	# Fieldstone beside it: a footing on the ground and a dry wall on a face.
	var bx := floori(seam.position.x / cs)
	var bz := floori(seam.position.z / cs)
	var by := floori(seam.position.y + 0.01)
	var look := PieceLook.material_for(sim, &"fieldstone")
	var footing: PlacedBlock = load("res://scenes/placed_block.tscn").instantiate()
	add_child(footing)
	footing.init_piece(&"foundation", &"fieldstone", {"kind": "volume", "axis": 0, "cell": Vector3i(bx + 2, by, bz) * 2}, 0, "low",
		Vector3(1.0, 0.5, 1.0), Vector3((bx + 2.5) * cs, by + 0.5, (bz + 0.5) * cs), 0.0, look)
	var wall: PlacedBlock = load("res://scenes/placed_block.tscn").instantiate()
	add_child(wall)
	wall.init_piece(&"dry_wall", &"fieldstone", {"kind": "face", "axis": 0, "cell": Vector3i(bx + 3, by, bz) * 2}, 0, "low",
		Vector3(1.0, 0.5, 0.3), Vector3((bx + 3.0) * cs, by + 0.5, (bz + 0.5) * cs), PI / 2.0, look)

	var camera := Camera3D.new()
	add_child(camera)
	var focus := Vector3((bx + 1.5) * cs, by + 0.3, (bz + 0.5) * cs)
	camera.global_position = focus + Vector3(0.8, 2.0, 4.2)
	camera.look_at(focus, Vector3.UP)


func _process(delta: float) -> void:
	t += delta
	if shot == 0 and t > 1.5:
		shot = 1
		get_viewport().get_texture().get_image().save_png("res://tests/seam.png")
		get_tree().quit()
