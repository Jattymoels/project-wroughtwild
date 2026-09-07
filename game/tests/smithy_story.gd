extends "res://scripts/sandpit.gd"
## INT-02A: actual generated smithy, existing ray/body interactions and paid
## building/save lifecycle. Isolated test paths only; no presentation benchmark.
var checks := 0
var failures := 0
var history: CataclysmSites
var smithy: Dictionary
var pocket: Dictionary
var source: PressurePocket

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL SMITHY_STORY: ", label)

func _ready() -> void:
	world_profile = "frontier_v6"
	world_seed = 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--story-profile="): world_profile = arg.get_slice("=", 1)
		if arg.begins_with("--story-seed="): world_seed = int(arg.get_slice("=", 1))
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	await get_tree().physics_frame
	check(world_profile in ["frontier_v5", "frontier_v6"], "fixture selects an existing pressure profile")
	check(terrain.map.get("pressure_pockets", []).size() == 1, "one existing finite pressure source")
	if terrain.map.get("pressure_pockets", []).size() != 1: _finish(); return
	pocket = terrain.map.pressure_pockets[0]
	for ruin: Dictionary in terrain.map.ruins:
		if String(ruin.id) == String(pocket.ruin_id): smithy = ruin; break
	check(not smithy.is_empty() and smithy.kind == "pre_cataclysm_blacksmith", "native source selects its old smithy")
	if smithy.is_empty(): _finish(); return
	source = PressurePocket.find_source(get_tree(), String(pocket.id), self)
	check(source != null and source.supported(), "existing source body remains supported")
	if source == null: _finish(); return
	terrain.ensure_area(pocket.work_position, 24)
	player.global_position = pocket.work_position + Vector3.UP * 1.2
	for i in 4: await get_tree().physics_frame
	history = get_node("CataclysmSites")
	history.refresh_area(int(smithy.x) - 12, int(smithy.z) - 12, 24)
	for i in 2: await get_tree().physics_frame
	var rules := _sim().export_json()
	var ledger := _sim().contraption_save()
	var native := _native_signature()
	var group := history.get_node(String(smithy.id))
	check(String(group.get_meta("story_source_id", "")) == String(pocket.id) and String(group.get_meta("story_discovery_id", "")) == String(pocket.linked_site_id), "story evidence uses native source and discovery associations")
	check(String(group.get_meta("story_impact_id", "")) == String(pocket.impact_id), "accidental impact association is retained")
	var roles := {}
	var observation_bodies: Array[StaticBody3D] = []
	for part: Node3D in group.get_children():
		if part.has_node("RuinBody"):
			var body: StaticBody3D = part.get_node("RuinBody")
			observation_bodies.append(body)
			var text := String(body.get_meta("story_observation", ""))
			check(text == CataclysmSites.SMITHY_OBSERVATION and text.length() <= 90 and not text.contains("E to"), "existing ruin wall carries one short observation without an action promise")
		if not part.has_meta("smithy_evidence"): continue
		var role := String(part.get_meta("smithy_evidence"))
		roles[role] = int(roles.get(role, 0)) + 1
		var visual: MeshInstance3D = part.get_node("Visual")
		check(part.visible and bool(part.get_meta("supported", false)), "added remnant is grounded and visible: " + role)
		var bounds := part.transform * visual.mesh.get_aabb()
		var centre_ground := StrangeSites._ground(terrain, part.position.x, part.position.z)
		check(not part.visible or bounds.end.y > centre_ground.y, "visible remnant retains its top above the ground, including thin paving: " + role)
		for x in [bounds.position.x + .1, bounds.end.x - .1]:
			for z in [bounds.position.z + .1, bounds.end.z - .1]:
				var ground := StrangeSites._ground(terrain, x, z)
				check(not part.visible or (bounds.position.y <= ground.y and bounds.end.y > ground.y), "visible remnant meets its supporting corners without a floating foot or buried top: " + role)
		check(not part.has_node("RuinBody") and _body_count(part) == 0 and not part is StationSite, "added evidence has no new collision or station: " + role)
		check(history._story_clear(smithy, pocket, part.transform * visual.mesh.get_aabb()), "honest remnant bounds preserve the native footprint, work strip and source margin: " + role)
		check(visual.mesh == AuthoredAssets.mesh_for(String(part.get_meta("authored_mesh_id"))) and visual.material_override == null, "existing imported mesh and materials are shared: " + role)
	check(observation_bodies.size() == 3, "existing smithy keeps its three original solid wall remnants and source-side breach")
	check(int(roles.get("old_craft", 0)) == 1 and int(roles.get("impact_remnant", 0)) == 2, "one collapsed craft remnant and two directed damage remnants remain bounded")
	check(int(roles.get("arrival_paving", 0)) >= 1 and int(roles.get("discovery_paving", 0)) >= 1, "old paving identifies both the existing arrival and discovery departure")
	for part: Node3D in history.pieces:
		if not part.has_node("RuinBody"): continue
		if String(part.get_meta("site_id", "")) != String(smithy.id):
			check(not part.get_node("RuinBody").has_meta("story_observation"), "other ruins do not inherit the smithy's history")
	await _walk_and_rays(observation_bodies)
	var before := _evidence_signature()
	history.refresh_all()
	history.refresh_buildings()
	check(_evidence_signature() == before, "refresh keeps stable evidence poses instead of rerolling the ruin")
	check(_sim().export_json() == rules and _sim().contraption_save() == ledger and _native_signature() == native, "composition, observation and source inspection change no native rules, stock or geography")
	await _building_and_grounding()
	_finish()

