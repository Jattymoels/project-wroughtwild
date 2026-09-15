extends "res://tests/rf06/walk.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF06B_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"77",output.path_join("private-world.json"))
 early_look.call_deferred()
func early_look() -> void:
 if not check(seed_controls.continue_saved(),"normal affected Continue"):return finish_rf("look")
 set_physics_process(true)
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"mouse and focus stay free")
 ready_at(Vector3(336.5,33.1,680.5))
 player.rotation.y=PI*.5
 player.spring_arm.rotation.x=-.13
 for i in 50:await tick()
 await still("early-fen.png")
 check(await travel(Vector3(332.5,32,680.5),180),"ordinary passage")
 player.rotation.y=PI*.25
 await still("early-passage.png")
 finish_rf("look")
