extends Sandpit
var checks := 0
var failures := 0
func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok: failures+=1;printerr("FAIL RESTORE ",label)
func _ready() -> void:
	set_physics_process(false)
	terrain.set_process(false)
	mob_packs.set_physics_process(false)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	_run.call_deferred()
func _run() -> void:
	var output:=OS.get_environment("WROUGHTWILD_ARRIVAL_OUTPUT")
	var trace:=preload("res://scripts/play03_trace.gd").install(self,PackedStringArray(["--play03-trace="+output]))
	var resources=load("res://art/creature_resources.gd")
	check(not resources._base_ready,"fresh restore has no roster preparation")
	var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/lf5b-published-boundary.json.gz")
	var saved:Dictionary=JSON.parse_string(packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8())
	check(_sim().import_json(saved.sim) and _sim().set_world_profile(saved.world_profile),"retained LF boundary native state and profile")
	var original:=_sim().export_json()
	var count:=get_tree().get_nodes_in_group("enemies").size()
	var began:=Time.get_ticks_usec()
	check(player.trial.restore_boundary(saved.trial_boundary),"actual suspended-trial restore from retained checkpoint")
	var elapsed:=(Time.get_ticks_usec()-began)/1000.0
	check(resources.ready_for(_sim()) and FinishedFauna.resources_ready(),"fresh restored trial prepares full current and alias resources before returning")
	check(player.trial.state=="boundary" and player.trial.wave_queue.is_empty(),"cleared boundary owns no pending wave")
	check(get_tree().get_nodes_in_group("enemies").size()==count,"restoration preparation creates no early actors")
	check(_sim().export_json()==original,"restored trial preserves exact native ownership")
	_sim().trial_abandon()
	player.trial.finish_run()
	check(not _sim().trial_active() and player.trial.wave_queue.is_empty(),"restored trial cancellation settles and clears queues")
	trace.stop("group_restored_trial")
	var receipt:={"checks":checks,"failures":failures,"restore_ms":elapsed,"trace":trace.output_path}
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"))
	print("GROUP_RESTORE ",JSON.stringify(receipt))
	get_tree().quit(0 if failures==0 else 1)
