extends RefCounted
## ART-04 isolated adapter. All inventory, claims, heat and production are native.
const SOURCE := "red_home_margin"
const BUFFER := "fixture_1030_62_1040"
const FEEDER := "fixture_1034_62_1036"
const PROFILE := "living_frontier_wave1"
const SEED := 77
var sim: WroughtwildSim
var paused := false
var physical_ready := true
var source_blocked := false
var work_advanced := false
var work_clock := 0.0
var ambient_clock := 0.0
var message := "Paid checkpoint: one firing held at 2.25 seconds."

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
	work_advanced = false

func checkpoint(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify({"world_profile":PROFILE,"world_seed":SEED,"sim":sim.export_json(),"leylines":sim.leyline_save(),"contraptions":sim.contraption_save()}))

func source() -> Dictionary:
	for s: Dictionary in sim.leyline_sources():
		if s.id == SOURCE: return s
	assert(false, "Bound Red source missing")
	return {}

func tick(delta: float) -> void:
	work_advanced = false
	if paused: return
	ambient_clock += delta
	var before := sim.contraption_state(FEEDER)
	sim.contraption_tick(FEEDER, delta, physical_ready)
	var after := sim.contraption_state(FEEDER)
	work_advanced = float(after.cycle_seconds) > float(before.cycle_seconds) or int(after.completed_cycles) > int(before.completed_cycles)
	if work_advanced: work_clock += delta
	var blocked := PackedStringArray([SOURCE]) if source_blocked else PackedStringArray()
	sim.leyline_tick(delta, blocked)

func act(action: String) -> Dictionary:
	var result: Dictionary
	if paused:
		result = {"ok":false,"moved":0,"message":"Review paused."}
	elif action == "work":
		result = {"ok":false,"moved":0,"message":"Source workspace obstructed."} if source_blocked else sim.leyline_work(SOURCE)
	elif action == "collect": result = sim.leyline_collect(SOURCE, "red_salt")
	elif action == "collect_rare": result = sim.leyline_collect(SOURCE, "ember_catalyst")
	elif action == "heat": result = sim.contraption_action(BUFFER, "heat", physical_ready)
	else: result = sim.contraption_action(FEEDER, action, physical_ready)
	message = String(result.message)
	work_advanced = false
	return result

func view() -> Dictionary:
	var s := source()
	var b := sim.contraption_state(BUFFER)
	var f := sim.contraption_state(FEEDER)
	var raw_count := int(s.claim.get("red_salt", 0))
	var rare_count := int(s.claim.get("ember_catalyst", 0))
	var ready: bool = int(s.lot) < int(s.lots) and s.claim.is_empty()
	var state := "Ready" if ready else ("Released claim" if not s.claim.is_empty() else "Forming")
	if ready and int(s.work) > 0: state = String(s.next_work)
	return {"source_state":state,"source_ready":ready,"source_work":int(s.work),"raw_claim":raw_count,"rare_claim":rare_count,
		"salt_owned":sim.material_count("red_salt"),"lot":int(s.lot),"lots":int(s.lots),"formation":float(s.formation),"formation_seconds":float(s.formation_seconds),
		"heat":int(b.heat),"reserved_heat":int(f.escrow_heat),"capacity":int(sim.contraption_config().heat_capacity),
		"clay_held":int(f.escrow_inputs.get("raw_clay",0)),"stroke_held":int(f.escrow_drive),
		"progress":float(f.cycle_seconds),"cycle_seconds":float(sim.contraption_config().feeder_cycle_seconds),
		"output":int(f.output.get("rustclay_brick",0)),"working":work_advanced and not paused and physical_ready and not bool(f.feeder_paused),
		"feeder_paused":bool(f.feeder_paused),"physical_ready":physical_ready,"source_blocked":source_blocked}
