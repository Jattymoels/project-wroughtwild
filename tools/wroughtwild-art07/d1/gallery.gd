extends "res://tests/home_workshop_review.gd"
## Posed native lattice gallery. Fixed stock/placement is inspection setup, not a campaign.
const D1 = preload("res://art07_d1/adapter.gd")
var originals:Dictionary={}
var label:Label
var view_output:String
var camera:Camera3D

func _run() -> void:
	player.hud.hide(); player.hide(); player.position=Vector3(-20,3,-15)
	view_output="res://art07_d1/evidence/"+RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(view_output))
	var build:=player.placement
	var entries:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d1/assigned.json"))
	for i in entries.size():
		var entry:Dictionary=entries[i]
		var id:String=entry.id
		var kind:String="volume" if entry.element=="block" else "face" if entry.element in ["wall","floor"] else "edge"
		var axis:int=0 if kind=="volume" else 1 if entry.element in ["floor","post"] else 2 if entry.element=="wall" else 0
		var element:Dictionary={"kind":kind,"axis":axis,"cell":Vector3i((i%5)*4,2,(i/5 as int)*4)}
		build.place_piece(element,StringName(id),&"fieldstone" if id in ["foundation","dry_wall"] else &"wood")
		var text:=Label3D.new(); text.text=id.replace("codex_","").replace("_"," ")+"\n"+str(entry.size_m)+" m"; text.font_size=30; text.pixel_size=.006; text.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(text); text.position=Vector3((i%5)*2+.5,.35,(i/5 as int)*2+.5); text.modulate=Color(.9,.87,.76)
	# A real native L-corner: floor/ceiling faces, two-height wall panels,
	# explicit edge posts and exposed beams. No separate cap conceals the joins.
	for x in 3:
		for z in 3:
			for y in [0,3]: build.place_piece({"kind":"face","axis":1,"cell":Vector3i(x*2,y*2,14+z*2)},&"floor_slab",&"wood")
	for y in 3:
		for x in 3: build.place_piece({"kind":"face","axis":2,"cell":Vector3i(x*2,y*2,20)},&"wall_panel",&"wood")
		for z in 3: build.place_piece({"kind":"face","axis":0,"cell":Vector3i(0,y*2,14+z*2)},&"wall_panel",&"wood")
		for xz in [Vector2i(0,14),Vector2i(0,20),Vector2i(6,20)]: build.place_piece({"kind":"edge","axis":1,"cell":Vector3i(xz.x,y*2,xz.y)},&"pillar",&"bog_oak")
	for x in 3: build.place_piece({"kind":"edge","axis":0,"cell":Vector3i(x*2,6,20)},&"beam",&"wood")
	for z in 3: build.place_piece({"kind":"edge","axis":2,"cell":Vector3i(0,6,14+z*2)},&"beam",&"wood")
	build.place_piece({"kind":"volume","axis":0,"cell":Vector3i(6,0,14)},&"stairs",&"wood")
	build.place_piece({"kind":"volume","axis":0,"cell":Vector3i(8,0,14)},&"codex_corner",&"stone",1)
	build.place_piece({"kind":"face","axis":1,"cell":Vector3i(8,2,14)},&"codex_corner_floor",&"stone",1)
	for x in 3: build.place_piece({"kind":"face","axis":2,"cell":Vector3i(8+x*2,0,20)},&"dry_wall",&"fieldstone")
	build.refresh_trims()
	# Native placement queued obsolete intermediate trims for deferred deletion.
	# Let that finish before retaining the final review material references.
	await get_tree().process_frame
	for child in get_children():
		if child is PlacedBlock: originals[child._mesh]=child._mesh.material_override
		if child.name=="WallTrims":
			for trim:MeshInstance3D in child.get_children(): originals[trim]=trim.material_override
	camera=Camera3D.new(); add_child(camera); camera.fov=48; camera.make_current()
	var canvas:=CanvasLayer.new(); add_child(canvas); label=Label.new(); canvas.add_child(label); label.position=Vector2(28,22); label.add_theme_font_size_override("font_size",21)
	label.text="ART-07 D1 / exact native lattice geometry\nProvisional existing materials • isolated posed review • "+RenderingServer.get_current_rendering_method()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps=0
	get_window().size=Vector2i(1440,900)
	_pose(Vector3(12,10,-13),Vector3(4,.7,3.5))
	for i in 90: await get_tree().process_frame
	if OS.get_cmdline_user_args().has("--benchmark"):
		await _benchmark()
		get_tree().quit(); return
	if OS.get_cmdline_user_args().has("--capture"):
		await _shot("catalogue-material")
		_neutral(true); await _shot("catalogue-neutral"); _neutral(false)
		_pose(Vector3(7,5,3),Vector3(1.3,1.4,8.5)); await _shot("joins-material")
		_neutral(true); await _shot("joins-neutral"); _neutral(false)
		# Review-only illumination; ordinary materials never gain emission.
		sun.light_energy=0; await _shot("joins-shade")
		sun.light_energy=.2; sun.light_color=Color("edb187"); environment.ambient_light_energy=.12
		await _shot("joins-dusk")
		sun.light_energy=1.15; sun.light_color=Color("fff1d5"); environment.ambient_light_energy=.45
		_pose(Vector3(3.4,1.1,7),Vector3(.5,2.8,9.5)); await _shot("ceiling-underside")
		for i in 48:
			var t:float=float(i)/48.0*TAU
			_pose(Vector3(1.5+6.7*sin(t),3.8,8.5+6.7*cos(t)),Vector3(1.5,1.4,8.5))
			await _shot("motion-%03d"%i,2)
		get_tree().paused=true
		var held:Array=[]
		for mesh:MeshInstance3D in originals: held.append(mesh.global_transform)
		await get_tree().process_frame
		var j:=0
		for mesh:MeshInstance3D in originals: assert(mesh.global_transform==held[j]); j+=1
		get_tree().paused=false
		print("D1_CAPTURE_OK native geometry; camera orbit only; static geometry unchanged while paused")
		get_tree().quit()

