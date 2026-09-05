extends Node3D
## Independent physics rays validate cover/ribbons against rendered terrain.
var terrain: Terrain
var seam: ResourceNode
var frame := 0
var checks := 0
var failures := 0
var original := PackedVector3Array()
var cover_before: Dictionary = {}
var dug := Vector3i.ZERO

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	terrain = Terrain.new()
	add_child(terrain)
	terrain._sim = sim
	terrain._seed = 1
	terrain.map = sim.world_map(1)
	terrain._blocks = terrain.map.blocks.duplicate()
	terrain.block_rules = sim.block_rules()
	terrain.faceted_surface = true
	terrain.frontier_look = preload("res://art/weathered_look.tres")
	for x in [144,160]:
		for z in [144,160]:
			terrain._build_chunk(sim.world_mesh_chunk(1,16,x,z,PackedInt32Array(),true),1.0)
	terrain.nodes_root = Node3D.new()
	terrain.add_child(terrain.nodes_root)
	# A seam crosses a chunk boundary and a height change, not just flat ground.
	seam = preload("res://scenes/resource_node.tscn").instantiate()
	seam.visual = &"seam"
	seam.material_family = &"stone"
	seam.position = Vector3(160.5,terrain.height_at(160,165),165.5)
	terrain.nodes_root.add_child(seam)
	seam.cracked = true
	seam.wedge_set = true
	seam.drive_progress = 2
	seam.remaining_units = 7
	original = seam.get_node("MeshInstance3D").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	dug = Vector3i(160,terrain.height_at(160,165)-1,165)
	# Cave floors are sampled by nearby height, rather than the topmost surface.
	var stacked := PackedVector3Array([Vector3(0,2,0),Vector3(1,2,0),Vector3(0,2,1),Vector3(0,8,0),Vector3(1,8,0),Vector3(0,8,1)])
	var sampler := SurfaceSampler.new(stacked)
	check(is_equal_approx(sampler.height_at(0.2,0.2,2),2),"cave sample stays on nearby floor")
	check(is_equal_approx(sampler.height_at(0.2,0.2,8),8),"surface sample stays above cave")
	check(not is_finite(sampler.height_at(0.2,0.2,5)),"absent support never jumps to a different storey")

func _ray(at: Vector3) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(at+Vector3.UP*0.2,at-Vector3.UP*0.3)
	query.exclude = [seam.get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func _check_surfaces() -> void:
	var count := 0
	var valid := true
	var centred := true
	for chunk in terrain.chunks.values():
		for child in chunk.get_children():
			if not child is MultiMeshInstance3D or not String(child.name).begins_with("Cover_"):
				continue
			var centre := Vector3.ZERO
			for i in child.multimesh.instance_count:
				var at: Vector3 = child.to_global(child.multimesh.get_instance_transform(i).origin)
				centre += at
				var hit := _ray(at)
				valid = valid and not hit.is_empty() and absf(hit.position.y-at.y-0.015)<0.002
				count += 1
			centre /= float(child.multimesh.instance_count)
			centred = centred and centre.distance_to(child.global_position)<0.002
	check(count>20 and valid,"decorative cover roots lie on collision triangles, including slopes: %d samples" % count)
	check(centred,"cover distance-fade origins stay at the centre of their actual plants")
	print("CODEX_COVER_ROOTS ",count)
	var mesh: MeshInstance3D = seam.get_node("MeshInstance3D")
	valid = mesh.mesh != null
	if valid:
		var vertices: PackedVector3Array = mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			var at: Vector3 = seam.position+vertex
			var hit := _ray(at)
			valid = valid and not hit.is_empty() and absf(at.y-hit.position.y-terrain.frontier_look.seam_surface_lift)<0.002
	check(valid,"seam ribbon vertices sit just above actual collision triangles")

func _physics_process(_delta: float) -> void:
	frame += 1
	if frame==4:
		_check_surfaces()
		terrain.cracked[dug] = true
		check(terrain.break_block(dug.x,dug.y,dug.z)!="","dig removes support under the ribbon")
	if frame==8:
		_check_surfaces()
		var mesh: MeshInstance3D = seam.get_node("MeshInstance3D")
		check(mesh.mesh==null or mesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]!=original,"nearby excavation rebuilds the resource ribbon")
		check(seam.cracked and seam.wedge_set and seam.drive_progress==2 and seam.remaining_units==7,"grounding preserves paid harvest and fire-setting state")
		terrain.apply_broken_blocks([])
	if frame==12:
		_check_surfaces()
		check(seam.get_node("MeshInstance3D").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==original,"restored excavation reproduces exact seam geometry")
		print("CODEX_GROUNDING %d checks, %d failures" % [checks,failures])
		get_tree().quit(0 if failures==0 else 1)
