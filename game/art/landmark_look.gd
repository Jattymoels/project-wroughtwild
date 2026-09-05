extends Resource
## Architectural wear and restrained curio accents, in the existing footprints.
@export var bevel_fraction := 0.14
@export var stone_colour := Color("626455")
@export var drowned_colour := Color("45584f")
@export var rift_colour := Color("27262b")
@export var inlay_colour := Color("a38b52")
@export var cold_inlay := Color("84a8a0")
## Trees in this small site radius become bare snags, retaining their wood yield.
@export var canopy_clearance_metres := 6.5
var _material: StandardMaterial3D

func material() -> StandardMaterial3D:
	if _material==null:
		_material = ArtGeometry.material()
	return _material

func stone(size: Vector3, shade: Color, seed_value: int) -> ArrayMesh:
	var st := ArtGeometry.begin()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var w := size.x*0.5
	var d := size.z*0.5
	var cut := minf(w,d)*bevel_fraction*2.0
	var ring := PackedVector3Array([Vector3(-w+cut,0,-d),Vector3(w-cut,0,-d),Vector3(w,0,-d+cut),Vector3(w,0,d-cut),Vector3(w-cut,0,d),Vector3(-w+cut,0,d),Vector3(-w,0,d-cut),Vector3(-w,0,-d+cut)])
	var lower := PackedVector3Array()
	var upper := PackedVector3Array()
	for point in ring:
		lower.append(point+Vector3(0,-size.y*0.5,0))
		upper.append(Vector3(point.x*rng.randf_range(0.82,0.98),size.y*0.5-rng.randf()*minf(0.12,size.y*0.12),point.z*rng.randf_range(0.82,0.98)))
	for i in 8:
		var j := (i+1)%8
		var colour := shade.darkened(rng.randf()*0.16)
		# Reverse triangles if their normal points into the convex stone.
		_outward(st,lower[i],lower[j],upper[j],colour)
		_outward(st,lower[i],upper[j],upper[i],colour)
		_outward(st,Vector3(0,size.y*0.46,0),upper[i],upper[j],shade.lightened(0.05))
		_outward(st,Vector3(0,-size.y*0.5,0),lower[j],lower[i],shade.darkened(0.2))
	return st.commit()

func _outward(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, colour: Color) -> void:
	if (c-a).cross(b-a).dot((a+b+c)/3.0)<0.0:
		ArtGeometry.triangle(st,a,c,b,colour)
	else:
		ArtGeometry.triangle(st,a,b,c,colour)

func inlay(kind: String) -> ArrayMesh:
	var st := ArtGeometry.begin()
	if kind=="altar":
		# Six radial cuts lead the eye into the offering basin.
		for i in 6:
			var a := TAU*float(i)/6.0
			ArtGeometry.branch(st,Vector3(cos(a)*0.16,0.59,sin(a)*0.16),Vector3(cos(a)*0.51,0.59,sin(a)*0.51),0.016,cold_inlay,1.0)
		ArtGeometry.branch(st,Vector3(0,0.58,0),Vector3(0,0.60,0),0.18,rift_colour,1.0)
	elif kind=="rift":
		# A narrow ember fault, broken into segments instead of a luminous panel.
		for i in 8:
			var y := 0.45+float(i)*0.48
			ArtGeometry.branch(st,Vector3(sin(i*1.7)*0.12,y,0.28),Vector3(sin((i+1)*1.7)*0.12,y+0.34,0.28),0.023,Color("c87e43"),0.5)
	else:
		# A recessed-looking heart socket, three worn bands and a split crest.
		ArtGeometry.branch(st,Vector3(0,1.32,0.57),Vector3(0,1.32,0.61),0.14,rift_colour,1.0)
		for i in 3:
			ArtGeometry.box(st,Vector3(0,1.05+float(i)*0.16,0.52),Vector3(0.34,0.022,0.025),inlay_colour)
	return st.commit()
