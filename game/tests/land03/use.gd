extends "res://tests/land03/common.gd"
## Recipe inputs other than the four source materials are explicitly staged.
## Source work, UI crafting, paid physical placement and requests are real.
func _ready() -> void:
 begin()
 run.call_deferred()
func walk_route(key: String) -> void:
 var route: PackedVector3Array=place_data[key]
 ready_at(route[0]+Vector3.UP*1.1);terrain.set_process(true)
 player.camera.rotation=Vector3.ZERO
 for i in 10:await tick()
 var ok:=true
 for index in route.size():
  var at: Vector3=route[index]
  # The anchor is inside the solid source body. Complete the authored path
  # at genuine interaction distance, then independently test the camera ray.
  if index>=route.size()-12 and ((player.position-route[-1])*Vector3(1,0,1)).length()<=2.1:break
  if not await travel(at,180):
   print("LAND03_ROUTE_STOP ",key," target=",at," feet=",player.position)
   for j in player.get_slide_collision_count():
    var hit:=player.get_slide_collision(j)
    print("LAND03_CONTACT ",hit.get_collider().get_path()," ",hit.get_normal())
   ok=false;break
 var red:=source("red_home_margin")
 face_at(red.global_position+Vector3.UP*.6)
 check(ok and not player.swimming and player.aim_probe().get("target")==red,key+" walks to genuine Red source interaction on ordinary controller")
 quiet()
func red_place_view() -> void:
 terrain.ensure_area(place_data.release_pockets[0],36)
 await tick();quiet()
 var pockets: Array[Vector3]=[]
 var red_brushes:=0
 for chunk: Node3D in terrain.chunks.values():
  for part: Node in chunk.get_children():
   if not part.has_meta("land03_cover"):continue
   var poses: Array=part.get_meta("world_transforms")
   if String(part.name)=="LAND03_release-nodule":
    for pose: Transform3D in poses:pockets.append(pose.origin)
   if String(part.name)=="LAND03_red-brush":red_brushes+=poses.size()
 check(not pockets.is_empty() and red_brushes>0,"native Red bank carries actual supported release nodules and tough living brush")
 print("LAND03_RED_FORMS pockets=",pockets.size()," red_brush=",red_brushes)
 if pockets.is_empty():return
 var target: Vector3=pockets[0]
 var view:=target+Vector3(-2.5,0,3)
 terrain.ensure_area(view,20)
 view.y=terrain.rendered_height(view.x,view.z,terrain.height_at(floori(view.x),floori(view.z)))+1.1
 ready_at(view);terrain.set_process(true)
 for i in 24:await tick()
 face_at(target+Vector3.UP*.2);await still("red-release.png");quiet()
func draw_lot(node: LeylineSource,collect_claim:=true) -> void:
 await aim_at(node);player.interact()
 for i in 4:
  if not await press(String(node.state().next_work)):return
 if collect_claim:
  for item: String in node.state().claim.keys():await press("Collect "+Hud.pretty(item))
 player.work_panel.close_panel()
func paid_recipe(id: String,station: StationSite=null) -> bool:
 stage_inputs(id)
 return craft(id,1,station)
