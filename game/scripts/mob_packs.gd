class_name MobPacks
extends Node
## Roaming mob packs of the sandpit. Each pack from the sim's world map is a
## dormant spawn point; when the player first comes near, its enemies appear
## and hold their ground (aggro is the enemies' own behaviour). Density is
## the biome's (Wave 7 slice 1): the deep biomes' packs walk their routes
## toward the heartland at night and are home by dawn, and noise - a press,
## a felled tree, a fight - wakes every idle mob and dormant pack in its
## radius. The sim says the radii; walls keep most of it in. Kills roll
## the sim's loot tables and scatter physical pickups where the mob fell -
## fighting always pays into the survival economy, and walking through
## your battlefield hoovers up the reward.

## How close the player must come before a pack takes shape. Far enough to
## feel discovered, near enough that distant packs cost nothing.
const ACTIVATION_RANGE_M := 28.0
const CHECK_SECONDS := 0.4
## V6 dormant-search cell width: nearby queries visit a small group of dens
## and route corridors. This changes search cost, never activation distance.
@export var dormant_cell_width_m := 64.0

var terrain: Terrain
var packs: Array = []          # {enemies, x, z, spawned, members}
var world_seed := 0
var _kill_counter := 0
var _check_timer := 0.0
## Population rules (combat_realtime.json horde): how many mobs may be
## alive at once, and when a calm far-off pack goes back to sleep.
var max_live_mobs := 60
var sleep_range_m := 60.0
var sleep_after_seconds := 6.0
## The night (Wave 6 slice 5): packs wake from further and stay awake
## further - the dark is theirs.
var night := false
var _night_aggro := 1.0
var _night_sleep := 1.0
## How far through the night (0 at dusk's end, 1 at dawn): patrols walk
## out over the first half and home over the second.
var night_progress := 0.0
## The mingling (Wave 8 slice 3): once the era's patrols cross biomes a
## patrol walks to the nearest den of another biome instead of toward the
## spawn; and a spawning pack may take a foreign family (the sim's pick).
var cross_biomes := false
## Test surface: foreign members mingled into packs since setup.
var mingled := 0
## Noise rules (combat_realtime.json noise): radius per source kind, and
## the fraction a closed room lets out.
var _noise: Dictionary = {}
var _heard_at := -100000
## Test surface: packs woken by noise since setup.
var woken_by_noise := 0
## The siege (Wave 7 slice 3): some nights, from the second, the hounds
## come to the lamp - rolled per night from the seed, spawned at the edge
## of the dark around home once the night is old enough, hunting from the
## start, gone with the dawn.
var siege_tonight := false
var _siege_rolled_day := -1
var _siege_spawned_day := -1
var _siege_members: Array = []
var _siege: Dictionary = {}
var _night_length := 1.0
var _first_siege_night := 0
var _indexed := false
var _pack_bins: Dictionary = {}
var _active_pack_ids: Dictionary = {}
## Diagnostic: candidate packs examined by the last local dormant query.
var last_candidate_count := 0


func _ready() -> void:
	add_to_group("mob_packs")


func setup(from_terrain: Terrain, seed_value: int) -> void:
	terrain = from_terrain
	world_seed = seed_value
	_kill_counter = 0
	packs = []
	for pack in terrain.map.get("packs", []):
		packs.append({
			"enemies": pack["enemies"],
			"frontier_host_id": pack.get("frontier_host_id", ""),
			"x": pack["x"],
			"y": pack.get("y", 0),
			"z": pack["z"],
			"elite_member": pack.get("elite_member", -1),
			"elite_modifier": pack.get("elite_modifier", ""),
			"grazer": pack.get("grazer", false),
			"biome": String(pack.get("biome", "")),
			"patrols": bool(pack.get("patrols", false)),
			"route": Vector2i(int(pack.get("route_x", 0)), int(pack.get("route_z", 0))),
			"foreign": Vector2i(int(pack.get("foreign_x", 0)), int(pack.get("foreign_z", 0))),
			"foreign_biome": String(pack.get("foreign_biome", "")),
			"has_foreign": bool(pack.get("has_foreign", false)),
			"spawned": false,
			"members": [],
		})
	load_rules()
	_indexed = terrain.world_profile() in ["frontier_v6","living_frontier_wave1","living_frontier_wave3"]
	_first_siege_night = int(terrain.map.get("starter_first_siege_night",0)) if _indexed else 0
	_siege_rolled_day = -1
	siege_tonight = false
	_active_pack_ids.clear()
	_build_pack_index()

