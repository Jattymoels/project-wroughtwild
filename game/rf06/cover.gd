extends RefCounted
## Derived wetland composition. No native state, water, collision or save fields.
const SETTINGS_PATH := "res://rf06/settings.json"
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
 pixels.resize(int(terrain.map.width)*int(terrain.map.height)*2)
 for z in int(terrain.map.height):
  for x in int(terrain.map.width):
   var i := z*int(terrain.map.width)+x
   var biome: String = terrain.map.biome_defs[terrain.map.biomes[i]].id
   var weight := zone(x,z,biome)
   pixels[i*2] = int(weight*255)
   pixels[i*2+1] = int(terrain.map.heights[i])
 mask = ImageTexture.create_from_image(Image.create_from_data(int(terrain.map.width),int(terrain.map.height),false,Image.FORMAT_RG8,pixels))

func zone(x: int, z: int, biome: String) -> float:
 if biome == "fen": return 1.0
 if biome not in ["meadow","forest"]: return 0.0
 var bank: Dictionary = shore.get(Vector2i(x,z),{})
 if bank.is_empty(): return 0.0
 var i := z*int(terrain.map.width)+x
 if i<0 or i>=terrain.map.heights.size(): return 0.0
 var rise := float(terrain.map.heights[i])-float(bank.level)
 if rise<0.0 or rise>3.0: return 0.0
 return 1.0-float(bank.distance-1)/float(settings.shore_width_m)

func owns(centre: Vector3, biome: String, surface: String) -> bool:
 return surface in ["marsh","grass","forest_floor"] and zone(floori(centre.x),floori(centre.z),biome)>0.0

static func prepare() -> void:
 if not meshes.is_empty(): return
 # Existing decorative sedge has no harvest seed heads. Two proportions share
 # its authored leaves; fern/deadfall remain the already adopted kit.
 for role in ["sedge","rush","fern","deadfall"]:
  var source: ArrayMesh = AuthoredAssets.mesh_for("strange_sedge" if role in ["sedge","rush"] else "fern_bed" if role=="fern" else "deadfall")
  var box := source.get_aabb()
  var centre := Vector3(box.get_center().x,box.position.y,box.get_center().z)
  var radius := 0.001
  for s in source.get_surface_count():
   for v: Vector3 in source.surface_get_arrays(s)[Mesh.ARRAY_VERTEX]: radius = maxf(radius,Vector2(v.x-centre.x,v.z-centre.z).length())
  var height := float(settings.rush_height_m if role=="rush" else settings.sedge_height_m)
  if role=="deadfall": height=0.18
  var gain := Vector3(float(settings.plant_width_m)*0.5/radius,height/box.size.y,float(settings.plant_width_m)*0.5/radius)
  var mesh := ArrayMesh.new()
  for s in source.get_surface_count():
   var tool := SurfaceTool.new()
   tool.begin(Mesh.PRIMITIVE_TRIANGLES)
   tool.append_from(source,s,Transform3D(Basis.from_scale(gain),-centre*gain))
   tool.set_material(source.surface_get_material(s))
   tool.commit(mesh)
  mesh.set_meta("rf01_clearance",mesh.get_aabb())
  meshes[role]=mesh

func bind(material: ShaderMaterial, kind: String) -> void:
 if kind not in ["marsh","grass","forest_floor"]: return
 material.set_shader_parameter("rf06_enabled",true)
 material.set_shader_parameter("rf06_mask",mask)
 material.set_shader_parameter("rf06_litter",preload("res://rf02/ground.tres").woodland_albedo)
 material.set_shader_parameter("rf06_mix",float(settings.ground_mix))

func build(chunk: Node3D, data: Dictionary, cell: float, distance: float) -> int:
 if not chunk.has_meta("surface_sampler"): return 0
 var sampler: SurfaceSampler = chunk.get_meta("surface_sampler")
 var batches: Dictionary = {}
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
   var patch := smoothstep(-.24,.25,noise.get_noise_2d(centre.x,centre.z))
   var density := lerpf(float(settings.sparse_coverage),float(settings.dense_coverage),patch)
   if support._roll(x,z,606)>density: continue
   var near_water := int(shore.get(Vector2i(x,z),{}).get("distance",999))<=int(settings.tall_band_m)
   var tall := patch>.48 and (biome=="fen" or near_water)
   for home: Dictionary in terrain.map.get("home_sites",[]):
    if Vector2(centre.x-float(home.x),centre.z-float(home.z)).length()<float(settings.home_open_radius_m): tall=false
   var roll: float = support._roll(x,z,607)
   var role := "rush" if tall and roll<float(settings.tall_share) else "fern" if roll>.83 else "sedge"
   if patch>.65 and roll>.986: role="deadfall"
   # Lower, more meadow-like growth at the outside of the bank.
   var size := lerpf(float(settings.minimum_scale),1.0,support._roll(x,z,608))
   if biome!="fen": size *= lerpf(.72,1.0,zone(x,z,biome))
   var radius := float(settings.plant_width_m)*.5*size
   var at := Vector3(centre.x,y,centre.z)
   if not support.clear(at,radius) or not regional_clear(at,radius): continue
   var pose: Variant = support.supported_pose(sampler,at,Basis(Vector3.UP,support._roll(x,z,609)*TAU).scaled(Vector3.ONE*size),radius,cell)
   if pose==null: continue
   if not batches.has(role): batches[role]=[]
   batches[role].append(pose)
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
   var bounds: AABB=local*mesh.get_aabb()
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
  part.set_meta("clearance_bounds",mesh.get_aabb())
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
    if not regional_clear(pose.origin,float(settings.plant_width_m)*.5*pose.basis.y.length()):continue
    if not batches.has(role):batches[role]=[]
    batches[role].append(pose)
   chunk.remove_child(part)
   part.free()
  publish(chunk,batches,distance)
