extends RefCounted
## Derived wetland composition. No native state, water, collision or save fields.
const SETTINGS_PATH := "res://rf06b/settings.json"
static var settings: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
static var meshes: Dictionary = {}
var terrain: Terrain
var _support: WeakRef
var support: RefCounted:
 get: return _support.get_ref()
var shore: Dictionary = {}
var occupied: Dictionary = {}
var noise := FastNoiseLite.new()
var mask: ImageTexture

func _init(owner_terrain: Terrain, support_cover: RefCounted) -> void:
 terrain = owner_terrain
 _support = weakref(support_cover)
 noise.seed = int(hash(str(terrain._seed)+"/"+terrain.world_profile()+"/rf06") & 0x7fffffff)
 noise.frequency = 1.0/float(settings.patch_metres)
 # Bounded flood from actual dry/wet edges, once per world build. No per-frame search.
 var wet: Dictionary = {}
 for lake: Dictionary in terrain.map.get("lakes",[]):
  for z in int(lake.height):
   for x in int(lake.width):
    if float(lake.beds[z*int(lake.width)+x])<float(lake.surface_y):
     wet[Vector2i(int(lake.min_x)+x,int(lake.min_z)+z)] = float(lake.surface_y)
 var wave: Array = wet.keys()
 var visited := wet.duplicate()
 for distance in range(1,int(settings.shore_width_m)+1):
  var next: Array = []
  for p: Vector2i in wave:
   for d: Vector2i in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var q := p+d
    if visited.has(q): continue
    var level := float(visited[p])
    visited[q] = level
    shore[q] = {"distance":distance,"level":level}
    next.append(q)
  wave = next
 prepare()
 var pixels := PackedByteArray()
 pixels.resize(int(terrain.map.width)*int(terrain.map.height)*3)
 for z in int(terrain.map.height):
  for x in int(terrain.map.width):
   var i := z*int(terrain.map.width)+x
   var biome: String = terrain.map.biome_defs[terrain.map.biomes[i]].id
   var weight := zone(x,z,biome)
   pixels[i*3] = int(weight*255)
   pixels[i*3+1] = int(terrain.map.heights[i])
   pixels[i*3+2] = int(patch_at(x+.5,z+.5)*255) if weight>0 else 0
 mask = ImageTexture.create_from_image(Image.create_from_data(int(terrain.map.width),int(terrain.map.height),false,Image.FORMAT_RGB8,pixels))

func zone(x: int, z: int, biome: String) -> float:
 if biome == "fen": return 1.0
 if biome not in ["meadow","forest"]: return 0.0
 var bank: Dictionary = shore.get(Vector2i(x,z),{})
 if bank.is_empty(): return 0.0
 var i := z*int(terrain.map.width)+x
 if i<0 or i>=terrain.map.heights.size(): return 0.0
 var rise := float(terrain.map.heights[i])-float(bank.level)
 if rise<0.0 or rise>float(settings.max_bank_rise_m): return 0.0
 return 1.0-float(bank.distance-1)/float(settings.shore_width_m)

func owns(centre: Vector3, biome: String, surface: String) -> bool:
 return surface in ["marsh","grass","forest_floor"] and zone(floori(centre.x),floori(centre.z),biome)>0.0

static func prepare() -> void:
 if not meshes.is_empty(): return
 for role in ["sedge-spread","sedge-crescent","rush-fan","fern-bower","root-weave"]:
  var root: Node3D = load("res://rf06b/assets/"+role+".glb").instantiate()
  var mesh := ArrayMesh.new()
  AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh)
  root.free()
  var radius := 0.0
  for surface in mesh.get_surface_count():
   for vertex: Vector3 in mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]: radius=maxf(radius,Vector2(vertex.x,vertex.z).length())
   var material := ShaderMaterial.new()
   material.shader=preload("res://rf06b/plant.gdshader")
   material.set_shader_parameter("plant_bend",float(settings.wind_bend_per_m) if role!="root-weave" else 0.0)
   material.set_shader_parameter("leaf_normal_up_mix",float(settings.normal_up_mix))
   material.set_shader_parameter("leaf_backlight",float(settings.backlight))
   R7Cover.materials.append(material) # Existing pause-aware wind clock.
   mesh.surface_set_material(surface,material)
  var sway := mesh.get_aabb().size.y*float(settings.wind_bend_per_m)
  mesh.set_meta("rf06b_radius",radius+sway)
  mesh.set_meta("rf01_clearance",mesh.get_aabb().grow(sway))
  meshes[role]=mesh

