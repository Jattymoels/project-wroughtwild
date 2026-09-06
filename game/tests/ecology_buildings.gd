extends "res://scripts/sandpit.gd"
## Exercise real ordinary placement, demolition and save restoration against
## regional MultiMeshes. All state stays in this isolated generated world.
var checks:=0
var failures:=0

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL ECOLOGY BUILDING: ",label)

func _ready() -> void:
	# Retain the historical composition/capture route; v4 has its own lifecycle checks.
	world_profile = "frontier_v3"
	super._ready()
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	await get_tree().process_frame
	_record_composition()
	var manager:=SaveManager.new()
	var before:=manager.capture(player)
	var target:=_find_target()
	check(not target.is_empty(),"fixture finds actual regional understory to build over")
	if not target.is_empty(): await _exercise(target,manager,before)
	await _exercise_ground_cover(manager)
	print("ECOLOGY_BUILDINGS %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _record_composition() -> void:
	var regions: Array=[]
	for group in get_node("StrangeSites").get_children():
		if not group.has_meta("region_id"): continue
		var counts: Dictionary={}
		var batches:=0
		for part in group.get_children():
			if not part is MultiMeshInstance3D: continue
			var kind:=String(part.get_meta("mesh_kind",""))
			counts[kind]=int(counts.get(kind,0))+part.multimesh.instance_count
			batches+=1
		var entry:={"id":group.get_meta("region_id"),"clusters":group.get_meta("cluster_count",0),"canopy":group.get_meta("canopy_count",0),"landmarks":group.get_meta("landmark_count",0),"details":group.get_meta("detail_count",0),"pools":group.get_meta("pool_count",0),"batches":batches,"instances":counts}
		regions.append(entry)
		print("ECOLOGY_COMPOSITION ",JSON.stringify(entry))
	var directory:=ProjectSettings.globalize_path("res://../build/frontier-polish")
	DirAccess.make_dir_recursive_absolute(directory)
	var file:=FileAccess.open(directory.path_join("ecology-counts.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"seed":1,"regions":regions},"\t"))

func _find_target() -> Dictionary:
	for region in get_node("StrangeSites").get_children():
		if not region.has_meta("region_id"): continue
		for part in region.get_children():
			if not part is MultiMeshInstance3D or String(part.get_meta("mesh_kind","")) not in ["fern","moss","sedge","dry_sedge"]: continue
			var transforms: Array=part.get_meta("world_transforms",[])
			if not transforms.is_empty(): return {"path":get_path_to(part),"index":0,"at":transforms[0].origin}
	return {}

func _exercise(target: Dictionary, manager: SaveManager, before: Dictionary) -> void:
	var at: Vector3=target.at
	terrain.ensure_area(at,16.0)
	await get_tree().process_frame
	# Deferred grounding may rebuild the group. Its deterministic tile/name and
	# index still identify the same visual-only specimen.
	var part:=get_node(target.path) as MultiMeshInstance3D
	var index:=int(target.index)
	var original: Transform3D=part.get_meta("world_transforms")[index]
	var rendered: Transform3D=part.get_meta("display_transforms")[index]
	var ground:=terrain.rendered_height(original.origin.x,original.origin.z,terrain.height_at(int(original.origin.x),int(original.origin.z)))
	check(is_finite(ground),"test plant has exact supported ground")
	var elements: Array=_sim().lattice_candidates("cube",Vector3(original.origin.x,ground,original.origin.z),Vector3.UP,false)
	check(not elements.is_empty(),"ordinary cube has a lattice target at the plant")
	if elements.is_empty(): return
	var block: PlacedBlock=player.placement.place_piece(elements[0],&"cube",&"wood",0)
	check(block!=null,"normal placement succeeds without treating decoration as collision")
	if block==null: return
	await get_tree().process_frame
	part=get_node(target.path) as MultiMeshInstance3D
	check(bool(part.get_meta("hidden_by_building")[index]),"placed piece clears intersecting decorative growth")
	check(_submitted(part,index).basis.determinant()==0,"cleared growth submits a collapsed renderer transform")
	check((part.get_meta("world_transforms")[index] as Transform3D).is_equal_approx(original),"clearing retains the exact ecological placement")
	check(_stocks(manager.capture(player))==_stocks(before),"placing a building does not harvest or alter finite stock")
	var saved:=manager.capture(player)
	check(player.placement.remove_piece(block),"ordinary demolition succeeds")
	await get_tree().process_frame
	part=get_node(target.path) as MultiMeshInstance3D
	check(not bool(part.get_meta("hidden_by_building")[index]),"demolition releases the decorative footprint")
	check(_submitted(part,index).is_equal_approx(rendered),"demolition restores the exact submitted transform")
	check(manager.apply(player,saved),"normal save restoration reinstates the placed building")
	await get_tree().process_frame
	part=get_node(target.path) as MultiMeshInstance3D
	check(bool(part.get_meta("hidden_by_building")[index]) and _submitted(part,index).basis.determinant()==0,"restored building clears growth before resumed play")
	check(_stocks(manager.capture(player))==_stocks(before),"restoration preserves every finite stock record")
	check(manager.apply(player,before),"restore the original world without the placed cube")
	await get_tree().process_frame
	part=get_node(target.path) as MultiMeshInstance3D
	check(not bool(part.get_meta("hidden_by_building")[index]),"restoring no structure releases its footprint")
	check(_submitted(part,index).is_equal_approx(rendered),"unobstructed restore retains the same ecological transform")
	# A later clearing refresh must not regrow an instance already suppressed by
	# an unsupported cave/excavation. Exercise the actual chunk-grounding path.
	var actual: Vector3=part.get_meta("world_transforms")[index].origin
	var poses_before: Array=part.get_meta("world_transforms").duplicate(true)
	var x:=floori(actual.x)
	var z:=floori(actual.z)
	var y:=terrain.height_at(x,z)-1
	check(not terrain.break_block(x,y,z).is_empty(),"player can excavate the supporting terrain")
	# Reground this existing tile before the deferred full composition refresh.
	# The next frame may legitimately omit a plant whose footprint was removed.
	StrangeSites.refresh_area(self,terrain,floori(float(x)/16)*16,floori(float(z)/16)*16)
	var unsupported:=not bool(part.get_meta("ground_supported",[])[index]) if part.has_meta("ground_supported") else false
	player.placement.refresh_ecology()
	if unsupported: check(_submitted(part,index).basis.determinant()==0,"building refresh cannot restore excavation-unsupported growth")
	else:
		var pose: Transform3D=part.get_meta("world_transforms")[index]
		var exact:=terrain.rendered_height(pose.origin.x,pose.origin.z,terrain.height_at(int(pose.origin.x),int(pose.origin.z)))
		check(is_finite(exact) and absf(float(part.get_meta("ground_heights")[index])-exact)<.01,"surviving growth follows the excavated surface instead of its original height")
	check(_stocks(manager.capture(player))==_stocks(before),"visual clearing and excavation do not mutate finite node stocks")
	await get_tree().process_frame
	part=get_node(target.path) as MultiMeshInstance3D
	var poses_after: Array=part.get_meta("world_transforms")
	check(poses_before.size()==poses_after.size(),"deferred excavation refresh retains the same ecological records")
	for i in mini(poses_before.size(),poses_after.size()):
		var old: Vector3=poses_before[i].origin
		var now: Vector3=poses_after[i].origin
		check(Vector2(old.x,old.z).is_equal_approx(Vector2(now.x,now.z)),"one dig never shuffles neighbouring growth")

func _submitted(part: MultiMeshInstance3D, index: int) -> Transform3D:
	var recorded: Transform3D=part.get_meta("display_transforms")[index]
	if DisplayServer.get_name()!="headless":
		check(part.multimesh.get_instance_transform(index).is_equal_approx(recorded),"renderer's actual transform matches the submitted pose")
	return recorded

func _find_cover_target() -> Dictionary:
	for chunk: Node3D in terrain.chunks.values():
		for part in chunk.get_children():
			if not part is MultiMeshInstance3D or String(part.name)!="Cover_tuft" or not part.has_meta("terrain_cover"): continue
			var poses: Array=part.get_meta("world_transforms",[])
			if not poses.is_empty(): return {"path":get_path_to(part),"at":poses[0].origin}
	return {}

func _cover_index(part: MultiMeshInstance3D, at: Vector3) -> int:
	var poses: Array=part.get_meta("world_transforms",[])
	for i in poses.size():
		var origin: Vector3=poses[i].origin
		if Vector2(origin.x,origin.z).is_equal_approx(Vector2(at.x,at.z)): return i
	return -1

func _exercise_ground_cover(manager: SaveManager) -> void:
	var before:=manager.capture(player)
	var target:=_find_cover_target()
	check(not target.is_empty(),"actual ordinary grass retains exact V3 presentation poses")
	if target.is_empty(): return
	var part:=get_node(target.path) as MultiMeshInstance3D
	var index:=_cover_index(part,target.at)
	var original: Transform3D=part.get_meta("world_transforms")[index]
	var displayed: Transform3D=part.get_meta("display_transforms")[index]
	var at: Vector3=target.at
	var candidates: Array=_sim().lattice_candidates("floor_slab",at+Vector3.UP*.015,Vector3.UP,false)
	check(not candidates.is_empty(),"ordinary floor slab targets grass-covered ground")
	if candidates.is_empty(): return
	var floor: PlacedBlock=player.placement.place_piece(candidates[0],&"floor_slab",&"wood",0)
	check(floor!=null,"normal floor placement succeeds over decorative terrain grass")
	if floor==null: return
	await get_tree().process_frame
	check(bool(part.get_meta("hidden_by_building")[index]) and _submitted(part,index).basis.determinant()==0,"floor suppresses ordinary grass in the renderer")
	check((part.get_meta("world_transforms")[index] as Transform3D).is_equal_approx(original),"floor retains the original grass pose")
	check(_stocks(manager.capture(player))==_stocks(before),"grass clearing changes no finite resource stock")
	_historical_cover_guard(part,index,displayed)
	var saved:=manager.capture(player)
	check(player.placement.remove_piece(floor),"ordinary floor removal succeeds")
	await get_tree().process_frame
	check(not bool(part.get_meta("hidden_by_building")[index]) and _submitted(part,index).is_equal_approx(displayed),"removing the floor restores its exact grass transform")
	check(manager.apply(player,saved),"normal save restoration restores floor-over-grass")
	await get_tree().process_frame
	part=get_node(target.path) as MultiMeshInstance3D
	index=_cover_index(part,at)
	check(index>=0 and bool(part.get_meta("hidden_by_building")[index]) and _submitted(part,index).basis.determinant()==0,"saved floor suppresses grass before resumed play")
	# A floor may already stand when a chunk is streamed or rebuilt. Phase 3
	# must apply the same clearing before the chunk's visible publication.
	terrain._rebuild_chunk(floori(at.x/16)*16,floori(at.z/16)*16)
	part=get_node(target.path) as MultiMeshInstance3D
	index=_cover_index(part,at)
	check(index>=0 and bool(part.get_meta("hidden_by_building")[index]) and _submitted(part,index).basis.determinant()==0,"rebuilt chunk publishes with pre-existing floor grass already suppressed")
	check(manager.apply(player,before),"restore ordinary ground without the floor")
	await get_tree().process_frame
	part=get_node(target.path) as MultiMeshInstance3D
	index=_cover_index(part,at)
	check(index>=0 and not bool(part.get_meta("hidden_by_building")[index]) and _submitted(part,index).is_equal_approx(displayed),"save without floor restores exact ordinary grass")
	check(_stocks(manager.capture(player))==_stocks(before),"grass restore and chunk rebuild preserve finite node stock")

func _historical_cover_guard(part: MultiMeshInstance3D, index: int, visible_pose: Transform3D) -> void:
	for profile: String in ["legacy_v1","frontier_v2"]:
		var historical:=Terrain.new()
		historical._world_profile=profile
		historical._sim=_sim()
		var chunk:=Node3D.new()
		var sample:=MultiMeshInstance3D.new()
		sample.multimesh=MultiMesh.new()
		sample.multimesh.transform_format=MultiMesh.TRANSFORM_3D
		sample.multimesh.mesh=part.multimesh.mesh
		sample.multimesh.instance_count=part.multimesh.instance_count
		sample.position=part.position
		sample.multimesh.set_instance_transform(index,visible_pose)
		sample.set_meta("terrain_cover",true)
		sample.set_meta("world_transforms",(part.get_meta("world_transforms") as Array).duplicate(true))
		sample.set_meta("cover_bounds",part.get_meta("cover_bounds"))
		var poses: Array=(part.get_meta("display_transforms") as Array).duplicate(true)
		poses[index]=visible_pose
		sample.set_meta("display_transforms",poses)
		sample.set_meta("hidden_by_building",[])
		chunk.add_child(sample)
		StrangeSites.refresh_cover_chunk(historical,chunk)
		check(_submitted(sample,index).is_equal_approx(visible_pose),"building clearing does not alter "+profile+" ground appearance")
		chunk.free()
		historical.free()

func _stocks(save: Dictionary) -> Dictionary:
	var result: Dictionary={}
	for row: Dictionary in save.get("resource_nodes",[]):
		result[String(row.name)]=[int(row.remaining_units),int(row.get("drive_progress",0))]
	return result
