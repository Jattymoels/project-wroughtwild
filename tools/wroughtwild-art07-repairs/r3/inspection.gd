extends "res://tests/home_workshop_review.gd"
## Labelled native inspection stock. No stock or unlock enters the real paid home.
var output: String
var pieces: Array[PlacedBlock] = []
var observations: Array = []
var views: Array = []
var assertion_rows: Array = []
var caption: Label
var r3_camera: Camera3D
var benchmark := false

func check(ok: bool, label: String) -> bool:
	assertion_rows.append({"ok":ok,"label":label})
	return super.check(ok,label)

func _run() -> void:
	get_window().size=Vector2i(1440,900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	benchmark="--benchmark" in OS.get_cmdline_user_args()
	if benchmark:RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var run_id:="first"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--run-id="):run_id=arg.get_slice("=",1)
	output="res://../evidence/r3-"+run_id+"-"+("candidate" if R3Materials.enabled() else "g1")+"-"+RenderingServer.get_current_rendering_method()
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"fresh evidence directory")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	check(not sim.shape_unlocked("roof_wedge"),"existing roof unlock starts closed")
	sim.record_world_effect("stonecut_blocks")
	for family in sim.build_material_ids():sim.add_material(String(sim.build_material(family).source),4000)
	# Two coarse panels joined to four fine panels; no whole-map scaling per piece.
	_put("wall_panel","wood",Vector3i(0,2,0))
	_put("wall_panel","wood",Vector3i(2,2,0))
	for x in [4,5]:
		for y in [2,3]:_put("half_wall","wood",Vector3i(x,y,0))
	_put("pillar","wood",Vector3i(0,2,4),1)
	_put("beam","wood",Vector3i(0,4,4),0)
	_put("half_beam","wood",Vector3i(2,4,4),0)
	_put("half_beam","wood",Vector3i(3,4,4),0)
	_put("floor_slab","wood",Vector3i(0,2,4),1)
	_put("half_slab","wood",Vector3i(2,2,4),1)
	_put("half_slab","wood",Vector3i(3,2,4),1)
	_put("door","wood",Vector3i(6,2,0),2,0)
	_put("door","wood",Vector3i(10,2,0),2,1)
	_put("stairs","wood",Vector3i(8,2,4),0,1)
	_put("codex_corner_floor","wood",Vector3i(4,2,4),1,1)
	for i in 4:
		var family: String=["stone","slate","shellstone","rustclay_brick"][i]
		var x:=i*6
		_put("wall_panel",family,Vector3i(x,2,20))
		_put("half_wall",family,Vector3i(x+2,2,20))
		_put("half_wall",family,Vector3i(x+2,3,20))
		_put("wall_panel",family,Vector3i(x,2,20),0)
		_put("floor_slab",family,Vector3i(x,2,24),1)
		_put("codex_corner_floor",family,Vector3i(x+2,2,24),1,i)
	for i in 4:
		var family: String=["iron","bronze","steel","silver"][i]
		var x:=i*6
		_put("girder",family,Vector3i(x,2,40),0)
		_put("beam",family,Vector3i(x,4,40),2)
		_put("wall_panel",family,Vector3i(x,2,44))
		if family in ["bronze","silver"]:_put("arch",family,Vector3i(x+2,2,44))
		else:_put("door",family,Vector3i(x+2,2,44))
	for i in 3:
		var family: String=["woven_reed","corkbark","vitrified_basalt"][i]
		_put("light_panel",family,Vector3i(i*4,2,60))
		_put("codex_roof_slope",family,Vector3i(i*4,2,64),0,i)
	# Layered and perpendicular fixed panes; opaque target reveals wrong sorting.
	for z in [72,74,76]:_put("glazed_window","cinderglass",Vector3i(0,2,z))
	_put("glazed_window","cinderglass",Vector3i(2,2,74),0)
	for i in 8:
		var target:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=Vector3(.125,1,.02)
		target.mesh=box;target.position=Vector3(.0625+i*.125,1.5,39)
		var mat:=StandardMaterial3D.new();mat.albedo_color=Color("ece8d0") if i%2==0 else Color("293640")
		target.material_override=mat;add_child(target)
	# Retained chamfers and triangle tops define an octagonal inspection ring.
	var corners:=[Vector3i(0,2,90),Vector3i(6,2,90),Vector3i(6,2,96),Vector3i(0,2,96)]
	for i in 4:
		_put("codex_corner","wood",corners[i],0,i)
		_put("codex_corner_floor","slate",corners[i]+Vector3i(0,2,0),1,i)
	for x in [2,4]:
		_put("wall_panel","wood",Vector3i(x,2,90))
		_put("wall_panel","wood",Vector3i(x,2,98))
	for z in [92,94]:
		_put("wall_panel","wood",Vector3i(0,2,z),0)
		_put("wall_panel","wood",Vector3i(8,2,z),0)
	for i in 4:
		_put("codex_roof_hip","slate",Vector3i(12+i*3,2,90),0,i)
		_put("codex_roof_valley","wood",Vector3i(12+i*3,2,94),0,i)
	player.placement.set_build_mode_enabled(false);player.hide();player.hud.hide()
	var native_before:=sim.export_json()
	for piece in pieces:
		check(piece._mesh.mesh.get_meta("r3_shape","")==String(piece.shape_id),"shape metadata retains actual shape")
		var mesh:=piece._mesh.mesh
		var signature:=PackedByteArray()
		var triangles:=0
		for surface in mesh.get_surface_count():
			var a:=mesh.surface_get_arrays(surface)
			for index in [Mesh.ARRAY_VERTEX,Mesh.ARRAY_NORMAL,Mesh.ARRAY_INDEX]:signature.append_array(var_to_bytes(a[index]))
			triangles+=(a[Mesh.ARRAY_INDEX].size() if a[Mesh.ARRAY_INDEX]!=null else a[Mesh.ARRAY_VERTEX].size())/3
		var hc:=HashingContext.new();hc.start(HashingContext.HASH_SHA256);hc.update(signature)
		observations.append({"shape":String(piece.shape_id),"family":String(piece.material_family),"element":str(piece.element),"pose":str(piece.transform),"triangles":triangles,"surfaces":mesh.get_surface_count(),"geometry_sha256":hc.finish().hex_encode(),"body":str(piece.size),"colliders":piece._collision_shapes.size()})
	check(sim.export_json()==native_before,"material/geometry inspection changes no native state")
	if R3Materials.enabled():
		for twin in [["beam","half_beam"],["wall_panel","half_wall"],["floor_slab","half_slab"]]:
			var coarse:=R3Materials.material_for("wood","surface",twin[0]) as ShaderMaterial
			var fine:=R3Materials.material_for("wood","surface",twin[1]) as ShaderMaterial
			check(coarse.get_shader_parameter("face_repeat")==fine.get_shader_parameter("face_repeat"),"coarse/fine metric face scale: "+twin[0])
			check(coarse.get_shader_parameter("edge_repeat")==fine.get_shader_parameter("edge_repeat"),"coarse/fine metric edge scale: "+twin[0])
			check(coarse.get_shader_parameter("face_albedo")==fine.get_shader_parameter("face_albedo"),"shared original face image: "+twin[0])
		check((R3Materials.material_for("cinderglass","surface","glazed_window",1) as ShaderMaterial).shader==R3Materials.opaque_shader,"glass frame stays in opaque pass")
		check((R3Materials.material_for("cinderglass","surface","glazed_window",0) as ShaderMaterial).shader==R3Materials.glass_shader,"only glass pane uses alpha pass")
	var layer:=CanvasLayer.new();add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(22,20);caption.add_theme_font_size_override("font_size",21)
	r3_camera=Camera3D.new();add_child(r3_camera);r3_camera.current=true;r3_camera.fov=55
	views=[
		{"id":"wood-joins-eye","eye":Vector3(3.8,1.65,7),"target":Vector3(2,1.45,.7)},
		{"id":"wood-end-close","eye":Vector3(2.6,2.7,3.8),"target":Vector3(.9,1.85,2)},
		{"id":"mineral-bedding-eye","eye":Vector3(6,1.65,16),"target":Vector3(5,1.4,10.8)},
		{"id":"slate-cut-close","eye":Vector3(5.4,2.7,14.3),"target":Vector3(3.9,1.2,12)},
		{"id":"metal-joins-eye","eye":Vector3(6,1.65,17),"target":Vector3(5.5,1.5,21)},
		{"id":"covering-edge-close","eye":Vector3(5.9,2.5,34.8),"target":Vector3(2.5,1.4,30.8)},
		{"id":"glass-layered-front","eye":Vector3(1.5,1.65,34),"target":Vector3(.5,1.5,38)},
		{"id":"glass-sorting-axis","eye":Vector3(.5,1.65,33),"target":Vector3(.5,1.5,39)},
		{"id":"glass-layered-back","eye":Vector3(-1.6,1.65,39.5),"target":Vector3(.5,1.5,36.8)},
		{"id":"octagon-triangles-eye","eye":Vector3(6.8,1.65,41),"target":Vector3(2,1.5,47)},
		{"id":"roofs-rotations-close","eye":Vector3(9,3.8,49),"target":Vector3(8,1.5,46.5)}]
	for view: Dictionary in views:
		for light in ["daylight","shade","dusk"]:
			_set_light(light)
			r3_camera.position=view.eye;r3_camera.look_at(view.target)
			caption.text="ART-07R3 / "+("CANDIDATE" if R3Materials.enabled() else "SEALED G1")+" / "+RenderingServer.get_current_rendering_method()+"\n"+String(view.id)+" / "+light+" / labelled catalogue inspection stock"
			for frame in 120 if benchmark else 12:await get_tree().process_frame
			if benchmark: await _measure(view,light)
			else:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(output+"/"+String(view.id)+"-"+light+".png")
	if not benchmark and R3Materials.enabled():
		_set_light("daylight")
		for mat: ShaderMaterial in R3Materials.cache.values():mat.set_shader_parameter("inspection",1)
		r3_camera.position=views[1].eye;r3_camera.look_at(views[1].target)
		caption.text="ART-07R3 / metric inspection only / 10 cm grid\nBrown = face, blue = cut / original geometry / full and fine density"
		for frame in 12:await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(output+"/metric-10cm.png")
		for mat: ShaderMaterial in R3Materials.cache.values():mat.set_shader_parameter("inspection",0)
	var result:={"checks":checks,"assertions":assertion_rows,"failures":failures,"scope":"Native inspection-stock assembly; camera/light comparisons, separate from the real paid home. No new forms or gameplay objects.","gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"size":str(get_window().size),"msaa":get_viewport().msaa_3d,"vsync":DisplayServer.window_get_vsync_mode(),"geometry":observations,"views":views,"samples":report.views,"cost":_cost(),"material_bindings":R3Materials.binding_inventory()}
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("R3_INSPECTION ",checks," checks, ",failures," failures, ",pieces.size()," retained pieces")
	get_tree().quit(1 if failures else 0)

func _put(id: String, family: String, cell: Vector3i, axis: int=2, turn: int=0) -> void:
	var def: Dictionary=sim.shape(id)
	var kind: String="volume" if def.element=="block" else "face" if def.element in ["wall","floor"] else "edge"
	var elem:={"kind":kind,"axis":0 if kind=="volume" else axis,"cell":cell}
	var build:=player.placement
	player.position=Vector3(cell)*.5+Vector3(-2,2,-2)
	build.set_build_mode_enabled(true);build.fine_mode=id.begins_with("half_")
	build.selected_material_family=StringName(family)
	var base_id: String=def.get("fine_of","")
	build.select_shape(StringName(id if base_id.is_empty() else base_id))
	build.preview_element=elem;build.preview_visible=true;build.preview_rotation_step=turn
	var source:String=sim.build_material(family).source;var held:=sim.material_count(source);var count:=sim.structure_piece_count()
	if not check(build.try_place_block(),"inspection native placement "+id+"/"+family+" at "+str(cell)+": "+build.preview_reason):return
	check(sim.material_count(source)==held-int(def.material_cost) and sim.structure_piece_count()==count+1,"exact inspection payment and one owner")
	var piece:=_piece(elem)
	if check(piece!=null,"one native physical object"):pieces.append(piece)
	check(not build.try_place_block() and sim.material_count(source)==held-int(def.material_cost),"duplicate placement retains material")

func _set_light(id: String) -> void:
	sun.rotation=Vector3(-.85,-.55,0);sun.light_color=Color("fff1d5");sun.light_energy=1.15
	environment.ambient_light_energy=.45
	if id=="shade":sun.light_energy=.12;environment.ambient_light_energy=.35
	if id=="dusk":sun.rotation=Vector3(-.2,-.55,0);sun.light_energy=.4;sun.light_color=Color("d9bd91");environment.ambient_light_energy=.22

func _cost() -> Dictionary:
	return {"texture_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED),"buffer_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED),"video_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),"draw_calls":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"primitives":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)}

func _measure(view: Dictionary, light: String) -> void:
	var wall: Array[float]=[];var gpu_times: Array[float]=[];var cpu_times: Array[float]=[];var previous:=Time.get_ticks_usec()
	for frame in 300:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec();wall.append(float(now-previous)/1000.0);previous=now
		gpu_times.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
		cpu_times.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
	wall.sort();gpu_times.sort();cpu_times.sort()
	report.views.append({"view":view.id,"light":light,"samples":300,"median_ms":wall[150],"p95_ms":wall[285],"gpu_median_ms":gpu_times[150],"gpu_p95_ms":gpu_times[285],"render_cpu_median_ms":cpu_times[150],"cost":_cost(),"eye":str(view.eye),"target":str(view.target)})
