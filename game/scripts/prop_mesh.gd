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


static func build_iron_vein(seed_value: int) -> ArrayMesh:
	return build_vein(seed_value, IRON_RUST)


## A squatter rock shot through with ore facets in the metal's colour -
## the ore reads from across the valley without a label.
static func build_vein(seed_value: int, ore: Color) -> ArrayMesh:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_blob(st, Vector3(0, 0.4, 0), rng.randf_range(0.62, 0.75), 0.6,
		rng, STONE, STONE_DARK, 0.25, ore, 0.3)
	st.generate_normals()
	return st.commit()
