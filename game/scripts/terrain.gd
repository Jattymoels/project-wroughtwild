class_name Terrain
extends Node3D
## Renders the sim's generated world (WroughtwildSim.world_map / world_mesh):
## a full 3D block field - rolling ground, craggy massifs, strata and carved
## caves - drawn as one MultiMesh per surface kind per chunk, with one
## trimesh collision body per chunk built from the exposed faces. The sim
## decides WHAT the world is and even which blocks are visible (world_mesh
## derives the geometry so no script re-walks a million blocks); this node
## only decides how it looks (ADR-0003 for terrain). Chunks exist so the
## digging slice can rebuild one 16x16 column patch instead of the world.

const RESOURCE_NODE_SCENE := preload("res://scenes/resource_node.tscn")

const CHUNK_CELLS := 16
## Every block kind the sim can emit (biome surface keys plus strata).
const KIND_TEXTURES := {
	"grass": "res://assets/textures/grass.png",
	"forest_floor": "res://assets/textures/forest_floor.png",
	"rock": "res://assets/textures/rock.png",
	"ash": "res://assets/textures/ash.png",
	"dirt": "res://assets/textures/dirt.png",
	"stone": "res://assets/textures/rock.png",
	"bedrock": "res://assets/textures/rock.png",
}
## Strata get a tint so stone reads darker than surface rock and bedrock
## reads as the unbreakable floor.
const KIND_TINTS := {
	"stone": Color(0.72, 0.72, 0.75),
	"bedrock": Color(0.38, 0.38, 0.42),
}

var map: Dictionary = {}
var nodes_root: Node3D
## chunk key "x_z" -> Node3D holding that chunk's meshes and collision.
var chunks: Dictionary = {}

var _materials := {}


func _cell_index(x: int, z: int) -> int:
	return z * int(map["width"]) + x


## The walking-surface level of a column (what the generator intended;
## a cave breach below does not move it).
func height_at(x: int, z: int) -> int:
	if x < 0 or z < 0 or x >= int(map["width"]) or z >= int(map["height"]):
		return 0
	return (map["heights"] as PackedInt32Array)[_cell_index(x, z)]


## The block id at a world cell (0 = air); reads the sim's block field.
func block_at(x: int, y: int, z: int) -> int:
	if x < 0 or z < 0 or x >= int(map["width"]) or z >= int(map["height"]):
		return 0
	if y < 0 or y >= int(map["depth"]):
		return 0
	return (map["blocks"] as PackedByteArray)[_cell_index(x, z) * int(map["depth"]) + y]


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


func _material_for(kind: String) -> StandardMaterial3D:
	if _materials.has(kind):
		return _materials[kind]
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(KIND_TEXTURES.get(kind, KIND_TEXTURES["rock"]))
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 1.0
	if KIND_TINTS.has(kind):
		material.albedo_color = KIND_TINTS[kind]
	_materials[kind] = material
	return material


func build(sim: WroughtwildSim, seed_value: int) -> void:
	for child in get_children():
		remove_child(child)
		child.free()
	chunks.clear()
	map = sim.world_map(seed_value)
	if map.is_empty():
		push_error("Terrain: sim.world_map returned nothing")
		return

	var cell: float = map["cell_size"]
	for chunk_data in sim.world_mesh(seed_value, CHUNK_CELLS):
		_build_chunk(chunk_data, cell)

	nodes_root = Node3D.new()
	nodes_root.name = "ResourceNodes"
	add_child(nodes_root)
	for node in map["nodes"]:
		_spawn_resource_node(node)


func _build_chunk(chunk_data: Dictionary, cell: float) -> void:
	var chunk := Node3D.new()
	chunk.name = "Chunk_%d_%d" % [int(chunk_data["x"]), int(chunk_data["z"])]
	add_child(chunk)
	chunks["%d_%d" % [int(chunk_data["x"]), int(chunk_data["z"])]] = chunk

	var kinds: Dictionary = chunk_data["kinds"]
	for kind in kinds:
		var centres: PackedVector3Array = kinds[kind]
		if centres.is_empty():
			continue
		var mesh := BoxMesh.new()
		mesh.size = Vector3.ONE * cell
		mesh.material = _material_for(String(kind))
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = mesh
		multimesh.instance_count = centres.size()
		for i in centres.size():
			multimesh.set_instance_transform(i, Transform3D(Basis.IDENTITY, centres[i]))
		var instance := MultiMeshInstance3D.new()
		instance.multimesh = multimesh
		chunk.add_child(instance)

	var faces: PackedVector3Array = chunk_data["faces"]
	if not faces.is_empty():
		var shape := ConcavePolygonShape3D.new()
		shape.set_faces(faces)
		# The sim does not promise a winding; collide from both sides.
		shape.backface_collision = true
		var body := StaticBody3D.new()
		body.name = "ChunkBody"
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		chunk.add_child(body)


func _spawn_resource_node(def: Dictionary) -> void:
	var node: ResourceNode = RESOURCE_NODE_SCENE.instantiate()
	# y is part of the name: a cave-floor node and a surface node may share
	# a column, and saves match nodes by name.
	node.name = "wn_%s_%d_%d_%d" % [def["type"], def["x"], def["y"], def["z"]]
	node.material_family = StringName(def["material_family"])
	node.remaining_units = def["units"]
	node.units_per_harvest = def["units_per_harvest"]
	node.visual = StringName(def["visual"])
	nodes_root.add_child(node)
	var cell: float = map["cell_size"]
	node.global_position = Vector3(
		(int(def["x"]) + 0.5) * cell, float(def["y"]), (int(def["z"]) + 0.5) * cell)
