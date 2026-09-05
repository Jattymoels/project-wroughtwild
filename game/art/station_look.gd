extends Resource
## The workshop study's silhouettes, now shared by real placed stations.
@export var timber := Color("735132")
@export var legs := Color("4d3b2e")
@export var stone := Color("74747a")
@export var iron := Color("565860")
@export var ember := Color("ec6e1e")
## Decorative hearth illumination, not a fuel meter or heat gameplay source.
@export var hearth_energy := 1.2
@export var hearth_range := 3.5
var _meshes := {}

func mesh_for(id: StringName) -> ArrayMesh:
	if _meshes.has(id):
		return _meshes[id]
	var st := ArtGeometry.begin()
	if String(id).begins_with("forge_"):
		ArtGeometry.box(st,Vector3(0,0.4,0),Vector3(0.9,0.8,0.9),iron)
		for x in [-0.36,0.36]:
			ArtGeometry.box(st,Vector3(x,1.1,0),Vector3(0.18,0.7,0.9),stone)
		ArtGeometry.box(st,Vector3(0,1.5,0),Vector3(0.95,0.15,0.95),iron)
		ArtGeometry.box(st,Vector3(0,0.95,0.35),Vector3(0.6,0.3,0.16),legs)
		ArtGeometry.box(st,Vector3(0,0.82,0),Vector3(0.6,0.05,0.55),ember)
		if id==&"forge_improved":
			# Taller hood and iron bands keep the existing upgrade visible.
			ArtGeometry.box(st,Vector3(0,1.76,0.2),Vector3(0.65,0.4,0.45),iron)
			for y in [0.2,0.65]:
				ArtGeometry.box(st,Vector3(0,y,-0.455),Vector3(0.92,0.065,0.025),iron.darkened(0.35))
	else:
		var top := timber if id==&"workbench" else stone
		ArtGeometry.box(st,Vector3(0,0.86,0),Vector3(0.94,0.18,0.92),top)
		for x in [-0.32,0.32]:
			for z in [-0.32,0.32]:
				ArtGeometry.box(st,Vector3(x,0.4,z),Vector3(0.16,0.8,0.16),legs)
		ArtGeometry.box(st,Vector3(0,1.02,0.12),Vector3(0.5,0.14,0.3),top.darkened(0.2))
	_meshes[id] = st.commit()
	return _meshes[id]
