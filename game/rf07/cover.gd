extends RefCounted
## RF07: derived highland recovery, no native geography or persistent state.
const PROFILES := ["frontier_v6","frontier_v7","frontier_v8","living_frontier_wave1","living_frontier_wave3"]
const SURFACES := ["rock","grass","dirt"]
static var settings: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://rf07/settings.json"))
static var meshes: Dictionary={}
static var rock_material: ShaderMaterial
var terrain: Terrain
var _support: WeakRef
var support: RefCounted:
 get:return _support.get_ref()
var noise:=FastNoiseLite.new()
var regional_batches: Dictionary={}
var regional_stats: Dictionary={}
var rocks: Dictionary={}
var context:=PackedByteArray()
var mask: ImageTexture

static func eligible(profile: String, biome: String, surface: String) -> bool:
 return profile in PROFILES and biome=="rocky_hills" and surface in SURFACES

func _init(owner_terrain: Terrain, support_cover: RefCounted) -> void:
 terrain=owner_terrain
 _support=weakref(support_cover)
 noise.seed=int(hash(str(terrain._seed)+"/"+terrain.world_profile()+"/rf07") & 0x7fffffff)
 noise.frequency=1.0/float(settings.patch_metres)
 prepare()
 # Reuse the established regional anchor recipe once, before chunk construction.
 # Only its ribs/outcrops remain regional; the old scattered sedge/scree yields
 # to supported chunk-local recovery. Native site/resource identity is unchanged.
 var reservations:=StrangeSites._reservations(terrain)
 for region: Dictionary in terrain.map.get("regions",[]):
  if region.id!="glasswind_uplands":continue
  var rng:=RandomNumberGenerator.new()
  rng.seed=hash(String(region.id))+int(terrain.map.get("seed",0))
  var legacy: Dictionary={}
  regional_stats={"landmark_count":0,"detail_count":0,"canopy_count":0,"cluster_count":0}
  StrangeSites._uplands_legacy(terrain,StrangeSites._anchor(terrain,region),float(region.radius_m),reservations,rng,legacy,regional_stats)
  for kind: String in ["stone_rib","low_outcrop"]:
   if not legacy.has(kind):continue
   regional_batches[kind]=legacy[kind]
   for pose: Transform3D in legacy[kind]:
    var b: AABB=pose*StrangeSites._mesh_for(kind).get_aabb()
    index_rock(b)
 # Ordinary finite stone seams also give outside-region growth a real parent.
 for node: Dictionary in terrain.map.get("nodes",[]):
  var x:=int(node.x)
  var z:=int(node.z)
  if biome_at(x,z)!="rocky_hills" or String(node.get("family","")) not in ["stone","fieldstone","split_stone"]:continue
  index_rock(AABB(Vector3(x-.5,terrain.height_at(x,z),z-.5),Vector3(2,1,2)))
 var width:=int(terrain.map.width)
 var height:=int(terrain.map.height)
 context.resize(width*height*4)
 for z in height:
  for x in width:
   var i:=z*width+x
   if biome_at(x,z)!="rocky_hills":continue
   var y:=float(terrain.map.heights[i])
   var land:=land_context(x,z)
   var parent:=rock_edge(Vector2(x+.5,z+.5))
   var near:=1.0-smoothstep(0.0,float(settings.rock_fringe_m),maxf(0.0,parent))
   var pocket:=clampf(patch_at(x+.5,z+.5)*(.67+.33*maxf(land,near)),0,1)
   if parent<-.15:pocket=0.0
   context[i*4]=255
   context[i*4+1]=int(y)
   context[i*4+2]=int(pocket*255)
   context[i*4+3]=int(maxf(near,land*.55)*255)
 mask=ImageTexture.create_from_image(Image.create_from_data(width,height,false,Image.FORMAT_RGBA8,context))

func biome_at(x: int, z: int) -> String:
 if x<0 or z<0 or x>=int(terrain.map.width) or z>=int(terrain.map.height):return ""
 return terrain.map.biome_defs[terrain.map.biomes[z*int(terrain.map.width)+x]].id

func owns(centre: Vector3, biome: String, surface: String) -> bool:
 return eligible(terrain.world_profile(),biome,surface)

func patch_at(x: float,z: float) -> float:
 return smoothstep(float(settings.patch_low),float(settings.patch_high),noise.get_noise_2d(x,z))

func land_context(x: int,z: int) -> float:
 var y:=terrain.height_at(x,z)
 var rise:=0.0
 var fall:=0.0
 var reach:=int(settings.shelter_reach_m)
 for d: Vector2i in [Vector2i(reach,0),Vector2i(-reach,0),Vector2i(0,reach),Vector2i(0,-reach)]:
  var h:=terrain.height_at(x+d.x,z+d.y)
  rise=maxf(rise,h-y)
  fall=maxf(fall,y-h)
 return smoothstep(.0,2.0,rise)*(1.0-smoothstep(2.0,5.0,fall))

