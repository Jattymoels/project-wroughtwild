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
 var batches: Dictionary={}
 var normals: Dictionary={}
 var colours: Dictionary={}
 var owners: Dictionary={}
 for z in range(maxi(0,floori((centre.z-radius)/16)*16),mini(height,ceili((centre.z+radius)/16)*16),16):
  for x in range(maxi(0,floori((centre.x-radius)/16)*16),mini(width,ceili((centre.x+radius)/16)*16),16):
   var delta:=Vector3(x+8,centre.y,z+8)-centre
   if delta.dot(d)<-45 or delta.dot(d)>float(place.ridge_offset_m)+float(place.ridge_width_m)+65 or absf(delta.dot(cross))>float(place.ridge_half_length_m)+65:continue
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
