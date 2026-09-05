extends Resource
## A middle layer in habitat patches, with quiet openings between them.
@export var patch_metres := 18.0
@export var patch_threshold := 0.08
## Per eligible cell inside a patch; existing resource yields are not affected.
@export var shrub_density := 0.075
@export var fern_density := 0.16
@export var deadfall_density := 0.008
@export var stump_density := 0.008
## Keep the starting clearing, progression sites and work nodes readable.
@export var clearing_metres := 10.0
@export var resource_clearance := 2
## Reject steep/unsupported footprints instead of leaving floating scenery.
@export var max_rise := 0.3
@export var visibility_metres := 75.0
@export var shrub_green := Color("3b4a2c")
@export var fern_green := Color("4e6340")
@export var bark := Color("40362c")
@export var rot := Color("6d6750")
var _meshes: Dictionary = {}
var _material: StandardMaterial3D
var _noise: FastNoiseLite

func patch(x: float, z: float) -> float:
	if _noise==null:
		_noise = FastNoiseLite.new()
		_noise.seed = 2741
		_noise.frequency = 1.0/patch_metres
	return smoothstep(patch_threshold,patch_threshold+0.25,_noise.get_noise_2d(x,z))

func entries(biome: String) -> Array:
	var entries := []
	if biome in ["meadow","forest","fen"]:
		entries.append({"kind":"shrub","density":shrub_density,"radius":0.65})
		entries.append({"kind":"fern_bed","density":fern_density*(1.0 if biome!="meadow" else 0.35),"radius":0.5})
	if biome in ["forest","meadow","fen","ember_wastes"]:
		entries.append({"kind":"deadfall","density":deadfall_density,"radius":0.85})
		entries.append({"kind":"stump","density":stump_density,"radius":0.4})
	return entries

func material() -> StandardMaterial3D:
	if _material==null:
		_material = ArtGeometry.material()
		_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return _material

func mesh_for(kind: String, variant: int) -> ArrayMesh:
	var authored := AuthoredAssets.mesh_for(kind)
	if authored != null:
		return authored
	var key := kind+str(variant)
	if _meshes.has(key):
		return _meshes[key]
	var rng := RandomNumberGenerator.new()
	rng.seed = 614+variant*193
	var st := ArtGeometry.begin()
	match kind:
		"shrub":
			for i in 7:
				var angle := float(i)*TAU/7.0+rng.randf_range(-0.2,0.2)
				var end := Vector3(cos(angle)*rng.randf_range(0.25,0.52),rng.randf_range(0.5,0.85),sin(angle)*0.4)
				ArtGeometry.branch(st,Vector3.ZERO,end,0.022,bark,0.25)
				# Small pointed leaves around each branch, not miniature tree balls.
				for j in 5:
					var at := end*(0.4+float(j)*0.12)
					var direction := Vector3(cos(angle+float(j)*2.4),0.35,sin(angle+float(j)*2.4))
					_leaf(st,at,direction*0.2,0.07,shrub_green.lightened(rng.randf()*0.12))
		"fern_bed":
			for i in 9:
				var angle := float(i)*TAU/9.0
				var direction := Vector3(cos(angle),0,sin(angle))
				var end := direction*0.47+Vector3.UP*rng.randf_range(0.26,0.48)
				ArtGeometry.branch(st,Vector3.ZERO,end,0.009,fern_green.darkened(0.2),0.3)
				for j in range(1,6):
					var t := float(j)/6.0
					var at := end*t+Vector3.UP*sin(t*PI)*0.11
					var cross := Vector3(-direction.z,0,direction.x)*(1.0-t)*0.21
					_leaf(st,at,cross+direction*0.08,0.045,fern_green)
					_leaf(st,at,-cross+direction*0.08,0.045,fern_green.darkened(0.12))
		"deadfall":
			# Short rotten split timber; open dark cavity and jagged broken ends.
			ArtGeometry.branch(st,Vector3(-0.72,0.14,0),Vector3(0.69,0.17,0.05),0.16,bark,0.8)
			ArtGeometry.branch(st,Vector3(-0.73,0.14,0),Vector3(-0.745,0.14,0),0.12,rot,1.0)
			ArtGeometry.branch(st,Vector3(-0.747,0.14,0),Vector3(-0.751,0.14,0),0.075,bark.darkened(0.65),1.0)
			for i in 3:
				var x := -0.35+float(i)*0.3
				ArtGeometry.branch(st,Vector3(x,0.19,0),Vector3(x+0.18,0.33,-0.23),0.035,bark,0.15)
		"stump":
			ArtGeometry.branch(st,Vector3(0,-0.08,0),Vector3(0.04,0.42,0),0.21,bark,0.7)
			ArtGeometry.branch(st,Vector3(0.04,0.42,0),Vector3(0.04,0.425,0),0.14,rot,1.0)
			for i in 5:
				var angle := float(i)*TAU/5.0
				ArtGeometry.branch(st,Vector3(0,0.12,0),Vector3(cos(angle)*0.36,-0.025,sin(angle)*0.36),0.085,bark,0.1)
	var mesh := st.commit()
	_meshes[key] = mesh
	return mesh

func _leaf(st: SurfaceTool, at: Vector3, direction: Vector3, width: float, colour: Color) -> void:
	var across := direction.cross(Vector3.UP).normalized()*width
	var middle := at+direction*0.48+Vector3.UP*0.025
	ArtGeometry.triangle(st,at,middle+across,at+direction,colour)
	ArtGeometry.triangle(st,at,at+direction,middle-across,colour.darkened(0.1))
