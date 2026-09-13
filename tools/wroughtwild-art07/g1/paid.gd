extends "res://tests/living_frontier_flow.gd"
## Actual finite no-grants acquisition and paid home on retained LF3 seed 77.
## Harness paces gathering/address selection. Measured route and entry use input.
const SAVE="user://g1-paid.json"
const WIDTH=6
const DEPTH=6
var route:PackedVector3Array
var report:Dictionary={"checks":[],"walk":{},"scope":"No supplied inventory, kits or unlocks. Gathering travel/address selection paced; route and entry walked with native controller."}
var output:=""
var selected:=""
var spent:Dictionary={}
var home:Dictionary={}
var harvested_id:=""
var walked_metres:=0.0
var walk_frames:=0
var walk_images:=0
func _ready():
	world_seed=77;world_profile="living_frontier_wave3"
	_build_world(world_seed);player.class_panel.choose("warden")
	for n in [player,player.placement,player.combat,player.spring_arm,mob_packs]:n.set_physics_process(false)
	mob_packs.set_process(false);set_physics_process(false)
	for h in terrain.map.frontier_hosts:
		if h.id=="lf3_red_rooting":route=h.source_route
	output="res://../evidence/paid-"+("art" if G1Art.enabled() else "baseline")+("-"+RenderingServer.get_current_rendering_method() if "--capture" in OS.get_cmdline_user_args() else "")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--run-id="):output+="-"+arg.get_slice("=",1)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	execute.call_deferred()
func check(ok:bool,label:String)->bool:
	super.check(ok,label);report.checks.append({"ok":ok,"label":label});return ok
func execute():
	var manager:=SaveManager.new()
	if "--restart" in OS.get_cmdline_user_args():
		var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(SAVE))
		check(manager.read(SAVE,player),"fresh process paid home restore: "+manager.last_error)
		freeze_fixtures();refresh_stations()
		check(JSON.parse_string(_sim().export_json())==JSON.parse_string(saved.sim),"fresh exact possessions and progression")
		check(_sim().leyline_save()==saved.leylines,"fresh exact source work/lots/claim")
		check(_sim().contraption_save()==saved.contraptions,"fresh exact paid device/heat ownership")
		check(player.placement.enclosure_at(player.position).enclosed,"fresh home remains sheltered")
		check(_sim().structure_piece_count()>140,"fresh full paid home")
		check(get_tree().get_nodes_in_group("contraptions").size()==_sim().contraption_ids().size(),"fresh exactly one scene per native device")
		check(get_tree().get_nodes_in_group("crafting_stations").filter(func(n):return n.player_built).size()==3,"fresh three paid usable workshop stations")
		complete();return
	check(_sim().inventory().is_empty(),"no supplied inventory")
	report.initial=manager.capture(player)
	if not await gather("wood",65):return complete()
	if not craft("workbench_kit"):return complete()
	if not await place_paid_kit("workbench_kit",route[0]+Vector3(5,0,5)):return complete()
	refresh_stations()
	if not craft("timber_frame",2,bench):return complete()
	if not await gather("fieldstone",6) or not craft("mason_yard_kit",1,bench):return complete()
	if not await place_paid_kit("mason_yard_kit",route[0]+Vector3(9,0,5)):return complete()
	var yard:StationSite
	for station in get_tree().get_nodes_in_group("crafting_stations"):
		if station.player_built and station.station_id==&"mason_yard":yard=station
	if not craft("timber_wedge",4) or not await gather("split_stone",16) or not craft("dress_stone",8,yard):return complete()
	if not await gather("iron_ore",16) or not craft("forge_kit",1,bench):return complete()
	if not await place_paid_kit("forge_kit",route[0]+Vector3(5,0,9)):return complete()
	refresh_stations()
	if not craft("smelt_iron",2,forge):return complete()
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		if source.source_id=="red_home_margin":red=source
	await aim_at(red);player.interact()
	for step in 4:await press(String(red.state().next_work))
	check(int(red.state().claim.get("red_salt",0))==16,"real source produces one finite 16-salt claim")
	await press("Collect Red Salt")
	check(_sim().material_count("red_salt")==16 and red.state().claim.get("red_salt",0)==0,"collection transfers exactly once")
	player.work_panel.close_panel()
	if not craft("assemble_red_heat_buffer",1,bench):return complete()
	await blocked_placement()
	if not await place_paid_kit("red_heat_buffer_kit",route[0]+Vector3(7,0,9)):return complete()
	freeze_fixtures()
	var buffer:=fixture("red_heat_buffer")
	await aim_at(buffer);player.interact();await press("Pay for 1 heat");player.work_panel.close_panel()
	check(machine(buffer).heat==1 and _sim().material_count("red_salt")==10,"placed buffer's heat costs two real salt after four-salt frame")
	await get_tree().process_frame

	if not await gather("wood",210):return complete()
	var definition:Dictionary=terrain.map.home_sites[0]
	# Keep the existing east/west source approach clear of the paid home.
	var origin:=Vector3i(int(definition.x)-3,0,int(definition.z)+4)
	terrain.ensure_area(Vector3(definition.x,definition.y,definition.z),24)
	for x in range(-1,WIDTH+1):
		for z in range(-3,DEPTH+1):origin.y=maxi(origin.y,ceili(terrain.surface_position(origin.x+x,origin.z+z).y))
	home=await _home("paid_timber_home",origin,false)
	if home.is_empty():return complete()
	await _use_home(home)
	await harvest_and_stream()
	player.position=home.interior;player.velocity=Vector3.ZERO
	check(manager.write(SAVE,player),"write paid playable home and workshop")
	report.home={"origin":str(origin),"interior":str(home.interior),"store_key":home.store_key,"spent":spent}
	report.paid=manager.capture(player)
	check(manager.write_data("res://g1/paid-home.json",report.paid),"retain independently playable paid checkpoint")
	await walk_route()
	player.position=home.interior;player.velocity=Vector3.ZERO
	check(manager.write(SAVE,player),"save walked route and sheltered home")
	report.final=manager.capture(player)
	complete()
