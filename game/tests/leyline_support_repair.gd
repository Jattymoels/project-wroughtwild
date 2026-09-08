extends "res://tests/living_frontier_flow.gd"
## Paid finite timber repairs and full-checkpoint recovery; no source grants.
const HOSTS := ["red_home_margin", "white_home_margin"]
const PHASES := ["undermined", "partial", "released", "formation"]

func host(id: String) -> LeylineSource:
	for node in get_tree().get_nodes_in_group("leyline_sources"):
		if node.source_id == id: return node
	return null

func path_for(id: String, phase: String) -> String:
	return "user://lf1-repair-" + id + "-" + phase + ".json"

func settled() -> void:
	for i in 3: await get_tree().physics_frame

func repair(source: LeylineSource) -> PlacedBlock:
	var cell := Vector3i(floori(source.position.x), floori(source.position.y)-1, floori(source.position.z))
	var before := _sim().material_count("wood")
	var paid := _sim().pay_placement("cube", "wood")
	check(paid and _sim().material_count("wood") < before, source.source_id+" ordinary timber payment")
	var block := player.placement.place_piece({"kind":"volume","axis":0,"cell":cell*2},"cube","wood") if paid else null
	await settled()
	check(block != null and source.supported(), source.source_id+" paid physical repair restores use at original anchor")
	return block

func refuse(source: LeylineSource, label: String) -> void:
	await aim_at(source)
	source.interact(player)
	var before := _sim().leyline_save()
	var inventory := _sim().inventory().duplicate(true)
	check(not source.supported() and not source._can_act(), label+" unsupported eligibility")
	source._work()
	source._collect(String(source.state().material))
	check(_sim().leyline_save()==before and _sim().inventory()==inventory,label+" work and collection refuse without mutation")
	player.work_panel.close_panel()

func save_phase(source: LeylineSource, phase: String) -> void:
	player.work_panel.close_panel()
	var manager := SaveManager.new()
	check(manager.write(path_for(source.source_id,phase),player),source.source_id+" saves "+phase+": "+manager.last_error)

func tick_sources(seconds: float) -> void:
	var blocked := PackedStringArray()
	for source in get_tree().get_nodes_in_group("leyline_sources"):
		if not source.supported(): blocked.append(source.source_id)
	_sim().leyline_tick(seconds,blocked)

func _run_lf() -> void:
	if "--repair-restore" in OS.get_cmdline_user_args():
		await restart_cases()
		return _finish_lf()
	if not await gather("wood",80): return _finish_lf()
	for id: String in HOSTS:
		var source := host(id)
		await aim_at(source)
		var anchor := source.global_position
		check(source.supported(),id+" starts on supported terrain")
		source.interact(player)
		source._work()
		check(source.state().work==1,id+" partial work exists")
		var ledger := _sim().leyline_save()
		var cell := Vector3i(floori(anchor.x),floori(anchor.y)-1,floori(anchor.z))
		check(terrain.break_block(cell.x,cell.y,cell.z)=="surface",id+" ordinary hand-diggable excavation")
		await settled()
		await refuse(source,id+" excavated partial work")
		await save_phase(source,"undermined")
		var block := await repair(source)
		check(_sim().leyline_save()==ledger and source.global_position==anchor,id+" repair keeps partial work, outcomes and anchor exact")
		await save_phase(source,"partial")
		await aim_at(source)
		source.interact(player)
		for step in 3: source._work()
		check(source.state().claim.get(source.state().material,0)==16,id+" repaired partial work completes its original lot")
		ledger = _sim().leyline_save()
		check(player.placement.remove_piece(block),id+" remove paid support normally")
		await settled()
		await refuse(source,id+" released claim unsupported")
		block = await repair(source)
		check(_sim().leyline_save()==ledger,id+" repeated repair keeps released claim exact")
		# Real paid geometry in the workspace must still reject, even with a
		# supporting top face. Native placement is used to isolate this predicate.
		check(_sim().pay_placement("cube","wood"),id+" workspace obstruction paid")
		var obstruction := player.placement.place_piece({"kind":"volume","axis":0,"cell":(cell+Vector3i.UP)*2},"cube","wood")
		await settled()
		await refuse(source,id+" workspace obstruction")
		check(player.placement.remove_piece(obstruction),id+" clear workspace")
		await settled()
		check(source.supported() and _sim().leyline_save()==ledger,id+" workspace clearance restores same released claim")
		await save_phase(source,"released")
		await aim_at(source)
		source.interact(player)
		for lot in 8:
			for item: String in source.state().claim.keys(): source._collect(item)
			if int(source.state().lot)==8: break
			for step in 4: source._work()
		check(source.state().claim.is_empty() and source.state().lot==8,id+" all original lots actually collected")
		tick_sources(123)
		check(source.state().formation==123,id+" formation credit starts normally")
		check(player.placement.remove_piece(block),id+" undermine forming host")
		await settled()
		tick_sources(1000)
		check(source.state().formation==600 and source.state().manifestation==0,id+" unsupported formation caps without refill")
		await save_phase(source,"formation")
		ledger = _sim().leyline_save()
		block = await repair(source)
		check(_sim().leyline_save()==ledger,id+" paid repair retains full formation credit")
		tick_sources(.01)
		check(source.state().manifestation==1 and source.state().formation==0,id+" valid repair releases exactly one earned formation")
		print("LF1_REPAIR ",id," partial/claim/obstruction/formation verified; anchor=",anchor)
	_finish_lf()

func restart_cases() -> void:
	var manager := SaveManager.new()
	for id: String in HOSTS:
		for phase: String in PHASES:
			var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path_for(id,phase)))
			check(manager.read(path_for(id,phase),player),id+" fresh process restores "+phase+": "+manager.last_error)
			await settled()
			check(_sim().leyline_save()==saved.leylines,id+" "+phase+" exact source ledger after restart")
			check(JSON.parse_string(_sim().export_json())==JSON.parse_string(saved.sim),id+" "+phase+" exact player state after restart")
			var source := host(id)
			if phase in ["undermined","formation"]:
				await refuse(source,id+" saved "+phase)
				await repair(source)
			else: check(source.supported(),id+" saved paid support remains usable")
			await aim_at(source)
			source.interact(player)
			if phase=="formation":
				tick_sources(.01)
				check(source.state().manifestation==1,id+" saved formation resumes once")
			elif phase=="released":
				var material := String(source.state().material)
				var before := _sim().material_count(material)
				source._collect(material)
				source._collect(material)
				check(_sim().material_count(material)==before+16,id+" saved release collects exactly once")
			else:
				source._work()
				check(source.state().work==2,id+" saved partial work resumes")
			print("LF1_REPAIR_RESTART ",id," ",phase," usable=",source.supported())
