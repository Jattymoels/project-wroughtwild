extends "res://tests/laboratory_repeat_loop.gd"
## INT-18A: matched complete attempts. Inherited forced fixtures are never called.
const OUT := "res://../build/int18-a/"
var case_id := "baseline"
var kit := "rough"
var evidence_id := ""
var payments: Array = []

var save_path := ""
var receipt: Dictionary = {}
var preparation: Dictionary = {}
var damage_events: Array = []
var campaign_before: Array = []
var monitoring := false
var live_clock := 0.0
var travelled := 0.0
var last_position := Vector3.ZERO

func quiet_pairing() -> void:
	# Isolate archived world ownership, never grant route-fixture immunity.
	world.set_physics_process(false)
	world.mob_packs.set_physics_process(false)
	player.placement.set_physics_process(false)
	trial.set_process(false) # Tick once per physical frame, including gallery travel.
	for pickup in get_tree().get_nodes_in_group("pickups"): pickup.set_physics_process(false)

func _physics_process(delta: float) -> void:
	if not monitoring: return
	if trial.active():
		live_clock += delta
		travelled += player.global_position.distance_to(last_position)
		check(player.combat.invulnerable_left <= 0.0, "no injected or dash immunity during the attempt")
		check(player.combat.is_physics_processing(), "combat clocks remain live between rooms")
		check(trial.trial_enemies().size() <= 24 && trial._hazards().size() <= 2, "live population and hazard caps")
		trial._process(delta)
	last_position = player.global_position

