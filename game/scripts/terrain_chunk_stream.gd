class_name TerrainChunkStream
extends RefCounted
## The full native world always exists. Exact near geometry is staged and
## retired; distant terrain is the same generated surface at lower detail.
## Excavation and its seam neighbours stay exact until a far edited-surface
## representation exists. Ordinary exploration does not retain visited chunks.
var terrain: Terrain
var _settings: Dictionary
var _mask: Image
var _mask_texture: ImageTexture
var _horizon: MeshInstance3D
var _pending: Array[Vector2i] = []
var _focus := Vector3.INF
var _timer := 0.0
var _mask_dirty := false
var chunk_build_ms: Array[float] = []
var phase_build_ms: Array[float] = []
var chunk_retire_ms: Array[float] = []
# Per-stage samples locate indivisible travel stalls; each uses the same fixed
# diagnostic window as the aggregate timings, never a growing journey log.
const PREPARATION_STAGES := ["payload", "sampler", "meshes", "cover", "collision_refresh"]
const REFRESH_STAGES := ["collision_faces", "collision_body", "cover_suppression", "resource_refresh", "rare_refresh", "history_refresh"]
var _preparation_samples: Dictionary = {}
var chunks_built_total := 0
var chunks_retired_total := 0
var horizon_build_ms := 0.0
var horizon_triangles := 0
var _job: Dictionary = {}

func setup(owner_terrain: Terrain) -> void:
	terrain = owner_terrain
	_settings = preload("res://art/strange_stream.tres").settings()
	for stage: String in PREPARATION_STAGES + REFRESH_STAGES:
		var samples: Array[float] = []
		_preparation_samples[stage] = samples
	_mask = Image.create(ceili(float(terrain.map.width)/Terrain.CHUNK_CELLS),ceili(float(terrain.map.height)/Terrain.CHUNK_CELLS),false,Image.FORMAT_R8)
	_mask.fill(Color.BLACK)
	_mask_texture = ImageTexture.create_from_image(_mask)
	_build_horizon()
	var spawn := terrain.surface_position(int(terrain.map.spawn_x),int(terrain.map.spawn_z))
	ensure_area(spawn,float(_settings.terrain_initial_radius_m))
	focus(spawn)

func _origins(point: Vector3,radius_m: float) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var cell := float(terrain.map.cell_size)
	var side := Terrain.CHUNK_CELLS*cell
	var radius := radius_m + side*0.72
	var lo_x := maxi(0,floori((point.x-radius)/side)*Terrain.CHUNK_CELLS)
	var hi_x := mini(int(terrain.map.width)-1,ceili((point.x+radius)/side)*Terrain.CHUNK_CELLS)
	var lo_z := maxi(0,floori((point.z-radius)/side)*Terrain.CHUNK_CELLS)
	var hi_z := mini(int(terrain.map.height)-1,ceili((point.z+radius)/side)*Terrain.CHUNK_CELLS)
	for z in range(lo_z,hi_z+1,Terrain.CHUNK_CELLS):
		for x in range(lo_x,hi_x+1,Terrain.CHUNK_CELLS):
			if Vector2((x+Terrain.CHUNK_CELLS*0.5)*cell-point.x,(z+Terrain.CHUNK_CELLS*0.5)*cell-point.z).length_squared()<=radius*radius:
				result.append(Vector2i(x,z))
	result.sort_custom(func(a: Vector2i,b: Vector2i) -> bool:
		return Vector2(a.x*cell-point.x,a.y*cell-point.z).length_squared()<Vector2(b.x*cell-point.x,b.y*cell-point.z).length_squared())
	return result

func _build(origin: Vector2i) -> void:
	var key := "%d_%d" % [origin.x,origin.y]
	if terrain.chunks.has(key):
		set_detail(origin,true)
		return
	var began := Time.get_ticks_usec()
	terrain._sim.set_world_profile(terrain.world_profile())
	var data: Dictionary = terrain._sim.world_mesh_chunk(terrain.seed_value(),Terrain.CHUNK_CELLS,origin.x,origin.y,terrain.broken_packed(),terrain.faceted_surface,terrain._blend_palette())
	terrain._build_chunk(data,float(terrain.map.cell_size))
	_record(chunk_build_ms,(Time.get_ticks_usec()-began)/1000.0)
	chunks_built_total+=1
	set_detail(origin,true)
	_refresh_nodes(origin)

