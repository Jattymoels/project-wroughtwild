extends "res://tests/living_frontier_habitat.gd"
## Full-route physical regression. Only the initial route position is supplied;
## all subsequent travel uses the unmodified player controller and real solids.
var baseline := false
var route_receipts: Array = []
const PUBLISHED_GEOGRAPHY := {
	5:"143558f2801d3016a57531fb8b1331a2292738042efc06b53fd42ff132199498",
	77:"48c4aded0e8fcac715ab86f40911f19b13604b9f69d82882645d175cec23d4ae"
}

func _ready() -> void:
	baseline = "--lf3-r1-baseline" in OS.get_cmdline_user_args()
	world_seed = 5
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--route-seed="): world_seed = int(arg.get_slice("=",1))
	world_profile = "living_frontier_wave3"
	_build_world(world_seed)
	player.class_panel.choose("warden")
	freeze_fixtures()
	set_physics_process(false)
	_run_routes.call_deferred()

func geography() -> Dictionary:
	var result := terrain.map.duplicate(true)
	result.erase("laboratory_trail")
	result.erase("frontier_rules")
	for h: Dictionary in result.frontier_hosts:
		h.erase("approach")
		h.erase("source_route")
	for lab: Dictionary in result.laboratories: lab.erase("approach")
	return result

