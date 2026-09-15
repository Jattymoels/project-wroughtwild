extends Sandpit
var checks := 0
var failures := 0
var output := ""
var trace: Node
var build_hold_checked := false
class EntryControls extends WorldSeedControls:
	var probe: Node
	func release() -> void:
		probe.check(FinishedFauna.resources_ready(),"Continue resource preparation is complete before control release")
		super.release()
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL PRESENTATION ",label)
	return ok
func _ready() -> void:
	output = OS.get_environment("WROUGHTWILD_ARRIVAL_OUTPUT")
	trace = preload("res://scripts/play03_trace.gd").install(self,PackedStringArray(["--play03-trace="+output]))
	seed_controls = EntryControls.new()
	seed_controls.probe = self
	add_child(seed_controls)
	seed_controls.configure(self,"77",output.get_base_dir().path_join("arrival-start.json"))
	_run.call_deferred()
func _build_world(seed_value: int) -> void:
	check(not player.is_physics_processing() and not player.is_processing_unhandled_input(),"fresh-process Continue holds movement/input during actual preparation")
	var count := get_tree().get_nodes_in_group("enemies").size()
	super._build_world(seed_value)
	check(FinishedFauna.resources_ready() and get_tree().get_nodes_in_group("enemies").size()==count,"preparation builds no live/invisible enemies")
	build_hold_checked = true
func _run() -> void:
	check(FinishedFauna._scenes.is_empty() and FinishedFauna._materials.is_empty(),"fresh-process resources start unprepared")
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(seed_controls.save_path))
	var began := Time.get_ticks_usec()
	if not check(seed_controls.continue_saved(),"ordinary Continue loads the retained private RF05 save"):
		finish({})
		return
	var loaded_ms := (Time.get_ticks_usec()-began)/1000.0
	check(build_hold_checked and player.is_physics_processing() and player.is_processing_unhandled_input(),"normal Continue releases controls after preparation")
	check(_sim().export_json()==String(saved.sim),"exact saved native possessions/progression preserved")
	check(terrain.world_profile()=="frontier_v8" and terrain.seed_value()==77 and terrain.map.lakes.size()==1,"V8 identity and lake remain")
	check(mob_packs.loot_kill_counter()==int(saved.loot_kill_counter),"saved loot sequence remains exact")
	var captured: Dictionary = JSON.parse_string(JSON.stringify(SaveManager.new().capture(player),"",true,true))
	check(captured.blocks==saved.blocks and captured.stations==saved.stations,"paid buildings and stations preserved")
	check(captured.world_drops==saved.world_drops,"loose-drop/death-pack ownership preserved")
	check(player.position.distance_to(Vector3(saved.player.position[0],saved.player.position[1],saved.player.position[2]))<.001,"disclosed outside-activation pose restored exactly")
	check(not mob_packs.packs[176].spawned and mob_packs.pack_position(mob_packs.packs[176]).distance_to(player.position)>28,"prepared selected pack remains dormant outside range")
	var native := _sim().export_json()
	var scenes := FinishedFauna._scenes.duplicate()
	var materials := FinishedFauna._materials.duplicate()
	var count := get_tree().get_nodes_in_group("enemies").size()
	began = Time.get_ticks_usec()
	FinishedFauna.prepare_world(trace)
	var repeated_ms := (Time.get_ticks_usec()-began)/1000.0
	check(FinishedFauna._scenes==scenes and FinishedFauna._materials==materials,"repeat preparation reuses existing resources")
	check(get_tree().get_nodes_in_group("enemies").size()==count and _sim().export_json()==native,"repeat preparation creates no actors or ownership changes")
	var a := Enemy.spawn(self,&"ember_whelp",player.position+Vector3(30,0,0))
	var b := Enemy.spawn(self,&"lf_red_boar",player.position+Vector3(35,0,0))
	var am := (a._mesh.get_node("Motion") as CreatureMotion).finished
	var bm := (b._mesh.get_node("Motion") as CreatureMotion).finished
	check(am.material!=bm.material and am.material!=materials.boar and bm.material!=materials.boar,"cached templates still create independent per-actor materials")
	check(bm.material.get_shader_parameter("core_colour")==FrontierHostLook.PALETTE.red,"LF alias retains its channel colour")
	a._flash_left = .1
	am.refresh_status()
	bm.refresh_status()
	check(bool(am.material.get_shader_parameter("status_active")) and not bool(bm.material.get_shader_parameter("status_active")),"status cannot leak between prepared actors")
	check(materials.boar.get_shader_parameter("status_active")==null,"shared template retains its shader default instead of actor status")
	check(am.model.is_visible_in_tree() and bm.model.is_visible_in_tree() and a._mesh.layers==0 and b._mesh.layers==0,"whole adopted models appear with hidden envelopes")
	check(a.attack_released.get_connections().size()==1 and b.attack_released.get_connections().size()==1,"one animation release listener per actor retained")
	a.free()
	b.free()
	check(_sim().export_json()==native,"presentation spawn/teardown preserves exact native state")
	finish({"continue_ms":loaded_ms,"repeat_preparation_ms":repeated_ms,"private_source":"RF05 private-world.json; only initial player pose changed for the arrival fixture"})
func finish(receipt: Dictionary) -> void:
	trace.stop("presentation_continue")
	receipt.merge({"checks":checks,"failures":failures,"trace":trace.output_path})
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"))
	print("PRESENTATION_LIFECYCLE ",JSON.stringify(receipt))
	get_tree().quit(0 if failures==0 else 1)
