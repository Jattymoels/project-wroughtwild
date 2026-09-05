class_name SurfaceSampler
extends RefCounted
## Vertical samples of the actual render/collision triangles, including caves.
## Buckets avoid a physics-frame wait when chunks and scenery are rebuilt.
var faces := PackedVector3Array()
var columns: Dictionary = {}
var cell_size := 1.0

func _init(triangles: PackedVector3Array, cell := 1.0) -> void:
	faces = triangles
	cell_size = cell
	for i in range(0, faces.size(), 3):
		var a := faces[i]
		var b := faces[i+1]
		var c := faces[i+2]
		if (c-a).cross(b-a).y <= 0.000001:
			continue
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
		var a := faces[i]
		var b := faces[i+1]
		var c := faces[i+2]
		var denominator := (b.z-c.z)*(a.x-c.x)+(c.x-b.x)*(a.z-c.z)
		var u := ((b.z-c.z)*(x-c.x)+(c.x-b.x)*(z-c.z))/denominator
		var v := ((c.z-a.z)*(x-c.x)+(a.x-c.x)*(z-c.z))/denominator
		if u < -0.00001 or v < -0.00001 or u+v > 1.00001:
			continue
		var y := u*a.y+v*b.y+(1-u-v)*c.y
		if absf(y-reference_y) <= distance:
			distance = absf(y-reference_y)
			closest = y
	return closest
