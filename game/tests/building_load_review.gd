extends "res://tests/first_hour_journey.gd"
## Actual V6 seed 77 resources -> pickup -> chest -> craft -> paid 6m home.
## Travel/pickup time is accelerated; no material, station or unlock grants.
const CHECKPOINT := "res://building-load-checkpoint.json"
const MANIFEST := "res://building-load-manifest.json"
var staging: PlacedBlock
var measured := {"work_presses":{},"released":{},"sources":{},"deliveries":{},"withdrawals":{},"spent":{}}
var build_family: StringName = &"wood"

func _run() -> void:
	if "--load-restore-only" in OS.get_cmdline_user_args():
		await restore_review()
		return finish_review()
	check(_sim().inventory().is_empty(),"fresh pack has no inspection stock")
	if not await gather("wood",6): return finish_review()
	var p := player.spawn_position+Vector3(-4,0,0)
	var cell := Vector3i(floori(p.x),ceili(terrain.surface_position(floori(p.x),floori(p.z)).y),floori(p.z))
	if not place(&"chest",cell): return finish_review()
	for child in get_children():
		if child is PlacedBlock and child.is_chest(): staging=child
	if not check(staging!=null,"paid staging chest exists"): return finish_review()
	if not await gather_stored("wood",219): return finish_review()
	check(_sim().carry_cap("wood")>=225,"one timber load can fund the home, workshop and staging chest")
	if not take("wood",31): return finish_review()
	if not craft("workbench_kit"): return finish_review()
	var bench := place_kit("workbench_kit",Vector2i(8,0))
	if bench==null or not craft("timber_frame",2,bench): return finish_review()
	if not await gather("fieldstone",6) or not craft("mason_yard_kit",1,bench): return finish_review()
	var yard := place_kit("mason_yard_kit",Vector2i(8,3))
	if yard==null or not craft("timber_wedges_bulk",1,bench): return finish_review()
	if not await gather("split_stone",16) or not craft("dress_stone",8,yard): return finish_review()
	if not await gather("iron_ore",4) or not craft("forge_kit",1,bench): return finish_review()
	if place_kit("forge_kit",Vector2i(8,6))==null: return finish_review()
	if not check(find_large_plot(),"clear generated plot fits six-metre home"): return finish_review()
	await build_large_home()
	# A paid 6 x 6 shellstone floor for the next workshop project: 144 raw ->72
	# finished. Moving sources into/out of the same real chest exposes both caps.
	if not await gather_stored("raw_shellstone",144): return finish_review()
	check(_sim().carry_cap("raw_shellstone")>=144,"one quarry haul supplies a six-metre workshop floor")
	var batches_left := 18
	while batches_left>0:
		var batches := mini(batches_left,_sim().carry_cap("raw_shellstone")/8)
		if not take("raw_shellstone",batches*8) or not craft("refine_shellstone",batches,yard): return finish_review()
		batches_left-=batches
	check(_sim().material_count("shellstone")==72,"144 quarry stock refines to exactly72 building units")
	build_family=&"shellstone"
	for x in 6:
		for z in 6:
			if not place(&"cube",home_cell+Vector3i(x,5,z)): return finish_review()
	build_family=&"wood"
	check(_sim().material_count("shellstone")==0,"paid workshop floor consumes exactly72 shellstone")
	player.global_position=Vector3(home_cell)+Vector3(2.5,1.97,2.5)
	terrain.resource_stream.capture()
	var manager := SaveManager.new()
	var saved := manager.capture(player)
	check(manager.write_data(CHECKPOINT,saved),"completed project saves in isolated copy: "+manager.last_error)
	var expected := {"inventory":_sim().inventory(),"store":_sim().store_contents(staging.store_key()),
		"store_key":staging.store_key(),"resources":saved.resource_nodes,"blocks":saved.blocks,
		"stations":saved.stations,"home":[home_cell.x,home_cell.y,home_cell.z],"measurements":measured}
	var file := FileAccess.open(MANIFEST,FileAccess.WRITE)
	file.store_string(JSON.stringify(expected,"\t",true,true))
	file.close()
	await restore_review()
	finish_review()

func gather(family: String, wanted: int) -> bool:
	for attempt in 400:
		if _sim().material_count(family)>=wanted: return true
		if not await work_once(family): return false
	return check(false,"bounded gathering reaches "+family)

func work_once(family: String) -> bool:
	var source := nearest_source(family)
	if not check(source!=null,"finite generated source for "+family): return false
	player.global_position=source.global_position+Vector3(0,1.1,1.4)
	var result := source.work(_sim())
	if not check(not result.has("refusal"),"contextual work accepts "+family+": "+str(result)): return false
	measured.work_presses[family]=int(measured.work_presses.get(family,0))+1
	if not measured.sources.has(family): measured.sources[family]={}
	measured.sources[family][source.resource_id]=true
	measured.released[family]=int(measured.released.get(family,0))+int(result.get("granted",0))
	var before := _sim().material_count(family)
	player._apply_work(source,result)
	check(_sim().material_count(family)==before,"work releases physical drops without granting carried stock")
	await collect()
	return true

func gather_stored(family: String, wanted: int) -> bool:
	for attempt in 1000:
		var carried := _sim().material_count(family)
		var stored := int(_sim().store_contents(staging.store_key()).get(family,0))
		var ready := carried+stored>=wanted
		if carried>0 and (ready or _sim().carry_room(family)==0):
			player.open_chest(staging)
			check(player.chest_panel.store(StringName(family),carried)==carried,"paid chest receives exact hauled "+family)
			player.chest_panel.close_panel()
			measured.deliveries[family]=int(measured.deliveries.get(family,0))+1
			if ready: return true
			# Collect the partial remainder before releasing more finite stock.
			await collect()
			continue
		if not await work_once(family): return false
	return check(false,"bounded store gathering completes "+family)