func index_rock(bounds: AABB) -> void:
 var rect:=Rect2(Vector2(bounds.position.x,bounds.position.z),Vector2(bounds.size.x,bounds.size.z))
 var pad:=float(settings.rock_fringe_m)+1.0
 var area:=rect.grow(pad)
 for z in range(floori(area.position.y/8),floori(area.end.y/8)+1):
  for x in range(floori(area.position.x/8),floori(area.end.x/8)+1):
   var key:=Vector2i(x,z)
   if not rocks.has(key):rocks[key]=[]
   rocks[key].append(rect)

func rock_edge(at: Vector2) -> float:
 var edge:=INF
 for rect: Rect2 in rocks.get(Vector2i(floori(at.x/8),floori(at.y/8)),[]):
  var offset: Vector2=(at-rect.get_center()).abs()-rect.size*.5
  var distance:=Vector2(maxf(offset.x,0),maxf(offset.y,0)).length()+minf(maxf(offset.x,offset.y),0)
  edge=minf(edge,distance)
 return edge

static func prepare() -> void:
 if not meshes.is_empty():return
 rock_material=ShaderMaterial.new()
 rock_material.shader=preload("res://rf07/stone.gdshader")
 for role: String in ["tussock","heath","cushion","shingle"]:
  var root: Node3D=load("res://rf07/assets/"+role+".glb").instantiate()
  var mesh:=ArrayMesh.new()
  AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh)
  root.free()
  var radius:=0.0
  var sway:=mesh.get_aabb().size.y*float(settings.wind_bend_per_m) if role!="shingle" else 0.0
  for surface in mesh.get_surface_count():
   for p: Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:radius=maxf(radius,Vector2(p.x,p.z).length())
   var material:=ShaderMaterial.new()
   material.shader=preload("res://rf06b/plant.gdshader")
   material.set_shader_parameter("plant_bend",float(settings.wind_bend_per_m) if role!="shingle" else 0.0)
   material.set_shader_parameter("leaf_normal_up_mix",.52 if role!="shingle" else 0.0)
   material.set_shader_parameter("leaf_backlight",.08 if role!="shingle" else 0.0)
   if role!="shingle":R7Cover.materials.append(material)
   mesh.surface_set_material(surface,rock_material if role=="shingle" else material)
  mesh.set_meta("rf07_radius",radius+sway)
  mesh.set_meta("rf01_clearance",mesh.get_aabb().grow(sway))
  meshes[role]=mesh

## Whole footprint checks original top cells, actual triangles and biome at each
## bounded sample. The owning chunk contains the whole moving footprint.
func supported_footprint(sampler: SurfaceSampler, at: Vector3, basis: Basis, radius: float, cell: float) -> Variant:
 var side:=Terrain.CHUNK_CELLS*cell
 if radius<.12 or floori((at.x-radius)/side)!=floori((at.x+radius)/side) or floori((at.z-radius)/side)!=floori((at.z+radius)/side):return null
 var root:=sampler.height_at(at.x,at.z,at.y)
 if not is_finite(root):return null
 var left:=sampler.height_at(at.x-radius,at.z,at.y)
 var right:=sampler.height_at(at.x+radius,at.z,at.y)
 var back:=sampler.height_at(at.x,at.z-radius,at.y)
 var front:=sampler.height_at(at.x,at.z+radius,at.y)
 if not is_finite(left+right+back+front):return null
 var sx:=(right-left)/(2*radius)
 var sz:=(front-back)/(2*radius)
 var steps:=maxi(2,ceili(radius*2/float(settings.support_step_m)))
 for zi in range(steps+1):
  for xi in range(steps+1):
   var dx:=lerpf(-radius,radius,float(xi)/steps)
   var dz:=lerpf(-radius,radius,float(zi)/steps)
   var x:=floori(at.x+dx)
   var z:=floori(at.z+dz)
   if biome_at(x,z)!="rocky_hills":return null
   var y:=sampler.height_at(at.x+dx,at.z+dz,at.y)
   if not is_finite(y) or absf(y-root)>float(settings.max_support_rise_m) or absf(y-root-sx*dx-sz*dz)>float(settings.max_plane_error_m):return null
   var original:=terrain.height_at(x,z)
   if terrain.block_at(x,original-1,z)==0 or not LakeWater.column(terrain.map,at.x+dx,at.z+dz).is_empty():return null
 var plane:=Basis(Vector3(1,sx,0),Vector3.UP,Vector3(0,sz,1))
 return Transform3D(plane*basis,Vector3(at.x,root-float(settings.root_embed_m),at.z))

func bind(material: ShaderMaterial, kind: String) -> void:
 if kind not in SURFACES:return
 material.set_shader_parameter("rf07_enabled",true)
 material.set_shader_parameter("rf07_mask",mask)
 material.set_shader_parameter("rf07_ground_mix",float(settings.ground_mix))
 material.set_shader_parameter("rf07_turf",preload("res://rf02/ground.tres").meadow_albedo)
 material.set_shader_parameter("rf07_litter",preload("res://rf02/ground.tres").woodland_albedo)
 material.set_shader_parameter("rf07_turf_detail",preload("res://rf02/ground.tres").meadow_detail)

