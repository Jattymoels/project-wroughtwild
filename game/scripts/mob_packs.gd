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


func _ready() -> void:
	add_to_group("mob_packs")


func setup(from_terrain: Terrain, seed_value: int) -> void:
	terrain = from_terrain
	world_seed = seed_value
	packs = []
	for pack in terrain.map.get("packs", []):
		packs.append({
			"enemies": pack["enemies"],
			"x": pack["x"],
			"y": pack.get("y", 0),
			"z": pack["z"],
			"elite_member": pack.get("elite_member", -1),
			"elite_modifier": pack.get("elite_modifier", ""),
			"grazer": pack.get("grazer", false),
			"biome": String(pack.get("biome", "")),
			"patrols": bool(pack.get("patrols", false)),
			"route": Vector2i(int(pack.get("route_x", 0)), int(pack.get("route_z", 0))),
			"spawned": false,
			"members": [],
		})
	load_rules()


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
	for pack in packs:
		if pack["spawned"]:
			# A patrol on its feet keeps walking its route: every calm
			# member roams toward where the pack should be by this hour.
			if pack["patrols"]:
				var there := pack_position(pack)
				for m in pack["members"]:
					if is_instance_valid(m) and (m as Enemy).life > 0.0:
						(m as Enemy).roam_to(there)
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
	var route: Vector2i = pack["route"]
	var out: Vector3
	if terrain != null and not terrain.map.is_empty():
		out = terrain.surface_position(route.x, route.y)
	else:
		out = Vector3((route.x + 0.5) * cell, float(pack["y"]), (route.y + 0.5) * cell)
	return den.lerp(out, sin(clampf(night_progress, 0.0, 1.0) * PI))


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
	for pack in packs:
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
		siege_tonight = sim.siege_tonight(seed_value, index)
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
	if get_tree() == null:
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
	for pack in packs:
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
		slept += 1
	return slept


func _spawn_pack(pack: Dictionary, at: Vector3) -> void:
	pack["spawned"] = true
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var ids: PackedStringArray = (pack["enemies"] as PackedStringArray).duplicate()
	# Herds (D-020 the quiet heartland) are life, not threat: no escorts,
	# never crowned.
	var grazer: bool = pack.get("grazer", false)
	# A pack returning from sleep is exactly its survivors: era bonuses and
	# escorts were added the first time and are in the list already.
	var resting: bool = pack.get("resting", false)
	# Era mechanics (eras.json): some families run in bigger packs now, some
	# bring escorts, and later eras crown elites more often.
	var era: Dictionary = sim.era()
	var bonus_seen := {}
	var escorts: Dictionary = era.get("pack_escorts", {})
	for id in (PackedStringArray() if resting else pack["enemies"]):
		if bonus_seen.has(id):
			continue
		bonus_seen[id] = true
		var bonus: Dictionary = sim.era_mechanic(id, "pack_size_bonus")
		for k in int(bonus.get("value", 0)):
			ids.append(id)
		for escort in (PackedStringArray() if grazer else escorts.get(id, PackedStringArray())):
			ids.append(escort)
	var elite_member: int = int(pack["elite_member"])
	var elite_modifier: String = String(pack["elite_modifier"])
	var elite_bonus: float = float(era.get("elite_chance_bonus", 0.0))
	if not grazer and elite_member < 0 and elite_bonus > 0.0:
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
		var enemy := Enemy.spawn(get_parent(), StringName(ids[i]), at + offset)
		enemy.set_aggro_multiplier(aggro_multiplier())
		# The danger ring may have crowned one member (Wave 3 elites).
		if i == elite_member and elite_modifier != "":
			enemy.make_elite(sim.elite_modifier(elite_modifier))
		enemy.died.connect(_on_enemy_died)
		members.append(enemy)
	pack["members"] = members


func _on_enemy_died(enemy: Enemy) -> void:
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
