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
var _wood_before_trial := 0
var _blocks_before := 0
var _corner_panel: PlacedBlock
var _door: PlacedBlock
var _room: Array = []
## The x-face, z-face and vertical edge that all meet at build-grid corner
## (5, 3, 5) - registry coordinates run at half cells, so (10, 6, 10).
const CORNER_FACE_X := {"kind": "face", "axis": 0, "cell": Vector3i(10, 6, 10)}
const CORNER_FACE_Z := {"kind": "face", "axis": 2, "cell": Vector3i(10, 6, 10)}
const CORNER_EDGE := {"kind": "edge", "axis": 1, "cell": Vector3i(10, 6, 10)}


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


## The placed piece whose collision holds the point, or null.
func _hits_body(point: Vector3) -> PlacedBlock:
	var shape := SphereShape3D.new()
	shape.radius = 0.05
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis.IDENTITY, point)
	for result in _player.get_world_3d().direct_space_state.intersect_shape(query, 8):
		if result["collider"] is PlacedBlock:
			return result["collider"]
	return null


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
		11:
			# Wave 4 lattice: a wall panel on the x-face of a mid-air cell; the
			# world rules are judged next frame, once it is in the physics space.
			var placement := _player.placement
			_corner_panel = placement.place_piece(CORNER_FACE_X, &"wall_panel", &"wood")
			check(_corner_panel != null and _corner_panel.element["cell"] == Vector3i(10, 6, 10),
				"corner: the panel stands on its element")
			check(_corner_panel.global_position.is_equal_approx(Vector3(5.0, 3.5, 5.5))
				and absf(_corner_panel.rotation.y - PI / 2.0) < 0.001,
				"corner: an x-face panel sits on the x = 5 plane, turned a quarter")
			check(placement.trim_count() == 4, "corner: a lone panel is framed at both ends (two half-cell trims each)")
		13:
			var placement := _player.placement
			check(placement.select_shape(&"wall_panel"), "corner: wall panel selectable")
			check(not placement.element_accepts(CORNER_FACE_X), "corner: the same face is already taken")
			check(placement.element_accepts(CORNER_FACE_Z), "corner: a second panel joins on the shared edge")
			check(placement.select_shape(&"pillar"), "corner: pillar selectable")
			check(placement.element_accepts(CORNER_EDGE), "corner: a post stands on the edge the walls share")
			check(not placement.element_accepts(CORNER_FACE_Z), "corner: a post may not stand on a face")
			check(placement.select_shape(&"cube"), "corner: cube selectable")
			check(placement.element_accepts({"kind": "volume", "axis": 0, "cell": Vector3i(10, 6, 10)})
				and placement.element_accepts({"kind": "volume", "axis": 0, "cell": Vector3i(8, 6, 10)}),
				"corner: a cube fills either cell a wall divides - the wall belongs to neither")
			check(placement.element_accepts({"kind": "volume", "axis": 0, "cell": Vector3i(9, 6, 10)}),
				"corner: a full-size cube may sit off the build grid (on a half cube, say)")
			# The perpendicular wall makes the shared edge a corner: a trim grows there.
			var second := placement.place_piece(CORNER_FACE_Z, &"wall_panel", &"wood")
			check(second != null and placement.trim_count() == 6, "corner: walls meeting at an angle grow a post")
			check(placement.remove_piece(second) and placement.remove_piece(_corner_panel)
				and placement.trim_count() == 0, "corner: removing the walls removes their trims")
			# A door: two cells tall, swings on E, and its opening cannot be straddled.
			check(placement.select_shape(&"door"), "door: selectable from the start")
			var door := placement.place_piece(CORNER_FACE_X, &"door", &"wood")
			check(door != null and door.is_door() and door.global_position.is_equal_approx(Vector3(5.0, 4.0, 5.5)),
				"door: stands two cells tall on its face")
			check(placement.select_shape(&"wall_panel")
				and not placement.element_accepts({"kind": "face", "axis": 0, "cell": Vector3i(10, 8, 10)}),
				"door: the face above it is the door's")
			check(door.toggle() and door.open and not door.toggle() and not door.open, "door: E swings it open and shut")
			_door = door
			# Fine mode: G swaps the selection for its half-scale twin and back.
			check(placement.select_shape(&"wall_panel") and placement.has_fine_twin()
				and not placement.select_shape(&"half_wall"), "fine: twins ride on G, never on Tab")
			check(placement.toggle_fine() and placement.placing_shape() == &"half_wall"
				and placement.shape_size.is_equal_approx(Vector3(0.5, 0.5, 0.125))
				and placement.selection_label().contains("fine"), "fine: G selects the half wall")
			check(placement.element_accepts({"kind": "face", "axis": 0, "cell": Vector3i(11, 7, 10)}),
				"fine: a half wall may stand off the build grid")
			check(placement.select_shape(&"door") and placement.placing_shape() == &"door",
				"fine: a shape without a twin stays full size in fine mode")
			check(not placement.toggle_fine() and placement.select_shape(&"wall_panel")
				and placement.placing_shape() == &"wall_panel", "fine: G again restores full size")
		17:
			# Shelter (building slice 3): walls, floor and roof around the
			# player's cell make a room; the sim's flood fill says so, and
			# resting there regenerates life until a hit resets the settle.
			var placement := _player.placement
			var combat := _player.combat
			var p := _player.global_position
			# The room stands three cells over so its walls never shove the
			# player (the pose is saved and compared a few frames on); the
			# probe point is the room's own centre.
			var c := Vector3i(floori(p.x) + 3, floori(p.y), floori(p.z))
			var inside := Vector3(c.x + 0.5, c.y + 0.5, c.z + 0.5)
			check(not placement.enclosure_at(p)["enclosed"], "shelter: open valley is no shelter")
			for y in 2:
				for wall in [[0, Vector3i(c.x, c.y + y, c.z)], [0, Vector3i(c.x + 1, c.y + y, c.z)],
						[2, Vector3i(c.x, c.y + y, c.z)], [2, Vector3i(c.x, c.y + y, c.z + 1)]]:
					_room.append(placement.place_piece({"kind": "face", "axis": wall[0], "cell": wall[1] * 2},
						&"wall_panel", &"wood"))
			_room.append(placement.place_piece({"kind": "face", "axis": 1, "cell": c * 2}, &"floor_slab", &"wood"))
			check(not placement.enclosure_at(inside)["enclosed"], "shelter: walls without a roof are a yard")
			_room.append(placement.place_piece({"kind": "face", "axis": 1, "cell": Vector3i(c.x, c.y + 2, c.z) * 2},
				&"floor_slab", &"wood"))
			var room: Dictionary = placement.enclosure_at(inside)
			check(room["enclosed"] and room["cells"] == 2, "shelter: a roofed two-cell box is a shelter of two cells")
			check(not placement.enclosure_at(p)["enclosed"], "shelter: standing outside it, you are not")
			check(combat.regen_per_second() > 0.0, "shelter: regen rate read from the sim")
			combat.set_sheltered(true)
			combat._settle_left = 0.0
			combat.life = 50.0
			check(combat.resting(), "shelter: sheltered, settled and hurt means resting")
		19:
			var combat := _player.combat
			check(combat.life > 50.0, "shelter: resting regenerates life (%.1f)" % combat.life)
			combat.take_hit(1.0, "physical", "test")
			check(not combat.resting(), "shelter: a hit resets the settle time")
			for piece in _room:
				_player.placement.remove_piece(piece)
			_room.clear()
			combat.set_sheltered(false)
			combat.restore_life()
			check(_player.inventory.get_sim().structure_pieces().is_empty(), "shelter: the room is gone again")
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
		15:
			# The door is in the physics space now: shut it collides (so X and
			# E can reach it), open it does not.
			var placement := _player.placement
			check(_hits_body(Vector3(5.0, 4.0, 5.5)) == _door, "door: the shut leaf collides")
			_door.toggle()
			check(_hits_body(Vector3(5.0, 4.0, 5.5)) == null, "door: the open leaf is walked through")
			_door.toggle()
			check(placement.remove_piece(_door) and placement.trim_count() == 0, "door: removed with its trims")
			check(_player.inventory.get_sim().structure_pieces().is_empty(), "corner: the structure is empty again")
			_ui_checks()
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
			check(sim.structure_pieces().size() == 1, "save: the structure registry restored with it")
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
			# D-012: dash is pure movement - it grants no invulnerability, so
			# a hit that catches you mid-dash still lands. Position, not
			# i-frames, is the defence.
			check(_player.combat.use_dash(), "combat: dash available")
			var life_before := _player.combat.life
			check(_back.force_attack() > 0.0, "combat: dash grants no i-frames - the hit lands")
			check(_player.combat.life < life_before, "combat: dashing through an attack still costs life")
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
		46:
			# Trial: the gate deposits goods and moves the player into the arena.
			var sim: WroughtwildSim = _player.inventory.get_sim()
			_wood_before_trial = sim.material_count("wood")
			check(_wood_before_trial > 0, "trial: carrying wood before entering")
			(_scene.get_node("TrialGate") as TrialGate).interact(_player)
			check(sim.trial_active(), "trial: run opened at the gate")
			check(sim.material_count("wood") == 0, "trial: goods deposited")
			check(_player.global_position.x > 60.0, "trial: player moved into the arena")
			check(_player.work_panel.is_open() and _player.trial.state == "doors", "trial: doors presented")
			check(not _player.save_game(SAVE_PATH), "trial: saving refused inside the run")
		48:
			check(_player.trial.enter_room(0), "trial: first room entered")
			check(_player.trial.state == "fighting" and _player.combat.alive_enemies().size() == 2, "trial: two whelps spawned")
			check(_player.hud._trial_prompt.text.begins_with("Clear the room"), "trial: HUD says what the room wants")
			var enemies := _player.combat.alive_enemies()
			check((enemies[0] as Enemy).give_up_distance == 0.0, "trial: arena enemies never give up")
			# A retreating archer used to walk through the wall mesh and fall
			# forever, leaving the room unwinnable. Push one out; it must come back.
			(enemies[0] as Enemy).global_position = _player.trial.arena.global_position + Vector3(0, -40, 0)
			(enemies[1] as Enemy).take_damage(1000.0)
		49:
			var survivor: Array = _player.combat.alive_enemies()
			check(survivor.size() == 1 and _player.trial.arena.contains((survivor[0] as Enemy).global_position),
				"trial: an enemy that leaves the room is put back on the floor")
			_player.hud.refresh()
			check(_player.hud._trial_prompt.text.contains("1 remains"), "trial: HUD counts the last enemy")
			(survivor[0] as Enemy).take_damage(1000.0)
		50:
			check(_player.trial.state == "reward" and _player.trial.current_offer.size() >= 1, "trial: clearing the room brings a boon offer")
			_player.trial.accept_boon(_player.trial.current_offer[0]["id"])
			check(_player.inventory.get_sim().trial_run_state()["boons"].size() == 1, "trial: boon accepted into the run")
			check(_player.trial.state == "doors", "trial: back to the doors")
		52:
			check(_player.trial.enter_room(1), "trial: slag vault entered")
			for enemy in _player.combat.alive_enemies():
				enemy.take_damage(1000.0)
		54:
			check(_player.inventory.get_sim().trial_loot().get("iron_ingot", 0) >= 4, "trial: materials room paid run loot")
			check(_player.trial.enter_room(0), "trial: catalyst shrine entered")
			for enemy in _player.combat.alive_enemies():
				enemy.take_damage(1000.0)
		56:
			check(_player.inventory.get_sim().trial_loot().get("ember_catalyst", 0) == 1, "trial: catalyst recovered into run loot")
			check(_player.inventory.get_sim().trial_stage()["can_bank_and_exit"], "trial: bank-out offered before the boss")
			check(_player.trial.enter_room(0), "trial: pushing on to the Tyrant")
			var boss: Boss = null
			for enemy in _player.combat.alive_enemies():
				if enemy is Boss:
					boss = enemy
			check(boss != null and boss.life == 160.0 and boss.breath_damage == 42.0, "trial: boss numbers from the sim")
			if boss != null:
				# Breath telegraph then fire: out of the cone nothing lands.
				_player.combat.invulnerable_left = 0.0
				boss.force_inhale()
				_player.global_position = boss.global_position + Vector3(0, 0, 8)
				boss.look_at(boss.global_position + Vector3(0, 0, -1), Vector3.UP)
				check(boss.breathe(_player) == 0.0, "trial: breath misses outside the cone")
				boss.force_inhale()
				boss.look_at(_player.global_position, Vector3.UP)
				var burned := boss.breathe(_player)
				check(burned >= 42.0 * 0.9 and burned <= 42.0 * 1.1, "trial: unresisted breath lands in band (%.1f)" % burned)
				boss.take_damage(1000.0)
		58:
			var sim: WroughtwildSim = _player.inventory.get_sim()
			check(not sim.trial_active(), "trial: run closed after the boss")
			check(sim.world_effect_active("stonecut_blocks"), "trial: completion unlock recorded")
			check(sim.material_count("wood") == _wood_before_trial, "trial: deposit restored")
			check(sim.material_count("ember_catalyst") == 1 and sim.material_count("iron_ingot") >= 4, "trial: loot banked")
			check(_player.global_position.x < 30.0, "trial: player back at the gate")
			check(_player.combat.life == _player.combat.max_life, "trial: life restored on return")
		60:
			# Death contract through the engine path.
			(_scene.get_node("TrialGate") as TrialGate).interact(_player)
			check(_player.trial.enter_room(1), "trial: second run, hound kennels")
			_player.combat.invulnerable_left = 0.0
			_player.combat.life = 1.0
			var hound: Enemy = _player.combat.alive_enemies()[0]
			hound.force_attack()
		62:
			var sim: WroughtwildSim = _player.inventory.get_sim()
			check(not sim.trial_active(), "trial: death ends the run")
			check(sim.material_count("wood") == _wood_before_trial, "trial: deposit survives death")
			check(sim.material_count("ember_catalyst") == 1, "trial: earlier catalyst survives death")
			check(_player.combat.alive_enemies().is_empty(), "trial: arena cleared after death")
			check(_player.global_position.x < 30.0, "trial: woke at the gate")
			for child in get_tree().current_scene.get_children():
				check(not (child is DroppedBundle), "trial: no pack dropped for a trial death")
		64:
			# The completion unlock widens construction: the slab is placeable.
			var sim: WroughtwildSim = _player.inventory.get_sim()
			check(sim.shape_unlocked("roof_wedge"), "unlock: roof wedge unlocked by the boss kill")
			check(_player.placement.select_shape(&"roof_wedge"), "unlock: wedge selectable")
			check(_player.placement.shape_form == "wedge" and _player.placement.rotatable(),
				"unlock: the wedge is an oriented piece with its own form")
			_blocks_before = _count_placed_blocks()
			_player.placement.set_build_mode_enabled(true)
		66:
			check(_player.placement.try_place_block(), "unlock: wedge placed")
			check(_count_placed_blocks() == _blocks_before + 1, "unlock: wedge in the scene")
			_player.placement.set_build_mode_enabled(false)
			# Wear armour and quench it at the upgraded forge, from the panel.
			var sim: WroughtwildSim = _player.inventory.get_sim()
			sim.add_material("iron_fittings", 6)
			(_scene.get_node("ForgeSite") as StationSite).interact(_player)
			check(_player.work_panel.is_open(), "gear: forge panel open")
			check(_player.work_panel.upgrade(), "gear: forge upgraded from the panel")
			sim.add_material("iron_chest_armour", 1)
			check(_player.work_panel.equip(&"iron_chest_armour"), "gear: armour worn from the panel")
			check(_player.work_panel.temper_basic()["applied"], "gear: quenched at the Improved Forge")
			check(sim.derived_stats()["fire_resistance_percent"] > 10.0, "gear: resistance on the build")
			var refused: Dictionary = _player.work_panel.temper_catalyst(&"ember_catalyst_tempering")
			check(refused["reason"] == "skill_too_low" and _player.work_panel.message().find("skill") >= 0,
				"gear: catalyst temper refused and explained below skill 5")
			_player.work_panel.close_panel()
		68:
			print("%d checks, %d failures" % [_checks, _failures])
			get_tree().quit(0 if _failures == 0 else 1)


