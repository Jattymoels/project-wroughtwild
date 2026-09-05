class_name ArtGeometry
extends RefCounted
## Shared primitive assembly for the frontier's hands, undergrowth and landmarks.
static func append(st: SurfaceTool, mesh: PrimitiveMesh, at: Vector3, size: Vector3, colour: Color, rotation: Vector3=Vector3.ZERO) -> void:
	var transform := Transform3D(Basis.from_euler(rotation).scaled(size),at)
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var normal_basis := transform.basis.inverse().transposed()
	for index in arrays[Mesh.ARRAY_INDEX]:
		st.set_color(colour)
		st.set_normal((normal_basis*normals[index]).normalized())
		st.add_vertex(transform*vertices[index])

static func oval(st: SurfaceTool, at: Vector3, size: Vector3, colour: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 7
	mesh.rings = 3
	append(st,mesh,at,size,colour)

static func box(st: SurfaceTool, at: Vector3, size: Vector3, colour: Color, rotation: Vector3=Vector3.ZERO) -> void:
	append(st,BoxMesh.new(),at,size,colour,rotation)

static func branch(st: SurfaceTool, a: Vector3, b: Vector3, radius: float, colour: Color, tip_fraction: float=0.65) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius
	mesh.top_radius = radius*tip_fraction
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 7
	append(st,mesh,(a+b)*0.5,Vector3.ONE,colour,Basis(Quaternion(Vector3.UP,(b-a).normalized())).get_euler())

static func triangle(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, colour: Color) -> void:
	var normal := (c-a).cross(b-a).normalized()
	for point in [a,b,c]:
		st.set_color(colour)
		st.set_normal(normal)
		st.add_vertex(point)

static func begin() -> SurfaceTool:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	return st

static func material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	return material
