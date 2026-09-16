extends RefCounted
## Selected generated/direct art, retained once during actual world entry.
static var ready:=false
static var meshes: Array[Mesh]=[]
static var contacts: Array[Shape3D]=[]
static var rock: Texture2D
static func imported(role: String) -> ArrayMesh:
 var scene: PackedScene=load("res://land02b/assets/"+role+".glb")
 var root:=scene.instantiate()
 var instances: Array=[]
 AuthoredAssets._collect_instances(root,Transform3D.IDENTITY,instances)
 var result: ArrayMesh
 if instances.size()==1 and (instances[0].transform as Transform3D).is_equal_approx(Transform3D.IDENTITY):
  result=(instances[0].mesh as ArrayMesh).duplicate()
  for i in result.get_surface_count():result.surface_set_material(i,instances[0].instance.get_active_material(i))
 else:
  result=ArrayMesh.new();AuthoredAssets._collect(root,Transform3D.IDENTITY,result)
 root.free()
 return result
static func prepare() -> void:
 if ready:return
 rock=load("res://land02b/textures/fractured-limestone.png")
 var leaves:=ShaderMaterial.new();leaves.shader=preload("res://land02b/foliage.gdshader")
 for i in 2:
  var mesh:=imported("gallery-column" if i==0 else "gallery-arch")
  for surface in mesh.get_surface_count():
   var material:=mesh.surface_get_material(surface)
   if material!=null and "Gallery living leaves" in material.resource_name:
    mesh.surface_set_material(surface,leaves)
  meshes.append(mesh)
  contacts.append(imported("gallery-contact-"+str(i)).create_trimesh_shape())
 ready=true
static func tree(seed_value: int) -> Mesh:
 prepare();return meshes[0 if posmod(seed_value,3)!=0 else 1]
static func contact(seed_value: int) -> Shape3D:
 prepare();return contacts[0 if posmod(seed_value,3)!=0 else 1]
static func bind_ground(material: ShaderMaterial,map: Dictionary) -> void:
 prepare()
 var place: Dictionary=map.scarwater[0]
 material.set_shader_parameter("land02b_enabled",true)
 material.set_shader_parameter("land02b_rock_albedo",rock)
 material.set_shader_parameter("land02b_scar",place.scar)
 material.set_shader_parameter("land02b_direction",Vector2(place.direction.x,place.direction.z))
