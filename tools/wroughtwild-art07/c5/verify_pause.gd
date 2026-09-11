extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var review:Node3D=load("res://c5/review.tscn").instantiate();root.add_child(review)
	for i in 8:await process_frame
	assert(not review.automatic)
	var event:=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.pressed=true;review._unhandled_input(event)
	var before:float=review.clock_seconds
	for i in 10:await process_frame
	assert(review.paused and review.clock_seconds==before)
	for mat in review.mats:assert(mat.get_shader_parameter("clock_seconds")==before)
	review._unhandled_input(event)
	for i in 10:await process_frame
	assert(not review.paused and review.clock_seconds>before)
	print("C5_INTERACTIVE_PAUSE_OK ",review.mats.size());quit()
