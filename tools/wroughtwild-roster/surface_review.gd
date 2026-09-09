extends Node3D
## ART-06B static surface comparison. Native gameplay is deliberately absent.
const SCAR = preload("res://scar.gdshader")
var config: Dictionary
var actors: Array[Node3D] = []
var materials: Array[ShaderMaterial] = []
var meshes: Array[MeshInstance3D] = []
var slots: Array[Vector3] = []
var captions: Array[Label3D] = []
var camera: Camera3D
var label: Label
var scar_clock := 0.0
var paused := false
var automatic := false
var mode := 3
var selected := -1
var checks: Array[String] = []
var pixel_results: Array[Dictionary] = []

func require(ok: bool, message: String) -> void:
	if not ok:
		push_error(message)
		get_tree().quit(1)
		assert(ok, message)
	checks.append(message)

func _ready() -> void:
	config = JSON.parse_string(FileAccess.get_file_as_string("res://surfaces.json"))
	var world := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("293238")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("bdc8d2")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.environment = env
	add_child(world)
	for spec in [[Vector3(-4,7,5),1.4],[Vector3(4,4,4),0.75],[Vector3(0,6,-3),1.0]]:
		var light := DirectionalLight3D.new()
		add_child(light)
		light.position = spec[0]
		light.look_at(Vector3(0,1.8,0))
		light.light_energy = spec[1]
	for i in config.assets.size():
		add_asset(i)
	camera = Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	add_child(camera)
	var canvas := CanvasLayer.new()
	add_child(canvas)
	label = Label.new()
	label.position = Vector2(16,12)
	label.add_theme_font_size_override("font_size",16)
	canvas.add_child(label)
	select_view(-1)
	apply_settings()
	if "--check" in OS.get_cmdline_user_args():
		automatic = true
		await check_all()
	elif "--capture" in OS.get_cmdline_user_args():
		automatic = true
		await capture_all()

