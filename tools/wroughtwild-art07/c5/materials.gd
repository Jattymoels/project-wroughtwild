extends RefCounted
static func apply(model:Node3D,row:Dictionary)->Array[ShaderMaterial]:
	var mats:Array[ShaderMaterial]=[]
	var cfg:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://c5/kit.json"))
	for mesh in model.find_children("*","MeshInstance3D",true,false):
		for s in mesh.mesh.get_surface_count():
			var mat:=ShaderMaterial.new();mat.shader=load("res://c5/ore.gdshader")
			mat.set_shader_parameter("albedo_map",load("res://c5/textures/rock-albedo.png"));mat.set_shader_parameter("orm_map",load("res://c5/textures/rock-orm.png"))
			mat.set_shader_parameter("host_tint",Vector3(row.host_tint[0],row.host_tint[1],row.host_tint[2]));mat.set_shader_parameter("mineral_colour",Vector3(row.colour[0],row.colour[1],row.colour[2]))
			mat.set_shader_parameter("mineral_roughness",row.roughness);mat.set_shader_parameter("mineral_metallic",row.metallic);mat.set_shader_parameter("period",cfg.pulse_period_s)
			mesh.set_surface_override_material(s,mat);mats.append(mat)
	return mats
