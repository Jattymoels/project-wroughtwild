class_name F4Art
extends RefCounted
## Read-only projection. Native ContraptionSite owns its unchanged drum/bellows formula.
static var maps: Dictionary = {}
static var textures: Dictionary = {}
static var settings: Dictionary = {}
static var standards: Dictionary = {}
static var detail := "near"
static var emission_off := false

static func tex(record: Dictionary) -> Texture2D:
	var digest: String=record.sha256
	if not textures.has(digest): textures[digest]=load("res://f4/textures/"+digest+".png")
	return textures[digest]

static func visual(kind: String, level := "") -> Node3D:
	if level.is_empty():level=detail
	if maps.is_empty():maps=JSON.parse_string(FileAccess.get_file_as_string("res://f4/textures.json"))
	if settings.is_empty():settings=JSON.parse_string(FileAccess.get_file_as_string("res://f4/appearance.json"))
	var imported: Node3D=load("res://f4/assets/"+kind+"_"+level+".glb").instantiate()
	# glTF's scene wrapper is not a mechanism pivot.
	var root: Node3D=imported
	if imported.get_child_count()==1 and imported.get_child(0) is Node3D:
		root=imported.get_child(0);imported.remove_child(root);imported.free()
	root.name="F4Visual"
	if kind=="feeder":
		# Native placement inspection looks up this real structural mesh.
		for child in root.get_children():
			if child is MeshInstance3D:child.name="Part";break
	for child in root.get_children():
		# Blender adds .001 because its immutable donor still owns "Drum".
		# Godot sanitizes that suffix and nests glTF extras; preserve the role.
		if child is MeshInstance3D:continue
		for role in ["Drum","Bellows","Hopper","FuelCup","OutputTray","PressureMembrane","ConnectionAnchor"]:
			if String(child.name).begins_with(role):child.name=role;break
	_materials(root)
	return root

static func _materials(node: Node) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var original: Material=node.mesh.surface_get_material(i)
			var name: String=original.resource_name
			var skin := name.begins_with("f3_ventlung_skin")
			var root_skin := name.begins_with("Thrumroot living incision")
			var entries: Array=maps.get(name,[])
			if skin or root_skin:
				var shader:=ShaderMaterial.new();shader.shader=preload("res://f4/skin.gdshader")
				shader.set_shader_parameter("root_tissue",root_skin)
				for key in ["stored_glow","working_glow","wave_per_route"]:shader.set_shader_parameter(key,settings[key])
				for entry: Dictionary in entries:
					shader.set_shader_parameter("albedo_map" if entry.colorspace=="sRGB" else "orm_map",tex(entry))
				node.set_surface_override_material(i,shader)
			elif not entries.is_empty():
				if not standards.has(name):
					var m: StandardMaterial3D=original.duplicate()
					m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
					for entry: Dictionary in entries:
						if entry.colorspace=="sRGB":m.albedo_texture=tex(entry)
						elif "normal" in String(entry.image).to_lower():m.normal_enabled=true;m.normal_texture=tex(entry);m.normal_scale=float(settings.normal_strength)
						else:m.roughness_texture=tex(entry);m.roughness_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_GREEN;m.metallic_texture=tex(entry);m.metallic_texture_channel=BaseMaterial3D.TEXTURE_CHANNEL_BLUE
					if name.begins_with("D4 Timber"):
						var c: Array=settings.timber_tint;m.albedo_color=Color(c[0],c[1],c[2])
					standards[name]=m
				node.set_surface_override_material(i,standards[name])
	for child in node.get_children():_materials(child)

static func state(node: Node, stock: float, work: float, phase: float) -> void:
	if node is MeshInstance3D:
		for i in node.mesh.get_surface_count():
			var m: Material=node.get_surface_override_material(i)
			if m is ShaderMaterial:
				m.set_shader_parameter("stock",stock);m.set_shader_parameter("work",work);m.set_shader_parameter("phase",phase);m.set_shader_parameter("emission_off",emission_off)
	for child in node.get_children():state(child,stock,work,phase)

static func refresh_feeder(site: ContraptionSite, record: Dictionary, active: bool, paused: bool, progress: float) -> void:
	if not site._visual.has_meta("f4_loads"):
		for pair in [[site._hopper_load,"clay"],[site._fuel_load,"fuel"],[site._output_load,"bricks"]]:
			var packed: Node3D=load("res://f4/assets/load_"+pair[1]+".glb").instantiate()
			var mesh:=ArrayMesh.new();AuthoredAssets._collect(packed,Transform3D.IDENTITY,mesh);packed.free();pair[0].mesh=mesh
		site._visual.set_meta("f4_loads",true)
	var stock:=float(record.energy)/maxf(1,float(site.sim.contraption_config().energy_capacity))
	var work:=1.0 if active and not paused and not site.get_tree().paused else 0.0
	state(site._visual,stock,work,progress)
	site._visual.set_meta("native_phase",progress)
	site._visual.set_meta("working",work>0)

static func mount_pocket(pocket: PressurePocket) -> void:
	var root:=visual("pocket");root.set_script(preload("res://f4/pocket_state.gd"));pocket.add_child(root)
	pocket._membrane=root.get_node("PressureMembrane")

static func refresh_pocket(pocket: PressurePocket, fraction: float) -> void:
	var root:=pocket.get_node_or_null("F4Visual")
	if root!=null:state(root,fraction,0,0)
