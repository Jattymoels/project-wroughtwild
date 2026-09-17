extends RefCounted
## Exact distant landmark, prepared once at entry. Nearby/edit chunks replace
## it with the same triangles through the stream's existing detail mask.
static func build(terrain: Terrain,detail_mask: Texture2D) -> Texture2D:
 var width:=int(terrain.map.width)
 var height:=int(terrain.map.height)
 var mask:=Image.create(ceili(float(width)/16),ceili(float(height)/16),false,Image.FORMAT_R8)
 mask.fill(Color.BLACK)
 var place: Dictionary=terrain.map.scarwater[0]
 var centre: Vector3=place.centre
 var d: Vector3=place.direction
 var cross:=Vector3(-d.z,0,d.x)
 var radius:=float(place.ridge_half_length_m)+float(place.ridge_offset_m)+65.0
 var minimum:=Vector2(centre.x-radius,centre.z-radius)
 var maximum:=Vector2(centre.x+radius,centre.z+radius)
 var steppe: Dictionary=terrain.map.get("dry_steppe",[{}])[0] if not terrain.map.get("dry_steppe",[]).is_empty() else {}
 if not steppe.is_empty():
  var steppe_radius:=maxf(float(steppe.half_length_m),float(steppe.half_width_m))+24.0
  minimum=minimum.min(Vector2(steppe.centre.x,steppe.centre.z)-Vector2.ONE*steppe_radius)
  maximum=maximum.max(Vector2(steppe.centre.x,steppe.centre.z)+Vector2.ONE*steppe_radius)
 var batches: Dictionary={}
 var normals: Dictionary={}
 var colours: Dictionary={}
 var owners: Dictionary={}
 for z in range(maxi(0,floori(minimum.y/16)*16),mini(height,ceili(maximum.y/16)*16),16):
  for x in range(maxi(0,floori(minimum.x/16)*16),mini(width,ceili(maximum.x/16)*16),16):
   var delta:=Vector3(x+8,centre.y,z+8)-centre
   var selected:=delta.dot(d)>=-45 and delta.dot(d)<=float(place.ridge_offset_m)+float(place.ridge_width_m)+65 and absf(delta.dot(cross))<=float(place.ridge_half_length_m)+65
   if not steppe.is_empty():
    var sd: Vector3=steppe.direction
    var local:=Vector3(x+8,0,z+8)-Vector3(steppe.centre.x,0,steppe.centre.z)
    selected=selected or (absf(local.dot(sd))<=float(steppe.half_length_m)+20 and absf(local.dot(Vector3(-sd.z,0,sd.x)))<=float(steppe.half_width_m)+20)
   if not selected:continue
   var data: Dictionary=terrain._sim.world_mesh_chunk(terrain.seed_value(),16,x,z,PackedInt32Array(),true,terrain._blend_palette())
   mask.set_pixel(x/16,z/16,Color.WHITE)
   for kind: String in data.surfaces:
    if not batches.has(kind):
     batches[kind]=PackedVector3Array();normals[kind]=PackedVector3Array();colours[kind]=PackedColorArray();owners[kind]=PackedVector2Array()
    batches[kind].append_array(data.surfaces[kind])
    normals[kind].append_array(data.soft_normals[kind])
    colours[kind].append_array(data.blend_colours[kind])
    var tags:=PackedVector2Array();tags.resize(data.surfaces[kind].size());tags.fill(Vector2(float(x+8)/width,float(z+8)/height));owners[kind].append_array(tags)
 var parent:=Node3D.new();parent.name="LAND02B_DistantGeology";terrain.add_child(parent)
 for kind: String in batches:
  var arrays:=[];arrays.resize(Mesh.ARRAY_MAX)
  arrays[Mesh.ARRAY_VERTEX]=batches[kind];arrays[Mesh.ARRAY_NORMAL]=normals[kind];arrays[Mesh.ARRAY_COLOR]=colours[kind]
  arrays[Mesh.ARRAY_TEX_UV2]=owners[kind]
  var mesh:=ArrayMesh.new();mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
  var instance:=MeshInstance3D.new();instance.mesh=mesh
  var material: ShaderMaterial=terrain._material_for(kind).duplicate()
  material.set_shader_parameter("land02b_distant",true)
  material.set_shader_parameter("land02b_detail_mask",detail_mask)
  material.set_shader_parameter("land02b_world_size",Vector2(width,height))
  instance.material_override=material;parent.add_child(instance)
 return ImageTexture.create_from_image(mask)
