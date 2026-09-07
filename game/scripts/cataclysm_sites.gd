class_name CataclysmSites
extends Node3D
## Native records own history and site identity. These grounded compositions
## add space and evidence, never a second resource roll or an extraction gate.
const LOOK = preload("res://art/cataclysm_look.tres")
const SMITHY_OBSERVATION := "An abandoned old hearth, split by an accidental asteroid strike."
var terrain: Terrain
var pieces: Array[Node3D] = []
var traces: Array[MeshInstance3D] = []
var _fissures := LeylineFissures.new()
# One pending entry per existing tile; integer identities retain no terrain or
# scene nodes. Only ordinary distant chunk arrivals use this cosmetic queue.
var _pending_traces: Dictionary = {}

static func build(root: Node3D, ground: Terrain) -> CataclysmSites:
	var old := root.get_node_or_null("CataclysmSites")
	if old != null:
		root.remove_child(old)
		old.queue_free()
	if ground.world_profile() not in ["frontier_v4","frontier_v5","frontier_v6"]: return null
	var result := CataclysmSites.new()
	result.name = "CataclysmSites"
	result.terrain = ground
	root.add_child(result)
	result._compose()
	return result

func _compose() -> void:
	for data: Dictionary in terrain.map.get("impacts", []): _impact(data)
	for data: Dictionary in terrain.map.get("ruins", []): _ruin(data)
	for data: Dictionary in terrain.map.get("leylines", []):
		for record: Dictionary in _trace_records(data):
			var trace := MeshInstance3D.new()
			trace.name = String(record.id)
			trace.set_meta("record", record)
			trace.set_meta("site_id", String(data.id))
			trace.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			trace.visibility_range_end = LeylineFissures.LOOK.distance_m
			trace.visibility_range_end_margin = LeylineFissures.LOOK.distance_margin_m
			add_child(trace)
			traces.append(trace)
	refresh_buildings()

func _trace_records(data: Dictionary) -> Array[Dictionary]:
	# Small spatial tiles bound regrounding cost when one streamed chunk arrives.
	# Disjoint segments in a tile are joined with an explicitly hidden gap.
	var result: Array[Dictionary] = []
	var tiles: Dictionary = {}
	var path: PackedVector3Array = data.get("points", PackedVector3Array())
	var exposure: PackedByteArray = data.get("exposure", PackedByteArray())
	for i in range(path.size() - 1):
		var cuts := maxi(1, ceili(path[i].distance_to(path[i + 1]) / Terrain.CHUNK_CELLS))
		for cut in cuts:
			var a := path[i].lerp(path[i + 1], float(cut) / cuts)
			var b := path[i].lerp(path[i + 1], float(cut + 1) / cuts)
			var mid := (a + b) * .5
			var key := Vector2i(floori(mid.x / Terrain.CHUNK_CELLS), floori(mid.z / Terrain.CHUNK_CELLS))
			if not tiles.has(key):
				var record := data.duplicate()
				record.id = String(data.id) + "_%d_%d" % [key.x, key.y]
				record.points = PackedVector3Array()
				record.exposure = PackedByteArray()
				record.fissure_tapers = PackedByteArray()
				tiles[key] = record
			var record: Dictionary = tiles[key]
			var points: PackedVector3Array = record.points
			var states: PackedByteArray = record.exposure
			var tapers: PackedByteArray = record.fissure_tapers
			if not points.is_empty():
				states.append(0)
				tapers.append(3)
			points.append(a)
			points.append(b)
			states.append(exposure[i] if i < exposure.size() else 0)
			# A tile boundary is an implementation detail, not another broken
			# geological endpoint. Only actual exposed-run ends narrow to a tip.
			var taper_flags := 0
			if cut == 0 and (i == 0 or i - 1 >= exposure.size() or exposure[i - 1] != 2): taper_flags |= 1
			if cut == cuts - 1 and (i + 1 >= exposure.size() or exposure[i + 1] != 2): taper_flags |= 2
			tapers.append(taper_flags)
			record.points = points
			record.exposure = states
			record.fissure_tapers = tapers
	for record: Dictionary in tiles.values(): result.append(record)
	return result

func _ground(x: float, z: float) -> Vector3:
	return StrangeSites._ground(terrain, x, z)

func _centre(data: Dictionary) -> Vector3:
	var cell := float(terrain.map.cell_size)
	return _ground((float(data.x) + .5) * cell, (float(data.z) + .5) * cell)