func _build_pack_index() -> void:
	_pack_bins.clear()
	if not _indexed: return
	var cell := float(terrain.map.get("cell_size",1))
	for index in packs.size():
		var pack: Dictionary = packs[index]
		pack["index"] = index
		var den := Vector2((float(pack.x)+.5)*cell,(float(pack.z)+.5)*cell)
		var ends: Array[Vector2] = [den]
		if bool(pack.patrols):
			ends.append((Vector2(pack.route)+Vector2.ONE*.5)*cell)
			if bool(pack.has_foreign): ends.append((Vector2(pack.foreign)+Vector2.ONE*.5)*cell)
		var visited: Dictionary = {}
		for end in ends:
			# Conservative bins cover the WHOLE den-to-destination segment,
			# including the later-era foreign route. Final checks use the actual
			# interpolated 3D point, so a corridor bin never invents a nearby pack.
			var low := _pack_bin(Vector2(minf(den.x,end.x),minf(den.y,end.y)))
			var high := _pack_bin(Vector2(maxf(den.x,end.x),maxf(den.y,end.y)))
			for z in range(low.y,high.y+1):
				for x in range(low.x,high.x+1):
					var key := Vector2i(x,z)
					if visited.has(key): continue
					visited[key] = true
					if not _pack_bins.has(key): _pack_bins[key] = []
					_pack_bins[key].append(index)

func _pack_bin(at: Vector2) -> Vector2i:
	return Vector2i(floori(at.x/maxf(dormant_cell_width_m,1)),floori(at.y/maxf(dormant_cell_width_m,1)))

func nearby_dormant_packs(at: Vector3, radius: float) -> Array:
	if not _indexed:
		last_candidate_count = packs.size()
		return packs
	var low := _pack_bin(Vector2(at.x-radius,at.z-radius))
	var high := _pack_bin(Vector2(at.x+radius,at.z+radius))
	var found: Dictionary = {}
	for z in range(low.y,high.y+1):
		for x in range(low.x,high.x+1):
			for index in _pack_bins.get(Vector2i(x,z),[]): found[int(index)] = true
	var indices: Array = found.keys()
	indices.sort() # Preserve generated order when the population cap chooses.
	var result: Array = []
	for index in indices:
		if not bool(packs[index].spawned): result.append(packs[index])
	last_candidate_count = result.size()
	return result

func _active_packs() -> Array:
	if not _indexed: return packs
	var result: Array = []
	for index in _active_pack_ids: result.append(packs[int(index)])
	return result

func _move_patrol(pack: Dictionary) -> void:
	if not bool(pack.patrols): return
	var there := pack_position(pack)
	for member in pack.members:
		if is_instance_valid(member) and (member as Enemy).life > 0: (member as Enemy).roam_to(there)


## The population and noise rules from the sim (setup calls this; tests
## on a bare pack system call it alone).
func load_rules() -> void:
	var horde: Dictionary = load("res://scripts/sim.gd").shared().realtime().get("horde", {})
	max_live_mobs = int(horde.get("max_live_mobs", 60))
	sleep_range_m = float(horde.get("sleep_range_m", 60.0))
	sleep_after_seconds = float(horde.get("sleep_after_seconds", 6.0))
	_noise = load("res://scripts/sim.gd").shared().noise_rules()