func _run() -> void:
	Engine.physics_ticks_per_second = 60
	Engine.max_physics_steps_per_frame = 64
	Engine.time_scale = 1.0
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--case="): case_id = argument.trim_prefix("--case=")
		if argument.begins_with("--kit="): kit = argument.trim_prefix("--kit=")
	if not check(case_id in ["baseline", "crossfire", "relentless_boss"], "bounded pressure case"): return finish_pressure()
	if not check(kit in ["rough", "sound", "ember", "control"], "ordinary preparation cohort"): return finish_pressure()
	evidence_id = (kit + "-" if kit != "rough" else "") + case_id
	save_path = "user://int18-" + evidence_id + ".json"
	selected_pressure = "" if case_id == "baseline" else case_id
	sim = load("res://scripts/sim.gd").shared()
	world = preload("res://scenes/sandpit.tscn").instantiate()
	world.scene_file_path = ""; world.world_profile = "living_frontier_wave3"; world.world_seed = 77
	get_tree().root.add_child(world); get_tree().current_scene = world
	player = world.player; trial = player.trial; arena = world.get_node("TrialArena")
	quiet_pairing()
	if "--restart" in OS.get_cmdline_user_args() or "--preentry" in OS.get_cmdline_user_args():
		await recover_pressure()
		return finish_pressure()
	var packed := FileAccess.get_file_as_bytes("res://tests/fixtures/lf6-published-ending.json.gz")
	var archive := packed.decompress_dynamic(16000000, FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(archive); file.close()
	if not check(player.load_game(save_path), "published ending fixture loads without modifying the owner's save"): return finish_pressure()
	quiet_pairing()
	prepare_paid_build()
	if failures: return finish_pressure()
	preparation = {"native_sha256": sim.export_json().sha256_text(), "kit":kit, "payments":payments, "equipment": sim.equipment(), "pack": sim.pack_items(), "stats": sim.derived_stats(), "bar": Array(sim.skill_bar()), "plate": sim.foundry().plate}
	before_world = SaveManager.new().capture(player)
	campaign_before = [sim.resonance_json(), sim.resonance_second_json()]
	check(player.save_game(save_path), "save identical paid preparation")
	await reach_central(); player.interact(); await press_button("Configure experiment")
	# First slot compatible with BOTH pressures, selected before any combat.
	var cross := sim.trial_map_offers(1, "crossfire")
	var relentless := sim.trial_map_offers(1, "relentless_boss")
	var slot := -1
	for i in cross.size():
		if cross[i].available and relentless[i].available: slot = i; break
	if not check(slot >= 0, "same saved offer accepts both pressures"): return finish_pressure()
	await press_button({"baseline":"No extra pressure", "crossfire":"Crossfire", "relentless_boss":"Relentless Boss"}[case_id])
	selected_offer = sim.trial_map_offers(1, selected_pressure)[slot].duplicate(true)
	selected_offer.slot = slot
	player.work_panel.close_panel()
	check(player.save_game(save_path), "pre-entry checkpoint preserves unopened batch")
	check(SaveManager.new().write_data(save_path + ".preentry", SaveManager.new().capture(player)), "retain pre-entry crash recovery fixture")
	var entry_bytes := FileAccess.get_file_as_bytes(save_path)
	player.interact(); await press_button("Configure experiment")
	await press_button({"baseline":"No extra pressure", "crossfire":"Crossfire", "relentless_boss":"Relentless Boss"}[case_id])
	run_inventory = sim.inventory().duplicate(true); run_currency = sim.currency().duplicate(true); run_items = sim.pack_items().size()
	var old_gate: String = JSON.parse_string(sim.export_json()).extra.trial_gate
	await press_button("Enter run %d" % (slot + 1))
	if not check(trial.active(), "physical controls enter configured attempt"): return finish_pressure()
	check(trial.layout.run_id == selected_offer.id and trial.layout.pressure == selected_pressure and trial.layout.conditions == selected_offer.conditions, "entry freezes exact previewed configuration")
	check(JSON.parse_string(sim.export_json()).extra.trial_gate != old_gate, "entry consumes the saved batch once")
	check(not player.save_game(save_path) and FileAccess.get_file_as_bytes(save_path) == entry_bytes, "active attempt cannot replace pre-entry recovery checkpoint")
	bot = load("res://tests/laboratory_experiment_combat.gd").new()
	bot.player = player; bot.combat = player.combat; bot.sim = sim; bot.trial = trial; bot.ranged = false
	bot.cohort = "archived_melee/iron_mace_bronze_mail/paid_recovery"
	player.combat.fight_seed_source.seed = 741103
	player.combat.hit_taken.connect(func(damage: float, source: String):
		if monitoring: damage_events.append({"time":live_clock,"stage":trial.current_stage_index,"damage":damage,"source":source,"life_after":player.combat.life})
		if bot.probing: bot.sample.damage_taken += damage)
	player.combat.skill_committed.connect(func(_id: StringName):
		if bot.probing: bot.sample.casts += 1)
	player.combat.hit_landed.connect(func(damage: float, _kills: int, _types: PackedStringArray):
		if bot.probing: bot.sample.direct_hit_damage += damage)
	player.combat.died.connect(func():
		if bot.probing: bot.sample.died = true; bot.sample.minimum_life_fraction = 0.0)
	player.combat.set_physics_process(true)
	monitoring = true; last_position = player.global_position
	await _settle_player(); await _settle_navigation(arena.dungeon)
	if not await _reach(arena.dungeon.secret, "optional physical secret"): return finish_pressure()
	player.interact()
	check(sim.trial_loot() == selected_offer.secret_materials, "secret exactly matches pressure preview")
	var secret_once := sim.trial_loot().duplicate(true)
	player.interact(); check(sim.trial_loot() == secret_once, "physical secret cannot pay twice")
	var outcome := "incomplete"
	for stage in 5:
		var marker: TrialFixture
		for fixture: TrialFixture in arena.dungeon.fixtures:
			if fixture.fixture_kind == "route" and fixture.stage_index == stage: marker = fixture
		if not check(marker != null, "physical room route exists") or not await _reach(marker, "live room " + str(stage + 1)): return finish_pressure()
		var entering_life := player.combat.life
		if stage > 0: check(is_equal_approx(entering_life,float(live_samples[-1].life_after_reward)), "next room carries previous reward's life without a reset")
		player.interact()
		if not check(trial.state == "fighting", "E begins real encounter"): return finish_pressure()
		var started := live_clock
		await fight_live(stage)
		var row: Dictionary = live_samples[-1]
		row.life_entering = entering_life; row.life_after_combat = 0.0 if row.died else player.combat.life
		if row.died: row.life_after_ordinary_respawn = player.combat.life
		row.run_start_seconds = started; row.boss_tells = trial.boss_tells
		check(row.casts > 0, "attempt uses actual committed skills")
		check(int(row.get("floor_rescue_frames",0)) == 0, "combat remains on connected physical floor without rescue")
		if row.died: outcome = "death"; break
		if not row.cleared:
			outcome = "timeout"; break
		if not await _reach(arena.dungeon.reward, "live earned offering " + str(stage + 1)): return finish_pressure()
		row.life_at_reward = player.combat.life
		row.reward = trial._pending_outcome.duplicate(true)
		if stage == 1: check(row.reward.materials == selected_offer.cache_materials, "real cache exactly matches preview")
		if stage == 3: check(row.reward.reward_type == "equipment" and not row.reward.catalyst_recovered, "LF equipment cache has no guaranteed Catalyst")
		if stage == 4: check(row.reward.materials == selected_offer.completion_components, "boss pays exact previewed core")
		player.interact()
		if not trial.current_offer.is_empty():
			row.boon_offers = trial.current_offer.duplicate(true)
			await press_button("Accept") # Same first offered boon policy in all cases.
		await frames(3)
		row.life_after_reward = player.combat.life
		if stage == 4: outcome = "victory"
	monitoring = false
	receipt = {"case":case_id,"outcome":outcome,"offer":record_offer(selected_offer),"preparation":preparation,"rooms":live_samples,"damage_events":damage_events,"run_seconds":live_clock,"combat_and_gallery_metres":travelled,"approach_and_gallery_metres":walked_metres,"combat_seed":741103}
	if outcome == "timeout":
		# No forced settlement. Preserve the honest unfinished attempt and pre-entry disk.
		check(FileAccess.get_file_as_bytes(save_path) == entry_bytes, "timeout preserves pre-entry disk")
		return finish_pressure()
	if not check(not trial.active() and not player.experiment_save_pending, "live outcome automatically settles and saves"): return finish_pressure()
	if outcome == "victory": check_rewards()
	else:
		check_material_sum(run_inventory, run_currency, {}, "natural death returns deposits, loses unbanked rewards")
		check(sim.pack_items() == preparation.pack, "natural death retains every owned item without unbanked gear")
		check(int(sim.trial_map_progress().max_tier) == 1, "death cannot unlock next tier")
	check_campaign()
	var saved := SaveManager.new().capture(player)
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(save_path))
	check(JSON.parse_string(disk.sim) == JSON.parse_string(sim.export_json()), "automatic save owns exact native result")
	check_preserved(before_world, saved)
	receipt.settlement = {"native_sha256":String(disk.sim).sha256_text(),"inventory":sim.inventory(),"currency":sim.currency(),"pack":sim.pack_items(),"gate":sim.trial_map_progress(),"offers":record_offers(sim.trial_map_offers(1)),"checkpoint_ms":player.get_meta("last_experiment_checkpoint_ms",-1)}
	check(player.load_game(save_path), "ordinary load restores settled attempt")
	quiet_pairing(); check(JSON.parse_string(sim.export_json()) == JSON.parse_string(disk.sim), "ordinary load exact rewards and gate")
	check_preserved(saved, SaveManager.new().capture(player)); check_campaign()
	await snapshot_pressure("return")
	finish_pressure()

