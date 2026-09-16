extends RefCounted
const KIT=preload("res://land02/kit.gd")
static var settings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://land02/settings.json"))
var terrain: Terrain
var place: Dictionary
var support: RefCounted
var direction:=Vector2.ZERO
var lateral:=Vector2.ZERO
var centre:=Vector2.ZERO
var scar:=Vector3.ZERO
var route_index: Dictionary={}
func _init(t: Terrain) -> void:
 terrain=t
 place=t.map.scarwater[0]
 support=t.reclaimed_cover
 KIT.prepare()
 direction=Vector2(place.direction.x,place.direction.z)
 lateral=Vector2(-direction.y,direction.x)
 centre=Vector2(place.centre.x,place.centre.z)
 scar=place.scar
 for key: String in ["sheltered_route","outlook_route"]:
  for at: Vector3 in place[key]:
   var p:=Vector2(at.x,at.z)
   for z in range(floori((p.y-4)/8),floori((p.y+4)/8)+1):
    for x in range(floori((p.x-4)/8),floori((p.x+4)/8)+1):
     var bucket:=Vector2i(x,z)
     if not route_index.has(bucket):route_index[bucket]=[]
     route_index[bucket].append(p)
func on_route(at: Vector2,radius: float) -> bool:
 for p: Vector2 in route_index.get(Vector2i(floori(at.x/8),floori(at.y/8)),[]):
  if p.distance_to(at)<radius+1.5:return true
 return false
func pose_for(sampler: SurfaceSampler,at: Vector3,basis: Basis,radius: float) -> Variant:
 if floori((at.x-radius)/16)!=floori((at.x+radius)/16) or floori((at.z-radius)/16)!=floori((at.z+radius)/16):return null
 var y:=sampler.height_at(at.x,at.z,at.y)
 if not is_finite(y):return null
 var low:=y
 var high:=y
 for dz in [-radius,0.0,radius]:
  for dx in [-radius,0.0,radius]:
   var x:=floori(at.x+dx)
   var z:=floori(at.z+dz)
   var h:=terrain.height_at(x,z)
   if terrain.block_at(x,h-1,z)==0 or not LakeWater.column(terrain.map,at.x+dx,at.z+dz).is_empty():return null
   var sy:=sampler.height_at(at.x+dx,at.z+dz,h)
   if not is_finite(sy):return null
   low=minf(low,sy);high=maxf(high,sy)
 if high-low>float(settings.support_rise_m):return null
 return Transform3D(basis,Vector3(at.x,low-float(settings.root_embed_m),at.z))
func build(chunk: Node3D,data: Dictionary) -> void:
 if not chunk.has_meta("surface_sampler"):return
 var sampler: SurfaceSampler=chunk.get_meta("surface_sampler")
 var batches: Dictionary={}
 var width:=int(terrain.map.width)
 for z in range(int(data.z),int(data.z)+16):
  for x in range(int(data.x),int(data.x)+16):
   if x%int(settings.grid_m)!=0 or z%int(settings.grid_m)!=0:continue
   var p:=Vector2(x+.5,z+.5)
   var offset:=p-centre
   if offset.length()>float(place.ridge_half_length_m)+110:continue
   var y:=terrain.height_at(x,z)
   if terrain.block_at(x,y-1,z)==0:continue
   var biome:=String(terrain.map.biome_defs[terrain.map.biomes[z*width+x]].id)
   var u:=offset.dot(direction)
   var v:=offset.dot(lateral)
   var roll: float=support._roll(x,z,92025)
   var role:=""
   var scale:=lerpf(float(settings.min_scale),float(settings.max_scale),roll)
   if biome=="gallery_woodland" and roll<float(settings.middle_density):role="underwood-"+str(posmod(x+z,2))
   elif biome=="rocky_hills" and absf(v)<float(place.ridge_half_length_m) and u>float(place.ridge_offset_m)-20 and u<float(place.ridge_offset_m)+25 and roll<.18:role="strata-"+str(posmod(x+z,3))
   elif biome=="gallery_woodland" and roll>.86:role="root-bank-"+str(posmod(x+z,2))
   if role.is_empty():continue
   var at:=Vector3(p.x,y,p.y)
   var radius:=1.1*scale if role.begins_with("underwood") else 2.0*scale
   if not support.clear(at,radius) or on_route(p,radius):continue
   # The cut is native and remains entirely unobscured by lip/rock art.
   if Vector2(at.x-scar.x,at.z-scar.z).length()<float(place.fissure_length_m)*.7:continue
   var angle:=atan2(direction.x,direction.y) if role.begins_with("strata") else roll*TAU
   var pose: Variant=pose_for(sampler,at,Basis(Vector3.UP,angle).scaled(Vector3.ONE*scale),radius)
   if pose==null:continue
   if not batches.has(role):batches[role]=[]
   batches[role].append(pose)
 publish(chunk,batches)
 if terrain.world_profile()!="frontier_v10":pulse(chunk,data,sampler)
