extends "res://tests/resonance_terrain.gd"
## Forced native rooms isolate settlement; live hybrid combat is a separate suite.
const SECOND_PENDING := "user://lf5c-pending.json"
const SECOND_APPLIED := "user://lf5c-applied.json"
var reject_publication := 0

func quiet() -> void:
	super.quiet()
	# Compare restored drop ownership before ordinary flight/age updates.
	for pickup in get_tree().get_nodes_in_group("pickups"): pickup.set_physics_process(false)

func apply_world_identity(seed_value: int, profile_id: String) -> bool:
	if reject_publication>0:
		reject_publication-=1
		return false # Explicit host failure injection, never a combat outcome.
	return super.apply_world_identity(seed_value,profile_id)

func load_frozen(name: String, manager: SaveManager) -> Dictionary:
	var packed:=FileAccess.get_file_as_bytes("res://tests/fixtures/"+name+".json.gz")
	var source:=packed.decompress_dynamic(16000000,FileAccess.COMPRESSION_GZIP).get_string_from_utf8()
	var path:="user://lf5-compat-"+name+".json"
	var file:=FileAccess.open(path,FileAccess.WRITE)
	file.store_string(source)
	file.close()
	check(manager.read(path,player),"published archive loads: "+name+" "+manager.last_error)
	quiet()
	return JSON.parse_string(source)

func ownership(before: Dictionary, after: Dictionary) -> void:
	for key in ["blocks","stations","world_drops","broken_blocks","cracked_blocks","contraptions","leylines"]:
		var same: bool=JSON.parse_string(JSON.stringify(before.get(key)))==JSON.parse_string(JSON.stringify(after.get(key)))
		if key=="world_drops": same=same_drops(before.world_drops,after.world_drops)
		check(same,"preserved complete ownership: "+key)
	var differences:=0
	for entry: Dictionary in before.resource_nodes:
		if JSON.parse_string(JSON.stringify(terrain.resource_stream.records.get(entry.resource_id,{})))!=JSON.parse_string(JSON.stringify(entry)): differences+=1
	check(differences==0,"every prior finite resource record remains exact")

func same_drops(before: Dictionary, after: Dictionary) -> bool:
	# Godot restores float32 transforms through a basis/Euler conversion. The
	# archived LF5B pickup changes yaw by 2.98e-8 radians; its counts/seed/age do
	# not change. Match spatial values within 1e-6, all ownership fields exactly.
	if int(before.version)!=int(after.version): return false
	for kind in ["pickups","bundles"]:
		if before[kind].size()!=after[kind].size(): return false
		for i in before[kind].size():
			var a: Dictionary=before[kind][i].duplicate(true)
			var b: Dictionary=after[kind][i].duplicate(true)
			for field in ["position","velocity","rotation"]:
				if not a.has(field): continue
				if not b.has(field) or SaveManager._unvec(a[field]).distance_to(SaveManager._unvec(b[field]))>0.000001: return false
				a.erase(field);b.erase(field)
			for field in ["yaw","mesh_y"]:
				if not a.has(field): continue
				if not b.has(field) or absf(float(a[field])-float(b[field]))>0.000001: return false
				a.erase(field);b.erase(field)
			if JSON.parse_string(JSON.stringify(a))!=JSON.parse_string(JSON.stringify(b)): return false
	return true

