extends RefCounted
## Review-only adapter. Original meshes, bodies, poses and refresh bounds stay authoritative.
const SURFACE = preload("res://c6/surface.gdshader")
var entries: Array[Dictionary] = []
var meshes: Dictionary = {}
var materials: Dictionary = {}
var enabled := true
var light_enabled := true
var paused := false
var clock_seconds := 0.0
var forced_detail := -1
var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://c6/kit.json"))

func material_for(source: Material, struck: bool) -> Material:
	if not source is StandardMaterial3D: return source
	var base := source as StandardMaterial3D
	var scarred := struck and String(source.resource_name).contains("recessed scar")
	var key := str(base.albedo_texture.resource_path if base.albedo_texture else base.albedo_color) + str(base.metallic) + str(base.roughness) + str(scarred)
	if materials.has(key): return materials[key]
	var mat := ShaderMaterial.new()
	mat.shader = SURFACE
	mat.set_shader_parameter("textured",base.albedo_texture != null)
	if base.albedo_texture: mat.set_shader_parameter("albedo_map",base.albedo_texture)
	mat.set_shader_parameter("tint",base.albedo_color)
	mat.set_shader_parameter("roughness",base.roughness)
	mat.set_shader_parameter("metallic",base.metallic)
	mat.set_shader_parameter("scarred",scarred)
	mat.set_shader_parameter("period_s",float(cfg.pulse_period_s))
	mat.set_shader_parameter("peak",float(cfg.pulse_peak))
	if base.roughness_texture:
		mat.set_shader_parameter("orm_map",base.roughness_texture)
		mat.set_shader_parameter("has_orm",true)
	materials[key] = mat
	return mat

func mesh_for(id: String, level: int) -> ArrayMesh:
	var key := id+"-lod%d" % level
	if meshes.has(key): return meshes[key]
	var path := "res://c6/assets/"+key+".gltf"
	if not ResourceLoader.exists(path): return null
	var root: Node = load(path).instantiate()
	var mesh := ArrayMesh.new()
	AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh)
	root.free()
	for i in mesh.get_surface_count():
		mesh.surface_set_material(i,material_for(mesh.surface_get_material(i),id.ends_with("_struck")))
	meshes[key] = mesh
	return mesh

func install(world: Node3D) -> void:
	var history: CataclysmSites = world.get_node("CataclysmSites")
	var scar_assigned := false
	for part: Node3D in history.pieces:
		var id := String(part.get_meta("authored_mesh_id",""))
		if id=="workbench" and String(part.get_meta("smithy_evidence",""))!="old_craft": continue
		if id=="cataclysm_upland_paving" and part.has_meta("smithy_evidence"):id="trail_transition"
		# A single lower-wall injury is an ambient remnant at the existing accidental site.
		if not scar_assigned and id=="cataclysm_fen_wall" and String(part.get_meta("site_id",""))=="ruv6_old_blacksmith":
			id+="_struck";scar_assigned=true
		attach(part.get_node("Visual"),id,Vector3.ONE)
	var frontier: FrontierSites = world.get_node_or_null("FrontierSites")
	if frontier==null:return
	for part: MeshInstance3D in frontier.trail_pieces:
		var size: Vector3 = part.mesh.size
		var id := ""
		var scale := Vector3.ONE
		if size.is_equal_approx(Vector3(.18,1.3,.18)): id="lf_post"
		elif size.is_equal_approx(Vector3(.75,.12,.34)): id="lf_clamp"
		elif size.is_equal_approx(Vector3(.07,.3,.25)): id="lf_stamp"
		elif is_equal_approx(size.x,.11) and is_equal_approx(size.y,.11):
			id="lf_feed"; scale.z=size.z
		elif size.is_equal_approx(Vector3(.1,.06,1.2)): id="lf_arrow_stem"
		elif size.is_equal_approx(Vector3(.07,.06,.55)): id="lf_arrow_tip"
		if id!="": attach(part,id,scale)

func attach(original: MeshInstance3D, id: String, fit: Vector3) -> void:
	if original.has_node("C6Candidate"): return
	var mesh := mesh_for(id,0)
	if mesh==null: return
	var variant := MeshInstance3D.new()
	variant.name="C6Candidate"
	variant.mesh=mesh
	variant.scale=fit
	variant.visibility_range_end=original.visibility_range_end
	original.add_child(variant)
	entries.append({"original":original,"variant":variant,"id":id,"layers":original.layers,"mesh":original.mesh,"pose":original.global_transform})
	set_render_layers(original,0 if enabled else original.layers)
	variant.visible=enabled

func set_render_layers(original: MeshInstance3D, mask: int) -> void:
	if original.layers==mask:return
	# Unpair using the old mask first; Godot 4.5 skips this when changing layers.
	# https://github.com/godotengine/godot/issues/121989
	var instance := original.get_instance()
	RenderingServer.instance_set_scenario(instance,RID())
	original.layers=mask
	RenderingServer.instance_set_scenario(instance,original.get_world_3d().scenario)

func tick(delta: float, camera: Camera3D) -> void:
	if not paused: clock_seconds+=delta
	for mat: ShaderMaterial in materials.values():
		mat.set_shader_parameter("clock_seconds",clock_seconds)
		mat.set_shader_parameter("light_enabled",light_enabled)
	for entry in entries:
		var original: MeshInstance3D = entry.original
		if not is_instance_valid(original): continue
		var variant: MeshInstance3D = entry.variant
		set_render_layers(original,0 if enabled else int(entry.layers))
		if variant.visible!=enabled:variant.visible=enabled
		var distance := camera.global_position.distance_to(original.global_position)
		var level := forced_detail if forced_detail>=0 else (0 if distance<float(cfg.lod_distances_m[0]) else 1 if distance<float(cfg.lod_distances_m[1]) else 2)
		var wanted_mesh := mesh_for(String(entry.id),level)
		if variant.mesh!=wanted_mesh:variant.mesh=wanted_mesh
