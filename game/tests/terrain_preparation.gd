extends "res://tests/wide_terrain_stream.gd"
## Focused preparation lifecycle checks. The separate wide_terrain_stream
## fixture owns long travel, finite harvesting and saved-state restoration.
var preparation_cases: Array[Dictionary] = []

func _exercise() -> void:
	var stream := terrain.chunk_stream
	check(stream != null, "profile has a staged terrain stream")
	if stream == null: return
	stream._finish_job()
	stream._pending.clear()
	var region: Dictionary = terrain.map.regions[0]
	await _compare_builds(Vector2i(int(region.x)/16*16, int(region.z)/16*16), "regional cover")
	var cave_origin := Vector2i(-1, -1)
	for definition: Dictionary in terrain.map.nodes:
		if int(definition.y) < terrain.height_at(int(definition.x), int(definition.z))-2:
			cave_origin = Vector2i(int(definition.x)/16*16, int(definition.z)/16*16)
			break
	check(cave_origin.x >= 0, "generated cave provides a second geometry case")
	if cave_origin.x >= 0: await _compare_builds(cave_origin, "cave floor and ceiling")
	var spawn := terrain.surface_position(int(terrain.map.spawn_x), int(terrain.map.spawn_z))
	var origin := Vector2i(int(spawn.x)/16*16, int(spawn.z)/16*16)
	await _compare_builds(origin, "starting ground")
	await _finish_before_restore(origin, spawn)
	await _dig_during_preparation(origin)

func _mesh_arrays(mesh: Mesh) -> Array:
	var result: Array = []
	for surface in mesh.get_surface_count(): result.append(mesh.surface_get_arrays(surface))
	return result

func _complete_signature(chunk: Node3D) -> String:
	var records: Array = []
	for child in chunk.get_children():
		var row := {"class": child.get_class(), "transform": child.transform}
		if child is MeshInstance3D:
			row.mesh = _mesh_arrays(child.mesh)
		elif child is MultiMeshInstance3D:
			row.mesh = _mesh_arrays(child.multimesh.mesh)
			row.instances = child.multimesh.instance_count
			row.visible_instances = child.multimesh.visible_instance_count
			row.buffer = child.multimesh.buffer
			for key in ["world_transforms", "display_transforms", "hidden_by_building", "cover_bounds"]:
				row[key] = child.get_meta(key, [])
		elif child is StaticBody3D:
			row.cells = child.get_meta("surface_cells", PackedVector3Array())
			row.layers = [child.collision_layer, child.collision_mask]
			row.shapes = []
			for shape in child.get_children():
				if shape is CollisionShape3D:
					row.shapes.append([shape.transform, shape.disabled, shape.shape.get_faces(), shape.shape.backface_collision])
		records.append(row)
	if chunk.has_meta("surface_sampler"):
		var sampler: SurfaceSampler = chunk.get_meta("surface_sampler")
		records.append([sampler.faces, sampler.coordinates, sampler.columns, sampler.cell_size])
	var digest := HashingContext.new()
	digest.start(HashingContext.HASH_SHA256)
	digest.update(var_to_bytes(records))
	return digest.finish().hex_encode()

func _begin_partial(origin: Vector2i) -> void:
	var stream := terrain.chunk_stream
	stream._finish_job()
	stream._retire(origin)
	stream._pending = [origin]
	stream._step_job() # Native payload only; still no scene or queryable chunk.
	check(not stream._job.is_empty(), "selected chunk starts a real staged job")

