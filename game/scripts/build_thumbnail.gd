class_name BuildThumbnail
extends Control
const LOOK = preload("res://art/build_ui_look.tres")
## Orthographic drawing of the actual piece triangles, without live 3D viewports.
var mesh: Mesh:
	set(value):
		mesh = value
		_sync_material_preview()
var turn := 0:
	set(value):
		turn = value
		_sync_material_preview()
var arrow := false
var colour: Color = LOOK.thumbnail_colour
var _material_view: SubViewport
var _material_mesh: MeshInstance3D
var _material_camera: Camera3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


## The selected catalogue item gets one actual rendered material preview.
## Grid cards remain inexpensive geometry swatches; only one viewport exists.
func show_material(sim: WroughtwildSim, family: StringName, form: String, role: String = "") -> void:
	if _material_view==null:
		_material_view = SubViewport.new()
		_material_view.size = Vector2i(520,320)
		_material_view.world_3d = World3D.new()
		_material_view.transparent_bg = true
		_material_view.render_target_update_mode = SubViewport.UPDATE_ONCE
		add_child(_material_view)
		_material_mesh = MeshInstance3D.new()
		_material_view.add_child(_material_mesh)
		_material_camera = Camera3D.new()
		_material_camera.projection = Camera3D.PROJECTION_ORTHOGONAL
		_material_view.add_child(_material_camera)
		_material_camera.make_current()
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-42,-30,0)
		light.light_energy = 1.3
		_material_view.add_child(light)
		var environment := WorldEnvironment.new()
		environment.environment = Environment.new()
		environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		environment.environment.ambient_light_color = Color("c5c9c0")
		environment.environment.ambient_light_energy = 0.6
		_material_view.add_child(environment)
	_sync_material_preview()
	if form=="station":
		_material_mesh.material_override = null
		for i in _material_mesh.get_surface_override_material_count(): _material_mesh.set_surface_override_material(i,null)
	else:
		# Box geometry alone cannot identify a post or beam. The picker supplies
		# its native element role; old direct callers retain form-based defaults.
		if role.is_empty(): role = "roof" if form.begins_with("roof_") else "door" if form=="door" else "surface"
		PieceLook.apply_to(_material_mesh,form,family,PieceLook.material_for(sim,family,
			role))
	queue_redraw()
	# Update once after selection; moving the mouse does not render more 3D worlds.
	if not RenderingServer.frame_post_draw.is_connected(queue_redraw):
		RenderingServer.frame_post_draw.connect(queue_redraw,CONNECT_ONE_SHOT)


func _sync_material_preview() -> void:
	if _material_mesh==null or mesh==null: return
	_material_mesh.mesh = mesh
	_material_mesh.rotation.y = float(turn)*PI/2.0
	var centre := mesh.get_aabb().get_center()
	_material_mesh.position = -(_material_mesh.basis*centre)
	_material_camera.size = mesh.get_aabb().size.length()*1.04
	_material_camera.position = Vector3(3,2.4,-4)
	_material_camera.look_at(Vector3.ZERO)
	_material_view.render_target_update_mode = SubViewport.UPDATE_ONCE
	queue_redraw()

func _draw() -> void:
	if mesh == null:
		return
	if _material_view!=null:
		draw_texture_rect(_material_view.get_texture(),Rect2(Vector2.ZERO,size),false)
		_draw_arrow()
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
		var points := PackedVector2Array([
			size/2.0+Vector2(a.x,-a.y)*zoom, size/2.0+Vector2(b.x,-b.y)*zoom,
			size/2.0+Vector2(c.x,-c.y)*zoom])
		# An otherwise valid 3D face can become a line in this view. Godot's
		# polygon triangulator cannot draw it, and it covers no thumbnail area.
		if not projected_face_has_area(points): continue
		# Godot triangle winding is clockwise; negate the cross for outward normals.
		var normal := -(b-a).cross(c-a).normalized()
		var shade := 0.55+0.45*maxf(0.0,normal.dot(Vector3(-0.4,0.7,1).normalized()))
		tris.append({"z":(a.z+b.z+c.z)/3.0, "points":points, "colour":colour*Color(shade,shade,shade,1)})
	tris.sort_custom(func(a: Dictionary,b: Dictionary) -> bool: return a.z < b.z)
	for tri in tris:
		# These are already triangles. The polygon ear-clipping path can
		# reject very thin imported faces after projection; submit the known
		# primitive directly instead of triangulating it a second time.
		draw_primitive(tri.points,PackedColorArray([tri.colour,tri.colour,tri.colour]),PackedVector2Array())
	_draw_arrow()


static func projected_face_has_area(points: PackedVector2Array) -> bool:
	return points.size()==3 and not is_zero_approx((points[1]-points[0]).cross(points[2]-points[0]))


func _draw_arrow() -> void:
	if arrow:
		var view := Basis.from_euler(LOOK.thumbnail_view).inverse()
		var rotate := Basis(Vector3.UP,float(turn)*PI/2.0)
		var direction := view*rotate*Vector3.FORWARD
		var end := size/2.0+Vector2(direction.x,-direction.y)*minf(size.x,size.y)*0.4
		var start := size/2.0+Vector2(direction.x,-direction.y)*minf(size.x,size.y)*0.22
		draw_line(start,end,LOOK.arrow_colour,2.0,true)
		var back := (start-end).normalized()*7.0
		draw_line(end,end+back.rotated(0.5),LOOK.arrow_colour,2.0,true)
		draw_line(end,end+back.rotated(-0.5),LOOK.arrow_colour,2.0,true)
