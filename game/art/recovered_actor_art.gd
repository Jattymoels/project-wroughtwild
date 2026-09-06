class_name RecoveredActorArt
extends RefCounted
## Reviewed Blender skins adapted to the existing rigid six/eight-part sampler.
## Imported AnimationPlayers are never installed: combat remains the only clock.
const LOOK = preload("res://art/augmentation_look.tres")
static var _catalog: Dictionary = {}
static var _meshes: Dictionary = {}

static func definitions() -> Dictionary:
	if _catalog.is_empty():
		_catalog=JSON.parse_string(FileAccess.get_file_as_string("res://assets/authored/mobs/manifest.json")).assets
	return _catalog

static func apply(mesh: MeshInstance3D, actor: Node3D, role: String) -> void:
	if not actor is Enemy: return
	var id: String=String(actor.enemy_id)
	# The Warden/capstone retain the current shared Tyrant body/rig contract.
	if actor is Boss: id="forge_tyrant"
	if not definitions().has(id): return
	var authored := mesh_for(id,role)
	if authored==null: return
	mesh.mesh=authored
	mesh.set_meta("authored_actor_id",id)
	# Family colour is already baked into the reviewed mesh. White avoids a
	# second multiplication; the existing actor still owns freeze/hit/burn looks.
	actor._base_albedo=Color.WHITE
	actor._material.albedo_color=Color.WHITE
	actor._material.roughness=LOOK.actor_roughness

static func mesh_for(id: String, role: String) -> ArrayMesh:
	if _meshes.has(id): return _meshes[id]
	if not definitions().has(id): return null
	var packed := load("res://assets/authored/mobs/"+id+".glb") as PackedScene
	if packed==null: return null
	var root := packed.instantiate()
	var found: Dictionary={}
	_find_mesh(root,Transform3D.IDENTITY,found)
	if found.is_empty():
		root.free()
		return null
	var instance: MeshInstance3D=found.instance
	var transform: Transform3D=found.transform
	var source := instance.mesh as ArrayMesh
	var definition: Dictionary=definitions()[id]
	var scale_array: Array=definition.applied_visual_scale
	var applied := Vector3(scale_array[0],scale_array[1],scale_array[2])
	# The study already multiplied vertices and joints by family size. Rebase
	# to CharacterLook space so normal family scale and later elite scale apply once.
	var inverse_scale := Vector3.ONE/applied
	transform=Transform3D(Basis.from_scale(inverse_scale),Vector3.ZERO)*transform
	var normal_basis := transform.basis.inverse().transposed()
	var bind_mapping := PackedInt32Array()
	for bind in instance.skin.get_bind_count(): bind_mapping.append(_bone_index(instance,bind))
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for surface in source.get_surface_count():
		var arrays := source.surface_get_arrays(surface)
		var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
		var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
		var colours: PackedColorArray=arrays[Mesh.ARRAY_COLOR]
		var bones: PackedInt32Array=arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array=arrays[Mesh.ARRAY_WEIGHTS]
		var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
		for i in range(indices.size() if not indices.is_empty() else vertices.size()):
			var index: int=indices[i] if not indices.is_empty() else i
			var mapped := PackedInt32Array()
			var vertex_weights := PackedFloat32Array()
			for slot in 4:
				mapped.append(bind_mapping[bones[index*4+slot]])
				vertex_weights.append(weights[index*4+slot])
			st.set_bones(mapped)
			st.set_weights(vertex_weights)
			# glTF stores linear vertex colours. Existing actor/status materials
			# expect authored sRGB, so convert once while building this shared mesh.
			st.set_color(colours[index].linear_to_srgb())
			st.set_normal((normal_basis*normals[index]).normalized())
			st.add_vertex(transform*vertices[index])
	AugmentationDetail.append_creature(st,role)
	st.index()
	var output := st.commit()
	output.set_meta("authored_actor_id",id)
	output.set_meta("source_triangles",definition.triangles)
	root.free()
	_meshes[id]=output
	return output

static func _bone_index(instance: MeshInstance3D, bind: int) -> int:
	var name: String=String(instance.skin.get_bind_name(bind))
	if name.is_empty():
		var skeleton := instance.get_node(instance.skeleton) as Skeleton3D
		name=skeleton.get_bone_name(instance.skin.get_bind_bone(bind))
	if name=="body": return 0
	return int(name.trim_prefix("part_"))

static func _find_mesh(node: Node, parent: Transform3D, found: Dictionary) -> void:
	var transform := parent
	if node is Node3D: transform*=node.transform
	if node is MeshInstance3D:
		found["instance"]=node
		found["transform"]=transform
		return
	for child in node.get_children():
		if found.is_empty(): _find_mesh(child,transform,found)
