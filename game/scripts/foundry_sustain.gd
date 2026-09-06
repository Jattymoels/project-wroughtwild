class_name FoundrySustain
extends Node3D
## Sixteen terminal sustain opportunities. Native form values own the budgets;
## this node owns their physical conditions and once-only collection clocks.
const ROLES := ["phoenix", "winterroot", "bloodroot", "harvest", "spring", "ironroot", "harbour", "fleet", "cinder", "cold_sip", "bloodletter", "long_drink", "deep_drink", "iron_drink", "ward_sip", "quick_sip"]
const CONTACT_ROLES := ["winterroot", "bloodroot", "spring", "ironroot", "cinder", "cold_sip", "bloodletter", "long_drink", "deep_drink", "ward_sip", "quick_sip"]
var combat: PlayerCombat
var skill_id: StringName
var mode := ""
var rules: Dictionary
var target: Enemy
var remaining := 0.0
var amount := 0.0
var progress := 0.0
var stage := 0
var anchor := Vector3.ZERO
var origin := Vector3.ZERO
var heading := Vector3.FORWARD
var seen := {}
var afflictions := PackedStringArray()
var last_contact: Dictionary
var display: MeshInstance3D

static func contact(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName, form: Dictionary, context: Dictionary) -> void:
	# Snapshot before this hit's payload; do not reward a packet that later fails.
	if not bool(context.get("practice_allowed", false)) or not is_instance_valid(enemy) or enemy.life <= 0 or enemy.flees: return
	if not context.has("sustain_pending"): context.sustain_pending = {}
	context.sustain_pending[enemy.get_instance_id()] = {"burning": enemy.burning_left > 0, "chilled": enemy.chill > 0 or enemy.is_frozen(), "bleeding": enemy.bleeding_left > 0, "form": form, "skill": skill}

static func landed(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName, _form: Dictionary, context: Dictionary) -> void:
	if not bool(context.get("practice_allowed", false)) or not is_instance_valid(enemy) or enemy.flees: return
	var pending: Dictionary = context.get("sustain_pending", {})
	var id := enemy.get_instance_id()
	if not pending.has(id): return
	var before: Dictionary = pending[id]
	pending.erase(id)
	var form: Dictionary = before.form
	var handled := {}
	# Existing opportunities may be completed by another supported real skill.
	for event in events(owner_combat):
		var eligible := (event.mode == "bloodletter" and event.target == enemy and bool(before.bleeding)) or (event.mode == "deep_drink" and not event.seen.has(id)) or (event.mode == "iron_drink" and event.stage == 1 and event.target == enemy) or (event.mode == "quick_sip" and event.skill_id != skill)
		if not eligible: continue
		if not FoundryReactions._commit(owner_combat, context, "sustain_follow_" + event.mode, event.limit("sustain_follow_gate")): continue
		if event.mode == "bloodletter" and event.target == enemy and bool(before.bleeding):
			event.stage += 1
			if event.stage >= int(event.limit("sustain_bloodletter_hits")): event.pay()
			handled[event.mode] = true
		elif event.mode == "deep_drink":
			event.seen[id] = true
			event.last_contact = context
			handled[event.mode] = true
		elif event.mode == "iron_drink" and event.stage == 1 and event.target == enemy:
			event.pay()
			handled[event.mode] = true
		elif event.mode == "quick_sip" and event.skill_id != skill:
			event.pay()
			handled[event.mode] = true
	for role: String in CONTACT_ROLES:
		if handled.has(role) or live(owner_combat, role) != null or float(form.get("identity_" + role + "_life", 0)) <= 0: continue
		if enemy.life <= 0 and role != "bloodroot": continue
		if role in ["winterroot", "cold_sip"] and not bool(before.chilled): continue
		if role in ["bloodroot", "bloodletter"] and not bool(before.bleeding): continue
		if role == "cinder" and not bool(before.burning): continue
		if role == "spring" and owner_combat.life / maxf(owner_combat.max_life, 1) > float(form.limits.sustain_low_life): continue
		if role == "ward_sip" and _afflictions(owner_combat).is_empty(): continue
		if role == "long_drink" and FoundryIdentity.point(owner_combat).distance_to(enemy.global_position + Vector3.UP * .5) < float(form.limits.sustain_long_min_range): continue
		if not FoundryReactions._commit(owner_combat, context, "sustain_" + role, float(form.limits.sustain_contact_cooldown)): continue
		var event := spawn(owner_combat, skill, role, enemy.global_position + Vector3.UP * .5, form, enemy)
		if event != null:
			event.seen[id] = true
			event.stage = 1 if role == "bloodletter" else 0
			event.last_contact = context
			context["sustain_follow_" + role + "_used"] = true

