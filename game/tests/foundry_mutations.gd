extends Node3D
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var combat: PlayerCombat
var sim: WroughtwildSim
const BOLT := &"prototype_ember_bolt"
const STRIKE := &"prototype_heavy_strike"

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func near(a: float, b: float, message: String) -> void:
	check(absf(a-b) < 0.001, message + " (%f, expected %f)" % [a,b])

func wall(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	body.add_child(shape)
	add_child(body)
	body.position = at
	return body

func enemy(at: Vector3) -> Enemy:
	var e := Enemy.spawn(self, &"ember_whelp", at)
	e.set_physics_process(false)
	e.life = 1000
	e.max_life = 1000
	return e

func settle() -> void:
	for i in 3: await get_tree().physics_frame

func clear() -> void:
	for group in ["enemies", "player_projectiles", "enemy_projectiles", "skill_bursts", "foundry_fields", "foundry_returns", "foundry_echoes"]:
		for node in get_tree().get_nodes_in_group(group): node.free()
	for id in combat.cooldowns: combat.cooldowns[id] = 0
	combat._mutation_cache.clear()
	combat._casts.clear()
	combat._cast_armour_left = 0
	combat.life = combat.max_life

func lay(skill: StringName, kind: String, ingot: String) -> Dictionary:
	sim.add_material("iron_ingot", 100)
	for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row,piece.col), "fixture lifts existing piece")
	sim.learn_skill(skill)
	for event in ["first_kill:ember_whelp", "first_kill:gloom_crawler", "work:strike_split", "first_kill:cinder_archer", "recipe:workbench_kit", "first_kill:stone_husk", "world_effect:stonecut_blocks", "first_kill:ash_hound"]:
		sim.foundry_event(event)
	sim.add_material(kind, 1)
	check(sim.foundry_place_skill(1,1,skill) and sim.foundry_place(1,0,ingot) and sim.foundry_place_kind(2,0,kind), "fixture commits a legal " + kind + " route")
	combat._mutation_cache.clear()
	return sim.skill_mutation(skill)

func shot(skill: StringName, at := Vector3(0,0.8,0)) -> SkillProjectile:
	var bolt := SkillProjectile.launch(skill, combat, self, at, Vector3.FORWARD, 0, [])
	bolt.set_physics_process(false)
	return bolt

