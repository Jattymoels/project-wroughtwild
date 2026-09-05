class_name FoundryReactions
extends RefCounted
## Spatial hooks consume sim-authored numbers. Secondary events cannot enter here.

static func contact(combat: PlayerCombat, enemy: Enemy, skill: StringName, form: Dictionary, context: Dictionary) -> void:
	var limits: Dictionary = form.get("limits", {})
	var at := enemy.global_position + Vector3.UP * 0.5
	_ember_contact(combat,enemy,skill,form,context)
	FoundryCold.contact(combat,enemy,skill,form,context)
	var release := float(form.get("burn_release_seconds", 0))
	if release > 0 and enemy.burning_left > 0 and combat._fight_clock >= enemy.burn_release_ready:
		enemy.burn_release_ready = combat._fight_clock + float(limits.burn_release_cooldown)
		var seconds := minf(release, enemy.burning_left)
		var rate := enemy._burn_dps
		if enemy._sear > 0 and Vector2(enemy.velocity.x, enemy.velocity.z).length() > 0.5 and enemy.bleeding_left > 0:
			rate *= 1.0 + enemy._sear
		enemy.burning_left -= seconds
		var damage := enemy.take_typed(rate * seconds, "fire", false)
		enemy._refresh_look()
		FoundryPuff.spawn(combat, at, 0.65, false)
		if damage > 0: combat.hit_landed.emit(damage, 0, PackedStringArray(["fire"]))
	if enemy.life <= 0: return
	var stagger := float(form.get("steam_stagger", 0))
	if stagger > 0 and (enemy.chill > 0 or enemy.is_frozen()) and combat.reaction_ready("steam_puff", float(limits.steam_puff_cooldown)):
		var radius := combat.mutation_radius(skill, float(limits.steam_puff_radius))
		for target in combat.alive_enemies():
			var centre: Vector3 = target.global_position + Vector3.UP * 0.5
			if at.distance_to(centre) <= radius and SkillBurst.solid_ray(combat, at, centre).is_empty():
				target.stagger(stagger * (float(limits.steam_boss_stagger_factor) if target is Boss else 1.0))
		FoundryPuff.spawn(combat, at, radius, true)
	if float(form.get("steam_fraction", 0)) > 0 and not bool(context.get("steam_used", false)):
		# Commit the FIRST target even if the player-wide budget is unavailable.
		context["steam_used"] = true
		if float(form.get("steam_fire_damage", 0)) + float(form.get("steam_cold_damage", 0)) > 0 and combat.reaction_ready("steam_plume", float(limits.steam_plume_cooldown)):
			FoundryField.spawn(combat, skill, enemy.global_position + Vector3.UP * 0.12, "steam", form)

static func ignited(combat: PlayerCombat, enemy: Enemy, form: Dictionary) -> void:
	if float(form.get("warm_cinder_life", 0)) > 0 and combat.reaction_ready("warm_cinder", float(form.limits.warm_cinder_cooldown)):
		FoundryReturn.launch(combat, enemy.global_position + Vector3.UP * 0.3, form, true)
	if float(form.get("cautery_charges",0)) > 0 and combat.reaction_ready("cautery",float(form.limits.cautery_cooldown)):
		FoundryEmber.cauterise(combat,form)

static func _commit(combat: PlayerCombat, context: Dictionary, key: String, cooldown: float) -> bool:
	if bool(context.get(key + "_used",false)): return false
	context[key + "_used"] = true
	return combat.reaction_ready(key,cooldown)

static func _ember_contact(combat: PlayerCombat, enemy: Enemy, skill: StringName, form: Dictionary, context: Dictionary) -> void:
	var limits: Dictionary = form.get("limits",{})
	var burning := enemy.burning_left > 0
	if float(form.get("fuse_buildup",0)) > 0 and not burning and not enemy._immune_statuses.has("ignite"):
		if _commit(combat,context,"fuse",float(limits.fuse_cooldown)):
			FoundryEmber.launch(combat,skill,"fuse",enemy,form)
	if float(form.get("rake_fire_damage",0)) > 0 and (burning or enemy.bleeding_left > 0):
		if _commit(combat,context,"seam",float(limits.rake_cooldown)):
			FoundryEmber.launch(combat,skill,"seam",enemy,form)
	if float(form.get("temper_push",0)) > 0 and burning and FoundryEmber.active(combat,"temper") == null:
		if _commit(combat,context,"temper",float(limits.temper_cooldown)):
			FoundryEmber.launch(combat,skill,"temper",enemy,form)
	if float(form.get("ember_hop_buildup",0)) <= 0 or not burning or bool(context.get("ember_hop_used",false)): return
	var origin := enemy.global_position + Vector3.UP * .5
	var nearest: Enemy
	var distance := float(form.ember_hop_range)
	for other in combat.alive_enemies():
		if other == enemy or other.burning_left > 0 or other._immune_statuses.has("ignite"): continue
		var centre: Vector3 = other.global_position + Vector3.UP * .5
		var gap := origin.distance_to(centre)
		if gap > distance or not SkillBurst.solid_ray(combat,origin,centre).is_empty(): continue
		if nearest != null and is_equal_approx(gap,distance) and other.get_instance_id() > nearest.get_instance_id(): continue
		nearest = other
		distance = gap
	if nearest == null or not _commit(combat,context,"ember_hop",float(limits.ember_hop_cooldown)): return
	var spark := FoundryEmber.launch(combat,skill,"spark",nearest,form)
	if spark != null: spark.global_position = origin