func add_asset(i: int) -> void:
	var row: Dictionary = config.assets[i]
	var packed := load("res://assets/%s/%s-surface.glb" % [row.id,row.id]) as PackedScene
	require(packed != null,"Surface import: "+row.id)
	var holder := Node3D.new()
	add_child(holder)
	var actor := packed.instantiate() as Node3D
	holder.add_child(actor)
	actor.rotation.y = deg_to_rad(225 if row.id == "gloom_crawler" else 45)
	var children := actor.find_children("*","MeshInstance3D",true,false)
	var attachments: Array = row.surface_report.get("face_repair",{}).get("attachments",[])
	require(children.size()==1+attachments.size(),"Source and documented face attachment count: "+row.id)
	var mesh := children[0] as MeshInstance3D
	if not attachments.is_empty():
		for child in children:
			if "surface host" in String(child.name): mesh=child
		var attachment_triangles := 0
		for child in children:
			if child==mesh: continue
			require(child.skin==null,"Unrigged head attachment: "+String(child.name))
			for surface in child.mesh.get_surface_count():
				attachment_triangles+=int(child.mesh.surface_get_array_index_len(surface)/3)
				var face_material := child.mesh.surface_get_material(surface) as StandardMaterial3D
				require(face_material!=null and not face_material.emission_enabled,"Natural non-emissive face material: "+String(child.name))
		var expected_triangles := 0
		for attachment in attachments: expected_triangles+=int(attachment.triangles)
		require(attachment_triangles==expected_triangles,"Exact documented face attachment triangles")
	var triangles := 0
	for surface in mesh.mesh.get_surface_count():
		triangles += int(mesh.mesh.surface_get_array_index_len(surface)/3)
		var arrays := mesh.mesh.surface_get_arrays(surface)
		var positions: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for point in positions:
			if not point.is_finite(): require(false,"Nonfinite exported point: "+row.id)
	require(triangles==int(row.surface_report.triangles),"Preserved surface triangle count: "+row.id)
	require(mesh.skin==null,"Source remains unrigged: "+row.id)
	var material := ShaderMaterial.new()
	material.shader = SCAR
	var folder := "res://assets/"+String(row.id)+"/"
	for pair in [["base_texture","base.png"],["orm_texture","orm.png"],["scar_texture","scar-mask.png"]]:
		var texture := load(folder+pair[1]) as Texture2D
		require(texture!=null,"Surface texture: "+row.id+" / "+pair[1])
		material.set_shader_parameter(pair[0],texture)
	material.set_shader_parameter("core_colour",Color(row.colour[0],row.colour[1],row.colour[2]))
	material.set_shader_parameter("damage_tint",Vector3(config.damage_tint[0],config.damage_tint[1],config.damage_tint[2]))
	for key in ["period_seconds","peak_emission","minimum_light","crest_width"]:
		material.set_shader_parameter(key,config[key])
	mesh.material_override = material
	mesh.set_instance_shader_parameter("phase_offset",fmod(i*.173,1.0))
	var lo := Vector3(INF,INF,INF)
	var hi := -lo
	var transform := holder.global_transform.affine_inverse()*mesh.global_transform
	for j in 8:
		var point := transform*mesh.get_aabb().get_endpoint(j)
		lo=lo.min(point)
		hi=hi.max(point)
	var factor := 1.65/maxf((hi-lo).x,maxf((hi-lo).y,(hi-lo).z))
	actor.scale *= factor
	actor.position = -Vector3((lo.x+hi.x)/2,lo.y,(lo.z+hi.z)/2)*factor
	var slot := Vector3((i%3-1)*2.15,2.1 if i<3 else 0.0,0)
	slot.y += (1.65-(hi.y-lo.y)*factor)*.5
	holder.position = slot
	slots.append(Vector3(slot.x, (2.1 if i<3 else 0.0)+.82,0))
	actors.append(holder)
	materials.append(material)
	meshes.append(mesh)
	var caption := Label3D.new()
	caption.text = String(row.id).replace("_"," ").capitalize()+" / "+row.animal
	caption.font_size = 38
	caption.pixel_size = .0023
	caption.position = Vector3(slot.x,1.93 if i<3 else -.17,.9)
	caption.no_depth_test = false
	caption.modulate = Color("cdd5d8")
	add_child(caption)
	captions.append(caption)

func select_view(index: int) -> void:
	selected = index
	for i in actors.size():
		actors[i].visible = selected<0 or selected==i
		captions[i].visible = selected<0
	var target := Vector3(0,1.8,0) if selected<0 else slots[selected]
	camera.size = 5.8 if selected<0 else 2.45
	camera.position = target+Vector3(0,0,10)
	camera.look_at(target)

func apply_settings() -> void:
	for material in materials:
		material.set_shader_parameter("scar_clock",scar_clock)
		material.set_shader_parameter("pulse_mode",mode)
	if is_instance_valid(label):
		var title := "SIX CREATURES" if selected<0 else String(config.assets[selected].animal).to_upper()
		label.text = "%s / %s\n%s · %s · dense unrigged sources\n0 all · 1–6 creature · M light · Space pause · Arrows orbit · R reset" % [title,"DEEP LIFELINES" if config.get("geometry_mode","")=="directional_channel" else "ATTACHED LIVING SCARS",["Dark damage","Steady light","Breathing light","Travelling light"][mode],"Paused" if paused else "Running"]

func _process(delta: float) -> void:
	if automatic: return
	if not paused: scar_clock += maxf(delta,0)
	if selected>=0:
		if Input.is_key_pressed(KEY_LEFT): actors[selected].rotation.y -= delta
		if Input.is_key_pressed(KEY_RIGHT): actors[selected].rotation.y += delta
	apply_settings()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode==KEY_0: select_view(-1)
	elif event.keycode>=KEY_1 and event.keycode<=KEY_6: select_view(event.keycode-KEY_1)
	elif event.keycode==KEY_M: mode=(mode+1)%4
	elif event.keycode==KEY_SPACE: paused=not paused
	elif event.keycode==KEY_R:
		for actor in actors: actor.rotation=Vector3.ZERO
	elif event.keycode==KEY_ESCAPE: get_tree().quit()
	apply_settings()

