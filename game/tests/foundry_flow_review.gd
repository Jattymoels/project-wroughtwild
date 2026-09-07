extends Node3D
## Common baseline/current fixture. Native legal routes and actual hover input;
## supplied milestones/stock review presentation, not acquisition or balance.
var player: WroughtwildPlayer
var sim: WroughtwildSim
var panel: FoundryPanel
var checks := 0
var failures := 0
var evidence: Array[Dictionary] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FOUNDRY_FLOW_REVIEW: ", label)

func settle() -> void:
	for frame in 12: await get_tree().process_frame

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	sim = player.inventory.get_sim()
	panel = player.foundry_panel
	for event in ["recipe:workbench_kit", "recipe:smelt_iron", "first_kill:ember_whelp", "first_kill:ash_hound", "first_kill:stone_husk", "first_kill:cinder_archer", "first_kill:gloom_crawler", "work:strike_split"]:
		sim.foundry_event(event)
	sim.add_materials({"iron_ingot":100,"vanguard":3,"frost_catalyst":3,"preserving_catalyst":3})
	sim.learn_skill("prototype_ember_bolt")
	var initial := sim.export_json()
	var directory := ProjectSettings.globalize_path("res://../captures/flow")
	DirAccess.make_dir_recursive_absolute(directory)
	for layout in ["shared", "branched"]:
		check(sim.import_json(initial), "restore supplied inspection stock")
		if layout == "branched": sim.record_world_effect("stonecut_blocks")
		for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row,piece.col), "clear fixture plate")
		check(sim.foundry_place_skill(1,1,"prototype_heavy_strike") and sim.foundry_place_skill(2,2,"prototype_ember_bolt"), "lay two actual skill sockets")
		check(sim.foundry_place(1,2,"ember"), "lay shared support")
		if layout == "shared": check(sim.foundry_place_kind(1,3,"vanguard"), "short native Kind route")
		else:
			check(sim.foundry_place_kind(1,3,"frost_catalyst") and sim.foundry_place_kind(0,3,"preserving_catalyst") and sim.foundry_place(0,2,"edge"), "long native Kind route with an intermediate branch")
		var before := sim.export_json()
		var effects := sim.foundry_effects()
		for resolution in [Vector2i(1280,720),Vector2i(2307,1345),Vector2i(1920,1080),Vector2i(3453,1789)]:
			get_window().size = resolution
			panel.open_panel()
			player._release_mouse()
			await settle()
			var target: Button = panel._cell_buttons[Vector2i(1,2)]
			var event := InputEventMouseMotion.new()
			event.position = target.get_global_rect().get_center()
			get_viewport().push_input(event)
			await settle()
			check(panel._preview.text.contains("CURRENT FLOW"), "actual hover selects current flow")
			check(panel._flow_overlay.paths.size() >= 2, "both receiving skill routes remain available")
			var bounds := get_viewport().get_visible_rect()
			check(bounds.encloses(panel._root.get_global_rect()), "entire Foundry fits " + str(resolution))
			check(panel._preview.get_theme_font_size("normal_font_size") >= 16, "inspector has readable body type")
			check(panel._preview.size.y >= 140, "inspector leaves room to read a consequence and scroll its detail")
			check(not panel._preview.get_global_rect().intersects(panel._grid.get_global_rect()) and not panel._preview.get_global_rect().intersects(panel._list_scroll.get_global_rect()), "inspector does not cover plate or workings")
			evidence.append({"layout":layout,"resolution":str(resolution),"panel":str(panel._root.get_global_rect()),"inspector":str(panel._preview.get_global_rect()),"body_px":panel._preview.get_theme_font_size("normal_font_size"),"content_height":panel._preview.get_content_height(),"paths":panel._flow_overlay.paths.size(),"text":panel._preview.text})
			if DisplayServer.get_name() != "headless":
				await RenderingServer.frame_post_draw
				check(get_viewport().get_texture().get_image().save_png(directory.path_join("%s-%d.png" % [layout,resolution.y])) == OK, "save matched inspector capture")
			panel.close_panel()
			await settle()
		check(sim.export_json() == before and sim.foundry_effects() == effects, "inspection leaves exact native ownership and effects unchanged")
	var file := FileAccess.open(directory.path_join("flow-review.json"),FileAccess.WRITE)
	check(file != null, "write measured layout evidence")
	if file != null: file.store_string(JSON.stringify({"checks":checks,"failures":failures,"cases":evidence},"  ")); file.close()
	print("FOUNDRY_FLOW_REVIEW %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