func complete():
	report.failures=failures;report.count=checks
	var f:=FileAccess.open(output+"/paid"+("-restart" if "--restart" in OS.get_cmdline_user_args() else "")+".json",FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("G1_PAID ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)
func blocked_placement():
	var build:=player.placement
	build.set_build_mode_enabled(true);player.build_palette.open_panel();player.build_palette.select_entry(&"red_heat_buffer_kit","kit");player.build_palette.close_panel()
	# Use actual source body as obstruction, with the same native preview lattice.
	var c:=Vector3i(floori(red.position.x),ceili(red.position.y),floori(red.position.z))
	player.position=red.position+Vector3(0,2.3,3)
	build.preview_element={"kind":"volume","axis":0,"cell":c*2};build.preview_visible=true
	var before:=_sim().inventory().duplicate(true)
	var machines:=_sim().contraption_save()
	check(not build.try_place_block(),"real source collision rejects overlapping kit")
	check(_sim().inventory()==before and _sim().contraption_save()==machines,"rejected overlap preserves kit and native ownership")
	build.set_build_mode_enabled(false)
func harvest_and_stream():
	var tree:ResourceNode
	terrain.ensure_area(route[0],30)
	for n in get_tree().get_nodes_in_group("resources"):
		if n.visual==&"tree" and n.remaining_units>0 and n.global_position.distance_to(route[0])<24:tree=n;break
	if not check(tree!=null,"surviving actual route tree exists"):return
	harvested_id=tree.resource_id
	var original_units:=tree.remaining_units
	player.global_position=tree.global_position+Vector3(0,1.2,1.3)
	player._apply_work(tree,tree.work(_sim()))
	check(tree.drive_progress>0,"route tree keeps partial native work")
	var progress:=tree.drive_progress
	var old_instance:=tree.get_instance_id()
	var at:=tree.global_position
	terrain.resource_stream.capture()
	terrain.resource_stream.focus(Vector3(800,40,800),true)
	check(not is_instance_valid(tree),"real stream retirement frees harvested actor")
	terrain.resource_stream.focus(at,true)
	tree=terrain.resource_stream.materialise(harvested_id)
	for frame in 2:await get_tree().process_frame
	check(tree.get_instance_id()!=old_instance and tree.drive_progress==progress and tree.remaining_units==original_units,"stream reentry restores exact stock and partial work")
	check(not G1Art.enabled() or tree.has_meta("g1_source"),"stream restores owned G1 source adapter")
	var carried:=_sim().material_count("wood")
	for attempt in 12:
		if tree.remaining_units==0:break
		player._apply_work(tree,tree.work(_sim()))
	check(tree.remaining_units==0,"normal work exhausts route tree")
	await collect()
	terrain.resource_stream.capture()
	check(not terrain.resource_stream.records.has(harvested_id),"depletion survives in authoritative finite ledger")
	check(_sim().material_count("wood")>=carried,"released wood uses ordinary capacity-aware pickups")
func walk_route():
	player.work_panel.close_panel();player.build_palette.close_panel();player.placement.set_build_mode_enabled(false)
	player.position=route[2]+Vector3.UP*1.2;player.velocity=Vector3.ZERO;player.rotation=Vector3.ZERO
	player.set_physics_process(true);player.combat.set_physics_process(true)
	if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args():
		player.hide();player.hud.hide();player.camera.position=Vector3(0,.65,0);player.camera.rotation=Vector3.ZERO
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output+"/walk"))
	for frame in 45:await get_tree().physics_frame
	var previous:=player.global_position
	var positions:Array=[]
	var stalled:=false
	Input.action_press("move_forward")
	for i in range(3,route.size()-3):
		var target:Vector3=route[i]
		var reached:=false
		for frame in 180:
			var delta:Vector3=(target-player.global_position)*Vector3(1,0,1)
			if delta.length()<.55:reached=true;break
			player.look_at(player.global_position+delta)
			await get_tree().physics_frame
			walked_metres+=player.global_position.distance_to(previous);previous=player.global_position
			walk_frames+=1
			if DisplayServer.get_name()!="headless" and "--capture" in OS.get_cmdline_user_args() and walk_frames%18==0:
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png(output+"/walk/%04d.png"%walk_images);walk_images+=1
			if frame%20==0:positions.append([previous.x,previous.y,previous.z])
		if not reached:stalled=true;report.walk["stalled_waypoint"]=i;break
	Input.action_release("move_forward")
	report.walk.merge({"metres":walked_metres,"positions":positions,"stalled":stalled})
	check(not stalled and walked_metres>100,"actual input/controller traverses existing source route without teleport or collision changes")
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
	# INT-03B found the old far-right forge's body inside the wall skin. Move
	# it forward and half a cell inward using the existing off-grid placement;
	# keep both houses, their catalogue and their paid quantities unchanged.
	var chest:=_place(&"chest",&"resinheart" if developed else &"wood",origin+Vector3i(4,1,4)) as PlacedBlock
	if chest==null:return {}
	home.chest_element=chest.element.duplicate(true)
	home.store_key=chest.store_key()
	home.interior=interior
	await get_tree().physics_frame
	return home

