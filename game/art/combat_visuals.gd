class_name CombatVisuals
extends RefCounted
## Authored primitive geometry, shared by first-person equipment and actual
## projectile nodes. These meshes have no collision or gameplay authority.
static var _weapons: Dictionary = {}
const BASE_ROLES := {
	"hunting_bow":"bow", "bronze_longbow":"bow", "iron_mace":"mace",
	"frost_sceptre":"sceptre", "bronze_sceptre":"sceptre",
	"ember_wand":"wand", "charred_brand":"brand",
}

static func weapon(base: String) -> ArrayMesh:
	if not BASE_ROLES.has(base):
		return null
	if _weapons.has(base):
		return _weapons[base]
	var st := ArtGeometry.begin()
	var wood := Color("65503a")
	var iron := Color("59646b")
	var metal := Color("927449") if base.begins_with("bronze") else iron
	var grip := Color("39362e")
	match String(BASE_ROLES[base]):
		"bow":
			for side in [-1.0,1.0]:
				var previous := Vector3.ZERO
				for i in range(1,9):
					var t := float(i)/8.0
					var at := Vector3(0,side*t*0.55,-sin(t*PI)*0.16+t*0.06)
					ArtGeometry.branch(st,previous,at,lerpf(0.028,0.011,t),wood,0.94)
					previous = at
				ArtGeometry.branch(st,Vector3(0,side*0.51,0.028),previous,0.017,metal)
			ArtGeometry.branch(st,Vector3(0,-0.55,0.06),Vector3(0,0.55,0.06),0.0025,Color("b5a687"),1.0)
			ArtGeometry.branch(st,Vector3(0,-0.075,0),Vector3(0,0.075,0),0.034,grip,1.0)
		"mace":
			ArtGeometry.branch(st,Vector3(0,-0.17,0),Vector3(0,0.38,0),0.028,wood,0.9)
			ArtGeometry.branch(st,Vector3(0,-0.13,0),Vector3(0,0.08,0),0.033,grip,1.0)
			ArtGeometry.branch(st,Vector3(0,0.29,0),Vector3(0,0.49,0),0.045,metal.darkened(0.2),1.0)
			for i in 6:
				var a := TAU*float(i)/6
				var radial := Vector3(cos(a),0,sin(a))
				var tangent := Vector3(-sin(a),0,cos(a))*0.008
				var blade := [radial*0.04+Vector3(0,0.29,0),radial*0.105+Vector3(0,0.34,0),radial*0.105+Vector3(0,0.44,0),radial*0.04+Vector3(0,0.49,0)]
				for side in [-1.0,1.0]:
					ArtGeometry.triangle(st,blade[0]+tangent*side,blade[1]+tangent*side,blade[2]+tangent*side,metal)
					ArtGeometry.triangle(st,blade[0]+tangent*side,blade[2]+tangent*side,blade[3]+tangent*side,metal)
				for j in 4:
					var k := (j+1)%4
					ArtGeometry.triangle(st,blade[j]-tangent,blade[k]-tangent,blade[k]+tangent,metal.lightened(0.16))
					ArtGeometry.triangle(st,blade[j]-tangent,blade[k]+tangent,blade[j]+tangent,metal.lightened(0.16))
			for i in 5:
				var y := -0.12+float(i)*0.038
				ArtGeometry.branch(st,Vector3(0,y,0),Vector3(0,y+0.012,0),0.034,grip.lightened(0.07),1.0)
			ArtGeometry.oval(st,Vector3(0,-0.17,0),Vector3.ONE*0.075,metal)
		"sceptre", "wand", "brand":
			var cold: bool = BASE_ROLES[base] == "sceptre"
			ArtGeometry.branch(st,Vector3(0,-0.16,0),Vector3(0,0.37,0),0.026,wood.darkened(0.15),0.75)
			for y in [-0.10,0.06,0.30]:
				ArtGeometry.branch(st,Vector3(0,y,0),Vector3(0,y+0.025,0),0.037,metal,1.0)
			for side in [-1.0,1.0]:
				ArtGeometry.branch(st,Vector3(0,0.29,0),Vector3(side*0.07,0.42,0),0.02,metal)
			ArtGeometry.oval(st,Vector3(0,0.42,0),Vector3(0.075,0.18,0.085),Color("83b5c2") if cold else Color("ae6335"))
	var mesh := st.commit()
	var material := ArtGeometry.material()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.surface_set_material(0,material)
	_weapons[base] = mesh
	return mesh

