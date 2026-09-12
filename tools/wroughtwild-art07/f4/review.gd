extends "res://tests/pressure_workshop.gd"
## Extends unchanged generated workshop checks; explicit inspection stock, native work.
const F4_SAVE := "user://f4-held.json"
var f4_output := ""
var f4_frames: Array = []
var f4_done := false
var f4_pose := Vector3.ZERO
var f4_key := ""
var f4_camera: Camera3D
var f4_caption: Label

func _ready() -> void:
	get_window().size=Vector2i(1600,900)
	get_viewport().msaa_3d=Viewport.MSAA_4X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	f4_output=ProjectSettings.globalize_path("res://../evidence/"+RenderingServer.get_current_rendering_method())
	DirAccess.make_dir_recursive_absolute(f4_output)
	var args:=OS.get_cmdline_user_args()
	if args.has("--restore") or args.has("--restore-exhausted") or args.has("--benchmark") or args.has("--play"):
		await _restore_f4()
		return
	await super._ready()

func _camera() -> void:
	if f4_camera!=null:return
	player.hud.hide();player.hide();player.camera.current=false
	f4_camera=Camera3D.new();f4_camera.fov=48;add_child(f4_camera);f4_camera.current=true
	var canvas:=CanvasLayer.new();add_child(canvas);f4_caption=Label.new();f4_caption.position=Vector2(24,22);f4_caption.add_theme_font_size_override("font_size",22);canvas.add_child(f4_caption)
	var env: Environment=$WorldEnvironment.environment
	env.tonemap_mode=Environment.TONE_MAPPER_LINEAR;env.glow_enabled=false

func _view(at: Vector3,offset:=Vector3(2.5,1.8,3)) -> void:
	_camera();f4_camera.global_position=at+offset;f4_camera.look_at(at+Vector3.UP*.7)

func _shot(id: String,text: String) -> void:
	_camera();f4_caption.text="ART-07F4 / "+RenderingServer.get_current_rendering_method()+"\n"+text
	if not OS.get_cmdline_user_args().has("--capture"):return
	for i in 2:await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(f4_output.path_join(id+".png"))==OK,"actual rendered "+id)

func _record(id: String,work: Vector3) -> void:
	if id=="struck-hearth":
		_view(source.global_position)
		var before:=_sim().contraption_save()
		for i in 30:source.set_highlight(i%2==0);source.refresh_visual()
		check(_sim().contraption_save()==before,"pocket hover/visual refresh cannot create pressure")
		check(source.connection_anchor()==source.global_position+Vector3.UP*.85,"pocket exact native centre-height anchor")
		await _shot("01-pocket-full","FINITE POCKET / 24 native strokes / reused scarred old hearth and folded reservoir")
	elif id=="working":
		f4_pose=feeder.global_position;f4_key=feeder.machine_key
		await _geometry()
		_view(feeder.global_position,Vector3(2.2,1.75,2.5))
		await _shot("03-paid-firing","PAID FIRING / separate clay, fuel, root drive, membrane and fired-brick tray")
		feeder.interact(player);await _shot("04-native-controls","NATIVE CONTROLS / existing escrow, loading and drive ownership");player.work_panel.close_panel()
		for i in 30:
			feeder._physics_process(1.0/30.0)
			f4_frames.append(_frame(i,"working"))
			await _shot("motion-%03d"%i,"PAID WORK / 30 Hz native ticks; no shader TIME")
		check(feeder.perform("pause").ok,"F4 explicit pause accepts")
		var held:=_sim().contraption_save();var pose: Transform3D=feeder._visual.get_node("Drum").transform
		for i in 15:
			feeder._physics_process(1.0/30.0)
			check(_sim().contraption_save()==held and feeder._visual.get_node("Drum").transform==pose,"paused ownership and drum stay exact")
			f4_frames.append(_frame(i+30,"paused"));await _shot("motion-%03d"%(i+30),"PAUSED / reserved native work held exactly")
		check(SaveManager.new().write(F4_SAVE,player),"write fractional paused firing and generated geography to isolated disk")
		await _shot("05-paused","PAUSED / this exact native checkpoint is reopened in another process")
		check(feeder.perform("resume").ok,"F4 native resume accepts")
		var blocker:=StaticBody3D.new();var collision:=CollisionShape3D.new();collision.shape=BoxShape3D.new();collision.shape.size=Vector3(.24,.40,.24);blocker.add_child(collision)
		blocker.position=(feeder.global_position+forge.global_position)*.5+Vector3.UP*.85;add_child(blocker)
		for i in 3:await get_tree().physics_frame
		check(not feeder.feeder_status().ready,"actual forge connection obstruction refuses work")
		held=_sim().contraption_save();pose=feeder._visual.get_node("Drum").transform
		for i in 15:
			feeder._physics_process(1.0/30.0)
			check(_sim().contraption_save()==held and feeder._visual.get_node("Drum").transform==pose and not feeder._visual.get_meta("working"),"blocked work neither advances nor emits a working pulse")
			f4_frames.append(_frame(i+45,"blocked"));await _shot("motion-%03d"%(i+45),"BLOCKED / real physics obstruction holds paid progress")
		await _shot("06-blocked","BLOCKED / same escrow; no duplicated heat or drive")
		blocker.free();for i in 3:await get_tree().physics_frame
		var before:=_sim().contraption_save()
		F4Art.emission_off=true;feeder.refresh_from_sim();source.refresh_visual()
		await _shot("07-emission-off","EMISSION OFF / inherited geometric root and membrane scars remain")
		check(_sim().contraption_save()==before,"emission-off inspection is read-only")
		_view(feeder.global_position,Vector3(-2.2,1.55,-2.5))
		await _shot("07-rear-emission-off","REAR / complete reused root drum and crank; emission disabled")
		F4Art.emission_off=false;feeder.refresh_from_sim()
		var lights: Array=[]
		for light in find_children("*","DirectionalLight3D",true,false):
			lights.append([light,light.visible]);light.hide()
		await _shot("07-shade","SHADE / native paid-progress scar response; no free-running clock")
		for entry in lights:entry[0].visible=entry[1]
		_view((feeder.global_position+source.global_position+forge.global_position)/3,Vector3(6,3.8,7))
		await _shot("08-both-attachments","ACTUAL GENERATED SITE / native centre-height forge and finite-pocket connections")
	elif id=="rebuilt":
		_view(feeder.global_position)
		await _shot("09-paid-brick-building","OUTPUT COLLECTED / existing native bricks paid for the nearby masonry")

