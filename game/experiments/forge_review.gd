extends Node3D
## Accelerated visual walkthrough of all three real story sessions. Live enemies,
## native choices, transitions and effects; fixture immunity and forced clears
## make this presentation/lifecycle evidence, never difficulty or duration proof.
var world:Sandpit
var player:WroughtwildPlayer
var trial:TrialController
var sim:WroughtwildSim
var camera:Camera3D
var caption:Label
var output:String
var recording:Array=[]
var samples:Array=[]
var previous_tick:=0
var measuring:=false
var frames:=0
var checks:=0
var failures:=0
var peak_enemies:=0
var started_at:=0
var build_ms:=0
var last_form:Dictionary={}
var dense_results:Dictionary={}
var diagnostics:=false
var cpu_totals:=Vector3.ZERO
var boss_only:=false

func check(ok:bool,label:String)->void:
	checks+=1
	if not ok: failures+=1; printerr("FAIL: Forge review: ",label)

func _ready()->void:
	get_window().size=Vector2i(1440,900)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps=120
	output=ProjectSettings.globalize_path("res://../build/intensives/forge")
	boss_only="--boss-only" in OS.get_cmdline_user_args()
	if boss_only: output=output.path_join("boss")
	DirAccess.make_dir_recursive_absolute(output)
	started_at=Time.get_ticks_msec()
	world=preload("res://scenes/sandpit.tscn").instantiate()
	add_child(world)
	build_ms=Time.get_ticks_msec()-started_at
	player=world.player
	player.class_panel.choose("kindler")
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.placement.set_physics_process(false)
	world.mob_packs.set_process(false)
	world.mob_packs.set_physics_process(false)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy.set_physics_process(false)
	sim=player.inventory.get_sim()
	trial=player.trial
	trial.seed_source.seed=193
	_setup_foundry()
	camera=Camera3D.new()
	add_child(camera)
	camera.fov=76
	camera.make_current()
	var canvas:=CanvasLayer.new()
	add_child(canvas)
	caption=Label.new()
	caption.position=Vector2(22,720)
	caption.add_theme_font_size_override("font_size",17)
	caption.add_theme_color_override("font_shadow_color",Color.BLACK)
	caption.add_theme_constant_override("shadow_offset_x",2)
	caption.add_theme_constant_override("shadow_offset_y",2)
	canvas.add_child(caption)
	Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
	previous_tick=Time.get_ticks_usec()
	for run_id in ([] if "--performance-only" in OS.get_cmdline_user_args() else ["forge_tyrant","deep_forge","forge_capstone"]):
		check(trial.begin_run(run_id),"real gate session starts "+run_id)
		if not trial.active(): continue
		await _story(run_id)
		if run_id=="forge_tyrant": check(sim.set_curio("hill_cairn"),"Tyrant curio opens the existing era landmark")
		elif run_id=="deep_forge": check(sim.set_curio("drowned_altar"),"Warden curio opens Ash Tide")
	if not "--performance-only" in OS.get_cmdline_user_args(): check(sim.world_effect_active("forge_arc_complete"),"full visual route reaches the separate capstone flag")
	if not "--skip-performance" in OS.get_cmdline_user_args(): await _dense_comparison()
	_finish()

func _setup_foundry()->void:
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer"]: sim.foundry_event(event)
	sim.add_materials({"frost_catalyst":2,"preserving_catalyst":2,"iron_ingot":100})
	sim.foundry_place_skill(1,1,"prototype_ember_bolt")
	sim.foundry_place(1,0,"ember")
	sim.foundry_place_kind(2,0,"frost_catalyst")
	player.combat._mutation_cache.clear()
	last_form=sim.skill_mutation("prototype_ember_bolt")

