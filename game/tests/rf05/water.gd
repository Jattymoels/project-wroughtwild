extends "res://tests/rf01/placement.gd"
var lake: Dictionary
var home: Dictionary
var axis:=Vector3.ZERO
var swim_frames:=0
var wade_frames:=0
var switches:=0
var last_swim:=false
var rows:=[]
var captured:=0
var rendered:=false
var route_distance:=0.0
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF05_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 player.class_panel.choose("warden")
 _water_run.call_deferred()
func setup_lake() -> void:
 lake=terrain.map.lakes[0]
 for h: Dictionary in terrain.map.home_sites:
  if h.id==lake.home_id:home=h
 axis=Vector3(cos(float(lake.angle)),0,sin(float(lake.angle)))
func ready_at(at: Vector3) -> void:
 terrain.ensure_area(at,32)
 terrain.resource_stream.focus(at,true)
 player.position=at
 player.velocity=Vector3.ZERO
 player.reset_environment_feedback()
 player.set_physics_process(true)
func tick() -> void:
 await get_tree().physics_frame
 await get_tree().process_frame
func travel(target: Vector3, limit:=2000) -> bool:
 var previous:=player.position
 var progress:=previous
 var stuck:=0
 for frame in limit:
  var offset: Vector3=(target-player.position)*Vector3(1,0,1)
  if offset.length()<.5:
   player.test_walk=Vector2.ZERO
   return true
  player.rotation.y=atan2(-offset.x,-offset.z)
  player.test_walk=Vector2(0,-1)
  await tick()
  route_distance+=((player.position-previous)*Vector3(1,0,1)).length()
  previous=player.position
  if player.swimming:swim_frames+=1
  elif player.wading:wade_frames+=1
  if last_swim!=player.swimming:switches+=1;last_swim=player.swimming
  if frame%30==0:
   rows.append({"position":[player.position.x,player.position.y,player.position.z],"swim":player.swimming,"wade":player.wading,"floor":player.is_on_floor()})
   if ((player.position-progress)*Vector3(1,0,1)).length()<.2:stuck+=30
   else:stuck=0
   progress=player.position
  if rendered and (wade_frames>3 or swim_frames>0) and captured<120 and frame%4==0:
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_jpg(output.path_join("media/swim-%03d.jpg"%captured),.9)
   captured+=1
  if stuck>=120:break
 player.test_walk=Vector2.ZERO
 return false
func still(name: String) -> void:
 await RenderingServer.frame_post_draw
 get_viewport().get_texture().get_image().save_png(output.path_join("media/"+name))
func _water_run() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 quiet()
 setup_lake()
 check(world_profile=="frontier_v8","ordinary New World uses V8")
 check(terrain.reclaimed_cover!=null and terrain._rf02_biome_mask!=null and mob_packs._indexed,"adopted art and streaming enabled")
 await _gather()
 quiet()
 var at:=Vector3(home.x+.5,home.y+1.1,home.z+.5)
 ready_at(at)
 for i in 15:await tick()
 quiet()
 var count_before:=_sim().material_count("wood")
 var target:=Vector3i(int(home.x),int(home.y),int(home.z))
 for dz in range(-1,2):
  for dx in range(-1,2):check(place(&"floor_slab",target+Vector3i(dx,0,dz)),"paid lakeside home floor")
 check(_sim().material_count("wood")==count_before-9,"lakeside construction keeps exact payment")
 # The controlled acquisition/setup ends here. The connected route uses the
 # actual controller from a dry pose just beside the paid floor.
 ready_at(at-axis*4)
 terrain.set_process(true)
 for i in 20:await tick()
 check(player.is_on_floor() and not player.swimming,"dry home support")
 # Ordinary sidestep around the finite boulders beside the home supply skirt.
 for point in [Vector3(535,0,614),Vector3(545,0,624),Vector3(lake.x,0,lake.z)]:
  if not check(await travel(point),"connected home/shore waypoint "+str(point)):return finish_water("water")
 check(swim_frames>60 and wade_frames>0 and player.swimming,"grounded wading transitions into sustained surface swimming")
 check(player.camera.global_position.y>float(lake.surface_y)+.5,"camera stays above water")
 var steps:=player.footsteps.step_count
 Input.action_press("jump")
 for i in 30:await tick()
 Input.action_release("jump")
 check(player.swimming and player.footsteps.step_count==steps and absf(player.position.y-float(lake.surface_y)-.05)<.12,"jump does not pop afloat; no walking footsteps")
 quiet()
 # Save one paid, uncollected material drop with its existing age/ownership.
 check(player.drop_material(&"wood",3),"drop consumes three carried wood")
 var drops:=[]
 var bundles:=[]
 WorldDrops._collect(self,drops,bundles,false)
 var chip: Pickup=drops.back()
 chip.position=Vector3(lake.x,float(lake.surface_y)-.3,lake.z)+axis*6
 chip._age=37.0
 chip.settle_water()
 chip.set_physics_process(false)
 check(absf(chip.position.y-float(lake.surface_y)-.06)<.01 and chip._age==37 and chip.amount==3,"paid pickup floats locally without age or amount change")
 # Real death creates the existing exact bundle at this horizontal lake pose.
 var death_position:=player.position
 var carried: Dictionary=_sim().inventory()
 player._on_died()
 WorldDrops._collect(self,drops,bundles,false)
 var pack: DroppedBundle=bundles.back()
 pack.set_physics_process(false)
 check(not player.swimming and pack.contents==carried and Vector2(pack.position.x,pack.position.z)==Vector2(death_position.x,death_position.z),"death resets swimming and keeps exact pack locally")
 check(absf(pack.position.y-float(lake.surface_y)-.06)<.01,"death pack floats within swimmer reach")
 # Explicit save fixture positioning after death; not counted as traversal.
 ready_at(death_position-axis*5)
 for i in 30:await tick()
 quiet()
 check(player.swimming,"afloat save fixture settles from world contact")
 check(SaveManager.new().write(output.path_join("private-world.json"),player),"save afloat with exact paid home and floating owners")
 # Basin edits do not enlarge the query below its original bed.
 var wet:=LakeWater.column(terrain.map,lake.x,lake.z)
 var below:=Vector3i(int(lake.x),int(wet.bed)-1,int(lake.z))
 check(terrain.break_block(below.x,below.y,below.z)!="","lake bed remains diggable")
 check(LakeWater.contact(terrain,Vector3(below)+Vector3(.5,.5,.5)).is_empty(),"dug space below original bed stays dry")
 var outside:=Vector3(lake.min_x-1,float(lake.surface_y)-1,lake.z)
 check(LakeWater.contact(terrain,outside).is_empty(),"outside original footprint stays dry")
 check(switches<=4,"entry has no repeated swim-state flicker")
 finish_water("water")
func finish_water(job: String) -> void:
 player.test_walk=Vector2.ZERO
 Input.action_release("jump")
 var report:={"checks":checks,"failures":failures,"swim_frames":swim_frames,"wade_frames":wade_frames,"transitions":switches,"distance_m":route_distance,"captured_frames":captured,"clip_fps":15,"lake":{ "x":lake.get("x"),"z":lake.get("z"),"surface":lake.get("surface_y"),"home":home},"rows":rows}
 FileAccess.open(output.path_join(job+"-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
 print("RF05_",job.to_upper()," ",checks," checks / ",failures," failures; swim=",swim_frames," wade=",wade_frames)
 get_tree().quit(0 if failures==0 else 1)
