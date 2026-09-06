extends Node3D
## Native legal plate rows, real payload/deal entry points and controlled clocks.
## Contact contexts represent separate committed inputs; no user save is touched.
const STRIKE := &"prototype_heavy_strike"
const OTHER := &"prototype_area_strike"
const DASH := &"prototype_dash"
var player: WroughtwildPlayer
var combat: PlayerCombat
var sim: WroughtwildSim
var checks := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ", message)

func near(actual: float, expected: float, message: String) -> void:
	check(absf(actual - expected) < .001, message + " (%f expected %f)" % [actual, expected])

func settle() -> void:
	for i in 3: await get_tree().physics_frame

func enemy(at := Vector3(0, 0, -2)) -> Enemy:
	var victim := Enemy.spawn(self, &"ember_whelp", at)
	victim.set_physics_process(false)
	victim.life = 1000
	victim.max_life = 1000
	return victim

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

func fresh(kind: String, ingot: String) -> Dictionary:
	for group in ["foundry_sustain", "enemies", "player_projectiles", "enemy_projectiles", "skill_bursts", "foundry_fields", "foundry_returns", "foundry_echoes", "foundry_puffs", "foundry_embers", "foundry_cold"]:
		for node in get_tree().get_nodes_in_group(group): node.free()
	for node in get_children():
		if node is DroppedBundle: node.free()
	# A slain body leaves the enemy group immediately, but its queued collision
	# deletion must finish before the next independent scene's cover queries.
	await settle()
	combat._reaction_ready.clear()
	combat._action_contexts.clear()
	combat._mutation_cache.clear()
	combat.clear_verbs()
	combat.clear_train()
	combat._cast_armour_left = 0
	combat.invulnerable_left = 0
	combat._fight_clock += 10
	for key in combat.cooldowns: combat.cooldowns[key] = 0
	player.position = Vector3.ZERO
	sim.add_material("iron_ingot", 100)
	for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row, piece.col), "lifts old fixture plate")
	sim.learn_skill(STRIKE)
	sim.learn_skill(OTHER)
	sim.learn_skill(DASH)
	for event in ["first_kill:ember_whelp", "first_kill:gloom_crawler", "work:strike_split", "first_kill:cinder_archer", "recipe:workbench_kit", "first_kill:stone_husk", "world_effect:stonecut_blocks", "first_kill:ash_hound"]: sim.foundry_event(event)
	sim.add_material(kind, 1)
	check(sim.foundry_place_skill(1, 1, STRIKE) and sim.foundry_place(1, 0, ingot) and sim.foundry_place_kind(2, 0, kind), "legal native " + kind + "/" + ingot + " arrangement")
	combat._mutation_cache.clear()
	combat.max_life = float(sim.derived_stats().max_life)
	combat.life = combat.max_life * .2
	return sim.skill_mutation(STRIKE)

func hit(victim: Enemy, skill := STRIKE, context: Dictionary = {}) -> Dictionary:
	# Use the ordinary pre-payload snapshot and positive native damage sequence.
	var action := {"practice_allowed": true} if context.is_empty() else context
	combat._action_contexts[skill] = action
	combat._fight_clock += .2
	combat.apply_payload(victim, skill, victim is Boss, 1, false, action)
	var result := combat.deal(victim, skill, false, 1, false, action)
	for event in FoundrySustain.events(combat): event.set_physics_process(false)
	return result

func event(role: String) -> FoundrySustain:
	var current := FoundrySustain.live(combat, role)
	check(current != null, "normal hit/cast hooks produce " + role)
	if current != null: current.set_physics_process(false)
	return current

func recovered(before: float, amount: float, message: String) -> void:
	near(combat.life - before, amount * (1 + float(sim.derived_stats().get("heal_more", 0))), message)

