extends Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL LAND02 ",label)
func _ready() -> void:
 var sim: WroughtwildSim=load("res://scripts/sim.gd").shared()
 var output:=OS.get_environment("WROUGHTWILD_LAND02_OUTPUT")
 var records:=[]
 for seed_value in [77,78]:
  check(sim.set_world_profile("frontier_v9"),"V8 selects")
  var map: Dictionary=sim.world_map(seed_value)
  if map.is_empty():check(false,sim.last_error());break
  check(map.lakes.size()==1 and map.home_sites.size()==4,"one lake, four home cores")
  var lake: Dictionary=map.lakes[0]
  var wet_cells:=0
  var shallow:=0
  for z in range(int(lake.min_z),int(lake.min_z)+int(lake.height)):
   for x in range(int(lake.min_x),int(lake.min_x)+int(lake.width)):
    var wet:=LakeWater.column(map,x,z)
    if wet.is_empty():continue
    wet_cells+=1
    if wet.depth<1.1:shallow+=1
    if int(map.heights[z*int(map.width)+x])!=int(wet.bed):check(false,"original bed matches native height")
  check(wet_cells>1000 and shallow>80,"substantial basin and shallow margins")
  check(LakeWater.column(map,lake.x,lake.z).depth>=3.4,"deep centre")
  var homes_dry:=true
  for home: Dictionary in map.home_sites:
   for dz in range(-14,15):
    for dx in range(-14,15):
     if dx*dx+dz*dz>196:continue
     if int(map.heights[(int(home.z)+dz)*int(map.width)+int(home.x)+dx])!=int(home.y):homes_dry=false
     if not LakeWater.column(map,int(home.x)+dx,int(home.z)+dz).is_empty():homes_dry=false
   for p: Vector3 in home.approach:
    if not LakeWater.column(map,p.x,p.z).is_empty():homes_dry=false
  check(homes_dry,"four level radius-14 cores and dry approaches")
  var placement_dry:=true
  for n: Dictionary in map.nodes:
   var wet:=LakeWater.column(map,float(n.x),float(n.z))
   if not wet.is_empty() and float(n.y)>=float(wet.bed):
    placement_dry=false
    print("WET_CONTENT ",seed_value," ",n," ",wet)
  for n: Dictionary in map.packs:
   var wet:=LakeWater.column(map,float(n.x),float(n.z))
   if not wet.is_empty() and float(n.y)>=float(wet.bed):
    placement_dry=false
    print("WET_CONTENT ",seed_value," ",n," ",wet)
  check(placement_dry,"terrestrial resources and packs ashore")
  var routes_dry:=true
  for collection in ["rare_sites","regions","habitats","ruins","pressure_pockets"]:
   for row: Dictionary in map.get(collection,[]):
    for p: Vector3 in row.get("approach",[]):
     if not LakeWater.column(map,p.x,p.z).is_empty():routes_dry=false
  check(routes_dry,"progression/discovery approaches remain on land")
  check(map.scarwater.size()==1,"one complete impulse composition")
  var place: Dictionary=map.scarwater[0]
  check(place.channel=="impulse" and place.host=="layered_rock_and_gallery_roots","typed force and host")
  check(map.regions.size()==3 and map.rare_sites.size()==14,"three discovery regions and unchanged fourteen placements of five rare families")
  var families: Dictionary={}
  for site: Dictionary in map.rare_sites:families[site.get("kind",site.get("type",""))]=true
  var route_ok:=true
  for key: String in ["sheltered_route","outlook_route"]:
   var route: PackedVector3Array=place[key]
   if route.size()<50:route_ok=false
   for i in route.size():
    var at: Vector3=route[i]
    if not LakeWater.column(map,at.x,at.z).is_empty():route_ok=false
    if i>0 and absf(at.y-route[i-1].y)>1.01:route_ok=false
  check(route_ok,"both distinct bank routes remain dry with native one-cell traversal")
  var scar: Vector3=place.scar
  var direction: Vector3=place.direction
  var edge:=scar-direction*5
  var edge_h:=int(map.heights[floori(edge.z)*int(map.width)+floori(edge.x)])
  check(edge_h-scar.y>=3 and LakeWater.column(map,scar.x,scar.z).is_empty(),"native dry recess retains at least three metres of depth")
  check(place.grove_home_id!=place.outlook_home_id,"two distinct existing homes serve grove and lake outlook")
  check(map.pressure_pockets.size()==1 and place.pressure_id==map.pressure_pockets[0].id,"one existing accidental pressure identity")
  check(sim.contraption_bind_world("frontier_v9",seed_value),"V9 binds ordinary pressure owner")
  check(sim.contraption_pressure_sources().size()==1 and sim.contraption_pressure_sources()[0].remaining==24,"ordinary finite stock only")
  check(sim.leyline_bind_world("frontier_v9",seed_value) and sim.leyline_sources().is_empty(),"no LF coloured source adoption")
  var digest:=hash(map.blocks)
  var fresh:=WroughtwildSim.new()
  check(fresh.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()) and fresh.set_world_profile("frontier_v9"),"independent generation inputs load")
  var second: Dictionary=fresh.world_map(seed_value)
  check(digest==hash(second.blocks) and lake==second.lakes[0] and place==second.scarwater[0],"same identity repeats geometry and lake metadata")
  records.append({"seed":seed_value,"lake_x":lake.x,"lake_z":lake.z,"surface":lake.surface_y,"home":lake.home_id,"radius":lake.radius_m,"wet_cells":wet_cells,"shallow_cells":shallow,"blocks_hash":digest,"height_hash":hash(map.heights),"place_hash":hash(place),"lake_aspect":lake.aspect,"ridge_length":place.ridge_half_length_m*2,"ridge_width":place.ridge_width_m,"ridge_arc":place.ridge_arc_m,"scar":str(scar),"fallback":place.fallback})
 check(records.size()==2 and records[0].lake_x!=records[1].lake_x and records[0].ridge_width!=records[1].ridge_width and records[0].ridge_length!=records[1].ridge_length,"seed changes siting, ridge proportions and arc, beyond rotation")
 FileAccess.open(output.path_join("generation-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records},"\t"))
 print("LAND02_GENERATION ",checks," checks / ",failures," failures ",records)
 get_tree().quit(0 if failures==0 else 1)
