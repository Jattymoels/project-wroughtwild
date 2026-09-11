extends "res://scripts/resource_node.gd"
## Copied-game-only presentation. Original native work, positions, body, timing and saves are inherited.
var art:Node3D
var stages:Array=[]
func _process(delta:float)->void:super._process(delta);sync_state()
func _refresh_wedge_look()->void:super._refresh_wedge_look();sync_state()
func _apply_visual()->void:
	super._apply_visual()
	if visual not in [&"slate_seam",&"shellstone_seam"]:return
	var pivot:MeshInstance3D=get_node("MeshInstance3D");pivot.mesh=null;pivot.material_override=null
	art=Node3D.new();art.name="C2 quarry candidate";pivot.add_child(art)
	var family:="slate" if visual==&"slate_seam" else "shellstone";var variant:=posmod(_visual_seed(),2)
	for state in ["full","worked","last"]:
		var model:Node3D=load("res://c2/assets/%s-v%d-%s-lod0.gltf"%[family,variant,state]).instantiate();art.add_child(model);stages.append(model)
		for mesh in model.find_children("*","MeshInstance3D",true,false):
			for s in mesh.mesh.get_surface_count():
				var mat:StandardMaterial3D=mesh.mesh.surface_get_material(s).duplicate();mat.emission_enabled=true;mat.emission_energy_multiplier=0;mesh.set_surface_override_material(s,mat);_own_materials.append(mat)
	sync_state()
func sync_state()->void:
	if stages.is_empty():return
	var state:=0 if remaining_units==24 else (1 if remaining_units>4 else 2)
	for i in stages.size():stages[i].visible=i==state
func _refresh_state_look()->void:super._refresh_state_look();sync_state()
func harvest()->int:
	var result:=super.harvest();sync_state();return result
func _leave_habitat_remnant()->void:
	if stages.is_empty():super._leave_habitat_remnant();return
	var remnant:Node3D=stages[2].duplicate();remnant.name="HarvestAftermath";remnant.visible=true;remnant.scale=Vector3(.92,.08,.92);get_parent().add_child(remnant);remnant.global_position=global_position;remnant.add_to_group("c2_aftermath")
	# Same session-only inert remnant as native HabitatResourceArt, never a new resource/save record.