func check_campaign() -> void:
	check([sim.resonance_json(), sim.resonance_second_json()] == campaign_before, "both exact terrain ledgers unchanged")
	check(sim.world_effect_active("forge_arc_complete") and int(sim.era().index) == 3 and not sim.trial_start_story(77,"forge_capstone"), "human ending remains once-only in era three")

func recover_pressure() -> void:
	var preentry := "--preentry" in OS.get_cmdline_user_args()
	var path := save_path + ".preentry" if preentry else save_path
	var result_path := OUT + evidence_id + ".json"
	receipt = JSON.parse_string(FileAccess.get_file_as_string(result_path))
	if not check(player.load_game(path), "fresh process loads " + path): return
	quiet_pairing()
	var disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	check(JSON.parse_string(sim.export_json()) == JSON.parse_string(disk.sim), "fresh process retains exact native ownership/configuration")
	check_preserved(disk, SaveManager.new().capture(player))
	if preentry:
		check(record_offer(sim.trial_map_offers(1,selected_pressure)[int(receipt.offer.slot)]) == without_slot(receipt.offer), "pre-entry recovery restores identical unconsumed configuration")
	else:
		check(String(disk.sim).sha256_text() == receipt.settlement.native_sha256, "fresh result matches independent recorded settlement hash")
		check(record_offers(sim.trial_map_offers(1)) == receipt.settlement.offers, "next batch survives fresh process without reroll")
	check(sim.world_effect_active("forge_arc_complete") and int(sim.era().index) == 3, "fresh process retains ending/era")
	await reach_central(); player.interact(); await press_button("Configure experiment")
	check(int(sim.trial_map_progress().last_tier) == 1, "saved selected tier is one")
	await press_button("No extra pressure")
	var next_offer: Dictionary = sim.trial_map_offers(1)[0]
	if not preentry: check(next_offer.id != receipt.offer.id, "new batch differs from consumed offer")
	# Prove usability in a disposable continuation; never replace the evidence save.
	player.set_meta("active_world_save_path", "user://int18-next-" + evidence_id + ("-preentry" if preentry else "") + ".json")
	await press_button("Enter run 1")
	check(trial.active() and trial.layout.run_id == next_offer.id, "next offer actually enters through physical UI")
	await _settle_player(); await _settle_navigation(arena.dungeon)
	if await _reach(arena.dungeon.boundary, "unused next-batch physical exit"):
		player.interact(); await press_button("Abandon experiment")
	check(not trial.active() and not player.experiment_save_pending, "unused next offer abandons and checkpoints normally")