func _piece(group: Node3D, id: String, at: Vector3, yaw: float, solid := false, size := Vector3.ONE, authored_id := "") -> Node3D:
	var mesh_id := "cataclysm_" + id if authored_id.is_empty() else authored_id
	var mesh := AuthoredAssets.mesh_for(mesh_id)
	if mesh == null:
		push_error("Missing cataclysm authored asset: " + id)
		return null
	var node := Node3D.new()
	node.name = id + "_" + str(group.get_child_count())
	node.position = at
	node.rotation.y = yaw
	node.scale = size
	node.set_meta("asset_id", id)
	node.set_meta("authored_mesh_id", mesh_id)
	node.set_meta("anchor_y", at.y)
	node.set_meta("site_id", group.name)
	node.set_meta("embedded_fragment", id == "impact_fragment")
	var visual := MeshInstance3D.new()
	visual.name = "Visual"
	visual.mesh = mesh
	visual.visibility_range_end = LOOK.detail_distance_m if "inlay" in id or "paving" in id else LOOK.structure_distance_m
	visual.visibility_range_end_margin = 12
	node.add_child(visual)
	if solid:
		var body := StaticBody3D.new()
		body.name = "RuinBody"
		body.set_meta("cataclysm_solid", true)
		if String(group.get_meta("record", {}).get("kind", "")) == "pre_cataclysm_blacksmith":
			body.set_meta("story_observation", SMITHY_OBSERVATION)
		node.add_child(body)
		# Only solid low walls use their close authored envelope. Open frames,
		# fallen roof debris and roots remain outside the walking route.
		var shape := BoxShape3D.new()
		shape.size = mesh.get_aabb().size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		collision.position = mesh.get_aabb().get_center()
		body.add_child(collision)
	group.add_child(node)
	pieces.append(node)
	_reground(node)
	return node

func _group(data: Dictionary) -> Node3D:
	var group := Node3D.new()
	group.name = String(data.id)
	group.set_meta("record", data)
	group.set_meta("site_id", String(data.id))
	add_child(group)
	return group

func _impact(data: Dictionary) -> void:
	var group := _group(data)
	var centre := _centre(data)
	if not centre.is_finite(): return
	var direction: Vector3 = data.get("impact_direction", Vector3.FORWARD)
	# The worked fracture face points back along the incoming direction, where
	# its long scar and the ordinary approach reveal the source of the damage.
	var yaw := atan2(-direction.x, -direction.z)
	if String(data.get("kind",""))=="blacksmith_strike":
		_piece(group,"impact_fragment",centre,yaw,false,LOOK.blacksmith_impact_scale)
		return
	_piece(group, "impact_fragment", centre, yaw, false, LOOK.impact_scale)
	# Fragments describe the same directed event at descending scale.
	for i in 3:
		var offset := Basis(Vector3.UP, yaw) * Vector3(-2.4 + i * 2.6, 0, -4.0 - i * 1.2)
		var at := _ground(centre.x + offset.x, centre.z + offset.z)
		if at.is_finite(): _piece(group, "impact_fragment", at, yaw + .24 * (i - 1), false, Vector3.ONE * (.24 + i * .07))

