class_name CreatureMotion
extends Node3D
## Presentation only: reads actual travel and the existing combat clocks.
## Skinning keeps one shared mesh surface and the actor's status material.
const LOOK = preload("res://art/character_look.tres")
const TUNING = preload("res://art/creature_motion.tres")
var rig: Skeleton3D
var actor: Node3D
var role := ""
var phase := 0.0
var idle_phase := 0.0
var stride_weight := 0.0
var release_left := 0.0
var _previous := Vector3.ZERO
var _mesh: MeshInstance3D
var _points: PackedVector3Array

static func attach(mesh: MeshInstance3D, owner_actor: Node3D, actor_role: String) -> CreatureMotion:
	var previous := mesh.get_node_or_null("Motion")
	if previous != null:
		previous.free()
	RecoveredActorArt.apply(mesh,owner_actor,actor_role)
	var motion := CreatureMotion.new()
	motion.name = "Motion"
	motion.actor = owner_actor
	motion.role = actor_role
	motion._mesh = mesh
	mesh.add_child(motion)
	motion._configure()
	return motion

func _configure() -> void:
	_points = LOOK.pivots(role)
	rig = Skeleton3D.new()
	rig.name = "Skeleton"
	add_child(rig)
	var skin := Skin.new()
	for i in _points.size():
		rig.add_bone("body" if i==0 else "part_%d" % i)
		if i>0:
			rig.set_bone_parent(i,0)
		var rest := Transform3D(Basis.IDENTITY,_points[i] if i==0 else _points[i]-_points[0])
		rig.set_bone_rest(i,rest)
		skin.add_bind(i,Transform3D(Basis.IDENTITY,-_points[i]))
	rig.reset_bone_poses()
	_mesh.skin = skin
	_mesh.skeleton = _mesh.get_path_to(rig)
	_mesh.extra_cull_margin = TUNING.cull_margin
	_previous = actor.global_position
	# Stable offsets keep packs from marching in lockstep; no gameplay RNG.
	idle_phase = fposmod(_previous.x*2.17+_previous.z*0.73,TAU)
	phase = idle_phase
	if actor is Enemy:
		actor.attack_released.connect(released)

func released(_kind: String) -> void:
	release_left = TUNING.release_seconds

func _physics_process(delta: float) -> void:
	var now := actor.global_position
	var travel := Vector2(now.x-_previous.x,now.z-_previous.z).length()
	_previous = now
	var windup := 0.0
	var inhale := 0.0
	var frozen := false
	var stagger := false
	if actor is Enemy:
		frozen = actor.is_frozen()
		stagger = actor.staggered()
		if actor.state=="windup":
			windup = clampf(1.0-actor._windup_left/maxf(actor.windup_seconds,0.001),0.0,1.0)
		if actor is Boss and actor.state=="inhale":
			inhale = clampf(1.0-actor._telegraph_left/maxf(actor.breath_telegraph_seconds,0.001),0.0,1.0)
		if not actor.is_on_floor():
			travel = 0.0
	# Teleports and respawns never advance the walk cycle by a huge distance.
	if travel>TUNING.teleport_metres:
		travel = 0.0
	sample(delta,travel,windup,inhale,frozen,stagger)

## Deterministic pose sampler also exercised by the isolated review fixture.
## A freeze holds the exact current pose; stagger cancels the attack follow-through.
func sample(delta: float, travel: float, windup: float=0.0, inhale: float=0.0,
		frozen: bool=false, stagger: bool=false) -> void:
	if frozen:
		release_left = 0.0
		return
	if stagger:
		release_left = 0.0
		windup = 0.0
		inhale = 0.0
		travel = 0.0
	var beast := role in ["melee","fast","grazer"]
	var crawler := role in ["swarm","lurker"]
	var gait: Vector2 = TUNING.gaits["beast" if beast else "crawler" if crawler else "humanoid"]
	var scaled_travel := travel/maxf(_mesh.scale.x,0.1)
	phase = fposmod(phase+scaled_travel/gait.x*TAU,TAU)
	idle_phase = fposmod(idle_phase+delta*TUNING.idle_hz*TAU,TAU)
	var speed := scaled_travel/maxf(delta,0.001)
	stride_weight = move_toward(stride_weight,clampf(speed,0.0,1.0),delta*TUNING.settle_rate)
	var stride := stride_weight*(1.0-maxf(windup,inhale))
	var swing := sin(phase)*deg_to_rad(gait.y)*stride
	var strike := clampf(release_left/maxf(TUNING.release_seconds,0.001),0.0,1.0)
	release_left = maxf(0.0,release_left-delta)
	var breathe := sin(idle_phase)*TUNING.idle_metres*(1.0-stride)
	var lift := absf(sin(phase))*TUNING.step_lift*stride
	var recoil := TUNING.stagger_radians if stagger else 0.0
	var lean := windup*TUNING.windup_radians - strike*TUNING.strike_radians + inhale*TUNING.windup_radians + recoil
	_pose(0,Vector3(lean,0,sin(phase)*stride*0.025),Vector3(0,breathe+lift,windup*TUNING.lunge_metres*0.35-strike*TUNING.lunge_metres))
	_pose(1,Vector3(windup*0.2-strike*0.3+inhale*0.2,sin(idle_phase*0.5)*0.045,0))
	if role=="skirmisher":
		_pose(0,Vector3(0,sin(idle_phase)*0.2,0.08*cos(idle_phase)),Vector3(0,TUNING.hover_metres*sin(idle_phase),-strike*TUNING.lunge_metres))
	elif beast:
		for i in range(2,6):
			# Diagonal pairs form a trot, rather than four identical paddles.
			var sign_value := 1.0 if i in [2,5] else -1.0
			_pose(i,Vector3(swing*sign_value,0,0))
	elif crawler:
		for i in range(2,8):
			var side := -1.0 if i<5 else 1.0
			var leg_wave := sin(phase+PI*float(i%2))
			_pose(i,Vector3(0,leg_wave*deg_to_rad(gait.y)*stride,side*maxf(0.0,leg_wave)*stride*0.16))
	else:
		_pose(2,Vector3(-swing*0.65-windup*0.3,0,-inhale*0.35))
		_pose(3,Vector3(swing,0,0))
		_pose(4,Vector3(swing*0.65-windup*1.05+strike*0.55,windup*0.25,inhale*0.35))
		_pose(5,Vector3(-swing,0,0))

func _pose(bone: int, angles: Vector3, offset: Vector3=Vector3.ZERO) -> void:
	rig.set_bone_pose_rotation(bone,Quaternion.from_euler(angles))
	rig.set_bone_pose_position(bone,rig.get_bone_rest(bone).origin+offset)
