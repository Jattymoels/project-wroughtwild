extends Node
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL RF05 ",label)
func _ready() -> void:
 var sim: WroughtwildSim=load("res://scripts/sim.gd").shared()
 var output:=OS.get_environment("WROUGHTWILD_RF05_OUTPUT")
 var records:=[]
 for seed_value in [77,78]:
  check(sim.set_world_profile("frontier_v8"),"V8 selects")
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
  var digest:=hash(map.blocks)
  var fresh:=WroughtwildSim.new()
  check(fresh.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()) and fresh.set_world_profile("frontier_v8"),"independent generation inputs load")
  var second: Dictionary=fresh.world_map(seed_value)
  check(digest==hash(second.blocks) and lake==second.lakes[0],"same identity repeats geometry and lake metadata")
  records.append({"seed":seed_value,"lake_x":lake.x,"lake_z":lake.z,"surface":lake.surface_y,"home":lake.home_id,"radius":lake.radius_m,"wet_cells":wet_cells,"shallow_cells":shallow,"blocks_hash":digest})
 check(records.size()==2 and records[0].lake_x!=records[1].lake_x,"seed variation changes lake siting")
 FileAccess.open(output.path_join("generation-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"records":records},"\t"))
 print("RF05_GENERATION ",checks," checks / ",failures," failures ",records)
 get_tree().quit(0 if failures==0 else 1)
