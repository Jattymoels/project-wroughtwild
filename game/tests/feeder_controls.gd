extends Node3D
## INT-06A: operate the paid, physically attached feeder through its real keyed
## controls. Seeded carried supplies are the only shortcut; work and transfers
## use normal buttons and the existing native transactions throughout.
var checks := 0
var failures := 0
var sim: WroughtwildSim
var player: WroughtwildPlayer
var feeder: ContraptionSite
var forge: StationSite
var work: WorkPanel

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FEEDER_CONTROLS: ", label)
	return ok

func _ready() -> void:
	_run.call_deferred()

func _solid(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	add_child(body)
	return body

func _state() -> Dictionary:
	return sim.contraption_state(feeder.machine_key)

func _row(id: String) -> Dictionary:
	for row: Dictionary in work._custom_rows:
		if row.get("id", "") == id: return row
	return {}

func _button(id: String) -> Button:
	var card: PanelContainer = work._custom_cards.get(id)
	if not check(card != null, "current page has keyed control " + id): return null
	return card.get_meta("custom_view").button

func _press(id: String) -> bool:
	var button := _button(id)
	if button == null: return false
	if not check(button.visible and not button.disabled, "action is visibly available: " + id): return false
	button.pressed.emit()
	return true

func _refused_control(id: String) -> void:
	var button := _button(id)
	if button == null: return
	check(button.disabled, "current refusal disables " + id)
	var ledger := sim.contraption_save()
	var economy := sim.export_json()
	button.pressed.emit()
	check(sim.contraption_save() == ledger and sim.export_json() == economy, "disabled signal cannot operate " + id)

func _main() -> void:
	if work._custom_context != "feeder:%s:main" % feeder.machine_key:
		_press("page:main")

func _run() -> void:
	get_window().size = Vector2i(1280,720)
	sim = load("res://scripts/sim.gd").shared()
	check(sim.contraption_bind_world("legacy_v1",1), "older-world fixture uses hand winding without adding a pressure source")
	_solid(Vector3(0,-0.5,0),Vector3(20,1,20))
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(-3,1.2,0)
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	work = player.work_panel
	sim.add_station("forge_basic")
	forge = preload("res://scenes/station_site.tscn").instantiate()
	forge.station_id = &"forge_basic"
	forge.position = Vector3(3.5,0,0.5)
	forge.station_key = StationSite.key_at("forge_basic",forge.position)
	forge.player_built = true
	add_child(forge)
	sim.add_materials({"pressure_feeder_kit":1,"raw_clay":128,"wood":16})
	check(sim.contraption_place("pressure_feeder","controls_feeder",Vector3(0.5,0,0.5),0), "native placement pays the seeded kit once")
	feeder = ContraptionSite.new()
	feeder.machine_key = "controls_feeder"
	feeder.sim = sim
	add_child(feeder)
	feeder.set_physics_process(false)
	for frame in 3: await get_tree().physics_frame
	feeder.interact(player)
	check(work.is_open() and work._custom_context == "feeder:controls_feeder:main", "ordinary physical interaction opens the exact machine overview")
	check(work._custom_rows.size() <= 7, "overview keeps production and navigation in a short page")
	await _attach_and_load()
	await _firing_controls()
	_capacity_includes_escrow()
	_trial_inspection()
	work.close_panel()
	print("FEEDER_CONTROLS %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _attach_and_load() -> void:
	_refused_control("action:start")
	_press("page:drive")
	check(String(_row("source:stock").get("text", "")).contains("hand winding available"), "unattached source does not hide the ordinary hand-drive path")
	_press("page:attach")
	var attach_id := "attach:" + forge.station_key + ":hand"
	_press("page:drive")
	check(work._custom_context.ends_with(":drive"), "attachment Back returns to its actual parent page")
	_press("page:attach")
	_press(attach_id)
	check(_state().forge_key == forge.station_key and _state().source_id == "", "actual Attach button stores the owned forge with no invented source")
	_press("action:wind")
	check(int(_state().energy) == 1, "Wind button stores one real stroke")
	_refused_control("action:charge")
	_main()
	_refused_control("action:start")
	check(String(_row("status").get("text", "")).contains("Waiting to fire"), "drive alone does not imply enough recipe supplies")
	_press("page:hopper")
	var clay_before := sim.material_count("raw_clay")
	var wood_before := sim.material_count("wood")
	_press("load:raw_clay")
	check(_state().input == {"raw_clay":32} and sim.material_count("raw_clay") == clay_before - 32, "Load clay moves the displayed one-batch share from the pack")
	_main()
	_refused_control("action:start")
	_press("page:hopper")
	_press("load:wood")
	check(_state().input == {"raw_clay":32,"wood":4} and sim.material_count("wood") == wood_before - 4, "Load fuel transfers ordinary heat separately from stored drive")
	_main()
	var start := _button("action:start")
	check(start != null and not start.disabled, "Start becomes available with actual connection, clay, fuel and drive")
	var obstruction := _solid(Vector3(2,0.85,0.5),Vector3(0.3,1,0.8))
	for frame in 2: await get_tree().physics_frame
	feeder.interact(player)
	check(String(_row("status").get("text", "")).contains("Workshop stopped"), "real obstructed connection produces a physical stop diagnosis")
	_refused_control("action:start")
	obstruction.free()
	for frame in 2: await get_tree().physics_frame
	feeder.interact(player)
	start = _button("action:start")
	check(start != null and not start.disabled, "removing the real obstruction restores Start")

func _firing_controls() -> void:
	var before := _state()
	_press("action:start")
	check(work.is_open() and work._custom_context.ends_with(":main"), "starting work keeps the live controls open")
	check(_state().escrow_inputs == {"raw_clay":8} and _state().escrow_fuel == {"wood":1} and int(_state().escrow_drive) == 1, "Start reserves exact existing clay, fuel and drive once")
	var pause := _button("action:pause")
	if pause != null: pause.grab_focus()
	feeder._physics_process(0.625)
	check(_button("action:pause") == pause and get_viewport().gui_get_focus_owner() == pause, "active native progress retains the actual focused Pause control")
	_press("action:pause")
	var held := sim.contraption_save()
	feeder._physics_process(2.0)
	check(sim.contraption_save() == held and String(_row("status").get("text", "")).contains("Paused by you"), "Pause holds exact native progress and describes explicit player intent")
	_press("action:resume")
	check(not _state().feeder_paused and is_equal_approx(float(_state().cycle_seconds),0.625), "Resume continues the same clock without a new reservation")
	_press("page:help")
	var held_text := String(_row("ownership").get("text", ""))
	check(held_text.contains("raw clay 8") and held_text.contains("wood 1"), "recovery text names held recipe ingredients and separately escrowed fuel")
	_press("action:cancel")
	check(_state().input == before.input and int(_state().energy) == int(before.energy) and int(_state().escrow_drive) == 0, "Cancel button returns exactly the current firing's held supplies and drive")
	_refused_control("action:cancel")
	_main()
	_press("action:start")
	feeder._physics_process(float(sim.contraption_config().feeder_cycle_seconds))
	check(_state().output == {"rustclay_brick":4} and int(_state().escrow_drive) == 0, "one stored stroke produces one completed firing then stops")
	check(String(work._custom_rows[1].get("id", "")) == "take:output:rustclay_brick", "completed output appears immediately below the current status")
	var bricks_before := sim.material_count("rustclay_brick")
	var collect := _button("take:output:rustclay_brick")
	_press("take:output:rustclay_brick")
	check(_state().output.is_empty() and sim.material_count("rustclay_brick") == bricks_before + 4, "actual Collect button transfers exactly the finished bricks")
	var ledger := sim.contraption_save()
	var economy := sim.export_json()
	if collect != null: collect.pressed.emit()
	check(sim.contraption_save() == ledger and sim.export_json() == economy, "removed Collect control cannot award those bricks twice")
	await get_tree().process_frame

func _capacity_includes_escrow() -> void:
	# After one firing the hopper has 24 clay + 3 wood. Ordinary one-batch
	# buttons add 32 clay and 4 wood, deliberately leaving exactly one slot.
	_press("page:hopper")
	_press("load:raw_clay")
	_press("load:wood")
	check(_state().input == {"raw_clay":56,"wood":7}, "button-only setup creates 63 real occupied input slots")
	_main()
	_press("page:drive")
	_press("action:wind")
	_main()
	_press("action:start")
	_press("page:hopper")
	var stock_text := String(_row("hopper:stock").get("text", ""))
	var held_text := String(_row("hopper:stock").get("details", ""))
	check(stock_text.contains("63 / 64") and stock_text.contains("including held"), "input capacity includes both held clay and held fuel")
	check(held_text.contains("raw clay 8") and held_text.contains("wood 1"), "hopper details preserve the two escrow owners")
	var load_button := _button("load:raw_clay")
	check(load_button != null and load_button.text == "Load 1 raw clay", "the displayed load amount is the single actually available slot")
	var carried := sim.material_count("raw_clay")
	_press("load:raw_clay")
	check(sim.material_count("raw_clay") == carried - 1 and int(_state().input.raw_clay) == 49, "normal Load takes only one clay beside active escrow")
	check(String(_row("hopper:stock").get("text", "")).contains("64 / 64"), "live capacity reflects the successful partial load immediately")
	_refused_control("load:raw_clay")
	_refused_control("load:wood")
	_main()

func _trial_inspection() -> void:
	var ledger := sim.contraption_save()
	var pack := sim.inventory()
	check(sim.trial_start_story(612,"forge_tyrant"), "real story entry deposits carried possessions while workshop escrow remains owned")
	var trial_economy := sim.export_json()
	for i in 20:
		var view := FeederReadout.inspect(feeder)
		check(not bool(view.native.available) and view.headline == "Workshop unavailable", "trial inspection is unavailable: %d" % i)
		feeder.refresh_from_sim()
		feeder.interact(player)
	check(sim.contraption_save() == ledger and sim.export_json() == trial_economy, "repeated readout, aimed refresh and open leave trial deposit, escrow and rules exact")
	_refused_control("action:pause")
	_press("page:hopper")
	for item in _state().input:
		_refused_control("take:input:" + String(item))
	_main()
	_press("page:drive")
	_refused_control("action:wind")
	_refused_control("action:charge")
	_refused_control("page:attach")
	_main()
	_press("page:help")
	_refused_control("action:cancel")
	_refused_control("dismantle")
	feeder._physics_process(30.0)
	check(sim.contraption_save() == ledger and sim.export_json() == trial_economy, "trial controls and oversized presentation tick cannot perform hidden production")
	sim.trial_abandon()
	check(sim.trial_end(), "ordinary trial exit restores the deposit")
	check(sim.inventory() == pack and sim.contraption_save() == ledger, "return preserves exact carried stock and workshop escrow independently")
	feeder.interact(player)
	_press("action:pause")
	_press("action:resume")
	_press("page:help")
	_press("action:cancel")
	check(int(_state().escrow_drive) == 0 and _state().input == {"raw_clay":57,"wood":7}, "returned ordinary controls recover the exact full hopper without duplication")
	_main()
