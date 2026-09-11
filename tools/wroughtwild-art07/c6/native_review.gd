extends "res://tests/exploration_review.gd"
## Actual published world and supported controller walks; C6 is an opt-in visual adapter.
var c6: RefCounted
var mode := "review"
var selected := 0
var c6_views: Array[Dictionary] = []
var interactive := false
var base_sun := 1.0
var native_sun_basis := Basis.IDENTITY
var inspection_sun_basis := Basis.IDENTITY
var light_index := 0
var auto_clock := true
var current_view_id := ""

func _ready() -> void:
	world_profile="living_frontier_wave3";world_seed=77
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--c6-mode="): mode=arg.get_slice("=",1)
		if arg.begins_with("--c6-seed="): world_seed=int(arg.get_slice("=",1))
	output=ProjectSettings.globalize_path("res://../evidence/"+RenderingServer.get_current_rendering_method()+"/"+mode+"-"+str(world_seed))
	DirAccess.make_dir_recursive_absolute(output)
	_build_world(world_seed);player.class_panel.choose("warden")
	for actor in [player,player.combat,player.placement,player.spring_arm,mob_packs]:actor.set_physics_process(false)
	mob_packs.set_process(false);mood.set_process(false);mood.set_physics_process(false);set_physics_process(false)
	player.hide();player.hud.hide();_setup_camera()
	get_window().size=Vector2i(1440,900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED);Engine.max_fps=0
	base_sun=$Sun.light_energy
	native_sun_basis=$Sun.global_basis
	initial_native=_native_signature()
	var before := _physical_signature()
	c6=preload("res://c6/adapter.gd").new();c6.install(self)
	check(_physical_signature()==before,"original collision, source meshes and part transforms are retained")
	check(_native_signature()==initial_native,"adapter installation changes no geography, resource or source ledger")
	_select_c6_views()
	report={"mode":mode,"seed":world_seed,"profile":world_profile,"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"driver":RenderingServer.get_video_adapter_api_version(),"native_before":initial_native,"views":[],"walks":[]}
	if mode=="review":
		interactive=true;await _pose(0);Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;return
	if mode=="capture": await _captures()
	elif mode=="benchmark":await _benchmarks()
	elif mode=="motion":await _motion()
	elif mode=="walk":await _walks()
	else:await _checks()
	check(_native_signature()==initial_native,"all review work retains native geography and finite stock")
	report.checks=checks;report.failures=failures
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("C6_NATIVE_",mode.to_upper()," ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func _native_signature() -> Dictionary:
	var result := super._native_signature()
	for key in ["laboratory_trail","laboratories","frontier_hosts"]:result[key]=_digest(terrain.map.get(key,[]))
	result.leylines=_digest(_sim().leyline_save())
	return result

func _physical_signature() -> String:
	var rows: Array = []
	_collect_physical(self,rows)
	return _digest(rows)

func _collect_physical(node: Node, rows: Array) -> void:
	if node is CollisionShape3D:
		var shape: CollisionShape3D=node
		rows.append([str(shape.get_path()),shape.global_transform,shape.disabled,str(shape.shape)])
	if node is MeshInstance3D and node.name!="C6Candidate" and node.get_parent() is Node3D:
		if node.name=="Visual" or node.get_parent() is FrontierSites:rows.append([str(node.get_path()),node.global_transform,node.mesh.get_aabb()])
	for child in node.get_children():_collect_physical(child,rows)

func _select_c6_views() -> void:
	var source: Dictionary=terrain.map.pressure_pockets[0]
	for ruin: Dictionary in terrain.map.ruins:
		if ruin.id==source.ruin_id:smithy=ruin
	var centre := terrain.surface_position(int(smithy.x),int(smithy.z))
	var route: PackedVector3Array=smithy.approach
	c6_views.append({"id":"smithy-arrival","at":route[maxi(0,route.size()-10)],"target":centre+Vector3.UP*.9})
	var history: CataclysmSites=get_node("CataclysmSites")
	for wanted in ["cataclysm_fen_wall_struck","cataclysm_forge_threshold","cataclysm_rootvault_frame","cataclysm_upland_wall","trail_transition","workbench"]:
		for entry: Dictionary in c6.entries:
			if String(entry.id)!=wanted:continue
			var visual: MeshInstance3D=entry.original
			var part: Node3D=visual.get_parent()
			if wanted in ["workbench","trail_transition"] and String(part.get_meta("site_id",""))!=String(smithy.id):continue
			var aabb: AABB=visual.mesh.get_aabb()
			var focus: Vector3=visual.global_transform*aabb.get_center()
			var direction: Vector3=(visual.global_basis*Vector3.BACK).normalized()
			c6_views.append({"id":wanted.replace("cataclysm_",""),"at":focus+direction*(2.8 if aabb.size.y>1 else 2.0),"target":focus})
			break
	var frontier: FrontierSites=get_node("FrontierSites")
	var mark: MeshInstance3D=frontier.trail_marks[0]
	var walk: Vector3=mark.get_meta("walk_position")
	c6_views.append({"id":"collection-marks","at":walk+Vector3(2,0,2.5),"target":mark.global_position+Vector3.UP*.2})
	var path: PackedVector3Array=terrain.map.laboratory_trail
	c6_views.append({"id":"collection-approach","at":path[maxi(0,path.size()-9)],"target":path[-1]+Vector3.UP*1.1})

func _pose(index: int) -> void:
	selected=index;var view: Dictionary=c6_views[index]
	await _settle(view.at,48)
	(get_node("CataclysmSites") as CataclysmSites).refresh_area(floori(view.target.x)-10,floori(view.target.z)-10,20)
	c6.install(self)
	terrain.set_process(false)
	review_camera.global_position=_ground(view.at)+Vector3.UP*1.65
	review_camera.look_at(view.target)
	inspection_sun_basis=Basis.looking_at((view.target-review_camera.global_position+Vector3.DOWN*3).normalized(),Vector3.UP)
	_light(light_index)
	current_view_id=String(view.id)
	c6.tick(0,review_camera)
	for i in 5:await get_tree().process_frame

func _process(delta: float) -> void:
	if c6==null or review_camera==null:return
	c6.tick(delta if auto_clock else 0.0,review_camera)
	if interactive and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		var direction:=Vector3(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_E))-float(Input.is_physical_key_pressed(KEY_Q)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W)))
		review_camera.position+=review_camera.global_basis*direction*delta*4
		caption.text="C6 · "+current_view_id+" | B before/after · L light · M scar · Space pause · 0 auto / 7–9 detail · Tab next view · WASD QE"