func without_slot(value: Dictionary) -> Dictionary:
	var copy := value.duplicate(true); copy.erase("slot"); return copy

func record_offer(value: Dictionary) -> Dictionary:
	# Godot JSON parses numeric seeds through binary64. Keep all 64 bits as text,
	# and normalise PackedStringArray before comparing separately parsed receipts.
	var copy := value.duplicate(true); copy.seed = str(value.seed)
	return JSON.parse_string(JSON.stringify(copy,"",true,true))

func record_offers(values: Array) -> Array:
	var result: Array = []
	for value: Dictionary in values: result.append(record_offer(value))
	return result

func snapshot_pressure(label: String) -> void:
	if "--visuals" not in OS.get_cmdline_user_args(): return
	await reach_central(); player.interact(); await press_button("Configure experiment")
	for i in 8: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT + evidence_id + "-" + label + ".png")

func finish_pressure() -> void:
	monitoring = false
	if is_instance_valid(bot): bot.free()
	var suffix := "-preentry" if "--preentry" in OS.get_cmdline_user_args() else ("-restart" if "--restart" in OS.get_cmdline_user_args() else "")
	if suffix.is_empty():
		receipt.checks = checks; receipt.failures = failures
		receipt.limits = "Synthetic archived ending and earned-ingot events; supplied ordinary inputs/facilities; historical classless melee bar. Paid recipes and exchange. World, ambient spawns and pickup age frozen for ownership comparison; initial travel to Central compressed. Physical capsule navigation and E rays inside all rooms; state-reading bot at 60 Hz, no forced outcomes, life reset or immunity; combat clocks stay live in gallery. Fixed first-boon policy. Not a fresh campaign or human balance acceptance."
	else: receipt = {"case":case_id,"mode":suffix,"checks":checks,"failures":failures}
	var file := FileAccess.open(OUT + evidence_id + suffix + ".json", FileAccess.WRITE)
	file.store_string(JSON.stringify(receipt,"  ",true,true)); file.close()
	print("INT18_ATTEMPT ", case_id, suffix, " ", checks, " checks, ", failures, " failures; outcome=", receipt.get("outcome","recovery"))
	get_tree().quit(1 if failures else 0)

