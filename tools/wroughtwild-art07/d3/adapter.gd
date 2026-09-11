extends RefCounted
## Review-only substitution. Native physics, gates and placement remain unchanged.
const IDS := ["half_cube","half_wall","half_pillar","half_beam","half_slab","light_panel","glazed_window"]
const COARSE := ["cube","wall_panel","pillar","beam","floor_slab"]
const TIMBER := ["wood","pine","bog_oak","ash_wood","resinheart"]
static var cache: Dictionary={}

static func mesh_for(id:String,family:String="wood") -> Mesh:
	var key:=id+"_solid" if id.begins_with("half_") and not family in TIMBER else id
	if cache.has(key): return cache[key]
	var packed:=load("res://art07_d3/assets/"+key+".glb") as PackedScene
	assert(packed!=null)
	var root:=packed.instantiate()
	var instances:Array=[]
	_collect(root,Transform3D.IDENTITY,instances)
	assert(instances.size()==1)
	var entry:Dictionary=instances[0]
	var source:Mesh=entry.mesh
	var result:=ArrayMesh.new()
	for i in source.get_surface_count():
		assert(source.surface_get_material(i)!=null,"Imported source has a complete material role")
		var st:=SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
		st.append_from(source,i,entry.pose); st.commit(result)
		result.surface_set_material(i,source.surface_get_material(i))
	root.free(); cache[key]=result
	return result

static func _collect(node:Node,parent:Transform3D,results:Array) -> void:
	var pose:=parent
	if node is Node3D: pose=parent*node.transform
	if node is MeshInstance3D: results.append({"mesh":node.mesh,"pose":pose})
	for child in node.get_children(): _collect(child,pose,results)
