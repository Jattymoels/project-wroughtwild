extends "res://tests/rf05/water.gd"
const WET = preload("res://rf06/cover.gd")
var fen_point := Vector3.ZERO
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF06B_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("checked-world.json"))
 player.class_panel.choose("warden")
 run_fen.call_deferred()

func find_fen() -> Vector3:
 var best := INF
 var result := Vector3.ZERO
 for z in range(8,int(terrain.map.height)-8,8):
  for x in range(8,int(terrain.map.width)-8,8):
   var i := z*int(terrain.map.width)+x
   if terrain.map.biome_defs[terrain.map.biomes[i]].id!="fen": continue
   var at := Vector3(x+.5,terrain.map.heights[i],z+.5)
   if not terrain.reclaimed_cover.clear(at,4): continue
   var level := true
   for d in [Vector2i(-3,-3),Vector2i(3,3),Vector2i(-3,3),Vector2i(3,-3)]:
    level=level and absf(terrain.map.heights[(z+d.y)*int(terrain.map.width)+x+d.x]-at.y)<.6
   var distance := at.distance_squared_to(Vector3(home.x,home.y,home.z))
   if level and distance<best: best=distance;result=at
 return result

func wet_rows() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for row in poses():
  if row.part.has_meta("rf06_cover"): result.append(row)
 return result

func set_origins() -> void:
 fixture_origins.clear()
 for point in [Vector3(lake.x,0,lake.z),fen_point]:
  var base := Vector2i(floori(point.x/16)*16,floori(point.z/16)*16)
  for dz in range(-1,2):
   for dx in range(-1,2): fixture_origins.append(base+Vector2i(dx,dz)*16)
 # Pin only these fixture chunks without moving the ordinary retirement focus.
 for origin: Vector2i in fixture_origins:
  if not terrain.chunks.has("%d_%d"%[origin.x,origin.y]): terrain._rebuild_chunk(origin.x,origin.y)

