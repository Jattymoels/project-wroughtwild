extends Node3D
## Two complete homes assembled with the ordinary catalogue and paid placement.
## Fixed review stock, an authored ground plane and the existing roof unlock
## isolate geometry/usability. This is not an economy-pacing or generated-world
## acceptance claim. --home-capture writes isolated evidence; --home-play leaves
## the completed scene available for ordinary first-person use after its checks.
const OUTPUT := "res://../captures/home"
const WIDTH := 6
const DEPTH := 6
const STOCK := {"wood":200,"shellstone":300,"woven_reed":80,"corkbark":80,
	"cinderglass":40,"resinheart":50,"slate":100,"stone":8,
	"workbench_kit":3,"mason_yard_kit":3,"forge_kit":3}
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var homes: Array[Dictionary]=[]
var sun: DirectionalLight3D
var environment: Environment
var review_camera: Camera3D
var spent: Dictionary={}
var selected := ""
var report: Dictionary={"scope":"Authored ground, fixed review stock and existing stonecut_blocks unlock; ordinary catalogue, payment, E and player movement. Not economy pacing.","views":[]}

func check(ok: bool, label: String) -> bool:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL HOME_WORKSHOP: ",label)
	return ok

func _ready() -> void:
	get_window().size=Vector2i(1280,720)
	_world()
	player=preload("res://scenes/player.tscn").instantiate()
	player.position=Vector3(-3,1,-3)
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	sim=player.inventory.get_sim()
	_run.call_deferred()

func _world() -> void:
	var ground:=StaticBody3D.new()
	ground.name="AuthoredReviewGround"
	ground.position=Vector3(10,-.5,3)
	var box:=BoxShape3D.new()
	box.size=Vector3(64,1,40)
	var collision:=CollisionShape3D.new()
	collision.shape=box
	ground.add_child(collision)
	var mesh:=MeshInstance3D.new()
	var cube:=BoxMesh.new()
	cube.size=box.size
	mesh.mesh=cube
	var surface:=StandardMaterial3D.new()
	surface.albedo_color=Color("74785b")
	surface.roughness=1
	mesh.material_override=surface
	ground.add_child(mesh)
	add_child(ground)
	var world:=WorldEnvironment.new()
	environment=Environment.new()
	environment.background_mode=Environment.BG_SKY
	var sky:=Sky.new()
	var sky_material:=ProceduralSkyMaterial.new()
	sky_material.sky_top_color=Color("7e9cac")
	sky_material.sky_horizon_color=Color("c3c4b6")
	sky_material.ground_horizon_color=Color("acae9c")
	sky.sky_material=sky_material
	environment.sky=sky
	environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color=Color("bcc6c4")
	environment.ambient_light_energy=.45
	environment.tonemap_mode=Environment.TONE_MAPPER_FILMIC
	world.environment=environment
	add_child(world)
	sun=DirectionalLight3D.new()
	sun.name="ReviewSun"
	sun.rotation=Vector3(-.85,-.55,0)
	sun.light_color=Color("fff1d5")
	sun.light_energy=1.15
	sun.shadow_enabled=true
	add_child(sun)

func _run() -> void:
	if not check(sim.last_error().is_empty(),"native rules loaded"):
		_finish()
		return
	check(sim.structure_piece_count()==0,"isolated scene starts with no placed construction")
	for id: String in STOCK: sim.add_material(id,int(STOCK[id]))
	check(not sim.world_effect_active("stonecut_blocks"),"early home starts without a pitched-roof reward")
	for frame in 3:await get_tree().physics_frame
	var early:=await _home("early_timber",Vector3i.ZERO,false)
	if early.is_empty():_finish();return
	homes.append(early)
	check(not sim.world_effect_active("stonecut_blocks"),"complete flat-roof shelter never needs the roof unlock")
	sim.record_world_effect("stonecut_blocks")
	check(sim.shape_unlocked("roof_wedge"),"review-only existing reward permits the developed roof")
	var developed:=await _home("developed_workshop",Vector3i(14,0,0),true)
	if developed.is_empty():_finish();return
	homes.append(developed)
	player.placement.set_build_mode_enabled(false)
	for home: Dictionary in homes:await _use_home(home)
	await _save_restore()
	if "--home-capture" in OS.get_cmdline_user_args():await _captures()
	_finish()

