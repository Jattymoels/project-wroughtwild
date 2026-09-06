extends Node3D
## Isolated, deterministic inspection of real committed Foundry routes. Actors
## and clocks pause for screenshots; the images never substitute fake effects.
const STRIKE := &"prototype_heavy_strike"
const NOVA := &"prototype_frost_nova"
var player: WroughtwildPlayer
var combat: PlayerCombat
var sim: WroughtwildSim
var camera: Camera3D
var title: Label
var subtitle: Label
var detail: Label
var output := ""
var checks := 0
var failures := 0
var records: Array = []

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)

func _ready() -> void:
	get_window().size = Vector2i(1600,1000)
	output = OS.get_environment("WW_FOUNDRY_CAPTURE")
	if output.is_empty(): output = ProjectSettings.globalize_path("res://../../../../build/foundry-identity/captures")
	DirAccess.make_dir_recursive_absolute(output)
	_court()
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.first_person = false
	player._apply_camera_mode()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.placement.set_physics_process(false)
	combat = player.combat
	combat.set_physics_process(false)
	sim = combat.sim
	player.hud.visible = false
	var hands = player.camera.get_node_or_null("FirstPersonHands")
	if hands != null:
		hands.visible = false
		hands.set_process(false)
	camera = Camera3D.new()
	add_child(camera)
	camera.position = Vector3(6,6.8,9)
	camera.look_at(Vector3(.7,.4,1))
	camera.fov = 44
	camera.current = true
	_ui()
	for i in 4: await get_tree().physics_frame
	await _cinder(false)
	await _afterimage()
	await _cinder(true)
	await _refrain()
	await _wide()
	var file := FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE)
	check(file!=null,"capture manifest opens")
	if file != null:
		file.store_string(JSON.stringify({"checks":checks,"failures":failures,"method":"Real use_skill commits and positive native hits; deterministic actor positions and paused clocks for review, no user save.","captures":records},"  "))
	print("FOUNDRY_IDENTITY_REVIEW: %d checks, %d failures, %d captures"%[checks,failures,records.size()])
	get_tree().quit(1 if failures else 0)

func _clear() -> void:
	for group in ["foundry_tempo","foundry_fields","foundry_cold","foundry_embers","foundry_returns","foundry_echoes","foundry_puffs","foundry_guards","foundry_sustain","foundry_offence","enemies","player_projectiles","enemy_projectiles","skill_bursts","skill_cast_effects"]:
		for node in get_tree().get_nodes_in_group(group): node.free()
	for id in combat.cooldowns: combat.cooldowns[id] = 0
	combat._mutation_cache.clear()
	combat._reaction_ready.clear()
	combat._action_contexts.clear()
	combat._casts.clear()
	combat.fight_active = false
	combat.fight_seed_source.seed = 92524
	combat.clear_verbs()
	combat.clear_train()
	player.position = Vector3(0,1,2)
	player.rotation = Vector3.ZERO

func _route(skill: StringName, kind: String, ingot: String, combined := false) -> Dictionary:
	_clear()
	sim.add_material("iron_ingot",100)
	for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row,piece.col),"lift old route")
	sim.learn_skill(skill)
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer","recipe:workbench_kit","first_kill:stone_husk","world_effect:stonecut_blocks","first_kill:ash_hound"]: sim.foundry_event(event)
	sim.add_material(kind,2)
	check(sim.foundry_place_skill(1,1,skill),"commit skill tablet")
	check(sim.foundry_place(1,0,ingot) and sim.foundry_place_kind(2,0,kind),"commit inward "+kind+" and "+ingot+" route")
	if combined:
		check(sim.foundry_place(1,2,"haste") and sim.foundry_place_kind(1,3,"quicksilver"),"commit independent second Quicksilver / Haste route to the same skill")
	combat._mutation_cache.clear()
	return combat.mutation(skill)

