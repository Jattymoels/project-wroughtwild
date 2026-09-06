extends Node3D
## Exact near terrain, cancellable staged construction and a native-derived
## far skyline. Optional rendered mode compares the same bounded walk setup.
var checks:=0
var failures:=0
var terrain: Terrain
var camera: Camera3D
var moving_view: Node3D
var output: String

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL TERRAIN STREAM: ",label)

func _ready() -> void:
	output=ProjectSettings.globalize_path("res://../build/strange-frontier/terrain-stream")
	DirAccess.make_dir_recursive_absolute(output)
	if OS.get_cmdline_user_args().has("--stream-performance"):
		await performance_review()
	else:
		await correctness()
	print("TERRAIN_STREAM_INTENSIVE %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func make_terrain(profile: String) -> Terrain:
	var result:=Terrain.new()
	result.name="Terrain"
	add_child(result)
	result.weathered=true
	result.build(load("res://scripts/sim.gd").shared(),1,profile)
	return result

func floor_hit(point: Vector3) -> Dictionary:
	return get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point+Vector3.UP*3,point-Vector3.UP*3,1))

func correctness() -> void:
	terrain=make_terrain("frontier_v3")
	var stream:=terrain.chunk_stream
	check(stream!=null,"new profile stages exact terrain")
	check(terrain.chunks.size()<1024 and terrain.chunks.size()>100,"startup does not create every expanded-world chunk")
	check(stream._horizon!=null and stream._horizon.mesh!=null,"distant native skyline exists before close detail")
	var vertices: PackedVector3Array=stream._horizon.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var maximum:=Vector3.ZERO
	for vertex in vertices:
		maximum=maximum.max(vertex)
		check(vertex.is_finite(),"horizon has finite coordinates")
		check(absf(vertex.y-terrain.height_at(clampi(int(vertex.x),0,511),clampi(int(vertex.z),0,511)))<0.001,"horizon samples actual generated terrain")
	check(maximum.x==512.0 and maximum.z==512.0,"far view spans the bounded 512 metre world")
	verify_regional_dressing()
	var site: Dictionary=terrain.map.rare_sites[0]
	var point:=terrain.surface_position(int(site.x),int(site.z))
	# An unrelated preview can select another cached identity before a teleport.
	load("res://scripts/sim.gd").shared().set_world_profile("frontier_v2")
	terrain.ensure_area(point,36.0)
	await get_tree().physics_frame
	await get_tree().physics_frame
	var hit:=floor_hit(point)
	check(not hit.is_empty(),"ensure_area prepares exact collision before a distant saved pose")
	check(terrain.world_profile()=="frontier_v3","detail query retains full world identity")
	var cx:=floori(float(site.x)/16.0)
	var cz:=floori(float(site.z)/16.0)
	check(stream._mask.get_pixel(cx,cz).r>0.5,"far approximation is hidden under exact near collision")
	var origin:=Vector2i(0,0)
	check(not terrain.chunks.has("0_0"),"fixture exercises an unvisited distant chunk")
	stream._finish_job()
	stream._pending=[origin]
	stream._step_job() # native payload
	stream._step_job() # first presentation phase
	check(not stream._job.is_empty() and is_instance_valid(stream._job.node),"staged chunk can exist before collision publishes it")
	check(not terrain.chunks.has("0_0"),"unfinished geometry is not exposed as a playable chunk")
	var y:=terrain.height_at(2,2)-1
	check(terrain.break_block(2,y,2)!="","excavation applies while the same chunk is staged")
	check(stream._job.is_empty(),"excavation cancels its stale native payload")
	check(terrain.block_at(2,y,2)==0 and terrain.chunks.has("0_0"),"edited exact geometry replaces the canceled job")
	stream.focus(terrain.surface_position(int(terrain.map.spawn_x),int(terrain.map.spawn_z)))
	check((terrain.chunks["0_0"] as Node3D).visible,"player excavation remains exact when viewed from far away")
	check(stream._mask.get_pixel(0,0).r>0.5,"far skyline cannot visually refill a dug quarry")
	var remote:=Vector2i(480,480)
	var spawn2:=Vector2(int(terrain.map.spawn_x),int(terrain.map.spawn_z))
	for alternative in [Vector2i(32,480),Vector2i(480,32)]:
		if Vector2(alternative).distance_squared_to(spawn2)>Vector2(remote).distance_squared_to(spawn2): remote=alternative
	terrain.ensure_area(terrain.surface_position(remote.x,remote.y),16.0)
	var ordinary_key:="%d_%d" % [remote.x,remote.y]
	stream.focus(terrain.surface_position(int(terrain.map.spawn_x),int(terrain.map.spawn_z)))
	var ordinary_parts: PackedStringArray=ordinary_key.split("_")
	check(not terrain.chunks.has(ordinary_key),"distant unmodified detail releases its mesh, collision and sampler to the coarse native skyline")
	check(stream._mask.get_pixel(int(ordinary_parts[0])/16,int(ordinary_parts[1])/16).r<0.5,"retired detail reveals the actual far heightfield")
	# Restoring excavation rebuilds the exact changed chunks, even if hidden.
	terrain.apply_broken_blocks([])
	check(terrain.block_at(2,y,2)!=0,"restore may undo only the newer excavation")
	terrain.apply_broken_blocks([[2,y,2]])
	check(terrain.block_at(2,y,2)==0,"saved excavation reapplies after staged travel")
	terrain.free()

