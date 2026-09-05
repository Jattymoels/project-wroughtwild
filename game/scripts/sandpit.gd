class_name Sandpit
extends Node3D
## The Wave 1 open world. Builds everything from the sim's seed-generated
## world map: blocky biome terrain, scattered resource nodes, dormant mob
## packs, the trial gate far out in the wastes and the prospector's order
## board at the spawn clearing. You start with nothing; the first workbench
## is hand-crafted from gathered wood (see docs/prototype/roadmap-waves.md).

const TRIAL_GATE_SCENE := preload("res://scenes/trial_gate.tscn")
const ORDER_BOARD_SCENE := preload("res://scenes/order_board.tscn")

## The world to generate; matches worldgen.json's default_seed on a new game
## and is overwritten by saves so a loaded game rebuilds its own world.
@export var world_seed: int = 1

@onready var terrain: Terrain = $Terrain
@onready var mob_packs: MobPacks = $MobPacks
## Eras (D-019): the world's state, polled from the sim; a change reveals
## the era's nodes, shifts the light and tells the story.
var _era_index := 0
var _era_poll := 0.0
## The day (Wave 6 slice 5): the sim keeps the clock; the sandpit advances
## it with play and hands the hour to the light, the packs and the player.
var _day_phase := ""
var _day_rules: Dictionary = {}
@onready var mood: BiomeMood = $Mood
@onready var player: WroughtwildPlayer = $Player


func _ready() -> void:
	_build_world(world_seed)
	# Before play begins (D-004): the class, unless a save already carries one.
	player.offer_class()


func _sim() -> WroughtwildSim:
	return player.inventory.get_sim()


func _build_world(seed_value: int) -> void:
	world_seed = seed_value
	# Owner accepted the smoother presentation and a less cartoon-like tone.
	# Explicit historical look switches keep reproducible comparisons available.
	var args := OS.get_cmdline_user_args()
	terrain.weathered = not (args.has("--legacy-look") or args.has("--crafted-look") or args.has("--faceted-look") or args.has("--frontier-look"))
	terrain.build(_sim(), seed_value)
	if terrain.map.is_empty():
		return
	mob_packs.setup(terrain, seed_value)

	var spawn := terrain.surface_position(terrain.map["spawn_x"], terrain.map["spawn_z"])
	player.global_position = spawn + Vector3(0, 1.2, 0)
	player.spawn_position = player.global_position
	player.velocity = Vector3.ZERO
	# The art direction's mood dial (D-013): light follows the biome.
	mood.setup(terrain, $WorldEnvironment.environment, $Sun)

	_replace_named(TRIAL_GATE_SCENE, "TrialGate",
		terrain.surface_position(terrain.map["gate_x"], terrain.map["gate_z"]))
	# The locks (Wave 8 slice 2): the landmarks worldgen placed, one per biome.
	for old_landmark in get_tree().get_nodes_in_group("landmarks"):
		old_landmark.free()
	for def in terrain.map.get("landmarks", []):
		Landmark.spawn(self, def, terrain.surface_position(int(def["x"]), int(def["z"])))
	var board := _replace_named(ORDER_BOARD_SCENE, "OrderBoard", spawn + Vector3(4.0, 0.0, 3.0))
	board.look_at(spawn + Vector3(0.0, board.global_position.y - spawn.y, 0.0), Vector3.UP)
	# Life beyond hostiles: the peddler by the board, birds over the trees.
	var old_peddler := get_node_or_null("Peddler")
	if old_peddler != null:
		old_peddler.free()
	var peddler := Peddler.new()
	peddler.name = "Peddler"
	add_child(peddler)
	peddler.global_position = spawn + Vector3(-4.0, 0.0, 3.5)
	peddler.look_at(spawn + Vector3(0.0, 0.0, 0.0), Vector3.UP)
	for flock in get_tree().get_nodes_in_group("flocks"):
		flock.free()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	for i in 6:
		var fx := int(spawn.x) + rng.randi_range(-30, 30)
		var fz := int(spawn.z) + rng.randi_range(-30, 30)
		var flock := Flock.spawn(self, terrain.surface_position(clampi(fx, 1, terrain.map["width"] - 2), clampi(fz, 1, terrain.map["height"] - 2)), seed_value + i)
		flock.add_to_group("flocks")


