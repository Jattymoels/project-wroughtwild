class_name TrialController
extends Node
## Drives one trial run in the engine: doors → fight → reward → doors, until
## the boss falls, the player banks out, or dies. The sim's TrialSession
## decides everything that matters (deposit, offers, loot, death contract);
## this node spawns the room's enemies in the arena, watches for the room to
## clear, and presents the choices the sim hands back.

var player: WroughtwildPlayer
var sim: WroughtwildSim
var arena: TrialArena

## idle | doors | fighting | reward
var state := "idle"
var current_room: Dictionary = {}
var current_offer: Array = []
var current_weakness: Dictionary = {}
var return_position := Vector3.ZERO
var seed_source := RandomNumberGenerator.new()


func setup(in_player: WroughtwildPlayer) -> void:
	player = in_player
	sim = player.inventory.get_sim()
	seed_source.randomize()


func active() -> bool:
	return sim.trial_active()


func _find_arena() -> TrialArena:
	if arena == null or not is_instance_valid(arena):
		arena = player.get_tree().get_first_node_in_group("trial_arena") as TrialArena
	return arena


func begin_run() -> bool:
	if active() or _find_arena() == null:
		return false
	if not sim.trial_start(int(seed_source.randi() & 0x7fffffff)):
		return false
	return_position = player.global_position
	player.placement.set_build_mode_enabled(false)
	player.global_position = arena.player_spawn.global_position
	player.velocity = Vector3.ZERO
	player.combat.restore_life()
	player.hud.notify("You stow your ordinary goods in the gate lockers and step inside.")
	show_doors()
	return true


func reopen() -> void:
	match state:
		"doors": show_doors()
		"reward": _present_pending_reward()


# --- doors -------------------------------------------------------------------

func _encounter_summary(ids: PackedStringArray) -> String:
	var counts := {}
	for id in ids:
		var name: String = sim.boss()["display_name"] if id == sim.boss()["id"] else sim.enemy(id).get("display_name", id)
		counts[name] = counts.get(name, 0) + 1
	var parts := PackedStringArray()
	for name in counts:
		parts.append("%d× %s" % [counts[name], name])
	return ", ".join(parts)


func _reward_label(reward: String) -> String:
	match reward:
		"boon_offer": return "a shrine's blessing"
		"weakness_offer": return "a cursed altar"
		"materials": return "salvage"
		"catalyst": return "the catalyst shrine"
		"completion": return "the Tyrant's forge"
	return reward


func show_doors() -> void:
	state = "doors"
	var stage: Dictionary = sim.trial_stage()
	if stage.is_empty():
		return
	var rows: Array = []
	var choices: Array = stage["choices"]
	for i in choices.size():
		var c: Dictionary = choices[i]
		rows.append({
			"text": "%s  —  %s; beyond it, %s." % [c["display_name"], _encounter_summary(c["encounter"]), _reward_label(c["reward"])],
			"button": "Enter",
			"callback": enter_room.bind(i),
		})
	if stage["can_bank_and_exit"]:
		rows.append({
			"text": "A side passage leads out. Bank your loot (%s) and leave; the Tyrant waits." % WorkPanel.amounts_text(sim.trial_loot()),
			"button": "Leave",
			"callback": bank_out,
		})
	var run: Dictionary = sim.trial_run_state()
	var status := ""
	if not run["boons"].is_empty() or not run["weaknesses"].is_empty():
		var names := PackedStringArray()
		for b in run["boons"]:
			names.append(b["display_name"])
		for w in run["weaknesses"]:
			names.append("cursed: " + w["display_name"])
		status = "This run: " + ", ".join(names)
	player.open_custom_panel("The Trial  —  stage %d" % (int(stage["index"]) + 1), rows, status)


func enter_room(choice_index: int) -> bool:
	var room: Dictionary = sim.trial_begin_room(choice_index)
	if not room.get("started", false):
		return false
	current_room = room
	player.work_panel.close_panel()
	state = "fighting"
	_spawn_encounter(room["encounter"])
	player.combat.fight_active = true
	player.hud.notify("%s. %s!" % [room["display_name"], _encounter_summary(room["encounter"])])
	return true


func _spawn_encounter(ids: PackedStringArray) -> void:
	var root: Node = player.world_root()
	var boss_id: String = sim.boss()["id"]
	var ordinary: Array = []
	for id in ids:
		if id == boss_id:
			_make_relentless(Boss.spawn_boss(root, arena.boss_spawn.global_position))
		else:
			ordinary.append(id)
	var points: Array = arena.enemy_spawn_points(ordinary.size())
	for i in ordinary.size():
		_make_relentless(Enemy.spawn(root, ordinary[i], points[i]))


## A trial room is a closed fight: its enemies always know where you are
## and never give up, so a room cannot stall with an idle mob in a corner
## (the open world's D-012 give-up rule stays as it is out there).
func _make_relentless(enemy: Enemy) -> void:
	if enemy == null:
		return
	enemy.aggro_range = 100.0
	enemy.give_up_distance = 0.0


func _process(_delta: float) -> void:
	if state == "fighting":
		_keep_everyone_in_the_room()
		if player.combat.alive_enemies().is_empty():
			_room_won()
	elif state != "idle":
		_keep_everyone_in_the_room()