func _process(_delta:float)->void:
	var now:=Time.get_ticks_usec()
	if measuring and previous_tick>0:
		samples.append(float(now-previous_tick)/1000.0)
		if diagnostics: cpu_totals+=Vector3(Performance.get_monitor(Performance.TIME_PROCESS)*1000,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000,Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	previous_tick=now
	if player!=null:
		player.combat.invulnerable_left=100
		if trial!=null and trial.active(): peak_enemies=maxi(peak_enemies,trial.trial_enemies().size())

func _story(run_id:String)->void:
	var guard:=0
	while trial.active() and guard<12:
		guard+=1
		if guard==1:
			var secret:=trial.arena.dungeon.secret
			player.global_position=secret.global_position+Vector3(0,.6,-1.7)
			var inward:float=-signf(secret.position.x)
			await _watch(run_id+" · optional hidden workshop",secret.global_position+Vector3(inward*15,1.7,-5),secret.global_position+Vector3(inward*7,1.3,-1),.8)
			trial.interact_fixture(secret)
			check(secret.claimed and trial.state=="exploring","secret is class-independent and leaves the route open")
			await _snap(run_id+"-secret-workshop")
		if trial.state=="boundary":
			var lift:=trial.arena.dungeon.boundary
			var at:=lift.global_position+Vector3(0,1.7,5)
			await _watch(run_id+" · cleared floor / continue, bank or suspend",at,lift.global_position+Vector3.UP*1.4,.8)
			trial.show_boundary()
			await _snap(run_id+"-boundary-options")
			check(trial.continue_floor(),"physical lift advances the same "+run_id+" session")
			continue
		var stage:Dictionary=sim.trial_stage()
		var choices:Array=stage.get("choices",[])
		if choices.is_empty(): check(false,"next authored route is available"); trial.on_player_died(); break
		var index:=int(stage["index"])
		var choice:=mini((index+(1 if run_id=="deep_forge" else 0))%2,choices.size()-1)
		var dungeon:=trial.arena.dungeon
		var room:Dictionary=dungeon.rooms["%d:%d"%[index,choice]]
		var centre:Vector3=dungeon.to_global(room["centre"])
		var door:TrialFixture=room["door"]
		var from:=door.global_position+Vector3(-signf(room["centre"].x)*3,1.7,0)
		player.global_position=from-Vector3.UP*1.1
		await _watch(run_id+" · "+String(choices[choice]["display_name"])+" / physical route preview",from,door.global_position+Vector3.UP*1.3,.5)
		trial.interact_fixture(door)
		check(trial.state=="fighting","entering the chosen physical room owns its enemies")
		var view:=dungeon.to_global(room["centre"]+Vector3(-signf(room["centre"].x)*6,1.7,8))
		player.global_position=view-Vector3.UP*1.1
		await _watch(run_id+" · "+String(room["module"]).replace("_"," ")+" / live encounter",view,centre+Vector3(0,1,-3),1.4)
		await _snap(run_id+"-floor"+str(trial.built_floor+1)+"-"+String(room["module"]))
		for enemy in trial.trial_enemies():
			if enemy is Boss:
				await _boss_view(run_id,enemy,room)
		var waves:=0
		while (not trial.trial_enemies().is_empty() or not trial.wave_queue.is_empty()) and waves<20:
			waves+=1
			for enemy in trial.trial_enemies(): enemy.take_damage(1000000000)
			for hazard in trial._hazards(): hazard.cancel()
			trial._tick_spatial(10)
			await get_tree().physics_frame
		for hazard in trial._hazards(): hazard.cancel()
		trial._process(0)
		await get_tree().physics_frame
		if not trial.active(): break
		check(trial.state=="reward","clearing exposes the offering in its room")
		var reward:TrialFixture=trial.arena.dungeon.reward
		player.global_position=reward.global_position+Vector3(0,.6,1.7)
		await _watch(run_id+" · recovered offering / rewards stay in the dungeon",reward.global_position+Vector3(0,1.7,3),reward.global_position+Vector3.UP*1.4,.45)
		trial.interact_fixture(reward)
		if not trial.current_offer.is_empty():
			await _snap(run_id+"-boon-"+str(index))
			trial.accept_boon(String(trial.current_offer[0]["id"]))
		elif trial.state=="reward" and trial.active(): trial.skip_offer()
		await get_tree().physics_frame
	check(not trial.active(),"all mandatory encounters and final reward finish "+run_id)

func _boss_view(run_id:String,boss:Boss,room:Dictionary)->void:
	var dungeon:=trial.arena.dungeon
	var from:=dungeon.to_global(room["centre"]+(Vector3(0,1.7,10) if run_id=="forge_capstone" else Vector3(8,1.7,8)))
	player.global_position=dungeon.to_global(room["centre"]+Vector3(3,.6,4))
	# Real Foundry field/reaction plus the boss's normal committed attack cycle.
	boss.apply_ignite(100,0,0,last_form)
	FoundryReactions.contact(player.combat,boss,&"prototype_ember_bolt",last_form,{})
	var field:=FoundryField.spawn(player.combat,&"prototype_ember_bolt",boss.global_position+Vector3(.7,.1,0),"rime",last_form)
	await _watch(run_id+" · boss tells under active Foundry effects",from,boss.global_position+Vector3.UP*1.0,1.5)
	await _snap(run_id+"-boss-foundry")
	if is_instance_valid(field): field.cancel()
	await _watch(run_id+" · committed boss attack and recovery",from,player.global_position+Vector3.UP,5.0)
	await _snap(run_id+"-boss-recovery")

func _watch(title:String,from:Vector3,to:Vector3,seconds:float)->void:
	if boss_only and not "boss" in title: return
	caption.text=title+"\nAccelerated visual review · fixture immunity and forced clears"
	var elapsed:=0.0
	var next_frame:=0.0
	camera.global_position=from
	camera.look_at(to)
	player.camera.global_transform=camera.global_transform
	while elapsed<seconds:
		measuring=true
		await get_tree().process_frame
		measuring=false
		elapsed+=get_process_delta_time()
		# Small player-height lateral movement exposes material grain and tells.
		camera.global_position=from+camera.global_basis.x*sin(elapsed*1.1)*.35
		camera.look_at(to)
		player.camera.global_transform=camera.global_transform
		if elapsed>=next_frame:
			next_frame+=.20
			await _snap("frame-"+str(frames).pad_zeros(4))

func _snap(id:String)->void:
	if DisplayServer.get_name()=="headless": return
	if boss_only and not ("boss" in id or id.begins_with("frame-")): return
	await RenderingServer.frame_post_draw
	var file:=id+".png"
	check(get_viewport().get_texture().get_image().save_png(output.path_join(file))==OK,"capture "+id)
	recording.append({"file":file,"label":caption.text})
	frames+=1
	previous_tick=Time.get_ticks_usec()

func _dense_comparison()->void:
	# Fixed cohort, effects, pose, frame count and resolution. Only the space
	# changes: original arena / complete Forge floor with trial navigation.
	check(trial.begin_run("forge_tyrant"),"dense comparison gets a native floor description")
	if not trial.active(): return
	var layout:Dictionary=trial.layout.duplicate(true)
	# Keep the same empty, unmodified native session for both cohorts. Early
	# extraction is deliberately unavailable; the fixture never saves this run.
	trial.set_process(false)
	var arena:=trial.arena
	var story_samples:=samples.duplicate()
	for mode in ["legacy_arena","forge_floor"]:
		seed(193)
		arena.restore_legacy()
		var centre:=arena.global_position
		if mode=="forge_floor":
			arena.build_floor(layout,0)
			centre=arena.dungeon.to_global(arena.dungeon.rooms["0:0"]["centre"])
		player.global_position=centre+Vector3(0,.5,6)
		camera.global_position=centre+Vector3(0,1.7,10)
		camera.look_at(centre+Vector3(0,1,-2))
		player.camera.global_transform=camera.global_transform
		caption.text="24 live enemies + 8 ignites + 4 Foundry fields · "+mode+"\nFixed cohort, camera and build · no captures during timing"
		var cohort:Array=[]
		var ids:Array=[&"ash_hound",&"ember_whelp",&"cinder_archer"]
		for i in 24:
			var at:=centre+Vector3(-3.75+float(i%6)*1.5,.5,-7+float(i/6)*1.5)
			var enemy:=Enemy.spawn(world,ids[i%ids.size()],at)
			enemy.trial_bound=true
			enemy.aggro_range=100
			enemy.give_up_distance=0
			enemy.state="chase"
			if mode=="forge_floor": enemy.trial_dungeon=arena.dungeon
			if i%3==0: enemy.apply_ignite(100,0,0,last_form)
			cohort.append(enemy)
		var fields:Array=[]
		for x in [-2.5,2.5]:
			for z in [-3.5,.5]:
				var field:=FoundryField.spawn(player.combat,&"prototype_ember_bolt",centre+Vector3(x,.1,z),"rime",last_form)
				field.remaining=100 # Identical persistent visual load for this measurement.
				fields.append(field)
		for frame in 120: await get_tree().process_frame
		samples=[]
		diagnostics=true
		cpu_totals=Vector3.ZERO
		previous_tick=Time.get_ticks_usec()
		measuring=true
		for frame in 600: await get_tree().process_frame
		measuring=false
		samples.sort()
		dense_results[mode]={"samples":samples.size(),"median_ms":samples[samples.size()/2],"p95_ms":samples[ceili(samples.size()*.95)-1],"enemy_count":cohort.size(),"ignite_count":8,"field_count":4,"capture_readbacks":0}
		dense_results[mode]["mean_process_ms"]=cpu_totals.x/samples.size()
		dense_results[mode]["mean_physics_ms"]=cpu_totals.y/samples.size()
		dense_results[mode]["mean_draw_calls"]=cpu_totals.z/samples.size()
		check(cohort.size()==24 and cohort.all(func(e):return is_instance_valid(e) and e.life>0),"dense cohort stays at the configured population cap")
		await _snap("dense-"+mode)
		if "--diagnose-dense" in OS.get_cmdline_user_args():
			for enemy in cohort: enemy.set_physics_process(false)
			for frame in 60: await get_tree().process_frame
			samples=[]
			cpu_totals=Vector3.ZERO
			previous_tick=Time.get_ticks_usec()
			measuring=true
			for frame in 300: await get_tree().process_frame
			measuring=false
			samples.sort()
			dense_results[mode]["static_diagnostic"]={"samples":samples.size(),"median_ms":samples[samples.size()/2],"p95_ms":samples[ceili(samples.size()*.95)-1],"mean_process_ms":cpu_totals.x/samples.size(),"mean_physics_ms":cpu_totals.y/samples.size(),"mean_draw_calls":cpu_totals.z/samples.size()}
		diagnostics=false
		for field in fields:
			if is_instance_valid(field): field.cancel()
		for enemy in cohort: enemy.queue_free()
		for projectile in get_tree().get_nodes_in_group("enemy_projectiles"): projectile.queue_free()
		await get_tree().physics_frame
		await get_tree().process_frame
	if dense_results.has("legacy_arena") and dense_results.has("forge_floor"):
		for stat in ["median_ms","p95_ms"]:
			dense_results[stat+"_change_percent"]=100*(float(dense_results.forge_floor[stat])/float(dense_results.legacy_arena[stat])-1)
		samples=story_samples

func _finish()->void:
	samples.sort()
	var result:Dictionary={"world_startup_ms":build_ms,"recorded_frames":recording.size(),"peak_enemies":peak_enemies,"dense_comparison":dense_results,"resolution":[1440,900],"renderer":RenderingServer.get_current_rendering_method(),"scope":"Three complete real story session paths, accelerated forced clears and immunity. Rendering samples exclude screenshot readback. Not balance or target-duration evidence.","records":recording}
	if boss_only: result["scope"]="Three live boss cycles on the final Forge geometry. Fixture immunity and accelerated native transitions; not difficulty or duration evidence."
	if not samples.is_empty():
		result["frame_samples"]=samples.size()
		result["median_ms"]=samples[samples.size()/2]
		result["p95_ms"]=samples[ceili(samples.size()*.95)-1]
	if "--performance-only" in OS.get_cmdline_user_args():
		result["scope"]="Matched fixed 24-enemy cohorts, 8 ignites and 4 Foundry fields; same build, seed, camera distance and 600 frames after 120 warmup frames. No captures during timing. Original arena versus complete Forge floor with navigation."
		var performance_file:=FileAccess.open(output.path_join("performance.json"),FileAccess.WRITE)
		performance_file.store_string(JSON.stringify(result,"\t"))
		performance_file.close()
		print("FORGE_DENSE ",checks," checks, ",failures," failures; ",JSON.stringify(dense_results))
		get_tree().quit(1 if failures else 0)
		return
	var file:=FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify(result,"\t"))
	file.close()
	var html:="<!doctype html><meta charset='utf-8'><title>The Forge · spatial review</title><style>body{margin:0;background:#171c1a;color:#e7dbc2;font:16px system-ui}main{max-width:1100px;margin:24px auto}h1{font-size:26px}img{width:100%;border:1px solid #556258}button{background:#485a4b;color:#f5eddb;border:0;border-radius:5px;padding:10px 20px}input{width:70%}p{line-height:1.55;color:#bdbcae}</style><main><h1>The Forge — three traversable story runs</h1><p>Complete accelerated visual route through Tyrant's Forge, Deeper Forge and the Ash Tide capstone. Live AI and native choices, physical junctions, two floors, rewards and boss effects. Fixture immunity and forced clears: this is presentation evidence, not a difficulty or duration measurement.</p><img id='view'><p id='caption'></p><button id='play'>Pause</button> <input id='scrub' type='range' min='0' value='0'><p>Use the slider to inspect room architecture, boon choices and floor transitions. Resources shown in the Forge share the player's building-material lookup.</p></main><script>const frames="+JSON.stringify(recording)+";let index=0,playing=true;const img=document.getElementById('view'),caption=document.getElementById('caption'),slider=document.getElementById('scrub');slider.max=frames.length-1;function show(){img.src=frames[index].file;caption.textContent=frames[index].label;slider.value=index}slider.oninput=()=>{index=+slider.value;show()};document.getElementById('play').onclick=e=>{playing=!playing;e.target.textContent=playing?'Pause':'Play'};setInterval(()=>{if(playing){index=(index+1)%frames.length;show()}},200);show();</script>"
	if boss_only:
		html=html.replace("three traversable story runs","three boss cycles")
		html=html.replace("Complete accelerated visual route through Tyrant's Forge, Deeper Forge and the Ash Tide capstone. Live AI and native choices, physical junctions, two floors, rewards and boss effects.","Final grounded boss cycles for Tyrant's Forge, Deeper Forge and the Ash Tide capstone, including active Foundry effects. Native routes are advanced between these excerpts.")
		html=html.replace("<main>","<main><p><a style='color:#bad1bd' href='../index.html'>Full spatial route</a></p>")
	else:
		html=html.replace("<main>","<main><p><a style='color:#bad1bd' href='boss/index.html'>Final grounded boss cycles</a> · <a style='color:#bad1bd' href='../materials/index.html'>Building materials</a> · <a style='color:#bad1bd' href='../world/index.html'>Resource habitats</a></p>")
	file=FileAccess.open(output.path_join("index.html"),FileAccess.WRITE)
	file.store_string(html)
	file.close()
	print("FORGE_REVIEW ",checks," checks, ",failures," failures; ",recording.size()," frames; ",JSON.stringify(result.duplicate().merged({"records":[]},true)))
	get_tree().quit(1 if failures else 0)