func _frame(index: int,label: String) -> Dictionary:
	return {"frame":index,"state":label,"native":_sim().contraption_state(feeder.machine_key),"drum":str(feeder._visual.get_node("Drum").transform),"bellows":str(feeder._visual.get_node("Bellows").transform),"working":feeder._visual.get_meta("working")}

func _place_workshop(work: Vector3) -> void:
	await super._place_workshop(work)
	if feeder==null:return
	_sim().add_material("pressure_feeder_kit",1) # Refusal stock, exact failed transaction.
	var build:=player.placement;build.set_build_mode_enabled(true);build._select_kit(&"pressure_feeder_kit")
	build.preview_element={"kind":"volume","axis":0,"cell":Vector3i(floori(feeder.position.x/.5),roundi(feeder.position.y/.5),floori(feeder.position.z/.5))};build.preview_visible=true
	var before:=_sim().contraption_save();var kits:=_sim().material_count("pressure_feeder_kit")
	check(not build.try_place_block() and kits==_sim().material_count("pressure_feeder_kit") and _sim().contraption_save()==before,"real occupied placement keeps the kit and adds no native object")
	build.set_build_mode_enabled(false)
	check(get_tree().get_nodes_in_group("contraptions").size()==1,"successful original placement creates exactly one usable feeder")
	_view(feeder.global_position)
	await _shot("02-empty-feeder","EMPTY / paid placed kit, no clay, fuel, energy or completed output")

func _geometry() -> void:
	check(feeder.get_child(0) is CollisionShape3D,"original direct collision child remains")
	check(feeder.get_child(0).shape.size==Vector3(1.5,1.45,1.45),"feeder complete native body unchanged")
	for name in ["Hopper","FuelCup","OutputTray","Drum","Bellows","ConnectionAnchor"]:check(feeder._visual.has_node(name),"distinct exported role "+name)
	check(feeder._visual.get_node("Drum").position.is_equal_approx(Vector3(.33,.66,.02)),"feeder pivot is its own native pivot, not the winch mount")
	check(feeder._visual.get_node("ConnectionAnchor").position.is_equal_approx(Vector3(0,.85,0)),"both connections retain exact native origin")
	for level in ["near","middle","far"]:
		for kind in ["feeder","pocket"]:
			var root:=F4Art.visual(kind,level);var mesh:=ArrayMesh.new();AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh)
			var size:=Vector3(1.5,1.45,1.45) if kind=="feeder" else Vector3(1.05,1.25,1.05)
			check(AABB(Vector3(-size.x/2,0,-size.z/2),size).grow(.00001).encloses(mesh.get_aabb()),kind+level+" full imported bounds fit native body")
			root.free()
	for phase in [0.0,.25,.50,.75,1.0]:
		var drum: Node3D=feeder._visual.get_node("Drum");var before:=drum.rotation.x;drum.rotation.x=phase*TAU
		var mesh:=ArrayMesh.new();AuthoredAssets._collect(feeder._visual,Transform3D.IDENTITY,mesh)
		check(AABB(Vector3(-.75,0,-.725),Vector3(1.5,1.45,1.45)).grow(.00001).encloses(mesh.get_aabb()),"full swept crank fits native body")
		drum.rotation.x=before
	var record:=_sim().contraption_state(feeder.machine_key)
	check(is_equal_approx(feeder._visual.get_node("Drum").rotation.x,(float(record.energy)*.25+float(record.cycle_seconds)/8.0)*TAU),"native feeder winding formula unchanged")

