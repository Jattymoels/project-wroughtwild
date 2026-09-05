class_name BuildThumbnail
extends Control
const LOOK = preload("res://art/build_ui_look.tres")
## Orthographic drawing of the actual piece triangles, without live 3D viewports.
var mesh: Mesh
var turn := 0
var arrow := false
var colour: Color = LOOK.thumbnail_colour

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func _draw() -> void:
	if mesh == null:
		return
	var faces := mesh.get_faces()
	if faces.is_empty():
		return
	var view := Basis.from_euler(LOOK.thumbnail_view).inverse()
	var rotate := Basis(Vector3.UP, float(turn)*PI/2.0)
	var centre := mesh.get_aabb().get_center()
	var span := mesh.get_aabb().size.length()
	var zoom: float = minf(size.x,size.y)*LOOK.thumbnail_fill/maxf(span,0.1)
	var tris: Array = []
	for i in range(0,faces.size(),3):
		var a := view*rotate*(faces[i]-centre)
		var b := view*rotate*(faces[i+1]-centre)
		var c := view*rotate*(faces[i+2]-centre)
		# Godot triangle winding is clockwise; negate the cross for outward normals.
		var normal := -(b-a).cross(c-a).normalized()
		var shade := 0.55+0.45*maxf(0.0,normal.dot(Vector3(-0.4,0.7,1).normalized()))
		tris.append({"z":(a.z+b.z+c.z)/3.0, "points":PackedVector2Array([
			size/2.0+Vector2(a.x,-a.y)*zoom, size/2.0+Vector2(b.x,-b.y)*zoom,
			size/2.0+Vector2(c.x,-c.y)*zoom]), "colour":colour*Color(shade,shade,shade,1)})
	tris.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.z < b.z)
	for tri in tris:
		draw_colored_polygon(tri.points,tri.colour)
	if arrow:
		var direction := view*rotate*Vector3.FORWARD
		var end := size/2.0+Vector2(direction.x,-direction.y)*minf(size.x,size.y)*0.4
		var start := size/2.0+Vector2(direction.x,-direction.y)*minf(size.x,size.y)*0.22
		draw_line(start,end,LOOK.arrow_colour,2.0,true)
		var back := (start-end).normalized()*7.0
		draw_line(end,end+back.rotated(0.5),LOOK.arrow_colour,2.0,true)
		draw_line(end,end+back.rotated(-0.5),LOOK.arrow_colour,2.0,true)