func _ruin(data: Dictionary) -> void:
	var group := _group(data)
	var centre := _centre(data)
	if not centre.is_finite(): return
	var region_id := String(data.get("region_id", ""))
	var is_forge := "forge" in String(data.get("kind", "")) or "forge" in String(data.id)
	var is_smithy:=String(data.get("kind",""))=="pre_cataclysm_blacksmith"
	var family := "rootvault" if region_id == "rootvault_wildwood" else "fen" if region_id == "lantern_fen" else "upland"
	var yaw := float(data.get("rotation_quarters", 0)) * PI * .5
	var basis := Basis(Vector3.UP, yaw)
	# Keep the central 3 m strip open from entrance to discovery. The native
	# footprint is reserved before ecology and resources are populated.
	var half_width := float(data.get("width_m", 12.0)) * .5
	var half_depth := float(data.get("depth_m", 12.0)) * .5
	var side_x := maxf(2.9, half_width - 1.15)
	for side in [-1.0, 1.0]:
		for z in [-half_depth * .44, half_depth * .32]:
			# The source enters the older hearth through this impact breach.
			# Preserve its central work point and source-side inspection ray.
			if is_smithy and side>0 and z<0:continue
			var offset := basis * Vector3(side * side_x, 0, z)
			var at := _ground(centre.x + offset.x, centre.z + offset.z)
			if at.is_finite(): _piece(group, family + "_wall", at, yaw + PI * .5, true)
		# Broken roofing is kept at the outside edge, never spread across the
		# promised approach or an intact specimen's working circle.
		var end := basis * Vector3(side * (side_x - .4), 0, -half_depth * .63)
		var end_at := _ground(centre.x + end.x, centre.z + end.z)
		if end_at.is_finite() and not (is_smithy and side>0):
			_piece(group, family + "_roof" if family != "upland" else "upland_shelter", end_at, yaw + side * .2, false, Vector3.ONE * .78)
	var feature_offset := basis * Vector3(-side_x + .5, 0, half_depth * .6)
	var feature_at := _ground(centre.x + feature_offset.x, centre.z + feature_offset.z)
	if feature_at.is_finite():
		var feature := "root_fragment" if family == "rootvault" else "fen_cistern" if family == "fen" else "upland_shelter"
		_piece(group, feature, feature_at, yaw, false, Vector3.ONE * .85)
	# Framing survives at a margin, rather than inserting a new solid gate.
	# The doorway occupies the middle gap between the two side-wall segments.
	# Its opening follows the side wall, and no solid board lies across it.
	var frame_at := _ground(centre.x + (basis * Vector3(side_x, 0, -.06 * half_depth)).x, centre.z + (basis * Vector3(side_x, 0, -.06 * half_depth)).z)
	if frame_at.is_finite():
		_piece(group, "forge_threshold" if is_forge else "rootvault_frame" if family == "rootvault" else "upland_shelter" if family == "upland" else "fen_wall", frame_at, yaw + PI * .5)
	# Recognisable fragments of an old worked path, with the living ground
	# showing through. Paving is low non-colliding dressing, not new stock.
	for i in 3:
		var offset := basis * Vector3(.28 * sin(float(i) * 2.1), 0, (i - 1) * 2.8)
		var at := _ground(centre.x + offset.x, centre.z + offset.z)
		if at.is_finite(): _piece(group, "upland_paving", at, yaw, false, Vector3(.75, .45, .8))
	group.set_meta("linked_site_id", String(data.get("linked_site_id", "")))
	group.set_meta("open_strip_m", 3.0)
	if is_smithy: _smithy_story(group, data, centre, basis)

func _smithy_story(group: Node3D, data: Dictionary, centre: Vector3, basis: Basis) -> void:
	# Select the same source/impact/discovery relationship the native map owns.
	# No opportunistic nearest-site lookup or a second history roll is needed.
	var source: Dictionary = {}
	for candidate: Dictionary in terrain.map.get("pressure_pockets", []):
		if String(candidate.get("ruin_id", "")) == String(data.id): source = candidate; break
	if source.is_empty() or not bool(source.get("accidental", false)): return
	if String(source.get("linked_site_id", "")) != String(data.get("linked_site_id", "")): return
	group.set_meta("story_source_id", String(source.id))
	group.set_meta("story_impact_id", String(source.get("impact_id", "")))
	group.set_meta("story_discovery_id", String(source.get("linked_site_id", "")))
	var yaw := float(data.get("rotation_quarters", 0)) * PI * .5
	var damage: Vector3 = data.get("damage_direction", basis * Vector3.FORWARD)
	damage.y = 0
	if damage.length_squared() == 0: damage = basis * Vector3.FORWARD
	damage = damage.normalized()
	var damage_yaw := atan2(damage.x, damage.z)
	var craft_offset: Vector2 = LOOK.smithy_craft_offset_m
	# Read the explicitly serialized packed arrays after resource construction.
	# Constant-preload analysis can otherwise see null script defaults during
	# the initial import of the mutually dependent world/actor scripts.
	var remnant_offsets: PackedVector2Array = LOOK.get("smithy_remnant_offsets_m")
	var paving_distances: PackedFloat32Array = LOOK.get("smithy_paving_distances_m")
	if remnant_offsets.is_empty() or paving_distances.is_empty():
		push_error("Smithy story requires its authored remnant and paving settings.")
		return
	_story_piece(group, data, source, "old_craft", "workbench", centre + basis * Vector3(craft_offset.x, 0, craft_offset.y),
		Basis(Vector3.UP, yaw) * Basis(Vector3.FORWARD, deg_to_rad(LOOK.smithy_craft_roll_degrees)), LOOK.smithy_craft_bounds_m)
	for offset: Vector2 in remnant_offsets:
		_story_piece(group, data, source, "impact_remnant", "cataclysm_rootvault_roof", centre + basis * Vector3(offset.x, 0, offset.y),
			Basis(Vector3.UP, damage_yaw), LOOK.smithy_remnant_bounds_m)
	for route_name in ["approach", "discovery_route"]:
		var path: PackedVector3Array = data.get(route_name, PackedVector3Array())
		if path.size() < 2: continue
		# A route is world-space and may turn inside the foundation. Its closest
		# non-central point gives the actual approach/exit, not a cardinal guess.
		var direction := Vector3.ZERO
		if route_name == "approach":
			for index in range(path.size() - 1, -1, -1):
				direction = Vector3(path[index].x - centre.x, 0, path[index].z - centre.z)
				if direction.length() >= paving_distances[0]: break
		else:
			for point: Vector3 in path:
				direction = Vector3(point.x - centre.x, 0, point.z - centre.z)
				if direction.length() >= paving_distances[0]: break
		if direction.length_squared() == 0: continue
		direction = direction.normalized()
		var edge := direction.cross(Vector3.UP) * LOOK.smithy_paving_side_m
		var role := "arrival_paving" if route_name == "approach" else "discovery_paving"
		for distance: float in paving_distances:
			var at := centre + direction * distance + edge
			var part := _story_piece(group, data, source, role, "cataclysm_upland_paving", at,
				Basis(Vector3.UP, atan2(direction.x, direction.z)), LOOK.smithy_paving_bounds_m)
			# The opposite old path margin may be the one clear of the hearth.
			if part == null:
				_story_piece(group, data, source, role, "cataclysm_upland_paving", at - edge * 2,
					Basis(Vector3.UP, atan2(direction.x, direction.z)), LOOK.smithy_paving_bounds_m)

