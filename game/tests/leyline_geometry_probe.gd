extends RefCounted
## A deterministic support seam exercises the actual fissure builder without
## changing the review world's terrain, inventory, native identity or save.
class SupportTerrain extends Terrain:
	var support_mode := "flat"
	func height_at(_x: int, _z: int) -> int:
		return 4
	func rendered_height(x: float, _z: float, _reference_y: float, _reach := 0.8) -> float:
		if support_mode == "absent": return INF
		if support_mode == "void" and x > 6.0 and x < 8.0: return INF
		if support_mode == "cliff" and x >= 7.0: return 1.0
		return 4.0

static func run(root: Node3D, _terrain: Terrain, _history: CataclysmSites) -> Dictionary:
	var result := {"checks":0, "failures":0, "messages":[]}
	var support := SupportTerrain.new()
	support.map = {"cell_size":1.0, "seed":719}
	# An available exact chunk must never substitute native ground for a hole.
	var chunk := Node3D.new()
	support.add_child(chunk)
	support.chunks["0_0"] = chunk
	root.add_child(support)
	var trace := MeshInstance3D.new()
	trace.set_meta("record", {"id":"isolated_support_seam", "width_m":2.0,
		"points":PackedVector3Array([Vector3(2,4,8),Vector3(13,4,8)]),
		"exposure":PackedByteArray([2])})
	support.add_child(trace)
	var builder := LeylineFissures.new()
	builder.rebuild(trace,support,{})
	_check(result,trace.mesh != null,"flat support creates the control fracture")
	if trace.mesh == null:
		support.free()
		return result
	var pristine: PackedVector3Array = trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	_check(result,pristine.size() > 0,"control has inspectable physical vertex positions")

	support.support_mode = "void"
	builder.rebuild(trace,support,{})
	_check(result,trace.mesh != null,"digging the middle retains supported fracture on both sides")
	if trace.mesh != null:
		var vertices: PackedVector3Array = trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var clear_void := true
		var no_bridge := true
		var near_side := false
		var far_side := false
		for vertex in vertices:
			clear_void = clear_void and not (vertex.x > 6.0 and vertex.x < 8.0)
			near_side = near_side or vertex.x < 6.0
			far_side = far_side or vertex.x > 8.0
		for index in range(0,vertices.size(),3):
			var left := minf(vertices[index].x,minf(vertices[index+1].x,vertices[index+2].x))
			var right := maxf(vertices[index].x,maxf(vertices[index+1].x,vertices[index+2].x))
			no_bridge = no_bridge and not (left < 6.0 and right > 8.0)
		_check(result,clear_void,"no vertex floats over the unsupported excavated strip")
		_check(result,no_bridge,"no triangle bridges the excavated strip")
		_check(result,near_side and far_side,"support suppression keeps both ordinary approach sides visible")
		_check(result,vertices.size() < pristine.size(),"excavation actually removes surface geometry")

	support.support_mode = "cliff"
	builder.rebuild(trace,support,{})
	_check(result,trace.mesh != null,"an abrupt height step keeps valid ground on either side")
	if trace.mesh != null:
		var vertices: PackedVector3Array = trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		var no_bridge := true
		var upper := false
		var lower := false
		for index in range(0,vertices.size(),3):
			var low := minf(vertices[index].y,minf(vertices[index+1].y,vertices[index+2].y))
			var high := maxf(vertices[index].y,maxf(vertices[index+1].y,vertices[index+2].y))
			no_bridge = no_bridge and high-low < 0.1
			upper = upper or high > 4.0
			lower = lower or low < 2.0
		_check(result,no_bridge,"no fracture facet spans the abrupt three-metre excavation face")
		_check(result,upper and lower,"both supported levels retain their own grounded fragments")

	support.support_mode = "absent"
	builder.rebuild(trace,support,{})
	_check(result,trace.mesh == null,"wholly unsupported exact terrain produces no fracture or light")
	support.support_mode = "flat"
	builder.rebuild(trace,support,{})
	_check(result,trace.mesh != null,"restoring support rebuilds the fracture")
	if trace.mesh != null:
		var restored: PackedVector3Array = trace.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		_check(result,restored == pristine,"restoring support restores identical geometry and branch layout")
	_check(result,support.get_child_count() == 2,"visual rebuild creates no terrain or fracture physics objects")
	support.free()
	await root.get_tree().process_frame
	return result

static func _check(result: Dictionary, success: bool, message: String) -> void:
	result.checks += 1
	if not success:
		result.failures += 1
		result.messages.append(message)
