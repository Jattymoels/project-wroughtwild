extends RefCounted
## One V11 world's supported living Steppe, derived from native host geometry.
const KIT=preload("res://land03/kit.gd")
static var settings: Dictionary=KIT.settings
var terrain: Terrain
var support: RefCounted
var place: Dictionary
var noise:=FastNoiseLite.new()
var mask: ImageTexture
var routes: Dictionary={}
var host_index: Dictionary={}
func _init(t: Terrain) -> void:
 terrain=t;support=t.reclaimed_cover;place=t.map.dry_steppe[0]
 KIT.prepare()
 noise.seed=int(hash(str(t._seed)+"/land03-growth") & 0x7fffffff)
 noise.frequency=1.0/float(settings.patch_metres)
 for route: String in ["ridge_route","low_route"]:
  for point: Vector3 in place.get(route,[]):
   var p:=Vector2(point.x,point.z)
   for z in range(floori((p.y-5)/8),floori((p.y+5)/8)+1):
    for x in range(floori((p.x-5)/8),floori((p.x+5)/8)+1):
     var key:=Vector2i(x,z)
     if not routes.has(key):routes[key]=[]
     routes[key].append(p)
 for host: Vector3 in place.get("mineral_hosts",[]):
  var reach:=float(settings.red_host_reach_m)
  for z in range(floori((host.z-reach)/8),floori((host.z+reach)/8)+1):
   for x in range(floori((host.x-reach)/8),floori((host.x+reach)/8)+1):
    var key:=Vector2i(x,z)
    if not host_index.has(key):host_index[key]=[]
    host_index[key].append(Vector2(host.x,host.z))
 var pixels:=PackedByteArray();pixels.resize(int(t.map.width)*int(t.map.height))
 for i in pixels.size():
  if String(t.map.biome_defs[t.map.biomes[i]].id)=="dry_steppe":pixels[i]=255
 mask=ImageTexture.create_from_image(Image.create_from_data(int(t.map.width),int(t.map.height),false,Image.FORMAT_R8,pixels))
func bind(material: ShaderMaterial) -> void:
 material.set_shader_parameter("land03_enabled",true)
 material.set_shader_parameter("land03_mask",mask)
 material.set_shader_parameter("land03_world_size",Vector2(terrain.map.width,terrain.map.height))
func biome_at(x: int,z: int) -> String:
 if x<0 or z<0 or x>=int(terrain.map.width) or z>=int(terrain.map.height):return ""
 return String(terrain.map.biome_defs[terrain.map.biomes[z*int(terrain.map.width)+x]].id)
func host_weight(p: Vector2) -> float:
 var distance:=INF
 for at: Vector2 in host_index.get(Vector2i(floori(p.x/8),floori(p.y/8)),[]):distance=minf(distance,p.distance_to(at))
 return 1.0-smoothstep(2.0,float(settings.red_host_reach_m),distance)
func reserved(p: Vector2,radius: float) -> bool:
 var source: Vector3=place.red_source
 if p.distance_to(Vector2(source.x,source.z))<5.0+radius:return true
 for point: Vector2 in routes.get(Vector2i(floori(p.x/8),floori(p.y/8)),[]):
  if p.distance_to(point)<float(settings.route_clearance_m)+radius:return true
 return false
func pose_for(sampler: SurfaceSampler,at: Vector3,basis: Basis,radius: float) -> Variant:
 if radius<.30 or floori((at.x-radius)/16)!=floori((at.x+radius)/16) or floori((at.z-radius)/16)!=floori((at.z+radius)/16):return null
 var root:=sampler.height_at(at.x,at.z,at.y)
 if not is_finite(root):return null
 var left:=sampler.height_at(at.x-radius,at.z,at.y)
 var right:=sampler.height_at(at.x+radius,at.z,at.y)
 var back:=sampler.height_at(at.x,at.z-radius,at.y)
 var front:=sampler.height_at(at.x,at.z+radius,at.y)
 if not is_finite(left+right+back+front):return null
 var sx:=(right-left)/(2*radius)
 var sz:=(front-back)/(2*radius)
 for dz in [-radius,0.0,radius]:
  for dx in [-radius,0.0,radius]:
   var x:=floori(at.x+dx);var z:=floori(at.z+dz)
   if biome_at(x,z)!="dry_steppe":return null
   var native_y:=terrain.height_at(x,z)
   if terrain.block_at(x,native_y-1,z)==0 or not LakeWater.column(terrain.map,at.x+dx,at.z+dz).is_empty():return null
   var y:=sampler.height_at(at.x+dx,at.z+dz,native_y)
   if not is_finite(y) or absf(y-root)>float(settings.max_support_rise_m) or absf(y-root-sx*dx-sz*dz)>float(settings.max_plane_error_m):return null
 var plane:=Basis(Vector3(1,sx,0),Vector3.UP,Vector3(0,sz,1))
 return Transform3D(plane*basis,Vector3(at.x,root-float(settings.root_embed_m),at.z))
