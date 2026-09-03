class_name MobPacks
extends Node
## Roaming mob packs of the sandpit. Each pack from the sim's world map is a
## dormant spawn point; when the player first comes near, its enemies appear
## and hold their ground (aggro is the enemies' own behaviour). Kills roll
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
			"spawned": false,
			"members": [],
		})
	var horde: Dictionary = load("res://scripts/sim.gd").shared().realtime().get("horde", {})
	max_live_mobs = int(horde.get("max_live_mobs", 60))
	sleep_range_m = float(horde.get("sleep_range_m", 60.0))
	sleep_after_seconds = float(horde.get("sleep_after_seconds", 6.0))


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
			continue
		# The cap: a crowd is a crowd, however many packs the walk crossed.
		if live >= max_live_mobs:
			break
		# Packs stand at their generated level: the surface, or a cave floor
		# (cave packs activate when the player is near in 3D - above ground
		# counts, so descending into a lit-up cave meets its residents).
		var cell: float = terrain.map["cell_size"]
		var at := Vector3((pack["x"] + 0.5) * cell, float(pack["y"]), (pack["z"] + 0.5) * cell)
		if at.distance_to(player.global_position) <= ACTIVATION_RANGE_M:
			_spawn_pack(pack, at)
			live += (pack["members"] as Array).size()


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
			if enemy.global_position.distance_to(player_position) < sleep_range_m:
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
		var anchor := Vector3((pack["x"] + 0.5) * cell, float(pack["y"]), (pack["z"] + 0.5) * cell)
		if anchor.distance_to(player_position) < sleep_range_m:
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
	var player := enemy.get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player == null or player.hud == null:
		return
	for id in granted:
		player.hud.notify("The Foundry: your first %s forged a %s." % [enemy.display_name, sim.foundry_ingot(id).get("display_name", id)])


## Rolls and scatters a kill's loot for a seed. The three loot kinds
## (materials, gear, pages) roll independent streams off this one seed
## inside the sim; an elite's id rides along for its bounty (extra passes,
## tripled gear and page chances). Nest-born kills come here too, when the
## encroachment rules say that kill drops at all.
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
