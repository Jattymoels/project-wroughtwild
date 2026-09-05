class_name HabitatSites
extends RefCounted
## Bounded authored compositions. Resource placement remains generator-owned;
## these accents never create harvestables, collision, progression or save data.
const LOOK = preload("res://art/habitat_sites_look.tres")

static func build(root: Node3D, terrain: Terrain) -> Node3D:
	var previous := root.get_node_or_null("HabitatSites")
	if previous != null:
		root.remove_child(previous)
		previous.queue_free()
	var dressing := Node3D.new()
	dressing.name = "HabitatSites"
	root.add_child(dressing)
	for site: Dictionary in terrain.map.get("habitats",[]):
		_build_site(dressing,terrain,site)
	return dressing

## Terrain calls once after excavation or saved excavation restoration. Rebuild
## only presentation: resource identity, depletion and world geography stay put.
static func refresh(root: Node3D, terrain: Terrain) -> void:
	if root != null and root.has_node("HabitatSites"):
		build(root,terrain)

static func _build_site(root: Node3D, terrain: Terrain, site: Dictionary) -> void:
	var group := Node3D.new()
	group.name = String(site.id)
	root.add_child(group)
	var cell := float(terrain.map.cell_size)
	var anchor := Vector3(float(site.x)*cell,0,float(site.z)*cell)
	anchor.y = terrain.rendered_height(anchor.x,anchor.z,float(site.get("y",0))*cell)
	if not anchor.is_finite(): return
	var radius := float(site.get("radius_m",12.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = int(terrain.map.get("seed",0))+int(site.x)*131+int(site.z)*617
	var batches: Dictionary = {}
	for i in LOOK.accents_per_site:
		var angle := float(i)*TAU/LOOK.accents_per_site+rng.randf_range(-0.12,0.12)
		var ring := radius*rng.randf_range(0.66,1.03)
		var at := anchor+Vector3(cos(angle)*ring,0,sin(angle)*ring)
		at.y = terrain.rendered_height(at.x,at.z,float(terrain.height_at(floori(at.x/cell),floori(at.z/cell))))
		if not at.is_finite() or not _clear(terrain,site,at): continue
		var kind := "fern_bed"
		var scale := Vector3.ONE
		match String(site.id):
			"quarry_escarpment":
				kind = "strata"
				scale = Vector3(1.2,0.55,0.95)
			"fen_hollow":
				kind = "shrub" if i%3==0 else "reeds"
				scale = Vector3.ONE*0.7 if kind=="reeds" else Vector3.ONE
			"oldgrowth_grove":
				kind = "deadfall" if i%4==0 else "fern_bed"
		# Footprint support keeps decorative detail out of excavation and cliffs.
		if not _supported(terrain,at,0.75,0.42): continue
		if not batches.has(kind): batches[kind] = []
		batches[kind].append(Transform3D(Basis(Vector3.UP,angle+PI*0.5).scaled(scale),at-Vector3.UP*0.04))
	for kind in batches:
		_batch(group,String(kind),batches[kind])
	if site.id=="fen_hollow":
		var pools:Array[Vector3]=[]
		# Search the whole hollow, not three points in its busy gathering core.
		# The golden-angle spiral is stable without consuming generator RNG.
		for i in LOOK.puddle_candidates:
			var ring:=radius*.9*sqrt(float(i+1)/float(LOOK.puddle_candidates))
			var at := anchor+Vector3(ring*cos(i*2.399),0,ring*sin(i*2.399))
			at.y = terrain.rendered_height(at.x,at.z,float(terrain.height_at(floori(at.x/cell),floori(at.z/cell))))
			var apart:=true
			for pool in pools:
				if Vector2(pool.x,pool.z).distance_to(Vector2(at.x,at.z))<LOOK.puddle_radius_metres*2.5: apart=false
			if at.is_finite() and apart and _clear(terrain,site,at) and _supported(terrain,at,LOOK.puddle_radius_metres,LOOK.puddle_max_rise):
				_pool(group,at)
				pools.append(at)
				if pools.size()==LOOK.puddles_per_site: break
	_motes(group,anchor,radius)
	group.set_meta("habitat_id",site.id)
	group.set_meta("resource_clearance",LOOK.resource_clearance_metres)

static func _clear(terrain: Terrain, site: Dictionary, at: Vector3) -> bool:
	var cell := float(terrain.map.cell_size)
	for node: Dictionary in terrain.map.get("nodes",[]):
		if Vector2(at.x,at.z).distance_to(Vector2((float(node.x)+.5)*cell,(float(node.z)+.5)*cell))<LOOK.resource_clearance_metres:
			return false
	for point: Vector3 in site.get("approach",[]):
		if Vector2(at.x,at.z).distance_to(Vector2(point.x,point.z))<LOOK.approach_clearance_metres:
			return false
	return true

static func _supported(terrain: Terrain, at: Vector3, radius: float, rise: float) -> bool:
	for offset in [Vector3.LEFT,Vector3.RIGHT,Vector3.FORWARD,Vector3.BACK]:
		var sample: Vector3 = at+offset*radius
		var height := terrain.rendered_height(sample.x,sample.z,at.y)
		if not is_finite(height) or absf(height-at.y)>rise: return false
	return true

static func _batch(parent: Node3D, kind: String, transforms: Array) -> void:
	var mesh: Mesh
	if kind=="strata": mesh = HabitatResourceArt.mesh_for(&"slate_seam",0)
	elif kind=="reeds": mesh = HabitatResourceArt.mesh_for(&"reed_bed",0)
	else: mesh = AuthoredAssets.mesh_for(kind)
	if mesh==null or transforms.is_empty(): return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	var origin: Vector3 = transforms[0].origin
	for i in transforms.size():
		var local: Transform3D = transforms[i]
		local.origin -= origin
		mm.set_instance_transform(i,local)
	var instance := MultiMeshInstance3D.new()
	instance.name = kind
	instance.multimesh = mm
	instance.position = origin
	instance.set_meta("world_transforms",transforms)
	instance.visibility_range_end = LOOK.detail_distance_metres
	instance.visibility_range_end_margin = 8.0
	if kind in ["reeds","fern_bed","shrub"]:
		var material := ShaderMaterial.new()
		material.shader = preload("res://art/habitat_motion.gdshader")
		material.set_shader_parameter("wind_metres",LOOK.wind_metres)
		material.set_shader_parameter("wind_rate",LOOK.wind_rate)
		material.set_shader_parameter("root_height",0.1)
		material.set_shader_parameter("linear_colours",kind!="reeds")
		instance.material_override = material
	elif kind=="strata": instance.material_override = ArtGeometry.material()
	parent.add_child(instance)

static func _pool(parent: Node3D, at: Vector3) -> void:
	var plane := CylinderMesh.new()
	plane.top_radius = LOOK.puddle_radius_metres
	plane.bottom_radius = LOOK.puddle_radius_metres*0.92
	plane.height = 0.018
	plane.radial_segments = 19
	var material := ShaderMaterial.new()
	material.shader = preload("res://art/fen_water.gdshader")
	material.set_shader_parameter("water_colour",LOOK.water_colour)
	var instance := MeshInstance3D.new()
	instance.name = "ShallowPool"
	instance.mesh = plane
	instance.material_override = material
	instance.position = at+Vector3.UP*0.014
	instance.scale.z = 0.64
	instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	instance.visibility_range_end = LOOK.detail_distance_metres
	parent.add_child(instance)

static func _motes(parent: Node3D, at: Vector3, radius: float) -> void:
	var particles := GPUParticles3D.new()
	particles.name = "HabitatMotes"
	particles.amount = LOOK.motes_per_site
	particles.lifetime = LOOK.motes_lifetime_seconds
	particles.visibility_aabb = AABB(Vector3(-radius,-1,-radius),Vector3(radius*2,7,radius*2))
	particles.position = at+Vector3.UP*1.5
	var process := ParticleProcessMaterial.new()
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	process.emission_box_extents = Vector3(radius*0.7,1.5,radius*0.7)
	process.gravity = Vector3(0.02,0.04,0.01)
	process.initial_velocity_min = 0.015
	process.initial_velocity_max = 0.045
	particles.process_material = process
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025,0.025)
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.56,0.56,0.41,0.35)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	quad.material = material
	particles.draw_pass_1 = quad
	parent.add_child(particles)
