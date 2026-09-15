extends Sandpit
## Focused envelope/actor ownership checks; no full-world generation or matrix.
var checks := 0
var failures := 0
var receipt := {}
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL ARRIVAL LIFECYCLE ",label)
	return ok
func _ready() -> void:
	set_physics_process(false)
	terrain.set_process(false)
	mob_packs.set_physics_process(false)
	player.set_physics_process(false)
	_run.call_deferred()
func source_bounds(id: String, definition: Dictionary) -> AABB:
	var packed: PackedScene = load("res://assets/authored/mobs/"+id+".glb")
	var source := packed.instantiate()
	var found := {}
	RecoveredActorArt._find_mesh(source,Transform3D.IDENTITY,found)
	var scale_values: Array = definition.applied_visual_scale
	var inverse := Vector3.ONE/Vector3(scale_values[0],scale_values[1],scale_values[2])
	var transform: Transform3D = Transform3D(Basis.from_scale(inverse),Vector3.ZERO)*found.transform
	var mesh: ArrayMesh = found.instance.mesh
	var bounds := AABB()
	var first := true
	for surface in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(surface)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		for i in range(indices.size() if not indices.is_empty() else vertices.size()):
			var point: Vector3 = transform*vertices[indices[i] if not indices.is_empty() else i]
			bounds = AABB(point,Vector3.ZERO) if first else bounds.expand(point)
			first = false
	source.free()
	return bounds
