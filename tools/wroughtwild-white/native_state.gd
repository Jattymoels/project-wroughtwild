extends RefCounted
## White requests passage; the native drum owns drive, movement and cargo.
const SOURCE := "white_home_margin"
const WHITE := "fixture_1008_62_1022"
const LEVER := "fixture_1000_62_1020"
const DRUM := "fixture_1008_62_1012"
const LANDING := "fixture_1036_62_1012"
const PROFILE := "living_frontier_wave1"
const SEED := 77
var sim: WroughtwildSim
var paused := false
var signal_clear := true
var cargo_clear := true
var source_blocked := false
var ambient_clock := 0.0
var request_age := -1.0
var request_duration := 0.85
var message := "Saved paid trip: ten wood already travelling. Loading does not replay its request."

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
	request_age = -1.0
	ambient_clock = 0.0

func checkpoint(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({"world_profile":PROFILE,"world_seed":SEED,"sim":sim.export_json(),"leylines":sim.leyline_save(),"contraptions":sim.contraption_save()}))

func source() -> Dictionary:
	for s: Dictionary in sim.leyline_sources():
		if s.id == SOURCE: return s
	assert(false,"White source missing")
	return {}

func tick(delta: float) -> void:
	if paused: return
	ambient_clock += delta
	if request_age >= 0.0:
		request_age += delta
		if request_age >= request_duration: request_age = -1.0
	sim.contraption_tick(DRUM, delta, cargo_clear)
	sim.leyline_tick(delta, PackedStringArray([SOURCE]) if source_blocked else PackedStringArray())

func act(action: String) -> Dictionary:
	var result: Dictionary
	if paused: result = {"ok":false,"moved":0,"message":"Review paused."}
	elif action == "work": result = {"ok":false,"moved":0,"message":"Source workspace blocked."} if source_blocked else sim.leyline_work(SOURCE)
	elif action == "collect": result = sim.leyline_collect(SOURCE,"white_mineral")
	elif action == "request":
		var before := int(sim.contraption_state(WHITE).pulses)
		result = sim.contraption_request(LEVER,{"path":signal_clear,"first_link":true,"second_link":true,"first_receiver":cargo_clear,"second_receiver":true})
		# A request can reach an unwound drum. Animate the actual counter event,
		# not result.ok; no animation is synthesized on checkpoint load or tick.
		if int(sim.contraption_state(WHITE).pulses) > before: request_age = 0.0
	elif action == "disconnect": result = sim.contraption_link(WHITE,"",true)
	elif action == "connect": result = sim.contraption_link(WHITE,DRUM,signal_clear)
	elif action == "cargo": result = sim.contraption_withdraw(LANDING if bool(sim.contraption_state(DRUM).at_landing) else DRUM,"cargo","wood",96)
	elif action == "load": result = sim.contraption_deposit(DRUM,"wood",10)
	else: result = sim.contraption_action(DRUM,action,cargo_clear)
	message = String(result.message)
	return result

func view() -> Dictionary:
	var s := source()
	var w := sim.contraption_state(WHITE)
	var d := sim.contraption_state(DRUM)
	var ready: bool = int(s.lot) < int(s.lots) and s.claim.is_empty()
	var state := "Ready" if ready else ("Released claim" if not s.claim.is_empty() else "Forming")
	if ready and int(s.work)>0: state=String(s.next_work)
	return {"source_state":state,"source_ready":ready,"source_work":int(s.work),"raw_claim":int(s.claim.get("white_mineral",0)),"mineral_owned":sim.material_count("white_mineral"),
		"lot":int(s.lot),"lots":int(s.lots),"formation":float(s.formation),"formation_seconds":float(s.formation_seconds),
		"pulses":int(w.pulses),"connected":not String(w.link).is_empty(),"request_age":request_age,"request_visible":request_age>=0.0,
		"energy":int(d.energy),"moving":bool(d.moving),"at_landing":bool(d.at_landing),"progress":float(d.progress),"trips":int(d.completed_trips),"cargo":int(d.cargo.get("wood",0)),"wood_owned":sim.material_count("wood"),
		"signal_clear":signal_clear,"cargo_clear":cargo_clear,"paused":paused}
