extends Sandpit
## One disclosed placement outside a normal pack; subsequent movement is real.
var checks := 0
var failures := 0
var output := ""
var report := {}
var trace: Node
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ARRIVAL ", label)
	return ok
class EntryControls extends WorldSeedControls:
	var probe: Node
	func release() -> void:
		probe.check(load("res://art/scenery_resources.gd").ready() and not player.is_physics_processing(), "scenery ready before New World controls release")
		probe.check(load("res://art/creature_resources.gd").ready_for(player.inventory.get_sim()) and not player.is_physics_processing(), "full current roster prepared before controls release")
		super.release()

var startup_began := 0
func _ready() -> void:
	output = OS.get_environment("WROUGHTWILD_ARRIVAL_OUTPUT")
	trace = preload("res://scripts/play03_trace.gd").install(self, PackedStringArray(["--play03-trace="+output]))
	world_seed = 77
	world_profile = "frontier_v8"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 120
	startup_began = Time.get_ticks_usec()
	seed_controls = EntryControls.new()
	seed_controls.probe = self
	add_child(seed_controls)
	seed_controls.configure(self,"77",output.path_join("private-world.json"))
	player.class_panel.choose("warden")
	_await_entry.call_deferred()
func _await_entry() -> void:
	while not seed_controls.finished: await get_tree().process_frame
	report["world_setup_ms"] = (Time.get_ticks_usec()-startup_began)/1000.0
	trace.note_arrival("controls_ready",Time.get_ticks_usec())
	_run()
