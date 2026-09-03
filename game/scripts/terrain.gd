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
	"marsh": "res://assets/textures/marsh.png",
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
## Rules for breaking generic blocks, from the sim: kind -> {breakable,
## dig_seconds, yields}.
var block_rules: Dictionary = {}
## Every block the player has dug out this world, for the save.
var broken: Array[Vector3i] = []
## The era the world is in (eras.json, D-019): nodes of a later era wait
## in _pending_nodes until reveal_era brings their era.
var current_era := 1
var _pending_nodes: Array = []
## Fire-setting (D-020): the sim's rules (fuels, reach, soak, hot_seconds,
## quench radius), rock that is hot right now (cell -> {heat, until_msec})
## and rock that has been cracked (cell -> true). Cracked rock digs by
## hand; hot rock cracks when cold lands on it. Cracks are saved, heat is
## not (a fire that was burning is out when you come back).
var fire_rules: Dictionary = {}
var cracked: Dictionary = {}
var _hot: Dictionary = {}
var _overlays: Node3D
var _overlay_nodes: Dictionary = {}
var _expire_timer := 0.0

## Block id -> kind name (worldgen.h's palette).
const KIND_NAMES := {1: "surface", 2: "dirt", 3: "stone", 4: "bedrock"}

var _materials := {}
var _sim: WroughtwildSim
var _seed := 0
## Mutable copy of the sim's block field with the player's digs applied.
var _blocks := PackedByteArray()


func _cell_index(x: int, z: int) -> int:
	return z * int(map["width"]) + x


## The walking-surface level of a column (what the generator intended;
## a cave breach below does not move it).
func height_at(x: int, z: int) -> int:
	if x < 0 or z < 0 or x >= int(map["width"]) or z >= int(map["height"]):
		return 0
	return (map["heights"] as PackedInt32Array)[_cell_index(x, z)]


## The block id at a world cell (0 = air), with the player's digs applied.
func block_at(x: int, y: int, z: int) -> int:
	if x < 0 or z < 0 or x >= int(map["width"]) or z >= int(map["height"]):
		return 0
	if y < 0 or y >= int(map["depth"]):
		return 0
	return _blocks[_cell_index(x, z) * int(map["depth"]) + y]


## The block kind name at a cell ("" for air).
func kind_at(x: int, y: int, z: int) -> String:
	return KIND_NAMES.get(block_at(x, y, z), "")


## The world seed this terrain was built from.
func seed_value() -> int:
	return _seed


## Every dug block as flat x,y,z triples, the form the sim's chunk and
## enclosure queries take.
func broken_packed() -> PackedInt32Array:
	var packed := PackedInt32Array()
	for v in broken:
		packed.append(v.x)
		packed.append(v.y)
		packed.append(v.z)
	return packed


## True when a collider is one of this terrain's chunk bodies.
func is_terrain_body(body: Object) -> bool:
	return body is Node and (body as Node).has_meta("terrain_chunk")


## Converts a collision hit on a chunk body into the block cell struck:
## the hit point sits on a face, so step half a block inward.
func block_from_hit(hit_position: Vector3, hit_normal: Vector3) -> Vector3i:
	var cell: float = map["cell_size"]
	var inside := hit_position - hit_normal * (cell * 0.5)
	return Vector3i(floori(inside.x / cell), floori(inside.y / cell), floori(inside.z / cell))


## World-space centre of a cell's top face: where things stand.
func surface_position(x: int, z: int) -> Vector3:
	var cell: float = map["cell_size"]
	return Vector3((x + 0.5) * cell, float(height_at(x, z)), (z + 0.5) * cell)


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
	broken.clear()
	_sim = sim
	_seed = seed_value
	current_era = int(sim.era().get("index", 1))
	_pending_nodes.clear()
	map = sim.world_map(seed_value)
	if map.is_empty():
		push_error("Terrain: sim.world_map returned nothing")
		return
	_blocks = (map["blocks"] as PackedByteArray).duplicate()
	block_rules = sim.block_rules()
	fire_rules = sim.fire_setting()
	cracked.clear()
	_hot.clear()
	_overlay_nodes.clear()
	_overlays = Node3D.new()
	_overlays.name = "FireSetting"
	add_child(_overlays)

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
		body.set_meta("terrain_chunk", true)
		var collider := CollisionShape3D.new()
		collider.shape = shape
		body.add_child(collider)
		chunk.add_child(body)