func prepare_paid_build() -> void:
	sim.add_materials({"iron_ingot":30,"bronze_ingot":20,"charcoal":20,"hide":20,"wood":20})
	sim.add_station("forge_basic");sim.add_station("forge_improved")
	if kit == "sound":
		# This diagnostic buys only the existing Sound equipment grade.
		# No XP injection, reroll selection or new combat rule.
		sim.add_materials({"iron_ingot":4,"bog_iron":2,"charcoal":4})
		for i in 2: check(bool(paid_craft("work_sound_iron").crafted), "pay ordinary graded iron refinement")
	for recipe in ["iron_mace","bronze_mail"]:
		var crafted:=paid_craft(recipe, 2 if kit == "sound" else 1)
		check(bool(crafted.get("crafted",false)),"paid ordinary prepared kit: "+recipe)
		if bool(crafted.get("crafted",false)):check(sim.equip_pack_item(sim.pack_items().size()-1),"equip paid "+recipe)
	check(bool(sim.temper_basic().get("applied",false)),"ordinary fire-resistance temper without a Catalyst")
	# A deliberate ordinary Catalyst purchase, not an intact-find shortcut.
	# The separate all-paid field journey obtains these same inputs itself.
	sim.add_materials({"red_salt":96,"iron_ingot":4,"charcoal":8})
	var salt_before:=sim.material_count("red_salt")
	var catalysts_before:=sim.material_count("ember_catalyst")
	check(bool(paid_craft("forge_faint_ember").get("crafted",false)),"ordinary costly Ember manufacture for the prepared run")
	check(sim.material_count("red_salt")==salt_before-96 && sim.material_count("ember_catalyst")==catalysts_before+1,"crafted Catalyst pays the full raw-material price")
	sim.add_materials({"silver_ingot":3,"hide":6,"charcoal":6})
	for i in sim.exchange_rate():check(bool(paid_craft("cast_marrow").get("crafted",false)),"pay ordinary Marrow manufacture")
	check(sim.exchange("marrow","sipping_marrow"),"pay three-for-one recovery Kind exchange")
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer","recipe:workbench_kit","first_kill:stone_husk","world_effect:stonecut_blocks","first_kill:ash_hound"]:sim.foundry_event(event)
	check(sim.foundry_place_skill(1,1,String(sim.skill_bar()[0])),"place existing primary skill on earned plate")
	check(sim.foundry_place(1,0,"vigour") && sim.foundry_place(2,1,"edge"),"ordinary Vigour/Edge ingots prepare the existing recovery build")
	check(sim.foundry_place_kind(2,0,"sipping_marrow"),"newly manufactured and exchanged Marrow works the persistent route")
	check(sim.foundry_place_skill(2,2,String(sim.skill_bar()[1])),"second existing attack joins the same paid recovery route")
	if kit in ["ember", "control"]:
		check(sim.foundry_place_kind(3,1,"ember_catalyst"), "place one ordinarily manufactured Faint Ember beside the shared Edge route")
	if kit == "control":
		check(sim.foundry_place(3,2,"frost"), "owned Frost support lends chill/Steambrand to the second attack")
		check(sim.foundry_place(1,2,"plate"), "owned Plate supports both attacks with existing on-cast protection")
		check(sim.foundry_place(0,1,"ward"), "owned Ward supports the first attack with existing status defence")

func paid_craft(id: String, quality := 1) -> Dictionary:
	var preview := sim.craft_preview(id, "", quality)
	var inventory := sim.inventory().duplicate(true)
	var purse := sim.currency().duplicate(true)
	var result := sim.craft(id, false, "", quality)
	payments.append({"recipe":id,"quality":quality,"costs":preview.costs,"fuel_heat":preview.fuel,"before_inventory":inventory,"after_inventory":sim.inventory(),"before_purse":purse,"after_purse":sim.currency(),"result":result})
	return result

