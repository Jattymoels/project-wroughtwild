extends Node3D
## Actual exported models; comparison stand, not generated world or paid gameplay.
var camera:Camera3D
var label:Label
var sun:DirectionalLight3D
var mats:Array[ShaderMaterial]=[]
var subjects:Array=[]
var bark_maps:Dictionary={}
var seconds:=0.0
var out:=""
func _ready():
	get_window().size=Vector2i(1440,900);get_viewport().msaa_3d=Viewport.MSAA_4X
	out="res://../evidence/r1-studio-v02-"+RenderingServer.get_current_rendering_method()
	assert(not DirAccess.dir_exists_absolute(out));DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var world:=WorldEnvironment.new();world.environment=Environment.new();world.environment.background_mode=Environment.BG_COLOR;world.environment.background_color=Color(.18,.23,.27);world.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;world.environment.ambient_light_color=Color(.8,.85,1);world.environment.ambient_light_energy=.7;add_child(world)
	sun=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-42,-35,0);sun.light_energy=1.8;sun.shadow_enabled=true;add_child(sun)
	camera=Camera3D.new();camera.fov=52;add_child(camera);camera.make_current()
	var floor:=MeshInstance3D.new();floor.mesh=PlaneMesh.new();floor.mesh.size=Vector2(50,50);var material:=StandardMaterial3D.new();material.albedo_color=Color(.19,.21,.15);material.roughness=1;floor.material_override=material;add_child(floor)
	var canvas:=CanvasLayer.new();add_child(canvas);label=Label.new();canvas.add_child(label);label.position=Vector2(22,20);label.add_theme_font_size_override("font_size",20)
	for kind in ["broadleaf","pine","broadleaf-b","pine-b","broadleaf-altered"]:
		for lod in 3:
			var role:String=kind if kind.ends_with("altered") or kind.ends_with("-b") else kind+"-a"
			var burial:=.55 if kind.begins_with("pine") else .65
			var pair:Array=[]
			for mode in ["before","after"]:
				var base:="res://b1/assets/" if mode=="before" else "res://r1/studio-assets/"
				var model:Node3D=load(base+role+"-lod"+str(lod)+".glb").instantiate();add_child(model)
				model.position=Vector3(-5 if mode=="before" else 5,-burial,0)
				if mode=="before":model.scale=Vector3(.1313987 if kind.begins_with("pine") else .2694963,1,.1313987 if kind.begins_with("pine") else .2694963)
				for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
					if kind=="broadleaf" and not "foliage" in mesh.name.to_lower() and not "branchlets" in mesh.name.to_lower():
						bark_maps[mode]=mesh.mesh.surface_get_material(0)
					if kind.ends_with("altered"):
						var mat:=ShaderMaterial.new();mat.shader=load("res://r1/canopy.gdshader")
						var original:StandardMaterial3D=bark_maps[mode]
						mat.set_shader_parameter("role",1 if "foliage" in mesh.name.to_lower() else (2 if "branchlets" in mesh.name.to_lower() else 0))
						mat.set_shader_parameter("base_texture",original.albedo_texture);mat.set_shader_parameter("orm_texture",original.roughness_texture)
						mesh.material_override=mat;mats.append(mat)
					else:
						for s in mesh.mesh.get_surface_count():
							var mat:StandardMaterial3D=mesh.mesh.surface_get_material(s).duplicate();mat.cull_mode=BaseMaterial3D.CULL_DISABLED;mesh.set_surface_override_material(s,mat)
				model.visible=false;pair.append(model)
			subjects.append({"kind":kind,"lod":lod,"pair":pair})
	for row in subjects:
		for model in row.pair:model.visible=true
		camera.position=Vector3(0,6.5,24);camera.look_at(Vector3(0,3.5,0))
		label.text="ART-07R1 actual exported "+row.kind+" / LOD"+str(row.lod)+" / "+RenderingServer.get_current_rendering_method()+"\nLEFT: G1 whole-tree fit    RIGHT: R1 lower-trunk refit"
		await shot(row.kind+"-lod"+str(row.lod))
		if row.kind=="broadleaf-altered" and row.lod==0:
			camera.position=Vector3(6.2,2.4,4.0);camera.look_at(Vector3(5,2.6,0))
			for mat in mats:mat.set_shader_parameter("light_enabled",false)
			label.text="ART-07R1 / actual altered broadleaf LOD0 / "+RenderingServer.get_current_rendering_method()+"\nR1 close-up / emission OFF / source recess geometry"
			await shot("scar-emission-off")
			for mat in mats:mat.set_shader_parameter("light_enabled",true)
			label.text="ART-07R1 / actual altered broadleaf LOD0 / "+RenderingServer.get_current_rendering_method()+"\nR1 close-up / emission ON / original B1 shader"
			await shot("scar-emission-on")
			label.text="ART-07R1 / actual altered broadleaf LOD0 / "+RenderingServer.get_current_rendering_method()+"\nR1 close-up / original shader clock at 12 Hz / illustrative playback"
			for frame in 48:
				for mat in mats:mat.set_shader_parameter("clock_seconds",float(frame)/12)
				await shot("scar-motion-%03d"%frame)
		for model in row.pair:model.visible=false
	print("R1_STUDIO_OK ",subjects.size()," actual LOD pairs; emission-off and timed shader playback")
	get_tree().quit()
func shot(name:String):
	for i in 4:await RenderingServer.frame_post_draw
	assert(get_viewport().get_texture().get_image().save_png(out+"/"+name+".png")==OK)
