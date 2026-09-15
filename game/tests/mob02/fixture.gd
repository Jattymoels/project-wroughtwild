extends Node3D
## Species-only source fixture. No Enemy, Sim, save, input capture or damage code.
const CLIPS := {"idle":4.0,"walk":1.4,"windup":0.6,"release":0.32,"guard":2.8}
const LOOPS := ["idle","walk","guard"]
var failures: Array[String] = []
var checks: Array[String] = []
var model: Node3D
var rig: Skeleton3D
var player: AnimationPlayer
var material: ShaderMaterial
var mesh: MeshInstance3D
var label: Label
var capture_mode := false
var capture_frame := 0
var capture_pending := false
var output := ""
var samples: Array = []
var suite_complete := false

func check(ok: bool, message: String) -> void:
	if ok: checks.append(message)
	else:
		failures.append(message)
		push_error(message)

func sample(animation: AnimationPlayer, skeleton: Skeleton3D, clip: String, seconds: float) -> void:
	animation.play(clip)
	animation.seek(seconds, true)
	animation.advance(0.0)
	skeleton.force_update_all_bone_transforms()

func make_material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://surface_scar.gdshader")
	for field in ["base","orm","scar"]:
		m.set_shader_parameter(field+"_texture", load("res://ram/"+("scar-mask" if field=="scar" else field)+".png"))
	m.set_shader_parameter("core_colour", Color(0.57,0.76,0.91))
	m.set_shader_parameter("damage_tint", Vector3(0.16,0.14,0.12))
	m.set_shader_parameter("period_seconds",4.0)
	m.set_shader_parameter("peak_emission",2.4)
	m.set_shader_parameter("minimum_light",0.32)
	m.set_shader_parameter("crest_width",0.20)
	m.set_shader_parameter("pulse_mode",3)
	m.set_shader_parameter("scar_clock",0.0)
	return m

func _ready() -> void:
	output = OS.get_environment("MOB02_OUTPUT")
	capture_mode = "--capture" in OS.get_cmdline_user_args()
	check(not output.is_empty(),"explicit disposable evidence output")
	model = load("res://ram/model.glb").instantiate()
	add_child(model)
	rig = model.find_children("*","Skeleton3D",true,false)[0]
	player = model.find_children("*","AnimationPlayer",true,false)[0]
	mesh = model.find_children("*","MeshInstance3D",true,false)[0]
	player.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	material = make_material()
	mesh.material_override = material
	mesh.extra_cull_margin = 0.65
	await get_tree().process_frame
	if capture_mode:
		check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and get_window().unfocusable,"capture keeps visible pointer and unfocusable window")
		make_stage()
		set_process(true)
	else:
		set_process(false)
		run_checks()
		check(suite_complete,"import suite reached completion")
		write_report("import-checks.json")
		get_tree().quit(0 if failures.is_empty() else 1)

func skin_vertex(arrays: Array, vertex: int) -> Vector3:
	var point: Vector3 = arrays[Mesh.ARRAY_VERTEX][vertex]
	var result := Vector3.ZERO
	for k in 4:
		var bind: int = arrays[Mesh.ARRAY_BONES][vertex*4+k]
		var weight: float = arrays[Mesh.ARRAY_WEIGHTS][vertex*4+k]
		if weight <= 0.0: continue
		var bone_index := mesh.skin.get_bind_bone(bind)
		if bone_index < 0: bone_index = rig.find_bone(mesh.skin.get_bind_name(bind))
		result += (rig.get_bone_global_pose(bone_index)*mesh.skin.get_bind_pose(bind)*point)*weight
	return result