static func projectile(profile: String, colour: Color) -> Node3D:
	var root := Node3D.new()
	var st := ArtGeometry.begin()
	if profile == "wave":
		# A low, forward-curving cutting edge reads differently from an orb
		# or arrow. The hot edge leads the darker, broken wake.
		for i in 24:
			var a := lerpf(-1.2, 1.2, float(i) / 24.0)
			var b := lerpf(-1.2, 1.2, float(i + 1) / 24.0)
			var p := Vector3(sin(a), 0, -cos(a)) * 0.72
			var q := Vector3(sin(b), 0, -cos(b)) * 0.72
			ArtGeometry.triangle(st, p, q, p + Vector3(0, 0.04, 0.13), colour.lightened(0.18))
			ArtGeometry.triangle(st, q, q + Vector3(0, 0.04, 0.13), p + Vector3(0, 0.04, 0.13), colour)
			if i % 3 == 0:
				ArtGeometry.triangle(st, p, p + Vector3(0.035, 0.09, 0.15), p + Vector3(0, 0, 0.48), colour.darkened(0.35))
	elif profile in ["arrow","fan","bodkin"]:
		ArtGeometry.branch(st,Vector3(0,0,0.35),Vector3(0,0,-0.3),0.009,Color("887052"),1.0)
		for i in 3:
			var a := TAU*float(i)/3
			var side := Vector3(cos(a),sin(a),0)*0.045
			ArtGeometry.triangle(st,Vector3(0,0,0.31),Vector3(0,0,0.13)+side,Vector3(0,0,0.12),Color("aa9e85"))
			ArtGeometry.triangle(st,Vector3(0,0,-0.44),side*0.7+Vector3(0,0,-0.27),-side*0.7+Vector3(0,0,-0.27),Color("9aaba9"))
	elif profile == "coal":
		ArtGeometry.oval(st,Vector3.ZERO,Vector3.ONE*0.28,Color("4b3930"))
		for i in 7:
			var a := TAU*float(i)/7
			var at := Vector3(cos(a)*0.13,sin(a)*0.13,0)
			ArtGeometry.branch(st,at+Vector3(0,0,0.12),at-Vector3(0,0,0.12),0.015,colour,0.7)
	elif profile == "frost":
		ArtGeometry.oval(st,Vector3.ZERO,Vector3.ONE*0.22,colour)
		for i in 6:
			var a := TAU*float(i)/6
			var at := Vector3(cos(a)*0.20,sin(a)*0.20,0)
			ArtGeometry.oval(st,at,Vector3(0.035,0.085,0.045),colour.lightened(0.2))
	else:
		ArtGeometry.oval(st,Vector3(0,0,-0.06),Vector3(0.12,0.12,0.34),colour.lightened(0.15))
		for i in 3:
			var a := TAU*float(i)/3
			var at := Vector3(cos(a)*0.06,sin(a)*0.06,0.14)
			ArtGeometry.branch(st,at+Vector3(0,0,0.34),at,0.006,colour.darkened(0.3),5.0)
	var visual := MeshInstance3D.new()
	visual.mesh = st.commit()
	var material := ArtGeometry.material()
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	if not profile in ["arrow","fan","bodkin","coal"]:
		material.emission_enabled = true
		material.emission = colour
		material.emission_energy_multiplier = 0.6
	visual.material_override = material
	visual.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(visual)
	return root
