extends Node3D
## F1 presentation only. Every stock, payment and request belongs to native state.
const ASSETS := "res://f1/assets/"
const SCAR := preload("res://f1/scar.gdshader")
static var LOOK: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://f1/settings.json")).state_presentation
var kind := ""
var key := ""
var rules: WroughtwildSim
var materials: Array[ShaderMaterial] = []
var previous: Dictionary = {}
var event_left := 0.0
var event_phase := 0.0
var lamp_on := false
var work_fraction := 0.0
var stock_fraction := 1.0
var lod := "near"

static func fitted(kind_id: String) -> Node3D:
	var root := load("res://f1/visuals.gd").new() as Node3D
	root.kind = kind_id
	root.name = "StrangeFixtureVisual"
	var imported := (load(ASSETS+kind_id+".glb") as PackedScene).instantiate()
	root.add_child(imported)
	for name_id: String in ["Housing","Heart","Lever","Resonator"]:
		var part := imported.find_child(name_id+"*",true,false)
		if part != null:
			part.owner = null
			part.get_parent().remove_child(part)
			root.add_child(part)
			part.name = name_id
	root._bind_materials(root)
	if kind_id == "lantern_lamp": StrangeResourceArt._light(root)
	return root

static func attach_source(node: ResourceNode) -> void:
	var existing := node.get_node_or_null("StrangeCore")
	if existing != null: existing.free()
	var root := load("res://f1/visuals.gd").new() as Node3D
	root.name = "StrangeCore"
	root.kind = String(node.visual)
	node.add_child(root)
	(node.get_node("MeshInstance3D") as Node3D).hide()
	var core := Node3D.new()
	core.name = "Core"
	root.add_child(core)
	for level: String in ["near","middle","far"]:
		var mesh := (load(ASSETS+root.kind+"_"+level+".glb") as PackedScene).instantiate() as Node3D
		mesh.name = level
		mesh.position.y = .12 if root.kind=="lanternheart" else .28
		if root.kind=="stormglass": mesh.rotation.z = -.7
		core.add_child(mesh)
		root._bind_materials(mesh)
		mesh.visible = level=="near"
	for mat in root.materials: node._own_materials.append(mat)
	var shape := BoxShape3D.new()
	shape.size = StrangeResourceArt.bounds_for(node.visual)
	var collision := node.get_node("CollisionShape3D") as CollisionShape3D
	collision.shape=shape
	collision.position.y=shape.size.y*.5
	if root.kind=="lanternheart": StrangeResourceArt._light(root)
	root.source_state(node,float(node.drive_progress)/maxi(node.drive_presses,1),false)

static func recovered(pickup: Pickup) -> void:
	if pickup.kind!="material" or pickup.family not in ["lanternheart","stormglass"]: return
	pickup._mesh.hide()
	var root := load("res://f1/visuals.gd").new() as Node3D
	root.name="RecoveredCore"
	root.kind=pickup.family
	root.set_meta("source_geometry",pickup.family+"_near.glb")
	var core := (load(ASSETS+pickup.family+"_near.glb") as PackedScene).instantiate() as Node3D
	if pickup.family=="stormglass": core.position.y=.08
	root.add_child(core)
	root._bind_materials(core)
	pickup.add_child(root)

func _ready() -> void:
	if get_parent() is ContraptionSite:
		var site := get_parent() as ContraptionSite
		key=site.machine_key
		rules=site.sim
		apply_state(rules.contraption_state(key),false)

func _bind_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mi := node as MeshInstance3D
		for i in mi.mesh.get_surface_count():
			var original := mi.get_active_material(i) as StandardMaterial3D
			if original==null: continue
			if "_skin" in original.resource_name and original.albedo_texture!=null:
				var mat := ShaderMaterial.new()
				mat.shader=SCAR
				mat.set_shader_parameter("albedo_map",original.albedo_texture)
				mat.set_shader_parameter("orm_map",original.roughness_texture)
				mat.set_shader_parameter("energy_colour",Vector3(1,.56,.16) if "lantern" in kind else Vector3(.72,.84,1))
				mi.set_surface_override_material(i,mat)
				materials.append(mat)
			else:
				# COLOR_0 stores linear scar masks, never display RGB (including the bore).
				var plain := original.duplicate() as StandardMaterial3D
				plain.vertex_color_use_as_albedo=false
				if "_skin" in original.resource_name:
					var c: Array = LOOK.bore_colour
					plain.albedo_color=Color(c[0],c[1],c[2])
					plain.emission_enabled=false
				plain.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
				mi.set_surface_override_material(i,plain)
	for child in node.get_children(): _bind_materials(child)

func apply_state(state: Dictionary, event: bool = true) -> void:
	if state.is_empty(): return
	lamp_on=kind=="lantern_lamp" and bool(state.get("lamp_on",true))
	if kind=="stormglass_lever" and event and not previous.is_empty() and int(state.pulses)>int(previous.pulses):
		event_left=ContraptionSite.LOOK.pulse_seconds
		event_phase=0
	previous=state.duplicate(true)
	_update_light()

func source_state(node: ResourceNode, progress: float, depleted: bool) -> void:
	stock_fraction=float(node.remaining_units)/maxi(node._initial_units,1)
	work_fraction=clampf(progress,0,1)
	var core := get_node("Core") as Node3D
	core.visible=not depleted and node.remaining_units>0
	if kind=="lanternheart":
		core.rotation.z=work_fraction*float(LOOK.heart_work_tilt_radians)
		core.position.y=work_fraction*float(LOOK.heart_work_lift_m)
	else: core.rotation.z=work_fraction*float(LOOK.tube_work_tilt_radians)
	var host := node.get_parent().get_node_or_null(kind+"_aftermath") as Node3D
	if host!=null and kind=="lanternheart":
		var opened := 1.0 if depleted else work_fraction
		host.scale=Vector3(1+opened*float(LOOK.husk_open_fraction),1,1+opened*float(LOOK.husk_open_fraction))
		host.set_meta("native_work_fraction",opened)
	var light := get_node_or_null("WarmInterior") as OmniLight3D
	if light!=null: light.visible=not depleted;light.light_energy=StrangeResourceArt.LOOK.heart_light_energy*stock_fraction
	_update_light()

func set_lod(level: String) -> void:
	assert(level in ["near","middle","far"])
	lod=level
	var core := get_node_or_null("Core")
	if core!=null:
		for child in core.get_children(): child.visible=child.name==level

func accepted_source_work() -> void:
	event_left=float(LOOK.source_work_seconds)
	event_phase=0

func _process(delta: float) -> void:
	if rules!=null and not key.is_empty(): apply_state(rules.contraption_state(key))
	if event_left>0: event_left=maxf(0,event_left-delta);event_phase+=delta
	if lamp_on or (kind=="lanternheart" and stock_fraction>0): event_phase+=delta*float(LOOK.heart_phase_rate)
	_update_light()

func _update_light() -> void:
	var strength := float(LOOK.lamp_emission) if lamp_on else float(LOOK.natural_heart_emission)*stock_fraction if kind=="lanternheart" else 0.0
	if kind=="stormglass_lever" and event_left>0: strength=float(LOOK.request_emission)*sin(clampf(event_left/ContraptionSite.LOOK.pulse_seconds,0,1)*PI)
	if kind=="stormglass" and event_left>0: strength=float(LOOK.source_work_emission)*sin(clampf(event_left/float(LOOK.source_work_seconds),0,1)*PI)
	for mat in materials:
		mat.set_shader_parameter("work",strength)
		mat.set_shader_parameter("phase",event_phase)
