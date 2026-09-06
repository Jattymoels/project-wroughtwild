extends "res://scripts/sandpit.gd"
## Actual generated v3 world, ordinary camera height and streaming. Scripted
## camera walks are visual evidence; they do not certify discovery excitement.
var checks:=0
var failures:=0
var report: Dictionary={}
var review_camera: Camera3D
var output: String
var caption: Label
var visual_only:=false
var prior_report: Dictionary={}

func check(ok: bool, label: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL STRANGE WORLD: ",label)

func _ready() -> void:
	# Preserve this historical v3 regression; cataclysm_intensive checks the new default.
	world_profile = "frontier_v3"
	var began:=Time.get_ticks_msec()
	super._ready()
	report["world_setup_ms"]=Time.get_ticks_msec()-began
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	mood.set_process(false)
	mood.set_physics_process(false)
	player.hud.notify("")
	output=ProjectSettings.globalize_path("res://../build/strange-frontier/world")
	DirAccess.make_dir_recursive_absolute(output)
	visual_only="--strange-visual-only" in OS.get_cmdline_user_args()
	if visual_only and FileAccess.file_exists(output.path_join("manifest.json")):
		prior_report=JSON.parse_string(FileAccess.get_file_as_string(output.path_join("manifest.json")))
	check(world_profile=="frontier_v3" and int(terrain.map.get("width",0))==512,"new world uses the 512 metre v3 profile")
	check(terrain.map.get("regions",[]).size()==3,"all three discovery regions exist")
	report["terrain_startup"]=terrain.build_profile.duplicate(true)
	for region: Dictionary in terrain.map.get("regions",[]):
		var art:=get_node_or_null("StrangeSites/"+String(region.id))
		check(art!=null and int(art.get_meta("landmark_count",0))>0,"region has its authored distant silhouette")
		if region.id=="lantern_fen": check(art!=null and int(art.get_meta("pool_count",0))>0,"Lantern Fen has supported broad shallow pools")
	if DisplayServer.get_name()!="headless":
		if "--strange-water-only" in OS.get_cmdline_user_args():
			await _water_review()
			print("STRANGE_WATER_REVIEW %d checks, %d failures"%[checks,failures])
			get_tree().quit(0 if failures==0 else 1)
			return
		await _review()
	report["checks"]=checks
	report["failures"]=failures
	var file:=FileAccess.open(output.path_join("checks.json" if DisplayServer.get_name()=="headless" else "manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"\t"))
	print("STRANGE_WORLD_REVIEW %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _physics_process(_delta: float) -> void:
	pass # Lighting and combat stay fixed; Terrain owns ordinary streaming ticks.

func _ground(at: Vector3) -> Vector3:
	var y:=float(terrain.height_at(floori(at.x),floori(at.z)))
	return Vector3(at.x,terrain.rendered_height(at.x,at.z,y),at.z)

func _settle(at: Vector3, radius:=48.0) -> void:
	player.global_position=at+Vector3.UP*1.2
	terrain.ensure_area(terrain.to_local(at),radius)
	if terrain.resource_stream!=null: terrain.resource_stream.focus(terrain.to_local(at),true)
	for i in 4: await get_tree().physics_frame

func _setup_camera() -> void:
	review_camera=Camera3D.new()
	review_camera.fov=75
	add_child(review_camera)
	review_camera.make_current()
	# Use the actual hand meshes and ordinary local pose at the review eye.
	# Leaving them on the inactive player camera would show their backs in air.
	var hands:=player.camera.get_node("FirstPersonHands") as FirstPersonHands
	hands.reparent(review_camera,false)
	hands.transform=Transform3D.IDENTITY
	hands.remaining=0.0
	hands.sample(1.0)
	var layer:=CanvasLayer.new()
	add_child(layer)
	caption=Label.new()
	caption.position=Vector2(400,22)
	caption.add_theme_font_size_override("font_size",19)
	caption.add_theme_color_override("font_color",Color("e3dece"))
	layer.add_child(caption)

func _water_review() -> void:
	_setup_camera()
	var fen:=get_node("StrangeSites/lantern_fen")
	for part in fen.get_children():
		if not part.has_meta("pool_support"): continue
		var shore: Vector3=part.global_position+Vector3(0,0,7)
		await _settle(shore)
		check(part.visible,"irregular pool remains supported by exact terrain")
		review_camera.global_position=_ground(shore)+Vector3.UP*1.65
		review_camera.look_at(part.global_position)
		caption.text="SHALLOW LANTERN FEN · SUPPORTED POOLS AT PLAYER HEIGHT"
		await _capture("lantern_fen-pools")
		return
	check(false,"fen contains a shallow water view")

func _review() -> void:
	_setup_camera()
	var regions: Array=[]
	for region: Dictionary in terrain.map.regions:
		var path: PackedVector3Array=region.approach
		var at: Vector3=path[maxi(0,path.size()-28)]
		await _settle(at)
		var centre:=Vector3(float(region.x)+.5,float(region.y),float(region.z)+.5)
		review_camera.global_position=_ground(at)+Vector3.UP*1.65
		review_camera.look_at(centre+Vector3.UP*3.0)
		caption.text=String(region.id).replace("_"," ").to_upper()+" · DAYLIGHT"
		await _capture(String(region.id)+"-day")
		var energy: float=$Sun.light_energy
		var colour: Color=$Sun.light_color
		$Sun.light_energy=energy*.48
		$Sun.light_color=Color("d9bd91")
		caption.text=String(region.id).replace("_"," ").to_upper()+" · MATCHED DUSK"
		await _capture(String(region.id)+"-dusk")
		$Sun.light_energy=energy
		$Sun.light_color=colour
		caption.text="SCRIPTED PLAYER-HEIGHT APPROACH · "+String(region.id).replace("_"," ").to_upper()
		var walk:=await _walk(String(region.id),path)
		# Complete the same visible chunk/resource set before both art samples;
		# asynchronous streaming must not favour the later hidden-dressing pass.
		var settings: Dictionary=preload("res://art/strange_stream.tres").settings()
		await _settle(player.global_position-Vector3.UP*1.2,float(settings.terrain_detail_radius_m))
		terrain.set_process(false)
		var dressing:=get_node("StrangeSites") as Node3D
		var with_art: Dictionary={}
		var without_art: Dictionary={}
		if visual_only:
			for previous: Dictionary in prior_report.get("regions",[]):
				if previous.id==region.id:
					with_art=previous.with_dressing
					without_art=previous.dressing_hidden
		else:
			with_art=await _frames()
			dressing.hide()
			without_art=await _frames()
			dressing.show()
		terrain.set_process(true)
		var art:=dressing.get_node(String(region.id))
		if region.id=="lantern_fen":
			var supported_pools:=0
			var first_pool: Node3D
			for part in art.get_children():
				if part.has_meta("pool_support") and part.visible:
					supported_pools+=1
					if first_pool==null: first_pool=part
			check(supported_pools>0,"fen pools remain supported after exact streamed geometry")
			if first_pool!=null:
				var shore:=first_pool.global_position+Vector3(0,0,7)
				await _settle(shore)
				review_camera.global_position=_ground(shore)+Vector3.UP*1.65
				review_camera.look_at(first_pool.global_position)
				caption.text="SHALLOW LANTERN FEN · SUPPORTED POOLS AT PLAYER HEIGHT"
				await _capture("lantern_fen-pools")
		regions.append({"id":region.id,"position":[region.x,region.y,region.z],"radius_m":region.radius_m,
			"landmarks":art.get_meta("landmark_count",0),"pools":art.get_meta("pool_count",0),"walk":walk,
			"with_dressing":with_art,"dressing_hidden":without_art,
			"change_percent":{"median":100*(float(with_art.median)/float(without_art.median)-1),"p95":100*(float(with_art.p95)/float(without_art.p95)-1)}})
		var cave: PackedVector3Array=region.get("cave_approach",PackedVector3Array())
		if cave.size()>21:
			var mouth: Vector3=cave[cave.size()-21]
			await _settle(mouth)
			review_camera.global_position=mouth+Vector3.UP*1.65
			review_camera.look_at(cave[mini(cave.size()-1,cave.size()-16)]+Vector3.UP*1.3)
			caption.text="AUTHORED CAVE APPROACH · "+String(region.id).replace("_"," ").to_upper()
			await _capture(String(region.id)+"-cave")
	report["regions"]=regions
	var shown: Dictionary={}
	for site: Dictionary in terrain.map.rare_sites:
		var id:=String(site.resource_type)
		if shown.has(id): continue
		shown[id]=true
		var position:=Vector3(float(site.x)+.5,float(site.y),float(site.z)+.5)
		await _settle(position)
		var node: ResourceNode
		for def: Dictionary in terrain.map.nodes:
			if def.get("site_id","")==site.id:
				node=terrain.resource_stream.materialise(String(def.resource_id))
				break
		check(node!=null,"rare approach reaches a streamed intact specimen")
		if node==null: continue
		var approach: PackedVector3Array=site.approach
		var from:=_ground(approach[maxi(0,approach.size()-5)])+Vector3.UP*1.65
		review_camera.global_position=from
		review_camera.look_at(node.global_position+Vector3.UP*.5)
		caption.text="INTACT FIND · "+id.to_upper()
		await _capture("find-"+id)
		var original_units:=node.remaining_units
		var completed: Dictionary={}
		for i in maxi(1,node.drive_presses):
			if is_instance_valid(node): completed=node.work(_sim())
		caption.text="AFTER CONTEXTUAL WORK · "+id.to_upper()
		check(int(completed.get("granted",0))>0,"ordinary contextual work grants intact rare material")
		await _capture("worked-"+id)
		var shell:=get_node_or_null("StrangeSites/"+String(site.id))
		check(shell!=null and shell.get_child_count()>0,"site housing and clues remain after gathering")
		if is_instance_valid(node):
			node.remaining_units=0
			node._deplete()
		await _capture("empty-"+id)
		check(original_units>0,"first rare haul was finite")
	await _interior()

func _walk(id: String, path: PackedVector3Array) -> Dictionary:
	var start:=maxi(0,path.size()-58)
	var end:=maxi(start+1,path.size()-3)
	await _settle(path[start],64)
	var distance:=0.0
	var frames:=0
	var next_capture:=0.0
	var elapsed:=0.0
	var previous:=Time.get_ticks_usec()
	review_camera.global_position=_ground(path[start])+Vector3.UP*1.65
	for index in range(start+1,end):
		var target: Vector3=path[index]
		while Vector2(review_camera.position.x-target.x,review_camera.position.z-target.z).length()>.05:
			await get_tree().process_frame
			var now:=Time.get_ticks_usec()
			var delta:=minf(float(now-previous)/1000000.0,.05)
			previous=now
			var current:=Vector3(review_camera.position.x,0,review_camera.position.z)
			var step:=current.move_toward(Vector3(target.x,0,target.z),5.0*delta)
			distance+=current.distance_to(step)
			var grounded:=_ground(step)
			check(grounded.is_finite(),"scripted approach has a rendered surface")
			if not grounded.is_finite(): break
			review_camera.global_position=grounded+Vector3.UP*1.65
			player.global_position=grounded+Vector3.UP*1.2
			var ahead: Vector3=path[mini(path.size()-1,index+5)]+Vector3.UP*1.65
			if ahead.distance_to(review_camera.global_position)>.1: review_camera.look_at(ahead)
			elapsed+=delta
			if elapsed>=next_capture:
				await _capture("walk-"+id+"-%03d"%frames)
				frames+=1
				next_capture+=.25
	return {"frames":frames,"seconds":elapsed,"distance_m":distance,"sample_fps":4,"eye_height_m":1.65}

func _frames() -> Dictionary:
	var values: Array[float]=[]
	for i in 180:
		var begin:=Time.get_ticks_usec()
		await get_tree().process_frame
		if i>=30: values.append(float(Time.get_ticks_usec()-begin)/1000)
	values.sort()
	return {"median":values[75],"p95":values[142],"samples":150,
		"draw_calls":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
		"primitives":RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME),
		"loaded_chunks":terrain.chunks.size(),"active_resources":terrain.resource_stream.active.size()}

func _interior() -> void:
	var centre:=terrain.surface_position(int(terrain.map.spawn_x)+11,int(terrain.map.spawn_z)+8)
	await _settle(centre)
	var house:=Node3D.new()
	house.name="ReviewLanternShelter"
	add_child(house)
	# Existing finished material pieces and existing lattice shapes furnish a
	# compact cave-workshop scene. No kit or rare core is spent by this review.
	var grid:=player.placement.registry_grid
	var cell:=Vector3i(centre/grid)
	for x in 4:
		for z in 4:
			check(player.placement.place_piece({"kind":"face","axis":1,"cell":cell+Vector3i(x*2,0,z*2)},&"floor_slab",&"shellstone")!=null,"ordinary shellstone workshop floor places")
			player.placement.place_piece({"kind":"face","axis":1,"cell":cell+Vector3i(x*2,6,z*2)},&"floor_slab",&"shellstone")
	for x in 4:
		for y in 3:
			player.placement.place_piece({"kind":"face","axis":2,"cell":cell+Vector3i(x*2,y*2,0)},&"wall_panel",&"resinheart")
	for z in 4:
		for y in 3:
			player.placement.place_piece({"kind":"face","axis":0,"cell":cell+Vector3i(0,y*2,z*2)},&"wall_panel",&"resinheart")
			player.placement.place_piece({"kind":"face","axis":0,"cell":cell+Vector3i(8,y*2,z*2)},&"glazed_window" if y==1 and z==1 else &"wall_panel",&"cinderglass" if y==1 and z==1 else &"resinheart")
	for x in 4:
		for y in 3:
			if x==1 and y==1: continue # The framed door occupies both lower faces.
			player.placement.place_piece({"kind":"face","axis":2,"cell":cell+Vector3i(x*2,y*2,8)},&"door" if x==1 and y==0 else &"wall_panel",&"resinheart")
	var lamp:=StrangeResourceArt.fixture_visual("lantern_lamp")
	house.add_child(lamp)
	lamp.global_position=centre+Vector3(.8,.95,2)
	var bench:=MeshInstance3D.new()
	bench.mesh=AuthoredAssets.mesh_for("workbench")
	house.add_child(bench)
	bench.global_position=centre+Vector3(.8,0,2)
	review_camera.global_position=centre+Vector3(3.4,1.65,3.6)
	review_camera.look_at(centre+Vector3(1,.7,1))
	caption.text="A FIND BROUGHT HOME · RESINHEART WORKSHOP AND LANTERNHEART LAMP"
	await _capture("lantern-workshop-day")
	$Sun.light_energy*=.4
	caption.text="THE SAME INTERIOR AT DUSK · LOCAL WARM LIGHT"
	await _capture("lantern-workshop-dusk")

func _capture(id: String) -> void:
	for i in 2: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK,"capture "+id)