func _unhandled_input(event: InputEvent) -> void:
	if c6==null:return
	if event is InputEventMouseMotion and interactive and Input.mouse_mode==Input.MOUSE_MODE_CAPTURED:
		review_camera.rotation.y-=event.relative.x*.002;review_camera.rotation.x=clampf(review_camera.rotation.x-event.relative.y*.002,-1.45,1.45)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_SPACE:c6.paused=not c6.paused
			KEY_M:c6.light_enabled=not c6.light_enabled
			KEY_B:c6.enabled=not c6.enabled
			KEY_L:light_index=(light_index+1)%4;_light(light_index)
			KEY_TAB:if interactive:_pose((selected+1)%c6_views.size())
			KEY_0:c6.forced_detail=-1
			KEY_7:c6.forced_detail=0
			KEY_8:c6.forced_detail=1
			KEY_9:c6.forced_detail=2
			KEY_ESCAPE:Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
			_:
				if interactive and event.physical_keycode>=KEY_1 and event.physical_keycode<=KEY_6:_pose(mini(c6_views.size()-1,event.physical_keycode-KEY_1))

func _light(index: int) -> void:
	$Sun.light_energy=base_sun*[1.0,.35,.48,1.0][index]
	$Sun.light_color=[Color.WHITE,Color("a5bbc7"),Color("d9bd91"),Color.WHITE][index]
	$Sun.global_basis=inspection_sun_basis if index==3 else native_sun_basis