func _compare_builds(origin: Vector2i, label: String) -> void:
	var key := "%d_%d" % [origin.x, origin.y]
	var stream := terrain.chunk_stream
	stream._finish_job()
	stream._retire(origin)
	sim.set_world_profile(profile)
	var data := sim.world_mesh_chunk(1, 16, origin.x, origin.y, terrain.broken_packed(), terrain.faceted_surface, terrain._blend_palette())
	terrain._build_chunk(data, float(terrain.map.cell_size))
	var expected := _complete_signature(terrain.chunks[key])
	_begin_partial(origin)
	var phases := 0
	# A finite guard detects a stuck job without assuming the number of small
	# presentation stages remains four. This is a test budget, not scheduling.
	while not stream._job.is_empty() and phases < 32:
		check(not terrain.chunks.has(key), label + ": incomplete geometry is not in the public chunk registry")
		var partial: Node3D = stream._job.node
		if is_instance_valid(partial):
			check(not partial.visible, label + ": incomplete geometry stays hidden")
			check(partial.find_children("*", "CollisionObject3D", true, false).is_empty(), label + ": incomplete geometry has no active collider")
		var middle := terrain.surface_position(origin.x+8, origin.y+8)
		check(not is_finite(terrain.rendered_height(middle.x, middle.z, middle.y)), label + ": incomplete sampler is not queryable")
		await get_tree().physics_frame
		await get_tree().physics_frame
		check(_floor_hit(middle).is_empty(), label + ": physics has no premature surface")
		stream._step_job()
		phases += 1
	check(stream._job.is_empty() and terrain.chunks.has(key), label + ": preparation completes within its finite budget")
	if not terrain.chunks.has(key): return
	check(terrain.chunks[key].visible, label + ": completed chunk is visible")
	check(_complete_signature(terrain.chunks[key]) == expected, label + ": staged mesh, cover, sampler, picking cells and collision exactly match synchronous output")
	preparation_cases.append({"case": label, "origin": [origin.x, origin.y], "steps_after_payload": phases, "sha256": expected})

func _finish_before_restore(origin: Vector2i, spawn: Vector3) -> void:
	var stream := terrain.chunk_stream
	var key := "%d_%d" % [origin.x, origin.y]
	var expected := _complete_signature(terrain.chunks[key])
	_begin_partial(origin)
	stream._step_job()
	var partial: Node3D = stream._job.get("node")
	check(is_instance_valid(partial), "restore fixture starts with a partial sampler")
	if not is_instance_valid(partial): return
	terrain.ensure_area(spawn, 16)
	check(stream._job.is_empty() and terrain.chunks.has(key), "ensure_area finishes pending work before returning to its caller")
	check(terrain.chunks[key] == partial and partial.visible, "ensure_area completes the existing node once")
	check(_complete_signature(partial) == expected, "synchronous flush preserves the complete staged output")
	await get_tree().physics_frame
	await get_tree().physics_frame
	_physical_surface(spawn, "restored player position")

func _dig_during_preparation(origin: Vector2i) -> void:
	var stream := terrain.chunk_stream
	# Dig on a real seam: the left neighbour's pre-edit payload is already
	# partly built when ordinary excavation requests its synchronous rebuild.
	var neighbour := origin-Vector2i(16, 0)
	_begin_partial(neighbour)
	stream._step_job()
	check(is_instance_valid(stream._job.get("node")), "dig fixture owns partial pre-edit geometry")
	if not is_instance_valid(stream._job.get("node")): return
	var obsolete: WeakRef = weakref(stream._job.node)
	var old_sampler: WeakRef = weakref(stream._job.node.get_meta("surface_sampler"))
	var y := terrain.height_at(origin.x, origin.y)-1
	terrain.cracked[Vector3i(origin.x, y, origin.y)] = true
	check(terrain.break_block(origin.x, y, origin.y) != "", "normal seam excavation succeeds during neighbour preparation")
	check(stream._job.is_empty() and obsolete.get_ref() == null and old_sampler.get_ref() == null, "dig cancels and frees the old payload's node and sampler")
	check(terrain.block_at(origin.x, y, origin.y) == 0, "dig remains authoritative after staged cancellation")
	var edited := {}
	for touched in terrain._touched_chunk_origins(origin.x, origin.y):
		var key := "%d_%d" % [touched.x, touched.y]
		check(terrain.chunks.has(key), "dig synchronously publishes touched exact geometry " + key)
		if terrain.chunks.has(key): edited[key] = _complete_signature(terrain.chunks[key])
	# A stale queued origin must observe the replacement and cannot publish
	# its old geometry over the dig on a later tick.
	stream._pending = [neighbour]
	for step in 8: stream._step_job()
	for key in edited:
		check(terrain.chunks.has(key) and _complete_signature(terrain.chunks[key]) == edited[key], "later queued work cannot refill or replace edited seam " + key)
	var name := "Chunk_%d_%d" % [neighbour.x, neighbour.y]
	check(terrain.find_children(name, "Node3D", false, false).size() == 1, "cancellation leaves one owned replacement chunk")

func _finish() -> void:
	print("TERRAIN_PREPARATION_CASES ", JSON.stringify(preparation_cases))
	if is_instance_valid(terrain): terrain.free()
	print("TERRAIN_PREPARATION %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
