extends "res://scripts/resource_node.gd"
## C1 copied-game presentation only. Native work, bodies, fall, payout and saves stay inherited.
const Presenter=preload("res://c1/present.gd")
var presenter:=Presenter.new()
var models:Dictionary={}
var current_art:=""
func _apply_visual()->void:
	super._apply_visual()
	var pivot:MeshInstance3D=get_node("MeshInstance3D");pivot.mesh=null;_own_materials.clear()
	var names:Array=["bog-oak-full","bog-oak-worked"] if visual==&"tree" else (["clay-24","clay-20","clay-16","clay-12","clay-8","clay-4"] if visual==&"clay_bank" else ["reed-24","reed-18","reed-12","reed-6"])
	for id:String in names:
		var model:Node3D=load("res://c1/assets/"+id+"-lod0.gltf").instantiate();pivot.add_child(model);models[id]=model;_own_materials.append_array(presenter.install(model,id,false,true))
	sync_art()
func sync_art()->void:
	if models.is_empty():return
	current_art=("bog-oak-worked" if drive_progress>0 or remaining_units<=0 else "bog-oak-full") if visual==&"tree" else (("clay-"+str(maxi(4,remaining_units))) if visual==&"clay_bank" else "reed-"+str(maxi(6,remaining_units)))
	for id:String in models:models[id].visible=id==current_art
func _process(delta:float)->void:
	super._process(delta);sync_art();presenter.tick(delta)
	for m:ShaderMaterial in _own_materials:m.set_shader_parameter("clock_seconds",presenter.clock_seconds)
func _refresh_state_look()->void:super._refresh_state_look();sync_art()
func work(sim:WroughtwildSim)->Dictionary:
	var result:=super.work(sim);sync_art();return result
func harvest()->int:
	var result:=super.harvest();sync_art();return result
func leave_art(id:String)->void:
	var obj:Node3D=load("res://c1/assets/"+id+"-lod0.gltf").instantiate();get_parent().add_child(obj);obj.global_position=global_position;obj.rotation.y=_yaw if visual==&"tree" else 0
	presenter.install(obj,id);obj.add_to_group("c1_session_aftermath")
func _leave_stump()->void:leave_art("bog-oak-stump")
func _leave_habitat_remnant()->void:leave_art("clay-0" if visual==&"clay_bank" else "reed-0")
