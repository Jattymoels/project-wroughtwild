class_name HabitatResourceArt
extends RefCounted
const LOOK = preload("res://art/habitat_sites_look.tres")
const LABELS := {"slate_seam":"Layered slate bed","shellstone_seam":"Fossil shellstone bed","clay_bank":"Rustclay bank","reed_bed":"Stand of weaving reeds","resinheart_tree":"Resinheart tree","corkbark_deadfall":"Corkbark trunk"}
static var _meshes := {}

static func supports(visual: StringName) -> bool:
	return LABELS.has(String(visual))

static func bounds_for(visual: StringName) -> Vector3:
	match String(visual):
		"resinheart_tree": return Vector3(0.7,3.0,0.7)*LOOK.resinheart_scale
		"corkbark_deadfall": return Vector3(1.65,0.65,0.9)
		"reed_bed": return Vector3(1.0,1.3,1.0)
		"clay_bank": return Vector3(1.8,0.38,1.25)
	return Vector3(2.0,0.58,1.15)

static func mesh_for(visual: StringName, seed_value: int) -> Mesh:
	var variant := posmod(seed_value,3)
	var key := String(visual)+str(variant)
	if _meshes.has(key): return _meshes[key]
	if visual==&"resinheart_tree":
		return AuthoredAssets.scaled_mesh("broadleaf_tree",LOOK.resinheart_scale)
	var st := ArtGeometry.begin()
	var rng := RandomNumberGenerator.new()
	rng.seed = 6837+variant*251
	match String(visual):
		"slate_seam", "shellstone_seam":
			var colour: Color = LOOK.quarry_colour if visual==&"slate_seam" else LOOK.shell_colour
			# Broken, tapered sedimentary beds. Each ledge shares the bedding
			# direction but has its own chipped outline, never sawn slab boxes.
			for i in 4:
				var at := Vector3(rng.randf_range(-0.09,0.09),.035+i*.115,rng.randf_range(-.04,.04))
				_stratum(st,rng,at,Vector3(2.00-i*.16,.16,1.12-i*.05),colour.darkened(rng.randf_range(0,.07)))
			if visual==&"shellstone_seam":
				for i in 3:
					var at := Vector3(rng.randf_range(-0.45,0.45),0.535,rng.randf_range(-0.28,0.28))
					for j in 9:
						var a := float(j)*0.6
						var b := float(j+1)*0.6
						ArtGeometry.branch(st,at+Vector3(cos(a),0,sin(a))*(0.10-j*0.006),at+Vector3(cos(b),0,sin(b))*(0.094-j*0.006),0.006,colour.darkened(0.19))
		"clay_bank":
			_stratum(st,rng,Vector3(0,-.055,0),Vector3(1.85,.22,1.25),LOOK.clay_colour.darkened(.17))
			_stratum(st,rng,Vector3(.06,.10,-.025),Vector3(1.60,.20,1.05),LOOK.clay_colour)
			_stratum(st,rng,Vector3(-.07,.245,-.01),Vector3(1.1,.085,.75),LOOK.clay_colour.lightened(.07))
			# Dried fractures and a wet cut face make this an exposed bank.
			for i in 5:
				var a:=Vector3(rng.randf_range(-.42,.42),.335,rng.randf_range(-.24,.24))
				var b:=a+Vector3(rng.randf_range(-.15,.15),-.008,rng.randf_range(.05,.19))
				ArtGeometry.branch(st,a,b,.005,LOOK.clay_colour.darkened(.35))
		"reed_bed":
			for i in 24:
				var at := Vector3(rng.randf_range(-0.48,0.48),0,rng.randf_range(-0.48,0.48))
				var end := at+Vector3(rng.randf_range(-0.12,0.12),rng.randf_range(0.85,1.4),rng.randf_range(-0.12,0.12))
				ArtGeometry.branch(st,at,end,0.012,LOOK.reed_colour,0.55)
				ArtGeometry.branch(st,end,end+Vector3.UP*0.16,0.029,LOOK.cork_colour,0.7)
				ArtGeometry.triangle(st,at.lerp(end,0.4),at.lerp(end,0.7)+Vector3(0.16,0.15,0),at.lerp(end,0.73),LOOK.reed_colour.lightened(0.08))
		"corkbark_deadfall":
			ArtGeometry.branch(st,Vector3(-0.77,0.26,0),Vector3(0.78,0.29,0.09),0.31,LOOK.cork_colour,0.88)
			for i in 11:
				var angle := float(i)*TAU/11.0
				var side := Vector3(0,cos(angle)*0.27,sin(angle)*0.27)
				ArtGeometry.branch(st,Vector3(-0.74,0.29,0)+side,Vector3(0.72,0.3,0.08)+side,0.04,LOOK.cork_colour.darkened(0.15),0.75)
			ArtGeometry.branch(st,Vector3(-0.785,0.26,0),Vector3(-0.795,0.26,0),0.22,LOOK.shell_colour.darkened(0.27),1.0)
	_meshes[key] = st.commit()
	return _meshes[key]

static func _stratum(st:SurfaceTool,rng:RandomNumberGenerator,at:Vector3,size:Vector3,colour:Color)->void:
	var lower:Array[Vector3]=[]
	var upper:Array[Vector3]=[]
	for i in 10:
		var angle:=float(i)*TAU/10.0
		var radial:=rng.randf_range(.82,1.0)
		lower.append(at+Vector3(cos(angle)*size.x*.5*radial,0,sin(angle)*size.z*.5*radial))
		upper.append(at+Vector3(cos(angle)*size.x*.46*radial,size.y+rng.randf_range(-.016,.016),sin(angle)*size.z*.46*radial))
	var top:=at+Vector3.UP*size.y
	for i in 10:
		var j:=(i+1)%10
		ArtGeometry.triangle(st,top,upper[i],upper[j],colour)
		ArtGeometry.triangle(st,lower[i],upper[j],upper[i],colour.darkened(.06))
		ArtGeometry.triangle(st,lower[i],lower[j],upper[j],colour.darkened(.06))
		ArtGeometry.triangle(st,at,lower[j],lower[i],colour.darkened(.12))
