extends Node3D
## Scratch: lay a campfire against a stone face near spawn, wait for the
## soak, screenshot the glow, quench, screenshot the cracks. Run windowed:
##   godot --path game --resolution 1152x648 res://tests/scratch_fire.tscn

var terrain: Terrain
var camera: Camera3D
var fire: PlacedBlock
var fire_pos := Vector3.ZERO
var rock := Vector3i.ZERO
var rock_node: ResourceNode
var t := 0.0
var shot := 0


func _ready() -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.build(sim, 5)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_energy = 0.7
	add_child(sun)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.5, 0.6, 0.75)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.6, 0.65, 0.7)
	e.ambient_light_energy = 0.5
	env.environment = e
	add_child(env)

	# The heartland's stone is boulders: the nearest one to spawn with open
	# ground beside it for the fire and the camera.
	var sx: int = terrain.map["spawn_x"]
	var sz: int = terrain.map["spawn_z"]
	var cs: float = terrain.map["cell_size"]
	var spawn := Vector3((sx + 0.5) * cs, 0.0, (sz + 0.5) * cs)
	var boulder: ResourceNode = null
	var best_d := 1e9
	for node in terrain.nodes_root.get_children():
		if node is ResourceNode and (node as ResourceNode).visual == &"boulder":
			var d := Vector2(node.position.x - spawn.x, node.position.z - spawn.z).length()
			if d < best_d:
				best_d = d
				boulder = node
	var bx := floori(boulder.position.x / cs)
	var bz := floori(boulder.position.z / cs)
	var by := floori(boulder.position.y + 0.01)
	var stand := Vector3i(bx + 1, by, bz)
	if terrain.block_at(stand.x, stand.y, stand.z) != 0 or terrain.height_at(stand.x, stand.z) != by:
		stand = Vector3i(bx - 1, by, bz)
	if terrain.block_at(stand.x, stand.y, stand.z) != 0 or terrain.height_at(stand.x, stand.z) != by:
		stand = Vector3i(bx, by, bz + 1)
	rock = Vector3i(bx, by - 1, bz)
	print("boulder at ", boulder.position, " fire stands at ", stand, " (", best_d, " m from spawn)")
	fire_pos = Vector3((stand.x + 0.5) * cs, (stand.y + 0.5) * cs, (stand.z + 0.5) * cs)
	rock_node = boulder
	fire = load("res://scenes/placed_block.tscn").instantiate()
	add_child(fire)
	var element := {"kind": "volume", "axis": 0, "cell": stand * 2}
	fire.init_piece(&"campfire", &"wood", element, 0, "fire", Vector3(1.0, 0.5, 1.0), fire_pos, 0.0,
		PieceLook.material_for(sim, &"wood"))

	camera = Camera3D.new()
	add_child(camera)
	var away := Vector3(stand.x - rock.x, 0, stand.z - rock.z)
	var side := Vector3(-away.z, 0.0, away.x)
	camera.global_position = fire_pos + away * 2.8 + side * 1.4 + Vector3(0.0, 1.6, 0.0)
	camera.look_at(fire_pos + Vector3(0, 0.1, 0) - away * 0.4, Vector3.UP)


func _process(delta: float) -> void:
	t += delta
	if shot == 0 and t > 7.0:
		shot = 1
		get_viewport().get_texture().get_image().save_png("res://tests/fire_hot.png")
		print("hot blocks: ", terrain._hot.size(), " boulder heat ", rock_node.hot_level, " refusal: ", rock_node.work_refusal())
	elif shot == 1 and t > 7.5:
		shot = 2
		var cracked := terrain.quench_at(fire_pos, 2.5)
		print("quench cracked blocks ", cracked, " boulder cracked ", rock_node.cracked, " workable ", rock_node.workable())
	elif shot == 2 and t > 8.5:
		shot = 3
		get_viewport().get_texture().get_image().save_png("res://tests/fire_cracked.png")
		get_tree().quit()