# --- digging (Wave 3: breaking the generic blocks) ---------------------------

## Digs one block out: air in the local field, recorded for the save, the
## touched chunk(s) rebuilt from the sim with the edits applied. Returns
## the kind broken, or "" when the cell holds nothing breakable.
func break_block(x: int, y: int, z: int) -> String:
	var kind := kind_at(x, y, z)
	if kind == "" or not block_rules.get(kind, {}).get("breakable", false):
		return ""
	# Fire-setting: rock that hands cannot dig must have been cracked first.
	if not diggable_by_hand(Vector3i(x, y, z)):
		return ""
	_blocks[_cell_index(x, z) * int(map["depth"]) + y] = 0
	broken.append(Vector3i(x, y, z))
	_forget_cell(Vector3i(x, y, z))
	for origin in _touched_chunk_origins(x, z):
		_rebuild_chunk(origin.x, origin.y)
	return kind


## The chunk holding a column, plus the neighbour when the column sits on
## a chunk border (a dig there exposes faces next door).
func _touched_chunk_origins(x: int, z: int) -> Array[Vector2i]:
	var origins: Array[Vector2i] = [Vector2i(x - x % CHUNK_CELLS, z - z % CHUNK_CELLS)]
	if x % CHUNK_CELLS == 0 and x > 0:
		origins.append(Vector2i(x - CHUNK_CELLS, z - z % CHUNK_CELLS))
	elif x % CHUNK_CELLS == CHUNK_CELLS - 1 and x + 1 < int(map["width"]):
		origins.append(Vector2i(x + 1, z - z % CHUNK_CELLS))
	if z % CHUNK_CELLS == 0 and z > 0:
		origins.append(Vector2i(x - x % CHUNK_CELLS, z - CHUNK_CELLS))
	elif z % CHUNK_CELLS == CHUNK_CELLS - 1 and z + 1 < int(map["height"]):
		origins.append(Vector2i(x - x % CHUNK_CELLS, z + 1))
	return origins


func _rebuild_chunk(cx: int, cz: int) -> void:
	cx -= cx % CHUNK_CELLS
	cz -= cz % CHUNK_CELLS
	var key := "%d_%d" % [cx, cz]
	if chunks.has(key):
		var old: Node3D = chunks[key]
		remove_child(old)
		old.free()
		chunks.erase(key)
	var packed := PackedInt32Array()
	for v in broken:
		packed.append(v.x)
		packed.append(v.y)
		packed.append(v.z)
	_build_chunk(_sim.world_mesh_chunk(_seed, CHUNK_CELLS, cx, cz, packed), map["cell_size"])


## SaveManager hook: makes the world's digs exactly the save's - undoes
## holes dug since (the field resets to the sim's pristine blocks), then
## re-carves the saved list and rebuilds every chunk either set touched.
func apply_broken_blocks(list: Array) -> void:
	var touched := {}
	for v in broken:
		for origin in _touched_chunk_origins(v.x, v.z):
			touched[origin] = true
	broken.clear()
	_blocks = (map["blocks"] as PackedByteArray).duplicate()
	for entry in list:
		if not (entry is Array) or entry.size() != 3:
			continue
		var v := Vector3i(int(entry[0]), int(entry[1]), int(entry[2]))
		if block_at(v.x, v.y, v.z) == 0:
			continue
		_blocks[_cell_index(v.x, v.z) * int(map["depth"]) + v.y] = 0
		broken.append(v)
		for origin in _touched_chunk_origins(v.x, v.z):
			touched[origin] = true
	for origin in touched:
		_rebuild_chunk(origin.x, origin.y)


## An era arrives: the nodes that were waiting for it surface. Returns
## how many.
func reveal_era(era: int) -> int:
	current_era = era
	var revealed := 0
	var still_waiting: Array = []
	for def in _pending_nodes:
		if int(def.get("era", 1)) <= era:
			_spawn_resource_node(def)
			revealed += 1
		else:
			still_waiting.append(def)
	_pending_nodes = still_waiting
	return revealed