func _run_routes() -> void:
	for i in 3: await get_tree().physics_frame
	var routes: Array = [{"id":"collection_trail","path":terrain.map.laboratory_trail}]
	for lab: Dictionary in terrain.map.laboratories: routes.append({"id":lab.id,"path":lab.approach})
	for host: Dictionary in terrain.map.frontier_hosts:
		routes.append({"id":String(host.id)+"_approach","path":host.approach})
		routes.append({"id":String(host.id)+"_cue","path":host.source_route})
	for route: Dictionary in routes:
		if "--lf3-r1-restore-only" in OS.get_cmdline_user_args(): continue
		if baseline and not ((world_seed==5 and route.id=="collection_trail") or (world_seed==77 and route.id=="lf3_central_laboratory")): continue
		var hits := shell_contacts(route.path)
		var walked := await walk_route(route.path)
		print("LF3_R1_ROUTE seed=",world_seed," id=",route.id," points=",route.path.size()," capsule_shell_contacts=",hits," walked=",walked)
		route_receipts.append({"id":route.id,"points":route.path.size(),"shell_contacts":hits,"walked":walked})
		check(hits>0 if baseline else hits==0,"baseline collision reproduced" if baseline else "complete capsule corridor clears solid shells: "+String(route.id))
		check(not walked if baseline else walked,"baseline controller blocked" if baseline else "ordinary full route traversal: "+String(route.id))
	if not baseline:
		var query:=PhysicsShapeQueryParameters3D.new()
		query.collision_mask=1
		var contacts:=0
		for part: MeshInstance3D in get_node("FrontierSites").trail_pieces:
			var shape:=BoxShape3D.new()
			shape.size=part.mesh.size
			query.shape=shape
			query.transform=part.global_transform
			for hit in get_world_3d().direct_space_state.intersect_shape(query,64):
				if hit.collider.name=="ExteriorBody": contacts+=1
		check(contacts==0,"all actual collection dressing clears solid shells")
	await paid_compatibility()
	var receipt := FileAccess.open("res://../build/lf3/routes-%d-%s.json" % [world_seed,"before" if baseline else "after"],FileAccess.WRITE)
	receipt.store_string(JSON.stringify({"seed":world_seed,"baseline":baseline,"routes":route_receipts,"checks":checks,"failures":failures},"\t"))
	print("LF3_R1 ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func shell_contacts(path: PackedVector3Array) -> int:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.get_node("CollisionShape3D").shape
	query.collision_mask = 1
	query.exclude = [player.get_rid()]
	var count := 0
	# Dense capsule sampling covers every axis-aligned one-metre segment. The
	# .1 m interval is smaller than every shell wall and the capsule diameter.
	for i in range(1,path.size()):
		for sample in 11:
			var point := path[i-1].lerp(path[i],sample/10.0)+Vector3.UP*.98
			query.transform = Transform3D(Basis.IDENTITY,point)
			for hit in get_world_3d().direct_space_state.intersect_shape(query,64):
				if hit.collider.name=="ExteriorBody": count+=1
	return count

func walk_route(path: PackedVector3Array) -> bool:
	if path.size()<2: return false
	terrain.ensure_area(path[0],24)
	player.global_position = path[0]+Vector3.UP*1.05
	player.velocity = Vector3.ZERO
	player.rotation = Vector3.ZERO
	player.test_walk = Vector2.ZERO
	player.set_physics_process(true)
	for frame in 20: await get_tree().physics_frame
	var focus := path[0]
	var frames := 0
	for index in range(1,path.size()):
		if path[index].distance_to(focus)>12:
			focus=path[index]
			terrain.ensure_area(focus,24)
		var reached := false
		for frame in 150:
			var delta := (path[index]-player.global_position)*Vector3(1,0,1)
			if delta.length()<.24:
				reached=true
				break
			player.test_walk=Vector2(delta.x,delta.z).normalized()
			if frame==30 or frame==95: Input.action_press("jump")
			if frame==31 or frame==96: Input.action_release("jump")
			await get_tree().physics_frame
			frames+=1
		player.test_walk=Vector2.ZERO
		Input.action_release("jump")
		if not reached:
			print("LF3_R1_BLOCKED index=",index," target=",path[index]," actual=",player.global_position," frames=",frames)
			for collision in player.get_slide_collision_count():
				print("LF3_R1_SOLID ",player.get_slide_collision(collision).get_collider())
			player.set_physics_process(false)
			return false
	for frame in 90:
		await get_tree().physics_frame
		if player.is_on_floor(): break
	var supported:=player.is_on_floor()
	player.set_physics_process(false)
	print("LF3_R1_WALK frames=",frames," endpoint=",player.global_position)
	return supported

func paid_compatibility() -> void:
	var file := "res://../build/lf3/routes-%d-published.json" % world_seed
	var manager := SaveManager.new()
	if baseline:
		if not await gather("wood",8): return
		var mark: MeshInstance3D = get_node("FrontierSites").trail_marks[1]
		var at := mark.global_position
		terrain.ensure_area(at,16)
		player.global_position=at+Vector3(0,1,3)
		var cell:=Vector3i(floori(at.x),ceili(terrain.surface_position(floori(at.x),floori(at.z)).y),floori(at.z))
		check(place(&"block",cell),"paid timber occupies old cosmetic collection mark")
		_sim().leyline_work("red_home_margin")
		for i in 3: await get_tree().physics_frame
		get_node("FrontierSites").refresh_buildings()
		check(not mark.visible,"paid space suppresses old mark")
		check(manager.write(file,player),"pre-repair save written with paid ownership and partial source work")
		var manifest:=FileAccess.open(file+".geography",FileAccess.WRITE)
		manifest.store_var(geography())
	else:
		# Committed pre-repair snapshots are compressed only to keep finite-node
		# ledgers compact. They are never synthesized by the repaired generator.
		var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/lf3-r1-seed-%d.json.gz" % world_seed)
		var text:=packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
		file="res://../build/lf3/routes-%d-restore.json" % world_seed
		var restore_file:=FileAccess.open(file,FileAccess.WRITE)
		restore_file.store_string(text)
		restore_file.close()
		var saved: Dictionary=JSON.parse_string(text)
		check(not saved.is_empty(),"pre-repair checkpoint exists")
		var hash:=HashingContext.new()
		hash.start(HashingContext.HASH_SHA256)
		hash.update(var_to_bytes(geography()))
		check(hash.finish().hex_encode()==PUBLISHED_GEOGRAPHY[world_seed],"all published map data except derived routes remain exact")
		for pass_index in 2:
			check(manager.read(file,player),"pre-repair paid checkpoint restores: "+manager.last_error)
			freeze_fixtures()
			var captured:=manager.capture(player)
			check(JSON.parse_string(captured.sim)==JSON.parse_string(saved.sim),"all saved inventory, equipment, progression and paid cost remain exact")
			for key in ["blocks","resource_nodes","stations","world_drops","leylines","contraptions"]:
				check(JSON.parse_string(JSON.stringify(captured.get(key)))==saved.get(key),"saved owner unchanged: "+key)
			for i in 3: await get_tree().physics_frame
			var sites: FrontierSites=get_node("FrontierSites")
			var buildings:=StrangeSites._building_index(terrain)
			var overlaps:=0
			for part in sites.dressing:
				if StrangeSites._building_overlap(buildings,part.transform*part.mesh.get_aabb()):
					overlaps+=1
					check(not part.visible,"corrected dressing yields to saved paid space")
			check(overlaps>0,"saved construction still overlaps corrected cosmetic trail")