func _story_piece(group: Node3D, ruin: Dictionary, source: Dictionary, role: String, mesh_id: String, at: Vector3, rotation_basis: Basis, maximum_size: Vector3) -> Node3D:
	var mesh := AuthoredAssets.mesh_for(mesh_id)
	if mesh == null: return null
	var rotated := Transform3D(rotation_basis, Vector3.ZERO) * mesh.get_aabb()
	var fit := maximum_size / rotated.size
	var scale_factor := minf(fit.x, minf(fit.y, fit.z))
	var proposed := Transform3D(rotation_basis.scaled(Vector3.ONE * scale_factor), at)
	var bounds := proposed * mesh.get_aabb()
	if not _story_clear(ruin, source, bounds): return null
	var part := _piece(group, "smithy_" + role, at, 0, false, Vector3.ONE, mesh_id)
	if part == null: return null
	part.basis = proposed.basis
	part.set_meta("smithy_evidence", role)
	part.set_meta("story_damage_direction", ruin.get("damage_direction", Vector3.ZERO))
	part.get_node("Visual").visibility_range_end = LOOK.detail_distance_m
	_reground(part)
	if not bool(part.get_meta("supported", false)):
		pieces.erase(part)
		group.remove_child(part)
		part.queue_free()
		return null
	return part

func _story_clear(ruin: Dictionary, source: Dictionary, bounds: AABB) -> bool:
	var centre := _centre(ruin)
	var basis := Basis(Vector3.UP, float(ruin.get("rotation_quarters", 0)) * PI * .5)
	var local := Transform3D(basis, centre).affine_inverse() * bounds
	var half_width := float(ruin.width_m) * .5 - LOOK.smithy_footprint_inset_m
	var half_depth := float(ruin.depth_m) * .5 - LOOK.smithy_footprint_inset_m
	if local.position.x < -half_width or local.end.x > half_width or local.position.z < -half_depth or local.end.z > half_depth: return false
	if local.position.x < LOOK.smithy_work_strip_half_width_m and local.end.x > -LOOK.smithy_work_strip_half_width_m: return false
	var cell := float(terrain.map.cell_size)
	var source_at := Vector2((float(source.x) + .5) * cell, (float(source.z) + .5) * cell)
	var footprint := Rect2(Vector2(bounds.position.x, bounds.position.z), Vector2(bounds.size.x, bounds.size.z))
	var source_bounds := Rect2(source_at, Vector2.ZERO).grow(float(source.get("radius_m", .8)) + LOOK.smithy_source_clearance_m)
	return not footprint.intersects(source_bounds)

