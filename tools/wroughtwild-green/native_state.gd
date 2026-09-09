extends RefCounted
## Native Green duplicates a request, never winding, ingredients or ownership.
const SOURCE := "green_home_margin"
const GREEN := "fixture_1024_62_1016"
const BLUE := "fixture_1016_62_1020"
const WHITE := "fixture_1008_62_1022"
const LEVER := "fixture_1000_62_1020"
const DRUM := "fixture_1008_62_1012"
const LANDING := "fixture_1036_62_1012"
const FEEDER := "fixture_1034_62_1036"
const PROFILE := "living_frontier_wave1"
const SEED := 77
var sim: WroughtwildSim
var paused := false
var active := true
var input_clear := true
var blue_output_clear := true
var first_clear := true
var second_clear := true
var cargo_clear := true
var feeder_clear := true
var source_blocked := false
var ambient_clock := 0.0
var passage_age := -1.0
var passage_duration := 1.05
var first_sent := false
var second_sent := false
var first_started := false
var second_started := false
var message := "Paid checkpoint: Blue holds a request; winch and feeder each own one winding."

func _init() -> void:
	sim=WroughtwildSim.new()
	assert(sim.load_tuning(ProjectSettings.globalize_path("res://data/tuning")),sim.last_error())
	load_checkpoint("res://paid-checkpoint.json")
func load_checkpoint(path: String) -> void:
	var saved:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(String(saved.world_profile)==PROFILE and int(saved.world_seed)==SEED)
	assert(sim.import_json(saved.sim),sim.last_error())
	assert(sim.leyline_load_world(saved.leylines,PROFILE,SEED))
	assert(sim.contraption_load_world(saved.contraptions,PROFILE,SEED))
	passage_age=-1;ambient_clock=0;first_sent=false;second_sent=false;first_started=false;second_started=false
func checkpoint(path: String) -> void:
	var file:=FileAccess.open(path,FileAccess.WRITE);assert(file!=null)
	file.store_string(JSON.stringify({"world_profile":PROFILE,"world_seed":SEED,"sim":sim.export_json(),"leylines":sim.leyline_save(),"contraptions":sim.contraption_save()}))
func source() -> Dictionary:
	for s:Dictionary in sim.leyline_sources():
		if s.id==SOURCE:return s
	assert(false,"Green source missing");return {}
func space(path_clear: bool) -> Dictionary:
	return {"path":path_clear,"first_link":first_clear,"second_link":second_clear,"first_receiver":cargo_clear,"second_receiver":feeder_clear}
func event_before() -> Array:
	return [int(sim.contraption_state(GREEN).pulses),int(sim.contraption_state(DRUM).energy),int(sim.contraption_state(FEEDER).energy)]
func observe(before: Array) -> void:
	var g:=sim.contraption_state(GREEN)
	if int(g.pulses)<=int(before[0]):return
	passage_age=0
	first_sent=first_clear and not String(g.link).is_empty()
	second_sent=second_clear and not String(g.second_link).is_empty()
	first_started=int(sim.contraption_state(DRUM).energy)<int(before[1])
	second_started=int(sim.contraption_state(FEEDER).energy)<int(before[2])
func tick(delta: float) -> void:
	if paused or not active:return
	ambient_clock+=delta
	if passage_age>=0:
		passage_age+=delta
		if passage_age>=passage_duration:passage_age=-1
	# Already paid jobs advance before any new departure is released this frame.
	sim.contraption_tick(DRUM,delta,cargo_clear)
	sim.contraption_tick(FEEDER,delta,feeder_clear)
	var before:=event_before()
	var result:=sim.contraption_request_tick(BLUE,delta,space(blue_output_clear))
	observe(before)
	if passage_age==0:message=String(result.message)
	sim.leyline_tick(delta,PackedStringArray([SOURCE]) if source_blocked else PackedStringArray())
