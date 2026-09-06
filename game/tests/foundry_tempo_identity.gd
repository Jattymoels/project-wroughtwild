extends Node3D
## Behavior checks use legal compiled routes and deterministic event clocks.
## No save files are read, no external session is controlled, and no echo is
## allowed to masquerade as another player input.
const STRIKE := &"prototype_heavy_strike"
const BOLT := &"prototype_ember_bolt"
const ORB := &"prototype_frost_orb"
const DASH := &"prototype_dash"
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var combat: PlayerCombat
var sim: WroughtwildSim

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)

func near(a: float, b: float, message: String) -> void:
	check(absf(a-b)<.001,message+" (%f vs %f)"%[a,b])

func wall(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	add_child(body)
	body.position = at
	return body

func enemy(at: Vector3) -> Enemy:
	var node := Enemy.spawn(self,&"ember_whelp",at)
	node.set_physics_process(false)
	node.life = 1000
	node.max_life = 1000
	return node

func clear() -> void:
	for group in ["foundry_tempo","foundry_fields","foundry_cold","foundry_embers","foundry_returns","foundry_echoes","foundry_puffs","foundry_guards","foundry_sustain","foundry_offence","enemies","player_projectiles","enemy_projectiles","skill_bursts"]:
		for node in get_tree().get_nodes_in_group(group): node.free()
	for node in get_children():
		if node is DroppedBundle: node.free()
	for id in combat.cooldowns: combat.cooldowns[id] = 0
	combat._mutation_cache.clear()
	combat._casts.clear()
	combat._reaction_ready.clear()
	combat._action_contexts.clear()
	combat._cast_armour = 0
	combat._cast_armour_left = 0
	combat.life = combat.max_life
	combat.clear_verbs()
	combat.clear_train()
	combat.invulnerable_left = 0
	player.position = Vector3(0,.8,0)
	player.rotation = Vector3.ZERO

func lay(skill: StringName, kind: String, ingot: String) -> Dictionary:
	clear()
	sim.add_material("iron_ingot",100)
	for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row,piece.col),"fixture removes old route")
	sim.learn_skill(skill)
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer","recipe:workbench_kit","first_kill:stone_husk","world_effect:stonecut_blocks","first_kill:ash_hound"]:
		sim.foundry_event(event)
	sim.add_material(kind,1)
	check(sim.foundry_place_skill(1,1,skill) and sim.foundry_place(1,0,ingot) and sim.foundry_place_kind(2,0,kind),"fixture places legal "+kind+" / "+ingot)
	combat._mutation_cache.clear()
	return sim.skill_mutation(skill)

func touch(skill: StringName, form: Dictionary, victim: Enemy, context: Dictionary = {}) -> void:
	# A deterministic positive-direct-hit boundary. The integration case below
	# additionally calls PlayerCombat.deal against an immune target.
	if context.is_empty(): context["practice_allowed"] = true
	FoundryTempo.contact(combat,victim,skill,form,context)
	FoundryTempo.landed(combat,victim,skill,form,context)

func cast(skill: StringName) -> void:
	FoundryTempo.cast(combat,skill,FoundryIdentity.point(combat))
	for node in get_tree().get_nodes_in_group("foundry_tempo"): node.set_physics_process(false)

func memory(kind: String) -> FoundryTempo:
	var node := FoundryTempo.live(combat,kind)
	check(node != null,"the compiled route creates "+kind)
	if node != null: node.set_physics_process(false)
	return node

func step(node: FoundryTempo, seconds: float) -> void:
	if node != null: node.advance(seconds)

func settle() -> void:
	for i in 3: await get_tree().physics_frame

func _ready() -> void:
	wall(Vector3(0,-.5,0),Vector3(100,1,100))
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	combat = player.combat
	combat.set_physics_process(false)
	sim = combat.sim
	await settle()
	await _footwork()
	await _attacks()
	await _spells()
	await _boundaries()
	_expiry()
	print("FOUNDRY_TEMPO_IDENTITY: %d checks, %d failures"%[checks,failures])
	get_tree().quit(1 if failures else 0)

