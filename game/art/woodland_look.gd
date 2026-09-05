extends Resource
## Experimental, seeded tree silhouettes. Trunk origins and harvest rules stay
## with ResourceNode; this resource only authors branch and crown geometry.
@export var profiles: Dictionary = {}
@export var radial_segments := 9
@export var irregularity := 0.09
@export var crown_stagger := 0.6
@export var foliage_shade := 1.0
@export var variant_count := 0
@export var design_purpose: Dictionary = {}
var _variants: Dictionary = {}

func build_tree(biome: String, seed_value: int) -> ArrayMesh:
	if variant_count > 0:
		var variant := posmod(seed_value, variant_count)
		var key := "%s:%d" % [biome, variant]
		if not _variants.has(key):
			_variants[key] = _build_tree(biome, variant * 7919 + 713)
		return _variants[key]
	return _build_tree(biome, seed_value)

func _build_tree(biome: String, seed_value: int) -> ArrayMesh:
	var p: Dictionary = profiles.get(biome, profiles["meadow"])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var height := float(p.height) * rng.randf_range(0.94, 1.06)
	var radius := float(p.trunk_radius)
	var phase := rng.randf() * TAU
	var lean := Vector3(cos(phase), 0, sin(phase)) * float(p.lean)
	var fork := Vector3(0, height * 0.52, 0) + lean * 0.45
	var top := Vector3(0, height, 0) + lean
	_tube(st, Vector3.ZERO, fork, radius, radius * 0.65, p.bark)
	_tube(st, fork, top, radius * 0.65, radius * 0.18, p.bark)
	# Root flares visibly settle the trunk; all decorative, trunk collision unchanged.
	for i in 4:
		var direction := Vector3(cos(phase + i * TAU / 4), 0, sin(phase + i * TAU / 4))
		_tube(st, direction * radius * 1.8 + Vector3.UP * 0.035,
			Vector3.UP * radius * 2.1, radius * 0.2, radius * 0.48, p.bark)
	var count := int(p.branches)
	for i in count:
		var angle := phase + float(i) * TAU / float(count) + rng.randf_range(-0.18, 0.18)
		var direction := Vector3(cos(angle), 0, sin(angle))
		var fraction := float(i) / float(maxi(1, count - 1))
		var taper := 1.0 - float(p.get("crown_taper",0.0)) * fraction
		var spread := float(p.spread) * rng.randf_range(0.83, 1.14) * taper
		var start := fork.lerp(top, fraction * crown_stagger)
		var end := start + direction * spread + Vector3.UP * float(p.branch_rise)
		var knee := start.lerp(end, 0.55) - Vector3.UP * 0.12
		_tube(st, start, knee, radius * 0.4, radius * 0.22, p.bark)
		_tube(st, knee, end, radius * 0.22, radius * 0.06, p.bark)
		if float(p.crown_radius) > 0:
			var crown := float(p.crown_radius) * rng.randf_range(0.85, 1.12) * taper
			_crown(st, end, Vector3(crown, float(p.crown_depth)*taper, crown * 0.86), angle, p.leaf, p.leaf_dark, p.get("pointed",false))
	if float(p.crown_radius) > 0:
		var crown := float(p.crown_radius) * (1.0-float(p.get("crown_taper",0.0)))
		_crown(st, top + Vector3.UP * float(p.crown_depth) * 0.25,
			Vector3(crown, float(p.crown_depth), crown), phase, p.leaf, p.leaf_dark, p.get("pointed",false))
	return st.commit()

func _triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, outward: Vector3, colour: Color) -> void:
	if (c - a).cross(b - a).dot(outward) < 0:
		var swap := b
		b = c
		c = swap
	var n := (c - a).cross(b - a).normalized()
	if n.length_squared() < 0.1:
		return
	st.set_normal(n)
	st.set_color(colour)
	for vertex in [a, b, c]:
		st.add_vertex(vertex)

func _tube(st: SurfaceTool, a: Vector3, b: Vector3, r0: float, r1: float, colour: Color) -> void:
	var along := (b - a).normalized()
	var side := along.cross(Vector3.FORWARD).normalized()
	if side.length_squared() < 0.1:
		side = along.cross(Vector3.RIGHT).normalized()
	var other := along.cross(side)
	for i in 6:
		var d0 := side * cos(i * TAU / 6) + other * sin(i * TAU / 6)
		var d1 := side * cos((i + 1) * TAU / 6) + other * sin((i + 1) * TAU / 6)
		var shade := colour.darkened(0.09 * (i % 2))
		_triangle(st, a + d0*r0, b + d0*r1, b + d1*r1, d0+d1, shade)
		_triangle(st, a + d0*r0, b + d1*r1, a + d1*r0, d0+d1, shade)
		_triangle(st, b, b + d0*r1, b + d1*r1, along, shade)

func _crown(st: SurfaceTool, centre: Vector3, extent: Vector3, phase: float, light: Color, dark: Color, pointed := false) -> void:
	# Broad, flattened masses with a shaded underside. Correlated lobing gives
	# leaf clusters, without unrelated random colours on every triangle.
	var rings: Array = []
	var levels := [Vector2(0.0, 0.0), Vector2(0.28, 0.84), Vector2(0.64, 1.0), Vector2(0.9, 0.65), Vector2(1.0, 0.0)]
	if pointed:
		levels = [Vector2(0.0,0.0),Vector2(0.15,1.0),Vector2(0.4,0.75),Vector2(0.7,0.42),Vector2(1.0,0.0)]
	for level in levels:
		var ring: Array[Vector3] = []
		for j in radial_segments:
			var angle := phase + j * TAU / radial_segments
			var scallop := 1.0 + irregularity * sin(angle * 3.0 + phase)
			ring.append(centre + Vector3(cos(angle) * extent.x * level.y * scallop,
				(level.x - 0.4) * extent.y, sin(angle) * extent.z * level.y * scallop))
		rings.append(ring)
	for i in 4:
		var colour := dark.lerp(light, [0.08, 0.35, 0.83, 1.0][i]) * Color(foliage_shade,foliage_shade,foliage_shade,1)
		for j in radial_segments:
			var next := (j + 1) % radial_segments
			var a: Vector3 = rings[i][j]
			var b: Vector3 = rings[i][next]
			var c: Vector3 = rings[i+1][next]
			var d: Vector3 = rings[i+1][j]
			_triangle(st, a,b,c,(a+b+c)/3-centre,colour)
			_triangle(st, a,c,d,(a+c+d)/3-centre,colour)
