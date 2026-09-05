class_name FoundryEcho
extends Node
var combat: PlayerCombat
var skill_id: StringName
var definition: Dictionary
var remaining := 0.0

func _ready() -> void:
	add_to_group("foundry_echoes")
	combat.died.connect(cancel)

func cancel() -> void:
	set_physics_process(false)
	queue_free()

func _physics_process(delta: float) -> void:
	if is_queued_for_deletion(): return
	remaining -= maxf(0, delta)
	if remaining > 0: return
	if is_instance_valid(combat) and combat.life > 0: combat.repeat_skill(skill_id, definition)
	cancel()
