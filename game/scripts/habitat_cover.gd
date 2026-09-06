class_name HabitatCover
extends RefCounted
const LOOK = preload("res://art/habitat_look.tres")

static func prepare(map: Dictionary) -> void:
	var reserved := {}
	for node in map.get("nodes",[]):
		for dx in range(-LOOK.resource_clearance,LOOK.resource_clearance+1):
			for dz in range(-LOOK.resource_clearance,LOOK.resource_clearance+1):
				reserved[Vector2i(int(node.x)+dx,int(node.z)+dz)] = true
	map["habitat_reserved"] = reserved

static func build(chunk: Node3D, data: Dictionary, map: Dictionary, cell: float, retain_poses: bool = false) -> int:
	if not chunk.has_meta("surface_sampler"):
		return 0
	var sampler: SurfaceSampler = chunk.get_meta("surface_sampler")
	var batches := {}
	var reserved: Dictionary = map.get("habitat_reserved",{})
	var width := int(map.width)
	var spawn := Vector2(float(map.spawn_x)*cell,float(map.spawn_z)*cell)
	for kind in data.kinds:
		if kind not in ["grass","forest_floor","marsh","ash"]:
			continue
		for centre: Vector3 in data.kinds[kind]:
			var x := floori(centre.x/cell)
			var z := floori(centre.z/cell)
			if reserved.has(Vector2i(x,z)) or Vector2(centre.x,centre.z).distance_to(spawn)<LOOK.clearing_metres:
				continue
			var y := float(map.heights[z*width+x])
			if absf(centre.y+cell*0.5-y)>0.01:
				continue
			var near_site := false
			for landmark in map.get("landmarks",[]):
				near_site = near_site or Vector2(x,z).distance_to(Vector2(landmark.x,landmark.z))<5.0
			near_site = near_site or Vector2(x,z).distance_to(Vector2(map.gate_x,map.gate_z))<5.0
			if near_site:
				continue
			var patch: float = LOOK.patch(centre.x,centre.z)
			if patch<=0.0:
				continue
			var biome: String = map.biome_defs[map.biomes[z*width+x]].id
			for entry in LOOK.entries(biome):
				if GroundCover._roll(x,z,entry.kind,79)>entry.density*patch:
					continue
				var radius: float = entry.radius
				var supported := true
				var ground := sampler.height_at(centre.x,centre.z,y)
				for offset in [Vector2(-radius,0),Vector2(radius,0),Vector2(0,-radius),Vector2(0,radius)]:
					var edge := sampler.height_at(centre.x+offset.x,centre.z+offset.y,y)
					supported = supported and is_finite(edge) and absf(edge-ground)<=LOOK.max_rise
				if not supported or not is_finite(ground):
					continue
				var variant := 0 if GroundCover._roll(x,z,entry.kind,81)<0.5 else 1
				var key: String = entry.kind+str(variant)
				if not batches.has(key):
					batches[key] = {"kind":entry.kind,"variant":variant,"transforms":[]}
				var yaw := GroundCover._roll(x,z,entry.kind,83)*TAU
				batches[key].transforms.append(Transform3D(Basis(Vector3.UP,yaw),Vector3(centre.x,ground-0.035,centre.z)))
				break
	var count := 0
	for key in batches:
		var entry: Dictionary = batches[key]
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = LOOK.mesh_for(entry.kind,entry.variant)
		mm.instance_count = entry.transforms.size()
		var origin := Vector3.ZERO
		for transform: Transform3D in entry.transforms:
			origin += transform.origin
		origin /= float(mm.instance_count)
		var displayed: Array=[]
		var cover_bounds:=AABB()
		for i in mm.instance_count:
			var local: Transform3D = entry.transforms[i]
			local.origin -= origin
			mm.set_instance_transform(i,local)
			if retain_poses:
				displayed.append(local)
				var bounds: AABB=entry.transforms[i]*mm.mesh.get_aabb()
				cover_bounds=bounds if i==0 else cover_bounds.merge(bounds)
		var batch := MultiMeshInstance3D.new()
		batch.name = "Habitat_"+key
		batch.multimesh = mm
		# Retain placement records for headless validation (dummy renderer does
		# not retain MultiMesh transform buffers) and future clearing queries.
		batch.set_meta("world_transforms",entry.transforms)
		if retain_poses:
			batch.set_meta("terrain_cover",true)
			batch.set_meta("display_transforms",displayed)
			batch.set_meta("cover_bounds",cover_bounds)
			batch.set_meta("hidden_by_building",[])
		batch.material_override = null if AuthoredAssets.mesh_for(entry.kind) != null else LOOK.material()
		batch.position = origin
		batch.visibility_range_end = LOOK.visibility_metres
		batch.visibility_range_end_margin = 10.0
		batch.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		chunk.add_child(batch)
		count += mm.instance_count
	chunk.set_meta("habitat_count",count)
	return count