func _physics_process(delta: float) -> void:
	_check_timer -= delta
	if _check_timer > 0.0:
		return
	_check_timer = CHECK_SECONDS
	var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player == null or terrain == null:
		return
	# A trial is a closed fight: the packs of the wastes around the arena
	# do not wake while the player is inside one.
	if player.trial != null and player.trial.active():
		return
	sleep_far_packs(player.global_position)
	var live := live_count()
	if _indexed:
		for pack in _active_packs(): _move_patrol(pack)
	for pack in nearby_dormant_packs(player.global_position,ACTIVATION_RANGE_M):
		if pack["spawned"]:
			# A patrol on its feet keeps walking its route: every calm
			# member roams toward where the pack should be by this hour.
			_move_patrol(pack)
			continue
		# The cap: a crowd is a crowd, however many packs the walk crossed.
		if live >= max_live_mobs:
			break
		# Packs stand at their generated level: the surface, or a cave floor
		# (cave packs activate when the player is near in 3D - above ground
		# counts, so descending into a lit-up cave meets its residents). A
		# patrolling pack stands wherever the night has walked it.
		var at := pack_position(pack)
		if at.distance_to(player.global_position) <= ACTIVATION_RANGE_M:
			_spawn_pack(pack, at)
			live += (pack["members"] as Array).size()


## Where a pack is right now: its den by day; at night a patrol is out along
## its route, furthest at the dead of night and home again by dawn.
func pack_position(pack: Dictionary) -> Vector3:
	var cell: float = terrain.map["cell_size"] if terrain != null and not terrain.map.is_empty() else 1.0
	var den := Vector3((pack["x"] + 0.5) * cell, float(pack["y"]), (pack["z"] + 0.5) * cell)
	if not night or not bool(pack.get("patrols", false)):
		return den
	var route: Vector2i = pack["foreign"] if cross_biomes and bool(pack.get("has_foreign", false)) else pack["route"]
	var out: Vector3
	if terrain != null and not terrain.map.is_empty():
		out = terrain.surface_position(route.x, route.y)
	else:
		out = Vector3((route.x + 0.5) * cell, float(pack["y"]), (route.y + 0.5) * cell)
	var at := den.lerp(out, sin(clampf(night_progress, 0.0, 1.0) * PI))
	if terrain != null and not terrain.map.is_empty():
		# Routes describe horizontal travel. Interpolating endpoint heights cuts
		# through hills (or hangs over valleys), corrupting activation and spawns.
		at.y = terrain.surface_position(floori(at.x/cell),floori(at.z/cell)).y
	return at


## Surface members share a den, not a floor height: their spread can cross a
## steep cell boundary. Use the scene's actual body footprint and the mutable
## terrain support, so excavation stays real. Cave members retain their native
## interior floor; they must never be projected onto the roof above them.
func _surface_member_position(at: Vector3, radius: float, settling_height: float) -> Vector3:
	var cell := float(terrain.map.cell_size)
	var highest := -INF
	for z in range(floori((at.z-radius)/cell),floori((at.z+radius)/cell)+1):
		for x in range(floori((at.x-radius)/cell),floori((at.x+radius)/cell)+1):
			var support := terrain.surface_position(x,z).y
			if not terrain._blocks.is_empty():
				var y := floori(support/cell)-1
				while y>=0 and terrain.block_at(x,y,z)==0: y-=1
				support = (y+1)*cell
			var px := clampf(at.x,x*cell,(x+1)*cell)
			var pz := clampf(at.z,z*cell,(z+1)*cell)
			var rendered := terrain.rendered_height(px,pz,support,cell)
			if is_finite(rendered): support = maxf(support,rendered)
			highest = maxf(highest,support)
	# Keep the existing settling allowance from the spawn ring's Y offset.
	at.y = highest + settling_height
	return at


## The era from the sandpit: whether its patrols cross biomes.
func set_era(era: Dictionary) -> void:
	cross_biomes = bool(era.get("patrols_cross_biomes", false))


