extends "res://scripts/player.gd"
## Test-only timings; production motion and collision queries run unchanged.
var motion_sample := {}
var step_ms := 0.0
var step_rise := 0.0
func _physics_process(delta: float) -> void:
	var before := global_position
	var began := Time.get_ticks_usec()
	super._physics_process(delta)
	motion_sample = {"motion_ms": (Time.get_ticks_usec()-began)/1000.0, "step_ms": step_ms, "step_rise": step_rise, "distance": global_position.distance_to(before), "floor": is_on_floor(), "velocity_y": velocity.y}
func _step_up(delta: float) -> void:
	var before := global_position.y
	var began := Time.get_ticks_usec()
	super._step_up(delta)
	step_ms = (Time.get_ticks_usec()-began)/1000.0
	step_rise = global_position.y-before
