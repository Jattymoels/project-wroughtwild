class_name TerrainChunkStream
extends RefCounted
## The full native world always exists. Only exact near geometry is staged;
## distant terrain is the same generated heightfield at a coarser resolution.
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
var _job: Dictionary = {}

func setup(owner_terrain: Terrain) -> void:
	terrain = owner_terrain
	_settings = preload("res://art/strange_stream.tres").settings()
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
	chunk_build_ms.append((Time.get_ticks_usec()-began)/1000.0)
	set_detail(origin,true)
	_refresh_nodes(origin)

func _refresh_nodes(origin: Vector2i) -> void:
	# Nodes can be materialised by a save or a review before its exact mesh.
	# Reground only that small neighbourhood when the real surface arrives.
	if is_instance_valid(terrain.nodes_root):
		var cell := float(terrain.map.cell_size)
		for node in terrain.nodes_root.get_children():
			if node is ResourceNode and node.position.x>=(origin.x-1)*cell and node.position.x<=(origin.x+Terrain.CHUNK_CELLS+1)*cell and node.position.z>=(origin.y-1)*cell and node.position.z<=(origin.y+Terrain.CHUNK_CELLS+1)*cell:
					node.refresh_surface()
	var parent:=terrain.get_parent()
	if parent is Node3D and parent.has_node("StrangeSites"):
		StrangeSites.refresh_area(parent,terrain,origin.x,origin.y,Terrain.CHUNK_CELLS)
	if parent is Node3D:
		var history := parent.get_node_or_null("CataclysmSites")
		if history != null: history.refresh_area(origin.x,origin.y,Terrain.CHUNK_CELLS)

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
	for key in terrain.chunks:
		if wanted.has(key) or keep.has(key): continue
		var parts: PackedStringArray=String(key).split("_")
		set_detail(Vector2i(int(parts[0]),int(parts[1])),false)
	_flush_mask()

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
			_refresh_nodes(_job.origin)
			_job.clear()
	phase_build_ms.append((Time.get_ticks_usec()-began)/1000.0)
	# Bounded diagnostic window; an afternoon of exploration does not grow a log.
	if phase_build_ms.size()>512: phase_build_ms.pop_front()

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
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var step:=int(_settings.terrain_far_step_cells)
	var width:=int(terrain.map.width)
	var height:=int(terrain.map.height)
	var cell:=float(terrain.map.cell_size)
	for z in range(0,height,step):
		for x in range(0,width,step):
			var x1:=mini(x+step,width)
			var z1:=mini(z+step,height)
			var points: Array[Vector2i]=[Vector2i(x,z),Vector2i(x,z1),Vector2i(x1,z),Vector2i(x1,z),Vector2i(x,z1),Vector2i(x1,z1)]
			for p in points:
				surface.set_color(_colour(p.x,p.y))
				surface.add_vertex(Vector3(p.x*cell,_height(p.x,p.y)*cell,p.y*cell))
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