func _home(id: String, origin: Vector3i, developed: bool) -> Dictionary:
	var home:={"id":id,"origin":origin,"stations":{},"door_element":{},"chest_element":{}}
	var floor_family: StringName=&"shellstone" if developed else &"wood"
	# A full-cell platform meets the door's base flush. Three-metre walls give
	# real headroom over the two-metre entry and the existing station bodies.
	for x in WIDTH:
		for z in DEPTH:
			if _place(&"cube",floor_family,origin+Vector3i(x,0,z))==null:return {}
	for y in range(1,4):
		for i in WIDTH:
			for wall in [[0,Vector3i(0,y,i)],[0,Vector3i(WIDTH,y,i)],[2,Vector3i(i,y,DEPTH)],[2,Vector3i(i,y,0)]]:
				var offset: Vector3i=wall[1]
				if int(wall[0])==2 and offset.z==0 and offset.x==2 and y<3:continue
				var shape: StringName=&"wall_panel"
				var family: StringName=&"wood"
				if developed:
					family=&"shellstone"
					if y>=2:
						shape=&"light_panel"
						family=&"woven_reed" if y==2 else &"corkbark"
						if y==2 and i in [1,4]:shape=&"glazed_window";family=&"cinderglass"
				if _place(shape,family,origin+offset,"face",int(wall[0]))==null:return {}
	var door:=_place(&"door",&"resinheart" if developed else &"wood",origin+Vector3i(2,1,0),"face",2) as PlacedBlock
	if door==null:return {}
	home.door_element=door.element.duplicate(true)
	var interior:=Vector3(origin)+Vector3(2.5,1.97,2.5)
	check(not player.placement.enclosure_at(interior).enclosed,id+" unfinished roof correctly leaves the room open")
	for x in WIDTH:
		for z in DEPTH:
			if developed:
				var rise:=mini(z,DEPTH-1-z)
				if _place(&"roof_wedge",&"slate",origin+Vector3i(x,4+rise,z),"volume",0,0 if z<DEPTH/2 else 2)==null:return {}
			else:
				if _place(&"floor_slab",&"wood",origin+Vector3i(x,4,z),"face",1)==null:return {}
	if developed:
		# The full existing stone wedges close the two triangular gable ends.
		for z in DEPTH:
			for rise in mini(z,DEPTH-1-z):
				for side in [0,WIDTH]:
					if _place(&"wall_panel",&"shellstone",origin+Vector3i(side,4+rise,z),"face",0)==null:return {}
	if _place(&"stairs",&"stone" if developed else &"wood",origin+Vector3i(2,0,-1))==null:return {}
	check(player.placement.enclosure_at(interior).enclosed,id+" complete roof and walls provide authoritative shelter")
	await get_tree().physics_frame
	# Two-metre station spacing also lets the untouched baseline complete these
	# matched homes. The compact adjacency fault has its own runtime regression.
	for item in [["workbench_kit",1],["mason_yard_kit",3],["forge_kit",5]]:
		var site:=_place(StringName(item[0]),floor_family,origin+Vector3i(int(item[1]),1,4),"volume",0,2,true) as StationSite
		if site==null:return {}
		home.stations[String(site.station_id)]=site.station_key
		await get_tree().physics_frame
	var chest:=_place(&"chest",&"resinheart" if developed else &"wood",origin+Vector3i(4,1,4)) as PlacedBlock
	if chest==null:return {}
	home.chest_element=chest.element.duplicate(true)
	home.store_key=chest.store_key()
	home.interior=interior
	await get_tree().physics_frame
	return home

