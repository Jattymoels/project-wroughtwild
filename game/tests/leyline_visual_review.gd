extends "res://tests/strange_frontier_review.gd"
## Isolated visual evidence in the actual V5 world. Never reads or writes the
## owner's user:// save. The same native seed, cameras and lighting are replayed.
var review_phase := "after"
var review_views: Array[Dictionary] = []
var initial_native: Dictionary = {}
class SyntheticPressurePocket extends PressurePocket:
	var supplied_strokes := 24
	func source_state() -> Dictionary:
		return {"remaining": supplied_strokes, "capacity": 24}

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--leyline-phase="): review_phase = arg.get_slice("=", 1)
	world_profile = "frontier_v5"
	world_seed = 1
	output = ProjectSettings.globalize_path("res://../build/leyline-visual/" + review_phase)
	DirAccess.make_dir_recursive_absolute(output)
	var started := Time.get_ticks_msec()
	_build_world(world_seed)
	report.world_setup_ms = Time.get_ticks_msec() - started
	report.terrain_startup = terrain.build_profile.duplicate(true)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.hide()
	player.hud.hide()
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	mood.set_process(false)
	mood.set_physics_process(false)
	set_physics_process(false)
	_setup_camera()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	initial_native = _native_signature()
	report.native_signature = initial_native
	report.phase = review_phase
	report.profile = world_profile
	report.seed = world_seed
	report.scope = "Actual V5 seed1, 1440x900 Forward+, FOV75, grounded 1.65m eye, fixed regional daylight and matched dusk. 90 warmup + 600 uncapped frames per view; PNG readback excluded. Automated review, not a human playtest."
	report.timing_context = "Observed wall frame times; the owner's independent playthrough may share the GPU. Do not interpret noisy baseline tails as a confirmed speedup."
	report.views = []
	_select_views()
	check(review_views.size() == 7, "exposed leyline, all five primary rare finds and accidental old smithy selected")
	var reference_path := ProjectSettings.globalize_path("res://../build/leyline-visual/baseline/manifest.json")
	if review_phase != "baseline" and FileAccess.file_exists(reference_path):
		prior_report = JSON.parse_string(FileAccess.get_file_as_string(reference_path))
		check(initial_native == prior_report.get("native_signature", {}), "visual continuation preserves native blocks, terrain, resource identities and source units")
	for view in review_views:
		await _review_view(view)
	check(_native_signature() == initial_native, "rendering and regrounding leave native generation and quantities untouched")
	if review_phase != "baseline" and not "--leyline-views-only" in OS.get_cmdline_user_args():
		await _trace_invariants()
		var geometry: Dictionary = await preload("res://tests/leyline_geometry_probe.gd").run(self, terrain, get_node("CataclysmSites"))
		checks += int(geometry.checks)
		failures += int(geometry.failures)
		for message in geometry.messages: printerr("FAIL STRANGE WORLD: ", message)
		report.support_probe = geometry
		await _resource_lifecycle()
		_pressure_presentation_probe()
	report.checks = checks
	report.failures = failures
	var file := FileAccess.open(output.path_join("manifest.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	print("LEYLINE_VISUAL_REVIEW %d checks, %d failures; %s" % [checks, failures, review_phase])
	get_tree().quit(0 if failures == 0 else 1)

func _setup_camera() -> void:
	review_camera = Camera3D.new()
	review_camera.fov = 75
	add_child(review_camera)
	review_camera.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	caption = Label.new()
	caption.position = Vector2(24, 22)
	caption.add_theme_font_size_override("font_size", 18)
	caption.add_theme_color_override("font_color", Color("ddd8c9"))
	layer.add_child(caption)

func _digest(value: Variant) -> String:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(var_to_bytes(value))
	return context.finish().hex_encode()

func _native_signature() -> Dictionary:
	var signature: Dictionary = {}
	for key in ["blocks", "heights", "nodes", "rare_sites", "impacts", "leylines", "pressure_pockets"]:
		signature[key] = _digest(terrain.map.get(key, []))
	signature.pressure_ledger = _digest(_sim().contraption_pressure_sources())
	return signature

func _select_views() -> void:
	for line: Dictionary in terrain.map.get("leylines", []):
		var points: PackedVector3Array = line.points
		var exposure: PackedByteArray = line.exposure
		var found := false
		for index in range(points.size() - 1):
			if index >= exposure.size() or exposure[index] != 2: continue
			if points[index].distance_to(points[index + 1]) < 3.0: continue
			var centre := points[index].lerp(points[index + 1], .5)
			var direction := Vector3(points[index + 1].x - points[index].x, 0, points[index + 1].z - points[index].z).normalized()
			var at := centre - direction * 4.0 + direction.cross(Vector3.UP) * 2.7
			review_views.append({"id": "connected_leyline", "at": at, "target": centre, "target_height": .12, "native_id": line.id})
			found = true
			break
		if found: break
	var seen: Dictionary = {}
	for site: Dictionary in terrain.map.rare_sites:
		var kind := String(site.resource_type)
		if seen.has(kind): continue
		seen[kind] = true
		var target := Vector3(float(site.x) + .5, float(site.y), float(site.z) + .5)
		var path: PackedVector3Array = site.approach
		var at := path[maxi(0, path.size() - 5)] if not path.is_empty() else target + Vector3.BACK * 4
		var id := ""
		for row: Dictionary in terrain.map.nodes:
			if row.get("site_id", "") == site.id:
				id = String(row.resource_id)
				target = Vector3(row.x + .5, row.y, row.z + .5)
				break
		review_views.append({"id": "rare_" + kind, "at": at, "target": target, "target_height": .65, "native_id": site.id, "resource_id": id})
	for source: Dictionary in terrain.map.get("pressure_pockets", []):
		var target := Vector3(source.x + .5, source.y, source.z + .5)
		var at: Vector3 = source.work_position
		var toward := Vector3(at.x - target.x, 0, at.z - target.z).normalized()
		review_views.append({"id": "struck_old_smithy", "at": target + toward * 5 + toward.cross(Vector3.UP) * 2, "target": target, "target_height": .8, "native_id": source.id})
		break

func _review_view(view: Dictionary) -> void:
	terrain.set_process(true)
	await _settle(view.at, 64)
	var history := get_node("CataclysmSites") as CataclysmSites
	history.refresh_area(floori(view.target.x) - 12, floori(view.target.z) - 12, 24)
	if view.has("resource_id"):
		var specimen := terrain.resource_stream.materialise(String(view.resource_id))
		check(specimen != null and specimen.remaining_units > 0, "primary rare specimen is live at " + String(view.id))
		if specimen != null:
			check(specimen.has_node("StrangeCore"), "ordinary resource uses shared authored rare art")
			var shape := specimen.get_node("CollisionShape3D") as CollisionShape3D
			check(shape.shape.size == StrangeResourceArt.bounds_for(specimen.visual), "visual finish retains established resource body envelope")
			if review_phase != "baseline": _rare_material_bounds(specimen)
	mood._target = mood.active_mood(mood._biome_under_player())
	mood._apply(1.0)
	review_camera.global_position = _ground(view.at) + Vector3.UP * 1.65
	var target := _ground(view.target) + Vector3.UP * float(view.target_height)
	review_camera.look_at(target)
	terrain.set_process(false)
	var camera_at := review_camera.global_position
	var result := {"id": view.id, "native_id": view.native_id, "camera_position": [camera_at.x, camera_at.y, camera_at.z], "target": [target.x, target.y, target.z]}
	for prior: Dictionary in prior_report.get("views", []):
		if prior.id != view.id: continue
		check(camera_at.distance_to(Vector3(prior.camera_position[0], prior.camera_position[1], prior.camera_position[2])) < .0001 and target.distance_to(Vector3(prior.target[0], prior.target[1], prior.target[2])) < .0001, "before/after uses the exact same grounded camera: " + String(view.id))
	# Preserve the route's loading order while repeating only the final outlier.
	if review_phase == "perf-repeat" and view.id != "rare_pullstone":
		terrain.set_process(true)
		return
	if review_phase != "perf-repeat":
		caption.text = String(view.id).replace("_", " ").to_upper() + " · DAYLIGHT"
		result.day = await _sample_frames()
		if DisplayServer.get_name() != "headless": await _capture(String(view.id) + "-day")
	var energy: float = $Sun.light_energy
	var colour: Color = $Sun.light_color
	$Sun.light_energy = energy * .48
	$Sun.light_color = Color("d9bd91")
	caption.text = String(view.id).replace("_", " ").to_upper() + " · DUSK"
	result.dusk = await _sample_frames()
	if DisplayServer.get_name() != "headless": await _capture(String(view.id) + "-dusk")
	$Sun.light_energy = energy
	$Sun.light_color = colour
	report.views.append(result)
	terrain.set_process(true)

func _rare_material_bounds(specimen: ResourceNode) -> void:
	var finish := specimen.get_node_or_null("StrangeCore/RareFinish") as Node3D
	check(finish != null, "allfive normal rare resources include their shared contained-light finish")
	if finish == null: return
	var body := StrangeResourceArt.bounds_for(specimen.visual)
	var envelope := AABB(Vector3(-body.x * .5, 0, -body.z * .5), body).grow(.04)
	var within_body := true
	var triangles := 0
	var opaque := true
	for child in finish.get_children():
		if not child is MeshInstance3D or child.mesh == null: continue
		within_body = within_body and envelope.encloses(child.transform * child.mesh.get_aabb())
		for surface in child.mesh.get_surface_count():
			var index_count: int = child.mesh.surface_get_array_index_len(surface)
			triangles += (index_count if index_count > 0 else child.mesh.surface_get_array_len(surface)) / 3
		var material := child.material_override as ShaderMaterial
		opaque = opaque and material != null and not "ALPHA" in material.shader.code
	check(within_body, "new local rare geometry stays within its existing body envelope plus four centimetres of motion tolerance: " + String(specimen.visual))
	check(opaque and finish.get_child_count() <= 3 and triangles < 4000, "contained rare light uses bounded opaque meshes without a particle or light network")
	if not report.has("rare_geometry"): report.rare_geometry = {}
	report.rare_geometry[String(specimen.visual)] = {"new_triangles": triangles, "new_meshes": finish.get_child_count(), "within_original_body": within_body}

func _sample_frames() -> Dictionary:
	if DisplayServer.get_name() == "headless": return {"samples": 0, "scope": "headless checks do not measure rendering"}
	for i in 90: await get_tree().process_frame
	var values: Array[float] = []
	var last := Time.get_ticks_usec()
	for i in 600:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		values.append(float(now - last) / 1000.0)
		last = now
	values.sort()
	return {"samples": values.size(), "median_ms": values[300], "p95_ms": values[570], "max_ms": values.back(),
		"draw_calls": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives": RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"loaded_chunks": terrain.chunks.size(), "active_resources": terrain.resource_stream.active.size()}

func _trace_invariants() -> void:
	var view: Dictionary = review_views[0]
	await _settle(view.target, 36)
	var history := get_node("CataclysmSites") as CataclysmSites
	history.refresh_area(floori(view.target.x) - 12, floori(view.target.z) - 12, 24)
	var selected: MeshInstance3D
	var whole_triangles := 0
	var maximum_branches := 0
	for trace in history.traces:
		whole_triangles += int(trace.get_meta("fissure_triangle_count", 0))
		maximum_branches = maxi(maximum_branches, int(trace.get_meta("fissure_branch_count", 0)))
		var bounds: Rect2 = trace.get_meta("xz_bounds", Rect2())
		if trace.mesh != null and String(trace.get_meta("site_id", "")) == view.native_id and bounds.has_point(Vector2(view.target.x, view.target.z)):
			selected = trace
	check(selected != null, "the selected native exposed interval has its actual grounded fissure mesh")
	if selected == null: return
	check(selected.get_child_count() == 0, "surface fracture adds no physics body or traversal obstacle")
	check(selected.mesh.get_surface_count() == 1, "one shared opaque surface bounds local draw cost")
	var material := selected.mesh.surface_get_material(0) as ShaderMaterial
	check(material != null and not "ALPHA" in material.shader.code, "light mask does not turn the fracture into a translucent ribbon")
	var arrays := selected.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var supported := true
	var minimum_lift := INF
	var maximum_lift := -INF
	for vertex in vertices:
		var ground := StrangeSites._ground(terrain, vertex.x, vertex.z)
		if not vertex.is_finite() or not ground.is_finite(): supported = false; continue
		minimum_lift = minf(minimum_lift, vertex.y - ground.y)
		maximum_lift = maxf(maximum_lift, vertex.y - ground.y)
	check(supported and minimum_lift >= -.002 and maximum_lift < .08, "dark mouths and chipped lips remain within eight centimetres of exact supporting terrain")
	check(maximum_branches <= 8 and int(selected.get_meta("fissure_triangle_count", 0)) <= 24000, "branch and local triangle populations remain bounded")
	var original := selected.mesh
	var record: Dictionary = selected.get_meta("record").duplicate(true)
	var synthetic := MeshInstance3D.new()
	var builder := LeylineFissures.new()
	for state in [0, 1]:
		var hidden: Dictionary = record.duplicate(true)
		var exposure: PackedByteArray = hidden.exposure
		exposure.fill(state)
		hidden.exposure = exposure
		synthetic.set_meta("record", hidden)
		builder.rebuild(synthetic, terrain, {})
		check(synthetic.mesh == null, "native buried/broken exposure produces neither fracture nor light")
	# Deliberately cover this tile using the same spatial building index format.
	var bounds: AABB = original.get_aabb().grow(1.0)
	var covering := _covering_index(bounds)
	synthetic.set_meta("record", record)
	builder.rebuild(synthetic, terrain, covering)
	check(synthetic.mesh == null, "player-building footprint suppresses the entire intersecting surface detail")
	builder.rebuild(synthetic, terrain, {})
	check(synthetic.mesh != null and _digest(synthetic.mesh.surface_get_arrays(0)) == _digest(original.surface_get_arrays(0)), "removing the covering restores the exact deterministic fracture")
	synthetic.free()
	report.fissures = {"visible_tile_vertices": vertices.size(), "maximum_branches_per_tile": maximum_branches, "total_generated_triangles": whole_triangles, "minimum_lift_m": minimum_lift, "maximum_lift_m": maximum_lift}
	check(_native_signature() == initial_native, "exposure/building art checks do not change native topology or stock")

func _covering_index(bounds: AABB) -> Dictionary:
	var index: Dictionary = {}
	# Mirror only the published lookup's spatial buckets; this is a synthetic
	# occupied area, not a placed piece or an economy bypass presented as gameplay.
	var bucket: float = preload("res://art/strange_ecology.tres").batch_width_m
	for x in range(floori(bounds.position.x / bucket), floori(bounds.end.x / bucket) + 1):
		for z in range(floori(bounds.position.z / bucket), floori(bounds.end.z / bucket) + 1):
			index[Vector2i(x, z)] = [bounds]
	return index

func _rare_state(node: ResourceNode) -> Dictionary:
	var finish := node.get_node_or_null("StrangeCore/RareFinish") as Node3D
	if finish == null: return {}
	var shader := finish.get_node_or_null("EmbeddedFilaments") as MeshInstance3D
	var material := shader.material_override as ShaderMaterial if shader != null else null
	return {"stock": float(finish.get_meta("stock_fraction", -1)), "work": float(finish.get_meta("work_fraction", -1)),
		"hover": float(material.get_shader_parameter("hover_amount")) if material != null else -1.0, "shown": shader.visible if shader != null else false}

func _aim_resource(body: Node3D) -> bool:
	terrain.ensure_area(body.global_position, 8)
	var collider := body.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var target := collider.global_position if collider != null else body.global_position
	for direction: Vector3 in [Vector3.BACK, Vector3.RIGHT, Vector3.FORWARD, Vector3.LEFT]:
		player.global_position = target + direction * 2.2 - Vector3.UP * .6
		await get_tree().physics_frame
		player.camera.global_position = target + direction * 2.2 + Vector3.UP * .6
		player.camera.look_at(target)
		var query := PhysicsRayQueryParameters3D.create(player.camera.global_position, target)
		query.exclude = [player]
		if get_world_3d().direct_space_state.intersect_ray(query).get("collider") == body: return true
	return false

func _resource_lifecycle() -> void:
	# Cursor hover is deliberately transient, not a saved progression field.
	# Disable only the hidden HUD during lifecycle assertions, after timings.
	player.hud.set_process(false)
	var saved_states: Dictionary = {}
	for view in review_views:
		if not view.has("resource_id"): continue
		await _settle(view.target, 16)
		var node := terrain.resource_stream.materialise(String(view.resource_id))
		check(node != null, "contextual gathering reaches the original stable resource identity")
		if node == null: continue
		var units := node.remaining_units
		check(await _aim_resource(node), "ordinary player aim reaches " + String(node.visual))
		node.set_highlight(false)
		player.interact()
		check(node.drive_progress == 1 and node.remaining_units == units, "first normal E records partial work without granting a component")
		# The ordinary interaction refreshes the HUD's hovered node immediately.
		# Hover is cursor state, so establish its explicit off pose for comparison.
		node.set_highlight(false)
		var partial := _rare_state(node)
		check(not partial.is_empty() and is_equal_approx(float(partial.get("work", -1)), 1.0 / node.drive_presses), "contained light and staged pose show actual partial work")
		node._apply_visual()
		check(_rare_state(node) == partial and node.remaining_units == units and node.drive_progress == 1, "visual rebuild preserves partial pose, stock and gameplay state")
		node.set_highlight(true)
		check(float(_rare_state(node).get("hover", -1)) == 1.0, "hover reaches the contained discovery detail")
		node.set_highlight(false)
		check(_rare_state(node) == partial, "leaving transient hover restores stock/work appearance; expected=" + str(partial) + " actual=" + str(_rare_state(node)))
		saved_states[String(view.resource_id)] = {"units": node.remaining_units, "progress": node.drive_progress, "visual": partial, "at": view.target}
	var manager := SaveManager.new()
	var checkpoint := output.path_join("partial-work-checkpoint.json")
	check(manager.write_data(checkpoint, manager.capture(player)), "review partial-work save writes atomically only under build")
	check(manager.read(checkpoint, player), "normal validating restore accepts the unchanged visual-only save contract")
	await _synthetic_stock_restore(manager, saved_states)
	check(manager.read(checkpoint, player), "restore the untouched normal-gathering checkpoint after the explicitly synthetic stock test")
	for id: String in saved_states:
		var state: Dictionary = saved_states[id]
		await _settle(state.at, 16)
		var node := terrain.resource_stream.materialise(id)
		check(node != null and node.remaining_units == state.units and node.drive_progress == state.progress, "reload restores exact rare quantity and partial work")
		if node == null: continue
		node.set_highlight(false)
		check(_rare_state(node) == state.visual, "reload restores matching reduced stock and work; expected=" + str(state.visual) + " actual=" + str(_rare_state(node)))
		var family := String(node.material_family)
		var before := _sim().material_count(family)
		check(await _aim_resource(node), "ordinary player E still reaches the restored rare body")
		for press in int(state.units) * maxi(node.drive_presses, 1) + 1:
			if node.remaining_units <= 0: break
			player.interact()
		check(node.remaining_units == 0 and not node.get_node("StrangeCore").visible, "normal full depletion hides every luminous core immediately")
		for frame in 180:
			if _sim().material_count(family) >= before + int(state.units): break
			await get_tree().physics_frame
		check(_sim().material_count(family) == before + int(state.units), "finite stock becomes exactly its ordinary physical pickups")
		check(not terrain.resource_stream.has_resource(id), "exhausted specimen leaves the authoritative stream")
	var depleted_checkpoint := output.path_join("depleted-checkpoint.json")
	check(manager.write_data(depleted_checkpoint, manager.capture(player)) and manager.read(depleted_checkpoint, player), "depleted review world restores through the normal save path")
	for id: String in saved_states: check(not terrain.resource_stream.has_resource(id), "reload does not restore depleted stock or its luminous detail")
	check(_native_signature() == initial_native, "finite runtime gathering retains the exact generated identities and terrain")
	report.lifecycle = {"rare_types": saved_states.size(), "partial_saved_and_restored": true, "finite_depletion_saved_and_restored": true, "save_directory": "build/leyline-visual/" + review_phase}

func _synthetic_stock_restore(manager: SaveManager, saved_states: Dictionary) -> void:
	# Each current rare gives its whole 3/4-unit haul at once. Reduced stock is
	# therefore an explicitly synthetic save-compatibility case, not a normal E
	# outcome. This tests the native-capacity visual denominator without changing
	# recipes, yield sizes or the original normal-gathering checkpoint.
	var synthetic := manager.capture(player)
	for row: Dictionary in synthetic.resource_nodes:
		var id := String(row.get("resource_id", ""))
		if saved_states.has(id): row.remaining_units = int(saved_states[id].units) - 1
	var path := output.path_join("synthetic-reduced-stock.json")
	check(manager.write_data(path, synthetic) and manager.read(path, player), "synthetic reduced-stock save restores through unchanged validation")
	for id: String in saved_states:
		var expected: Dictionary = saved_states[id]
		await _settle(expected.at, 16)
		var node := terrain.resource_stream.materialise(id)
		check(node != null and node.remaining_units == int(expected.units) - 1, "synthetic lower quantity is restored, not refilled")
		if node == null: continue
		node.set_highlight(false)
		var state := _rare_state(node)
		var fraction := float(int(expected.units) - 1) / float(expected.units)
		check(is_equal_approx(float(state.get("stock", -1)), fraction) and fraction < 1.0, "synthetic reduced-stock appearance uses original native capacity after reload")
		node._apply_visual()
		check(_rare_state(node) == state, "synthetic reduced-stock appearance survives another visual rebuild")
	report.synthetic_stock_scope = "Save-compatibility probe only: each current rare normally yields its entire stock in one completed harvest. No production yield rule was changed."

func _pressure_presentation_probe() -> void:
	var before := _sim().contraption_save()
	var probe := SyntheticPressurePocket.new()
	add_child(probe)
	for stock in [24, 12, 0]:
		probe.supplied_strokes = stock
		probe.refresh_visual()
		var finish := probe.get_node("RareFinish") as Node3D
		check(is_equal_approx(float(finish.get_meta("stock_fraction", -1)), stock / 24.0), "synthetic old-hearth appearance reflects supplied full/partial/empty source state")
		probe.set_highlight(true)
		var shown := false
		for child in finish.get_children():
			if child.name != &"HostFragments" and child.visible: shown = true
		check(probe._membrane.visible == (stock > 0) and shown == (stock > 0), "highlight never revives an empty source membrane or luminous pressure detail")
	probe.free()
	check(_sim().contraption_save() == before, "synthetic presentation inputs perform no native pressure transfer")
	report.pressure_visual_probe = "Supplied24/12/0 states only; no source ledger, recipe or transfer altered. Actual transfers are covered by pressure_workshop."
