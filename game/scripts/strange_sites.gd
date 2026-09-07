class_name StrangeSites
extends RefCounted
## Composed regional silhouettes and persistent empty housings. Generation owns
## regions, sites, approaches and intact specimens; these nodes grant no loot.
const LOOK = preload("res://art/strange_look.tres")
const ECOLOGY = preload("res://art/strange_ecology.tres")
const DISCOVERY = preload("res://art/discovery_look.tres")
const INDEX_CELL := 4.0
static var _meshes: Dictionary={}
static var _materials: Dictionary={}
## Review-only ablation: compare the same scene and poses with the former full scan.
static var _bounded_refresh := not OS.get_cmdline_user_args().has("--cat-unbounded-refresh")

static func build(root: Node3D, terrain: Terrain) -> Node3D:
	var previous:=root.get_node_or_null("StrangeSites")
	if previous!=null:
		root.remove_child(previous)
		previous.queue_free()
	var dressing:=Node3D.new()
	dressing.name="StrangeSites"
	root.add_child(dressing)
	var reservations:=_reservations(terrain)
	# One pass over generated identities, not a whole-world scan on every cue.
	var site_resources:=_site_resource_ids(terrain)
	for region: Dictionary in terrain.map.get("regions",[]): _region(dressing,terrain,region,reservations)
	for site: Dictionary in terrain.map.get("rare_sites",[]): _site(dressing,terrain,site,site_resources.get(String(site.id),[]))
	refresh_buildings(root,terrain)
	return dressing

static func refresh(root: Node3D, terrain: Terrain) -> void:
	if root!=null and root.has_node("StrangeSites"):
		# Keep the same ecological placements when digging or restoring. A new
		# world calls build explicitly; local terrain edits only re-ground or
		# suppress existing poses, so they cannot shuffle the neighbouring grove.
		refresh_area(root,terrain,0,0,maxi(int(terrain.map.get("width",0)),int(terrain.map.get("height",0))))

static func refresh_area(root: Node3D, terrain: Terrain, cx: int, cz: int, width: int = 16) -> void:
	var dressing:=root.get_node_or_null("StrangeSites")
	if dressing==null: return
	var cell:=float(terrain.map.get("cell_size",1.0))
	var bounds:=Rect2(Vector2(cx*cell-1,cz*cell-1),Vector2(width*cell+2,width*cell+2))
	var buildings:=_building_index(terrain)
	for group in dressing.get_children():
		for part in group.get_children():
			if part is MultiMeshInstance3D:
				# Anchors never change X/Z during regrounding. Reject a distant tile
				# before touching thousands of retained ecological transforms.
				if _bounded_refresh and part.has_meta("anchor_bounds") and not bounds.intersects(part.get_meta("anchor_bounds")): continue
				var transforms: Array=part.get_meta("world_transforms",[])
				var heights: Array=part.get_meta("ground_heights",[])
				var supported: Array=part.get_meta("ground_supported",[])
				var hidden: Array=part.get_meta("hidden_by_building",[])
				var displayed: Array=part.get_meta("display_transforms",[])
				if supported.size()!=transforms.size(): supported.resize(transforms.size()); supported.fill(true)
				if hidden.size()!=transforms.size(): hidden.resize(transforms.size()); hidden.fill(false)
				for i in transforms.size():
					var at: Vector3=transforms[i].origin
					if not bounds.has_point(Vector2(at.x,at.z)): continue
					var ground:=_ground(terrain,at.x,at.z)
					var local: Transform3D=transforms[i]
					if ground.is_finite():
						local.origin.y+=ground.y-float(heights[i])
						transforms[i]=local
						heights[i]=ground.y
						hidden[i]=_building_overlap(buildings,local*part.multimesh.mesh.get_aabb())
						local.origin-=part.position
					supported[i]=ground.is_finite()
					if not supported[i] or hidden[i]: local=Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO)
					part.multimesh.set_instance_transform(i,local)
					if displayed.size()==transforms.size(): displayed[i]=local
				part.set_meta("world_transforms",transforms)
				part.set_meta("ground_heights",heights)
				part.set_meta("ground_supported",supported)
				part.set_meta("hidden_by_building",hidden)
				part.set_meta("display_transforms",displayed)
			elif part is MeshInstance3D and part.has_meta("ground_y"):
				var at: Vector3=part.position
				if not bounds.has_point(Vector2(at.x,at.z)): continue
				var ground:=_ground(terrain,at.x,at.z)
				var supported:=ground.is_finite()
				if ground.is_finite():
					part.position.y+=ground.y-float(part.get_meta("ground_y"))
					part.set_meta("ground_y",ground.y)
					if part.has_meta("pool_support"):
						supported=_pool_supported(terrain,ground,float(part.get_meta("pool_radius",LOOK.pool_radius_m)),float(part.get_meta("pool_aspect",.72)))
				part.set_meta("ground_supported",supported)
				var hidden:=part.mesh!=null and _building_overlap(buildings,part.transform*part.mesh.get_aabb())
				part.set_meta("hidden_by_building",hidden)
				part.visible=supported and not hidden

