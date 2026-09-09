extends "res://tests/living_frontier_hosts.gd"
var human: Conservator
var total_hits := 0
var total_damage := 0.0

func _contact_cases() -> void:
	player=preload("res://scenes/player.tscn").instantiate()
	player.position=Vector3(0,1,0)
	add_child(player)
	player.placement.set_physics_process(false)
	player.trial.set_process(false)
	sim=player.inventory.get_sim()
	pristine=preload("res://tests/central_fixture.gd").ready_rules(sim,sim.export_json())
	check(not pristine.is_empty(),"actual campaign prerequisites prepare from frozen first-clear receipt")
	player.combat.hit_taken.connect(func(amount: float,_source: String): total_hits+=1;total_damage+=amount)
	if "--lf6-visuals" in OS.get_cmdline_user_args():
		await capture_human()
		return
	for ticks in [20,60]:
		Engine.physics_ticks_per_second=ticks
		for sequence in 3:
			for mode in ["stand","side","cover","stagger","freeze","drain"]:
				await human_contact(sequence,mode,ticks)
			if sequence==2:
				for mode in ["branch","branch_cover"]: await human_contact(sequence,mode,ticks)
	Engine.physics_ticks_per_second=60
	for class_id in ["warden","ranger","kindler"]: await human_fight(class_id)
	var file:=FileAccess.open("res://../build/lf6/combat.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"samples":results},"  "))
	print("LF6_COMBAT ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)

func prepare(class_id: String="warden", sequence: int=0) -> void:
	if is_instance_valid(human): human.free()
	sim.trial_abandon()
	sim.trial_end()
	await reset_case(class_id)
	player.combat.invulnerable_left=0
	check(sim.trial_start_story(618,"forge_capstone"),"actual Central native session selects human")
	human=Boss.spawn_boss(self,Vector3(0,.02,5)) as Conservator
	enemy=human
	check(human!=null,"dedicated scene spawned")
	human.sequence_index=sequence
	total_hits=0;total_damage=0

func human_contact(sequence: int, mode: String, ticks: int) -> void:
	await prepare("warden",sequence)
	for i in ticks*2:
		if not human.channel.is_empty(): break
		await frames(1)
	check(not human.channel.is_empty(),"actual physics begins a channel")
	var mark:=human.committed_mark
	var origin:=human.committed_origin
	var directions:=human.committed_directions.duplicate()
	var initial:=human.channel
	if mode in ["branch","branch_cover"]:
		# Contact placement inside a committed branch; escape cases use movement.
		player.global_position=origin+directions[0]*5+Vector3.UP
	var blue_frames:=0;var red_frames:=0
	var wall: StaticBody3D
	if mode in ["cover","branch_cover"]:
		wall=StaticBody3D.new()
		var collider:=CollisionShape3D.new()
		var shape:=BoxShape3D.new()
		shape.size=Vector3(8,4,.25)
		collider.shape=shape
		wall.add_child(collider)
		wall.position=Vector3(0,2,2.5)
		add_child(wall)
	var interrupted:=false
	for step in ticks*4:
		if human.channel=="blue": blue_frames+=1
		if human.channel=="red": red_frames+=1
		if step>=int(ticks*.3):
			if mode=="side": player.test_walk=Vector2(1,0)
			elif mode=="stagger" and not interrupted: human.stagger(.5);interrupted=true
			elif mode=="freeze" and not interrupted: human.apply_chill(100);interrupted=true
			elif mode=="drain" and not interrupted:
				check(human.drain_channel(),"active channel drains")
				check(human.recovery_left==human.rule("release_recovery_seconds"),"apparatus earns its full exposed recovery")
				check(not human.drain_channel(),"draining recovery cannot extend it again")
				interrupted=true
		check(human.committed_mark==mark && human.committed_origin==origin && human.committed_directions==directions,"warning cannot retarget")
		await frames(1)
		if human.releases>0 or interrupted: break
	player.test_walk=Vector2.ZERO
	# Tick once so the contact's normal damage signal has completed.
	await frames(1)
	var should_hit:bool=(mode=="stand" and sequence!=2) or mode=="branch"
	check((total_hits==1 && total_damage>0) if should_hit else total_hits==0,"contact/counterplay "+initial+" "+mode)
	check(human.releases==(0 if interrupted else 1),"one release or complete cancellation")
	if sequence==1 and not interrupted: check(blue_frames>=ticks-1 && red_frames>=ticks-1,"full separate Blue and Red warnings")
	check(human.recovery_left>0 && human.channel_tells.is_empty(),"release/cancel exposes recovery and removes danger")
	results.append({"kind":"contact","channel":initial,"mode":mode,"ticks":ticks,"hits":total_hits,"damage":total_damage,"releases":human.releases})
	print("LF6_CONTACT ",JSON.stringify(results.back()))
	if wall!=null: wall.free()
	human.free()
	sim.trial_abandon()
	sim.trial_end()
	await frames(2)

func human_fight(class_id: String) -> void:
	# Class, materials and ordinary workbench access are explicit fixtures.
	# Craft payment, casts, incoming hits, statuses and boss death are real.
	sim.trial_abandon()
	sim.trial_end()
	await reset_case(class_id)
	sim.add_station("workbench")
	sim.add_materials({"wood":30,"hide":8})
	check(bool(sim.craft({"warden":"wooden_cudgel","ranger":"simple_bow","kindler":"wooden_focus"}[class_id]).get("crafted",false)),"ordinary weapon is paid")
	check(sim.equip_pack_item(sim.pack_items().size()-1),"ordinary weapon equipped")
	check(sim.foundry().plate.is_empty(),"build contains no Catalyst or support fixture")
	check(sim.trial_start_story(618,"forge_capstone"),"real fight uses Central native boss definition")
	player.combat.invulnerable_left=0
	human=Boss.spawn_boss(self,Vector3(0,.02,5)) as Conservator
	enemy=human
	total_hits=0;total_damage=0
	var casts:=0;var seconds:=0.0;var observed: Dictionary={}
	release_count=0
	human.attack_released.connect(func(_kind:String):release_count+=1)
	for step in 60*120:
		if not is_instance_valid(human) or human.life<=0 or player.combat.life<=0: break
		var to: Vector3=(human.position-player.position)*Vector3(1,0,1)
		var forward:=to.normalized()
		var distance:=to.length()
		player.look_at(player.position+forward)
		player.camera.look_at(human.position+Vector3.UP*1.4)
		var move:=Vector3.ZERO
		if distance>(1.5 if class_id=="warden" else 5.0): move=forward
		if not human.channel.is_empty():
			observed[human.channel]=true
			if human.channel in ["blue","red"]:
				var away:Vector3=(player.position-human.committed_mark)*Vector3(1,0,1)
				move=away.normalized() if away.length()>.2 else Vector3(-forward.z,0,forward.x)
				if away.length()>human.rule("mark_radius_m")+.5: move=Vector3.ZERO
			elif human.channel=="white": move=Vector3(-forward.z,0,forward.x)
			else: move=Vector3.ZERO # The committed centre gap is Green's answer.
		var local:=player.global_basis.inverse()*move
		player.test_walk=Vector2(local.x,local.z)
		for skill in sim.skill_bar():
			var definition:Dictionary=player.combat.skills.get(skill,{})
			if definition.get("delivery","")=="dash": continue
			if definition.get("delivery","") in ["strike","cone"] and distance>player.combat.strike_reach(skill): continue
			if player.combat.use_skill(skill): casts+=1;break
		await frames(1)
		seconds+=1.0/60
	var remaining:=human.life if is_instance_valid(human) else 0.0
	check(remaining<=0 && player.combat.life>0,"ordinary "+class_id+" wins through actual casts")
	check(casts>0 && player.combat.invulnerable_left==0 && player.combat.is_physics_processing(),"live combat without invulnerability")
	results.append({"kind":"fight","class":class_id,"seconds":seconds,"casts":casts,"life":player.combat.life,"hits":total_hits,"damage":total_damage,"remaining":remaining,"observed":observed,"releases":release_count})
	print("LF6_FIGHT ",JSON.stringify(results.back()))
	player.test_walk=Vector2.ZERO
	if is_instance_valid(human): human.free()
	player.combat.clear_trial_effects()
	sim.trial_abandon()
	sim.trial_end()
	await frames(3)

func capture_human() -> void:
	await prepare()
	var floor_mesh:=MeshInstance3D.new()
	var mesh:=BoxMesh.new();mesh.size=Vector3(40,.1,40)
	floor_mesh.mesh=mesh
	floor_mesh.position.y=-.06
	add_child(floor_mesh)
	var light:=DirectionalLight3D.new();light.rotation_degrees=Vector3(-55,-35,0);add_child(light)
	var environment:=WorldEnvironment.new();environment.environment=Environment.new()
	environment.environment.background_mode=Environment.BG_COLOR
	environment.environment.background_color=Color("424f59")
	environment.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color=Color("bcc7ca")
	environment.environment.ambient_light_energy=.65
	add_child(environment)
	var camera:=Camera3D.new();add_child(camera)
	camera.position=Vector3(7,6,-5);camera.look_at(Vector3(0,1,3));camera.current=true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://../captures/lf6"))
	for phase in ["white","blue","red","green"]:
		for i in 900:
			if human.channel==phase: break
			await frames(1)
		check(human.channel==phase,"capture actual "+phase+" tell")
		await frames(8)
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("res://../captures/lf6/"+phase+".png")
	print("LF6_VISUALS ",checks," checks, ",failures," failures")
	get_tree().quit(1 if failures else 0)
