extends Node3D
## PLAY-05: real chest buttons, native paid storage, isolated ownership checks.
## Authored ground/fixed stock isolate the interaction; no campaign or art review.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var panel: ChestPanel
var first: PlacedBlock
var second: PlacedBlock
var job := "transfers"
var resumed := 0

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL PLAY05: ", label)
	return ok

func settle(frames := 4) -> void:
	for i in frames: await get_tree().process_frame

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	for name in ["reproduce", "restore"]:
		if "--play05-" + name in OS.get_cmdline_user_args(): job = name
	check(DisplayServer.get_name() == "headless" and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE, "headless fixture leaves the desktop pointer free")
	var ground := StaticBody3D.new()
	ground.position = Vector3(2, -0.5, 0)
	var shape := BoxShape3D.new()
	shape.size = Vector3(20, 1, 20)
	var collision := CollisionShape3D.new()
	collision.shape = shape
	ground.add_child(collision)
	add_child(ground)
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(-3, 0, -3)
	add_child(player)
	if job != "restore": player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	sim = player.inventory.get_sim()
	panel = player.chest_panel
	if not check(sim.last_error().is_empty(), "native tuning loaded"): _finish(); return
	if job == "restore":
		await _restore()
		await settle()
		_finish()
		return
	sim.add_material("wood", 49)
	await get_tree().physics_frame
	first = _place_chest(Vector3i.ZERO)
	second = _place_chest(Vector3i(8, 0, 0))
	if first == null or second == null: _finish(); return
	check(sim.material_count("wood") == 37, "two ordinary chests cost twelve of the fixture's 49 wood")
	player.placement.set_build_mode_enabled(false)
	await get_tree().physics_frame
	if not _open(first): _finish(); return
	await settle()
	var action := button("wood", "10  »")
	if action == null: _finish(); return
	var original_buttons := row_buttons("wood")
	# Signal activation is essential: direct store() calls miss the reported bug.
	action.pressed.emit()
	check(sim.material_count("wood") == 27 and stock(first, "wood") == 10, "Store 10 moves native quantities exactly once through pressed")
	check(panel.message() == "Stored 10 wood.", "Store reports the actual amount")
	if job != "reproduce":
		_retired(original_buttons, "Store refresh")
		await _transfers()
		_lifetime_boundaries()
		_write_checkpoint()
		_capacity_boundaries()
	panel.close_panel()
	await settle()
	_finish()

func _place_chest(cell: Vector3i) -> PlacedBlock:
	var build := player.placement
	build.set_build_mode_enabled(true)
	build.fine_mode = false
	player.build_palette.group = "All"
	player.build_palette.open_panel()
	player.build_palette.select_entry(&"chest", "shape")
	player.build_palette.select_material(&"wood")
	player.build_palette.close_panel()
	var element := {"kind":"volume", "axis":0, "cell":cell}
	var held := sim.material_count("wood")
	if not check(build.element_refusal(element).is_empty(), "ordinary chest placement accepts the fixture address"): return null
	build.preview_element = element
	build.preview_visible = true
	if not check(build.try_place_block(), "ordinary paid chest placement succeeds"): return null
	check(sim.material_count("wood") == held - int(sim.shape("chest").material_cost), "placement pays the unchanged native chest price")
	for child in get_children():
		if child is PlacedBlock and child.element == element: return child
	check(false, "paid chest has a physical block")
	return null

func _open(block: PlacedBlock) -> bool:
	var stand := block.global_position + Vector3(0, 0, 2)
	stand.y = 0
	player.global_position = stand
	player.velocity = Vector3.ZERO
	player.camera.global_position = stand + Vector3.UP * WroughtwildPlayer.FP_EYE_HEIGHT
	player.camera.look_at(block.global_position)
	if not check(player.aim_probe().get("target") == block, "normal E ray reaches the physical chest"): return false
	player.interact()
	return check(panel.is_open() and panel.chest == block and panel.store_key == block.store_key(), "normal interaction opens the same native store")

func row(family: String) -> HBoxContainer:
	for child in panel._rows.get_children():
		if (child.get_child(1) as Label).text == Hud.pretty(family): return child
	return null

func button(family: String, caption: String) -> Button:
	var entry := row(family)
	if check(entry != null, "family row exists: " + family):
		for child in entry.get_children():
			if child is Button and child.text == caption: return child
	check(false, "button exists: " + caption)
	return null

func stock(block: PlacedBlock, family: String) -> int:
	return int(sim.store_contents(block.store_key()).get(family, 0))