func verify_regional_dressing() -> void:
	var dressing:=StrangeSites.build(self,terrain)
	var reserved:=StrangeSites._reservations(terrain)
	var before: Dictionary={}
	var distant_groups:=0
	for region: Dictionary in terrain.map.regions:
		var group:=dressing.get_node_or_null(String(region.id))
		check(group!=null and group.get_child_count()>0,"distant region has actual dressing before exact geometry: "+String(region.id))
		check(int(group.get_meta("landmark_count",0))>0 and int(group.get_meta("detail_count",0))>0,"region contains both a silhouette and nearby detail: "+String(region.id))
		var key:="%d_%d"%[floori(float(region.x)/16)*16,floori(float(region.z)/16)*16]
		if not terrain.chunks.has(key): distant_groups+=1
		for part in group.get_children():
			if not part is MultiMeshInstance3D: continue
			var transforms: Array=part.get_meta("world_transforms",[])
			var heights: Array=part.get_meta("ground_heights",[])
			for i in transforms.size():
				var at: Vector3=transforms[i].origin
				before["%s/%s/%d"%[region.id,part.name,i]]=at
				before["height/%s/%s/%d"%[region.id,part.name,i]]=float(heights[i])
				check(at.is_finite(),"unloaded regional accent is not positioned at infinity")
				var mesh_kind:=String(part.get_meta("mesh_kind",String(part.name)))
				if mesh_kind in ["root_arch","root_arch_b","root_arch_c","hollow_trunk","stone_rib","low_outcrop"]:
					check(StrangeSites._clear(reserved,at,1.0),"regional silhouette reserves native approaches before streaming: %s/%s[%d] at %s"%[region.id,mesh_kind,i,at])
				if mesh_kind in ["hollow_trunk","stone_rib","low_outcrop"]:
					# Grounded stone and woody ends occupy their full authored
					# footprint. Leaf canopies may frame a clear route overhead.
					var bounds: AABB=part.multimesh.mesh.get_aabb()
					var clearance:=1.0
					for corner in 8:
						var offset: Vector3=transforms[i].basis*bounds.get_endpoint(corner)
						clearance=maxf(clearance,Vector2(offset.x,offset.z).length())
					check(StrangeSites._clear(reserved,at,clearance),"full authored footprint preserves work/route clearance: %s/%s[%d] radius %.3f at %s"%[region.id,mesh_kind,i,clearance,at])
	check(distant_groups>=2,"fixture includes regional centres without exact initial chunks")
	for region: Dictionary in terrain.map.regions:
		terrain.ensure_area(terrain.surface_position(int(region.x),int(region.z)),32.0)
		var group:=dressing.get_node(String(region.id))
		var grounded_count:=0
		for part in group.get_children():
			if not part is MultiMeshInstance3D: continue
			var transforms: Array=part.get_meta("world_transforms",[])
			var heights: Array=part.get_meta("ground_heights",[])
			for i in transforms.size():
				var at: Vector3=transforms[i].origin
				var prior: Vector3=before["%s/%s/%d"%[region.id,part.name,i]]
				check(Vector2(at.x,at.z).is_equal_approx(Vector2(prior.x,prior.z)),"exact regrounding preserves horizontal approach clearance")
				var actual:=terrain.rendered_height(at.x,at.z,terrain.height_at(int(at.x),int(at.z)))
				if is_finite(actual):
					grounded_count+=1
					check(absf(float(heights[i])-actual)<0.01,"streamed accent follows the exact nearby surface")
					check(absf((at.y-prior.y)-(actual-float(before["height/%s/%s/%d"%[region.id,part.name,i]])))<0.01,"grounding retains the authored vertical offset")
		check(grounded_count>0,"region receives an actual near-detail regrounding pass")