## Read current lattice pieces, never scene-name guesses or save records. Batches
## keep their authoritative poses while a building temporarily hides intersecting
## decor. Removing the piece restores it only when terrain still supports it.
static func refresh_buildings(root: Node3D, terrain: Terrain) -> void:
	if root==null or terrain==null: return
	var dressing:=root.get_node_or_null("StrangeSites")
	if dressing==null: return
	var buildings:=_building_index(terrain)
	for group in dressing.get_children():
		for part in group.get_children():
			if part is MultiMeshInstance3D:
				_clear_batch_buildings(part,buildings)
			elif part is MeshInstance3D and part.mesh!=null:
				var hidden:=_building_overlap(buildings,part.transform*part.mesh.get_aabb())
				part.set_meta("hidden_by_building",hidden)
				part.visible=bool(part.get_meta("ground_supported",true)) and not hidden
	var history := root.get_node_or_null("CataclysmSites")
	if history != null: history.refresh_buildings()
	if terrain.world_profile() in ["frontier_v3","frontier_v4","frontier_v5","frontier_v6"]:
		for chunk: Node3D in terrain.chunks.values(): _clear_cover_chunk(chunk,buildings)

## Terrain calls this before a streamed/rebuilt chunk is made visible. Older
## profiles neither retain these extra poses nor take the clearing path.
static func refresh_cover_chunk(terrain: Terrain, chunk: Node3D) -> void:
	if terrain==null or chunk==null or terrain.world_profile() not in ["frontier_v3","frontier_v4","frontier_v5","frontier_v6"]: return
	_clear_cover_chunk(chunk,_building_index(terrain))

static func _clear_cover_chunk(chunk: Node3D, buildings: Dictionary) -> void:
	for part in chunk.get_children():
		if not part is MultiMeshInstance3D or not part.has_meta("terrain_cover"): continue
		# Most chunks are far from a home. Their aggregate exact bounds reject
		# the whole batch before visiting individual grass/fern transforms.
		if not bool(part.get_meta("cover_has_hidden",false)) and not _building_overlap(buildings,part.get_meta("cover_bounds")):
			continue
		_clear_batch_buildings(part,buildings)
		part.set_meta("cover_has_hidden",(part.get_meta("hidden_by_building",[]) as Array).has(true))

static func _clear_batch_buildings(part: MultiMeshInstance3D, buildings: Dictionary) -> void:
	var transforms: Array=part.get_meta("world_transforms",[])
	var supported: Array=part.get_meta("ground_supported",[])
	var previous: Array=part.get_meta("hidden_by_building",[])
	var displayed: Array=part.get_meta("display_transforms",[])
	var hidden: Array=[]
	for i in transforms.size():
		var intersects:=_building_overlap(buildings,transforms[i]*part.multimesh.mesh.get_aabb())
		hidden.append(intersects)
		if previous.size()==transforms.size() and bool(previous[i])==intersects: continue
		var local: Transform3D=transforms[i]
		local.origin-=part.position
		if intersects or (supported.size()==transforms.size() and not bool(supported[i])):
			local=Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO)
		part.multimesh.set_instance_transform(i,local)
		if displayed.size()==transforms.size(): displayed[i]=local
	part.set_meta("hidden_by_building",hidden)
	part.set_meta("display_transforms",displayed)

static func _building_index(terrain: Terrain) -> Dictionary:
	var result: Dictionary={}
	if terrain._sim==null or terrain._sim.structure_piece_count()==0: return result
	for piece: Dictionary in terrain._sim.structure_pieces():
		var shape: Dictionary=terrain._sim.shape(String(piece.shape))
		var pose: Dictionary=terrain._sim.lattice_pose(String(piece.shape),piece)
		if shape.is_empty() or pose.is_empty(): continue
		var size: Vector3=shape.size
		var centre: Vector3=pose.centre
		var yaw:=float(pose.yaw_turns)*PI*.5
		var oriented:=bool(shape.get("oriented",false))
		if String(piece.kind)=="volume":
			var grid:=terrain._sim.lattice_registry_grid() if bool(shape.get("fine",false)) else terrain._sim.grid_size()
			centre.y-=(grid-size.y)*.5
			if oriented: yaw+=float(piece.get("rotation_step",0))*PI*.5
		elif oriented and String(shape.get("form",""))=="corner" and int(piece.axis)==1: yaw+=float(piece.get("rotation_step",0))*PI*.5
		elif oriented: yaw+=float(int(piece.get("rotation_step",0))%2)*PI
		var bounds: AABB=(Transform3D(Basis(Vector3.UP,yaw),centre)*AABB(-size*.5,size)).grow(ECOLOGY.building_clearance_m)
		var begin:=Vector2i(floori(bounds.position.x/ECOLOGY.batch_width_m),floori(bounds.position.z/ECOLOGY.batch_width_m))
		var end:=Vector2i(floori(bounds.end.x/ECOLOGY.batch_width_m),floori(bounds.end.z/ECOLOGY.batch_width_m))
		for x in range(begin.x,end.x+1):
			for z in range(begin.y,end.y+1):
				var key:=Vector2i(x,z)
				if not result.has(key): result[key]=[]
				result[key].append(bounds)
	return result