func _run_terrain() -> void:
	var manager:=SaveManager.new()
	var args:=OS.get_cmdline_user_args()
	if "--lf5c-visuals" in args:
		await visual_second(manager)
		return done()
	if "--lf5c-host-recovery" in args:
		check(manager.read(pending_source(),player),"host recovery fixture restores pending ownership")
		quiet()
		var before:=_sim().export_json()
		reject_publication=2
		var result:=ResonanceEvent.publish(player,"user://lf5c-host-recovery.json")
		check(not result.ok && reject_publication==0 && _sim().export_json()==before && int(_sim().era().index)==2 && not player.is_physics_processing(),"failed host and rollback restore prior native era and require reload")
		var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("user://lf5c-host-recovery.json"))
		check(JSON.parse_string(disk.sim).economy.resonance_second.phase=="applied","complete recoverable candidate remains on disk after host recovery failure")
		check(manager.read("user://lf5c-host-recovery.json",player) && int(_sim().era().index)==3 && _sim().material_count("warden_eye")==1,"reload completes physical publication without another payout")
		await physical_bank(JSON.parse_string(_sim().resonance_second_json()))
		return done()
	for arg: String in args:
		if arg.begins_with("--lf5-compat="):
			await compatibility(arg.trim_prefix("--lf5-compat="),manager)
			return done()
	if "--lf5c-pending" in args or "--lf5c-applied" in args or "--lf5c-real-return" in args:
		await restart_second(manager,"--lf5c-applied" in args,"--lf5c-real-return" in args)
		return done()
	load_frozen("lf4-published-applied",manager)
	var first:=_sim().resonance_json()
	var candidate:=WroughtwildSim.new()
	candidate.load_tuning(load("res://scripts/sim.gd").get_tuning_directory())
	candidate.import_json(_sim().export_json())
	candidate.set_world_profile(world_profile)
	force_clear(candidate)
	var pending:=candidate.export_json()
	check(not candidate.resonance_prepare(world_seed,[[0,0,2048,2048]]) && candidate.export_json()==pending,"fully occupied second region leaves pending and prior ownership intact")
	if not check(candidate.resonance_prepare(world_seed,[]),"second candidate prepares: "+candidate.last_error()): return done()
	await paid_second_site(JSON.parse_string(candidate.resonance_second_json()))
	force_clear(_sim())
	check(int(_sim().era().index)==2 && JSON.parse_string(_sim().resonance_second_json()).phase=="pending","native first-clear queues, pays one Eye and retains era two")
	var before:=manager.capture(player)
	var heights: PackedInt32Array=terrain.map.heights.duplicate()
	check(manager.write_data(SECOND_PENDING,before),"retain pre-publication pending paid ownership")
	var threat:=Enemy.spawn(self,&"ember_whelp",player.global_position+Vector3(2,0,0))
	threat.set_physics_process(false)
	threat.state="chase"
	var deferred:=ResonanceEvent.publish(player,"user://lf5c-fight.json")
	check(not deferred.ok && heights==terrain.map.heights && int(_sim().era().index)==2,"combat defers second physical event and era")
	check(JSON.parse_string(FileAccess.get_file_as_string("user://lf5c-fight.json")).sim==before.sim,"combat deferral first saves all pending ownership")
	threat.free()
	check(not ResonanceEvent.publish(player,"user://absent-lf5c-directory/save.json").ok && _sim().export_json()==before.sim && heights==terrain.map.heights,"failed disk checkpoint cannot advance or mutate the world")
	reject_publication=1
	var failed:=ResonanceEvent.publish(player,"user://lf5c-host-failure.json")
	check(not failed.ok && not reject_publication && int(_sim().era().index)==2 && _sim().export_json()==before.sim && terrain.map.heights==heights,"injected host failure rolls back native era and physical world")
	check(JSON.parse_string(FileAccess.get_file_as_string("user://lf5c-host-failure.json")).sim==before.sim,"host rollback saves pending ownership for retry")
	ownership(before,manager.capture(player))
	var result:=ResonanceEvent.publish(player,SECOND_APPLIED)
	print("LF5C_PUBLICATION ms=",result.get("publication_ms",0)," reason=",result.reason)
	if not check(result.ok,"second publication installs physical terrain: "+String(result.reason)): return done()
	quiet()
	var after:=manager.capture(player)
	check(_sim().resonance_json()==first && int(_sim().era().index)==3 && heights!=terrain.map.heights,"era three follows actual second geometry; first ledger is byte exact")
	ownership(before,after)
	check(after.resource_nodes.size()==before.resource_nodes.size()+4 && terrain.map.frontier_hosts.size()==6,"second publication adds exactly four finite lots and one paired host")
	check(not terrain.resource_stream.records.has("lf4_fen_ore_0") && terrain.resource_stream.records.lf4_fen_ore_1.remaining_units==6 && _sim().world_effect_active("host_defeated:lf4_retained_fen_blue"),"first depleted ore and dead host are never replenished")
	var old_rules: Dictionary=JSON.parse_string(before.sim)
	var new_rules: Dictionary=JSON.parse_string(after.sim)
	old_rules.economy.erase("resonance_second")
	new_rules.economy.erase("resonance_second")
	new_rules.economy.world_effects.erase("ash_tide")
	check(int(new_rules.economy.foundry.owned.get("frost",0))==1 && new_rules.economy.foundry.metals.get("frost",{}).size()==1 && int(new_rules.economy.foundry.metals.get("frost",{}).get("steel",0))==1 && new_rules.economy.foundry.milestones.has("deep_forge"),"existing era-three Foundry grant is paid once on publication")
	new_rules.economy.foundry.owned.erase("frost")
	new_rules.economy.foundry.metals.erase("frost")
	new_rules.economy.foundry.milestones.erase("deep_forge")
	check(old_rules==new_rules,"publication changes only second ledger and established era-three milestone/Foundry grant")
	await physical_bank()
	await physical_bank(JSON.parse_string(_sim().resonance_second_json()))
	quiet()
	check(_sim().set_curio("drowned_altar") && not _sim().set_curio("drowned_altar") && int(_sim().era().index)==3,"Eye remembrance is once-only and does not trigger another era")
	await work_second_ore()
	for pack: Dictionary in mob_packs.packs:
		if String(pack.get("frontier_host_id",""))!="lf5_excited_uplands_pair": continue
		var at:=mob_packs.pack_position(pack)
		terrain.ensure_area(at,20)
		mob_packs._spawn_pack(pack,at)
		check(pack.members.size()==1 && pack.members[0].enemy_id=="lf_paired_boar","changed fauna actually instantiates the ordered specimen")
		if pack.members.is_empty(): continue
		var host: Enemy=pack.members[0]
		host.set_physics_process(false)
		host.take_damage(1000000000) # Forced ownership/death fixture; not a combat win.
		var once:=WorldDrops.capture(self)
		mob_packs._on_enemy_died(host)
		check(WorldDrops.capture(self)==once && _sim().world_effect_active("host_defeated:lf5_excited_uplands_pair"),"repeated host death cannot pay twice")
	check(manager.write(SECOND_APPLIED,player),"save both events, paid work, spent Eye, depleted new ore and finite host death")
	var settled:=_sim().export_json()
	check(not ResonanceEvent.publish(player,SECOND_APPLIED).ok && _sim().export_json()==settled,"second publication cannot repeat awards or geometry")
	var foreign:=manager.capture(player)
	foreign.world_seed=5
	check(not manager.apply(player,foreign) && _sim().export_json()==settled,"foreign world seed rejected before live mutation")
	done()

