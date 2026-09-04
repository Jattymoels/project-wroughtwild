class_name PropMesh
extends RefCounted
## Procedural chunky low-poly props (D-013 "chunky, not childish"): trees,
## boulders and iron veins built as flat-shaded faceted meshes with vertex
## colours from the master palette - the Valheim register of crooked
## silhouettes, deliberately NOT Minecraft's box-on-box props while the
## terrain stays blocky. Deterministic: the same seed always builds the
## same prop, so a rebuilt world looks identical.
##
## Budgets are tiny by design: a tree is ~84 triangles, a boulder 20.

# Master palette (docs/art/art-direction.md).
const BARK := Color("5C4026")
const BARK_DARK := Color("402C1A")
const LEAF := Color("306A2A")
const LEAF_DARK := Color("204C1C")
const STONE := Color("74747A")
const STONE_DARK := Color("565860")
const IRON_RUST := Color("C4742C")
## Era-two ores (D-019): copper glints warm, tin pale.
const COPPER := Color("C8783C")
const TIN := Color("C9CCD2")
const EMBER_ORE := Color("E8642C")
const SILVER := Color("E4E8F0")
const SEAM := Color("D9D3C4")

const PHI := 1.618034
## Icosahedron faces over the 12 canonical vertices (see _ico_vertices).
const ICO_FACES := [
	[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11],
	[1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
	[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9],
	[4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]


## The one material every prop shares in kind: flat vertex colours, fully
## rough, with the hover-highlight emission pre-configured but off.
static func material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = 1.0
	m.emission = Color(0.85, 0.85, 0.6)
	m.emission_energy_multiplier = 0.35
	return m


static func _ico_vertices() -> Array:
	var raw := [
		Vector3(-1, PHI, 0), Vector3(1, PHI, 0), Vector3(-1, -PHI, 0), Vector3(1, -PHI, 0),
		Vector3(0, -1, PHI), Vector3(0, 1, PHI), Vector3(0, -1, -PHI), Vector3(0, 1, -PHI),
		Vector3(PHI, 0, -1), Vector3(PHI, 0, 1), Vector3(-PHI, 0, -1), Vector3(-PHI, 0, 1)]
	var out := []
	for p in raw:
		out.append((p as Vector3).normalized())
	return out


## One flat-shaded triangle: unshared vertices so generate_normals() gives
## a hard facet, one colour for the whole face.
static func _facet(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	st.set_color(color)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _jittered(color: Color, rng: RandomNumberGenerator) -> Color:
	return color.darkened(rng.randf_range(0.0, 0.14)) if rng.randf() < 0.5 \
		else color.lightened(rng.randf_range(0.0, 0.1))


## A warped icosahedron blob: every vertex pushed to its own radius, the
## whole thing squashed vertically. The workhorse of canopies and rocks.
static func _blob(st: SurfaceTool, center: Vector3, radius: float, squash: float,
		rng: RandomNumberGenerator, base: Color, dark: Color, dark_chance: float,
		accent := Color.TRANSPARENT, accent_chance := 0.0) -> void:
	var warped := []
	for p in _ico_vertices():
		var r := radius * rng.randf_range(0.72, 1.28)
		warped.append(center + Vector3(p.x * r, p.y * r * squash, p.z * r))
	for face in ICO_FACES:
		var color := base
		if accent_chance > 0.0 and rng.randf() < accent_chance:
			color = accent
		elif rng.randf() < dark_chance:
			color = dark
		_facet(st, warped[face[0]], warped[face[1]], warped[face[2]], _jittered(color, rng))


## A tapering, slightly crooked trunk: hexagonal rings whose centres lean
## further off-axis with height. Returns the top-centre for the canopy.
static func _trunk(st: SurfaceTool, rng: RandomNumberGenerator) -> Vector3:
	var lean := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() \
		* rng.randf_range(0.1, 0.3)
	var heights := [0.0, rng.randf_range(1.3, 1.7), rng.randf_range(2.6, 3.1)]
	var radii := [rng.randf_range(0.3, 0.38), 0.24, 0.16]
	var rings := []
	for i in 3:
		var center: Vector3 = Vector3(0, heights[i], 0) + lean * (heights[i] / heights[2])
		var ring := []
		for s in 6:
			var angle := TAU * s / 6.0 + rng.randf_range(-0.1, 0.1)
			ring.append(center + Vector3(cos(angle), 0, sin(angle)) * radii[i])
		rings.append(ring)
	for i in 2:
		for s in 6:
			var t: int = (s + 1) % 6
			var color := _jittered(BARK_DARK if rng.randf() < 0.3 else BARK, rng)
			_facet(st, rings[i][s], rings[i + 1][s], rings[i][t], color)
			_facet(st, rings[i][t], rings[i + 1][s], rings[i + 1][t], color)
	return Vector3(0, heights[2], 0) + lean


static func build_tree(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var top := _trunk(st, rng)
	# Canopy: one master blob on the crown, two smaller lobes shouldering
	# it, so no two trees share a silhouette.
	_blob(st, top + Vector3(0, 0.5, 0), rng.randf_range(1.0, 1.3), 0.85,
		rng, LEAF, LEAF_DARK, 0.35)
	for i in 2:
		var side := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized() \
			* rng.randf_range(0.55, 0.85)
		_blob(st, top + side + Vector3(0, rng.randf_range(0.0, 0.35), 0),
			rng.randf_range(0.55, 0.75), 0.85, rng, LEAF, LEAF_DARK, 0.35)
	st.generate_normals()
	return st.commit()


static func build_boulder(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_blob(st, Vector3(0, 0.45, 0), rng.randf_range(0.7, 0.85), 0.66,
		rng, STONE, STONE_DARK, 0.3)
	st.generate_normals()
	return st.commit()


static func build_iron_vein(seed_value: int, rises: Array = [0.0, 0.0, 0.0]) -> ArrayMesh:
	return build_vein(seed_value, IRON_RUST, rises)


## A flat quad as two facets, one colour: the flush pieces of a strip.
static func _slab(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
	_facet(st, a, b, c, color)
	_facet(st, a, c, d, color)


## A line through the stone (the owner, 4 Sep 2026: seams "flush with the
## exposed stone generated rather than a pebble look", "more of a
## pattern/line through the stone", carried to the ore veins). Runs along
## local +X across `rises.size()` cells, one metre each, centred on the
## node's own cell; rises[i] is that cell's surface height relative to the
## node's, so the line steps up and down the blocks it crosses instead of
## floating. A torn band of stone hugs the surface with a thin dark
## fracture (or metal-coloured vein) wandering along its middle; chips
## are allowed but off - the owner asked for a line, not a pebble component.
static func _strip(st: SurfaceTool, rng: RandomNumberGenerator, rises: Array, band: Color, band_dark: Color,
		vein: Color, vein_width: float, chips: int) -> void:
	var cells := rises.size()
	var x0 := -float(cells) * 0.5
	for i in cells:
		var y: float = float(rises[i]) + 0.03
		var xa := x0 + float(i)
		var xb := xa + 1.0
		# The band: two or three facets of jittered width, so the edge is torn, not ruled.
		var pieces := rng.randi_range(2, 3)
		for p in pieces:
			var pa := xa + float(p) / float(pieces)
			var pb := xa + float(p + 1) / float(pieces)
			var half_a := rng.randf_range(0.2, 0.34)
			var half_b := rng.randf_range(0.2, 0.34)
			var colour := band_dark if rng.randf() < 0.45 else band
			_slab(st, Vector3(pa, y, -half_a), Vector3(pb, y, -half_b), Vector3(pb, y, half_b), Vector3(pa, y, half_a), _jittered(colour, rng))
		# The vein: a thin bright line wandering along the band, a hair above it.
		var wander_a := rng.randf_range(-0.08, 0.08)
		var wander_b := rng.randf_range(-0.08, 0.08)
		var vy := y + 0.012
		_slab(st, Vector3(xa, vy, wander_a - vein_width), Vector3(xb, vy, wander_b - vein_width),
			Vector3(xb, vy, wander_b + vein_width), Vector3(xa, vy, wander_a + vein_width), _jittered(vein, rng))
		# A riser where the line steps to the next block, so the band reads as one.
		if i + 1 < cells and rises[i + 1] != rises[i]:
			var top: float = maxf(float(rises[i]), float(rises[i + 1])) + 0.03
			var bottom: float = minf(float(rises[i]), float(rises[i + 1]))
			_slab(st, Vector3(xb - 0.02, bottom, -0.24), Vector3(xb + 0.02, bottom, -0.24),
				Vector3(xb + 0.02, top, 0.24), Vector3(xb - 0.02, top, 0.24), _jittered(band_dark, rng))
	for c in chips:
		var cx := rng.randf_range(x0 + 0.2, -x0 - 0.2)
		var i := clampi(int(floor(cx - x0)), 0, cells - 1)
		_blob(st, Vector3(cx, float(rises[i]) + 0.05, rng.randf_range(-0.42, 0.42)), rng.randf_range(0.07, 0.13), 0.5,
			rng, band, band_dark, 0.4, vein, 0.25)


## A stone seam (D-021): a fracture line through the exposed stone, flush
## with the blocks it crosses - the thing a wedge goes into. `rises` is
## the surface height of each crossed cell relative to the node's.
static func build_seam(seed_value: int, rises: Array = [0.0, 0.0, 0.0]) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_strip(st, rng, rises, STONE, STONE_DARK, Color("2E3036"), 0.045, 0)
	st.generate_normals()
	return st.commit()


## An ore vein: the metal's colour as a line through the rock, with a squat
## knuckle of ore where the line breaks the surface - the ore reads from
## across the valley without a label.
static func build_vein(seed_value: int, ore: Color, rises: Array = [0.0, 0.0, 0.0]) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_strip(st, rng, rises, STONE, STONE_DARK, ore, 0.06, 0)
	_blob(st, Vector3(rng.randf_range(-0.3, 0.3), 0.22, rng.randf_range(-0.2, 0.2)), rng.randf_range(0.34, 0.44), 0.55,
		rng, STONE, STONE_DARK, 0.25, ore, 0.35)
	st.generate_normals()
	return st.commit()


## A chunk of split stone that falls off a seam: a fist of rock.
static func build_chunk(seed_value: int) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_blob(st, Vector3.ZERO, rng.randf_range(0.14, 0.2), 0.8, rng, STONE, STONE_DARK, 0.35, SEAM, 0.15)
	st.generate_normals()
	return st.commit()
