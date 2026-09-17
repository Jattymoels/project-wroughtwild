extends "res://tests/land04/common.gd"
## Recipe inputs other than the four source materials are explicitly staged.
## Source work, UI crafting, paid physical placement and requests are real.
func _ready() -> void:
 begin()
 run.call_deferred()
func walk_journey(row: Dictionary) -> void:
 # Stage arrival at the native reveal, then walk the changed local approach.
 # The long unchanged-country approach is covered by generation, not replayed
 # three times as an unrelated cross-world renderer test.
 var route: PackedVector3Array=row.source_route
 if not check(route.size()>1,"native "+row.channel+" approach exists"):return
 ready_at(route[0]+Vector3.UP*1.1);terrain.set_process(true)
 player.camera.rotation=Vector3.ZERO
 for i in 10:await tick()
 var ok:=true
 for at: Vector3 in route:
  if not await travel(at,180):
   print("LAND04_ROUTE_STOP ",row.channel," target=",at," feet=",player.position)
   for j in player.get_slide_collision_count():
    var hit:=player.get_slide_collision(j)
    print("LAND04_CONTACT ",hit.get_collider().get_path()," ",hit.get_normal())
   ok=false;break
 var node:=source(row.source_id)
 if node!=null:face_at(node.global_position+Vector3.UP*.6)
 check(ok and node!=null and player.is_on_floor() and not player.swimming and player.aim_probe().get("target")==node,row.channel+" actual controller reaches dry source stance with clear camera interaction")
 quiet()

func observe_host(row: Dictionary) -> void:
 var h: Dictionary={}
 for item: Dictionary in terrain.map.frontier_hosts:
  if item.id==row.host_id:h=item;break
 if not check(not h.is_empty(),row.channel+" existing finite host is mapped"):return
 var pack: Dictionary={}
 for item: Dictionary in mob_packs.packs:
  if item.get("frontier_host_id","")==h.id:pack=item;break
 if not check(not pack.is_empty(),row.channel+" selected pack has stable ownership"):return
 terrain.ensure_area(h.position,28)
 player.position=h.position+Vector3(0,1.2,25)
 mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
 if not check(pack.members.size()==1,row.channel+" has one separate existing finite host"):return
 var creature: Enemy=pack.members[0]
 creature.set_physics_process(true)
 for frame in 170:await tick()
 check(String(creature.enemy_id)==String(h.enemy_id) and creature.influence==row.channel and creature.state=="idle" and creature._habit_index>0,row.channel+" retains existing body, influence and active calm habitat behavior")
 creature.set_physics_process(false)
 var sources_before:=_sim().leyline_save()
 # Explicit forced-death fixture proves once-only ownership, not a combat win.
 creature.take_typed(creature.max_life*2,"physical")
 var drops:=WorldDrops.capture(self)
 mob_packs._on_enemy_died(creature)
 check(_sim().world_effect_active("host_defeated:"+String(h.id)) and WorldDrops.capture(self)==drops,row.channel+" finite death settles once and duplicate death pays nothing")
 check(_sim().leyline_save()==sources_before,row.channel+" finite host death leaves source lots/claims untouched")
 host_deaths.append(String(h.id))
 quiet()