func _place(id: StringName, family: StringName, cell: Vector3i, kind := "volume", axis := 0, rotation_step := 0, kit := false) -> Node3D:
	var build:=player.placement
	var palette:=player.build_palette
	build.set_build_mode_enabled(true)
	# Real catalogue selection is retained between repeated identical pieces.
	var selection:="%s/%s/%d/%s"%[id,family,rotation_step,kit]
	if selection!=selected:
		build.fine_mode=false
		palette.group="All"
		palette.open_panel()
		palette.select_entry(id,"kit" if kit else "shape")
		palette.select_material(family)
		for turn in 4:
			if build.preview_rotation_step==rotation_step or not build.rotatable():break
			palette.turn(1)
		palette.close_panel()
		selected=selection
	var element:={"kind":kind,"axis":axis,"cell":cell*2}
	# Addresses are deterministic fixture targets, but ordinary refusal and
	# payment stay authoritative. No direct place_piece or station creation.
	player.global_position=Vector3(cell)+Vector3(-2,1.97,-2)
	var source: String=String(id) if kit else String(sim.build_material(family).source)
	var cost:=1 if kit else int(sim.shape(id).material_cost)
	var before:=sim.material_count(source)
	var refusal:=build.element_refusal(element)
	if not check(refusal.is_empty(),"normal target accepts %s %s at%s: %s"%[family,id,cell,refusal]):return null
	build.preview_element=element
	build.preview_visible=true
	if not check(build.try_place_block(),"normal paid placement succeeds for %s at%s: %s"%[id,cell,build.preview_reason]):return null
	check(sim.material_count(source)==before-cost,"placement pays exactly the native cost: "+String(id))
	spent[source]=int(spent.get(source,0))+cost
	if kit:
		var at:=Vector3(cell)+Vector3(.5,0,.5)
		for child in get_children():
			if child is StationSite and child.player_built and child.global_position.is_equal_approx(at):return child
	else:
		return _piece(element)
	check(false,"paid placement created its expected physical object: "+String(id))
	return null

func _piece(element: Dictionary) -> PlacedBlock:
	for child in get_children():
		if child is PlacedBlock and child.element==element:return child
	return null

func _station(key: String) -> StationSite:
	for child in get_children():
		if child is StationSite and child.station_key==key:return child
	return null

func _aim(target: Node3D, stand: Vector3, point: Vector3) -> bool:
	player.global_position=stand
	player.velocity=Vector3.ZERO
	player.camera.global_position=stand+Vector3.UP*WroughtwildPlayer.FP_EYE_HEIGHT
	player.camera.look_at(point)
	return player.aim_probe().get("target")==target

