extends "res://tests/home_workshop_review.gd"
## Controlled inspection supplies; real crafting, native cargo and ordinary saves.
## No normal world, first-hour economy claim or automatic repeating work.
const ART := preload("res://f2/art.gd")
const DRUM := "fixture_0_0_0"
const LANDING := "fixture_16_0_0"
const OUT := "res://f2/evidence/"
var drum: ContraptionSite
var landing: ContraptionSite
var source: ResourceNode
var wall: StaticBody3D
var status: Label
var elapsed := 0.0
var halted := false
var review_ready := false
var manual := false
var emissions := true
var recovered: Node3D
var initial: Dictionary
var observations: Array[Dictionary]=[]

func _run() -> void:
	player.hud.hide()
	player.hide()
	player.placement.set_process(false)
	check(sim.contraption_bind_world("legacy_v1",0),"frozen native world starts empty")
	sim.add_station("workbench")
	# Explicit fixture stock isolates paid costs; no cost or inventory is bypassed.
	for item in {"wood":34,"iron_ingot":3,"thrumroot":1}:sim.add_material(item,{"wood":34,"iron_ingot":3,"thrumroot":1}[item])
	for frame in 3:await get_tree().physics_frame
	drum=await _place_f2("cargo_winch",Vector3i.ZERO)
	landing=await _place_f2("winch_landing",Vector3i(16,0,0))
	if drum==null or landing==null:_done("setup");return
	check(sim.material_count("wood")==20 and sim.material_count("iron_ingot")==0 and sim.material_count("thrumroot")==0,"complete two-endpoint cost is 14 wood, 3 iron, one Thrumroot")
	check(sim.contraption_link(DRUM,LANDING,drum.link_clear(landing)).ok,"supported clear eight-metre span links")
	source=preload("res://scenes/resource_node.tscn").instantiate()
	source.name="F2FiniteThrumroot";source.visual=&"thrumroot";source.resource_id="f2-inspection-thrumroot";source.material_family=&"thrumroot";source.remaining_units=3;source.units_per_harvest=3;source.drive_presses=4;source.position=Vector3(-3,0,.5);add_child(source)
	source.set_physics_process(false)
	recovered=ART.scene("recovered-coil.glb");recovered.name="CarriedRootInspection";recovered.position=Vector3(-3,0,1.2);add_child(recovered);recovered.hide()
	recovered.set_meta("authority","Static sample visible when native pack owns roots; no pickup, inventory or collision")
	wall=_obstacle(Vector3(4.5,1.45,.5),Vector3(.22,1.2,1.0));_block(false)
	review_camera=Camera3D.new();add_child(review_camera);review_camera.make_current();review_camera.fov=48
	get_window().size=Vector2i(1440,900);DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	Engine.max_fps=0
	_ui()
	initial=SaveManager.new().capture(player)
	review_ready=true
	var args:=OS.get_cmdline_user_args()
	if "--restart" in args:await _restart();return
	if "--check" in args:await _checks();return
	if "--capture" in args:await _captures_f2();return
	if "--motion" in args:await _motion();return
	if "--benchmark" in args:await _bench();return
	manual=true;_camera("route");Input.mouse_mode=Input.MOUSE_MODE_VISIBLE

func _place_f2(kind: String,cell: Vector3i) -> ContraptionSite:
	var recipe: Dictionary=sim.recipe("assemble_"+kind)
	var before: Dictionary=sim.inventory().duplicate(true)
	check(sim.craft("assemble_"+kind).crafted,kind+" ordinary paid craft")
	for item: String in recipe.inputs:check(sim.material_count(item)==int(before.get(item,0))-int(recipe.inputs[item]),kind+" exact "+item+" spend")
	player.placement.set_build_mode_enabled(true);player.placement._select_kit(StringName(kind+"_kit"));player.placement.preview_element={"kind":"volume","axis":0,"cell":cell};player.placement.preview_rotation_step=0
	check(player.placement.element_accepts(player.placement.preview_element),kind+" physical body accepts")
	check(player.placement._place_kit(),kind+" normal kit transaction succeeds")
	var site:=ContraptionSite.find_site(get_tree(),"fixture_%d_%d_%d"%[cell.x,cell.y,cell.z])
	check(site!=null and sim.material_count(kind+"_kit")==0,kind+" exactly one owner and spent kit")
	if site!=null:site.set_physics_process(false)
	player.placement.set_build_mode_enabled(false)
	await get_tree().physics_frame
	return site