## The interface is a headless test surface (interface.md rule 4): pack
## screen, help overlay, action bar and work-panel cards.
func _ui_checks() -> void:
	# The interface is a headless test surface (interface.md rule 4):
	# pack screen, help overlay, action bar and work-panel cards.
	var sim: WroughtwildSim = _player.inventory.get_sim()
	var pack: InventoryPanel = _player.inventory_panel
	_player.toggle_inventory()
	check(pack.is_open(), "ui: I opens the pack screen")
	var nonzero := 0
	for id in sim.inventory():
		if sim.inventory()[id] > 0:
			nonzero += 1
	for id in sim.currency():
		if sim.currency()[id] > 0:
			nonzero += 1
	check(pack.tile_count == nonzero and nonzero > 0, "ui: one tile per carried family and currency")
	pack.set_mod_active(&"deep_frost", true)
	check(sim.skill_mod_active("deep_frost"), "ui: pack toggles a spike mod through the sim")
	pack.set_mod_active(&"deep_frost", false)
	check(not sim.skill_mod_active("deep_frost"), "ui: and back off")
	check(not pack.wear(&"iron_chest_armour"), "ui: wearing armour you do not carry is refused")
	sim.roll_item_into_pack("frost_sceptre", "keen", 1, 11)
	pack.refresh()
	check(pack.gear_count == 1, "ui: a rolled item shows as a gear card")
	check(pack.wear_pack_item(0) and sim.equipment().has("weapon"), "ui: wearing from the pack screen")
	check(pack.take_off(&"weapon") and pack.gear_count == 1, "ui: taking gear off returns it to the pack")
	_player.toggle_inventory()
	check(not pack.is_open(), "ui: I closes the pack screen")
	check(not _player.hud.help_visible(), "ui: help starts hidden")
	_player.hud.toggle_help()
	check(_player.hud.help_visible(), "ui: H shows the controls")
	_player.hud.toggle_help()
	check(_player.hud.action_bar != null and _player.hud.action_bar.slots.size() == 4, "ui: four action slots")
	check(_player.hud.action_bar.shown_fraction(PlayerCombat.AREA_SKILL) == 1.0, "ui: a ready skill shows a full sweep")
	check(_player.hud.holdings_text().contains("wood"), "ui: holdings strip names carried wood")
	_player.open_hand_crafting()
	check(_player.work_panel.is_open() and _player.work_panel.row_count() >= 2, "ui: field crafting renders cards")
	_player.work_panel.close_panel()
