class_name SkillCastEffect
extends MeshInstance3D
## Brief aftermath of an already committed cast. Never deals delayed damage.
const LOOK = preload("res://art/combat_feel.tres")
var remaining := 0.0
var tint: StandardMaterial3D

static func spawn(combat: PlayerCombat, skill: StringName) -> SkillCastEffect:
	var def: Dictionary = combat.skills.get(skill,{})
	var spatial: Dictionary = combat.sim.realtime().get("skills",{}).get(String(skill),{})
	var profile: String = LOOK.profile(def,spatial)
	if String(def.get("delivery", "")) in ["strike", "cone"] and float(combat.mutation(skill).get("wave",0)) > 0:
		return null # the travelling edge is the hit shape; no misleading melee-area ring
	if not profile in ["strike","rend","sweep","nova","drive","reap"]:
		return null
	var root := combat.player.world_root()
	var active := root.get_tree().get_nodes_in_group("skill_cast_effects")
	if active.size() >= LOOK.max_cast_effects:
		# Detach immediately so repeated casts in one frame stay bounded.
		active[0].get_parent().remove_child(active[0])
		active[0].queue_free()
	var effect := SkillCastEffect.new()
	effect.remaining = LOOK.effect_seconds
	var st := ArtGeometry.begin()
	var colour: Color = LOOK.colour(def)
	if profile in ["sweep","nova","reap"]:
		var radius: float = float(def.get("base_area_radius",1.0)) * (1.0+float(combat.sim.derived_stats()["area_bonus"])) * combat.sim.skill_reach(String(skill))
		if combat.alive_enemies().size() == 1:
			radius *= float(combat.sim.combat_mods()["isolated_area_multiplier"])
		var arc := deg_to_rad(float(spatial.get("cone_degrees",combat.cone_degrees)))
		for i in 40:
			var a := -arc*0.5+arc*float(i)/40
			var b := -arc*0.5+arc*float(i+1)/40
			var p := Vector3(sin(a),0,-cos(a))
			var q := Vector3(sin(b),0,-cos(b))
			ArtGeometry.triangle(st,p*radius,q*radius,p*(radius-0.065),colour)
			ArtGeometry.triangle(st,q*radius,q*(radius-0.065),p*(radius-0.065),colour)
	else:
		var reach := combat.strike_reach(skill)
		var across := Vector3(0.24,0.16,0) if profile == "rend" else Vector3(0.02,0.3,0)
		ArtGeometry.triangle(st,Vector3(0,0,-0.65)-across,Vector3(0,0,-reach),Vector3(0,0,-0.65)+across,colour)
	effect.mesh = st.commit()
	effect.tint = ArtGeometry.material()
	effect.tint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	effect.tint.cull_mode = BaseMaterial3D.CULL_DISABLED
	effect.tint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	effect.material_override = effect.tint
	effect.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(effect)
	effect.add_to_group("skill_cast_effects")
	effect.global_position = combat.player.global_position + Vector3(0,-0.35,0)
	effect.rotation.y = combat.player.global_rotation.y
	return effect

func _process(delta: float) -> void:
	remaining = maxf(0.0,remaining-delta)
	tint.albedo_color.a = remaining/LOOK.effect_seconds*0.65
	if remaining <= 0:
		queue_free()
