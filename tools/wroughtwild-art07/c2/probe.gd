extends SceneTree
func _initialize()->void:call_deferred("run")
func run()->void:
	var rows:Array=[]
	var defs:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://../data/tuning/worldgen.json")).nodes
	for id in ["slate_outcrop","shellstone_outcrop"]:
		var n:ResourceNode=load("res://scenes/resource_node.tscn").instantiate()
		for key in ["visual","material_family","units_per_harvest","drive_presses"]:n.set(key,defs[id][key])
		n.remaining_units=defs[id].units;root.add_child(n)
		var body:CollisionShape3D=n.get_node("CollisionShape3D");var m:MeshInstance3D=n.get_node("MeshInstance3D")
		assert(body.shape.size==Vector3(2,.58,1.15));assert(body.position==Vector3(0,.29,0));assert(m.rotation==Vector3.ZERO)
		rows.append({"id":id,"body_size_m":[body.shape.size.x,body.shape.size.y,body.shape.size.z],"body_centre_m":[body.position.x,body.position.y,body.position.z],"stock":n.remaining_units,"per_release":n.units_per_harvest,"presses":n.drive_presses,"mesh_aabb":str(m.mesh.get_aabb()),"visual_transform":str(m.transform),"work_target":n.collision_layer})
		n.free()
	var f:=FileAccess.open("res://probe.json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"\t"));print("C2_NATIVE_ENVELOPES_OK ",JSON.stringify(rows));quit()