func act(action: String) -> Dictionary:
	var result:Dictionary
	var before:=event_before()
	if paused or not active:result={"ok":false,"moved":0,"message":"Review paused or outside active radius."}
	elif action=="work":result={"ok":false,"moved":0,"message":"Source workspace blocked."} if source_blocked else sim.leyline_work(SOURCE)
	elif action=="collect":result=sim.leyline_collect(SOURCE,"green_resin")
	elif action=="rare":result=sim.leyline_collect(SOURCE,"preserving_catalyst")
	elif action=="request":result=sim.contraption_request(LEVER,space(input_clear))
	elif action in ["pause","resume","cancel"]:result=sim.contraption_action(BLUE,action)
	elif action=="disconnect_first":result=sim.contraption_link(GREEN,"",true)
	elif action=="connect_first":result=sim.contraption_link(GREEN,DRUM,first_clear)
	elif action=="disconnect_second":result=sim.contraption_link_second(GREEN,"",true)
	elif action=="connect_second":result=sim.contraption_link_second(GREEN,FEEDER,second_clear)
	elif action=="cargo":result=sim.contraption_withdraw(LANDING if bool(sim.contraption_state(DRUM).at_landing) else DRUM,"cargo","wood",96)
	elif action=="load":result=sim.contraption_deposit(DRUM,"wood",10)
	elif action=="bricks":result=sim.contraption_withdraw(FEEDER,"output","rustclay_brick",96)
	elif action=="clay":result=sim.contraption_deposit(FEEDER,"raw_clay",8)
	elif action=="fuel":result=sim.contraption_deposit(FEEDER,"wood",1)
	elif action=="wind_feeder":result=sim.contraption_action(FEEDER,"wind",feeder_clear)
	else:result=sim.contraption_action(DRUM,action,cargo_clear)
	observe(before);message=String(result.message);return result
func view() -> Dictionary:
	var s:=source();var g:=sim.contraption_state(GREEN);var b:=sim.contraption_state(BLUE)
	var d:=sim.contraption_state(DRUM);var f:=sim.contraption_state(FEEDER)
	var ready:bool=int(s.lot)<int(s.lots) and s.claim.is_empty()
	var state:="Ready" if ready else ("Released claim" if not s.claim.is_empty() else "Forming")
	if ready and int(s.work)>0:state=String(s.next_work)
	return {"source_state":state,"source_ready":ready,"source_work":int(s.work),"raw_claim":int(s.claim.get("green_resin",0)),"rare_claim":int(s.claim.get("preserving_catalyst",0)),"mineral_owned":sim.material_count("green_resin"),"lot":int(s.lot),"lots":int(s.lots),"formation":float(s.formation),"formation_seconds":float(s.formation_seconds),
		"pulses":int(g.pulses),"first_connected":not String(g.link).is_empty(),"second_connected":not String(g.second_link).is_empty(),"passage_age":passage_age,"passage_visible":passage_age>=0,"first_sent":first_sent,"second_sent":second_sent,"first_started":first_started,"second_started":second_started,
		"blue_pending":bool(b.pending_request),"blue_elapsed":float(b.delay_seconds),"blue_paused":bool(b.delay_paused),"delay_total":float(sim.contraption_config().delay_seconds),
		"energy":int(d.energy),"moving":bool(d.moving),"at_landing":bool(d.at_landing),"progress":float(d.progress),"trips":int(d.completed_trips),"cargo":int(d.cargo.get("wood",0)),"wood_owned":sim.material_count("wood"),
		"feeder_energy":int(f.energy),"feeder_working":int(f.queued_cycles)>0,"feeder_progress":float(f.cycle_seconds),"feeder_duration":float(sim.contraption_config().feeder_cycle_seconds),"clay_input":int(f.input.get("raw_clay",0)),"fuel_input":int(f.input.get("wood",0)),"clay_escrow":int(f.escrow_inputs.get("raw_clay",0)),"fuel_escrow":int(f.escrow_fuel.get("wood",0)),"drive_escrow":int(f.escrow_drive),"bricks":int(f.output.get("rustclay_brick",0)),"bricks_owned":sim.material_count("rustclay_brick"),"cycles":int(f.completed_cycles),
		"input_clear":input_clear,"blue_output_clear":blue_output_clear,"first_clear":first_clear,"second_clear":second_clear,"cargo_clear":cargo_clear,"feeder_clear":feeder_clear,"paused":paused,"active":active}