func _restore_f4() -> void:
	world_profile="frontier_v5";world_seed=77
	var exhausted:=OS.get_cmdline_user_args().has("--restore-exhausted")
	var path:="user://f4-exhausted.json" if exhausted else F4_SAVE
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(path))
	if saved.is_empty():printerr("F4 checkpoint missing: run --check first");get_tree().quit(1);return
	world_seed=int(saved.world_seed);world_profile=String(saved.world_profile)
	_build_world(world_seed);player.class_panel.choose("warden");player.set_physics_process(false);player.combat.set_physics_process(false);player.placement.set_physics_process(false);mob_packs.set_physics_process(false);mob_packs.set_process(false);set_physics_process(false)
	await get_tree().physics_frame
	var manager:=SaveManager.new();check(manager.read(path,player),"fresh process uses ordinary SaveManager: "+manager.last_error)
	check(JSON.parse_string(_sim().export_json())==JSON.parse_string(saved.sim),"exact inventory and progression restored")
	check(JSON.parse_string(_sim().contraption_save())==JSON.parse_string(saved.contraptions),"exact finite source, escrow, progress, output and drive restored")
	for n in get_tree().get_nodes_in_group("contraptions"):
		if n.kind=="pressure_feeder":feeder=n;feeder_key=n.machine_key;feeder.set_physics_process(false)
	var state:=_sim().contraption_state(feeder_key);forge=feeder.feeder_forge(String(state.forge_key));source=PressurePocket.find_source(get_tree(),String(state.source_id))
	terrain.ensure_area(feeder.global_position,24);player.global_position=feeder.global_position+Vector3(0,1.2,3)
	for i in 4:await get_tree().physics_frame
	check(source!=null and forge!=null and feeder.feeder_status().ready,"restored physical forge and pocket attachments are usable")
	await _geometry();_view(feeder.global_position)
	if exhausted:
		check(source.source_state().remaining==0 and not source._membrane.visible,"fresh spent pocket remains visibly exhausted")
		var before:=_sim().contraption_save()
		check(not feeder.perform("charge").ok and before==_sim().contraption_save(),"fresh spent pocket cannot supply free pressure")
		_view(source.global_position);await _shot("14-exhausted-reload","FRESH EXHAUSTED SOURCE / exact zero stock; hand-wound drive retained")
		await _end_f4("exhausted-restore");return
	await _shot("10-fresh-process","FRESH PROCESS / exact paid escrow, finite source and native pose")
	if OS.get_cmdline_user_args().has("--play"):
		feeder.set_physics_process(true);Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;f4_caption.text="F4 / E native controls  W wind  F start  P pause/resume  X cancel  K collect  G emission  Esc quit";return
	if OS.get_cmdline_user_args().has("--benchmark"):
		await _benchmark_f4();await _end_f4("benchmark");return
	check(feeder.perform("resume").ok,"fresh paused firing resumes normally")
	feeder._physics_process(8)
	check(int(_sim().contraption_state(feeder_key).output.get("rustclay_brick",0))==4,"fresh resumed firing pays four bricks exactly once")
	await _shot("11-completed-tray","FOUR FIRED BRICKS / representative model of actual native output")
	check(feeder.perform("cancel").ok,"cancel next reserved cycle through native operation")
	var held:=_sim().contraption_save();check(not feeder.perform("cancel").ok and _sim().contraption_save()==held,"repeated fresh-process cancel cannot duplicate ownership")
	await _end_f4("restore")

func _finish() -> void:
	if f4_done:return
	f4_done=true
	if failures==0 and not f4_key.is_empty():await _exhaust()
	await _end_f4("checks")

