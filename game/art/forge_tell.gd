class_name ForgeTell
extends Node3D
## A depth-tested perimeter entirely inside one existing convex danger area.
## Geometry is shared; the only changing value is an existing warning's fraction.
const LOOK = preload("res://art/forge_tell_look.tres")
const EDGE = preload("res://art/forge_tell_edge.gdshader")
static var _meshes: Dictionary = {}
static var _border_material: StandardMaterial3D
var stroke: ShaderMaterial
var warning_progress := 0.0
var active := false


static func cone(radius: float, degrees: float) -> PackedVector2Array:
	var points := PackedVector2Array([Vector2.ZERO])
	var arc := deg_to_rad(degrees) * 0.5
	for i in LOOK.arc_segments + 1:
		var angle := lerpf(-arc, arc, float(i) / LOOK.arc_segments)
		points.append(Vector2(sin(angle), -cos(angle)) * radius)
	return points


static func disc(radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in LOOK.arc_segments:
		var angle: float = TAU * float(i) / LOOK.arc_segments
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	return points


static func lane(size: Vector2) -> PackedVector2Array:
	var half := size * 0.5
	return PackedVector2Array([Vector2(-half.x, -half.y), Vector2(half.x, -half.y),
		Vector2(half.x, half.y), Vector2(-half.x, half.y)])


static func attach(parent: MeshInstance3D, points: PackedVector2Array) -> ForgeTell:
	var tell := ForgeTell.new()
	tell.name = "TellBoundary"
	var key := str(points) + str(Vector3(LOOK.border_width_m, LOOK.stroke_inset_m, LOOK.stroke_width_m))
	if not _meshes.has(key):
		if _meshes.size() >= clampi(LOOK.mesh_cache_limit, 1, 32): _meshes.erase(_meshes.keys()[0])
		_meshes[key] = [_band(points, 0.0, LOOK.border_width_m),
			_band(points, LOOK.stroke_inset_m, LOOK.stroke_inset_m + LOOK.stroke_width_m)]
	if _border_material == null:
		_border_material = StandardMaterial3D.new()
		_border_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_border_material.cull_mode = BaseMaterial3D.CULL_DISABLED
		_border_material.albedo_color = LOOK.border_colour
	var border := MeshInstance3D.new()
	border.name = "DarkEdge"
	border.mesh = _meshes[key][0]
	border.material_override = _border_material
	border.position.y = LOOK.outline_height_m
	border.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tell.add_child(border)
	var edge := MeshInstance3D.new()
	edge.name = "ProgressEdge"
	edge.mesh = _meshes[key][1]
	edge.position.y = LOOK.outline_height_m + LOOK.stroke_lift_m
	edge.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	tell.stroke = ShaderMaterial.new()
	tell.stroke.shader = EDGE
	tell.stroke.set_shader_parameter("warning_colour", LOOK.warning_colour)
	tell.stroke.set_shader_parameter("progress_colour", LOOK.progress_colour)
	tell.stroke.set_shader_parameter("active_colour", LOOK.active_colour)
	edge.material_override = tell.stroke
	tell.add_child(edge)
	parent.add_child(tell)
	tell.set_warning(1.0, 1.0)
	return tell


func set_warning(left: float, total: float) -> void:
	active = false
	warning_progress = clampf(1.0 - left / maxf(total, 0.0001), 0.0, 1.0)
	stroke.set_shader_parameter("warning_progress", warning_progress)
	stroke.set_shader_parameter("active", false)


func set_active() -> void:
	active = true
	warning_progress = 1.0
	stroke.set_shader_parameter("warning_progress", 1.0)
	stroke.set_shader_parameter("active", true)


## Intersection of neighbouring inset edges. The supported cone, disc and
## rectangle are convex and counter-clockwise, so all strips stay inward.
static func _inset(points: PackedVector2Array, width: float) -> PackedVector2Array:
	var result := PackedVector2Array()
	for i in points.size():
		var p := points[i]
		var before := (p - points[posmod(i - 1, points.size())]).normalized()
		var after := (points[(i + 1) % points.size()] - p).normalized()
		var a := p + Vector2(-before.y, before.x) * width
		var b := p + Vector2(-after.y, after.x) * width
		var cross := before.cross(after)
		result.append(a + before * ((b - a).cross(after) / cross) if absf(cross) > 0.00001 else a)
	return result


static func _band(points: PackedVector2Array, outer_width: float, inner_width: float) -> ArrayMesh:
	var outside := _inset(points, outer_width)
	var inside := _inset(points, inner_width)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size():
		var next := (i + 1) % points.size()
		var u := float(i) / points.size()
		var v := float(i + 1) / points.size()
		for vertex in [[outside[i], u], [outside[next], v], [inside[i], u],
			[outside[next], v], [inside[next], v], [inside[i], u]]:
			var at: Vector2 = vertex[0]
			st.set_uv(Vector2(float(vertex[1]), 0.0))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(at.x, 0.0, at.y))
	return st.commit()
