class_name PlayerCombat
extends Node
## The player's real-time combat: life, skill cooldown timers, the dash window
## and hit application. Every number (max life, damage per hit, mitigation)
## is asked of the sim; this node only decides when and whom (ADR-0003).

signal life_changed(life: float, max_life: float)
signal died
## A player hit connected with at least one enemy (HUD hitmarker). types:
## the damage types that landed, so a two-element hit can show both.
signal hit_landed(total_damage: float, kills: int, types: PackedStringArray)
## Damage got through to the player; the HUD names the source so a hit
## from out of sight is never a mystery.
signal hit_taken(damage: float, source_name: String)
## Presentation-only incoming bearing. Zero means no known planar source.
signal damage_bearing(damage: float, toward_source: Vector3)
## Known skills or the bar changed (page learned, slot assigned, game
## loaded); the action bar rebuilds itself from the sim.
signal loadout_changed
## Fire-setting (D-020): a skill worked the world ("cracked" or "heated"
## with a count) - the HUD tells you what the cold did to the rock.
signal world_worked(what: String, count: int)
## A link fired (D-023): skill_id cast itself because source_skill's
## trigger (freeze, ignite, bleed) landed on an enemy.
signal linked_cast(skill_id: StringName, trigger: String, source_skill: StringName)
## A real cooldown was spent (even a missed strike); presentation only.
signal skill_committed(skill_id: StringName)

## The four starting skills, named for tests and legacy callers. Everything
## else arrives as a skill page and is addressed through the bar (D-016).
const AREA_SKILL := &"prototype_area_strike"
const HEAVY_SKILL := &"prototype_heavy_strike"
const DASH_SKILL := &"prototype_dash"
const ORB_SKILL := &"prototype_frost_orb"

var player: WroughtwildPlayer
var sim: WroughtwildSim

var max_life := 1.0
var life := 1.0
var skills := {}     # skill id -> sim view (base_damage, cooldown_seconds, ...)
var cooldowns := {}  # skill id -> seconds remaining
var invulnerable_left := 0.0
var melee_reach := 2.0
## First-person area-strike arc (D-012): "area" is the slice of the horde
## you are facing, so training mobs into a bunch is what makes it pay.
var cone_degrees := 360.0
var dash_invulnerable := 0.3
var dash_duration := 0.25
var fight_active := false
## Seeds each fight's damage stream; tests set a fixed seed for replay.
var fight_seed_source := RandomNumberGenerator.new()
var last_hit_dealt := 0.0
var last_hit_taken := 0.0
## The Plate reading (D-023 slice 2): armour a cast granted and how long it
## has left. The sim says how much; this owns the clock.
var _cast_armour := 0.0
var _cast_armour_left := 0.0
## The Haste reading beside a Vanguard (D-023 slice 4): a burst of speed
## after a hit. The sim says how much; this owns the clock.
var _haste := 0.0
var _haste_left := 0.0
var _haste_seconds := 2.0

var _dash_left := 0.0
var _dash_velocity := Vector3.ZERO
## The Husk's Manner (a rail, D-023 slice 9): how long you have stood still.
var _still_seconds := 0.0


func setup(in_player: WroughtwildPlayer, in_sim: WroughtwildSim) -> void:
	player = in_player
	sim = in_sim
	for id in sim.combat_skill_ids():
		skills[id] = sim.combat_skill(id)
		cooldowns[id] = 0.0
	var rt: Dictionary = sim.realtime()
	melee_reach = rt["player"]["melee_reach_m"]
	cone_degrees = rt["player"].get("cone_degrees", 360.0)
	dash_invulnerable = rt["dash"]["invulnerable_seconds"]
	dash_duration = rt["dash"]["duration_seconds"]
	_haste_seconds = float(sim.foundry().get("haste_after_hit_seconds", 2.0))
	fight_seed_source.randomize()
	restore_life()


func restore_life() -> void:
	max_life = sim.derived_stats()["max_life"]
	life = max_life
	life_changed.emit(life, max_life)


## Gear or the Foundry changed: the maximum moves, current life keeps its
## share of it.
func refresh_stats() -> void:
	var fraction := life / maxf(max_life, 1.0)
	max_life = sim.derived_stats()["max_life"]
	life = clampf(fraction * max_life, 0.0, max_life)
	life_changed.emit(life, max_life)


## --- shelter regen (Wave 4 building slice 3) ---
## Resting in an enclosed room regenerates life once you have gone the
## settle time without a hit. The sim decides what a shelter is and how
## fast it heals (world.json shelter); this owns the clocks: probing the
## room once a second and paying the regen per frame.
signal shelter_changed(sheltered: bool)
const SHELTER_PROBE_SECONDS := 1.0
var sheltered := false
var _shelter_probe_left := 0.0
var _settle_left := 0.0
var _regen_per_second := 0.0
var _settle_seconds := 0.0
## Home: the last shelter rested in.
var has_home := false
var home_position := Vector3.ZERO
## The last shelter probe as the sim returned it ({enclosed, cells, reason,
## leak}), so build mode can mark where a room leaks.
var last_shelter: Dictionary = {}
## The night (Wave 6 slice 5): out in the open after dark the cold takes
## life down to a floor and no further; in a shelter the night mends you
## faster. The sim's day rules say how much; this pays them per frame.
const COMPASS := ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
var night := false
var day_phase := "day"
## True while the cold is taking life.
var exposed := false
var _exposure_per_second := 0.0
var _exposure_floor_fraction := 0.0
var _night_regen_multiplier := 1.0
## A fight is a beacon (Wave 7 slice 1): a hit landing either way is heard;
## at most once a second, so a flurry is one noise.
const FIGHT_NOISE_SECONDS := 1.0
var _fight_noise_left := 0.0
## The train (Wave 7 slice 2): bites from different mobs inside the sim's
## window stack. The sim says the window and the bonus; this remembers who
## bit when.
var _train_hits: Array = []
var _train_window := -1.0
var _fight_clock := 0.0
## The verbs suffered (Wave 8 slice 1): harried (slowed), rooted (held
## until a dash), marked (the hunters sprint at you). The enemy's numbers
## come from the sim; these are the clocks.
var _slow_left := 0.0
var _slow := 0.0
var _root_left := 0.0
var _marked_left := 0.0
var _mark_sprint := 1.0
var _root_said := -100000


