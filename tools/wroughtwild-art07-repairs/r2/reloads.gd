extends "res://g1/paid.gd"
## Paid-checkpoint reuse, real finite source release, and a separate-process restore.
const R2_SAVE="user://r2-reloads.json"
const OWNERS=["sim","leylines","contraptions","blocks","stations","resource_nodes"]
func execute():
	get_window().size=Vector2i(1440,900)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var manager:=SaveManager.new()
	output="res://../evidence/r2-reloads-paced-"+("headless" if DisplayServer.get_name()=="headless" else RenderingServer.get_current_rendering_method())
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var restart:="--r2-restart" in OS.get_cmdline_user_args()
	var file:=R2_SAVE if restart else "res://g1/paid-home.json"
	check(manager.read(file,player),"R2 actual checkpoint read: "+manager.last_error)
	freeze_fixtures();refresh_stations();terrain.set_process(false)
	var expected:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(file)) if restart else JSON.parse_string(FileAccess.get_file_as_string("res://r2/reference-probe.json")).snapshot
	var state:=manager.capture(player)
	for key in OWNERS:check(r2_saved_equal(state[key],expected[key]),"R2 initial exact owner: "+key)
	var geography:=JSON.stringify(terrain.map).sha256_text()
	var home_position:=player.position
	var first_use_boundary_ms:float=await r2_frame_boundary()
	var initial_cost:=costs()
	var cycles:Array=[]
	if not restart:
		for cycle in 3:
			var start:=Time.get_ticks_usec()
			terrain.ensure_area(route[66],64);terrain.resource_stream.focus(route[66],true)
			var route_first_use_ms:float=await r2_frame_boundary()
			terrain.ensure_area(home_position,64);terrain.resource_stream.focus(home_position,true)
			var home_first_use_ms:float=await r2_frame_boundary()
			check(manager.read(file,player),"R2 repeated ordinary home read")
			freeze_fixtures();refresh_stations();terrain.set_process(false)
			var restored:=manager.capture(player)
			for key in OWNERS:check(r2_saved_equal(restored[key],state[key]),"R2 repeated home/route exact owner: "+key)
			check(JSON.stringify(terrain.map).sha256_text()==geography,"R2 repeated route geography exact")
			check(player.placement.enclosure_at(player.position).enclosed,"R2 paid home remains sheltered")
			var restore_first_use_ms:float=await r2_frame_boundary()
			cycles.append({"route_first_use_boundary_ms":route_first_use_ms,"home_first_use_boundary_ms":home_first_use_ms,"restore_first_use_boundary_ms":restore_first_use_ms,"cycle":cycle+1,"reload_and_focus_ms":float(Time.get_ticks_usec()-start)/1000.0,"cost":costs()})
		# This inherited G1 flow performs actual native work, retires/re-enters
		# the actor, restores partial work, then exhausts it with one payout.
		await harvest_and_stream()
		player.position=home_position;player.velocity=Vector3.ZERO
		check(manager.write(R2_SAVE,player),"R2 save after actual release/re-entry and exhaustion")
		state=manager.capture(player)
	else:
		for frame in 15:await get_tree().process_frame
		var restored:=manager.capture(player)
		for key in OWNERS:check(r2_saved_equal(restored[key],state[key]),"R2 fresh process final-hook owner stable: "+key)
		check(JSON.stringify(terrain.map).sha256_text()==geography,"R2 fresh process geography remains exact")
	FileAccess.open(output+("/restart.json" if restart else "/flow.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"geography_sha256":geography,"snapshot":state,"cycles":cycles,"first_use_boundary_ms":first_use_boundary_ms,"initial_cost":initial_cost,"final_cost":costs(),"renderer":RenderingServer.get_current_rendering_method(),"engine":Engine.get_version_info(),"gpu":RenderingServer.get_video_adapter_name(),"viewport":str(get_window().size),"msaa":get_viewport().msaa_3d,"vsync":DisplayServer.window_get_vsync_mode(),"scope":"Three scripted focus/load cycles, real native partial work and finite depletion; not elapsed-hours or human play evidence."},"  "))
	print("R2_RELOAD_CHECKS ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func r2_saved_equal(a:Variant,b:Variant)->bool:
	# Compare every persisted value without Godot int-versus-JSON-float type noise.
	return JSON.parse_string(JSON.stringify(a))==JSON.parse_string(JSON.stringify(b))

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

func r2_frame_boundary()->float:
	# Exercise a real visit before retiring its newly created rendering instances.
	var started:=Time.get_ticks_usec()
	for frame in 2:await get_tree().process_frame
	if DisplayServer.get_name()!="headless":await RenderingServer.frame_post_draw
	return float(Time.get_ticks_usec()-started)/1000.0