func add_pose(batches: Dictionary,role: String,at: Vector3,scale: float,yaw: float,sampler: SurfaceSampler) -> void:
 var mesh: ArrayMesh=KIT.meshes[role]
 var edge:=minf(minf(fposmod(at.x,16),16-fposmod(at.x,16)),minf(fposmod(at.z,16),16-fposmod(at.z,16)))-.015
 scale=minf(scale,edge/float(mesh.get_meta("land03_radius")))
 var radius:=float(mesh.get_meta("land03_radius"))*scale
 var low_grass:=role.begins_with("grass")
 # Low blades do not occlude work: reserve their roots at ordinary finite
 # nodes, but still test their entire supported/build-suppressed footprint.
 var clear: bool=support.clear(at,.15 if low_grass else radius)
 if low_grass and not clear:
  for home: Dictionary in terrain.map.get("home_sites",[]):
   if Vector2(at.x-float(home.x)-.5,at.z-float(home.z)-.5).length()<float(home.radius_m):
    clear=true
    break
 if not clear or reserved(Vector2(at.x,at.z),radius):return
 var pose: Variant=pose_for(sampler,at,Basis(Vector3.UP,yaw).scaled(Vector3.ONE*scale),radius)
 if pose==null:return
 if not batches.has(role):batches[role]=[]
 batches[role].append(pose)
func build(chunk: Node3D,data: Dictionary) -> void:
 if not chunk.has_meta("surface_sampler"):return
 var sampler: SurfaceSampler=chunk.get_meta("surface_sampler")
 var batches: Dictionary={}
 var direction: Vector3=place.direction
 var yaw:=atan2(direction.x,direction.z)
 for z in range(int(data.z),int(data.z)+16):
  for x in range(int(data.x),int(data.x)+16):
   if x%int(settings.grid_m)!=0 or z%int(settings.grid_m)!=0 or biome_at(x,z)!="dry_steppe":continue
   var p:=Vector2(x+1.0+(support._roll(x,z,1129)-.5)*float(settings.root_jitter_m),z+1.0+(support._roll(x,z,1151)-.5)*float(settings.root_jitter_m))
   var patch:=smoothstep(-.35,.35,noise.get_noise_2d(p.x,p.y))
   var roll: float=support._roll(x,z,1103)
   if roll>lerpf(float(settings.sparse_coverage),float(settings.grass_coverage),patch):continue
   var red:=host_weight(p)
   var choice: float=support._roll(x,z,1109)
   var role:="grass-flow" if choice<.55 else "grass-islands"
   if choice<float(settings.shrub_share)*(patch+.4):role="sage-fan"
   if red>.20 and choice<float(settings.red_brush_share)*red:role="red-brush"
   var height:=terrain.height_at(x,z)
   var nearby:=maxi(abs(height-terrain.height_at(x+2,z)),abs(height-terrain.height_at(x,z+2)))
   if nearby>0 and choice>.78:role="erosion-join"
   var scale:=lerpf(float(settings.min_scale),float(settings.max_scale),support._roll(x,z,1117))
   var at:=Vector3(p.x,height,p.y)
   add_pose(batches,role,at,scale,yaw+(support._roll(x,z,1123)-.5)*1.3,sampler)
 # Recessed little inclusions are rooted beside the shared native hosts, not
 # independent random landmarks. Real source stock and its workplace are separate.
 for host: Vector3 in place.get("release_pockets",[]):
  if floori(host.x/16)*16!=int(data.x) or floori(host.z/16)*16!=int(data.z):continue
  add_pose(batches,"release-nodule",host,1.0,yaw,sampler)
 publish(chunk,batches)
static func publish(chunk: Node3D,batches: Dictionary) -> void:
 for role: String in batches:
  var poses: Array=batches[role];var mesh: ArrayMesh=KIT.meshes[role]
  var mm:=MultiMesh.new();mm.transform_format=MultiMesh.TRANSFORM_3D;mm.mesh=mesh;mm.instance_count=poses.size()
  var origin:=Vector3.ZERO
  for pose: Transform3D in poses:origin+=pose.origin
  origin/=poses.size()
  var displayed: Array=[];var total:=AABB()
  for i in poses.size():
   var local: Transform3D=poses[i];var bounds: AABB=local*mesh.get_meta("rf01_clearance")
   total=bounds if i==0 else total.merge(bounds)
   local.origin-=origin;mm.set_instance_transform(i,local);displayed.append(local)
  var part:=MultiMeshInstance3D.new();part.name="LAND03_"+role;part.multimesh=mm;part.position=origin
  part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if role.begins_with("grass") else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
  part.visibility_range_end=float(settings.cover_distance_m);part.visibility_range_end_margin=12.0
  part.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
  part.set_meta("terrain_cover",true);part.set_meta("rf01_cover",true);part.set_meta("land03_cover",true)
  part.set_meta("world_transforms",poses);part.set_meta("display_transforms",displayed)
  part.set_meta("cover_bounds",total);part.set_meta("clearance_bounds",mesh.get_meta("rf01_clearance"));part.set_meta("hidden_by_building",[])
  part.custom_aabb=AABB(total.position-origin,total.size);chunk.add_child(part)