func _obstacle(at: Vector3,size: Vector3) -> StaticBody3D:
	var b:=StaticBody3D.new();b.position=at;var c:=CollisionShape3D.new();var s:=BoxShape3D.new();s.size=size;c.shape=s;b.add_child(c)
	var m:=MeshInstance3D.new();var box:=BoxMesh.new();box.size=size;m.mesh=box;var mat:=StandardMaterial3D.new();mat.albedo_color=Color("705248");m.material_override=mat;b.add_child(m);add_child(b);return b
func _block(on: bool) -> void:
	wall.visible=on;wall.collision_layer=1 if on else 0;wall.collision_mask=1 if on else 0
func _sync() -> void:
	if not is_instance_valid(drum):return
	drum.refresh_from_sim()
	var d: Dictionary=sim.contraption_state(DRUM)
	if d.is_empty():return
	if not emissions:drum._visual.set_meta("emission_off",true)
	else:drum._visual.remove_meta("emission_off")
	ART.energy(drum._visual,float(d.energy)/4.0,float(d.progress) if d.moving else 0.0,bool(d.moving))
	if drum._pulse!=null:drum._pulse.hide()
	if drum._receiver!=null:drum._receiver.hide()
	if is_instance_valid(source):
		if not emissions:source.set_meta("emission_off",true)
		else:source.remove_meta("emission_off")
		ART.source_state(source,source.remaining_units<=0)
	recovered.visible=sim.material_count("thrumroot")>0
	status.text="THRUMROOT / F2    %s\nWinding %d / 4   Cargo %d / 96   Trips %d   %s\nInspection supplies; actual paid craft and work. One drum owns the basket."%["PAUSED" if halted else "",int(d.energy),int(d.cargo.get("wood",0)),int(d.completed_trips),"Travelling %.1f%%"%(float(d.progress)*100) if d.moving else ("At landing" if d.at_landing else "At drum")]
func _step(delta: float) -> void:
	if halted:return
	elapsed+=delta
	if is_instance_valid(drum):drum._physics_process(delta)
	_sync()
func _physics_process(delta: float) -> void:
	if review_ready and manual:_step(delta)
func _ui() -> void:
	var layer:=CanvasLayer.new();add_child(layer);status=Label.new();status.position=Vector2(22,18);status.add_theme_font_size_override("font_size",20);layer.add_child(status)
	var actions:=[['Wind','wind'],['Load 20 wood','load'],['Request trip','start'],['Collect 7','collect'],['Work source','work'],['Collect roots','pickup'],['Block span','block'],['Pause','pause']]
	for i in actions.size():
		var button:=Button.new();button.text=actions[i][0];button.position=Vector2(20+i*174,840);button.size=Vector2(166,38);button.pressed.connect(_action.bind(actions[i][1]));layer.add_child(button)
	var help:=Label.new();help.position=Vector2(22,795);help.text="1 source   2 winch   3 landing   4 full span   G light off   R restore paid inspection   Esc close";layer.add_child(help)
func _action(action: String) -> void:
	if action=="pause":halted=not halted;_sync();return
	if action=="block":_block(not wall.visible);return
	if halted:return
	match action:
		"load":sim.contraption_deposit(DRUM,"wood",20)
		"collect":sim.contraption_withdraw(LANDING if sim.contraption_state(DRUM).at_landing else DRUM,"cargo","wood",7)
		"work":
			if is_instance_valid(source):player._apply_work(source,source.work(sim))
		"pickup":
			for p in get_tree().get_nodes_in_group("pickups"):p._absorb(player)
		_:drum.perform(action)
	_sync()