func _reground(node: Node3D) -> void:
	var visual := node.get_node("Visual") as MeshInstance3D
	var at := _ground(node.position.x, node.position.z)
	var supported := at.is_finite()
	if supported:
		node.position.y = at.y - LOOK.bury_m
		var story := node.has_meta("smithy_evidence")
		var local_bounds := AABB()
		var story_bury := LOOK.bury_m
		var tolerance := LOOK.support_tolerance_m
		if story:
			# Fallen craft can be rolled onto its side. Its measured bottom,
			# rather than the original upright pivot, must meet the ground.
			local_bounds = Transform3D(node.basis, Vector3.ZERO) * visual.mesh.get_aabb()
			story_bury = minf(LOOK.bury_m, local_bounds.size.y * LOOK.smithy_bury_height_fraction)
			tolerance = minf(LOOK.support_tolerance_m, local_bounds.size.y * LOOK.smithy_support_height_fraction)
			node.position.y = at.y - story_bury - local_bounds.position.y
		var bounds := node.transform * visual.mesh.get_aabb()
		var lowest := at.y
		var highest := at.y
		var embedded := bool(node.get_meta("embedded_fragment", false))
		# Check the footprint, not just its pivot, after digging or streaming.
		for x in [bounds.position.x + .1, bounds.end.x - .1]:
			for z in [bounds.position.z + .1, bounds.end.z - .1]:
				var sample := _ground(x, z)
				if not sample.is_finite():
					supported = false
				else:
					lowest = minf(lowest, sample.y)
					highest = maxf(highest, sample.y)
					if not embedded and absf(sample.y - at.y) > tolerance: supported = false
		if embedded:
			# A buried meteor is not a wall foundation. Sink its broad foot to
			# the lowest support; retain only fragments with a visible crown.
			node.position.y = lowest - LOOK.bury_m
			if highest - lowest > bounds.size.y * (1.0 - LOOK.impact_exposed_fraction): supported = false
		elif story:
			# A horizontal worn slab must not float above its lowest corner.
			# Reject a rise that would conceal its thin top at the other edge.
			node.position.y = lowest - story_bury - local_bounds.position.y
			if highest - lowest > tolerance: supported = false
	node.set_meta("supported", supported)
	_apply_visibility(node, supported and not bool(node.get_meta("hidden_by_building", false)))

func _apply_visibility(node: Node3D, shown: bool) -> void:
	node.visible = shown
	var body := node.get_node_or_null("RuinBody")
	if body != null:
		for collision: CollisionShape3D in body.get_children(): collision.set_deferred("disabled", not shown)

func refresh_buildings() -> void:
	if terrain == null: return
	_pending_traces.clear()
	var index := StrangeSites._building_index(terrain)
	for node in pieces:
		var visual := node.get_node("Visual") as MeshInstance3D
		var hidden := StrangeSites._building_overlap(index, node.transform * visual.mesh.get_aabb())
		node.set_meta("hidden_by_building", hidden)
		_apply_visibility(node, bool(node.get_meta("supported", false)) and not hidden)
	# Rebuild only on a building action, never per-frame. Individual strip
	# segments underneath a placed floor disappear and return on dismantling.
	for trace in traces: _trace(trace, index)

func refresh_area(cx: int, cz: int, width: int, defer_traces := false) -> void:
	var cell := float(terrain.map.cell_size)
	var bounds := Rect2(Vector2(cx - 5, cz - 5) * cell, Vector2.ONE * (width + 10) * cell)
	var index := StrangeSites._building_index(terrain)
	for node in pieces:
		if not bounds.has_point(Vector2(node.position.x, node.position.z)): continue
		_reground(node)
		var visual := node.get_node("Visual") as MeshInstance3D
		var hidden := StrangeSites._building_overlap(index, node.transform * visual.mesh.get_aabb())
		node.set_meta("hidden_by_building", hidden)
		_apply_visibility(node, bool(node.get_meta("supported", false)) and not hidden)
	for i in traces.size():
		var trace := traces[i]
		if not bounds.intersects(trace.get_meta("xz_bounds", Rect2())): continue
		if defer_traces:
			_pending_traces[trace.get_instance_id()] = i
		else:
			_trace(trace, index, true)

func step_trace_refresh() -> bool:
	if _pending_traces.is_empty(): return false
	var id: int = _pending_traces.keys()[0]
	var index: int = _pending_traces[id]
	_pending_traces.erase(id)
	if index < traces.size() and is_instance_valid(traces[index]) and traces[index].get_instance_id() == id:
		# Re-read current support and buildings, never publish an old prepared
		# snapshot after a dig, retirement, replacement or building action.
		_trace(traces[index], StrangeSites._building_index(terrain), true)
	return true