func _body_count(node: Node) -> int:
	var count := 1 if node is CollisionObject3D else 0
	for child in node.get_children(): count += _body_count(child)
	return count

func _native_signature() -> int:
	var values := []
	for key in ["nodes", "rare_sites", "ruins", "impacts", "leylines", "pressure_pockets"]: values.append(terrain.map.get(key, []))
	return hash(values)

func _evidence_signature() -> Array:
	var result := []
	for part: Node3D in history.pieces:
		if part.has_meta("smithy_evidence"): result.append([String(part.name), part.transform, part.visible])
	return result

func _walk_and_rays(walls: Array[StaticBody3D]) -> void:
	var centre := terrain.surface_position(int(smithy.x), int(smithy.z))
	var basis := Basis(Vector3.UP, float(smithy.rotation_quarters) * PI * .5)
	var capsule := CapsuleShape3D.new()
	capsule.radius = .42
	capsule.height = 1.92
	for step in range(-4, 5):
		var at := centre + basis * Vector3(0, 0, step)
		var ground := StrangeSites._ground(terrain, at.x, at.z)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY, ground + Vector3.UP * 1.04)
		var blocked := false
		for hit in get_world_3d().direct_space_state.intersect_shape(query, 32):
			if hit.collider is Node and hit.collider.has_meta("cataclysm_solid"): blocked = true
		check(ground.is_finite() and not blocked, "actual capsule traverses the existing central working strip")
	var observed := false
	for wall in walls:
		if not wall.get_parent().visible: continue
		var shape: CollisionShape3D = wall.get_child(0)
		for direction: Vector3 in [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]:
			var at := shape.global_position + direction * 2.1
			var ground := StrangeSites._ground(terrain, at.x, at.z)
			if not ground.is_finite(): continue
			player.global_position = ground + Vector3.UP * 1.2
			player.camera.global_position = ground + Vector3.UP * 1.65
			player.camera.look_at(shape.global_position)
			var probe := player.aim_probe()
			if String(probe.get("label", "")) != CataclysmSites.SMITHY_OBSERVATION: continue
			observed = true
			check(probe.state == "none" and probe.target == null, "actual aim ray reads the old wall without an E target")
			var rules := _sim().export_json()
			var ledger := _sim().contraption_save()
			player.interact()
			check(_sim().export_json() == rules and _sim().contraption_save() == ledger and not player.work_panel.is_open(), "interacting with the observed wall grants no work, loot or pressure")
			break
		if observed: break
	check(observed, "one existing wall observation is reachable from a grounded gameplay camera")
	var work: Vector3 = pocket.work_position
	player.global_position = work + Vector3.UP * 1.2
	player.camera.global_position = StrangeSites._ground(terrain, work.x, work.z) + Vector3.UP * 1.65
	player.camera.look_at(source.global_position + Vector3.UP * .7)
	var source_probe := player.aim_probe()
	check(source_probe.get("target") == source, "unchanged native work position still aims at the existing pressure source")
	player.interact()
	check(player.work_panel.is_open() and player.work_panel._custom_title == "The struck blacksmith's hearth", "source inspection retains its existing useful interaction")
	player.work_panel.close_panel()

