class_name GroundedSeam
extends RefCounted
## A narrow fracture/ore ribbon tessellated onto the real terrain surface.
## Missing supports interrupt the ribbon; it never bridges an excavated hole.
static func build(node: ResourceNode, terrain: Terrain, along_x: bool, ore: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = terrain.frontier_look.seam_steps
	var half_width: float = terrain.frontier_look.seam_half_width
	var lift: float = terrain.frontier_look.seam_surface_lift
	var basis := Basis.IDENTITY if along_x else Basis(Vector3.UP,PI*0.5)
	var count := 0
	var rows: Dictionary = {}
	for i in steps:
		var ends: Array = []
		for j in [i,i+1]:
			if rows.has(j):
				ends.append(rows[j])
				continue
			var x := -1.5+3.0*float(j)/steps
			var wander := sin(x*5.0+float(node._visual_seed()%100))*half_width*0.25
			var width := half_width*(0.8+0.2*sin(x*9.0))
			var row: Array[Vector3] = []
			for z in [-width,wander-0.035,wander+0.035,width]:
				var at := node.position+basis*Vector3(x,0,z)
				var y := terrain.rendered_height(at.x,at.z,node.position.y,1.25)
				row.append(Vector3(at.x-node.position.x,y-node.position.y+lift,at.z-node.position.z))
			ends.append(row)
			rows[j] = row
		for band in 3:
			var a: Vector3 = ends[0][band]
			var b: Vector3 = ends[1][band]
			var c: Vector3 = ends[1][band+1]
			var d: Vector3 = ends[0][band+1]
			if not a.is_finite() or not b.is_finite() or not c.is_finite() or not d.is_finite():
				continue
			# Do not bridge a vertical discontinuity to another floor.
			if maxf(maxf(a.y,b.y),maxf(c.y,d.y))-minf(minf(a.y,b.y),minf(c.y,d.y))>0.5:
				continue
			st.set_color(ore if band==1 else PropMesh.STONE_DARK)
			for triangle in [[a,b,c],[a,c,d]]:
				var n: Vector3 = (triangle[2]-triangle[0]).cross(triangle[1]-triangle[0]).normalized()
				st.set_normal(n)
				for v in triangle:
					st.add_vertex(v)
				count += 1
	return st.commit() if count>0 else null