func patch_at(x: float, z: float) -> float:
 return smoothstep(float(settings.patch_low),float(settings.patch_high),noise.get_noise_2d(x,z))

func passage_at(x: float, z: float) -> bool:
 return absf(noise.get_noise_2d(x*float(settings.passage_frequency_scale)+137.0,z*float(settings.passage_frequency_scale)-219.0))<float(settings.passage_threshold)

## Sample the actual full footprint, including crossed native cells. Keep it
## within its owning chunk so retirement never changes support or hides a hole.
func supported_footprint(sampler: SurfaceSampler, at: Vector3, basis: Basis, radius: float, cell: float) -> Variant:
 var chunk_side := Terrain.CHUNK_CELLS*cell
 if floori((at.x-radius)/chunk_side)!=floori((at.x+radius)/chunk_side) or floori((at.z-radius)/chunk_side)!=floori((at.z+radius)/chunk_side):return null
 var root := sampler.height_at(at.x,at.z,at.y)
 if not is_finite(root):return null
 var left := sampler.height_at(at.x-radius,at.z,at.y)
 var right := sampler.height_at(at.x+radius,at.z,at.y)
 var back := sampler.height_at(at.x,at.z-radius,at.y)
 var front := sampler.height_at(at.x,at.z+radius,at.y)
 if not is_finite(left+right+back+front):return null
 var sx := (right-left)/(2*radius)
 var sz := (front-back)/(2*radius)
 var steps := maxi(2,ceili(radius*2/float(settings.support_step_m)))
 for zi in range(steps+1):
  for xi in range(steps+1):
   var dx := lerpf(-radius,radius,float(xi)/steps)
   var dz := lerpf(-radius,radius,float(zi)/steps)
   var x := at.x+dx
   var z := at.z+dz
   var y := sampler.height_at(x,z,at.y)
   if not is_finite(y) or absf(y-root)>float(settings.max_support_rise_m) or absf(y-root-sx*dx-sz*dz)>float(settings.max_plane_error_m):return null
   var i := floori(z/cell)*int(terrain.map.width)+floori(x/cell)
   if i<0 or i>=terrain.map.heights.size():return null
   # A native top cut cannot be replaced by a nearby lower upward triangle.
   if terrain.block_at(floori(x),int(terrain.map.heights[i])-1,floori(z))==0:return null
   var biome: String = terrain.map.biome_defs[terrain.map.biomes[i]].id
   if zone(floori(x),floori(z),biome)<=0 or not LakeWater.column(terrain.map,x,z).is_empty():return null
 var plane := Basis(Vector3(1,sx,0),Vector3.UP,Vector3(0,sz,1))
 return Transform3D(plane*basis,Vector3(at.x,root-float(settings.root_embed_m),at.z))

func bind(material: ShaderMaterial, kind: String) -> void:
 if kind not in ["marsh","grass","forest_floor"]: return
 material.set_shader_parameter("rf06_enabled",true)
 material.set_shader_parameter("rf06_mask",mask)
 material.set_shader_parameter("rf06_litter",preload("res://rf02/ground.tres").woodland_albedo)
 material.set_shader_parameter("rf06_turf",preload("res://rf02/ground.tres").meadow_albedo)
 material.set_shader_parameter("rf06_mix",float(settings.ground_mix))

