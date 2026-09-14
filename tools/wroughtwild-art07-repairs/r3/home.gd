extends "res://g1/review.gd"
## Reopen the original no-grants paid home, add one genuinely paid bench, restart.
var setup_begin := Time.get_ticks_msec()
func execute():
	get_window().size=Vector2i(1440,900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	var restoring:="--r3-restore" in OS.get_cmdline_user_args()
	var timing:="--benchmark" in OS.get_cmdline_user_args()
	if timing:RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)
	var run_id:="first"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--run-id="):run_id=arg.get_slice("=",1)
	output="res://../evidence/r3-home-"+run_id+"-"+("candidate" if R3Materials.enabled() else "g1")+"-"+RenderingServer.get_current_rendering_method()
	check(not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(output)),"fresh paid-home evidence")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var manager:=SaveManager.new()
	var save_path:="user://r3-paid-home.json"
	var source_path:=save_path if restoring else "res://g1/paid-home.json"
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(source_path))
	check(manager.read(source_path,player),"real paid home loads in process: "+manager.last_error)
	freeze_fixtures();refresh_stations();terrain.set_process(false)
	# Restored PhysicsServer bodies must register before native overlap queries.
	for frame in 2:await get_tree().physics_frame
	check(JSON.parse_string(_sim().export_json())==JSON.parse_string(saved.sim),"exact saved paid inventory/progression")
	check(_sim().leyline_save()==saved.leylines,"exact saved finite sources/work")
	check(_sim().contraption_save()==saved.contraptions,"exact saved machine ownership")
	check(player.placement.enclosure_at(player.position).enclosed,"paid home stays sheltered")
	var initial:=manager.capture(player)
	var geography:=JSON.stringify(terrain.map).sha256_text()
	var setup_seconds:=float(Time.get_ticks_msec()-setup_begin)/1000.0
	var origin:=player.position
	var original_rotation:=player.rotation
	var original_camera_position:=player.camera.position
	var original_camera_rotation:=player.camera.rotation
	var positions:Array=[]
	var motion_ticks:Array=[]
	var motion_tick_start:=0
	var motion_tick_end:=0
	if not restoring and not timing:
		check(craft("workbench_kit"),"existing held resources pay ordinary workbench recipe")
		var build:=player.placement
		var existing: StationSite
		for site in get_tree().get_nodes_in_group("crafting_stations"):
			if site.player_built:existing=site;break
		check(existing!=null,"real paid station provides obstruction")
		var c:=Vector3i(floori(existing.position.x),roundi(existing.position.y),floori(existing.position.z))
		build.set_build_mode_enabled(true);build._select_kit(&"workbench_kit")
		build.preview_element={"kind":"volume","axis":0,"cell":c*2};build.preview_visible=true
		var held:=_sim().material_count("workbench_kit")
		var before_count:=get_tree().get_nodes_in_group("crafting_stations").size()
		check(not build.try_place_block(),"existing station collision refuses new kit")
		check(_sim().material_count("workbench_kit")==held and get_tree().get_nodes_in_group("crafting_stations").size()==before_count,"failed placement retains kit and publishes nothing")
		build.set_build_mode_enabled(false)
		check(await place_paid_kit("workbench_kit",route[0]+Vector3(13,0,5)),"real paid extra kit succeeds on clear native support")
		check(_sim().material_count("workbench_kit")==held-1 and get_tree().get_nodes_in_group("crafting_stations").size()==before_count+1,"successful placement pays once and creates exactly one object")
		player.position=origin;player.velocity=Vector3.ZERO
	if restoring:
		var restored:=manager.capture(player)
		var recaptured_blocks: Array=JSON.parse_string(JSON.stringify(restored.blocks,"",true,true))
		check(recaptured_blocks==saved.blocks,"fresh-process exact building addresses and door state")
		report["restore_value_comparison"]={"saved_records":saved.blocks.size(),"recaptured_records":restored.blocks.size(),"saved_coordinate_type":type_string(typeof(saved.blocks[0].cell[0])),"live_coordinate_type":type_string(typeof(restored.blocks[0].cell[0])),"normalization":"Compare every field as its exact persistent JSON value; live integer arrays are serialized and parsed without dropping fields or applying tolerances."}
		check(get_tree().get_nodes_in_group("crafting_stations").filter(func(n):return n.player_built).size()==4,"fresh process restores exactly four paid stations")
	player.hide();player.hud.hide();player.camera.current=false;mood.set_process(false)
	camera=Camera3D.new();camera.fov=60;add_child(camera);camera.current=true
	var layer:=CanvasLayer.new();add_child(layer);caption=Label.new();layer.add_child(caption);caption.position=Vector2(22,20);caption.add_theme_font_size_override("font_size",21)
	var view_list:Array=[
		{"id":"paid-exterior-eye","eye":origin+Vector3(5,.55,-7),"target":origin+Vector3(0,.1,1)},
		{"id":"paid-interior-close","eye":origin+Vector3(.2,.55,-1),"target":origin+Vector3(2,-.25,2)}]
	var samples:Array=[]
	for view:Dictionary in view_list:
		camera.position=view.eye;camera.look_at(view.target)
		for light in ["daylight","shade","dusk"]:
			mood._target=mood.active_mood(mood._biome_under_player());mood._apply(1.0)
			if light=="shade":$Sun.light_energy*=.12
			if light=="dusk":$Sun.light_energy*=.35;$Sun.light_color=Color("d9bd91")
			caption.text="ART-07R3 / "+("CANDIDATE" if R3Materials.enabled() else "SEALED G1")+" / "+RenderingServer.get_current_rendering_method()+"\nREAL PAID HOME / "+String(view.id)+" / "+light+(" / fresh-process restore" if restoring else "")
			for frame in 120 if timing else 12:await get_tree().process_frame
			if timing:
				var wall:Array[float]=[];var gpu_times:Array[float]=[];var cpu_times:Array[float]=[];var previous:=Time.get_ticks_usec()
				for frame in 300:
					await get_tree().process_frame
					var now:=Time.get_ticks_usec();wall.append(float(now-previous)/1000.0);previous=now
					gpu_times.append(RenderingServer.viewport_get_measured_render_time_gpu(get_viewport().get_viewport_rid()))
					cpu_times.append(RenderingServer.viewport_get_measured_render_time_cpu(get_viewport().get_viewport_rid()))
				wall.sort();gpu_times.sort();cpu_times.sort()
				samples.append({"view":view.id,"light":light,"samples":300,"median_ms":wall[150],"p95_ms":wall[285],"gpu_median_ms":gpu_times[150],"gpu_p95_ms":gpu_times[285],"render_cpu_median_ms":cpu_times[150],"cost":costs(),"draw_calls":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),"primitives":get_viewport().get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE,Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)})
			else:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(output+"/"+String(view.id)+"-"+light+".png")
	if not restoring and not timing:
		# Real first-person input/collision; 90 observations with actual engine tick stamps.
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output+"/walk"))
		camera.current=false;player.camera.current=true
		player.position=origin;player.velocity=Vector3.ZERO;player.rotation=Vector3.ZERO
		player.camera.position=Vector3(0,.65,0);player.camera.rotation=Vector3.ZERO
		player.set_physics_process(true);caption.text="ART-07R3 / REAL PAID HOME\nNative controller movement / existing collision / no camera interpolation"
		motion_tick_start=Engine.get_physics_frames()
		Input.action_press("move_forward")
		for frame in 90:
			await get_tree().physics_frame
			positions.append(str(player.position))
			motion_ticks.append(Engine.get_physics_frames())
			if frame%3==0:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(output+"/walk/%03d.png"%frame)
		Input.action_release("move_forward");player.set_physics_process(false)
		motion_tick_end=Engine.get_physics_frames()
		check(player.position.distance_to(origin)>1.0,"native controller motion travels more than one metre")
		player.position=origin;player.velocity=Vector3.ZERO;player.rotation=original_rotation
		player.camera.position=original_camera_position;player.camera.rotation=original_camera_rotation
	if not restoring and not timing:check(manager.write(save_path,player),"write private candidate paid checkpoint")
	check(geography==JSON.stringify(terrain.map).sha256_text(),"material repair retains exact geography")
	var result:={"checks":checks,"assertions":report.checks,"failures":failures,"scope":"Original paid G1 home; ordinary recipe and refused/successful kit transaction when not benchmarking. Native input motion is labelled separately. No inspection stock or roof unlock supplied.","initial":initial,"final":manager.capture(player),"geography_sha256":geography,"gpu":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"msaa":get_viewport().msaa_3d,"vsync":DisplayServer.window_get_vsync_mode(),"setup_seconds":setup_seconds,"samples":samples,"views":view_list,"motion_positions":positions,"motion_physics_frames":motion_ticks,"motion_tick_start":motion_tick_start,"motion_tick_end":motion_tick_end,"motion_scope":"90 observations of ordinary controller input; render capture may span additional actual engine ticks, explicitly recorded. No camera interpolation.","material_bindings":R3Materials.binding_inventory(),"cost":costs(),"restoring":restoring,"restore_value_comparison":report.get("restore_value_comparison",{})}
	FileAccess.open(output+"/report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("R3_PAID_HOME ",checks," checks, ",failures," failures, restore=",restoring)
	get_tree().quit(1 if failures else 0)