func force_clear(sim: WroughtwildSim) -> void:
	if not check(sim.trial_start_story(515,"deep_forge"),"forced settlement fixture starts native Pairing"): return
	for i in 8:
		if bool(sim.trial_stage().get("awaiting_floor",false)): check(sim.trial_continue_floor(),"native floor continues")
		check(bool(sim.trial_begin_room(0).started),"native room begins")
		sim.trial_resolve_room(true)
		sim.trial_skip_reward()
	check(sim.trial_finished() && sim.world_effect_active("lf5_pairing_victory"),"forced complete Trial settles one first-clear receipt")
	sim.trial_end()

func paid_second_site(plan: Dictionary) -> void:
	var c: Array=plan.columns[plan.columns.size()/2]
	var at:=Vector3(c[0]+.5,c[2],c[1]+.5)
	if not await gather("wood",48): return
	terrain.ensure_area(at,32)
	player.global_position=at+Vector3(0,1,4)
	var cell:=Vector3i(c[0],maxi(int(c[2]),ceili(terrain.rendered_height(at.x,at.z,at.y))),c[1])
	check(place(&"block",cell) && place(&"block",cell+Vector3i.UP),"paid footing and support in second event candidate")
	check(place(&"chest",cell+Vector3i(2,0,0)) && place(&"door",cell+Vector3i(0,0,3),"face",2) && place(&"beam",cell+Vector3i(0,2,0),"edge",0),"paid chest, door and spanning beam in second region")
	var blocks: Array=[];var nodes: Array=[];var sites: Array=[]
	SaveManager._walk(self,blocks,nodes,sites)
	for block: PlacedBlock in blocks:
		if block.is_chest(): check(_sim().store_deposit(block.store_key(),"wood",4)==4,"real gathered chest contents")
		if block.is_door(): block.set_door_open(true)
	check(not terrain.break_block(c[0]-3,c[2]-1,c[1]).is_empty(),"actual nearby excavation retained")
	_sim().add_material("cargo_winch_kit",1)
	_sim().add_material("winch_landing_kit",1)
	check(_sim().contraption_place("cargo_winch","lf5-drum",at+Vector3(0,0,8),0) && _sim().contraption_place("winch_landing","lf5-landing",at+Vector3(12,0,8),0),"declared fixture kits paid through ordinary machine placement")
	check(_sim().contraption_link("lf5-drum","lf5-landing",true).ok && _sim().contraption_deposit("lf5-drum","wood",3).ok,"working machine link and real cargo")
	var bundle:=WorldDrops.BUNDLE_SCENE.instantiate() as DroppedBundle
	bundle.contents={"wood":2} # Explicit recovery fixture.
	add_child(bundle)
	bundle.global_position=at+Vector3(4,.5,8)
	quiet()

