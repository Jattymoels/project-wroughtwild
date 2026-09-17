extends RefCounted
## One world's transient low-cover composition. No owned state or geometry edits.
const SETTINGS = preload("res://rf01/low_cover.tres")
const PROFILES := ["frontier_v6","frontier_v7","frontier_v8","frontier_v9","frontier_v10","frontier_v11","living_frontier_wave1","living_frontier_wave3"]
const RESERVATION_CELL := 8.0
var recovery: RefCounted
var wetland: RefCounted
var highland: RefCounted
var _map: Dictionary
var _seed: int
var _profile: String
var _noise := FastNoiseLite.new()
var _reserved: Dictionary = {}

static func eligible(profile: String, biome: String, surface: String) -> bool:
 return profile in PROFILES and biome in ["meadow","forest","gallery_woodland"] and surface in ["grass","forest_floor"]

func _init(map: Dictionary, world_seed: int, profile: String, reservations: Dictionary) -> void:
 _map = map
 _seed = world_seed
 _profile = profile
 recovery = preload("res://rf08/context.gd").new(map,world_seed,profile)
 _noise.seed = int(hash(str(world_seed)+"/"+profile+"/"+str(SETTINGS.visual_salt)) & 0x7fffffff)
 _noise.frequency = 1.0/SETTINGS.patch_metres
 # Reuse the established site/resource/approach reservations. Expanding their
 # index once avoids scanning a large impact radius for every little plant.
 for key in reservations:
  if key is Vector2i:
   for point: Vector3 in reservations[key]: _reserve(point)
 var cell := float(map.cell_size)
 _reserve(Vector3((float(map.spawn_x)+0.5)*cell,HabitatCover.LOOK.clearing_metres,(float(map.spawn_z)+0.5)*cell))
 for site: Dictionary in map.get("home_sites",[]):
  # V7 cores are useful ground, not visible plots. Low grass remains until
  # ordinary paid footprints clear it; published V6/LF reservations stay exact.
  if profile not in ["frontier_v7","frontier_v8","frontier_v9"]:
   _reserve(Vector3((float(site.x)+0.5)*cell,float(site.radius_m),(float(site.z)+0.5)*cell))
  for point: Vector3 in site.get("approach",[]): _reserve(Vector3(point.x,StrangeSites.LOOK.approach_clearance_m,point.z))
 for site: Dictionary in map.get("landmarks",[]):
  _reserve(Vector3((float(site.x)+0.5)*cell,5.0*cell,(float(site.z)+0.5)*cell))
 _reserve(Vector3((float(map.gate_x)+0.5)*cell,5.0*cell,(float(map.gate_z)+0.5)*cell))
 # LF laboratories and their source walks share native records, not policies.
 for lab: Dictionary in map.get("laboratories",[]):
  var p: Vector3 = lab.position
  var size: Vector3 = lab.size
  _reserve(Vector3(p.x,Vector2(size.x,size.z).length()*0.5+0.8,p.z))
  for point: Vector3 in lab.get("approach",[]): _reserve(Vector3(point.x,StrangeSites.LOOK.approach_clearance_m,point.z))
 for host: Dictionary in map.get("frontier_hosts",[]):
  var p: Vector3 = host.position
  _reserve(Vector3(p.x,StrangeSites.LOOK.resource_clearance_m,p.z))
  for route in ["approach","source_route"]:
   for point: Vector3 in host.get(route,[]): _reserve(Vector3(point.x,StrangeSites.LOOK.approach_clearance_m,point.z))
 for point: Vector3 in map.get("laboratory_trail",[]): _reserve(Vector3(point.x,StrangeSites.LOOK.approach_clearance_m,point.z))

func _reserve(point: Vector3) -> void:
 var pad := point.y+maxf(SETTINGS.grass_width_m,SETTINGS.fern_width_m)
 for x in range(floori((point.x-pad)/RESERVATION_CELL),floori((point.x+pad)/RESERVATION_CELL)+1):
  for z in range(floori((point.z-pad)/RESERVATION_CELL),floori((point.z+pad)/RESERVATION_CELL)+1):
   var key := Vector2i(x,z)
   if not _reserved.has(key): _reserved[key] = []
   _reserved[key].append(point)

