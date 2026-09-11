extends "res://tests/home_workshop_review.gd"
## Actual candidate meshes on native registry poses. Static posed art inspection.
var originals:Dictionary={}
var label:Label
var view_output:String
var camera:Camera3D
var neutral:=false
var orbit_angle:=0.0

func _run() -> void:
	player.hud.hide(); player.hide(); player.position=Vector3(-20,3,-15)
	view_output="res://art07_d3/evidence/"+RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(view_output))
	var build:=player.placement
	var entries:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d3/assigned.json"))
	for i in 5:
		var entry:Dictionary=entries[i]; var id:String=entry.id
		var kind:String="volume" if entry.element=="block" else "face" if entry.element in ["wall","floor"] else "edge"
		var axis:int=0 if kind=="volume" else 1 if entry.element in ["floor","post"] else 2 if entry.element=="wall" else 0
		build.place_piece({"kind":kind,"axis":axis,"cell":Vector3i(i*3,2,0)},StringName(id),&"wood")
		_caption(id.replace("half_","")+" / 0.5 m",Vector3(i*1.5+.25,.7,-.25))
	# Every legal panel finish shares the integral closed frame, including reed/cork.
	var panels:Array=entries[5].allowed_materials
	for i in panels.size():
		var cell:=Vector3i((i%7)*3,2,4+(i/7 as int)*4)
		build.place_piece({"kind":"face","axis":2,"cell":cell},&"light_panel",StringName(panels[i]))
		_caption(panels[i],Vector3(cell.x*.5+.5,.7,cell.z*.5-.15))
	# Mixed D1/D3 join demonstration. Coarse walls meet half wall; small shelves,
	# uprights and rails use real addresses with no helper collision/ornament.
	for x in 3:
		for z in 2:
			for y in [0,3]: build.place_piece({"kind":"face","axis":1,"cell":Vector3i(x*2,y*2,14+z*2)},&"floor_slab",&"wood")
	for y in 3:
		for x in 3:
			build.place_piece({"kind":"face","axis":2,"cell":Vector3i(x*2,y*2,18)},&"glazed_window" if y==1 else &"light_panel",&"cinderglass" if y==1 else &"woven_reed")
		for z in 2: build.place_piece({"kind":"face","axis":0,"cell":Vector3i(0,y*2,14+z*2)},&"wall_panel",&"wood")
	for y in 3: build.place_piece({"kind":"edge","axis":1,"cell":Vector3i(0,y*2,18)},&"pillar",&"bog_oak")
	for x in 3: build.place_piece({"kind":"edge","axis":0,"cell":Vector3i(x*2,6,18)},&"beam",&"wood")
	for z in 4:
		build.place_piece({"kind":"face","axis":1,"cell":Vector3i(0,3,14+z)},&"half_slab",&"wood")
		for y in [2,3]: build.place_piece({"kind":"edge","axis":1,"cell":Vector3i(1,y,14+z)},&"half_pillar",&"bog_oak")
		build.place_piece({"kind":"edge","axis":2,"cell":Vector3i(1,4,14+z)},&"half_beam",&"wood")
	for x in 2:
		build.place_piece({"kind":"volume","axis":0,"cell":Vector3i(5+x,0,14)},&"half_cube",&"wood")
		build.place_piece({"kind":"face","axis":2,"cell":Vector3i(5+x,1,14)},&"half_wall",&"wood")
	build.refresh_trims(); await get_tree().process_frame
	# Separate source inspection shows integral frames without the existing
	# automatic wall-end trim layered over them. Native assembly above retains it.
	for i in 4:
		var family:String=["cinderglass","wood","woven_reed","corkbark"][i]
		var id:String="glazed_window" if i==0 else "light_panel"
		var mesh:=MeshInstance3D.new()
		mesh.mesh=preload("res://art07_d3/adapter.gd").mesh_for(id,family)
		PieceLook.apply_to(mesh,id,StringName(family),PieceLook.material_for(sim,StringName(family)))
		add_child(mesh); mesh.position=Vector3(14+i*1.5,1.5,8); _remember(mesh)
		_caption(family,mesh.position+Vector3(0,-.72,0))
	for child in get_children():
		if child is PlacedBlock: _remember(child._mesh)
		if child.name=="WallTrims":
			for trim:MeshInstance3D in child.get_children(): _remember(trim)
	camera=Camera3D.new(); add_child(camera); camera.fov=48; camera.make_current()
	var canvas:=CanvasLayer.new(); add_child(canvas); label=Label.new(); canvas.add_child(label); label.position=Vector2(24,20); label.add_theme_font_size_override("font_size",21)
	label.text="ART-07 D3 / fine pieces and complete framed coverings\nActual models / native family materials / "+RenderingServer.get_current_rendering_method()+"\nArrows orbit • N clay/material • Esc close"
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps=0; get_window().size=Vector2i(1440,900)
	_pose(Vector3(12,10,-12),Vector3(4,.9,3.5))
	for i in 90: await get_tree().process_frame
	if OS.get_cmdline_user_args().has("--benchmark"):
		await _benchmark(); get_tree().quit(); return
	if OS.get_cmdline_user_args().has("--capture"):
		await _shot("catalogue-material")
		_neutral(true); await _shot("catalogue-neutral"); _neutral(false)
		label.text="ART-07 D3 / complete source frames / "+RenderingServer.get_current_rendering_method()+"\nNative family surfaces • source inspection without automatic wall-end trims"
		_pose(Vector3(16.25,2.4,2),Vector3(16.25,1.45,8)); await _shot("source-frames-front")
		_neutral(true); await _shot("source-frames-neutral"); _neutral(false)
		_pose(Vector3(16.25,2.4,14),Vector3(16.25,1.45,8)); await _shot("source-frames-back")
		label.text="ART-07 D3 / native coarse and fine joins / "+RenderingServer.get_current_rendering_method()+"\nExisting family surfaces and automatic seam trims retained"
		_pose(Vector3(4,3,-3),Vector3(3.4,1.1,0)); await _shot("fine-pieces")
		_pose(Vector3(4.8,2.8,-2.5),Vector3(4.8,1.3,2.4)); await _shot("coverings-front")
		_pose(Vector3(4.8,2.6,7.8),Vector3(4.8,1.3,3.8)); await _shot("coverings-back")
		_pose(Vector3(5.8,3.6,4.0),Vector3(1.6,1.4,8.5)); await _shot("joins-material")
		_neutral(true); await _shot("joins-neutral"); _neutral(false)
		_pose(Vector3(2.4,1.7,6.0),Vector3(1.4,1.5,9)); await _shot("window-front")
		_pose(Vector3(2.4,1.7,11.5),Vector3(1.4,1.5,9)); await _shot("window-back")
		_pose(Vector3(2.5,1.1,7.3),Vector3(.25,1.65,8)); await _shot("shelf-underside")
		_pose(Vector3(5.8,3.6,4.0),Vector3(1.6,1.4,8.5))
		sun.light_energy=0; await _shot("joins-shade")
		sun.light_energy=.2; sun.light_color=Color("edb187"); environment.ambient_light_energy=.12; await _shot("joins-dusk")
		sun.light_energy=1.15; sun.light_color=Color("fff1d5"); environment.ambient_light_energy=.45
		for i in 48:
			var t:float=float(i)/48.0*TAU
			_pose(Vector3(1.5+5.5*sin(t),3.3,8.2+5.5*cos(t)),Vector3(1.5,1.4,8.2)); await _shot("motion-%03d"%i,2)
		get_tree().paused=true
		var held:Array=[]
		for mesh:MeshInstance3D in originals: held.append(mesh.global_transform)
		await get_tree().process_frame
		var j:=0
		for mesh:MeshInstance3D in originals: assert(mesh.global_transform==held[j]); j+=1
		get_tree().paused=false
		print("D3_CAPTURE_OK actual static models; orbit is camera motion; pause preserves all poses")
		get_tree().quit()

