extends SceneTree
const IDS=["iron_vein","copper_vein","tin_vein","ember_iron_vein","silver_vein"]
func _initialize()->void:
	call_deferred("run")
func run()->void:
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	var rows:Array=[]
	for id in IDS:
		var n:ResourceNode=load("res://scenes/resource_node.tscn").instantiate()
		n.visual=defs[id].visual;n.material_family=defs[id].material_family;n.remaining_units=defs[id].units;n.units_per_harvest=defs[id].units_per_harvest;n.heat_to_work=defs[id].get("heat_to_work",0);root.add_child(n)
		var c:CollisionShape3D=n.get_node("CollisionShape3D")
		rows.append({"id":id,"definition":defs[id],"fallback_size":var_to_str(c.shape.size),"fallback_center":var_to_str(c.position),"fallback_yaw":n.get_node("MeshInstance3D").rotation.y,"tool":String(n.tool_item),"presses":n.drive_presses,"cold_workable":n.workable()})
		n.free()
	var terrain:=Terrain.new();terrain.faceted_surface=true;terrain.weathered=true;terrain.frontier_look=load("res://art/weathered_look.tres");terrain.map={"cell_size":1.0};root.add_child(terrain);terrain.set_process(false)
	var chunk:=Node3D.new();terrain.add_child(chunk);terrain.chunks["0_0"]=chunk
	chunk.set_meta("surface_sampler",SurfaceSampler.new(PackedVector3Array([Vector3(0,0,0),Vector3(16,0,16),Vector3(0,0,16),Vector3(0,0,0),Vector3(16,0,0),Vector3(16,0,16)]),1.0))
	terrain.nodes_root=Node3D.new();terrain.add_child(terrain.nodes_root)
	for row in rows:
		var n:ResourceNode=load("res://scenes/resource_node.tscn").instantiate();n.visual=row.definition.visual;n.position=Vector3(8,0,8);terrain.nodes_root.add_child(n)
		var mesh:Mesh=n.get_node("MeshInstance3D").mesh;var box:=mesh.get_aabb()
		row["grounded_bounds"]={"position":var_to_str(box.position),"size":var_to_str(box.size)}
		row["grounded_triangles"]=mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()/3
		row["grounded_collider_points"]=n.get_node("CollisionShape3D").shape.get_faces().size()
		n.free()
	var f:=FileAccess.open("res://c5/native-envelopes.json",FileAccess.WRITE);f.store_string(JSON.stringify({"rows":rows,"seam_steps":terrain.frontier_look.seam_steps,"half_width":terrain.frontier_look.seam_half_width,"lift":terrain.frontier_look.seam_surface_lift,"finding":"Grounded ores have a zero-thickness terrain ribbon collider, not a solid boulder body. Solid sources are fallback/source candidates; do not install a protruding rock into the ordinary ribbon without a separate fit decision."},"\t"));terrain.free();print("C5_NATIVE_ENVELOPES_OK");quit()