static func _building_overlap(index: Dictionary, bounds: AABB) -> bool:
	if index.is_empty(): return false
	var begin:=Vector2i(floori(bounds.position.x/ECOLOGY.batch_width_m),floori(bounds.position.z/ECOLOGY.batch_width_m))
	var end:=Vector2i(floori(bounds.end.x/ECOLOGY.batch_width_m),floori(bounds.end.z/ECOLOGY.batch_width_m))
	for x in range(begin.x,end.x+1):
		for z in range(begin.y,end.y+1):
			for building: AABB in index.get(Vector2i(x,z),[]):
				if building.intersects(bounds): return true
	return false

static func _index_key(at: Vector3) -> Vector2i:
	return Vector2i(floori(at.x/INDEX_CELL),floori(at.z/INDEX_CELL))

static func _reserve(index: Dictionary, at: Vector3, radius: float) -> void:
	var key:=_index_key(at)
	if not index.has(key): index[key]=[]
	index[key].append(Vector3(at.x,radius,at.z))
	index["max_radius"]=maxf(float(index.get("max_radius",0)),radius)

static func _reservations(terrain: Terrain) -> Dictionary:
	var result: Dictionary={}
	var cell:=float(terrain.map.get("cell_size",1.0))
	for node: Dictionary in terrain.map.get("nodes",[]):
		_reserve(result,Vector3((float(node.x)+.5)*cell,0,(float(node.z)+.5)*cell),LOOK.resource_clearance_m)
	for ruin: Dictionary in terrain.map.get("ruins",[]):
		_reserve(result, Vector3(float(ruin.x)+.5,0,float(ruin.z)+.5)*cell, maxf(float(ruin.width_m),float(ruin.depth_m))*.72)
		for route in ["approach","discovery_route"]:
			for point: Vector3 in ruin.get(route,[]): _reserve(result,point,LOOK.approach_clearance_m)
	for impact: Dictionary in terrain.map.get("impacts",[]):
		_reserve(result,Vector3((float(impact.x)+.5)*cell,0,(float(impact.z)+.5)*cell),float(impact.radius_m)*.6)
	for collection in ["regions","rare_sites","habitats"]:
		for area: Dictionary in terrain.map.get(collection,[]):
			if collection=="rare_sites":
				_reserve(result,Vector3((float(area.x)+.5)*cell,0,(float(area.z)+.5)*cell),float(area.get("radius_m",7.0)))
				for point: Vector3 in area.get("clue_points",[]): _reserve(result,point,LOOK.approach_clearance_m)
			for key in ["approach","cave_approach"]:
				for point: Vector3 in area.get(key,[]): _reserve(result,point,LOOK.approach_clearance_m)
	return result

static func _clear(index: Dictionary, at: Vector3, radius: float = 0.0) -> bool:
	var key:=_index_key(at)
	var reach:=ceili((radius+float(index.get("max_radius",LOOK.resource_clearance_m)))/INDEX_CELL)
	for x in range(-reach,reach+1):
		for z in range(-reach,reach+1):
			for point: Vector3 in index.get(key+Vector2i(x,z),[]):
				if Vector2(point.x,point.z).distance_to(Vector2(at.x,at.z))<point.y+radius: return false
	return true

static func _ground(terrain: Terrain, x: float, z: float) -> Vector3:
	var cell:=float(terrain.map.get("cell_size",1.0))
	var expected:=float(terrain.height_at(floori(x/cell),floori(z/cell)))
	var actual:=terrain.rendered_height(x,z,expected)
	# Unloaded fine geometry still has a deterministic native surface. A loaded
	# chunk with no support is an excavation/cave void and must stay empty.
	var key:="%d_%d"%[floori(x/cell/16)*16,floori(z/cell/16)*16]
	if not is_finite(actual) and not terrain.chunks.has(key): actual=expected
	return Vector3(x,actual,z)

static func _anchor(terrain: Terrain, data: Dictionary) -> Vector3:
	var cell:=float(terrain.map.get("cell_size",1.0))
	return _ground(terrain,(float(data.x)+.5)*cell,(float(data.z)+.5)*cell)

static func _supported(terrain: Terrain, at: Vector3, radius: float, rise: float) -> bool:
	for i in 8:
		var angle:=float(i)*TAU/8
		var sample:=_ground(terrain,at.x+cos(angle)*radius,at.z+sin(angle)*radius)
		if not sample.is_finite() or absf(sample.y-at.y)>rise: return false
	return true

static func _region(parent: Node3D, terrain: Terrain, data: Dictionary, reserved: Dictionary) -> void:
	var group:=Node3D.new()
	group.name=String(data.id)
	group.set_meta("region_id",String(data.id))
	parent.add_child(group)
	var centre:=_anchor(terrain,data)
	if not centre.is_finite(): return
	var radius:=float(data.get("radius_m",55.0))
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash(String(data.id))+int(terrain.map.get("seed",0))
	var batches: Dictionary={}
	var stats: Dictionary={"landmark_count":0,"detail_count":0,"canopy_count":0,"cluster_count":0}
	match String(data.id):
		"rootvault_wildwood": _woodland(terrain,centre,radius,reserved,rng,batches,stats)
		"lantern_fen": _fen(group,terrain,centre,radius,reserved,rng,batches,stats)
		"glasswind_uplands": _uplands(terrain,centre,radius,reserved,rng,batches,stats)
	for kind: String in batches: _batch(group,terrain,kind,batches[kind])
	for key: String in stats: group.set_meta(key,stats[key])
	group.set_meta("centre",centre)
	group.set_meta("radius_m",radius)
	# The last 21 authored cave points describe the stair, rather than the
	# entire cross-world route. Broken boles frame its mouth from the sides.
	var cave: PackedVector3Array=data.get("cave_approach",PackedVector3Array())
	if not cave.is_empty():
		var mouth:=cave[maxi(0,cave.size()-21)]
		for sign in [-1,1]:
			var at:=_ground(terrain,mouth.x+sign*3.5,mouth.z)
			if at.is_finite() and _clear(reserved,at,.75):
				var frame:=StrangeResourceArt.part(group,"hollow_trunk" if data.id=="rootvault_wildwood" else "stone_rib","CaveFrame",at)
				frame.scale=Vector3(.6,.7,.6)
				frame.set_meta("ground_y",at.y)

