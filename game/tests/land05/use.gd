extends "res://tests/land04/use.gd"
var population: Dictionary={}
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND05_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 player.class_panel.choose("warden")
 run.call_deferred()
func native_identity() -> void:
 var sim:=WroughtwildSim.new();sim.load_tuning(load("res://scripts/sim.gd").get_tuning_directory())
 sim.set_world_profile("frontier_v12")
 var old: Dictionary=sim.world_map(77)
 check(hash(old.blocks)==2744122157 and hash(old.heights)==2701913624 and hash(old.force_journeys)==1669597966,"published V12 exact terrain and corrected journey fingerprints preserved")
 var current: Dictionary=terrain.map
 for key in ["blocks","heights","biomes","nodes","home_sites","lakes","scarwater","dry_steppe","force_journeys","leyline_source_sites","frontier_hosts"]:
  check(hash(old.get(key))==hash(current.get(key)),"V13 retains exact V12 "+key+"; thinning does not redirect geography or owners")
 var old_elk:=0;var new_elk:=0;var old_herds:=0;var new_herds:=0
 var old_other:=[];var new_other:=[];var old_elk_packs:=[]
 for pack: Dictionary in old.packs:
  if pack.enemies.has("valley_elk") and String(pack.get("frontier_host_id","")).is_empty():old_elk+=pack.enemies.size();old_herds+=1;old_elk_packs.append(pack)
  else:old_other.append(pack)
 for pack: Dictionary in current.packs:
  if pack.enemies.has("valley_elk") and String(pack.get("frontier_host_id","")).is_empty():
   new_elk+=pack.enemies.size();new_herds+=1
   check(old_elk_packs.has(pack),"retained whole herd keeps exact composition and den")
  else:new_other.append(pack)
 check(old_other==new_other,"all nonambient packs and finite teaching hosts remain exact")
 check(new_elk>old_elk*.40 and new_elk<old_elk*.60,"chosen seed has approximately half the ambient elk")
 population={"seed":77,"v12_elk":old_elk,"v13_elk":new_elk,"v12_herds":old_herds,"v13_herds":new_herds,"keep_fraction":.5}
 sim.set_world_profile("frontier_v13")
 check(sim.world_map(77).packs==current.packs,"V13 retained population is deterministic")
 sim.leyline_bind_world("frontier_v13",77);sim.contraption_bind_world("frontier_v13",77)
 check(JSON.parse_string(sim.leyline_save()).profile=="frontier_v13","V13 source ledger uses exact version identity")
 FileAccess.open(output.path_join("population-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"population":population},"\t"))
func cover_rows(root: Node3D) -> Array[String]:
 var result: Array[String]=[]
 for part: Node in root.get_children():
  if not part is MultiMeshInstance3D:continue
  var poses: Array=part.get_meta("world_transforms",[])
  for i in poses.size():
   result.append(str([part.name,poses[i],part.multimesh.mesh.get_faces().size(),part.multimesh.use_colors,part.multimesh.get_instance_color(i) if part.multimesh.use_colors else Color.WHITE]))
 result.sort();return result
func exact_cover() -> void:
 # One lakeside chunk compares the old complete operation with all four
 # staged strips, including its retained authored grass and wetland families.
 var data: Dictionary=_sim().world_mesh_chunk(77,16,528,592,terrain.broken_packed(),terrain.faceted_surface,terrain._blend_palette())
 var old:=Node3D.new();var staged:=Node3D.new()
 old.set_meta("surface_sampler",SurfaceSampler.new(data.faces,1.0))
 staged.set_meta("surface_sampler",SurfaceSampler.new(data.faces,1.0))
 var baseline=load("res://tests/land05/baseline_ground.gd")
 baseline.build_for_chunk(old,data,terrain.map,1.0,terrain.frontier_look,true,terrain.reclaimed_cover)
 for i in 4:
  var slice:=data.duplicate();slice.cover_slice=i;slice.cover_slices=4
  GroundCover.build_for_chunk(staged,slice,terrain.map,1.0,terrain.frontier_look,true,terrain.reclaimed_cover)
 var expected:=cover_rows(old);var actual:=cover_rows(staged)
 check(not expected.is_empty() and actual==expected,"four staged strips preserve every original selected cover pose, mesh and tint exactly")
 check(not staged.has_meta("pending_ground_cover") and not staged.has_meta("pending_rf06_cover"),"complete cover releases temporary batches")
 population["matched_cover_instances"]=actual.size()
 old.free();staged.free()
func picture_walk(row: Dictionary,name: String) -> void:
 var route: PackedVector3Array=row.source_route
 ready_at(route[0]+Vector3.UP*1.1);terrain.set_process(true)
 for i in 8:await tick()
 var ok:=true
 for index in route.size():
  if not await travel(route[index],180):ok=false;break
  if index==maxi(0,route.size()-8):
   face_at(row.position+Vector3.UP*.7);player.hud.notify("")
   await still(name+".png")
 var node:=source(row.source_id)
 if node!=null:face_at(node.global_position+Vector3.UP*.6)
 check(ok and player.is_on_floor() and node!=null and player.aim_probe().get("target")==node,name+" walking discovery approach reaches real source interaction")
 quiet()
func run() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 if terrain.map.is_empty():get_tree().quit(1);return
 quiet();journeys=terrain.map.force_journeys;place_data=terrain.map.dry_steppe[0]
 check(world_profile=="frontier_v13","ordinary fresh world selects V13")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"no-focus / visible mouse verified")
 native_identity();exact_cover()
 for channel: String in ["green","white","blue"]:await picture_walk(journey(channel),channel)
 await journey_picture(journey("green",true),"green-steppe")
 await art_support_and_build(journey("green",true))
 # Green manual work is the unchanged payoff at the connected workplace.
 await draw_lot(source("green_home_margin"),false)
 await aim_source(source("blue_home_margin"));player.interact();await press(String(source("blue_home_margin").state().next_work));player.work_panel.close_panel()
 await observe_host(journey("white"))
 # One paid home action exercises ordinary construction, not the unaffected
 # complete device chain which already passed LAND04.
 var h: Dictionary=terrain.map.home_sites[0]
 ready_at(Vector3(h.x,h.y+1.1,h.z)+Vector3(4,0,4));await tick();quiet()
 _sim().add_material("wood",2)
 var before:=_sim().material_count("wood")
 check(place(&"floor_slab",Vector3i(h.x,h.y,h.z)),"paid home floor at original home core")
 check(_sim().material_count("wood")==before-1,"home action spends existing price")
 var pick:=Vector3(h.x+6,h.y,h.z+6)
 terrain.ensure_area(pick,16);await tick()
 var ray:=PhysicsRayQueryParameters3D.create(pick+Vector3.UP*4,pick-Vector3.UP*4);ray.exclude=[player]
 var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
 check(not hit.is_empty() and terrain.is_terrain_body(hit.get("collider")),"picked terrain uses actual contact")
 var cell:=terrain.block_from_surface_hit(hit)
 check(terrain.break_block(cell.x,cell.y,cell.z)!="","native picked owner remains diggable")
 quiet();freeze_fixtures()
 var manager:=SaveManager.new()
 check(manager.write(output.path_join("private-world.json"),player),"checkpoint saves paid floor, finite death, digs and source work/claim")
 var expected:={"height_hash":hash(terrain.map.heights),"journey_hash":hash(journeys),"dug":[cell.x,cell.y,cell.z],"host_ids":host_deaths,"population":population}
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify(expected,"\t"))
 finish_job("use",{"population":population,"scope":"Arrivals and two wood staged; actual local walks, source UI, paid placement, native dig, forced finite-host death. Existing complete device-chain evidence reused.","placement":terrain.force_journeys.stats})