func distribution(values: Array) -> Dictionary:
	values.sort()
	if values.is_empty(): return {}
	return {"samples":values.size(),"median_ms":values[values.size()/2],"p95_ms":values[ceili(values.size()*0.95)-1],"p99_ms":values[ceili(values.size()*0.99)-1],"max_ms":values[-1]}

func performance_review() -> void:
	get_window().size=Vector2i(1920,1080)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=120
	var environment:=WorldEnvironment.new()
	environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color(0.57,0.66,0.73)
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color(0.66,0.70,0.72)
	environment.environment.ambient_light_energy=0.6
	add_child(environment)
	var sun:=DirectionalLight3D.new()
	sun.rotation_degrees=Vector3(-48,-30,0)
	sun.light_energy=1.1
	sun.shadow_enabled=true
	add_child(sun)
	moving_view=Node3D.new()
	moving_view.name="Player"
	add_child(moving_view)
	camera=Camera3D.new()
	camera.fov=75
	camera.far=650
	camera.current=true
	moving_view.add_child(camera)
	var results:=[]
	for profile in ["frontier_v2","frontier_v3"]:
		terrain=make_terrain(profile)
		moving_view.position=terrain.surface_position(int(terrain.map.spawn_x),int(terrain.map.spawn_z))+Vector3.UP*1.7
		moving_view.look_at(moving_view.position+Vector3(1,-0.05,0))
		for frame in 180: await get_tree().process_frame
		var samples: Array=[]
		var active_samples: Array=[]
		var settled_samples: Array=[]
		var physics_samples: Array=[]
		var now:=Time.get_ticks_usec()
		var elapsed:=0.0
		var distance:=0.0
		var active_frames:=0
		var start:=Vector2(float(terrain.map.spawn_x)+0.5,float(terrain.map.spawn_z)+0.5)
		# 5m/s, thirty seconds, out and back over a 75m track. This remains
		# inside both bounded profiles and exercises fresh-prefetch terrain.
		while elapsed<30.0:
			await get_tree().process_frame
			var next:=Time.get_ticks_usec()
			var dt:=float(next-now)/1000000.0
			now=next
			elapsed+=dt
			distance+=dt*5.0
			var offset:=distance if distance<=75.0 else 150.0-distance
			var x:=clampf(start.x+offset,5.0,float(terrain.map.width)-5.0)
			moving_view.position=Vector3(x,float(terrain.height_at(int(x),int(start.y)))+1.7,start.y)
			moving_view.look_at(moving_view.position+Vector3(1 if distance<=75.0 else -1,-0.05,0))
			samples.append(dt*1000.0)
			physics_samples.append(Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0)
			if terrain.chunk_stream!=null and (not terrain.chunk_stream._pending.is_empty() or not terrain.chunk_stream._job.is_empty()):
				active_samples.append(dt*1000.0)
				active_frames+=1
			else: settled_samples.append(dt*1000.0)
		await RenderingServer.frame_post_draw
		var capture_path:=output.path_join(profile+"-return.png")
		check(get_viewport().get_texture().get_image().save_png(capture_path)==OK,"rendered terrain approach capture "+profile)
		var result:={"profile":profile,"seed":1,"startup":terrain.build_profile.duplicate(),"seconds":elapsed,"distance_m":distance,
			"frame":distribution(samples),"active_prefetch":distribution(active_samples),"settled":distribution(settled_samples),"physics":distribution(physics_samples),
			"active_prefetch_frames":active_frames,"chunks_created":terrain.chunks.size(),"active_resources":terrain.nodes_root.get_child_count(),
			"memory_bytes":OS.get_static_memory_usage(),"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"capture":capture_path}
		if terrain.chunk_stream!=null: result["construction_phase"]=distribution(terrain.chunk_stream.phase_build_ms.duplicate())
		results.append(result)
		print("TERRAIN_STREAM_PERFORMANCE ",JSON.stringify(result))
		terrain.free()
		for frame in 30: await get_tree().process_frame
	var report:={"renderer":RenderingServer.get_current_rendering_method(),"resolution":[1920,1080],"fps_cap":120,"speed_m_s":5,
		"scope":"Matched 30s camera route with identical weathered material, daylight, view and speed; full native world and ordinary resources. Each profile begins at its own spawn and follows a 75m eastward return track. No combat, regional decorative kits or player-controller timing; geography differs by profile. Active-prefetch frames are reported separately; no forced travel clearing or ordinary scene loading is excluded.","results":results}
	var file:=FileAccess.open(output.path_join("performance.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
