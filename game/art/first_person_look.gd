extends Resource
## Camera-space hand placement leaves the crosshair and lower action bar clear.
@export var hand_position := Vector3(0.24,-0.25,-0.43)
## Recovery lengths after the existing instant cast; they never delay damage.
@export var strike_seconds := 0.28
@export var cast_seconds := 0.36
@export var impact_seconds := 0.09
## Hand movement in metres, not camera movement: no new camera shake.
@export var stride_sway := 0.009
@export var impact_recoil := 0.018
## Maximum forward reach checked for walls; hands withdraw before crossing them.
@export var wall_reach := 0.95
@export var wall_margin := 0.08
@export var sleeve_colour := Color("444a3c")
@export var glove_colour := Color("65513b")
var _hands := {}

func hand_mesh(left: bool=false) -> ArrayMesh:
	if _hands.has(left):
		return _hands[left]
	var st := ArtGeometry.begin()
	ArtGeometry.branch(st,Vector3(0,-0.13,0.13),Vector3(0,0,-0.12),0.062,sleeve_colour,0.8)
	ArtGeometry.branch(st,Vector3(0,-0.008,-0.08),Vector3(0,0,-0.14),0.055,glove_colour.darkened(0.25),1.0)
	ArtGeometry.box(st,Vector3(0,0,-0.19),Vector3(0.096,0.067,0.11),glove_colour)
	for i in 4:
		var x := (float(i)-1.5)*0.024
		ArtGeometry.branch(st,Vector3(x,0,-0.23),Vector3(x,-0.015,-0.29+absf(x)*0.35),0.011,glove_colour.lightened(0.08),0.82)
	var thumb_side := 1.0 if left else -1.0
	ArtGeometry.branch(st,Vector3(thumb_side*0.046,-0.008,-0.16),Vector3(thumb_side*0.07,-0.025,-0.205),0.018,glove_colour)
	_hands[left] = st.commit()
	return _hands[left]