func _enemy(at: Vector3, label: String) -> Enemy:
	var node := Enemy.spawn(self,&"ember_whelp",at)
	node.set_physics_process(false)
	node.life = 1000
	node.max_life = 1000
	node.set_meta("review_role",label)
	return node

func _freeze() -> void:
	for group in ["foundry_tempo","skill_bursts","skill_cast_effects","foundry_puffs","player_projectiles"]:
		for node in get_tree().get_nodes_in_group(group):
			node.set_physics_process(false)
			node.set_process(false)

func _cast(skill: StringName) -> void:
	check(combat.use_skill(skill),"actual ready skill commits "+String(skill))
	check(bool(combat.action_context(skill).get("practice_allowed",false)),"actual cast owns a real input context")
	_freeze()

func _elapsed(seconds: float) -> void:
	combat._fight_clock += seconds
	for id in combat.cooldowns: combat.cooldowns[id] = maxf(0,float(combat.cooldowns[id])-seconds)
	for enemy in get_tree().get_nodes_in_group("enemies"): enemy._tick_statuses(seconds)
	for node in get_tree().get_nodes_in_group("foundry_tempo"):
		if node.remaining>0 and not node.is_queued_for_deletion(): node.advance(seconds)
	for node in get_tree().get_nodes_in_group("skill_bursts"):
		if not node.is_queued_for_deletion(): node.advance(seconds)
	for node in get_tree().get_nodes_in_group("skill_cast_effects"):
		if not node.is_queued_for_deletion(): node._process(seconds)
	_freeze()

func _cinder(combined: bool) -> void:
	var form := _route(STRIKE,"quicksilver","ember",combined)
	check(float(form.get("identity_tempo_cinder_fraction",0))>0,"Cinder Wake compiles")
	if combined: check(float(form.get("identity_tempo_after_fraction",0))>0,"Afterimage compiles alongside Cinder Wake")
	var primary := _enemy(Vector3(0,0,0),"FIRST HIT")
	var crossing := _enemy(Vector3(1.4,0,2),"CROSSES SEAM")
	var next := _enemy(Vector3(3,0,0),"NEXT CAST TARGET")
	_cast(STRIKE)
	check(primary.life<1000,"Heavy Strike really hits its first victim")
	player.position.x = 3
	_elapsed(.1)
	check(crossing.life<1000,"actual Cinder Wake seam hits a crossing enemy")
	var after := crossing.life
	_elapsed(.1)
	check(is_equal_approx(crossing.life,after),"actual seam does not pulse")
	await _capture("combined-ready" if combined else "cinder-wake", "HEAVY STRIKE  /  CINDER WAKE + AFTERIMAGE" if combined else "HEAVY STRIKE  /  CINDER WAKE", "HIT → MOVE: the short fire seam is now live." if not combined else "ONE SKILL, TWO ROUTES: movement draws the seam; the paired echo rings still wait for a recast.","The first target is excluded from the seam. A crossing enemy is hit once, with no repeated pulse.")
	if combined:
		_elapsed(maxf(0,float(combat.cooldowns.get(STRIKE,0)))+.01)
		var arrival := _enemy(Vector3(0,0,2),"ECHO ARRIVAL")
		_cast(STRIKE)
		check(arrival.life<1000 and next.life<1000,"combined route preserves direct melee and pays its old-position echo")
		await _capture("combined-release","HEAVY STRIKE  /  TWO INDEPENDENT PAYOFFS","RECAST: the old-position echo discharges while the direct melee strike still hits in front.","Both names retain their own trigger. Native rules cap each packet; neither creates another cast.")