func _run() -> void:
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS),"mouse-free nonfocusing capture")
	var selected := {}
	var best := INF
	for p: Dictionary in mob_packs.packs:
		if p.biome=="cave" or not "hollow_knight" in p.enemies: continue
		var den := mob_packs.pack_position(p)
		for angle in range(0,360,45):
			var candidate := den + Vector3(55,0,0).rotated(Vector3.UP,deg_to_rad(angle))
			if candidate.x<48 or candidate.z<48 or candidate.x>976 or candidate.z>976: continue
			candidate.y=terrain.height_at(floori(candidate.x),floori(candidate.z))+1.1
			var near := []
			var ids := []
			var clear := true
			for other: Dictionary in mob_packs.packs:
				var d := mob_packs.pack_position(other).distance_to(candidate)
				if d<40: clear=false;break
				if d<85 and not other.grazer:
					near.append(other.index)
					ids.append_array(Array(other.enemies))
			if not clear or not "cinder_archer" in ids or not "cinder_wisp" in ids: continue
			var score := ids.size()*1000+candidate.distance_to(player.position)
			if score<best:
				best=score
				selected={"position":candidate,"facing":den,"packs":near,"ids":ids}
	if not check(not selected.is_empty(),"native cluster contains reported trio outside activation"):
		finish();return
	player.position=selected.position
	player.velocity=Vector3.ZERO
	var direction: Vector3=((selected.facing-player.position)*Vector3(1,0,1)).normalized()
	player.rotation.y=atan2(-direction.x,-direction.z)
	player.spring_arm.rotation.x=-.08
	report["initial_position"]=[player.position.x,player.position.y,player.position.z]
	report["yaw"]=player.rotation.y
	trace.note_arrival("fixture_position",Time.get_ticks_usec())
	for i in 90: await get_tree().process_frame
	report["walk_start_frame"]=Engine.get_process_frames()
	player.test_walk=Vector2(0,-1)
	for i in 30: await get_tree().process_frame
	player.test_walk=Vector2.ZERO
	check(player.is_on_floor() and player.position.y>0,"valid grounded in-map approach")
	var expected := []
	for p: Dictionary in mob_packs.nearby_dormant_packs(player.position,90):
		if not p.grazer and mob_packs.pack_position(p).distance_to(player.position)<=90:
			expected.append({"index":p.index,"ids":Array(p.enemies),"position":str(mob_packs.pack_position(p))})
	report["expected_packs"]=expected
	report["trigger_position"]=[player.position.x,player.position.y,player.position.z]
	report["trigger_frame"]=Engine.get_process_frames()
	var began := Time.get_ticks_usec()
	var woken := mob_packs.noise_at(player.position,"horn")
	trace.note_arrival("group_horn",began,{"woken":woken})
	check(woken>0,"existing horn propagation wakes native group")
	report["group"]=[]
	for p: Dictionary in expected:
		var live: Dictionary=mob_packs.packs[p.index]
		var ids:=[]
		for e: Enemy in live.members: ids.append(String(e.enemy_id))
		check(live.spawned and ids==p.ids,"full ordered generated pack %d"%p.index)
		report.group.append({"index":p.index,"ids":ids})
	var began_ms := Time.get_ticks_msec()
	while Time.get_ticks_msec()-began_ms<2200: await get_tree().process_frame
	report["recovery_end_frame"]=Engine.get_process_frames()
	check(player.is_physics_processing() and mob_packs.is_physics_processing() and terrain.is_processing(),"normal world processing remains active")
	check(terrain.world_profile()=="frontier_v8" and terrain.map.lakes.size()==1,"RF05 lake remains")
	# The retained mob route faces away from the source. Turn the existing camera
	# toward it for an explicit first-view sample, outside the approach timings.
	var target: ResourceNode = terrain.resource_stream.active.get("wnv6_rsv6_pullstone_primary_1_specimen")
	check(target != null,"measured pullstone is live for first-view check")
	if target != null:
		var delta_at := target.global_position+Vector3.UP*.7-player.camera.global_position
		player.rotation.y=atan2(-delta_at.x,-delta_at.z)
		player.spring_arm.rotation.x=atan2(delta_at.y,Vector2(delta_at.x,delta_at.z).length())
		report["first_view_frame"]=Engine.get_process_frames()
		trace.note_arrival("scenery_first_view",Time.get_ticks_usec(),{"visual":"pullstone"})
		await RenderingServer.frame_post_draw
		check(player.camera.is_position_in_frustum(target.global_position+Vector3.UP*.7),"pullstone lies inside actual first-view camera frustum")
		for i in 30: await get_tree().process_frame
		report["first_view_end_frame"]=Engine.get_process_frames()
		# Private, owner-invoked near-source save: a supported pose, no added items.
		var private_save: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.get_base_dir().path_join("arrival-start.json")))
		var at := Vector3(target.position.x,0,target.position.z-12)
		at.y=terrain.height_at(floori(at.x),floori(at.z))+1.1
		private_save.player.position=[at.x,at.y,at.z]
		private_save.player.yaw=PI
		private_save.player.pitch=-.08
		report["private_pose"]=[at.x,at.y,at.z]
		FileAccess.open(output.get_base_dir().path_join("scenery-start.json"),FileAccess.WRITE).store_string(JSON.stringify(private_save,"",true,true))
	# Separate repeated-source attachment probe after ordinary travel/recovery.
	report["sources"]=[]
	for kind: String in StrangeResourceArt.IDS:
		for id: String in terrain.resource_stream.records.keys():
			if terrain.resource_stream.records[id].visual != kind: continue
			for repeat in 2:
				if terrain.resource_stream.active.has(id):
					var old: ResourceNode = terrain.resource_stream.active[id]
					old.get_parent().remove_child(old)
					old.free()
				var source_began := Time.get_ticks_usec()
				var node := terrain.resource_stream.materialise(id)
				report.sources.append({"kind":kind,"repeat":repeat,"ms":(Time.get_ticks_usec()-source_began)/1000.0,"id":id})
				check(node != null and node.remaining_units>0,"complete source "+kind)
			break
	finish()
func finish() -> void:
	trace.stop("scenery_complete")
	report.merge({"checks":checks,"failures":failures,"trace":trace.output_path})
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("SCENERY_RESULT ",JSON.stringify(report))
	get_tree().quit(0 if failures==0 else 1)
