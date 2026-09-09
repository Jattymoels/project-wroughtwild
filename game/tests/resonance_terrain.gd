extends "res://tests/living_frontier_routes.gd"
const ResonanceEvent := preload("res://scripts/resonance_event.gd")
const PENDING_SAVE := "user://lf4a-pending.json"
const APPLIED_SAVE := "user://lf4a-applied.json"

func _ready() -> void:
	world_seed=77
	world_profile="living_frontier_wave3"
	_sim().set_campaign_policy("living_frontier_wave4")
	_build_world(world_seed)
	player.class_panel.choose("warden")
	quiet()
	_run_terrain.call_deferred()

func quiet() -> void:
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	mob_packs.set_physics_process(false)
	set_physics_process(false)
	freeze_fixtures()

func _run_terrain() -> void:
	var manager:=SaveManager.new()
	var args:=OS.get_cmdline_user_args()
	if "--lf4a-applied" in args:
		check(manager.read(APPLIED_SAVE,player),"fresh applied restart: "+manager.last_error)
		quiet()
		var loaded:=manager.capture(player)
		var disk: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(APPLIED_SAVE))
		check(JSON.parse_string(loaded.sim)==JSON.parse_string(disk.sim),"applied terrain and complete rules exact after restart")
		check(not _sim().resonance_queue(world_seed),"applied event cannot requeue")
		check(not ResonanceEvent.publish(player,APPLIED_SAVE).ok,"applied event cannot repay or republish")
		await physical_bank()
		return done()
	if "--lf4a-pending" in args:
		check(manager.read(PENDING_SAVE,player),"fresh pending restart: "+manager.last_error)
		quiet()
	else:
		check(ResonanceEvent.phase(_sim())=="dormant","new campaign starts without an event")
		check(not _sim().trial_start_story(1,"deep_forge") && not _sim().trial_start(1,""),"successor cannot enter later or legacy Trial bypasses")
		check(_sim().resonance_queue(world_seed),"isolated fixture queues once without a Trial trigger")
		check(not _sim().resonance_queue(world_seed),"duplicate pending request refused")
		var candidate:=WroughtwildSim.new()
		candidate.load_tuning(load("res://scripts/sim.gd").get_tuning_directory())
		candidate.import_json(_sim().export_json())
		candidate.set_world_profile(world_profile)
		var isolated_pending:=candidate.export_json()
		check(not candidate.resonance_prepare(world_seed,[[0,0,2048,2048]]) && candidate.export_json()==isolated_pending,"fully occupied preparation preserves pending ownership for explicit retry")
		if not check(candidate.resonance_prepare(world_seed,[]),"isolated candidate planned: "+candidate.last_error()): return done()
		var plan: Dictionary=JSON.parse_string(candidate.resonance_json())
		var c: Array=plan.columns[plan.columns.size()/2]
		var at:=Vector3(c[0]+.5,c[2],c[1]+.5)
		terrain.ensure_area(at,32)
		# Real gathered timber and normal paid placement; the remaining fixture
		# machinery is isolated test stock, installed through the paying API.
		if not await gather("wood",48): return done()
		terrain.ensure_area(at,32)
		player.global_position=at+Vector3(0,1,4)
		var floor_y:=maxi(int(c[2]),ceili(terrain.rendered_height(at.x,at.z,at.y)))
		var cell:=Vector3i(c[0],floor_y,c[1])
		check(place(&"block",cell),"paid footing in a candidate transformation column")
		check(place(&"block",cell+Vector3i.UP),"paid support above the footing")
		check(place(&"chest",cell+Vector3i(2,0,0)),"paid storage beside the support")
		var blocks: Array=[];var nodes: Array=[];var sites: Array=[]
		SaveManager._walk(self,blocks,nodes,sites)
		for block: PlacedBlock in blocks:
			if block.is_chest(): check(_sim().store_deposit(block.store_key(),"wood",4)==4,"stored gathered materials owned by chest")
		check(not terrain.break_block(c[0]-3,c[2]-1,c[1]).is_empty(),"excavated adjacent real surface")
		_sim().add_material("cargo_winch_kit",1)
		_sim().add_material("winch_landing_kit",1)
		check(_sim().contraption_place("cargo_winch","lf4a-drum",at+Vector3(0,0,8),0),"fixture winch kit paid")
		check(_sim().contraption_place("winch_landing","lf4a-landing",at+Vector3(12,0,8),0),"fixture landing kit paid")
		check(_sim().contraption_link("lf4a-drum","lf4a-landing",true).ok,"working span linked")
		check(_sim().contraption_deposit("lf4a-drum","wood",3).ok,"stored cargo uses actual inventory")
		var bundle:=WorldDrops.BUNDLE_SCENE.instantiate() as DroppedBundle
		bundle.contents={"wood":2}
		add_child(bundle)
		bundle.global_position=at+Vector3(4,.5,8)
		quiet()
		check(manager.write(PENDING_SAVE,player),"pending ownership checkpoint: "+manager.last_error)
	var before:=manager.capture(player)
	var heights: PackedInt32Array=terrain.map.heights.duplicate()
	var protected_bounds:=ResonanceEvent.protection(player,before)
	var failed:=ResonanceEvent.publish(player,"user://absent-lf4a-directory/save.json")
	check(not failed.ok && ResonanceEvent.phase(_sim())=="pending" && heights==terrain.map.heights,"failed checkpoint leaves pending and physical world unchanged")
	var result:=ResonanceEvent.publish(player,APPLIED_SAVE)
	if not check(result.ok,"atomic physical publication: "+String(result.reason)): return done()
	quiet()
	var after:=manager.capture(player)
	check(ResonanceEvent.phase(_sim())=="applied" && terrain.map.heights!=heights,"published actual transformed terrain")
	for key in ["blocks","stations","world_drops","broken_blocks","contraptions","leylines"]:
		check(JSON.parse_string(JSON.stringify(before.get(key)))==JSON.parse_string(JSON.stringify(after.get(key))),"complete ownership unchanged: "+key)
	var old_rules: Dictionary=JSON.parse_string(before.sim)
	var new_rules: Dictionary=JSON.parse_string(after.sim)
	old_rules.economy.erase("resonance");new_rules.economy.erase("resonance")
	check(old_rules==new_rules,"event changes no inventory, stores, mastery or era in isolated LF-4A")
	var transformed: Dictionary=JSON.parse_string(_sim().resonance_json())
	var retained:=true
	for c: Array in transformed.columns:
		for b: Array in protected_bounds:
			if c[0]>=b[0]-3 && c[0]<=b[2]+3 && c[1]>=b[1]-3 && c[1]<=b[3]+3: retained=false
	check(retained,"all occupied columns, support/workspace buffers and recovery positions retained")
	var resource_differences:=0
	for entry: Dictionary in before.resource_nodes:
		var actual: Dictionary=terrain.resource_stream.records.get(entry.resource_id,{})
		if JSON.parse_string(JSON.stringify(actual))!=JSON.parse_string(JSON.stringify(entry)):
			resource_differences+=1
			if resource_differences<4: print("LF4A_RESOURCE_DIFF ",entry," ACTUAL ",actual)
	check(resource_differences==0,"all old finite resource ownership exact")
	check(after.resource_nodes.size()==before.resource_nodes.size()+4,"four finite distinct future ore opportunities, no repeated old stock")
	await physical_bank()
	var paid_state:=_sim().export_json()
	var foreign:=manager.capture(player)
	foreign.world_seed=5
	check(not manager.apply(player,foreign) && _sim().export_json()==paid_state,"wrong seed rejected before ownership mutation")
	done()

