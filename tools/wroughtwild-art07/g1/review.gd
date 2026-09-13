extends "res://g1/paid.gd"
## Current paid save, matched cameras/renderers; no image capture during timing.
var camera:Camera3D
var caption:Label
func execute():
	get_window().size=Vector2i(1440,900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	output="res://../evidence/"+("benchmark-" if "--benchmark" in OS.get_cmdline_user_args() else "views-")+("art-" if G1Art.enabled() else "baseline-")+RenderingServer.get_current_rendering_method()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	check(SaveManager.new().read("res://g1/paid-home.json",player),"actual paid retained checkpoint loads")
	freeze_fixtures();refresh_stations()
	player.hide();player.hud.hide();player.camera.current=false;mood.set_process(false)
	camera=Camera3D.new();camera.fov=60;add_child(camera);camera.current=true
	var layer:=CanvasLayer.new();add_child(layer);caption=Label.new();layer.add_child(caption)
	caption.position=Vector2(22,20);caption.add_theme_font_size_override("font_size",20)
	var interior:=player.position
	var views:Array=[
		{"id":"paid-home","at":interior,"eye":interior+Vector3(8,5,-13),"target":interior+Vector3(0,0,1)},
		{"id":"paid-interior","at":interior,"eye":interior+Vector3(.2,.55,-1),"target":interior+Vector3(2,-.25,2)},
		{"id":"paid-workshop","at":route[0],"eye":route[0]+Vector3(15,6,15),"target":route[0]+Vector3(7,1,7)},
		{"id":"source-trail","at":route[66],"eye":route[66]+Vector3(0,1.65,0),"target":route[76]+Vector3.UP*1.65}]
	if not "--benchmark" in OS.get_cmdline_user_args():
		for source in get_tree().get_nodes_in_group("leyline_sources"):
			views.append({"id":source.source_id,"at":source.position,"eye":source.position+Vector3(2.2,1.7,2.5),"target":source.position+Vector3.UP*.55})
		for family in ["pine","bog_oak","raw_clay","raw_reed","slate","shellstone","resinheart_log","raw_corkbark","ash_wood"]:
			for id in terrain.resource_stream.records:
				var r:Dictionary=terrain.resource_stream.records[id]
				if r.family!=family or int(r.get("era",1))>1:continue
				var p:Array=r.position;var at:=Vector3(p[0],p[1],p[2])
				var tall:=String(r.visual) in ["tree","resinheart_tree"]
				views.append({"id":"regional-"+family,"native_id":id,"at":at,"eye":at+(Vector3(5,3.5,7) if tall else Vector3(2.5,2.1,3)),"target":at+Vector3.UP*(2.5 if tall else .5)})
				break
	var samples:Array=[]
	var viewport:=get_viewport().get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(viewport,true)
	for view:Dictionary in views:
		player.position=view.at+Vector3(0,1.2,4)
		terrain.ensure_area(view.at,64);terrain.resource_stream.focus(view.at,true);terrain.set_process(false)
		camera.position=view.eye;camera.look_at(view.target)
		for lighting in ["day","dusk"]:
			mood._target=mood.active_mood(mood._biome_under_player());mood._apply(1.0)
			if lighting=="dusk":$Sun.light_energy*=.35;$Sun.light_color=Color("d9bd91")
			caption.text="ART-07G1 / "+RenderingServer.get_current_rendering_method()+" / "+("ART" if G1Art.enabled() else "BASELINE")+"\n"+String(view.id)+" / "+lighting+(" / native "+String(view.native_id) if view.has("native_id") else "")
			for frame in 120 if "--benchmark" in OS.get_cmdline_user_args() else 12:await get_tree().process_frame
			if "--benchmark" in OS.get_cmdline_user_args():
				var wall:Array[float]=[];var gpu:Array[float]=[];var cpu:Array[float]=[]
				var previous:=Time.get_ticks_usec()
				for frame in 300:
					await get_tree().process_frame
					var now:=Time.get_ticks_usec();wall.append(float(now-previous)/1000.0);previous=now
					gpu.append(RenderingServer.viewport_get_measured_render_time_gpu(viewport));cpu.append(RenderingServer.viewport_get_measured_render_time_cpu(viewport))
				wall.sort();gpu.sort();cpu.sort()
				var ids:Array=terrain.resource_stream.active.keys();ids.sort()
				samples.append({"scene":view.id,"lighting":lighting,"samples":300,"camera":str(camera.position),"target":str(view.target),"resources":ids.size(),"resource_ids_sha256":str(ids).sha256_text(),"chunks":terrain.chunks.size(),"frame_median_ms":wall[150],"frame_p95_ms":wall[285],"gpu_median_ms":gpu[150],"gpu_p95_ms":gpu[285],"render_cpu_median_ms":cpu[150],"draw_calls":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"primitives":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),"cost":costs()})
			else:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(output+"/"+String(view.id)+"-"+lighting+".png")
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify({"base":"6bb2e044dcd0bf1788896aa2c19cdf56fee93522","art":G1Art.enabled(),"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"viewport":str(get_viewport().size),"vsync":DisplayServer.window_get_vsync_mode(),"views":views,"samples":samples,"cost":costs(),"failures":failures},"  "))
	print("G1_REVIEW_OK ",views.size()," views, ",samples.size()," matched samples")
	get_tree().quit(1 if failures else 0)

func costs() -> Dictionary:
	var meshes:Dictionary={};var instances:=0;var unique_triangles:=0;var surfaces:=0;var vertices:=0;var indices:=0
	for node in find_children("*","Node3D",true,false):
		var mesh:Mesh
		if node is MeshInstance3D:mesh=node.mesh;instances+=1
		if node is MultiMeshInstance3D and node.multimesh!=null:mesh=node.multimesh.mesh;instances+=node.multimesh.instance_count
		if mesh!=null:meshes[mesh.get_instance_id()]=mesh
	for mesh:Mesh in meshes.values():
		surfaces+=mesh.get_surface_count()
		for i in mesh.get_surface_count():
			var arrays:Array=mesh.surface_get_arrays(i)
			var vc:int=arrays[Mesh.ARRAY_VERTEX].size()
			var ic:int=arrays[Mesh.ARRAY_INDEX].size() if arrays[Mesh.ARRAY_INDEX]!=null else 0
			vertices+=vc;indices+=ic;unique_triangles+=(ic if ic>0 else vc)/3
	return {"texture_bytes_total_loaded":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED),"buffer_bytes_total_loaded":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_BUFFER_MEM_USED),"video_bytes_total_loaded":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED),"scene_unique_meshes_including_hidden":meshes.size(),"mesh_instances_including_multimesh_and_hidden":instances,"scene_unique_triangles":unique_triangles,"scene_unique_surfaces":surfaces,"scene_unique_vertices":vertices,"scene_unique_indices":indices,"scope":"Backend total loaded texture/buffer/video allocations, plus all live scene geometry including hidden resource stages, LODs and MultiMesh references. Buffer totals include caches and non-geometry renderer buffers; triangle count is unique live-scene base meshes, not multiplied by instances."}