func fight_live(stage:int) -> void:
	bot.sample={"stage":stage,"elapsed_seconds":0.0,"died":false,"damage_taken":0.0,"casts":0,"kills":0,"direct_hit_damage":0.0,"minimum_life_fraction":1.0,"remaining_enemy_life":0.0,"max_live_enemies":0,"boss_min_distance_m":999.0,"boss_max_distance_m":0.0,"boss_chase_stalled_seconds":0.0}
	bot.seen.clear();bot.decision_left=0;bot.probing=true
	var room:Dictionary=arena.dungeon.rooms["%d:0"%stage]
	var path:=arena.dungeon.path(player.global_position,arena.dungeon.to_global(room.centre+Vector3(0,0,7)))
	var path_index:=0
	var pursuit:=PackedVector3Array()
	var pursuit_clock:=0
	while bot.sample.elapsed_seconds<180 && not bot.sample.died && trial.state=="fighting":
		bot._physics_process(1.0/60)
		bot.sample.max_major_hazards = maxi(int(bot.sample.get("max_major_hazards",0)),trial._hazards().size())
		bot.sample.last_live_reserves = trial.wave_queue.size()
		var immediate_danger:=false
		for foe:Enemy in trial.trial_enemies():
			if foe is Boss && foe.state=="inhale":immediate_danger=true
		for hazard in trial._hazards():
			if hazard.global_position.distance_to(player.global_position)<4.2:immediate_danger=true
		if path_index<path.size() && not immediate_danger:
			var to:Vector3=(path[path_index]-player.global_position)*Vector3(1,0,1)
			if to.length()<.6:path_index+=1
			else:
				var local:=player.global_basis.inverse()*to.normalized();player.test_walk=Vector2(local.x,local.z)
		elif path_index>=path.size() and not immediate_danger:
			# The isolated open-room bot steers directly at targets. The full
			# laboratory also has real cabinets/cover: follow native floor paths
			# to a distant target without overriding an immediate danger escape.
			var foes:=trial.trial_enemies()
			var nearest:Enemy
			var distance:=INF
			var danger:=false
			for foe:Enemy in foes:
				var gap:=player.global_position.distance_to(foe.global_position)
				if gap<distance:nearest=foe;distance=gap
				if foe is Boss && foe.state=="inhale":danger=true
			for hazard in trial._hazards():
				if hazard.global_position.distance_to(player.global_position)<4.2:danger=true
			pursuit_clock-=1
			if is_instance_valid(nearest) && distance>3.0 && not danger:
				if pursuit_clock<=0:
					pursuit=arena.dungeon.path(player.global_position,nearest.global_position);pursuit_clock=12
				while not pursuit.is_empty() && ((pursuit[0]-player.global_position)*Vector3(1,0,1)).length()<.6:pursuit.remove_at(0)
				if not pursuit.is_empty():
					var direction:Vector3=(pursuit[0]-player.global_position)*Vector3(1,0,1)
					var local:=player.global_basis.inverse()*direction.normalized();player.test_walk=Vector2(local.x,local.z)
		check(trial.trial_enemies().size()<=24 && trial._hazards().size()<=2,"live population and hazard cap")
		await frames(1)
	bot.probing=false;player.test_walk=Vector2.ZERO
	bot.sample.cleared=trial.state=="reward" && not bot.sample.died
	if bot.sample.died:
		# Normal death tears down the encounter before this continuation. Retain
		# the last live tick rather than falsely reporting that enemies were dead.
		bot.sample.enemy_life_before_final_tick = bot.sample.remaining_enemy_life
		bot.sample.erase("remaining_enemy_life")
	else:
		bot.sample.remaining_enemy_life=0.0
		for foe:Enemy in trial.trial_enemies():bot.sample.remaining_enemy_life+=foe.life
	live_samples.append(bot.sample.duplicate(true))
	print("INT18_FULL_ROOM ",JSON.stringify(bot.sample))
