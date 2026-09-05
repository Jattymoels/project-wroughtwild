class_name SurfaceSampler
extends RefCounted
## Vertical samples of the actual render/collision triangles, including caves.
## Buckets avoid a physics-frame wait when chunks and scenery are rebuilt.
var faces := PackedVector3Array()
var columns: Dictionary = {}
var cell_size := 1.0
var coordinates := PackedVector3Array()

func _init(triangles: PackedVector3Array, cell := 1.0) -> void:
	faces = triangles
	cell_size = cell
	coordinates.resize(faces.size())
	for i in range(0, faces.size(), 3):
		var a := faces[i]
		var b := faces[i+1]
		var c := faces[i+2]
		if (c-a).cross(b-a).y <= 0.000001:
			continue
		# Cache barycentric coefficients and height differences once. Scenery
		# asks many times per triangle, especially the mineral ribbon spans.
		var denominator := (b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
		var u := Vector3((b.z-c.z)/denominator,(c.x-b.x)/denominator,a.y-c.y)
		var v := Vector3((c.z-a.z)/denominator,(a.x-c.x)/denominator,b.y-c.y)
		coordinates[i] = u
		coordinates[i+1] = v
		coordinates[i+2] = Vector3(c.x,c.z,c.y)
		for x in range(floori(minf(a.x,minf(b.x,c.x))/cell), floori(maxf(a.x,maxf(b.x,c.x))/cell)+1):
			for z in range(floori(minf(a.z,minf(b.z,c.z))/cell), floori(maxf(a.z,maxf(b.z,c.z))/cell)+1):
				var key := Vector2i(x,z)
				if not columns.has(key):
					columns[key] = []
				columns[key].append(i)

## Nearest upward-facing surface to reference_y. Never jump to a cave roof
## or far below an excavated patch; an absent support returns INF.
func height_at(x: float, z: float, reference_y: float, reach := 0.8) -> float:
	var closest := INF
	var distance := reach
	for i in columns.get(Vector2i(floori(x/cell_size),floori(z/cell_size)), []):
		var origin := coordinates[i+2]
		var cu := coordinates[i]
		var cv := coordinates[i+1]
		# Local offsets retain precision at far map coordinates and triangle edges.
		var dx := x-origin.x
		var dz := z-origin.y
		var u := cu.x*dx+cu.y*dz
		var v := cv.x*dx+cv.y*dz
		if u < -0.00001 or v < -0.00001 or u+v > 1.00001:
			continue
		var y := u*cu.z+v*cv.z+origin.z
		if absf(y-reference_y) <= distance:
			distance = absf(y-reference_y)
			closest = y
	return closest
