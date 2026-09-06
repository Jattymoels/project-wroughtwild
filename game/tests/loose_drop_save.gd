extends Node3D
## Isolated authored world: exercise physical ownership through normal Pickup,
## DroppedBundle and SaveManager operations without touching user:// saves.
const CHECKPOINT := "res://loose_drop_save_checkpoint.json"
const DISK_PROBE := "res://loose_drop_save_disk_probe.json"
const EMPTY := {"version":1,"pickups":[],"bundles":[]}
const BUNDLE_SCENE := preload("res://scenes/dropped_bundle.tscn")
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var manager := SaveManager.new()
var initial_rules := ""
var gear_seed := -1
var elite_id := ""
var page_skill := ""

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: loose drops: ",label)
	return ok

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.global_position = Vector3(1000,10,1000)
	sim = player.inventory.get_sim()
	initial_rules = sim.export_json()
	_run.call_deferred()

func _run() -> void:
	if "--read-checkpoint" in OS.get_cmdline_user_args():
		_read_checkpoint()
	elif "--write-checkpoint" in OS.get_cmdline_user_args():
		if _select_rewards(): _write_checkpoint()
	else:
		_material_flow()
		_motion_and_expiry()
		_identical_and_scoped()
		if _select_rewards():
			_reward_flow()
			_malformed_payloads()
		_bundle_flow()
		_legacy_and_disk()
	print("LOOSE_DROP_SAVE %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _reset() -> void:
	WorldDrops.restore(self,EMPTY)
	check(sim.import_json(initial_rules),"reset isolated economy")
	player.global_position = Vector3(1000,10,1000)

func _drops(root: Node = null) -> Array:
	if root == null: root = self
	var found: Array = []
	for child in root.get_children():
		if child.is_queued_for_deletion(): continue
		if child is Pickup or child is DroppedBundle: found.append(child)
		found.append_array(_drops(child))
	return found

func _freeze_drops(root: Node = null) -> void:
	for drop in _drops(root): drop.set_physics_process(false)

func _chip(amount: int, family := "wood", root: Node = null) -> Pickup:
	if root == null: root = self
	var drop: Pickup = Pickup.scatter(root,Vector3(20,6,20),{family:amount},7,3.0)[0]
	drop.set_physics_process(false)
	drop._velocity = Vector3(1.25,2.5,-.75)
	drop._floor_y = 3.0
	drop._bounces = 1
	drop._age = 31.25
	drop._bob_phase = 1.75
	drop._mesh.position.y = .15625
	drop.rotation.y = .5
	return drop

func _bundle(contents: Dictionary, root: Node = null) -> DroppedBundle:
	if root == null: root = self
	var bundle: DroppedBundle = BUNDLE_SCENE.instantiate()
	root.add_child(bundle)
	bundle.global_position = Vector3(22,3,20)
	bundle.global_rotation = Vector3(.125,.5,-.125)
	bundle.contents = contents.duplicate(true)
	return bundle

func _find(kind: String) -> Node:
	for drop in _drops():
		if kind == "bundle" and drop is DroppedBundle: return drop
		if drop is Pickup and drop.kind == kind: return drop
	return null

func _apply(saved: Dictionary, label: String) -> bool:
	var ok := manager.apply(player,saved)
	check(ok,label+": "+manager.last_error)
	_freeze_drops()
	return ok

func _roundtrip(saved: Dictionary) -> Dictionary:
	return JSON.parse_string(JSON.stringify(saved,"",true,true))

func _material_flow() -> void:
	_reset()
	var chip := _chip(14)
	var saved := manager.capture(player)
	check(sim.material_count("wood")==0 and saved.world_drops.pickups.size()==1,"uncollected yield has one world owner and no carried copy")
	chip._absorb(player)
	chip._absorb(player)
	check(sim.material_count("wood")==14,"same-frame duplicate full absorption pays once")
	check(manager.capture(player).world_drops.pickups.is_empty(),"save immediately after absorption excludes the queued chip")
	if not _apply(_roundtrip(saved),"restore released material before collection"): return
	check(sim.material_count("wood")==0 and _drops().size()==1,"restoration rewinds pack and replaces the physical set")
	for attempt in 3:
		if not _apply(saved,"repeat exact material restore "+str(attempt)): return
		check(_drops().size()==1 and sim.material_count("wood")==0,"repeated restoration never merges another copy")
	var restored := _find("material") as Pickup
	if not check(restored!=null,"restored material can be collected"): return
	player.global_position = restored.global_position-Vector3(0,.6,0)
	restored._physics_process(1.0/60.0)
	check(sim.material_count("wood")==14 and manager.capture(player).world_drops.pickups.is_empty(),"ordinary proximity collection pays the restored amount once")
	_reset()
	var cap := sim.carry_cap("wood")
	sim.add_material("wood",cap-3)
	chip = _chip(9)
	chip._absorb(player)
	chip._absorb(player)
	check(sim.material_count("wood")==cap and chip.amount==6 and not chip.is_queued_for_deletion(),"partial haul owns three in pack and six in the surviving chip")
	saved = manager.capture(player)
	if not _apply(_roundtrip(saved),"restore a partially collected chip"): return
	restored = _find("material") as Pickup
	if not check(restored!=null,"partial remainder remains a physical drop"): return
	check(sim.material_count("wood")+restored.amount==cap+6,"partial collection conserves carried plus loose quantity")
	var at := restored.global_position
	player.global_position = at-Vector3(0,.6,0)
	restored._physics_process(0.0)
	check(sim.material_count("wood")==cap and restored.amount==6 and restored.global_position==at,"full pack neither vacuums nor consumes the remainder")
	check(sim.consume_material("wood",6),"make ordinary room for the saved remainder")
	restored._physics_process(0.0)
	check(sim.material_count("wood")==cap and manager.capture(player).world_drops.pickups.is_empty(),"free capacity accepts only the six remaining units")

func _motion_and_expiry() -> void:
	_reset()
	var chip := _chip(4)
	chip._age = Pickup.MAX_AGE_SECONDS-.125
	var saved := manager.capture(player)
	if not _apply(_roundtrip(saved),"restore an airborne chip near expiry"): return
	var restored := _find("material") as Pickup
	if not check(restored!=null,"airborne chip restored"): return
	check(restored.global_position.is_equal_approx(Vector3(20,6,20)) and restored._velocity.is_equal_approx(Vector3(1.25,2.5,-.75)) and is_equal_approx(restored._floor_y,3.0),"position, trajectory and landing floor survive reload")
	check(restored._bounces==1 and not restored._resting and is_equal_approx(restored._age,Pickup.MAX_AGE_SECONDS-.125) and is_equal_approx(restored.rotation.y,.5) and is_equal_approx(restored._bob_phase,1.75) and is_equal_approx(restored._mesh.position.y,.15625),"bounce, age, phase and exact visible bob offset are retained")
	restored._physics_process(.0625)
	check(not restored.is_queued_for_deletion() and restored.global_position!=Vector3(20,6,20),"restored airborne motion continues before its remaining lifetime elapses")
	restored._physics_process(.125)
	check(restored.is_queued_for_deletion() and sim.material_count("wood")==0 and manager.capture(player).world_drops.pickups.is_empty(),"expiry consumes no inventory and does not restart its lifetime")
	_reset()
	chip = _chip(2)
	chip.global_position.y = chip._floor_y
	chip._resting = true
	chip._velocity = Vector3.ZERO
	saved = manager.capture(player)
	if not _apply(saved,"restore a resting chip"): return
	restored = _find("material") as Pickup
	if not check(restored!=null,"resting chip restored"): return
	var resting_at := restored.global_position
	restored._physics_process(.25)
	check(restored._resting and restored.global_position==resting_at and restored._velocity==Vector3.ZERO,"resting drop stays on its saved floor rather than relaunching")

func _identical_and_scoped() -> void:
	_reset()
	_chip(5)
	_chip(5)
	var saved := manager.capture(player)
	check(saved.world_drops.pickups.size()==2 and saved.world_drops.pickups[0]==saved.world_drops.pickups[1],"two genuinely identical chips are represented independently")
	if _apply(saved,"restore two identical legitimate chips"):
		for drop in _drops(): (drop as Pickup)._absorb(player)
		check(sim.material_count("wood")==10,"identical legitimate records are not deduplicated")
	_reset()
	_chip(3,"fixture_unlisted_stock")
	if _apply(manager.capture(player),"restore an open native inventory identifier"):
		var generic := _find("material") as Pickup
		if check(generic!=null,"unlisted generic stock stays physical"):
			generic._absorb(player)
			check(sim.material_count("fixture_unlisted_stock")==3,"an incomplete catalogue whitelist does not erase valid generic inventory stock")
	_reset()
	var nested := Node3D.new()
	nested.position = Vector3(8,0,-6)
	add_child(nested)
	_chip(3,"raw_clay",nested)
	var other_world := Node3D.new()
	get_tree().root.add_child(other_world)
	var foreign_chip := _chip(8,"wood",other_world)
	var foreign_pack := _bundle({"fieldstone":9},other_world)
	var doomed := Node3D.new()
	add_child(doomed)
	_chip(99,"wood",doomed)
	doomed.queue_free()
	var scoped := WorldDrops.capture(self)
	check(scoped.pickups.size()==1 and scoped.bundles.is_empty() and scoped.pickups[0].family=="raw_clay","capture includes nested owned drops but skips unrelated worlds and queued ancestor subtrees")
	var before := sim.export_json()
	WorldDrops.restore(self,scoped)
	_freeze_drops()
	check(is_instance_valid(foreign_chip) and is_instance_valid(foreign_pack) and _drops(other_world).size()==2,"restore leaves another world's pickups and death pack untouched")
	var restored := _find("material") as Pickup
	check(restored!=null and restored.global_position.is_equal_approx(Vector3(20,6,20)) and sim.export_json()==before,"nested-world positions restore in world coordinates without awards")
	other_world.free()
	nested.free()

func _select_rewards() -> bool:
	_reset()
	var elites := sim.elite_modifier_ids()
	if not check(not elites.is_empty(),"native elite definition available for exact loot test"): return false
	elite_id = String(elites[0])
	for seed_value in 512:
		# The Godot kill schedule can exceed the binding's 32-bit argument.
		# Preserve the whole original seed while retaining native claim rules.
		var candidate_seed := 4294967296+seed_value
		if not sim.enemy_gear_loot("stone_husk",candidate_seed,elite_id).is_empty():
			gear_seed = candidate_seed
			break
	for id in sim.combat_skill_ids():
		if not sim.known_skill_ids().has(id):
			page_skill = String(id)
			break
	return check(gear_seed>=4294967296 and page_skill!="","bounded native search finds a real elite gear roll and an unknown skill")

func _gear() -> Pickup:
	var previews: Array = sim.enemy_gear_loot("stone_husk",gear_seed,elite_id)
	var drop := Pickup.drop_gear(self,Vector3(25,4,20),"stone_husk",gear_seed,previews[0],3.0,elite_id)
	drop.set_physics_process(false)
	drop._age = Pickup.MAX_AGE_SECONDS+100.0
	return drop

func _page() -> Pickup:
	var drop := Pickup.drop_page(self,Vector3(27,4,20),page_skill,String(sim.combat_skill(page_skill).display_name),3.0)
	drop.set_physics_process(false)
	drop._age = Pickup.MAX_AGE_SECONDS+100.0
	return drop

func _normal_item(item: Dictionary) -> Dictionary:
	var result := item.duplicate(true)
	result.erase("index")
	return result

func _claim_gear(drop: Pickup, label: String) -> void:
	var expected: Array = sim.enemy_gear_loot(drop.enemy_id,drop.gear_seed,drop.elite_id)
	var before := sim.pack_items().size()
	drop._absorb(player)
	drop._absorb(player)
	var actual: Array = sim.pack_items()
	check(actual.size()==before+expected.size(),label+" banks the native roll once despite duplicate same-frame callbacks")
	var same := actual.size()==before+expected.size()
	if same:
		for index in expected.size(): same = same and _normal_item(actual[before+index])==_normal_item(expected[index])
	check(same,label+" matches native current-era gear, including exact rolled properties")

func _reward_flow() -> void:
	_reset()
	_gear()
	_page()
	var saved := manager.capture(player)
	var rules := sim.export_json()
	check(saved.world_drops.pickups[0].gear_seed==str(gear_seed),"gear checkpoint stores the complete original seed as decimal text")
	if not _apply(_roundtrip(saved),"restore gear and a fixed skill page"): return
	check(sim.export_json()==rules and sim.pack_items().is_empty() and not sim.known_skill_ids().has(page_skill),"restoration previews no awards or skill learning")
	var gear := _find("gear") as Pickup
	var page := _find("page") as Pickup
	if not check(gear!=null and page!=null,"both pending reward kinds remain physical"): return
	check(gear.gear_seed==gear_seed and gear.elite_id==elite_id and page.page_skill==page_skill,"gear provenance and the already-selected page survive exactly")
	gear._physics_process(.25)
	page._physics_process(.25)
	check(not gear.is_queued_for_deletion() and not page.is_queued_for_deletion(),"gear and pages retain their existing non-expiring lifetime")
	_claim_gear(gear,"restored elite gear")
	var learned_events := [0]
	var count_learning := func(): learned_events[0]+=1
	player.combat.loadout_changed.connect(count_learning)
	page._absorb(player)
	page._absorb(player)
	player.combat.loadout_changed.disconnect(count_learning)
	check(sim.known_skill_ids().has(page_skill) and learned_events[0]==1,"the fixed saved page teaches once on collection")
	check(manager.capture(player).world_drops.pickups.is_empty(),"claimed gear and page cannot reappear in an immediate snapshot")

func _bundle_flow() -> void:
	_reset()
	sim.add_materials({"wood":7,"raw_clay":3,"vanguard":1})
	var currency_before := sim.currency().duplicate(true)
	player._on_died()
	var bundle := _find("bundle") as DroppedBundle
	if not check(bundle!=null,"ordinary open-world death creates a recoverable physical pack"): return
	check(bundle.contents=={"wood":7,"raw_clay":3} and sim.inventory().is_empty() and sim.currency()==currency_before,"death transfers materials once and leaves the purse protected")
	var saved := manager.capture(player)
	bundle.interact(player)
	bundle.interact(player)
	check(sim.material_count("wood")==7 and sim.material_count("raw_clay")==3 and manager.capture(player).world_drops.bundles.is_empty(),"same-frame recovery is once-only and its emptied pack is unsaved")
	if not _apply(_roundtrip(saved),"restore the unclaimed death pack"): return
	bundle = _find("bundle") as DroppedBundle
	if not check(bundle!=null,"saved death pack remains interactable"): return
	check(sim.inventory().is_empty() and bundle.contents=={"wood":7,"raw_clay":3},"saved materials have a single death-pack owner")
	bundle.interact(player)
	check(sim.material_count("wood")==7 and sim.material_count("raw_clay")==3 and sim.currency()==currency_before,"restored death pack recovers the exact original contents")

func _node_ids(root: Node = null) -> Array:
	if root == null: root = self
	var ids: Array = [root.get_instance_id()]
	for child in root.get_children(): ids.append_array(_node_ids(child))
	return ids

func _reject(saved: Dictionary, label: String) -> void:
	var rules := sim.export_json()
	var drops := WorldDrops.capture(self)
	var nodes := _node_ids()
	var pose := player.global_transform
	check(not manager.apply(player,saved),label+" rejects the entire save")
	check(sim.export_json()==rules and WorldDrops.capture(self)==drops and _node_ids()==nodes and player.global_transform==pose,label+" leaves rules, all nodes, physical ownership and pose untouched")

func _malformed_payloads() -> void:
	_reset()
	_chip(7)
	_gear()
	_page()
	_bundle({"raw_clay":3})
	var saved := manager.capture(player)
	# The live state deliberately differs from the target, proving rejection
	# happens before native import or removal of any existing world nodes.
	sim.add_material("wood",5)
	_chip(2,"fieldstone")
	player.global_position += Vector3(2,0,1)
	var changes: Array = [
		["kind","unknown"],["position",[1,2]],["position",[1,NAN,3]],
		["velocity",[INF,0,0]],["floor_y",INF],["yaw",NAN],["mesh_y",INF],
		["bounces",1.5],["bounces",-1],["resting",1],
		["age",-.1],["age",INF],["bob_phase",NAN],
		["family",""],["amount",0],["amount",-1],
		["amount",1.5],["amount",2147483648],
	]
	for change in changes:
		var bad := saved.duplicate(true)
		var record: Dictionary = bad.world_drops.pickups[0].duplicate(true)
		record[change[0]] = change[1]
		bad.world_drops.pickups.append(record)
		_reject(bad,"late malformed material "+str(change[0])+"="+str(change[1]))
	for change in [["enemy_id","missing_enemy"],["elite_id","missing_elite"],["gear_seed","9223372036854775808"],["gear_seed","-9223372036854775809"],["gear_seed","01"],["gear_seed",1.5]]:
		var bad := saved.duplicate(true)
		var record: Dictionary = bad.world_drops.pickups[1].duplicate(true)
		record[change[0]] = change[1]
		bad.world_drops.pickups.append(record)
		_reject(bad,"late malformed gear "+str(change[0])+"="+str(change[1]))
	var bad_page := saved.duplicate(true)
	bad_page.world_drops.pickups.append({"kind":"page","page_skill":"missing_skill"})
	_reject(bad_page,"late incomplete page")
	bad_page = saved.duplicate(true)
	bad_page.world_drops.pickups[2].page_skill = "missing_skill"
	_reject(bad_page,"unknown saved page skill")
	for contents in [{"wood":0},{"wood":-1},{"wood":1.5},{"wood":2147483648},{"":1}]:
		var bad := saved.duplicate(true)
		var record: Dictionary = bad.world_drops.bundles[0].duplicate(true)
		record.contents = contents
		bad.world_drops.bundles.append(record)
		_reject(bad,"late invalid death-pack contents "+str(contents))
	for payload in [null,[],{"version":2,"pickups":[],"bundles":[]},{"version":1,"pickups":{},"bundles":[]}]:
		var bad := saved.duplicate(true)
		bad.world_drops = payload
		_reject(bad,"unsupported or malformed world-drop container "+str(payload))

func _legacy_and_disk() -> void:
	_reset()
	_chip(4)
	_bundle({"wood":3})
	var saved := manager.capture(player)
	var legacy := saved.duplicate(true)
	legacy.erase("world_drops")
	if _apply(legacy,"legacy schema-two payload without drop records"):
		check(_drops().is_empty() and sim.material_count("wood")==0,"legacy absence means empty saved set, clearing stale chips and packs without inventing stock")
	var path := ProjectSettings.globalize_path(DISK_PROBE)
	var pending := path+".pending"
	check(manager.write_data(path,saved),"write isolated last-good disk save")
	var original := FileAccess.get_file_as_string(path)
	# A directory at the exact staging filename forces a write-open failure
	# before replacement. Only this fixture-created empty directory is removed.
	var made := DirAccess.make_dir_absolute(pending)
	if check(made==OK,"create bounded staging-path obstruction"):
		check(not manager.write_data(path,legacy),"expected failed staged write reports failure")
		check(FileAccess.get_file_as_string(path)==original,"failed staged write leaves the original complete save unchanged")
		check(DirAccess.remove_absolute(pending)==OK,"remove only the fixture's empty staging obstruction")
	check(manager.read(path,player),"last-good save remains readable after write failure: "+manager.last_error)
	_freeze_drops()
	check(_drops().size()==2 and sim.material_count("wood")==0,"disk recovery restores physical owners without collection")

func _write_checkpoint() -> void:
	_reset()
	_chip(7)
	_gear()
	_page()
	_bundle({"fieldstone":3,"raw_clay":2})
	var saved := manager.capture(player)
	saved["checkpoint_probe"] = {"gear_seed":str(gear_seed),"elite_id":elite_id,"page_skill":page_skill,"expected_pickups":3,"expected_bundles":1}
	var path := ProjectSettings.globalize_path(CHECKPOINT)
	check(manager.write_data(path,saved),"write physical material, gear, page and death pack for a fresh process")
	check(sim.material_count("wood")==0 and sim.pack_items().is_empty() and not sim.known_skill_ids().has(page_skill),"checkpoint writing grants nothing")
	print("LOOSE_DROP_CHECKPOINT_WRITTEN ",path)

func _read_checkpoint() -> void:
	var path := ProjectSettings.globalize_path(CHECKPOINT)
	if not check(FileAccess.file_exists(path),"fresh process has an explicit isolated checkpoint file"): return
	var saved: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not check(saved is Dictionary and saved.get("checkpoint_probe") is Dictionary,"checkpoint includes fixture expectations"): return
	var probe: Dictionary = saved.checkpoint_probe
	check(_drops().is_empty() and sim.pack_items().is_empty() and sim.material_count("wood")==0,"new process begins without in-memory drops or awarded stock")
	if not check(manager.read(path,player),"fresh process restores checkpoint: "+manager.last_error): return
	_freeze_drops()
	var payload := WorldDrops.capture(self)
	check(payload.pickups.size()==int(probe.expected_pickups) and payload.bundles.size()==int(probe.expected_bundles),"all four physical ownership records survive process restart")
	var chip := _find("material") as Pickup
	var gear := _find("gear") as Pickup
	var page := _find("page") as Pickup
	var bundle := _find("bundle") as DroppedBundle
	if not check(chip!=null and gear!=null and page!=null and bundle!=null,"restored nodes retain their normal interaction classes"): return
	check(chip.amount==7 and is_equal_approx(chip._age,31.25) and chip._velocity.is_equal_approx(Vector3(1.25,2.5,-.75)),"fresh-process material retains amount, elapsed age and motion")
	check(gear.gear_seed==int(probe.gear_seed) and gear.elite_id==probe.elite_id and page.page_skill==probe.page_skill and bundle.contents=={"fieldstone":3,"raw_clay":2},"fresh-process reward provenance and death-pack contents are exact")
	check(sim.material_count("wood")==0 and sim.pack_items().is_empty() and not sim.known_skill_ids().has(String(probe.page_skill)),"restart restores physical rewards without awarding them")
	chip._absorb(player)
	_claim_gear(gear,"fresh-process gear")
	page._absorb(player)
	bundle.interact(player)
	check(sim.material_count("wood")==7 and sim.material_count("fieldstone")==3 and sim.material_count("raw_clay")==2 and sim.known_skill_ids().has(String(probe.page_skill)),"normal collection after restart grants exactly the saved materials and fixed page")
	check(WorldDrops.capture(self).pickups.is_empty() and WorldDrops.capture(self).bundles.is_empty(),"collected restart rewards leave no second world owner")
	print("LOOSE_DROP_CHECKPOINT_READ ",path)
