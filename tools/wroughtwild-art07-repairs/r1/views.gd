extends "res://g1/review.gd"
## Same pinned paid world and cameras for delivered G1 / R1; no capture during timing.
var shape_cache:Dictionary={}
func execute():
	get_window().size=Vector2i(1440,900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	var mode:="before" if "--r1-before" in OS.get_cmdline_user_args() else "after"
	var timing:bool="--benchmark" in OS.get_cmdline_user_args()
	output="res://../evidence/r1-"+("cost-v02-" if timing else "views-v02-")+mode+"-"+RenderingServer.get_current_rendering_method()
	assert(not DirAccess.dir_exists_absolute(output),"Fresh evidence only")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	check(SaveManager.new().read("res://g1/paid-home.json",player),"actual paid retained checkpoint loads")
	freeze_fixtures();refresh_stations()
	var setup_ms:=Time.get_ticks_msec()
	player.hide();player.hud.hide();player.camera.current=false;mood.set_process(false)
	camera=Camera3D.new();camera.fov=60;add_child(camera);camera.current=true
	var layer:=CanvasLayer.new();add_child(layer);caption=Label.new();layer.add_child(caption)
	caption.position=Vector2(22,20);caption.add_theme_font_size_override("font_size",20)
	var interior:=player.position
	var home_eye:=interior+Vector3(8,0,-13)
	var route_eye:=route[66]
	var route_target:=route[76]
	var views:Array=[{"id":"home-player-height","at":interior,"eye":home_eye,"target":interior+Vector3(0,.72,1)},{"id":"route-player-height","at":route[66],"eye":route_eye,"target":route_target}]
	for family in ["pine","ash_wood"]:
		for id in terrain.resource_stream.records:
			var r:Dictionary=terrain.resource_stream.records[id]
			if r.family!=family or int(r.get("era",1))>1:continue
			var at:=Vector3(r.position[0],r.position[1],r.position[2])
			var eye:=at+Vector3(5,0,7)
			views.append({"id":family+"-player-height","native_id":id,"at":at,"eye":eye,"target":at+Vector3.UP*3})
			break
	var samples:Array=[];var measurements:Array=[]
	var viewport:=get_viewport().get_viewport_rid();RenderingServer.viewport_set_measure_render_time(viewport,true)
	for view:Dictionary in views:
		player.position=view.at+Vector3(0,1.2,4)
		terrain.ensure_area(view.at,64);terrain.resource_stream.focus(view.at,true);terrain.set_process(false)
		view.eye=ground_eye(view.eye)
		if view.id=="route-player-height":view.target=ground_eye(view.target)
		view.ground_sample_y=view.eye.y-1.68
		camera.position=view.eye;camera.look_at(view.target)
		if not timing:measurements.append(measure_crowns(view))
		for lighting in ["day","shade","dusk"]:
			mood._target=mood.active_mood(mood._biome_under_player());mood._apply(1.0)
			if lighting=="shade":$Sun.light_energy*=.12
			if lighting=="dusk":$Sun.light_energy*=.35;$Sun.light_color=Color("d9bd91")
			caption.text="ART-07R1 / "+mode+" / "+RenderingServer.get_current_rendering_method()+"\n"+String(view.id)+" / "+lighting+" / eye 1.68 m above sampled ground"
			for frame in 120 if timing else 18:await get_tree().process_frame
			if timing:
				var wall:Array[float]=[];var gpu:Array[float]=[];var cpu:Array[float]=[];var previous:=Time.get_ticks_usec()
				for frame in 300:
					await get_tree().process_frame
					var now:=Time.get_ticks_usec();wall.append(float(now-previous)/1000.0);previous=now
					gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport));cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport))
				wall.sort();gpu.sort();cpu.sort()
				samples.append({"scene":view.id,"lighting":lighting,"samples":300,"camera":str(camera.position),"target":str(view.target),"frame_median_ms":wall[150],"frame_p95_ms":wall[285],"frame_worst_ms":wall[-1],"gpu_median_ms":gpu[150],"gpu_p95_ms":gpu[285],"gpu_worst_ms":gpu[-1],"render_cpu_median_ms":cpu[150],"draw_calls":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"primitives":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"cost":costs()})
			else:
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(output+"/"+String(view.id)+"-"+lighting+".png")==OK,"actual matched capture")
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify({"runtime_base":"6bb2e044dcd0bf1788896aa2c19cdf56fee93522","mode":mode,"setup_ms":setup_ms,"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(get_viewport().size),"msaa":"4x","vsync":DisplayServer.window_get_vsync_mode(),"views":views,"samples":samples,"measurements":measurements,"cost":costs(),"failures":failures},"  "))
	print("R1_VIEWS_OK ",mode," ",views.size()," views ",samples.size()," timed samples ",failures," failures")
	get_tree().quit(1 if failures else 0)
func measure_crowns(view:Dictionary)->Dictionary:
	var rows:Array=[];var viewport_rect:=Rect2(Vector2.ZERO,Vector2(1440,900))
	for node in get_tree().get_nodes_in_group("resources"):
		if not node.has_meta("b1_fit") and node.get_meta("g1_source","")!="c4":continue
		var pivot:MeshInstance3D=node.get_node("MeshInstance3D")
		if pivot.get_child_count()==0:continue
		var model:Node3D=pivot.get_child(0)
		var key:=String(node.material_family)
		var burial:float=node.art_burial if node.has_meta("b1_fit") else 0.0
		if not shape_cache.has(key):
			var upper:=AABB();var lower:=AABB();var first_upper:=true;var first_lower:=true
			for mesh:MeshInstance3D in model.find_children("*","MeshInstance3D",true,false):
				for surface in mesh.mesh.get_surface_count():
					for vertex:Vector3 in mesh.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
						var p:Vector3=model.global_transform.affine_inverse()*mesh.global_transform*vertex
						if p.y-burial>2.6:
							upper=AABB(p,Vector3.ZERO) if first_upper else upper.expand(p);first_upper=false
						elif p.y-burial>=0:
							lower=AABB(p,Vector3.ZERO) if first_lower else lower.expand(p);first_lower=false
			shape_cache[key]={"upper":upper,"lower":lower}
		var bounds:AABB=shape_cache[key].upper
		var rect:=Rect2();var first:=true;var near:=false;var wmin:=INF;var wmax:=-INF
		for i in 8:
			var p:Vector3=model.global_transform*bounds.get_endpoint(i)
			if camera.is_position_behind(p):near=true;break
			var screen:=camera.unproject_position(p)
			rect=Rect2(screen,Vector2.ZERO) if first else rect.expand(screen);first=false
			var w:=camera.global_basis.x.dot(p);wmin=minf(wmin,w);wmax=maxf(wmax,w)
		if near or not rect.intersects(viewport_rect):continue
		rows.append({"id":node.resource_id,"family":node.material_family,"position":str(node.position),"body":str(node.get_node("CollisionShape3D").shape.size),"model_scale":str(model.scale),"crown_width_camera_m":wmax-wmin,"crown_rect_px":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"source_crown_bounds":str(bounds),"source_lower_bounds":str(shape_cache[key].lower),"visibility_end":pivot.visibility_range_end})
	var overlaps:Array=[]
	for a in rows.size():
		for b in range(a+1,rows.size()):
			var x:Array=rows[a].crown_rect_px;var y:Array=rows[b].crown_rect_px
			var hit:=Rect2(x[0],x[1],x[2],x[3]).intersection(Rect2(y[0],y[1],y[2],y[3])).intersection(viewport_rect)
			if hit.has_area():overlaps.append({"a":rows[a].id,"b":rows[b].id,"overlap_px2":hit.get_area()})
	return {"camera_id":view.id,"eye":str(view.eye),"target":str(view.target),"trees":rows,"overlaps":overlaps,"scope":"Projected actual imported upper-mesh AABBs, clipped to camera. Conservative geometric overlap, not measured opaque leaf coverage; review the matched rendered images."}

func ground_eye(point:Vector3)->Vector3:
	# Query after the view's real chunks are ensured; sample the same triangles
	# used by walking. The native cell height is a reference, not a fallback.
	var cell:float=terrain.map.cell_size
	var reference:Vector3=terrain.surface_position(floori(point.x/cell),floori(point.z/cell))
	var ground:float=terrain.rendered_height(point.x,point.z,reference.y,4.0)
	check(is_finite(ground),"R1 camera has finite actual terrain support at "+str(point))
	assert(is_finite(ground),"Missing rendered support; do not capture a guessed camera")
	return Vector3(point.x,ground+1.68,point.z)