func refresh_all() -> void:
	for node in pieces: _reground(node)
	refresh_buildings()

func _trace(trace: MeshInstance3D, buildings: Dictionary = {}, only_surface_changes := false) -> void:
	_pending_traces.erase(trace.get_instance_id())
	# A streamed chunk can overlap the broad refresh margin without changing
	# any surface a fissure samples. Keep only exact node IDs, never strong
	# sampler/node references that would defeat distant-terrain retirement.
	var ids := _trace_surface_ids(trace)
	if only_surface_changes and trace.get_meta("sampled_chunk_ids", PackedInt64Array()) == ids \
			and trace.get_meta("sampled_profile", "") == terrain.world_profile() \
			and int(trace.get_meta("sampled_seed", -1)) == terrain.seed_value():
		return
	_fissures.rebuild(trace, terrain, buildings)
	trace.set_meta("sampled_chunk_ids", ids)
	trace.set_meta("sampled_profile", terrain.world_profile())
	trace.set_meta("sampled_seed", terrain.seed_value())

func _trace_surface_ids(trace: MeshInstance3D) -> PackedInt64Array:
	var ids := PackedInt64Array([terrain.get_instance_id()])
	var path: PackedVector3Array = trace.get_meta("record", {}).get("points", PackedVector3Array())
	if path.is_empty(): return ids
	var bounds := Rect2(Vector2(path[0].x,path[0].z),Vector2.ZERO)
	for point in path: bounds = bounds.expand(Vector2(point.x,point.z))
	var look = LeylineFissures.LOOK
	# Every sampled centre lies on a native interval or a branch/twig. Bound
	# all three possible curve jitters, the longest branch and a whole twig;
	# include chipped outer columns and the independently wandering light.
	var cross_width := 0.0
	for column in LeylineFissures.CROSS_SECTION: cross_width = maxf(cross_width,absf(column))
	var edge_stretch := maxf(1.0,absf(1.0-look.edge_width_variation))
	var half_width := maxf(absf(look.minimum_width_m),absf(look.maximum_width_m))*0.5
	var width_scale := maxf(1.0,absf(look.branch_width_fraction))
	var lateral := half_width*width_scale*maxf(cross_width*edge_stretch,0.035+absf(look.strand_wander_fraction))
	var reach := 3.0*absf(look.meander_m)+maxf(absf(look.branch_minimum_m),absf(look.branch_maximum_m))+absf(look.twig_length_m)+lateral
	var cell := float(terrain.map.get("cell_size",1.0))
	# rendered_height also reads neighbours within half a voxel of a seam.
	# Inclusive limits conservatively retain a boundary neighbour at exact ties.
	bounds = bounds.grow(reach+cell*0.5)
	var side := Terrain.CHUNK_CELLS*cell
	var first := Vector2i(floori(bounds.position.x/side),floori(bounds.position.y/side))
	var last := Vector2i(floori(bounds.end.x/side),floori(bounds.end.y/side))
	# Grid coordinates accompany IDs so equal vectors cannot alias footprints.
	ids.append(first.x)
	ids.append(first.y)
	ids.append(last.x)
	ids.append(last.y)
	for z in range(first.y,last.y+1):
		for x in range(first.x,last.x+1):
			var chunk: Node3D = terrain.chunks.get("%d_%d" % [x*Terrain.CHUNK_CELLS,z*Terrain.CHUNK_CELLS])
			ids.append(chunk.get_instance_id() if is_instance_valid(chunk) else 0)
	return ids

## Same authored technology inset against the existing dungeon's solid walls.
## It changes no corridor widths, navigation polygons, fixtures or boss tells.
static func dress_forge(parent: Node3D, centre: Vector3, room_width: float) -> void:
	for side in [-1.0, 1.0]:
		var mesh := AuthoredAssets.mesh_for("cataclysm_forge_lamella")
		if mesh == null: return
		for z in [-7.0, 6.0]:
			var part := MeshInstance3D.new()
			part.name = "CataclysmLamella"
			part.mesh = mesh
			part.position = centre + Vector3(side * (room_width * .5 - .16), 2.8, z)
			part.rotation.y = -side * PI * .5
			part.visibility_range_end = LOOK.detail_distance_m
			parent.add_child(part)