func _use_home(home: Dictionary) -> void:
	var origin:=Vector3(home.origin)
	var id:=String(home.id)
	var door:=_piece(home.door_element)
	var chest:=_piece(home.chest_element)
	if not check(door!=null and chest!=null,id+" physical door and storage are present"):return
	player.placement.set_build_mode_enabled(false)
	var stand:=origin+Vector3(2.5,1.97,-.3)
	if check(_aim(door,stand,door.leaf_point()),id+" real E ray reaches the closed door from its front step"):
		player.interact()
		check(door.open,id+" normal E opens the door")
	await get_tree().physics_frame
	# Probe the actual player capsule, then walk it from ground up the two
	# existing stair risers and through the open leaf using the normal controller.
	var shape:=player.get_node("CollisionShape3D").shape as CapsuleShape3D
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.exclude=[player]
	for z in [.25,.75,1.25,1.75,2.25,2.75,3.25]:
		query.transform=Transform3D(Basis.IDENTITY,origin+Vector3(2.5,1.97,z))
		var blocked:=get_world_3d().direct_space_state.intersect_shape(query,32)
		check(blocked.is_empty(),id+" actual capsule fits the doorway and central aisle at z="+str(z)+": "+_hits(blocked))
	player.global_position=origin+Vector3(2.5,.98,-1.8)
	player.rotation=Vector3.ZERO
	player.spring_arm.rotation=Vector3.ZERO
	player.camera.transform=Transform3D.IDENTITY
	player.velocity=Vector3.ZERO
	player.test_walk=Vector2(0,1)
	player.set_physics_process(true)
	for frame in 84:
		await get_tree().physics_frame
		if player.position.z>=origin.z+2.7:break
	player.test_walk=Vector2.ZERO
	player.set_physics_process(false)
	check(player.position.z>=origin.z+2.5 and absf(player.position.x-origin.x-2.5)<.12,id+" ordinary walking climbs the steps and enters without a jump or teleport; actual="+str(player.position-origin))
	check(player.position.y>origin.y+1.8 and player.position.y<origin.y+2.1,id+" walking ends supported at the interior floor level")
	player.global_position=home.interior
	player.combat._shelter_probe_left=0
	player.combat._tick_shelter(1)
	check(player.combat.sheltered and player.placement.enclosure_at(home.interior).enclosed,id+" the occupied room grants shelter with its door open")
	for station_id: String in home.stations:
		var station:=_station(home.stations[station_id])
		if not check(station!=null and station.player_built and station.is_built(sim),id+" contains the player's built "+station_id):continue
		var from:=_station_stand(home,station)
		query.transform=Transform3D(Basis.IDENTITY,from)
		check(get_world_3d().direct_space_state.intersect_shape(query,32).is_empty(),id+" actual capsule fits the station's working position: "+station_id)
		if check(_aim(station,from,station.global_position+Vector3.UP),id+" unobstructed E ray reaches "+station_id):
			player.interact()
			check(player.work_panel.is_open() and player.work_panel._station==station,id+" E opens this physical station's work panel: "+station_id)
			player.work_panel.close_panel()
	var held:=sim.material_count("wood")
	if check(_aim(chest,origin+Vector3(4.5,1.97,2.9),chest.global_position),id+" real E ray reaches the chest from its working aisle"):
		player.interact()
		check(player.chest_panel.is_open() and player.chest_panel.store_key==String(home.store_key),id+" E opens this chest's native store")
		check(player.chest_panel.store(&"wood",5)==5 and sim.material_count("wood")==held-5,id+" storage moves five carried timber into this chest exactly once")
		check(player.chest_panel.take(&"wood",2)==2 and sim.material_count("wood")==held-3,id+" taking two timber uses the same ordinary capacity validation")
		player.chest_panel.close_panel()
	check(int(sim.store_contents(String(home.store_key)).get("wood",0))==3,id+" keeps three timber in its own store")
	if check(_aim(door,origin+Vector3(2.5,1.97,1.8),door.leaf_point()),id+" the swung leaf remains reachable for closing"):
		player.interact()
		check(not door.open,id+" E closes the door without altering enclosure")
	await get_tree().physics_frame
	query.transform=Transform3D(Basis.IDENTITY,origin+Vector3(2.5,1.97,0))
	var closed_hits:=get_world_3d().direct_space_state.intersect_shape(query,32)
	var door_blocks:=false
	for hit in closed_hits:door_blocks=door_blocks or hit.collider==door
	check(door_blocks,id+" a closed door physically blocks the same capsule")
	check(player.placement.enclosure_at(home.interior).enclosed,id+" closing preserves authoritative shelter")

func _hits(rows: Array) -> String:
	var names:=PackedStringArray()
	for row in rows:
		var body: Object=row.collider
		names.append(String(body.shape_id) if body is PlacedBlock else String(body.station_id) if body is StationSite else str(body))
	return ", ".join(names)