func _refresh_nodes(origin: Vector2i, measure := false) -> void:
	# Nodes can be materialised by a save or a review before its exact mesh.
	# Reground only that small neighbourhood when the real surface arrives.
	var began := Time.get_ticks_usec()
	if is_instance_valid(terrain.nodes_root):
		var cell := float(terrain.map.cell_size)
		for node in terrain.nodes_root.get_children():
			if node is ResourceNode and node.position.x>=(origin.x-1)*cell and node.position.x<=(origin.x+Terrain.CHUNK_CELLS+1)*cell and node.position.z>=(origin.y-1)*cell and node.position.z<=(origin.y+Terrain.CHUNK_CELLS+1)*cell:
					node.refresh_surface()
	if measure: _record(_preparation_samples.resource_refresh,(Time.get_ticks_usec()-began)/1000.0)
	began = Time.get_ticks_usec()
	var parent:=terrain.get_parent()
	if parent is Node3D and parent.has_node("StrangeSites"):
		StrangeSites.refresh_area(parent,terrain,origin.x,origin.y,Terrain.CHUNK_CELLS)
	if measure: _record(_preparation_samples.rare_refresh,(Time.get_ticks_usec()-began)/1000.0)
	began = Time.get_ticks_usec()
	if parent is Node3D:
		var history := parent.get_node_or_null("CataclysmSites")
		if history != null: history.refresh_area(origin.x,origin.y,Terrain.CHUNK_CELLS)
	if measure: _record(_preparation_samples.history_refresh,(Time.get_ticks_usec()-began)/1000.0)

func set_detail(origin: Vector2i,visible: bool) -> void:
	var key := "%d_%d" % [origin.x,origin.y]
	var chunk: Node3D = terrain.chunks.get(key)
	if is_instance_valid(chunk): chunk.visible=visible
	var x := floori(float(origin.x)/Terrain.CHUNK_CELLS)
	var z := floori(float(origin.y)/Terrain.CHUNK_CELLS)
	var value := Color.WHITE if visible else Color.BLACK
	if _mask.get_pixel(x,z).r!=value.r:
		_mask.set_pixel(x,z,value)
		_mask_dirty=true

func _flush_mask() -> void:
	if _mask_dirty:
		_mask_texture.update(_mask)
		_mask_dirty=false

func ensure_area(point: Vector3,radius_m:=32.0) -> void:
	# Restores and teleports also move the retirement focus. Otherwise repeated
	# synchronous visits could keep whole regions alive without a player tick.
	focus(point)
	_finish_job()
	for origin in _origins(point,radius_m): _build(origin)
	_flush_mask()

func focus(point: Vector3) -> void:
	_focus=point
	_pending.clear()
	var wanted := {}
	for origin in _origins(point,float(_settings.terrain_detail_radius_m)):
		var key := "%d_%d" % [origin.x,origin.y]
		wanted[key]=true
		if terrain.chunks.has(key): set_detail(origin,true)
		else: _pending.append(origin)
	var keep := {}
	for origin in _origins(point,float(_settings.terrain_keep_radius_m)):
		keep["%d_%d" % [origin.x,origin.y]]=true
	# Excavated chunks keep their exact visible silhouette. A far approximation
	# must never refill a player-made quarry while looking back from a ridge.
	for v in terrain.broken:
		for origin in terrain._touched_chunk_origins(v.x,v.z): keep["%d_%d" % [origin.x,origin.y]]=true
	# A completed stale job would publish collision behind the player after
	# retirement. Free its partial meshes/sampler as well as its native payload.
	if not _job.is_empty():
		var job_key := "%d_%d" % [_job.origin.x,_job.origin.y]
		if not wanted.has(job_key) and not keep.has(job_key): cancel_chunk(_job.origin)
	for key in terrain.chunks.keys():
		if wanted.has(key) or keep.has(key): continue
		var parts: PackedStringArray=String(key).split("_")
		_retire(Vector2i(int(parts[0]),int(parts[1])))
	_flush_mask()

func _retire(origin: Vector2i) -> void:
	var began := Time.get_ticks_usec()
	set_detail(origin,false)
	# Samplers, editable-face mappings, cover poses, GPU meshes and physics
	# shapes are owned by this one node. Freeing it releases them together.
	if terrain._release_chunk(origin):
		chunks_retired_total+=1
		_record(chunk_retire_ms,(Time.get_ticks_usec()-began)/1000.0)

func _record(values: Array[float],milliseconds: float) -> void:
	values.append(milliseconds)
	if values.size()>int(_settings.diagnostic_window_samples): values.pop_front()

func preparation_samples() -> Dictionary:
	# Review tools receive an independent snapshot and cannot mutate the live
	# rolling samples. These timings have no generation or scheduling authority.
	return _preparation_samples.duplicate(true)

func retention() -> Dictionary:
	var pinned := {}
	for v in terrain.broken:
		for origin in terrain._touched_chunk_origins(v.x,v.z): pinned["%d_%d" % [origin.x,origin.y]]=true
	return {"resident_chunks":terrain.chunks.size(),"edited_chunk_bound":pinned.size(),
		"near_chunk_bound":_origins(_focus,float(_settings.terrain_keep_radius_m)).size() if _focus.is_finite() else 0,
		"partial_chunks":0 if _job.is_empty() else 1,"built_total":chunks_built_total,"retired_total":chunks_retired_total,
		"horizon_triangles":horizon_triangles,"horizon_build_ms":horizon_build_ms}

