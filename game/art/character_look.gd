extends Resource
## Shared canonical pivots and procedural player/fallback meshes. Normal enemy
## families adopt the reviewed Blender skins through RecoveredActorArt when
## CreatureMotion attaches; both paths retain one status-aware surface.
@export var name_font_size := 32
@export var name_pixel_size := 0.006
@export var name_reference_distance := 6.0
@export var name_distance := 24.0
@export var name_focus_degrees := 16.0
@export var design_purpose: Dictionary = {}
var _meshes: Dictionary = {}
var _bone := 0

## Rest pivots in authored mesh space. Body, head, then paired limbs.
func pivots(role: String) -> PackedVector3Array:
	var points := PackedVector3Array([Vector3(0,0.7,0),Vector3(0,1.32,0)])
	if role in ["fast","melee","grazer"]:
		points[1] = Vector3(0,0.91,-0.27)
		for x in [-0.2,0.2]:
			for z in [-0.26,0.32]:
				points.append(Vector3(x,0.62,z))
	elif role in ["swarm","lurker"]:
		points[1] = Vector3(0,0.57,-0.3)
		for side in [-1.0,1.0]:
			for z in [-0.3,0.0,0.3]:
				points.append(Vector3(side*0.2,0.64,z))
	else:
		for side in [-1.0,1.0]:
			points.append(Vector3(side*0.3,1.14,0))
			points.append(Vector3(side*0.13,0.57,0))
	return points

func build(role: String) -> ArrayMesh:
	if _meshes.has(role):
		return _meshes[role]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	_bone = 0
	if role in ["fast", "melee", "grazer"]:
		# Low chest, haunches and a forward muzzle: a lean four-legged beast.
		_oval(st, Vector3(0,0.68,0.02), Vector3(0.55,0.61,0.91), Color(0.64,0.61,0.55))
		_bone = 1
		_oval(st, Vector3(0,0.98,-0.35), Vector3(0.39,0.46,0.4), Color(0.85,0.82,0.73))
		_oval(st, Vector3(0,0.86,-0.56), Vector3(0.27,0.22,0.36), Color(0.46,0.44,0.4))
		for x in [-0.2,0.2]:
			for z in [-0.26,0.32]:
				_bone = 2 + (2 if x>0 else 0) + (1 if z>0 else 0)
				_limb(st, Vector3(x,0.62,z), Vector3(x*1.2,0.08,z+0.1),0.085,Color(0.45,0.43,0.39))
			_bone = 1
			_limb(st, Vector3(x*0.65,1.1,-0.32),Vector3(x*0.8,1.3,-0.27),0.07,Color(0.75,0.73,0.66))
			if role == "grazer":
				_limb(st,Vector3(x*0.65,1.16,-0.32),Vector3(x*1.6,1.58,-0.2),0.025,Color(0.65,0.6,0.49))
				_limb(st,Vector3(x*1.2,1.4,-0.25),Vector3(x*1.8,1.52,-0.4),0.02,Color(0.65,0.6,0.49))
	elif role in ["swarm", "lurker"]:
		# A raised chitin ridge and six splayed, jointed legs.
		_oval(st, Vector3(0,0.68,0.06), Vector3(0.66,0.73,0.91), Color(0.58,0.57,0.55))
		_bone = 1
		_oval(st, Vector3(0,0.57,-0.46), Vector3(0.38,0.29,0.3), Color(0.84,0.81,0.74))
		for side in [-1.0,1.0]:
			for z in [-0.3,0.0,0.3]:
				_bone = 2 + (3 if side>0 else 0) + roundi((z+0.3)/0.3)
				var knee := Vector3(side*0.5,0.43,z+0.12)
				_limb(st,Vector3(side*0.2,0.64,z),knee,0.055,Color(0.74,0.72,0.65))
				_limb(st,knee,Vector3(side*0.46,0.05,z+0.28),0.04,Color(0.4,0.39,0.37))
	elif role == "skirmisher":
		# A suspended ember core and broken shell: distinguish wisps from walkers.
		_oval(st,Vector3(0,0.88,0),Vector3(0.33,0.68,0.32),Color(1.0,0.91,0.72))
		for i in 3:
			var angle := TAU*float(i)/3.0
			var at := Vector3(cos(angle)*0.27,0.83+float(i)*0.08,sin(angle)*0.27)
			_oval(st,at,Vector3(0.14,0.45,0.14),Color(0.43,0.4,0.37))
	else:
		# Hood, sloping shoulders, split coat, arms and boots replace a capsule.
		var cloth := Color(0.53,0.56,0.52)
		var leather := Color(0.36,0.29,0.21)
		_frustum(st,Vector3(0,0.96,0),0.28,0.21,0.62,cloth)
		_frustum(st,Vector3(0,0.59,0),0.32,0.21,0.26,cloth.darkened(0.15))
		_frustum(st,Vector3(0,0.83,0),0.25,0.24,0.055,leather)
		_limb(st,Vector3(-0.17,1.24,-0.18),Vector3(0.17,0.74,-0.25),0.025,leather)
		_bone = 1
		_oval(st,Vector3(0,1.48,0),Vector3(0.35,0.43,0.36),cloth.darkened(0.15))
		_oval(st,Vector3(0,1.47,-0.145),Vector3(0.21,0.25,0.09),Color(0.26,0.23,0.18))
		for side in [-1.0,1.0]:
			_bone = 2 + (2 if side>0 else 0)
			_oval(st,Vector3(side*0.26,1.18,0),Vector3(0.3,0.27,0.4),cloth.lightened(0.13))
			_limb(st,Vector3(side*0.3,1.14,0),Vector3(side*0.39,0.69,-0.04),0.095,cloth)
			_oval(st,Vector3(side*0.39,0.65,-0.04),Vector3(0.13,0.18,0.15),leather)
			_bone += 1
			_limb(st,Vector3(side*0.13,0.57,0),Vector3(side*0.15,0.14,0),0.1,leather)
			_oval(st,Vector3(side*0.15,0.09,-0.055),Vector3(0.2,0.18,0.33),leather)
		if role in ["guard","knight","boss"]:
			_bone = 2
			_oval(st,Vector3(-0.4,0.9,-0.2),Vector3(0.4,0.7,0.13),Color(0.78,0.78,0.75))
			_bone = 0
			_oval(st,Vector3(0,1.09,-0.15),Vector3(0.4,0.37,0.17),Color(0.65,0.66,0.62))
			_frustum(st,Vector3(0,1.32,0),0.2,0.16,0.08,Color(0.45,0.47,0.44))
		if role == "boss":
			_bone = 1
			for side in [-1.0,1.0]:
				_limb(st,Vector3(side*0.12,1.6,0),Vector3(side*0.28,1.82,0.06),0.065,Color(0.72,0.68,0.54))
		if role == "peddler":
			_bone = 0
			_oval(st,Vector3(0,1.03,0.32),Vector3(0.66,0.77,0.45),leather)
			_bone = 4
			_limb(st,Vector3(0.43,0.04,-0.15),Vector3(0.43,1.49,-0.15),0.035,leather)
	var mesh := st.commit()
	_meshes[role] = mesh
	return mesh

