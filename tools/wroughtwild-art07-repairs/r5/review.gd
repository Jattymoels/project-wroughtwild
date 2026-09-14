extends "res://e3/review.gd"
## R5 harness only. Supplied fixture stock, actual placement/payment/E/storage;
## no replacement body, tolerance, native source or saved pose.
var r5 := {"cases":[],"scope":"Deterministic addressed fixture targets and supplied stock; native placement/payment/storage; real panel-driven lid delta. Not a first-hour journey."}
var mode := "checks"
func check(ok: bool, label: String) -> bool:
	var result: bool = super.check(ok,label)
	if not r5.has("assertions"): r5.assertions=[]
	r5.assertions.append({"ok":ok,"label":label})
	return result
func _run() -> void:
	get_window().size=Vector2i(1440,900)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	backend=RenderingServer.get_current_rendering_method()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):output=arg.trim_prefix("--out=")
		if arg in ["--capture","--benchmark","--restore"]:mode=arg.trim_prefix("--")
	DirAccess.make_dir_recursive_absolute(output)
	player.hide();player.hud.hide();player.spring_arm.set_physics_process(false);player.camera.current=false
	camera=Camera3D.new();add_child(camera);camera.current=true;camera.fov=42
	var layer:=CanvasLayer.new();add_child(layer);caption=Label.new();caption.position=Vector2(24,20);caption.add_theme_font_size_override("font_size",21);layer.add_child(caption)
	environment.tonemap_mode=Environment.TONE_MAPPER_LINEAR;environment.glow_enabled=false
	if mode=="restore":await r5_restore();done();return
	check(sim.contraption_bind_world("legacy_v1",0),"explicit isolated native identity")
	sim.drop_inventory()
	player.placement.select_shape(&"chest");player.build_palette.select_material(&"wood")
	player.placement.set_build_mode_enabled(true)
	player.placement.preview_element={"kind":"volume","axis":0,"cell":Vector3i(0,0,0)};player.placement.preview_visible=true
	var empty_owned:=sim.export_json()
	check(not player.placement.try_place_block(),"empty pack refuses unpaid chest")
	check(sim.export_json()==empty_owned and sim.structure_piece_count()==0,"unpaid refusal creates no owner and spends nothing")
	for family in sim.build_material_ids():
		check(sim.shape_allows_family("chest",family)==CHESTS.has(String(family)),"original chest eligibility "+String(family))
	for f in CHESTS:
		sim.add_material(String(sim.build_material(f).source),200)
	await settle()
	for i in CHESTS.size():
		var c:=_place(&"chest",StringName(CHESTS[i]),Vector3i(i*2,0,0)) as PlacedBlock
		if c==null:done();return
		chest_nodes.append(c)
		await settle()
		await inspect_case(c,"flat-"+CHESTS[i],0.0)
	for fine in [false,true]:
		var x:=0 if not fine else 3
		for dx in 2 if fine else 1:
			for dz in 2 if fine else 1:
				var floor_id:StringName=&"half_slab" if fine else &"floor_slab"
				if place_fixture(floor_id,&"wood",Vector3i(x,1,4),"face",1,Vector3i(dx,0,dz))==null:done();return
		var c:=_place(&"chest",&"wood",Vector3i(x,1,4)) as PlacedBlock
		if c==null:done();return
		chest_nodes.append(c)
		await settle()
		await inspect_case(c,"fine-slab" if fine else "ordinary-slab",1.0625 if fine else 1.125)
	# D-017 ordinary face/volume overlaps remain legal. These are clearance probes,
	# not invented new placement refusals for walls or low ceilings.
	for low in [false,true]:
		var origin:=Vector3i(7 if low else 10,0,4)
		var c:=_place(&"chest",&"wood",origin) as PlacedBlock
		if c==null:done();return
		chest_nodes.append(c)
		var obstacle:=_place(&"floor_slab" if low else &"wall_panel",&"wood",origin+Vector3i(0,1,0) if low else origin,"face",1 if low else 2) as PlacedBlock
		check(obstacle!=null,"retained legal low ceiling/wall lattice placement")
		await settle()
		await inspect_case(c,"low-ceiling" if low else "back-wall",0.0,obstacle)
	player.placement.set_build_mode_enabled(false)
	if mode=="benchmark":await r5_bench()
	else:
		var expected:Dictionary={"native":JSON.parse_string(sim.export_json()),"blocks":JSON.parse_string(JSON.stringify(manager.capture(player).blocks))}
		check(manager.write("user://r5-storage.json",player),"write paid R5 checkpoint")
		FileAccess.open("user://r5-expected.json",FileAccess.WRITE).store_string(JSON.stringify(expected))
	done()
