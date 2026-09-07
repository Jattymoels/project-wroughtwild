extends Node3D
## Retained live work pages use the real controls and current action contract.
## This fixture exercises presentation only; no recipe or machine is operated.
var checks := 0
var failures := 0
var calls: Array[String] = []
var player: WroughtwildPlayer
var work: WorkPanel

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: custom panel refresh: ", message)

func settle(frames := 6) -> void:
	for i in frames: await get_tree().process_frame

func row(id: String, version := 0) -> Dictionary:
	return {"id":id, "text":"Hopper stock: %d items." % version,
		"button":"Collect %d" % version, "enabled":true,
		"details":"Reserved inputs remain owned. Reading %d." % version,
		"callback":func() -> void: calls.append("%s:%d" % [id, version])}

func view(id: String) -> Dictionary:
	return (work._custom_cards[id] as PanelContainer).get_meta("custom_view")

func legacy_button(caption: String) -> Button:
	for node in work._body.find_children("*", "Button", true, false):
		if node.text == caption: return node
	return null

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	get_window().size = Vector2i(1280, 720)
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	work = player.work_panel
	var sim := player.inventory.get_sim()
	var before := sim.export_json()
	await _live_page()
	await _pointer_press()
	await _identity_and_actions()
	await _legacy_and_layout()
	check(sim.export_json() == before, "browsing, disclosure, focus and refresh never change native state")
	work.close_panel()
	print("CUSTOM_PANEL_REFRESH %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)

func _live_page() -> void:
	var rows: Array = []
	for i in 24: rows.append(row("stock:%d" % i))
	player.open_custom_panel("Pressure feeder", rows, "", "machine-a:hopper")
	await settle()
	check(work.row_count() == rows.size() and work._custom_context == "machine-a:hopper", "player forwards the optional machine/page context")
	var card: PanelContainer = work._custom_cards["stock:12"]
	var action: Button = view("stock:12").button
	var detail: Button = view("stock:12").toggle
	detail.button_pressed = true
	await settle()
	action.grab_focus()
	work._scroll.scroll_vertical = 250
	await settle()
	var scrolled := work._scroll.scroll_vertical
	check(scrolled > 0, "long keyed page genuinely scrolls at 720p")
	for version in range(1, 5):
		await get_tree().create_timer(0.5).timeout
		for i in rows.size(): rows[i] = row("stock:%d" % i, version)
		player.open_custom_panel("Pressure feeder", rows, "", "machine-a:hopper")
		await settle()
		check(work._custom_cards["stock:12"] == card and view("stock:12").button == action and view("stock:12").toggle == detail, "live refresh keeps the same card and controls %d" % version)
		check(get_viewport().gui_get_focus_owner() == action, "live refresh preserves focused action %d" % version)
		check(work._scroll.scroll_vertical == scrolled, "live refresh preserves the user's scroll %d" % version)
		check((view("stock:12").more as RichTextLabel).visible and (view("stock:12").more as RichTextLabel).text.ends_with("%d." % version), "expanded explanation updates without collapsing %d" % version)
	check(calls.is_empty(), "timed refresh and expanded details execute no callback")
	action.pressed.emit()
	check(calls == ["stock:12:4"] and action.pressed.get_connections().size() == 1, "one retained connection dispatches the latest callback exactly once")
	rows.reverse()
	player.open_custom_panel("Pressure feeder", rows, "", "machine-a:hopper")
	check(work._body.get_child(0) == work._custom_cards["stock:23"] and view("stock:12").button == action, "changing row order reuses rather than rebinds the focused action")
	await settle()
	check(get_viewport().gui_get_focus_owner() == action, "row movement preserves actual focus")

func _mouse_button(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.global_position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	get_viewport().push_input(event, true)

func _pointer_press() -> void:
	player.open_custom_panel("Pressure feeder", [row("collect", 1)], "", "machine-a:press")
	await settle()
	var action: Button = view("collect").button
	var centre := action.get_global_rect().get_center()
	var count := calls.size()
	_mouse_button(centre, true)
	# Update between physical press and release, as a firing clock can do.
	player.open_custom_panel("Pressure feeder", [row("collect", 2)], "", "machine-a:press")
	_mouse_button(centre, false)
	await settle()
	check(view("collect").button == action and calls.size() == count + 1 and calls.back() == "collect:2", "a mouse press spanning refresh reaches the current action once")

func _identity_and_actions() -> void:
	player.open_custom_panel("Pressure feeder", [row("pause")], "", "machine-a:main")
	await settle()
	var paused_button: Button = view("pause").button
	(view("pause").toggle as Button).button_pressed = true
	var count := calls.size()
	player.open_custom_panel("Pressure feeder", [row("start")], "", "machine-a:main")
	paused_button.pressed.emit()
	check(calls.size() == count and paused_button.disabled and not paused_button.is_inside_tree(), "removed Pause action is inert rather than becoming Start")
	check(not (view("start").more as RichTextLabel).visible, "a different action starts with its own collapsed explanation")
	var first_machine_button: Button = view("start").button
	(view("start").toggle as Button).button_pressed = true
	player.open_custom_panel("Pressure feeder", [row("start", 2)], "", "machine-b:main")
	first_machine_button.pressed.emit()
	check(calls.size() == count and first_machine_button.disabled, "same-title machine switch cannot execute the old machine's action")
	check(not (view("start").more as RichTextLabel).visible and work._scroll.scroll_vertical == 0, "same-title machine switch clears disclosure and scroll state")
	var action: Button = view("start").button
	var changed := row("start", 3)
	changed.enabled = false
	player.open_custom_panel("Pressure feeder", [changed], "", "machine-b:main")
	action.pressed.emit()
	check(calls.size() == count and action.disabled, "current disabled state rejects even a manually emitted stale signal")
	changed.enabled = true
	player.open_custom_panel("Renamed feeder page", [changed], "", "machine-b:main")
	check(view("start").button == action, "explicit context survives presentation title changes")
	action.pressed.emit()
	check(calls.size() == count + 1 and calls.back() == "start:3", "reenabling retains one current callback")
	work.close_panel()
	action.pressed.emit()
	check(calls.size() == count + 1, "closed keyed controls cannot dispatch an action")
	player.open_custom_panel("Pressure feeder", [changed], "", "machine-b:main")
	check(view("start").button != action and not (view("start").more as RichTextLabel).visible, "reopening begins a fresh presentation session")
	await settle()

func _legacy_and_layout() -> void:
	var old_rows: Array = [{"text":"Cost stays visible.", "button":"Work", "enabled":false,
		"details":"Optional explanation.", "callback":func() -> void: calls.append("legacy")}]
	work.open_custom("Legacy choice", old_rows)
	await settle()
	legacy_button("Details").button_pressed = true
	work.open_custom("Legacy choice", old_rows)
	await settle()
	check(legacy_button("Less detail") != null and legacy_button("Work").disabled, "legacy unkeyed refresh retains its established disclosure and availability")
	work.close_panel()
	work.open_custom("Legacy choice", old_rows)
	await settle()
	check(legacy_button("Details") != null, "legacy close still clears disclosure")
	# Duplicate IDs deliberately fall back to the ordinary independent row list.
	work.open_custom("Malformed keys", [row("duplicate"), row("duplicate", 2)], "", "invalid:page")
	check(work.row_count() == 2 and work._custom_cards.is_empty(), "duplicate IDs cannot alias two actions into one retained card")
	await settle()
	player.open_custom_panel("Pressure feeder", [row("start")], "", "machine-a:main")
	await settle()
	# Start an actual custom fit, then switch modes during its two-frame wait.
	work._fit_height()
	work.open_hand_crafting()
	work._scroll.custom_minimum_size.y = 137
	await settle()
	check(work._mode == "crafting" and work.catalogue.visible and not work._scroll.visible, "pending custom layout cannot replace the crafting surface")
	check(work._scroll.custom_minimum_size.y == 137 and work._root.custom_minimum_size.x == 1120, "stale custom fit cannot resize the new crafting page")
