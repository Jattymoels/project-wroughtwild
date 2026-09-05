class_name FoundryReactions
extends RefCounted
## Spatial hooks consume sim-authored numbers. Secondary events cannot enter here.

static func contact(combat: PlayerCombat, enemy: Enemy, skill: StringName, form: Dictionary, context: Dictionary) -> void:
	var limits: Dictionary = form.get("limits", {})
	var at := enemy.global_position + Vector3.UP * 0.5
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
	if float(form.get("warm_cinder_life", 0)) <= 0: return
	if not combat.reaction_ready("warm_cinder", float(form.limits.warm_cinder_cooldown)): return
	FoundryReturn.launch(combat, enemy.global_position + Vector3.UP * 0.3, form, true)
