extends "res://tests/wide_frontier_review.gd"
## Real world presentation, collision, automatic population ticks and enemy AI.
## Scripted observer follows the existing approach; no combat/economy shortcuts.

func _ready() -> void:
	world_profile="frontier_v6"
	world_seed=1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--home-seed="): world_seed=int(arg.get_slice("=",1))
	output=ProjectSettings.globalize_path("res://../build/intensives/population-walk-%d"%world_seed)
	DirAccess.make_dir_recursive_absolute(output)
	_build_world(world_seed)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.set_process_unhandled_input(false)
	player.hide()
	player.hud.hide()
	mood.set_process(false)
	mood.set_physics_process(false)
	set_physics_process(false)
	_setup_camera()
	Engine.max_fps=60
	report={"seed":world_seed,"scope":"Scripted 5m/s observer at 1.65m, real streaming/automatic packs/enemy AI. No attacks by observer; no normal saves loaded.","walks":[],"encounters":[]}
	var quarry: Dictionary
	for h: Dictionary in terrain.map.habitats:
		if h.id=="quarry_escarpment": quarry=h
	check(not quarry.is_empty(),"native shellstone quarry exists")
	for dark in [false,true]:
		_clear_population()
		mob_packs.set_night(dark,_sim().day_rules())
		mob_packs.night_progress=.17 if dark else 0.0
		_review_light(dark) # Dusk visibility accompanies the labelled night patrol state.
		var path: PackedVector3Array=quarry.approach
		var start:=maxi(0,path.size()-61)
		await _settle(path[start],48)
		var distance:=0.0
		var peak:=0
		var seen: Dictionary={}
		var samples: Array=[]
		for index in range(start,path.size()-1):
			var a:=path[index]
			var b:=path[index+1]
			var length:=a.distance_to(b)
			var steps:=maxi(1,ceili(length/5.0*60))
			for step in steps:
				var pose:=a.lerp(b,float(step)/steps)
				var ahead:=path[mini(index+5,path.size()-1)]
				if Vector2(ahead.x-pose.x,ahead.z-pose.z).length()<5:
					var direction:=Vector3(b.x-a.x,0,b.z-a.z).normalized()
					ahead=pose+direction*8
				_pose(pose,ahead)
				await get_tree().physics_frame
				peak=maxi(peak,mob_packs.live_count())
				for p: Dictionary in mob_packs._active_packs(): seen[p.index]=true
			distance+=length
			if index%10==0: samples.append({"at":[a.x,a.y,a.z],"live":mob_packs.live_count(),"candidates":mob_packs.last_candidate_count})
			if index in [start,start+30,path.size()-2] and DisplayServer.get_name()!="headless":
				caption.text="SHELLSTONE APPROACH · SEED %d · %s · %d LIVE"%[world_seed,"NIGHT PATROLS / DUSK LIGHT" if dark else "DAY",mob_packs.live_count()]
				await _capture("quarry-%s-%d"%["night" if dark else "day",index-start])
		var hostile_packs:=0
		for id: int in seen:
			if not mob_packs.packs[id].grazer: hostile_packs+=1
		report.walks.append({"night":dark,"biome":quarry.biome,"metres":distance,"peak_live":peak,"pack_ids_seen":seen.keys(),"hostile_packs_seen":hostile_packs,"samples":samples})
		check(distance>40,"walk covers the final quarry approach at player height")
		# Visit the actual nearest hostile den/current patrol, through normal
		# activation. This distinguishes a sparse route from a broken spawner.
		_clear_population()
		var target: Dictionary
		var nearest:=INF
		var quarry_at:=terrain.surface_position(quarry.x,quarry.z)
		for p: Dictionary in mob_packs.packs:
			if p.grazer or p.biome=="cave": continue
			var d:=mob_packs.pack_position(p).distance_to(quarry_at)
			if d<nearest:
				nearest=d
				target=p
		var at:=mob_packs.pack_position(target)
		# An 8m observation point on the closest contour exposes ordinary chase
		# without mistaking the accepted vertical reach limit for missing AI.
		var observer:=at+Vector3(0,0,8)
		var least_height_gap:=INF
		for i in 16:
			var candidate:=at+Vector3(cos(TAU*i/16),0,sin(TAU*i/16))*8
			candidate.y=terrain.height_at(floori(candidate.x),floori(candidate.z))
			if absf(candidate.y-at.y)<least_height_gap:
				least_height_gap=absf(candidate.y-at.y)
				observer=candidate
		await _settle(observer,40)
		_pose(observer,at)
		# Capture after the ordinary 0.4s activation tick, before fast enemies
		# reach the stationary observer and fill the entire camera.
		for i in 42: await get_tree().physics_frame
		check(target.spawned and not target.members.is_empty(),"ordinary near-player tick activates the nearest native hostile pack")
		var before: Array=[]
		for enemy: Enemy in target.members: before.append(enemy.position)
		if DisplayServer.get_name()!="headless":
			caption.text="NEAREST NATIVE HOSTILES · %s · %dm FROM QUARRY · %s"%[target.biome,nearest,"NIGHT" if dark else "DAY"]
			await _capture("native-hostiles-"+("night" if dark else "day"))
		for i in 180: await get_tree().physics_frame
		var members: Array=[]
		for i in target.members.size():
			var enemy: Enemy=target.members[i]
			members.append({"id":enemy.enemy_id,"state":enemy.state,"moved_m":enemy.position.distance_to(before[i]),"on_floor":enemy.is_on_floor(),"y":enemy.position.y})
		report.encounters.append({"night":dark,"pack":target.index,"biome":target.biome,"quarry_distance_m":nearest,"observer_height_gap_m":least_height_gap,"members":members})
	# No player attacks, gathering, spending or saving occurred during the walk.
	check(_sim().world_profile()=="frontier_v6","runtime observation preserves native world identity")
	report.checks=checks
	report.failures=failures
	FileAccess.open(output.path_join("manifest.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("POPULATION_WALK %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _clear_population() -> void:
	for node in get_tree().get_nodes_in_group("enemies"): node.free()
	mob_packs.setup(terrain,world_seed)
