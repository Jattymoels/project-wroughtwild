extends Sandpit
## Private copy of the original paid-home starting checkpoint; not an incident save.
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL PLAY01 CONTINUE: ",label)
func _ready()->void:
	set_physics_process(false)
	var checkpoint:=ProjectSettings.globalize_path("res://../build/play01/paid-home-original.json")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--play01-checkpoint="):checkpoint=arg.trim_prefix("--play01-checkpoint=")
	seed_controls=SEED_CONTROLS.new()
	add_child(seed_controls)
	seed_controls.configure(self,"77",checkpoint)
	_run.call_deferred()
func quiet()->void:
	for subject in [self,player.combat,player.placement,mob_packs]:subject.set_physics_process(false)
	mob_packs.set_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"):enemy.set_physics_process(false)
func _run()->void:
	check(seed_controls.continue_saved(),"normal Continue handler restores original paid checkpoint")
	quiet()
	if failures>0:
		get_tree().quit(1)
		return
	check(player.is_physics_processing(),"Continue restores normal movement processing")
	check(world_seed==77 and world_profile=="living_frontier_wave3","original world identity retained")
	var manager:=SaveManager.new()
	var before:Dictionary=manager.capture(player)
	var owned:=_sim().export_json()
	check(not before.blocks.is_empty() and not before.stations.is_empty(),"paid home and stations are present")
	for i in 20:await get_tree().physics_frame
	check(player.is_on_floor(),"saved home has actual capsule floor contact")
	var began:=player.position
	# Select a clear short direction at the saved home; use capsule sweeps,
	# not a teleport or a guessed incident coordinate.
	var direction:=Vector3.ZERO
	for candidate in [Vector3.RIGHT,Vector3.LEFT,Vector3.FORWARD,Vector3.BACK]:
		if not player.test_move(player.global_transform,candidate*0.8):
			direction=candidate
			break
	check(direction!=Vector3.ZERO,"saved home has a clear short walking direction")
	player.rotation.y=0
	player.test_walk=Vector2(direction.x,direction.z)
	for i in 8:await get_tree().physics_frame
	player.test_walk=Vector2.ZERO
	check(player.position.distance_to(began)>0.3,"actual controller moves after Continue")
	player.set_physics_process(false)
	var surface:=terrain.rendered_height(player.position.x,player.position.z,player.position.y-0.96,2.0)
	check(is_finite(surface) and player.position.y-0.96>=surface-0.002,"player stays above current terrain at paid home")
	check(_sim().export_json()==owned,"short movement preserves exact native progression and possessions")
	check(manager.write("user://play01-resaved.json",player),"save checked private home")
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://play01-resaved.json"))
	check(player.load_game("user://play01-resaved.json"),"ordinary reload accepts the current checkpoint")
	quiet()
	player.set_physics_process(false)
	var restored:Dictionary=JSON.parse_string(JSON.stringify(manager.capture(player)))
	check(_sim().export_json()==saved.sim,"native ownership round-trips exactly")
	for key in ["blocks","stations","contraptions","leylines","resource_nodes","world_drops"]:
		check(restored[key]==JSON.parse_string(JSON.stringify(saved[key])),"exact saved ownership: "+key)
	# Restore's immediate focus finishes pending overlays. Incremental travel
	# keeps the original native ribbon/collision while decoration is pending.
	terrain.resource_stream.focus(player.position,true)
	check(terrain.resource_stream._projection_pending.is_empty(),"explicit immediate focus completes all seam overlays")
	print("PLAY01_CONTINUE %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)