func _run() -> void:
	var output := OS.get_environment("WROUGHTWILD_ARRIVAL_OUTPUT")
	var sim := _sim()
	var native_before := sim.export_json()
	check(not has_node("Play03Trace") and terrain.play03_trace==null, "normal recorder stays off")
	receipt["bounds"] = {}
	for id in ["ember_whelp","ash_hound","valley_elk"]:
		var definition: Dictionary = RecoveredActorArt.definitions()[id]
		var actor := Enemy.spawn(self,StringName(id),Vector3(10,1,0))
		actor.set_physics_process(false)
		var motion := actor._mesh.get_node("Motion") as CreatureMotion
		motion.set_physics_process(false)
		var expected := source_bounds(id,definition)
		var actual := actor._mesh.mesh.get_aabb()
		check(actual.is_equal_approx(expected), id+" exact source envelope after family rebasing")
		receipt.bounds[id] = {"position_error":actual.position.distance_to(expected.position), "size_error":actual.size.distance_to(expected.size)}
		check(actor._mesh.layers==0 and motion.finished!=null and motion.finished.model.is_visible_in_tree(), id+" complete visible finished model with hidden envelope")
		check(actor._mesh.mesh.get_meta("finished_envelope",false) and not RecoveredActorArt._materials.has(id),id+" no legacy surface/material reconstruction")
		var body := actor.get_node("CollisionShape3D") as CollisionShape3D
		check(is_equal_approx(body.shape.radius,.35) and is_equal_approx(body.shape.height,1.3) and MobGrid.near(actor.position,1).has(actor),id+" unchanged capsule and immediate spatial registration")
		check(actor.life==float(sim.enemy(StringName(id)).max_life),id+" native life unchanged")
		var sampler := motion.finished
		var bounds := sampler.model.transform
		var label_y := actor._label.position.y
		actor.configure(sim)
		motion = actor._mesh.get_node("Motion") as CreatureMotion
		motion.set_physics_process(false)
		check(motion.finished.model.transform.is_equal_approx(bounds) and is_equal_approx(actor._label.position.y,label_y) and actor.attack_released.get_connections().size()==1,id+" reconfigure retains fit/label and one release listener")
		actor._flash_left = .1
		motion.finished.refresh_status()
		check(bool(motion.finished.material.get_shader_parameter("status_active")),id+" finished material still shows hit status")
		actor._flash_left = 0
		motion.finished.refresh_status()
		check(not bool(motion.finished.material.get_shader_parameter("status_active")),id+" status clears normally")
		actor.make_elite(sim.elite_modifier(sim.elite_modifier_ids()[0]))
		check(is_equal_approx(actor._label.position.y,actual.end.y*actor._mesh.scale.y+.25),id+" elite label uses same envelope")
		actor.free()
	var host := Enemy.spawn(self,&"lf_red_boar",Vector3(15,1,0))
	host.set_physics_process(false)
	var host_motion := host._mesh.get_node("Motion") as CreatureMotion
	host_motion.set_physics_process(false)
	check(host_motion.finished!=null and host.get_node("FrontierHostLook").finished_scar and host_motion.finished.material.get_shader_parameter("core_colour")==FrontierHostLook.PALETTE.red,"finite host visual alias retains finished channel material/tell")
	host.free()
	check(native_before==sim.export_json(),"presentation setup/status/elite/teardown never changes exact native save or possessions")
	var trace: Node = preload("res://scripts/play03_trace.gd").install(self,PackedStringArray(["--play03-trace="+output]))
	var pack := {"enemies":PackedStringArray(["ember_whelp","ash_hound"]),"x":10,"y":1,"z":0,"spawned":false,"members":[],"elite_member":-1,"elite_modifier":"","grazer":false}
	mob_packs.terrain = terrain
	mob_packs.packs = [pack]
	mob_packs._spawn_pack(pack,Vector3(10,1,0))
	check(pack.members.size()==2 and pack.members[0].enemy_id==&"ember_whelp" and pack.members[1].enemy_id==&"ash_hound","pack completes synchronously in deterministic member order")
	for actor: Enemy in pack.members:
		actor.set_physics_process(false)
		actor._mesh.get_node("Motion").set_physics_process(false)
	var kill_before := mob_packs.loot_kill_counter()
	var dead: Enemy = pack.members[0]
	dead.take_damage(dead.life+1)
	var drops_after := get_tree().get_nodes_in_group("pickups").size()
	dead.take_damage(1)
	check(mob_packs.loot_kill_counter()==kill_before+1 and get_tree().get_nodes_in_group("pickups").size()==drops_after,"real death pays once; repeated damage cannot claim again")
	var survivor: Enemy = pack.members[1]
	survivor.state = "idle"
	survivor.since_hurt = 100
	check(mob_packs.sleep_far_packs(Vector3(200,1,200))==1 and pack.enemies==PackedStringArray(["ash_hound"]),"sleep retains exactly the surviving member")
	mob_packs._spawn_pack(pack,Vector3(10,1,0))
	check(pack.members.size()==1 and pack.members[0].enemy_id==&"ash_hound" and pack.members[0].life==float(sim.enemy(&"ash_hound").max_life),"waking restores survivor once with full native life")
	pack.members[0].free()
	# The affected code adds no queue/reservation or new saved data.
	check(not FileAccess.file_exists(trace.output_path),"arrival markers do not write during sampling")
	trace._frame()
	var events: Array = trace.rows.back().get("arrivals",[])
	check(events.any(func(e: Dictionary) -> bool:return e.phase=="pack" and e.count==2) and events.any(func(e: Dictionary) -> bool:return e.phase=="presentation_setup"),"bounded spans retain actual pack/member setup")
	for i in 140: trace.note_arrival("bound_check",Time.get_ticks_usec())
	check(trace._interval.arrivals.size()==128 and trace._interval.arrival_events_dropped==12,"per-interval event bound and explicit overflow count")
	var saved_native := sim.export_json()
	check(trace.stop("lifecycle") and not trace.stop() and sim.export_json()==saved_native,"stop disconnects once and preserves exact native ownership")
	var count: int = trace.rows.size()
	trace.note_arrival("after_stop",Time.get_ticks_usec())
	check(trace.rows.size()==count and trace._interval.is_empty(),"stopped recorder ignores arrival spans")
	receipt.merge({"checks":checks,"failures":failures})
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"))
	print("ARRIVAL_LIFECYCLE ",JSON.stringify(receipt))
	get_tree().quit(0 if failures==0 else 1)