func clear(at: Vector3, radius: float) -> bool:
 if preload("res://land02/kit.gd").in_cut(_map,at,radius+.6):return false
 for point: Vector3 in _reserved.get(Vector2i(floori(at.x/RESERVATION_CELL),floori(at.z/RESERVATION_CELL)),[]):
  if Vector2(at.x-point.x,at.z-point.z).length_squared() < (point.y+radius)*(point.y+radius): return false
 return true

func _roll(x: int, z: int, salt: int) -> float:
 return float((hash(Vector3i(x,salt+SETTINGS.visual_salt,z)) ^ hash(str(_seed)+"/"+_profile)) & 0x7fffffff)/2147483647.0

func density_at(x: float, z: float) -> float:
 var patch := smoothstep(-0.3,0.3,_noise.get_noise_2d(x,z))
 return recovery.density(x,z,lerpf(SETTINGS.sparse_coverage,SETTINGS.dense_coverage,patch))

## Nine bounded triangle queries, never per-vertex projection or cave-floor search.
## The root plane follows ordinary slopes; the mesh's X/Z footprint stays fixed.
func supported_pose(sampler: SurfaceSampler, at: Vector3, basis: Basis, radius: float, cell: float) -> Variant:
 var lo := Vector2(-radius,-radius)
 var hi := Vector2(radius,radius)
 # Keep the complete moving footprint in the owning native cell. This makes
 # border rebuilding independent of neighbouring chunk publication/retirement.
 var cx := floori(at.x/cell)
 var cz := floori(at.z/cell)
 if at.x+lo.x<cx*cell+0.005 or at.x+hi.x>(cx+1)*cell-0.005 or at.z+lo.y<cz*cell+0.005 or at.z+hi.y>(cz+1)*cell-0.005: return null
 var xs := [lo.x,0.0,hi.x]
 var zs := [lo.y,0.0,hi.y]
 var heights: Array[float] = []
 for dz: float in zs:
  for dx: float in xs:
   var y := sampler.height_at(at.x+dx,at.z+dz,at.y)
   if not is_finite(y): return null
   heights.append(y)
 var root := heights[4]
 var slope_x := (heights[5]-heights[3])/(hi.x-lo.x)
 var slope_z := (heights[7]-heights[1])/(hi.y-lo.y)
 for zi in 3:
  for xi in 3:
   var y := heights[zi*3+xi]
   if absf(y-root)>SETTINGS.max_support_rise_m or absf(y-root-slope_x*xs[xi]-slope_z*zs[zi])>SETTINGS.max_plane_error_m: return null
 var plane := Basis(Vector3(1,slope_x,0),Vector3.UP,Vector3(0,slope_z,1))
 return Transform3D(plane*basis,Vector3(at.x,root-SETTINGS.root_embed_m,at.z))

