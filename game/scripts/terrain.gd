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
var resource_stream: ResourceStream
var chunk_stream: TerrainChunkStream
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
## Codex aesthetic comparison, opt-in; never serialized into a world save.
var frontier_look: Resource
## Separate v3 presentation: older world profiles keep their prior materials
## and atmosphere, including when the owner loads one into this same scene.
var atmosphere_look: Resource
var faceted_surface := false
var weathered := false
var build_profile: Dictionary = {}
var last_chunk_profile: Dictionary = {}
var _sim: WroughtwildSim
var _seed := 0
var _world_profile := "legacy_v1"
var _habitat_refresh_queued := false
var _augmentation_texture: ImageTexture
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


func world_profile() -> String:
	return _world_profile


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

## Faceted triangles carry their exact editable voxel; never guess from a
## slanted normal. Legacy cubic callers retain their existing conversion.
func block_from_surface_hit(hit: Dictionary) -> Vector3i:
	var body: Object = hit.get("collider")
	var face_index := int(hit.get("face_index", -1))
	if faceted_surface and body != null and body.has_meta("surface_cells"):
		var cells: PackedVector3Array = body.get_meta("surface_cells")
		if face_index >= 0 and face_index < cells.size():
			return Vector3i(cells[face_index])
	return block_from_hit(hit["position"], hit["normal"])


## World-space centre of a cell's top face: where things stand.
func surface_position(x: int, z: int) -> Vector3:
	var cell: float = map["cell_size"]
	return Vector3((x + 0.5) * cell, float(height_at(x, z)), (z + 0.5) * cell)


func _material_for(kind: String) -> Material:
	if _materials.has(kind):
		return _materials[kind]
	if frontier_look != null:
		var frontier_material: Material = frontier_look.terrain_material(kind, float(map.get("cell_size", 1.0)))
		frontier_material.set_shader_parameter("world_mesh", faceted_surface)
		if _world_profile in ["frontier_v4", "frontier_v5", "frontier_v6"] and _augmentation_texture != null:
			frontier_material.set_shader_parameter("augmentation_enabled", true)
			frontier_material.set_shader_parameter("augmentation_map", _augmentation_texture)
			frontier_material.set_shader_parameter("augmentation_extent", Vector2(map.width, map.height) * float(map.cell_size))
			frontier_material.set_shader_parameter("augmentation_tint", preload("res://art/cataclysm_look.tres").ground_tint_strength)
		_materials[kind] = frontier_material
		return frontier_material
	var material := StandardMaterial3D.new()
	material.albedo_texture = load(KIND_TEXTURES.get(kind, KIND_TEXTURES["rock"]))
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	material.roughness = 1.0
	if KIND_TINTS.has(kind):
		material.albedo_color = KIND_TINTS[kind]
	_materials[kind] = material
	return material


func build(sim: WroughtwildSim, seed_value: int, profile_id: String = "") -> void:
	# Direct old fixtures keep the sim's legacy default; new Sandpit worlds
	# select frontier_v2 explicitly. Reject before clearing any existing world.
	if not profile_id.is_empty() and not sim.set_world_profile(profile_id):
		push_error(sim.last_error())
		return
	var build_start := Time.get_ticks_msec()
	var crafted := OS.get_cmdline_user_args().has("--crafted-look")
	weathered = weathered or OS.get_cmdline_user_args().has("--weathered-look")
	faceted_surface = OS.get_cmdline_user_args().has("--faceted-look") or crafted or weathered
	if OS.get_cmdline_user_args().has("--frontier-look") or faceted_surface:
		frontier_look = preload("res://art/frontier_look.tres")
	if crafted:
		frontier_look = preload("res://art/crafted_look.tres")
	if weathered:
		frontier_look = preload("res://art/weathered_look.tres")
	_materials.clear()
	chunk_stream=null
	for child in get_children():
		remove_child(child)
		child.free()
	chunks.clear()
	broken.clear()
	_sim = sim
	_seed = seed_value
	_world_profile = sim.world_profile()
	atmosphere_look = null
	_augmentation_texture = null
	if weathered and _world_profile in ["frontier_v3", "frontier_v4", "frontier_v5", "frontier_v6"]:
		frontier_look = preload("res://art/wildland_look.tres")
		atmosphere_look = preload("res://art/wildland_atmosphere.tres")
	current_era = int(sim.era().get("index", 1))
	_pending_nodes.clear()
	resource_stream = null
	map = sim.world_map(seed_value)
	if map.is_empty():
		push_error("Terrain: sim.world_map returned nothing")
		return
	if _world_profile in ["frontier_v4", "frontier_v5", "frontier_v6"]:
		var field: PackedFloat32Array = map.get("augmentation_field", PackedFloat32Array())
		if field.size() == int(map.width) * int(map.height):
			_augmentation_texture = ImageTexture.create_from_image(Image.create_from_data(int(map.width), int(map.height), false, Image.FORMAT_RF, field.to_byte_array()))
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
	var geometry_start := Time.get_ticks_msec()
	if weathered:
		HabitatCover.prepare(map)
	if _world_profile in ["frontier_v3", "frontier_v4", "frontier_v5", "frontier_v6"]:
		chunk_stream=TerrainChunkStream.new()
		chunk_stream.setup(self)
	else:
		for chunk_data in sim.world_mesh(seed_value, CHUNK_CELLS, faceted_surface, _blend_palette()):
			_build_chunk(chunk_data, cell)
	var resources_start := Time.get_ticks_msec()

	nodes_root = Node3D.new()
	nodes_root.name = "ResourceNodes"
	add_child(nodes_root)
	if _world_profile in ["frontier_v3", "frontier_v4", "frontier_v5", "frontier_v6"]:
		resource_stream = ResourceStream.new()
		resource_stream.setup(self,map["nodes"])
		resource_stream.focus(surface_position(int(map.spawn_x),int(map.spawn_z)),true)
	else:
		for node in map["nodes"]:
			_spawn_resource_node(node)
	build_profile = {"map_ms":geometry_start-build_start,"chunks_ms":resources_start-geometry_start,
		"resources_ms":Time.get_ticks_msec()-resources_start,"total_ms":Time.get_ticks_msec()-build_start}


