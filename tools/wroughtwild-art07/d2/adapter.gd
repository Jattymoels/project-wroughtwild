extends RefCounted
## D2 review-only mesh substitution. Production files remain untouched.
const IDS := ["codex_roof_slope","codex_roof_hip","codex_roof_valley","door","roof_wedge","girder","arch"]
static var cache: Dictionary = {}
const D1_IDS := ["cube","wall_panel","pillar","beam","floor_slab","stairs","codex_corner","codex_corner_floor","foundation","dry_wall"]

static func mesh_for(id: String) -> Mesh:
	if cache.has(id): return cache[id]
	var packed := load("res://art07_d2/"+("d1-assets/" if id in D1_IDS else "assets/")+id+".glb") as PackedScene
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
