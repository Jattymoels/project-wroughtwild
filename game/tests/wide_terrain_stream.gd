extends Node3D
## Real generated terrain and ResourceStream. Runs in the isolated review;
## historical V5 mode is an early regression, V6 is the acceptance target.
var checks := 0
var failures := 0
var terrain: Terrain
var sim: WroughtwildSim
var profile := "frontier_v6"
var visits: Array = []

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL WIDE TERRAIN: ",label)

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--stream-profile="): profile=arg.trim_prefix("--stream-profile=")
	sim=load("res://scripts/sim.gd").shared()
	if not sim.set_world_profile(profile):
		check(false,"requested generation profile is available: "+profile)
		_finish()
		return
	terrain=Terrain.new()
	terrain.name="Terrain"
	terrain.weathered=true
	add_child(terrain)
	terrain.build(sim,1,profile)
	terrain.set_process(false)
	await _exercise()
	_finish()

func _finish() -> void:
	var report := {"profile":profile,"seed":1,"checks":checks,"failures":failures,"visits":visits}
	if is_instance_valid(terrain):
		report["startup"]=terrain.build_profile
		report["retention"]=terrain.chunk_stream.retention()
		report["static_memory_bytes"]=OS.get_static_memory_usage()
		terrain.free()
	print("WIDE_TERRAIN_STREAM ",JSON.stringify(report))
	print("WIDE_TERRAIN_STREAM %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _key(point: Vector3) -> String:
	var cell:=float(terrain.map.cell_size)
	return "%d_%d"%[floori(point.x/cell/16)*16,floori(point.z/cell/16)*16]

func _signature(chunk: Node3D) -> int:
	var parts: Array=[]
	for child in chunk.get_children():
		if child is MeshInstance3D:
			for surface in child.mesh.get_surface_count(): parts.append(child.mesh.surface_get_arrays(surface))
		elif child is MultiMeshInstance3D:
			parts.append(child.get_meta("world_transforms",[]))
		elif child is StaticBody3D:
			parts.append(child.get_meta("surface_cells",PackedVector3Array()))
			for shape in child.get_children():
				if shape is CollisionShape3D: parts.append(shape.shape.get_faces())
	parts.append(chunk.get_meta("surface_sampler").faces)
	return hash(parts)

func _floor_hit(point: Vector3) -> Dictionary:
	var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*0.4,point-Vector3.UP*0.6,1)
	var excluded: Array[RID]=[]
	for node in terrain.nodes_root.get_children():
		if node is CollisionObject3D: excluded.append(node.get_rid())
	query.exclude=excluded
	return get_world_3d().direct_space_state.intersect_ray(query)

func _physical_surface(point: Vector3,label: String) -> void:
	var exact:=terrain.rendered_height(point.x,point.z,point.y)
	check(is_finite(exact),label+" has an exact supported surface")
	if not is_finite(exact): return
	var hit:=_floor_hit(Vector3(point.x,exact,point.z))
	check(not hit.is_empty() and terrain.is_terrain_body(hit.get("collider")),label+" has actual terrain collision")
	if not hit.is_empty(): check(absf(float(hit.position.y)-exact)<0.002,label+" collision matches the sampler")

func _bounded(label: String) -> void:
	var status:=terrain.chunk_stream.retention()
	check(int(status.resident_chunks)<=int(status.near_chunk_bound)+int(status.edited_chunk_bound),label+" resident terrain is bounded by the current area plus real edits")
	var actual:=0
	for child in terrain.get_children():
		if String(child.name).begins_with("Chunk_"): actual+=1
	check(actual<=int(status.resident_chunks)+int(status.partial_chunks),label+" has no orphan mesh or collision nodes")
	visits.append(status.duplicate())

