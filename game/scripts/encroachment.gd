class_name Encroachment
extends Node
## Encroachment controller (D-018's base-threat half): feeds the sim's
## rules a clock and the player's home, raises the nests it says settle,
## fields and refills their packs, and hands nest-born kills to the pack
## loot path only when the sim says that kill drops. Pressure, never
## demolition: nothing here touches a placed piece.

const TICK_SECONDS := 1.0

var mob_packs: MobPacks
var world_seed := 0
## World clock in seconds since this world began.
var now := 0.0
var _tick_left := 0.0
## nest id -> {node, respawn_left}
var _nests: Dictionary = {}
var _kill_counter := 0


func setup(packs: MobPacks, seed_value: int) -> void:
	add_to_group("encroachment")
	mob_packs = packs
	world_seed = seed_value
	now = 0.0
	for entry in _nests.values():
		if is_instance_valid(entry["node"]):
			entry["node"].queue_free()
	_nests.clear()
	_sim().encroachment_reset(seed_value)


func _sim() -> WroughtwildSim:
	return load("res://scripts/sim.gd").shared()


func _physics_process(delta: float) -> void:
	now += delta
	_tick_left -= delta
	if _tick_left > 0.0:
		return
	_tick_left = TICK_SECONDS
	tick()


## One rules step: the sim settles and grows nests; this raises and refills.
func tick() -> void:
	var player := get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player == null:
		return
	var combat := player.combat
	var born: Array = _sim().encroachment_tick(now, combat.has_home, combat.home_position)
	for nest in born:
		_raise(nest, player)
	for nest in _sim().encroachment_nests():
		var id: int = nest["id"]
		if not _nests.has(id):
			continue
		var entry: Dictionary = _nests[id]
		var node: Nest = entry["node"]
		if node.tier != int(nest["tier"]):
			node.set_tier(int(nest["tier"]))
			player.hud.notify("The %s near your home has grown." % node.display_name().to_lower())
		# The pack stands at its tier's size; the fallen return while the nest does.
		var wanted: PackedStringArray = nest["pack"]
		var alive := node.defenders().size()
		if alive < wanted.size():
			entry["respawn_left"] -= TICK_SECONDS
			if entry["respawn_left"] <= 0.0:
				entry["respawn_left"] = _sim().encroachment_rules()["respawn_seconds"]
				_field(node, wanted, alive)


func _raise(nest: Dictionary, player: WroughtwildPlayer) -> void:
	var at := Vector3(nest["x"], 0.0, nest["z"])
	var terrain := player.world_root().get_node_or_null("Terrain") as Terrain
	if terrain != null and not terrain.map.is_empty():
		var cell: float = terrain.map["cell_size"]
		at.y = float(terrain.height_at(floori(at.x / cell), floori(at.z / cell)))
	else:
		at.y = player.global_position.y - 1.0
	var node := Nest.spawn(player.world_root(), at, int(nest["id"]), int(nest["tier"]))
	_nests[int(nest["id"])] = {"node": node, "respawn_left": 0.0}
	_field(node, nest["pack"], 0)
	player.hud.notify("Something has settled on the edge of your claim: a %s." % node.display_name().to_lower())


## Spawns the pack members a nest is short of.
func _field(node: Nest, pack: PackedStringArray, alive: int) -> void:
	for i in range(alive, pack.size()):
		var angle := TAU * float(i) / float(maxi(pack.size(), 1))
		var offset := Vector3(cos(angle), 0.6, sin(angle)) * 2.2
		var enemy := Enemy.spawn(node.get_parent(), StringName(pack[i]), node.global_position + offset)
		enemy.nest_id = node.nest_id
		enemy.died.connect(_on_nest_kill)


## Nest-born kills: the sim decides whether this one drops at all (the
## exploit guard), then the ordinary pack loot path rolls it.
func _on_nest_kill(enemy: Enemy) -> void:
	_kill_counter += 1
	var kill_seed := world_seed + 104729 + _kill_counter * 7919
	if mob_packs != null and _sim().encroachment_kill_drops(kill_seed):
		mob_packs.drop_loot_for(enemy, kill_seed)
	MobPacks.note_first_kill(enemy)


## E on an undefended nest: gone, and the spot scars.
func clear_nest(node: Nest, player: WroughtwildPlayer) -> bool:
	if not _sim().encroachment_clear(node.nest_id, now):
		return false
	_nests.erase(node.nest_id)
	node.queue_free()
	player.hud.notify("You tear the %s apart. The ground here stays quiet a while." % node.display_name().to_lower())
	return true


func nest_count() -> int:
	return _nests.size()


func nest_node(id: int) -> Nest:
	return _nests[id]["node"] if _nests.has(id) else null
