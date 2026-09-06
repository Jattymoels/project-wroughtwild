extends Node3D
## Real Foundry routes prepare the defences. Controlled spatial probes then
## exercise the decision and its negative case without scripted mob kills.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var combat: PlayerCombat
var sim: WroughtwildSim
const STRIKE := &"prototype_heavy_strike"
const INGOTS := ["ember","frost","edge","reach","vigour","plate","ward","haste"]

func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL: ",message)

func near(a: float, b: float, message: String) -> void:
	check(absf(a-b)<.001,message+" (%f, expected %f)"%[a,b])

func settle() -> void:
	for i in 3: await get_tree().physics_frame

func wall(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size=size
	shape.shape=box
	body.add_child(shape)
	add_child(body)
	body.position=at
	return body

func mob(at: Vector3, kind := &"ember_whelp") -> Enemy:
	var enemy := Enemy.spawn(self,kind,at)
	enemy.set_physics_process(false)
	enemy.life=1000
	enemy.max_life=1000
	return enemy

func clear() -> void:
	for group in ["foundry_guard","foundry_cold","foundry_embers","foundry_fields","foundry_returns","foundry_echoes","foundry_puffs","enemies","player_projectiles","enemy_projectiles","skill_cast_effects"]:
		for node in get_tree().get_nodes_in_group(group): node.free()
	for id in combat.cooldowns: combat.cooldowns[id]=0
	combat._reaction_ready.clear()
	combat._mutation_cache.clear()
	combat._action_contexts.clear()
	combat._casts.clear()
	combat.life=combat.max_life
	combat.invulnerable_left=0
	combat.clear_verbs()
	combat.clear_train()
	player.position=Vector3(0,.8,0)
	player.rotation=Vector3.ZERO

func lay(kind: String, ingot: String) -> Dictionary:
	clear()
	sim.add_material("iron_ingot",100)
	for piece in sim.foundry().plate: check(sim.foundry_remove(piece.row,piece.col),"lift fixture's previous route")
	for event in ["first_kill:ember_whelp","first_kill:gloom_crawler","work:strike_split","first_kill:cinder_archer","recipe:workbench_kit","first_kill:stone_husk","world_effect:stonecut_blocks","first_kill:ash_hound"]: sim.foundry_event(event)
	sim.learn_skill(STRIKE)
	sim.add_material(kind,1)
	check(sim.foundry_place_skill(1,1,STRIKE) and sim.foundry_place(1,0,ingot) and sim.foundry_place_kind(2,0,kind),"legal "+kind+":"+ingot+" route")
	combat._mutation_cache.clear()
	var form := combat.mutation(STRIKE)
	check(float(form.get("zone_armour",0))==0 and float(form.get("ward_charges",0))==0,"new identity replaces generic seal instead of stacking it")
	check(combat.use_skill(STRIKE),"real skill input prepares "+kind+":"+ingot)
	for active_guard in FoundryGuard.nodes(combat): active_guard.set_physics_process(false)
	return form

func event(kind: String) -> FoundryGuard:
	var node := FoundryGuard.live(combat,kind)
	check(node!=null,"real cast created "+kind)
	return node

func landed(enemy: Enemy, form: Dictionary, allowed := true) -> void:
	FoundryGuard.landed(combat,enemy,STRIKE,form,{"practice_allowed":allowed})

func shot(node: FoundryGuard, across := 0.0, backwards := false) -> Dictionary:
	var side := node.direction.cross(Vector3.UP)*across
	var from := node.global_position+node.direction*6+side
	var to := node.global_position-node.direction*6+side
	if backwards:
		var swap := from
		from=to
		to=swap
	var result := FoundryGuard.projectile_candidate(combat,from,to)
	if not result.is_empty(): result["position"]=from+(to-from)*float(result.at)
	return result

func consume(node: FoundryGuard) -> Vector3:
	var candidate := shot(node)
	check(not candidate.is_empty() and candidate.node==node,"shot actually crosses the intended defence")
	if candidate.is_empty(): return node.global_position
	check(FoundryGuard.consume_projectile(node,candidate.position),"crossing spends one charge")
	check(not FoundryGuard.consume_projectile(node,candidate.position),"the same charge cannot catch a second shot in one frame")
	return candidate.position

func _ready() -> void:
	wall(Vector3(0,-.5,0),Vector3(100,1,100))
	player=preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position=Vector3(0,.8,0)
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	combat=player.combat
	combat.set_physics_process(false)
	sim=combat.sim
	await settle()
	await guard_cases()
	await veil_cases()
	await arbitration_cases()
	await safety_cases()
	print("FoundryGuardIdentity: %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func guard_cases() -> void:
	var form := lay("vanguard","ember")
	check(combat.alive_enemies().is_empty() and combat.cooldown_left(STRIKE)>0,"a real empty Heavy Strike spends its cooldown and can prepare defence without a fabricated contact")
	var node := event("guard_furnace")
	if node==null: return
	var enemy := mob(Vector3(0,.8,-1))
	var before := enemy.life
	check(FoundryGuard.absorb(combat,20,enemy)<20,"Furnace takes part of the incoming hit")
	near(enemy.life,before,"Furnace retaliation waits for its visible delay")
	near(FoundryGuard.absorb(combat,20,enemy),20,"Furnace charge cannot absorb twice")
	node.advance(float(form.limits.identity_guard_vent_delay)+.01)
	check(enemy.life<before,"spent Furnace releases its fire packet once")
	before=enemy.life
	node.advance(10)
	near(enemy.life,before,"expired Furnace cannot vent again")

	form=lay("vanguard","frost")
	node=event("guard_rime")
	if node==null: return
	enemy=mob(Vector3(0,.8,-4))
	enemy.position=Vector3(0,.8,-1)
	node.advance(.1)
	check(enemy.chill>0 and enemy.staggered(),"Rime crossing chills and interrupts a newcomer")
	before=enemy.chill
	enemy.position.z=-4
	node.advance(.1)
	enemy.position.z=-1
	node.advance(.1)
	near(enemy.chill,before,"Rime does not repeatedly farm one enemy crossing back and forth")
	var boss := Boss.spawn_boss(self,Vector3(1,.8,0))
	boss.set_physics_process(false)
	boss.global_position=Vector3(1,.8,0)
	boss.life=1000
	node.advance(.1)
	near(boss.chill,float(form.identity_guard_rime_chill_boss),"defensive chill uses the native boss-resistant payload")
	boss.free()

	form=lay("vanguard","edge")
	node=event("guard_blade")
	if node==null: return
	enemy=mob(Vector3(0,.8,-1))
	var other := mob(Vector3(1,.8,-1))
	combat.life-=5
	FoundryGuard.damaged(combat,enemy,5)
	before=other.life
	landed(other,form)
	near(other.life,before,"Blade counter refuses an unrelated enemy")
	check(node.armed,"wrong target preserves the counter opportunity")
	before=enemy.life
	landed(enemy,form,false)
	near(enemy.life,before,"linked or repeated contact cannot spend a riposte")
	landed(enemy,form)
	check(enemy.life<before and enemy.staggered(),"answering the actual aggressor spends the Blade counter")
	check(node.is_queued_for_deletion(),"Blade counter is one-use")

	form=lay("vanguard","reach")
	node=event("guard_broad")
	if node==null: return
	enemy=mob(Vector3(0,.8,-4))
	enemy.position=node.global_position-Vector3.UP*.5
	node.advance(.1)
	check(enemy._shove_left.z<0,"Broad crossing pushes the approaching enemy away from the caster")
	other=mob(Vector3(0,.8,1))
	node.advance(.1)
	check(other._shove_left.is_zero_approx(),"Broad does not shove a rear flanker outside the crossbar")

	form=lay("vanguard","vigour")
	node=event("guard_living")
	if node==null: return
	enemy=mob(Vector3(0,.8,-1))
	combat.life-=20
	before=combat.life
	node.advance(.4)
	near(combat.life,before,"Living brace grants no healing without recorded damage")
	FoundryGuard.damaged(combat,enemy,4)
	node.advance(.6)
	near(combat.life,before,"Living recovery waits for quiet residence")
	FoundryGuard.damaged(combat,enemy,1)
	node.advance(.6)
	near(combat.life,before,"another hit restarts the quiet requirement")
	node.advance(.41)
	check(combat.life>before,"quiet residence collects recorded Living recovery")
	form=lay("vanguard","vigour")
	node=event("guard_living")
	enemy=mob(Vector3(0,.8,-1))
	combat.life-=10
	before=combat.life
	FoundryGuard.damaged(combat,enemy,4)
	player.position.x=4
	node.advance(1.1)
	near(combat.life,before,"leaving forfeits Living recovery")

	form=lay("vanguard","plate")
	node=event("guard_plate")
	if node==null: return
	enemy=mob(Vector3(0,.8,-1))
	near(FoundryGuard.absorb(combat,20,enemy),20,"Bulwark has no pool before settling")
	node.advance(float(form.limits.identity_guard_settle_seconds)+.01)
	check(FoundryGuard.absorb(combat,20,enemy)<20,"settled Bulwark has a finite absorption pool")
	near(FoundryGuard.absorb(combat,20,enemy),20,"spent Bulwark pool cannot pay again")
	form=lay("vanguard","plate")
	node=event("guard_plate")
	player.position.x=1
	node.advance(.6)
	check(node.is_queued_for_deletion(),"moving breaks Bulwark rather than carrying its stance")

	form=lay("vanguard","ward")
	node=event("guard_post")
	if node==null: return
	enemy=mob(Vector3(0,.8,-1))
	other=mob(Vector3(1,.8,-1))
	landed(enemy,form)
	check(FoundryGuard.absorb(combat,20,enemy)<20,"Guardpost weakens its designated aggressor")
	near(FoundryGuard.absorb(combat,20,other),20,"Guardpost does not become generic resistance to other enemies")
	player.position.x=4
	near(FoundryGuard.absorb(combat,20,enemy),20,"Guardpost protection ends outside its position")

	form=lay("vanguard","haste")
	node=event("guard_quick")
	if node==null: return
	enemy=mob(Vector3(0,.8,1))
	combat.cooldowns[&"prototype_dash"]=2.0
	near(FoundryGuard.absorb(combat,20,enemy),20,"Quickbrace refuses a rear hit")
	enemy.position.z=-1
	check(FoundryGuard.absorb(combat,20,enemy)<20,"timed frontal hit spends Quickbrace")
	check(float(combat.cooldowns[&"prototype_dash"])<2,"successful Quickbrace restores movement, not another attack")
	form=lay("vanguard","haste")
	node=event("guard_quick")
	enemy=mob(Vector3(0,.8,-1))
	node.advance(.51)
	near(FoundryGuard.absorb(combat,20,enemy),20,"late hits miss the short brace window")

func veil_cases() -> void:
	var form := lay("warding_vanguard","ember")
	var node := event("veil_ember")
	if node==null: return
	var at := consume(node)
	var enemy := mob(at-Vector3.UP*.5+Vector3.RIGHT*.3)
	var before := enemy.life
	node.advance(float(form.limits.identity_veil_fuse_seconds)*.5)
	near(enemy.life,before,"Ember catch creates a fuse, not an instant explosion")
	node.advance(float(form.limits.identity_veil_fuse_seconds))
	check(enemy.life<before,"Ember fuse damages a nearby enemy after its delay")

	form=lay("warding_vanguard","frost")
	node=event("veil_rime")
	if node==null: return
	check(shot(node,1.5).is_empty(),"small Rime front initially misses a wide shot")
	node.advance(float(form.limits.identity_veil_rime_seconds)*.6)
	check(not shot(node,1.5).is_empty(),"the same shot meets the expanding Rime front later")
	at=consume(node)
	check(node.is_queued_for_deletion(),"Rime expansion still carries only one interception")

	form=lay("warding_vanguard","edge")
	check(FoundryGuard.live(combat,"veil_razor")==null,"Razor needs contact, not an empty cast")
	enemy=mob(Vector3(0,.8,-3))
	landed(enemy,form,false)
	check(FoundryGuard.live(combat,"veil_razor")==null,"linked/repeated hits cannot manufacture Razor wires")
	landed(enemy,form)
	node=event("veil_razor")
	if node==null: return
	node.set_physics_process(false)
	check(shot(node,node.radius+1).is_empty(),"Razor tripwire has a bounded lateral span")
	enemy.position=node.global_position-Vector3.UP*.5
	before=enemy.life
	consume(node)
	check(enemy.life<before,"interception snaps Razor into a narrow physical cut")

	form=lay("warding_vanguard","reach")
	node=event("veil_wide")
	if node==null: return
	check(node.global_position.z<player.global_position.z-2,"Wide Veil is projected ahead, not placed at the feet")
	check(shot(node,0,true).is_empty(),"shots from behind pass through Wide Veil")
	consume(node)
	var cover := wall(Vector3(0,1.2,-1.8),Vector3(4,3,.2))
	await settle()
	form=lay("warding_vanguard","reach")
	node=event("veil_wide")
	check(node.global_position.z> -1.8,"solid cover shortens Wide Veil projection")
	cover.free()

	form=lay("warding_vanguard","vigour")
	node=event("veil_living")
	if node==null: return
	combat.life-=20
	before=combat.life
	at=consume(node)
	node.advance(.1)
	near(combat.life,before,"Living Veil does not heal remotely at interception")
	player.position=at-Vector3.UP*.5
	node.advance(.1)
	check(combat.life>before,"approaching the impact collects Living Veil recovery")
	before=combat.life
	node.advance(1)
	near(combat.life,before,"the spent pickup cannot heal twice")
	form=lay("warding_vanguard","vigour")
	node=event("veil_living")
	if node==null: return
	combat.life-=20
	at=consume(node)
	before=combat.life
	player.position=at-Vector3.UP*.5
	node.advance(float(form.limits.identity_veil_pickup_seconds)+1)
	near(combat.life,before,"arrival after the Living Veil pickup expires grants no late heal")
	check(node.is_queued_for_deletion(),"expired Living Veil pickup is consumed without a reward")

	form=lay("warding_vanguard","plate")
	node=event("veil_iron")
	if node==null: return
	consume(node)
	check(node.mode=="veil_iron_shell","caught shot becomes a carried Iron remnant")
	enemy=mob(Vector3(0,.8,-2),&"cinder_archer")
	near(FoundryGuard.absorb(combat,20,enemy),20,"Iron remnant is reserved for a melee attacker")
	enemy=mob(Vector3(0,.8,-1))
	check(FoundryGuard.absorb(combat,20,enemy)<20,"Iron remnant absorbs part of one melee hit")
	near(FoundryGuard.absorb(combat,20,enemy),20,"Iron remnant is spent once")

	form=lay("warding_vanguard","ward")
	node=event("veil_aegis")
	if node==null: return
	check(shot(node).is_empty(),"healthy Aegis remains unarmed")
	combat.life=combat.max_life*.35
	player.position.x=3
	node.advance(.1)
	near(node.global_position.x,player.global_position.x,"armed Aegis follows the endangered player")
	consume(node)

	form=lay("warding_vanguard","haste")
	node=event("veil_fleeting")
	if node==null: return
	check(shot(node).is_empty(),"Fleeting decoy cannot protect a player who has not left")
	at=node.global_position
	player.position.x=4
	combat.cooldowns[&"prototype_dash"]=2
	node.advance(.1)
	check(node.global_position.is_equal_approx(at),"Fleeting stays behind rather than following the player")
	consume(node)
	check(float(combat.cooldowns[&"prototype_dash"])<2,"decoy interception repays movement cooldown")

func arbitration_cases() -> void:
	# Deliberately synthetic mixed-family scene: current recipes no longer make
	# the old generic seal, but any remaining legacy field must share the same
	# nearest-crossing arbitration as the new cast-created defence.
	for guard_first in [true,false]:
		var form := lay("warding_vanguard","ember")
		var node := event("veil_ember")
		if node==null: return
		var near_centre := Vector3(5,1.3,-9)
		var far_centre := Vector3(5,1.3,-3)
		node.global_position=near_centre if guard_first else far_centre
		var legacy_centre := far_centre if guard_first else near_centre
		var legacy := FoundryField.spawn(combat,STRIKE,legacy_centre,"guard",{
			"limits":form.limits,"ward_charges":1,"field_radius":.5,"zone_armour":0})
		legacy.set_physics_process(false)
		legacy.global_position=legacy_centre-Vector3.UP*.65
		var from := Vector3(5,1.3,-14)
		var to := Vector3(5,1.3,0)
		var guard_at := node.crossing(from,to)
		var legacy_at := FoundryIdentity.sphere_crossing(combat,legacy_centre,legacy.radius,from,to)
		check(is_finite(guard_at) and is_finite(legacy_at),"both mixed-family wards intersect the same cover-limited segment")
		check((guard_at<legacy_at)==guard_first,"explicit ward placement determines the intended nearest crossing")
		check(not FoundryIdentity.intercept(get_tree(),from,Vector3(5,1.3,-12),null),"a segment ending before both wards spends neither family")
		check(node.mode=="veil_ember" and legacy.charges==1,"truncated sweep preserves both interception charges")
		var saved_remaining := node.remaining
		check(FoundryIdentity.intercept(get_tree(),from,to,null),"global arbitration catches a shot crossing both ward families")
		if guard_first:
			check(node.mode=="veil_ember_fuse","earlier new ward spends its charge and becomes its fuse")
			check(legacy.charges==1,"farther legacy ward retains its charge after the earlier new ward catches")
		else:
			check(legacy.charges==0,"earlier legacy ward spends its charge before the new ward")
			check(node.mode=="veil_ember","farther new ward retains its charge after the earlier legacy ward catches")
			near(node.remaining,saved_remaining,"unselected new ward keeps its exact remaining lifetime")
	clear()

func safety_cases() -> void:
	var form := lay("warding_vanguard","ember")
	var node := event("veil_ember")
	if node==null: return
	check(FoundryGuard.projectile_candidate(combat,node.global_position+Vector3.FORWARD*6,node.global_position+Vector3.FORWARD*4).is_empty(),"a world-limited shot before the ward cannot spend it")
	var cover := wall(node.global_position+Vector3.FORWARD*.7,Vector3(4,3,.2))
	await settle()
	check(shot(node).is_empty(),"wall between ward centre and crossing refuses remote protection")
	cover.free()
	var saved_remaining := node.remaining
	combat.cooldowns[STRIKE]=0
	combat.use_skill(STRIKE)
	near(node.remaining,saved_remaining,"recasting cannot refresh a live charge")
	check(FoundryGuard.nodes(combat).size()==1,"recasting cannot stack the same defensive identity")
	near(FoundryGuard.absorb(combat,20,null),20,"environmental damage cannot spend enemy-only charges")
	combat.died.emit()
	check(FoundryGuard.nodes(combat).is_empty(),"death immediately removes every guard charge")
	# Each authored operation has its own trigger key, keeping data dispatch
	# independent of display names and avoiding an accidental shared seal.
	var combined := {}
	for kind in ["vanguard","warding_vanguard"]:
		for ingot in INGOTS:
			form=lay(kind,ingot)
			combined.merge(form,true)
			var identity_keys := []
			for key in form:
				if String(key).begins_with("identity_guard_") or String(key).begins_with("identity_veil_"): identity_keys.append(key)
			check(not identity_keys.is_empty(),kind+":"+ingot+" exposes resolved identity values")
	clear()
	for kind in FoundryGuard.CAST_MODES:
		FoundryGuard.spawn(combat,STRIKE,kind,FoundryIdentity.point(combat),combined)
	check(FoundryGuard.nodes(combat).size()==int(combined.limits.identity_guard_max_nodes),"all simultaneous defensive identities obey the shared node ceiling")
	for capped_guard in FoundryGuard.nodes(combat): capped_guard.set_physics_process(false)
	combat.died.emit()
	check(FoundryGuard.nodes(combat).is_empty(),"death clears an entire capped defensive batch without a reward")
	clear()
