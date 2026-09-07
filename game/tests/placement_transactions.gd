extends "res://tests/home_workshop_review.gd"
## INT-03C: click dispatch, actual geometry and saved ownership away from origin.
## Inspection stock isolates transactions and fit; never opens a normal save.

func _run() -> void:
	if OS.get_cmdline_user_args().has("--placement-restore-only"):
		await _fresh_restore()
		print("PLACEMENT_RESTART %d checks, %d failures" % [checks,failures])
		get_tree().quit(1 if failures else 0)
		return
	check(sim.contraption_bind_world("legacy_v1",0),"isolated legacy machine ledger starts empty")
	for id in sim.kit_item_ids(): sim.add_material(id,80)
	sim.add_material("wood",2000)
	player.hud.hide()
	await get_tree().physics_frame
	await _fixtures()
	await _corners()
	print("PLACEMENT_TRANSACTIONS %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _click(action: String) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	player._unhandled_input(event)

func _select_fixture(kind: String, cell: Vector3i, turn: int) -> void:
	var build := player.placement
	build.set_build_mode_enabled(true)
	build._select_kit(StringName(kind+"_kit"))
	build.preview_rotation_step=turn
	build.preview_element={"kind":"volume","axis":0,"cell":cell}
	build.preview_visible=true

func _fixtures() -> void:
	# Exercise every current kit at a positive world height and far from origin,
	# with all four yaws. Existing contraption tests mostly use y=0 near origin.
	var build := player.placement
	var expected: Dictionary={}
	for i in sim.contraption_kinds().size():
		var kind: String=sim.contraption_kinds()[i]
		for turn in 4:
			var at:=Vector3(300+i*5,24,300+turn*5)
			var cell:=Vector3i(at*2)
			var floor:=StaticBody3D.new()
			var shape:=CollisionShape3D.new()
			shape.shape=BoxShape3D.new()
			shape.shape.size=Vector3(4,1,4)
			floor.add_child(shape)
			add_child(floor)
			floor.position=at+Vector3(.5,-.5,.5)
			await get_tree().physics_frame
			_select_fixture(kind,cell,turn)
			var kit:=kind+"_kit"
			var count:=sim.material_count(kit)
			check(build.element_accepts(build.preview_element),kind+" initial full footprint is clear")
			_click("primary_action")
			var key:="fixture_%d_%d_%d" % [cell.x,cell.y,cell.z]
			var site:=ContraptionSite.find_site(get_tree(),key)
			check(site!=null and sim.material_count(kit)==count-1,kind+" click pays once and publishes one fixture")
			if site==null: continue
			site.set_physics_process(false)
			await get_tree().physics_frame
			check(site.global_position.is_equal_approx(at+Vector3(.5,0,.5)),kind+" native ground pivot is at chosen world position")
			check(is_equal_approx(site.rotation.y,turn*PI*.5),kind+" yaw agrees with selection")
			check(site._visual!=null and site._visual.is_visible_in_tree(),kind+" authored visual exists and is visible")
			var housing:=site._visual.find_child("Housing",true,false) as MeshInstance3D
			if kind=="pressure_feeder": housing=site._visual.find_child("Part",true,false)
			check(housing!=null and housing.mesh!=null and housing.mesh.get_aabb().size.length()>0,kind+" has nonempty geometry")
			var target:=site.global_position+Vector3.UP*ContraptionSite.bounds_for(kind).y*.5
			player.position=target+Vector3(0,0,2.5)
			player.camera.global_position=player.position
			player.camera.look_at(target)
			check(build._get_view_trace().get("collider")==site,kind+" actual interaction ray reaches body")
			build.set_build_mode_enabled(false)
			_click("interact")
			check(player.work_panel.is_open(),kind+" E opens usable controls")
			player.work_panel.close_panel()
			_select_fixture(kind,cell,turn)
			_click("primary_action")
			check(sim.material_count(kit)==count-1 and sim.contraption_ids().size()==expected.size()+1,kind+" duplicate click retains second kit")
			expected[key]=sim.contraption_state(key).duplicate(true)
			if turn==0 and DisplayServer.get_name()!="headless":
				DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/placement"))
				player.camera.make_current()
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../captures/placement/"+kind+".png")
	var owned:=sim.inventory().duplicate(true)
	var manager:=SaveManager.new()
	var path:="user://int03c-fixtures.json"
	check(manager.write(path,player),"atomic isolated fixture checkpoint writes")
	for repeat in 2:
		var restored:=manager.read(path,player)
		check(restored,"fixture checkpoint restores repeatedly: "+manager.last_error)
		await get_tree().physics_frame
		check(sim.inventory()==owned and sim.contraption_ids().size()==expected.size(),"restart replaces exact ownership")
		check(get_tree().get_nodes_in_group("contraptions").size()==expected.size(),"restart creates exactly one scene per ledger record")
		for key: String in expected:
			var site:=ContraptionSite.find_site(get_tree(),key)
			check(site!=null and sim.contraption_state(key)==expected[key],"saved fixture state and scene survive: "+key)
	# Removal uses the aimed build control; native regression covers exact recipe
	# refunds, overflow refusal and loaded cargo. Here verify spatial removal once.
	for key: String in expected:
		var site:=ContraptionSite.find_site(get_tree(),key)
		var target:=site.global_position+Vector3.UP*ContraptionSite.bounds_for(site.kind).y*.5
		player.position=target+Vector3(0,0,2.5)
		player.camera.global_position=player.position
		player.camera.look_at(target)
		build.set_build_mode_enabled(true)
		_click("remove_block")
		check(sim.contraption_state(key).is_empty(),"X dismantles exactly the aimed fixture")
		var after:=sim.inventory().duplicate(true)
		_click("remove_block")
		check(sim.inventory()==after,"repeat X cannot refund twice")
		await get_tree().physics_frame

func _corners() -> void:
	var build:=player.placement
	player.position=Vector3(-10,3,-10)
	for fine in [false,true]:
		for turn in 4:
			var cell:=Vector3i(10+turn*10,0,20+(10 if fine else 0))
			if fine: cell+=Vector3i.ONE
			var floor_shape: StringName=&"half_slab" if fine else &"floor_slab"
			# A full station still fits a full room; the floor/wall anchors can be
			# offset by half a cell. Adjacent perpendicular walls match the report.
			for axis in [0,2]:
				for y in 2:
					check(build.place_piece({"kind":"face","axis":axis,"cell":cell+Vector3i(0,y*2,0)},&"wall_panel",&"wood")!=null,"real corner wall created")
			check(build.place_piece({"kind":"face","axis":1,"cell":cell},floor_shape,&"wood")!=null,"real floor created")
			await get_tree().physics_frame
			build.set_build_mode_enabled(true)
			build._select_kit(&"workbench_kit")
			build.preview_element={"kind":"volume","axis":0,"cell":cell}
			build.preview_visible=true
			build.preview_rotation_step=turn
			var count:=sim.material_count("workbench_kit")
			var ghost:=Transform3D()
			if turn==0:
				var base:=Vector3(cell)*.5
				player.camera.global_position=base+Vector3(1.5,1.65,2.5)
				player.camera.look_at(base+Vector3(.25,.0625 if fine else .125,.25))
				build._update_preview()
				check(build.preview_element.get("cell")==cell and build.preview_valid,"actual floor ray produces the legal corner ghost")
				ghost=build._preview_mesh.global_transform
			check(build.element_accepts(build.preview_element),"corner obtains a nonintersecting station anchor: "+build.element_refusal(build.preview_element))
			_click("primary_action")
			check(sim.material_count("workbench_kit")==count-1,"legal corner click pays exactly once")
			await get_tree().physics_frame
			if sim.material_count("workbench_kit")!=count-1: continue
			var site: StationSite
			for node in get_children():
				if node is StationSite and node.position.distance_to(Vector3(cell)*.5)<2: site=node
			check(site!=null,"corner station has a physical scene")
			if site==null: continue
			site.name="Corner_%s_%d" % [fine,turn]
			if turn==0: check(site.global_transform.is_equal_approx(ghost),"placed station exactly matches the visible corner ghost")
			# Query the actual full body separately from placement's contact box.
			var query:=PhysicsShapeQueryParameters3D.new()
			query.shape=StationSite.BODY
			query.transform=site.get_node("CollisionShape3D").global_transform
			query.exclude=[site.get_rid()]
			for hit in get_world_3d().direct_space_state.intersect_shape(query):
				var wall:=hit.collider as PlacedBlock
				check(wall==null or wall.element.axis==1,"full station body clears both corner walls")
			var target:=site.global_position+Vector3.UP*.6
			player.position=target+Vector3(1.3,.6,2.3)
			player.camera.position=Vector3.ZERO
			player.camera.global_position=player.position
			player.camera.look_at(target)
			check(build._get_view_trace().get("collider")==site,"corner remains accessible by a real interaction ray")
			# A real player capsule can approach, but must collide with the station.
			player.position=site.position+Vector3(0,1,2.5)
			var collision:=player.move_and_collide(Vector3(0,0,-3),true)
			check(collision!=null and collision.get_collider()==site,"station still stops actual player motion")
			if DisplayServer.get_name()!="headless" and turn==0:
				player.camera.global_position=target+Vector3(1.3,.6,2.3)
				player.camera.look_at(target)
				build._preview_mesh.hide()
				await RenderingServer.frame_post_draw
				get_viewport().get_texture().get_image().save_png("res://../captures/placement/corner-"+str(fine)+".png")
	var manager:=SaveManager.new()
	var saved:=manager.capture(player)
	check(manager.apply(player,JSON.parse_string(JSON.stringify(saved))),"seated stations restore using saved physical positions")
	check(manager.capture(player).stations==saved.stations,"corner station keys and exact offsets survive restoration")

func _fresh_restore() -> void:
	var path:="user://int03c-fixtures.json"
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var manager:=SaveManager.new()
	check(manager.read(path,player),"fresh process restores isolated fixture checkpoint: "+manager.last_error)
	check(JSON.parse_string(sim.export_json())==JSON.parse_string(saved.sim),"fresh process preserves exact inventory and progression")
	check(JSON.parse_string(sim.contraption_save())==JSON.parse_string(saved.contraptions),"fresh process preserves exact machine and source ledger")
	check(sim.contraption_ids().size()==28 and get_tree().get_nodes_in_group("contraptions").size()==28,"all seven kinds and four rotations restore once")
	await get_tree().physics_frame
	for key in sim.contraption_ids():
		var site:=ContraptionSite.find_site(get_tree(),key)
		check(site!=null and site._visual.is_visible_in_tree(),"fresh fixture has visible scene")
		if site==null: continue
		check(site.position.is_equal_approx(sim.contraption_state(key).position),"fresh fixture uses the exact native world pose")