func run() -> void:
 if not await started():return finish_job("use")
 ready_at(place_data.reveal+Vector3.UP*1.1);terrain.set_process(true)
 for i in 40:await tick()
 face_at(place_data.red_source+Vector3.UP*2)
 check(player.is_on_floor(),"ordinary player-height Steppe reveal")
 await still("reveal.png");quiet()
 await walk_route("ridge_route")
 await walk_route("low_route")
 print("LAND03_USE routes complete; checks=",checks," failures=",failures)
 await red_place_view()
 if OS.get_cmdline_user_args().has("--land03-routes-only"):return finish_job("routes")
 var raw_before:=_sim().inventory()
 for id in ["red_home_margin","white_home_margin","blue_home_margin","green_home_margin"]:
  var host:=source(id)
  if not check(host!=null,id+" is an ordinary source scene"):return finish_job("use")
  terrain.ensure_area(host.global_position,20)
  check(host.supported(),id+" has real ground and work clearance")
  await draw_lot(host)
 check(_sim().material_count("red_salt")==16 and _sim().material_count("white_mineral")==16 and _sim().material_count("blue_flake")==16 and _sim().material_count("green_resin")==16,"all four actual source claims become carried material")
 var red:=source("red_home_margin")
 for lot in 7:await draw_lot(red)
 check(_sim().material_count("red_salt")==128 and red.state().claim.is_empty(),"Red exhausts eight sixteen-unit lots through manual controls")
 # Existing source-related host only: observe its habit, then a finite death
 # fixture (not a balance victory) to check separate saved ownership.
 print("LAND03_USE all source work complete; checks=",checks," failures=",failures)
 var h: Dictionary=terrain.map.frontier_hosts[0]
 var pack: Dictionary={}
 for row: Dictionary in mob_packs.packs:
  if row.get("frontier_host_id","")==h.id:pack=row
 terrain.ensure_area(h.position,28)
 player.position=h.position+Vector3(0,1.2,23)
 mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
 if check(pack.members.size()==1,"one existing finite Red boar on its separate route"):
  var boar: Enemy=pack.members[0]
  boar.set_physics_process(true)
  for frame in 170:await tick()
  check(boar.influence=="red" and boar.visual_id=="ember_whelp" and boar.state=="idle" and boar._habit_index>0,"Red boar retains authored ancestry and calm source-related habit")
  boar.set_physics_process(false)
  var view:=boar.global_position+Vector3(6,0,7)
  view.y=terrain.rendered_height(view.x,view.z,terrain.height_at(int(view.x),int(view.z)))+1.1
  ready_at(view)
  for i in 18:await tick()
  face_at(boar.global_position+Vector3.UP*.65);await still("red-host.png");quiet()
  var sources_before:=_sim().leyline_save()
  boar.take_typed(boar.max_life*2,"physical")
  var drops:=WorldDrops.capture(self)
  mob_packs._on_enemy_died(boar)
  check(_sim().world_effect_active("host_defeated:"+String(h.id)) and WorldDrops.capture(self)==drops,"finite host records once before reward; duplicate death pays nothing")
  check(_sim().leyline_save()==sources_before,"boar death never changes source lots/claims")
 var home:=home_for(place_data.hollow_home_id)
 var centre:=Vector3(home.x+.5,home.y,home.z+.5)
 ready_at(centre+Vector3(2,1.1,2));await tick();quiet()
 _sim().add_material("wood",60)
 var wood:=_sim().material_count("wood")
 for z in range(-1,2):
  for x in range(-1,2):check(place(&"floor_slab",Vector3i(home.x+x,home.y,home.z+z)),"paid Steppe home floor")
 check(_sim().material_count("wood")==wood-9,"home costs nine real wood")
 if not paid_recipe("workbench_kit"):return finish_job("use")
 if not await place_paid_kit("workbench_kit",centre+Vector3(-6,0,-3)):return finish_job("use")
 refresh_stations()
 if not paid_recipe("forge_kit",bench):return finish_job("use")
 if not await place_paid_kit("forge_kit",centre+Vector3(-4,0,-4)):return finish_job("use")
 refresh_stations()
 var salt:=_sim().material_count("red_salt")
 check(paid_recipe("forge_faint_ember",forge) and _sim().material_count("red_salt")==salt-96,"ordinary manufacture spends ninety-six extracted Red salt")
 check(paid_recipe("fire_red_brick",forge),"Red has useful ordinary brick manufacture")
 var offsets:={"pressure_feeder":Vector3(-1,0,-4),"red_heat_buffer":Vector3(-1,0,-7),"cargo_winch":Vector3(4,0,3),"winch_landing":Vector3(10,0,3),"stormglass_lever":Vector3(-10,0,3),"white_connection":Vector3(-7,0,3),"blue_delay":Vector3(-4,0,3),"green_junction":Vector3(0,0,3)}
 for kind: String in offsets:
  if not paid_recipe("assemble_"+kind,bench):return finish_job("use")
  if not await place_paid_kit(kind+"_kit",centre+offsets[kind]):return finish_job("use")
 print("LAND03_USE paid workshop placed; checks=",checks," failures=",failures)
 freeze_fixtures()
 var feeder:=fixture("pressure_feeder");var buffer:=fixture("red_heat_buffer")
 var drum:=fixture("cargo_winch");var landing:=fixture("winch_landing")
 var lever:=fixture("stormglass_lever");var white:=fixture("white_connection")
 var blue:=fixture("blue_delay");var green:=fixture("green_junction")
 check(feeder.attach_feeder(forge.station_key,"").ok,"own paid forge connects to hand-wound feeder")
 await connect_control(buffer,feeder,"Choose heat receiver")
 await connect_control(drum,landing,"Choose landing")
 await connect_control(lever,white,"Choose receiver")
 await connect_control(white,blue,"Choose receiver")
 await connect_control(blue,green,"Choose receiver")
 await connect_control(green,drum,"Choose first receiver")
 await aim_at(green);player.interact();await press("Choose second receiver");await press("Link this Pressure feeder")
 check(machine(green).second_link==feeder.machine_key,"Green second real port reaches feeder")
 check(not _sim().contraption_link_second(green.machine_key,drum.machine_key,true).ok,"duplicate Green receiver refuses")
 await aim_at(lever);player.interact();await press("Strike the lever")
 blue._physics_process(3.0)
 check(not machine(drum).moving and machine(drum).energy==0 and machine(feeder).completed_cycles==0,"White/Blue/Green request creates no free work or matter")
 _sim().add_materials({"raw_clay":8,"wood":12})
 check(_sim().contraption_deposit(feeder.machine_key,"raw_clay",8).moved==8,"feeder takes eight paid clay")
 check(feeder.perform("wind").ok and drum.perform("wind").ok,"two receivers store their own hand winding")
 check(_sim().contraption_deposit(drum.machine_key,"wood",10).moved==10,"cargo owns ten paid wood")
 salt=_sim().material_count("red_salt")
 await aim_at(buffer);player.interact();await press("Pay for 1 heat")
 check(machine(buffer).heat==1 and _sim().material_count("red_salt")==salt-2,"Red heat consumes two actually acquired salt")
 await aim_at(lever);player.interact();await press("Strike the lever")
 check(machine(blue).pending_request and not machine(drum).moving,"real Blue delay holds one request")
 blue._physics_process(.8)
 var held:=_sim().contraption_save()
 get_tree().paused=true;blue._physics_process(20);get_tree().paused=false
 check(_sim().contraption_save()==held,"paused device gains no elapsed credit")
 blue._physics_process(2.21)
 check(machine(drum).moving and machine(drum).energy==0 and machine(feeder).escrow_drive==1 and machine(feeder).escrow_heat==1,"Green branches once; each receiver pays separate drive and Red heat")
 player.work_panel.close_panel()
 player.position=centre+Vector3(2,1.1,0)
 feeder._physics_process(8);drum._physics_process(20)
 check(machine(feeder).output.get("rustclay_brick",0)==4 and machine(buffer).heat==0 and machine(drum).at_landing,"paid Red firing and cargo trip actually complete")
 await aim_at(landing);player.interact();await press("Collect wood")
 check(machine(drum).cargo.is_empty() and machine(drum).completed_trips==1,"cargo collected exactly once")
 check(_sim().contraption_pressure_sources()[0].remaining==24,"ordinary finite smithy pressure remains a separate untouched owner")
 player.work_panel.close_panel()
 ready_at(centre+Vector3(8,1.1,8));terrain.set_process(true)
 for i in 25:await tick()
 face_at(centre+Vector3(-1,1,0));await still("workshop.png");quiet()
 # Keep independent interrupted work, outstanding claim, depleted Red and held
 # request/paid heat for the fresh-process Continue/rejection job.
 await aim_at(source("blue_home_margin"));player.interact();await press(String(source("blue_home_margin").state().next_work))
 await draw_lot(source("green_home_margin"),false)
 await aim_at(buffer);player.interact();await press("Pay for 1 heat")
 await aim_at(lever);player.interact();await press("Strike the lever");blue._physics_process(.6)
 await aim_at(blue);player.interact();await press("Pause");player.work_panel.close_panel()
 var edit_at:=centre+Vector3(5,0,-10)
 terrain.ensure_area(edit_at,16);await tick()
 var ray:=PhysicsRayQueryParameters3D.create(edit_at+Vector3.UP*3,edit_at-Vector3.UP*5)
 ray.exclude=[player]
 var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
 if not check(not hit.is_empty() and terrain.is_terrain_body(hit.get("collider")),"Steppe editable surface has native contact"):return finish_job("use")
 var cell:=terrain.block_from_surface_hit(hit)
 check(terrain.break_block(cell.x,cell.y,cell.z)!="","picked Steppe owner can be excavated")
 for i in 3:await tick()
 check(terrain.block_at(cell.x,cell.y,cell.z)==0,"local edit removes actual solid")
 quiet();freeze_fixtures()
 var manager:=SaveManager.new()
 check(manager.write(output.path_join("private-world.json"),player),"isolated checkpoint owns sources, paused request, heat, excavation and paid home")
 var expected:={"height_hash":hash(terrain.map.heights),"place_hash":hash(place_data),"dug":[cell.x,cell.y,cell.z],"host_id":h.id}
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify(expected,"\t"))
 finish_job("use",{"scope":"Normal New World and actual UI/controller. Arrival and non-source recipe inputs staged; no acquisition pacing/balance claim."})