func _captures() -> void:
	auto_clock=false
	for idx in c6_views.size():
		await _pose(idx)
		var view: Dictionary=c6_views[idx]
		for state in [false,true]:
			c6.enabled=state
			for light in 4:
				_light(light);c6.tick(0,review_camera)
				var id: String=String(view.id)+("-after" if state else "-before")+"-"+["day","shade","dusk","inspection-sun"][light]
				caption.text="C6 · "+id+" · actual seed "+str(world_seed)
				await _capture(id)
		report.views.append({"id":view.id,"camera":review_camera.global_position,"target":view.target,"native_sun_basis":native_sun_basis,"inspection_sun_basis":inspection_sun_basis,"lighting_note":"Day, shade and dusk preserve native sun direction. Inspection-sun rotates the same review light toward the viewed face in both before and after."})
	# Matched fixed camera explicitly shows all three authored detail levels.
	await _pose(1);c6.enabled=true;_light(3)
	for level in 3:
		caption.text="C6 · struck wall · detail %d · inspection sun" % level
		c6.forced_detail=level;c6.tick(0,review_camera);await _capture("struck-wall-lod%d" % level)
	caption.text="C6 · struck wall · emission OFF · inspection sun"
	c6.forced_detail=0;c6.light_enabled=false;c6.tick(0,review_camera);await _capture("struck-wall-emission-off")
	caption.text="C6 · struck wall · emission ON · inspection sun"
	c6.light_enabled=true;c6.tick(0,review_camera);await _capture("struck-wall-emission-on")

func _benchmarks() -> void:
	auto_clock=false
	for index in [0,1,c6_views.size()-2]:
		await _pose(index)
		for state in [false,true]:
			c6.enabled=state;c6.tick(0,review_camera);_light(0)
			for warm in 180:await get_tree().process_frame
			var values: Array[float]=[]
			for frame in 600:
				var begin:=Time.get_ticks_usec();await get_tree().process_frame;values.append((Time.get_ticks_usec()-begin)/1000.0)
			values.sort()
			report.views.append({"id":c6_views[index].id,"candidate":state,"p50_ms":values[300],"p95_ms":values[570],"worst_ms":values[-1],"draws":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TEXTURE_MEM_USED),"camera":review_camera.global_position,"warmup":180,"samples":600})

func _checks() -> void:
	await _pose(1)
	var signature:=_physical_signature()
	var count: int=c6.entries.size();c6.install(self)
	check(c6.entries.size()==count,"repeat install creates exactly one candidate per original")
	for level in 3:
		c6.forced_detail=level;c6.tick(0,review_camera)
		for e: Dictionary in c6.entries:
			var original: MeshInstance3D=e.original;var candidate: MeshInstance3D=e.variant
			check(original.mesh==e.mesh,"original mesh remains refresh and body reference")
			var limit:=original.mesh.get_aabb().grow(.0002)
			for surface in candidate.mesh.get_surface_count():
				var vertices: PackedVector3Array=candidate.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
				var within:=true
				for vertex in vertices:
					if not limit.has_point(candidate.transform*vertex):within=false;break
				check(within,"candidate detail stays in native envelope: "+String(e.id))
			check(candidate.get_child_count()==0,"candidate has no collider, interaction, stock or loot child")
	check(_physical_signature()==signature,"all detail changes retain exact original collision/anchor signature")
	var original: MeshInstance3D=c6.entries[0].original
	original.get_parent().hide();check(not c6.entries[0].variant.is_visible_in_tree(),"native parent suppression hides its candidate")
	original.get_parent().show()
	await _pause_test()
	report.candidate_instances=count;report.cached_meshes=c6.meshes.size();report.shared_materials=c6.materials.size()