## Safety net under the walls: anything that still leaves the floor (a
## knockback through a seam, a spawn on the wall line) is put back on it
## rather than falling forever with the room unfinished.
func _keep_everyone_in_the_room() -> void:
	if _find_arena() == null:
		return
	for enemy in player.combat.alive_enemies():
		if not arena.contains(enemy.global_position):
			enemy.global_position = arena.clamp_to_floor(enemy.global_position)
			enemy.velocity = Vector3.ZERO
	if not arena.contains(player.global_position):
		player.global_position = arena.player_spawn.global_position
		player.velocity = Vector3.ZERO


## What the run wants from the player right now, for the HUD.
func prompt() -> String:
	match state:
		"fighting":
			var remaining := player.combat.alive_enemies().size()
			return "Clear the room  —  %d remain" % remaining if remaining != 1 else "Clear the room  —  1 remains"
		"doors":
			return "" if player.work_panel.is_open() else "E  —  choose the next door"
		"reward":
			return "" if player.work_panel.is_open() else "E  —  answer the shrine"
	return ""


# --- rewards -----------------------------------------------------------------

var _pending_outcome: Dictionary = {}
var _completion_items := ""


## ", and a keen Frost Sceptre" for the gear a room dropped (D-014).
func _items_text(outcome: Dictionary) -> String:
	var names := PackedStringArray()
	for item in outcome.get("items", []):
		names.append("a %s %s" % [item.get("rarity", "plain"), item.get("display_name", "item")])
	return "" if names.is_empty() else "  Among the spoils: %s." % ", ".join(names)


func _room_won() -> void:
	state = "reward"
	_pending_outcome = sim.trial_resolve_room(true)
	current_offer = _pending_outcome.get("boon_offer", [])
	current_weakness = _pending_outcome.get("offered_weakness", {})
	_present_pending_reward()


func _present_pending_reward() -> void:
	var outcome := _pending_outcome
	match outcome.get("reward_type", ""):
		"boon_offer":
			var rows: Array = []
			for boon in current_offer:
				rows.append({
					"text": "%s  —  %s" % [boon["display_name"], boon["design_purpose"]],
					"button": "Accept",
					"callback": accept_boon.bind(boon["id"]),
				})
			rows.append({"text": "Decline the blessing.", "button": "Skip", "callback": skip_offer})
			player.open_custom_panel("A shrine offers a temporary blessing", rows, "For this run only; your stored build is untouched.")
		"weakness_offer":
			var rows: Array = []
			if current_weakness.is_empty():
				rows.append({"text": "The altar is silent.", "button": "Continue", "callback": skip_offer})
			else:
				rows.append({
					"text": "%s  —  every enemy ahead quickens; rewards ×%.2f." % [current_weakness["display_name"], current_weakness["reward_multiplier"]],
					"button": "Accept",
					"callback": accept_weakness,
				})
				rows.append({"text": "Refuse the bargain.", "button": "Decline", "callback": skip_offer})
			player.open_custom_panel("A cursed altar offers greater rewards for greater danger", rows, "")
		"materials":
			player.hud.notify("You claim %s%s." % [WorkPanel.amounts_text(outcome.get("materials", {})), _items_text(outcome)])
			_after_reward()
		"catalyst":
			player.hud.notify("You prise an EMBER CATALYST from the shrine; it thrums with heat. Even death cannot take it from you now.%s" % _items_text(outcome))
			_after_reward()
		"completion":
			_completion_items = _items_text(outcome)
			finish_run()
		_:
			_after_reward()


func accept_boon(boon_id: String) -> void:
	if sim.trial_accept_boon(boon_id):
		player.hud.notify("The blessing settles over you, for this run only.")
	_after_reward()


func skip_offer() -> void:
	_after_reward()


func accept_weakness() -> void:
	if sim.trial_accept_weakness():
		player.hud.notify("The enemies ahead quicken...")
	_after_reward()


func _after_reward() -> void:
	current_offer = []
	current_weakness = {}
	player.work_panel.close_panel()
	if sim.trial_finished():
		finish_run()
	else:
		show_doors()


# --- ending ------------------------------------------------------------------

func bank_out() -> void:
	if sim.trial_bank_and_exit():
		player.hud.notify("You slip out with your prizes. The Tyrant waits.")
		finish_run()


## Called by the player when they die inside a run.
func on_player_died() -> void:
	if not active():
		return
	if state == "fighting":
		sim.trial_resolve_room(false)
	else:
		sim.trial_abandon()
	finish_run()


func _despawn_enemies() -> void:
	for node in player.get_tree().get_nodes_in_group("enemies"):
		node.remove_from_group("enemies")
		node.queue_free()


func finish_run() -> void:
	var died: bool = sim.trial_player_died()
	var boss_defeated: bool = sim.trial_boss_defeated()
	_despawn_enemies()
	player.work_panel.close_panel()
	sim.trial_end()
	state = "idle"
	current_room = {}
	player.global_position = return_position
	player.velocity = Vector3.ZERO
	player.combat.restore_life()
	player.combat.invulnerable_left = 2.0
	if died:
		var kept := ", and the catalyst is still in your hand" if sim.material_count("ember_catalyst") > 0 else ""
		player.hud.notify("You wake at the gate. Your stored goods are untouched%s. The Tyrant's weakness to prepared steel is clearer now." % kept)
	elif boss_defeated:
		player.hud.notify("The Forge Tyrant falls! Deep in its forge you find mastery of stonecut blocks: a new material for your constructions.%s" % _completion_items)
		_completion_items = ""
	player.hud.refresh()