func _exercise() -> void:
	var stream:=terrain.chunk_stream
	check(stream!=null,"current world profile uses bounded terrain streaming")
	if stream==null: return
	var extent:=int(terrain.map.width)
	check(extent==(1024 if profile=="frontier_v6" else 512),"expected finite map extent")
	check(int(terrain.map.depth)==(96 if profile=="frontier_v6" else 48),"expected full voxel depth")
	check(terrain.chunks.size()<extent*extent/256,"startup does not build the whole world")
	var horizon: PackedVector3Array=stream._horizon.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var skyline_valid:=horizon.size()==int(stream.horizon_triangles)*3
	var maximum:=Vector3.ZERO
	for point in horizon:
		maximum=maximum.max(point)
		skyline_valid=skyline_valid and point.is_finite() and absf(point.y-terrain.height_at(clampi(int(point.x),0,extent-1),clampi(int(point.z),0,extent-1)))<0.001
	check(skyline_valid,"complete coarse skyline retains the exact native sampled heights")
	check(maximum.x==extent and maximum.z==extent,"horizon covers every edge of the finite world")
	check(stream._horizon.get_child_count()==0,"far-only surface never supplies fake collision")

	var spawn:=terrain.surface_position(int(terrain.map.spawn_x),int(terrain.map.spawn_z))
	var start_key:=_key(spawn)
	var old_chunk: Node3D=terrain.chunks[start_key]
	var old_node: WeakRef=weakref(old_chunk)
	var old_sampler: WeakRef=weakref(old_chunk.get_meta("surface_sampler"))
	var old_body: WeakRef=weakref(old_chunk.get_node("ChunkBody"))
	var pristine_signature:=_signature(old_chunk)
	old_chunk=null
	# Use normal contextual work, leaving a real boulder one press into its
	# next chunk. No fixture-only harvest rules or synthetic node data.
	var boulders: Array=[]
	for id in terrain.resource_stream.records:
		var record: Dictionary=terrain.resource_stream.records[id]
		var p:=Vector3(record.position[0],record.position[1],record.position[2])
		if String(record.visual)=="boulder" and int(record.drive_presses)>1 and int(record.heat_to_work)==0 and p.distance_to(spawn)<100:
			boulders.append(id)
	check(boulders.size()>=2,"generated starting supply supports partial and depleted-node checks")
	if boulders.size()<2: return
	var partial_id:=String(boulders[0])
	var spent_id:=String(boulders[1])
	var partial:=terrain.resource_stream.materialise(partial_id)
	var before_units:=partial.remaining_units
	var press: Dictionary=partial.work(sim)
	check(partial.drive_progress==1 and not press.has("granted") and partial.remaining_units==before_units,"one normal work press remains unbanked partial harvesting")
	var partial_position:=partial.position
	var spent:=terrain.resource_stream.materialise(spent_id)
	var depleted_units:=spent.remaining_units
	var granted:=0
	while spent.remaining_units>0: granted+=spent.harvest()
	check(granted==depleted_units,"depletion removes only the generated finite stock")
	await get_tree().process_frame
	var saved_records:=terrain.resource_stream.capture()
	check(not terrain.resource_stream.has_resource(spent_id),"depleted record is absent before terrain retirement")
	partial=null
	spent=null

	# Independent distant destinations force release even without ordinary
	# player-process ticks, then a few staged phases exercise live prefetch.
	for fraction in [Vector2(0.12,0.12),Vector2(0.88,0.12),Vector2(0.88,0.88),Vector2(0.12,0.88),Vector2(0.65,0.78),Vector2(0.25,0.65)]:
		var point:=terrain.surface_position(int(extent*fraction.x),int(extent*fraction.y))
		terrain.ensure_area(point,32)
		terrain.resource_stream.focus(point)
		for phase in 10: stream._step_job()
		_bounded("distant travel "+str(fraction))
		await get_tree().physics_frame
		await get_tree().physics_frame
		# Native cave breaches may have no intended top surface; the exact
		# playable home and cave-floor assertions below use guaranteed support.
	check(old_node.get_ref()==null and old_body.get_ref()==null,"distant exact mesh node and physics body are freed")
	check(old_sampler.get_ref()==null,"surface triangle lookup storage is freed with its chunk")
	check(not terrain.chunks.has(start_key),"initial terrain is no longer retained after distant travel")
	check(stream.chunks_retired_total>0,"real release counter records retired chunks")
	check(not terrain.resource_stream.active.has(partial_id),"partial resource scene also retires during distant travel")
	check(int(terrain.resource_stream.records[partial_id].drive_progress)==1 and int(terrain.resource_stream.records[partial_id].remaining_units)==before_units,"terrain release preserves partial work and finite stock")

	# Restore data while the originating exact mesh and resource scene are
	# absent; this is the same resource/terrain restore operation used by saves.
	terrain.resource_stream.restore(saved_records)
	terrain.apply_broken_blocks([])
	check(not terrain.chunks.has(start_key),"restoring unedited state does not eagerly rebuild old terrain")
	sim.set_world_profile("legacy_v1")
	terrain.ensure_area(spawn,36)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(terrain.world_profile()==profile and sim.world_profile()==profile,"return uses the original profile and seed despite an unrelated preview")
	check(_signature(terrain.chunks[start_key])==pristine_signature,"revisit rebuilds identical exact render, cover, collision and editable faces")
	_physical_surface(spawn,"restored starting location")
	terrain.ensure_area(partial_position,16)
	partial=terrain.resource_stream.materialise(partial_id)
	check(partial.drive_progress==1 and partial.remaining_units==before_units,"save-style restoration retains a partial node across terrain eviction")
	var payout:=0
	for i in partial.drive_presses-1: payout+=int(partial.work(sim).get("granted",0))
	check(payout==partial.units_per_harvest and partial.remaining_units==before_units-payout and partial.drive_progress==0,"resumed normal work pays exactly the remaining partial harvest")
	check(not terrain.resource_stream.has_resource(spent_id) and terrain.resource_stream.materialise(spent_id)==null,"return and restore never regenerate a depleted node")
	partial=null

	await _cave_return()
	await _excavation_and_cancel()
	# A long session can perform arbitrarily many operations; these are the
	# real metric append path, bounded independently of operation totals.
	for i in int(stream._settings.diagnostic_window_samples)+17:
		stream._record(stream.chunk_build_ms,float(i))
		stream._record(stream.phase_build_ms,float(i))
		stream._record(stream.chunk_retire_ms,float(i))
	for values in [stream.chunk_build_ms,stream.phase_build_ms,stream.chunk_retire_ms]:
		check(values.size()==int(stream._settings.diagnostic_window_samples) and values[0]==17.0,"long-running timing diagnostics keep only their newest fixed window")
	_bounded("final retention")

