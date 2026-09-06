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
var spatial := false
var built_floor := 0
var layout: Dictionary = {}
var room_space: Dictionary = {}
var encounter_id := ""
var wave_queue: Array = []
var wave_left := 0.0
var rules: Dictionary = {}
var run_mods: Dictionary = {}
var vent_left := 0.0
var vent_index := 0
var conduits: Array = []
var conduit_left := 0.0
var elapsed_seconds := 0.0
var completed_encounters := 0
var boss_tells := 0
var _last_floor_completion := -1
var current_stage_index := -1


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


func begin_run(floor_id: String = "") -> bool:
	return _begin_run(floor_id, false)

## Retained only for original economy-oracle fixtures.
func begin_legacy_run(floor_id: String = "") -> bool:
	return _begin_run(floor_id, true)

func begin_map(tier: int, offer_index: int) -> bool:
	if active() or _find_arena() == null:
		return false
	if not sim.call("trial_start_map", tier, offer_index): return false
	spatial=true
	_enter_run()
	return true

func _begin_run(floor_id: String, legacy: bool) -> bool:
	if active() or _find_arena() == null: return false
	var seed:=int(seed_source.randi() & 0x7fffffff)
	var started: bool=sim.trial_start(seed,floor_id) if legacy else bool(sim.call("trial_start_story",seed,"forge_tyrant" if floor_id=="" else floor_id))
	if not started:
		return false
	spatial=not legacy
	_enter_run()
	return true

func _enter_run() -> void:
	_cancel_transients()
	return_position = player.global_position
	elapsed_seconds=0
	completed_encounters=0
	boss_tells=0
	_last_floor_completion=-1
	conduits=[]
	if spatial:
		layout=sim.call("trial_layout")
		rules=sim.call("trial_rules")
		run_mods=sim.combat_mods()
		built_floor=0
		arena.build_floor(layout,built_floor)
	else:
		arena.restore_legacy()
	player.placement.set_build_mode_enabled(false)
	player.global_position = arena.player_spawn.global_position
	player.velocity = Vector3.ZERO
	player.combat.restore_life()
	player.hud.notify("You stow your ordinary goods in the gate lockers and step inside.")
	show_doors()


func reopen() -> void:
	if spatial:
		var probe:=player.aim_probe()
		var target: Object=probe.get("target")
		if target is TrialFixture: interact_fixture(target)
		return
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
	if spatial:
		_show_spatial_route()
		return
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
	var stage_index:=int(sim.trial_stage().get("index",0))
	current_stage_index=stage_index
	var room: Dictionary = sim.trial_begin_room(choice_index)
	if not room.get("started", false):
		return false
	current_room = room
	if spatial:
		room_space=arena.dungeon.open_room(stage_index,choice_index)
		encounter_id=String(room.get("id","encounter_%d"%stage_index))
		run_mods=sim.combat_mods()
	player.work_panel.close_panel()
	state = "fighting"
	_spawn_encounter(room["encounter"])
	player.combat.fight_active = true
	player.hud.notify("%s. %s!" % [room["display_name"], _encounter_summary(room["encounter"])])
	return true


func _spawn_encounter(ids: PackedStringArray) -> void:
	if spatial:
		_spawn_spatial_encounter(ids)
		return
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
	enemy.trial_bound = true
	enemy.aggro_range = 100.0
	enemy.give_up_distance = 0.0
	if spatial:
		enemy.trial_encounter_id=encounter_id
		enemy.trial_dungeon=arena.dungeon
		enemy.trial_controller=self
		enemy.max_life*=float(run_mods.get("enemy_life_multiplier",1.0))
		enemy.life=enemy.max_life
		enemy.damage*=float(run_mods.get("enemy_damage_multiplier",1.0))
		enemy.died.connect(_spatial_enemy_died)
		if enemy is Boss:
			enemy.breath_damage*=float(run_mods.get("enemy_damage_multiplier",1.0))
			enemy.configure_trial(self,rules)
		enemy.verb_arc+=float(run_mods.get("guard_arc_bonus_degrees",0.0))
		enemy.state="chase"
		enemy._refresh_label()