func _tick_shelter(delta: float) -> void:
	_settle_left = maxf(0.0, _settle_left - delta)
	_shelter_probe_left -= delta
	if _shelter_probe_left <= 0.0:
		_shelter_probe_left = SHELTER_PROBE_SECONDS
		if _regen_per_second <= 0.0 and sim != null:
			var rules: Dictionary = sim.shelter()
			var round_seconds: float = sim.realtime().get("round_seconds", 1.0)
			_regen_per_second = float(rules.get("regen_life_per_round", 0.0)) / maxf(round_seconds, 0.01)
			_settle_seconds = float(rules.get("settle_rounds", 0.0)) * round_seconds
		set_sheltered(_probe_shelter())
		if sheltered:
			has_home = true
			home_position = get_parent().global_position
	if sheltered and _settle_left <= 0.0 and life > 0.0 and life < max_life:
		heal(regen_per_second() * delta)
	# The cold: at night, out in the open, life falls to the floor and stops.
	var floor_life := _exposure_floor_fraction * max_life
	var cold := night and not sheltered and life > floor_life and life > 0.0 and _exposure_per_second > 0.0
	if cold:
		life = maxf(floor_life, life - _exposure_per_second * delta)
		life_changed.emit(life, max_life)
	exposed = cold


func _probe_shelter() -> bool:
	var player := get_parent()
	if player == null or not (player is WroughtwildPlayer):
		return false
	last_shelter = (player as WroughtwildPlayer).placement.enclosure_at(player.global_position)
	return last_shelter.get("enclosed", false)


## One line for the HUD about the room you are in ("" when nothing to say).
func shelter_text() -> String:
	if sheltered or last_shelter.is_empty():
		return ""
	match String(last_shelter.get("reason", "")):
		"sky":
			return "open to the sky  ·  leak marked in build mode"
		"cap":
			return "too big to be a room (%d cells)" % int(last_shelter.get("cells", 0))
	return ""


func set_sheltered(value: bool) -> void:
	if value == sheltered:
		return
	sheltered = value
	shelter_changed.emit(sheltered)


## True while resting is actually paying out.
func resting() -> bool:
	return sheltered and _settle_left <= 0.0 and life < max_life


## How many other mouths bit inside the train window before this one.
func train_earlier_hits(source: Node) -> int:
	if _train_window < 0.0:
		_train_window = float(sim.train_rules().get("window_seconds", 0.0))
	var mine: int = source.get_instance_id() if source != null else 0
	var keep: Array = []
	var mouths := {}
	for hit in _train_hits:
		if _fight_clock - float(hit["at"]) <= _train_window:
			keep.append(hit)
			if int(hit["source"]) != mine:
				mouths[int(hit["source"])] = true
	_train_hits = keep
	return mouths.size()


## Forgets who bit (a scene change, a test that wants a clean bite).
func clear_train() -> void:
	_train_hits.clear()


## The multiplier a bite from this mob lands with right now.
func train_multiplier_for(source: Node) -> float:
	return sim.train_multiplier(train_earlier_hits(source))


## A hit landing is heard (Wave 7 slice 1), at most once a second.
func fight_noise(at: Vector3) -> void:
	if _fight_noise_left > 0.0:
		return
	_fight_noise_left = FIGHT_NOISE_SECONDS
	MobPacks.noise(get_tree(), at, "fight", sheltered)


## What resting pays per second: the shelter's rate, more through the night.
func regen_per_second() -> float:
	return _regen_per_second * (_night_regen_multiplier if night else 1.0)


## The hour and the day rules, from the sandpit each frame.
func set_day(day: Dictionary, rules: Dictionary) -> void:
	night = bool(day.get("night", false))
	day_phase = String(day.get("phase", "day"))
	_exposure_per_second = float(rules.get("exposure_life_per_second", 0.0))
	_exposure_floor_fraction = float(rules.get("exposure_floor_fraction", 0.0))
	_night_regen_multiplier = float(rules.get("shelter_night_regen_multiplier", 1.0))


## One line for the HUD about the dark ("" by day or under a roof): the
## cold's cost and the way home.
func night_text() -> String:
	if sheltered:
		return ""
	var home := home_text()
	var way := "  ·  home " + home if home != "" else ""
	if exposed:
		return "the cold bites -%.1f/s%s" % [_exposure_per_second, way]
	if night:
		return ("cold to the bone%s" if _exposure_per_second>0.0 else "night%s") % way
	if day_phase == "dusk":
		return "dusk%s" % way
	return ""


## "84 m NW" to the last shelter rested in ("" without one).
func home_text() -> String:
	if not has_home:
		return ""
	var to: Vector3 = home_position - (get_parent() as Node3D).global_position
	to.y = 0.0
	if to.length() < 6.0:
		return "right here"
	return "%d m %s" % [int(to.length()), compass(to)]


## Eight winds; -Z is north.
static func compass(to: Vector3) -> String:
	return COMPASS[wrapi(roundi(atan2(to.x, -to.z) / (TAU / 8.0)), 0, 8)]


func _physics_process(delta: float) -> void:
	for id in cooldowns:
		cooldowns[id] = maxf(0.0, cooldowns[id] - delta)
	invulnerable_left = maxf(0.0, invulnerable_left - delta)
	_fight_noise_left = maxf(0.0, _fight_noise_left - delta)
	_fight_clock += delta
	_slow_left = maxf(0.0, _slow_left - delta)
	_root_left = maxf(0.0, _root_left - delta)
	_marked_left = maxf(0.0, _marked_left - delta)
	_tick_shelter(delta)
	_dash_left = maxf(0.0, _dash_left - delta)
	_cast_armour_left = maxf(0.0, _cast_armour_left - delta)
	if _cast_armour_left <= 0.0:
		_cast_armour = 0.0
	_haste_left = maxf(0.0, _haste_left - delta)
	if _haste_left <= 0.0:
		_haste = 0.0
	# Stillness counted for the Husk's Manner; the first step resets it.
	var planar_speed: float = Vector2(player.velocity.x, player.velocity.z).length() if player != null else 0.0
	_still_seconds = _still_seconds + delta if planar_speed < 0.1 and _dash_left <= 0.0 else 0.0
	if fight_active and alive_enemies().is_empty():
		fight_active = false


func is_ready(skill_id: StringName) -> bool:
	return cooldowns.get(skill_id, 1.0) <= 0.0


