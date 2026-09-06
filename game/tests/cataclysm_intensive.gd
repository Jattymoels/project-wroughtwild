extends "res://scripts/sandpit.gd"
## Actual v4/default-world regression. Isolated test saves live under build/.
var checks := 0
var failures := 0
var output := ""

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL CATACLYSM: ", message)

func _ready() -> void:
	# Historical V4 regression remains pinned after the pressure workshop adds V5.
	world_profile = "frontier_v4"
	output = ProjectSettings.globalize_path("res://../build/cataclysm")
	DirAccess.make_dir_recursive_absolute(output)
	super._ready()
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	set_physics_process(false)
	await get_tree().physics_frame
	check(world_profile == "frontier_v4" and terrain.world_profile() == world_profile, "normal game selects the cataclysm profile")
	check(int(terrain.map.width) == 512 and int(terrain.map.height) == 512, "finite world extent stays bounded")
	check(terrain.map.get("impacts", []).size() == 3, "three impact anchors exist")
	check(terrain.map.get("leylines", []).size() >= 2, "connected technological traces exist")
	check(terrain.map.get("ruins", []).size() >= 5, "old settlement remains connect to discoveries")
	check(terrain._augmentation_texture != null, "native augmentation influences actual terrain material")
	var terrain_material := terrain._material_for("grass") as ShaderMaterial
	check(bool(terrain_material.get_shader_parameter("augmentation_enabled")), "v4 enables its own native influence field")
	var history := get_node_or_null("CataclysmSites") as CataclysmSites
	check(history != null, "normal world installs cataclysm presentation")
	if history == null:
		_finish()
		return
	var identities: Dictionary = {}
	for collection in ["impacts", "ruins", "leylines"]:
		for row: Dictionary in terrain.map.get(collection, []):
			check(not identities.has(String(row.id)), "native historical identity is unique")
			identities[String(row.id)] = true
	for impact: Dictionary in terrain.map.impacts:
		var centre := terrain.surface_position(int(impact.x), int(impact.z))
		terrain.ensure_area(centre, 18)
		await get_tree().physics_frame
		history.refresh_area(int(impact.x) - 8, int(impact.z) - 8, 16)
		await get_tree().physics_frame
		var key := "%d_%d" % [floori(centre.x / Terrain.CHUNK_CELLS) * Terrain.CHUNK_CELLS, floori(centre.z / Terrain.CHUNK_CELLS) * Terrain.CHUNK_CELLS]
		var exact: Node3D = terrain.chunks.get(key)
		check(exact != null and exact.has_meta("surface_sampler"), "impact approach installs exact walking terrain: " + String(impact.id))
		var group := history.get_node_or_null(String(impact.id))
		var main_fragment: Node3D = group.get_child(0) as Node3D if group != null and group.get_child_count() > 0 else null
		check(main_fragment != null and main_fragment.get_meta("asset_id", "") == "impact_fragment", "native impact retains its main authored fragment: " + String(impact.id))
		check(main_fragment != null and main_fragment.visible and bool(main_fragment.get_meta("supported", false)), "main impact remains visibly embedded after exact terrain arrives: " + String(impact.id))
	var capsule := CapsuleShape3D.new()
	capsule.radius = .42
	capsule.height = 1.92
	for ruin: Dictionary in terrain.map.ruins:
		var centre := terrain.surface_position(int(ruin.x), int(ruin.z))
		terrain.ensure_area(centre, 18)
		await get_tree().physics_frame
		history.refresh_area(int(ruin.x) - 8, int(ruin.z) - 8, 16)
		await get_tree().physics_frame
		var group := history.get_node_or_null(String(ruin.id))
		check(group != null and group.get_child_count() >= 6, "each ruin has an authored composition")
		var walls := 0
		if group != null:
			for part: Node3D in group.get_children():
				if part.has_node("RuinBody") and part.visible: walls += 1
		check(walls >= 2, "ruin has grounded solid wall remnants")
		var basis := Basis(Vector3.UP, float(ruin.rotation_quarters) * PI * .5)
		for step in range(-3, 4):
			var at := centre + basis * Vector3(0, 0, step)
			var ground := StrangeSites._ground(terrain, at.x, at.z)
			check(ground.is_finite(), "ruin's central approach is grounded")
			if not ground.is_finite(): continue
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, ground + Vector3.UP * 1.04)
			var blocked := false
			for hit in get_world_3d().direct_space_state.intersect_shape(query, 32):
				if hit.collider is Node and hit.collider.has_meta("cataclysm_solid"): blocked = true
			check(not blocked, "actual player capsule has a clear central ruin route")
	# A rare haul still reaches its existing useful creation through ordinary work.
	var target: Dictionary = {}
	for row: Dictionary in terrain.map.nodes:
		if row.type == "thrumroot": target = row; break
	check(not target.is_empty(), "Thrumroot discovery survives the composed geography")
	if not target.is_empty():
		terrain.ensure_area(Vector3(target.x + .5, target.y, target.z + .5), 18)
		var node := terrain.resource_stream.materialise(String(target.resource_id))
		check(node != null, "rare node activates at its linked discovery")
		if node != null:
			var initial := node.remaining_units
			var carried := _sim().material_count("thrumroot")
			check(await _aim_body(node), "normal interaction ray reaches the Thrumroot specimen")
			for press in node.drive_presses: player.interact()
			var released := initial - node.remaining_units
			check(released > 0, "contextual work extracts an existing finite component")
			check(_sim().material_count("thrumroot") == carried, "freed component remains a physical drop before collection")
			check(await _collect_gain("thrumroot", carried, released), "nearby pickup absorption delivers exactly the freed component")
			_sim().add_station("workbench")
			_sim().add_materials({"wood": 8, "iron_ingot": 2})
			check(_sim().craft("assemble_cargo_winch").crafted, "the discovered component makes the existing useful winch")
	await _persistence(history)
	_finish()

