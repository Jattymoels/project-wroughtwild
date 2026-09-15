extends "res://tests/rf01/placement.gd"
## Acquisition/placement are harness-paced; finite harvesting, costs, ownership,
## collision, station use and save handling are the ordinary game paths.
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF03_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 player.class_panel.choose("warden")
 _run.call_deferred()

func select_home() -> Dictionary:
 var home: Dictionary=terrain.map.home_sites[1]
 fixture_origins.clear()
 for z in range(floori((home.z-24.0)/16)*16,floori((home.z+24.0)/16)*16+1,16):
  for x in range(floori((home.x-24.0)/16)*16,floori((home.x+24.0)/16)*16+1,16): fixture_origins.append(Vector2i(x,z))
 return home

func _run() -> void:
 while not seed_controls.finished: await get_tree().process_frame
 quiet()
 check(world_profile=="frontier_v7" and world_seed==77,"ordinary seed/class flow chooses V7")
 check(terrain.chunk_stream!=null and terrain.resource_stream!=null and mob_packs._indexed,"V7 uses wide-world streaming")
 check(terrain.reclaimed_cover!=null and terrain._rf02_biome_mask!=null,"V7 uses adopted RF01/RF02 art")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"mouse remains free")
 var home:=select_home()
 terrain.ensure_area(Vector3(home.x,home.y,home.z),40)
 await get_tree().physics_frame
 quiet()
 await _gather()
 quiet()
 var rows: Array[Dictionary]=[]
 for row in poses():
  var at: Vector3=row.pose.origin
  if Vector2(at.x-home.x,at.z-home.z).length()<10: rows.append(row)
 check(not rows.is_empty(),"natural grass continues across the usable home core")
 var target:=_flat_clear_target(rows,0)
 if not check(target.x>=0,"home has a real clear paid footprint"): return finish()
 player.position=Vector3(target)+Vector3(5,1.1,5)
 var wood: int=_sim().material_count("wood")
 for dz in range(-1,2):
  for dx in range(-1,2):
   var corner: bool=abs(dx)==1 and abs(dz)==1
   var shape: StringName=&"codex_corner_floor" if corner else &"floor_slab"
   var turn:=0 if dx<0 and dz<0 else 1 if dx<0 else 2 if dz>0 else 3
   check(place(shape,target+Vector3i(dx,0,dz),turn),"paid ordinary octagonal floor")
 await get_tree().process_frame
 quiet()
 check(_sim().material_count("wood")==wood-9 and _sim().structure_piece_count()==9,"nine floor parts cost exactly nine wood")
 check(hidden_count()>0,"paid footprint hides overlapping grass")
 player.work_panel.open_hand_crafting()
 var catalogue=player.work_panel.catalogue
 catalogue.select_recipe("workbench_kit")
 catalogue.quantity=1
 catalogue._render_detail()
 check(not catalogue._action.disabled,"ordinary hand crafting offers the funded workbench")
 catalogue._action.pressed.emit()
 player.work_panel.close_panel()
 check(_sim().material_count("workbench_kit")==1,"one paid workbench kit crafted")
 var station_target:=_flat_clear_target(rows,5,Vector3(target))
 if not check(station_target.x>=0,"home has room for a separate workshop area"): return finish()
 check(place(&"workbench_kit",station_target,1,true),"paid workbench fits and consumes its kit")
 await get_tree().process_frame
 quiet()
 var station: StationSite
 for node in get_tree().get_nodes_in_group("crafting_stations"):
  if node.player_built: station=node
 check(station!=null and _sim().material_count("workbench_kit")==0,"exactly one placed station owner")
 if station!=null:
  station.interact(player)
  check(player.work_panel.is_open(),"ordinary workbench interaction is usable")
  player.work_panel.close_panel()
 var local:=snapshot()
 StrangeSites.refresh_buildings(self,terrain)
 check(snapshot()==local,"local paid clearance matches complete refresh")
 player.position=Vector3(target)+Vector3(.5,1.2,.5)
 player.velocity=Vector3.ZERO
 player.rotation.y=0
 player.set_physics_process(true)
 for i in 30: await get_tree().physics_frame
 check(player.is_on_floor(),"real capsule is supported on the paid floor")
 var start:=player.position
 player.test_walk=Vector2(0,-1)
 for i in 16: await get_tree().physics_frame
 player.test_walk=Vector2.ZERO
 check(player.position.distance_to(start)>.6,"real capsule walks across the built home footprint")
 quiet()
 var dug:=Vector3i(-1,-1,-1)
 for row in poses():
  var at: Vector3=row.pose.origin
  if at.distance_to(Vector3(target))<8 or at.distance_to(Vector3(station_target))<5: continue
  dug=Vector3i(floori(at.x),terrain.height_at(floori(at.x),floori(at.z))-1,floori(at.z))
  break
 if check(dug.x>=0,"one nearby planted soil cell is available"):
  check(terrain.break_block(dug.x,dug.y,dug.z)!="","local digging remains available")
  await get_tree().process_frame
  quiet()
  var lingering:=false
  for row in poses():
   if floori(row.pose.origin.x)==dug.x and floori(row.pose.origin.z)==dug.z: lingering=true
  check(not lingering and terrain.block_at(dug.x,dug.y,dug.z)==0,"digging clears grass and actual terrain")
 player.position=Vector3(target)+Vector3(.5,1.2,.5)
 player.velocity=Vector3.ZERO
 check(SaveManager.new().write(output.path_join("private-world.json"),player),"private paid V7 save written")
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify({"home":home.id,"target":[target.x,target.y,target.z],"station":[station_target.x,station_target.y,station_target.z],"dug":[dug.x,dug.y,dug.z],"height_digest":hash(terrain.map.heights)},"\t"))
 finish()

func finish() -> void:
 var report:={"checks":checks,"failures":failures,"profile":world_profile,"seed":world_seed,"scope":"One paid octagonal footprint and ordinary workbench; actual finite harvesting, capsule support/movement, local dig, CPU clearance and private save."}
 FileAccess.open(output.path_join("build-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF03_BUILD ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
