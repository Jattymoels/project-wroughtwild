extends "res://scripts/resource_node.gd"
## Task-local presentation adapter. Work, yields, depletion, collider and fall clock inherited unchanged.
var source_kind:="broadleaf"
var fit_xz:=1.0
var art_burial:=0.0
func _apply_visual()->void:
	super._apply_visual()
	var pivot:MeshInstance3D=get_node("MeshInstance3D")
	pivot.mesh=null
	var model:Node3D=load("res://b1/assets/"+source_kind+"-a-lod0.glb").instantiate()
	var controls:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://b1/kit.json"))
	art_burial=controls[source_kind].burial_m
	# Fit the walk-height trunk to the unchanged native 0.7 m body, preserving source masters.
	var radius:=0.0
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var vertices:PackedVector3Array=mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for point in vertices:
				if point.y-art_burial>=.6 and point.y-art_burial<=1.9:radius=maxf(radius,Vector2(point.x,point.z).length())
			var material:StandardMaterial3D=mesh.mesh.surface_get_material(surface).duplicate()
			material.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.set_surface_override_material(surface,material)
	assert(radius>0)
	fit_xz=.35/radius*.98
	model.scale=Vector3(fit_xz,1,fit_xz);model.position.y=-art_burial
	pivot.add_child(model)
	set_meta("b1_fit",{"native_body":get_node("CollisionShape3D").shape.size,"source_walk_height_radius":radius,"horizontal_scale":fit_xz,"vertical_scale":1.0,"burial_m":art_burial})

func _leave_stump()->void:
	if get_parent()==null:return
	var stump:Node3D=load("res://b1/assets/"+source_kind+"-stump.glb").instantiate()
	get_parent().add_child(stump);stump.global_position=global_position-Vector3.UP*art_burial;stump.rotation.y=_yaw;stump.scale=Vector3(fit_xz,1,fit_xz);stump.add_to_group("b1_session_stumps")