static func cast(owner_combat: PlayerCombat, skill: StringName, at: Vector3) -> void:
	# The host calls this only after a real input succeeds, never for links/echoes.
	for event in events(owner_combat):
		if event.mode == "cold_sip" and String(owner_combat.skills.get(skill, {}).get("delivery", "")) == "dash": event.pay()
		elif event.mode == "deep_drink" and event.seen.size() >= int(event.limit("sustain_deep_targets")) and not is_same(event.last_contact, owner_combat.action_context(skill)): event.pay()
	var form := owner_combat.mutation(skill)
	if float(form.get("identity_iron_drink_life", 0)) > 0 and live(owner_combat, "iron_drink") == null and owner_combat.reaction_ready("sustain_iron_drink", float(form.limits.sustain_contact_cooldown)):
		spawn(owner_combat, skill, "iron_drink", at, form)

static func killed(owner_combat: PlayerCombat, enemy: Enemy, skill: StringName) -> void:
	if not is_instance_valid(enemy) or enemy.flees or owner_combat.life <= 0: return
	var at := enemy.global_position + Vector3.UP * .5
	var mark := live(owner_combat, "bloodroot")
	if mark != null and mark.target == enemy:
		if at.distance_to(FoundryIdentity.point(owner_combat)) <= mark.limit("sustain_execution_range") and corpse_clear(owner_combat, at, FoundryIdentity.point(owner_combat), [enemy]): mark.pay()
		else: mark.cancel()
	var harvest := live(owner_combat, "harvest")
	if harvest != null and not harvest.seen.has(enemy.get_instance_id()) and harvest.global_position.distance_to(at) <= harvest.limit("sustain_harvest_range") and corpse_clear(owner_combat, harvest.global_position, at, [enemy, harvest.target]):
		harvest.seen[enemy.get_instance_id()] = true
		harvest.stage = 1
	var form := owner_combat.mutation(skill)
	for role: String in ["phoenix", "harvest", "harbour", "fleet"]:
		if float(form.get("identity_" + role + "_life", 0)) <= 0 or live(owner_combat, role) != null: continue
		if not owner_combat.reaction_ready("sustain_" + role, float(form.limits.sustain_kill_cooldown)): continue
		var event := spawn(owner_combat, skill, role, at, form)
		if event != null:
			event.seen[enemy.get_instance_id()] = true
			if role == "harvest": event.target = enemy

static func corpse_clear(owner_combat: PlayerCombat, from: Vector3, to: Vector3, corpses: Array) -> bool:
	# Enemy death removes group membership before queued collision deletion.
	# These known corpse bodies must not count as the wall between two kills.
	var excluded: Array[RID] = [owner_combat.player.get_rid()]
	for hostile in owner_combat.get_tree().get_nodes_in_group("enemies"):
		if hostile is Enemy: excluded.append(hostile.get_rid())
	for corpse in corpses:
		if is_instance_valid(corpse): excluded.append(corpse.get_rid())
	return owner_combat.player.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1, excluded)).is_empty()