## The hour from the sandpit: night or not, and how far through it.
func set_hour(day: Dictionary, rules: Dictionary) -> void:
	var length := float(rules.get("length_seconds", 720.0))
	var night_length := maxf((1.0 - float(rules.get("dusk_end", 0.66))) * length, 1.0)
	_night_length = night_length
	night_progress = clampf(1.0 - float(day.get("seconds_to_dawn", 0.0)) / night_length, 0.0, 1.0)
	set_night(bool(day.get("night", false)), rules)


## Noise at a point (Wave 7 slice 1): every idle mob within the kind's
## radius wakes, every dormant pack within it takes shape and comes. A
## muffled source (inside a closed room) carries the muffle fraction of
## its radius. Returns how many mobs and packs it woke.
func noise_at(position: Vector3, kind: String, muffled: bool = false) -> int:
	var radii: Dictionary = _noise.get("radius_m", {})
	var radius := float(radii.get(kind, 0.0))
	if muffled:
		radius *= float(_noise.get("muffle", 1.0))
	if radius <= 0.0:
		return 0
	var woken := 0
	if get_tree() == null:
		return 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if not (node is Enemy) or not is_instance_valid(node):
			continue
		var enemy := node as Enemy
		if enemy.life <= 0.0 or enemy.state != "idle" or enemy.trial_bound:
			continue
		if enemy.global_position.distance_to(position) > radius:
			continue
		enemy.state = "flee" if enemy.flees else "chase"
		woken += 1
	var packs_woken := 0
	var live := live_count()
	for pack in nearby_dormant_packs(position,radius):
		if pack["spawned"] or pack["grazer"] or live >= max_live_mobs:
			continue
		if pack_position(pack).distance_to(position) > radius:
			continue
		_spawn_pack(pack, pack_position(pack))
		for m in pack["members"]:
			if is_instance_valid(m):
				(m as Enemy).state = "chase"
		live += (pack["members"] as Array).size()
		packs_woken += 1
		woken += 1
	woken_by_noise += packs_woken
	if packs_woken > 0:
		var now := Time.get_ticks_msec()
		if now - _heard_at > 12000:
			_heard_at = now
			var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
			if player != null and player.hud != null:
				player.hud.notify("Something heard that.")
	return woken


## The siege, ticked with the hour: rolls the night once per day, spawns
## the era's pack around home once the night is old enough and the player
## is home, and dismisses what is left at dawn.
func tick_siege(day: Dictionary, player: WroughtwildPlayer, seed_value: int) -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	if _siege.is_empty():
		_siege = sim.siege_rules()
	var index := int(day.get("index", 1))
	if index != _siege_rolled_day:
		_siege_rolled_day = index
		siege_tonight = index >= _first_siege_night and sim.siege_tonight(seed_value, index)
	if not bool(day.get("night", false)):
		if not _siege_members.is_empty():
			dismiss_siege()
		return
	if not siege_tonight or _siege_spawned_day == index or player == null:
		return
	if night_progress * _night_length < float(_siege.get("arrive_seconds_into_night", 0.0)):
		return
	if not player.combat.has_home or player.global_position.distance_to(player.combat.home_position) > float(_siege.get("home_radius_m", 0.0)):
		return
	spawn_siege(player.combat.home_position, index)