func _footwork() -> void:
	var form := lay(STRIKE,"quicksilver","ember")
	var victim := enemy(Vector3(0,0,-2))
	var crossing := enemy(Vector3(1,0,0))
	touch(STRIKE,form,victim)
	var node := memory("q_cinder")
	step(node,.1)
	near(crossing.life,1000,"Cinder Wake pays nothing before moving")
	player.position.x = 2
	step(node,.1)
	check(crossing.life<1000,"Cinder Wake damages a crossing enemy on its drawn seam")
	near(victim.life,1000,"Cinder Wake excludes its original victim")
	var after := crossing.life
	step(node,.8)
	near(crossing.life,after,"Cinder Wake never pulses or repeats its crossing packet")

	form = lay(STRIKE,"quicksilver","frost")
	victim = enemy(Vector3(0,0,0))
	cast(STRIKE)
	node = memory("q_frost")
	step(node,.1)
	near(victim.chill,0,"Frost Wake cannot chill while its owner stays")
	player.position.x = 2
	step(node,.1)
	check(victim.chill>0,"Frost Wake chills the first pursuer after leaving")
	near(victim.life,1000,"Frost Wake is control, not another damaging trail")

	form = lay(STRIKE,"quicksilver","edge")
	victim = enemy(Vector3(0,0,-2))
	touch(STRIKE,form,victim)
	node = memory("q_razor")
	player.position.x = .7
	step(node,.1)
	near(victim.life,1000,"Razor Wake requires the opposite flank")
	player.position = Vector3(0,.8,-3.5)
	step(node,.1)
	check(victim.life<1000,"Razor Wake pays one cut after circling the victim")

	form = lay(STRIKE,"quicksilver","reach")
	victim = enemy(Vector3(0,0,-5))
	cast(STRIKE)
	touch(STRIKE,form,victim)
	near(victim._shove_left.length(),0,"Long Wake requires repositioning before a far hit")
	player.position.x = 2
	touch(STRIKE,form,victim)
	check(victim._shove_left.z>0,"Long Wake pulls a far victim toward the old position")
	near(victim.life,1000,"Long Wake adds displacement without invented damage")

	form = lay(STRIKE,"quicksilver","vigour")
	victim = enemy(Vector3(0,0,-2))
	combat.life = combat.max_life-10
	var life_before := combat.life
	touch(STRIKE,form,victim)
	node = memory("q_living")
	step(node,.1)
	near(combat.life,life_before,"Living Wake cannot heal a stationary attacker")
	player.position.x = 2
	step(node,.1)
	check(combat.life>life_before,"Living Wake heals once when the attacker leaves")

	form = lay(STRIKE,"quicksilver","plate")
	victim = enemy(Vector3(0,0,-2))
	cast(STRIKE)
	FoundryTempo.damaged(combat,victim,2)
	near(victim._shove_left.length(),0,"Iron Wake cannot retaliate before retreat")
	player.position.x = 2
	FoundryTempo.damaged(combat,victim,2)
	check(victim._shove_left.length()>0,"Iron Wake spends its charge on the attacker after retreat")

	form = lay(STRIKE,"quicksilver","ward")
	victim = enemy(Vector3(0,0,-2))
	combat._root_left = 2
	combat._slow_left = 2
	cast(STRIKE)
	cast(STRIKE)
	near(combat._root_left,2,"Warded Wake requires incoming damage, not empty recasting")
	FoundryTempo.damaged(combat,victim,2)
	cast(STRIKE)
	near(combat._root_left,0,"Warded Wake clears root on the answering cast")
	near(combat._slow_left,2,"Warded Wake clears exactly one control")

	form = lay(STRIKE,"quicksilver","haste")
	victim = enemy(Vector3(0,0,0))
	cast(STRIKE)
	player.position.x = 3
	node = memory("q_after")
	step(node,.2)
	near(victim.life,1000,"Afterimage movement alone cannot hurt an enemy")
	cast(STRIKE)
	check(victim.life<1000,"Afterimage recasting pays one packet at the abandoned cast point")
	check(FoundryTempo.live(combat,"q_cinder")==null,"Afterimage never becomes the Cinder Wake fire seam")

