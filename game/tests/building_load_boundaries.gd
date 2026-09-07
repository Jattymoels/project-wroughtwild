extends "res://tests/loose_drop_save.gd"
## Supplied boundary stock is intentional: this checks exact ownership, not
## gathering pace. The separate building_load_review has no material grants.
const LOAD_SAVE := "res://building-load-boundaries.json"
const LOAD_EXPECTED := "res://building-load-boundaries-expected.json"
const COMMON := ["wood","pine","bog_oak","ash_wood","fieldstone","split_stone","stone",
	"raw_slate","raw_shellstone","raw_clay","raw_reed","resinheart_log","raw_corkbark","furnace_slag","cinderglass_shard",
	"slate","shellstone","rustclay_brick","woven_reed","resinheart","corkbark","vitrified_basalt","cinderglass"]

func _run() -> void:
	# Authoritative world scope for the authored fixture; no generated ledger.
	sim.contraption_bind_world("legacy_v1",0)
	if "--load-restore-only" in OS.get_cmdline_user_args():
		read_boundary()
	else:
		for family in COMMON: pickup_boundary(family)
		unchanged_caps()
		crafted_output_boundary()
		chest_boundary()
		legacy_boundary()
		death_and_trial()
		write_boundary()
		read_boundary()
	print("BUILDING_LOAD_BOUNDARIES %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func pickup_boundary(family: String) -> void:
	_reset()
	var cap := sim.carry_cap(family)
	sim.add_material(family,cap-3)
	var chip := _chip(10,family)
	chip._absorb(player)
	chip._absorb(player)
	check(sim.material_count(family)==cap and chip.amount==7,"partial "+family+" pickup retains exact remainder")
	var saved := manager.capture(player)
	if not _apply(_roundtrip(saved),"restore full "+family+" pack and leftover"): return
	var restored := _find("material") as Pickup
	if not check(restored!=null,"physical remainder exists for "+family): return
	player.global_position=restored.global_position-Vector3(0,.6,0)
	restored._physics_process(0.0)
	check(sim.material_count(family)==cap and restored.amount==7,"full "+family+" pack leaves seven physical units")
	sim.consume_material(family,7)
	restored._physics_process(0.0)
	check(sim.material_count(family)==cap and restored.is_queued_for_deletion(),"new "+family+" room collects seven exactly once")

func unchanged_caps() -> void:
	for family in ["iron_ore","copper_ore","tin_ore","ember_iron_ore","silver_ore","hide"]:
		check(sim.carry_cap(family)==30,"specialised hauling cap unchanged: "+family)
	for family in ["shrieker_horn","tyrant_heart","warden_eye"]:
		check(sim.carry_cap(family)==1,"curio cap unchanged: "+family)
	for family in ["timber_wedge","lanternheart","thrumroot","stormglass","pullstone","ventlung","workbench_kit","iron_ingot","charcoal","preserving_catalyst","unlisted_stock"]:
		check(sim.carry_cap(family)==40,"existing default or explicit cap unchanged: "+family)
	check(sim.carry_cap("iron_chest_armour")==0,"equipment remains uncapped")

func chest_boundary() -> void:
	_reset()
	var key := "block:0:0,0,0"
	var capacity := sim.store_room(key)
	var cap := sim.carry_cap("wood")
	check(capacity>=cap*4,"one chest fits four full common stacks")
	for family in ["wood","stone","raw_shellstone","shellstone"]:
		sim.add_material(family,cap)
		check(sim.store_deposit(key,family,cap)==cap,"shared chest stores one complete "+family+" load")
	check(sim.store_room(key)==capacity-cap*4,"mixed stacks use shared chest capacity")
	sim.add_material("wood",capacity+9)
	var space := sim.store_room(key)
	check(sim.store_deposit(key,"wood",capacity+9)==space,"deposit stops exactly at shared space")
	check(sim.store_deposit(key,"wood",1)==0,"full chest refuses without losing held stock")
	sim.consume_material("wood",sim.material_count("wood"))
	check(sim.store_withdraw(key,"wood",cap+1)==cap,"withdrawal stops at selected pack cap")
	var remaining := sim.store_contents(key).duplicate(true)
	check(sim.store_withdraw(key,"wood",1)==0 and sim.store_contents(key)==remaining,"full-pack withdrawal leaves stored quantity")
	# Chest dismantling hands every unit back to a world owner, regardless of
	# pack capacity; normal physical pickup then enforces the selected haul cap.
	var spill: Dictionary=sim.store_remove(key)
	check(spill==remaining and sim.store_contents(key).is_empty(),"dismantling returns every stored family once")
	check(sim.store_remove(key).is_empty(),"duplicate chest removal cannot duplicate contents")

func crafted_output_boundary() -> void:
	_reset()
	# Supplied station isolates the native output contract; the generated route
	# separately earns and places all stations through their real recipes.
	sim.add_station("mason_yard")
	var cap := sim.carry_cap("shellstone")
	sim.add_materials({"shellstone":cap-1,"raw_shellstone":8})
	check(bool(sim.craft("refine_shellstone").crafted),"ordinary refinement can finish beside a full pack")
	check(sim.material_count("shellstone")==cap+3 and sim.material_count("raw_shellstone")==0,"crafting preserves all four outputs above the pickup cap")
	check(sim.carry_room("shellstone")==0,"over-cap crafted stock prevents new hauling")

func legacy_boundary() -> void:
	_reset()
	# Old-cap snapshots and legitimate over-cap stock both remain exact. Caps
	# constrain new transfers; SaveManager must not reinterpret owned quantities.
	for counts in [[60,240],[777,1234]]:
		# Use the native save schema to represent pre-existing owned quantities.
		var rules: Dictionary=JSON.parse_string(sim.export_json())
		var economy: Dictionary=rules.economy
		economy.inventory={"wood":int(counts[0])}
		economy.stores={"old_chest":{"wood":int(counts[1])}}
		var saved := manager.capture(player)
		saved.sim=JSON.stringify(rules)
		if _apply(saved,"old/over-cap checkpoint imports without clamping"):
			check(sim.material_count("wood")==int(counts[0]),"existing carried quantity is exact")
			check(sim.store_contents("old_chest")=={"wood":int(counts[1])},"existing stored quantity is exact")

func death_and_trial() -> void:
	_reset()
	var owned := {"wood":777,"raw_shellstone":241,"shellstone":242}
	sim.add_materials(owned)
	var dropped: Dictionary=sim.drop_inventory()
	check(dropped==owned and sim.inventory().is_empty(),"world death moves every over-cap building unit into its pack")
	var bundle := _bundle(dropped)
	bundle.interact(player)
	bundle.interact(player)
	check(sim.inventory()==owned,"death recovery returns exact stock once, even above pickup caps")
	var gear_before: String=sim.export_json()
	check(sim.trial_start(77),"trial accepts enlarged carried deposit")
	check(sim.inventory().is_empty(),"ordinary carried building materials are held at trial entrance")
	check(not sim.trial_begin_room(0).is_empty(),"enter a native trial room")
	sim.trial_resolve_room(false)
	check(sim.trial_player_died(),"room defeat records actual trial death")
	check(sim.trial_end(),"finished trial settles once")
	check(sim.inventory()==owned,"trial death restores the entire deposit once")
	check(sim.export_json()==gear_before,"trial death leaves permanent economy including equipment exact")

func write_boundary() -> void:
	_reset()
	sim.contraption_bind_world("legacy_v1",0)
	sim.add_materials({"wood":777,"raw_shellstone":241,"shellstone":242})
	sim.store_deposit("saved_chest","shellstone",242)
	_chip(9,"wood")
	_bundle({"wood":300,"stone":299})
	var expected := manager.capture(player)
	check(manager.write_data(LOAD_SAVE,expected),"write enlarged ownership checkpoint")
	var file := FileAccess.open(LOAD_EXPECTED,FileAccess.WRITE)
	file.store_string(JSON.stringify(expected,"",true,true))
	file.close()

func read_boundary() -> void:
	var expected: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(LOAD_EXPECTED))
	for repeat in 2:
		if not check(manager.read(LOAD_SAVE,player),"fresh/repeated enlarged checkpoint read: "+manager.last_error): return
		_freeze_drops()
		var actual := manager.capture(player)
		check(JSON.parse_string(actual.sim)==JSON.parse_string(expected.sim),"exact native stock, storage, equipment and progression after restart")
		check(JSON.parse_string(JSON.stringify(actual.world_drops,"",true,true))==expected.world_drops,"loose remainder and death pack retain exact ownership")
