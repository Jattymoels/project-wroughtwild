extends "res://tests/land02b/early.gd"
## Harness poses/acquisition accelerate inspection; walking, native work, paid
## recipes/placement and finite ledgers use the unchanged ordinary game paths.
var source: PressurePocket
var feeder: ContraptionSite
var forge: StationSite
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_LAND02B_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new();add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 player.class_panel.choose("warden")
 use_run.call_deferred()
func finish_use() -> void:
 player.test_walk=Vector2.ZERO
 FileAccess.open(output.path_join("use-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"walk_distance_m":route_distance,"swim_frames":swim_frames,"scope":"Ordinary New World and controller; staged arrival, accelerated finite gathering and supplied workshop recipe inputs; normal payment/ownership, not a discovery or balance playtest."},"\t"))
 print("LAND02B_USE ",checks," checks / ",failures," failures, walked ",route_distance," m")
 get_tree().quit(0 if failures==0 else 1)
func walk_route(key: String) -> bool:
 var route: PackedVector3Array=place_data[key]
 ready_at(route[0]+Vector3.UP*1.1)
 terrain.set_process(true)
 for i in 10:await tick()
 var ok:=true
 # Keep the existing controller fixture's half-metre waypoint tolerance.
 # It represents capsule arrival, not exact sub-capsule centre coincidence.
 # Follow every cardinal native turn. Coarse waypoint skipping cuts across
 # steep terrain corners and is not evidence of following the reserved route.
 var targets: Array[Vector3]=[]
 for i in range(1,route.size()-1):targets.append(route[i])
 targets.append(route[-1])
 for at: Vector3 in targets:
  if not await travel(at,170):
   print("LAND02B_ROUTE_STOP ",key," at=",at," player=",player.position)
   for contact_index in player.get_slide_collision_count():
    var contact:=player.get_slide_collision(contact_index)
    print("LAND02B_CONTACT ",contact.get_collider().get_path()," point=",contact.get_position()," normal=",contact.get_normal())
   ok=false;break
 print("LAND02B_ROUTE ",key," reached=",ok," distance=",route_distance)
 check(ok and not player.swimming,key+" ordinary controller reaches the smithy")
 return ok
func use_run() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 if terrain.map.is_empty():return finish_use()
 place_data=terrain.map.scarwater[0];setup_lake();quiet()
 check(world_profile=="frontier_v10" and world_seed==77,"normal New World selects V10")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"verified desktop comfort")
 check(preload("res://land02b/kit.gd").ready,"shared art prepared before controls release")
 ready_at(place_data.reveal+Vector3.UP*1.1);terrain.set_process(true)
 for i in 60:await tick()
 face_at(place_data.centre+place_data.direction*(float(place_data.ridge_offset_m)+5)+Vector3.UP*float(place_data.relief_m)*.15)
 check(player.is_on_floor(),"reveal at ordinary grounded eye height")
 await still("reveal.png");quiet()
 await _gather();quiet()
 # Two paid homes are the existing cores, each accepting ordinary construction.
 for id: String in [place_data.outlook_home_id,place_data.grove_home_id]:
  var h: Dictionary={}
  for item: Dictionary in terrain.map.home_sites:
   if item.id==id:h=item;break
  var at:=Vector3i(h.x,h.y,h.z)
  ready_at(Vector3(at)+Vector3(3,1.1,3))
  for i in 8:await tick()
  quiet()
  var before:=_sim().material_count("wood")
  for dz in range(-1,2):
   for dx in range(-1,2):check(place(&"floor_slab",at+Vector3i(dx,0,dz)),"paid "+id+" floor")
  check(_sim().material_count("wood")==before-9,"home payment remains nine wood")
 # Pay the hand recipe and use the normal kit-placement path at the lake home.
 var bench_at:=Vector3i(home.x+4,home.y,home.z)
 ready_at(Vector3(bench_at)+Vector3(2,1.1,2));await tick();quiet()
 check(_sim().craft("workbench_kit").crafted,"gathered wood funds hand-crafted bench")
 check(place(&"workbench_kit",bench_at,1,true),"paid usable workbench at outlook home")
 await tick()
 var bench: StationSite
 for n in get_tree().get_nodes_in_group("crafting_stations"):
  if n is StationSite and n.player_built and n.station_id==&"workbench":bench=n
 check(bench!=null,"bench has ordinary physical ownership")
 if bench!=null:
  bench.interact(player);check(player.work_panel.is_open(),"paid home bench opens ordinary crafting");player.work_panel.close_panel()
 ready_at(Vector3(home.x,home.y+1.1,home.z)+Vector3(-7,0,-7))
 for i in 10:await tick()
 face_at(place_data.centre+Vector3.UP*2)
 await still("home.png")
 print("LAND02B_USE paid homes complete")
 if OS.get_environment("WROUGHTWILD_LAND02B_REUSE_BANK_ROUTES")!="1":
  await walk_route("sheltered_route")
  await walk_route("outlook_route")
 else:print("LAND02B_REUSED_BANK_ROUTES: both passed in use-20260916-201946; only the local fissure width/end taper changed.")
 # Full physical length of the dry scar, including both native walkout ends.
 var side: Vector3=place_data.direction
 # The clear floor beside the recessed channel is the traversable path.
 var scar: Vector3=place_data.scar+side*2.15
 scar.y=terrain.height_at(floori(scar.x),floori(scar.z))
 var along:=Vector3(-side.z,0,side.x)
 var entry:=scar-along*(float(place_data.fissure_length_m)*.5+2)
 entry.y=terrain.height_at(floori(entry.x),floori(entry.z))+1.1
 ready_at(entry);terrain.set_process(true)
 for i in 10:await tick()
 check(await travel(scar,450),"ordinary controller descends to actual fissure floor")
 check(player.position.y<scar.y+1.5 and not player.swimming,"dry native floor contact")
 check(await travel(scar+along*(float(place_data.fissure_length_m)*.5+2),450),"ordinary controller walks out of opposite fissure end")
 check(await travel(scar,450) and await travel(entry,450),"return journey walks out of first fissure end")
 var look:=scar-side*4
 look.y=terrain.height_at(floori(look.x),floori(look.z))+1.1
 ready_at(look)
 for i in 15:await tick()
 face_at(scar+along*3+Vector3.UP*.8);await still("scar.png")
 quiet()
 var definition: Dictionary=terrain.map.pressure_pockets[0]
 source=PressurePocket.find_source(get_tree(),definition.id)
 check(source!=null and source.supported() and source.source_state().remaining==24,"grounded finite old smithy")
 if source==null:return finish_use()
 var work: Vector3=definition.work_position
 ready_at(work+Vector3(0,1.1,3));await tick();quiet()
 var target:=source.global_position+Vector3.UP*.8
 face_at(target)
 await tick()
 # Inspection through the existing panel, not a new landform interaction.
 source.interact(player)
 check(player.work_panel.is_open() and player.work_panel._custom_title=="The struck blacksmith's hearth","existing accidental history and finite-source inspection")
 player.work_panel.close_panel()
 await place_workshop(work)
 if feeder==null or forge==null:return finish_use()
 var attachment: Dictionary=feeder.attach_feeder(forge.station_key,source.source_id)
 check(attachment.ok,"normal local forge/source attachment: "+str(attachment))
 check(feeder.perform("charge").ok,"finite pocket charges paid feeder")
 check(source.source_state().remaining==20 and _sim().contraption_state(feeder.machine_key).energy==4,"exact debit 24 to 20; four stored strokes")
 var full:=_sim().contraption_save()
 check(not feeder.perform("charge").ok and _sim().contraption_save()==full,"full feeder cannot debit twice")
 _sim().add_materials({"raw_clay":8,"wood":1})
 check(_sim().contraption_deposit(feeder.machine_key,"raw_clay",8).moved==8,"ordinary recipe clay leaves pack")
 check(_sim().contraption_deposit(feeder.machine_key,"wood",1).moved==1,"ordinary fuel leaves pack")
 check(feeder.perform("start").ok,"start existing finite recipe")
 feeder._physics_process(8.0)
 check(_sim().contraption_state(feeder.machine_key).output=={"rustclay_brick":4},"existing paid cycle produces four bricks")
 check(_sim().contraption_withdraw(feeder.machine_key,"output","rustclay_brick",4).moved==4,"one output collection")
 check(not _sim().contraption_withdraw(feeder.machine_key,"output","rustclay_brick",4).ok,"no duplicate output")
 ready_at(work+Vector3(0,1.1,4))
 for i in 45:await tick()
 check(player.is_on_floor(),"smithy capture at grounded eye height")
 face_at(source.global_position+Vector3.UP);await still("smithy.png");quiet()
 # An actual floor edit removes local seam support and survives a fresh process.
 terrain.ensure_area(scar,16)
 await tick()
 var ray:=PhysicsRayQueryParameters3D.create(scar+Vector3.UP*3,scar-Vector3.UP*3)
 ray.exclude=[player]
 var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
 check(not hit.is_empty() and terrain.is_terrain_body(hit.get("collider")),"fissure floor physically matches visible terrain")
 if hit.is_empty():return finish_use()
 var cell:=terrain.block_from_surface_hit(hit)
 var hit_position: Vector3=hit.position
 check(terrain.block_at(cell.x,cell.y,cell.z)!=0,"ray resolves exact editable floor owner")
 check(terrain.break_block(cell.x,cell.y,cell.z)!="","native scar floor is ordinarily diggable")
 for i in 3:await tick()
 check(terrain.block_at(cell.x,cell.y,cell.z)==0,"dug native cell really absent")
 var changed:=get_world_3d().direct_space_state.intersect_ray(ray)
 check(changed.is_empty() or (changed.position as Vector3).distance_to(hit_position)>.03,"dig rebuilds actual collision at the picked surface")
 ready_at(scar-side*5+Vector3.UP*5)
 for i in 12:await tick()
 quiet()
 var manager:=SaveManager.new()
 var saved:=manager.capture(player)
 check(manager.write_data(output.path_join("private-world.json"),saved),"isolated save records terrain, paid structures and finite source")
 var expected: Dictionary={"height_hash":hash(terrain.map.heights),"place_hash":hash(place_data),"dug":[cell.x,cell.y,cell.z],"pressure_remaining":20,"feeder":feeder.machine_key}
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify(expected,"\t"))
 finish_use()
