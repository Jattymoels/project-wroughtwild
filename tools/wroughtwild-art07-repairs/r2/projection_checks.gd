extends "res://b3/native_review.gd"
## Differential oracle: unchanged G1 projection versus R2 on the same surfaces.
const Reference=preload("res://r2/reference_b3.gd")
func surface_contacts()->void:
	super.surface_contacts()
	var terrain:=Terrain.new();terrain.faceted_surface=true;terrain.weathered=true;terrain.frontier_look=load("res://art/weathered_look.tres");terrain.map={"cell_size":1.0};add_child(terrain);terrain.set_process(false)
	var chunk:=Node3D.new();terrain.add_child(chunk);terrain.chunks["0_0"]=chunk
	terrain.nodes_root=Node3D.new();terrain.add_child(terrain.nodes_root)
	var original:ResourceNode
	var candidate:ResourceNode
	for script in [Reference,load("res://b3/native_resource.gd")]:
		var node:ResourceNode=load("res://scenes/resource_node.tscn").instantiate();node.set_script(script)
		node.visual=&"seam";node.remaining_units=12;node.units_per_harvest=2;node.tool_item=&"timber_wedge";node.drive_presses=4;node.position=Vector3(8,0,8);node.resource_id="r2-exact-seam"
		chunk.set_meta("surface_sampler",SurfaceSampler.new(surface_faces(false),1.0))
		terrain.nodes_root.add_child(node)
		if original==null:original=node
		else:candidate=node
	for phase in [false,true,false,true,false]:
		chunk.set_meta("surface_sampler",SurfaceSampler.new(surface_faces(phase),1.0))
		original.refresh_surface();candidate.refresh_surface()
		var a:Array=original.art.find_children("*","MeshInstance3D",true,false)
		var b:Array=candidate.art.find_children("*","MeshInstance3D",true,false)
		check(a.size()==b.size(),"R2 exact mesh-instance count after surface replacement")
		for i in a.size():
			check(a[i].transform==b[i].transform and a[i].visible==b[i].visible,"R2 exact pose/support visibility")
			check(a[i].mesh.get_surface_count()==b[i].mesh.get_surface_count(),"R2 exact supported surface count")
			for s in a[i].mesh.get_surface_count():
				check(a[i].mesh.surface_get_arrays(s)==b[i].mesh.surface_get_arrays(s),"R2 all vertex/normal/UV/index arrays exactly equal to unchanged G1")
		var original_body:CollisionShape3D=original.get_node("CollisionShape3D")
		var candidate_body:CollisionShape3D=candidate.get_node("CollisionShape3D")
		check(original_body.shape is ConcavePolygonShape3D and candidate_body.shape is ConcavePolygonShape3D,"R2 actual grounded seam uses native triangle picking in both versions")
		check(original_body.shape.get_faces()==candidate_body.shape.get_faces() and original_body.transform==candidate_body.transform and original_body.disabled==candidate_body.disabled and original.collision_layer==candidate.collision_layer and original.collision_mask==candidate.collision_mask,"R2 exact native grounded picking faces, pose, enabled state and masks")
	terrain.free()