## The era's pack takes shape around home, hunting from the start.
func spawn_siege(home: Vector3, index: int) -> int:
	if index < _first_siege_night: return 0
	_siege_spawned_day = index
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	if _siege.is_empty():
		_siege = sim.siege_rules()
	var ids: PackedStringArray = sim.siege_pack()
	var radius := float(_siege.get("spawn_radius_m", 20.0))
	var rng := RandomNumberGenerator.new()
	rng.seed = world_seed ^ (index * 7919)
	var first := rng.randf() * TAU
	for i in ids.size():
		var angle := first + TAU * float(i) / float(maxi(ids.size(), 1))
		var at := home + Vector3(cos(angle), 0.0, sin(angle)) * radius
		if terrain != null and not terrain.map.is_empty():
			var w := int(terrain.map["width"])
			var h := int(terrain.map["height"])
			at = terrain.surface_position(clampi(int(at.x), 1, w - 2), clampi(int(at.z), 1, h - 2)) + Vector3(0, 0.5, 0)
		var enemy := Enemy.spawn(get_parent(), StringName(ids[i]), at)
		enemy.siege = true
		enemy.state = "chase"
		enemy.set_aggro_multiplier(aggro_multiplier())
		enemy.died.connect(_on_enemy_died)
		_siege_members.append(enemy)
	var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player != null and player.hud != null and not ids.is_empty():
		player.hud.notify("They have come to the lamp.")
	return ids.size()


## Dawn: what is left of the siege slinks off.
func dismiss_siege() -> int:
	var gone := 0
	for m in _siege_members:
		if is_instance_valid(m) and (m as Enemy).life > 0.0:
			(m as Enemy).queue_free()
			gone += 1
	_siege_members.clear()
	if gone > 0:
		var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
		if player != null and player.hud != null:
			player.hud.notify("The hounds slink off with the light.")
	return gone


func siege_members() -> Array:
	return _siege_members


## Noise from anywhere in the world: finds the sandpit's pack system.
static func noise(tree: SceneTree, position: Vector3, kind: String, muffled: bool = false) -> int:
	if tree == null:
		return 0
	var system := tree.get_first_node_in_group("mob_packs") as MobPacks
	return system.noise_at(position, kind, muffled) if system != null else 0


## The hour from the sandpit: at night every live mob wakes from further.
func set_night(value: bool, rules: Dictionary) -> void:
	_night_aggro = float(rules.get("night_aggro_multiplier", 1.0))
	_night_sleep = float(rules.get("night_sleep_range_multiplier", 1.0))
	if value == night:
		return
	night = value
	# A bare pack system (tests) has no tree and no mobs to tell.
	if not is_inside_tree():
		return
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Enemy and is_instance_valid(node):
			(node as Enemy).set_aggro_multiplier(aggro_multiplier())


func aggro_multiplier() -> float:
	return _night_aggro if night else 1.0


## How far a calm pack must be from the player to sleep: further at night.
func sleep_range() -> float:
	return sleep_range_m * (_night_sleep if night else 1.0)


## Mobs alive in the world right now.
func live_count() -> int:
	var count := 0
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Enemy and is_instance_valid(node) and (node as Enemy).life > 0.0:
			count += 1
	return count


## A woken pack whose members are all calm, unhurt for a while and far
## from the player goes back to sleep: its survivors are freed and return
## (at full life, as they were) when the player comes back. Returns how
## many packs slept.
func sleep_far_packs(player_position: Vector3) -> int:
	var slept := 0
	var cell: float = terrain.map["cell_size"] if terrain != null and not terrain.map.is_empty() else 1.0
	for pack in _active_packs():
		if not pack["spawned"]:
			continue
		var members: Array = pack["members"]
		var survivors := PackedStringArray()
		var survivor_ids: Array = []
		var elite_index := -1
		var all_calm := true
		var any_alive := false
		for i in members.size():
			var m = members[i]
			if not is_instance_valid(m) or (m as Enemy).life <= 0.0:
				continue
			any_alive = true
			var enemy := m as Enemy
			if not enemy.calm() or enemy.since_hurt < sleep_after_seconds:
				all_calm = false
				break
			if enemy.global_position.distance_to(player_position) < sleep_range():
				all_calm = false
				break
			if enemy.elite_id != "":
				elite_index = survivors.size()
			survivors.append(String(enemy.enemy_id))
			survivor_ids.append(enemy)
		if not any_alive:
			# Everyone died: the pack is spent and will not return.
			pack["members"] = []
			if _indexed: _active_pack_ids.erase(int(pack.index))
			continue
		if not all_calm:
			continue
		var anchor := pack_position(pack)
		if anchor.distance_to(player_position) < sleep_range():
			continue
		for enemy in survivor_ids:
			(enemy as Enemy).queue_free()
		pack["enemies"] = survivors
		pack["elite_member"] = elite_index
		pack["elite_modifier"] = pack["elite_modifier"] if elite_index >= 0 else ""
		pack["members"] = []
		pack["spawned"] = false
		pack["resting"] = true  # spawns as plain members again: bonuses already applied once
		if _indexed: _active_pack_ids.erase(int(pack.index))
		slept += 1
	return slept


