class_name LeylineFissures
extends RefCounted
## Bounded cosmetic fractures. Native exposure and topology remain authoritative;
## rebuilding a tile consumes no gameplay RNG and creates no physics object.
const LOOK = preload("res://art/leyline_look.tres")
const SHADER = preload("res://art/leyline_fissure.gdshader")
const CROSS_SECTION: Array[float] = [-1.12, -1.0, -.8, -.035, .035, .8, 1.0, 1.12]
var _material: ShaderMaterial
var _terrain: Terrain
var _buildings: Dictionary
var _vertices := PackedVector3Array()
var _normals := PackedVector3Array()
var _colours := PackedColorArray()
var _uvs := PackedVector2Array()
var _rng := RandomNumberGenerator.new()
var _triangles := 0
var _fragments := 0
var _branches := 0

func rebuild(trace: MeshInstance3D, ground: Terrain, buildings: Dictionary) -> void:
	_terrain = ground
	_buildings = buildings
	_triangles = 0
	_fragments = 0
	_branches = 0
	var data: Dictionary = trace.get_meta("record")
	var path: PackedVector3Array = data.get("points", PackedVector3Array())
	var exposure: PackedByteArray = data.get("exposure", PackedByteArray())
	var tapers: PackedByteArray = data.get("fissure_tapers", PackedByteArray())
	if path.size() < 2:
		trace.mesh = null
		return
	_rng.seed = String(data.id).hash() ^ int(ground.map.get("seed", 0))
	var bounds := Rect2(Vector2(path[0].x, path[0].z), Vector2.ZERO)
	for point in path: bounds = bounds.expand(Vector2(point.x, point.z))
	trace.set_meta("xz_bounds", bounds.grow(LOOK.bounds_padding_m))
	_vertices.clear()
	_normals.clear()
	_colours.clear()
	_uvs.clear()
	var width := clampf(float(data.get("width_m", 2.0)) * LOOK.width_fraction, LOOK.minimum_width_m, LOOK.maximum_width_m)
	for i in range(path.size() - 1):
		# Neither buried (0) nor broken (1) native intervals receive cracks or light.
		if i >= exposure.size() or exposure[i] != 2: continue
		var a := path[i]
		var b := path[i + 1]
		var delta := Vector3(b.x - a.x, 0, b.z - a.z)
		var length := delta.length()
		if length < LOOK.sample_m: continue
		var phase := _rng.randf_range(0.0, TAU)
		_add_path(a, b, width, phase, false, int(tapers[i]) if i < tapers.size() else 3)
		var branches := mini(ceili(length / LOOK.branch_spacing_m), LOOK.branches_per_tile - _branches)
		for branch in branches:
			var t := (float(branch) + _rng.randf_range(.3, .7)) / branches
			var anchor := _curve(a, b, t, phase)
			var sign_side := -1.0 if (branch + i) % 2 == 0 else 1.0
			var angle := deg_to_rad(_rng.randf_range(LOOK.branch_angle_min_degrees, LOOK.branch_angle_max_degrees)) * sign_side
			var direction := delta.normalized().rotated(Vector3.UP, angle)
			var end := anchor + direction * _rng.randf_range(LOOK.branch_minimum_m, LOOK.branch_maximum_m)
			var fork_phase := _rng.randf_range(0.0, TAU)
			var branch_light := LOOK.branch_light_strength if _rng.randf() < LOOK.branch_light_probability else 0.0
			_add_path(anchor, end, width * LOOK.branch_width_fraction, fork_phase, true, 3, branch_light)
			_branches += 1
			if _rng.randf() < LOOK.twig_probability:
				var twig_anchor := _curve(anchor, end, .55, fork_phase)
				var twig_end := twig_anchor + direction.rotated(Vector3.UP, -sign_side * .85) * LOOK.twig_length_m
				_add_path(twig_anchor, twig_end, width * LOOK.branch_width_fraction * .55, fork_phase + 1.7, true, 3, 0.0)
	trace.set_meta("fragment_count", _fragments)
	trace.set_meta("fissure_branch_count", _branches)
	trace.set_meta("fissure_triangle_count", _triangles)
	trace.set_meta("fissure_exposure_only", true)
	trace.mesh = null
	if _triangles == 0: return
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		_material.set_shader_parameter("emission_strength", LOOK.emission_strength)
		_material.set_shader_parameter("light_variation", LOOK.light_variation)
		_material.set_shader_parameter("light_period_seconds", LOOK.light_period_seconds)
		_material.set_shader_parameter("mineral_roughness", LOOK.roughness)
		_material.set_shader_parameter("grain_cells_per_m", LOOK.grain_cells_per_m)
		_material.set_shader_parameter("grain_contrast", LOOK.grain_contrast)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _vertices
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_COLOR] = _colours
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, _material)
	trace.mesh = mesh

func _curve(a: Vector3, b: Vector3, t: float, phase: float) -> Vector3:
	var side := Vector3(b.x - a.x, 0, b.z - a.z).normalized().cross(Vector3.UP)
	var along := a.distance_to(b) * t
	# Endpoints meet exactly; facets between samples supply the angular crack.
	var drift := sin(t * PI) * (sin(along * 2.7 + phase) * .7 + sin(along * 5.1 - phase) * .3)
	return a.lerp(b, t) + side * drift * LOOK.meander_m

