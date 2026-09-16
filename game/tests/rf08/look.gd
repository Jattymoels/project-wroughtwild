extends "res://tests/rf05/water.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF08_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("look-world.json"))
 player.class_panel.choose("warden")
 look.call_deferred()
func aim(at: Vector3) -> void:
 var delta:=at-player.camera.global_position
 player.rotation.y=atan2(-delta.x,-delta.z)
 player.spring_arm.rotation.x=atan2(delta.y,Vector2(delta.x,delta.z).length())
func look() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("scout.json")))
 var candidate: Dictionary=source.candidates[2]
 var p: Array=candidate.at
 var c: Array=candidate.centre
 var centre:=Vector3(c[0],c[1],c[2])
 var along:=(Vector3(p[0],0,p[2])-centre*Vector3(1,0,1)).normalized()
 var point:=Vector3(p[0],0,p[2])+along*5
 point.y=terrain.height_at(floori(point.x),floori(point.z))+1.1
 ready_at(point)
 set_physics_process(true)
 terrain.set_process(true)
 for i in 40:await tick()
 aim(centre+Vector3.UP*2)
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"free mouse/no focus")
 await still("early-recovery.png")
 point=Vector3(p[0],float(p[1])+1.1,p[2])
 ready_at(point)
 for i in 30:await tick()
 aim(centre+Vector3.UP*2)
 await still("early-impact.png")
 aim(Vector3(p[0]-2,terrain.height_at(floori(p[0]-2),floori(p[2]-2)),p[2]-2))
 await still("early-scar.png")
 print("RF08_LOOK ",checks," checks; failures ",failures)
 get_tree().quit(0 if failures==0 else 1)
