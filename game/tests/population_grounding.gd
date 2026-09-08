extends Node3D
## Generated hills and real character/terrain collision. Common baseline fixture.
var checks := 0
var failures := 0
var terrain: Terrain
var population: MobPacks
var report := {"members":[],"day_offsets":[]}

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL POPULATION: ",label)

func _ready() -> void:
	var seed_value := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--home-seed="): seed_value = int(arg.get_slice("=",1))
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	sim.set_world_profile("frontier_v6")
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.set_process(false)
	terrain._world_profile = "frontier_v6"
	terrain.map = sim.world_map(seed_value)
	terrain._blocks = terrain.map.blocks
	terrain._sim = sim
	terrain._seed = seed_value
	terrain.faceted_surface = true
	terrain.nodes_root = Node3D.new()
	terrain.add_child(terrain.nodes_root)
	population = MobPacks.new()
	add_child(population)
	population.set_physics_process(false)
	population.setup(terrain,seed_value)
	_native_routes()
	# Select the same generated hill independently of the production correction.
	var worst := -INF
	var target: Dictionary
	for pack: Dictionary in population.packs:
		if not pack.patrols or pack.biome=="cave": continue
		var den := Vector3(pack.x+.5,pack.y,pack.z+.5)
		var old_at := den.lerp(terrain.surface_position(pack.route.x,pack.route.y),sin(.17*PI))
		var depth := terrain.height_at(floori(old_at.x),floori(old_at.z))-old_at.y
		if depth>worst:
			worst=depth
			target=pack
	check(worst>2,"generated seed contains an actual hill crossing")
	population.night=true
	population.night_progress=.17
	var at := population.pack_position(target)
	_build_near(at)
	await get_tree().physics_frame
	var ground := terrain.height_at(floori(at.x),floori(at.z))
	check(absf(at.y-ground)<=.8,"night anchor follows the hill surface, not the endpoint chord")
	population._spawn_pack(target,at)
	var start_y: Array = []
	for enemy: Enemy in target.members:
		start_y.append(enemy.position.y)
		check(_body_clear(enemy),"night member starts outside solid terrain")
	for i in 90: await get_tree().physics_frame
	for i in target.members.size():
		var enemy: Enemy = target.members[i]
		check(enemy.is_on_floor(),"night member settles on real collision")
		check(_above_collision_floor(enemy),"night member remains above its actual faceted supporting floor")
		report.members.append({"id":enemy.enemy_id,"start_y":start_y[i],"end_y":enemy.position.y,"on_floor":enemy.is_on_floor()})
		enemy.free()
	target.members=[]
	# Daytime spread across steep cells is a separate failure from patrol height.
	population.night=false
	var tested := 0
	for pack: Dictionary in population.packs:
		if pack.biome=="cave": continue
		var den := population.pack_position(pack)
		var steep := false
		for i in pack.enemies.size():
			var offset := Vector3(cos(TAU*i/pack.enemies.size()),.5,sin(TAU*i/pack.enemies.size()))*1.6
			var p := den+offset
			if terrain.height_at(floori(p.x),floori(p.z))>p.y+1: steep=true
		if not steep: continue
		population._spawn_pack(pack,den)
		for enemy: Enemy in pack.members:
			check(_body_clear(enemy),"day member spread does not embed in a neighbouring hill cell")
			report.day_offsets.append({"pack":pack.index,"position":[enemy.position.x,enemy.position.y,enemy.position.z],"clear":_body_clear(enemy)})
			enemy.free()
		pack.members=[]
		tested+=1
		if tested==12: break
	check(tested>0,"generated daytime slope cases were exercised")
	# A generated underground pack keeps its floor and vertical activation.
	for pack: Dictionary in population.packs:
		if pack.biome!="cave": continue
		population._spawn_pack(pack,population.pack_position(pack))
		for enemy: Enemy in pack.members:
			check(is_equal_approx(enemy.position.y,float(pack.y)+.8),"cave member retains the native interior floor")
			enemy.free()
		pack.members=[]
		break
	_excavated_support()
	report.seed=seed_value
	report.pack=target.index
	report.baseline_chord_depth_m=worst
	report.checks=checks
	report.failures=failures
	FileAccess.open("res://../build/intensives/population-grounding-%d.json"%seed_value,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("POPULATION_GROUNDING %d checks, %d failures"%[checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _native_routes() -> void:
	var spawn := Vector2(terrain.map.spawn_x+.5,terrain.map.spawn_z+.5)
	for foreign in [false,true]:
		population.cross_biomes=foreign
		for progress in [0.0,.17,.5,.82,1.0]:
			population.night=progress>0
			population.night_progress=progress
			var surface_ok:=true
			var horizontal_ok:=true
			var quiet_ok:=true
			var caves_ok:=true
			for pack: Dictionary in population.packs:
				var at:=population.pack_position(pack)
				if pack.biome=="cave": caves_ok=caves_ok and is_equal_approx(at.y,float(pack.y))
				if not pack.grazer: quiet_ok=quiet_ok and Vector2(at.x,at.z).distance_to(spawn)>=189.99
				if not pack.patrols: continue
				var route: Vector2i=pack.foreign if foreign and pack.has_foreign else pack.route
				var den:=Vector3(pack.x+.5,pack.y,pack.z+.5)
				var chord:=den.lerp(terrain.surface_position(route.x,route.y),sin(progress*PI))
				horizontal_ok=horizontal_ok and Vector2(at.x-chord.x,at.z-chord.z).length()<.001
				surface_ok=surface_ok and absf(at.y-terrain.height_at(floori(at.x),floori(at.z)))<.001
			check(surface_ok,"all native patrol anchors follow terrain (foreign %s, phase %.2f)"%[foreign,progress])
			check(horizontal_ok and quiet_ok and caves_ok,"horizontal routes, quiet boundary and cave heights preserved")
			for habitat: Dictionary in terrain.map.habitats:
				if habitat.id!="quarry_escarpment": continue
				for i in range(0,habitat.approach.size(),10):
					var at: Vector3=habitat.approach[i]+Vector3.UP
					var expected: Array=[]
					var indexed: Array=[]
					for p: Dictionary in population.packs:
						if population.pack_position(p).distance_to(at)<=28: expected.append(p.index)
					for p: Dictionary in population.nearby_dormant_packs(at,28):
						if population.pack_position(p).distance_to(at)<=28: indexed.append(p.index)
					check(indexed==expected,"generated quarry candidate order matches exhaustive 3D activation")
	population.cross_biomes=false
	population.night=false

func _excavated_support() -> void:
	# Separate mutable voxel fixture: no edits to the generated map above.
	var dug := Terrain.new()
	var heights:=PackedInt32Array()
	heights.resize(64)
	heights.fill(8)
	dug.map={"width":8,"height":8,"depth":16,"cell_size":1,"heights":heights}
	dug._blocks.resize(8*8*16)
	for z in 8:
		for x in 8:
			for y in 8: dug._blocks[(z*8+x)*16+y]=3
	for z in range(1,7):
		for x in range(1,7):
			for y in range(5,8): dug._blocks[(z*8+x)*16+y]=0
	var before:=dug._blocks.duplicate()
	population.terrain=dug
	var pack: Dictionary=population.packs[0].duplicate(true)
	pack.enemies=PackedStringArray(["ember_whelp"])
	pack.biome="meadow"
	pack.members=[]
	pack.grazer=false
	pack.elite_member=-1
	population._spawn_pack(pack,Vector3(4,8,4))
	var enemy: Enemy=pack.members[0]
	check(is_equal_approx(enemy.position.y,5.8),"surface member uses excavated support rather than the pristine height map")
	check(dug._blocks==before,"grounding never writes terrain or finite resource records")
	enemy.free()
	population.terrain=terrain
	dug.free()

func _body_clear(enemy: Enemy) -> bool:
	# Voxel occupancy detects actors wholly inside the one-sided surface volume,
	# which a triangle intersection alone cannot detect. Include the body footprint.
	for offset in [Vector3.ZERO,Vector3(.34,0,0),Vector3(-.34,0,0),Vector3(0,0,.34),Vector3(0,0,-.34)]:
		for y in [.1,.65,1.2]:
			var p: Vector3 = enemy.position+offset+Vector3.UP*y
			if terrain.block_at(floori(p.x),floori(p.y),floori(p.z))!=0: return false
	return true

func _above_collision_floor(enemy: Enemy) -> bool:
	# Once gravity settles the capsule, a rounded face can legitimately lie
	# inside its source voxel. Assert against the real walking triangles.
	var ray := PhysicsRayQueryParameters3D.create(enemy.position+Vector3.UP,enemy.position-Vector3.UP)
	var excluded: Array[RID]=[]
	for member: Enemy in get_tree().get_nodes_in_group("enemies"): excluded.append(member.get_rid())
	ray.exclude=excluded
	var hit := get_world_3d().direct_space_state.intersect_ray(ray)
	return not hit.is_empty() and terrain.is_terrain_body(hit.collider) and enemy.position.y>=float(hit.position.y)-.01

func _build_near(at: Vector3) -> void:
	var cx := floori(at.x/16)*16
	var cz := floori(at.z/16)*16
	for z in range(cz-16,cz+17,16):
		for x in range(cx-16,cx+17,16):
			var data := terrain._sim.world_mesh_chunk(terrain._seed,16,x,z,terrain.broken_packed(),true,{})
			terrain._build_chunk(data,1.0)