func _save_restore() -> void:
	var directory:=ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(directory)
	var path:=directory.path_join("home-checkpoint.json")
	var manager:=SaveManager.new()
	player.global_position=homes[1].interior
	var baseline:=manager.capture(player)
	var held:=sim.inventory().duplicate(true)
	if not check(manager.write_data(path,baseline),"both completed homes write an isolated atomic checkpoint: "+manager.last_error):return
	player.global_position+=Vector3(8,0,0)
	if not check(manager.read(path,player),"both completed homes restore through the normal SaveManager: "+manager.last_error):return
	await get_tree().physics_frame
	var restored:=manager.capture(player)
	check(restored.blocks==baseline.blocks,"save/restore retains every paid shape, material, address and orientation")
	# Godot sanitizes auto-generated @ node names when assigned on restore.
	# The baseline reproduces that too; retain exact comparison of every field,
	# including authoritative station_key, with only that engine name conversion.
	var expected_stations: Array=baseline.stations.duplicate(true)
	for entry: Dictionary in expected_stations:entry.name=String(entry.name).validate_node_name()
	check(restored.stations==expected_stations,"save/restore retains physical station ownership, position and orientation")
	check(sim.inventory()==held,"loading the completed homes does not pay or refund a second time")
	check(player.global_position.is_equal_approx(Vector3(baseline.player.position[0],baseline.player.position[1],baseline.player.position[2])),"loading restores the interior player position")
	for home: Dictionary in homes:
		check(_piece(home.door_element)!=null and _piece(home.chest_element)!=null,String(home.id)+" restores its usable door and chest")
		check(player.placement.enclosure_at(home.interior).enclosed,String(home.id)+" remains sheltered after restore")
		check(int(sim.store_contents(String(home.store_key)).get("wood",0))==3,String(home.id)+" stored timber restores once in the same chest")
		for key: String in home.stations.values():check(_station(key)!=null,String(home.id)+" keeps a reachable physical station identity")
	# Reopen one restored station and each restored store through real E. Reads
	# must not deposit again or depend on references to the freed pre-load nodes.
	for home: Dictionary in homes:
		var origin:=Vector3(home.origin)
		var chest:=_piece(home.chest_element)
		if chest!=null and check(_aim(chest,origin+Vector3(4.5,1.97,2.9),chest.global_position),String(home.id)+" restored chest is physically targetable"):
			player.interact()
			check(player.chest_panel.is_open() and int(sim.store_contents(String(home.store_key)).get("wood",0))==3,String(home.id)+" restored E access leaves stored contents unchanged")
			player.chest_panel.close_panel()
		var forge:=_station(home.stations.get("forge_basic",""))
		if forge!=null and check(_aim(forge,_station_stand(home,forge),forge.global_position+Vector3.UP),String(home.id)+" restored forge is physically targetable"):
			player.interact()
			check(player.work_panel.is_open() and player.work_panel._station==forge,String(home.id)+" restored E opens the correct forge")
			player.work_panel.close_panel()
	report.paid_materials=spent.duplicate(true)
	report.blocks=restored.blocks.size()
	report.stations=restored.stations.size()
	report.save_path=path

func _station_stand(home: Dictionary, station: StationSite) -> Vector3:
	var at:=station.global_position+Vector3(0,.97,-1.6)
	# The last forge sits beside the wall. Its usable front can be approached
	# slightly off centre without teleporting the player's capsule into that wall.
	at.x=clampf(at.x,float(home.origin.x)+.65,float(home.origin.x)+WIDTH-.65)
	return at

