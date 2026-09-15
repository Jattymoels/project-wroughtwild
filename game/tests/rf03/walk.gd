extends "res://tests/rf03/build.gd"
## One continuous ordinary walk from the woodland home to the meadow overlook.
## The initial capture placement is explicit. Every subsequent metre uses the
## real controller/collision; world work, combat and streaming remain active.
var captured:=0
var walk_rows: Array=[]
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF03_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 _walk.call_deferred()
func _walk() -> void:
 if not check(seed_controls.continue_saved(),"ordinary Continue opens the paid V7 world"):return end_walk()
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"mouse opt-out is active before capture")
 check(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"window cannot take focus")
 check(RenderingServer.get_current_rendering_method()=="forward_plus","one Forward+ renderer")
 check(world_profile=="frontier_v7" and world_seed==77,"saved V7 identity restored")
 if failures>0:return end_walk()
 var home0: Dictionary=terrain.map.home_sites[0]
 var home1: Dictionary=terrain.map.home_sites[1]
 var route: PackedVector3Array=home0.approach.duplicate()
 route.reverse()
 route.append_array(home1.approach.slice(1))
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("expected.json")))
 var target: Array=expected.target
 # End beside the paid footprint on the same level home ground.
 route.append(Vector3(home1.x+.5,home1.y,target[2]+4.5))
 terrain.ensure_area(route[0],40)
 terrain.resource_stream.focus(route[0],true)
 player.set_physics_process(false)
 player.position=route[0]+Vector3(0,1.05,0)
 player.velocity=Vector3.ZERO
 player.rotation.y=0
 player.spring_arm.rotation.x=-.10
 player.set_physics_process(true)
 set_physics_process(true)
 Engine.max_fps=60
 for i in 90: await get_tree().process_frame
 check(player.is_on_floor(),"woodland home starts with real floor contact")
 await still("01-woodland-pocket.png")
 var begin:=player.position
 var previous:=begin
 var last_progress:=begin
 var distance:=0.0
 var frames:=0
 var stuck:=0
 var segment:=1
 var meadow_still:=false
 while segment<route.size() and frames<3300:
  var offset: Vector3=(route[segment]-player.position)*Vector3(1,0,1)
  if offset.length()<.55:
   segment+=1
   continue
  player.rotation.y=lerp_angle(player.rotation.y,atan2(-offset.x,-offset.z),.18)
  player.test_walk=Vector2(0,-1)
  await get_tree().process_frame
  frames+=1
  distance+=((player.position-previous)*Vector3(1,0,1)).length()
  previous=player.position
  if frames%30==0:
   if ((player.position-last_progress)*Vector3(1,0,1)).length()<.2:stuck+=30
   else:stuck=0
   last_progress=player.position
   walk_rows.append({"frame":frames,"position":[player.position.x,player.position.y,player.position.z],"grounded":player.is_on_floor()})
  # One eight-second normal-speed stretch approaching the overlook.
  if distance>125 and captured<120 and frames%4==0:
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_jpg(output.path_join("media/walk-%03d.jpg"%captured),.90)
   captured+=1
  if not meadow_still and distance>120:
   await still("02-meadow-approach.png")
   meadow_still=true
  if stuck>=120:break
 player.test_walk=Vector2.ZERO
 # A short look back across the valley from the actual reached outlook.
 var look:=Vector3(530,31,509)-player.position
 player.rotation.y=atan2(-look.x,-look.z)
 player.spring_arm.rotation.x=-.17
 for i in 30:await get_tree().process_frame
 await still("03-overlook-home.png")
 check(segment==route.size(),"continuous woodland-to-overlook route completed")
 check(distance>180,"useful ordinary walk crosses both home settings")
 check(captured==120,"eight seconds of actual walking captured")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"capture comfort remains active")
 check(player.is_physics_processing() and is_physics_processing() and terrain.is_processing() and mob_packs.is_physics_processing(),"ordinary physics and world work stayed active")
 select_home()
 # Rendering verifies the already checked CPU grass/building masks.
 var buildings: Dictionary=terrain.reclaimed_cover.workspace_index(terrain,StrangeSites._building_index(terrain))
 var overlaps:=0
 var visible_overlap:=false
 for row in poses():
  var bounds: AABB=row.pose*row.part.get_meta("clearance_bounds")
  if not StrangeSites._building_overlap(buildings,bounds):continue
  overlaps+=1
  var transforms: Array=row.part.get_meta("world_transforms")
  var i:=transforms.find(row.pose)
  if row.part.multimesh.get_instance_transform(i).basis.determinant()!=0:visible_overlap=true
 check(overlaps>0 and not visible_overlap,"Forward+ keeps grass out of paid home/station footprints")
 var report:={"checks":checks,"failures":failures,"profile":world_profile,"seed":world_seed,"distance_m":distance,"controller_frames":frames,"captured_frames":captured,"clip_fps":15,"route_complete":segment==route.size(),"stuck_frames":stuck,"start":[begin.x,begin.y,begin.z],"end":[player.position.x,player.position.y,player.position.z],"rows":walk_rows,"scope":"One daylight Forward+ walk, initial pose at woodland home; scripted ordinary walking with no jumps/teleports afterward. Paid home at meadow overlook. Impact is beyond this heartland route."}
 FileAccess.open(output.path_join("walk-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF03_WALK distance=",distance," frames=",frames," captures=",captured," failures=",failures)
 end_walk()
func still(filename: String) -> void:
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join("media/"+filename))
func end_walk() -> void:
 get_tree().quit(0 if failures==0 else 1)
