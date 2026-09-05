extends Node3D
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var combat: PlayerCombat
var sim: WroughtwildSim
var landed_hits := 0
const NEW := [&"prototype_fan_shot",&"prototype_bodkin_shot",&"prototype_driving_blow",&"prototype_reaping_sweep",&"prototype_cinderburst",&"prototype_ashfall"]

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func settle() -> void:
	for i in 3: await get_tree().physics_frame

func clear() -> void:
	for group in ["enemies","player_projectiles","skill_bursts"]:
		for node in get_tree().get_nodes_in_group(group): node.free()
	for id in combat.cooldowns: combat.cooldowns[id]=0.0
	landed_hits=0

func enemy(at: Vector3) -> Enemy:
	var e := Enemy.spawn(self,&"ember_whelp",at)
	e.set_physics_process(false)
	return e

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

func shot(id: StringName, at:=Vector3(0,0.8,0),dir:=Vector3.FORWARD) -> SkillProjectile:
	var s := SkillProjectile.launch(id,combat,self,at,dir,0,[])
	s.set_physics_process(false)
	return s

func _ready() -> void:
	get_window().size=Vector2i(1280,720)
	wall(Vector3(0,-0.5,0),Vector3(100,1,100))
	player=preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position=Vector3(0,1.1,0)
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	combat=player.combat
	combat.set_physics_process(false)
	sim=combat.sim
	combat.hit_landed.connect(func(_d,_k,_t): landed_hits+=1)
	for id in NEW:
		check(sim.learn_skill(id),"new skill page can be learned: "+String(id))
		check(not String(sim.combat_skill(id).get("description","")).is_empty(),"skill explains its tactical use")
	await settle()
	var line: Array=[]
	for z in [-3.0,-5.0,-7.0]: line.append(enemy(Vector3(0,0,z)))
	await settle()
	var arrow:=shot(NEW[1])
	arrow.advance(0.3)
	check(landed_hits==3 and arrow.spent,"Bodkin pierces three enemies in travel order during a long frame")
	for e in line: check(e.life<e.max_life,"each enemy in the line takes its own sim hit")
	clear()
	var before:=enemy(Vector3(0,0,-3))
	var behind:=enemy(Vector3(0,0,-7))
	var cover:=wall(Vector3(0,1,-5),Vector3(3,3,0.08))
	await settle()
	arrow=shot(NEW[1]); arrow.advance(1.0)
	check(before.life<before.max_life and behind.life==behind.max_life and arrow.spent,"piercing arrow stops at thin cover before a rear enemy")
	cover.free();clear()
	var front:=enemy(Vector3(0,0,-3))
	front.apply_chill(1000)
	await settle()
	arrow=shot(NEW[1]);arrow.advance(0.15)
	check(front.life<=0,"physical piercing shot cashes in a frozen enemy through the attack hook")
	clear()
	var boss:=Boss.spawn_boss(self,Vector3(0,0,-4))
	boss.set_physics_process(false)
	boss.apply_chill(1000)
	await settle()
	arrow=shot(NEW[1]);arrow.advance(0.2)
	check(boss.life>0 and not boss.is_frozen(),"the same projectile thaws a frozen boss without executing it")
	clear()
	var close:=enemy(Vector3(0,0,-1))
	await settle()
	combat._launch_fan(NEW[0],Vector3(0,0.8,0),Vector3.FORWARD)
	for s in get_tree().get_nodes_in_group("player_projectiles"):
		s.set_physics_process(false)
		s.advance(0.1)
	check(landed_hits==1 and close.max_life-close.life<15,"point-blank fan hits once, not three stacked arrows")
	clear()
	line=[]
	for x in [-1.0,0.0,1.0]: line.append(enemy(Vector3(x,0,-4)))
	await settle()
	combat._launch_fan(NEW[0],Vector3(0,0.8,0),Vector3.FORWARD)
	for s in get_tree().get_nodes_in_group("player_projectiles"):
		s.set_physics_process(false); s.advance(0.25)
	check(landed_hits==3,"fan covers three spread enemies")
	clear()
	front=enemy(Vector3(0,0,-3))
	var aside:=enemy(Vector3(1.7,0,-2.5))
	await settle()
	check(combat.use_skill(NEW[2]) and front.staggered() and aside.life==aside.max_life,"Driving Blow reaches the distant line without sweeping the flank")
	check(combat.cast_armour()>=12,"driving commitment grants its existing-style swing armour")
	clear()
	aside=enemy(Vector3(1.7,0,-2.5))
	await settle()
	combat.use_skill(NEW[2])
	check(aside.life==aside.max_life,"an empty driving line does not fall back to a wide flank hit")
	clear()
	front=enemy(Vector3(1.8,0,-1))
	behind=enemy(Vector3(0,0,2))
	await settle()
	combat.use_skill(NEW[3])
	check(front.bleed>0 and behind.bleed==0,"Reaping Sweep applies bleed to a broad front, not behind")
	clear()
	front=enemy(Vector3(0,0,-4))
	var neighbour:=enemy(Vector3(1.4,0,-4))
	behind=enemy(Vector3(3.8,0,-4))
	await settle()
	var coal:=shot(NEW[4]);coal.advance(0.4)
	check(front.life<front.max_life and neighbour.life<neighbour.max_life and behind.life==behind.max_life,"Cinderburst catches a cluster in one contact burst")
	check(front.max_life-front.life<22 and front.ignite>0,"contact target receives one sim hit and the ignite payload")
	clear()
	for spec in [[NEW[4],3],[NEW[5],2]]:
		front=enemy(Vector3(0,0,-4))
		front.max_life=1000;front.life=1000
		await settle()
		for i in int(spec[1]):
			SkillBurst.hit_area(combat,spec[0],Vector3(0,0.7,-4),2.3,1,[],true)
			check((front.burning_left>0)==(i==int(spec[1])-1),"slow area spell reaches its intended ignite breakpoint with real cooldown decay")
			if i<int(spec[1])-1: front._tick_statuses(combat.cooldown_total(spec[0]))
		clear()
	front=enemy(Vector3(1,0,-4));behind=enemy(Vector3(-1,0,-4))
	cover=wall(Vector3(0,1,-4),Vector3(0.08,3,4))
	await settle()
	SkillBurst.hit_area(combat,NEW[4],Vector3(0.2,0.7,-4),2.3,1,[],true)
	check(front.life<front.max_life and behind.life==behind.max_life,"solid wall blocks area damage")
	cover.free();clear()
	front=enemy(Vector3(0,0,-4))
	await settle()
	var mark:=SkillBurst.mark(combat,NEW[5],Vector3(0,0.08,-4),Vector3.UP,0.85)
	mark.set_physics_process(false)
	mark.advance(0.8)
	check(front.life==front.max_life and not mark.detonated,"marked ground does no damage before the delay")
	mark.advance(0.06)
	check(front.life<front.max_life and mark.detonated,"marked ground detonates after its delay")
	var life_after:=front.life
	mark.advance(0.1)
	check(front.life==life_after,"blast aftermath never pays a second hit")
	clear()
	front=enemy(Vector3(0,0,-4))
	mark=SkillBurst.mark(combat,NEW[5],Vector3(0,0.08,-4),Vector3.UP,0.85)
	mark.set_physics_process(false)
	front.position.x=5
	await settle()
	mark.advance(1)
	check(front.life==front.max_life,"moving out of a fixed mark avoids the blast")
	clear()
	player.spring_arm.rotation.x=0.6
	await settle()
	var uses:int=sim.combat_skill(NEW[5]).uses
	check(not combat.use_skill(NEW[5]) and combat.is_ready(NEW[5]) and sim.combat_skill(NEW[5]).uses==uses,"aiming Ashfall into sky spends no cooldown or mastery")
	player.spring_arm.rotation.x=-0.4
	await settle()
	check(combat.use_skill(NEW[5]),"Ashfall casts on a visible surface")
	mark=get_tree().get_nodes_in_group("skill_bursts")[0]
	mark.set_physics_process(false)
	var fixed:=mark.global_position
	player.rotation.y=1.2
	check(mark.global_position==fixed and not combat.use_skill(NEW[5]),"turning does not move a mark and cooldown rejects a second cast")
	clear()
	for i in 12:
		mark=SkillBurst.mark(combat,NEW[5],Vector3(0,0.08,-4),Vector3.UP,0.85)
		mark.set_physics_process(false)
	check(not combat.use_skill(NEW[5]) and combat.is_ready(NEW[5]),"live mark budget refuses a new cast without spending")
	combat.died.emit()
	for effect in get_tree().get_nodes_in_group("skill_bursts"):
		check(effect.is_queued_for_deletion(),"death cancels pending damage")
	await settle();clear()
	# An asynchronous linked delivery must not start a new link chain later.
	combat._link_depth=1
	arrow=shot(NEW[1])
	mark=SkillBurst.mark(combat,NEW[5],Vector3(0,0.08,-4),Vector3.UP,0.85)
	mark.set_physics_process(false)
	combat._link_depth=0
	check(not arrow.allow_links and not mark.allow_links,"projectile and delayed links retain the recursion guard after cast returns")
	clear()
	var saves:=SaveManager.new()
	var saved:=saves.capture(player)
	arrow=shot(NEW[1])
	mark=SkillBurst.mark(combat,NEW[5],Vector3(0,0.08,-4),Vector3.UP,0.85)
	mark.set_physics_process(false)
	check(saves.apply(player,saved),"normal save restore accepts expanded skills")
	check(arrow.spent and arrow.is_queued_for_deletion() and mark.is_queued_for_deletion(),"reload cancels projectiles and delayed damage from the abandoned timeline")
	await settle();clear()
	player.inventory_panel.open_panel()
	player.inventory_panel.show_guide(true)
	var guide:=player.inventory_panel.guide
	guide.select_filter("Undiscovered")
	check(not guide.shown_skills.has(String(NEW[0])),"discovered page leaves the unknown filter")
	guide.select_filter("Attacks")
	check(guide.shown_skills.has(String(NEW[0])) and not guide.shown_skills.has(String(NEW[5])),"guide separates attacks and spells by tags")
	for card in guide.get_children():
		if card is PanelContainer:
			var column:=card.get_child(0)
			if String(column.get_child(0).text).begins_with("Fan Shot"):
				column.get_child(column.get_child_count()-1).get_child(3).pressed.emit()
				break
	check(sim.skill_bar()[3]==String(NEW[0]),"guide slot button assigns the selected skill to the selected bar slot")
	guide.select_page("Kinds")
	check(guide.shown_kinds.size()==12,"guide exposes all Kind variants, including ones not held")
	guide.select_page("Progression")
	for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size=size
		player.inventory_panel._fit_height()
		for i in 6: await get_tree().process_frame
		var rect:=player.inventory_panel._root.get_global_rect()
		check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=size.x+1 and rect.end.y<=size.y+1,"build guide fits viewport %s" % size)
	player.inventory_panel.close_panel()
	player.foundry_panel.open_panel()
	for size in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size=size
		player.foundry_panel.refresh()
		for i in 8: await get_tree().process_frame
		var rect:=player.foundry_panel._root.get_global_rect()
		check(rect.position.x>=0 and rect.position.y>=0 and rect.end.x<=size.x+1 and rect.end.y<=size.y+1,"Foundry stays in viewport with expanded skill tray %s (%s)" % [size,rect])
	print("%d skill expansion checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)