func _cave_return() -> void:
	var cave:=Vector3.INF
	for definition: Dictionary in terrain.map.nodes:
		if int(definition.y)<terrain.height_at(int(definition.x),int(definition.z))-2:
			cave=Vector3(float(definition.x)+0.5,definition.y,float(definition.z)+0.5)
			break
	check(cave.is_finite(),"real generated cave floor is available for travel regression")
	if not cave.is_finite(): return
	terrain.ensure_area(cave,16)
	await get_tree().physics_frame
	await get_tree().physics_frame
	_physical_surface(cave,"native underground floor before eviction")
	var key:=_key(cave)
	var prior:=_signature(terrain.chunks[key])
	var extent:=int(terrain.map.width)
	var opposite:=terrain.surface_position(extent-32 if cave.x<extent/2 else 32,extent-32 if cave.z<extent/2 else 32)
	terrain.ensure_area(opposite,16)
	check(not terrain.chunks.has(key),"underground sampler and collision can retire with their unedited column")
	terrain.ensure_area(cave,16)
	await get_tree().physics_frame
	await get_tree().physics_frame
	check(_signature(terrain.chunks[key])==prior,"revisited cave retains exact ceiling, floor and source face mapping")
	_physical_surface(cave,"native underground floor after eviction")

func _excavation_and_cancel() -> void:
	var stream:=terrain.chunk_stream
	var extent:=int(terrain.map.width)
	var spawn:=terrain.surface_position(int(terrain.map.spawn_x),int(terrain.map.spawn_z))
	terrain.ensure_area(spawn,32)
	stream._finish_job()
	var remote:=Vector2i(16,16)
	if Vector2(remote).distance_to(Vector2(spawn.x,spawn.z))<250: remote=Vector2i(extent-32,extent-32)
	stream._pending=[remote]
	stream._step_job()
	stream._step_job()
	check(not stream._job.is_empty() and is_instance_valid(stream._job.node),"fixture enters a staged chunk before collision publication")
	var stale: WeakRef=weakref(stream._job.node)
	var stale_sampler: WeakRef=weakref(stream._job.node.get_meta("surface_sampler"))
	stream.focus(spawn)
	check(stream._job.is_empty() and stale.get_ref()==null and stale_sampler.get_ref()==null,"changing focus cancels and frees out-of-range partial geometry")
	var x:=int(spawn.x)/16*16
	var z:=int(spawn.z)/16*16
	# A real seam-boundary surface dig pins every affected neighbouring chunk.
	var y:=terrain.height_at(x,z)-1
	terrain.cracked[Vector3i(x,y,z)]=true
	check(terrain.break_block(x,y,z)!="","normal excavation removes a surface block on a chunk seam")
	var edited_keys: Array[String]=[]
	var signatures: Dictionary={}
	for origin in terrain._touched_chunk_origins(x,z):
		var key:="%d_%d"%[origin.x,origin.y]
		edited_keys.append(key)
		signatures[key]=_signature(terrain.chunks[key])
	terrain.ensure_area(terrain.surface_position(remote.x,remote.y),32)
	for key in edited_keys:
		check(terrain.chunks.has(key) and terrain.chunks[key].visible,"far excavation and seam neighbour stay exact: "+key)
		check(_signature(terrain.chunks[key])==signatures[key],"far edited geometry is never replaced with pristine approximation: "+key)
	_bounded("edited terrain after departure")
	terrain.apply_broken_blocks([])
	stream.focus(terrain.surface_position(remote.x,remote.y))
	for key in edited_keys: check(not terrain.chunks.has(key),"restoring away a later dig releases its former pin: "+key)
	terrain.apply_broken_blocks([[x,y,z]])
	check(terrain.block_at(x,y,z)==0,"saved excavation is restored while the player is distant")
	for key in edited_keys:
		check(_signature(terrain.chunks[key])==signatures[key],"saved excavation rebuilds exact distant geometry: "+key)
	terrain.ensure_area(spawn,32)
	check(terrain.block_at(x,y,z)==0,"return never refills restored excavation")