func place_fixture(id:StringName,family:StringName,cell:Vector3i,kind:String,axis:int,offset:Vector3i)->PlacedBlock:
	# Fine shapes use the same public selector as the G toggle, because catalogue
	# cards list only their coarse parent. Actual try_place_block owns all effects.
	var b:=player.placement;b.set_build_mode_enabled(true);b.fine_mode=false;b.select_shape(&"floor_slab" if id==&"half_slab" else id);player.build_palette.select_material(family);selected=""
	if id==&"half_slab":b.toggle_fine()
	var element:Dictionary={"kind":kind,"axis":axis,"cell":cell*2+offset}
	player.position=Vector3(cell)+Vector3(-2,1,-2)
	var before:=sim.material_count(String(sim.build_material(family).source))
	check(b.element_refusal(element).is_empty(),"native fine floor accepts: "+b.element_refusal(element))
	b.preview_element=element;b.preview_visible=true
	check(b.try_place_block(),"paid fine floor placement")
	check(sim.material_count(String(sim.build_material(family).source))==before-int(sim.shape(id).material_cost),"exact fine floor cost")
	return _piece(element)
func native_record(c:PlacedBlock)->Dictionary:
	return {"element":str(c.element),"pose":str(c.transform),"size":str(c.size),"collision_transform":str(c._collision_shapes[0].transform),"collision_size":str(c._collision_shapes[0].shape.size),"key":c.store_key(),"hinge":str(c.get_node("E3View/Hinge").position),"capacity":sim.store_room(c.store_key())+sim.store_units(c.store_key())}
func inspect_case(c:PlacedBlock,label:String,support:float,obstacle:PlacedBlock=null)->void:
	var state:Node3D=c.get_node("E3View")
	var before:=native_record(c)
	var bounds:=visual_bounds(state,c)
	var world_bounds:AABB=c.global_transform*bounds
	var native:=AABB(Vector3(-.5,-.5,-.4),Vector3(1,.7,.8))
	check(native.grow(.0001).encloses(bounds),label+" visual stays inside native closed envelope")
	check(c._mesh.mesh.get_aabb().is_equal_approx(bounds),label+" closed preview and placed geometry agree")
	var info:Dictionary={"id":label,"family":String(c.material_family),"native":before,"closed_local":str(bounds),"visible_bottom_world":world_bounds.position.y,"support_top_world":support,"gap_m":world_bounds.position.y-support,"closed_top_world":world_bounds.end.y,"preview_bounds":str(c._mesh.mesh.get_aabb())}
	var geometry:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://e3/geometry.json"))["chest_"+String(c.material_family)+"_body"]
	if geometry.has("seating"):
		var seat:Dictionary=geometry.seating
		info.cabinet_bottom_world=c.global_position.y+float(seat.cabinet_bounds_blender[0][2])
		info.cabinet_gap_m=float(info.cabinet_bottom_world)-support
		info.concealed_foot_depth_m=maxf(0.0,-float(info.gap_m))
		check(float(info.cabinet_gap_m)>=-.0001,label+" cabinet clears support surface")
		var actual:=E3HomeArt.part("chest_"+String(c.material_family)+"_body")
		var foot_vertices:=0
		var feet_only:=true
		for surface in actual.get_surface_count():
			var vertices:PackedVector3Array=actual.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
			for vertex in vertices:
				if vertex.y<float(seat.cabinet_bounds_blender[0][2])-.00001:
					foot_vertices+=1
					feet_only=feet_only and absf(absf(vertex.x)-float(seat.foot_x_m))<=float(seat.foot_width_m)*.5+.0001 and absf(absf(vertex.z)-float(seat.foot_depth_m))<=float(seat.foot_width_m)*.5+.0001
		check(foot_vertices>0 and feet_only,label+" only four exported inset feet extend below the clear cabinet")
	player.placement.set_build_mode_enabled(true)
	var owned:=sim.export_json();var count:=sim.structure_piece_count()
	player.placement.select_shape(&"chest");player.build_palette.select_material(c.material_family);selected=""
	player.placement.preview_element=c.element;player.placement.preview_visible=true
	check(not player.placement.try_place_block(),label+" duplicate refuses")
	check(sim.export_json()==owned and sim.structure_piece_count()==count,label+" refusal retains payment and one owner")
	player.placement.set_build_mode_enabled(false)
	view(c.global_position+Vector3(0,-.12,0),2.3)
	await snap(label+"-closed",label+(" / cabinet gap %.4f m; concealed feet %.4f m"%[float(info.cabinet_gap_m),float(info.concealed_foot_depth_m)] if info.has("cabinet_gap_m") else " / inherited base gap %.4f m"%float(info.gap_m)))
	check(_aim(c,c.global_position+Vector3(0,.8,2),c.global_position+Vector3(0,-.10,.39)),label+" actual ray targets unchanged body")
	player.interact();check(player.chest_panel.is_open() and player.chest_panel.chest==c,label+" E opens sole native store")
	player.chest_panel.hide()
	view(c.global_position+Vector3(0,.20,0),3.0)
	for frame in 40:
		await get_tree().physics_frame
		if label=="ordinary-slab" and mode=="capture" and frame%2==0:await snap("motion-open-%02d"%frame,"Actual panel-driven opening / physical frame "+str(frame))
	check(is_equal_approx(state.angle,-deg_to_rad(78.0)),label+" actual delta opens retained 78 degree lid")
	var open_bounds:=visual_bounds(state,c);info.open_local=str(open_bounds);info.open_top_world=(c.global_transform*open_bounds).end.y
	if obstacle!=null:
		var obstacle_box:AABB=obstacle.global_transform*obstacle._mesh.mesh.get_aabb()
		info.obstacle_bounds=str(obstacle_box);info.closed_obstacle_overlap=str(world_bounds.intersection(obstacle_box));info.open_obstacle_overlap=str((c.global_transform*open_bounds).intersection(obstacle_box))
	sim.add_materials({"wood":17,"stone":23})
	check(player.chest_panel.store(&"wood",17)==17 and player.chest_panel.store(&"stone",23)==23,label+" paid deposit exact")
	check(player.chest_panel.take(&"stone",3)==3,label+" paid withdrawal exact")
	check(sim.store_contents(c.store_key())=={"wood":17,"stone":20} and sim.store_room(c.store_key())==923,label+" same 960-unit shared capacity")
	await snap(label+"-open",label+" / full floor, cavity and retained lid sweep")
	player.chest_panel.close_panel();player.chest_panel.show()
	for frame in 40:await get_tree().physics_frame
	check(is_zero_approx(state.angle),label+" natural closing")
	check(native_record(c)==before,label+" visual operation preserves native body/pose/hinge/key/capacity")
	r5.cases.append(info)