func expected_hit(skill: StringName, target: Enemy) -> float:
	var total := 0.0
	for packet in sim.player_hit(skill,false,target.carried_statuses()): total += float(packet.damage) * target.damage_taken(String(packet.type))
	return total

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	wall(Vector3(0,-0.5,0), Vector3(100,1,100))
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position = Vector3(0,0.8,0)
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	combat = player.combat
	combat.set_physics_process(false)
	sim = combat.sim
	await settle()
	var form := lay(BOLT,"frost_catalyst","ember")
	check(form.forms[0].form_name == "Smoulder", "backend names the transformed Ember support")
	var target := enemy(Vector3(0,0,-4))
	target.apply_ignite(100,0,0,form)
	near(target.status_move_multiplier(),0.75,"Smoulder slows during the burn")
	var before := target.life
	target._tick_statuses(0.5)
	near(before-target.life, float(form.burn_dps)*0.5*target.damage_taken("fire"), "Smoulder deals one fire burn, not two stacked DoTs")
	target.burning_left = 0
	near(target.status_move_multiplier(),1,"Smoulder slow ends with its burn")
	var boss := Boss.spawn_boss(self,Vector3(5,0,-4))
	boss.set_physics_process(false)
	boss.apply_ignite(100,0,0,form)
	near(boss.status_move_multiplier(),0.9375,"boss gets a quarter-strength Smoulder slow")
	var neighbour := enemy(Vector3(0.6,0,-4))
	target.apply_ignite(100,0,0,form)
	await settle()
	target._proliferate()
	check(neighbour.burning_left>0 and neighbour.smoulder_slow>0,"spread carries Smoulder into a neighbouring burn")
	near(neighbour._burn_dps,target._burn_dps,"spread retains the originating burn snapshot")
	clear()

	form = lay(BOLT,"preserving_catalyst","ember")
	target = enemy(Vector3(0,0,-4))
	var behind := enemy(Vector3(2,0,-4))
	var cover := wall(Vector3(1,1,-4),Vector3(0.08,3,4))
	await settle()
	var field := FoundryField.spawn(combat,BOLT,Vector3(0,0.15,-4),"impact",form)
	field.set_physics_process(false)
	sim.begin_fight(271)
	var expected_field := 0.0
	for i in 3: expected_field += expected_hit(BOLT,target) * float(form.field_fraction)
	sim.begin_fight(271)
	before = target.life
	field.advance(0.79)
	near(target.life,before,"retained impact waits for the first pulse")
	field.advance(0.02)
	check(target.life<before and behind.life==1000,"field pulses hit nearby enemies and respect solid cover")
	var ignite_after := target.ignite
	check(ignite_after>0 and ignite_after < sim.ignite_applied(BOLT,false),"field buildup is scaled by the pulse fraction")
	field.advance(10)
	near(before-target.life,expected_field,"a long frame delivers exactly three seeded hit fractions across the field lifetime")
	check(field.is_queued_for_deletion(),"expired field is removed")
	check(get_tree().get_nodes_in_group("foundry_fields").size()==1,"pulses do not create child fields")
	cover.free()
	clear()

	form = lay(STRIKE,"piercing_catalyst","edge")
	target = enemy(Vector3(0,0,-4))
	neighbour = enemy(Vector3(0,0,-7))
	await settle()
	var wave := shot(STRIKE)
	check(wave.visual_profile=="wave","melee mutation has a travelling cutting-edge presentation")
	wave.advance(1)
	check(target.life<1000 and neighbour.life<1000,"a mutated melee wave hits and pierces beyond melee reach")
	check((form.tags as PackedStringArray).has("attack") and (form.tags as PackedStringArray).has("projectile"),"travelling melee retains attack and gains projectile capability")
	clear()
	form = lay(BOLT,"impact_catalyst","reach")
	target = enemy(Vector3(0,0,-4))
	neighbour = enemy(Vector3(1.3,0,-4))
	await settle()
	sim.begin_fight(271)
	var expected_contact := expected_hit(BOLT,target)
	var expected_neighbour := expected_hit(BOLT,neighbour)
	sim.begin_fight(271)
	var bolt := shot(BOLT)
	bolt.advance(1)
	check(target.life<1000 and neighbour.life<1000,"Impact turns an ordinary bolt into a contact burst")
	near(1000-target.life,expected_contact,"contact target takes exactly one seeded burst hit")
	near(1000-neighbour.life,expected_neighbour,"neighbour takes exactly one seeded burst hit")
	clear()

	form = lay(BOLT,"warding_vanguard","ward")
	var seal := FoundryField.spawn(combat,BOLT,Vector3(0,0.15,0),"guard",form)
	seal.set_physics_process(false)
	check(FoundryField.intercept(get_tree(),Vector3(0,0.8,-8),Vector3(0,0.8,0)),"ward intercepts a shot crossing it in one long frame")
	check(not FoundryField.intercept(get_tree(),Vector3(0,0.8,-8),Vector3(0,0.8,0)),"spent ward cannot intercept a second shot")
	clear()
	form = lay(BOLT,"vanguard","plate")
	seal = FoundryField.spawn(combat,BOLT,Vector3(0,0.15,0),"guard",form)
	seal.set_physics_process(false)
	near(combat.cast_armour(),10,"Bulwark armour is active inside its seal")
	player.position.x = 8
	near(combat.cast_armour(),0,"stepping away loses the positional armour")
	player.position.x = 0
	clear()

	form = lay(BOLT,"marrow","vigour")
	combat.life = combat.max_life - 20
	field = FoundryField.spawn(combat,BOLT,Vector3(0,0.15,0),"recovery",form)
	field.set_physics_process(false)
	before = combat.life
	field.advance(4)
	near(combat.life-before,4.5,"standing in a recovery bed collects its entire finite healing budget")
	clear()
	form = lay(BOLT,"sipping_marrow","edge")
	combat.life = combat.max_life - 20
	before = combat.life
	FoundryReturn.launch(combat,Vector3(0,0.8,-8),form)
	var mote: FoundryReturn = get_tree().get_nodes_in_group("foundry_returns")[0]
	mote.set_physics_process(false)
	mote.advance(0.1)
	near(combat.life,before,"siphoned life waits for the returning mote")
	mote.advance(3)
	near(combat.life-before,0.65,"life is paid once when the mote arrives")
	mote.advance(3)
	near(combat.life-before,0.65,"a spent mote cannot pay twice")
	clear()

	form = lay(BOLT,"casting_quicksilver","haste")
	for i in 3:
		combat.cooldowns[BOLT] = 0
		check(combat.use_skill(BOLT),"cadence fixture casts")
	check(get_tree().get_nodes_in_group("foundry_echoes").size()==1,"three spell uses schedule one delayed echo")
	var echo: FoundryEcho = get_tree().get_nodes_in_group("foundry_echoes")[0]
	echo.set_physics_process(false)
	before = combat.cooldown_left(BOLT)
	var uses: int = sim.combat_skill(BOLT).uses
	echo._physics_process(1)
	near(combat.cooldown_left(BOLT),before,"echo preserves the real cooldown")
	check(sim.combat_skill(BOLT).uses==uses,"echo does not award an extra mastery use")
	clear()

	form = lay(BOLT,"frost_catalyst","ember")
	check(sim.foundry_remove(2,0),"preview fixture lifts its Kind")
	var saved: String = sim.export_json()
	var preview: Dictionary = sim.foundry_preview(2,0,"frost_catalyst","")
	check(preview.valid and preview.effects.any(func(e): return e.get("form_name","")=="Smoulder"),"placement preview shows its real resolved form")
	check(sim.export_json()==saved,"preview spends no inventory and mutates no save state")
	check(not sim.foundry_preview(1,0,"frost_catalyst","").valid,"preview refuses an occupied support exactly as commit does")
	player.foundry_panel.open_panel()
	player.foundry_panel._on_subject("frost_catalyst")
	await settle()
	player.foundry_panel._inspect_cell(2,0)
	check("Smoulder" in player.foundry_panel._preview.text,"Foundry UI names the prospective transformation")
	check(player.foundry_panel._flow_overlay.paths.size()>0,"preview draws the resolved inward route")
	await settle()
	var rect := player.foundry_panel._root.get_global_rect()
	check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=1281 and rect.end.y<=721,"Foundry remains usable at 720p")
	player.foundry_panel.close_panel()
	clear()
	form = lay(BOLT,"preserving_catalyst","reach")
	field = FoundryField.spawn(combat,BOLT,Vector3.ZERO,"impact",form)
	field.set_physics_process(false)
	combat.died.emit()
	check(field.is_queued_for_deletion(),"death cancels persistent mutation effects")
	clear()
	print("%d checks, %d failures (Foundry mutations)" % [checks,failures])
	get_tree().quit(1 if failures else 0)
