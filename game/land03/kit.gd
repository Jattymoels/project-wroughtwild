extends RefCounted
## LAND-03 meshes prepare once at actual world entry; no persistent owners.
static var ready:=false
static var meshes: Dictionary={}
static var settings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://land03/settings.json"))
static func prepare() -> void:
 if ready:return
 for role: String in ["grass-flow","grass-islands","sage-fan","red-brush","erosion-join","release-nodule"]:
  var scene: PackedScene=load("res://land03/assets/"+role+".glb")
  var root: Node3D=scene.instantiate()
  var mesh:=ArrayMesh.new()
  AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh)
  root.free()
  var plant:=role not in ["erosion-join","release-nodule"]
  var material:=ShaderMaterial.new()
  material.shader=preload("res://land03/host.gdshader")
  material.set_shader_parameter("plant_bend",float(settings.wind_bend_per_m) if plant else 0.0)
  material.set_shader_parameter("leaf_normal_up_mix",.48 if plant else 0.0)
  material.set_shader_parameter("leaf_backlight",.07 if plant else 0.0)
  material.set_shader_parameter("release_host",role=="release-nodule" or role=="red-brush")
  for surface in mesh.get_surface_count():mesh.surface_set_material(surface,material)
  if plant:R7Cover.materials.append(material)
  var radius:=0.0
  for surface in mesh.get_surface_count():
   for p: Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:radius=maxf(radius,Vector2(p.x,p.z).length())
  var sway:=mesh.get_aabb().size.y*float(settings.wind_bend_per_m) if plant else 0.0
  mesh.set_meta("land03_radius",radius+sway)
  mesh.set_meta("rf01_clearance",mesh.get_aabb().grow(sway))
  meshes[role]=mesh
 ready=true