func _afterimage() -> void:
	_route(STRIKE,"quicksilver","haste")
	var primary := _enemy(Vector3(0,0,0),"FIRST HIT")
	var arrival := _enemy(Vector3(0,0,2),"WAITS IN OLD POSITION")
	var next := _enemy(Vector3(3,0,0),"NEXT CAST TARGET")
	_cast(STRIKE)
	check(primary.life<1000,"plain Heavy Strike delivery remains intact")
	player.position.x = 3
	_elapsed(.1)
	check(is_equal_approx(arrival.life,1000),"Afterimage movement alone deals no damage")
	await _capture("afterimage-ready","HEAVY STRIKE  /  AFTERIMAGE","MOVE: the old casting position keeps its paired rings. Nothing has discharged yet.","This uses the same melee skill as Cinder Wake. Moving does not create a damaging trail.")
	_elapsed(maxf(0,float(combat.cooldowns.get(STRIKE,0)))+.01)
	_cast(STRIKE)
	check(arrival.life<1000 and next.life<1000,"recast pays old-position echo and current direct attack")
	await _capture("afterimage-release","HEAVY STRIKE  /  AFTERIMAGE","RECAST FROM ELSEWHERE: one physical echo flashes at the old position.","The warm-white flash is the actual terminal effect. It deals no duplicate payload and does not pulse.")

func _refrain() -> void:
	_route(STRIKE,"striking_quicksilver","frost")
	var first := _enemy(Vector3(0,0,0),"FIRST TARGET")
	var second := _enemy(Vector3(3,0,0),"SECOND TARGET")
	_cast(STRIKE)
	_elapsed(maxf(0,float(combat.cooldowns.get(STRIKE,0)))+.01)
	player.position.x = 3
	_cast(STRIKE)
	check(first.life<1000 and second.life<1000,"two true attacks hit different targets")
	var node := FoundryTempo.live(combat,"s_frost")
	check(node!=null and node.phase==1,"target switch launches the returning chill mote")
	if node != null: node.advance(.16)
	await _capture("frost-refrain-return","HEAVY STRIKE  /  FROST REFRAIN","HIT A DIFFERENT FOE: a cold mote returns to the first target.","Target selection replaces a generic repeated attack. The chill budget waits for the mote to arrive.")
	if node != null: node.advance(.5)
	check(first.chill>0,"returning mote applies native chill on arrival")
	await _capture("frost-refrain-arrival","HEAVY STRIKE  /  FROST REFRAIN","ARRIVAL: the first target receives chill; the second was the delivery decision.","The sequence uses separate positive hits. Duplicated callbacks and linked casts cannot advance it.")

func _wide() -> void:
	_route(NOVA,"casting_quicksilver","reach")
	var centre := _enemy(Vector3(0,0,0),"SAFE ECHO CENTRE")
	var outside := _enemy(Vector3(2.7,0,0),"OUTER RING")
	_cast(NOVA)
	var node := FoundryTempo.live(combat,"c_wide")
	check(node!=null,"real spell hit leaves Wide Echo")
	var centre_life := centre.life
	var outside_life := outside.life
	_elapsed(.3)
	await _capture("wide-echo-ready","FROST NOVA  /  WIDE ECHO","SPELL HIT → DELAY: the outer ring is dangerous; its centre stays safe.","The original spell retains its own area delivery. Wide Echo adds one bounded, hollow delayed shape.")
	if node != null: node.advance(.4)
	check(is_equal_approx(centre.life,centre_life),"Wide Echo leaves its centre safe")
	check(outside.life<outside_life,"Wide Echo pays a native cold packet on the outer ring")
	await _capture("wide-echo-resolved","FROST NOVA  /  WIDE ECHO","DISCHARGE: only the outer-ring target loses additional life.","The two circles previewed the exact safe centre and dangerous outer area; no whole-arena pulse was added.")

func _capture(id: String, heading: String, action: String, explanation: String) -> void:
	# Let the actual 0.12-second enemy hit flash finish. This keeps the court's
	# authored actors readable while the longer terminal cue is still visible.
	_elapsed(.14)
	title.text = heading
	subtitle.text = action
	detail.text = explanation+"\nActual game actors and committed plate routes · paused for inspection · no user save loaded"
	var enemies: Array = []
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var role := String(enemy.get_meta("review_role","ENEMY"))
		enemy._label.text = role+"\n"+str(snappedf(enemy.life,.1))+" / 1000"
		if enemy.chill>0: enemy._label.text += "\nCHILL "+str(snappedf(enemy.chill,.1))
		enemy._label.font_size = 34
		enemy._label.pixel_size = .0035
		enemy._label.position.y = 1.7
		enemies.append({"role":role,"life":enemy.life,"chill":enemy.chill})
	_freeze()
	for i in 4: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	check(get_viewport().get_texture().get_image().save_png(output.path_join(id+".png"))==OK,"capture "+id)
	records.append({"id":id,"title":heading,"action":action,"enemies":enemies})