static func _clusters(terrain: Terrain, centre: Vector3, radius: float, count: int, spacing: float,
		reserved: Dictionary, rng: RandomNumberGenerator) -> Array[Vector3]:
	var result: Array[Vector3]=[]
	for i in ECOLOGY.cluster_candidates:
		var angle:=rng.randf()*TAU
		var distance:=radius*ECOLOGY.core_fraction*sqrt(rng.randf())
		var at:=_ground(terrain,centre.x+cos(angle)*distance,centre.z+sin(angle)*distance)
		if not at.is_finite() or not _clear(reserved,at,.3): continue
		var apart:=true
		for existing: Vector3 in result:
			if Vector2(at.x,at.z).distance_to(Vector2(existing.x,existing.z))<spacing: apart=false; break
		if not apart: continue
		result.append(at)
		if result.size()>=count: break
	return result

static func _around(terrain: Terrain, centre: Vector3, radius: float, rng: RandomNumberGenerator) -> Vector3:
	var angle:=rng.randf()*TAU
	# Two independent radii concentrate growth towards a grove's interior;
	# bare margins between groves remain deliberate glades, not uniform scatter.
	var distance:=radius*sqrt(rng.randf()*rng.randf())
	return _ground(terrain,centre.x+cos(angle)*distance,centre.z+sin(angle)*distance)

static func _inside(at: Vector3, centre: Vector3, radius: float) -> bool:
	return at.is_finite() and Vector2(at.x,at.z).distance_to(Vector2(centre.x,centre.z))<radius

static func _plant(terrain: Terrain, batches: Dictionary, kind: String, at: Vector3, size: Vector3,
		yaw: float, reserved: Dictionary, footprint: float, rise: float) -> bool:
	if terrain.world_profile() in ["frontier_v4", "frontier_v5", "frontier_v6"] and at.is_finite():
		var field: PackedFloat32Array = terrain.map.get("augmentation_field", PackedFloat32Array())
		var cell := float(terrain.map.cell_size)
		var x := floori(at.x / cell)
		var z := floori(at.z / cell)
		if x >= 0 and z >= 0 and x < int(terrain.map.width) and z < int(terrain.map.height) and field.size() == int(terrain.map.width) * int(terrain.map.height):
			var influence := field[z * int(terrain.map.width) + x]
			var look = preload("res://art/cataclysm_look.tres")
			if kind.begins_with("root_arch") or kind in ["wildwood_tree", "fen_tree"]: size.y *= 1.0 + influence * look.canopy_height_gain
			elif kind in ["fern", "sedge", "shrub"]: size.y *= 1.0 + influence * look.understory_height_gain
	var clearance:=footprint
	if kind in ["stone_rib","hollow_trunk","low_outcrop"]:
		# These broad forms include eroded ends and buttress roots beyond the
		# central supporting bole. Scaling their nominal support radius alone
		# understated that visual footprint, especially for small variants.
		var mesh:=_mesh_for(kind)
		if mesh!=null:
			var bounds:=mesh.get_aabb()
			var reach:=Vector2(maxf(absf(bounds.position.x),absf(bounds.end.x))*size.x,maxf(absf(bounds.position.z),absf(bounds.end.z))*size.z)
			clearance=maxf(clearance,reach.length())
		clearance=maxf(clearance,ECOLOGY.landmark_clearance_floor_m)
	if not at.is_finite() or not _clear(reserved,at,clearance): return false
	if not _supported(terrain,at,footprint,rise): return false
	if kind.begins_with("root_arch"):
		# The elder's roots extend beyond its bole. Their four grounded ends
		# may frame a route but must not occupy its walking or working strip.
		for foot: Vector3 in [Vector3(-6,0,0),Vector3(6,0,1),Vector3(-2,0,-3),Vector3(1,0,3)]:
			var end:=at+Basis(Vector3.UP,yaw)*(foot*size)
			var ground:=_ground(terrain,end.x,end.z)
			if not ground.is_finite() or absf(ground.y-at.y)>rise or not _clear(reserved,ground,.7): return false
	_add_batch(batches,kind,Transform3D(Basis(Vector3.UP,yaw).scaled(size),at-Vector3.UP*ECOLOGY.base_bury_m))
	return true

