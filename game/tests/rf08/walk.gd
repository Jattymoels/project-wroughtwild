extends "res://tests/rf08/placement.gd"
var recording:=false
var last_capture_ms:=0
var frame_times: Array[int]=[]
func tick() -> void:
 await super.tick()
 if recording and Time.get_ticks_msec()-last_capture_ms>=100:
  await RenderingServer.frame_post_draw
  last_capture_ms=Time.get_ticks_msec()
  frame_times.append(last_capture_ms)
  get_viewport().get_texture().get_image().save_jpg(output.path_join("media/walk-%03d.jpg"%captured),.94)
  captured+=1
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF08_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("checked-world.json"))
 walk_recovery.call_deferred()
func face(target: Vector3) -> void:
 var offset:=target-player.camera.global_position
 player.rotation.y=atan2(-offset.x,-offset.z)
 player.spring_arm.rotation.x=atan2(offset.y,Vector2(offset.x,offset.z).length())
func walk_recovery() -> void:
 if not check(seed_controls.continue_saved(),"ordinary Continue opens recovered impact"):return finish_rf("walk")
 read_bench()
 var approach: PackedVector3Array
 for impact: Dictionary in terrain.map.impacts:
  if impact.id==selected.impact:approach=impact.approach
 var route: Array[Vector3]=[]
 for i in range(maxi(0,approach.size()-25),approach.size()):
  var point:=approach[i]
  if Vector2(point.x-impact_centre.x,point.z-impact_centre.z).length()<5.0:break
  route.append(point)
 check(route.size()>8,"real native approach provides a short connected walking route")
 if route.size()<9:return finish_rf("walk")
 ready_at(route[0]+Vector3.UP*1.1) # One disclosed initial staging on the native approach.
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"capture keeps mouse/focus free")
 check(RenderingServer.get_current_rendering_method()=="forward_plus","Forward+ renderer")
 set_physics_process(true)
 terrain.set_process(true)
 for i in 60:await tick()
 face(impact_centre+Vector3.UP*2)
 await still("01-recovered-impact.png")
 var reached:=true
 for i in range(1,route.size()-4):
  if not await travel(route[i],180):reached=false;break
 check(reached,"ordinary walk along native impact approach")
 face(impact_centre+Vector3(0,1,0))
 print("RF08_ROUTE ",route," actual player ",player.position)
 await still("02-living-scar.png")
 var cat: CataclysmSites=get_node("CataclysmSites")
 var start_clock:=cat._fissures.clock_seconds
 recording=true
 var started:=Time.get_ticks_msec()
 while Time.get_ticks_msec()-started<9500:await tick()
 recording=false
 check(cat._fissures.clock_seconds-start_clock>9.0,"observable pulse uses real unaccelerated time")
 FileAccess.open(output.path_join("frame-times.json"),FileAccess.WRITE).store_string(JSON.stringify(frame_times))
 var material: ShaderMaterial=cat._fissures._material
 var strength: float=material.get_shader_parameter("emission_strength")
 material.set_shader_parameter("emission_strength",0.0)
 await tick()
 await still("04-emission-disabled.png")
 material.set_shader_parameter("emission_strength",strength)
 check(float(material.get_shader_parameter("emission_strength"))==strength,"normal emission restored after physical readability view")
 var ended:=true
 for i in range(route.size()-4,route.size()):
  if not await travel(route[i],180):ended=false;break
 check(ended,"ordinary walking continues beside the impact")
 face(impact_centre+Vector3(0,1.5,0))
 await still("03-growth-and-fragments.png")
 check(player.is_physics_processing() and is_physics_processing() and terrain.is_processing() and mob_packs.is_physics_processing(),"normal world, collision, mobs and HUD remain active")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"comfort retained throughout")
 finish_rf("walk")