## The room's own living enemies. The open world's packs are not the
## trial's business: they are neither pulled into the arena nor counted.
func trial_enemies() -> Array:
	var alive: Array = []
	for enemy in player.combat.alive_enemies():
		if enemy.trial_bound:
			if not spatial or enemy.trial_encounter_id==encounter_id:
				alive.append(enemy)
	return alive


func _process(_delta: float) -> void:
	if spatial and active():
		elapsed_seconds+=_delta
		if state=="fighting":
			_tick_spatial(_delta)
	if state == "fighting":
		_keep_everyone_in_the_room()
		if trial_enemies().is_empty() and wave_queue.is_empty() and _hazards().is_empty():
			_room_won()
	elif state != "idle":
		_keep_everyone_in_the_room()


## Safety net under the walls: anything that still leaves the floor (a
## knockback through a seam, a spawn on the wall line) is put back on it
## rather than falling forever with the room unfinished.
func _keep_everyone_in_the_room() -> void:
	if _find_arena() == null:
		return
	for enemy in trial_enemies():
		if not arena.contains(enemy.global_position):
			enemy.global_position = arena.clamp_to_floor(enemy.global_position)
			enemy.velocity = Vector3.ZERO
	if not arena.contains(player.global_position):
		player.global_position = arena.clamp_to_floor(player.global_position) if spatial else arena.player_spawn.global_position
		player.velocity = Vector3.ZERO


## What the run wants from the player right now, for the HUD.
func prompt() -> String:
	if spatial:
		var prefix: String="Floor %d/%d" % [built_floor+1,int(layout.get("floor_count",2))]
		match state:
			"fighting": return "%s · %s · %d enemies, %d reserves" % [prefix,current_room.get("display_name","Encounter"),trial_enemies().size(),wave_queue.size()]
			"reward": return "%s · Claim the offering inside the cleared chamber" % prefix
			"boundary": return "%s cleared · Reach the descent lift: continue, extract or suspend" % prefix
			"exploring": return "%s · Follow the gallery and inspect the lit route seals" % prefix
	match state:
		"fighting":
			var remaining := trial_enemies().size()
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
	if spatial:
		completed_encounters+=1
		var reward_type:=String(_pending_outcome.get("reward_type",""))
		arena.dungeon.place_reward(room_space,"claim "+_reward_label(reward_type))
		_clear_conduits()
		return
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
					"text": "%s  —  %s; rewards ×%.2f." % [current_weakness["display_name"], current_weakness.get("design_purpose","The run grows more dangerous"),current_weakness["reward_multiplier"]],
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
	if not sim.trial_accept_boon(boon_id): return
	player.hud.notify("The blessing settles over you, for this run only.")
	_after_reward()


func skip_offer() -> void:
	if spatial: sim.call("trial_skip_reward")
	_after_reward()


func accept_weakness() -> void:
	if sim.trial_accept_weakness():
		player.hud.notify("The bargain takes hold: "+String(current_weakness.get("display_name","greater danger")))
	_after_reward()


func _after_reward() -> void:
	current_offer = []
	current_weakness = {}
	player.work_panel.close_panel()
	if spatial:
		if is_instance_valid(arena.dungeon.reward):
			arena.dungeon.reward.claimed=true
			arena.dungeon.reward.available=false
			arena.dungeon.reward.refresh()
		arena.dungeon.complete_stage(current_stage_index)
		run_mods=sim.combat_mods()
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
	wave_queue=[]
	for node in player.get_tree().get_nodes_in_group("enemies"):
		if not (node is Enemy) or not (node as Enemy).trial_bound:
			continue
		node.remove_from_group("enemies")
		node.queue_free()