func _finish() -> void:
	print("PLAY05_%s %d checks, %d failures" % [job.to_upper(), checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func row_buttons(family: String) -> Array[Button]:
	var buttons: Array[Button] = []
	for child in row(family).get_children():
		if child is Button: buttons.append(child)
	return buttons

func _retired(buttons: Array[Button], boundary: String) -> void:
	var before := sim.export_json()
	for action in buttons:
		if not check(is_instance_valid(action), boundary + ": emitter survives until the end of the frame"): continue
		check(action.disabled and not action.is_inside_tree(), boundary + ": obsolete button is inactive and detached")
		check(action.pressed.get_connections().is_empty(), boundary + ": obsolete signal has no transfer callback")
		action.pressed.emit()
		action.pressed.emit()
	check(sim.export_json() == before, boundary + ": immediate repeated stale activation moves nothing")

func _display(family: String, pack: int, stored: int) -> void:
	var entry := row(family)
	if not check(entry != null, "current family has a displayed row"): return
	check((entry.get_child(2) as Label).text == "pack %d / %d" % [pack, sim.carry_cap(family)], "pack display matches native quantity and cap")
	check((entry.get_child(5) as Label).text == "chest %d" % stored, "chest row displays the actual quantity")
	check(sim.material_count(family) == pack and int(sim.store_contents(panel.store_key).get(family, 0)) == stored, "displayed quantities agree with native ownership")
	check(panel._title.text == "Chest  ·  %d / %d" % [sim.store_units(panel.store_key), int(sim.hauling_rules().chest_units)], "title uses the current store and native shared capacity")
	check((entry.get_child(3) as Button).disabled == (pack == 0) and (entry.get_child(4) as Button).disabled == (pack == 0), "empty pack disables both Store controls")
	check((entry.get_child(6) as Button).disabled == (stored == 0) and (entry.get_child(7) as Button).disabled == (stored == 0), "empty chest family disables both Take controls")

func _mouse_click(action: Button) -> void:
	var centre := action.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = centre
		event.global_position = centre
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		get_viewport().push_input(event, true)

func _transfers() -> void:
	_display("wood", 27, 10)
	await settle()
	_mouse_click(button("wood", "10  »"))
	_display("wood", 17, 20)
	button("wood", "«  10").pressed.emit()
	_display("wood", 27, 10)
	button("wood", "«  Take all").pressed.emit()
	_display("wood", 37, 0)
	check(panel.message() == "Took 10 wood.", "Take all reports the ten actually available")
	button("wood", "Store all  »").pressed.emit()
	_display("wood", 0, 37)
	player.open_chest(second)
	check(panel.row_count == 0 and panel._empty.visible, "empty pack and empty selected chest show the empty message")
	check(stock(first, "wood") == 37, "opening the empty chest does not move the other chest's contents")
	player.open_chest(first)
	var taking := row_buttons("wood")
	button("wood", "«  Take all").pressed.emit()
	_display("wood", 37, 0)
	_retired(taking, "Take refresh")
	# Simulate a displayed family being spent before its old button is released.
	sim.add_material("stone", 1)
	panel.refresh()
	var emptied := row_buttons("stone")
	var empty_action := button("stone", "Store all  »")
	check(sim.consume_material("stone", 1), "fixture spends the last displayed stone before activation")
	empty_action.pressed.emit()
	check(row("stone") == null and panel.row_count == 1 and panel.message() == "Nothing to store.", "zero native transfer removes the emptied family row truthfully")
	_retired(emptied, "Emptied family")

func _lifetime_boundaries() -> void:
	var closing := row_buttons("wood")
	panel.close_panel()
	check(not panel.is_open() and panel.store_key.is_empty() and panel.chest == null and panel.row_count == 0, "close clears current chest identity and controls immediately")
	_retired(closing, "Closed panel")
	player.open_chest(first)
	_retired(closing, "Reopened same chest")
	var switching := row_buttons("wood")
	player.open_chest(second)
	_retired(switching, "Switched chest before queued deletion")
	check(stock(first, "wood") == 0 and stock(second, "wood") == 0 and sim.material_count("wood") == 37, "stale controls cannot target the new chest")
	var other := row_buttons("wood")
	player.open_chest(first)
	_retired(other, "Switched back before queued deletion")
	button("wood", "10  »").pressed.emit()
	check(panel.store(&"wood", 3) == 3 and panel.take(&"wood", 3) == 3, "direct callers retain exact synchronous return values")
	_display("wood", 27, 10)

func _write_checkpoint() -> void:
	panel.close_panel()
	check(player.save_game(), "ordinary save writes the paid chests and exact contents in isolated APPDATA")
	var snapshot := SaveManager.new().capture(player)
	var expected := {"first_key":first.store_key(), "second_key":second.store_key(),
		"inventory":sim.inventory(), "first_contents":sim.store_contents(first.store_key()),
		"second_contents":sim.store_contents(second.store_key()), "blocks":snapshot.blocks}
	var file := FileAccess.open(OS.get_environment("WROUGHTWILD_PLAY05_OUTPUT").path_join("chest-expected.json"), FileAccess.WRITE)
	if check(file != null, "focused ownership receipt opens"):
		file.store_string(JSON.stringify(expected, "\t"))
		file.close()
	check(sim.material_count("wood") == 27 and stock(first, "wood") == 10 and stock(second, "wood") == 0, "checkpoint has 27 carried wood, 10 in the first paid chest and an empty second chest")

func _capacity_boundaries() -> void:
	player.open_chest(first)
	check(sim.carry_cap("wood") == 240 and int(sim.hauling_rules().chest_units) == 960, "accepted 240/960 capacities are unchanged")
	# Fixed stock sets up only the two relevant capacity edges; native APIs own all moves.
	sim.add_material("stone", 945)
	check(sim.store_deposit(first.store_key(), "stone", 945) == 945 and sim.store_room(first.store_key()) == 5, "native fixture leaves five shared chest units")
	panel.refresh()
	button("wood", "Store all  »").pressed.emit()
	_display("wood", 22, 15)
	check(panel.message() == "Stored 5 wood." and sim.store_units(first.store_key()) == 960, "partial Store reports five and fills the unchanged shared cap")
	var before := sim.export_json()
	button("wood", "10  »").pressed.emit()
	check(sim.export_json() == before and panel.message() == "The chest is full.", "full chest refuses without changing ownership")
	sim.add_material("wood", 216)
	panel.refresh()
	button("wood", "«  Take all").pressed.emit()
	_display("wood", 240, 13)
	check(panel.message() == "Took 2 wood.", "partial Take reports the two units of remaining carrying room")
	before = sim.export_json()
	button("wood", "«  10").pressed.emit()
	check(sim.export_json() == before and panel.message() == "Your pack can carry no more wood.", "full pack refuses without changing either store or pack")

func saved_world_started() -> void:
	# The normal Continue callback; this authored fixture has no world to generate.
	resumed += 1

func _restore() -> void:
	var expected_path := OS.get_environment("WROUGHTWILD_PLAY05_OUTPUT").path_join("chest-expected.json")
	if not check(FileAccess.file_exists(expected_path), "previous transfer job left its focused ownership receipt"): return
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(expected_path))
	check(sim.structure_piece_count() == 0 and sim.material_count("wood") == 0, "fresh process starts without the paid chests or their stock")
	var controls := WorldSeedControls.new()
	add_child(controls)
	controls.configure(self, "77", SaveManager.default_path())
	await settle()
	if not check(controls.continue_button != null, "normal Continue control sees the isolated save"): return
	controls.continue_button.pressed.emit()
	check(controls.finished and resumed == 1, "real Continue signal restores through player.load_game and SaveManager once")
	await get_tree().physics_frame
	var snapshot := SaveManager.new().capture(player)
	check(JSON.parse_string(JSON.stringify(snapshot.blocks)) == expected.blocks, "Continue restores the same paid shapes, material, addresses and orientation")
	# JSON receipts use floating-point numbers. Compare the same representation
	# on both sides, retaining every key and exact quantity.
	check(JSON.parse_string(JSON.stringify(sim.inventory())) == expected.inventory, "Continue restores exact carried quantities without paying or refunding again")
	for child in get_children():
		if child is PlacedBlock:
			if child.store_key() == String(expected.first_key): first = child
			if child.store_key() == String(expected.second_key): second = child
	if not check(first != null and second != null, "Continue restores both physical chest identities"): return
	check(JSON.parse_string(JSON.stringify(sim.store_contents(first.store_key()))) == expected.first_contents and JSON.parse_string(JSON.stringify(sim.store_contents(second.store_key()))) == expected.second_contents, "Continue restores each chest's own contents exactly")
	if not _open(first): return
	await settle()
	_display("wood", 27, 10)
	_mouse_click(button("wood", "«  10"))
	_display("wood", 37, 0)
	await settle()
	_mouse_click(button("wood", "10  »"))
	_display("wood", 27, 10)
	panel.close_panel()
	if not _open(first): return
	await settle()
	_display("wood", 27, 10)
	check(stock(second, "wood") == 0, "restored chest use leaves the other paid store empty")
	panel.close_panel()