func _blend_palette() -> Dictionary:
	return frontier_look.top_colours if frontier_look != null and frontier_look.blend_materials else {}

## Exact surface/cave collision before a saved pose, review move or teleport.
## Coordinates are local to Terrain, matching surface_position and map nodes.
func ensure_area(local_position: Vector3,radius_m:=32.0) -> void:
	if chunk_stream != null: chunk_stream.ensure_area(local_position,radius_m)

## The chunk owns all exact surface samplers, cover transforms and collision.
## No resource records or excavation state belong to its presentation lifetime.
func _release_chunk(origin: Vector2i) -> bool:
	var key := "%d_%d" % [origin.x,origin.y]
	var chunk: Node3D = chunks.get(key)
	chunks.erase(key)
	if not is_instance_valid(chunk): return false
	remove_child(chunk)
	chunk.free()
	return true

func _build_chunk(chunk_data: Dictionary, cell: float) -> void:
	var chunk: Node3D
	var phase_names := ["sampler_ms","meshes_ms","cover_ms","collision_ms"]
	last_chunk_profile={}
	for phase in 4:
		var began:=Time.get_ticks_usec()
		chunk=_build_chunk_phase(chunk_data,cell,phase,chunk)
		last_chunk_profile[phase_names[phase]]=(Time.get_ticks_usec()-began)/1000.0

## Small independent presentation phases let exploration amortise expensive
## cover and collision work. Chunks become queryable only after collision exists.
func _build_chunk_phase(chunk_data: Dictionary,cell: float,phase: int,chunk: Node3D=null) -> Node3D:
	if phase==0:
		chunk = Node3D.new()
		chunk.name = "Chunk_%d_%d" % [int(chunk_data["x"]), int(chunk_data["z"])]
		add_child(chunk)
		if faceted_surface:
			chunk.set_meta("surface_sampler", SurfaceSampler.new(chunk_data["faces"], cell))
		chunk.visible=false
	elif phase==1:
		var kinds: Dictionary = chunk_data["kinds"]
		for kind in kinds:
			if chunk_data.has("surfaces"):
				var arrays := []
				arrays.resize(Mesh.ARRAY_MAX)
				arrays[Mesh.ARRAY_VERTEX] = chunk_data["surfaces"][kind]
				arrays[Mesh.ARRAY_NORMAL] = chunk_data["normals"][kind]
				if chunk_data.get("blend_colours",{}).has(kind):
					arrays[Mesh.ARRAY_COLOR] = chunk_data.blend_colours[kind]
				if frontier_look != null and frontier_look.soft_terrain:
					arrays[Mesh.ARRAY_NORMAL] = chunk_data["soft_normals"][kind]
				var surface := ArrayMesh.new()
				surface.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
				var visible := MeshInstance3D.new()
				visible.mesh = surface
				visible.material_override = _material_for(String(kind))
				chunk.add_child(visible)
				continue
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

	elif phase==2:
		GroundCover.build_for_chunk(chunk, chunk_data, map, cell, frontier_look,_world_profile in ["frontier_v3", "frontier_v4", "frontier_v5", "frontier_v6"])
		if weathered:
			HabitatCover.build(chunk,chunk_data,map,cell,_world_profile in ["frontier_v3", "frontier_v4", "frontier_v5", "frontier_v6"])

	elif phase==3:
		var faces: PackedVector3Array = chunk_data["faces"]
		if not faces.is_empty():
			var shape := ConcavePolygonShape3D.new()
			shape.set_faces(faces)
			# The sim does not promise a winding; collide from both sides.
			shape.backface_collision = true
			var body := StaticBody3D.new()
			body.name = "ChunkBody"
			body.set_meta("terrain_chunk", true)
			if chunk_data.has("source_cells"):
				body.set_meta("surface_cells", chunk_data["source_cells"])
			var collider := CollisionShape3D.new()
			collider.shape = shape
			body.add_child(collider)
			chunk.add_child(body)
		# A placed floor can predate this streamed/rebuilt chunk. Suppress
		# intersecting V3 cover before publishing any visible grass or shrubs.
		if _world_profile in ["frontier_v3", "frontier_v4", "frontier_v5", "frontier_v6"]: StrangeSites.refresh_cover_chunk(self,chunk)
		chunks["%d_%d" % [int(chunk_data.x),int(chunk_data.z)]]=chunk
		chunk.visible=true
	return chunk


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
	if faceted_surface:
		# Vertex averaging reads diagonally across a chunk corner as well.
		var sides := origins.duplicate()
		for a in sides:
			for b in sides:
				var diagonal := Vector2i(a.x, b.y)
				if not origins.has(diagonal):
					origins.append(diagonal)
	return origins