func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_1:_camera("source")
		KEY_2:_camera("winch")
		KEY_3:_camera("landing")
		KEY_4:_camera("route")
		KEY_G:emissions=not emissions;_sync()
		KEY_R:await _restore(initial)
		KEY_ESCAPE:get_tree().quit()
func _camera(view: String) -> void:
	var target:=Vector3(.5,1.0,.5);var offset:=Vector3(2.2,1.6,3.0)
	if view=="source":target=Vector3(-3,.4,.5);offset=Vector3(1.3,1.1,2.8)
	if view=="landing":target=Vector3(8.5,1,.5)
	if view=="recovered":target=Vector3(-3,.13,1.2);offset=Vector3(.6,.55,1.1)
	if view=="route":target=Vector3(3.5,.7,.5);offset=Vector3(3.0,5.0,11)
	review_camera.position=target+offset;review_camera.look_at(target)
func _restore(data: Dictionary) -> void:
	var manager:=SaveManager.new();check(manager.apply(player,data),"ordinary save restores: "+manager.last_error)
	_references();halted=false;_block(false)
	for frame in 3:await get_tree().physics_frame
	_sync()
func _references() -> void:
	drum=ContraptionSite.find_site(get_tree(),DRUM);landing=ContraptionSite.find_site(get_tree(),LANDING)
	for c in get_tree().get_nodes_in_group("contraptions"):c.set_physics_process(false)
	source=get_node_or_null("F2FiniteThrumroot")
	player.set_physics_process(false);player.combat.set_physics_process(false);player.placement.set_physics_process(false)
func _read(path: String) -> void:
	var manager:=SaveManager.new();check(manager.read(path,player),"ordinary separate checkpoint read: "+manager.last_error);_references()
	for frame in 3:await get_tree().physics_frame
	_sync()