static func _woodland(terrain: Terrain, centre: Vector3, radius: float, reserved: Dictionary,
		rng: RandomNumberGenerator, batches: Dictionary, stats: Dictionary) -> void:
	var groves:=_clusters(terrain,centre,radius-ECOLOGY.grove_radius_m*.5,ECOLOGY.grove_count,ECOLOGY.grove_spacing_m,reserved,rng)
	var trunks: Dictionary={}
	stats.cluster_count=groves.size()
	for grove_index in groves.size():
		var grove: Vector3=groves[grove_index]
		# Only a few elders carry the regional silhouette. Supporting trees
		# have full crowns at several heights, clustered around those old boles.
		if stats.landmark_count<ECOLOGY.elder_count:
			var size:=rng.randf_range(ECOLOGY.elder_scale_range.x,ECOLOGY.elder_scale_range.y)
			var kind:="root_arch" if int(stats.landmark_count)%3==0 else "root_arch_b" if int(stats.landmark_count)%3==1 else "root_arch_c"
			if _plant(terrain,batches,kind,grove,Vector3.ONE*size,rng.randf()*TAU,reserved,3.6*size,ECOLOGY.tree_support_rise_m):
				_reserve(trunks,grove,ECOLOGY.tree_spacing_m)
				stats.landmark_count+=1
				stats.canopy_count+=1
		var grove_trees:=0
		for i in ECOLOGY.trees_per_grove*3:
			var at:=_around(terrain,grove,ECOLOGY.grove_radius_m,rng)
			if not _inside(at,centre,radius*ECOLOGY.core_fraction) or not _clear(trunks,at,1.3): continue
			var size:=rng.randf_range(ECOLOGY.tree_scale_range.x,ECOLOGY.tree_scale_range.y)
			if _plant(terrain,batches,"wildwood_tree",at,Vector3(size,rng.randf_range(.9,1.16)*size,size),rng.randf()*TAU,reserved,.9*size,ECOLOGY.tree_support_rise_m):
				_reserve(trunks,at,ECOLOGY.tree_spacing_m*.5)
				stats.canopy_count+=1
				stats.detail_count+=1
				grove_trees+=1
				if grove_trees>=ECOLOGY.trees_per_grove: break
		for i in ECOLOGY.saplings_per_grove:
			var at:=_around(terrain,grove,ECOLOGY.grove_radius_m*1.1,rng)
			var size:=rng.randf_range(ECOLOGY.sapling_scale_range.x,ECOLOGY.sapling_scale_range.y)
			if _inside(at,centre,radius) and _clear(trunks,at,.4) and _plant(terrain,batches,"wildwood_sapling",at,Vector3.ONE*size,rng.randf()*TAU,reserved,.45,ECOLOGY.tree_support_rise_m): stats.detail_count+=1
		for i in ECOLOGY.understory_per_grove:
			var at:=_around(terrain,grove,ECOLOGY.grove_radius_m*1.25,rng)
			if not _inside(at,centre,radius): continue
			var kind:="fern" if i%5<3 else "moss" if i%5==3 else "shrub"
			var size:=rng.randf_range(.65,1.45)
			if _plant(terrain,batches,kind,at,Vector3.ONE*size,rng.randf()*TAU,reserved,.35*size,ECOLOGY.small_support_rise_m): stats.detail_count+=1
		for i in ECOLOGY.deadfall_per_grove:
			var at:=_around(terrain,grove,ECOLOGY.grove_radius_m*.7,rng)
			var size:=rng.randf_range(.8,1.8)
			if _plant(terrain,batches,"deadfall",at,Vector3.ONE*size,rng.randf()*TAU,reserved,.8*size,ECOLOGY.small_support_rise_m): stats.detail_count+=1

static func _fen(group: Node3D, terrain: Terrain, centre: Vector3, radius: float, reserved: Dictionary,
		rng: RandomNumberGenerator, batches: Dictionary, stats: Dictionary) -> void:
	# Pools precede dry growth: shoreline rings use the native reservations,
	# while dry islands also avoid the complete water footprint.
	var dry: Dictionary=reserved.duplicate(true)
	var pools:=_pools(group,terrain,centre,radius,reserved,dry,rng)
	for pool: Dictionary in pools:
		var at: Vector3=pool.at
		for i in ECOLOGY.shore_reed_count+ECOLOGY.shore_scrub_count:
			var angle:=rng.randf()*TAU
			var shore: float=_shore_radius(angle,float(pool.radius),float(pool.phase))
			var outside:=rng.randf_range(.15,ECOLOGY.shore_band_m)
			var pos:=_ground(terrain,at.x+cos(angle)*(shore+outside),at.z+sin(angle)*(shore+outside)*float(pool.aspect))
			var kind:="sedge" if i<ECOLOGY.shore_reed_count else "shrub"
			var size:=rng.randf_range(.65,1.35)
			var height: float=rng.randf_range(.85,1.65)*size*(ECOLOGY.shore_height_scale if kind=="sedge" else 1.0)
			if _plant(terrain,batches,kind,pos,Vector3(size,height,size),rng.randf()*TAU,reserved,.5,ECOLOGY.small_support_rise_m): stats.detail_count+=1
	var patches:=_clusters(terrain,centre,radius-ECOLOGY.fen_patch_radius_m*.4,ECOLOGY.fen_patch_count,ECOLOGY.fen_patch_spacing_m,dry,rng)
	stats.cluster_count=patches.size()+pools.size()
	for patch: Vector3 in patches:
		if stats.landmark_count<ECOLOGY.fen_hollow_count:
			var size:=rng.randf_range(.55,1.05)
			if _plant(terrain,batches,"hollow_trunk",patch,Vector3.ONE*size,rng.randf()*TAU,dry,1.2*size,ECOLOGY.tree_support_rise_m): stats.landmark_count+=1
		if stats.canopy_count<ECOLOGY.fen_tree_count:
			var at:=_around(terrain,patch,ECOLOGY.fen_patch_radius_m*.5,rng)
			var size:=rng.randf_range(.42,.72)
			if _plant(terrain,batches,"fen_tree",at,Vector3(size,size*.86,size),rng.randf()*TAU,dry,.7,ECOLOGY.tree_support_rise_m): stats.canopy_count+=1
		for i in ECOLOGY.fen_growth_per_patch:
			var at:=_around(terrain,patch,ECOLOGY.fen_patch_radius_m,rng)
			if not _inside(at,centre,radius): continue
			var kind:="sedge" if i%5<3 else "shrub" if i%5==3 else "moss"
			var size:=rng.randf_range(.6,1.5)
			var shape:=Vector3(size,size*(ECOLOGY.fen_sedge_height_scale if kind=="sedge" else 1.0),size)
			if _plant(terrain,batches,kind,at,shape,rng.randf()*TAU,dry,.45*size,ECOLOGY.small_support_rise_m): stats.detail_count+=1

