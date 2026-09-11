extends SceneTree
## Exercise the standalone scene's actual Space input and running process clock.
func _initialize()->void:call_deferred("run")
func key(pressed:bool)->void:
	var event:=InputEventKey.new();event.physical_keycode=KEY_SPACE;event.keycode=KEY_SPACE;event.pressed=pressed
	Input.parse_input_event(event)
func run()->void:
	var scene:Node3D=load("res://review.tscn").instantiate();root.add_child(scene)
	for i in 15:await process_frame
	scene.automatic=false
	var before:float=scene.clock_seconds
	for i in 8:await process_frame
	assert(scene.clock_seconds>before)
	key(true);await process_frame;key(false);await process_frame
	assert(scene.paused)
	var held:float=scene.clock_seconds
	for i in 16:await process_frame
	assert(scene.clock_seconds==held)
	for material:ShaderMaterial in scene.materials:assert(is_equal_approx(float(material.get_shader_parameter("clock_seconds")),held))
	key(true);await process_frame;key(false)
	for i in 8:await process_frame
	assert(not scene.paused and scene.clock_seconds>held)
	var f:=FileAccess.open("res://input-pause-check.json",FileAccess.WRITE);f.store_string(JSON.stringify({"space_input":true,"paused_frames":16,"materials":scene.materials.size(),"resume":true},"\t"))
	print("C4_INPUT_PAUSE_OK");quit()