func _spawn_pack(pack: Dictionary, at: Vector3) -> void:
	pack["spawned"] = true
	if _indexed: _active_pack_ids[int(pack.index)] = true
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var frontier_id := String(pack.get("frontier_host_id", ""))
	if not frontier_id.is_empty() and sim.world_effect_active("host_defeated:" + frontier_id):
		pack["members"] = []
		return
	var ids: PackedStringArray = (pack["enemies"] as PackedStringArray).duplicate()
	# Herds (D-020 the quiet heartland) are life, not threat: no escorts,
	# never crowned.
	var grazer: bool = pack.get("grazer", false)
	var bounded := not frontier_id.is_empty()
	# A pack returning from sleep is exactly its survivors: era bonuses and
	# escorts were added the first time and are in the list already.
	var resting: bool = pack.get("resting", false)
	# Era mechanics (eras.json): some families run in bigger packs now, some
	# bring escorts, and later eras crown elites more often.
	var era: Dictionary = sim.era()
	var bonus_seen := {}
	var escorts: Dictionary = era.get("pack_escorts", {})
	for id in (PackedStringArray() if resting or bounded else pack["enemies"]):
		if bonus_seen.has(id):
			continue
		bonus_seen[id] = true
		var bonus: Dictionary = sim.era_mechanic(id, "pack_size_bonus")
		for k in int(bonus.get("value", 0)):
			ids.append(id)
		for escort in (PackedStringArray() if grazer else escorts.get(id, PackedStringArray())):
			ids.append(escort)
	# The mingling (Wave 8 slice 3): from the deep on, a foreign family may
	# join a pack in this biome - the sim's pick, deterministic per den.
	if not resting and not grazer and not bounded:
		var foreign: String = sim.mingle_pick(String(pack.get("biome", "")), hash(Vector3i(int(pack["x"]), int(pack["y"]), int(pack["z"]))) ^ world_seed)
		if foreign != "":
			ids.append(foreign)
			mingled += 1
	var elite_member: int = int(pack["elite_member"])
	var elite_modifier: String = String(pack["elite_modifier"])
	var elite_bonus: float = float(era.get("elite_chance_bonus", 0.0))
	if not grazer and not bounded and elite_member < 0 and elite_bonus > 0.0:
		var roll := RandomNumberGenerator.new()
		roll.seed = hash(Vector3i(int(pack["x"]), int(pack["y"]), int(pack["z"]))) ^ world_seed
		if roll.randf() < elite_bonus:
			var modifiers: PackedStringArray = sim.elite_modifier_ids()
			if not modifiers.is_empty():
				elite_member = roll.randi() % ids.size()
				elite_modifier = modifiers[roll.randi() % modifiers.size()]
	var members: Array = []
	for i in ids.size():
		var angle := TAU * float(i) / float(maxi(ids.size(), 1))
		var offset := Vector3(cos(angle), 0.5, sin(angle)) * 1.6
		var enemy: Enemy = preload("res://scenes/enemy.tscn").instantiate()
		enemy.enemy_id = StringName(ids[i])
		var position := at + (Vector3.UP * .5 if bounded else offset)
		if terrain != null and not terrain.map.is_empty() and String(pack.get("biome",""))!="cave":
			var body := enemy.get_node("CollisionShape3D") as CollisionShape3D
			position = _surface_member_position(position,(body.shape as CapsuleShape3D).radius,offset.y)
		# Set the final pose before entering the tree, as Enemy.spawn does: no
		# transient body at the scene origin and a correct first MobGrid entry.
		enemy.position = (get_parent() as Node3D).to_local(position) if get_parent() is Node3D else position
		get_parent().add_child(enemy)
		enemy.set_aggro_multiplier(aggro_multiplier())
		if bounded:
			enemy.set_meta("frontier_host_id",frontier_id)
			for habitat: Dictionary in terrain.map.get("frontier_hosts",[]):
				if String(habitat.id) == frontier_id:
					enemy.habit_points = habitat.habits
					enemy.habit_pause_seconds = float(terrain.map.frontier_rules.habit_pause_seconds)
		# The danger ring may have crowned one member (Wave 3 elites).
		if i == elite_member and elite_modifier != "":
			enemy.make_elite(sim.elite_modifier(elite_modifier))
		enemy.died.connect(_on_enemy_died)
		members.append(enemy)
	pack["members"] = members


