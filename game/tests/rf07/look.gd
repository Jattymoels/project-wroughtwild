extends "res://tests/rf05/water.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF07_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("look-world.json"))
 player.class_panel.choose("warden")
 look.call_deferred()
func look() -> void:
 while not seed_controls.finished:await get_tree().process_frame
 var source: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("scout.json")))
 var p: Array=source.candidates[0].at
 var at:=Vector3(p[0],p[1]+1.1,p[2])
 ready_at(at)
 player.rotation.y=-PI*.50
 player.spring_arm.rotation.x=-.10
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"free mouse/no focus")
 check(terrain.highland_cover!=null,"ordinary New World highland recovery")
 for i in 50:await tick()
 await still("early-highland.png")
 player.rotation.y=PI*.55
 await still("early-outlook.png")
 check(SaveManager.new().write(output.path_join("look-world.json"),player),"private scene save")
 print("RF07_LOOK ",checks," checks; failures ",failures)
 get_tree().quit(0 if failures==0 else 1)
