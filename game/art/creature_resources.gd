extends RefCounted
## Finite current-roster resources. Called by world/trial loading transactions;
## never creates live actors, changes encounters, or runs a background queue.
static var _base_ready := false
static var _roles: Dictionary = {}
static var _scenes: Dictionary = {}

static func prepare(sim: WroughtwildSim, trace: Node = null) -> void:
	var began := Time.get_ticks_usec() if is_instance_valid(trace) and trace.active else 0
	if not _base_ready:
		FinishedFauna.prepare_world(trace)
		for adapter in [PorcupinePresentation,CranePresentation,RamPresentation,BeetlePresentation,NymphPresentation,TortoisePresentation]:
			var step := Time.get_ticks_usec() if began > 0 else 0
			adapter.prepare_resources()
			if began > 0: trace.note_arrival("roster_adapter_prepare",step,{"adapter":adapter.resource_path})
		for id: String in RecoveredActorArt.definitions():
			var step := Time.get_ticks_usec() if began > 0 else 0
			var role: String = RecoveredActorArt.definitions()[id].role
			# Keep exact visible skinned wisps AND later adapters' adorned envelopes.
			# Only existing off-tree source meshes are built; no Enemy is instantiated.
			RecoveredActorArt.mesh_for(id,role,trace)
			_prepare_role(role)
			if began > 0: trace.note_arrival("roster_mesh_prepare",step,{"enemy_id":id})
		for path in ["res://scenes/enemy.tscn","res://scenes/boss.tscn","res://scenes/conservator.tscn"]:
			_scenes[path] = load(path)
		for behaviour: Dictionary in sim.realtime().behaviours.values():
			if behaviour.has("projectile"): EnemyProjectile.prepare_head(behaviour.projectile)
			if behaviour.get("verb","")=="ward": Enemy.prepare_ward(float(behaviour.verb_radius_m))
		Conservator.prepare_resources()
		_base_ready = true
	# Profile-specific aliases reuse visual_id resources, but can select another
	# procedural fallback role before attaching that visual. Prepare each once.
	for id: String in sim.enemy_ids():
		_prepare_role(String(sim.enemy(id).behaviour))
	if began > 0: trace.note_arrival("roster_preparation",began,{"roles":_roles.size()})

static func _prepare_role(role: String) -> void:
	if _roles.has(role): return
	preload("res://art/character_look.tres").build(role)
	_roles[role] = true

static func ready_for(sim: WroughtwildSim) -> bool:
	if not _base_ready: return false
	for id: String in sim.enemy_ids():
		if not _roles.has(String(sim.enemy(id).behaviour)): return false
	return true
