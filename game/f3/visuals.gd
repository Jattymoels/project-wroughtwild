extends Node3D
## F3 isolated presentation adapter. Native calls own all payment/stock/work.
const ASSETS := "res://f3/assets/"
const SCAR := preload("res://f3/scar.gdshader")
var kind := ""
var key := ""
var rules: WroughtwildSim
var materials: Array[ShaderMaterial] = []
var previous: Dictionary = {}
var event_left := 0.0
var event_phase := 0.0
var membrane: Node3D
var platen: Node3D
var piles: Dictionary = {}
var stock_fraction := 1.0
var work_fraction := 0.0
var lod := "near"

static func fitted(kind_id: String) -> Node3D:
	var root := load("res://f3/visuals.gd").new() as Node3D
	root.kind = kind_id
	root.name = "StrangeFixtureVisual"
	var imported := (load(ASSETS+kind_id+".glb") as PackedScene).instantiate()
	root.add_child(imported)
	var housing := imported.find_child("Housing*",true,false)
	if housing != null: housing.name = "Housing"
	root.membrane = imported.find_child("Membrane*",true,false)
	root.platen = imported.find_child("Platen*",true,false)
	root._bind_materials(imported)
	if kind_id == "magnetic_sorter": root._make_piles()
	return root

static func attach_source(node: ResourceNode) -> void:
	var existing := node.get_node_or_null("StrangeCore")
	if existing != null: existing.free()
	var root := load("res://f3/visuals.gd").new() as Node3D
	root.name = "StrangeCore"
	root.kind = String(node.visual)
	node.add_child(root)
	(node.get_node("MeshInstance3D") as Node3D).hide()
	# Only the finite core belongs to the ResourceNode. Site shell is separate.
	var core := Node3D.new()
	core.name = "Core"
	root.add_child(core)
	for level: String in ["near","middle","far"]:
		var mesh := (load(ASSETS+root.kind+"_"+level+".glb") as PackedScene).instantiate() as Node3D
		mesh.name = level
		if root.kind == "pullstone":
			mesh.scale = Vector3.ONE*.70
			mesh.position = Vector3(0,.16,.08)
		else:
			mesh.scale = Vector3.ONE*.87
			mesh.position.y = .19
		core.add_child(mesh)
		root._bind_materials(mesh)
		mesh.visible = level == "near"
	for mat in root.materials: node._own_materials.append(mat)
	var shape := BoxShape3D.new()
	shape.size = StrangeResourceArt.bounds_for(node.visual)
	var collision := node.get_node("CollisionShape3D") as CollisionShape3D
	collision.shape = shape
	collision.position.y = shape.size.y*.5
	root.previous = {"source_initial":true}
	root.source_state(node, float(node.drive_progress)/maxi(node.drive_presses,1), false)

func _ready() -> void:
	if get_parent() is ContraptionSite:
		var site := get_parent() as ContraptionSite
		key = site.machine_key
		rules = site.sim
		apply_state(rules.contraption_state(key), false)

func _bind_materials(node: Node) -> void:
	if node is MeshInstance3D:
		var mesh := node as MeshInstance3D
		for i in mesh.mesh.get_surface_count():
			var original := mesh.get_active_material(i) as StandardMaterial3D
			if original == null: continue
			if "_skin" in original.resource_name and original.albedo_texture != null:
				var mat := ShaderMaterial.new()
				mat.shader = SCAR
				mat.set_shader_parameter("albedo_map",original.albedo_texture)
				mat.set_shader_parameter("orm_map",original.roughness_texture)
				mesh.set_surface_override_material(i,mat)
				materials.append(mat)
			else:
				original.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	for child in node.get_children(): _bind_materials(child)

func _make_piles() -> void:
	for port: String in ["input","ferrous","remainder"]:
		var pile := Node3D.new()
		pile.name = port.capitalize()+"Contents"
		pile.position = {"input":Vector3(0,1.06,-.13),"ferrous":Vector3(-.4,.30,.15),"remainder":Vector3(.4,.30,.15)}[port]
		add_child(pile)
		for i in 8:
			var chip := MeshInstance3D.new()
			var geometry := BoxMesh.new()
			geometry.size = Vector3(.072,.055,.071)
			chip.mesh = geometry
			chip.position = Vector3((i%3-1)*.078,(i/3)*.032,(i%2-.5)*.065)
			chip.rotation = Vector3(i*.24,i*.72,i*.18)
			var mat := StandardMaterial3D.new()
			mat.albedo_color = Color("626867") if port == "ferrous" else Color("aa916b")
			mat.metallic = .55 if port == "ferrous" else 0.0
			mat.roughness = .8
			chip.material_override = mat
			pile.add_child(chip)
		piles[port] = pile

func units(items: Dictionary) -> int:
	var total := 0
	for count in items.values(): total += int(count)
	return total

func apply_state(state: Dictionary, event: bool = true) -> void:
	if state.is_empty(): return
	if kind == "magnetic_sorter":
		for port: String in piles:
			var count := units(state.get(port,{}))
			var pile := piles[port] as Node3D
			pile.set_meta("native_units",count)
			for i in pile.get_child_count(): pile.get_child(i).visible = i < mini(count,8)
		if event and not previous.is_empty():
			var moved := units(state.ferrous)+units(state.remainder)-units(previous.get("ferrous",{}))-units(previous.get("remainder",{}))
			if moved > 0: event_left = .7; event_phase = 0.0
	elif kind == "ventlung_bellows":
		var fraction := float(state.get("energy",0))/maxf(1,float(rules.contraption_config().energy_capacity if rules != null else 4))
		if membrane != null:
			membrane.scale.y = lerpf(.40,.52,fraction)
		if platen != null:
			platen.position.y = .22+.96*lerpf(.40,.52,fraction)+.025
		if event and not previous.is_empty() and state.get("energy",0) != previous.get("energy",0): event_left = .4; event_phase = 0.0
	previous = state.duplicate(true)
	_update_light()

func source_state(node: ResourceNode, progress: float, depleted: bool) -> void:
	stock_fraction = float(node.remaining_units)/maxi(node._initial_units,1)
	work_fraction = clampf(progress,0,1)
	var core := get_node("Core") as Node3D
	core.visible = not depleted and node.remaining_units > 0
	if kind == "pullstone": core.rotation.z = -work_fraction*.12; core.position.y = work_fraction*.09
	if kind == "ventlung": core.scale = Vector3(1.0-work_fraction*.16,1.0-work_fraction*.3,1.0-work_fraction*.16)
	# A refresh describes partial work only; it never starts a success event.
	_update_light()

func set_lod(level: String) -> void:
	assert(level in ["near","middle","far"])
	lod = level
	var core := get_node_or_null("Core")
	if core != null:
		for child in core.get_children(): child.visible = child.name == level

func accepted_source_work() -> void:
	event_left = .7
	event_phase = 0.0

func _process(delta: float) -> void:
	if rules != null and not key.is_empty(): apply_state(rules.contraption_state(key))
	if event_left > 0:
		event_left = maxf(0,event_left-delta)
		event_phase += delta
	_update_light()

func _update_light() -> void:
	var strength := 0.0
	if kind in ["pullstone","ventlung"]: strength = .18*work_fraction*stock_fraction
	if event_left > 0: strength = .9*sin(clampf(event_left/.7,0,1)*PI)
	for mat in materials:
		mat.set_shader_parameter("work",strength)
		mat.set_shader_parameter("phase",event_phase)