static func damaged(owner_combat: PlayerCombat, enemy: Enemy, damage: float) -> void:
	if damage <= 0 or owner_combat.life <= 0 or not is_instance_valid(enemy): return
	for event in events(owner_combat):
		if event.mode == "spring": event.progress = 0
		elif event.mode == "ironroot" and event.stage == 0:
			event.stage = 1
			event.amount = minf(event.amount, damage * event.limit("sustain_recoup_fraction"))
			event.anchor = FoundryIdentity.point(owner_combat)
		elif event.mode == "iron_drink" and event.stage == 0:
			if not FoundryIdentity.inside(owner_combat, event.anchor, FoundryIdentity.point(owner_combat), event.limit("sustain_stand_radius")): continue
			event.stage = 1
			event.target = enemy
			event.amount = minf(event.amount, damage * event.limit("sustain_recoup_fraction"))

static func _afflictions(owner_combat: PlayerCombat) -> PackedStringArray:
	var active := PackedStringArray()
	if owner_combat.rooted(): active.append("root")
	if owner_combat.harried(): active.append("harry")
	if owner_combat.marked(): active.append("mark")
	return active

static func events(owner_combat: PlayerCombat) -> Array[FoundrySustain]:
	var result: Array[FoundrySustain] = []
	for node in owner_combat.get_tree().get_nodes_in_group("foundry_sustain"):
		if node is FoundrySustain and node.combat == owner_combat and node.remaining > 0 and not node.is_queued_for_deletion(): result.append(node)
	return result

static func live(owner_combat: PlayerCombat, role: String) -> FoundrySustain:
	for event in events(owner_combat):
		if event.mode == role: return event
	return null

static func spawn(owner_combat: PlayerCombat, skill: StringName, role: String, at: Vector3, form: Dictionary, victim: Enemy = null) -> FoundrySustain:
	if owner_combat.life <= 0 or live(owner_combat, role) != null or not FoundryIdentity.admit(owner_combat, "foundry_sustain", int(form.limits.sustain_max_events)): return null
	var node := FoundrySustain.new()
	node.combat = owner_combat
	node.skill_id = skill
	node.mode = role
	node.rules = form.duplicate(true)
	node.target = victim
	node.amount = float(form.get("identity_" + role + "_life", 0))
	node.remaining = float(form.limits.sustain_window)
	if role == "quick_sip": node.remaining = float(form.limits.sustain_quick_window)
	node.anchor = FoundryIdentity.point(owner_combat)
	node.origin = node.anchor
	node.afflictions = _afflictions(owner_combat)
	node.heading = (at - node.anchor) * Vector3(1, 0, 1)
	node.heading = node.heading.normalized() if not node.heading.is_zero_approx() else FoundryIdentity.direction(owner_combat)
	owner_combat.player.world_root().add_child(node)
	node.global_position = at
	node.make_visual()
	return node

func _ready() -> void:
	add_to_group("foundry_sustain")
	combat.died.connect(cancel)

func limit(key: String) -> float:
	return float(rules.limits[key])

func cancel() -> void:
	remaining = 0
	amount = 0
	queue_free()