static func _uplands(terrain: Terrain, centre: Vector3, radius: float, reserved: Dictionary,
		rng: RandomNumberGenerator, batches: Dictionary, stats: Dictionary) -> void:
	var shelves:=_clusters(terrain,centre,radius-ECOLOGY.outcrop_cluster_radius_m*.5,ECOLOGY.outcrop_cluster_count,ECOLOGY.outcrop_cluster_spacing_m,reserved,rng)
	stats.cluster_count=shelves.size()
	for shelf: Vector3 in shelves:
		var bearing:=rng.randf()*TAU
		if stats.landmark_count<ECOLOGY.rib_count:
			var size:=rng.randf_range(.5,.85)
			if _plant(terrain,batches,"stone_rib",shelf,Vector3(size,size*.68,size),bearing,reserved,1.2*size,ECOLOGY.tree_support_rise_m): stats.landmark_count+=1
		for i in ECOLOGY.outcrops_per_cluster:
			var at:=_around(terrain,shelf,ECOLOGY.outcrop_cluster_radius_m*.5,rng)
			var size:=rng.randf_range(ECOLOGY.outcrop_scale_range.x,ECOLOGY.outcrop_scale_range.y)
			if _plant(terrain,batches,"low_outcrop",at,Vector3(size,size*rng.randf_range(.65,1.0),size),bearing+rng.randf_range(-.3,.3),reserved,1.9*size,ECOLOGY.tree_support_rise_m): stats.detail_count+=1
		for i in ECOLOGY.scree_per_cluster+ECOLOGY.tussocks_per_cluster:
			# A lee-side crescent relates the finer debris and grass to its shelf.
			var angle:=bearing+rng.randf_range(-PI*.65,PI*.65)
			var distance:=rng.randf_range(1.4,ECOLOGY.outcrop_cluster_radius_m)
			var at:=_ground(terrain,shelf.x+cos(angle)*distance,shelf.z+sin(angle)*distance)
			if not _inside(at,centre,radius): continue
			var kind:="scree" if i<ECOLOGY.scree_per_cluster else "dry_sedge"
			var size:=rng.randf_range(.5,1.25)
			var shape:=Vector3(size,size*(ECOLOGY.dry_sedge_height_scale if kind=="dry_sedge" else 1.0),size)
			if _plant(terrain,batches,kind,at,shape,bearing+rng.randf_range(-.8,.8),reserved,.5*size,ECOLOGY.small_support_rise_m): stats.detail_count+=1

static func _add_batch(batches: Dictionary, id: String, transform: Transform3D) -> void:
	if not batches.has(id): batches[id]=[]
	batches[id].append(transform)

static func _mesh_for(kind: String) -> Mesh:
	if _meshes.has(kind): return _meshes[kind]
	var result: Mesh
	if kind.begins_with("root_arch"):
		var trunk:=AuthoredAssets.mesh_for("strange_"+kind)
		var crown:=AuthoredAssets.mesh_for("strange_root_crown")
		if trunk!=null and crown!=null:
			# Bake one shared grounded tree. Streaming then moves its bole and
			# attached crown together, even when their horizontal anchors differ.
			var merged:=ArrayMesh.new()
			for entry: Dictionary in [{"mesh":trunk,"pose":Transform3D.IDENTITY},{"mesh":crown,"pose":Transform3D(Basis.IDENTITY,ECOLOGY.elder_crown_anchor)}]:
				for surface_index in entry.mesh.get_surface_count():
					var surface:=SurfaceTool.new()
					surface.begin(Mesh.PRIMITIVE_TRIANGLES)
					surface.append_from(entry.mesh,surface_index,entry.pose)
					surface.commit(merged)
			result=merged
		else: result=trunk
	elif kind in ["wildwood_tree","wildwood_sapling","fen_tree"]: result=AuthoredAssets.mesh_for("strange_wildwood_tree")
	elif kind in ["deadfall","shrub"]: result=AuthoredAssets.mesh_for(kind)
	else: result=AuthoredAssets.mesh_for("strange_"+("sedge" if kind=="dry_sedge" else kind))
	if result==null:
		var fallback:={"wildwood_tree":"broadleaf_tree","wildwood_sapling":"broadleaf_tree","fen_tree":"broadleaf_tree","fern":"fern_bed","moss":"fern_bed","sedge":"shrub","dry_sedge":"shrub","low_outcrop":"boulder","scree":"boulder"}
		result=AuthoredAssets.mesh_for(fallback.get(kind,"strange_root_arch"))
	_meshes[kind]=result
	return result

