extends "res://tests/rf05/water.gd"
const HIGHLAND=preload("res://rf07/cover.gd")
var bench:=Vector3.ZERO
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF07_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("checked-world.json"))
 player.class_panel.choose("warden")
 run_highland.call_deferred()
func set_origins() -> void:
 fixture_origins.clear()
 var base:=Vector2i(floori(bench.x/16)*16,floori(bench.z/16)*16)
 for dz in range(-1,2):
  for dx in range(-1,2):fixture_origins.append(base+Vector2i(dx,dz)*16)
 for origin: Vector2i in fixture_origins:
  if not terrain.chunks.has("%d_%d"%[origin.x,origin.y]):terrain._rebuild_chunk(origin.x,origin.y)
func highland_rows() -> Array[Dictionary]:
 var result: Array[Dictionary]=[]
 for row in poses():
  if row.part.has_meta("rf07_cover"):result.append(row)
 return result
func read_bench() -> void:
 var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("scout.json")))
 var p: Array=source.candidates[0].at
 bench=Vector3(p[0],p[1],p[2])
func run_highland() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 quiet()
 read_bench()
 set_origins()
 await tick()
 quiet()
 check(world_profile=="frontier_v8" and terrain.highland_cover!=null,"ordinary New World prepares highland resources and context")
 check(preload("res://art/scenery_resources.gd").ready(),"adopted scenery preparation remains installed")
 var initial:=snapshot()
 var rows:=highland_rows()
 check(rows.size()>50,"representative ordinary highland has recovery growth")
 var support_ok:=true
 var boundaries:=true
 var widths:=0.0
 var counts: Dictionary={}
 for row in rows:
  var at: Vector3=row.pose.origin
  var radius: float=row.part.multimesh.mesh.get_meta("rf07_radius")*row.pose.basis.y.length()
  widths=maxf(widths,radius*2)
  var role:=String(row.part.name)
  counts[role]=int(counts.get(role,0))+1
  var sampler: SurfaceSampler=row.chunk.get_meta("surface_sampler")
  support_ok=support_ok and terrain.highland_cover.supported_footprint(sampler,Vector3(at.x,terrain.height_at(floori(at.x),floori(at.z)),at.z),Basis.IDENTITY,radius,1.0)!=null
  boundaries=boundaries and terrain.highland_cover.biome_at(floori(at.x),floori(at.z))=="rocky_hills" and terrain.reclaimed_cover.clear(at,radius)
 check(widths>1.2 and support_ok,"full broad footprints have actual complete triangle support")
 check(boundaries,"roots preserve native biome and reserved approaches")
 check(counts.has("RF07_heath") and counts.has("RF07_tussock") and int(counts.get("RF07_shingle",0))>=8,"scrub, tough grass and parent-linked debris represented")
 var low:=false
 for i in terrain.map.heights.size():
  if terrain.map.heights[i]<53 and terrain.map.biome_defs[terrain.map.biomes[i]].id=="rocky_hills":
   low=terrain.highland_cover.context[i*4]==255
   break
 check(low,"region-forced highlands below height threshold receive the same context")
 check(not HIGHLAND.eligible("frontier_v5","rocky_hills","rock") and not HIGHLAND.eligible("frontier_v8","fen","rock") and not HIGHLAND.eligible("frontier_v8","forest","grass") and not HIGHLAND.eligible("frontier_v8","ember_wastes","rock"),"historical and unrelated biome eligibility remains excluded")
 check(HIGHLAND.eligible("frontier_v6","rocky_hills","rock") and HIGHLAND.eligible("frontier_v7","rocky_hills","grass") and HIGHLAND.eligible("living_frontier_wave1","rocky_hills","rock") and HIGHLAND.eligible("living_frontier_wave3","rocky_hills","rock"),"existing V6/V7/LF identity paths are eligible without new profiles")
 var heights:=hash(terrain.map.heights)
 var water:=hash(terrain.map.lakes)
 for origin: Vector2i in fixture_origins:terrain._release_chunk(origin)
 for origin: Vector2i in fixture_origins:terrain._rebuild_chunk(origin.x,origin.y)
 await tick()
 quiet()
 check(snapshot()==initial,"retirement/rebuild reproduces exact cosmetic transforms")
 rows=highland_rows()
 var selected: Dictionary=rows[0]
 for row in rows:
  if float(row.part.multimesh.mesh.get_meta("rf07_radius"))*row.pose.basis.y.length()>.68:selected=row;break
 var root: Vector3=selected.pose.origin
 var radius: float=selected.part.multimesh.mesh.get_meta("rf07_radius")*selected.pose.basis.y.length()
 var dx:=floori(root.x+radius*.9)
 if dx==floori(root.x):dx=floori(root.x-radius*.9)
 var dug:=Vector3i(dx,terrain.height_at(dx,floori(root.z))-1,floori(root.z))
 var kind:=terrain.kind_at(dug.x,dug.y,dug.z)
 terrain.heat_block(dug,terrain.heat_to_crack(kind))
 terrain.crack_block(dug)
 check(terrain.break_block(dug.x,dug.y,dug.z)!="","existing heat/crack/dig removes outer support")
 await tick()
 quiet()
 var safe:=true
 for row in highland_rows():
  if row.pose.origin.distance_to(root)>.001:continue
  var remaining: float=row.part.multimesh.mesh.get_meta("rf07_radius")*row.pose.basis.y.length()
  safe=safe and terrain.highland_cover.supported_footprint(row.chunk.get_meta("surface_sampler"),Vector3(root.x,terrain.height_at(floori(root.x),floori(root.z)),root.z),Basis.IDENTITY,remaining,1.0)!=null
 check(dx!=floori(root.x) and safe,"outer excavation cannot leave unsupported cover or conceal a hole")
 terrain.apply_broken_blocks([])
 terrain.apply_cracked([])
 await tick()
 quiet()
 check(snapshot()==initial,"restoring support restores exact treatment")
 await _gather()
 quiet()
 set_origins()
 rows=highland_rows()
 rows.sort_custom(func(a,b):return a.pose.origin.distance_squared_to(bench)<b.pose.origin.distance_squared_to(bench))
 var target:=_flat_clear_target(rows,0)
 check(target.x>=0 and Vector3(target).distance_to(bench)<12,"selected outlook supports an ordinary paid floor")
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
 check(_sim().material_count("wood")==wood-9 and hidden_count()>0,"floor pays exactly and clears intersecting highland growth")
 player.work_panel.open_hand_crafting()
 var catalogue=player.work_panel.catalogue
 catalogue.select_recipe("workbench_kit")
 catalogue.quantity=1
 catalogue._render_detail()
 catalogue._action.pressed.emit()
 player.work_panel.close_panel()
 var station_at:=_flat_clear_target(rows,5,Vector3(target))
 check(station_at.x>=0 and Vector3(station_at).distance_to(bench)<18,"outlook margin supports a normal station")
 if station_at.x<0:return finish_rf("placement")
 check(place(&"workbench_kit",station_at,1,true),"paid workbench kit placed through ordinary placement")
 await tick()
 quiet()
 var station: StationSite
 for node in get_tree().get_nodes_in_group("crafting_stations"):
  if node.player_built:station=node
 check(station!=null and _sim().material_count("workbench_kit")==0,"one physical station owns the consumed kit")
 if station!=null:
  station.interact(player)
  check(player.work_panel.is_open(),"normal paid station remains usable")
  player.work_panel.close_panel()
  var bounds:=RF.station_bounds(station)
  var clean:=true
  for row in highland_rows():
   var footprint: AABB=row.pose*row.part.get_meta("clearance_bounds")
   if not footprint.intersects(bounds):continue
   var poses: Array=row.part.get_meta("world_transforms")
   clean=clean and bool(row.part.get_meta("hidden_by_building")[poses.find(row.pose)])
  check(clean,"actual station body clears every overlapping new footprint")
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
 check(partial,"partial finite-source work retained in private save")
 var old_seed: int=terrain.highland_cover.noise.seed
 var sample_a: float=terrain.highland_cover.patch_at(bench.x,bench.z)
 terrain.highland_cover.noise.seed=int(hash("78/frontier_v8/rf07") & 0x7fffffff)
 var sample_b: float=terrain.highland_cover.patch_at(bench.x,bench.z)
 check(sample_b==terrain.highland_cover.patch_at(bench.x,bench.z) and sample_a!=sample_b,"cheap second-seed spot changes grouping reproducibly")
 terrain.highland_cover.noise.seed=old_seed
 # A private player pose only; scenery always derives from the loaded map.
 ready_at(bench+Vector3(0,1.1,0))
 player.rotation.y=-PI*.5
 player.spring_arm.rotation.x=-.12
 for i in 20:await tick()
 quiet()
 set_origins()
 StrangeSites.refresh_buildings(self,terrain)
 check(hash(terrain.map.heights)==heights and hash(terrain.map.lakes)==water,"native terrain and lake records unchanged")
 check(SaveManager.new().write(output.path_join("checked-world.json"),player),"private save with paid outlook and finite work")
 var expected:={"bench":[bench.x,bench.y,bench.z],"target":[target.x,target.y,target.z],"station":[station_at.x,station_at.y,station_at.z],"height_digest":heights,"water_digest":water,"cover_digest":hash(snapshot()),"hidden":hidden_count(),"counts":counts,"widest_m":widths}
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify(expected,"\t"))
 finish_rf("placement")
func finish_rf(job: String) -> void:
 player.test_walk=Vector2.ZERO
 var report:={"checks":checks,"failures":failures,"distance_m":route_distance,"captured_frames":captured}
 FileAccess.open(output.path_join(job+"-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF07_",job.to_upper()," ",JSON.stringify(report))
 get_tree().quit(0 if failures==0 else 1)
