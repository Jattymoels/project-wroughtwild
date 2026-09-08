class_name ResourceCanopies
extends RefCounted
## Distant pictures of existing broadleaf resources, with no bodies or stock.
## The live ledger, including saved depletion, is their sole source of identity.
const LOOK = preload("res://art/material_library.tres")
var _stream: WeakRef
var stream: ResourceStream:
	get: return _stream.get_ref() as ResourceStream
var root: Node3D
var slots: Dictionary = {}
var _material: ShaderMaterial

func setup(owner_stream: ResourceStream) -> void:
	_stream = weakref(owner_stream)
	if not stream.terrain.weathered or stream.terrain.chunk_stream == null: return
	root = Node3D.new()
	root.name = "DistantResourceCanopies"
	stream.terrain.add_child(root)
	_material = ShaderMaterial.new()
	_material.shader = preload("res://art/distant_canopy.gdshader")
	_material.set_shader_parameter("detail_mask",stream.terrain.chunk_stream._mask_texture)
	_material.set_shader_parameter("world_size",Vector2(stream.terrain.map.width,stream.terrain.map.height)*float(stream.terrain.map.cell_size))
	rebuild()

func rebuild() -> void:
	if not is_instance_valid(root): return
	for child in root.get_children(): child.free()
	slots.clear()
	var mesh := AuthoredAssets.mesh_for("broadleaf_tree_far")
	if mesh == null: return
	for bucket: Vector2i in stream.buckets:
		var ids: Array[String] = []
		for id: String in stream.buckets[bucket]:
			if stream.records.has(id) and _eligible(stream.records[id]): ids.append(id)
		if ids.is_empty(): continue
		var batch := MultiMeshInstance3D.new()
		batch.name = "Canopies_%d_%d" % [bucket.x,bucket.y]
		batch.multimesh = MultiMesh.new()
		batch.multimesh.transform_format = MultiMesh.TRANSFORM_3D
		batch.multimesh.use_custom_data = true
		batch.multimesh.mesh = mesh # Retains the importer's actual mesh LODs.
		batch.multimesh.instance_count = ids.size()
		batch.material_override = _material
		batch.visibility_range_end = LOOK.distant_canopy_distance
		batch.visibility_range_end_margin = LOOK.distant_canopy_fade_margin
		batch.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
		batch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		root.add_child(batch)
		var bounds := AABB()
		for i in ids.size():
			slots[ids[i]] = [batch.multimesh,i,Transform3D()]
			update(ids[i])
			var pose := _native_pose(stream.records[ids[i]])
			var box := pose*mesh.get_aabb()
			pose.origin.y = _horizon_height(pose.origin)-.025
			box = box.merge(pose*mesh.get_aabb())
			bounds = box if i==0 else bounds.merge(box)
		# Zero-scale hidden instances must not drag the culling box to world origin.
		batch.custom_aabb = bounds

func _eligible(record: Dictionary) -> bool:
	if String(record.visual) != "tree" or int(record.remaining_units) <= 0: return false
	if int(record.get("era",1)) > stream.terrain.current_era: return false
	var p := Vector3(record.position[0],record.position[1],record.position[2])
	var terrain := stream.terrain
	var cs := float(terrain.map.cell_size)
	var x := floori(p.x/cs); var z := floori(p.z/cs)
	if x < 0 or z < 0 or x >= terrain.map.width or z >= terrain.map.height: return false
	var biome := int(terrain.map.biomes[z*int(terrain.map.width)+x])
	if not String(terrain.map.biome_defs[biome].id) in ["meadow","fen"]: return false
	# The near representation deliberately opens landmark canopies into snags.
	for site: Dictionary in terrain.map.get("landmarks",[]):
		var anchor := terrain.surface_position(int(site.x),int(site.z))
		if Vector2(p.x,p.z).distance_to(Vector2(anchor.x,anchor.z)) < preload("res://art/landmark_look.tres").canopy_clearance_metres: return false
	return true

func update(id: String) -> void:
	# Terrain clears its chunk stream before old ResourceNodes leave the tree.
	# Teardown must not rebuild pictures against that disappearing heightfield.
	if stream.terrain.chunk_stream == null or not is_instance_valid(root): return
	if not slots.has(id): return
	var slot: Array = slots[id]
	var mesh: MultiMesh = slot[0]
	var transform := Transform3D(Basis.IDENTITY.scaled(Vector3.ZERO),Vector3.ZERO)
	if stream.records.has(id) and not stream.active.has(id):
		var record: Dictionary = stream.records[id]
		if int(record.remaining_units) > 0:
			var p := Vector3(record.position[0],record.position[1],record.position[2])
			transform = _native_pose(record)
			# Exact chunks replace the coarse horizon through its existing mask.
			# Store the matching far triangle height; do not invent a new terrain.
			mesh.set_instance_custom_data(int(slot[1]),Color(_horizon_height(p)-p.y,0,0,0))
	mesh.set_instance_transform(int(slot[1]),transform)
	slot[2] = transform

func _native_pose(record: Dictionary) -> Transform3D:
	var p := Vector3(record.position[0],record.position[1],record.position[2])
	var seed := hash(Vector3i((p*4.0).round()))+hash("tree")
	return Transform3D(Basis(Vector3.UP,float(seed%628)/100.0),p-Vector3.UP*.025)

func _horizon_height(p: Vector3) -> float:
	var terrain := stream.terrain
	var cs := float(terrain.map.cell_size)
	var step := int(preload("res://art/strange_stream.tres").terrain_far_step_cells)
	var x := floori(p.x/cs/step)*step; var z := floori(p.z/cs/step)*step
	var x1 := mini(x+step,int(terrain.map.width)); var z1 := mini(z+step,int(terrain.map.height))
	var u := (p.x/cs-x)/float(x1-x); var v := (p.z/cs-z)/float(z1-z)
	var chunks := terrain.chunk_stream
	var a := chunks._height(x,z)*cs; var b := chunks._height(x1,z)*cs
	var c := chunks._height(x,z1)*cs; var d := chunks._height(x1,z1)*cs
	return a+(b-a)*u+(c-a)*v if u+v<=1 else d+(c-d)*(1-u)+(b-d)*(1-v)
