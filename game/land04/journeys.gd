extends RefCounted
## Presentation consumes native force/host decisions. It creates no geography,
## stock, collision shell or persistent owner. Thin roots/scales conform to the
## actual editable triangles; native banks own the substantial solid form.
const KIT = preload("res://land04/kit.gd")
var terrain: Terrain
var anchors: Dictionary = {}
var stats: Dictionary = {}
var settings: Dictionary = KIT.settings
func _init(t: Terrain) -> void:
	terrain = t
	KIT.prepare_resources()
	for journey: Dictionary in t.map.get("force_journeys",[]):
		var secondary := bool(journey.get("secondary",false))
		var channel := String(journey.channel)
		var bank_role := "white-brace" if channel=="white" else "blue-lamination" if channel=="blue" else "green-steppe-colony" if secondary else "green-root-fan"
		var plant_role := bank_role
		if channel=="blue": plant_role = "blue-sheaths" if String(journey.biome)=="fen" else "blue-bracts-dry"
		var direction: Vector3 = journey.direction
		var yaw := atan2(direction.x,direction.z)
		for family: String in ["form_anchors","growth_anchors"]:
			var index := 0
			for at: Vector3 in journey.get(family,[]):
				var key := Vector2i(floori(at.x/16)*16,floori(at.z/16)*16)
				if not anchors.has(key): anchors[key] = []
				var role := bank_role if family=="form_anchors" else plant_role
				var scale := lerpf(.87,float(settings.maximum_scale),_roll(at,index))
				anchors[key].append({"at":at,"role":role,"yaw":yaw+(_roll(at,index+71)-.5)*.4,"scale":scale,"journey":journey,"family":family})
				index += 1
		if channel=="green": _connect(journey,yaw)

func _store(record: Dictionary) -> void:
	var at: Vector3=record.at
	var key:=Vector2i(floori(at.x/16)*16,floori(at.z/16)*16)
	if not anchors.has(key):anchors[key]=[]
	anchors[key].append(record)

func _connect(journey: Dictionary, yaw: float) -> void:
	# Read the published approach, never move an owner or invent another source.
	# Wide, low buttressed roots follow its margins and feed living fan junctions.
	var route: PackedVector3Array=journey.source_route
	if route.size()<2:return
	for sign_value in [-1.0,1.0]:
		var previous:=Vector3.INF
		var travelled:=0.0
		for i in route.size():
			var point: Vector3=route[i]
			var tangent: Vector3=(route[mini(i+2,route.size()-1)]-route[maxi(0,i-2)])*Vector3(1,0,1)
			if tangent.length()<.01:continue
			tangent=tangent.normalized()
			var side:=Vector3(-tangent.z,0,tangent.x)
			var at: Vector3=point+side*float(settings.network_offset_m)*sign_value
			at.y=float(terrain.height_at(floori(at.x),floori(at.z)))
			if previous.is_finite():
				var delta: Vector3=(at-previous)*Vector3(1,0,1)
				if delta.length()<4.0:
					var count:=maxi(1,ceili(delta.length()/float(settings.network_segment_m)))
					for part in count:
						var start: Vector3=previous.lerp(at,float(part)/count)
						var end: Vector3=previous.lerp(at,float(part+1)/count)
						var centre: Vector3=(start+end)*.5
						_store({"at":centre,"role":"root-link","yaw":atan2(delta.x,delta.z),"scale":1.0,"stretch":Vector3(1,1,delta.length()/count),"journey":journey,"family":"network"})
					travelled+=delta.length()
			if travelled>=float(settings.network_fan_spacing_m) or not previous.is_finite():
				var role:="green-steppe-colony" if bool(journey.secondary) else "green-root-fan"
				_store({"at":at,"role":role,"yaw":yaw+sign_value*.4,"scale":.9,"journey":journey,"family":"junction"})
				travelled=0
			previous=at
	if not bool(journey.secondary):
		# The workplace is the root junction, not an isolated object in a bare
		# circle. Low bark skins meet its outer roots and branch into the banks.
		var source: Vector3=journey.position
		var direction: Vector3=journey.direction
		var side:=Vector3(-direction.z,0,direction.x)
		for sign_value in [-1.0,1.0]:
			var fork: Vector3=source+side*sign_value*3.4
			_link(source+side*sign_value*.85,fork,journey)
			_link(fork,source+side*sign_value*8.0+direction*4.0,journey)
			_link(fork,source+side*sign_value*6.5-direction*5.0,journey)