func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = .88
	return material

func _box(at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = material
	add_child(mesh)
	mesh.position = at

func _court() -> void:
	var env := WorldEnvironment.new()
	var settings := Environment.new()
	settings.background_mode = Environment.BG_COLOR
	settings.background_color = Color("263139")
	settings.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	settings.ambient_light_color = Color("bacbd0")
	settings.ambient_light_energy = .55
	settings.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = settings
	add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-25,0)
	sun.light_color = Color("ffe0b4")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(20,1,18)
	collision.shape = floor_shape
	floor_body.add_child(collision)
	add_child(floor_body)
	floor_body.position.y = -.5
	var tiles: Array[Material] = [_material(Color("4b5558")),_material(Color("535d5e")),_material(Color("475154"))]
	_box(Vector3(0,-.08,0),Vector3(20,.12,18),_material(Color("20292b")))
	for x in range(-5,5):
		for z in range(-4,5):
			_box(Vector3(x*2+1,-.025,z*2),Vector3(1.97,.05,1.97),tiles[posmod(x*7+z*3,3)])
	var stone := _material(Color("665f51"))
	var cap := _material(Color("908572"))
	_box(Vector3(0,.7,-8),Vector3(20,1.4,.8),stone)
	_box(Vector3(0,1.45,-8),Vector3(20,.16,1),cap)
	for x in [-8.0,-4.0,4.0,8.0]:
		_box(Vector3(x,1.35,-7.8),Vector3(.8,2.7,1),stone)
		_box(Vector3(x,2.8,-7.8),Vector3(1.05,.22,1.2),cap)
	for x in [-9.0,9.0]:
		_box(Vector3(x,.35,0),Vector3(.7,.7,15.5),stone)
	for x in [-6.0,6.0]:
		_box(Vector3(x,.65,-5.8),Vector3(.65,1.3,.65),stone)
		var brazier := OmniLight3D.new()
		brazier.position = Vector3(x,1.8,-5.8)
		brazier.light_color = Color("ff8c3f")
		brazier.light_energy = 1.6
		brazier.omni_range = 5
		add_child(brazier)
		var ember := _material(Color("e47a37"))
		ember.emission_enabled = true
		ember.emission = Color("e77a24")
		_box(Vector3(x,1.35,-5.8),Vector3(.52,.12,.52),ember)

func _ui() -> void:
	var canvas := CanvasLayer.new()
	add_child(canvas)
	var top := ColorRect.new()
	top.position = Vector2(0,0)
	top.size = Vector2(1600,112)
	top.color = Color(.035,.05,.06,.94)
	canvas.add_child(top)
	title = Label.new()
	title.position = Vector2(36,23)
	title.add_theme_font_size_override("font_size",27)
	title.add_theme_color_override("font_color",Color("e5cfac"))
	canvas.add_child(title)
	subtitle = Label.new()
	subtitle.position = Vector2(36,67)
	subtitle.add_theme_font_size_override("font_size",21)
	canvas.add_child(subtitle)
	var bottom := ColorRect.new()
	bottom.position = Vector2(0,910)
	bottom.size = Vector2(1600,90)
	bottom.color = Color(.035,.05,.06,.94)
	canvas.add_child(bottom)
	detail = Label.new()
	detail.position = Vector2(36,928)
	detail.add_theme_font_size_override("font_size",19)
	detail.add_theme_color_override("font_color",Color("c4cfd1"))
	canvas.add_child(detail)
