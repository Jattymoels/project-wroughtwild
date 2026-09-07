extends "res://tests/wide_frontier_review.gd"
## Identical baseline/current driver. No disk IO inside measured click windows.
## Whole V6 scenery, real native placement, collider creation and queued refresh.
class TimedPlacement extends GridPlacement:
	var stages: Dictionary={}
	func refresh_trims() -> void:
		var began:=Time.get_ticks_usec()
		super.refresh_trims()
		stages.trims_ms=(Time.get_ticks_usec()-began)/1000.0
	func refresh_ecology() -> void:
		var began:=Time.get_ticks_usec()
		super.refresh_ecology()
		stages.ecology_ms=(Time.get_ticks_usec()-began)/1000.0
	func element_refusal(element: Dictionary) -> String:
		var began:=Time.get_ticks_usec()
		var result:=super.element_refusal(element)
		stages.validation_ms=(Time.get_ticks_usec()-began)/1000.0
		return result

func _ready() -> void:
	world_profile="frontier_v6"
	world_seed=77
	output=ProjectSettings.globalize_path("res://../captures/placement")
	DirAccess.make_dir_recursive_absolute(output)
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.hud.hide()
	player.hud.set_process(false)
	player.spring_arm.set_physics_process(false)
	mob_packs.set_physics_process(false)
	mob_packs.set_process(false)
	mood.set_process(false)
	set_physics_process(false)
	var old:=player.placement
	player.remove_child(old)
	old.free()
	var build:=TimedPlacement.new()
	build.camera=player.camera
	build.inventory=player.inventory
	player.add_child(build)
	player.placement=build
	build.set_physics_process(false)
	build.set_build_mode_enabled(true)
	_setup_camera()
	_review_light(false)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=120
	_sim().add_material("wood",5000)
	var rows: Array=[]
	# Stable flat home, sloped regional approach, and an excavated patch. Homes
	# are raised to a legal plane; nearby hills/scenery remain the normal world.
	var home: Dictionary=terrain.map.home_sites[0]
	var path: PackedVector3Array=terrain.map.regions[2].approach
	var places: Array[Vector3]=[Vector3(home.x,home.y,home.z),path[path.size()/2],path[path.size()/2]+Vector3(12,0,0)]
	for index in places.size():
		var at:=places[index]
		terrain.ensure_area(at,32)
		await _settle(at,64)
		var floor_y:=0
		for x in 12:
			for z in 12:
				var p:=terrain.surface_position(int(at.x)+x,int(at.z)+z)
				floor_y=maxi(floor_y,ceili(p.y))
		if index==2:
			var dug:=0
			for x in range(3,6):
				for z in range(3,6):
					var dig:=Vector3i(int(at.x)+x,terrain.height_at(int(at.x)+x,int(at.z)+z)-1,int(at.z)+z)
					if not terrain.break_block(dig.x,dig.y,dig.z).is_empty(): dug+=1
			check(dug>0,"excavated case has actual accepted terrain edits")
		var origin:=Vector3i(int(at.x)*2,(floor_y+1)*2,int(at.z)*2)
		player.position=Vector3(origin)*.5+Vector3(-2,2,-2)
		review_camera.position=player.position+Vector3(0,4,0)
		review_camera.look_at(Vector3(origin)*.5+Vector3(5,0,5))
		# Complete 6x6 and 10x10 shells: floors, perimeter walls, ceiling.
		for width in [6,10]:
			var base:=origin+Vector3i(0,0,0 if width==6 else 28)
			for x in width:
				for z in width:
					build.place_piece({"kind":"face","axis":1,"cell":base+Vector3i(x*2,0,z*2)},&"floor_slab",&"wood")
			for side in 4:
				for offset in width:
					for y in 3:
						if side==2 and offset==width/2 and y<2: continue
						var c:=base+Vector3i(0,y*2,0)
						var axis:=0 if side<2 else 2
						if side<2: c+=Vector3i(side*width*2,0,offset*2)
						else: c+=Vector3i(offset*2,0,(side-2)*width*2)
						build.place_piece({"kind":"face","axis":axis,"cell":c},&"wall_panel",&"wood")
			build.place_piece({"kind":"face","axis":2,"cell":base+Vector3i(width,0,0)},&"door",&"wood")
			await get_tree().process_frame
			for warm in 30: await get_tree().process_frame
			var group:=[]
			for n in 24:
				var c:=base+Vector3i((n%width)*2,6,(n/width)*2)
				build.select_shape(&"floor_slab")
				build.preview_element={"kind":"face","axis":1,"cell":c}
				build.preview_visible=true
				build.stages.clear()
				var began:=Time.get_ticks_usec()
				var ok:=build.try_place_block()
				var click_ms:=(Time.get_ticks_usec()-began)/1000.0
				var frames:=[]
				for frame in 4:
					await get_tree().process_frame
					var now:=Time.get_ticks_usec()
					frames.append((now-began)/1000.0)
					began=now
				check(ok,"paid ceiling placement succeeds")
				var row:=build.stages.duplicate(true)
				row.click_ms=click_ms
				row.frames_ms=frames
				row.process_ms=Performance.get_monitor(Performance.TIME_PROCESS)*1000
				row.physics_ms=Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000
				group.append(row)
			rows.append({"ground":["flat","hill","excavated"][index],"width":width,"pieces":_sim().structure_piece_count(),"placements":group})
			# Finish the same home after sampling its final construction stage.
			for n in range(24,width*width):
				build.preview_element={"kind":"face","axis":1,"cell":base+Vector3i((n%width)*2,6,(n/width)*2)}
				check(build.try_place_block(),"remaining paid roof completes home")
			check(build.enclosure_at(Vector3(base)*.5+Vector3(width*.5,1.5,width*.5)).enclosed,"completed home has native enclosure")
			await get_tree().process_frame
		# Exact restored/scenery output is exercised separately from timing.
	var file:=FileAccess.open(output.path_join("placement-timing.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"groups":rows,"gpu":RenderingServer.get_video_adapter_name(),"seed":world_seed,"checks":checks,"failures":failures},"\t"))
	file.close()
	print("PLACEMENT_PERFORMANCE %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
