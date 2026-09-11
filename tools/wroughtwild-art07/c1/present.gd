extends RefCounted
## C1 material sharing and retained B4 ground interpolation; no native ownership.
var materials:Dictionary={}
var clock_seconds:=0.0
var paused:=false
var controls:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(get_script().resource_path.get_base_dir()+"/kit.json"))
static func river(z:float)->float:return -5.8+sin(z*.12)+.35*sin(z*.31)
static func analytic(x:float,z:float)->float:
	var r:=absf(x-river(z))
	return 1.25*(1-exp(-pow(r/3.0,4.0)))-.8+.13*sin(x*.31+z*.19)+.10*cos(z*.34-x*.22)+maxf(0,absf(x)-9)*.035+3.4*exp(-pow((z-34)/10.0,2.0))
static func ground(x:float,z:float)->float:
	var a:=floorf(x*2)*.5;var b:=floorf(z*2)*.5;var u:=(x-a)*2;var v:=(z-b)*2
	var h00:=analytic(a,b);var h10:=analytic(a+.5,b);var h01:=analytic(a,b+.5);var h11:=analytic(a+.5,b+.5)
	return h00+u*(h10-h00)+v*(h01-h00) if u+v<=1 else h11+(1-u)*(h01-h11)+(1-v)*(h10-h11)
func install(model:Node3D,id:String,conform:=false,own:=false)->Array:
	var result:Array=[]
	for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
		for s in mesh.mesh.get_surface_count():
			var old:StandardMaterial3D=mesh.mesh.surface_get_material(s)
			var role:=0
			if id.begins_with("bog-oak"):
				if str(mesh.name).contains("foliage") or old.resource_name.contains("foliage"):role=1
				elif str(mesh.name).contains("branchlet") or old.resource_name.contains("twigs"):role=2
			elif id.begins_with("reed") or id.begins_with("fen-sedge"):role=3
			elif id.begins_with("clay"):role=7
			elif id=="ground":role=5
			elif id=="water":role=6
			var image:Texture2D=old.albedo_texture
			var key:=str(role)+":"+str(conform)+":"+old.resource_name+":"+(image.resource_path if image else str(old.albedo_color))+":"+str(old.vertex_color_use_as_albedo)
			if not materials.has(key):
				var m:=ShaderMaterial.new();m.shader=load(get_script().resource_path.get_base_dir()+"/surface.gdshader")
				m.set_shader_parameter("role",role);m.set_shader_parameter("textured",image!=null);m.set_shader_parameter("vertex_colored",old.vertex_color_use_as_albedo);m.set_shader_parameter("solid_color",old.albedo_color)
				if image:m.set_shader_parameter("albedo_map",image)
				m.set_shader_parameter("ground_conform",conform);m.set_shader_parameter("plant_bend",controls.wind_m_per_m);m.set_shader_parameter("wind_period_s",controls.wind_period_s);m.set_shader_parameter("seating_fade",Vector2(controls.plant_seating_fade_m[0],controls.plant_seating_fade_m[1]));m.set_shader_parameter("clay_top",controls.clay_seated_top_m);m.set_shader_parameter("crown_wind_fade",Vector2(controls.oak_crown_start_m,controls.oak_crown_spread_m))
				m.set_shader_parameter("has_orm",old.roughness_texture!=null)
				if old.roughness_texture:m.set_shader_parameter("orm_map",old.roughness_texture)
				if role==5:m.set_shader_parameter("textured",true);m.set_shader_parameter("albedo_map",load(get_script().resource_path.get_base_dir()+"/forest-floor.png"))
				materials[key]=m
			var mat:ShaderMaterial=materials[key].duplicate() if own else materials[key]
			mesh.set_surface_override_material(s,mat);result.append(mat)
	return result
func set_time(value:float)->void:
	clock_seconds=value
	for m:ShaderMaterial in materials.values():m.set_shader_parameter("clock_seconds",value)
func tick(delta:float)->void:
	if not paused:set_time(clock_seconds+delta)
