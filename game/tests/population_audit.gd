extends Node3D
## Native census and runtime anchor audit; no world/save mutations or spawned mobs.
var terrain: Terrain
var population: MobPacks
var report := {}

func point(v: Vector3) -> Array:
	return [snappedf(v.x,.001),snappedf(v.y,.001),snappedf(v.z,.001)]

func _ready() -> void:
	var seed_value := 1
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--home-seed="): seed_value = int(arg.get_slice("=",1))
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	sim.set_world_profile("frontier_v6")
	terrain = Terrain.new()
	add_child(terrain)
	terrain.set_process(false)
	terrain._world_profile = "frontier_v6"
	terrain.map = sim.world_map(seed_value)
	terrain._blocks = terrain.map.blocks
	population = MobPacks.new()
	add_child(population)
	population.set_physics_process(false)
	population.setup(terrain,seed_value)
	var spawn := terrain.surface_position(terrain.map.spawn_x,terrain.map.spawn_z)
	report = {"seed":seed_value,"profile":"frontier_v6","packs":population.packs.size(),"spawn":point(spawn),"bands":{},"biomes":{},"habitats":[],"regions":[],"states":[],"dens":[],"height_grid":[]}
	# Compact deterministic identity, independent of presentation and runtime poses.
	var identity := HashingContext.new()
	identity.start(HashingContext.HASH_SHA256)
	identity.update(terrain.map.blocks)
	identity.update(var_to_bytes(terrain.map.packs))
	identity.update(var_to_bytes(terrain.map.nodes))
	report.native_sha256 = identity.finish().hex_encode()
	for z in range(0,1024,16):
		for x in range(0,1024,16): report.height_grid.append(terrain.height_at(x,z))
	for pack: Dictionary in population.packs:
		var distance := Vector2(pack.x+.5-spawn.x,pack.z+.5-spawn.z).length()
		var band := "0-150" if distance<150 else ("150-190" if distance<190 else ("190-300" if distance<300 else ("300-500" if distance<500 else "500+")))
		var category := "grazer" if pack.grazer else ("cave" if pack.biome=="cave" else "hostile_surface")
		for group_name in ["bands","biomes"]:
			var group: Dictionary = report[group_name]
			var key: String = band if group_name=="bands" else pack.biome
			if not group.has(key): group[key] = {"hostile_surface":0,"cave":0,"grazer":0,"members":0}
			group[key][category] += 1
			group[key].members += pack.enemies.size()
		report.dens.append([pack.x,pack.y,pack.z,pack.biome,pack.grazer,pack.patrols,pack.enemies.size()])
	for region: Dictionary in terrain.map.regions:
		var entry:= {"id":region.id,"biome":region.biome,"x":region.x,"z":region.z,"radius_m":region.radius_m,"surface_hostile_packs":0,"foreign_biome_dens":0}
		for p: Dictionary in population.packs:
			if p.grazer or p.biome=="cave" or Vector2(p.x-region.x,p.z-region.z).length()>float(region.radius_m): continue
			entry.surface_hostile_packs+=1
			if p.biome!=region.biome: entry.foreign_biome_dens+=1
		report.regions.append(entry)
	for habitat: Dictionary in terrain.map.habitats:
		var route: Array = []
		var route_biomes: Dictionary={}
		for p: Vector3 in habitat.approach:
			route.append(point(p))
			var biome: String=terrain.map.biome_defs[terrain.map.biomes[floori(p.z)*int(terrain.map.width)+floori(p.x)]].id
			route_biomes[biome]=int(route_biomes.get(biome,0))+1
		var containing_regions: Array=[]
		for r: Dictionary in terrain.map.regions:
			if Vector2(habitat.x-r.x,habitat.z-r.z).length()<=float(r.radius_m): containing_regions.append(r.id)
		report.habitats.append({"id":habitat.id,"biome":habitat.biome,"x":habitat.x,"z":habitat.z,"approach":route,"approach_cell_biomes":route_biomes,"containing_regions":containing_regions})
	for foreign in [false,true]:
		population.cross_biomes = foreign
		for progress in [0.0,.17,.5,.82]:
			population.night = progress>0
			population.night_progress = progress
			var state := {"foreign":foreign,"night_progress":progress,"below_surface_2m":0,"above_surface_2m":0,"surface_packs":0,"worst_depth_m":0.0,"worst_pack":-1,"quarries":[],"positions":[]}
			for pack: Dictionary in population.packs:
				var at := population.pack_position(pack)
				state.positions.append(point(at))
				if pack.biome=="cave": continue
				state.surface_packs += 1
				var ground := terrain.height_at(floori(at.x),floori(at.z))
				var depth := ground-at.y
				if depth>2: state.below_surface_2m += 1
				if depth < -2: state.above_surface_2m += 1
				if depth>state.worst_depth_m:
					state.worst_depth_m = depth
					state.worst_pack = pack.index
			for h: Dictionary in terrain.map.habitats:
				if h.id!="quarry_escarpment": continue
				var covered := 0
				var samples := 0
				var nearest := INF
				for i in range(0,h.approach.size(),10):
					var at: Vector3 = h.approach[i]
					var distance := INF
					for p: Dictionary in population.packs:
						if p.grazer or p.biome=="cave": continue
						distance = minf(distance,population.pack_position(p).distance_to(at+Vector3.UP))
					if distance<=MobPacks.ACTIVATION_RANGE_M: covered+=1
					nearest = minf(nearest,distance)
					samples+=1
				state.quarries.append({"id":h.id,"samples":samples,"within_activation":covered,"nearest_m":nearest})
			report.states.append(state)
	var output := ProjectSettings.globalize_path("res://../build/intensives/population-audit-%d.json" % seed_value)
	FileAccess.open(output,FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("POPULATION_AUDIT ",seed_value," packs=",population.packs.size()," output=",output)
	get_tree().quit()
