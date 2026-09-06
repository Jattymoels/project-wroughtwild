class_name CataclysmSites
extends Node3D
## Native records own history and site identity. These grounded compositions
## add space and evidence, never a second resource roll or an extraction gate.
const LOOK = preload("res://art/cataclysm_look.tres")
var terrain: Terrain
var pieces: Array[Node3D] = []
var traces: Array[MeshInstance3D] = []
var _fissures := LeylineFissures.new()

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

func _piece(group: Node3D, id: String, at: Vector3, yaw: float, solid := false, size := Vector3.ONE) -> Node3D:
	var mesh := AuthoredAssets.mesh_for("cataclysm_" + id)
	if mesh == null:
		push_error("Missing cataclysm authored asset: " + id)
		return null
	var node := Node3D.new()
	node.name = id + "_" + str(group.get_child_count())
	node.position = at
	node.rotation.y = yaw
	node.scale = size
	node.set_meta("asset_id", id)
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

func _reground(node: Node3D) -> void:
	var visual := node.get_node("Visual") as MeshInstance3D
	var at := _ground(node.position.x, node.position.z)
	var supported := at.is_finite()
	if supported:
		node.position.y = at.y - LOOK.bury_m
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
					if not embedded and absf(sample.y - at.y) > LOOK.support_tolerance_m: supported = false
		if embedded:
			# A buried meteor is not a wall foundation. Sink its broad foot to
			# the lowest support; retain only fragments with a visible crown.
			node.position.y = lowest - LOOK.bury_m
			if highest - lowest > bounds.size.y * (1.0 - LOOK.impact_exposed_fraction): supported = false
	node.set_meta("supported", supported)
	_apply_visibility(node, supported and not bool(node.get_meta("hidden_by_building", false)))

func _apply_visibility(node: Node3D, shown: bool) -> void:
	node.visible = shown
	var body := node.get_node_or_null("RuinBody")
	if body != null:
		for collision: CollisionShape3D in body.get_children(): collision.set_deferred("disabled", not shown)

func refresh_buildings() -> void:
	if terrain == null: return
	var index := StrangeSites._building_index(terrain)
	for node in pieces:
		var visual := node.get_node("Visual") as MeshInstance3D
		var hidden := StrangeSites._building_overlap(index, node.transform * visual.mesh.get_aabb())
		node.set_meta("hidden_by_building", hidden)
		_apply_visibility(node, bool(node.get_meta("supported", false)) and not hidden)
	# Rebuild only on a building action, never per-frame. Individual strip
	# segments underneath a placed floor disappear and return on dismantling.
	for trace in traces: _trace(trace, index)

func refresh_area(cx: int, cz: int, width: int) -> void:
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
	for trace in traces:
		if bounds.intersects(trace.get_meta("xz_bounds", Rect2())): _trace(trace, index)

func refresh_all() -> void:
	for node in pieces: _reground(node)
	refresh_buildings()

func _trace(trace: MeshInstance3D, buildings: Dictionary = {}) -> void:
	_fissures.rebuild(trace, terrain, buildings)

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