func _attacks() -> void:
	var form := lay(STRIKE,"striking_quicksilver","ember")
	var victim := enemy(Vector3(0,0,-2))
	var neighbour := enemy(Vector3(0,0,-3.4))
	touch(STRIKE,form,victim)
	touch(STRIKE,form,victim)
	near(neighbour.life,1000,"Cinder Refrain needs an established burn")
	victim.burning_left = 2
	touch(STRIKE,form,victim)
	check(neighbour.life<1000,"Cinder Refrain bursts behind the repeatedly hit burning victim")
	near(victim.life,1000,"Cinder Refrain excludes the attacked victim")

	form = lay(STRIKE,"striking_quicksilver","frost")
	victim = enemy(Vector3(0,0,-2))
	neighbour = enemy(Vector3(2,0,-2))
	touch(STRIKE,form,victim)
	touch(STRIKE,form,victim)
	node_step("s_frost",.1)
	near(victim.chill,0,"Frost Refrain cannot reward tunnelling on one target")
	touch(STRIKE,form,neighbour)
	near(victim.chill,0,"Frost Refrain waits for its returning mote")
	node_step("s_frost",.4)
	check(victim.chill>0 and neighbour.chill==0,"Frost Refrain returns chill to the first target only")

	form = lay(STRIKE,"striking_quicksilver","edge")
	victim = enemy(Vector3(0,0,-2))
	touch(STRIKE,form,victim)
	touch(STRIKE,form,victim)
	near(victim.life,1000,"Doublecut rejects an immediate duplicate contact")
	node_step("s_double",.4)
	touch(STRIKE,form,victim)
	check(victim.life<1000,"Doublecut rewards its timed second same-target contact")

	form = lay(STRIKE,"striking_quicksilver","reach")
	victim = enemy(Vector3(-2,0,-2))
	neighbour = enemy(Vector3(2,0,-2))
	var between := enemy(Vector3(0,0,-2))
	touch(STRIKE,form,victim)
	touch(STRIKE,form,neighbour)
	check(between.life<1000,"Sweeping Refrain cuts enemies between two contact positions")
	check(victim.life==1000 and neighbour.life==1000,"Sweeping Refrain excludes both endpoint victims")

	form = lay(STRIKE,"striking_quicksilver","vigour")
	victim = enemy(Vector3(0,0,-2))
	combat.life = combat.max_life-10
	var before := combat.life
	var context := {"practice_allowed":true}
	touch(STRIKE,form,victim,context)
	touch(STRIKE,form,victim,context)
	touch(STRIKE,form,victim)
	near(combat.life,before,"Sustaining Refrain counts casts, not duplicate hits within one cast")
	touch(STRIKE,form,victim)
	check(combat.life>before,"Sustaining Refrain heals after three unbroken positive-hit casts")
	combat._reaction_ready.clear()
	touch(STRIKE,form,victim)
	FoundryTempo.damaged(combat,victim,1)
	check(FoundryTempo.live(combat,"s_sustain")==null,"Incoming damage breaks Sustaining Refrain")

	form = lay(STRIKE,"striking_quicksilver","plate")
	victim = enemy(Vector3(0,0,-2))
	touch(STRIKE,form,victim)
	touch(STRIKE,form,victim)
	near(combat._cast_armour,0,"Braced Refrain needs time between positive hits")
	node_step("s_brace",.7)
	touch(STRIKE,form,victim)
	check(combat._cast_armour>0,"Braced Refrain earns armour by holding through two attacks")

	form = lay(STRIKE,"striking_quicksilver","ward")
	victim = enemy(Vector3(0,0,-2))
	neighbour = enemy(Vector3(2,0,-2))
	cast(STRIKE)
	combat._slow_left = 2
	FoundryTempo.damaged(combat,victim,1)
	touch(STRIKE,form,neighbour)
	near(combat._slow_left,2,"Guarded Refrain requires answering the actual attacker")
	touch(STRIKE,form,victim)
	check(victim._stagger_left>0 and combat._slow_left==0,"Guarded Refrain interrupts that attacker and clears one control")

	form = lay(STRIKE,"striking_quicksilver","haste")
	sim.learn_skill(DASH)
	combat.cooldowns[DASH] = 5
	cast(STRIKE)
	cast(STRIKE)
	player.position.x = 2
	cast(STRIKE)
	near(float(combat.cooldowns[DASH]),5,"Threefold Step rejects repeated casts from the same feet")
	player.position = Vector3(2,.8,-2)
	cast(STRIKE)
	check(float(combat.cooldowns[DASH])<5,"Threefold Step earns movement cooldown after three distinct positions")