func run_checks() -> void:
	check(rig.get_bone_count()==23,"23 fitted bones including four four-bone legs")
	check(mesh.skin != null and mesh.skin.get_bind_count()==23,"runtime mesh is bound to the imported skeleton")
	var arrays := mesh.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var max_sum_error := 0.0
	for i in vertices.size():
		var total := 0.0
		for k in 4: total += weights[i*4+k]
		max_sum_error=maxf(max_sum_error,absf(total-1.0))
	check(max_sum_error<0.0001,"every exported vertex has normalized four-slot weights")
	var actual_clips := []
	for name in player.get_animation_list():
		if name!="RESET":actual_clips.append(name)
	check(actual_clips.size()==CLIPS.size(),"exactly five exported clips")
	for clip in CLIPS:
		check(player.has_animation(clip),"clip present: "+clip)
		if not player.has_animation(clip):continue
		var animation := player.get_animation(clip)
		check(absf(animation.length-CLIPS[clip])<0.001,"duration: "+clip)
		var pure_bones := true
		for i in animation.get_track_count():
			pure_bones = pure_bones and animation.track_get_type(i) in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]
		check(pure_bones,"only bone transforms, no gameplay events: "+clip)
		# Check meaningful poses from the actual import, including interpolation.
		for fraction in [0.0,0.23,0.5,1.0]:
			sample(player,rig,clip,float(CLIPS[clip])*fraction)
			var floor_y := INF
			var max_point := 0.0
			var torso_shift := 0.0
			for i in range(0,vertices.size(),13):
				var point := skin_vertex(arrays,i)
				floor_y=minf(floor_y,point.y)
				max_point=maxf(max_point,point.length())
				if vertices[i].z < -0.35 and vertices[i].y > 0.95 and vertices[i].y < 1.4:
					torso_shift=maxf(torso_shift,point.distance_to(vertices[i]))
			var root := rig.get_bone_global_pose(rig.find_bone("root"))
			check(root.origin.length()<0.00001,"in-place root: %s %.2f" % [clip,fraction])
			check(floor_y > -0.012 and max_point<3.0,"bounded grounded skin: %s %.2f" % [clip,fraction])
			if clip in ["guard","windup","release"]:
				check(torso_shift<0.09,"rear torso stays independent of head action: %s %.2f" % [clip,fraction])
			samples.append({"clip":clip,"fraction":fraction,"minimum_sample_y":floor_y,"maximum_torso_shift":torso_shift})
		if clip in LOOPS:
			sample(player,rig,clip,0)
			var first: Array[Transform3D]=[]
			for b in rig.get_bone_count():first.append(rig.get_bone_pose(b))
			sample(player,rig,clip,CLIPS[clip])
			var error := 0.0
			for b in rig.get_bone_count():
				error=maxf(error,first[b].origin.distance_to(rig.get_bone_pose(b).origin))
				error=maxf(error,first[b].basis.get_rotation_quaternion().angle_to(rig.get_bone_pose(b).basis.get_rotation_quaternion()))
			check(error<0.002,"matching loop endpoints: "+clip)
	# Native windup end must hand off continuously to release start.
	sample(player,rig,"windup",CLIPS.windup)
	var head_end := rig.get_bone_global_pose(rig.find_bone("head"))
	sample(player,rig,"release",0.0)
	check(head_end.is_equal_approx(rig.get_bone_global_pose(rig.find_bone("head"))),"windup-to-release head continuity")
	var other: Node3D=load("res://ram/model.glb").instantiate()
	add_child(other)
	var other_rig: Skeleton3D=other.find_children("*","Skeleton3D",true,false)[0]
	var other_player: AnimationPlayer=other.find_children("*","AnimationPlayer",true,false)[0]
	other_player.callback_mode_process=AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	sample(other_player,other_rig,"idle",0.0)
	var other_head := other_rig.get_bone_global_pose(other_rig.find_bone("head"))
	sample(player,rig,"windup",CLIPS.windup)
	check(rig!=other_rig and player!=other_player,"independent instance skeleton and AnimationPlayer")
	check(other_head.is_equal_approx(other_rig.get_bone_global_pose(other_rig.find_bone("head"))),"sampling one instance cannot pose another")
	var guarded := rig.get_bone_global_pose(rig.find_bone("head"))
	sample(player,rig,"idle",0.0)
	var reset := rig.get_bone_global_pose(rig.find_bone("head"))
	check(not reset.is_equal_approx(guarded) and reset.is_equal_approx(other_head),"action interruption resets to idle without stale bones")
	var other_mat := make_material()
	material.set_shader_parameter("scar_clock",1.5)
	check(float(other_mat.get_shader_parameter("scar_clock"))==0.0,"independent material clock")
	check(mesh.mesh.get_surface_count()==1 and mesh.mesh.surface_get_primitive_type(0)==Mesh.PRIMITIVE_TRIANGLES,"one actual runtime mesh surface")
	check(arrays[Mesh.ARRAY_INDEX].size()/3==109998,"actual imported triangle count")
	print("MOB02_PATHS "+JSON.stringify({"skeleton":str(model.get_path_to(rig)),"animation_player":str(model.get_path_to(player)),"mesh":str(model.get_path_to(mesh)),"vertices":vertices.size(),"triangles":arrays[Mesh.ARRAY_INDEX].size()/3}))
	other.free()
	suite_complete=true

