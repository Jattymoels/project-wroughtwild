extends Resource
## RF-01 cosmetic controls only. Shared mesh cache has no world/seed state.
@export var visual_salt := 91073
@export var patch_metres := 14.0
@export var sparse_coverage := 0.28
@export var dense_coverage := 0.94
@export var grass_width_m := 0.94
@export var grass_height_m := 0.38
@export var fern_width_m := 0.96
@export var fern_height_m := 0.43
@export var meadow_fern_share := 0.025
@export var forest_fern_share := 0.22
@export var edge_grass_share := 0.28
@export var minimum_scale := 0.76
@export var grass_layers := 3
@export var layer_turn_radians := 2.4
@export var layer_scale_step := 0.08
@export var max_support_rise_m := 0.46
@export var max_plane_error_m := 0.075
@export var root_embed_m := 0.025
@export var design_purpose: Dictionary = {}
@export var grass_art: Resource # RF02 source/material only; scatter and envelopes remain RF01.
var meshes: Dictionary = {}

func mesh_for(role: String) -> ArrayMesh:
 var key := str([role,grass_width_m,grass_height_m,fern_width_m,fern_height_m,grass_layers,layer_turn_radians,layer_scale_step])
 if meshes.has(key): return meshes[key]
 var authored_grass := grass_art != null and role.begins_with("grass")
 var source: ArrayMesh = grass_art.source(role) if authored_grass else R7Cover.source(role)
 var box := source.get_aabb()
 var centre := Vector3(box.get_center().x,box.position.y,box.get_center().z)
 var fern := role.begins_with("fern")
 var width := fern_width_m if fern else grass_width_m
 var height := fern_height_m if fern else grass_height_m
 if role == "grass-edge": height *= 0.66
 # Fit the widest actual source vertex into a circular footprint, rather
 # than a square that silently gets wider when it turns.
 var radius := 0.001
 for i in source.get_surface_count():
  for v: Vector3 in source.surface_get_arrays(i)[Mesh.ARRAY_VERTEX]:
   radius = maxf(radius,Vector2(v.x-centre.x,v.z-centre.z).length())
 var scale := Vector3(width*0.5/radius,height/box.size.y,width*0.5/radius)
 var pose := Transform3D(Basis.IDENTITY.scaled(scale),-centre*scale)
 var mesh := ArrayMesh.new()
 for i in source.get_surface_count():
  var surface := SurfaceTool.new()
  surface.begin(Mesh.PRIMITIVE_TRIANGLES)
  # Cross additional existing grass crowns at the same supported root.
  # Each layer is smaller, retaining the already checked radial footprint.
  for layer in (1 if fern or authored_grass else grass_layers):
   var gain := 1.0-float(layer)*layer_scale_step
   var local := Transform3D(Basis(Vector3.UP,float(layer)*layer_turn_radians).scaled(Vector3.ONE*gain),Vector3.ZERO)
   surface.append_from(source,i,local*pose)
  surface.set_material(grass_art.material_for(source.surface_get_material(i)) if authored_grass else R7Cover.material_for(source.surface_get_material(i),0.0))
  surface.commit(mesh)
 mesh.set_meta("rf01_role",role)
 # These bounds describe moving leaves too; StrangeSites uses them rather
 # than only the undeformed mesh. Materials and their clock remain R7's.
 var sway := height*float(R7Cover.settings.wind_bend_per_m)
 mesh.set_meta("rf01_clearance",mesh.get_aabb().grow(sway))
 meshes[key] = mesh
 return mesh