func place_workshop(work: Vector3) -> void:
 for recipe_id in ["forge_kit","assemble_pressure_feeder"]:
  var recipe: Dictionary=_sim().recipe(recipe_id)
  for id in recipe.get("inputs",{}):_sim().add_material(String(id),int(recipe.inputs[id]))
  check(_sim().craft(recipe_id).crafted,recipe_id+" pays ordinary bench recipe")
 player.placement.set_build_mode_enabled(true)
 for kit in ["forge_kit","pressure_feeder_kit"]:
  player.placement._select_kit(StringName(kit))
  var selected: Dictionary={}
  # Candidate search uses normal footprint checks on the old flat foundation.
  for offset in [Vector3(0,0,0),Vector3(0,0,2),Vector3(2,0,0),Vector3(-2,0,0),Vector3(0,0,-2),Vector3(2,0,2),Vector3(-2,0,-2),Vector3(-2,0,2),Vector3(2,0,-2)]:
   var at: Vector3=work+offset
   var cell:=Vector3i(floori(at.x/player.placement.registry_grid),roundi(at.y/player.placement.registry_grid),floori(at.z/player.placement.registry_grid))
   var element: Dictionary={"kind":"volume","axis":0,"cell":cell}
   if player.placement.element_accepts(element):selected=element;break
  check(not selected.is_empty(),kit+" has a clear place around the old smithy")
  if selected.is_empty():return
  player.placement.preview_element=selected
  player.placement.preview_visible=true
  check(player.placement.try_place_block(),kit+" places through ordinary payment and collision checks")
  await get_tree().physics_frame
  if kit=="forge_kit":
   for site in get_tree().get_nodes_in_group("crafting_stations"):
    if site is StationSite and site.player_built and site.station_id==&"forge_basic":forge=site
  else:
   for fixture in get_tree().get_nodes_in_group("contraptions"):
    if fixture is ContraptionSite and fixture.kind=="pressure_feeder":feeder=fixture;feeder.set_physics_process(false)
 player.placement.set_build_mode_enabled(false)
 for frame in 2:await get_tree().physics_frame