func build(chunk: Node3D, data: Dictionary, cell: float, distance: float) -> int:
 if not chunk.has_meta("surface_sampler"): return 0
 var sampler: SurfaceSampler = chunk.get_meta("surface_sampler")
 var batches: Dictionary = {}
 for surface in data.kinds:
  if surface not in ["grass","forest_floor","dirt","rock"]: continue
  for centre: Vector3 in data.kinds[surface]:
   var x := floori(centre.x/cell)
   var z := floori(centre.z/cell)
   var i := z*int(_map.width)+x
   if not LakeWater.column(_map,centre.x,centre.z).is_empty(): continue
   var expected := float(_map.heights[i])
   if absf(centre.y+cell*0.5-expected)>0.01: continue
   var biome: String = _map.biome_defs[_map.biomes[i]].id
   if wetland!=null and wetland.owns(centre,biome,surface): continue
   var recovery_sample: Vector2 = recovery.sample(centre.x,centre.z)
   var recovered := recovery_sample.x>float(recovery.settings.eligible_weight) and biome in ["meadow","forest","gallery_woodland"]
   if not (eligible(_profile,biome,surface) or recovered) or _roll(x,z,11)>density_at(centre.x,centre.z): continue
   var fern_share: float = SETTINGS.forest_fern_share if biome=="forest" else SETTINGS.meadow_fern_share
   var role := "fern-sparse" if _roll(x,z,17)<fern_share else "grass-edge" if _roll(x,z,19)<SETTINGS.edge_grass_share else "grass-meadow"
   if recovered and biome=="forest" and _roll(x,z,37)<float(recovery.settings.woodland_mat_share): role="rf08-groundleaf"
   if recovered and _roll(x,z,31)<float(recovery.settings.debris_share)*(1.0-recovery_sample.y): role="rf08-shingle"
   var mesh: ArrayMesh = recovery.mesh_for(role) if role.begins_with("rf08-") else SETTINGS.mesh_for(role)
   var size := lerpf(SETTINGS.minimum_scale,1.0,_roll(x,z,23))
   var basis := Basis(Vector3.UP,_roll(x,z,29)*TAU).scaled(Vector3.ONE*size)
   # Radius includes inherited wind. Cell-centred roots retain room for full
   # leaves at chunk edges; visual asymmetry comes from authored forms and yaw.
   var radius := (SETTINGS.fern_width_m if role.begins_with("fern") else SETTINGS.grass_width_m)*0.5*size+SETTINGS.fern_height_m*float(R7Cover.settings.wind_bend_per_m)*1.06
   if role.begins_with("rf08-"): radius=(float(recovery.settings.chip_footprint_m) if role=="rf08-shingle" else float(recovery.settings.mat_footprint_m))*size
   var at := Vector3(centre.x,expected,centre.z)
   if not clear(at,radius): continue
   var pose: Variant = supported_pose(sampler,at,basis,radius,cell)
   if pose == null: continue
   if not batches.has(role): batches[role] = []
   batches[role].append(pose)
 var count := 0
 for role: String in batches:
  var poses: Array = batches[role]
  var mesh: ArrayMesh = recovery.mesh_for(role) if role.begins_with("rf08-") else SETTINGS.mesh_for(role)
  var local_bounds: AABB = mesh.get_meta("rf01_clearance")
  var mm := MultiMesh.new()
  mm.transform_format = MultiMesh.TRANSFORM_3D
  mm.mesh = mesh
  mm.instance_count = poses.size()
  var origin := Vector3.ZERO
  for pose: Transform3D in poses: origin += pose.origin
  origin /= poses.size()
  var displayed: Array = []
  var total := AABB()
  for i in poses.size():
   var local: Transform3D = poses[i]
   var bounds: AABB = local*local_bounds
   total = bounds if i==0 else total.merge(bounds)
   local.origin -= origin
   mm.set_instance_transform(i,local)
   displayed.append(local)
  var part := MultiMeshInstance3D.new()
  part.name = "RF01_"+role
  part.multimesh = mm
  part.position = origin
  part.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
  part.visibility_range_end = distance
  part.visibility_range_end_margin = 8.0
  part.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
  part.set_meta("terrain_cover",true)
  part.set_meta("rf01_cover",true)
  part.set_meta("world_transforms",poses)
  part.set_meta("display_transforms",displayed)
  part.set_meta("cover_bounds",total)
  part.set_meta("clearance_bounds",local_bounds)
  part.set_meta("hidden_by_building",[])
  part.custom_aabb = AABB(total.position-origin,total.size)
  chunk.add_child(part)
  count += poses.size()
 return count
## RF-only work-area mask uses each station's actual saved pose and body.
## Older cover still uses the unchanged lattice index.
static func station_bounds(site: StationSite) -> AABB:
 var collision: CollisionShape3D = site.get_node("CollisionShape3D")
 var bounds: AABB = collision.global_transform*AABB(-StationSite.BODY.size*0.5,StationSite.BODY.size)
 return bounds.grow(StrangeSites.ECOLOGY.building_clearance_m)

func workspace_index(terrain: Node3D, buildings: Dictionary) -> Dictionary:
 var result: Dictionary = buildings.duplicate(true)
 for site in terrain.get_tree().get_nodes_in_group("crafting_stations"):
  if not site is StationSite or site.get_parent()!=terrain.get_parent(): continue
  var bounds := station_bounds(site)
  var step: float = StrangeSites.ECOLOGY.batch_width_m
  for x in range(floori(bounds.position.x/step),floori(bounds.end.x/step)+1):
   for z in range(floori(bounds.position.z/step),floori(bounds.end.z/step)+1):
    var key := Vector2i(x,z)
    if not result.has(key): result[key] = []
    result[key].append(bounds)
 return result