func loot_kill_counter() -> int:
	return _kill_counter


func restore_loot_counter(value: int) -> void:
	_kill_counter = maxi(0, value)


func _on_enemy_died(enemy: Enemy) -> void:
	var id := String(enemy.get_meta("frontier_host_id", ""))
	if not id.is_empty():
		var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
		var effect := "host_defeated:" + id
		if sim.world_effect_active(effect): return
		sim.record_world_effect(effect)
	_kill_counter += 1
	# Per-kill deterministic seed: replaying a save replays its luck.
	drop_loot_for(enemy, world_seed + _kill_counter * 7919)
	note_first_kill(enemy)


## A family's first kill is a Foundry milestone (foundry.json sources):
## the sim says whether this one forged an ingot.
static func note_first_kill(enemy: Enemy) -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var granted: Array = sim.foundry_event("first_kill:%s" % enemy.enemy_id)
	# An elite's fall is its own milestone (D-023 slice 10): the first of
	# a family pays an ingot already cast in the era's alloy.
	if enemy.elite_id != "":
		granted.append_array(sim.foundry_event("elite_kill:%s" % enemy.enemy_id))
	var player := enemy.get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player == null or player.hud == null:
		return
	for id in granted:
		player.hud.notify("The Foundry: your first %s forged a %s." % [enemy.display_name, sim.foundry_ingot(id).get("display_name", id)])


## Rolls and scatters a kill's loot for a seed. The three loot kinds
## (materials, gear, pages) roll independent streams off this one seed
## inside the sim; an elite's id rides along for its bounty (extra passes,
## tripled gear and page chances).
func drop_loot_for(enemy: Enemy, kill_seed: int) -> void:
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var elite: String = enemy.elite_id
	var at := enemy.global_position
	var from := at + Vector3(0, 0.5, 0)
	var floor_y := at.y + 0.02
	var drops: Dictionary = sim.enemy_loot(enemy.enemy_id, kill_seed, elite)
	if not drops.is_empty():
		Pickup.scatter(get_parent(), from, drops, kill_seed, floor_y)
	# Gear: one pickup per kill, previewing the roll; the sim re-rolls the
	# identical item on claim, so the pickup remembers only the kill (elite
	# id included - the bounty survives the walk back).
	var gear: Array = sim.enemy_gear_loot(enemy.enemy_id, kill_seed, elite)
	if not gear.is_empty():
		Pickup.drop_gear(get_parent(), from, enemy.enemy_id, kill_seed, gear[0], floor_y, elite)
	var page: String = sim.enemy_skill_page(enemy.enemy_id, kill_seed, elite)
	if page != "":
		var view: Dictionary = sim.combat_skill(page)
		Pickup.drop_page(get_parent(), from, page, view.get("display_name", page), floor_y)
