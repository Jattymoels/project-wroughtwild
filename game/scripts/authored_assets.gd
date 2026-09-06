class_name AuthoredAssets
extends RefCounted
## Curated visual-only Blender exports. Flatten transforms into a cached mesh;
## never instantiate exported bodies or duplicate gameplay collision.
static var _meshes: Dictionary = {}

static func mesh_for(id: String) -> ArrayMesh:
	if _meshes.has(id):
		return _meshes[id]
	var path := "res://assets/authored/"+id+".glb"
	if not ResourceLoader.exists(path):
		return null
	var scene := load(path) as PackedScene
	if scene == null:
		return null
	var root := scene.instantiate()
	var instances: Array = []
	_collect_instances(root,Transform3D.IDENTITY,instances)
	if instances.size()==1 and instances[0].transform.is_equal_approx(Transform3D.IDENTITY):
		# Nature and most furniture are already one mesh at an applied pivot.
		# Keep the importer-generated LODs instead of rebuilding its surfaces.
		var imported := instances[0].mesh as ArrayMesh
		var visual: MeshInstance3D = instances[0].instance
		# glTF may put materials on the instance rather than the mesh. Preserve
		# those overrides when discarding the imported scene, while retaining LODs.
		var copied := false
		for surface in imported.get_surface_count():
			var active := visual.get_active_material(surface)
			if active != imported.surface_get_material(surface):
				if not copied:
					imported = imported.duplicate() as ArrayMesh
					copied = true
				imported.surface_set_material(surface, active)
		root.free()
		_meshes[id] = imported
		return imported
	var mesh := ArrayMesh.new()
	_collect(root, Transform3D.IDENTITY, mesh)
	root.free()
	_meshes[id] = mesh
	return mesh

static func _collect_instances(node: Node, parent_transform: Transform3D, output: Array) -> void:
	var transform := parent_transform
	if node is Node3D: transform *= (node as Node3D).transform
	if node is MeshInstance3D: output.append({"mesh":(node as MeshInstance3D).mesh,"transform":transform,"instance":node})
	for child in node.get_children(): _collect_instances(child,transform,output)

static func _collect(node: Node, parent_transform: Transform3D, output: ArrayMesh) -> void:
	var transform := parent_transform
	if node is Node3D:
		transform *= (node as Node3D).transform
	if node is MeshInstance3D:
		var instance := node as MeshInstance3D
		for i in instance.mesh.get_surface_count():
			var surface := SurfaceTool.new()
			surface.begin(Mesh.PRIMITIVE_TRIANGLES)
			surface.append_from(instance.mesh, i, transform)
			surface.set_material(instance.get_active_material(i))
			surface.commit(output)
	for child in node.get_children():
		_collect(child, transform, output)

static func scaled_mesh(id: String, scale: Vector3) -> Mesh:
	var source := mesh_for(id)
	if source == null:
		return null
	var key := id+str(scale)
	if _meshes.has(key):
		return _meshes[key]
	var output := ArrayMesh.new()
	for i in source.get_surface_count():
		var surface := SurfaceTool.new()
		surface.begin(Mesh.PRIMITIVE_TRIANGLES)
		surface.append_from(source,i,Transform3D(Basis.from_scale(scale),Vector3.ZERO))
		surface.set_material(source.surface_get_material(i))
		surface.commit(output)
	_meshes[key] = output
	return output