func restart_second(manager: SaveManager, applied: bool, real_return: bool) -> void:
	var source:=SECOND_APPLIED if applied else ("user://lf5c-real-return-pending.json" if real_return else pending_source())
	var path:=source if applied else ("user://lf5c-resume-real-return.json" if real_return else "user://lf5c-resume-pending.json")
	if not applied:
		check(manager.write_data(path,JSON.parse_string(FileAccess.get_file_as_string(source))),"fresh restart uses a copy so its pending evidence stays immutable")
	var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	var first: Dictionary=JSON.parse_string(disk.sim).economy.resonance
	if not check(player.load_game(path),"fresh process loads second checkpoint"): return
	quiet()
	if not applied: check(int(_sim().era().index)==2 && JSON.parse_string(_sim().resonance_second_json()).phase=="pending","normal load restores prior era before deferred physical publication")
	for i in 6: await get_tree().process_frame
	quiet()
	check(int(_sim().era().index)==3 && JSON.parse_string(_sim().resonance_json())==first && JSON.parse_string(_sim().resonance_second_json()).phase=="applied","fresh process completes both physical ledgers without replacing first")
	if applied:
		check(JSON.parse_string(_sim().export_json())==JSON.parse_string(disk.sim),"applied native ownership byte-equivalent after restart")
		ownership(disk,manager.capture(player))
		check(not terrain.resource_stream.records.has("lf5_uplands_ore_0") && terrain.resource_stream.records.lf5_uplands_ore_1.remaining_units==6 && _sim().material_count("warden_eye")==0,"spent Eye and depleted/partial new stock remain spent")
		for pack: Dictionary in mob_packs.packs:
			if String(pack.get("frontier_host_id","")) in ["lf4_retained_fen_blue","lf5_excited_uplands_pair"]:
				mob_packs._spawn_pack(pack,mob_packs.pack_position(pack))
				check(pack.members.is_empty(),"both saved finite deaths cannot respawn")
	else:
		check(_sim().material_count("warden_eye")==1 && SaveManager.path_for(player)==path && JSON.parse_string(JSON.parse_string(FileAccess.get_file_as_string(path)).sim).economy.resonance_second.phase=="applied","pending resumes to its restored path without duplicate Eye")
		print("LF5C_PENDING_PUBLICATION ms=",get_meta("last_resonance_publication_ms",0)," real_return=",real_return)
	await physical_bank()
	await physical_bank(JSON.parse_string(_sim().resonance_second_json()))

