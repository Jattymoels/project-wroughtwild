extends "res://scripts/resource_node.gd"
## R1 presentation only. Native work, stock, collision, heights and fall inherited.
var source_kind:="broadleaf"
var art_burial:=0.0
static var _controls:Dictionary={}
static var _models:Dictionary={}
func _apply_visual()->void:
	super._apply_visual()
	# The selected V10 Gallery assembly already supplies its own solid-wood
	# contact and mesh. Do not erase it with the earlier broadleaf replacement.
	if _terrain()!=null and _terrain().world_profile() in ["frontier_v10","frontier_v11","frontier_v12","frontier_v13"] and _biome_id()=="gallery_woodland":return
	var pivot:MeshInstance3D=get_node("MeshInstance3D")
	pivot.mesh=null
	if _controls.is_empty():
		_controls=JSON.parse_string(FileAccess.get_file_as_string("res://r1/settings.json"))
	var controls:Dictionary=_controls
	var model_path:="res://r1/assets/%s-a-lod%d.glb"%[source_kind,int(controls.runtime_lod)]
	if not _models.has(model_path):
		_models[model_path]=load(model_path)
	var model:Node3D=_models[model_path].instantiate()
	art_burial=controls.burial_m[source_kind]
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var material:StandardMaterial3D=mesh.mesh.surface_get_material(surface).duplicate()
			material.cull_mode=BaseMaterial3D.CULL_DISABLED
			mesh.set_surface_override_material(surface,material)
	model.position.y=-art_burial
	pivot.add_child(model)
	set_meta("b1_fit",{"native_body":get_node("CollisionShape3D").shape.size,"horizontal_scale":1.0,"vertical_scale":1.0,"burial_m":art_burial,"r1_lower_radius_m":controls.lower_radius_m,"source_walk_height_radius":controls.lower_radius_m})
	set_meta("r1_canopy",true)
func _leave_stump()->void:
	if _terrain()!=null and _terrain().world_profile() in ["frontier_v10","frontier_v11","frontier_v12","frontier_v13"] and _biome_id()=="gallery_woodland":
		super._leave_stump()
		return
	if get_parent()==null:return
	var stump:Node3D=load("res://r1/assets/"+source_kind+"-stump.glb").instantiate()
	get_parent().add_child(stump)
	stump.global_position=global_position-Vector3.UP*art_burial
	stump.rotation.y=_yaw
	stump.add_to_group("b1_session_stumps")
