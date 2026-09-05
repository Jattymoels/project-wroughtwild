extends Node3D
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	var ground := StaticBody3D.new()
	var ground_collision := CollisionShape3D.new()
	var ground_shape := BoxShape3D.new()
	ground_shape.size = Vector3(40,1,40)
	ground_collision.shape = ground_shape
	ground.add_child(ground_collision)
	ground.position.y = -0.5
	add_child(ground)
	var player: WroughtwildPlayer = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position = Vector3(-5,1.1,0)
	player.set_physics_process(false)
	var sim := player.inventory.get_sim()
	var build := player.placement
	build.set_physics_process(false)
	var palette := player.build_palette
	sim.add_material("wood",30)
	sim.add_material("stone",8)
	sim.add_material("workbench_kit",1)
	build.set_build_mode_enabled(true)
	var key := InputEventAction.new()
	key.action = "cycle_shape"
	key.pressed = true
	player._unhandled_input(key)
	check(palette.is_open() and build.palette_open, "Tab opens visual catalogue in build mode")
	check(palette.cards.size() == build.placeables().size(), "catalogue includes normal shapes and held station kits")
	check(not build.preview_visible and not build.try_place_block(), "palette cannot place through its controls")
	var count := sim.material_count("wood")
	palette.cards["codex_corner"].pressed.emit()
	check(build.selected_shape == &"codex_corner" and sim.material_count("wood") == count, "clicking a shape selects without payment")
	check(not palette.picture.mesh.get_faces().is_empty(), "selected thumbnail uses actual piece triangles")
	palette.turn(-1)
	check(build.preview_rotation_step == 3 and palette.picture.turn == 3, "left turn wraps and updates the displayed orientation")
	palette.turn(1)
	check(build.preview_rotation_step == 0, "right turn reverses left turn")
	palette.select_entry(&"codex_roof_hip")
	check(palette.detail.text.contains("Forge Tyrant") and build.locked(), "locked roof is inspectable with its unlock requirement")
	palette.select_entry(&"door")
	palette.turn(1)
	check(palette.picture.turn == 2 and build.orientation_label().contains("Hinge 2/2"), "door thumbnail flips 180 degrees to match the actual hinge pose")
	palette.turn(-1)
	palette.select_material(&"stone")
	check(palette.detail.text.contains("joinery") and palette.detail.text.contains("Timber"), "incompatible family gives a requirement and usable alternatives")
	palette.select_material(&"wood")
	check(build.family_allowed(), "material selector resolves compatibility through existing sim rule")
	palette.select_entry(&"cube")
	palette.fine.toggled.emit(true)
	check(build.placing_shape() == &"half_cube" and palette.title.text.contains("fine"), "half-size toggle selects and names the existing fine twin")
	palette.select_entry(&"codex_corner")
	check(build.placing_shape() == &"codex_corner" and not palette.title.text.contains("fine"), "shape without a fine twin stays full size")
	palette.select_entry(&"workbench_kit","kit")
	check(build.selected_kit == &"workbench_kit" and palette.detail.text.contains("1 kit"), "station kit shows its own cost and actual station mesh")
	palette.turn(1)
	palette.close_panel()
	player.spring_arm.rotation.x = -0.5
	for i in 3:
		await get_tree().physics_frame
	build._update_preview()
	check(build.preview_visible and is_equal_approx(build._preview_mesh.rotation.y,PI/2.0), "station ghost and front marker follow the chosen quarter turn")
	check(build.try_place_block() and sim.material_count("workbench_kit") == 0, "rotated kit places and consumes only its kit")
	var station_matches := false
	for child in get_children():
		if child is StationSite:
			station_matches = is_equal_approx(child.rotation.y,PI/2.0)
	check(station_matches, "station orientation agrees with its world preview")
	build.preview_rotation_step = 0
	palette.open_panel()
	palette.select_entry(&"cube")
	palette.fine.toggled.emit(false)
	palette.group = "Corners & roofs"
	palette.refresh()
	check(palette.cards.has("codex_corner_floor") and palette.cards.has("codex_roof_valley") and not palette.cards.has("cube"), "roof group keeps diagonal floor transitions together with roofs")
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution
		for i in 3:
			await get_tree().process_frame
		var rect := palette.root.get_global_rect()
		check(rect.position.x >= 0 and rect.position.y >= 0 and rect.end.x <= resolution.x and rect.end.y <= resolution.y, "picker fits viewport at %s (rect %s)" % [resolution,rect])
	palette._input(key)
	check(not palette.is_open() and not build.palette_open and build.build_mode_enabled, "Tab closes the picker and resumes building")
	var address := {"kind":"volume","axis":0,"cell":Vector3i(0,0,0)}
	build.preview_element = address
	build.preview_visible = true
	build.preview_valid = true
	check(build.try_place_block(), "selected shape places through normal payment path")
	var paid := sim.material_count("wood")
	check(paid == count-2, "shape cost is paid exactly once")
	check(not build.try_place_block() and sim.material_count("wood") == paid and build.preview_reason.contains("occupied"), "double click on stale occupied preview spends nothing and explains failure")
	build.select_shape(&"codex_roof_slope")
	check(build.selection_refusal().contains("Forge Tyrant"), "locked shape never bypasses the unlock")
	sim.record_world_effect("stonecut_blocks")
	check(build.selection_refusal() == "", "existing world reward removes lock")
	for id in [&"codex_corner",&"codex_corner_floor",&"codex_roof_slope",&"codex_roof_hip",&"codex_roof_valley"]:
		build.select_shape(id)
		for i in 4:
			build.rotate_preview()
		check(build.preview_rotation_step == 0 and build._orientation_marker.visible, "four turns restore each octagonal/roof selection: "+String(id))
	build.select_shape(&"wall_panel")
	var rotation_before := build.preview_rotation_step
	build.rotate_preview()
	check(build.preview_rotation_step == rotation_before and not build._orientation_marker.visible, "surface-aligned pieces do not imply manual rotation")
	build.select_shape(&"cube")
	var obstacle: ResourceNode = preload("res://scenes/resource_node.tscn").instantiate()
	obstacle.position = Vector3(4.5,0,0.5)
	add_child(obstacle)
	for i in 3:
		await get_tree().physics_frame
	var blocked := {"kind":"volume","axis":0,"cell":Vector3i(8,0,0)}
	check(build.element_refusal(blocked).contains("resource"), "world resource collision identifies what must be cleared")
	build.preview_element = blocked
	build.preview_visible = true
	build.preview_valid = true
	check(not build.try_place_block() and sim.material_count("wood") == paid, "stale valid preview cannot pay through a new obstacle")
	build.select_shape(&"codex_corner")
	build.preview_rotation_step = 2
	build.preview_element = {"kind":"volume","axis":0,"cell":Vector3i(0,0,6)}
	build.preview_visible = true
	check(build.try_place_block(), "rotated corner places through the normal path")
	var saved := SaveManager.new().capture(player)
	check(SaveManager.new().apply(player,JSON.parse_string(JSON.stringify(saved))), "normal save restores builds made with the picker")
	var found := false
	for piece in get_children():
		if piece is PlacedBlock and piece.shape_id == &"codex_corner":
			found = piece.rotation_step == 2
	check(found, "corner orientation survives save restoration")
	player.inventory_panel.open_panel()
	palette.open_panel()
	check(not palette.is_open(), "another open panel prevents overlapping pickers")
	player.inventory_panel.close_panel()
	palette.open_panel()
	player.inventory_panel.open_panel()
	await get_tree().process_frame
	await get_tree().process_frame
	check(not palette.is_open() and player.inventory_panel.is_open(), "an asynchronously opened panel dismisses the picker")
	print("CODEX_BUILD_USABILITY %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures == 0 else 1)
