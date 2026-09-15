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
	# Bounded distinct presentation pass; actual Enemy.spawn, one per native ID.
	# This is separate from the generated group and never a fabricated encounter.
	report["roster"]=[]
	var original := _sim().export_json()
	# Separate finite coverage phase, after the natural group has recovered.
	# Select LF so the native catalogue includes all five aliases too.
	check(_sim().set_world_profile("living_frontier_wave3"),"native LF roster selected for separate coverage")
	load("res://art/creature_resources.gd").prepare(_sim(),trace)
	for native_id: String in _sim().enemy_ids():
		var def: Dictionary = _sim().enemy(native_id)
		var start := Time.get_ticks_usec()
		var e := Enemy.spawn(self,StringName(def.id),player.position+Vector3(0,0,-8))
		var elapsed := (Time.get_ticks_usec()-start)/1000.0
		var m := e._mesh.get_node("Motion") as CreatureMotion
		report.roster.append({"id":String(e.enemy_id),"visual_id":e.visual_id,"spawn_ms":elapsed,"frame":Engine.get_process_frames(),"bones":m.rig.get_bone_count(),"visible":m.finished.model.is_visible_in_tree() if m.finished!=null else e._mesh.is_visible_in_tree()})
		check(m.rig.get_bone_count()>0,"complete rig for "+String(e.enemy_id))
		await get_tree().process_frame
		await get_tree().process_frame
		e.free()
	check(_sim().import_json(original),"coverage native state restored")
	report["bosses"]=[]
	var start := Time.get_ticks_usec()
	var boss := Boss.spawn_boss(self,player.position+Vector3(0,0,-8))
	report.bosses.append({"id":String(boss.enemy_id),"spawn_ms":(Time.get_ticks_usec()-start)/1000.0,"frame":Engine.get_process_frames()})
	check(boss._mesh.get_meta("authored_actor_id")=="forge_tyrant","Tyrant/Warden/capstone share the preserved body")
	await get_tree().process_frame
	await get_tree().process_frame
	boss.free()
	var central := preload("res://tests/central_fixture.gd").ready_rules(_sim(),original)
	check(not central.is_empty() and _sim().import_json(central),"retained Central prerequisites for separate human coverage")
	check(_sim().trial_start_story(618,"forge_capstone"),"native Central selects actual Conservator")
	start=Time.get_ticks_usec()
	var human := Boss.spawn_boss(self,player.position+Vector3(0,0,-8)) as Conservator
	report.bosses.append({"id":String(human.enemy_id),"spawn_ms":(Time.get_ticks_usec()-start)/1000.0,"frame":Engine.get_process_frames()})
	check(human.arms.size()==2 and human.harness.is_visible_in_tree(),"complete procedural human and harness")
	await get_tree().process_frame
	await get_tree().process_frame
	human.free()
	_sim().trial_abandon()
	check(_sim().trial_end(),"temporary boss trial settles before restoration")
	check(_sim().import_json(original),"boss coverage restores native state")
	finish()
func finish() -> void:
	trace.stop("group_complete")
	report.merge({"checks":checks,"failures":failures,"trace":trace.output_path})
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("GROUP_RESULT ",JSON.stringify(report))
	get_tree().quit(0 if failures==0 else 1)