func _rebuild_chunk(cx: int, cz: int) -> void:
	# A terrain query must retain this world's full identity even if another
	# fixture or a preview most recently selected a different sim profile.
	if not _sim.set_world_profile(_world_profile):
		push_error(_sim.last_error())
		return
	cx -= cx % CHUNK_CELLS
	cz -= cz % CHUNK_CELLS
	if chunk_stream != null: chunk_stream.cancel_chunk(Vector2i(cx,cz))
	_release_chunk(Vector2i(cx,cz))
	var packed := PackedInt32Array()
	for v in broken:
		packed.append(v.x)
		packed.append(v.y)
		packed.append(v.z)
	_build_chunk(_sim.world_mesh_chunk(_seed, CHUNK_CELLS, cx, cz, packed, faceted_surface, _blend_palette()), map["cell_size"])
	if chunk_stream != null: chunk_stream.set_detail(Vector2i(cx,cz),true)
	if faceted_surface and is_instance_valid(nodes_root):
		var cell: float = map["cell_size"]
		for node in nodes_root.get_children():
			if node is ResourceNode and node.position.x >= (cx-2)*cell and node.position.x <= (cx+CHUNK_CELLS+2)*cell and node.position.z >= (cz-2)*cell and node.position.z <= (cz+CHUNK_CELLS+2)*cell:
				node.refresh_surface()
	# A dig can touch several chunks; refresh the three compositions once
	# after the entire edit rather than once for every neighbouring chunk.
	if get_parent() is Node3D and not _habitat_refresh_queued:
		_habitat_refresh_queued = true
		_refresh_habitats.call_deferred()

func _refresh_habitats() -> void:
	_habitat_refresh_queued = false
	if get_parent() is Node3D:
		HabitatSites.refresh(get_parent(), self)
		StrangeSites.refresh(get_parent(), self)
		var history := get_parent().get_node_or_null("CataclysmSites")
		if history != null: history.refresh_all()

## Same triangles used by picking and walking. Queries near chunk edges also
## consider neighbours because rounded corners can extend over the boundary.
func rendered_height(x: float, z: float, reference_y: float, reach := 0.8) -> float:
	var cell: float = map.get("cell_size",1.0)
	var cx := floori(x / cell / CHUNK_CELLS) * CHUNK_CELLS
	var cz := floori(z / cell / CHUNK_CELLS) * CHUNK_CELLS
	var result := INF
	var xs := [0]
	var zs := [0]
	# Rounded vertices move at most half a cell. Interior samples need only
	# their own chunk; boundary samples keep the neighbouring triangles.
	if x/cell-cx<0.5:
		xs.append(-CHUNK_CELLS)
	elif x/cell-cx>CHUNK_CELLS-0.5:
		xs.append(CHUNK_CELLS)
	if z/cell-cz<0.5:
		zs.append(-CHUNK_CELLS)
	elif z/cell-cz>CHUNK_CELLS-0.5:
		zs.append(CHUNK_CELLS)
	for dx in xs:
		for dz in zs:
			var chunk: Node3D = chunks.get("%d_%d" % [cx+dx,cz+dz])
			if chunk == null or not chunk.has_meta("surface_sampler"):
				continue
			var y: float = chunk.get_meta("surface_sampler").height_at(x,z,reference_y,reach)
			if is_finite(y) and (not is_finite(result) or absf(y-reference_y)<absf(result-reference_y)):
				result = y
	return result