func _pose(at:Vector3,target:Vector3) -> void:
	camera.position=at; camera.look_at(target)

func _neutral(on:bool) -> void:
	var clay:=StandardMaterial3D.new(); clay.albedo_color=Color("8f9291"); clay.roughness=.9
	for mesh:MeshInstance3D in originals: mesh.material_override=clay if on else originals[mesh]

func _shot(name:String,frames:int=8) -> void:
	for i in frames: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(view_output+"/"+name+".png")

func _benchmark() -> void:
	label.hide()
	var rows:Array=[]
	for distance in [6.0,12.0,24.0]:
		_pose(Vector3(1.5+distance*.55,1.4+distance*.35,8.5-distance*.75),Vector3(1.5,1.4,8.5))
		for i in 180: await get_tree().process_frame
		var times:Array=[]; var last:int=Time.get_ticks_usec()
		for i in 360:
			await get_tree().process_frame
			var now:int=Time.get_ticks_usec(); times.append(float(now-last)/1000.0); last=now
		times.sort()
		rows.append({"camera_distance_parameter_m":distance,"p50_ms":times[180],"p95_ms":times[342],"worst_ms":times[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"video_bytes":Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)})
	FileAccess.open(view_output+"/benchmark.json",FileAccess.WRITE).store_string(JSON.stringify({"renderer":RenderingServer.get_current_rendering_method(),"adapter":RenderingServer.get_video_adapter_name(),"resolution":[1440,900],"vsync":false,"cap":0,"warmup_frames":180,"sample_frames":360,"scene":"same static native lattice gallery; no captures/generation during measurement","rows":rows},"\t"))
	print("D1_BENCHMARK_OK ",JSON.stringify(rows))
