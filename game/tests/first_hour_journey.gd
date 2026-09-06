extends Sandpit
## Actual V6 finite resources, no inventory/station/unlock grants. Travel and
## pickup time are accelerated through existing dispatchers; this proves the
## economy and UI handoffs, not first-hour pace or new-player comprehension.
var checks := 0
var failures := 0
var journal: Array[String] = []
var save_path := ""
var home_cell := Vector3i.ZERO

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: first hour: ",label)
	return ok

func _ready() -> void:
	world_seed = 77
	super._ready()
	var chosen := "warden"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--journey-class="): chosen = argument.get_slice("=",1)
	player.class_panel.choose(chosen)
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	mob_packs.set_physics_process(false)
	terrain.set_process(false)
	save_path = ProjectSettings.globalize_path("res://first_hour_journey_save.json")
	_run.call_deferred()

func _physics_process(_delta: float) -> void: pass

func nearest_source(family: String) -> ResourceNode:
	var best := ""
	var distance := INF
	for id in terrain.resource_stream.records:
		var record: Dictionary = terrain.resource_stream.records[id]
		if record.family != family or int(record.remaining_units) <= 0 or int(record.get("era",1)) > 1: continue
		var p: Array = record.position
		var candidate := Vector3(p[0],p[1],p[2]).distance_squared_to(player.spawn_position)
		if candidate < distance:
			best = id
			distance = candidate
	return terrain.resource_stream.materialise(best) if best != "" else null

func collect() -> void:
	# Move the fixture player into each released chip's real absorption range.
	# Its normal tick performs haul/capacity checks and is the only inventory grant.
	for pickup in get_tree().get_nodes_in_group("pickups"):
		if pickup.is_queued_for_deletion(): continue
		player.global_position = pickup.global_position-Vector3(0,.6,0)
		pickup._physics_process(1.0/60.0)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	await get_tree().process_frame
	terrain.resource_stream.capture()

func gather(family: String, wanted: int) -> bool:
	var sim := _sim()
	for attempt in 120:
		if sim.material_count(family) >= wanted: return true
		var source := nearest_source(family)
		if not check(source != null,"generated reachable source exists for "+family): return false
		player.global_position = source.global_position+Vector3(0,1.1,1.4)
		var result := source.work(sim)
		if not check(not result.has("refusal"),"ordinary contextual work accepts "+family+": "+str(result)): return false
		var before := sim.material_count(family)
		player._apply_work(source,result)
		if int(result.get("granted",0)) > 0:
			check(sim.material_count(family)==before,"released "+family+" waits for pickup")
			await collect()
	return check(false,"bounded gathering completes "+family)

func craft(id: String, batches := 1, station: StationSite = null) -> bool:
	var work := player.work_panel
	if station == null: work.open_hand_crafting()
	else: station.interact(player)
	var catalogue := work.catalogue
	catalogue.select_recipe(id)
	catalogue.quantity = batches
	catalogue._render_detail()
	if not check(not catalogue._action.disabled,"current station can make "+id+": "+catalogue._next.text): return false
	var before: Dictionary = _sim().inventory().duplicate(true)
	catalogue._action.pressed.emit()
	var produced := true
	for output in _sim().recipe(id).get("outputs",{}):
		produced = produced and _sim().material_count(output)==int(before.get(output,0))+int(_sim().recipe(id).outputs[output])*batches
	check(produced,"paid craft produces exact output: "+id)
	journal.append(work.message())
	work.close_panel()
	return produced

func place(shape: StringName, cell: Vector3i, kind := "volume", axis := 0, kit := false) -> bool:
	var build := player.placement
	build.set_build_mode_enabled(true)
	player.build_palette.open_panel()
	player.build_palette.select_entry(shape,"kit" if kit else "shape")
	player.build_palette.select_material(&"wood")
	player.build_palette.close_panel()
	build.preview_element = {"kind":kind,"axis":axis,"cell":cell*2}
	build.preview_visible = true
	var made := build.try_place_block()
	check(made,"paid placement "+String(shape)+": "+build.preview_reason)
	build.set_build_mode_enabled(false)
	return made

func place_kit(id: String, offset: Vector2i) -> StationSite:
	var p := player.spawn_position+Vector3(offset.x,0,offset.y)
	var c := Vector3i(floori(p.x),ceili(terrain.surface_position(floori(p.x),floori(p.z)).y),floori(p.z))
	if not place(StringName(id),c,"volume",0,true): return null
	for station in get_tree().get_nodes_in_group("crafting_stations"):
		if station.player_built and station.station_id==StringName(_sim().kit_station(id)):
			check(station.is_built(_sim()),"placed "+id+" is usable")
			return station
	check(false,"placed station instance exists: "+id)
	return null

