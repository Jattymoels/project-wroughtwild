extends "res://scripts/sandpit.gd"
## Read-only measurement of actual native scene geometry before C6 authoring.
func vec(v: Vector3) -> Array: return [v.x, v.y, v.z]
func bounds(a: AABB) -> Dictionary: return {"min":vec(a.position), "size":vec(a.size)}
func _ready() -> void:
	world_profile = "living_frontier_wave3"
	world_seed = 77
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_process(false)
	mob_packs.set_physics_process(false)
	set_physics_process(false)
	for ruin: Dictionary in terrain.map.ruins:
		terrain.ensure_area(terrain.surface_position(int(ruin.x),int(ruin.z)),16)
	for i in 3: await get_tree().physics_frame
	var history: CataclysmSites = get_node("CataclysmSites")
	history.refresh_all()
	var records: Array = []
	for part: Node3D in history.pieces:
		if not part.has_meta("site_id"): continue
		var visual: MeshInstance3D = part.get_node("Visual")
		var bodies: Array = []
		if part.has_node("RuinBody"):
			for shape: CollisionShape3D in part.get_node("RuinBody").get_children():
				bodies.append({"position":vec(shape.position),"size":vec(shape.shape.size),"disabled":shape.disabled})
		records.append({"name":str(part.name),"site_id":part.get_meta("site_id"),"asset":part.get_meta("authored_mesh_id", ""),"local_bounds":bounds(visual.mesh.get_aabb()),"world_bounds":bounds(part.global_transform*visual.mesh.get_aabb()),"origin":vec(part.global_position),"basis":[vec(part.basis.x),vec(part.basis.y),vec(part.basis.z)],"shown":part.visible,"bodies":bodies,"story_role":part.get_meta("smithy_evidence","")})
	var trails: Array = []
	for part: MeshInstance3D in get_node("FrontierSites").trail_pieces:
		trails.append({"name":str(part.name),"size":vec(part.mesh.size),"position":vec(part.position),"basis":[vec(part.basis.x),vec(part.basis.y),vec(part.basis.z)],"albedo":part.mesh.material.albedo_color.to_html(),"children":part.get_child_count()})
	var ruins: Array = []
	for r: Dictionary in terrain.map.ruins:
		var routes: Dictionary = {}
		for key in ["approach","discovery_route"]:
			var points: Array = []
			for p: Vector3 in r.get(key,[]): points.append(vec(p))
			routes[key] = points
		ruins.append({"id":r.id,"kind":r.kind,"region":r.region_id,"width":r.width_m,"depth":r.depth_m,"centre":vec(terrain.surface_position(int(r.x),int(r.z))),"rotation_quarters":r.rotation_quarters,"routes":routes})
	var out := {"profile":world_profile,"seed":world_seed,"pieces":records,"trail_pieces":trails,"ruins":ruins,"geography_hash":var_to_bytes(terrain.map).hex_encode().sha256_text(),"sim_hash":_sim().export_json().sha256_text()}
	var file := FileAccess.open("res://c6/survey.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(out,"  "))
	print("C6_SURVEY_OK parts=",records.size()," trail_parts=",trails.size())
	get_tree().quit()