func _key(code: Key) -> void:
	var event:=InputEventKey.new();event.physical_keycode=code;event.pressed=true;Input.parse_input_event(event)
	await get_tree().process_frame
	event=InputEventKey.new();event.physical_keycode=code;event.pressed=false;Input.parse_input_event(event)
	await get_tree().process_frame

func _pause_test() -> void:
	auto_clock=true;c6.paused=false
	await _key(KEY_SPACE)
	check(c6.paused,"actual Space input pauses the scar clock")
	var held: float=c6.clock_seconds
	for i in 12:await get_tree().process_frame
	check(c6.clock_seconds==held,"paused C6 clock remains exact")
	for mat: ShaderMaterial in c6.materials.values():check(float(mat.get_shader_parameter("clock_seconds"))==held,"every material holds the explicit paused clock")
	await _key(KEY_SPACE)
	for i in 3:await get_tree().process_frame
	check(not c6.paused and c6.clock_seconds>held,"actual Space resumes the clock")

func _motion() -> void:
	await _pose(1);auto_clock=false;c6.enabled=true;c6.forced_detail=0
	for i in 48:
		c6.clock_seconds=float(i)*float(c6.cfg.pulse_period_s)/48;c6.tick(0,review_camera)
		caption.text="C6 · actual inset scar · frame %02d" % i;await _capture("pulse-%03d" % i)
	await _pause_test()

func _walks() -> void:
	var path: PackedVector3Array=smithy.approach
	path=path.slice(maxi(0,path.size()-12));path.append_array(smithy.discovery_route.slice(0,12))
	await _c6_walk(path,"smithy")
	var trail: PackedVector3Array=terrain.map.laboratory_trail
	await _c6_walk(trail.slice(maxi(0,trail.size()-24)),"collection")

func _c6_walk(path: PackedVector3Array, id: String) -> void:
	await _settle(path[0],48);c6.install(self);terrain.set_process(false)
	player.global_position=path[0]+Vector3.UP*1.05;player.velocity=Vector3.ZERO;player.rotation=Vector3.ZERO;player.test_walk=Vector2.ZERO
	player.set_physics_process(true)
	for i in 20:await get_tree().physics_frame
	var frames:=0;var supported:=0;var airborne:=0;var distance:=0.0;var last:=player.global_position;var reached_all:=true
	for index in range(1,path.size()):
		var reached:=false
		for attempt in 150:
			var direction: Vector3=(path[index]-player.global_position)*Vector3(1,0,1)
			if direction.length()<.24:reached=true;break
			player.test_walk=Vector2(direction.x,direction.z).normalized()
			if attempt==30 or attempt==95:Input.action_press("jump")
			if attempt==31 or attempt==96:Input.action_release("jump")
			await get_tree().physics_frame
			frames+=1
			if player.is_on_floor():supported+=1
			else:airborne+=1
			distance+=Vector2(last.x,last.z).distance_to(Vector2(player.global_position.x,player.global_position.z));last=player.global_position
			var ground:=_ground(player.global_position)
			check(ground.is_finite() and player.global_position.y>ground.y-1,"walk stays above supported retained terrain")
			review_camera.global_position=player.camera.global_position
			var toward: Vector3=path[mini(index+3,path.size()-1)]+Vector3.UP*1.5
			if review_camera.global_position.distance_to(toward)>.1:review_camera.look_at(toward)
			if frames%10==0 and DisplayServer.get_name()!="headless":
				caption.text="C6 · "+id+" · actual controller walk";await _capture("walk-"+id+"-%04d" % frames)
		player.test_walk=Vector2.ZERO;Input.action_release("jump")
		if not reached:reached_all=false;break
	for i in 90:
		await get_tree().physics_frame
		if player.is_on_floor():break
	check(reached_all and player.is_on_floor(),"ordinary controller reaches supported "+id+" endpoint")
	player.set_physics_process(false)
	report.walks.append({"id":id,"points":path.size(),"frames":frames,"supported_frames":supported,"airborne_frames":airborne,"distance_m":distance,"reached":reached_all,"endpoint_supported":player.is_on_floor(),"endpoint":player.global_position})
