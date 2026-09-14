extends Node3D
## Reads panel identity and existing burn_left only. No save data or native writes.
var lid: Node3D
var fuel: MeshInstance3D
var ash: MeshInstance3D
var ember: ShaderMaterial
var fuel_surfaces: Array[ShaderMaterial] = []
var angle := 0.0
var fraction := 0.0
var visual_state := "closed"
func add_part(id: String, parent: Node3D = self) -> MeshInstance3D:
	var m := MeshInstance3D.new()
	m.name = id
	m.mesh = E3HomeArt.part(id)
	parent.add_child(m)
	return m
func bind() -> void:
	var b := get_parent() as PlacedBlock
	var f := String(b.material_family)
	if b.is_chest():
		add_part("chest_"+f+"_body")
		lid = Node3D.new()
		lid.name = "Hinge"
		add_child(lid)
		var p: Array = E3HomeArt.look().lid_pivot_godot
		lid.position = Vector3(p[0],p[1],p[2])
		add_part("chest_"+f+"_lid",lid).position = -lid.position
	else:
		fuel = add_part("fire_"+f+"_fuel")
		ash = add_part("fire_"+f+"_ash")
		var e := add_part("fire_"+f+"_embers")
		ember = ShaderMaterial.new()
		ember.shader = preload("res://e3/ember.gdshader")
		ember.set_shader_parameter("gain",E3HomeArt.look().ember_gain)
		e.material_override = ember
		for i in fuel.mesh.get_surface_count():
			var original := fuel.mesh.surface_get_material(i) as StandardMaterial3D
			var m := ShaderMaterial.new()
			m.shader = preload("res://e3/fuel.gdshader")
			m.set_shader_parameter("albedo_map",original.albedo_texture)
			m.set_shader_parameter("normal_map",original.normal_texture)
			m.set_shader_parameter("orm_map",original.roughness_texture)
			m.set_shader_parameter("normal_strength",E3HomeArt.look().normal_strength)
			fuel.set_surface_override_material(i,m)
			fuel_surfaces.append(m)
	_process(0)
func _process(delta: float) -> void:
	if get_tree().paused: return
	var b := get_parent() as PlacedBlock
	if b.is_chest():
		var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
		var opened := player != null and player.chest_panel != null and player.chest_panel.is_open() and player.chest_panel.chest == b
		var target := -deg_to_rad(float(E3HomeArt.look().lid_angle_degrees)) if opened else 0.0
		angle = move_toward(angle,target,float(E3HomeArt.look().lid_speed_radians)*delta)
		lid.rotation.x = angle
		visual_state = "open" if opened else "closed"
	else:
		var duration := float(b._fire_rules().fuels[String(b.material_family)].burn_seconds)
		fraction = clampf(b.burn_left/duration,0,1)
		var burned := 1.0-fraction
		for m in fuel_surfaces: m.set_shader_parameter("burned",burned)
		ember.set_shader_parameter("remaining",fraction)
		ember.set_shader_parameter("native_seconds",duration-b.burn_left)
		ember.set_shader_parameter("heat",float(b.fire_heat))
		ash.visible = fraction > 0 and burned >= float(E3HomeArt.look().ash_start_fraction)
		visual_state = "spent" if fraction <= 0 else ("ash / dwindling fuel" if ash.visible else "burning")