func tick(delta: float,point: Vector3) -> void:
	# A direct teleport is a supported restore/review path. Even a caller that
	# missed ensure_area receives collision before ordinary travel continues.
	if not _focus.is_finite() or point.distance_to(_focus)>float(_settings.terrain_safe_radius_m):
		ensure_area(point,float(_settings.terrain_safe_radius_m))
		focus(point)
	_timer-=delta
	if _timer<=0.0:
		_timer=float(_settings.refresh_seconds)
		if point.distance_squared_to(_focus)>1.0: focus(point)
	for i in int(_settings.terrain_chunks_per_frame):
		_step_job()
	_flush_mask()

func _step_job() -> void:
	if _job.is_empty() and _pending.is_empty(): return
	var began:=Time.get_ticks_usec()
	var stage_index := 0 if _job.is_empty() else int(_job.phase) + 1
	if _job.is_empty():
		while not _pending.is_empty():
			var origin: Vector2i=_pending.pop_front()
			if terrain.chunks.has("%d_%d" % [origin.x,origin.y]): continue
			terrain._sim.set_world_profile(terrain.world_profile())
			var data: Dictionary=terrain._sim.world_mesh_chunk(terrain.seed_value(),Terrain.CHUNK_CELLS,origin.x,origin.y,terrain.broken_packed(),terrain.faceted_surface,terrain._blend_palette())
			_job={"origin":origin,"data":data,"phase":0,"node":null}
			break
	else:
		_job.node=terrain._build_chunk_phase(_job.data,float(terrain.map.cell_size),int(_job.phase),_job.node)
		_job.phase=int(_job.phase)+1
		if int(_job.phase)==4:
			set_detail(_job.origin,true)
			for stage: String in terrain.last_collision_profile:
				_record(_preparation_samples[stage],float(terrain.last_collision_profile[stage]))
			_refresh_nodes(_job.origin,true)
			chunks_built_total+=1
			_job.clear()
	var elapsed_ms := (Time.get_ticks_usec()-began)/1000.0
	_record(phase_build_ms,elapsed_ms)
	_record(_preparation_samples[PREPARATION_STAGES[stage_index]],elapsed_ms)

func _finish_job() -> void:
	while not _job.is_empty(): _step_job()

func cancel_chunk(origin: Vector2i) -> void:
	if _job.is_empty() or _job.origin!=origin: return
	var partial: Node3D=_job.node
	if is_instance_valid(partial):
		partial.get_parent().remove_child(partial)
		partial.free()
	_job.clear()

func _height(x: int,z: int) -> float:
	return float(terrain.height_at(clampi(x,0,int(terrain.map.width)-1),clampi(z,0,int(terrain.map.height)-1)))

func _colour(x: int,z: int) -> Color:
	x=clampi(x,0,int(terrain.map.width)-1)
	z=clampi(z,0,int(terrain.map.height)-1)
	var biome_index := int((terrain.map.biomes as PackedInt32Array)[z*int(terrain.map.width)+x])
	var kind := String(terrain.map.biome_defs[biome_index].surface)
	var palette: Dictionary=terrain.frontier_look.top_colours if terrain.frontier_look!=null else {"grass":Color(0.285,0.365,0.20),"forest_floor":Color(0.16,0.235,0.155),"marsh":Color(0.235,0.28,0.205),"rock":Color(0.35,0.365,0.37),"ash":Color(0.204,0.18,0.18)}
	var c: Color=palette.get(kind,Color(0.35,0.365,0.37))
	return c.srgb_to_linear()

func _build_horizon() -> void:
	var began := Time.get_ticks_usec()
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step:=int(_settings.terrain_far_step_cells)
	var width:=int(terrain.map.width)
	var height:=int(terrain.map.height)
	var cell:=float(terrain.map.cell_size)
	# Sample each grid point once, instead of six repeated terrain/palette
	# lookups per quad. Topology and native heights stay identical at 1 km.
	var columns:=ceili(float(width)/step)+1
	var rows:=ceili(float(height)/step)+1
	var positions:=PackedVector3Array()
	var colours:=PackedColorArray()
	positions.resize(columns*rows)
	colours.resize(columns*rows)
	for iz in rows:
		for ix in columns:
			var x:=mini(ix*step,width)
			var z:=mini(iz*step,height)
			positions[iz*columns+ix]=Vector3(x*cell,_height(x,z)*cell,z*cell)
			colours[iz*columns+ix]=_colour(x,z)
	for iz in rows-1:
		for ix in columns-1:
			var a:=iz*columns+ix
			for index in [a,a+columns,a+1,a+1,a+columns,a+columns+1]:
				surface.set_color(colours[index])
				surface.add_vertex(positions[index])
	surface.generate_normals()
	_horizon=MeshInstance3D.new()
	_horizon.name="StrangeFrontierHorizon"
	_horizon.mesh=surface.commit()
	var material:=ShaderMaterial.new()
	material.shader=preload("res://art/strange_horizon.gdshader")
	material.set_shader_parameter("detail_mask",_mask_texture)
	material.set_shader_parameter("world_size",Vector2(width*cell,height*cell))
	_horizon.material_override=material
	terrain.add_child(_horizon)
	horizon_triangles=(columns-1)*(rows-1)*2
	horizon_build_ms=(Time.get_ticks_usec()-began)/1000.0
