extends RefCounted
## D1 review-only mesh substitution. Production files remain untouched.
const IDS := ["cube","wall_panel","pillar","beam","floor_slab","stairs","codex_corner","codex_corner_floor","foundation","dry_wall"]
static var cache: Dictionary = {}

static func mesh_for(id: String) -> Mesh:
	if cache.has(id): return cache[id]
	var packed := load("res://art07_d1/assets/"+id+".glb") as PackedScene
	assert(packed!=null)
	var root := packed.instantiate()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_append(root,Transform3D.IDENTITY,st)
	var result := st.commit()
	root.free()
	cache[id]=result
	return result

static func _append(node: Node, parent: Transform3D, st: SurfaceTool) -> void:
	var pose := parent
	if node is Node3D: pose=parent*node.transform
	if node is MeshInstance3D:
		for surface in node.mesh.get_surface_count(): st.append_from(node.mesh,surface,pose)
	for child in node.get_children(): _append(child,pose,st)