func pay() -> void:
	if remaining <= 0 or is_queued_for_deletion(): return
	var earned := amount
	cancel() # Commit consumption before healing/signals can run another event.
	combat.heal(earned)

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if remaining <= 0 or is_queued_for_deletion(): return
	if not is_instance_valid(combat) or not is_instance_valid(combat.player) or combat.life <= 0:
		cancel()
		return
	var elapsed := minf(maxf(delta, 0), remaining)
	remaining -= elapsed
	if remaining <= 0:
		cancel()
		return
	var player_at := FoundryIdentity.point(combat)
	var target_live := is_instance_valid(target) and target.life > 0
	match mode:
		"phoenix":
			progress += elapsed
			if progress >= limit("sustain_phoenix_delay") and near_player(limit("sustain_pickup_radius")): pay()
		"winterroot":
			if not target_live or (target.chill <= 0 and not target.is_frozen()):
				cancel()
				return
			global_position = target.global_position + Vector3.UP * .5
			if not near_player(limit("sustain_winter_range")) or player_at.distance_to(anchor) > limit("sustain_stand_radius"):
				progress = 0
				anchor = player_at
			else: progress += elapsed
			if progress >= limit("sustain_winter_hold"): pay()
		"harvest":
			if stage == 1 and near_player(limit("sustain_pickup_radius")): pay()
		"spring":
			global_position = player_at
			progress += elapsed
			if progress >= limit("sustain_spring_quiet"): pay()
		"ironroot":
			global_position = anchor
			if stage == 1:
				if near_player(limit("sustain_stand_radius")): progress += elapsed
				else: progress = 0
				if progress >= limit("sustain_iron_hold"): pay()
		"harbour":
			var clear := near_player(limit("sustain_harbour_range"))
			for enemy in combat.alive_enemies():
				if enemy.flees: continue
				if FoundryIdentity.inside(combat, global_position, enemy.global_position + Vector3.UP * .5, limit("sustain_harbour_range")):
					clear = false
					break
			progress = progress + elapsed if clear else 0.0
			if progress >= limit("sustain_harbour_quiet"): pay()
		"fleet":
			progress += elapsed
			var next := global_position + heading * limit("sustain_fleet_speed") * elapsed
			if SkillBurst.solid_ray(combat, global_position, next).is_empty(): global_position = next
			if progress >= limit("sustain_fleet_head_start") and player_at.distance_to(origin) >= limit("sustain_fleet_chase") and near_player(limit("sustain_pickup_radius")): pay()
		"cinder":
			if stage == 0:
				if not target_live or target.burning_left <= 0:
					cancel()
					return
				global_position = target.global_position + Vector3.UP * .5
				if not near_player(limit("sustain_tether_range")):
					cancel()
					return
				progress += elapsed
				if progress >= limit("sustain_cinder_hold"): stage = 1
			else:
				var next := global_position.move_toward(player_at, limit("sustain_return_speed") * elapsed)
				if not SkillBurst.solid_ray(combat, global_position, next).is_empty():
					cancel()
					return
				global_position = next
				if next.distance_to(player_at) <= limit("sustain_return_arrival"): pay()
		"long_drink":
			if not target_live:
				cancel()
				return
			global_position = target.global_position + Vector3.UP * .5
			var gap := player_at.distance_to(global_position)
			if gap < limit("sustain_long_min_range") or not near_player(limit("sustain_tether_range")):
				cancel()
				return
			progress += elapsed
			if progress >= limit("sustain_long_hold") and gap >= origin.distance_to(global_position) + limit("sustain_long_retreat"): pay()
		"ward_sip":
			global_position = player_at
			var current := _afflictions(combat)
			var cleared := true
			for affliction in afflictions:
				if current.has(affliction): cleared = false
			if cleared: pay()
		"bloodroot", "bloodletter":
			if target_live: global_position = target.global_position + Vector3.UP * .5
			elif mode == "bloodletter": cancel()
		"cold_sip", "deep_drink", "quick_sip": global_position = player_at
	if display != null and remaining > 0:
		display.rotation.y += elapsed
		display.scale = Vector3.ONE * (1.0 + minf(progress, 1.0) * .15)

func near_player(radius: float) -> bool:
	return FoundryIdentity.inside(combat, global_position, FoundryIdentity.point(combat), radius)

func make_visual() -> void:
	var shape := "orb"
	var colour := Color("b6887c")
	if mode in ["phoenix", "harvest", "harbour"]: shape = "ring"
	elif mode in ["winterroot", "bloodroot", "fleet", "bloodletter"]: shape = "spike"
	elif mode in ["ironroot", "long_drink", "iron_drink", "quick_sip"]: shape = "bar"
	if mode in ["winterroot", "cold_sip"]: colour = Color("9cbcb9")
	elif mode in ["phoenix", "cinder"]: colour = Color("dcb384")
	elif mode in ["harbour", "ward_sip"]: colour = Color("c2c6a0")
	display = FoundryIdentity.visual(self, shape, colour, limit("sustain_visual_radius"))