func write_report(file_name: String) -> void:
	var report := {"checks":checks,"failures":failures,"samples":samples,
		"skeleton":str(model.get_path_to(rig)),"animation_player":str(model.get_path_to(player)),
		"mesh":str(model.get_path_to(mesh)),"renderer":RenderingServer.get_current_rendering_method(),
		"scope":"Imported species asset only; no native Enemy, combat or save integration"}
	var f := FileAccess.open(output.path_join(file_name),FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"\t")+"\n")
	print("MOB02_CHECKS ",checks.size()," PASSED; ",failures.size()," FAILED")

func make_stage() -> void:
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode=Environment.BG_COLOR
	environment.background_color=Color(0.055,0.073,0.085)
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color(0.74,0.81,0.89)
	environment.ambient_light_energy=0.48
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	env.environment=environment;add_child(env)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-42,-34,0);sun.light_energy=2.15;sun.shadow_enabled=true;add_child(sun)
	var fill:=DirectionalLight3D.new()
	fill.rotation_degrees=Vector3(-25,145,0);fill.light_color=Color(0.62,0.76,1);fill.light_energy=0.65;add_child(fill)
	var ground:=MeshInstance3D.new()
	var plane:=PlaneMesh.new();plane.size=Vector2(200,200);ground.mesh=plane
	var ground_mat:=StandardMaterial3D.new();ground_mat.albedo_color=Color(0.105,0.133,0.14);ground_mat.roughness=0.95
	ground.material_override=ground_mat;ground.position.y=-0.005;add_child(ground)
	var camera:=Camera3D.new();camera.name="Camera"
	camera.position=Vector3(3.8,2.15,4.3);add_child(camera);camera.look_at(Vector3(0,0.95,0))
	camera.fov=36;camera.current=true
	var layer:=CanvasLayer.new();add_child(layer)
	var title:=Label.new();title.text="WROUGHTWILD  /  MOB–02"
	title.position=Vector2(32,22);title.add_theme_font_size_override("font_size",23);layer.add_child(title)
	var info:=Label.new();info.text="Stone Husk • ram rig  |  actual exported mesh"
	info.position=Vector2(32,54);info.add_theme_color_override("font_color",Color(0.65,0.77,0.79));layer.add_child(info)
	label=Label.new();label.position=Vector2(32,569);label.add_theme_font_size_override("font_size",22);layer.add_child(label)
	var note:=Label.new();note.position=Vector2(32,604);note.text="In-place source motion • native movement, guard and hit timing remain authoritative"
	note.add_theme_font_size_override("font_size",14);note.add_theme_color_override("font_color",Color(0.6,0.72,0.74));layer.add_child(note)

func _process(_delta: float) -> void:
	if not capture_mode or capture_pending:return
	capture_pending=true
	var t:=capture_frame/24.0
	var clip:="idle"
	var local_time:=t
	var caption:="IDLE  /  quiet breath, planted hooves"
	if t>=3.0 and t<6.6:
		clip="walk";local_time=fposmod(t-3.0,CLIPS.walk);caption="WALK  /  four-beat gait, individually fitted legs"
	elif t>=6.6 and t<8.6:
		clip="guard";local_time=t-6.6;caption="GUARD  /  supported forehead, grounded stance"
	elif t>=8.6 and t<9.2:
		clip="windup";local_time=t-8.6;caption="WINDUP  /  existing 0.6-second anticipation"
	elif t>=9.2 and t<9.52:
		clip="release";local_time=t-9.2;caption="RELEASE  /  short head strike, no charge"
	elif t>=9.52:
		clip="guard";local_time=t-9.52;caption="GUARD  /  recovery into the brace"
	if clip=="idle":local_time=fposmod(local_time,CLIPS.idle)
	sample(player,rig,clip,local_time)
	material.set_shader_parameter("scar_clock",t)
	label.text=caption
	await RenderingServer.frame_post_draw
	var image:=get_viewport().get_texture().get_image()
	image.save_png(output.path_join("frames/%04d.png"%capture_frame))
	if capture_frame in [24,183,219]:
		image.save_png(output.path_join("ram-%s.png" % ["idle","guard","windup"][[24,183,219].find(capture_frame)]))
	capture_frame+=1
	capture_pending=false
	if capture_frame>=264:
		set_process(false)
		capture_mode=false
		check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE and get_window().unfocusable,"pointer/focus policy held through capture")
		check(capture_frame==264,"264 actual GLB frames captured at 24 fps")
		write_report("capture-checks.json")
		get_tree().quit(0 if failures.is_empty() else 1)
