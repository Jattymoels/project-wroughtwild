class_name G1Environment
extends Node
## Existing placed scenery owns transforms, visibility and collision. No scatter.
static var cover_cache: Dictionary={}
static var moving_materials: Array[ShaderMaterial]=[]
static var settings:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://g1/settings.json"))
var adapter: RefCounted
var world: Node3D
var clock:=0.0

static func install(owner_world: Node3D) -> void:
	var previous:=owner_world.get_node_or_null("G1Environment")
	if previous!=null: previous.free()
	var root:=G1Environment.new()
	root.name="G1Environment"
	root.world=owner_world
	owner_world.add_child(root)
	root.adapter=load("res://c6/adapter.gd").new()
	root.adapter.install(owner_world)

static func cover_mesh(entry: Dictionary) -> ArrayMesh:
	var role: String={"tuft":"grass-meadow","fern":"fern-sparse","dead_grass":"grass-edge"}.get(String(entry.kind),"")
	if role.is_empty(): return null
	var key:=str(entry)
	if cover_cache.has(key): return cover_cache[key]
	var root: Node3D=load("res://b2/assets/"+role+"-lod%d.glb"%int(settings.groundcover_lod)).instantiate()
	var source:=ArrayMesh.new()
	AuthoredAssets._collect(root,Transform3D.IDENTITY,source)
	root.free()
	var bounds:=source.get_aabb()
	var scale:=minf(float(entry.width)/maxf(bounds.size.x,bounds.size.z),float(entry.height)/bounds.size.y)
	var pose:=Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*scale),-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*scale)
	var mesh:=ArrayMesh.new()
	for i in source.get_surface_count():
		var tool:=SurfaceTool.new();tool.begin(Mesh.PRIMITIVE_TRIANGLES)
		tool.append_from(source,i,pose);tool.commit(mesh)
		var mat:=ShaderMaterial.new()
		# B4's rooted motion, with its analytic study-ground conformance disabled.
		mat.shader=load("res://b4/surface.gdshader")
		mat.set_shader_parameter("role",3)
		mat.set_shader_parameter("textured",false)
		mat.set_shader_parameter("ground_conform",false)
		mat.set_shader_parameter("plant_bend",float(settings.plant_bend))
		var gain:Array=settings.leaf_colour_gain
		mat.set_shader_parameter("leaf_colour_gain",Vector3(gain[0],gain[1],gain[2]))
		mesh.surface_set_material(i,mat)
		moving_materials.append(mat)
	mesh.set_meta("g1_role",role)
	mesh.set_meta("g1_fit_scale",scale)
	cover_cache[key]=mesh
	return mesh

func _process(delta: float) -> void:
	clock+=delta
	for mat in moving_materials: mat.set_shader_parameter("clock_seconds",clock)
	var camera:=get_viewport().get_camera_3d()
	if adapter!=null and camera!=null: adapter.tick(delta,camera)
