extends "res://tests/rf05/water.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF05_OUTPUT")
 rendered=true
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 walk_run.call_deferred()
func walk_run() -> void:
 if not check(seed_controls.continue_saved(),"ordinary saved lake/home opens"):return finish_water("walk")
 setup_lake()
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"capture cannot seize mouse or focus")
 check(RenderingServer.get_current_rendering_method()=="forward_plus","one Forward+ renderer")
 # One disclosed initial dry-home placement. No further pose assignments.
 ready_at(Vector3(home.x+.5,home.y+1.1,home.z+.5)-axis*4)
 player.rotation.y=atan2(-axis.x,-axis.z)
 player.spring_arm.rotation.x=-.12
 set_physics_process(true)
 for i in 50:await tick()
 await still("01-lakeside-home.png")
 # Ordinary sidestep around the finite boulders beside the home supply skirt.
 for point in [Vector3(535,0,614),Vector3(545,0,624),Vector3(lake.x,0,lake.z)+Vector3(-axis.z,0,axis.x)*4]:
  if not check(await travel(point),"connected home/shore waypoint "+str(point)):return finish_water("walk")
 await still("02-surface-swimming.png")
 check(await travel(Vector3(lake.x,0,lake.z)+axis*(float(lake.radius_m)+3)),"actual swim-to-opposite-shore exit")
 for i in 20:await tick()
 player.rotation.y=atan2(axis.x,axis.z)
 player.spring_arm.rotation.x=-.12
 await still("03-shore-outlook.png")
 check(not player.swimming and player.is_on_floor(),"natural exit to dry land")
 check(captured==120 and swim_frames>60 and wade_frames>0,"eight-second clip and wade/swim states captured")
 check(player.is_physics_processing() and is_physics_processing() and terrain.is_processing() and mob_packs.is_physics_processing(),"ordinary physics/world work stayed active")
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"comfort flags retained throughout")
 finish_water("walk")