func build(chunk: Node3D,data: Dictionary,cell: float) -> int:
 if not chunk.has_meta("surface_sampler"):return 0
 var sampler: SurfaceSampler=chunk.get_meta("surface_sampler")
 var batches: Dictionary={}
 for surface: String in data.kinds:
  if surface not in SURFACES:continue
  for centre: Vector3 in data.kinds[surface]:
   var x:=floori(centre.x/cell)
   var z:=floori(centre.z/cell)
   if not owns(centre,biome_at(x,z),surface):continue
   var i:=z*int(terrain.map.width)+x
   var y:=float(terrain.map.heights[i])
   if absf(centre.y+cell*.5-y)>.01:continue
   var pocket:=float(context[i*4+2])/255.0
   var rubble:=float(context[i*4+3])/255.0
   var debris: bool=rubble>.22 and support._roll(x,z,737)<float(settings.debris_share)*rubble
   if not debris and support._roll(x,z,701)>lerpf(float(settings.sparse_coverage),float(settings.pocket_coverage),pocket):continue
   var parent:=rock_edge(Vector2(centre.x,centre.z))
   if parent<.10:continue
   var role:="tussock"
   var roll: float=support._roll(x,z,703)
   if pocket>float(settings.scrub_threshold) and roll<float(settings.scrub_share):role="heath"
   elif roll>1.0-float(settings.mat_share):role="cushion"
   if debris:role="shingle"
   var mesh: ArrayMesh=meshes[role]
   var size:=lerpf(float(settings.min_scale),float(settings.max_scale),support._roll(x,z,709))
   if pocket<.3 and role!="shingle":size*=.72
   var at:=Vector3(centre.x+(support._roll(x,z,719)-.5)*float(settings.root_jitter_m),y,centre.z+(support._roll(x,z,727)-.5)*float(settings.root_jitter_m))
   var edge:=minf(minf(fposmod(at.x,16),16-fposmod(at.x,16)),minf(fposmod(at.z,16),16-fposmod(at.z,16)))-.015
   size=minf(size,edge/float(mesh.get_meta("rf07_radius")))
   var radius:=float(mesh.get_meta("rf07_radius"))*size
   var yaw: float=support._roll(x,z,733)*TAU
   var pose: Variant=null
   if support.clear(at,radius):pose=supported_footprint(sampler,at,Basis(Vector3.UP,yaw).scaled(Vector3.ONE*size),radius,cell)
   if pose==null and role!="shingle":
    role="cushion"
    mesh=meshes[role]
    size=minf(float(settings.fringe_scale),edge/float(mesh.get_meta("rf07_radius")))
    radius=float(mesh.get_meta("rf07_radius"))*size
    if support.clear(at,radius):pose=supported_footprint(sampler,at,Basis(Vector3.UP,yaw).scaled(Vector3.ONE*size),radius,cell)
   if pose==null:continue
   if not batches.has(role):batches[role]=[]
   batches[role].append(pose)
 return publish(chunk,batches)

static func publish(chunk: Node3D,batches: Dictionary) -> int:
 var count:=0
 for role: String in batches:
  var poses: Array=batches[role]
  var mesh: ArrayMesh=meshes[role]
  var mm:=MultiMesh.new()
  mm.transform_format=MultiMesh.TRANSFORM_3D
  mm.mesh=mesh
  mm.instance_count=poses.size()
  var origin:=Vector3.ZERO
  for pose: Transform3D in poses:origin+=pose.origin
  origin/=poses.size()
  var displayed: Array=[]
  var total:=AABB()
  for i in poses.size():
   var local: Transform3D=poses[i]
   var bounds: AABB=local*mesh.get_meta("rf01_clearance")
   total=bounds if i==0 else total.merge(bounds)
   local.origin-=origin
   mm.set_instance_transform(i,local)
   displayed.append(local)
  var part:=MultiMeshInstance3D.new()
  part.name="RF07_"+role
  part.multimesh=mm
  part.position=origin
  part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  part.visibility_range_end=float(settings.cover_distance_m)
  part.visibility_range_end_margin=10.0
  part.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
  part.set_meta("terrain_cover",true)
  part.set_meta("rf01_cover",true)
  part.set_meta("rf07_cover",true)
  part.set_meta("world_transforms",poses)
  part.set_meta("display_transforms",displayed)
  part.set_meta("cover_bounds",total)
  part.set_meta("clearance_bounds",mesh.get_meta("rf01_clearance"))
  part.set_meta("hidden_by_building",[])
  part.custom_aabb=AABB(total.position-origin,total.size)
  chunk.add_child(part)
  count+=poses.size()
 return count