func _oval(st: SurfaceTool, at: Vector3, size: Vector3, colour: Color) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = 0.5
	mesh.height = 1.0
	mesh.radial_segments = 8
	mesh.rings = 3
	_append(st,mesh,Transform3D(Basis.from_scale(size),at),colour)

func _frustum(st: SurfaceTool, at: Vector3, bottom: float, top: float, height: float, colour: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = bottom
	mesh.top_radius = top
	mesh.height = height
	mesh.radial_segments = 8
	_append(st,mesh,Transform3D(Basis.IDENTITY,at),colour)

func _limb(st: SurfaceTool, a: Vector3, b: Vector3, radius: float, colour: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = radius * 0.65
	mesh.top_radius = radius
	mesh.height = a.distance_to(b)
	mesh.radial_segments = 6
	var basis := Basis(Quaternion(Vector3.UP,(b-a).normalized()))
	_append(st,mesh,Transform3D(basis,(a+b)*0.5),colour)

func _append(st: SurfaceTool, mesh: PrimitiveMesh, transform: Transform3D, colour: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var normal_basis := transform.basis.inverse().transposed()
	for index in arrays[Mesh.ARRAY_INDEX]:
		st.set_bones(PackedInt32Array([_bone,0,0,0]))
		st.set_weights(PackedFloat32Array([1,0,0,0]))
		st.set_color(colour)
		st.set_normal((normal_basis*normals[index]).normalized())
		st.add_vertex(transform*vertices[index])
