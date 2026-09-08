extends PlayerCombat
## Test-only observer: delegates every action and rule to production combat.
var metrics := {}
var primary_only := ""
var recovery_source := "other_healing"

func reset_metrics() -> void:
	metrics={"direct_damage":0.0,"hit_healing":0.0,"kill_healing":0.0,"other_healing":0.0,"effect_triggers":{},"direct_targets":{}}

func use_skill(id: StringName) -> bool:
	if primary_only!="" and String(id)!=primary_only and id!=DASH_SKILL: return false
	return super.use_skill(id)

func heal(amount: float) -> void:
	var before:=life
	super.heal(amount)
	if not metrics.is_empty(): metrics[recovery_source]+=maxf(0,life-before)

func _reap(id: StringName, kills: int) -> void:
	var previous:=recovery_source
	recovery_source="kill_healing"
	super._reap(id,kills)
	recovery_source=previous

func deal(enemy: Enemy, id: StringName, isolated: bool, fraction:=1.0, secondary:=false, context: Dictionary={}) -> Dictionary:
	var before:=enemy.life
	var previous:=recovery_source
	recovery_source="hit_healing"
	var result:=super.deal(enemy,id,isolated,fraction,secondary,context)
	recovery_source=previous
	if not secondary and not metrics.is_empty():
		metrics.direct_damage+=maxf(0,before-maxf(0,enemy.life))
		if before>enemy.life: metrics.direct_targets[str(enemy.get_instance_id())]=true
	return result

func apply_payload(enemy: Enemy, id: StringName, boss: bool, fraction:=1.0, secondary:=false, context: Dictionary={}) -> PackedStringArray:
	var result:=super.apply_payload(enemy,id,boss,fraction,secondary,context)
	if not metrics.is_empty():
		for trigger in result: metrics.effect_triggers[trigger]=int(metrics.effect_triggers.get(trigger,0))+1
	return result