func _add_path(a: Vector3, b: Vector3, width: float, phase: float, branch: bool, taper_flags := 3, light_strength := 1.0) -> void:
	var length := a.distance_to(b)
	var samples := maxi(2, ceili(length / LOOK.sample_m))
	var rows: Array[Dictionary] = []
	for sample in samples + 1:
		var t := float(sample) / samples
		var at := _curve(a, b, t, phase)
		var ahead := _curve(a, b, minf(1.0, t + .01), phase)
		var behind := _curve(a, b, maxf(0.0, t - .01), phase)
		var side := (ahead - behind).normalized().cross(Vector3.UP)
		var taper := pow(1.0 - t, .6) if branch else 1.0
		if not branch:
			if taper_flags & 1: taper *= lerpf(LOOK.tip_width_fraction, 1.0, smoothstep(0.0, minf(.25, LOOK.tip_length_m / length), t))
			if taper_flags & 2: taper *= lerpf(LOOK.tip_width_fraction, 1.0, smoothstep(0.0, minf(.25, LOOK.tip_length_m / length), 1.0-t))
		var half := width * .5 * taper
		# Independent world-position noise gives both sides chips and pockets;
		# it also joins consistently when the same split crosses a render tile.
		var left_chip := 1.0 - LOOK.edge_width_variation * (.5 + .5 * sin(at.x * 5.9 + at.z * 4.1))
		var right_chip := 1.0 - LOOK.edge_width_variation * (.5 + .5 * sin(at.x * 4.3 - at.z * 7.1))
		var strand_shift := half * LOOK.strand_wander_fraction * sin(at.x * 2.3 + at.z * 3.8)
		var vertices := PackedVector3Array()
		var valid := true
		for column in CROSS_SECTION.size():
			var offset := CROSS_SECTION[column] * half * (left_chip if column < 4 else right_chip)
			if column in [3,4]: offset = CROSS_SECTION[column] * half + strand_shift
			var raw := at + side * offset
			var support := StrangeSites._ground(_terrain, raw.x, raw.z)
			if not support.is_finite():
				valid = false
				break
			var raised := LOOK.lip_height_m * (.5 + .5 * sin(at.x * 7.3 + at.z * 3.7 * (-1.0 if column == 1 else 1.0))) if column in [1, 6] else 0.0
			vertices.append(support + Vector3.UP * (LOOK.lift_m + raised))
		var light := smoothstep(1.0 - LOOK.light_coverage - .15, 1.0 - LOOK.light_coverage + .15, .5 + .5 * sin(length * t * 2.15 + phase)) * light_strength
		rows.append({"vertices":vertices, "valid":valid, "light":light, "phase":phase + length * t * .1})
	var emitted := false
	for sample in samples:
		var first: Dictionary = rows[sample]
		var second: Dictionary = rows[sample + 1]
		if not first.valid or not second.valid: continue
		var left: PackedVector3Array = first.vertices
		var right: PackedVector3Array = second.vertices
		var bounds := AABB(left[0], Vector3.ZERO)
		var valid := true
		for column in CROSS_SECTION.size():
			bounds = bounds.expand(left[column]).expand(right[column])
			if absf(left[column].y - right[column].y) > LOOK.maximum_step_m: valid = false
			if column > 0 and (absf(left[column].y - left[column - 1].y) > LOOK.maximum_step_m or absf(right[column].y - right[column - 1].y) > LOOK.maximum_step_m): valid = false
		if not valid or StrangeSites._building_overlap(_buildings, bounds.grow(.08)): continue
		for column in range(CROSS_SECTION.size() - 1):
			var colour: Color = LOOK.rim_colour if column in [0, 6] else LOOK.lip_colour if column in [1, 5] else LOOK.light_colour if column == 3 else LOOK.mouth_colour
			var normal := (left[column + 1] - left[column]).cross(right[column] - left[column]).normalized()
			# Each row contributes the same colour/UV three times. Assemble the
			# unchanged unindexed triangles in batches instead of allocating six
			# temporary vertex/row pairs and issuing 24 SurfaceTool calls per quad.
			var lit_a := float(first.light) if column == 3 else 0.0
			var lit_b := float(second.light) if column == 3 else 0.0
			var albedo_a := LOOK.mouth_colour.lerp(colour, lit_a) if column == 3 else colour
			var albedo_b := LOOK.mouth_colour.lerp(colour, lit_b) if column == 3 else colour
			var colour_a := Color(albedo_a.r, albedo_a.g, albedo_a.b, lit_a)
			var colour_b := Color(albedo_b.r, albedo_b.g, albedo_b.b, lit_b)
			var uv_a := Vector2(float(column), float(first.phase))
			var uv_b := Vector2(float(column), float(second.phase))
			_vertices.append_array(PackedVector3Array([left[column],right[column+1],left[column+1],left[column],right[column],right[column+1]]))
			_normals.append_array(PackedVector3Array([normal,normal,normal,normal,normal,normal]))
			_colours.append_array(PackedColorArray([colour_a,colour_b,colour_a,colour_a,colour_b,colour_b]))
			_uvs.append_array(PackedVector2Array([uv_a,uv_b,uv_a,uv_a,uv_b,uv_b]))
			_triangles += 2
		emitted = true
	if emitted: _fragments += 1
