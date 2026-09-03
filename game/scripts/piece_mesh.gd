class_name PieceMesh
## Meshes and collision for construction pieces by form (construction.json
## "form"): box, stairs, wedge, door. Static so the placement preview and
## PlacedBlock build the same geometry, and so the shapes stay testable
## without a scene. Sizes are metres; every mesh is centred on the piece's
## pose, faces -z as "front" (stairs rise toward +z, the wedge's high side
## is +z), and the door leaf hangs from the local -x edge.

const DOOR_LEAF_INSET := 0.06
## The arch's opening: a half-round of this fraction of the piece's width,
## rising from the bottom edge.
const ARCH_RADIUS_FRACTION := 0.4
const ARCH_STRIPS := 12


## The render mesh for a form at a size.
static func mesh_for(form: String, size: Vector3) -> Mesh:
	match form:
		"stairs":
			return _stairs_mesh(size)
		"wedge":
			return _wedge_mesh(size)
		"arch":
			return _arch_mesh(size)
		"door":
			var leaf := BoxMesh.new()
			leaf.size = _door_leaf_size(size)
			return leaf
	var box := BoxMesh.new()
	box.size = size
	return box


## What the preview shows: the footprint box for boxes and doors (so the
## door's whole opening reads), the real shape for stairs and wedges.
static func preview_mesh_for(form: String, size: Vector3) -> Mesh:
	if form == "door":
		var box := BoxMesh.new()
		box.size = size
		return box
	return mesh_for(form, size)


## Collision shapes for a form: an array of {shape, transform} in local
## space. Stairs are two boxes, the wedge a convex hull, the rest one box.
static func collision_for(form: String, size: Vector3) -> Array:
	match form:
		"stairs":
			var lower := BoxShape3D.new()
			lower.size = Vector3(size.x, size.y * 0.5, size.z)
			var upper := BoxShape3D.new()
			upper.size = Vector3(size.x, size.y * 0.5, size.z * 0.5)
			return [
				{"shape": lower, "transform": Transform3D(Basis.IDENTITY, Vector3(0.0, -size.y * 0.25, 0.0))},
				{"shape": upper, "transform": Transform3D(Basis.IDENTITY, Vector3(0.0, size.y * 0.25, size.z * 0.25))},
			]
		"wedge":
			var hull := ConvexPolygonShape3D.new()
			hull.points = _wedge_points(size)
			return [{"shape": hull, "transform": Transform3D.IDENTITY}]
		"door":
			var leaf := BoxShape3D.new()
			leaf.size = _door_leaf_size(size)
			return [{"shape": leaf, "transform": Transform3D.IDENTITY}]
		"arch":
			# Two piers and the head above the opening's crown.
			var r := ARCH_RADIUS_FRACTION * size.x
			var pier := BoxShape3D.new()
			pier.size = Vector3(size.x * 0.5 - r, size.y, size.z)
			var head := BoxShape3D.new()
			head.size = Vector3(size.x, size.y * 0.5 - r, size.z)
			var px := (size.x * 0.5 + r) * 0.5
			return [
				{"shape": pier, "transform": Transform3D(Basis.IDENTITY, Vector3(-px, 0.0, 0.0))},
				{"shape": pier, "transform": Transform3D(Basis.IDENTITY, Vector3(px, 0.0, 0.0))},
				{"shape": head, "transform": Transform3D(Basis.IDENTITY, Vector3(0.0, size.y * 0.5 - head.size.y * 0.5, 0.0))},
			]
	var box := BoxShape3D.new()
	box.size = size
	return [{"shape": box, "transform": Transform3D.IDENTITY}]


static func _door_leaf_size(size: Vector3) -> Vector3:
	return Vector3(size.x - DOOR_LEAF_INSET, size.y - DOOR_LEAF_INSET, size.z * 0.5)


static func _stairs_mesh(size: Vector3) -> Mesh:
	# Two boxes merged into one ArrayMesh so the piece is one draw.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_add_box(st, Vector3(0.0, -size.y * 0.25, 0.0), Vector3(size.x, size.y * 0.5, size.z))
	_add_box(st, Vector3(0.0, size.y * 0.25, size.z * 0.25), Vector3(size.x, size.y * 0.5, size.z * 0.5))
	st.generate_normals()
	return st.commit()


## The wedge's six corners: a full-height back (+z) sloping down to the
## front (-z) floor edge.
static func _wedge_points(size: Vector3) -> PackedVector3Array:
	var hx := size.x * 0.5
	var hy := size.y * 0.5
	var hz := size.z * 0.5
	return PackedVector3Array([
		Vector3(-hx, -hy, -hz), Vector3(hx, -hy, -hz),  # front floor edge
		Vector3(hx, -hy, hz), Vector3(-hx, -hy, hz),    # back floor edge
		Vector3(hx, hy, hz), Vector3(-hx, hy, hz),      # back top edge
	])


static func _wedge_mesh(size: Vector3) -> Mesh:
	var p := _wedge_points(size)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Bottom (facing down), back (facing +z), slope (facing up/-z), two sides.
	_add_quad(st, p[0], p[3], p[2], p[1])
	_add_quad(st, p[2], p[3], p[5], p[4])
	_add_quad(st, p[0], p[1], p[4], p[5])
	_add_tri(st, p[0], p[5], p[3])
	_add_tri(st, p[1], p[2], p[4])
	st.generate_normals()
	return st.commit()


## A wall piece whose underside is a half-round opening: vertical strips
## across the width, each solid from the arc up to the top edge.
static func _arch_mesh(size: Vector3) -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var r := ARCH_RADIUS_FRACTION * size.x
	var strip := size.x / float(ARCH_STRIPS)
	for i in ARCH_STRIPS:
		var x0 := -size.x * 0.5 + strip * float(i)
		var xc := x0 + strip * 0.5
		var arc := -size.y * 0.5
		if absf(xc) < r:
			arc = sqrt(maxf(r * r - xc * xc, 0.0)) - size.y * 0.5
		var top := size.y * 0.5
		if top - arc < 0.01:
			continue
		_add_box(st, Vector3(xc, (top + arc) * 0.5, 0.0), Vector3(strip, top - arc, size.z))
	st.generate_normals()
	return st.commit()


static func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)


static func _add_quad(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3) -> void:
	_add_tri(st, a, b, c)
	_add_tri(st, a, c, d)


static func _add_box(st: SurfaceTool, centre: Vector3, size: Vector3) -> void:
	var h := size * 0.5
	var c := centre
	var v := [
		c + Vector3(-h.x, -h.y, -h.z), c + Vector3(h.x, -h.y, -h.z),
		c + Vector3(h.x, -h.y, h.z), c + Vector3(-h.x, -h.y, h.z),
		c + Vector3(-h.x, h.y, -h.z), c + Vector3(h.x, h.y, -h.z),
		c + Vector3(h.x, h.y, h.z), c + Vector3(-h.x, h.y, h.z),
	]
	_add_quad(st, v[0], v[3], v[2], v[1])  # bottom
	_add_quad(st, v[4], v[5], v[6], v[7])  # top
	_add_quad(st, v[0], v[1], v[5], v[4])  # front (-z)
	_add_quad(st, v[2], v[3], v[7], v[6])  # back (+z)
	_add_quad(st, v[3], v[0], v[4], v[7])  # left (-x)
	_add_quad(st, v[1], v[2], v[6], v[5])  # right (+x)
