class_name Terrain
extends Node3D
## Renders the sim's generated world (WroughtwildSim.world_map): blocky
## terrain as one MultiMesh per surface texture plus dirt filler for exposed
## cliff sides, a single heightmap collision body, and the scattered
## resource nodes. The sim decides WHAT the world is; this node only decides
## how it looks (ADR-0003 for terrain).
##
## Known greybox compromise: collision uses a heightmap, which ramps between
## cells instead of hard block steps; visuals stay blocky. Building reads
## the block heights directly (build_cell_center, cell_clear_of_ground) so
## placement follows what the player sees, not the ramp.

const RESOURCE_NODE_SCENE := preload("res://scenes/resource_node.tscn")

const SURFACE_TEXTURES := {
	"grass": "res://assets/textures/grass.png",
	"forest_floor": "res://assets/textures/forest_floor.png",
	"rock": "res://assets/textures/rock.png",
	"ash": "res://assets/textures/ash.png",
}
const FILLER_TEXTURE := "res://assets/textures/dirt.png"

var map: Dictionary = {}
var nodes_root: Node3D


func _cell_index(x: int, z: int) -> int:
	return z * int(map["width"]) + x


func height_at(x: int, z: int) -> int:
	if x < 0 or z < 0 or x >= int(map["width"]) or z >= int(map["height"]):
		return 0
	return (map["heights"] as PackedInt32Array)[_cell_index(x, z)]


## World-space centre of a cell's top face: where things stand.
func surface_position(x: int, z: int) -> Vector3:
	var cell: float = map["cell_size"]
	return Vector3((x + 0.5) * cell, float(height_at(x, z)), (z + 0.5) * cell)


## Centre of the build cell resting on the terrain block under a ground hit.
func build_cell_center(point: Vector3, grid_size: float) -> Vector3:
	var cell: float = map["cell_size"]
	var x := floori(point.x / cell)
	var z := floori(point.z / cell)
	return Vector3((x + 0.5) * cell, float(height_at(x, z)) + grid_size * 0.5, (z + 0.5) * cell)


## True when a build cell's floor sits on or above the terrain block there.
func cell_clear_of_ground(cell_center: Vector3, grid_size: float) -> bool:
	var cell: float = map["cell_size"]
	var x := floori(cell_center.x / cell)
	var z := floori(cell_center.z / cell)
	return cell_center.y - grid_size * 0.5 >= float(height_at(x, z)) - 0.001


static func _block_material(texture_path: String) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(texture_path)
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 1.0
	return material


func build(sim: WroughtwildSim, seed_value: int) -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	map = sim.world_map(seed_value)
	if map.is_empty():
		push_error("Terrain: sim.world_map returned nothing")
		return

	var width: int = map["width"]
	var depth: int = map["height"]
	var cell: float = map["cell_size"]
	var heights: PackedInt32Array = map["heights"]
	var biomes: PackedInt32Array = map["biomes"]
	var biome_defs: Array = map["biome_defs"]

	# Sort every visible cube into buckets: surface texture -> transforms.
	var buckets := {}
	for key in SURFACE_TEXTURES:
		buckets[key] = []
	var filler: Array = []

	for z in depth:
		for x in width:
			var h := heights[_cell_index(x, z)]
			var surface: String = biome_defs[biomes[_cell_index(x, z)]]["surface"]
			if not buckets.has(surface):
				surface = "grass"
			# Top block: its upper face is the walking surface at y = h.
			buckets[surface].append(Vector3((x + 0.5) * cell, h - 0.5, (z + 0.5) * cell))
			# Filler blocks down to the lowest neighbour, so cliffs have sides.
			var lowest := h
			for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				lowest = mini(lowest, height_at(x + offset.x, z + offset.y))
			for y in range(lowest, h - 1):
				filler.append(Vector3((x + 0.5) * cell, y + 0.5, (z + 0.5) * cell))

	for surface in buckets:
		_add_multimesh(buckets[surface], SURFACE_TEXTURES[surface], cell)
	_add_multimesh(filler, FILLER_TEXTURE, cell)

	_build_collision(width, depth, cell, heights)

	nodes_root = Node3D.new()
	nodes_root.name = "ResourceNodes"
	add_child(nodes_root)
	for node in map["nodes"]:
		_spawn_resource_node(node)


func _add_multimesh(positions: Array, texture_path: String, cell: float) -> void:
	if positions.is_empty():
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3.ONE * cell
	mesh.material = _block_material(texture_path)
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = mesh
	multimesh.instance_count = positions.size()
	for i in positions.size():
		multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, positions[i]))
	var instance := MultiMeshInstance3D.new()
	instance.multimesh = multimesh
	add_child(instance)


func _build_collision(width: int, depth: int, cell: float, heights: PackedInt32Array) -> void:
	var shape := HeightMapShape3D.new()
	shape.map_width = width
	shape.map_depth = depth
	var data := PackedFloat32Array()
	data.resize(width * depth)
	for i in width * depth:
		data[i] = float(heights[i])
	shape.map_data = data

	var body := StaticBody3D.new()
	body.name = "TerrainBody"
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	add_child(body)
	# HeightMapShape3D is centred on its own origin; align its sample points
	# with cell centres.
	body.global_position = Vector3(width * cell / 2.0, 0.0, depth * cell / 2.0)


func _spawn_resource_node(def: Dictionary) -> void:
	var node: ResourceNode = RESOURCE_NODE_SCENE.instantiate()
	node.name = "wn_%s_%d_%d" % [def["type"], def["x"], def["z"]]
	node.material_family = StringName(def["material_family"])
	node.remaining_units = def["units"]
	node.units_per_harvest = def["units_per_harvest"]
	node.visual = StringName(def["visual"])
	nodes_root.add_child(node)
	node.global_position = surface_position(def["x"], def["z"])
