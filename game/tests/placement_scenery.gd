extends "res://scripts/sandpit.gd"
## Local updates must match the complete reference after rapid edits and loads.
var checks:=0
var failures:=0

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL PLACEMENT_SCENERY: ",label)

func _ready() -> void:
	world_seed=77
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	await get_tree().physics_frame
	# Both algorithms must see the same completed terrain. Manual ensure_area
	# calls below still exercise arrivals/retirement, but timed background work
	# cannot change a chunk between the local and full-reference snapshots.
	terrain.set_process(false)
	var manager:=SaveManager.new()
	var original:=manager.capture(player)
	var stock:=JSON.stringify(original.resource_nodes)
	var ledger:=_sim().contraption_save()
	var targets: Array[Vector3]=[]
	for group in get_node("StrangeSites").get_children():
		for part in group.get_children():
			if part is MultiMeshInstance3D and part.get_meta("world_transforms",[]).size()>0:
				targets.append(part.get_meta("world_transforms")[0].origin)
				break
	var history:=get_node("CataclysmSites") as CataclysmSites
	for piece in history.pieces:
		if piece.has_node("RuinBody"): targets.append(piece.position)
	for trace in history.traces:
		if trace.mesh!=null: targets.append(trace.mesh.get_aabb().get_center())
		if targets.size()>28: break
	var placed: Array[PlacedBlock]=[]
	for target in targets:
		terrain.ensure_area(target,16)
		var e: Dictionary=_sim().lattice_candidates("cube",target,Vector3.UP,false)[0]
		var block:=player.placement.place_piece(e,&"cube",&"wood")
		if block!=null: placed.append(block)
	check(placed.size()>12,"rapid edits cover actual regional growth, ruins and leyline tiles")
	await get_tree().process_frame
	await _equivalent("rapid distant placements")
	var saved:=manager.capture(player)
	for i in placed.size():
		if i%2==0: check(player.placement.remove_piece(placed[i]),"rapid alternate removal succeeds")
	await get_tree().process_frame
	await _equivalent("mixed retained and removed pieces")
	check(manager.apply(player,saved),"saved rapid build restores")
	await _equivalent("save restoration")
	check(manager.apply(player,original),"empty earlier checkpoint replaces later buildings")
	await _equivalent("removed buildings on older checkpoint")
	check(JSON.stringify(manager.capture(player).resource_nodes)==stock,"finite resource state is unchanged by all scenery operations")
	check(_sim().contraption_save()==ledger,"machine/source ledger is unchanged by scenery operations")
	print("PLACEMENT_SCENERY %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _snapshot(node: Node=self, result: Dictionary={}) -> Dictionary:
	# Renderer-independent submitted transforms, exact mesh arrays and actual
	# collision flags; no generated screenshots are used as the correctness oracle.
	if node==self: result={}
	if node is MultiMeshInstance3D:
		result[String(get_path_to(node))]=[node.get_meta("display_transforms",[]).duplicate(true),node.get_meta("hidden_by_building",[]).duplicate(true)]
	elif node is MeshInstance3D and is_ancestor_of(node) and (get_node("CataclysmSites").is_ancestor_of(node) or get_node("StrangeSites").is_ancestor_of(node)):
		var arrays:=[]
		if node.mesh!=null:
			for surface in node.mesh.get_surface_count(): arrays.append(hash(node.mesh.surface_get_arrays(surface)))
		result[String(get_path_to(node))]=[node.visible,node.global_transform,arrays]
	elif node is CollisionShape3D and get_node("CataclysmSites").is_ancestor_of(node):
		result[String(get_path_to(node))]=node.disabled
	for child in node.get_children(): _snapshot(child,result)
	return result

func _equivalent(label: String) -> void:
	await get_tree().process_frame
	# Freeze streaming while comparing two representations of the same support.
	terrain.set_process(false)
	terrain.set_physics_process(false)
	# ensure_area above also schedules legitimate terrain-arrival refreshes.
	# Compare completed output, after those existing jobs have caught up.
	var history:=get_node("CataclysmSites") as CataclysmSites
	while history.step_trace_refresh(): pass
	var local:=_snapshot()
	StrangeSites.refresh_buildings(self,terrain)
	await get_tree().process_frame
	var full:=_snapshot()
	check(local.size()==full.size(),label+": same scenery node set")
	for path: String in full:
		check(local.get(path)==full[path],label+": exact full-reference geometry/visibility at "+path)