func build(chunk: Node3D, data: Dictionary, cell: float, distance: float) -> int:
 if not chunk.has_meta("surface_sampler"): return 0
 var sampler: SurfaceSampler = chunk.get_meta("surface_sampler")
 var batches: Dictionary=chunk.get_meta("pending_rf06_cover",{})
 for surface in data.kinds:
  if surface not in ["marsh","grass","forest_floor"]: continue
  for centre: Vector3 in data.kinds[surface]:
   var x := floori(centre.x/cell)
   var z := floori(centre.z/cell)
   var i := z*int(terrain.map.width)+x
   var biome: String = terrain.map.biome_defs[terrain.map.biomes[i]].id
   if not owns(centre,biome,surface): continue
   var y := float(terrain.map.heights[i])
   if absf(centre.y+cell*0.5-y)>.01 or not LakeWater.column(terrain.map,centre.x,centre.z).is_empty(): continue
   var patch := patch_at(centre.x,centre.z)
   var passage := passage_at(centre.x,centre.z)
   var density := float(settings.passage_coverage) if passage else lerpf(float(settings.sparse_coverage),float(settings.dense_coverage),patch)
   if support._roll(x,z,606)>density:continue
   var near_water := int(shore.get(Vector2i(x,z),{}).get("distance",999))<=int(settings.tall_band_m)
   var tall := not passage and patch>float(settings.tall_patch_threshold) and (biome=="fen" or near_water)
   for home: Dictionary in terrain.map.get("home_sites",[]):
    if Vector2(centre.x-float(home.x),centre.z-float(home.z)).length()<float(settings.home_open_radius_m):tall=false
   var roll: float = support._roll(x,z,607)
   var role := "sedge-spread" if support._roll(x,z,617)<.5 else "sedge-crescent"
   if tall and roll<float(settings.rush_share):role="rush-fan"
   elif not passage and patch>float(settings.fern_patch_threshold) and roll>1.0-float(settings.fern_share):role="fern-bower"
   if not passage and patch>float(settings.root_patch_threshold) and roll>1.0-float(settings.root_share):role="root-weave"
   var size := lerpf(float(settings.minimum_scale),float(settings.maximum_scale),support._roll(x,z,608))
   if passage:size*=float(settings.passage_scale)
   if biome!="fen":size*=lerpf(float(settings.outer_bank_scale),1.0,zone(x,z,biome))
   var mesh: ArrayMesh=meshes[role]
   var radius: float=mesh.get_meta("rf06b_radius")
   var at := Vector3(centre.x,y,centre.z)
   # Small asymmetric offsets; border roots shrink, not depend on neighbour chunks.
   var jitter := float(settings.root_jitter_m)
   at.x+=(support._roll(x,z,619)-.5)*jitter
   at.z+=(support._roll(x,z,623)-.5)*jitter
   var edge := minf(minf(fposmod(at.x,16),16-fposmod(at.x,16)),minf(fposmod(at.z,16),16-fposmod(at.z,16)))-.015
   size=minf(size,edge/radius)
   radius*=size
   var basis := Basis(Vector3.UP,support._roll(x,z,609)*TAU)
   var pose: Variant=null
   if support.clear(at,radius) and regional_clear(at,radius):
    pose=supported_footprint(sampler,at,basis.scaled(Vector3.ONE*size),radius,cell)
   if pose==null:
    # Low edge growth bridges large masses on narrow terraces. Still check
    # every actual support/approach/ownership boundary; never bridge a hole.
    role="sedge-crescent"
    size=minf(float(settings.fringe_scale),edge/float(meshes[role].get_meta("rf06b_radius")))
    radius=float(meshes[role].get_meta("rf06b_radius"))*size
    if support.clear(at,radius) and regional_clear(at,radius):
     pose=supported_footprint(sampler,at,basis.scaled(Vector3.ONE*size),radius,cell)
   if pose==null:continue
   if not batches.has(role): batches[role]=[]
   batches[role].append(pose)
 if int(data.get("cover_slice",0))+1<int(data.get("cover_slices",1)):
  chunk.set_meta("pending_rf06_cover",batches)
  return 0
 if chunk.has_meta("pending_rf06_cover"):chunk.remove_meta("pending_rf06_cover")
 return publish(chunk,batches,distance)