func frame_at(light_mode: int, seconds: float) -> Image:
	mode=light_mode
	scar_clock=seconds
	apply_settings()
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func difference(a: Image,b: Image) -> int:
	var changed := 0
	# Exclude the caption; only actual rendered creature pixels count.
	for y in range(110,a.get_height()-20,2):
		for x in range(20,a.get_width()-20,2):
			var c := a.get_pixel(x,y)
			var d := b.get_pixel(x,y)
			if absf(c.r-d.r)+absf(c.g-d.g)+absf(c.b-d.b)>.035: changed+=1
	return changed

func check_all() -> void:
	for i in actors.size():
		select_view(i)
		var off := await frame_at(0,0.0)
		var lit := await frame_at(1,0.0)
		var first := await frame_at(3,.7)
		var second := await frame_at(3,2.1)
		var light_pixels := difference(off,lit)
		var travel_pixels := difference(first,second)
		require(light_pixels>20,"Actual surface emission visible: "+config.assets[i].id)
		require(travel_pixels>10,"Actual travelling-light pixels change: "+config.assets[i].id)
		pixel_results.append({"asset":config.assets[i].id,"lit_changed_samples":light_pixels,"travel_changed_samples":travel_pixels,"sample_stride":2})
	automatic=false
	paused=true
	var before:=scar_clock
	_process(.5)
	require(scar_clock==before,"Paused clock remains fixed")
	paused=false
	_process(.5)
	require(is_equal_approx(scar_clock,before+.5),"Resumed clock advances by elapsed time")
	automatic=true
	var first_phase: float = meshes[0].get_instance_shader_parameter("phase_offset")
	meshes[1].set_instance_shader_parameter("phase_offset",.91)
	require(meshes[0].get_instance_shader_parameter("phase_offset")==first_phase,"Instance phase change remains local")
	var colour_before: Variant = materials[0].get_shader_parameter("core_colour")
	materials[1].set_shader_parameter("core_colour",Color.RED)
	require(materials[0].get_shader_parameter("core_colour")==colour_before,"Creature colour change remains local")
	var a := await frame_at(0,0)
	var b := await frame_at(0,2)
	require(difference(a,b)==0,"Off mode has no time-dependent glow")
	write_json("checks.json",{"checks":checks.size(),"passed":checks,"pixels":pixel_results,"renderer":RenderingServer.get_current_rendering_method(),"scope":"Static surface, clock and rendered-light checks; no rig, native gameplay or performance claim."})
	print("ROSTER_SURFACE_CHECKS ",checks.size())
	get_tree().quit()

func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open("res://"+path,FileAccess.WRITE)
	file.store_string(JSON.stringify(value,"  "))
	file.close()

func save_frame(path: String, picture: Image) -> void:
	require(picture.save_png("res://captures/"+path+".png")==OK,"Capture written: "+path)

func capture_all() -> void:
	DirAccess.make_dir_recursive_absolute("res://captures")
	select_view(-1)
	save_frame("gallery-dark",await frame_at(0,0))
	save_frame("gallery-lit",await frame_at(1,0))
	for frame in 48:
		save_frame("pulse-%03d"%frame,await frame_at(3,frame/12.0))
	for i in actors.size():
		select_view(i)
		save_frame(config.assets[i].id+"-dark",await frame_at(0,0))
		save_frame(config.assets[i].id+"-lit",await frame_at(1,0))
	write_json("capture.json",{"frames":48,"fps":12,"duration_seconds":4,"source":"Actual Godot rendered frames; deterministic pulse clock, static unrigged meshes.","bloom":false})
	print("ROSTER_SURFACE_CAPTURED")
	get_tree().quit()
