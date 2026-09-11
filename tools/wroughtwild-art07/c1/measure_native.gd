extends SceneTree
func _initialize()->void:call_deferred("measure")
func measure()->void:
	var result:Dictionary={}
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for id in ["bog_oak","clay_bank","reed_bed"]:
		var n:ResourceNode=load("res://scenes/resource_node.tscn").instantiate()
		for p in ["visual","material_family","units_per_harvest","drive_presses"]:n.set(p,defs[id][p])
		n.remaining_units=defs[id].units;n.resource_id=id;root.add_child(n)
		var body:CollisionShape3D=n.get_node("CollisionShape3D")
		result[id]={"shape":var_to_str(body.shape.size),"center":var_to_str(body.position),"units":n.remaining_units,"per_release":n.units_per_harvest,"presses":n.drive_presses,"visual":n.visual,"mesh_bounds":var_to_str(n.get_node("MeshInstance3D").mesh.get_aabb())}
		n.queue_free()
	var f:=FileAccess.open("res://c1/native-contracts.json",FileAccess.WRITE);f.store_string(JSON.stringify(result,"\t"));f.close();print("C1_NATIVE_CONTRACTS ",JSON.stringify(result));quit()
