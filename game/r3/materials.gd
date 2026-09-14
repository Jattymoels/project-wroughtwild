class_name R3Materials
extends RefCounted
## R3 binds the original D4-D6 images to retained G1 geometry. No native writes.
static var families: Dictionary = {}
static var cache: Dictionary = {}
static var shapes: Dictionary = {}
static var cfg: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://r3/settings.json"))
static var opaque_shader: Shader = preload("res://r3/opaque.gdshader")
static var glass_shader: Shader = preload("res://r3/glass.gdshader")

static func enabled() -> bool:
	return true

static func _load_families() -> void:
	if not families.is_empty(): return
	for slice in ["d4", "d5", "d6"]:
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://"+slice+"/materials.json"))
		for row: Dictionary in source.families:
			families[row.id] = {"slice":slice, "row":row}
	var construction: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(load("res://scripts/sim.gd").get_tuning_directory().path_join("construction.json")))
	for row: Dictionary in construction.shapes: shapes[row.id] = row

static func material_for(family: String, role: String, shape_id: String = "trim", surface: int = 0) -> Material:
	_load_families()
	var key := family+":"+role+":"+shape_id+":"+str(surface)
	if cache.has(key): return cache[key]
	assert(families.has(family), "Unknown retained family: "+family)
	var entry: Dictionary = families[family]
	var row: Dictionary = entry.row
	var slice: String = entry.slice
	var frame := surface == 1 and shape_id in ["glazed_window", "light_panel"]
	var opaque_frame := frame or role == "frame"
	var pane := family == "cinderglass" and not opaque_frame
	var mat := ShaderMaterial.new()
	mat.resource_name = "R3 "+key
	mat.shader = glass_shader if pane else opaque_shader
	var stem := "res://"+slice+"/textures/"+slice+"_"+family
	for map in ["albedo", "normal", "orm"]:
		mat.set_shader_parameter("face_"+map, R2Resources.resource(stem+("" if slice=="d6" else "_face")+"_"+map+".png"))
		mat.set_shader_parameter("edge_"+map, R2Resources.resource(stem+("" if slice=="d6" else "_edge")+"_"+map+".png"))
	var face: Array = row.get("tile_metres", [0.5,0.5])
	var edge: Array = row.get("edge_metres", face)
	mat.set_shader_parameter("face_repeat", Vector2(face[0],face[1]))
	mat.set_shader_parameter("edge_repeat", Vector2(edge[0],edge[1]))
	var kind := 0 if slice=="d4" else 1 if slice=="d5" else 2
	if family=="woven_reed": kind=3
	if family=="corkbark": kind=4
	mat.set_shader_parameter("family_kind",kind)
	var shape: Dictionary = shapes.get(shape_id,{"size_m":[0.12,0.5,0.12]})
	var size: Array = shape.size_m
	mat.set_shader_parameter("half_size",Vector3(size[0],size[1],size[2])*0.5)
	var axis := Vector3.UP
	if shape_id in ["beam","half_beam","girder"]: axis=Vector3.RIGHT
	if shape_id in ["floor_slab","half_slab","codex_corner_floor","stairs"]: axis=Vector3.BACK
	mat.set_shader_parameter("grain_axis",axis)
	mat.set_shader_parameter("broad_sides",shape.get("element","")=="block")
	mat.set_shader_parameter("slab",shape_id in ["floor_slab","half_slab","codex_corner_floor"])
	mat.set_shader_parameter("roof",String(shape.get("form","")).begins_with("roof_") or shape_id=="roof_wedge")
	mat.set_shader_parameter("roof_topology",1 if shape.get("form","")=="roof_hip" else 2 if shape.get("form","")=="roof_valley" else 0)
	mat.set_shader_parameter("moving_member",shape_id=="door")
	mat.set_shader_parameter("integral_frame",frame)
	mat.set_shader_parameter("all_edge",opaque_frame and family=="cinderglass")
	mat.set_shader_parameter("door",shape_id=="door")
	var rails: float = cfg.coarse_rail_width_m if shape_id in ["cube","wall_panel"] else cfg.fine_rail_width_m if shape_id in ["half_cube","half_wall"] else 0.0
	mat.set_shader_parameter("rail_width",rails)
	mat.set_shader_parameter("frame_width",cfg.window_frame_width_m if shape_id=="glazed_window" else cfg.panel_frame_width_m)
	mat.set_shader_parameter("shade",float(cfg.frame_shade) if role=="frame" or frame else 1.0)
	for parameter in ["normal_strength","frame_shade","end_normal_threshold","board_width_m","board_phase_texels","face_resolution_px","recess_min_m","recess_edge_guard_m","seam_roughness_add","door_rail_half_width_m","projection_axis_threshold","roof_face_min_up","alternate_axis_threshold","recess_face_threshold","inspection_grid_m","inspection_line_fraction"]:
		mat.set_shader_parameter(parameter,float(cfg[parameter]))
	mat.set_shader_parameter("door_rails_y",Vector2(cfg.door_rails_y_m[0],cfg.door_rails_y_m[1]))
	var tint: Array = row.get("seam_tint",[1,1,1])
	mat.set_shader_parameter("seam_tint",Vector3(tint[0],tint[1],tint[2]))
	mat.set_shader_parameter("seam_metallic",float(row.get("seam_metallic",0)))
	mat.set_shader_parameter("pane_opacity",float(row.get("opacity",1.0)))
	cache[key]=mat
	return mat

static func apply_to(mesh: MeshInstance3D, family: StringName, material: Material) -> void:
	var id: String = mesh.mesh.get_meta("r3_shape", "trim")
	var role := "frame" if id in ["beam","half_beam","pillar","half_pillar","girder"] else "surface"
	mesh.material_override = null
	for surface in mesh.mesh.get_surface_count():
		var bound := material_for(String(family),role,id,surface) as ShaderMaterial
		bound.set_shader_parameter("half_size",mesh.mesh.get_aabb().size*0.5)
		mesh.set_surface_override_material(surface,bound)

static func binding_inventory() -> Dictionary:
	var paths: Dictionary = {}
	var active: Dictionary = cache
	for material: Material in active.values():
		var textures: Array = []
		if material is ShaderMaterial:
			for key in ["face_albedo","face_normal","face_orm","edge_albedo","edge_normal","edge_orm"]:textures.append(material.get_shader_parameter(key))
		elif material is StandardMaterial3D:
			textures=[material.albedo_texture,material.normal_texture,material.roughness_texture,material.metallic_texture]
		for texture: Texture2D in textures:
			if texture!=null:paths[texture.resource_path]={"width":texture.get_width(),"height":texture.get_height()}
	return {"cached_materials":active.size(),"unique_original_image_bindings":paths.size(),"images":paths,"scope":"G1 construction material cache only; backend totals separately include world assets and renderer allocations."}

const R2Resources=preload("res://r2/resources.gd")
