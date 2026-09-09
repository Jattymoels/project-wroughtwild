extends RefCounted
## Blue retains one request; the native drum owns winding, movement and cargo.
const SOURCE := "blue_home_margin"
const BLUE := "fixture_1016_62_1020"
const WHITE := "fixture_1008_62_1022"
const LEVER := "fixture_1000_62_1020"
const DRUM := "fixture_1008_62_1012"
const LANDING := "fixture_1036_62_1012"
const PROFILE := "living_frontier_wave1"
const SEED := 77
var sim: WroughtwildSim
var paused := false
var active := true
var signal_clear := true
var input_clear := true
var cargo_clear := true
var source_blocked := false
var ambient_clock := 0.0
var release_age := -1.0
var release_duration := 0.65
var message := "Saved request: 0.8 / 3 seconds held. Ten wood and one winding belong to the drum."

func _init() -> void:
	sim = WroughtwildSim.new()
	assert(sim.load_tuning(ProjectSettings.globalize_path("res://data/tuning")), sim.last_error())
	load_checkpoint("res://paid-checkpoint.json")

func load_checkpoint(path: String) -> void:
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(String(saved.world_profile) == PROFILE and int(saved.world_seed) == SEED)
	assert(sim.import_json(saved.sim), sim.last_error())
	assert(sim.leyline_load_world(saved.leylines, PROFILE, SEED))
	assert(sim.contraption_load_world(saved.contraptions, PROFILE, SEED))
	release_age = -1.0
	ambient_clock = 0.0

func checkpoint(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({"world_profile":PROFILE,"world_seed":SEED,"sim":sim.export_json(),"leylines":sim.leyline_save(),"contraptions":sim.contraption_save()}))

func source() -> Dictionary:
	for s: Dictionary in sim.leyline_sources():
		if s.id == SOURCE: return s
	assert(false,"Blue source missing")
	return {}

func space(clear: bool) -> Dictionary:
	return {"path":clear,"first_link":true,"second_link":true,"first_receiver":cargo_clear,"second_receiver":true}

func tick(delta: float) -> void:
	if paused or not active: return
	ambient_clock += delta
	if release_age >= 0.0:
		release_age += delta
		if release_age >= release_duration: release_age = -1.0
	# Advance a previously departed trip before releasing new work this frame.
	# This matches the host's discrete clocks; no whole-frame over-credit on release.
	sim.contraption_tick(DRUM, delta, cargo_clear)
	var held: bool = sim.contraption_state(BLUE).pending_request
	var result := sim.contraption_request_tick(BLUE, delta, space(signal_clear))
	if held and not bool(sim.contraption_state(BLUE).pending_request):
		release_age = 0.0
		message = String(result.message)
	sim.leyline_tick(delta, PackedStringArray([SOURCE]) if source_blocked else PackedStringArray())

func act(action: String) -> Dictionary:
	var result: Dictionary
	if paused or not active: result = {"ok":false,"moved":0,"message":"Review paused or outside active radius."}
	elif action == "work": result = {"ok":false,"moved":0,"message":"Source workspace blocked."} if source_blocked else sim.leyline_work(SOURCE)
	elif action == "collect": result = sim.leyline_collect(SOURCE,"blue_flake")
	elif action == "rare": result = sim.leyline_collect(SOURCE,"frost_catalyst")
	elif action == "request": result = sim.contraption_request(LEVER,space(input_clear))
	elif action in ["pause","resume","cancel"]: result = sim.contraption_action(BLUE,action)
	elif action == "disconnect": result = sim.contraption_link(BLUE,"",true)
	elif action == "connect": result = sim.contraption_link(BLUE,DRUM,signal_clear)
	elif action == "cargo": result = sim.contraption_withdraw(LANDING if bool(sim.contraption_state(DRUM).at_landing) else DRUM,"cargo","wood",96)
	elif action == "load": result = sim.contraption_deposit(DRUM,"wood",10)
	else: result = sim.contraption_action(DRUM,action,cargo_clear)
	message = String(result.message)
	return result

func view() -> Dictionary:
	var s := source()
	var b := sim.contraption_state(BLUE)
	var d := sim.contraption_state(DRUM)
	var ready: bool = int(s.lot) < int(s.lots) and s.claim.is_empty()
	var state := "Ready" if ready else ("Released claim" if not s.claim.is_empty() else "Forming")
	if ready and int(s.work)>0: state=String(s.next_work)
	return {"source_state":state,"source_ready":ready,"source_work":int(s.work),"raw_claim":int(s.claim.get("blue_flake",0)),"rare_claim":int(s.claim.get("frost_catalyst",0)),"mineral_owned":sim.material_count("blue_flake"),
		"lot":int(s.lot),"lots":int(s.lots),"formation":float(s.formation),"formation_seconds":float(s.formation_seconds),
		"pulses":int(b.pulses),"connected":not String(b.link).is_empty(),"pending":bool(b.pending_request),"delay_paused":bool(b.delay_paused),"delay_seconds":float(b.delay_seconds),"delay_total":float(sim.contraption_config().delay_seconds),"release_age":release_age,"release_visible":release_age>=0.0,
		"energy":int(d.energy),"moving":bool(d.moving),"at_landing":bool(d.at_landing),"progress":float(d.progress),"trips":int(d.completed_trips),"cargo":int(d.cargo.get("wood",0)),"wood_owned":sim.material_count("wood"),
		"signal_clear":signal_clear,"input_clear":input_clear,"cargo_clear":cargo_clear,"paused":paused,"active":active}