func finish_run() -> void:
	var died: bool = sim.trial_player_died()
	var boss_defeated: bool = sim.trial_boss_defeated()
	var finished_floor: Dictionary=sim.trial_floor()
	var finished_layout: Dictionary=layout.duplicate(true)
	_despawn_enemies()
	for hazard in _hazards(): hazard.cancel()
	_clear_conduits()
	_cancel_transients()
	player.work_panel.close_panel()
	sim.trial_end()
	state = "idle"
	current_room = {}
	if spatial:
		arena.clear_floor()
		player.combat.clear_trial_effects()
	player.global_position = return_position
	player.velocity = Vector3.ZERO
	player.combat.restore_life()
	player.combat.invulnerable_left = 2.0
	if died:
		var kept := ", and the catalyst is still in your hand" if sim.material_count("ember_catalyst") > 0 else ""
		player.hud.notify("You wake at the gate. Your stored goods are untouched%s. The Tyrant's weakness to prepared steel is clearer now." % kept)
	elif boss_defeated:
		var floor: Dictionary = finished_floor
		if String(floor.get("id", "")) != "":
			player.hud.notify("%s%s" % [floor.get("completion_text", "The warden falls."), _completion_items])
		else:
			player.hud.notify("The Forge Tyrant falls! In the ash of its forge lies its cinder heart, still warm.%s" % _completion_items)
		# The curio (Wave 8 slice 2): its reading names the lock.
		for hint in sim.curio_hints():
			player.hud.notify(String(hint))
		_completion_items = ""
		# The first trial (D-023 slice 9): the forge's completion offers the
		# specialisation - a view of what the plate's rails can become.
		if bool(sim.foundry().get("can_specialise", false)):
			player.hud.notify("The forge was your first trial. You may specialise further: F opens the plate and shows what your rails can become.")
	player.hud.refresh()
	if spatial:
		player.hud.notify("Trial %s · %.1f minutes · %d encounters · %d boss tells" % ["failed" if died else "complete" if boss_defeated else "extracted",elapsed_seconds/60.0,completed_encounters,boss_tells])
		if String(finished_layout.get("run_kind",""))=="map" and boss_defeated:
			player.hud.notify("Challenge cleared. The gate offers the next tier.")
	spatial=false
	layout={}


func _show_spatial_route() -> void:
	var stage: Dictionary=sim.trial_stage()
	if stage.is_empty(): return
	if bool(stage.get("awaiting_floor",false)):
		state="boundary"
		arena.dungeon.boundary.available=true
		arena.dungeon.boundary.refresh()
		if _last_floor_completion!=built_floor:
			_last_floor_completion=built_floor
			_cancel_transients()
		return
	state="exploring"
	arena.dungeon.select_stage(int(stage["index"]),stage.get("choices",[]))

func interact_fixture(fixture: TrialFixture) -> void:
	if not active() or not spatial or fixture.claimed or not fixture.available: return
	if fixture.global_position.distance_to(player.global_position)>player.interact_range+2.0: return
	match fixture.fixture_kind:
		"route":
			if state=="exploring" and fixture.stage_index==int(sim.trial_stage().get("index",-1)):
				enter_room(fixture.choice_index)
		"reward":
			if state=="reward": _present_pending_reward()
		"boundary":
			if state=="boundary": show_boundary()
		"secret":
			if state not in ["exploring","boundary"]: return
			var found: Dictionary=sim.call("trial_claim_secret")
			if not bool(found.get("claimed",false)): return
			fixture.claimed=true
			fixture.available=false
			fixture.refresh()
			player.hud.notify("Hidden store: %s. These materials must be extracted."%WorkPanel.amounts_text(found.get("materials",found)))
		"conduit":
			if state=="fighting":
				fixture.available=false
				fixture.claimed=true
				fixture.refresh()
				player.hud.notify("The ward conduit cools. The furnace guardian loses part of its protection.")