func node_step(kind: String, seconds: float) -> void:
	step(memory(kind),seconds)

func _spells() -> void:
	var form := lay(BOLT,"casting_quicksilver","ember")
	var victim := enemy(Vector3(0,0,-3))
	var neighbour := enemy(Vector3(.4,0,-3))
	var arrival := enemy(Vector3(4,0,-3))
	touch(BOLT,form,victim)
	arrival.position.x = .8
	node_step("c_ember",.3)
	near(arrival.life,1000,"Ember Echo waits through its telegraph")
	node_step("c_ember",.4)
	check(arrival.life<1000,"Ember Echo rewards an arriving enemy")
	check(victim.life==1000 and neighbour.life==1000,"Ember Echo excludes every original occupant, not just its hit target")

	form = lay(BOLT,"casting_quicksilver","frost")
	victim = enemy(Vector3(0,0,-4))
	neighbour = enemy(Vector3(0,0,0))
	touch(BOLT,form,victim)
	player.position.x = 3
	node_step("c_frost",.7)
	check(neighbour.chill>0 and victim.chill==0,"Frost Echo chills the old attacking position, not the spell's distant impact")

	form = lay(BOLT,"casting_quicksilver","edge")
	victim = enemy(Vector3(0,0,-4))
	neighbour = enemy(Vector3(0,0,-2))
	touch(BOLT,form,victim)
	node_step("c_blade",.7)
	check(neighbour.life<1000 and victim.life==1000,"Blade Echo cuts the return line while excluding the original victim")

	form = lay(BOLT,"casting_quicksilver","reach")
	victim = enemy(Vector3(0,0,-3))
	neighbour = enemy(Vector3(2.3,0,-3))
	var centre := enemy(Vector3(.4,0,-3))
	touch(BOLT,form,victim)
	node_step("c_wide",.7)
	check(neighbour.life<1000 and centre.life==1000 and victim.life==1000,"Wide Echo hits the hollow outer ring and leaves its centre safe")

	form = lay(BOLT,"casting_quicksilver","vigour")
	victim = enemy(Vector3(0,0,-3))
	combat.life = combat.max_life-10
	var before := combat.life
	victim.life = 0
	FoundryTempo.killed(combat,victim,BOLT)
	cast(BOLT)
	node_step("c_living",.1)
	near(combat.life,before,"Living Echo's mote waits for a different spell")
	sim.learn_skill(ORB)
	cast(ORB)
	near(combat.life,before,"Living Echo cannot heal before its mote travels home")
	node_step("c_living",.6)
	check(combat.life>before,"Living Echo heals only on the returning mote's arrival")

	form = lay(BOLT,"casting_quicksilver","plate")
	cast(BOLT)
	node_step("c_brace",.3)
	near(combat._cast_armour,0,"Braced Echo has a stationary afterglow before armour")
	node_step("c_brace",.4)
	check(combat._cast_armour>0,"Braced Echo earns armour without needing a second hit")
	combat._reaction_ready.clear()
	combat._cast_armour = 0
	cast(BOLT)
	player.position.x = 1
	node_step("c_brace",.7)
	near(combat._cast_armour,0,"Moving cancels Braced Echo before its armour grant")

	form = lay(BOLT,"casting_quicksilver","ward")
	victim = enemy(Vector3(0,0,-5))
	cast(BOLT)
	var from := Vector3(0,1.3,-4)
	var to := Vector3(0,1.3,4)
	check(FoundryTempo.projectile_candidate(combat,from,to,victim).is_empty(),"Warded Echo cannot intercept before its delay")
	node_step("c_ward",.7)
	var candidate := FoundryTempo.projectile_candidate(combat,from,to,victim)
	check(not candidate.is_empty() and float(candidate.get("at",1))<.5,"Warded Echo offers a swept front boundary, not its centre")
	check(FoundryTempo.live(combat,"c_ward")!=null,"Candidate lookup does not spend the one-shot screen")
	if not candidate.is_empty():
		check(FoundryTempo.consume_projectile(candidate.node,from.lerp(to,float(candidate.at)),victim),"Nearest-hit arbitration spends Warded Echo once")
		check(not FoundryTempo.consume_projectile(candidate.node,to,victim),"Warded Echo cannot spend a second interception")

	form = lay(BOLT,"casting_quicksilver","haste")
	combat.cooldowns[BOLT] = 5
	cast(BOLT)
	cast(BOLT)
	near(float(combat.cooldowns[BOLT]),5,"Aftercast does not reward immediate recasting")
	node_step("c_after",1.8)
	cast(BOLT)
	near(float(combat.cooldowns[BOLT]),5,"Aftercast requires following its drifting mark")
	var node := memory("c_after")
	if node != null: player.position = node.global_position-Vector3.UP*.5
	cast(BOLT)
	check(float(combat.cooldowns[BOLT])<5,"Aftercast refunds the spell cast at the metronome")