static func _batch(parent: Node3D, terrain: Terrain, kind: String, transforms: Array) -> void:
	var mesh:=_mesh_for(kind)
	if mesh==null or transforms.is_empty(): return
	var tiles: Dictionary={}
	for transform: Transform3D in transforms:
		var key:=Vector2i(floori(transform.origin.x/ECOLOGY.batch_width_m),floori(transform.origin.z/ECOLOGY.batch_width_m))
		if not tiles.has(key): tiles[key]=[]
		tiles[key].append(transform)
	for tile: Vector2i in tiles:
		var poses: Array=tiles[tile]
		var origin: Vector3=poses[0].origin
		var multi:=MultiMesh.new()
		multi.transform_format=MultiMesh.TRANSFORM_3D
		multi.mesh=mesh
		multi.instance_count=poses.size()
		var heights: Array=[]
		var displayed: Array=[]
		for i in poses.size():
			var local: Transform3D=poses[i]
			local.origin-=origin
			multi.set_instance_transform(i,local)
			displayed.append(local)
			heights.append(_ground(terrain,poses[i].origin.x,poses[i].origin.z).y)
		var instance:=MultiMeshInstance3D.new()
		instance.name="%s_%d_%d"%[kind,tile.x,tile.y]
		instance.multimesh=multi
		instance.position=origin
		var canopy:=kind.begins_with("root_arch") or kind=="wildwood_tree" or kind=="fen_tree"
		var middle:=kind in ["hollow_trunk","stone_rib","low_outcrop","wildwood_sapling"]
		instance.visibility_range_end=ECOLOGY.canopy_distance_m if canopy else ECOLOGY.middle_distance_m if middle else ECOLOGY.understory_distance_m
		instance.visibility_range_end_margin=12
		if not canopy and not middle: instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.material_override=_material(kind)
		instance.set_meta("mesh_kind",kind)
		instance.set_meta("world_transforms",poses)
		instance.set_meta("anchor_bounds",Rect2(Vector2(tile)*ECOLOGY.batch_width_m,Vector2.ONE*ECOLOGY.batch_width_m))
		instance.set_meta("ground_heights",heights)
		# The dummy headless renderer does not retain MultiMesh buffers; this
		# records the exact submitted poses for the placement/save regression.
		instance.set_meta("display_transforms",displayed)
		instance.set_meta("hidden_by_building",[])
		parent.add_child(instance)

static func _material(kind: String) -> Material:
	var leafy:=kind in ["wildwood_tree","wildwood_sapling","fen_tree","fern","sedge","dry_sedge","shrub"]
	var key:="dry" if kind=="dry_sedge" else "fen" if kind=="fen_tree" else "leaves" if leafy else "solid"
	if not _materials.has(key):
		var material:=StrangeResourceArt.material(0,LOOK.paper_sway_m if leafy else 0)
		if key=="dry": material.set_shader_parameter("tint",Color("b2a685"))
		if key=="fen": material.set_shader_parameter("tint",Color("a7b5a1"))
		_materials[key]=material
	return _materials[key]

static func _shore_radius(angle: float, radius: float, phase: float) -> float:
	return radius*(.87+.08*sin(angle*3+phase)+.035*sin(angle*7-phase))

static func _pool_supported(terrain: Terrain, at: Vector3, radius: float, aspect: float) -> bool:
	for ring in [0.33,0.66,1.0]:
		for i in 16:
			var angle:=float(i)*TAU/16
			var sample:=_ground(terrain,at.x+cos(angle)*radius*ring,at.z+sin(angle)*radius*ring*aspect)
			if not sample.is_finite() or absf(sample.y-at.y)>LOOK.pool_max_rise_m: return false
	return true