func _remember(mesh:MeshInstance3D) -> void:
	var surfaces:Array=[]
	for i in mesh.get_surface_override_material_count(): surfaces.append(mesh.get_surface_override_material(i))
	originals[mesh]={"override":mesh.material_override,"surfaces":surfaces}

func _caption(text:String,at:Vector3) -> void:
	var caption:=Label3D.new(); caption.text=text.replace("_"," "); caption.font_size=28; caption.pixel_size=.005; caption.billboard=BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption); caption.position=at; caption.modulate=Color(.94,.9,.8)

func _pose(at:Vector3,target:Vector3) -> void:
	camera.position=at; camera.look_at(target)

func _neutral(on:bool) -> void:
	neutral=on
	var clay:=StandardMaterial3D.new(); clay.albedo_color=Color("8f9291"); clay.roughness=.9
	for mesh:MeshInstance3D in originals:
		mesh.material_override=clay if on else originals[mesh].override
		for i in mesh.get_surface_override_material_count(): mesh.set_surface_override_material(i,null if on else originals[mesh].surfaces[i])

func _unhandled_input(event:InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode==KEY_ESCAPE: get_tree().quit()
		if event.keycode==KEY_N: _neutral(not neutral)
		if event.keycode in [KEY_LEFT,KEY_RIGHT]:
			orbit_angle+=.15 if event.keycode==KEY_RIGHT else -.15
			_pose(Vector3(1.5+5.5*sin(orbit_angle),3.3,8.2+5.5*cos(orbit_angle)),Vector3(1.5,1.4,8.2))

func _shot(name:String,frames:int=8) -> void:
	for i in frames: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(view_output+"/"+name+".png")

func _benchmark() -> void:
	label.hide(); var rows:Array=[]
	for distance in [6.0,12.0,24.0]:
		_pose(Vector3(1.5+distance*.55,1.4+distance*.35,8.5-distance*.75),Vector3(1.5,1.4,8.5))
		for i in 180: await get_tree().process_frame
		var times:Array=[]; var last:int=Time.get_ticks_usec()
		for i in 360:
			await get_tree().process_frame
			var now:int=Time.get_ticks_usec(); times.append(float(now-last)/1000.0); last=now
		times.sort()
		rows.append({"camera_distance_parameter_m":distance,"p50_ms":times[180],"p95_ms":times[342],"worst_ms":times[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
	FileAccess.open(view_output+"/benchmark.json",FileAccess.WRITE).store_string(JSON.stringify({"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"resolution":[1440,900],"vsync":false,"warmup_frames":180,"sample_frames":360,"scene":"posed fine/covering gallery; separate from capture/generation","rows":rows},"\t"))
	print("D3_BENCHMARK_OK ",JSON.stringify(rows))
