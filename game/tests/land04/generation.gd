extends Node
## Two ordinary seeds exercise changed journey geometry and V12 ownership. This
## is not a seed matrix or a substitute for controller contact in use.gd.
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL LAND04 generation: ",label)
func dry(map: Dictionary, at: Vector3) -> bool:
 return LakeWater.column(map,at.x,at.z).is_empty()
func _ready() -> void:
 var sim:=WroughtwildSim.new()
 check(sim.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()),"tuning loads")
 var records:=[]
 var previous: Array=[]
 for seed_value in [77,78]:
  check(sim.set_world_profile("frontier_v12"),"new V12 profile selects")
  var map: Dictionary=sim.world_map(seed_value)
  if map.is_empty():check(false,sim.last_error());break
  check(map.home_sites.size()==4 and map.lakes.size()==1 and map.scarwater.size()==1 and map.dry_steppe.size()==1,"four original home cores, fixed lake, approved Scarwater and Steppe survive")
  check(map.regions.size()==3 and map.rare_sites.size()==14 and map.pressure_pockets.size()==1 and map.laboratories.is_empty() and map.future_transformations.is_empty(),"finite discoveries and separate pressure preserved without LF campaign")
  var homes_ok:=true
  var width:=int(map.width)
  for home: Dictionary in map.home_sites:
   for dz in range(-14,15):
    for dx in range(-14,15):
     if dx*dx+dz*dz>196:continue
     if map.heights[(int(home.z)+dz)*width+int(home.x)+dx]!=home.y or not dry(map,Vector3(home.x+dx,home.y,home.z+dz)):homes_ok=false
  check(homes_ok,"all four complete radius-fourteen home cores stay level and dry")
  var journeys: Array=map.force_journeys
  check(journeys.size()==4,"three source journeys and Green Steppe contrast")
  var primary:=[]
  var secondary:=[]
  var routes_ok:=true
  var blue: Dictionary={}
  var green: Dictionary={}
  var stance_ok:=true
  for row: Dictionary in journeys:
   if row.secondary:secondary.append(row)
   else:primary.append(row)
   if row.channel=="blue":blue=row
   if row.channel=="green" and not row.secondary:green=row
   if row.secondary:continue
   var ground_id: String=map.biome_defs[map.biomes[int(row.position.z)*width+int(row.position.x)]].id
   check(ground_id==row.biome,row.channel+" selected physical host agrees with actual ground habitat")
   for key in ["approach","host_route"]:
    var route: PackedVector3Array=row[key]
    if route.size()<2:routes_ok=false
    for i in route.size():
     if not dry(map,route[i]):routes_ok=false
     if i>0 and absf(route[i].y-route[i-1].y)>1.01:routes_ok=false
   var separation: float=((row.position-row.work_stance)*Vector3(1,0,1)).length()
   stance_ok=stance_ok and separation>=1.7 and separation<=4.5 and row.approach[-1]==row.work_stance
   check(not row.form_anchors.is_empty() and not row.growth_anchors.is_empty(),row.channel+" has substantial integrated form and living-host anchors")
  check(routes_ok and stance_ok,"dry source and observation routes end outside solid source bodies")
  check(primary.size()==3 and secondary.size()==1 and secondary[0].channel=="green" and secondary[0].source_id=="" and secondary[0].host_id=="" and secondary[0].biome=="dry_steppe" and secondary[0].host!=green.host,"Green branches through different tall/low hosts without a second resin or finite-creature owner")
  check(sim.contraption_bind_world("frontier_v12",seed_value) and sim.leyline_bind_world("frontier_v12",seed_value),"V12 binds exact ordinary source and device owners")
  var sources:=sim.leyline_sources()
  var owners:=[]
  var anchors_ok: bool=sources.size()==4 and map.leyline_source_sites.size()==4
  for source: Dictionary in sources:
   owners.append(source.id)
   var at: Vector3=source.position
   if not dry(map,at) or source.lots!=8 or source.units_per_lot!=16 or source.steps!=4 or source.formation_seconds!=600:anchors_ok=false
  owners.sort()
  check(anchors_ok and owners==["blue_home_margin","green_home_margin","red_home_margin","white_home_margin"],"exact four dry existing source owners keep eight-lot/manual/renewal rules")
  var ids:=[]
  var host_ids:=[]
  var hosts_ok: bool=map.frontier_hosts.size()==4
  for host: Dictionary in map.frontier_hosts:
   ids.append(host.enemy_id);host_ids.append(host.id)
   var source_at:=Vector3.INF
   for item: Dictionary in sources:
    if item.id==host.source_id:source_at=item.position;break
   var distance: float=((host.position-source_at)*Vector3(1,0,1)).length()
   hosts_ok=hosts_ok and distance>=65 and distance<=130 and Vector2(host.position.x-map.spawn_x,host.position.z-map.spawn_z).length()>=170
   for other: Dictionary in map.frontier_hosts:
    if host.id!=other.id and ((host.position-other.position)*Vector3(1,0,1)).length()<60:hosts_ok=false
  ids.sort()
  check(hosts_ok and ids==["lf_blue_boar","lf_green_moth","lf_red_boar","lf_white_stag"],"four separate existing finite hosts preserve source/start/mutual separation")
  var fresh:=WroughtwildSim.new()
  fresh.load_tuning(load("res://scripts/sim.gd").get_tuning_directory());fresh.set_world_profile("frontier_v12")
  var repeated: Dictionary=fresh.world_map(seed_value)
  check(hash(map.blocks)==hash(repeated.blocks) and journeys==repeated.force_journeys and map.leyline_source_sites==repeated.leyline_source_sites and map.frontier_hosts==repeated.frontier_hosts,"independent same seed/profile repeats terrain, sources, routes and finite hosts")
  if not previous.is_empty():check(previous!=journeys,"contrasting seed changes place geography rather than only a cosmetic random seed")
  previous=journeys
  if seed_value==77 and not blue.is_empty():
   var at: Vector3=blue.form_anchors[0]
   var data:=sim.world_mesh_chunk(seed_value,16,floori(at.x/16)*16,floori(at.z/16)*16,PackedInt32Array(),true,{})
   var visible:=PackedVector3Array()
   for kind: String in data.surfaces:visible.append_array(data.surfaces[kind])
   check(visible.size()==data.faces.size() and data.source_cells.size()*3==data.faces.size(),"V12 changed host chunk has matching visible/contact triangles and edit owners")
   var valid:=true
   for owner: Vector3 in data.source_cells:
    if map.blocks[(int(owner.z)*width+int(owner.x))*int(map.depth)+int(owner.y)]==0:valid=false
   check(valid,"every changed-host triangle owns an existing solid block")
  records.append({"seed":seed_value,"height_hash":hash(map.heights),"blocks_hash":hash(map.blocks),"journeys":journeys,"finite_host_ids":host_ids})
 # Published V11 fingerprint and changed LF source dispatch are targeted only.
 sim.set_world_profile("frontier_v11")
 var old: Dictionary=sim.world_map(77)
 check(hash(old.blocks)==1005562575 and hash(old.heights)==1514548234 and old.force_journeys.is_empty(),"published V11 exact geography fingerprint and presentation identity preserved")
 sim.leyline_bind_world("frontier_v11",77);sim.leyline_work("white_home_margin")
 var v11:=sim.leyline_save()
 check(JSON.parse_string(v11).profile=="frontier_v11","V11 keeps its original exact source ledger tag")
 sim.set_world_profile("living_frontier_wave3");sim.leyline_bind_world("living_frontier_wave3",77)
 sim.leyline_work("white_home_margin")
 check(JSON.parse_string(sim.leyline_save()).profile=="living_frontier_wave1","LF preserves its historical internal ledger identity")
 sim.set_world_profile("frontier_v12");sim.leyline_bind_world("frontier_v12",77)
 var reset:=true
 for source: Dictionary in sim.leyline_sources():
  if source.work!=0:reset=false
 check(reset and JSON.parse_string(sim.leyline_save()).profile=="frontier_v12","same seed changed profile carries no previous-world partial source work")
 var output:=OS.get_environment("WROUGHTWILD_LAND04_OUTPUT")
 FileAccess.open(output.path_join("generation-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records},"\t"))
 print("LAND04_GENERATION ",checks," checks / ",failures," failures")
 get_tree().quit(0 if failures==0 else 1)