func _link(start: Vector3,end: Vector3,journey: Dictionary) -> void:
	var delta: Vector3=(end-start)*Vector3(1,0,1)
	var count:=maxi(1,ceili(delta.length()/float(settings.network_segment_m)))
	for i in count:
		var a:=start.lerp(end,float(i)/count)
		var b:=start.lerp(end,float(i+1)/count)
		_store({"at":(a+b)*.5,"role":"root-link","yaw":atan2(delta.x,delta.z),"scale":1.0,"stretch":Vector3(1.4,1,delta.length()/count),"journey":journey,"family":"network"})

func _roll(at: Vector3,salt: int) -> float:
	return float(hash("%s/%s/%s/%s" % [terrain._seed,at.x,at.z,salt]) & 0xffff)/65535.0

func _reserved(at: Vector3, journey: Dictionary, radius: float, network := false) -> bool:
	if not bool(journey.get("secondary",false)):
		var source: Vector3 = journey.position
		if Vector2(at.x-source.x,at.z-source.z).length()<(.65 if network else float(settings.source_clearance_m))+radius*.55: return true
	for route: String in ([] if network else ["source_route","host_route"]):
		for point: Vector3 in journey.get(route,[]):
			if Vector2(at.x-point.x,at.z-point.z).length()<float(settings.route_clearance_m)+radius*.35: return true
	for home: Dictionary in terrain.map.get("home_sites",[]):
		if Vector2(at.x-float(home.x)-.5,at.z-float(home.z)-.5).length()<float(home.radius_m)+radius: return true
	return false

func build(chunk: Node3D,data: Dictionary) -> void:
	var key := Vector2i(int(data.x),int(data.z))
	if not anchors.has(key) or not chunk.has_meta("surface_sampler"): return
	var sampler: SurfaceSampler = chunk.get_meta("surface_sampler")
	for record: Dictionary in anchors[key]:
		var result := _add(chunk,sampler,record)
		var id := String(record.journey.id)
		if not stats.has(id): stats[id] = {}
		stats[id][result] = int(stats[id].get(result,0))+1

