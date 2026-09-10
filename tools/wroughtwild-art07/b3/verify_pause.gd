extends SceneTree
## Exercise the interactive clock path; capture mode's manual clock is not a pause test.
func _initialize()->void:
	call_deferred("run")
func run()->void:
	var scene:Node3D=load("res://review.tscn").instantiate();root.add_child(scene)
	for i in 16:await process_frame
	assert(scene.entries.size()==9 and not scene.mats.is_empty(),"Imported kit and scar materials must exist")
	scene.automatic=false;scene.paused=false;scene.set_time(1.0)
	scene._process(.25);assert(is_equal_approx(scene.clock_seconds,1.25))
	var key:=InputEventKey.new();key.physical_keycode=KEY_SPACE;key.pressed=true
	scene._unhandled_input(key);assert(scene.paused)
	scene._process(.5);assert(is_equal_approx(scene.clock_seconds,1.25))
	for mat in scene.mats:assert(is_equal_approx(mat.get_shader_parameter("clock_seconds"),1.25))
	scene._unhandled_input(key);assert(not scene.paused)
	scene._process(.25);assert(is_equal_approx(scene.clock_seconds,1.5))
	for mat in scene.mats:assert(is_equal_approx(mat.get_shader_parameter("clock_seconds"),1.5))
	print("B3_INTERACTIVE_PAUSE_OK clock advances, Space freezes every scar uniform, Space resumes")
	quit()
