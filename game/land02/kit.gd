extends RefCounted
## Shared original kit; retained at real New World/Continue entry, no stock.
static var meshes: Dictionary={}
static var ready:=false
static var pulse_mesh: BoxMesh
static func prepare() -> void:
 if ready:return
 for role: String in ["gallery-column","gallery-fork","strata-0","strata-1","strata-2","root-bank-0","root-bank-1","underwood-0","underwood-1"]:
  var scene: PackedScene=load("res://land02/assets/"+role+".glb")
  var root: Node3D=scene.instantiate()
  var mesh:=ArrayMesh.new()
  AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh)
  root.free()
  var material:=ShaderMaterial.new()
  material.shader=preload("res://land02/woodland.gdshader")
  material.set_shader_parameter("foliage",role.begins_with("gallery") or role.begins_with("underwood"))
  for i in mesh.get_surface_count():mesh.surface_set_material(i,material)
  mesh.set_meta("rf01_clearance",mesh.get_aabb())
  meshes[role]=mesh
 pulse_mesh=BoxMesh.new();pulse_mesh.size=Vector3(.07,.028,1)
 var pulse_material:=ShaderMaterial.new();pulse_material.shader=preload("res://land02/pulse.gdshader")
 pulse_mesh.material=pulse_material
 ready=true
static func tree(seed_value: int) -> Mesh:
 prepare()
 return meshes["gallery-column" if posmod(seed_value,3)!=0 else "gallery-fork"]

static func bind_ground(material: ShaderMaterial,map: Dictionary) -> void:
 if map.get("scarwater",[]).is_empty():return
 var place: Dictionary=map.scarwater[0]
 material.set_shader_parameter("land02_enabled",true)
 material.set_shader_parameter("land02_centre",Vector2(place.centre.x,place.centre.z))
 material.set_shader_parameter("land02_direction",Vector2(place.direction.x,place.direction.z))
 material.set_shader_parameter("land02_level",float(place.centre.y))
 material.set_shader_parameter("land02_scar",place.scar)
 material.set_shader_parameter("land02_cut_size",Vector2(place.fissure_width_m,place.fissure_length_m))

static func in_cut(map: Dictionary,at: Vector3,pad:=0.0) -> bool:
 if map.get("scarwater",[]).is_empty():return false
 var place: Dictionary=map.scarwater[0]
 var q:=at-(place.scar as Vector3)
 var d: Vector3=place.direction
 return absf(q.dot(d))<float(place.fissure_width_m)*.5+pad and absf(q.dot(Vector3(-d.z,0,d.x)))<float(place.fissure_length_m)*.5+pad
