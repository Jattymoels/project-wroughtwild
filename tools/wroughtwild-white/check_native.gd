extends SceneTree
const Adapter := preload("res://native_state.gd")
var checks := 0
var failures: Array[String] = []
func check(value: bool, label: String) -> void:
	checks += 1
	if not value: failures.append(label); push_error(label)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var a := Adapter.new()
	if "--restart" in OS.get_cmdline_user_args():
		a.load_checkpoint("user://white-held.json")
		check(a.view().moving and a.view().cargo==10 and is_equal_approx(a.view().progress,3.3/14.0),"fresh process exact paid fractional trip")
		check(not a.view().request_visible and a.view().pulses==4,"saved counter does not replay request")
		a.cargo_clear=false;var held:=a.sim.contraption_save();a.tick(20)
		check(a.sim.contraption_save()==held,"blocked restart retains all cargo and progress")
		a.cargo_clear=true;a.tick(20)
		check(a.view().at_landing and a.view().cargo==10 and a.view().trips==1,"fresh process delivers same ten wood once")
		var wood:int=a.view().wood_owned
		check(a.act("cargo").moved==10 and a.view().wood_owned==wood+10 and a.view().cargo==0,"restart collection exact")
		check(not a.act("cargo").ok,"restart cannot collect twice")
		finish();return
	check(a.view().moving and a.view().cargo==10 and is_equal_approx(a.view().progress,1.2/14.0),"original paid trip and ten wood")
	check(a.view().energy==0 and a.view().pulses==3 and not a.view().request_visible,"restore shows no invented drive or request replay")
	var original:=a.sim.contraption_save()
	a.paused=true;a.tick(30)
	check(a.sim.contraption_save()==original and a.ambient_clock==0,"review pause freezes native and cosmetic clocks")
	check(not a.act("request").ok and not a.view().request_visible,"paused input cannot trigger request")
	a.paused=false;a.cargo_clear=false;a.tick(20)
	check(a.sim.contraption_save()==original,"blocked basket preserves paid trip")
	a.cargo_clear=true
	check(not a.act("request").ok and a.view().request_visible and a.view().pulses==4,"request reaches travelling drum without scheduling another trip")
	check(a.view().energy==0 and a.view().cargo==10 and a.view().trips==0,"failed departure preserves drive cargo and trips")
	a.paused=true;var age:float=a.request_age;a.tick(5)
	check(a.request_age==age,"review pause freezes transient request")
	a.paused=false;a.tick(.7)
	check(is_equal_approx(a.view().progress,3.3/14.0),"native speed advances exact paid trip")
	a.checkpoint("user://white-held.json")
	a.tick(.2)
	check(not a.view().request_visible,"one-shot request expires")
	a.tick(20)
	check(a.view().at_landing and not a.view().moving and a.view().trips==1 and a.view().cargo==10,"original ten wood arrives once")
	var before_wood:int=a.view().wood_owned
	check(a.act("cargo").moved==10 and a.view().wood_owned==before_wood+10,"native transfer to carried wood")
	check(not a.act("cargo").ok and a.view().wood_owned==before_wood+10,"cannot collect twice")
	check(not a.act("request").ok and a.view().request_visible and a.view().energy==0,"unwound request passes but creates no motion")
	a.tick(1);check(not a.view().moving and not a.view().request_visible,"no queued unpaid departure or looping light")
	check(a.act("wind").ok and a.view().energy==1,"manual winding owns one work")
	a.tick(10);check(not a.view().moving and a.view().energy==1,"later winding cannot replay failed request")
	a.signal_clear=false;var count:int=a.view().pulses
	check(not a.act("request").ok and a.view().pulses==count and not a.view().request_visible and a.view().energy==1,"blocked signal emits no passage or payment")
	a.signal_clear=true
	check(a.act("disconnect").ok,"disconnect White")
	check(not a.act("request").ok and a.view().pulses==count and not a.view().request_visible,"disconnected request has no passage")
	check(a.act("connect").ok and a.act("request").ok,"reconnected actual request starts paid return")
	check(a.view().energy==0 and a.view().moving,"return spends exactly one winding")
	check(a.act("disconnect").ok,"disconnect during trip")
	a.tick(20);check(not a.view().at_landing and a.view().trips==2,"disconnect preserves departed paid return")
	check(a.act("load").moved==10 and a.view().cargo==10 and a.view().wood_owned==before_wood,"loading retains exact ownership")
	check(a.act("connect").ok and a.act("wind").ok and a.act("request").ok,"next actual request uses new winding")
	a.tick(20);check(a.view().trips==3 and a.view().cargo==10,"second outbound trip completes once")
	# Extraction cases remain independent of the request/transport proof.
	a.load_checkpoint("res://paid-checkpoint.json")
	check(a.view().mineral_owned==14 and a.view().source_ready and a.view().lot==1,"published White stock and pack")
	var ledger:=a.sim.leyline_save();a.source_blocked=true
	check(not a.act("work").ok and a.sim.leyline_save()==ledger,"physical workspace refusal preserves source")
	a.source_blocked=false
	for i in 4:
		check(a.act("work").ok and a.view().source_work==(i+1)%4,"actual extraction stage %d"%(i+1))
	check(a.view().raw_claim==16 and a.view().mineral_owned==14 and not a.view().source_ready,"released pieces stay source owned")
	ledger=a.sim.leyline_save()
	check(not a.act("work").ok and a.sim.leyline_save()==ledger,"held claim stops further extraction")
	a.checkpoint("user://white-claim.json");a.load_checkpoint("user://white-claim.json")
	check(a.sim.leyline_save()==ledger and a.view().raw_claim==16,"claim reload is exact")
	check(a.act("collect").moved==16 and a.view().raw_claim==0 and a.view().mineral_owned==30,"one full native collection")
	check(not a.act("collect").ok and a.view().mineral_owned==30,"repeat collection cannot duplicate")
	for lot in 6:
		for step in 4:check(a.act("work").ok,"exhaust remaining native lot")
		check(a.act("collect").moved==16,"collect remaining native lot")
	check(not a.view().source_ready and a.view().mineral_owned==126 and a.view().source_state=="Forming","exhausted source loses ready cue with physical scars retained")
	a.source_blocked=true;a.tick(700)
	check(not a.view().source_ready and a.view().formation==600,"obstructed renewal stays capped and not ready")
	a.source_blocked=false;a.tick(.01)
	check(a.view().source_ready and a.view().lot==0,"unblocked native renewal re-arms once")
	for i in 4:a.act("work")
	check(a.act("collect").moved==2 and a.view().raw_claim==14 and a.view().mineral_owned==128,"partial collection retains fourteen source-owned pieces")
	ledger=a.sim.leyline_save()
	check(not a.act("collect").ok and a.sim.leyline_save()==ledger,"full family refuses without losing pieces")
	finish()
func finish() -> void:
	var result:={"checks":checks,"failures":failures,"restart":"--restart" in OS.get_cmdline_user_args()}
	var path:="res://evidence/native-restart.json" if result.restart else "res://evidence/native-checks.json"
	FileAccess.open(path,FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("WHITE_NATIVE_CHECKS ",checks," failures ",failures.size())
	quit(0 if failures.is_empty() else 1)