func show_boundary() -> void:
	if not spatial or state!="boundary": return
	player.open_custom_panel("The cleared floor",[
		{"text":"Carry your blessings and unbanked haul into the next floor.","button":"Continue","callback":continue_floor},
		{"text":"Secure the haul and return to the gate. The final boss remains.","button":"Bank and leave","callback":bank_out},
		{"text":"Save this exact run and quit. Life, blessings and at-risk loot resume here.","button":"Suspend and quit","callback":suspend_and_quit},
	],"Suspending grants no healing or extraction.")

func continue_floor() -> bool:
	if not spatial or state!="boundary" or not bool(sim.call("trial_continue_floor")): return false
	player.work_panel.close_panel()
	_cancel_transients()
	layout=sim.call("trial_layout")
	built_floor=int(sim.trial_stage().get("floor_index",built_floor+1))
	arena.build_floor(layout,built_floor)
	player.global_position=arena.player_spawn.global_position
	player.velocity=Vector3.ZERO
	room_space={}
	_show_spatial_route()
	return true

func suspend_to(path: String) -> bool:
	if not spatial or state!="boundary" or not _hazards().is_empty() or not trial_enemies().is_empty(): return false
	if _has_live_foundry_events():
		player.hud.notify("Let your active Foundry effects finish before suspending this exact run.")
		return false
	if player.global_position.distance_to(arena.dungeon.boundary.global_position)>player.interact_range+2.0:
		player.hud.notify("Reach the cleared floor's descent lift to suspend.")
		return false
	var manager:=SaveManager.new()
	var success:=manager.write(path,player)
	if not success: player.hud.notify("Suspend failed: "+manager.last_error)
	return success

func suspend_and_quit() -> void:
	if suspend_to(SaveManager.DEFAULT_PATH): player.get_tree().quit()

func capture_boundary() -> Dictionary:
	if not spatial or state!="boundary": return {}
	if _has_live_foundry_events(): return {}
	var checkpoint: String=sim.call("trial_checkpoint")
	if checkpoint.is_empty(): return {}
	var combat_state:=player.combat.capture_trial_state()
	return {"version":1,"checkpoint":checkpoint,"built_floor":built_floor,
		"secret_claimed":is_instance_valid(arena.dungeon.secret) and arena.dungeon.secret.claimed,
		"return_position":SaveManager._vec(return_position),"combat":combat_state,
		"combat_exact":Marshalls.variant_to_base64(combat_state,false),
		"elapsed_seconds":elapsed_seconds,"completed_encounters":completed_encounters,"boss_tells":boss_tells}

func restore_boundary(data: Dictionary) -> bool:
	if int(data.get("version",0))!=1 or _find_arena()==null: return false
	if not bool(sim.call("trial_restore_checkpoint",String(data.get("checkpoint","")))): return false
	spatial=true
	layout=sim.call("trial_layout")
	rules=sim.call("trial_rules")
	run_mods=sim.combat_mods()
	built_floor=int(data["built_floor"])
	return_position=SaveManager._unvec(data["return_position"])
	arena.build_floor(layout,built_floor)
	for stage in layout.get("stages",[]):
		if int(stage.get("floor_index",0))==built_floor:
			var index:=int(stage["index"])
			arena.dungeon.open_room(index,int(layout["route"][index]))
			arena.dungeon.complete_stage(index)
	if is_instance_valid(arena.dungeon.secret) and bool(data.get("secret_claimed",false)):
		arena.dungeon.secret.claimed=true
		arena.dungeon.secret.available=false
		arena.dungeon.secret.refresh()
	player.global_position=arena.dungeon.boundary.global_position+Vector3(0,.5,3)
	player.velocity=Vector3.ZERO
	player.placement.set_build_mode_enabled(false)
	player.combat.restore_trial_state(data["combat"])
	elapsed_seconds=float(data.get("elapsed_seconds",0))
	completed_encounters=int(data.get("completed_encounters",0))
	boss_tells=int(data.get("boss_tells",0))
	_last_floor_completion=built_floor
	_show_spatial_route()
	player.hud.notify("Suspended run restored at the cleared floor. Your haul is still at risk.")
	return true