func _captures() -> void:
	if DisplayServer.get_name()=="headless":
		check(false,"--home-capture requires a rendered review process")
		return
	var directory:=ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(directory)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=0
	review_camera=Camera3D.new()
	review_camera.name="FixedHomeReviewCamera"
	review_camera.fov=75
	add_child(review_camera)
	review_camera.make_current()
	player.placement.set_build_mode_enabled(false)
	for child in player.get_children():
		if child is CanvasLayer:child.hide()
	var hands:=player.camera.get_node_or_null("FirstPersonHands") as Node3D
	if hands!=null:hands.hide()
	for home: Dictionary in homes:
		var origin:=Vector3(home.origin)
		var views:=[{"name":"exterior","at":origin+Vector3(-5,4.6,-7),"target":origin+Vector3(3,2.6,2)},
			{"name":"interior","at":origin+Vector3(1.05,2.65,1.1),"target":origin+Vector3(3.0,2.0,4.4)}]
		for view: Dictionary in views:
			player.global_position=view.at-Vector3.UP*WroughtwildPlayer.FP_EYE_HEIGHT
			review_camera.global_position=view.at
			review_camera.look_at(view.target)
			for phase: String in ["day","dusk"]:
				sun.light_energy=1.15 if phase=="day" else .45
				sun.light_color=Color("fff1d5") if phase=="day" else Color("d9b58a")
				environment.ambient_light_energy=.45 if phase=="day" else .24
				for frame in 90:await get_tree().process_frame
				var times: Array[float]=[]
				var last:=Time.get_ticks_usec()
				for frame in 600:
					await get_tree().process_frame
					var now:=Time.get_ticks_usec()
					times.append(float(now-last)/1000.0)
					last=now
				await RenderingServer.frame_post_draw
				var file: String=String(home.id)+"-"+String(view.name)+"-"+phase+".png"
				check(get_viewport().get_texture().get_image().save_png(directory.path_join(file))==OK,"rendered home view writes: "+file)
				check(review_camera.global_position.is_equal_approx(view.at),"fixed capture camera retains its requested pose: "+file)
				times.sort()
				var actual:=review_camera.global_position
				report.views.append({"file":file,"camera":[actual.x,actual.y,actual.z],"target":[view.target.x,view.target.y,view.target.z],"fov":review_camera.fov,
					"median_ms":times[times.size()/2],"p95_ms":times[ceili(times.size()*.95)-1],"frames":times.size(),
					"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
		await _ghost_capture(home,directory)
	for child in player.get_children():
		if child is CanvasLayer:child.show()
	if hands!=null:hands.show()
	player.camera.make_current()
	review_camera.free()
	review_camera=null
	sun.light_energy=1.15
	sun.light_color=Color("fff1d5")
	environment.ambient_light_energy=.45

func _ghost_capture(home: Dictionary, directory: String) -> void:
	var prior_player:=player.global_transform
	var prior_camera:=review_camera.global_transform
	var held:=sim.inventory().duplicate(true)
	var origin:=Vector3(home.origin)
	var build:=player.placement
	var prior_placement_camera:=build.camera
	build.camera=review_camera
	build.set_build_mode_enabled(true)
	var palette:=player.build_palette
	build.fine_mode=false
	palette.group="All"
	palette.open_panel()
	palette.select_entry(&"workbench_kit","kit")
	palette.select_material(&"wood")
	for turn in 4:
		if build.preview_rotation_step==2:break
		palette.turn(1)
	palette.close_panel()
	player.global_position=origin+Vector3(3.5,1.97,1.1)
	review_camera.global_position=player.global_position+Vector3.UP*WroughtwildPlayer.FP_EYE_HEIGHT
	review_camera.look_at(origin+Vector3(3.5,1,2.7))
	sun.light_energy=1.15
	sun.light_color=Color("fff1d5")
	environment.ambient_light_energy=.45
	for frame in 3:await get_tree().physics_frame
	build._update_preview()
	check(build.preview_visible and build.preview_valid,String(home.id)+" fixed normal camera ray produces a valid interior kit ghost: "+build.preview_reason)
	for frame in 12:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var file:=String(home.id)+"-station-ghost-day.png"
	check(get_viewport().get_texture().get_image().save_png(directory.path_join(file))==OK,"actual station placement preview writes: "+file)
	report.views.append({"file":file,"camera":[review_camera.global_position.x,review_camera.global_position.y,review_camera.global_position.z],"scope":"Actual held-kit selection and _update_preview ray; no placement and no performance sample."})
	check(sim.inventory()==held,String(home.id)+" preview capture spends no kit or construction stock")
	build.set_build_mode_enabled(false)
	build.camera=prior_placement_camera
	player.global_transform=prior_player
	review_camera.global_transform=prior_camera

func _finish() -> void:
	report.checks=checks
	report.failures=failures
	var directory:=ProjectSettings.globalize_path(OUTPUT)
	DirAccess.make_dir_recursive_absolute(directory)
	# Ordinary headless regression runs must not replace the rendered evidence.
	var manifest:="manifest-headless.json" if DisplayServer.get_name()=="headless" else "manifest.json"
	var file:=FileAccess.open(directory.path_join(manifest),FileAccess.WRITE)
	if file!=null:file.store_string(JSON.stringify(report,"  "));file.close()
	print("HOME_WORKSHOP_REVIEW %d checks, %d failures"%[checks,failures])
	if failures==0 and "--home-play" in OS.get_cmdline_user_args():
		player.global_position=homes[0].interior
		player.camera.transform=Transform3D.IDENTITY
		player.spring_arm.rotation=Vector3.ZERO
		player.placement.set_build_mode_enabled(false)
		player.set_physics_process(true)
		player.combat.set_physics_process(true)
		player.placement.set_physics_process(true)
		player.hud.notify("Review homes ready. Fixed review stock; ordinary controls and station access.")
		player._capture_mouse()
		return
	get_tree().quit(1 if failures else 0)
