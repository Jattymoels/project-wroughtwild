extends RefCounted
## Visual adapter installed only into the frozen F2 review copy.
const ROOT := "res://f2/assets/"
static func scene(file: String) -> Node3D:
	return (load(ROOT+file) as PackedScene).instantiate()
static func fixture(kind: String) -> Node3D:
	var imported:=scene({"cargo_winch":"winch.glb","winch_landing":"landing.glb","cargo_basket":"basket.glb"}[kind])
	# Godot adds a GLB scene wrapper. Preserve the authored local origin and
	# expose Drum as the immediate child expected by unchanged ContraptionSite.
	var authored:=imported.get_child(0) as Node3D
	imported.remove_child(authored);imported.free()
	# Blender disambiguates the second static body as Housing001. The native
	# placement contract names the real nonempty static mesh Housing.
	var housing:=authored.find_child("Housing*",true,false)
	if housing!=null:housing.name="Housing"
	return authored
static func attach_source(node: ResourceNode) -> void:
	var old := node.get_node_or_null("StrangeCore")
	if old != null: old.hide()
	var source := scene("thrumroot-near.glb")
	source.name="F2Source"
	for child in source.find_children("*","MeshInstance3D",true,false):
		var m:=ShaderMaterial.new();m.shader=preload("res://f2/source.gdshader");m.set_shader_parameter("albedo_tex",load(ROOT+"thrumroot-albedo.png"));child.material_override=m
	node.add_child(source)
	source.set_meta("authority","ResourceNode remaining_units and drive_progress; no item owner")
static func source_state(node: ResourceNode, depleted: bool) -> void:
	var source := node.get_node_or_null("F2Source") as Node3D
	if source == null: return
	source.visible = not depleted and node.remaining_units>0
	# Pose is stable on reload, derived solely from work already accepted.
	for child in source.find_children("*","MeshInstance3D",true,false):
		child.material_override.set_shader_parameter("work_level",float(node.drive_progress)/float(maxi(node.drive_presses,1)))
		child.material_override.set_shader_parameter("emission_off",node.has_meta("emission_off"))
static func energy(root: Node3D, winding: float, phase: float, travelling: bool=false) -> void:
	for child in root.find_children("*","MeshInstance3D",true,false):
		var mesh := child as MeshInstance3D
		for i in mesh.mesh.get_surface_count():
			var m := mesh.get_active_material(i)
			if m is StandardMaterial3D and ("incision" in m.resource_name.to_lower() or "living" in m.resource_name.to_lower()):
				if not mesh.has_meta("f2_material_%d"%i):
					var shader:=ShaderMaterial.new();shader.shader=preload("res://f2/energy.gdshader");shader.set_shader_parameter("bark_colour",m.albedo_color)
					mesh.set_surface_override_material(i,shader);mesh.set_meta("f2_material_%d"%i,true)
			if mesh.has_meta("f2_material_%d"%i):
				var shader:=mesh.get_active_material(i) as ShaderMaterial
				shader.set_shader_parameter("winding",winding);shader.set_shader_parameter("paid_phase",phase);shader.set_shader_parameter("travelling",travelling);shader.set_shader_parameter("emission_off",root.has_meta("emission_off"))