func _persistence(history: CataclysmSites) -> void:
	var manager := SaveManager.new()
	var first: ResourceNode
	var second: ResourceNode
	for row: Dictionary in terrain.map.nodes:
		if not String(row.get("site_id", "")).is_empty() and int(row.get("drive_presses", 1)) > 1 and terrain.resource_stream.has_resource(String(row.resource_id)):
			if first == null: first = terrain.resource_stream.materialise(String(row.resource_id))
			elif second == null:
				second = terrain.resource_stream.materialise(String(row.resource_id))
				break
	check(first != null and second != null, "save fixture has two finite specimens")
	if first == null or second == null: return
	var partial_id := first.resource_id
	var partial_units := first.remaining_units
	check(await _aim_body(first), "normal interaction ray reaches the partial-work specimen")
	player.interact()
	check(first.drive_progress == 1 and first.remaining_units == partial_units, "one contextual press saves genuine incomplete work without yielding stock")
	var depleted_id := second.resource_id
	var depleted_family := String(second.material_family)
	var depleted_units := second.remaining_units
	var carried := _sim().material_count(depleted_family)
	check(await _aim_body(second), "normal interaction ray reaches the depletion specimen")
	for press in depleted_units * maxi(second.drive_presses, 1) + 1:
		if second.remaining_units <= 0: break
		player.interact()
	check(second.remaining_units == 0, "repeated contextual harvesting fully exhausts the finite specimen")
	check(await _collect_gain(depleted_family, carried, depleted_units), "depleted specimen's entire stock is collected exactly once")
	check(not terrain.resource_stream.has_resource(depleted_id), "fully harvested specimen leaves the authoritative resource stream")
	await get_tree().process_frame
	var editable: Node3D
	for part in history.pieces:
		if part.visible and part.has_node("RuinBody"): editable = part; break
	check(editable != null, "a normal ruin wall is available for building overlap review")
	if editable != null:
		var id := String(editable.get_meta("site_id")) + "/" + String(editable.name)
		var at := editable.position
		terrain.ensure_area(at, 18)
		await get_tree().physics_frame
		var grid := player.placement.registry_grid
		var cell := Vector3i(floori(at.x / grid), ceili(terrain.height_at(floori(at.x), floori(at.z)) / grid), floori(at.z / grid))
		var element := {"kind": "volume", "axis": 0, "cell": cell}
		player.placement.set_build_mode_enabled(true)
		player.placement.selected_material_family = &"shellstone"
		player.placement.select_shape(&"cube")
		_sim().add_material("shellstone", 12)
		var material_before := _sim().material_count("shellstone")
		var reason := player.placement.element_refusal(element)
		check(reason.is_empty(), "normal placement accepts replaceable ruin scenery: " + reason)
		player.placement.preview_element = element
		player.placement.preview_visible = true
		check(player.placement.try_place_block(), "normal paid construction places the selected piece")
		check(_sim().material_count("shellstone") == material_before - int(_sim().shape("cube").material_cost), "construction pays the existing material cost once")
		await get_tree().process_frame
		await get_tree().physics_frame
		check(not editable.visible, "new construction clears intersecting ruin geometry")
		var collider := editable.get_node("RuinBody").get_child(0) as CollisionShape3D
		check(collider.disabled, "hidden scenery leaves no invisible solid wall")
		var saved := manager.capture(player)
		var field: PackedFloat32Array = terrain.map.augmentation_field.duplicate()
		check(manager.write_data(output.path_join("checkpoint.json"), saved), "v4 world/player/build checkpoint writes atomically")
		check(manager.read(output.path_join("checkpoint.json"), player), "v4 checkpoint restores through normal validation")
		check(terrain.map.augmentation_field == field, "reload retains exact augmentation geography")
		var restored := get_node("CataclysmSites").get_node_or_null(id) as Node3D
		check(restored != null and not restored.visible, "saved building still clears the same deterministic ruin")
		check(not terrain.resource_stream.has_resource(depleted_id), "depleted specimen stays depleted after full restore")
		var partial := terrain.resource_stream.materialise(partial_id)
		check(partial != null and partial.drive_progress == 1 and partial.remaining_units == partial_units, "partial work and remaining stock restore exactly")
		var placed: PlacedBlock
		for child in get_children():
			if child is PlacedBlock and child.element == element: placed = child; break
		check(placed != null, "the paid building piece restores at the same lattice address")
		if placed != null and restored != null:
			check(await _aim_body(placed), "normal removal ray selects the restored player piece")
			player.placement.set_build_mode_enabled(true)
			check(player.placement.try_remove_block(), "normal removal dismantles the player piece")
			await get_tree().process_frame
			await get_tree().physics_frame
			check(restored.visible, "removing the intersecting building restores the supported ruin")
			var restored_collision := restored.get_node("RuinBody").get_child(0) as CollisionShape3D
			check(not restored_collision.disabled, "restored ruin resumes its visible wall collision")
		for profile in ["legacy_v1", "frontier_v2", "frontier_v3"]:
			check(apply_world_identity(world_seed, profile), "older profile remains selectable: " + profile)
			check(get_node_or_null("CataclysmSites") == null and terrain._augmentation_texture == null, "old geography gains no retrofitted history or influence texture")
		check(manager.apply(player, saved), "return from old profiles to the identical v4 save")
		var rejected := saved.duplicate(true)
		rejected.world_profile = "frontier_unknown"
		var before := _sim().export_json()
		check(not manager.apply(player, rejected) and before == _sim().export_json(), "unknown future profile rejects without mutating possessions")