func _boundaries() -> void:
	var form := lay(STRIKE,"quicksilver","vigour")
	var victim := enemy(Vector3(0,0,-2))
	FoundryTempo.contact(combat,victim,STRIKE,form,{"practice_allowed":true})
	check(FoundryTempo.live(combat,"q_living")==null,"Pre-payload contact alone cannot seed recovery")
	touch(STRIKE,form,victim,{"practice_allowed":false})
	check(FoundryTempo.live(combat,"q_living")==null,"Linked and repeated cast contexts cannot seed tempo events")
	# Zero direct fraction is the real combat boundary for a refused packet; the
	# same guard handles damage immunity, and must not count as a landed hit.
	combat.deal(victim,STRIKE,false,0,false,{"practice_allowed":true})
	check(FoundryTempo.live(combat,"q_living")==null,"PlayerCombat refuses tempo recovery on zero damage")

	form = lay(DASH,"quicksilver","haste")
	victim = enemy(Vector3(0,0,0))
	cast(DASH)
	player.position.x = 2
	cast(DASH)
	near(victim.life,1000,"Afterimage never invents damage for a movement skill")
	for pair in [[BOLT,"striking_quicksilver"],[STRIKE,"casting_quicksilver"]]:
		for ingot in ["ember","frost","edge","reach","vigour","plate","ward","haste"]:
			form = lay(pair[0],pair[1],ingot)
			cast(pair[0])
			victim = enemy(Vector3(0,0,-2))
			touch(pair[0],form,victim)
			var active := 0
			for effect in get_tree().get_nodes_in_group("foundry_tempo"):
				if effect.remaining>0: active += 1
			check(active==0,"Incompatible "+pair[1]+" / "+ingot+" never becomes an attack or spell cadence")

	form = lay(STRIKE,"quicksilver","ember")
	victim = enemy(Vector3(0,0,-2))
	var crossing := enemy(Vector3(1.5,0,0))
	var barrier := wall(Vector3(1,1,0),Vector3(.2,2,3))
	await settle()
	touch(STRIKE,form,victim)
	player.position.x = 2
	node_step("q_cinder",.1)
	near(crossing.life,1000,"A fire seam cannot bridge solid cover")
	barrier.free()
	await settle()
	clear()
	check(FoundryTempo.live(combat,"q_cinder")==null,"All tempo memories are transient and removable at death/load cleanup")