func pending_node_count() -> int:
	return _pending_nodes.size()


func _spawn_resource_node(def: Dictionary) -> void:
	if int(def.get("era", 1)) > current_era:
		_pending_nodes.append(def)
		return
	var node: ResourceNode = RESOURCE_NODE_SCENE.instantiate()
	node.heat_to_work = int(def.get("heat_to_work", 0))
	# y is part of the name: a cave-floor node and a surface node may share
	# a column, and saves match nodes by name.
	node.name = "wn_%s_%d_%d_%d" % [def["type"], def["x"], def["y"], def["z"]]
	node.material_family = StringName(def["material_family"])
	node.remaining_units = def["units"]
	node.units_per_harvest = def["units_per_harvest"]
	node.visual = StringName(def["visual"])
	nodes_root.add_child(node)
	var cell: float = map["cell_size"]
	# Local position: terrain sits at the origin, and this also works when a
	# harness builds the terrain before the first frame.
	node.position = Vector3(
		(int(def["x"]) + 0.5) * cell, float(def["y"]), (int(def["z"]) + 0.5) * cell)


# --- fire-setting (D-020: heat cracks stone, cold shatters what is hot) -----

func _process(delta: float) -> void:
	_expire_timer -= delta
	if _expire_timer > 0.0 or _hot.is_empty():
		return
	_expire_timer = 0.5
	var now := Time.get_ticks_msec()
	var cooled: Array = []
	for cell in _hot:
		if _hot[cell]["until"] <= now:
			cooled.append(cell)
	for cell in cooled:
		_hot.erase(cell)
		_clear_overlay(cell)


## The fire heat a block kind needs before cold can crack it (0 = never).
func heat_to_crack(kind: String) -> int:
	return int(block_rules.get(kind, {}).get("heat_to_crack", 0))


## Fire heat the cell is soaked in right now (0 when cold).
func heat_level(cell: Vector3i) -> int:
	if not _hot.has(cell):
		return 0
	return int(_hot[cell]["heat"])


func is_cracked(cell: Vector3i) -> bool:
	return cracked.has(cell)


## Hands dig soil, and any rock that has been cracked.
func diggable_by_hand(cell: Vector3i) -> bool:
	var kind := kind_at(cell.x, cell.y, cell.z)
	if kind == "":
		return false
	if block_rules.get(kind, {}).get("by_hand", true):
		return true
	return cracked.has(cell)


## Why LMB does nothing here ("" when it digs). The words are the tutorial.
func dig_refusal(cell: Vector3i) -> String:
	var kind := kind_at(cell.x, cell.y, cell.z)
	if kind == "" or diggable_by_hand(cell):
		return ""
	var need := heat_to_crack(kind)
	if need <= 0 or not block_rules.get(kind, {}).get("breakable", false):
		return "%s will not break" % Hud.pretty(kind)
	var heat := heat_level(cell)
	if heat >= need:
		return "%s glows  ·  cold will crack it" % Hud.pretty(kind)
	if heat > 0:
		return "%s is warm  ·  it wants a hotter fire (charcoal)" % Hud.pretty(kind)
	return "%s will not yield to hands  ·  fire against it, then cold" % Hud.pretty(kind)


## A fire at `centre` soaks every crackable block within `reach` cells
## (Chebyshev) at `heat`, and every resource node standing that close.
## Returns how many blocks are hot afterwards.
func heat_around(centre: Vector3i, heat: int, reach: int) -> int:
	var count := 0
	for dz in range(-reach, reach + 1):
		for dy in range(-reach, reach + 1):
			for dx in range(-reach, reach + 1):
				var cell := centre + Vector3i(dx, dy, dz)
				if heat_block(cell, heat):
					count += 1
	var cs: float = map["cell_size"]
	var at := Vector3((centre.x + 0.5) * cs, float(centre.y), (centre.z + 0.5) * cs)
	if nodes_root != null:
		for node in nodes_root.get_children():
			if node is ResourceNode and (node as ResourceNode).heat_to_work > 0 \
					and node.position.distance_to(at) <= (reach + 0.75) * cs:
				(node as ResourceNode).soak(heat, float(fire_rules.get("hot_seconds", 45.0)))
	return count