func r5_restore()->void:
	var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://r5-expected.json"))
	for repeat in 2:
		check(manager.read("user://r5-storage.json",player),"fresh-process restore "+str(repeat)+": "+manager.last_error)
		check(JSON.parse_string(sim.export_json())==expected.native,"fresh exact native ownership")
		check(JSON.parse_string(JSON.stringify(manager.capture(player).blocks))==expected.blocks,"fresh exact saved geography and poses")
		var count:=0
		for c in get_children():
			if c is PlacedBlock and c.is_chest():
				count+=1
				check(c.get_node("E3View").angle==0 and sim.store_units(c.store_key())==37,"restored closed chest and exact contents")
		check(count==12,"exactly twelve restored paid chest owners")
	await settle()
func r5_bench()->void:
	view(Vector3(7,.3,0),12);caption.text="R5 settled 12-chest fixture / no capture"
	await settle(120)
	var values:Array[float]=[];var previous:=Time.get_ticks_usec()
	for frame in 300:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec();values.append((now-previous)/1000.0);previous=now
	values.sort();r5.benchmark={"samples":300,"p50_ms":values[150],"p95_ms":values[285],"worst_ms":values[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)}
func done()->void:
	r5.checks=checks;r5.failures=failures;r5.backend=backend;r5.gpu=RenderingServer.get_video_adapter_name();r5.viewport=str(get_viewport().size);r5.msaa="4x";r5.vsync="off"
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(r5,"  "))
	print("R5_",mode.to_upper()," ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func snap(name: String, text: String) -> void:
	caption.text="ART-07R5 / "+backend+"\n"+text
	if mode!="capture":return
	await settle(2)
	await RenderingServer.frame_post_draw
	if name.begins_with("motion-"):
		if not r5.has("motion_frames"):r5.motion_frames=[]
		var chest:PlacedBlock=player.chest_panel.chest
		r5.motion_frames.append({"image":name+".png","capture_usec":Time.get_ticks_usec(),"lid_angle_radians":chest.get_node("E3View").angle,"native_pose":str(chest.transform)})
	check(get_viewport().get_texture().get_image().save_png(output+"/"+name+".png")==OK,"actual R5 capture "+name)