func _building_and_grounding() -> void:
	var native_before := _native_signature()
	var target: Node3D
	for part in history.pieces:
		if String(part.get_meta("smithy_evidence", "")) == "old_craft": target = part; break
	if target == null: check(false, "craft remnant exists for lifecycle probe"); return
	var path := String(history.get_path_to(target))
	var manager := SaveManager.new()
	var original := manager.capture(player)
	var grid := player.placement.registry_grid
	var at := target.position
	var cell := Vector3i(floori(at.x / grid), ceili(terrain.height_at(floori(at.x), floori(at.z)) / grid), floori(at.z / grid))
	var element := {"kind":"volume", "axis":0, "cell":cell}
	player.placement.set_build_mode_enabled(true)
	player.placement.selected_material_family = &"shellstone"
	player.placement.select_shape(&"cube")
	_sim().add_material("shellstone", 12)
	var held := _sim().material_count("shellstone")
	var refusal := player.placement.element_refusal(element)
	check(refusal.is_empty(), "existing building placement accepts inert story evidence: " + refusal)
	player.placement.preview_element = element
	player.placement.preview_visible = true
	check(player.placement.try_place_block(), "normal paid building replaces the decorative remnant")
	player.placement.refresh_ecology()
	check(not target.visible and _sim().material_count("shellstone") == held - int(_sim().shape("cube").material_cost), "building suppression retains the existing exact construction cost")
	var built := manager.capture(player)
	check(manager.apply(player, built), "saved building and story evidence restore together: " + manager.last_error)
	history = get_node("CataclysmSites")
	target = history.get_node(path)
	check(not target.visible, "saved construction keeps the same story evidence suppressed")
	check(manager.apply(player, original), "restore the pre-build world through normal validation")
	history = get_node("CataclysmSites")
	target = history.get_node(path)
	check(target.visible, "removing the saved building restores the supported remnant")
	# A controlled one-column excavation uses the normal saved terrain-edit
	# path. It tests regrounding without introducing a new digging or loot rule.
	var edits: Array = original.get("broken_blocks", []).duplicate(true)
	var x := floori(target.position.x)
	var z := floori(target.position.z)
	var top := floori(terrain.height_at(x, z))
	for y in range(maxi(0, top - 5), top + 1): edits.append([x, y, z])
	terrain.apply_broken_blocks(edits)
	history.refresh_all()
	check(not target.visible and not bool(target.get_meta("supported", true)), "a deep support hole hides the remnant instead of leaving a floating work surface")
	check(_sim().contraption_save() == String(original.contraptions), "building and excavation presentation cannot refill or spend native pressure")
	check(manager.apply(player, original), "restore the isolated fixture after its excavation probe")
	check(_native_signature() == native_before, "fixture retains the same native associations after the edit restore")

func _finish() -> void:
	print("SMITHY_STORY %d checks, %d failures; %s seed %d" % [checks, failures, world_profile, world_seed])
	get_tree().quit(1 if failures else 0)