func _exhaust() -> void:
	# Recovered kit plus explicitly supplied recipe difference supports a real
	# finite-stock drain; this never edits or resets source remaining/capacity.
	check(_sim().contraption_place("pressure_feeder","f4_exhaust",f4_pose,0),"new paid inspection kit owns the exhaustion fixture")
	feeder=ContraptionSite.new();feeder.machine_key="f4_exhaust";feeder.sim=_sim();add_child(feeder);feeder.set_physics_process(false);feeder_key=feeder.machine_key
	for i in 3:await get_tree().physics_frame
	check(feeder.attach_feeder(forge.station_key,source.source_id).ok,"exhaustion fixture attaches both real endpoints")
	_sim().add_materials({"raw_clay":160,"wood":20})
	for batch in 5:
		check(feeder.perform("charge").ok,"draw finite source into available native store")
		check(_sim().contraption_deposit(feeder_key,"raw_clay",32).moved==32,"load exact batch clay")
		check(_sim().contraption_deposit(feeder_key,"wood",4).moved==4,"load exact batch fuel")
		check(feeder.perform("start").ok,"start actual finite-pressure batch")
		for cycle in 4:feeder._physics_process(8)
		check(_sim().contraption_withdraw(feeder_key,"output","rustclay_brick",16).moved==16,"collect exactly sixteen paid bricks per batch")
	source.refresh_visual();check(source.source_state().remaining==0 and not source._membrane.visible,"exhausted native source hides its finite reservoir without refilling")
	_view(source.global_position);await _shot("12-pocket-exhausted","EXHAUSTED / all 24 source strokes spent through native charging and paid firings")
	var before:=_sim().contraption_save();check(not feeder.perform("charge").ok and before==_sim().contraption_save(),"spent pocket cannot generate another operation")
	check(feeder.perform("wind").ok,"ordinary hand winding remains usable after source exhaustion")
	check(SaveManager.new().write("user://f4-exhausted.json",player),"save exhausted geography and new hand-wound store")
	_view(feeder.global_position)
	for level in ["near","middle","far"]:
		var previous:=feeder._visual
		var loads: Array=[feeder._hopper_load,feeder._fuel_load,feeder._output_load]
		for node: Node in loads:previous.remove_child(node)
		feeder.remove_child(previous);previous.free();feeder._visual=F4Art.visual("feeder",level);feeder.add_child(feeder._visual)
		for node: Node in loads:feeder._visual.add_child(node)
		feeder.refresh_from_sim()
		await _shot("13-detail-"+level,"EXPLICIT "+level.to_upper()+" / conservative Ventlung far retains its folded middle silhouette")

func _benchmark_f4() -> void:
	# Separate process; fixed camera and held native state, no generation/captures.
	var shadows:=not OS.get_cmdline_user_args().has("--no-shadows")
	if not shadows:
		for light in find_children("*","DirectionalLight3D",true,false):light.shadow_enabled=false
	for i in 132:await get_tree().process_frame
	var samples: Array[float]=[];var previous:=Time.get_ticks_usec()
	for i in 600:
		await get_tree().process_frame
		var now:=Time.get_ticks_usec();samples.append(float(now-previous)/1000);previous=now
	samples.sort()
	var record:={"renderer":RenderingServer.get_current_rendering_method(),"device":RenderingServer.get_video_adapter_name(),"resolution":[1600,900],"warmup":132,"frames":600,"p50_ms":samples[300],"p95_ms":samples[570],"worst_ms":samples[-1],"draws":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),"primitives":Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),"texture_bytes":Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED),"scope":"generated smithy, one E2 forge, one F4 feeder/pocket; explicit near; no capture"}
	record["directional_shadows"]=shadows
	var file:=FileAccess.open(f4_output.path_join("timings.json" if shadows else "timings-no-shadows.json"),FileAccess.WRITE);file.store_string(JSON.stringify(record,"\t"))

func _end_f4(mode: String) -> void:
	var file:=FileAccess.open(f4_output.path_join(mode+".json"),FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"frames":f4_frames,"seed":world_seed,"profile":world_profile},"\t"));file.close()
	print("F4_",mode.to_upper()," ",checks," checks, ",failures," failures")
	for child in get_children():child.queue_free()
	await get_tree().process_frame;await get_tree().process_frame;get_tree().quit(1 if failures else 0)

func _unhandled_input(event: InputEvent) -> void:
	if not OS.get_cmdline_user_args().has("--play") or not event is InputEventKey or not event.pressed or event.echo:return
	match event.keycode:
		KEY_ESCAPE:get_tree().quit()
		KEY_E:feeder.interact(player)
		KEY_W:feeder.perform("wind")
		KEY_F:feeder.perform("start")
		KEY_P:feeder.perform("resume" if _sim().contraption_state(feeder_key).feeder_paused else "pause")
		KEY_X:feeder.perform("cancel")
		KEY_K:
			var store: Dictionary=_sim().contraption_state(feeder_key).output
			for item: String in store:_sim().contraption_withdraw(feeder_key,"output",item,int(store[item]))
		KEY_G:F4Art.emission_off=not F4Art.emission_off;feeder.refresh_from_sim();source.refresh_visual()