func _ready() -> void:
	wall(Vector3(0, -1, 0), Vector3(100, 1, 100))
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	combat = player.combat
	combat.set_physics_process(false)
	sim = combat.sim
	await settle()
	var ingots := ["ember", "frost", "edge", "reach", "vigour", "plate", "ward", "haste"]
	var keys := {}
	for kind: String in ["marrow", "sipping_marrow"]:
		for ingot: String in ingots:
			var resolved := await fresh(kind, ingot)
			var own_keys := []
			for key in resolved:
				if String(key).begins_with("identity_") and String(key).ends_with("_life") and float(resolved[key]) > 0: own_keys.append(key)
			check(own_keys.size() == 1, "each sustain row exposes one authored role")
			if own_keys.size() == 1: keys[own_keys[0]] = true
			check(float(resolved.get("siphon", 0)) == 0 and float(resolved.get("recovery_on_kill", 0)) == 0, "row no longer also grants the generic mote/bed")
	check(keys.size() == 16, "all sixteen native sustain readings have distinct operations")

	var form := await fresh("marrow", "ember")
	var victim := enemy()
	victim.life = 1
	hit(victim)
	var current := event("phoenix")
	if current != null:
		player.position = current.position - Vector3.UP * .5
		var before := combat.life
		current.advance(.3)
		near(combat.life, before, "Phoenix seed cannot pay before ripening")
		current.advance(.41)
		recovered(before, form.identity_phoenix_life, "Phoenix is collected once after ripening")
		current.advance(1)
		recovered(before, form.identity_phoenix_life, "a consumed Phoenix seed never pays twice")

	form = await fresh("marrow", "frost")
	victim = enemy(Vector3(0, 0, -1))
	victim.chill = 40
	hit(victim)
	current = event("winterroot")
	if current != null:
		var before := combat.life
		current.advance(.6)
		player.position.x = .5
		current.advance(.6)
		near(combat.life, before, "Winterroot movement restarts the stationary harvest")
		current.advance(1.01)
		recovered(before, form.identity_winterroot_life, "holding near a chilled target earns Winterroot")

	form = await fresh("marrow", "edge")
	victim = enemy()
	victim.bleeding_left = 4
	hit(victim)
	current = event("bloodroot")
	if current != null:
		var before := combat.life
		victim.life = 1
		hit(victim)
		check(current.is_queued_for_deletion() and combat.life >= before + float(form.identity_bloodroot_life), "a real direct execution spends Bloodroot")

	form = await fresh("marrow", "reach")
	victim = enemy()
	victim.life = 1
	hit(victim)
	current = event("harvest")
	if current != null:
		player.position = current.position - Vector3.UP * .5
		var before := combat.life
		current.advance(.1)
		near(combat.life, before, "one kill cannot ripen Harvest Ground")
		var second := enemy(Vector3(1, 0, -2))
		second.life = 1
		hit(second)
		before = combat.life
		current.advance(.1)
		recovered(before, form.identity_harvest_life, "second nearby direct kill ripens one physical harvest")

	form = await fresh("marrow", "vigour")
	victim = enemy()
	hit(victim)
	current = event("spring")
	if current != null:
		current.advance(1.5)
		FoundrySustain.damaged(combat, victim, 1)
		var before := combat.life
		current.advance(1)
		near(combat.life, before, "incoming damage resets Second Spring's quiet interval")
		current.advance(1.01)
		recovered(before, form.identity_spring_life, "Second Spring pays after the renewed quiet interval")

	form = await fresh("marrow", "plate")
	victim = enemy()
	hit(victim)
	current = event("ironroot")
	if current != null:
		FoundrySustain.damaged(combat, victim, 2)
		var before := combat.life
		current.advance(1.01)
		recovered(before, 1, "Ironroot recoup cannot exceed half the triggering base damage")

	form = await fresh("marrow", "ward")
	victim = enemy()
	var guard := enemy(Vector3(1, 0, -2))
	victim.life = 1
	hit(victim)
	current = event("harbour")
	if current != null:
		player.position = current.position - Vector3.UP * .5
		var before := combat.life
		current.advance(1)
		near(combat.life, before, "a living nearby threat blocks Safe Harbour")
		guard.position.x = 10
		current.advance(.81)
		recovered(before, form.identity_harbour_life, "clearing the harbour allows one recovery")

	form = await fresh("marrow", "haste")
	victim = enemy()
	victim.life = 1
	hit(victim)
	current = event("fleet")
	if current != null:
		var before := combat.life
		current.advance(.5)
		near(combat.life, before, "Fleet Harvest requires pursuit")
		player.position = current.position - Vector3.UP * .5
		current.advance(.05)
		recovered(before, form.identity_fleet_life, "pursuit collects the fleeing pod")

	form = await fresh("sipping_marrow", "ember")
	victim = enemy(Vector3(0, 0, -3))
	victim.burning_left = 4
	hit(victim)
	current = event("cinder")
	if current != null:
		var before := combat.life
		current.advance(.81)
		near(combat.life, before, "Cinder Siphon earns a return without instant healing")
		current.advance(.5)
		recovered(before, form.identity_cinder_life, "Cinder Siphon pays only on physical arrival")

	form = await fresh("sipping_marrow", "frost")
	victim = enemy()
	victim.chill = 40
	hit(victim)
	current = event("cold_sip")
	if current != null:
		var before := combat.life
		player.position.x = 3
		current.advance(.2)
		near(combat.life, before, "walking alone cannot spend Cold Siphon")
		check(combat.use_skill(DASH), "the learned real movement skill succeeds")
		recovered(before, form.identity_cold_sip_life, "a successful movement cast spends the chilled charge")

	form = await fresh("sipping_marrow", "edge")
	victim = enemy()
	victim.bleeding_left = 5
	var shared := {"practice_allowed": true}
	hit(victim, STRIKE, shared)
	current = event("bloodletter")
	if current != null:
		hit(victim, STRIKE, shared)
		check(current.stage == 1, "fan/recontact from one cast cannot progress Bloodletter")
		hit(victim)
		check(current.stage == 2, "a second real cast progresses Bloodletter once")
		var before := combat.life
		hit(victim)
		check(current.is_queued_for_deletion() and combat.life >= before + float(form.identity_bloodletter_life), "the third real bleeding contact spends Bloodletter")

	form = await fresh("sipping_marrow", "reach")
	victim = enemy(Vector3(0, 0, -5))
	hit(victim)
	current = event("long_drink")
	if current != null:
		var before := combat.life
		current.advance(1.1)
		near(combat.life, before, "a held long tether alone pays nothing")
		player.position.z = 1.1
		current.advance(.1)
		recovered(before, form.identity_long_drink_life, "retreat after a distant hold draws Long Drink")

	form = await fresh("sipping_marrow", "vigour")
	victim = enemy()
	var second := enemy(Vector3(1, 0, -2))
	shared = {"practice_allowed": true}
	hit(victim, STRIKE, shared)
	current = event("deep_drink")
	if current != null:
		hit(second, STRIKE, shared)
		check(current.seen.size() == 1, "one cast's fan cannot fill both Deep Drink samples")
		hit(second)
		check(current.seen.size() == 2, "another real cast records the distinct target")
		var before := combat.life
		FoundrySustain.cast(combat, STRIKE, FoundryIdentity.point(combat))
		near(combat.life, before, "the cast that fills Deep Drink is not its next cast")
		combat._action_contexts[OTHER] = {"practice_allowed": true}
		FoundrySustain.cast(combat, OTHER, FoundryIdentity.point(combat))
		recovered(before, form.identity_deep_drink_life, "the next real cast spends the filled reservoir")

	form = await fresh("sipping_marrow", "plate")
	FoundrySustain.cast(combat, STRIKE, FoundryIdentity.point(combat))
	current = event("iron_drink")
	victim = enemy()
	second = enemy(Vector3(2, 0, -2))
	if current != null:
		FoundrySustain.damaged(combat, victim, 2)
		hit(second)
		check(not current.is_queued_for_deletion(), "counterhitting the wrong attacker cannot spend Iron Drink")
		var before := combat.life
		hit(victim)
		var ordinary := float(sim.skill_life_on_hit(STRIKE))
		recovered(before, 1 + ordinary, "the actual attacker yields only the limited recoup and ordinary hit recovery")

	form = await fresh("sipping_marrow", "ward")
	combat._root_left = 2
	combat._marked_left = 2
	victim = enemy()
	hit(victim)
	current = event("ward_sip")
	if current != null:
		var before := combat.life
		combat._root_left = 0
		current.advance(.1)
		near(combat.life, before, "clearing only one captured affliction cannot spend Ward Siphon")
		combat._marked_left = 0
		current.advance(.1)
		recovered(before, form.identity_ward_sip_life, "all captured afflictions must clear before Ward Siphon pays")

	form = await fresh("sipping_marrow", "haste")
	victim = enemy()
	hit(victim)
	current = event("quick_sip")
	if current != null:
		hit(victim)
		check(not current.is_queued_for_deletion(), "same-skill repetition cannot spend Quick Sip")
		var before := combat.life
		hit(victim, OTHER)
		check(current.is_queued_for_deletion() and combat.life >= before + float(form.identity_quick_sip_life), "another real skill contact spends Quick Sip")

	await ownership_cases()
	await safety_cases()
	print("FOUNDRY_SUSTAIN_IDENTITY %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func ownership_cases() -> void:
	# Brittle is a retained native compatibility hook, no longer granted by a
	# current form row. Enable its existing debug modifier explicitly on legal
	# sustain plates; the actual payload, immunity, execute and nova remain real.
	for ingot in ["edge","ember"]:
		await fresh("marrow",ingot)
		sim.set_skill_mod_active("brittle",true)
		check(sim.skill_brittle(STRIKE),"synthetic compatibility composition activates the real native Brittle hook")
		var victim := enemy(Vector3(0,0,-1))
		victim.frozen_left=3
		victim.bleeding_left=3
		victim._damage_taken={"physical":0,"fire":0,"cold":0}
		var neighbour := enemy(Vector3(1,0,-1))
		var neighbour_life := neighbour.life
		var before := combat.life
		var ordinary_life := float(sim.skill_life_on_hit(STRIKE))+float(sim.skill_life_on_kill(STRIKE))
		var result := hit(victim)
		check(victim.life<=0 and bool(result.kill) and float(result.damage)>0,"immune direct packet retains Brittle's aggregate execute and damage feedback")
		check(neighbour.life<neighbour_life,"the compatibility case executes a real secondary nova against a neighbour")
		check(FoundrySustain.events(combat).is_empty(),"Brittle-only damage cannot seed a new sustain contact or kill opportunity")
		recovered(before,ordinary_life,"Brittle preserves legacy reap while refusing extra Bloodroot or Phoenix recovery")
		sim.set_skill_mod_active("brittle",false)
	await fresh("marrow","ember")
	# Even with Brittle available, a real positive direct packet which kills
	# owns its one Phoenix seed. This guards the positive side of the split.
	sim.set_skill_mod_active("brittle",true)
	var victim := enemy(Vector3(0,0,-1))
	victim.life=1
	victim.frozen_left=3
	victim.bleeding_left=3
	var result := hit(victim)
	check(float(result.damage)>0 and bool(result.kill),"positive native direct packet still reports its real kill")
	var current := event("phoenix")
	check(current!=null and FoundrySustain.events(combat).size()==1,"direct packet kill creates exactly one authored Phoenix seed")
	if current!=null:
		var before := combat.life
		player.position=current.position-Vector3.UP*.5
		current.advance(.71)
		recovered(before,float(current.rules.identity_phoenix_life),"a direct-kill seed still pays once through its real collection rule")
	sim.set_skill_mod_active("brittle",false)

func safety_cases() -> void:
	var form := await fresh("sipping_marrow", "ember")
	var victim := enemy(Vector3(0, 0, -4))
	victim.burning_left = 3
	var action := {"practice_allowed": true}
	FoundrySustain.contact(combat, victim, STRIKE, form, action)
	check(FoundrySustain.events(combat).is_empty(), "pre-payload contact alone earns nothing without positive damage")
	FoundrySustain.contact(combat, victim, STRIKE, form, {"practice_allowed": false})
	FoundrySustain.landed(combat, victim, STRIKE, form, {"practice_allowed": false})
	check(FoundrySustain.events(combat).is_empty(), "links and echoes cannot invent real-contact sustain")
	victim._damage_taken = {"physical": 0, "fire": 0, "cold": 0}
	var rejected := hit(victim)
	check(float(rejected.damage) == 0 and FoundrySustain.events(combat).is_empty(), "an actual fully immune native packet cannot create a sustain opportunity")
	victim._damage_taken = {"physical": 1, "fire": 1, "cold": 1}
	hit(victim, STRIKE, {"practice_allowed": false})
	check(FoundrySustain.events(combat).is_empty(), "the real positive-damage path still rejects a linked-cast context")
	hit(victim)
	var current := event("cinder")
	var cover := wall(Vector3(0, .5, -2), Vector3(5, 3, .1))
	await settle()
	if current != null:
		var before := combat.life
		current.advance(.9)
		near(combat.life, before, "new solid cover breaks Cinder Siphon without payout")
		check(current.is_queued_for_deletion(), "blocked tether is consumed, never teleported through cover")
	cover.free()
	await settle()
	form = await fresh("marrow", "frost")
	var boss := Boss.spawn_boss(self, Vector3(0, 0, -1))
	boss.set_physics_process(false)
	boss.chill = 40
	hit(boss)
	current = event("winterroot")
	if current != null:
		var before := combat.life
		current.advance(1.01)
		recovered(before, form.identity_winterroot_life, "a living chilled boss supports the same bounded harvest without extra damage")
	form = await fresh("sipping_marrow", "frost")
	victim = enemy()
	victim.chill = 40
	hit(victim)
	current = event("cold_sip")
	if current != null:
		var before := combat.life
		current.advance(float(form.limits.sustain_window) + 1)
		FoundrySustain.cast(combat, DASH, FoundryIdentity.point(combat))
		near(combat.life, before, "expired charge cannot pay on a later movement cast")
	form = await fresh("marrow", "plate")
	victim = enemy()
	hit(victim)
	current = event("ironroot")
	if current != null:
		FoundrySustain.damaged(combat, victim, 0)
		check(current.stage == 0, "fully mitigated hit does not arm recoup")
		var duplicate := FoundrySustain.spawn(combat, STRIKE, "ironroot", FoundryIdentity.point(combat), form)
		check(duplicate == null, "duplicate readings never create a second personal charge")
		var before := combat.life
		combat.died.disconnect(player._on_died)
		combat.died.emit()
		current.advance(2)
		near(combat.life, before, "death cancellation pays nothing")
		check(current.is_queued_for_deletion(), "death clears the sustain event")
		combat.died.connect(player._on_died)
	form = await fresh("sipping_marrow", "frost")
	victim = enemy()
	victim.chill = 40
	hit(victim)
	current = event("cold_sip")
	if current != null:
		combat.life = combat.max_life - .2
		FoundrySustain.cast(combat, DASH, FoundryIdentity.point(combat))
		near(combat.life, combat.max_life, "the shared healing path caps sustain at maximum life")
