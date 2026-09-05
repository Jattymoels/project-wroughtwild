class_name FoundryReturn
extends Node3D
## Siphoned life is earned on a landed direct hit and delivered on arrival.
var combat: PlayerCombat
var amount := 0.0
var speed := 9.0
var collectible := false
var remaining := 6.0
var pickup_radius := 1.4
var visual: Node3D

static func launch(from_combat: PlayerCombat, at: Vector3, mutation: Dictionary, warm_cinder := false) -> void:
	var count := 0
	for node in from_combat.get_tree().get_nodes_in_group("foundry_returns"):
		if node.combat == from_combat and not node.is_queued_for_deletion(): count += 1
	if count >= int(mutation.limits.get("max_returns", 24)): return
	var mote := FoundryReturn.new()
	mote.combat = from_combat
	mote.amount = float(mutation.get("siphon", 0))
	if warm_cinder:
		mote.amount = float(mutation.get("warm_cinder_life", 0))
		mote.collectible = true
		mote.remaining = float(mutation.limits.warm_cinder_lifetime)
		mote.pickup_radius = float(mutation.limits.warm_cinder_pickup_radius)
	mote.speed = float(mutation.limits.get("siphon_speed", 9))
	from_combat.player.world_root().add_child(mote)
	mote.global_position = at
	mote.visual = CombatVisuals.projectile("coal" if warm_cinder else "frost", Color("ed994e") if warm_cinder else Color("b78a8a"))
	mote.visual.scale = Vector3.ONE * (0.7 if warm_cinder else 0.35)
	mote.add_child(mote.visual)

func _ready() -> void:
	add_to_group("foundry_returns")
	combat.died.connect(cancel)

func cancel() -> void:
	amount = 0
	queue_free()

func _physics_process(delta: float) -> void:
	advance(delta)

func advance(delta: float) -> void:
	if is_queued_for_deletion(): return
	if not is_instance_valid(combat) or not is_instance_valid(combat.player) or combat.life <= 0:
		cancel()
		return
	var target := combat.player.global_position + Vector3.UP * 0.6
	if collectible:
		remaining -= maxf(delta, 0)
		if remaining <= 0:
			cancel()
			return
		if visual != null: visual.position.y = 0.08 * sin(remaining * TAU)
		if global_position.distance_to(target) > pickup_radius: return
		if not SkillBurst.solid_ray(combat, global_position, target).is_empty(): return
		collectible = false
	global_position = global_position.move_toward(target, speed * maxf(0, delta))
	if global_position.distance_to(target) <= 0.2:
		combat.heal(amount)
		cancel()
