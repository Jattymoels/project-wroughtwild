extends Node
## In-engine integration test, run with:
##   godot --headless --path game res://tests/integration.tscn
## Instances the real spike scene and drives the placement loop across
## physics frames: preview validity (unaffordable -> red, affordable -> green),
## block placement consuming material, and removal with partial refund.
## Quits with a non-zero exit code on failure.

const SAVE_PATH := "user://integration_test_save.json"

var _scene: Node3D
var _player: WroughtwildPlayer
var _frame := 0
var _failures := 0
var _checks := 0
var _saved_wood := 0
var _front: Enemy
var _back: Enemy
var _wood_before_death := 0
var _death_spot := Vector3.ZERO


func check(condition: bool, label: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		printerr("FAIL: %s" % label)


func _ready() -> void:
	_scene = (load("res://scenes/spike_valley.tscn") as PackedScene).instantiate()
	add_child(_scene)
	_player = _scene.get_node("Player")
	# Tilt the camera arm down so the view ray hits the floor within range,
	# and nudge the player off x = 0 so the ray does not graze a cell boundary.
	(_player.get_node("SpringArm3D") as SpringArm3D).rotation.x = -0.6
	_player.position.x = 0.3


func _count_placed_blocks() -> int:
	# Placement spawns blocks under the current scene root.
	var count := 0
	for child in get_tree().current_scene.get_children():
		if child is PlacedBlock:
			count += 1
	return count


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		2:
			# Build mode with an empty inventory: preview must show invalid.
			# The cube costs 2 wood per data/tuning/construction.json.
			_player.placement.set_build_mode_enabled(true)
		4:
			check(_player.placement.preview_visible, "integration: preview visible over floor")
			check(not _player.placement.preview_valid, "integration: unaffordable preview is invalid")
			check(not _player.placement.try_place_block(), "integration: invalid preview refuses placement")
			_player.inventory.add_material(&"wood", 10)
		6:
			check(_player.placement.preview_valid, "integration: affordable free cell is valid")
			check(_player.placement.try_place_block(), "integration: placement succeeds")
			check(_player.inventory.get_count(&"wood") == 8, "integration: material consumed")
			check(_count_placed_blocks() == 1, "integration: block spawned into scene")
		8:
			# The placed block is now in the physics space and in the view ray.
			check(_player.placement.try_remove_block(), "integration: removal hits placed block")
			check(_player.inventory.get_count(&"wood") == 9,
				"integration: partial refund applied (floor(2 * 0.5) = 1)")
		10:
			check(_count_placed_blocks() == 0, "integration: removed block left the scene")
		12:
			# Forge site: refused while unaffordable, built through the sim once paid for.
			var sim: WroughtwildSim = _player.inventory.get_sim()
			var forge: StationSite = _scene.get_node("ForgeSite")
			forge.interact(_player)
			check(not sim.has_station("forge_basic"), "integration: forge refused without materials")
			sim.add_material("wood", 15)
			sim.add_material("iron_ore", 4)
			forge.interact(_player)
			check(sim.has_station("forge_basic"), "integration: forge built through the sim")
			check(sim.material_count("iron_ore") == 0, "integration: forge cost paid from inventory")
			check(not _player.work_panel.is_open(), "integration: building does not open the panel")
		14:
			# Built forge opens the crafting panel; crafting runs the sim rule.
			var sim: WroughtwildSim = _player.inventory.get_sim()
			var forge: StationSite = _scene.get_node("ForgeSite")
			forge.interact(_player)
			check(_player.work_panel.is_open(), "integration: built forge opens the crafting panel")
			sim.add_material("iron_ore", 2)
			var result: Dictionary = _player.work_panel.craft("smelt_iron")
			check(result["crafted"], "integration: smelt crafted from the panel")
			check(sim.material_count("iron_ingot") == 1, "integration: ingot in the shared inventory")
			check(_player.work_panel.message().begins_with("Crafted"), "integration: panel reports the craft")
			_player.work_panel.close_panel()
			check(not _player.work_panel.is_open(), "integration: panel closes")
		16:
			# Order board: delivery consumes output, pays currency and changes the world.
			var sim: WroughtwildSim = _player.inventory.get_sim()
			sim.add_material("iron_fittings", 24)
			(_scene.get_node("MineBoard") as OrderBoard).interact(_player)
			check(_player.work_panel.is_open(), "integration: order board opens the panel")
			var delivered: Dictionary = _player.work_panel.deliver()
			check(delivered["fulfilled"], "integration: order delivered")
			check(sim.material_count("iron_fittings") == 0, "integration: order consumed the fittings")
			check(sim.currency_count("trade_currency") == 40, "integration: order paid trade currency")
			check(sim.world_effect_active("old_mine_reinforced"), "integration: world effect recorded")
			check(not sim.recipe_feeds_open_order("iron_fittings"), "integration: fittings no longer feed an open order")
			_player.work_panel.close_panel()
		18:
			_player.placement.set_build_mode_enabled(true)
		20:
			# Save with one block placed, the iron node partly harvested.
			check(_player.placement.try_place_block(), "save: block placed before saving")
			(_scene.get_node("IronNode") as ResourceNode).remaining_units = 5
			_saved_wood = _player.inventory.get_count(&"wood")
			check(_player.save_game(SAVE_PATH), "save: game written")
			check(FileAccess.file_exists(SAVE_PATH), "save: file exists")
		22:
			# Mutate everything the save covers, then load.
			var sim: WroughtwildSim = _player.inventory.get_sim()
			for child in get_tree().current_scene.get_children():
				if child is PlacedBlock:
					child.free()
			sim.consume_material("wood", 3)
			(_scene.get_node("IronNode") as ResourceNode).remaining_units = 1
			_player.global_position += Vector3(2, 0, 0)
			check(_count_placed_blocks() == 0, "save: block removed before loading")
			check(_player.load_game(SAVE_PATH), "save: game loaded")
		24:
			var sim: WroughtwildSim = _player.inventory.get_sim()
			check(_count_placed_blocks() == 1, "save: placed block restored")
			check(_player.inventory.get_count(&"wood") == _saved_wood, "save: inventory restored")
			check((_scene.get_node("IronNode") as ResourceNode).remaining_units == 5, "save: resource node units restored")
			check(sim.has_station("forge_basic") and sim.currency_count("trade_currency") == 40,
				"save: stations and currency restored")
			check(absf(_player.global_position.x - 0.3) < 0.05, "save: player pose restored")
			DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		26:
			# Combat: one whelp ahead (heavy-strike target), one behind (attacker).
			_player.placement.set_build_mode_enabled(false)
			_player.combat.fight_seed_source.seed = 1234
			var p := _player.global_position
			_front = Enemy.spawn(get_tree().current_scene, &"ember_whelp", p + Vector3(0, 0, -1.5))
			_back = Enemy.spawn(get_tree().current_scene, &"ember_whelp", p + Vector3(0, 0, 1.4))
			check(_front.life == 30.0 and _front.damage == 6.0, "combat: enemy numbers come from the sim")
			check(_player.combat.max_life == 100.0 and _player.combat.life == 100.0, "combat: player life from derived stats")
		28:
			check(_player.combat.use_heavy(), "combat: heavy strike finds the enemy in front")
			var dealt := _player.combat.last_hit_dealt
			check(dealt >= 28.0 * 0.9 and dealt <= 28.0 * 1.1, "combat: heavy damage inside the sim's band (%.2f)" % dealt)
			check(not is_instance_valid(_front) or _front.life <= 30.0 - dealt + 0.001, "combat: damage applied to the target")
			check(is_instance_valid(_back) and _back.life == 30.0, "combat: enemy behind untouched by a frontal strike")
			check(not _player.combat.use_heavy(), "combat: cooldown blocks an immediate second strike")
		30:
			var taken := _back.force_attack()
			check(taken >= 6.0 * 0.9 and taken <= 6.0 * 1.1, "combat: whelp hit mitigated by the sim (%.2f)" % taken)
			check(absf(_player.combat.life - (100.0 - taken)) < 0.001, "combat: life reduced by exactly the mitigated hit")
		32:
			var hits := _player.combat.use_area()
			check(hits >= 1, "combat: area strike hits enemies in radius (%d)" % hits)
		34:
			check(_player.combat.use_dash(), "combat: dash available")
			var life_before := _player.combat.life
			check(_back.force_attack() == 0.0, "combat: dash window dodges the hit")
			check(_player.combat.life == life_before, "combat: no life lost while invulnerable")
		40:
			# Open-world death: the pack drops where you fell, you respawn at camp.
			var sim: WroughtwildSim = _player.inventory.get_sim()
			_wood_before_death = sim.material_count("wood")
			check(_wood_before_death > 0, "death: carrying materials before dying")
			_player.combat.invulnerable_left = 0.0
			_player.combat.life = 1.0
			_death_spot = _player.global_position
			_back.force_attack()
			check(_player.combat.life == _player.combat.max_life, "death: respawned with full life")
			check(_player.global_position.distance_to(_player.spawn_position) < 0.01, "death: back at the spawn point")
			check(sim.material_count("wood") == 0, "death: carried materials dropped")
			check(sim.currency_count("trade_currency") == 40, "death: currency kept")
			var bundle: DroppedBundle = null
			for child in get_tree().current_scene.get_children():
				if child is DroppedBundle:
					bundle = child
			check(bundle != null and bundle.global_position.distance_to(_death_spot) < 0.01, "death: pack lies where the player fell")
			if bundle != null:
				bundle.interact(_player)
			check(sim.material_count("wood") == _wood_before_death, "death: pack recovered restores materials")
		42:
			# Ambush data flows from world.json; a forced ambush spawns the party.
			var iron: ResourceNode = _scene.get_node("IronNode")
			check(_player.maybe_ambush(iron).is_empty(), "ambush: suppressed once the mine is reinforced")
			var party: Array = _player.spawn_ambush(iron)
			check(party.size() == 2 and party[0].enemy_id == &"ash_hound", "ambush: two ash hounds per world.json")
			for enemy in get_tree().get_nodes_in_group("enemies"):
				enemy.queue_free()
		44:
			print("%d checks, %d failures" % [_checks, _failures])
			get_tree().quit(0 if _failures == 0 else 1)