func compatibility(name: String, manager: SaveManager) -> void:
	var old:=load_frozen(name,manager)
	var before: Dictionary=JSON.parse_string(old.sim)
	var after: Dictionary=JSON.parse_string(_sim().export_json())
	after.economy.erase("resonance_second")
	check(before==after,"archived native rules remain exact apart from explicit second ledger")
	ownership(old,manager.capture(player))
	var second: Dictionary=JSON.parse_string(_sim().resonance_second_json())
	check(second.phase==("pending" if name=="lf5b-published-clear" else "dormant"),"documented absent-ledger migration chooses correct phase")
	check(int(_sim().era().index)==(2 if name in ["lf4-published-applied","lf5b-published-clear","lf5b-published-boundary"] else 1),"loading alone does not award a new era")
	if name=="lf5b-published-boundary": check(player.trial.active() && String(player.trial.layout.run_id)=="deep_forge","historical revision-two Pairing boundary remains resumable")
	var saved:=manager.capture(player)
	var future:=saved.duplicate(true)
	var native: Dictionary=JSON.parse_string(future.sim)
	native.economy.resonance_second.version=2
	future.sim=JSON.stringify(native)
	check(not manager.apply(player,future) && _sim().export_json()==saved.sim,"unknown second event schema rejected without mutation")
	if name=="lf4-published-dormant":
		var path:="user://lf5-future-schema.json"
		check(manager.write_data(path,saved) && manager.write_data(path,future),"future schema refusal fixture includes a readable old backup")
		check(not manager.read(path,player) && manager.last_error.contains("unsupported") && _sim().export_json()==saved.sim,"future second schema cannot silently fall back to an older era/ownership backup")
	if name in ["lf4-published-pending","lf4-published-paid-pending","lf5b-published-clear"]:
		var result:=ResonanceEvent.publish(player,"user://lf5-compat-published-"+name+".json")
		check(result.ok,"historical pending state remains physically publishable: "+String(result.reason))
		check(int(_sim().era().index)==(3 if name=="lf5b-published-clear" else (2 if name=="lf4-published-pending" else 1)),"only appropriate historic receipt awards its own era")
		ownership(saved,manager.capture(player))

func work_second_ore() -> void:
	# Fuel/access are fixtures. Every tested iron/silver unit must be worked and
	# collected from the actual second publication using existing charcoal heat.
	var sim:=_sim()
	sim.add_material("charcoal",12)
	for id in ["lf5_uplands_ore_0","lf5_uplands_ore_1"]:
		var record: Dictionary=terrain.resource_stream.records[id]
		var p:=SaveManager._unvec(record.position)
		terrain.ensure_area(p,24)
		var node:=terrain.resource_stream.materialise(id)
		if not check(node!=null,"actual new finite deposit materialises"): return
		check(node.workable() if id.ends_with("0") else not node.workable(),"iron retains ordinary cold work; silver retains its charcoal heat gate")
		player.global_position=p+Vector3(0,1.2,3)
		if node.heat_to_work<=0:
			await work_units(node,null,4)
			continue
		var build:=player.placement
		build.set_build_mode_enabled(true)
		player.build_palette.open_panel()
		player.build_palette.select_entry(&"campfire","shape")
		player.build_palette.select_material(&"charcoal")
		player.build_palette.close_panel()
		var fuel:=sim.material_count("charcoal")
		var placed:=false
		for offset: Vector2i in [Vector2i(1,0),Vector2i(0,1),Vector2i(-1,0),Vector2i(0,-1),Vector2i(1,1),Vector2i(-1,-1)]:
			var cell:=Vector3i(floori(p.x)+offset.x,ceili(p.y),floori(p.z)+offset.y)
			cell.y=maxi(cell.y,terrain.height_at(cell.x,cell.z))
			build.preview_element={"kind":"volume","axis":0,"cell":cell*2}
			build.preview_visible=true
			if build.try_place_block(): placed=true;break
		build.set_build_mode_enabled(false)
		if not check(placed && sim.material_count("charcoal")==fuel-3,"ordinary charcoal fire pays existing three-unit fuel cost"): return
		var fire: PlacedBlock
		var blocks: Array=[];var nodes: Array=[];var sites: Array=[]
		SaveManager._walk(self,blocks,nodes,sites)
		for block: PlacedBlock in blocks:
			if block.is_fire() && block.global_position.distance_to(p)<3: fire=block
		if not check(fire!=null,"actual heating fire beside second deposit"): return
		fire.set_process(false)
		fire._process(5)
		check(node.workable(),"real charcoal heat enables new metal")
		await work_units(node,fire,1)
		fire._burn_out()
		for i in 2: await get_tree().process_frame
	terrain.resource_stream.capture()
	check(not terrain.resource_stream.records.has("lf5_uplands_ore_0") && terrain.resource_stream.records.lf5_uplands_ore_1.remaining_units==6,"second lots are finite and retain depletion")
	sim.add_material("wood",30)
	var iron:=sim.material_count("iron_ore")
	var silver:=sim.material_count("silver_ore")
	check(bool(sim.craft("smelt_iron").crafted) && sim.material_count("iron_ore")==iron-2,"new iron makes useful ingots through the existing paid recipe")
	check(bool(sim.craft("smelt_silver").crafted) && sim.material_count("silver_ore")==silver-2,"new silver makes useful warding metal through the existing paid recipe")