## One block soaked at `heat` (an Ember Bolt striking rock). False when the
## cell is not rock that fire can work, or is already cracked.
func heat_block(cell: Vector3i, heat: int) -> bool:
	var kind := kind_at(cell.x, cell.y, cell.z)
	if kind == "" or heat_to_crack(kind) <= 0 or cracked.has(cell):
		return false
	var until := Time.get_ticks_msec() + int(float(fire_rules.get("hot_seconds", 45.0)) * 1000.0)
	var level := heat
	if _hot.has(cell):
		level = maxi(level, int(_hot[cell]["heat"]))
	_hot[cell] = {"heat": level, "until": until}
	_set_overlay(cell, true)
	return true


## Cold lands at `point`: every hot block within `radius` whose heat meets
## its kind's need cracks (and stays cracked), and every hot node too.
## Returns how many blocks cracked.
func quench_at(point: Vector3, radius: float) -> int:
	var cs: float = map["cell_size"]
	var count := 0
	var hits: Array = []
	for cell in _hot:
		var centre := Vector3((cell.x + 0.5) * cs, (cell.y + 0.5) * cs, (cell.z + 0.5) * cs)
		if centre.distance_to(point) > radius:
			continue
		var kind := kind_at(cell.x, cell.y, cell.z)
		if int(_hot[cell]["heat"]) >= heat_to_crack(kind):
			hits.append(cell)
	for cell in hits:
		_hot.erase(cell)
		cracked[cell] = true
		_set_overlay(cell, false)
		count += 1
	if nodes_root != null:
		for node in nodes_root.get_children():
			if node is ResourceNode and node.position.distance_to(point) <= radius + 0.75 * cs:
				(node as ResourceNode).quench()
	return count


## Cracked cells as flat x,y,z triples, for the save.
func cracked_packed_list() -> Array:
	var out: Array = []
	for cell in cracked:
		out.append([cell.x, cell.y, cell.z])
	return out


## SaveManager hook: the save's cracks, exactly (heat never persists).
func apply_cracked(list: Array) -> void:
	for cell in cracked.keys():
		_clear_overlay(cell)
	cracked.clear()
	for cell in _hot.keys():
		_clear_overlay(cell)
	_hot.clear()
	for entry in list:
		if not (entry is Array) or entry.size() != 3:
			continue
		var cell := Vector3i(int(entry[0]), int(entry[1]), int(entry[2]))
		if block_at(cell.x, cell.y, cell.z) == 0:
			continue
		cracked[cell] = true
		_set_overlay(cell, false)


func _forget_cell(cell: Vector3i) -> void:
	_hot.erase(cell)
	cracked.erase(cell)
	_clear_overlay(cell)


## A thin shell over the block: ember-orange while hot, dark and dull once
## cracked. One MultiMesh instance cannot be retinted, so the state is a
## second mesh.
func _set_overlay(cell: Vector3i, hot: bool) -> void:
	_clear_overlay(cell)
	if _overlays == null:
		return
	var cs: float = map["cell_size"]
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3.ONE * cs * 1.03
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	if hot:
		material.albedo_color = Color(1.0, 0.45, 0.1, 0.45)
		material.emission_enabled = true
		material.emission = Color(1.0, 0.4, 0.05)
		material.emission_energy_multiplier = 1.5
	else:
		material.albedo_color = Color(0.08, 0.06, 0.06, 0.55)
	box.material = material
	mesh.mesh = box
	mesh.position = Vector3((cell.x + 0.5) * cs, (cell.y + 0.5) * cs, (cell.z + 0.5) * cs)
	_overlays.add_child(mesh)
	_overlay_nodes[cell] = mesh


func _clear_overlay(cell: Vector3i) -> void:
	if _overlay_nodes.has(cell):
		var old: Node = _overlay_nodes[cell]
		_overlay_nodes.erase(cell)
		if is_instance_valid(old):
			old.queue_free()
