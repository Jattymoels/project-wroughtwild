extends Node3D
## INT-03A: real capsule traversal, runnable against the preserved baseline.
## Inspection ground isolates headroom; no saves, grants or changed collision rules.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var obstacles: Array[Node3D] = []

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: home headroom: ",label)

func body(size: Vector3, at: Vector3) -> StaticBody3D:
	var result := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	result.add_child(collision)
	add_child(result)
	result.position = at
	obstacles.append(result)
	return result

func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	body(Vector3(40,1,40),Vector3(0,-.5,0))
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.set_physics_process(false)
	player.move_speed = 2.0
	var capsule: CapsuleShape3D = player.get_node("CollisionShape3D").shape
	check(is_equal_approx(capsule.height,1.92) and is_equal_approx(capsule.radius,.42),"original capsule dimensions are retained")
	check(is_equal_approx(player.STEP_HEIGHT,.55),"original maximum step is retained")
	var initial: Dictionary = player.inventory.get_sim().inventory().duplicate(true)
	await threshold("shallow step in open air",.125,0.0,true)
	await threshold("shallow step with sufficient real headroom",.125,2.18,true)
	await threshold("shallow step under an insufficient ceiling",.125,2.0,false)
	await threshold("half-metre step",.5,3.0,true)
	await threshold("half-metre step with sufficient real headroom",.5,2.45,true)
	await threshold("diagonal half-metre step with sufficient real headroom",.5,2.45,true,Vector2(1,-1).normalized())
	await threshold("half-metre step under an insufficient ceiling",.5,2.4,false)
	await threshold("wall beyond the existing step height",.75,3.0,false)
	await threshold("diagonal wall beyond the existing step height",.75,3.0,false,Vector2(1,-1).normalized())
	check(player.inventory.get_sim().inventory()==initial,"walking never changes material ownership")
	print("CODEX_HOME_HEADROOM %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func threshold(label: String, rise: float, ceiling: float, passable: bool, direction := Vector2(0,-1)) -> void:
	# The threshold starts at z=0. The ceiling also covers the approach,
	# so a successful walk cannot borrow extra headroom outside the room.
	var platform := body(Vector3(12,rise,5),Vector3(0,rise*.5,-2.5))
	var roof: StaticBody3D
	if ceiling>0.0: roof=body(Vector3(12,.25,8),Vector3(0,ceiling+.125,-1))
	player.position=Vector3(0,.965,1.5)
	player.velocity=Vector3.ZERO
	player.rotation=Vector3.ZERO
	player.test_walk=Vector2.ZERO
	player.set_physics_process(true)
	await frames(12)
	player.test_walk=direction
	await frames(100)
	player.test_walk=Vector2.ZERO
	await frames(3)
	player.set_physics_process(false)
	var crossed := player.position.z<-.65
	check(crossed==passable,label+" (%s)" % str(player.position))
	if passable:
		check(absf(player.position.y-(rise+capsule_half_height()))<.08,label+" lands on its actual surface")
	else:
		check(player.position.z>-.42,label+" does not penetrate the blocking geometry")
	check(player.position.is_finite() and player.velocity.is_finite(),label+" leaves a finite physical state")
	platform.free()
	if roof!=null: roof.free()
	await frames(2)

func capsule_half_height() -> float:
	return (player.get_node("CollisionShape3D").shape as CapsuleShape3D).height*.5