func run_fen() -> void:
 while not seed_controls.finished: await get_tree().process_frame
 quiet()
 setup_lake()
 fen_point=find_fen()
 check(fen_point!=Vector3.ZERO,"one existing fen setting located")
 set_origins()
 await tick()
 quiet()
 check(terrain.wetland_cover!=null,"normal V8 New World installs fen and dry-bank treatment")
 var initial := snapshot()
 var plants := wet_rows()
 check(plants.size()>20,"actual supported fen and lake bank plants exist")
 var fen_count := 0
 var shore_count := 0
 var root_ok := true
 var dry_ok := true
 var widest := 0.0
 var full_support := true
 for row in plants:
  var at: Vector3=row.pose.origin
  var i := floori(at.z)*int(terrain.map.width)+floori(at.x)
  var biome: String=terrain.map.biome_defs[terrain.map.biomes[i]].id
  if biome=="fen": fen_count+=1
  else: shore_count+=1
  root_ok=root_ok and terrain.reclaimed_cover.clear(at,.24)
  dry_ok=dry_ok and LakeWater.column(terrain.map,at.x,at.z).is_empty()
  var radius: float=row.part.multimesh.mesh.get_meta("rf06b_radius")*row.pose.basis.y.length()
  widest=maxf(widest,radius*2)
  var sampler: SurfaceSampler=row.chunk.get_meta("surface_sampler")
  var base:=Vector3(at.x,terrain.map.heights[i],at.z)
  full_support=full_support and terrain.wetland_cover.supported_footprint(sampler,base,Basis.IDENTITY,radius,1.0)!=null
 check(widest>1.5 and full_support,"actual larger footprints have complete surface support")
 check(fen_count>0 and shore_count>0,"both real fen and actual lake margins represented")
 check(root_ok and dry_ok,"native approaches remain clear and all new roots are dry")
 check(not terrain.wetland_cover.owns(Vector3(10,0,10),"rocky_hills","grass"),"no highland spill")
 var heights := hash(terrain.map.heights)
 var water := hash(terrain.map.lakes)
 for origin: Vector2i in fixture_origins: terrain._release_chunk(origin)
 for origin: Vector2i in fixture_origins: terrain._rebuild_chunk(origin.x,origin.y)
 await tick()
 quiet()
 check(snapshot()==initial,"retired chunks reproduce exact transforms")
 plants=wet_rows()
 if plants.is_empty():return finish_rf("placement")
 # Excavate below the outer part of a broad patch, not just its root.
 var selected: Dictionary=plants[0]
 for row in plants:
  if float(row.part.multimesh.mesh.get_meta("rf06b_radius"))*row.pose.basis.y.length()>.72:selected=row;break
 var root: Vector3=selected.pose.origin
 var selected_radius: float=selected.part.multimesh.mesh.get_meta("rf06b_radius")*selected.pose.basis.y.length()
 var root_cell:=Vector2i(floori(root.x),floori(root.z))
 var dig_x:=floori(root.x+selected_radius*.8)
 if dig_x==root_cell.x:dig_x=floori(root.x-selected_radius*.8)
 var dug := Vector3i(dig_x,terrain.height_at(dig_x,floori(root.z))-1,floori(root.z))
 check(terrain.break_block(dug.x,dug.y,dug.z)!="","ordinary excavation removes selected support")
 await tick()
 quiet()
 var hanging := false
 for row in wet_rows():
  var p: Vector3=row.pose.origin
  if p.distance_to(root)<.001:
   var remaining_radius: float=row.part.multimesh.mesh.get_meta("rf06b_radius")*row.pose.basis.y.length()
   # A small fringe may replace the broad form only if its own full support passes.
   var sampler: SurfaceSampler=row.chunk.get_meta("surface_sampler")
   hanging=terrain.wetland_cover.supported_footprint(sampler,Vector3(p.x,terrain.height_at(floori(p.x),floori(p.z)),p.z),Basis.IDENTITY,remaining_radius,1.0)==null
 check(dug.x!=root_cell.x and not hanging,"outer-footprint excavation cannot leave unsupported broad leaves")
 terrain.apply_broken_blocks([])
 await tick()
 quiet()
 check(snapshot()==initial,"restored terrain gives identical cosmetic placement")
 await _gather()
 quiet()
 set_origins()
 var target := _flat_clear_target(wet_rows(),0)
 check(target.x>=0,"affected covered terrain supports a paid floor")
 if target.x<0:return finish_rf("placement")
 var wood := _sim().material_count("wood")
 player.position=Vector3(target)+Vector3(0,1.1,4)
 for dx in range(-1,2):
  for dz in range(-1,2):
   var corner := absi(dx)==1 and absi(dz)==1
   var turn := 0 if dx<0 and dz<0 else 1 if dx<0 else 2 if dz>0 else 3
   check(place(&"codex_corner_floor" if corner else &"floor_slab",target+Vector3i(dx,0,dz),turn),"paid octagonal floor component")
 await tick()
 quiet()
 check(_sim().material_count("wood")==wood-9 and hidden_count()>0,"floor paid exactly and overlapping plants hidden")
 player.work_panel.open_hand_crafting()
 var catalogue = player.work_panel.catalogue
 catalogue.select_recipe("workbench_kit")
 catalogue.quantity=1
 catalogue._render_detail()
 catalogue._action.pressed.emit()
 player.work_panel.close_panel()
 var station_at := _flat_clear_target(wet_rows(),6,Vector3(target))
 check(station_at.x>=0,"another affected root fits station")
 if station_at.x<0:return finish_rf("placement")
 check(place(&"workbench_kit",station_at,1,true),"paid workbench kit consumed at affected ground")
 await tick()
 quiet()
 var station: StationSite
 for node in get_tree().get_nodes_in_group("crafting_stations"):
  if node.player_built:station=node
 check(station!=null and _sim().material_count("workbench_kit")==0,"one physical station owns the paid kit")
 if station!=null:
  station.interact(player)
  check(player.work_panel.is_open(),"paid station remains usable")
  player.work_panel.close_panel()
 # Preserve a real partially worked finite source in the Continue fixture.
 var partial := false
 for id in terrain.resource_stream.records:
  var record: Dictionary=terrain.resource_stream.records[id]
  if record.family!="wood" or int(record.remaining_units)<12:continue
  var node: ResourceNode=terrain.resource_stream.materialise(id)
  var result:=node.work(_sim())
  if result.has("refusal"):continue
  player._apply_work(node,result)
  terrain.resource_stream.capture()
  partial=int(terrain.resource_stream.records[id].remaining_units)>0
  break
 check(partial,"partially worked finite source retained")
 # One cheap second-seed distribution check. Native map/geography is untouched.
 var original_seed: int=terrain.wetland_cover.noise.seed
 var preview_seed:=int(hash("78/frontier_v8/rf06") & 0x7fffffff)
 var same:=true
 var differs:=false
 for point in [Vector2(336.5,680.5),Vector2(343.5,676.5),Vector2(555.5,653.5)]:
  var original: float=terrain.wetland_cover.patch_at(point.x,point.y)
  terrain.wetland_cover.noise.seed=preview_seed
  var a: float=terrain.wetland_cover.patch_at(point.x,point.y)
  var b: float=terrain.wetland_cover.patch_at(point.x,point.y)
  same=same and a==b
  differs=differs or a!=original
  terrain.wetland_cover.noise.seed=original_seed
 check(same and differs,"second seed changes grouping reproducibly without any scenery-coordinate override")
 ready_at(Vector3(home.x+.5,home.y+1.1,home.z+.5)-axis*4)
 player.rotation.y=atan2(-axis.x,-axis.z)
 for i in 20:await tick()
 quiet()
 set_origins()
 StrangeSites.refresh_buildings(self,terrain)
 check(hash(terrain.map.heights)==heights and hash(terrain.map.lakes)==water,"planting/building preserves native heights and lake records")
 check(SaveManager.new().write(output.path_join("checked-world.json"),player),"private existing-world checkpoint written")
 var expected := {"fen":[fen_point.x,fen_point.y,fen_point.z],"height_digest":heights,"water_digest":water,"cover_digest":hash(snapshot()),"hidden":hidden_count(),"fen_plants":fen_count,"shore_plants":shore_count,"target":[target.x,target.y,target.z],"station":[station_at.x,station_at.y,station_at.z]}
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify(expected,"\t"))
 # One non-lake native V6 context, without building a second playable world.
 check(_sim().set_world_profile("frontier_v6"),"existing V6 profile accepted")
 var old_map: Dictionary=_sim().world_map(77)
 check(old_map.get("lakes",[]).is_empty(),"existing non-lake fen profile gains no generated water")
 var old := Terrain.new()
 old.map=old_map
 old._seed=77
 old._world_profile="frontier_v6"
 var old_support = preload("res://rf01/cover.gd").new(old_map,77,"frontier_v6",{})
 var old_wet = WET.new(old,old_support)
 check(old_wet.shore.is_empty() and old_wet.zone(0,0,"fen")==1.0,"non-lake fen treatment derives without water or shore invention")
 old.free()
 _sim().set_world_profile("frontier_v8")
 finish_rf("placement")

func finish_rf(job: String) -> void:
 player.test_walk=Vector2.ZERO
 var report := {"checks":checks,"failures":failures,"swim_frames":swim_frames,"wade_frames":wade_frames,"distance_m":route_distance,"captured_frames":captured}
 FileAccess.open(output.path_join(job+"-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF06B_",job.to_upper()," ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
