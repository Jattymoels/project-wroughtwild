extends "res://tests/rf05/water.gd"
func _ready() -> void:
 output=OS.get_environment("WROUGHTWILD_RF09_OUTPUT")
 set_physics_process(false)
 seed_controls=SEED_CONTROLS.new()
 add_child(seed_controls)
 seed_controls.configure(self,"904",output.path_join("fixtures/rf07/checked-world.json"))
 look.call_deferred()
func look() -> void:
 if not check(seed_controls.continue_saved(),"ordinary Continue opens retained highland"):return get_tree().quit(1)
 set_physics_process(true)
 ready_at(Vector3(846.5,70.1,708.5))
 player.rotation.y=PI*.5
 player.spring_arm.rotation.x=-.10
 for i in 50:await tick()
 check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"free mouse/no focus")
 await still("early-highland.png")
 print("RF09_LOOK ",checks," checks; failures ",failures)
 get_tree().quit(0 if failures==0 else 1)