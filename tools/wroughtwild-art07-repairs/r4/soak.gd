extends Node
## Twelve bounded native boulder work/save/dispose cycles. Posed fixture work,
## not human playtime, continuous travel, a GPU benchmark or a general leak proof.
const CLEANUP := preload("res://r4/fixture_cleanup.gd")
const OPTIONS := preload("res://r4/cleanup_options.gd")
var checks := 0
var samples: Array = []

func check(value: bool, label: String) -> void:
	checks += 1
	if not value: push_error("R4_SOAK_FAIL "+label)
	assert(value,label)

func _ready() -> void:
	call_deferred("_run")

func _run() -> void:
	var started := Time.get_ticks_usec()
	var original_scene := get_tree().current_scene
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var initial_rules := sim.export_json()
	var reference := "--reference-teardown" in OS.get_cmdline_user_args()
	var released: Array[WeakRef] = []
	seed(7704)
	for iteration in OPTIONS.SOAK_ITERATIONS:
		check(sim.import_json(initial_rules),"same initial native state")
		var scope := Node3D.new()
		scope.name="R4Cycle"+str(iteration)
		get_tree().root.add_child(scope)
		get_tree().current_scene=scope
		var cycle := {"iteration":iteration,"before_create":CLEANUP.counts()}
		var player: WroughtwildPlayer=preload("res://scenes/player.tscn").instantiate()
		scope.add_child(player)
		player.class_panel.choose("warden")
		player.set_physics_process(false)
		player.combat.set_physics_process(false)
		player.placement.set_physics_process(false)
		player.hud.hide()
		player.position=Vector3(0,1.1,5)
		var node: ResourceNode=preload("res://scenes/resource_node.tscn").instantiate()
		node.set_script(load("res://b3/native_resource.gd"))
		node.name="R4Boulder"
		node.resource_id="r4-fixed-boulder"
		node.visual=&"boulder"
		node.material_family=&"fieldstone"
		node.remaining_units=9
		node.units_per_harvest=3
		node.drive_presses=3
		scope.add_child(node)
		for frame in 8: await get_tree().physics_frame
		for work in 4: player._apply_work(node,node.work(sim))
		for child in scope.get_children():
			if child is Pickup and not child.is_queued_for_deletion(): child._absorb(player)
		check(node.remaining_units==6 and node.drive_progress==1,"finite partial stock/work")
		check(sim.material_count("fieldstone")==3,"first release collected exactly once")
		var manager:=SaveManager.new()
		var partial:=manager.capture(player)
		var path:="user://r4-cycle-%02d-partial.json"%iteration
		check(manager.write(path,player),"partial native checkpoint written")
		check(manager.read(path,player),"same-process native checkpoint restored")
		check(manager.capture(player).resource_nodes==partial.resource_nodes,"exact resource identity/stock/work restored")
		check(sim.export_json()==String(partial.sim),"exact paid-out native ownership restored")
		while node.remaining_units>0: player._apply_work(node,node.work(sim))
		check(node.harvest()==0,"finite depletion refuses second yield")
		for frame in 48: await get_tree().physics_frame
		for child in scope.get_children():
			if child is Pickup and not child.is_queued_for_deletion(): child._absorb(player)
		check(get_tree().get_nodes_in_group("resources").is_empty(),"depleted native target released")
		check(sim.material_count("fieldstone")==9,"all finite stock collected once")
		path="user://r4-cycle-%02d-final.json"%iteration
		check(manager.write(path,player),"final native checkpoint written")
		check(manager.read(path,player),"depleted state restored")
		check(sim.material_count("fieldstone")==9 and get_tree().get_nodes_in_group("resources").is_empty(),"depleted identity stays absent")
		cycle["before_dispose"]=CLEANUP.counts()
		# Keep weak observations only. The fixture does not own the shared PCM cache.
		for voice in scope.find_children("*","AudioStreamPlayer3D",true,false):
			if voice.has_stream_playback(): released.append(weakref(voice.get_stream_playback()))
		if reference:
			scope.process_mode=Node.PROCESS_MODE_DISABLED
			for child in scope.get_children(): child.queue_free()
			for frame in 2: await get_tree().process_frame
		else:
			cycle["cleanup"]=await CLEANUP.dispose(scope)
		get_tree().current_scene=original_scene
		scope.free()
		player=null
		node=null
		manager=null
		cycle["observed_playbacks_alive"]=CLEANUP._alive(released)
		# Discard expired observers so the instrument itself cannot inflate object counts.
		released= released.filter(func(ref: WeakRef) -> bool: return ref.get_ref()!=null)
		for frame in 2: await get_tree().process_frame
		cycle["after_release"]=CLEANUP.counts()
		samples.append(cycle)
		print("R4_SOAK_CYCLE ",JSON.stringify(cycle))
	var result := {"reference_teardown":reference,"iterations":OPTIONS.SOAK_ITERATIONS,"checks":checks,
		"seconds":float(Time.get_ticks_usec()-started)/1000000.0,"samples":samples,
		"after_release":CLEANUP.counts(),"observed_playbacks_alive":CLEANUP._alive(released),
		"scope":"accelerated native work/restore/dispose; cache intentionally retained; no long-session or process/GPU memory bound"}
	var output:=FileAccess.open("user://r4-soak.json",FileAccess.WRITE)
	output.store_string(JSON.stringify(result,"  "))
	output.close()
	print("R4_SOAK_OK ",checks," ",JSON.stringify(result.after_release))
	get_tree().quit()
