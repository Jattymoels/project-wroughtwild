extends "res://tests/rf05/water.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF05_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"904",output.path_join("private-world.json"))
 restore_run.call_deferred()
func restore_run() -> void:
 var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("private-world.json")))
 if not check(seed_controls.continue_saved(),"fresh-process ordinary Continue"):return finish_water("continue")
 quiet()
 print("RF05_CONTINUE restored; checking owners and surface contact")
 setup_lake()
 var restored: Dictionary=JSON.parse_string(JSON.stringify(SaveManager.new().capture(player),"",true,true))
 FileAccess.open(output.path_join("restore-drops-diagnostic.json"),FileAccess.WRITE).store_string(JSON.stringify({"saved":saved.world_drops,"restored":restored.world_drops},"\t",true,true))
 check(world_profile=="frontier_v8" and world_seed==77,"Continue selects saved identity before generation")
 check(_sim().export_json()==saved.sim,"exact native progression and possessions")
 for key in ["blocks","stations","contraptions","leylines","resource_nodes","world_drops","broken_blocks"]:
  check(restored.get(key,[])==saved.get(key,[]),"exact restored "+key)
 player.set_physics_process(true)
 terrain.set_process(true)
 for i in 30:await tick()
 check(player.swimming and absf(player.position.y-float(lake.surface_y)-.05)<.12,"Continue settles to surface pose")
 var drops:=[]
 var bundles:=[]
 WorldDrops._collect(self,drops,bundles,false)
 var pack: DroppedBundle=bundles[0]
 var paid: Dictionary=pack.contents.duplicate()
 check(await travel(pack.position-axis*1.8),"swim to floating death pack")
 player.rotation.y=atan2(-(pack.position.x-player.position.x),-(pack.position.z-player.position.z))
 pack.interact(player)
 check(_sim().inventory()==paid,"recover exactly the existing death pack")
 pack.interact(player)
 check(_sim().inventory()==paid,"second same-frame interaction cannot duplicate pack")
 check(await travel(Vector3(lake.x,0,lake.z)+axis*(float(lake.radius_m)+3)),"swim to opposite shore and walk out")
 for i in 20:await tick()
 check(not player.swimming and player.is_on_floor(),"opposite shore gives ordinary dry floor contact")
 check(player.velocity.is_finite(),"exit velocity remains valid")
 check(_sim().material_count("wood")==int(paid.get("wood",0))+3,"ordinary swimmer attraction recovers the three paid floating wood")
 # A paid solid block in shallow water supports the capsule above the surface.
 quiet()
 var shallow:=Vector3i.ZERO
 for k in range(8,int(lake.radius_m)+2):
  var p:=Vector3(lake.x,0,lake.z)+axis*k
  var col:=LakeWater.column(terrain.map,p.x,p.z)
  if not col.is_empty() and float(col.depth)<.8:
   shallow=Vector3i(floori(p.x),int(col.bed),floori(p.z))
   break
 check(shallow!=Vector3i.ZERO,"shallow bank has a supported building cell")
 if shallow!=Vector3i.ZERO:
  player.position=Vector3(shallow)+Vector3(0,2,3)
  var wood:=_sim().material_count("wood")
  var build:=player.placement
  build.set_build_mode_enabled(true)
  build.select_shape(&"cube")
  build.selected_material_family=&"wood"
  build.preview_element={"kind":"volume","axis":0,"cell":shallow*2}
  build.preview_visible=true
  check(build.try_place_block(),"ordinary paid block placed in shallows")
  build.set_build_mode_enabled(false)
  check(_sim().material_count("wood")==wood-2,"water does not change the paid block cost")
  ready_at(Vector3(shallow)+Vector3(.5,2.1,.5))
  for i in 25:await tick()
  check(player.is_on_floor() and not player.swimming and player.position.y-.94>float(lake.surface_y),"raised paid support provides dry standing above water")
  player.reset_environment_feedback()
  check(not player.swimming and not player.wading,"teleport/reset clears transient wet state")
 finish_water("continue")