func _checks() -> void:
	check(drum.supported() and landing.supported() and drum.span_clear(),"native fixed supported endpoints and clear swept span")
	check(drum._visual.get_node("Drum").position.is_equal_approx(Vector3(0,1.05,0)),"exported drum has authoritative pivot")
	check(drum.cable_anchor().is_equal_approx(drum.position+Vector3(0,1.7,0)),"unchanged cable socket")
	check(landing._basket==null,"landing cannot own a second basket")
	var count:=sim.contraption_ids().size();sim.add_material("cargo_winch_kit",1)
	check(not sim.contraption_place("cargo_winch",DRUM,drum.position,0) and sim.material_count("cargo_winch_kit")==1 and sim.contraption_ids().size()==count,"failed placement retains kit and native scene count")
	check(sim.consume_material("cargo_winch_kit",1),"remove unused explicitly granted refusal probe kit")
	for step in 2:player._apply_work(source,source.work(sim))
	check(source.drive_progress==2 and source.remaining_units==3 and sim.material_count("thrumroot")==0,"two ordinary work presses preserve finite source ownership")
	check(SaveManager.new().write("user://f2-partial.json",player),"real partial source save")
	for step in 2:player._apply_work(source,source.work(sim))
	check(source.remaining_units==0 and sim.material_count("thrumroot")==0,"fourth press releases but does not duplicate carried roots")
	for p in get_tree().get_nodes_in_group("pickups"):p._absorb(player)
	check(sim.material_count("thrumroot")==3,"ordinary pickup collects the exact finite three roots")
	for frame in 30:await get_tree().physics_frame
	check(not is_instance_valid(source),"depleted source leaves no second harvest owner")
	check(not drum.perform("start").ok,"unwound request creates no trip")
	_step(8);check(not sim.contraption_state(DRUM).moving,"unpaid request is not queued")
	check(sim.contraption_deposit(DRUM,"wood",20).moved==20 and sim.material_count("wood")==0,"real basket deposit debits pack exactly once")
	check(drum.perform("wind").ok and sim.contraption_state(DRUM).energy==1,"one real winding stores one operation")
	check(drum.perform("start").ok and sim.contraption_state(DRUM).energy==0,"real trip spends one winding at departure")
	_step(.4);var held: String=sim.contraption_save();var pose: Vector3=drum._basket.global_position;var rotation: Vector3=drum._visual.get_node("Drum").rotation
	check(is_equal_approx(sim.contraption_state(DRUM).progress,.15),"eight-metre trip advances 1.2m at native speed")
	_block(true);for frame in 2:await get_tree().physics_frame
	check(not drum.span_clear(),"physical wall blocks actual native basket sphere sweep")
	_step(8);check(sim.contraption_save()==held and drum._basket.global_position.is_equal_approx(pose) and drum._visual.get_node("Drum").rotation.is_equal_approx(rotation),"blocked native cargo and actual moving parts stay still")
	_block(false);for frame in 2:await get_tree().physics_frame
	halted=true;_step(8);check(sim.contraption_save()==held,"explicit review pause freezes native trip")
	halted=false
	check(SaveManager.new().write("user://f2-midtrip.json",player),"ordinary mid-trip save writes exact native owner")
	_step(10);check(sim.contraption_state(DRUM).at_landing and sim.contraption_state(DRUM).completed_trips==1,"one arrival after paid travel")
	check(sim.contraption_withdraw(LANDING,"cargo","wood",7).moved==7 and sim.contraption_state(DRUM).cargo.wood==13,"partial collection leaves thirteen at the one drum owner")
	check(sim.contraption_state(LANDING).cargo.is_empty(),"landing forwards collection without inventory copy")
	check(sim.contraption_withdraw(LANDING,"cargo","wood",96).moved==13 and sim.material_count("wood")==20,"remainder collection conserves all twenty")
	check(not sim.contraption_withdraw(LANDING,"cargo","wood",96).ok,"empty basket cannot pay twice")
	check(drum.perform("wind").ok and drum.perform("start").ok,"empty return also pays one hand winding")
	_step(.25)
	var roots:=sim.material_count("thrumroot");var wood:=sim.material_count("wood");var iron:=sim.material_count("iron_ingot")
	check(sim.contraption_remove(LANDING).ok,"remove endpoint during paid return")
	landing.free();landing=null;_sync()
	var d: Dictionary=sim.contraption_state(DRUM)
	check(not d.moving and not d.at_landing and d.progress==0 and String(d.link).is_empty(),"landing removal recalls same basket without phantom travel")
	check(sim.material_count("thrumroot")==roots and sim.material_count("wood")==wood+3 and sim.material_count("iron_ingot")==iron,"landing half common refund has no second rare core or rounded-up iron")
	check(sim.contraption_deposit(DRUM,"wood",9).moved==9,"load recall basket")
	wood=sim.material_count("wood");iron=sim.material_count("iron_ingot")
	check(sim.contraption_remove(DRUM).ok,"dismantle loaded drum")
	check(sim.material_count("thrumroot")==roots+1 and sim.material_count("wood")==wood+13 and sim.material_count("iron_ingot")==iron+1,"drum refunds one intact root, four wood, one iron and all nine cargo")
	check(not sim.contraption_remove(DRUM).ok,"no repeat refund")
	_done("checks")
func _restart() -> void:
	await _read("user://f2-partial.json")
	check(source!=null and source.drive_progress==2 and source.remaining_units==3 and sim.material_count("thrumroot")==0,"fresh process preserves exact partial source")
	await _read("user://f2-midtrip.json")
	var d: Dictionary=sim.contraption_state(DRUM)
	check(d.moving and is_equal_approx(d.progress,.15) and d.energy==0 and d.cargo.wood==20,"fresh process exact paid trip, drive and cargo")
	check(source==null and sim.material_count("thrumroot")==3,"depleted source and collected finite roots stay settled")
	check(get_tree().get_nodes_in_group("contraptions").size()==2 and landing._basket==null,"restart has two endpoints and one basket")
	var held:=sim.contraption_save();_block(true);for frame in 2:await get_tree().physics_frame
	_step(20);check(sim.contraption_save()==held,"blocked fresh restart cannot advance")
	_block(false);for frame in 2:await get_tree().physics_frame
	_step(10);check(sim.contraption_state(DRUM).completed_trips==1,"fresh process arrives exactly once")
	check(sim.contraption_withdraw(LANDING,"cargo","wood",7).moved==7,"restart partial collection")
	check(SaveManager.new().write("user://f2-collected.json",player),"save partial cargo collection")
	await _read("user://f2-collected.json")
	check(sim.material_count("wood")==7 and sim.contraption_state(DRUM).cargo.wood==13,"restore partial collection cannot duplicate")
	check(sim.contraption_withdraw(LANDING,"cargo","wood",96).moved==13 and not sim.contraption_withdraw(LANDING,"cargo","wood",96).ok,"restore pays remaining cargo only once")
	_done("restart")
