extends Node3D
var checks := 0
var failures := 0
const FEEL = preload("res://art/combat_feel.tres")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	var player: WroughtwildPlayer = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.position = Vector3(0,1,0)
	var combat := player.combat
	combat.set_physics_process(false)
	var compass := player.hud.damage_compass
	compass.set_process(false)
	check(compass.mouse_filter == Control.MOUSE_FILTER_IGNORE, "damage overlay never captures mouse input")
	for pair in [[Vector3.FORWARD,Vector2.UP],[Vector3.BACK,Vector2.DOWN],[Vector3.RIGHT,Vector2.RIGHT],[Vector3.LEFT,Vector2.LEFT]]:
		check(compass.screen_direction(pair[0]).is_equal_approx(pair[1]), "cardinal incoming direction %s" % pair[0])
	player.spring_arm.rotation.x = -1.25
	check(compass.screen_direction(Vector3.BACK).is_equal_approx(Vector2.DOWN), "steep pitch keeps behind at the bottom")
	player.spring_arm.rotation.x = 0
	var source := Node3D.new()
	add_child(source)
	source.position = player.position+Vector3.RIGHT*3
	combat.take_hit(4,"physical","fixture",source)
	check(compass.bearings.size()==1 and compass.bearings[0].direction==Vector3.RIGHT,"real damage reports the source bearing")
	source.position = player.position+Vector3.LEFT*3
	check(compass.bearings[0].direction==Vector3.RIGHT,"moving attacker is not tracked after the hit")
	source.free()
	player.rotation.y = PI/2
	check(compass.screen_direction(compass.bearings[0].direction).is_equal_approx(Vector2.DOWN),"camera turn reorients a remembered hit")
	player.rotation.y = 0
	compass.clear()
	combat.take_hit(4,"fire","departed archer",null,Vector3.BACK)
	check(compass.bearings.size()==1 and compass.bearings[0].direction==Vector3.BACK,"projectile flight direction survives a deleted shooter")
	compass.clear()
	combat.invulnerable_left = 1
	combat.take_hit(10,"physical","blocked",null,Vector3.RIGHT)
	check(compass.bearings.is_empty(),"rejected hit never produces an indicator")
	combat.invulnerable_left = 0
	combat.take_hit(0,"physical","zero",null,Vector3.RIGHT)
	check(compass.bearings.is_empty(),"zero damage never produces an indicator")
	combat.take_hit(1,"fire","burning ground")
	check(compass.bearings.is_empty() and compass.unknown_left>0,"environmental damage has no invented direction")
	compass.clear()
	compass.receive_hit(1,Vector3.RIGHT)
	compass.receive_hit(1,Vector3.RIGHT)
	check(compass.bearings.size()==1,"repeated hits merge by bearing")
	for i in 24:
		compass.receive_hit(1,Vector3.FORWARD.rotated(Vector3.UP,TAU*float(i)/24))
	check(compass.bearings.size()<=FEEL.max_hit_directions,"pack-hit visual count stays bounded")
	compass.sample(FEEL.hit_seconds+0.01)
	check(compass.bearings.is_empty() and compass.unknown_left==0,"indicators expire completely")
	compass.receive_hit(1,Vector3.RIGHT)
	combat.died.emit()
	check(compass.bearings.is_empty(),"death clears old bearings before respawn")
	var hands := player.camera.get_node("FirstPersonHands") as FirstPersonHands
	hands.set_process(false)
	var camera_before := player.camera.transform
	var body_before := player.transform
	var sim_before := combat.sim.export_json()
	var expected := {
		"prototype_heavy_strike":"strike", "prototype_rend":"rend",
		"prototype_area_strike":"sweep", "prototype_cinder_sweep":"sweep",
		"prototype_frost_nova":"nova", "prototype_bow_shot":"arrow",
		"prototype_frost_orb":"frost", "prototype_ember_bolt":"ember",
	}
	var poses := {}
	for id in expected:
		hands.present_skill(StringName(id))
		hands.sample(0.03)
		check(hands.active_profile==expected[id],"existing skill has delivery/tag profile: "+id)
		poses[id] = hands.hands[1].transform
	check(poses.prototype_heavy_strike!=poses.prototype_rend and poses.prototype_area_strike!=poses.prototype_frost_nova,"strike, rend, sweep and nova have different hand poses")
	check(poses.prototype_bow_shot!=poses.prototype_ember_bolt and poses.prototype_frost_orb!=poses.prototype_ember_bolt,"arrow, frost and ember have different hand poses")
	check(combat.sim.export_json()==sim_before,"presentation alone never changes persistent rules state")
	check(player.camera.transform==camera_before and player.transform==body_before,"presentation never kicks the camera or player")
	hands.sample(2.0)
	check(hands.remaining==0,"cast gesture settles completely")
	combat.cooldowns[PlayerCombat.AREA_SKILL] = 0
	combat.use_skill(PlayerCombat.AREA_SKILL)
	var effect_count := get_tree().get_nodes_in_group("skill_cast_effects").size()
	var left := hands.remaining
	check(not combat.use_skill(PlayerCombat.AREA_SKILL) and hands.remaining==left and get_tree().get_nodes_in_group("skill_cast_effects").size()==effect_count,"cooldown refusal adds neither a gesture nor an effect")
	for i in 20:
		SkillCastEffect.spawn(combat,PlayerCombat.AREA_SKILL)
	check(get_tree().get_nodes_in_group("skill_cast_effects").size()<=FEEL.max_cast_effects,"rapid cast effects stay bounded within one frame")
	for effect in get_tree().get_nodes_in_group("skill_cast_effects"):
		effect._process(1.0)
		check(effect.is_queued_for_deletion(),"cast aftermath frees itself")
	for base in CombatVisuals.BASE_ROLES:
		var index := combat.sim.roll_item_into_pack(base,"plain",1,17)
		combat.sim.equip_pack_item(index)
		hands.refresh_weapon()
		hands.sample(0.0)
		check(hands.weapon_base==base and hands.weapon.mesh!=null,"equipped weapon has its actual model: "+base)
	combat.sim.unequip("weapon")
	hands.refresh_weapon()
	hands.sample(0.0)
	check(hands.weapon.mesh==null and not hands.weapon.visible,"unequipping removes the held model")
	for id in ["prototype_bow_shot","prototype_frost_orb","prototype_ember_bolt"]:
		var shot := SkillProjectile.launch(StringName(id),combat,self,Vector3(0,3,0),Vector3.RIGHT,0,[])
		shot.set_physics_process(false)
		check(shot.visual_profile==expected[id] and shot.visual.get_child_count()>0,"actual projectile uses distinct visual: "+id)
		check((-shot.visual.basis.z).is_equal_approx(Vector3.RIGHT),"projectile visual points along its flight")
		var position_before := shot.position
		shot._process(0.2)
		check(shot.position==position_before,"projectile presentation never advances physics")
		shot.queue_free()
	for resolution in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = resolution
		combat._marked_left = 5.0
		player.hud.refresh()
		for i in 3:
			await get_tree().process_frame
		check(player.hud._life_text.get_global_rect().end.x < player.hud.action_bar.get_global_rect().position.x,"long combat status stays left of skill bar at %s" % resolution)
		check(compass.size.is_equal_approx(Vector2(resolution)),"damage compass follows viewport at %s" % resolution)
	print("CODEX_COMBAT_PRESENTATION %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
