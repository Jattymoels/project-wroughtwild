extends SceneTree
## One synthetic sloped footprint with an unsupported opening; exact mesh
## digests were recorded from the pre-PLAY01 B3 projector on Godot 4.5.
class TestTerrain extends Terrain:
	var cut := false
	func rendered_height(x:float,z:float,_reference:float,_reach:=0.8)->float:
		if x>0.15 and z>0.08:return INF
		if cut and x < 0.0:return INF
		return x*0.05
var checks:=0
var failures:=0
func check(ok:bool,label:String)->void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL PLAY01 SEAM: ",label)
func _initialize()->void:run.call_deferred()
func fingerprint(node:ResourceNode)->Array:
	var result:=[]
	for mesh in node.art.find_children("*","MeshInstance3D",true,false):
		var surfaces:=[]
		for i in mesh.mesh.get_surface_count():
			var arrays: Array=mesh.mesh.surface_get_arrays(i)
			surfaces.append({"vertices":hash(arrays[Mesh.ARRAY_VERTEX]),"normals":hash(arrays[Mesh.ARRAY_NORMAL]),"uv":hash(arrays[Mesh.ARRAY_TEX_UV]),"count":arrays[Mesh.ARRAY_VERTEX].size(),"material":mesh.mesh.surface_get_material(i).resource_path})
		result.append(surfaces)
	return result
func run()->void:
	var terrain:=TestTerrain.new()
	terrain.faceted_surface=true
	terrain.frontier_look=preload("res://art/frontier_look.tres")
	root.add_child(terrain)
	terrain.set_process(false)
	terrain.resource_stream=ResourceStream.new()
	terrain.resource_stream.terrain=terrain
	var nodes:=Node3D.new()
	terrain.add_child(nodes)
	terrain.nodes_root=nodes

	var scene:PackedScene=load("res://scenes/resource_node.tscn")
	var node:ResourceNode=G1Art.resource(scene,{"visual":"seam","family":"split_stone"})
	node.visual=&"seam"
	node.remaining_units=12
	node.drive_progress=2
	node.set_meta("stream_projection",true)
	nodes.add_child(node)
	var expected_path:="res://tests/play01_seam_expected.json"
	var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(expected_path))
	check(expected.initial!=expected.cut,"synthetic edit actually changes supported decoration")
	check(terrain.resource_stream._projection_pending.size()==1 and not node.art.visible,"arrival queues one hidden overlay")
	var collider:CollisionShape3D=node.get_node("CollisionShape3D")
	var ribbon:MeshInstance3D=node.get_node("MeshInstance3D")
	var collision_hash:=hash(collider.shape.get_faces())
	check(collider.shape!=null and ribbon.mesh!=null and ribbon.visible,"native ribbon and collision are ready immediately")
	terrain.resource_stream._step_projections(Time.get_ticks_usec()+2000)
	check(not node._projection.is_empty() and not node.art.visible,"2 ms slot yields with unpublished work")
	var steps:=0
	var maximum_ms:=0.0
	while not terrain.resource_stream._projection_pending.is_empty() and steps<1000:
		var began:=Time.get_ticks_usec()
		terrain.resource_stream._step_projections(began+2000)
		maximum_ms=maxf(maximum_ms,(Time.get_ticks_usec()-began)/1000.0)
		steps+=1
	check(steps<1000 and node.art.visible,"bounded jobs eventually publish complete overlay")
	check(JSON.parse_string(JSON.stringify(fingerprint(node)))==expected.initial,"vertices, normals, UVs, materials and triangle order match original projector")
	check(hash(collider.shape.get_faces())==collision_hash,"decoration never replaces authoritative collision")
	node.reproject()
	terrain.resource_stream._step_projections(Time.get_ticks_usec()+2000)
	terrain.cut=true
	node.refresh_surface()
	check(terrain.resource_stream._projection_pending.size()==1 and not node.art.visible,"terrain edit replaces/coalesces unfinished job")
	steps=0
	while not terrain.resource_stream._projection_pending.is_empty() and steps<1000:
		terrain.resource_stream._step_projections(Time.get_ticks_usec()+2000)
		steps+=1
	check(steps<1000 and JSON.parse_string(JSON.stringify(fingerprint(node)))==expected.cut,"edited hole publishes only current support, matching original")
	check(node.remaining_units==12 and node.drive_progress==2,"projection preserves finite stock and partial work")
	node.reproject()
	nodes.remove_child(node)
	node.free()
	terrain.resource_stream._step_projections(Time.get_ticks_usec()+2000)
	check(terrain.resource_stream._projection_pending.is_empty(),"retired resource cancels its weak queued job")
	print("PLAY01_SEAM %d checks, %d failures; largest observed slot %.3f ms"%[checks,failures,maximum_ms])
	quit(0 if failures==0 else 1)
