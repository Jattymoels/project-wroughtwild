extends Node3D
## Real pack activation/noise/sleep over a synthetic 1 km layout, plus native
## V6 pacing metadata. Flat support isolates route-index coverage from mesh work.
var checks := 0
var failures := 0
var packs: MobPacks
var terrain: FlatTerrain
var player: WroughtwildPlayer

class FlatTerrain extends Terrain:
	func surface_position(x: int, z: int) -> Vector3:
		return Vector3(x+.5,12,z+.5)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func candidates(at: Vector3, radius: float, indexed: bool) -> Array:
	var result: Array = []
	var source: Array = packs.nearby_dormant_packs(at,radius) if indexed else packs.packs
	for p in source:
		if not p.spawned and packs.pack_position(p).distance_to(at)<=radius: result.append(p.index)
	return result

func clear_members() -> void:
	for node in get_tree().get_nodes_in_group("enemies"): node.free()
	packs._active_pack_ids.clear()
	for p in packs.packs:
		p.members = []
		p.spawned = false

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.global_position = Vector3(0,12,0)
	var sim: WroughtwildSim = player.combat.sim
	check(sim.set_world_profile("frontier_v6"),"native accepts the V6 identity")
	var native_map: Dictionary = sim.world_map(1)
	check(native_map.get("starter_first_siege_night")==3 and native_map.get("starter_quiet_radius_m")==150 and native_map.get("hostile_boundary_m")==190,"native exports V6's accepted quiet-heartland and siege metadata")
	terrain = FlatTerrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.set_process(false)
	terrain._world_profile = "frontier_v6"
	var definitions: Array = []
	for z in range(16,1024,32):
		for x in range(16,1024,32):
			definitions.append({"enemies":PackedStringArray(["ember_whelp"]),"x":x,"y":12,"z":z,
				"patrols":true,"route_x":mini(1023,x+95),"route_z":maxi(0,z-39),
				"has_foreign":true,"foreign_x":maxi(0,x-111),"foreign_z":mini(1023,z+79),"biome":"wastes","foreign_biome":"forest"})
	terrain.map = {"width":1024,"height":1024,"cell_size":1,"packs":definitions,"starter_first_siege_night":native_map.starter_first_siege_night}
	packs = MobPacks.new()
	add_child(packs)
	packs.set_physics_process(false)
	packs.setup(terrain,1)
	check(packs._indexed and packs._first_siege_night==3,"V6 setup selects indexed dormant search and night three")
	var largest_candidates := 0
	for foreign in [false,true]:
		packs.cross_biomes = foreign
		for progress in [0.0,.17,.5,.82,1.0]:
			packs.night = progress>0
			packs.night_progress = progress
			for index in [0,33,297,528,1023]:
				var at := packs.pack_position(packs.packs[index])
				for offset in [Vector3.ZERO,Vector3(27,0,0),Vector3(0,80,0)]:
					for radius in [28.0,45.0]:
						check(candidates(at+offset,radius,true)==candidates(at+offset,radius,false),"index matches exhaustive 3D selection/order (foreign %s, night %.2f, pack %d)" % [foreign,progress,index])
						largest_candidates = maxi(largest_candidates,packs.last_candidate_count)
	check(largest_candidates<definitions.size()/4,"local search remains bounded on 1 km routes (%d/%d packs)" % [largest_candidates,definitions.size()])
	# A current foreign patrol can wake away from BOTH its den and ordinary end.
	packs.night = true
	packs.night_progress = .5
	packs.cross_biomes = true
	var target: Dictionary = packs.packs[528]
	var at := packs.pack_position(target)
	player.global_position = at
	packs.max_live_mobs = 1
	var eligible := candidates(at,28,true)
	packs._check_timer = 0
	packs._physics_process(.4)
	var chosen: Dictionary = packs.packs[int(eligible[0])]
	check(chosen.spawned and packs._active_pack_ids.size()==1,"real activation uses generated order at the live population cap")
	var enemy := chosen.members[0] as Enemy
	enemy.set_physics_process(false)
	packs.night_progress = .7
	packs._check_timer = 0
	packs._physics_process(.4)
	check(enemy.roaming() and enemy.roam_target==packs.pack_position(chosen),"indexed active pack follows its actual moving route")
	enemy.state = "idle"
	enemy.since_hurt = 100
	check(packs.sleep_far_packs(Vector3(-500,12,-500))==1 and not chosen.spawned and packs._active_pack_ids.is_empty(),"far calm indexed survivor sleeps and leaves active update list")
	await get_tree().process_frame
	check(packs.nearby_dormant_packs(packs.pack_position(chosen),1).has(chosen),"sleeping survivor remains findable along its current route")
	packs._spawn_pack(chosen,packs.pack_position(chosen))
	enemy = chosen.members[0]
	enemy.set_physics_process(false)
	enemy.life = 0 # Spent-pack lifecycle only; no synthetic kill/reward claim.
	packs.sleep_far_packs(Vector3(-500,12,-500))
	check(chosen.spawned and packs._active_pack_ids.is_empty() and not packs.nearby_dormant_packs(packs.pack_position(chosen),1).has(chosen),"fully spent pack never re-enters dormant search")
	clear_members()
	packs.night = false
	packs.cross_biomes = false
	packs.max_live_mobs = 60
	# Real noise distances, including muffle and a vertically remote cave den.
	var near: Dictionary = packs.packs[0]
	var high: Dictionary = packs.packs[1]
	high.y = 100
	var sound_at := packs.pack_position(near)+Vector3(20,0,0)
	check(packs.noise_at(sound_at,"tree_fall",true)==0,"muffled tree fall cannot wake out-of-radius indexed dens")
	check(packs.noise_at(sound_at,"tree_fall",false)>0 and near.spawned and not high.spawned,"ordinary noise wakes the nearby den but preserves actual vertical-distance rejection")
	clear_members()
	# The profile threshold changes eligibility, not later chance or arrival rules.
	var seed2 := -1
	var seed3 := -1
	for seed_value in 100:
		if sim.siege_tonight(seed_value,2): seed2 = seed_value
		if sim.siege_tonight(seed_value,3): seed3 = seed_value
	check(seed2>=0 and seed3>=0,"native deterministic siege rolls supply eligible nights for the fixture")
	packs.tick_siege({"index":2,"night":true},null,seed2)
	check(not packs.siege_tonight and packs.spawn_siege(Vector3.ZERO,2)==0,"V6 forbids both rolled and direct home siege before night three")
	packs.tick_siege({"index":3,"night":true},null,seed3)
	check(packs.siege_tonight,"V6 keeps an ordinarily successful roll eligible from night three")
	player.combat.has_home = true
	player.combat.home_position = Vector3(500,12,500)
	player.global_position = player.combat.home_position
	packs.set_hour({"night":true,"seconds_to_dawn":10.0,"index":3},sim.day_rules())
	packs.tick_siege({"index":3,"night":true},player,seed3)
	check(not packs.siege_members().is_empty(),"first eligible siege still arrives through normal home and elapsed-night checks")
	var size := packs.siege_members().size()
	packs.tick_siege({"index":3,"night":true},player,seed3)
	check(packs.siege_members().size()==size,"eligible night cannot spawn its siege twice")
	packs.tick_siege({"index":4,"night":false},player,seed3)
	check(packs.siege_members().is_empty(),"dawn still dismisses the home siege")
	await get_tree().process_frame
	terrain._world_profile = "frontier_v5"
	packs.setup(terrain,1)
	packs.tick_siege({"index":2,"night":true},null,seed2)
	check(not packs._indexed and packs._first_siege_night==0 and packs.siege_tonight,"V5 ignores V6 map thresholds and preserves native night-two eligibility")
	check(packs.nearby_dormant_packs(Vector3.ZERO,1).size()==definitions.size(),"legacy profile retains original full-list search semantics")
	print("WIDE_FRONTIER_PACING: %d checks, %d failures; largest local candidate group %d/%d" % [checks,failures,largest_candidates,definitions.size()])
	get_tree().quit(1 if failures else 0)