func _aim_body(body: Node3D) -> bool:
	# Move the fixture player near the actual target and use the real ray. No
	# direct work/harvest/placement bypass supplies the outcome being asserted.
	terrain.ensure_area(body.global_position, 8)
	var shape := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var target := shape.global_position if shape != null else body.global_position
	for direction: Vector3 in [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]:
		player.global_position = target + direction * 2.2 - Vector3.UP * .6
		await get_tree().physics_frame
		player.camera.global_position = target + direction * 2.2 + Vector3.UP * .6
		player.camera.look_at(target)
		var ray := PhysicsRayQueryParameters3D.create(player.camera.global_position, target)
		ray.exclude = [player]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if hit.get("collider") == body: return true
	return false

func _collect_gain(family: String, before: int, amount: int) -> bool:
	# Physical chips use their ordinary magnet and absorption code while the
	# nearby player remains still. The bound catches absent or duplicated gain.
	for frame in 180:
		if _sim().material_count(family) >= before + amount: break
		await get_tree().physics_frame
	return amount > 0 and _sim().material_count(family) == before + amount

func _finish() -> void:
	var file := FileAccess.open(output.path_join("checks.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures, "profile": world_profile, "startup": terrain.build_profile}, "\t"))
	print("CATACLYSM_INTENSIVE %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)