func reload_boundary(label: String) -> bool:
	var manager := SaveManager.new()
	var before := _sim().inventory().duplicate(true)
	var position_before := player.global_position
	if not check(manager.write(save_path,player),label+" writes isolated save: "+manager.last_error): return false
	player.global_position += Vector3(3,0,2)
	if not check(manager.read(save_path,player),label+" restores: "+manager.last_error): return false
	check(_sim().inventory()==before and player.global_position.is_equal_approx(position_before),label+" preserves inventory and pose")
	check(world_profile=="frontier_v6" and world_seed==77,label+" preserves generation identity")
	await get_tree().process_frame
	return true

func _run() -> void:
	if "--pickup-probe" in OS.get_cmdline_user_args() or "--pickup-restore" in OS.get_cmdline_user_args():
		await pickup_probe()
		return finish()
	check(_sim().inventory().is_empty(),"fresh class has no supplied building materials")
	var first := nearest_source("wood")
	var first_id := first.resource_id
	player._apply_work(first,first.work(_sim()))
	check(first.drive_progress > 0 and _sim().material_count("wood")==0,"first work remains partial")
	if not await reload_boundary("partial harvest"): return finish()
	first = terrain.resource_stream.materialise(first_id)
	check(first.drive_progress==1,"partial work resumes at the same press")
	if not await gather("wood",50): return finish()
	if not craft("workbench_kit"): return finish()
	check(not _sim().has_station("workbench"),"crafting a kit does not operate a station")
	if not await reload_boundary("unplaced bench kit"): return finish()
	var bench := place_kit("workbench_kit",Vector2i(8,0))
	if bench==null: return finish()
	if not craft("timber_frame",2,bench): return finish()
	if not await gather("fieldstone",6): return finish()
	if not craft("mason_yard_kit",1,bench): return finish()
	var yard := place_kit("mason_yard_kit",Vector2i(8,3))
	if yard==null: return finish()
	if not craft("timber_wedge",4): return finish()
	if not await gather("split_stone",16): return finish()
	if not craft("dress_stone",8,yard): return finish()
	if not await gather("iron_ore",8): return finish()
	if not craft("forge_kit",1,bench): return finish()
	var forge := place_kit("forge_kit",Vector2i(8,6))
	if forge==null: return finish()
	if not craft("smelt_iron",1,forge): return finish()
	check(_sim().material_count("iron_ingot") > 0,"normal ore, flux and selected fuel produce first ingot")
	if not await gather("wood",55): return finish()
	await build_home()
	finish()

func build_home() -> void:
	if not check(find_home_plot(),"a clear first-home plot is available near the start"): return
	player.global_position = Vector3(home_cell)+Vector3(-2,1,1)
	for x in 2:
		for z in 2:
			if not place(&"floor_slab",home_cell+Vector3i(x,0,z),"face",1): return
	for y in 2:
		for i in 2:
			for wall in [[0,Vector3i(0,y,i)],[0,Vector3i(2,y,i)],[2,Vector3i(i,y,2)]]:
				if not place(&"wall_panel",home_cell+wall[1],"face",wall[0]): return
			if i==1 and not place(&"wall_panel",home_cell+Vector3i(i,y,0),"face",2): return
	if not place(&"door",home_cell,"face",2): return
	var inside := Vector3(home_cell)+Vector3(.5,1.1,.5)
	check(not player.placement.enclosure_at(inside).enclosed,"walls without roof give actionable shelter failure")
	for x in 2:
		for z in 2:
			if not place(&"floor_slab",home_cell+Vector3i(x,2,z),"face",1): return
	check(player.placement.enclosure_at(inside).enclosed,"paid slab roof and door seal first home before roof unlock")
	check(not _sim().world_effect_active("stonecut_blocks"),"first home did not grant pitched-roof unlock")
	if not place(&"chest",home_cell+Vector3i(1,0,1)): return
	var chest: PlacedBlock
	for block in get_children():
		if block is PlacedBlock and block.is_chest(): chest=block
	if not check(chest!=null,"paid chest exists"): return
	player.open_chest(chest)
	var carried := _sim().material_count("wood")
	check(player.chest_panel.store(&"wood",5)==5 and _sim().material_count("wood")==carried-5,"carried stock is distinct from stored stock")
	check(player.chest_panel.take(&"wood",2)==2,"stored supplies can be returned to crafting inventory")
	var key := chest.store_key()
	player.chest_panel.close_panel()
	player.global_position=inside
	player.combat._tick_shelter(1)
	check(player.combat.sheltered and player.combat.has_home,"ordinary shelter probe establishes home")
	await reload_boundary("home and stored resources")
	check(_sim().store_contents(key).get("wood",0)==3,"chest contents restore without redeposit")
	check(player.placement.enclosure_at(inside).enclosed,"restored home still seals")
	journal.append("Gathered → bench → wedges/yard → dressed stone → forge → first ingot → slab-roof home and chest.")
	if DisplayServer.get_name() != "headless":
		# Overview of the actually paid house; the player's saved pose above
		# remains the interior pose, separate from this review camera.
		var review_camera := Camera3D.new()
		add_child(review_camera)
		review_camera.global_position=Vector3(home_cell)+Vector3(-5,4,-6)
		review_camera.look_at(Vector3(home_cell)+Vector3(1,1,1))
		review_camera.make_current()
		for i in 12: await get_tree().process_frame
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(ProjectSettings.globalize_path("res://first-hour-home.png"))