static func publish(chunk: Node3D, batches: Dictionary, distance: float) -> int:
 var count := 0
 for role: String in batches:
  var poses: Array = batches[role]
  var mesh: ArrayMesh = meshes[role]
  var mm := MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.mesh=mesh
  mm.instance_count=poses.size()
  var origin := Vector3.ZERO
  for pose: Transform3D in poses: origin+=pose.origin
  origin/=poses.size()
  var displayed: Array=[]
  var total := AABB()
  for i in poses.size():
   var local: Transform3D=poses[i]
   var bounds: AABB=local*mesh.get_meta("rf01_clearance")
   total=bounds if i==0 else total.merge(bounds)
   local.origin-=origin
   mm.set_instance_transform(i,local)
   displayed.append(local)
  var part := MultiMeshInstance3D.new()
  part.name="RF06_"+role
  part.multimesh=mm
  part.position=origin
  part.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  part.visibility_range_end=distance
  part.visibility_range_end_margin=8.0
  part.visibility_range_fade_mode=GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
  part.set_meta("terrain_cover",true)
  part.set_meta("rf01_cover",true) # Reuse exact paid station/body clearance.
  part.set_meta("rf06_cover",true)
  part.set_meta("world_transforms",poses)
  part.set_meta("display_transforms",displayed)
  part.set_meta("cover_bounds",total)
  part.set_meta("clearance_bounds",mesh.get_meta("rf01_clearance"))
  part.set_meta("hidden_by_building",[])
  part.custom_aabb=AABB(total.position-origin,total.size)
  chunk.add_child(part)
  count+=poses.size()
 return count

func regional_clear(at: Vector3, radius: float) -> bool:
 for p: Vector3 in occupied.get(Vector2i(floori(at.x/4),floori(at.z/4)),[]):
  if Vector2(at.x-p.x,at.z-p.z).length()<p.y+radius: return false
 return true

func reserve_existing(root: Node3D) -> void:
 occupied.clear()
 for group in root.get_children():
  for part in group.get_children():
   var points: Array=[]
   if part is MultiMeshInstance3D:
    for pose: Transform3D in part.get_meta("world_transforms",[]): points.append(Vector3(pose.origin.x,.65,pose.origin.z))
   elif part is MeshInstance3D and part.has_meta("pool_radius"):
    points.append(Vector3(part.position.x,float(part.get_meta("pool_radius"))*1.2,part.position.z))
   for p: Vector3 in points:
    var pad := p.y+float(settings.plant_width_m)
    for x in range(floori((p.x-pad)/4),floori((p.x+pad)/4)+1):
     for z in range(floori((p.z-pad)/4),floori((p.z+pad)/4)+1):
      var key := Vector2i(x,z)
      if not occupied.has(key):occupied[key]=[]
      occupied[key].append(p)
 # Initial near chunks may precede regional dressing during world entry.
 # Filter their retained poses once so first load and later rebuild agree.
 for chunk in terrain.chunks.values():
  var batches: Dictionary={}
  var distance := 55.0
  for part in chunk.get_children():
   if not part.has_meta("rf06_cover"):continue
   distance=part.visibility_range_end
   var role := String(part.name).trim_prefix("RF06_")
   for pose: Transform3D in part.get_meta("world_transforms"):
    if not regional_clear(pose.origin,float(meshes[role].get_meta("rf06b_radius"))*pose.basis.y.length()):continue
    if not batches.has(role):batches[role]=[]
    batches[role].append(pose)
   chunk.remove_child(part)
   part.free()
  publish(chunk,batches,distance)