func take(family: String, wanted: int) -> bool:
	var missing := wanted-_sim().material_count(family)
	if missing<=0: return true
	player.open_chest(staging)
	var moved := player.chest_panel.take(StringName(family),missing)
	player.chest_panel.close_panel()
	measured.withdrawals[family]=int(measured.withdrawals.get(family,0))+1
	return check(moved==missing,"chest withdrawal provides exact carried work supply: "+family)

func place(shape: StringName, cell: Vector3i, kind := "volume", axis := 0, kit := false) -> bool:
	var cost := 1 if kit else _sim().shape_material_cost(shape)
	if not kit and build_family==&"wood" and staging!=null:
		if _sim().material_count("wood")<cost and not take("wood",mini(_sim().carry_cap("wood"),int(_sim().store_contents(staging.store_key()).get("wood",0)))): return false
	var build := player.placement
	build.set_build_mode_enabled(true)
	player.build_palette.open_panel()
	player.build_palette.select_entry(shape,"kit" if kit else "shape")
	player.build_palette.select_material(build_family)
	player.build_palette.close_panel()
	build.preview_element={"kind":kind,"axis":axis,"cell":cell*2}
	build.preview_visible=true
	player.global_position=Vector3(cell)+Vector3(-2,2,-2)
	var source := String(shape) if kit else String(build_family)
	var before := _sim().material_count(source)
	var made := build.try_place_block()
	check(made,"paid placement "+String(shape)+": "+build.preview_reason)
	check(_sim().material_count(source)==before-(cost if made else 0),"exact placement payment: "+source)
	if made: measured.spent[source]=int(measured.spent.get(source,0))+cost
	build.set_build_mode_enabled(false)
	return made

func find_large_plot() -> bool:
	var build := player.placement
	build.select_shape(&"cube")
	for dx in [-20,-12,12,20,28]:
		for dz in [-20,-12,12,20,28]:
			var p := player.spawn_position+Vector3(dx,0,dz)
			terrain.ensure_area(p)
			var c := Vector3i(floori(p.x),0,floori(p.z))
			for x in 7:
				for z in 7: c.y=maxi(c.y,ceili(terrain.surface_position(c.x+x,c.z+z).y))
			var clear := true
			for x in range(-1,7):
				for z in range(-2,7):
					if build.element_refusal({"kind":"volume","axis":0,"cell":(c+Vector3i(x,0,z))*2})!="": clear=false
			if clear:
				home_cell=c
				return true
	return false

func build_large_home() -> void:
	var before := int(measured.spent.wood)
	for x in 6:
		for z in 6:
			if not place(&"cube",home_cell+Vector3i(x,0,z)): return
	for y in range(1,4):
		for i in 6:
			for wall in [[0,Vector3i(0,y,i)],[0,Vector3i(6,y,i)],[2,Vector3i(i,y,6)],[2,Vector3i(i,y,0)]]:
				if wall[0]==2 and wall[1].z==0 and wall[1].x==2 and y<3: continue
				if not place(&"wall_panel",home_cell+wall[1],"face",wall[0]): return
	if not place(&"door",home_cell+Vector3i(2,1,0),"face",2): return
	for x in 6:
		for z in 6:
			if not place(&"floor_slab",home_cell+Vector3i(x,4,z),"face",1): return
	if not place(&"stairs",home_cell+Vector3i(2,0,-1)): return
	if not place(&"chest",home_cell+Vector3i(4,1,4)): return
	check(int(measured.spent.wood)-before==188,"complete six-metre home costs exactly188 wood")
	check(player.placement.enclosure_at(Vector3(home_cell)+Vector3(2.5,1.97,2.5)).enclosed,"actual paid home is sheltered")
	check(not _sim().world_effect_active("stonecut_blocks"),"home needs no trial roof unlock")

func restore_review() -> void:
	var from_baseline := "--load-baseline" in OS.get_cmdline_user_args()
	var checkpoint := "res://../../baseline/game/building-load-checkpoint.json" if from_baseline else CHECKPOINT
	var manifest := "res://../../baseline/game/building-load-manifest.json" if from_baseline else MANIFEST
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(manifest))
	var manager := SaveManager.new()
	for repeat in 2:
		if not check(manager.read(checkpoint,player),"completed project restores: "+manager.last_error): return
		await get_tree().process_frame
		var saved := manager.capture(player)
		check(JSON.parse_string(JSON.stringify(_sim().inventory()))==expected.inventory,"restart preserves exact carried resources")
		check(_sim().store_contents(expected.store_key)==expected.store,"restart preserves exact stored resources")
		check(JSON.parse_string(JSON.stringify(saved.resource_nodes))==expected.resources,"finite source depletion and partial work survive")
		check(JSON.parse_string(JSON.stringify(saved.blocks))==expected.blocks,"paid home and workshop floor survive without repayment")
		var stations: Array=expected.stations.duplicate(true)
		for entry in stations: entry.name=String(entry.name).validate_node_name()
		check(saved.stations==stations,"all three paid stations retain ownership and poses")
		check(world_profile=="frontier_v6" and world_seed==77,"saved geography retains identity")

func finish_review() -> void:
	print("BUILDING_LOAD_MEASUREMENTS ",JSON.stringify(measured))
	print("BUILDING_LOAD_REVIEW %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