## SaveManager hook: makes the world's digs exactly the save's - undoes
## holes dug since (the field resets to the sim's pristine blocks), then
## re-carves the saved list and rebuilds every chunk either set touched.
func apply_broken_blocks(list: Array) -> void:
	var touched := {}
	for v in broken:
		for origin in _touched_chunk_origins(v.x, v.z):
			touched[origin] = true
	broken.clear()
	if _world_profile in ["frontier_v4", "frontier_v5", "frontier_v6"]:
		var field: PackedFloat32Array = map.get("augmentation_field", PackedFloat32Array())
		if field.size() == int(map.width) * int(map.height):
			_augmentation_texture = ImageTexture.create_from_image(Image.create_from_data(int(map.width), int(map.height), false, Image.FORMAT_RF, field.to_byte_array()))
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
	if resource_stream != null:
		var revealed_count := 0
		for record in resource_stream.records.values():
			if int(record.get("era",1))>current_era and int(record.get("era",1))<=era: revealed_count+=1
		current_era=era
		return revealed_count
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
	if resource_stream != null:
		var count := 0
		for record in resource_stream.records.values():
			if int(record.get("era",1))>current_era: count+=1
		return count
	return _pending_nodes.size()


func _spawn_resource_node(def: Dictionary) -> void:
	if int(def.get("era", 1)) > current_era:
		_pending_nodes.append(def)
		return
	var node: ResourceNode = RESOURCE_NODE_SCENE.instantiate()
	node.heat_to_work = int(def.get("heat_to_work", 0))
	node.tool_item = StringName(String(def.get("tool_item", "")))
	node.drive_presses = maxi(int(def.get("drive_presses", 1)), 1)
	# y is part of the name: a cave-floor node and a surface node may share
	# a column, and saves match nodes by name.
	var identity := String(def.get("resource_id", "wn_%s_%d_%d_%d" % [def["type"], def["x"], def["y"], def["z"]]))
	node.name = identity
	node.resource_id = identity
	node.habitat_id = String(def.get("habitat_id", ""))
	node.presentation_label = String(def.get("presentation_label", def.get("display_name", "")))
	node.material_family = StringName(def["material_family"])
	node.remaining_units = def["units"]
	node.units_per_harvest = def["units_per_harvest"]
	node.visual = StringName(def["visual"])
	node.set_meta("rare_stages",Array(def.get("harvest_stages",[])))
	node.set_meta("rare_use",String(def.get("use_preview","")))
	node.set_meta("site_id",String(def.get("site_id","")))
	var cell: float = map["cell_size"]
	# Local position: terrain sits at the origin, and this also works when a
	# harness builds the terrain before the first frame. Set before the node
	# enters the tree, so its look (seeded by position; a seam's line
	# following the cells it crosses) is built in the right place.
	node.position = Vector3(
		(int(def["x"]) + 0.5) * cell, float(def["y"]), (int(def["z"]) + 0.5) * cell)
	nodes_root.add_child(node)


# --- fire-setting (D-020: heat cracks stone, cold shatters what is hot) -----

func _process(delta: float) -> void:
	if chunk_stream != null:
		var geometry_player := get_parent().get_node_or_null("Player") as Node3D
		if geometry_player != null: chunk_stream.tick(delta,to_local(geometry_player.global_position))
	if resource_stream != null:
		var player := get_parent().get_node_or_null("Player") as Node3D
		if player != null:
			resource_stream.tick(delta,to_local(player.global_position))
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
		return "%s is hot  ·  heavy impact or cold cracks it" % Hud.pretty(kind)
	if heat > 0:
		return "%s is warm  ·  it wants a hotter fire (charcoal)" % Hud.pretty(kind)
	return "%s needs a fire, then heavy impact or cold" % Hud.pretty(kind)


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


## A heavy blow on one hot block cracks it (the impact route, D-021).
func crack_block(cell: Vector3i) -> bool:
	if not _hot.has(cell):
		return false
	var kind := kind_at(cell.x, cell.y, cell.z)
	if int(_hot[cell]["heat"]) < heat_to_crack(kind):
		return false
	_hot.erase(cell)
	cracked[cell] = true
	_set_overlay(cell, false)
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