func _place(id: StringName, family: StringName, cell: Vector3i, kind := "volume", axis := 0, rotation_step := 0, kit := false, half_offset := Vector3i.ZERO) -> Node3D:
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
	var element:={"kind":kind,"axis":axis,"cell":cell*2+half_offset}
	# Addresses are deterministic fixture targets, but ordinary refusal and
	# payment stay authoritative. No direct place_piece or station creation.
	player.global_position=Vector3(cell)+Vector3(-2,1.97,-2)
	var source: String=String(id) if kit else String(_sim().build_material(family).source)
	var cost:=1 if kit else int(_sim().shape(id).material_cost)
	var before:=_sim().material_count(source)
	var refusal:=build.element_refusal(element)
	if not check(refusal.is_empty(),"normal target accepts %s %s at%s: %s"%[family,id,cell,refusal]):return null
	build.preview_element=element
	build.preview_visible=true
	if not check(build.try_place_block(),"normal paid placement succeeds for %s at%s: %s"%[id,cell,build.preview_reason]):return null
	check(_sim().material_count(source)==before-cost,"placement pays exactly the native cost: "+String(id))
	spent[source]=int(spent.get(source,0))+cost
	if kit:
		var at:=Vector3(cell)+Vector3(.5,0,.5)+Vector3(half_offset)*.5
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
		if not check(station!=null and station.player_built and station.is_built(_sim()),id+" contains the player's built "+station_id):continue
		var from:=_station_stand(home,station)
		query.transform=Transform3D(Basis.IDENTITY,from)
		check(get_world_3d().direct_space_state.intersect_shape(query,32).is_empty(),id+" actual capsule fits the station's working position: "+station_id)
		if check(_aim(station,from,station.global_position+Vector3.UP),id+" unobstructed E ray reaches "+station_id):
			player.interact()
			check(player.work_panel.is_open() and player.work_panel._station==station,id+" E opens this physical station's work panel: "+station_id)
			player.work_panel.close_panel()
	var held:=_sim().material_count("wood")
	if check(_aim(chest,origin+Vector3(3.5,1.97,2.9),chest.global_position),id+" real E ray reaches the chest from its working aisle"):
		player.interact()
		check(player.chest_panel.is_open() and player.chest_panel.store_key==String(home.store_key),id+" E opens this chest's native store")
		check(player.chest_panel.store(&"wood",19)==19 and _sim().material_count("wood")==held-19,id+" storage moves nineteen carried timber into this chest exactly once")
		check(player.chest_panel.take(&"wood",2)==2 and _sim().material_count("wood")==held-17,id+" taking two timber uses the same ordinary capacity validation")
		player.chest_panel.close_panel()
	check(int(_sim().store_contents(String(home.store_key)).get("wood",0))==17,id+" keeps seventeen timber in its own store")
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

func _station_stand(home: Dictionary, station: StationSite) -> Vector3:
	var at:=station.global_position+Vector3(0,.97,-1.6)
	# The last forge sits beside the wall. Its usable front can be approached
	# slightly off centre without teleporting the player's capsule into that wall.
	at.x=clampf(at.x,float(home.origin.x)+.65,float(home.origin.x)+WIDTH-.65)
	return at
