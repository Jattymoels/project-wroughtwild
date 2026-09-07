extends Node3D
## INT-06A: real native hopper transfers, cache boundaries and physical pause.
## The isolated pocket below supplies only presentation states; the generated
## source ledger and whole-world lifecycle remain in pressure_workshop.tscn.
class CountingFeeder extends ContraptionSite:
	var status_reads := 0
	func feeder_status(state: Dictionary = {}) -> Dictionary:
		status_reads += 1
		return super.feeder_status(state)

class DisplayPocket extends PressurePocket:
	var shown_remaining := 24
	func source_state() -> Dictionary:
		return {"remaining":shown_remaining,"capacity":24}

var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var feeder: CountingFeeder
var forge: StationSite

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FEEDER_VISUALS: ", label)
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

func _run() -> void:
	sim = load("res://scripts/sim.gd").shared()
	check(sim.contraption_bind_world("legacy_v1",1), "fixture uses the existing older-world hand-drive contract")
	_solid(Vector3(0,-0.5,0), Vector3(20,1,20))
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(-3,1.2,0)
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	sim.add_station("forge_basic")
	forge = preload("res://scenes/station_site.tscn").instantiate()
	forge.station_id = &"forge_basic"
	forge.position = Vector3(3.5,0,0.5)
	forge.station_key = StationSite.key_at("forge_basic",forge.position)
	forge.player_built = true
	add_child(forge)
	sim.add_material("pressure_feeder_kit",1)
	check(sim.contraption_place("pressure_feeder","visual_feeder",Vector3(0.5,0,0.5),0), "visual fixture pays for its native machine")
	feeder = CountingFeeder.new()
	feeder.machine_key = "visual_feeder"
	feeder.sim = sim
	add_child(feeder)
	feeder.set_physics_process(false)
	for frame in 3: await get_tree().physics_frame
	check(feeder.attach_feeder(forge.station_key, "").ok, "actual supported forge attaches")
	_loads_and_ports()
	await _cache_and_work()
	_pocket_inspection()
	await _release_fixture()
	print("FEEDER_VISUALS %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _release_fixture() -> void:
	# The last assertion creates a shader-backed pocket and closes two freshly
	# built inspection pages in one callback. Let their deferred two-frame fits
	# and rendering submissions settle, then release them while the normal frame
	# loop still runs instead of first releasing them during engine shutdown.
	var ledger := sim.contraption_save()
	var economy := sim.export_json()
	for frame in 4: await get_tree().process_frame
	for child in get_children(): child.queue_free()
	for frame in 4: await get_tree().process_frame
	check(get_child_count() == 0, "fixture releases its scene nodes before renderer shutdown")
	check(sim.contraption_save() == ledger and sim.export_json() == economy, "ordinary frame settling and scene removal never perform work or change ownership")

func _loads_and_ports() -> void:
	check(not feeder._hopper_load.visible and not feeder._fuel_load.visible and not feeder._output_load.visible, "empty physical buffers show no phantom stock")
	var envelope := AABB(Vector3(-0.75,0,-0.725),ContraptionSite.bounds_for("pressure_feeder"))
	for visual: MeshInstance3D in [feeder._hopper_load,feeder._fuel_load,feeder._output_load]:
		check(envelope.encloses(visual.transform * visual.mesh.get_aabb()), "representative load fits unchanged machine bounds")
		check(visual.get_child_count() == 0, "load adds no particle, light, collider or item owner")
	var input_clay: Dictionary = sim.contraption_config().feeder_inputs
	var fuels: Dictionary = sim.contraption_config().feeder_fuels
	for fuel in fuels:
		sim.add_material(String(fuel),1)
		check(sim.contraption_deposit(feeder.machine_key,String(fuel),1).moved == 1, "real native fuel deposit: " + String(fuel))
		var native_before := sim.contraption_save()
		feeder.refresh_from_sim()
		check(feeder._fuel_load.visible and not feeder._hopper_load.visible and not feeder._output_load.visible, "fuel alone never looks like clay or completed bricks")
		check(sim.contraption_save() == native_before, "fuel display changes no ledger ownership")
		check(sim.contraption_withdraw(feeder.machine_key,"input",String(fuel),1).moved == 1, "native withdrawal recovers fuel")
		feeder.refresh_from_sim()
		check(not feeder._fuel_load.visible and not feeder._hopper_load.visible, "last fuel withdrawal empties the visible hopper")
	for family in input_clay:
		sim.add_material(String(family),1)
		check(sim.contraption_deposit(feeder.machine_key,String(family),1).moved == 1, "real native clay deposit")
		feeder.refresh_from_sim()
		check(feeder._hopper_load.visible and not feeder._fuel_load.visible, "clay alone never implies available fuel")
		check(sim.contraption_withdraw(feeder.machine_key,"input",String(family),1).moved == 1, "native clay withdrawal")
		feeder.refresh_from_sim()
	var feed_material := feeder._feeder_pipe.material_override as StandardMaterial3D
	var pressure_material := feeder._pressure_pipe.material_override as StandardMaterial3D
	check(feed_material.albedo_color != pressure_material.albedo_color, "forge and pocket connections have distinct restrained finishes")
	check(not feed_material.emission_enabled and not pressure_material.emission_enabled, "connections imply no glowing or continuous flow")
	check(feeder._feeder_pipe.visible and not feeder._pressure_pipe.visible, "hand-driven attachment never invents a pressure pipe")
	var from := feeder.global_position + Vector3.UP * ContraptionSite.LOOK.feeder_link_height_m
	var to := forge.global_position + Vector3.UP * ContraptionSite.LOOK.feeder_link_height_m
	check(feeder._feeder_pipe.global_position.is_equal_approx((from + to) * 0.5), "pipe remains on the existing physical connection centreline")
	var body: CollisionShape3D
	for child in feeder.get_children():
		if child is CollisionShape3D: body = child
	check(body != null and (body.shape as BoxShape3D).size == Vector3(1.5,1.45,1.45)
		and body.position.is_equal_approx(Vector3(0,0.725,0)), "physical body and support height remain exact")

func _cache_and_work() -> void:
	sim.add_materials({"raw_clay":8,"wood":1})
	sim.contraption_deposit(feeder.machine_key,"raw_clay",8)
	sim.contraption_deposit(feeder.machine_key,"wood",1)
	feeder.refresh_from_sim()
	check(feeder._hopper_load.visible and feeder._fuel_load.visible, "mixed hopper shows separate actual supplies")
	check(feeder.perform("wind").ok and feeder.perform("start").ok, "real manual drive starts existing recipe")
	check(not feeder._hopper_load.visible and not feeder._fuel_load.visible, "reserved supplies no longer pretend to remain in the hopper")
	var ledger := sim.contraption_save()
	var reads := feeder.status_reads
	var cached := feeder.feeder_readout().duplicate(true)
	for i in 120: feeder.interact_label()
	check(feeder.status_reads == reads and sim.contraption_save() == ledger, "repeated aimed labels neither reprobe geometry nor touch native work")
	check(feeder.interact_label().contains(String(cached.headline)) and feeder.interact_label().ends_with("E to use"), "aimed action uses the cached truthful headline")
	feeder._physics_process(0.1)
	check(feeder.status_reads == reads + 1, "one physical readiness sample serves both active ticking and presentation")
	check(float(feeder.feeder_readout().progress) == float(cached.progress), "progress-only frames do not rerun the native display preview")
	feeder._physics_process(ContraptionSite.LOOK.feeder_panel_refresh_seconds + 0.01)
	var current: Dictionary = sim.contraption_state(feeder.machine_key)
	check(is_equal_approx(float(feeder.feeder_readout().progress),float(current.cycle_seconds) / float(sim.contraption_config().feeder_cycle_seconds)), "normal cadence catches up the displayed firing progress")
	var obstacle := _solid(Vector3(2,0.85,0.5), Vector3(0.3,1,0.8))
	for frame in 2: await get_tree().physics_frame
	ledger = sim.contraption_save()
	reads = feeder.status_reads
	check(not feeder.perform("resume").ok, "physical obstruction rejects an attempted operation")
	check(feeder.status_reads == reads + 1, "failed physical operation reuses its current readiness sample")
	check(not bool(feeder.feeder_readout().geometry.ready) and feeder.feeder_readout().headline == "Firing held", "refusal updates aimed diagnosis immediately")
	feeder._physics_process(2.0)
	check(sim.contraption_save() == ledger, "obstruction leaves exact reserved ownership and progress unchanged")
	obstacle.free()
	for frame in 2: await get_tree().physics_frame
	feeder.refresh_from_sim()
	check(bool(feeder.feeder_readout().geometry.ready) and feeder.feeder_readout().headline == "Firing bricks", "cleared real obstruction restores the current diagnosis")
	check(feeder.perform("pause").ok and feeder.feeder_readout().headline == "Paused by you", "explicit pause is distinct from a physical hold")
	check(feeder.perform("resume").ok and feeder.feeder_readout().headline == "Firing bricks", "resume describes the same reserved firing")
	feeder._physics_process(float(sim.contraption_config().feeder_cycle_seconds))
	check(feeder._output_load.visible and not feeder._hopper_load.visible and not feeder._fuel_load.visible, "only completed native bricks appear in the tray")
	check(sim.contraption_state(feeder.machine_key).output == {"rustclay_brick":4}, "visual fix preserves exact existing recipe yield")
	check(sim.contraption_withdraw(feeder.machine_key,"output","rustclay_brick",4).moved == 4, "ordinary output collection owns the bricks once")
	feeder.refresh_from_sim()
	check(not feeder._output_load.visible, "collected output disappears immediately")
	var native_before := sim.contraption_save()
	for i in 10: feeder.refresh_from_sim()
	check(sim.contraption_save() == native_before, "repeat refresh never refills buffers, drive or output")

func _pocket_inspection() -> void:
	var pocket := DisplayPocket.new()
	pocket.source_id = "presentation-only-pocket"
	pocket.sim = sim
	pocket.position = Vector3(-5,0,-5)
	add_child(pocket)
	var native_before := sim.contraption_save()
	pocket.interact(player)
	check(player.work_panel._custom_rows.size() == 3, "source inspection retains three compact existing topics")
	for row: Dictionary in player.work_panel._custom_rows:
		check(String(row.text).length() < 110 and not String(row.get("details", "")).is_empty(), "long source lore and setup detail stay optional")
	check(String(player.work_panel._custom_rows[0].details).contains("predates")
		and String(player.work_panel._custom_rows[0].details).contains("by accident"), "expanded source history retains the accepted accidental pre-cataclysm origin")
	check(pocket._membrane.visible and pocket.interact_label().contains("24 pressure strokes"), "positive displayed source has truthful remaining-stock cues")
	pocket.shown_remaining = 0
	pocket.interact(player)
	check(not pocket._membrane.visible and pocket.interact_label().contains("Pocket spent"), "spent source does not advertise remaining pressure")
	check(String(player.work_panel._custom_rows[1].text).contains("Hand-winding")
		and String(player.work_panel._custom_rows[1].details).contains("stored drive remains usable"), "exhaustion does not claim that existing stored work or hand winding stopped")
	pocket.set_highlight(true)
	check(not pocket._membrane.visible and sim.contraption_save() == native_before, "inspection/highlight never revives source stock or changes the ledger")
	player.work_panel.close_panel()
