extends "res://tests/rf05/water.gd"
const RECOVERY=preload("res://rf08/context.gd")
var bench:=Vector3.ZERO
var impact_centre:=Vector3.ZERO
var selected: Dictionary
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF08_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("checked-world.json"))
 player.class_panel.choose("warden")
 run_recovery.call_deferred()
func read_bench() -> void:
 var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("scout.json")))
 selected=source.candidates[2]
 var p: Array=selected.at
 var c: Array=selected.centre
 bench=Vector3(p[0],p[1],p[2])
 impact_centre=Vector3(c[0],c[1],c[2])
func set_origins() -> void:
 fixture_origins.clear()
 var base:=Vector2i(floori(bench.x/16)*16,floori(bench.z/16)*16)
 for dz in range(-1,2):
  for dx in range(-1,2):fixture_origins.append(base+Vector2i(dx,dz)*16)
 for origin: Vector2i in fixture_origins:
  if not terrain.chunks.has("%d_%d"%[origin.x,origin.y]):terrain._rebuild_chunk(origin.x,origin.y)
func finish_rf(job: String) -> void:
 player.test_walk=Vector2.ZERO
 var report:={"checks":checks,"failures":failures,"distance_m":route_distance,"captured_frames":captured}
 FileAccess.open(output.path_join(job+"-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF08_",job.to_upper()," ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
func run_recovery() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 quiet()
 read_bench()
 set_origins()
 await tick()
 quiet()
 var cat: CataclysmSites=get_node("CataclysmSites")
 check(world_profile=="frontier_v8" and terrain.reclaimed_cover.recovery!=null,"ordinary New World installs recovery context")
 check(preload("res://art/scenery_resources.gd").ready(),"scenery arrival preparation retained")
 var native:=hash([terrain.map.heights,terrain.map.impacts,terrain.map.leylines,terrain.map.nodes])
 var initial:=snapshot()
 var rows:=poses()
 var old_reservations:=StrangeSites._reservations(terrain)
 var new_reservations:=StrangeSites._reservations(terrain,true)
 var old_impact_points: Array=[]
 for impact: Dictionary in terrain.map.impacts:
  if impact.get("kind","")!="blacksmith_strike":old_impact_points.append(Vector3(impact.x+.5,float(impact.radius_m)*.6,impact.z+.5))
 var preserved:=true
 for key in old_reservations:
  if not key is Vector2i:continue
  for point: Vector3 in old_reservations[key]:
   if point in old_impact_points:continue
   preserved=preserved and point in new_reservations.get(key,[])
 check(preserved,"every resource, ruin, source/clue, approach and smithy reservation remains exact")
 var reclaimed:=0
 var supported:=true
 var intact:=true
 for row in rows:
  var at: Vector3=row.pose.origin
  if Vector2(at.x-impact_centre.x,at.z-impact_centre.z).length()>float(selected.radius)*.6:continue
  reclaimed+=1
  var role:=String(row.part.name).trim_prefix("RF01_")
  var size: float=row.pose.basis.y.length()
  var radius: float=(RF.SETTINGS.fern_width_m if role.begins_with("fern") else RF.SETTINGS.grass_width_m)*.5*size+RF.SETTINGS.fern_height_m*float(R7Cover.settings.wind_bend_per_m)*1.06
  if role.begins_with("rf08-"):radius=(.42 if role=="rf08-shingle" else .34)*size
  supported=supported and terrain.reclaimed_cover.supported_pose(row.chunk.get_meta("surface_sampler"),Vector3(at.x,terrain.height_at(floori(at.x),floori(at.z)),at.z),Basis.IDENTITY,radius,1.0)!=null
  intact=intact and terrain.reclaimed_cover.clear(at,radius)
 check(reclaimed>5 and supported and intact,"living cover enters old blanket while supported and outside protected footprints")
 var fragment_clear:=true
 for piece in cat.pieces:
  if piece.get_meta("asset_id","")!="impact_fragment":continue
  var b: AABB=piece.global_transform*piece.get_node("Visual").mesh.get_aabb()
  for row in rows:
   var at: Vector3=row.pose.origin
   if Rect2(Vector2(b.position.x,b.position.z),Vector2(b.size.x,b.size.z)).grow(.40).has_point(Vector2(at.x,at.z)):fragment_clear=false
 check(fragment_clear,"actual fragment footprints stay clear")
 var test_line: MeshInstance3D
 for trace in cat.traces:
  if trace.get_meta("site_id")==selected.line and trace.mesh!=null:
   if test_line==null or trace.mesh.get_aabb().get_center().distance_to(bench)<test_line.mesh.get_aabb().get_center().distance_to(bench):test_line=trace
 check(test_line!=null,"real selected native exposed stretch has grounded physical mesh")
 if test_line==null:return finish_rf("placement")
 var original_record: Dictionary=test_line.get_meta("record")
 var trial:=MeshInstance3D.new()
 var builder:=LeylineFissures.new()
 var native_states: PackedByteArray=original_record.exposure.duplicate()
 for state in [0,1]:
  var record:=original_record.duplicate(true)
  var states: PackedByteArray=record.exposure
  states.fill(state)
  record.exposure=states
  trial.set_meta("record",record)
  builder.rebuild(trial,terrain,{})
  check(trial.mesh==null,"native exposure %d excludes all physical and luminous geometry"%state)
 trial.free()
 check(original_record.exposure==native_states,"exposure probes never mutate native record")
 check(cat._fissures.look==preload("res://rf08/fissure.tres") and LeylineFissures.LOOK.light_period_seconds==47.0,"eligible pulse leaves old shared defaults unchanged")
 check(not RECOVERY.eligible("frontier_v5") and RECOVERY.eligible("frontier_v6") and RECOVERY.eligible("frontier_v7") and RECOVERY.eligible("living_frontier_wave1") and RECOVERY.eligible("living_frontier_wave3"),"profile boundary spot check")
 var other=RECOVERY.new(terrain.map,78,world_profile)
 var repeat=RECOVERY.new(terrain.map,77,world_profile)
 check(repeat.pixels==terrain.reclaimed_cover.recovery.pixels and other.pixels!=repeat.pixels,"same context deterministic and second seed varies recovery")
 for origin: Vector2i in fixture_origins:terrain._release_chunk(origin)
 for origin: Vector2i in fixture_origins:terrain._rebuild_chunk(origin.x,origin.y)
 await tick()
 quiet()
 check(snapshot()==initial,"chunk retirement/rebuild restores exact treatment")
 # Excavate an actual rendered scar vertex in this place; no invented trace.
 var vertices: PackedVector3Array=test_line.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
 var v: Vector3=vertices[vertices.size()/2]
 var dug:=Vector3i(floori(v.x),terrain.height_at(floori(v.x),floori(v.z))-1,floori(v.z))
 var kind:=terrain.kind_at(dug.x,dug.y,dug.z)
 terrain.heat_block(dug,terrain.heat_to_crack(kind))
 terrain.crack_block(dug)
 check(terrain.break_block(dug.x,dug.y,dug.z)!="","real local dig removes scar/plant support")
 cat.refresh_area(dug.x,dug.z,1)
 await tick()
 quiet()
 var lid:=false
 for row in poses():
  if floori(row.pose.origin.x)==dug.x and floori(row.pose.origin.z)==dug.z:lid=true
 check(not lid,"no vegetation lid over excavation")
 var bridge:=false
 for trace in cat.traces:
  if trace.mesh==null:continue
  for point: Vector3 in trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
   if floori(point.x)==dug.x and floori(point.z)==dug.z and point.y>dug.y+.85:bridge=true
 check(not bridge,"no suspended scar across the removed native surface")
 terrain.apply_broken_blocks([])
 terrain.apply_cracked([])
 cat.refresh_area(dug.x,dug.z,1)
 await tick()
 quiet()
 check(snapshot()==initial,"restored local support reproduces cover")
 await _gather()
 quiet()
 set_origins()
 rows=poses()
 rows.sort_custom(func(a,b):return a.pose.origin.distance_squared_to(bench)<b.pose.origin.distance_squared_to(bench))
 var target:=_flat_clear_target(rows,0)
 check(target.x>=0 and Vector3(target).distance_to(bench)<24,"ordinary nearby supported ground fits a paid floor")
 if target.x<0:return finish_rf("placement")
 player.position=Vector3(target)+Vector3(0,1.1,4)
 var wood:=_sim().material_count("wood")
 for x in range(-1,2):
  for z in range(-1,2):
   var corner:=absi(x)==1 and absi(z)==1
   var turn:=0 if x<0 and z<0 else 1 if x<0 else 2 if z>0 else 3
   check(place(&"codex_corner_floor" if corner else &"floor_slab",target+Vector3i(x,0,z),turn),"paid octagonal floor component")
 await tick()
 quiet()
 check(_sim().material_count("wood")==wood-9 and hidden_count()>0,"exact floor payment and intersecting cover suppression")
 player.work_panel.open_hand_crafting()
 var catalogue=player.work_panel.catalogue
 catalogue.select_recipe("workbench_kit")
 catalogue.quantity=1
 catalogue._render_detail()
 catalogue._action.pressed.emit()
 player.work_panel.close_panel()
 var station_at:=_flat_clear_target(rows,5,Vector3(target))
 check(station_at.x>=0,"ordinary station space beside recovery")
 if station_at.x<0:return finish_rf("placement")
 check(place(&"workbench_kit",station_at,1,true),"paid workbench placed normally")
 await tick()
 quiet()
 var station: StationSite
 for node in get_tree().get_nodes_in_group("crafting_stations"):
  if node.player_built:station=node
 check(station!=null and _sim().material_count("workbench_kit")==0,"physical station owns consumed kit")
 station.interact(player)
 check(player.work_panel.is_open(),"normal paid station usable")
 player.work_panel.close_panel()
 var clean:=true
 var bounds:=RF.station_bounds(station)
 for row in poses():
  if not (row.pose*row.part.get_meta("clearance_bounds")).intersects(bounds):continue
  var transforms: Array=row.part.get_meta("world_transforms")
  clean=clean and bool(row.part.get_meta("hidden_by_building")[transforms.find(row.pose)])
 check(clean,"actual station footprint clears new cover")
 var partial:=false
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
 check(partial,"partial finite work retained")
 ready_at(bench+Vector3(5,1.1,3))
 for i in 20:await tick()
 quiet()
 set_origins()
 StrangeSites.refresh_buildings(self,terrain)
 check(hash([terrain.map.heights,terrain.map.impacts,terrain.map.leylines,terrain.map.nodes])==native,"native terrain, impact, trace/exposure and source identities unchanged")
 check(SaveManager.new().write(output.path_join("checked-world.json"),player),"private save with paid possessions, structures and finite work")
 var expected:={"bench":[bench.x,bench.y,bench.z],"target":[target.x,target.y,target.z],"station":[station_at.x,station_at.y,station_at.z],"height_digest":hash(terrain.map.heights),"water_digest":hash(terrain.map.lakes),"native_digest":native,"cover_digest":hash(snapshot()),"hidden":hidden_count(),"reclaimed_inside_old_blanket":reclaimed}
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify(expected,"\t"))
 finish_rf("placement")
