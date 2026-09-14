extends RefCounted
## Slice-only import/material adapter; no collision or resource authority.
static var materials:Array[ShaderMaterial]=[]
static func model(key:String, base:String="res://")->Node3D:
	var node:Node3D=load(base+"assets/"+key+".gltf").instantiate()
	var controls:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(base+"kit.json"))
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		for surface in mesh.mesh.get_surface_count():
			var old:StandardMaterial3D=mesh.mesh.surface_get_material(surface)
			var mat:=ShaderMaterial.new();mat.shader=load(base+"surface.gdshader")
			for parameter in ["wind_tip_m","wind_period_s","pulse_period_s","peak_emission","minimum_light"]:mat.set_shader_parameter(parameter,controls[parameter])
			var title:String=mesh.name.to_lower();var role:=4
			if key.begins_with("resinheart"):
				role=1 if "foliage" in title else (2 if "branchlets" in title else (0 if surface==0 else 4))
			elif key in ["fern-sparse","moss","leaf-litter","grass-edge"]:role=3
			mat.set_shader_parameter("role",role)
			mat.set_shader_parameter("altered",key.begins_with("resinheart-altered") and role==0)
			mat.set_shader_parameter("textured",old.albedo_texture!=null)
			mat.set_shader_parameter("base_colour",old.albedo_color)
			if old.albedo_texture!=null:mat.set_shader_parameter("albedo_map",old.albedo_texture)
			if old.roughness_texture!=null:
				mat.set_shader_parameter("orm_map",old.roughness_texture);mat.set_shader_parameter("has_orm",true)
			mesh.set_surface_override_material(surface,mat);materials.append(mat)
	return node
static func set_time(seconds:float, light:bool=true)->void:
	for mat in materials:
		mat.set_shader_parameter("clock_seconds",seconds);mat.set_shader_parameter("light_enabled",light)