func _spawn_spatial_encounter(ids: PackedStringArray) -> void:
	var boss_id:=String(sim.boss()["id"])
	wave_queue=[]
	for id in ids: wave_queue.append(String(id))
	var ordinary: Array=[]
	for id in ids:
		if id!=boss_id: ordinary.append(id)
	# Rolled density supplies reserves, never a surprise population spike.
	var extras:=int(run_mods.get("crowded_extra_count",0))+int(run_mods.get("reinforcement_count",0))
	if not ordinary.is_empty():
		for i in extras: wave_queue.append(ordinary[i%ordinary.size()])
	wave_left=0
	vent_left=float(rules.get("boss_vent_period_seconds",8.0))
	vent_index=0
	_release_wave()

func _release_wave() -> void:
	if wave_queue.is_empty(): return
	var max_alive:=int(rules.get("living_enemy_limit",24))
	var count:=mini(mini(int(rules.get("encounter_wave_size",10)),wave_queue.size()),max_alive-trial_enemies().size())
	if count<=0: return
	var points:=arena.dungeon.spawn_points(room_space,count)
	for i in count:
		var id:=String(wave_queue.pop_front())
		var enemy: Enemy
		if id==String(sim.boss()["id"]):
			enemy=Boss.spawn_boss(player.world_root(),arena.dungeon.to_global(room_space.get("centre",Vector3.ZERO))+Vector3(0,.5,-4))
		else:
			enemy=Enemy.spawn(player.world_root(),StringName(id),points[i])
		_make_relentless(enemy)
		if not (enemy is Boss) and i==0 and (String(layout.get("run_kind",""))=="map" or current_stage_index%4==3):
			enemy.elite_id="trial_rare"
			enemy.display_name="Forge-bound "+enemy.display_name
			enemy.max_life*=float(rules.get("elite_life_multiplier",1.5))
			enemy.life=enemy.max_life
			enemy.damage*=float(rules.get("elite_damage_multiplier",1.15))
			enemy.trial_ward_radius=float(run_mods.get("rare_ward_radius_m",0))
			enemy.trial_ward_strength=float(run_mods.get("rare_ward_reduction",0))
			if enemy.trial_ward_radius>0:
				enemy.verb="ward"
				enemy.verb_radius=enemy.trial_ward_radius
				enemy.verb_strength=enemy.trial_ward_strength
			enemy._refresh_label()
	wave_left=float(run_mods.get("reinforcement_delay_seconds",rules.get("reinforcement_delay_seconds",8.0)))

func _tick_spatial(delta: float) -> void:
	wave_left-=delta
	if not wave_queue.is_empty() and (wave_left<=0 or trial_enemies().is_empty()): _release_wave()
	vent_left-=delta
	var boss_alive:=false
	for e in trial_enemies():
		if e is Boss: boss_alive=true; break
	if vent_left<=0 and (boss_alive or int(run_mods.get("extra_vent_count",0))>0):
		vent_left=float(rules.get("boss_vent_period_seconds",8.0))
		var centre: Vector3=room_space.get("centre",Vector3.ZERO)
		for i in 1+int(run_mods.get("extra_vent_count",0)):
			var offset:=float(vent_index%3-1)*5
			var across:=String(layout.get("run_id",""))=="forge_capstone" and vent_index%2==1
			vent_index+=1
			spawn_hazard(arena.dungeon.to_global(centre+(Vector3(0,0,offset) if across else Vector3(offset,0,0))),rules,Vector2(16,2.8) if across else Vector2(2.8,16),"Furnace vent")
	conduit_left-=delta
	if not conduits.is_empty() and conduit_left<=0:
		conduit_left=float(rules.get("conduit_rearm_seconds",16))
		for conduit in conduits:
			if is_instance_valid(conduit):
				conduit.available=true
				conduit.claimed=false
				conduit.refresh()