func cooldown_left(skill_id: StringName) -> float:
	return cooldowns.get(skill_id, 0.0)


## Horizontal velocity the player should adopt while a dash is in progress.
func dash_velocity() -> Vector3:
	return _dash_velocity if _dash_left > 0.0 else Vector3.ZERO


func alive_enemies() -> Array:
	var alive: Array = []
	for node in player.get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(node) and node is Enemy and node.life > 0.0:
			alive.append(node)
	return alive


func _ensure_fight() -> void:
	if not fight_active:
		fight_active = true
		sim.begin_fight(int(fight_seed_source.randi() & 0x7fffffff))


func _planar_distance(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## The skill's cooldown after gear modifiers (the sim resolves it). The
## Dash's is divided further by the sheet's dash recovery (Fleet, D-023).
func cooldown_total(skill_id: StringName) -> float:
	if sim != null:
		var total: float = sim.skill_cooldown_seconds(String(skill_id))
		if String(skills.get(skill_id, {}).get("delivery", "")) == "dash":
			total /= 1.0 + float(sim.derived_stats().get("dash_recovery", 0.0))
		return total
	return skills.get(skill_id, {}).get("cooldown_seconds", 1.0)


func _spend(skill_id: StringName) -> void:
	_action_contexts[skill_id] = {"steam_used": false, "practice_allowed": _link_depth == 0, "practice_used": false}
	cooldowns[skill_id] = cooldown_total(skill_id)
	skill_committed.emit(skill_id)


## --- the skill bar (D-016) ---------------------------------------------------
## Skills are learned, not worn: the sim owns which are known and which sit
## on the four bar slots; the keys 1-4 cast whatever sits there, dispatched
## by the skill's delivery shape.

func bar_skills() -> PackedStringArray:
	return sim.skill_bar()


## Casts whatever sits in bar slot `slot` (0-based). False for an empty
## slot, an unknown skill or one still on cooldown.
func use_slot(slot: int) -> bool:
	var bar := sim.skill_bar()
	if slot < 0 or slot >= bar.size() or bar[slot] == "":
		return false
	return use_skill(StringName(bar[slot]))


## The bar slot holding a dash-delivery skill, or -1: Shift is an alias for
## it, so movement keeps its reflex key wherever Dash is slotted.
func dash_slot() -> int:
	var bar := sim.skill_bar()
	for i in bar.size():
		if skills.get(StringName(bar[i]), {}).get("delivery", "") == "dash":
			return i
	return -1


## Casts one skill by id, dispatching on its delivery. The sim owns every
## number; each delivery shape owns its space (ADR-0003).
func use_skill(skill_id: StringName) -> bool:
	var def: Dictionary = skills.get(skill_id, {})
	if def.is_empty() or not is_ready(skill_id):
		return false
	var origin := player.global_position+Vector3.UP*.5
	var fired := _cast(skill_id, def)
	if fired:
		FoundryCold.cast(self,skill_id,origin)
		_brace(skill_id)
		_echo(skill_id, def)
	return fired


## One delivery of the skill, whatever its shape.
func _cast(skill_id: StringName, def: Dictionary) -> bool:
	var origin := player.global_position + Vector3.UP * 0.12
	var fired := _deliver(skill_id, def)
	if fired:
		var form := mutation(skill_id)
		if float(form.get("zone_armour", 0)) > 0 or float(form.get("ward_charges", 0)) > 0:
			FoundryField.spawn(self, skill_id, origin, "guard", form)
		if float(form.get("trail_fraction", 0)) > 0:
			FoundryField.spawn(self, skill_id, origin, "trail", form)
		if String(def.get("delivery", "")) in ["strike", "cone"] and float(form.get("wave", 0)) <= 0:
			mutation_impact(skill_id, origin - player.global_basis.z * minf(strike_reach(skill_id), 1.5))
	return fired


func _deliver(skill_id: StringName, def: Dictionary) -> bool:
	var delivery := String(def.get("delivery", ""))
	if delivery in ["strike", "cone"] and float(mutation(skill_id).get("wave", 0)) > 0:
		return _use_projectile(skill_id)
	if delivery == "cone":
		_use_cone(skill_id)
		return true
	if delivery == "strike":
		return _use_strike(skill_id)
	if delivery == "projectile":
		return _use_projectile(skill_id)
	if delivery == "ground":
		return _use_ground(skill_id)
	if delivery == "dash":
		return _use_dash(skill_id)
	return false


## Echo (a form, D-023): every nth cast of a skill repeats itself, free of
## the cooldown. The sim says n; this counts the casts.
var _casts := {}


func _echo(skill_id: StringName, def: Dictionary) -> void:
	var every: int = sim.skill_echo_every(String(skill_id))
	if every <= 0:
		return
	_casts[skill_id] = int(_casts.get(skill_id, 0)) + 1
	if int(_casts[skill_id]) % every != 0:
		return
	var seconds := float(mutation(skill_id).get("echo_delay", 0))
	if seconds > 0:
		# A node-owned timer is cancelled by death/load along with other effects.
		var echo := FoundryEcho.new()
		echo.combat = self
		echo.skill_id = skill_id
		echo.remaining = seconds
		echo.definition = def
		player.world_root().add_child(echo)
	else:
		repeat_skill(skill_id, def)


## The Plate reading: casting a skill it supports grants armour for a
## moment. The larger grant wins; the clock refreshes.
func _brace(skill_id: StringName) -> void:
	var grant: Dictionary = sim.skill_cast_armour(String(skill_id))
	var armour: float = grant.get("armour", 0.0)
	if armour <= 0.0:
		return
	_cast_armour = maxf(_cast_armour, armour)
	_cast_armour_left = maxf(_cast_armour_left, float(grant.get("seconds", 0.0)))


## Armour a cast is granting right now; counted with the sheet's when a
## hit lands.
func cast_armour() -> float:
	var zone := 0.0
	for field in get_tree().get_nodes_in_group("foundry_fields"):
		if field.combat == self and field.covers(player.global_position + Vector3.UP * 0.5): zone = maxf(zone, field.armour)
	return (_cast_armour if _cast_armour_left > 0.0 else 0.0) + zone


## The Husk's Manner (a rail, D-023 slice 9): the sheet's still armour once
## you have stood a second, gone on the first step.
func still_armour() -> float:
	return float(sim.derived_stats().get("still_armour", 0.0)) if _still_seconds >= 1.0 else 0.0


## What your walking speed is multiplied by right now (the Haste reading
## beside a Vanguard, after a hit).
func haste_multiplier() -> float:
	var haste := 1.0 + _haste if _haste_left > 0.0 else 1.0
	return haste * (1.0 - _slow if _slow_left > 0.0 else 1.0)


## --- the verbs suffered (Wave 8 slice 1) ---
func _suffer_verb(enemy: Enemy) -> void:
	if FoundryEmber.prevent(self,enemy.verb): return
	match enemy.verb:
		"harry":
			_slow_left = maxf(_slow_left, enemy.verb_seconds)
			_slow = clampf(enemy.verb_strength, 0.0, 0.9)
		"root":
			_root_left = maxf(_root_left, enemy.verb_seconds)
			var now := Time.get_ticks_msec()
			if now - _root_said > 6000 and player != null and player.hud != null:
				_root_said = now
				player.hud.notify("Rooted! Dash to break free.")
		"mark":
			_marked_left = maxf(_marked_left, enemy.verb_seconds)
			_mark_sprint = maxf(1.0, enemy.verb_strength)


func harried() -> bool:
	return _slow_left > 0.0


func rooted() -> bool:
	return _root_left > 0.0


func marked() -> bool:
	return _marked_left > 0.0


## What the hunters run at while you are marked (1 when you are not).
func marked_sprint() -> float:
	return _mark_sprint if _marked_left > 0.0 else 1.0


## A dash breaks a root.
func break_root() -> void:
	_root_left = 0.0


func clear_verbs() -> void:
	_slow_left = 0.0
	_root_left = 0.0
	_marked_left = 0.0


## One line for the HUD about the verbs on you ("" when none).
func verb_text() -> String:
	var parts := PackedStringArray()
	if FoundryEmber.active(self,"temper") != null: parts.append("Furnace Plate ready")
	if FoundryEmber.active(self,"cautery") != null: parts.append("Cautery ward ready")
	if FoundryCold.live(self,"skin") != null: parts.append("Cold Sap ready")
	if FoundryCold.live(self,"tempo") != null: parts.append("Lingering Step: switch skills")
	if rooted():
		parts.append("rooted, dash breaks it")
	if harried():
		parts.append("harried, slowed")
	if marked():
		parts.append("marked, they sprint at you")
	return "  ·  ".join(parts)


## The Vanguard's answers to a hit (D-023 slice 4): Barbs bleed the
## striker and, with Answer Reach, every enemy near you; Haste quickens
## you for a moment. The sim says the numbers; this finds who and runs
## the clock.
func _answer_hit(source: Node) -> void:
	var ds: Dictionary = sim.derived_stats()
	# Riposte (a rail, D-023 slice 9): the Barbs bleed for more and stagger.
	var barbs: float = float(ds.get("barbs", 0.0)) * (1.0 + float(ds.get("barbs_more", 0.0)))
	if barbs > 0.0 and source is Enemy:
		(source as Enemy).apply_bleed(barbs)
		(source as Enemy).stagger(float(ds.get("barbs_stagger", 0.0)))
		var reach: float = float(ds.get("answer_reach_m", 0.0))
		if reach > 0.0:
			for enemy in alive_enemies():
				if enemy != source and _planar_distance(enemy.global_position, player.global_position) <= reach:
					enemy.apply_bleed(barbs)
	var haste: float = float(ds.get("haste_after_hit", 0.0))
	if haste > 0.0:
		_haste = maxf(_haste, haste)
		_haste_left = _haste_seconds


## Life restored from any source: kills, hits, the Dash, the shelter. The
## sheet's heal_more (Lifeline, D-023) amplifies every one.
func heal(amount: float) -> void:
	if amount <= 0.0 or life <= 0.0:
		return
	amount *= 1.0 + float(sim.derived_stats().get("heal_more", 0.0))
	life = minf(max_life, life + amount)
	life_changed.emit(life, max_life)


## What a kill with a skill pays back: life (the Vigour reading and the
## Marrow's forms), a cooldown refund and a burst of speed (the
## Quicksilver's forms).
func _reap(skill_id: StringName, kills: int) -> void:
	if kills <= 0:
		return
	var id := String(skill_id)
	heal(kills * sim.skill_life_on_kill(id))
	var refund: float = sim.skill_refund_on_kill(id)
	if refund > 0.0:
		cooldowns[skill_id] = float(cooldowns.get(skill_id, 0.0)) * (1.0 - refund)
	var quicken: float = sim.skill_haste_on_kill(id)
	if quicken > 0.0:
		_haste = maxf(_haste, quicken)
		_haste_left = _haste_seconds


## Deals one hit of skill_id to enemy as the sim's typed packets (D-023
## slice 2), each scaled by `fraction` (a fork generation), each refused by
## a mob immune to its type. Returns {damage, kill, types}: what landed.
func deal(enemy: Enemy, skill_id: StringName, isolated: bool, fraction := 1.0, secondary := false, context: Dictionary = {}) -> Dictionary:
	var live_hostile := enemy.life > 0 and not enemy.flees
	var landed := 0.0
	var types := PackedStringArray()
	# The Hound's Manner (a rail, D-023 slice 9): an enemy moving toward
	# you takes more. The sim says how much; this reads where it is going.
	# The guard and the ward (Wave 8 slice 1): a husk's front takes less
	# from where you stand; a mob beside a standing knight takes less.
	if enemy.guards_against(player.global_position):
		fraction *= 1.0 - enemy.verb_strength
	var warden: Enemy = enemy.warded_by()
	if warden != null:
		fraction *= 1.0 - warden.verb_strength
	var approaching: float = float(sim.derived_stats().get("damage_vs_approaching", 0.0))
	if approaching > 0.0 and enemy.approaching(player.global_position):
		fraction *= 1.0 + approaching
	for packet in sim.player_hit(String(skill_id), isolated, enemy.carried_statuses()):
		var taken: float = enemy.take_typed(float(packet["damage"]) * fraction, String(packet["type"]))
		if taken > 0.0:
			landed += taken
			types.append(String(packet["type"]))
	# Brittle (a form): a frozen, bleeding enemy shatters from this hit,
	# though the skill would never shatter on its own.
	if not secondary and enemy.life > 0.0 and enemy.is_frozen() and enemy.bleeding_left > 0.0 and sim.skill_brittle(String(skill_id)):
		var cascade := _shatter_cascade([enemy], sim.shatter_rules(), sim.skill_nova_chill(String(skill_id)))
		landed += cascade["damage"]
		if not types.has(String(sim.shatter_rules().get("nova_damage_type", "cold"))):
			types.append(String(sim.shatter_rules().get("nova_damage_type", "cold")))
	if landed > 0 and live_hostile and not secondary: practice_contact(skill_id, context)
	last_hit_dealt = landed
	# Life on hit (the Marrow's forms): a hit that lands drinks.
	if landed > 0.0:
		heal(sim.skill_life_on_hit(String(skill_id)))
		fight_noise(enemy.global_position)
		if not secondary and float(mutation(skill_id).get("siphon", 0)) > 0:
			FoundryReturn.launch(self, enemy.global_position + Vector3.UP * 0.6, mutation(skill_id))
	var kill := enemy.life <= 0.0
	if kill:
		_reap(skill_id, 1)
		if not secondary and landed>0: FoundryCold.killed(self,enemy,skill_id)
		if not secondary and float(mutation(skill_id).get("recovery_on_kill", 0)) > 0:
			FoundryField.spawn(self, skill_id, enemy.global_position + Vector3.UP * 0.12, "recovery", mutation(skill_id))
	return {"damage": landed, "kill": kill, "types": types}


## Mastery (D-019): the sim counts casts that fired; a perk that unlocks
## is announced and changes this skill's numbers from now on.
func practice_contact(skill_id: StringName, context: Dictionary = {}) -> void:
	var cast: Dictionary = action_context(skill_id) if context.is_empty() else context
	if not bool(cast.get("practice_allowed", false)) or bool(cast.get("practice_used", false)): return
	cast["practice_used"] = true
	_note_use(skill_id)


func _note_use(skill_id: StringName) -> void:
	for text in sim.note_skill_use(String(skill_id)):
		if player != null and player.hud != null:
			player.hud.notify("Mastery: %s - %s." % [skills[skill_id].get("display_name", String(skill_id)), text])


## Bar assignment and page learning route through here so the HUD hears
## about it (loadout_changed).
func assign_bar_slot(slot: int, skill_id: String) -> bool:
	if not sim.set_bar_slot(slot, skill_id):
		return false
	loadout_changed.emit()
	return true


func learn_skill(skill_id: String) -> bool:
	if not sim.learn_skill(skill_id):
		return false
	loadout_changed.emit()
	return true


## Named wrappers for the starting four (tests, legacy callers).
func use_area() -> int:
	return _use_cone(AREA_SKILL)


func use_heavy() -> bool:
	return _use_strike(HEAVY_SKILL)


func use_orb() -> bool:
	return _use_projectile(ORB_SKILL)


func use_dash() -> bool:
	return _use_dash(DASH_SKILL)


## Applies the skill's status payload to a struck enemy. Skills without a
## payload apply 0s; a matching add_*_buildup gear roll can still give them
## one (a Frostbite mace chills with plain strikes). Payload lands before
## the damage so a killing blow that ignites leaves a burning corpse for
## proliferate.
## Returns the triggers this payload crossed on the enemy (freeze, ignite,
## bleed), for the links.
func apply_payload(enemy: Enemy, skill_id: StringName, is_boss: bool, fraction := 1.0, secondary := false, context := {}) -> PackedStringArray:
	var status_before := Vector3(enemy.chill, enemy.ignite, enemy.bleed)
	var live_hostile := enemy.life > 0 and not enemy.flees
	var id := String(skill_id)
	var form := mutation(skill_id)
	if not secondary:
		FoundryReactions.contact(self, enemy, skill_id, form, action_context(skill_id) if context.is_empty() else context)
	if enemy.life <= 0: return PackedStringArray()
	var was_frozen := enemy.is_frozen()
	var was_burning := enemy.burning_left > 0.0
	var was_bleeding := enemy.bleeding_left > 0.0
	# Quench and Sear (forms, D-023) ride with the status they belong to:
	# the mob keeps them for the freeze and the burn this skill causes.
	enemy.apply_chill(sim.chill_applied(id, is_boss) * fraction, sim.skill_quenches(id))
	# Pyre (a rail, D-023 slice 9): an ignite this hit lights spreads at once.
	var spread := maxf(float(sim.derived_stats().get("proliferate_on_hit", 0)), float(form.get("ignite_spread", 0)))
	enemy.apply_ignite(sim.ignite_applied(id, is_boss) * fraction, sim.skill_sear(id), spread, form)
	enemy.apply_bleed(sim.bleed_applied(id, is_boss) * fraction)
	var crossed := PackedStringArray()
	if not was_frozen and enemy.is_frozen():
		crossed.append("freeze")
	if not was_burning and enemy.burning_left > 0.0:
		crossed.append("ignite")
		if not secondary: FoundryReactions.ignited(self, enemy, form)
	if not was_bleeding and enemy.bleeding_left > 0.0:
		crossed.append("bleed")
	if not secondary and live_hostile and (not crossed.is_empty() or status_before != Vector3(enemy.chill, enemy.ignite, enemy.bleed)):
		practice_contact(skill_id, context)
	return crossed


## Links (D-023): when a skill's trigger lands on an enemy, every skill
## linked to it on the plate casts itself at that enemy, with its own
## cooldown, on or off the bar. A linked cast never fires another link.
var _link_depth := 0


func fire_links(skill_id: StringName, crossed: PackedStringArray, enemy: Enemy) -> void:
	if _link_depth > 0 or crossed.is_empty() or sim == null:
		return
	for trigger in crossed:
		for other in sim.linked_casts(String(skill_id), trigger):
			_cast_linked(StringName(other), String(trigger), skill_id, enemy)


func _cast_linked(skill_id: StringName, trigger: String, source_skill: StringName, enemy: Enemy) -> void:
	var def: Dictionary = skills.get(skill_id, {})
	if def.is_empty() or not is_ready(skill_id):
		return
	_link_depth += 1
	var fired := false
	if (String(def.get("delivery", "")) == "projectile" or (String(def.get("delivery", "")) in ["strike", "cone"] and float(mutation(skill_id).get("wave", 0)) > 0)) and is_instance_valid(enemy):
		# A linked projectile flies at the enemy the trigger landed on.
		_spend(skill_id)
		_ensure_fight()
		var from: Vector3 = player.camera.global_position - player.camera.global_transform.basis.z * 0.6
		var dir: Vector3 = (enemy.global_position + Vector3(0, 0.5, 0) - from).normalized()
		_launch_fan(skill_id, from, dir)
		fired = true
	elif String(def.get("delivery", "")) == "ground" and is_instance_valid(enemy):
		fired = _use_ground(skill_id, enemy.global_position)
	else:
		fired = _cast(skill_id, def)
	_link_depth -= 1
	if fired:
		linked_cast.emit(skill_id, trigger, source_skill)
		if player != null and player.hud != null:
			player.hud.notify("%s casts itself: %s's %s." % [skills[skill_id].get("display_name", String(skill_id)),
				skills[source_skill].get("display_name", String(source_skill)), trigger])


## Cone delivery: every living enemy inside the radius AND inside the arc
## takes one hit (D-012: area is the slice of the horde you are facing).
## A per-skill cone_degrees in combat_realtime.json overrides the player's
## first-person arc - 360 turns the cone into a nova ring. Returns hits.
func _use_cone(skill_id: StringName) -> int:
	if not is_ready(skill_id):
		return 0
	_spend(skill_id)
	var enemies := alive_enemies()
	# Area size on the sheet scales every area; reach (D-023) widens this skill alone.
	var base_radius: float = skills[skill_id]["base_area_radius"] * (1.0 + sim.derived_stats()["area_bonus"]) \
		* sim.skill_reach(String(skill_id))
	# A cold ring quenches the hot rock around you whether or not anything
	# is alive in it (D-020 fire-setting: the nova is a quarry tool too).
	if sim.chill_applied(String(skill_id), false) > 0.0:
		var terrain := player._find_terrain()
		if terrain != null and not terrain.map.is_empty():
			var cracked_count: int = terrain.quench_at(player.global_position, base_radius)
			if cracked_count > 0:
				world_worked.emit("cracked", cracked_count)
	if enemies.is_empty():
		return 0
	_ensure_fight()
	var isolated := enemies.size() == 1
	var radius := base_radius
	if isolated:
		radius *= sim.combat_mods()["isolated_area_multiplier"]
	var spatial: Dictionary = sim.realtime().get("skills", {}).get(String(skill_id), {})
	var arc: float = spatial.get("cone_degrees", cone_degrees)
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var cone_cos := cos(deg_to_rad(arc / 2.0))
	var hits := 0
	var kills := 0
	var total := 0.0
	var types := PackedStringArray()
	var to_shatter: Array = []
	var shatter: Dictionary = sim.shatter_for(String(skill_id))
	for enemy in enemies:
		var to_enemy: Vector3 = enemy.global_position - player.global_position
		to_enemy.y = 0.0
		var distance := to_enemy.length()
		if distance > radius:
			continue
		# Point-blank targets always count; beyond that, the arc decides.
		if distance > 0.6 and forward.dot(to_enemy / distance) < cone_cos:
			continue
		# The shatter hook: frozen enemies hit by a trigger skill shatter
		# instead of taking the ordinary hit.
		if shatter.get("enabled", false) and enemy.is_frozen():
			if not enemy.flees: practice_contact(skill_id)
			to_shatter.append(enemy)
			hits += 1
			continue
		var crossed := apply_payload(enemy, skill_id, enemy is Boss)
		var landed := deal(enemy, skill_id, isolated)
		total += landed["damage"]
		if landed["kill"]:
			kills += 1
		for type in landed["types"]:
			if not types.has(type):
				types.append(type)
		fire_links(skill_id, crossed, enemy)
		_space_control(enemy, skill_id, to_enemy / maxf(distance, 0.001))
		hits += 1

	var cascade := _shatter_cascade(to_shatter, shatter, sim.skill_nova_chill(String(skill_id)))
	total += cascade["damage"]
	kills += cascade["kills"]
	_reap(skill_id, cascade["kills"])
	if cascade["damage"] > 0.0 and not types.has(String(shatter.get("nova_damage_type", "cold"))):
		types.append(String(shatter.get("nova_damage_type", "cold")))
	if hits > 0:
		hit_landed.emit(total, kills, types)
	return hits


## Strike delivery: the nearest living enemy in front within melee reach,
## or, with Arc (a form, D-023), every enemy within reach and the arc's
## width either side of the line.
func _use_strike(skill_id: StringName) -> bool:
	if not is_ready(skill_id):
		return false
	_spend(skill_id)
	# Reach (D-023): a Reach ingot beside the skill's socket lengthens the strike.
	var reach := strike_reach(skill_id)
	var arc: float = sim.skill_arc(String(skill_id))
	var targets: Array = _enemies_in_front(reach, arc) if arc > 0.0 else []
	if arc<=0.0 and targets.is_empty():
		var nearest := _nearest_enemy_in_front(reach)
		if nearest != null:
			targets = [nearest]
	if targets.is_empty():
		# No enemy: the blow lands on whatever is in front (D-021).
		return player.strike_world()
	_ensure_fight()
	# An attack on a frozen target cashes in the shatter combo instead.
	var shatter: Dictionary = sim.shatter_for(String(skill_id))
	var total := 0.0
	var kills := 0
	var types := PackedStringArray()
	var to_shatter: Array = []
	for enemy in targets:
		if shatter.get("enabled", false) and enemy.is_frozen():
			if not enemy.flees: practice_contact(skill_id)
			to_shatter.append(enemy)
			continue
		var crossed := apply_payload(enemy, skill_id, enemy is Boss)
		var landed := deal(enemy, skill_id, alive_enemies().size() == 1)
		total += landed["damage"]
		if landed["kill"]:
			kills += 1
		for type in landed["types"]:
			if not types.has(type):
				types.append(type)
		fire_links(skill_id, crossed, enemy)
		_space_control(enemy, skill_id, -player.global_transform.basis.z)
	var cascade := _shatter_cascade(to_shatter, shatter, sim.skill_nova_chill(String(skill_id)))
	total += cascade["damage"]
	kills += cascade["kills"]
	_reap(skill_id, cascade["kills"])
	if cascade["damage"] > 0.0 and not types.has(String(shatter.get("nova_damage_type", "cold"))):
		types.append(String(shatter.get("nova_damage_type", "cold")))
	hit_landed.emit(total, kills, types)
	return true


## Melee's space control (Wave 5 item 11): the mob a blow lands on halts
## for the skill's stagger and is shoved its push along the blow. The sim
## says both numbers, a boss its fractions; this halts and shoves.
func _space_control(enemy: Enemy, skill_id: StringName, along: Vector3) -> void:
	if not is_instance_valid(enemy) or enemy.life <= 0.0:
		return
	var id := String(skill_id)
	enemy.stagger(sim.skill_stagger(id, enemy is Boss))
	enemy.shove(along, sim.skill_push(id, enemy is Boss))


## Every living enemy in front within `reach` and no more than `half_width`
## either side of the facing line: the Arc's sweep.
func _enemies_in_front(reach: float, half_width: float) -> Array:
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var found: Array = []
	for enemy in alive_enemies():
		var to_enemy: Vector3 = enemy.global_position - player.global_position
		to_enemy.y = 0.0
		var distance := to_enemy.length()
		if distance > reach or distance < 0.001:
			continue
		var along := forward.dot(to_enemy)
		if along <= 0.0:
			continue
		var aside := (to_enemy - forward * along).length()
		if aside <= half_width:
			found.append(enemy)
	return found


## Projectile delivery: fires from the eyes so first-person aim is the
## delivery; flight, forks and payload live in SkillProjectile.
func _use_projectile(skill_id: StringName) -> bool:
	if not is_ready(skill_id):
		return false
	_spend(skill_id)
	_ensure_fight()
	var from: Vector3 = player.camera.global_position - player.camera.global_transform.basis.z * 0.6
	var dir: Vector3 = -player.camera.global_transform.basis.z
	# Volley (a rail, D-023 slice 9): the sim says how many projectiles a
	# cast fires; they fan out ten degrees apart around the aim.
	_launch_fan(skill_id, from, dir)
	return true


func _launch_fan(skill_id: StringName, from: Vector3, dir: Vector3) -> void:
	var spatial: Dictionary = sim.realtime().get("skills",{}).get(String(skill_id),{})
	var count: int = sim.skill_projectiles(String(skill_id))
	var shared: Array = []
	for i in count:
		var yaw := deg_to_rad(float(spatial.get("fan_degrees",10.0))) * (float(i)-float(count-1)/2.0)
		var visited: Array = shared if float(spatial.get("shared_hits",0))>0 else []
		SkillProjectile.launch(skill_id,self,player.world_root(),from,dir.rotated(Vector3.UP,yaw),0,visited)


func strike_reach(skill_id: StringName) -> float:
	var spatial: Dictionary = sim.realtime().get("skills",{}).get(String(skill_id),{})
	return float(spatial.get("melee_reach_m",melee_reach))*sim.skill_reach(String(skill_id))


func area_radius(skill_id: StringName) -> float:
	var radius: float = maxf(float(skills[skill_id].get("base_area_radius",0.0)), float(mutation(skill_id).get("impact_radius",0))) * (1.0+float(sim.derived_stats()["area_bonus"])) * sim.skill_reach(String(skill_id))
	if alive_enemies().size()==1:
		radius *= float(sim.combat_mods()["isolated_area_multiplier"])
	return radius


## A ground cast needs a visible solid surface. The cooldown is spent only
## once targeting and the live-effect budget accept it. The mark is fixed.
func _use_ground(skill_id: StringName, linked_target := Vector3.INF) -> bool:
	if not is_ready(skill_id): return false
	var spatial: Dictionary = sim.realtime().get("skills",{}).get(String(skill_id),{})
	if not SkillBurst.has_room(self,int(spatial.get("max_live_bursts",12))): return false
	var origin := player.camera.global_position
	var maximum := float(spatial.get("max_range_m",14.0))*sim.skill_reach(String(skill_id))
	var end := origin-player.camera.global_basis.z*maximum
	if linked_target!=Vector3.INF:
		# The linked target is a position at trigger time, never a tracked mob.
		var toward := linked_target-origin
		end = origin+toward.limit_length(maximum)
	var hit := SkillBurst.solid_ray(self,origin,end)
	if hit.is_empty() and linked_target!=Vector3.INF and origin.distance_to(linked_target)<=maximum:
		hit = SkillBurst.solid_ray(self,linked_target+Vector3.UP*0.5,linked_target+Vector3.DOWN*2)
	if hit.is_empty():
		if player.hud!=null: player.hud.notify("Aim at a surface within %.0f metres." % maximum)
		return false
	_spend(skill_id)
	_ensure_fight()
	SkillBurst.mark(self,skill_id,hit.position+hit.normal*float(spatial.get("surface_offset_m",0.08)),hit.normal,float(spatial.get("delay_seconds",0)))
	return true


## Dash delivery: a burst forward. Pure movement (D-012) - position, not
## i-frames, is the defence.
func _use_dash(skill_id: StringName) -> bool:
	if not is_ready(skill_id):
		return false
	_spend(skill_id)
	for enemy in alive_enemies():
		if not enemy.flees and enemy.state in ["chase", "windup"] and enemy._horizontal_distance_to(player) <= enemy.give_up_distance and enemy._vertical_gap_to(player) <= enemy.vertical_reach:
			practice_contact(skill_id)
			break
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	# The Quicksilver's Dash forms (D-023 slice 8) live on the sheet: extra
	# reach, life restored, armour granted for a moment.
	var ds: Dictionary = sim.derived_stats()
	var distance: float = float(skills[skill_id].get("distance", 4.0)) + float(ds.get("dash_reach_m", 0.0))
	_dash_velocity = forward * (distance / dash_duration)
	_dash_left = dash_duration
	invulnerable_left = dash_invulnerable
	heal(float(ds.get("life_on_dash", 0.0)))
	var braced: float = float(ds.get("armour_on_dash", 0.0))
	if braced > 0.0:
		_cast_armour = maxf(_cast_armour, braced)
		_cast_armour_left = maxf(_cast_armour_left, float(sim.skill_cast_armour(String(skill_id)).get("seconds", 2.0)))
	return true


## Shatter cascade: each shattered mob dies releasing a cold nova; other
## FROZEN mobs inside the nova shatter too, so a frozen train chains down
## its own line. Every mob shatters at most once. A frozen boss takes the
## nova and thaws instead of dying, unless executes_boss is tuned on - the
## freeze window is the reward, not a one-shot.
func _shatter_cascade(to_shatter: Array, shatter: Dictionary, nova_chill := 0.0) -> Dictionary:
	var total := 0.0
	var kills := 0
	var shattered := {}
	# The nova is typed like any packet: a mob immune to cold shrugs it off.
	# nova_chill (Rime, a form): the nova chills the mobs it reaches.
	var nova_type := String(shatter.get("nova_damage_type", "cold"))
	while not to_shatter.is_empty():
		var victim: Enemy = to_shatter.pop_front()
		if not is_instance_valid(victim) or shattered.has(victim.get_instance_id()):
			continue
		shattered[victim.get_instance_id()] = true
		var at: Vector3 = victim.global_position
		_spawn_nova(at, shatter["nova_radius_m"])
		var executes: bool = shatter.get("executes_frozen", true) \
			and (shatter.get("executes_boss", false) or not (victim is Boss))
		if executes:
			total += victim.life
			victim.take_damage(victim.life)
			kills += 1
		else:
			victim.thaw()
			total += victim.take_typed(shatter["nova_damage"], nova_type)
			if victim.life <= 0.0:
				kills += 1
		for other in alive_enemies():
			if shattered.has(other.get_instance_id()) or to_shatter.has(other):
				continue
			if _planar_distance(other.global_position, at) > shatter["nova_radius_m"]:
				continue
			if other.is_frozen():
				to_shatter.append(other)
			else:
				total += other.take_typed(shatter["nova_damage"], nova_type)
				if nova_chill > 0.0:
					other.apply_chill(nova_chill)
				if other.life <= 0.0:
					kills += 1
	return {"damage": total, "kills": kills}


## A brief expanding ice sphere where a mob shattered (greybox VFX).
func _spawn_nova(at: Vector3, radius: float) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(0.6, 0.85, 1.0, 0.55)
	material.emission_enabled = true
	material.emission = Color(0.6, 0.85, 1.0)
	sphere.material = material
	mesh.mesh = sphere
	player.world_root().add_child(mesh)
	mesh.global_position = at + Vector3(0, 0.5, 0)
	var tween := mesh.create_tween()
	tween.tween_property(mesh, "scale", Vector3.ONE * radius * 2.0, 0.22)
	tween.parallel().tween_property(mesh, "transparency", 1.0, 0.22)
	tween.tween_callback(mesh.queue_free)


func _nearest_enemy_in_front(reach: float) -> Enemy:
	var forward := -player.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var best: Enemy = null
	var best_distance := INF
	for enemy in alive_enemies():
		var to_enemy: Vector3 = enemy.global_position - player.global_position
		to_enemy.y = 0.0
		var distance := to_enemy.length()
		if distance > reach or distance < 0.001:
			continue
		if forward.dot(to_enemy / distance) < 0.2:
			continue
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


## An enemy's raw hit arrives here; the sim decides what gets through. The
## source, when it is a mob, brings the statuses it carries for the Ward
## reading, and the armour a cast granted counts with the sheet's (D-023
## slice 2).
func take_hit(raw_damage: float, damage_type: String, source_name := "", source: Node = null, incoming_direction := Vector3.ZERO) -> float:
	if invulnerable_left > 0.0 or life <= 0.0:
		return 0.0
	_ensure_fight()
	var warded := raw_damage
	if source is Enemy:
		warded *= sim.ward_multiplier((source as Enemy).carried_statuses())
	# The train: other mouths that bit inside the window make this one worse.
	var train := train_multiplier_for(source)
	warded *= train
	last_hit_taken = sim.enemy_hit_damage(warded, damage_type, cast_armour() + still_armour())
	if source is Enemy: last_hit_taken=FoundryCold.absorb(self,last_hit_taken)
	_train_hits.append({"at": _fight_clock, "source": source.get_instance_id() if source != null else 0})
	life = maxf(0.0, life - last_hit_taken)
	_settle_left = _settle_seconds
	life_changed.emit(life, max_life)
	hit_taken.emit(last_hit_taken, source_name + ("  ·  the train x%.1f" % train if train > 1.0 else ""))
	if last_hit_taken > 0.0:
		var bearing: Vector3 = incoming_direction
		if bearing.is_zero_approx() and source is Node3D:
			bearing = source.global_position - player.global_position
		damage_bearing.emit(last_hit_taken, bearing)
		if source is Enemy: FoundryEmber.retaliate(self)
	_answer_hit(source)
	fight_noise(get_parent().global_position)
	if source is Enemy:
		_suffer_verb(source as Enemy)
	if life <= 0.0:
		died.emit()
	return last_hit_taken


var _mutation_frame := -1
var _mutation_cache := {}

func mutation(skill_id: StringName) -> Dictionary:
	var frame := Engine.get_physics_frames()
	if frame != _mutation_frame:
		_mutation_cache.clear()
		_mutation_frame = frame
	if not _mutation_cache.has(skill_id): _mutation_cache[skill_id] = sim.skill_mutation(String(skill_id))
	return _mutation_cache[skill_id]

func mutation_radius(skill_id: StringName, base: float) -> float:
	return base * (1.0 + float(sim.derived_stats().get("area_bonus", 0))) * sim.skill_reach(String(skill_id))

var _action_contexts := {}
var _reaction_ready := {}

func action_context(skill_id: StringName) -> Dictionary:
	if not _action_contexts.has(skill_id): _action_contexts[skill_id] = {"steam_used": false, "practice_allowed": false, "practice_used": false}
	return _action_contexts[skill_id]

func reaction_ready(key: String, seconds: float) -> bool:
	if _fight_clock < float(_reaction_ready.get(key, -1)): return false
	_reaction_ready[key] = _fight_clock + seconds
	return true

func mutation_impact(skill_id: StringName, at: Vector3, form := {}) -> void:
	var resolved: Dictionary = mutation(skill_id) if form.is_empty() else form
	if float(resolved.get("field_fraction", 0)) > 0:
		FoundryField.spawn(self, skill_id, at, "impact", resolved)

func repeat_skill(skill_id: StringName, def: Dictionary) -> void:
	# Repetition does not spend or reset the real skill's remaining cooldown,
	# count mastery, create another echo, or trigger another linked cast.
	if life <= 0: return
	var cooldown := float(cooldowns.get(skill_id, 0))
	cooldowns[skill_id] = 0.0
	_link_depth += 1
	_cast(skill_id, def)
	_link_depth -= 1
	cooldowns[skill_id] = cooldown