func work_units(node: ResourceNode, fire: PlacedBlock, presses: int) -> void:
	for i in presses:
		if fire!=null: fire._process(1)
		var result:=node.work(_sim())
		check(int(result.get("granted",0))==2,"ordinary work releases two actual finite metal units")
		player._apply_work(node,result)
		for pickup in get_tree().get_nodes_in_group("pickups"):
			if pickup.is_queued_for_deletion(): continue
			player.global_position=pickup.global_position-Vector3(0,.6,0)
			pickup._physics_process(1.0/60.0)
		await get_tree().process_frame

func done() -> void:
	print("LF5C_PHYSICAL ",checks," checks, ",failures," failures; forced settlement/death fixtures, actual movement and resource work")
	get_tree().quit(1 if failures else 0)

func visual_second(manager: SaveManager) -> void:
	if not check(manager.read(pending_source(),player),"visual fixture restores paid second pending checkpoint"): return
	quiet()
	var applied: Dictionary=JSON.parse_string(JSON.parse_string(FileAccess.get_file_as_string(SECOND_APPLIED)).sim).economy.resonance_second
	var c: Array=applied.columns[applied.columns.size()/3]
	var focus:=Vector3(c[0]+.5,c[3],c[1]+.5)
	terrain.ensure_area(focus,48)
	var observer:=Camera3D.new()
	add_child(observer)
	observer.global_position=focus+Vector3(18,25,22)
	observer.look_at(focus)
	observer.current=true
	var folder:="res://../captures/lf5/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(folder))
	for i in 3: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"uplands-before.png")
	player.set_meta("active_world_save_path","user://lf5c-visual-publication.json")
	settle_resonance()
	check(int(_sim().era().index)==2 && player.hud._notice.text.contains("Preparing protected ground"),"normal publication displays preparing feedback while still in era two")
	await RenderingServer.frame_post_draw
	check(int(_sim().era().index)==2,"preparing notice reaches a rendered frame before synchronous publication")
	get_viewport().get_texture().get_image().save_png(folder+"uplands-preparing.png")
	for i in 6: await get_tree().process_frame
	check(int(_sim().era().index)==3,"rendered normal publication installs era three")
	terrain.ensure_area(focus,48)
	observer.current=true
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(folder+"uplands-applied.png")
	print("LF5C_RENDERED_PUBLICATION ms=",get_meta("last_resonance_publication_ms",0))

func pending_source() -> String:
	var state: Dictionary=JSON.parse_string(JSON.parse_string(FileAccess.get_file_as_string(SECOND_PENDING)).sim).economy.resonance_second
	return SECOND_PENDING if state.phase=="pending" else SECOND_PENDING+".previous"
