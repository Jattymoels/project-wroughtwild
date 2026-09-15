extends "res://tests/play03_presentation_lifecycle.gd"
var entry_checks := {}
func _build_world(seed_value: int) -> void:
	super._build_world(seed_value)
	check(load("res://art/creature_resources.gd").ready_for(_sim()),"full roster ready inside actual Continue build before release")

func finish(receipt: Dictionary) -> void:
	var resources = load("res://art/creature_resources.gd")
	var native := _sim().export_json()
	var meshes := RecoveredActorArt._meshes.duplicate()
	var actor_count := get_tree().get_nodes_in_group("enemies").size()
	var began := Time.get_ticks_usec()
	resources.prepare(_sim(),trace)
	receipt["repeat_roster_ms"]=(Time.get_ticks_usec()-began)/1000.0
	check(meshes==RecoveredActorArt._meshes and _sim().export_json()==native and actor_count==get_tree().get_nodes_in_group("enemies").size(),"full roster repeat preserves resources, ownership and actor count")
	# Entry is the real TrialController transaction; alias roles were not warmed
	# in this fresh normal-world process. No actor is created by preparation.
	check(_sim().set_world_profile("living_frontier_wave3"),"select native LF catalogue")
	check(not resources.ready_for(_sim()),"new LF fallback roles begin unprepared")
	began=Time.get_ticks_usec()
	check(player.trial.begin_legacy_run(),"real independent trial entry prepares resources")
	receipt["trial_entry_ms"]=(Time.get_ticks_usec()-began)/1000.0
	check(resources.ready_for(_sim()) and actor_count==get_tree().get_nodes_in_group("enemies").size(),"trial entry readies LF roles without early mobs")
	check(player.trial.enter_room(0),"real trial initial encounter entry")
	var ids:=[]
	for enemy: Enemy in player.trial.trial_enemies(): ids.append(String(enemy.enemy_id))
	check(ids==Array(player.trial.current_room.encounter),"initial trial group count and ordering preserved")
	player.trial.on_player_died()
	check(not _sim().trial_active() and player.trial.wave_queue.is_empty(),"trial cancellation settles and clears its queue")
	check(_sim().import_json(native),"exact native save can restore after cancelled trial")
	check(_sim().set_world_profile("living_frontier_wave3"),"LF bodies available for finite resource lifecycle checks")
	receipt["roster"]=[]
	for id: String in _sim().enemy_ids():
		var a:=Enemy.spawn(self,StringName(id),player.position+Vector3(20,0,0))
		var b:=Enemy.spawn(self,StringName(id),player.position+Vector3(24,0,0))
		var am:=a._mesh.get_node("Motion") as CreatureMotion
		var bm:=b._mesh.get_node("Motion") as CreatureMotion
		check(a._mesh.mesh==b._mesh.mesh and am.rig!=bm.rig and a._material!=b._material,id+" shared exact mesh with independent rig/status material")
		if am.finished!=null:
			check(am.finished.material!=bm.finished.material and am.finished.model.transform==bm.finished.model.transform,id+" independent adopted material and unchanged fit")
			var expected:=am.finished.model.transform
			a.configure(_sim())
			am=a._mesh.get_node("Motion") as CreatureMotion
			check(am.finished.model.transform==expected,id+" reconfiguration preserves fit")
		else:
			check(a._mesh.layers==1 and a._mesh.skin!=null and a._mesh.mesh.get_surface_count()==1,id+" visible moth retains complete skinned surface")
		a._flash_left=.1
		a._refresh_look()
		if am.finished!=null:
			am.finished.refresh_status();bm.finished.refresh_status()
			check(bool(am.finished.material.get_shader_parameter("status_active")) and not bool(bm.finished.material.get_shader_parameter("status_active")),id+" no cross-actor status leak")
		else:
			check(a._material!=b._material and b._flash_left==0,id+" independent visible moth status")
		var scale_before:=a._mesh.scale
		a.make_elite(_sim().elite_modifier(_sim().elite_modifier_ids()[0]))
		check(a._mesh.scale!=scale_before and a.life>0,id+" elite retains body and scaling")
		if not a.projectile_rules.is_empty():
			var x:=EnemyProjectile.make_head(a.projectile_rules)
			var y:=EnemyProjectile.make_head(a.projectile_rules)
			check(x.mesh==y.mesh and x.material_override!=y.material_override and is_equal_approx(x.mesh.radius,float(a.projectile_rules.radius_m)),id+" cached shot shape and separate correct materials")
			x.free();y.free()
		if a.verb=="ward":
			a._refresh_aura();b._refresh_aura()
			check(a._aura.mesh==b._aura.mesh and is_equal_approx(a._aura.mesh.radius,a.verb_radius),id+" unchanged ward radius with shared geometry")
		receipt.roster.append(id)
		a.free();b.free()
	check(_sim().import_json(native),"roster fixture restores original native state")
	# Same actual Conservator path as rendered coverage, with corrected teardown.
	var central:=preload("res://tests/central_fixture.gd").ready_rules(_sim(),native)
	check(not central.is_empty() and _sim().import_json(central),"retained Central prerequisite receipt")
	check(_sim().trial_start_story(618,"forge_capstone"),"native human boss session")
	var human:=Boss.spawn_boss(self,player.position+Vector3(20,0,0)) as Conservator
	check(human!=null and human.arms.size()==2 and human.harness!=null,"complete human body/harness through boss dispatcher")
	human.free()
	_sim().trial_abandon()
	check(_sim().trial_end() and _sim().import_json(native),"boss trial settles before exact native restoration")
	# Check the changed recorder bound explicitly, without re-running old suites.
	trace._frame()
	for i in trace.MAX_ARRIVAL_EVENTS+12: trace.note_arrival("bound_check",Time.get_ticks_usec())
	check(trace._interval.arrivals.size()==trace.MAX_ARRIVAL_EVENTS and trace._interval.arrival_events_dropped==12,"full-group event bound retains explicit overflow")
	super.finish(receipt)