static func _pools(parent: Node3D, terrain: Terrain, centre: Vector3, radius: float,
		_reserved: Dictionary, dry: Dictionary, rng: RandomNumberGenerator) -> Array:
	var result: Array=[]
	for i in ECOLOGY.pool_candidates:
		var ring: float=(radius-ECOLOGY.pool_radius_range_m.y)*ECOLOGY.core_fraction*sqrt(float(i+1)/ECOLOGY.pool_candidates)
		var at:=_ground(terrain,centre.x+cos(i*2.399)*ring,centre.z+sin(i*2.399)*ring)
		var pool_radius:=rng.randf_range(ECOLOGY.pool_radius_range_m.x,ECOLOGY.pool_radius_range_m.y)
		var aspect:=rng.randf_range(ECOLOGY.pool_aspect_range.x,ECOLOGY.pool_aspect_range.y)
		if not at.is_finite() or not _clear(dry,at,pool_radius): continue
		if not _pool_supported(terrain,at,pool_radius,aspect): continue
		var phase:=rng.randf()*TAU
		var surface:=SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		for edge in 40:
			var a:=float(edge)*TAU/40
			var b:=float(edge+1)*TAU/40
			var ra:=_shore_radius(a,pool_radius,phase)
			var rb:=_shore_radius(b,pool_radius,phase)
			for point: Vector3 in [Vector3.ZERO,Vector3(cos(b)*rb,0,sin(b)*rb),Vector3(cos(a)*ra,0,sin(a)*ra)]:
				surface.set_normal(Vector3.UP)
				surface.add_vertex(point)
		var water:=ShaderMaterial.new()
		water.shader=preload("res://art/strange_water.gdshader")
		water.set_shader_parameter("water_colour",LOOK.water_colour)
		water.set_shader_parameter("pool_radius",pool_radius)
		var instance:=MeshInstance3D.new()
		instance.name="ShallowPool_%02d"%result.size()
		instance.mesh=surface.commit()
		instance.material_override=water
		instance.position=at+Vector3.UP*ECOLOGY.pool_surface_lift_m
		instance.scale.z=aspect
		instance.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		instance.visibility_range_end=ECOLOGY.middle_distance_m
		instance.set_meta("ground_y",at.y)
		instance.set_meta("pool_support",true)
		instance.set_meta("pool_radius",pool_radius)
		instance.set_meta("pool_aspect",aspect)
		parent.add_child(instance)
		_reserve(dry,at,pool_radius+ECOLOGY.pool_spacing_m)
		result.append({"at":at,"radius":pool_radius,"aspect":aspect,"phase":phase})
		if result.size()>=ECOLOGY.pool_count: break
	parent.set_meta("pool_count",result.size())
	return result


static func _site_resource_ids(terrain: Terrain) -> Dictionary:
	var result: Dictionary={}
	for definition: Dictionary in terrain.map.get("nodes",[]):
		var site_id:=String(definition.get("site_id",""))
		var resource_id:=String(definition.get("resource_id",""))
		if site_id.is_empty() or resource_id.is_empty(): continue
		if not result.has(site_id): result[site_id]=[]
		result[site_id].append(resource_id)
	return result

static func _site(parent: Node3D, terrain: Terrain, data: Dictionary, resource_ids: Array) -> void:
	var group:=Node3D.new()
	group.name=String(data.id)
	group.set_meta("site_id",String(data.id))
	group.set_meta("resource_type",String(data.get("resource_type","")))
	group.set_meta("resource_ids",resource_ids.duplicate())
	parent.add_child(group)
	var at:=_anchor(terrain,data)
	if not at.is_finite(): return
	var kind:=String(data.get("resource_type",""))
	var rng:=RandomNumberGenerator.new()
	rng.seed=hash(String(data.id))
	var housing: MeshInstance3D
	match kind:
		"lanternheart":
			housing=StrangeResourceArt.part(group,"lantern_shell","EmptyHousing",at)
			# The open side of the hollow faces the last ordinary approach.
			var path: PackedVector3Array=data.get("approach",PackedVector3Array())
			if path.size()>2:
				var toward:=path[maxi(0,path.size()-4)]-at
				housing.rotation.y=atan2(toward.x,toward.z)+0.45
		"thrumroot": housing=StrangeResourceArt.part(group,"thrumroot_shell","EmptyHousing",at)
		"stormglass":
			housing=StrangeResourceArt.part(group,"lightning_scar","EmptyHousing",at-Vector3.UP*.08)
			housing.scale=Vector3(.65,.045,.65)
		"pullstone":
			housing=StrangeResourceArt.part(group,"stone_rib","Overhang",at+Vector3(0,0,.85))
			housing.scale=Vector3(.75,.38,.65)
		"ventlung": housing=StrangeResourceArt.part(group,"vent_case","EmptyHousing",at)
	if housing!=null:
		housing.set_meta("persists_after_harvest",true)
		housing.set_meta("ground_y",_ground(terrain,housing.position.x,housing.position.z).y)
	var clue_index:=0
	for point: Vector3 in data.get("clue_points",[]):
		var clue_at:=_ground(terrain,point.x,point.z)
		if not clue_at.is_finite(): continue
		var clue_kind: String={"lanternheart":"empty_husk","thrumroot":"thrumroot_shell","stormglass":"lightning_scar","pullstone":"scree","ventlung":"vent_case"}.get(kind,"")
		if String(clue_kind).is_empty(): continue
		# Empty host meshes share the inert material: no intact core, stock glow,
		# movement, collision or interaction. Keep direct mesh children so the
		# established support/building refresh restores the same grounded poses.
		var clue:=StrangeResourceArt.part(group,clue_kind,"Clue_%02d"%clue_index,clue_at,_material("solid"))
		if clue.mesh==null:
			clue.free()
			continue
		clue.rotation.y=rng.randf_range(-PI,PI)
		var size:=clue.mesh.get_aabb().size
		clue.scale=DISCOVERY.clue_size(kind)/size
		clue.set_meta("decorative_clue",true)
		clue.set_meta("clue_mesh_kind",String(clue_kind))
		clue.set_meta("ground_y",clue_at.y)
		clue_index+=1
	group.set_meta("clue_count",clue_index)
	group.set_meta("intact_anchor",at)
	preload("res://art/strange_sound.gd").attach(group,at+Vector3.UP*.7,kind,terrain,resource_ids)
