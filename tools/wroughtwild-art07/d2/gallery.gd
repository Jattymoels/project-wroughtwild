extends "res://tests/home_workshop_review.gd"
## Native paid placements with granted inspection stock. Not a first-hour journey.
const D2 = preload("res://art07_d2/adapter.gd")
var originals:Dictionary={}
var label:Label
var view_output:String
var camera:Camera3D
var doors:Array[PlacedBlock]=[]

func put(id:String,family:String,kind:String,axis:int,cell:Vector3i,turn:int=0) -> PlacedBlock:
	var piece:PlacedBlock=player.placement.place_piece({"kind":kind,"axis":axis,"cell":cell},StringName(id),StringName(family),turn)
	assert(piece!=null,"D2 gallery placement failed: "+id+str(cell))
	return piece

func _run() -> void:
	player.hud.hide(); player.hide(); player.position=Vector3(-20,3,-15)
	player.spring_arm.set_physics_process(false)
	for item in ["wood","stone","slate","bronze_ingot","iron_ingot"]: sim.add_material(item,2000)
	sim.record_world_effect("stonecut_blocks")
	view_output="res://art07_d2/evidence/"+RenderingServer.get_current_rendering_method()+"/v03"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(view_output))
	var entries:Array=JSON.parse_string(FileAccess.get_file_as_string("res://art07_d2/assigned.json"))
	for i in entries.size():
		var entry:Dictionary=entries[i]; var id:String=entry.id
		var kind:String="volume" if entry.element=="block" else "face" if entry.element=="wall" else "edge"
		var axis:int=2 if kind=="face" else 0
		var family:String="stone" if id=="roof_wedge" else "iron" if id=="girder" else "bronze" if id=="arch" else "wood" if id=="door" else "slate"
		var piece:=put(id,family,kind,axis,Vector3i(i*4,0,0))
		if piece.is_door(): doors.append(piece)
		var text:=Label3D.new(); text.text=id.replace("codex_","").replace("_"," "); text.font_size=30; text.pixel_size=.005; text.billboard=BaseMaterial3D.BILLBOARD_ENABLED
		add_child(text); text.position=piece.position+Vector3(0,entry.size_m[1]*.5+.2,0)
	# Four-metre native room: D1 floor/walls/posts, D2 roof courses and true door.
	for x in 4:
		for z in 4:
			put("floor_slab","wood","face",1,Vector3i(x*2,0,12+z*2))
			var a:int=mini(x,3-x); var b:int=mini(z,3-z)
			var id:String="codex_roof_hip" if a==b else "codex_roof_slope"
			var turn:int
			if a==b: turn=0 if x<2 and z<2 else 1 if x<2 else 2 if z>=2 else 3
			elif a<b: turn=1 if x<2 else 3
			else: turn=0 if z<2 else 2
			put(id,"slate","volume",0,Vector3i(x*2,6+mini(a,b),12+z*2),turn)
	for y in 3:
		for x in 4:
			put("wall_panel","wood","face",2,Vector3i(x*2,y*2,20))
			if x!=1 or y==2: put("wall_panel","wood","face",2,Vector3i(x*2,y*2,12))
		for z in 4:
			put("wall_panel","wood","face",0,Vector3i(0,y*2,12+z*2))
			put("wall_panel","wood","face",0,Vector3i(8,y*2,12+z*2))
	doors.append(put("door","wood","face",2,Vector3i(2,0,12)))
	for x in 4: put("beam","wood","edge",0,Vector3i(x*2,6,12))
	# An exposed ceiling/corner coupon and a concave valley preserve native joins.
	for x in 2:
		for z in 2:
			put("floor_slab","wood","face",1,Vector3i(12+x*2,6,12+z*2))
	put("girder","iron","edge",0,Vector3i(12,6,12))
	put("pillar","wood","edge",1,Vector3i(12,4,12))
	put("arch","bronze","face",2,Vector3i(14,4,12))
	put("codex_roof_valley","slate","volume",0,Vector3i(12,7,12))
	put("codex_roof_slope","slate","volume",0,Vector3i(10,7,12),1)
	put("codex_roof_slope","slate","volume",0,Vector3i(12,7,10),0)
	put("codex_roof_hip","slate","volume",0,Vector3i(10,7,10),0)
	player.placement.refresh_trims(); await get_tree().process_frame
	for child in get_children():
		if child is PlacedBlock: originals[child._mesh]=child._mesh.material_override
		if child.name=="WallTrims":
			for trim:MeshInstance3D in child.get_children(): originals[trim]=trim.material_override
	camera=Camera3D.new(); add_child(camera); camera.fov=48; camera.make_current()
	var canvas:=CanvasLayer.new(); add_child(canvas); label=Label.new(); canvas.add_child(label); label.position=Vector2(28,22); label.add_theme_font_size_override("font_size",21)
	label.text="ART-07 D2 / roofs, native hinged leaf and metal spans\nD1 join geometry • granted review stock • "+RenderingServer.get_current_rendering_method()
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED); Engine.max_fps=0; get_window().size=Vector2i(1440,900)
	_pose(Vector3(14,6,-7),Vector3(6.5,.8,1))
	for i in 90: await get_tree().process_frame
	if OS.get_cmdline_user_args().has("--benchmark"):
		await _benchmark(); get_tree().quit(); return
	if OS.get_cmdline_user_args().has("--capture"):
		await _shot("catalogue-material"); _neutral(true); await _shot("catalogue-neutral"); _neutral(false)
		_pose(Vector3(10,8,-1),Vector3(3,2,7)); await _shot("joins-material")
		_neutral(true); await _shot("joins-neutral"); _neutral(false)
		_pose(Vector3(7,6,2),Vector3(5.8,3.5,6)); await _shot("valley-contact")
		_pose(Vector3(2,1.7,4),Vector3(1.5,1.2,6)); await _shot("door-closed")
		await _interact(doors[1]); await _shot("door-open")
		get_tree().paused=true; var held:Transform3D=doors[1]._mesh.global_transform
		for i in 5: await get_tree().process_frame
		assert(doors[1]._mesh.global_transform==held); get_tree().paused=false
		var manager:=SaveManager.new(); assert(manager.write("user://d2-gallery.json",player))
		# Film actual E interactions. The existing contract switches at the input
		# event; do not manufacture a tween or a different collision animation.
		var states:Array=[]
		for i in 48:
			if i in [12,36]: await _interact(doors[1])
			_pose(Vector3(1.5+sin(i*.035)*1.6,1.65,3.7),Vector3(1.5,1.1,6))
			await _shot("motion-%03d"%i,2)
			states.append({"frame":i,"open":doors[1].open,"visual":str(doors[1]._mesh.global_transform),"collision":str(doors[1]._collision_shapes[0].global_transform)})
		FileAccess.open(view_output+"/motion-states.json",FileAccess.WRITE).store_string(JSON.stringify(states,"\t"))
		_pose(Vector3(2,1.8,6.7),Vector3(1.4,3.3,8.5)); await _shot("ceiling-underside")
		_pose(Vector3(10,8,-1),Vector3(3,2,7)); sun.light_energy=0; await _shot("joins-shade")
		sun.light_energy=.2; sun.light_color=Color("edb187"); environment.ambient_light_energy=.12; await _shot("joins-dusk")
		print("D2_CAPTURE_OK actual E leaf states; pause; native geometry; saved open-state")
		get_tree().quit()

func _interact(door:PlacedBlock) -> void:
	var aim:=Camera3D.new(); add_child(aim); var old:Camera3D=player.camera
	var clear:=false
	for distance in [.3,.6,1.4,-.3,-.6,-1.4]:
		aim.global_position=door.leaf_point()+door._collision_shapes[0].global_basis.z*distance
		aim.look_at(door.leaf_point())
		await get_tree().physics_frame
		var query:=PhysicsRayQueryParameters3D.create(aim.global_position,door.leaf_point())
		if get_world_3d().direct_space_state.intersect_ray(query).get("collider")==door:
			clear=true; break
	assert(clear,"Inspection camera must have a real clear ray to the leaf")
	player.camera=aim
	var before:bool=door.open; player.interact(); assert(door.open!=before,"Real interaction must change one door")
	player.camera=old; aim.queue_free()
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
	print("D2_BENCHMARK_OK ",JSON.stringify(rows))
