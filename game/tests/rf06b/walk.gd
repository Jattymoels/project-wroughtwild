extends "res://tests/rf06b/placement.gd"
var record_fen := false
var fen_ticks := 0
func tick() -> void:
 await super.tick()
 if record_fen:
  fen_ticks+=1
  if fen_ticks%4==0 and captured<40:
   await RenderingServer.frame_post_draw
   get_viewport().get_texture().get_image().save_jpg(output.path_join("media/swim-%03d.jpg"%captured),.9)
   captured+=1

func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF06B_OUTPUT")
 rendered=true
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("checked-world.json"))
 walk_fen.call_deferred()
func walk_fen() -> void:
 if not check(seed_controls.continue_saved(),"ordinary saved lake/home opens"):return finish_rf("walk")
 setup_lake()
 var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("expected.json")))
 fen_point=Vector3(expected.fen[0],expected.fen[1],expected.fen[2])
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"capture cannot seize mouse or focus")
 check(RenderingServer.get_current_rendering_method()=="forward_plus","one Forward+ renderer")
 set_physics_process(true)
 # Disclosed first staging at existing fen. All walking uses the normal controller.
 ready_at(fen_point+Vector3(0,1.1,0))
 player.rotation.y=PI*.5
 player.spring_arm.rotation.x=-.13
 for i in 60:await tick()
 await still("01-fen-ground.png")
 record_fen=true
 check(await travel(fen_point+Vector3(-4,0,0),180),"short ordinary fen passage")
 record_fen=false
 player.rotation.y=PI*.25
 await still("02-fen-opening.png")
 # Disclosed second staging avoids a long cross-world journey.
 ready_at(Vector3(home.x+.5,home.y+1.1,home.z+.5)-axis*4)
 player.rotation.y=atan2(-axis.x,-axis.z)
 player.spring_arm.rotation.x=-.12
 for i in 50:await tick()
 await still("03-lakeside-home.png")
 for point in [Vector3(535,0,614),Vector3(545,0,624),Vector3(lake.x,0,lake.z)+Vector3(-axis.z,0,axis.x)*4]:
  if not check(await travel(point),"connected home/shore waypoint "+str(point)):return finish_rf("walk")
 await still("04-water-and-bank.png")
 check(await travel(Vector3(lake.x,0,lake.z)+axis*(float(lake.radius_m)+3)),"actual swim-to-shore exit")
 for i in 20:await tick()
 player.rotation.y=atan2(axis.x,axis.z)
 player.spring_arm.rotation.x=-.12
 await still("05-planted-bank.png")
 check(not player.swimming and player.is_on_floor(),"natural dry shore exit")
 check(swim_frames>60 and wade_frames>0,"ordinary wade and swim states")
 check(player.is_physics_processing() and is_physics_processing() and terrain.is_processing() and mob_packs.is_physics_processing(),"ordinary world systems remain active")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"comfort flags retained")
 finish_rf("walk")
