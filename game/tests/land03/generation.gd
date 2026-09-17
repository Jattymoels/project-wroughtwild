extends Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL LAND03 generation: ",label)
func _ready() -> void:
 var sim:=WroughtwildSim.new()
 check(sim.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()),"tuning loads")
 var records:=[]
 var previous: Dictionary={}
 for seed_value in [77,78]:
  check(sim.set_world_profile("frontier_v11"),"new profile selects")
  var map: Dictionary=sim.world_map(seed_value)
  if map.is_empty():check(false,sim.last_error());break
  check(map.home_sites.size()==4 and map.lakes.size()==1 and map.scarwater.size()==1 and map.dry_steppe.size()==1,"inherited Scarwater and four-home finite landscape plus one Steppe")
  check(map.regions.size()==3 and map.rare_sites.size()==14 and map.pressure_pockets.size()==1,"existing discovery regions/rare/pressure owners retained")
  check(map.laboratories.is_empty() and map.future_transformations.is_empty(),"source adoption introduces no laboratories or transformations")
  var p: Dictionary=map.dry_steppe[0]
  var widths:=int(map.width)
  var homes_ok:=true
  var ecology:=true
  for h: Dictionary in map.home_sites:
   for dz in range(-14,15):
    for dx in range(-14,15):
     if dx*dx+dz*dz>196:continue
     if map.heights[(int(h.z)+dz)*widths+int(h.x)+dx]!=h.y or not LakeWater.column(map,h.x+dx,h.z+dz).is_empty():homes_ok=false
   if h.id in [p.hollow_home_id,p.outlook_home_id] and map.biome_defs[map.biomes[int(h.z)*widths+int(h.x)]].id!="dry_steppe":ecology=false
  check(homes_ok,"all four radius-fourteen cores remain level and dry")
  check(ecology,"Steppe hollow/outlook use the other two existing home cores")
  var routes_ok:=true
  for key in ["ridge_route","low_route"]:
   var route: PackedVector3Array=p[key]
   if route.size()<5:routes_ok=false
   for i in route.size():
    if not LakeWater.column(map,route[i].x,route[i].z).is_empty():routes_ok=false
    if i>0 and absf(route[i].y-route[i-1].y)>1.01:routes_ok=false
  check(routes_ok and p.ridge_route!=p.low_route,"two distinct dry traversable native source approaches")
  check(sim.contraption_bind_world("frontier_v11",seed_value) and sim.leyline_bind_world("frontier_v11",seed_value),"bind separate ordinary source and machine owners")
  var sources:=sim.leyline_sources()
  var anchors_ok: bool=sources.size()==4 and map.leyline_source_sites.size()==4
  for source: Dictionary in sources:
   var at: Vector3=source.position
   if not LakeWater.column(map,at.x,at.z).is_empty() or source.lots!=8 or source.units_per_lot!=16 or source.steps!=4 or source.formation_seconds!=600:anchors_ok=false
  check(anchors_ok,"four actual dry sources keep existing eight-lot/manual/renewal economy")
  var h: Dictionary=map.frontier_hosts[0] if map.frontier_hosts.size()==1 else {}
  check(not h.is_empty() and h.enemy_id=="lf_red_boar","only selected existing Red teaching host")
  if not h.is_empty():
   var distance:=Vector2(h.position.x-p.red_source.x,h.position.z-p.red_source.z).length()
   check(distance>=65 and distance<=130 and Vector2(h.position.x-map.spawn_x,h.position.z-map.spawn_z).length()>=170,"Red host separated from source work and quiet start")
  var fresh:=WroughtwildSim.new();fresh.load_tuning(load("res://scripts/sim.gd").get_tuning_directory());fresh.set_world_profile("frontier_v11")
  var repeated: Dictionary=fresh.world_map(seed_value)
  check(hash(map.blocks)==hash(repeated.blocks) and p==repeated.dry_steppe[0] and map.leyline_source_sites==repeated.leyline_source_sites,"independent same profile/seed repeats terrain, routes and source anchors")
  var at: Vector3=p.mineral_hosts[0]
  var data:=sim.world_mesh_chunk(seed_value,16,floori(at.x/16)*16,floori(at.z/16)*16,PackedInt32Array(),true,{})
  var visible:=PackedVector3Array()
  for kind: String in data.surfaces:visible.append_array(data.surfaces[kind])
  check(visible.size()==data.faces.size() and data.source_cells.size()*3==data.faces.size(),"Steppe density feeds equal visible/contact triangles with edit owners")
  var valid:=true
  for owner: Vector3 in data.source_cells:
   if map.blocks[(int(owner.z)*widths+int(owner.x))*int(map.depth)+int(owner.y)]==0:valid=false
  check(valid,"every Steppe triangle owns existing solid matter")
  records.append({"seed":seed_value,"height_hash":hash(map.heights),"blocks_hash":hash(map.blocks),"centre":p.centre,"direction":p.direction,"fallback":p.fallback,"routes":[p.ridge_route.size(),p.low_route.size()],"red_source":p.red_source,"red_host":p.red_host})
  if not previous.is_empty():check(previous.centre!=p.centre and previous.direction!=p.direction and previous.ridge_route!=p.ridge_route,"contrasting seed changes country/orientation/routes rather than only art jitter")
  previous=p
 # Only changed old-profile dispatch is checked, reusing prior body/campaign evidence.
 sim.set_world_profile("frontier_v10")
 var old: Dictionary=sim.world_map(77)
 check(hash(old.blocks)==919471993 and hash(old.heights)==563832340,"published V10 exact geography matches retained worker fingerprint")
 check(sim.leyline_bind_world("frontier_v10",77) and sim.leyline_sources().is_empty(),"V10 keeps no coloured acquisition")
 sim.set_world_profile("living_frontier_wave3");sim.leyline_bind_world("living_frontier_wave3",77)
 sim.leyline_work("red_home_margin")
 check(sim.leyline_sources()[0].work==1,"LF live partial work fixture")
 sim.set_world_profile("frontier_v11");sim.leyline_bind_world("frontier_v11",77)
 var reset:=true
 for source: Dictionary in sim.leyline_sources():
  if source.work!=0:reset=false
 check(reset and JSON.parse_string(sim.leyline_save()).profile=="frontier_v11","same seed different profile cannot inherit another source's work")
 var output:=OS.get_environment("WROUGHTWILD_LAND03_OUTPUT")
 FileAccess.open(output.path_join("generation-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records},"\t"))
 print("LAND03_GENERATION ",checks," checks / ",failures," failures")
 get_tree().quit(0 if failures==0 else 1)