func pulse(chunk: Node3D,data: Dictionary,sampler: SurfaceSampler) -> void:
 # Recessed fragments follow the actual floor. Small broken segments, no beam,
 # fake hole or implied extractable stock. Missing native support makes them go.
 var poses: Array=[]
 for i in range(-7,7):
  var a:=Vector2(scar.x,scar.z)+lateral*float(i)*.68+direction*(.38*sin(i*1.73))
  var b:=Vector2(scar.x,scar.z)+lateral*float(i+1)*.68+direction*(.38*sin((i+1)*1.73))
  for branch in range(2 if posmod(i,4)==0 else 1):
   var end:=b if branch==0 else a+direction*(.9 if posmod(i,8)==0 else -.8)+lateral*.5
   var mid: Vector2=(a+end)*.5
   if floori(mid.x/16)*16!=int(data.x) or floori(mid.y/16)*16!=int(data.z):continue
   var h:=terrain.height_at(floori(mid.x),floori(mid.y))
   if h<int(scar.y) or terrain.block_at(floori(mid.x),h-1,floori(mid.y))==0:continue
   var y:=sampler.height_at(mid.x,mid.y,h)
   if not is_finite(y):continue
   var delta: Vector2=end-a
   var basis:=Basis(Vector3.UP,atan2(delta.x,delta.y)).scaled(Vector3(1,1,delta.length()*.93))
   poses.append(Transform3D(basis,Vector3(mid.x,y+.02,mid.y)))
 if poses.is_empty():return
 var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=KIT.pulse_mesh;mm.instance_count=poses.size()
 for i in poses.size():mm.set_instance_transform(i,poses[i])
 var part:=MultiMeshInstance3D.new();part.name="Scarwater_inset_pulse";part.multimesh=mm
 part.set_meta("terrain_cover",true);part.set_meta("rf01_cover",true);part.set_meta("world_transforms",poses);part.set_meta("display_transforms",poses.duplicate());part.set_meta("cover_bounds",AABB(scar-Vector3(8,5,8),Vector3(16,10,16)));part.set_meta("hidden_by_building",[])
 chunk.add_child(part)

static func publish(chunk: Node3D,batches: Dictionary) -> void:
 for role: String in batches:
  var mesh: ArrayMesh=KIT.meshes[role]
  var poses: Array=batches[role]
  var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=poses.size()
  var total:=AABB()
  for i in poses.size():
   mm.set_instance_transform(i,poses[i]);var b: AABB=poses[i]*mesh.get_aabb();total=b if i==0 else total.merge(b)
  var part:=MultiMeshInstance3D.new();part.name="LAND02_"+role;part.multimesh=mm
  part.visibility_range_end=float(settings.cover_distance_m);part.visibility_range_end_margin=12
  part.set_meta("terrain_cover",true);part.set_meta("rf01_cover",true);part.set_meta("land02_cover",true)
  part.set_meta("world_transforms",poses);part.set_meta("display_transforms",poses.duplicate());part.set_meta("cover_bounds",total);part.set_meta("hidden_by_building",[])
  chunk.add_child(part)
