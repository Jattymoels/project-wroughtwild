extends Node3D
## Codex regression: source-cell picking, collision, seam rebuild and restoration.
var terrain: Terrain
var sim: WroughtwildSim
var frame := 0
var checks := 0
var failures := 0
var target := Vector3i.ZERO
var originals: Dictionary = {}
var original_normals: Dictionary = {}
var old_bodies: Dictionary = {}
var player: WroughtwildPlayer

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + label)

func _ready() -> void:
	sim = load("res://scripts/sim.gd").shared()
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain._sim = sim
	terrain._seed = 1
	terrain.map = sim.world_map(1)
	terrain._blocks = terrain.map["blocks"].duplicate()
	terrain.block_rules = sim.block_rules()
	terrain.faceted_surface = true
	terrain.frontier_look = preload("res://art/frontier_look.tres")
	for x in [144, 160]:
		for z in [144, 160]:
			var data: Dictionary = sim.world_mesh_chunk(1, 16, x, z, PackedInt32Array(), true)
			originals[Vector2i(x,z)] = data["faces"]
			original_normals[Vector2i(x,z)] = data["soft_normals"]
			check(data["source_cells"].size() * 3 == data["faces"].size(), "every collision triangle has a source voxel")
			var rendered := 0
			for kind in data["surfaces"]:
				rendered += data["surfaces"][kind].size()
			check(rendered == data["faces"].size(), "render and collision have matching vertex counts")
			terrain._build_chunk(data, 1)
			old_bodies["%s_%s" % [x,z]] = terrain.chunks["%s_%s" % [x,z]].get_instance_id()
	target = Vector3i(159, terrain.height_at(159,159)-1, 159)
	check(terrain._touched_chunk_origins(159,159).size() == 4, "corner dig invalidates the diagonal chunk too")
	check(terrain._touched_chunk_origins(150,150).size() == 1, "interior dig rebuilds only its own chunk")
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.process_mode = Node.PROCESS_MODE_DISABLED
	player.position = Vector3(150, 30, 150)

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame == 5:
		check(player.placement._buried({"kind":"volume", "axis":0, "cell":target*2}), "placement reserves the visible terrain voxel")
		var hit := _ray()
		check(not hit.is_empty() and int(hit.get("face_index", -1)) >= 0, "physics exposes the faceted triangle index")
		if not hit.is_empty():
			check(terrain.block_from_surface_hit(hit) == target, "real ray maps to the precise editable block")
			check(absf(hit["position"].y - float(target.y + 1)) < 0.001, "voxel face centre retains its resource anchoring height")
		check(terrain.break_block(target.x,target.y,target.z) != "", "picked block digs through the normal rules")
		check(terrain.block_at(target.x,target.y,target.z) == 0, "dig updates the authoritative block field")
		check(not player.placement._buried({"kind":"volume", "axis":0, "cell":target*2}), "excavated voxel becomes available to construction")
		for key in old_bodies:
			check(terrain.chunks[key].get_instance_id() != old_bodies[key], "dig rebuilds affected chunk " + key)
	if frame == 10:
		var hit := _ray()
		check(not hit.is_empty() and hit["position"].y < float(target.y + 1) - 0.1, "collision follows the excavated hole")
		if not hit.is_empty():
			var cell := terrain.block_from_surface_hit(hit)
			check(cell != target and terrain.block_at(cell.x,cell.y,cell.z) != 0, "hole ray selects the next solid voxel")
		# Compare every shared grid-vertex occurrence across chunk boundaries.
		var edge_positions: Dictionary = {}
		for coordinate in originals:
			var data: Dictionary = sim.world_mesh_chunk(1,16,coordinate.x,coordinate.y,terrain.broken_packed(),true)
			var faces: PackedVector3Array = data["faces"]
			for vertex in faces:
				var key := Vector3i(roundi(vertex.x),roundi(vertex.y),roundi(vertex.z))
				# Ignore pinned face centres; only shared lattice corners matter.
				if absf(vertex.x-160) < 0.49 and absf(vertex.z-160) < 0.49:
					if edge_positions.has(key):
						check(edge_positions[key].is_equal_approx(vertex), "rebuilt chunk corner has identical shared vertex")
					else:
						edge_positions[key] = vertex
		terrain.apply_broken_blocks([])
	if frame == 15:
		check(terrain.block_at(target.x,target.y,target.z) != 0, "restoring the saved empty edit list restores the voxel")
		for coordinate in originals:
			var data: Dictionary = sim.world_mesh_chunk(1,16,coordinate.x,coordinate.y,terrain.broken_packed(),true)
			check(data["faces"] == originals[coordinate], "restoration reproduces exact faceted triangles")
			for kind in data["soft_normals"]:
				check(data["soft_normals"][kind] == original_normals[coordinate][kind], "restoration reproduces exact lighting normals")
		var hit := _ray()
		check(not hit.is_empty() and terrain.block_from_surface_hit(hit) == target, "restored collision selects the restored block")
		print("Codex faceted terrain: %d checks, %d failures" % [checks,failures])
		get_tree().quit(0 if failures == 0 else 1)

func _ray() -> Dictionary:
	var xz := Vector3(target.x+0.5,0,target.z+0.5)
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(
		xz + Vector3.UP * (target.y+3), xz + Vector3.UP * (target.y-2)))