func find_home_plot() -> bool:
	# Query the same refusal path as the preview; choose open ground instead
	# of deleting a resource or bypassing a valid placement refusal.
	var build := player.placement
	build.select_shape(&"cube")
	for dx in [-12,-8,-4,4,12]:
		for dz in [-12,-8,-4,4,8,12]:
			var p := player.spawn_position+Vector3(dx,0,dz)
			var c := Vector3i(floori(p.x),0,floori(p.z))
			for x in 3:
				for z in 3: c.y=maxi(c.y,ceili(terrain.surface_position(c.x+x,c.z+z).y))
			var clear := true
			for x in range(-1,3):
				for z in range(-1,3):
					if build.element_refusal({"kind":"volume","axis":0,"cell":(c+Vector3i(x,0,z))*2})!="": clear=false
			if clear:
				home_cell=c
				return true
	return false

func finish() -> void:
	var file := FileAccess.open(ProjectSettings.globalize_path("res://first-hour-journey.txt"),FileAccess.WRITE)
	if file: file.store_string("\n".join(journal))
	print("CODEX_FIRST_HOUR_JOURNEY %d checks, %d failures; class %s" % [checks,failures,_sim().foundry().get("class","")])
	get_tree().quit(0 if failures==0 else 1)

func pickup_probe() -> void:
	# INT-07 converts the reproduced diagnostic into a normal-world regression.
	# A separate process reads the exact checkpoint and its test-only ground truth.
	var manager := SaveManager.new()
	var path := ProjectSettings.globalize_path("res://first-hour-pickup-probe.json")
	if "--pickup-restore" in OS.get_cmdline_user_args():
		var manifest: Variant = JSON.parse_string(FileAccess.get_file_as_string(path+".expected"))
		if not check(manifest is Dictionary and int(manifest.get("amount",0))>0,"restart has the previous process's harvest ground truth"): return
		if not check(manager.read(path,player),"probe can restore after-release payload"): return
		var loose := 0
		for drop in get_tree().get_nodes_in_group("pickups"):
			if drop.kind=="material" and drop.family=="wood": loose+=drop.amount
		check(_sim().material_count("wood")==0 and loose==int(manifest.amount),"restart keeps the entire harvested yield loose, without automatic collection")
		check(not terrain.resource_stream.has_resource(String(manifest.resource_id)),"restart keeps the harvested source depleted")
		await collect()
		check(_sim().material_count("wood")==int(manifest.amount),"restored generated-world yield can be collected exactly once")
		print("CODEX_PICKUP_PROBE_RESTART loose_wood=%d collected_wood=%d" % [loose,_sim().material_count("wood")])
		return
	var source := nearest_source("wood")
	var id := source.resource_id
	var payout := source.units_per_harvest
	var before := manager.capture(player)
	for i in source.drive_presses: player._apply_work(source,source.work(_sim()))
	var dropped := get_tree().get_nodes_in_group("pickups").size()
	check(dropped > 0 and _sim().material_count("wood")==0,"probe freed real yield without collection")
	check(manager.write(path,player),"probe writes actual after-release save")
	var expected := FileAccess.open(path+".expected",FileAccess.WRITE)
	if not check(expected!=null,"probe records independent restart ground truth"): return
	expected.store_string(JSON.stringify({"amount":payout,"resource_id":id}))
	expected.close()
	check(manager.apply(player,before),"probe loads before-harvest state")
	check(get_tree().get_nodes_in_group("pickups").is_empty(),"rewind removes drops released after the saved resource state")
	source = terrain.resource_stream.materialise(id)
	for i in source.drive_presses: player._apply_work(source,source.work(_sim()))
	await collect()
	check(_sim().material_count("wood")==payout,"rewind and reharvest yield once, without stale-drop duplication")
	print("CODEX_PICKUP_PROBE_RELOAD single_yield=%d held_after_reload_and_reharvest=%d" % [payout,_sim().material_count("wood")])
