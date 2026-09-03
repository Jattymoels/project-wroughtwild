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
var packs: Array = []          # {enemies, x, z, spawned}
var world_seed := 0
var _kill_counter := 0
var _check_timer := 0.0


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
			"spawned": false,
		})


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
	for pack in packs:
		if pack["spawned"]:
			continue
		# Packs stand at their generated level: the surface, or a cave floor
		# (cave packs activate when the player is near in 3D - above ground
		# counts, so descending into a lit-up cave meets its residents).
		var cell: float = terrain.map["cell_size"]
		var at := Vector3((pack["x"] + 0.5) * cell, float(pack["y"]), (pack["z"] + 0.5) * cell)
		if at.distance_to(player.global_position) <= ACTIVATION_RANGE_M:
			_spawn_pack(pack, at)


func _spawn_pack(pack: Dictionary, at: Vector3) -> void:
	pack["spawned"] = true
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	var ids: PackedStringArray = pack["enemies"]
	# Era mechanics (eras.json): some families run in bigger packs now, some
	# bring escorts, and later eras crown elites more often.
	var era: Dictionary = sim.era()
	var bonus_seen := {}
	var escorts: Dictionary = era.get("pack_escorts", {})
	for id in pack["enemies"]:
		if bonus_seen.has(id):
			continue
		bonus_seen[id] = true
		var bonus: Dictionary = sim.era_mechanic(id, "pack_size_bonus")
		for k in int(bonus.get("value", 0)):
			ids.append(id)
		for escort in escorts.get(id, PackedStringArray()):
			ids.append(escort)
	var elite_member: int = int(pack["elite_member"])
	var elite_modifier: String = String(pack["elite_modifier"])
	var elite_bonus: float = float(era.get("elite_chance_bonus", 0.0))
	if elite_member < 0 and elite_bonus > 0.0:
		var roll := RandomNumberGenerator.new()
		roll.seed = hash(Vector3i(int(pack["x"]), int(pack["y"]), int(pack["z"]))) ^ world_seed
		if roll.randf() < elite_bonus:
			var modifiers: PackedStringArray = sim.elite_modifier_ids()
			if not modifiers.is_empty():
				elite_member = roll.randi() % ids.size()
				elite_modifier = modifiers[roll.randi() % modifiers.size()]
	for i in ids.size():
		var angle := TAU * float(i) / float(maxi(ids.size(), 1))
		var offset := Vector3(cos(angle), 0.5, sin(angle)) * 1.6
		var enemy := Enemy.spawn(get_parent(), StringName(ids[i]), at + offset)
		# The danger ring may have crowned one member (Wave 3 elites).
		if i == elite_member and elite_modifier != "":
			enemy.make_elite(sim.elite_modifier(elite_modifier))
		enemy.died.connect(_on_enemy_died)


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