func art_support_and_build(row: Dictionary) -> void:
 # One actual emitted root patch, one paid floor, one local dig. Limited
 # candidate search finds ordinary legal build space; no visibility is forced.
 var build:=player.placement
 build.select_shape(&"floor_slab")
 build.selected_material_family=&"wood"
 build.preview_rotation_step=0
 var selected: MultiMeshInstance3D=null
 var selected_cell:=Vector3i.ZERO
 var candidates:=0
 var refusals: Array[String]=[]
 for chunk: Node3D in terrain.chunks.values():
  if selected!=null or candidates>=12:break
  for child: Node in chunk.get_children():
   if selected!=null or candidates>=12:break
   if not child is MultiMeshInstance3D or not child.has_meta("land04_cover") or String(child.get_meta("journey_id",""))!=String(row.id):continue
   var part:=child as MultiMeshInstance3D
   if not part.is_visible_in_tree() or part.multimesh==null or part.multimesh.instance_count!=1 or absf(part.multimesh.get_instance_transform(0).basis.determinant())<.01:continue
   var candidate_root:=part.global_position
   var candidate_support:=Vector3i(floori(candidate_root.x),terrain.height_at(floori(candidate_root.x),floori(candidate_root.z))-1,floori(candidate_root.z))
   if terrain.block_at(candidate_support.x,candidate_support.y,candidate_support.z)==0 or not terrain.diggable_by_hand(candidate_support):continue
   candidates+=1
   var bounds: AABB=part.get_meta("cover_bounds")
   for offset: Vector2i in [Vector2i.ZERO,Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
    var cell:=Vector3i(candidate_support.x+offset.x,0,candidate_support.z+offset.y)
    cell.y=terrain.height_at(cell.x,cell.z)
    var element:={"kind":"face","axis":1,"cell":cell*2}
    var pose: Dictionary=build.piece_pose(&"floor_slab",element,0)
    if pose.is_empty():continue
    var size: Vector3=_sim().shape("floor_slab").size
    var centre: Vector3=pose.centre
    var floor_box:=AABB(centre-size*.5,size)
    if not bounds.intersects(floor_box):continue
    var refusal:=build.element_refusal(element)
    if not refusal.is_empty():refusals.append(refusal);continue
    var ray:=PhysicsRayQueryParameters3D.create(candidate_root+Vector3.UP*2,candidate_root-Vector3.UP*2)
    ray.exclude=[player]
    var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
    if hit.is_empty() or not terrain.is_terrain_body(hit.get("collider")):continue
    selected=part;selected_cell=cell;break
 if not check(selected!=null,"one supported emitted Green root fits a legal overlapping floor (at most twelve candidates)"):
  print("LAND04_ART_FIXTURE_REFUSALS ",refusals)
  return
 var root:=selected.global_position
 var role:=String(selected.get_meta("role"))
 var before_pose:=selected.multimesh.get_instance_transform(0)
 var support:=Vector3i(floori(root.x),terrain.height_at(floori(root.x),floori(root.z))-1,floori(root.z))
 var pieces_before:=_sim().structure_piece_count()
 var existing:=get_children()
 _sim().add_material("wood",1) # One declared fixture ingredient; placement pays it.
 var wood:=_sim().material_count("wood")
 if not check(place(&"floor_slab",selected_cell),"real existing floor placement succeeds over emitted root"):return
 for i in 3:await tick()
 quiet()
 var floor: PlacedBlock=null
 for child: Node in get_children():
  if child is PlacedBlock and not existing.has(child):floor=child;break
 check(floor!=null and _sim().structure_piece_count()==pieces_before+1 and _sim().material_count("wood")==wood-1,"overlapping floor has one paid owner and spends exact wood")
 check((selected.get_meta("hidden_by_building",[]) as Array).has(true) and absf(selected.multimesh.get_instance_transform(0).basis.determinant())<.001,"actual paid floor suppresses overlapping LAND04 root through shared cover refresh")
 if floor==null:return
 _sim().refund_removal(floor.shape_id,floor.material_family)
 check(build.remove_piece(floor),"ordinary floor removal removes its native owner")
 for i in 3:await tick()
 quiet()
 check(_sim().structure_piece_count()==pieces_before and not (selected.get_meta("hidden_by_building",[]) as Array).has(true) and selected.multimesh.get_instance_transform(0)==before_pose,"removing the paid floor restores the same supported root geometry")
 if not check(terrain.break_block(support.x,support.y,support.z)!="","real local dig removes the root's original top support block"):return
 for i in 3:await tick()
 quiet()
 var remains:=false
 for chunk: Node3D in terrain.chunks.values():
  for child: Node in chunk.get_children():
   if not child is MultiMeshInstance3D or not child.has_meta("land04_cover") or String(child.get_meta("journey_id",""))!=String(row.id) or String(child.get_meta("role",""))!=role:continue
   var part:=child as MultiMeshInstance3D
   if Vector2(part.global_position.x-root.x,part.global_position.z-root.z).length()<.01 and part.multimesh.instance_count>0 and absf(part.multimesh.get_instance_transform(0).basis.determinant())>.01:remains=true
 check(terrain.block_at(support.x,support.y,support.z)==0 and not remains,"chunk rebuild removes unsupported root/skin at the edited anchor")
 captured_art["lifecycle"]={"journey":row.id,"role":role,"anchor":root,"floor":selected_cell,"support_dig":support,"candidates":candidates}
func draw_lot(node: LeylineSource,collect_claim:=true) -> void:
 await aim_source(node);player.interact()
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
 for channel in ["blue","white","green"]:
  var row:=journey(channel)
  await journey_picture(row,channel+"-journey")
  await walk_journey(row)
 await journey_picture(journey("green",true),"green-steppe")
 print("LAND04_USE source routes complete; checks=",checks," failures=",failures)
 if OS.get_cmdline_user_args().has("--land04-routes-only"):return finish_job("routes")
 await art_support_and_build(journey("green",true))
 var raw_before:=_sim().inventory()
 for id in ["red_home_margin","white_home_margin","blue_home_margin","green_home_margin"]:
  var host:=source(id)
  if not check(host!=null,id+" is an ordinary source scene"):return finish_job("use")
  terrain.ensure_area(host.global_position,20)
  check(host.supported(),id+" has real ground and work clearance")
  await draw_lot(host)
 check(_sim().material_count("red_salt")==16 and _sim().material_count("white_mineral")==16 and _sim().material_count("blue_flake")==16 and _sim().material_count("green_resin")==16,"all four actual source claims become carried material")
 for channel in ["white","blue","green"]:await observe_host(journey(channel))
 var home:=home_for(place_data.hollow_home_id)
 var centre:=Vector3(home.x+.5,home.y,home.z+.5)
 ready_at(centre+Vector3(2,1.1,2));await tick();quiet()
 _sim().add_material("wood",60)
 var wood:=_sim().material_count("wood")
 for z in range(-1,2):
  for x in range(-1,2):check(place(&"floor_slab",Vector3i(home.x+x,home.y,home.z+z)),"paid existing home floor")
 check(_sim().material_count("wood")==wood-9,"home costs nine real wood")
 if not paid_recipe("workbench_kit"):return finish_job("use")
 if not await place_paid_kit("workbench_kit",centre+Vector3(-6,0,-3)):return finish_job("use")
 refresh_stations()
 if not paid_recipe("forge_kit",bench):return finish_job("use")
 if not await place_paid_kit("forge_kit",centre+Vector3(-4,0,-4)):return finish_job("use")
 refresh_stations()
 var salt:=_sim().material_count("red_salt")
 var offsets:={"pressure_feeder":Vector3(-1,0,-4),"red_heat_buffer":Vector3(-1,0,-7),"cargo_winch":Vector3(4,0,3),"winch_landing":Vector3(10,0,3),"stormglass_lever":Vector3(-10,0,3),"white_connection":Vector3(-7,0,3),"blue_delay":Vector3(-4,0,3),"green_junction":Vector3(0,0,3)}
 for kind: String in offsets:
  if not paid_recipe("assemble_"+kind,bench):return finish_job("use")
  if not await place_paid_kit(kind+"_kit",centre+offsets[kind]):return finish_job("use")
 print("LAND04_USE paid workshop placed; checks=",checks," failures=",failures)
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
 # Keep independent interrupted work, outstanding claim and held
 # request/paid heat for the fresh-process Continue/rejection job.
 await aim_source(source("blue_home_margin"));player.interact();await press(String(source("blue_home_margin").state().next_work))
 await draw_lot(source("green_home_margin"),false)
 await aim_at(buffer);player.interact();await press("Pay for 1 heat")
 await aim_at(lever);player.interact();await press("Strike the lever");blue._physics_process(.6)
 await aim_at(blue);player.interact();await press("Pause");player.work_panel.close_panel()
 var edit_at:=centre+Vector3(5,0,-10)
 terrain.ensure_area(edit_at,16);await tick()
 var ray:=PhysicsRayQueryParameters3D.create(edit_at+Vector3.UP*3,edit_at-Vector3.UP*5)
 ray.exclude=[player]
 var hit:=get_world_3d().direct_space_state.intersect_ray(ray)
 if not check(not hit.is_empty() and terrain.is_terrain_body(hit.get("collider")),"V12 editable surface has native contact"):return finish_job("use")
 var cell:=terrain.block_from_surface_hit(hit)
 check(terrain.break_block(cell.x,cell.y,cell.z)!="","picked V12 owner can be excavated")
 for i in 3:await tick()
 check(terrain.block_at(cell.x,cell.y,cell.z)==0,"local edit removes actual solid")
 quiet();freeze_fixtures()
 var manager:=SaveManager.new()
 check(manager.write(output.path_join("private-world.json"),player),"isolated checkpoint owns sources, paused request, heat, excavation and paid home")
 var expected:={"height_hash":hash(terrain.map.heights),"journey_hash":hash(journeys),"dug":[cell.x,cell.y,cell.z],"host_ids":host_deaths}
 FileAccess.open(output.path_join("expected.json"),FileAccess.WRITE).store_string(JSON.stringify(expected,"\t"))
 finish_job("use",{"scope":"Normal New World and actual UI/controller. Arrival and non-source recipe inputs staged; no acquisition pacing/balance claim."})
