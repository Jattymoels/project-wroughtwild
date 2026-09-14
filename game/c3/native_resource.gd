extends "res://scripts/resource_node.gd"
## Presentation-only C3 adapter; unchanged ResourceNode owns work, body and clock.
const View=preload("res://c3/asset_view.gd")
var c3_state:=-1
var c3_model:Node3D
var c3_clock:=0.0
var altered:=false
func _apply_visual()->void:
	super._apply_visual()
	var pivot:MeshInstance3D=get_node("MeshInstance3D")
	pivot.mesh=null;pivot.material_override=null
	_sync_art()
func _sync_art()->void:
	var state:=24 if _is_tree() else remaining_units
	if state==c3_state:return
	c3_state=state
	# Native depletion owns the final .3 s shrink and removal. Keep the last
	# worked mesh alive during that animation instead of clearing it early.
	if state<=0:return
	if is_instance_valid(c3_model):c3_model.queue_free()
	var key:String=("resinheart-altered" if altered else "resinheart")+"-lod0" if _is_tree() else "corkbark-"+str(state)+"-lod0"
	c3_model=View.model(key,"res://c3/");get_node("MeshInstance3D").add_child(c3_model)
	_own_materials.clear()
	for mesh in c3_model.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():_own_materials.append(mesh.get_surface_override_material(surface))
	_refresh_state_look()
func _refresh_wedge_look()->void:
	super._refresh_wedge_look()
	# SaveManager's existing presentation callback also restores peeled sleeves.
	_sync_art()
func _process(delta:float)->void:
	super._process(delta)
	_sync_art()
	if not get_tree().paused:c3_clock+=delta;View.set_time(c3_clock)
func _leave_stump()->void:
	if get_parent()==null:return
	var stump:=View.model("resinheart-stump","res://c3/")
	get_parent().add_child(stump);stump.global_position=global_position;stump.rotation.y=_yaw;stump.add_to_group("c3_session_stumps")
func _leave_habitat_remnant()->void:
	if get_parent()==null:return
	var remnant:=View.model("corkbark-6-lod0","res://c3/")
	remnant.name="HarvestAftermath";remnant.scale=Vector3(.92,.08,.92)
	get_parent().add_child(remnant);remnant.global_position=global_position
	remnant.add_to_group("c3_session_bark_remnants")