func _replace_named(scene: PackedScene, node_name: String, at: Vector3) -> Node3D:
	var existing := get_node_or_null(node_name)
	if existing != null:
		remove_child(existing)
		existing.free()
	var node: Node3D = scene.instantiate()
	node.name = node_name
	add_child(node)
	node.global_position = at
	return node


func _physics_process(delta: float) -> void:
	if terrain.map.is_empty():
		return
	_tick_day(delta)
	_era_poll -= delta
	if _era_poll > 0.0:
		return
	_era_poll = 1.0
	var era: Dictionary = _sim().era()
	var index := int(era.get("index", 1))
	if _era_index == 0:
		_era_index = index
		mood.set_era(index)
		mob_packs.set_era(era)
		return
	if index == _era_index:
		return
	_era_index = index
	var revealed := terrain.reveal_era(index)
	mood.set_era(index)
	mob_packs.set_era(era)
	player.hud.notify("Era %d: %s. %s%s" % [index, era["display_name"], era["story"], _mingle_notice(era)])
	if revealed > 0:
		player.hud.notify("The strata have cracked: %d new veins surfaced in the deep." % revealed)


## The mingling told (Wave 8 slice 3): which families now walk which biomes.
func _mingle_notice(era: Dictionary) -> String:
	var parts := PackedStringArray()
	var mingle: Dictionary = era.get("mingle", {})
	for biome in mingle:
		var names := PackedStringArray()
		for id in mingle[biome]:
			names.append(Hud.pretty(String(id)).to_lower() + "s")
		parts.append("%s in the %s" % [", ".join(names), Hud.pretty(String(biome)).to_lower()])
	if parts.is_empty():
		return ""
	return "  The packs mingle: %s.%s" % [", ".join(parts),
		"  The night's patrols cross into other biomes." if bool(era.get("patrols_cross_biomes", false)) else ""]


## Day and night (Wave 6 slice 5; the owner: "imperative there is almost
## like a forced - go back and continue your shelter, and get lost in that
## for a bit"). The clock runs with play; the light, the packs and the
## player's cold follow it, and each phase change is told once. Tests call
## this with zero delta after setting the sim's clock.
func _tick_day(delta: float) -> void:
	var sim := _sim()
	sim.advance_time(delta)
	var day: Dictionary = sim.day()
	if day.is_empty():
		return
	if _day_rules.is_empty():
		_day_rules = sim.day_rules()
	mood.set_day(day, _day_rules)
	player.set_day(day, _day_rules)
	mob_packs.set_hour(day, _day_rules)
	mob_packs.tick_siege(day, player, world_seed)
	var phase := String(day.get("phase", "day"))
	if phase == _day_phase:
		return
	var first := _day_phase == ""
	_day_phase = phase
	if not first:
		player.hud.notify(_phase_notice(phase, day))


func _phase_notice(phase: String, day: Dictionary) -> String:
	var home := player.combat.home_text()
	match phase:
		"dusk":
			return "Dusk. The light is fading and the packs will wake from further away.%s%s" % [
				"  Home is %s." % home if home != "" else "",
				"  Somewhere in the dark, the hounds howl." if mob_packs.siege_tonight else ""]
		"night":
			return "Night. The packs wake from further away; resting in a shelter mends you faster.%s" % (
				"  Home is %s." % home if home != "" else "")
		"dawn":
			return "Dawn. The light returns."
	return "Day %d." % int(day.get("index", 1))


## SaveManager hook: a loaded save carries its own seed; rebuild the world
## when it differs. Placed blocks and stations are restored by the save
## after this runs, so nothing dynamic is lost.
func apply_world_seed(seed_value: int) -> void:
	if seed_value == world_seed:
		return
	_build_world(seed_value)