func _hazards() -> Array:
	var out: Array=[]
	if player==null: return out
	for h in player.get_tree().get_nodes_in_group("trial_hazards"):
		if is_instance_valid(h) and not h.spent and h.controller==self: out.append(h)
	return out

func spawn_hazard(at: Vector3, config: Dictionary, lane:=Vector2.ZERO, title:="Furnace vent") -> TrialHazard:
	if _hazards().size()>=int(rules.get("hazard_limit",2)): return null
	var hazard:=TrialHazard.new()
	player.world_root().add_child(hazard)
	hazard.configure(self,at,config,lane,title)
	return hazard

func _spatial_enemy_died(enemy: Enemy) -> void:
	if enemy.trial_encounter_id!=encounter_id: return
	if enemy.elite_id!="":
		player.combat.heal(player.combat.max_life*float(sim.combat_mods().get("elite_kill_heal_fraction",0)))
		if float(run_mods.get("volatile_damage",0))>0:
			var config:=rules.duplicate(true)
			config["hazard_telegraph_seconds"]=run_mods.get("volatile_delay_seconds",1.4)
			config["hazard_damage_per_tick"]=run_mods.get("volatile_damage",0)
			config["hazard_radius_m"]=run_mods.get("volatile_radius_m",3)
			config["hazard_active_seconds"]=float(rules.get("hazard_tick_seconds",.8))*.5
			spawn_hazard(enemy.global_position,config,Vector2.ZERO,"Volatile rare eruption")

func target_multiplier(enemy: Enemy) -> float:
	var multiplier:=1.0
	if enemy.staggered(): multiplier*=float(sim.combat_mods().get("staggered_damage_multiplier",1))
	if enemy is Boss:
		var active_conduits:=0
		for c in conduits:
			if is_instance_valid(c) and c.available: active_conduits+=1
		multiplier*=1.0-float(rules.get("conduit_reduction_per_active",.15))*active_conduits
	return maxf(0.05,multiplier)

func build_conduits() -> void:
	_clear_conduits()
	var centre: Vector3=room_space.get("centre",Vector3.ZERO)
	for offset in [Vector3(-7,0,7),Vector3(7,0,7),Vector3(0,0,-9)]:
		var c:=arena.dungeon._fixture("conduit",centre+offset,"Ward conduit","cool the ward")
		c.available=true
		c.refresh()
		conduits.append(c)
	conduit_left=float(rules.get("conduit_rearm_seconds",16))

func _clear_conduits() -> void:
	for c in conduits:
		if is_instance_valid(c): c.queue_free()
	conduits=[]

func _cancel_transients() -> void:
	for group in ["enemy_projectiles","player_projectiles","skill_bursts","foundry_fields","foundry_returns","foundry_echoes","foundry_embers","foundry_cold","foundry_offence","foundry_guard","foundry_sustain","foundry_tempo","foundry_puffs","burning_ground"]:
		for effect in player.get_tree().get_nodes_in_group(group):
			if effect.has_method("cancel"): effect.cancel()
			else: effect.queue_free()

func _has_live_foundry_events() -> bool:
	# A cleared floor removes encounter effects. A new cast made at the lift
	# must finish before an exact checkpoint; it cannot disappear on resume.
	for group in ["foundry_fields","foundry_returns","foundry_echoes","foundry_embers","foundry_cold","foundry_offence","foundry_guard","foundry_sustain","foundry_tempo","player_projectiles","skill_bursts"]:
		for effect in player.get_tree().get_nodes_in_group(group):
			if not effect.is_queued_for_deletion(): return true
	return false