func physical_bank() -> void:
	var state: Dictionary=JSON.parse_string(_sim().resonance_json())
	var columns: Array=state.columns
	if not check(not columns.is_empty(),"sparse applied bank exists"): return
	var c: Array=columns[columns.size()/3]
	var route:=PackedVector3Array()
	# Cross old ground, both bank margins and its new surface with the actual
	# capsule/controller. This is not a height-only or endpoint teleport check.
	for x in range(int(c[0])-10,int(c[0])+11):
		route.append(terrain.surface_position(x,int(c[1])))
	check(await walk_route(route),"ordinary complete walk crosses transformed collision and both margins")
	var hit_changed:=false
	for c2: Array in columns:
		if int(c2[1])==int(c[1]) && absf(float(c2[0])-float(c[0]))<8: hit_changed=true
	check(hit_changed,"physical walk intersects actually changed columns")
	var target:=Vector3(c[0]+.5,c[3]+8,c[1]+.5)
	terrain.ensure_area(target,20)
	for i in 3: await get_tree().physics_frame
	var hit:=get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(target,target-Vector3.UP*16,1))
	print("LF4A_RAY column=",c," hit=",hit)
	check(not hit.is_empty() && hit.position.y>float(c[2])+.2,"real collision is raised above the published surface")

func done() -> void:
	print("LF4A_PHYSICAL ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)