func _add(chunk: Node3D,sampler: SurfaceSampler,record: Dictionary) -> String:
	var at: Vector3 = record.at
	var original: ArrayMesh = KIT.meshes[String(record.role)]
	var basis := Basis(Vector3.UP,float(record.yaw)).scaled(record.get("stretch",Vector3.ONE))
	var projected := Transform3D(basis,Vector3.ZERO)*original.get_aabb()
	var half := maxf(maxf(absf(projected.position.x),absf(projected.end.x)),maxf(absf(projected.position.z),absf(projected.end.z)))
	var edge := minf(minf(fposmod(at.x,16),16-fposmod(at.x,16)),minf(fposmod(at.z,16),16-fposmod(at.z,16)))-.04
	var scale := minf(float(record.scale),edge/maxf(half,.01))
	if scale<(.15 if record.family=="network" else float(settings.minimum_scale)): return "chunk_edge"
	var radius := half*scale
	if _reserved(at,record.journey,radius,record.family=="network"): return "reserved"
	basis = basis.scaled(Vector3.ONE*scale)
	# Per-quarter-metre sample reuse keeps vertex-rich foliage from asking the
	# same native triangle thousands of times during a normal chunk arrival.
	var heights: Dictionary = {}
	var cells: Dictionary = {}
	var grounded := sampler.height_at(at.x,at.z,float(terrain.height_at(floori(at.x),floori(at.z))),1.8)
	if not is_finite(grounded): return "root_support"
	var output := ArrayMesh.new()
	for surface in original.get_surface_count():
		var arrays: Array = original.surface_get_arrays(surface).duplicate(true)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var regions := PackedInt32Array()
		var secondary := bool(record.journey.get("secondary",false))
		for i in vertices.size():
			var vertex: Vector3 = basis*vertices[i]
			var x := at.x+vertex.x
			var z := at.z+vertex.z
			if secondary:
				var delta := Vector3(x,0,z)-Vector3(record.journey.position.x,0,record.journey.position.z)
				var u := delta.dot(record.journey.direction)
				regions.append(0 if u < -5.3 else 1 if u > -.7 and u < 11.2 else 2 if u > 14.8 else -1)
			var cell := Vector2i(floori(x),floori(z))
			if not cells.has(cell):
				var height := terrain.height_at(cell.x,cell.y)
				cells[cell] = height if terrain.block_at(cell.x,height-1,cell.y)!=0 and LakeWater.column(terrain.map,x,z).is_empty() else -1
			var native_y: int = cells[cell]
			if native_y<0: return "water_or_dig"
			var sample_key := Vector2i(roundi(x*8),roundi(z*8))
			if not heights.has(sample_key): heights[sample_key] = sampler.height_at(x,z,float(native_y),1.8)
			var y: float = heights[sample_key]
			if not is_finite(y): return "surface_support"
			if absf(y-grounded)>float(settings.maximum_bank_rise_m): return "steep_span"
			vertices[i] = Vector3(vertex.x,y-grounded+vertex.y-float(settings.root_embed_m),vertex.z)
			if normals.size()==vertices.size(): normals[i] = basis.orthonormalized()*normals[i]
		arrays[Mesh.ARRAY_VERTEX] = vertices
		arrays[Mesh.ARRAY_NORMAL] = normals
		if secondary:
			# The low Steppe host has two real dry interruptions. Stop every
			# triangle (and its pulse) at those breaks, including broad root fans.
			var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
			if indices.is_empty():
				for i in vertices.size(): indices.append(i)
			var retained := PackedInt32Array()
			for i in range(0,indices.size(),3):
				var a := indices[i]
				var b := indices[i+1]
				var c := indices[i+2]
				if regions[a]>=0 and regions[a]==regions[b] and regions[a]==regions[c]: retained.append_array(PackedInt32Array([a,b,c]))
			if retained.is_empty(): continue
			arrays[Mesh.ARRAY_INDEX] = retained
		output.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
		output.surface_set_material(output.get_surface_count()-1,original.surface_get_material(surface))
	if output.get_surface_count()==0: return "dry_break"
	var world_pose := Transform3D(Basis.IDENTITY,Vector3(at.x,grounded,at.z))
	var bounds := output.get_aabb().grow(.05)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = output
	mm.instance_count = 1
	mm.set_instance_transform(0,Transform3D.IDENTITY)
	var part := MultiMeshInstance3D.new()
	part.name = "LAND04_"+String(record.role)
	part.position = world_pose.origin
	part.multimesh = mm
	part.visibility_range_end = float(settings.cover_distance_m)
	part.visibility_range_end_margin = 12
	part.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	part.set_meta("terrain_cover",true)
	part.set_meta("rf01_cover",true)
	part.set_meta("land04_cover",true)
	part.set_meta("journey_id",String(record.journey.id))
	part.set_meta("role",String(record.role))
	part.set_meta("world_transforms",[world_pose])
	part.set_meta("display_transforms",[Transform3D.IDENTITY])
	part.set_meta("clearance_bounds",bounds)
	part.set_meta("cover_bounds",world_pose*bounds)
	part.set_meta("hidden_by_building",[])
	part.custom_aabb = bounds
	chunk.add_child(part)
	return "placed_"+String(record.role)
