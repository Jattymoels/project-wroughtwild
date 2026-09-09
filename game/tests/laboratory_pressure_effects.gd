extends "res://tests/forge_tells.gd"
## Isolated contact/clock checks through real configured native entry. Synthetic
## access, controlled positions and inherited forced cleanup are explicitly scoped.
var ready_save:=""
var counting:=false
var projectiles:=0

func _ready() -> void:
	_body(Vector3(0,-.25,0),Vector3(50,.5,50))
	var arena:=preload("res://scenes/trial_arena.tscn").instantiate();arena.position=Vector3(90,0,0);add_child(arena)
	player=preload("res://scenes/player.tscn").instantiate();add_child(player)
	player.placement.set_physics_process(false);player.combat.set_physics_process(false)
	trial=player.trial;trial.set_process(false);sim=player.inventory.get_sim()
	ready_save=preload("res://tests/central_fixture.gd").ready_rules(sim,sim.export_json())
	check(sim.import_json(ready_save),"synthetic native campaign prerequisites")
	sim.record_world_effect("forge_arc_complete");ready_save=sim.export_json()
	get_tree().node_added.connect(func(node:Node):
		if counting && node is EnemyProjectile:projectiles+=1)
	for ticks in [20,60]:
		Engine.physics_ticks_per_second=ticks
		enter_pressure("relentless_boss")
		player.set_physics_process(false)
		await _boss(String(sim.boss().id))
		trial.on_player_died();await settle()
		for mode in ["stand","side","cover"]:await crossfire(mode,ticks)
	Engine.physics_ticks_per_second=60
	print("LF7_PRESSURE_EFFECTS ",checks," checks, ",failures," failures; real configured contacts at 20/60 Hz")
	get_tree().quit(1 if failures else 0)

func enter_pressure(pressure:String) -> void:
	check(sim.import_json(ready_save),"reset exact fixture")
	var offers:=sim.trial_map_offers(1,pressure)
	for i in offers.size():
		if bool(offers[i].available):
			check(trial.begin_map(1,i,pressure,String(offers[i].id)),"actual configured entry: "+pressure)
			return
	check(false,"compatible fixed pressure")

func crossfire(mode:String,ticks:int) -> void:
	enter_pressure("crossfire")
	player.position=Vector3(0,.96,0);player.rotation=Vector3.ZERO;player.velocity=Vector3.ZERO
	player.combat.restore_life();player.combat.invulnerable_left=0;player.set_physics_process(true)
	var archer:=Enemy.spawn(self,&"cinder_archer",Vector3(0,.02,9))
	trial._make_relentless(archer)
	archer.set_physics_process(false)
	await settle()
	for step in ticks*2:
		archer._physics_process(1.0/ticks)
		if archer.state=="windup":break
		await settle(1)
	check(archer.state=="windup","Crossfire retains committed ranged windup")
	var aim:=archer._shot_aim
	var cover:StaticBody3D
	if mode=="cover":cover=_body(Vector3(0,1.5,4),Vector3(5,3,.3))
	if mode=="side":player.test_walk=Vector2(1,0)
	var life:=player.combat.life
	projectiles=0;counting=true
	for step in ticks*3:
		if projectiles==0:archer._physics_process(1.0/ticks)
		await settle(1)
	counting=false;player.test_walk=Vector2.ZERO
	check(projectiles==3,"Crossfire releases exactly the centre shot plus two actual physical fan shots")
	check(archer._shot_aim==aim,"player movement never retargets the committed fan")
	check((player.combat.life<life)==(mode=="stand"),"actual "+mode+" contact outcome at "+str(ticks)+" Hz")
	print("LF7_CROSSFIRE ",mode," hz=",ticks," projectiles=",projectiles," damage=",life-player.combat.life)
	if is_instance_valid(cover):cover.free()
	archer.free()
	for projectile in get_tree().get_nodes_in_group("enemy_projectiles"):projectile.queue_free()
	trial.on_player_died();await settle()
