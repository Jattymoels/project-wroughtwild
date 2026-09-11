extends "res://scripts/resource_node.gd"
## Posed wastes-biome fixture. All work, stock, collision sizes and clocks inherited.
var source_kind:="ash-a"
func _biome_id()->String:
	return "ember_wastes"
func _apply_visual()->void:
	super._apply_visual()
	var pivot:MeshInstance3D=get_node("MeshInstance3D")
	pivot.mesh=null
	var model:Node3D=load("res://c4/assets/"+source_kind+"-lod0.gltf").instantiate()
	pivot.add_child(model)
	# The exported source already fits; no runtime squeeze or collider enlargement.
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for s in mesh.mesh.get_surface_count():
			var material:StandardMaterial3D=mesh.mesh.surface_get_material(s).duplicate()
			material.emission_enabled=true;material.emission_energy_multiplier=0
			mesh.set_surface_override_material(s,material);_own_materials.append(material)
func _leave_stump()->void:
	if get_parent()==null:return
	var stump:Node3D=load("res://c4/assets/ash-stump-lod0.gltf").instantiate()
	get_parent().add_child(stump);stump.global_position=global_position;stump.rotation.y=_yaw
	stump.add_to_group("c4_session_stumps")