func _shot(name: String) -> void:
	_sync();for i in 8:await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUT+RenderingServer.get_current_rendering_method()+"-"+name+".png")
func _captures_f2() -> void:
	for view in ["source","winch","landing","route"]:_camera(view);await _shot(view)
	_camera("source");_action("work");_action("work");await _shot("source-worked")
	emissions=false;await _shot("source-emission-off");emissions=true
	_action("work");_action("work");_action("pickup");for i in 30:await get_tree().physics_frame
	await _shot("source-depleted");_camera("recovered");await _shot("recovered")
	_camera("winch");_action("load");_action("wind");await _shot("wound-loaded")
	_action("start");_step(.9);_camera("route");await _shot("travelling")
	_block(true);for i in 2:await get_tree().physics_frame
	_step(2);await _shot("blocked")
	_block(false);for i in 2:await get_tree().physics_frame
	_step(10);_camera("landing");await _shot("arrived")
	_camera("winch");emissions=false;await _shot("emission-off")
	sun.light_energy=.18;environment.ambient_light_energy=.23;await _shot("shade")
	_done("capture")
func _motion() -> void:
	var detail:="--close" in OS.get_cmdline_user_args()
	_action("load");_action("wind");_action("start");_camera("winch" if detail else "route")
	var renderer:=RenderingServer.get_current_rendering_method()+('-detail' if detail else '')
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT+renderer+"-motion"))
	for frame in 108:
		if frame==24:_block(true)
		if frame==48:_block(false)
		await get_tree().physics_frame;_step(1.0/24.0)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(OUT+renderer+"-motion/%04d.png"%frame)
		observations.append({"frame":frame,"native":sim.contraption_state(DRUM),"basket":var_to_str(drum._basket.global_position),"drum":var_to_str(drum._visual.get_node("Drum").rotation),"blocked":wall.visible})
	check(sim.contraption_state(DRUM).completed_trips==1,"recorded sequence completes one paid trip")
	FileAccess.open(OUT+renderer+"-motion.json",FileAccess.WRITE).store_string(JSON.stringify(observations,"\t"));_done("detail-motion-checks" if detail else "motion-checks")
func _bench() -> void:
	_camera("route");_sync();var frames: Array[float]=[]
	for i in 120:await get_tree().process_frame
	var previous:=Time.get_ticks_usec()
	for i in 600:
		await get_tree().process_frame;var now:=Time.get_ticks_usec();frames.append((now-previous)/1000.0);previous=now
	frames.sort()
	var data:={"device":RenderingServer.get_video_adapter_name(),"renderer":RenderingServer.get_current_rendering_method(),"size":[1440,900],"vsync":"off","samples":600,"p50_ms":frames[300],"p95_ms":frames[570],"worst_ms":frames[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"scope":"settled isolated native study; no captures/generation during measurement"}
	FileAccess.open(OUT+RenderingServer.get_current_rendering_method()+"-benchmark.json",FileAccess.WRITE).store_string(JSON.stringify(data,"\t"));_done("benchmark-checks")
func _done(mode: String) -> void:
	var result:={"checks":checks,"failures":failures,"mode":mode,"renderer":RenderingServer.get_current_rendering_method()}
	FileAccess.open(OUT+RenderingServer.get_current_rendering_method()+"-"+mode+".json",FileAccess.WRITE).store_string(JSON.stringify(result,"\t"))
	print("F2_",mode.to_upper()," ",checks," checks ",failures," failures")
	get_tree().quit(0 if failures==0 else 1)