func _expiry() -> void:
	var form := lay(STRIKE,"quicksilver","vigour")
	var victim := enemy(Vector3(0,0,-2))
	combat.life = combat.max_life-10
	var before := combat.life
	touch(STRIKE,form,victim)
	var node := memory("q_living")
	player.position.x = 2
	step(node,float(form.limits.identity_tempo_window_seconds)+.1)
	near(combat.life,before,"Expired Living Wake cannot pay for late movement")

	form = lay(STRIKE,"quicksilver","frost")
	victim = enemy(Vector3(0,0,0))
	cast(STRIKE)
	node = memory("q_frost")
	player.position.x = 2
	step(node,float(form.limits.identity_tempo_window_seconds))
	near(victim.chill,0,"Frost Wake's exact deadline cannot chill a late pursuer")

	form = lay(STRIKE,"quicksilver","edge")
	victim = enemy(Vector3(0,0,-2))
	touch(STRIKE,form,victim)
	node = memory("q_razor")
	player.position = Vector3(0,.8,-3.5)
	step(node,float(form.limits.identity_tempo_window_seconds)+.1)
	near(victim.life,1000,"Expired Razor Wake cannot pay for a late flank")

	form = lay(BOLT,"casting_quicksilver","vigour")
	victim = enemy(Vector3(0,0,-2))
	combat.life = combat.max_life-10
	before = combat.life
	victim.life = 0
	FoundryTempo.killed(combat,victim,BOLT)
	sim.learn_skill(ORB)
	cast(ORB)
	node = memory("c_living")
	step(node,float(form.limits.identity_tempo_window_seconds)+.1)
	near(combat.life,before,"Expired Living Echo cannot heal on a late mote arrival")

	form = lay(STRIKE,"striking_quicksilver","frost")
	victim = enemy(Vector3(0,0,-2))
	var second := enemy(Vector3(2,0,-2))
	touch(STRIKE,form,victim)
	touch(STRIKE,form,second)
	node = memory("s_frost")
	step(node,float(form.limits.identity_tempo_window_seconds)+.1)
	near(victim.chill,0,"Expired Frost Refrain cannot deliver a late returning mote")

	form = lay(STRIKE,"quicksilver","ember")
	victim = enemy(Vector3(0,0,-2))
	touch(STRIKE,form,victim)
	node = memory("q_cinder")
	player.position.x = 2
	step(node,.1)
	var late := enemy(Vector3(1,0,0))
	step(node,float(form.limits.identity_tempo_seam_seconds)+.1)
	near(late.life,1000,"Expired Cinder Wake cannot cut a late crossing")

	form = lay(BOLT,"casting_quicksilver","reach")
	victim = enemy(Vector3(0,0,-3))
	var outer := enemy(Vector3(2.3,0,-3))
	touch(BOLT,form,victim)
	node = memory("c_wide")
	step(node,float(form.limits.identity_tempo_window_seconds)+.1)
	check(outer.life<1000 and victim.life==1000,"A scheduled Wide Echo still pays its one terminal release on a long tick")
	var after := outer.life
	step(node,.1)
	near(outer.life,after,"A terminal release cannot be replayed after expiry")

	form = lay(BOLT,"casting_quicksilver","plate")
	cast(BOLT)
	node = memory("c_brace")
	step(node,float(form.limits.identity_tempo_window_seconds)+.1)
	check(combat._cast_armour>0,"Braced Echo preserves its deliberate completed stationary release")
