extends Node3D
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func poses(motion: CreatureMotion) -> Array:
	var result := []
	for i in motion.rig.get_bone_count():
		result.append(motion.rig.get_bone_pose(i))
	return result

func _ready() -> void:
	var look := preload("res://art/character_look.tres")
	for role in ["melee","fast","grazer","swarm","lurker","guard","ranged","shrieker","knight","skirmisher","boss","peddler"]:
		var actor := Node3D.new()
		add_child(actor)
		var mesh := MeshInstance3D.new()
		mesh.mesh = look.build(role)
		actor.add_child(mesh)
		var motion := CreatureMotion.attach(mesh,actor,role)
		motion.set_physics_process(false)
		var arrays := mesh.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
		var valid := bones.size()==vertices.size()*4 and weights.size()==bones.size()
		var rest_exact := true
		for i in vertices.size():
			var bone := bones[i*4]
			valid = valid and bone>=0 and bone<motion.rig.get_bone_count() and is_equal_approx(weights[i*4],1.0)
			var at := motion.rig.get_bone_global_pose(bone)*mesh.skin.get_bind_pose(bone)*vertices[i]
			rest_exact = rest_exact and at.is_equal_approx(vertices[i])
		check(valid,"all vertices bound to existing bones: "+role)
		check(rest_exact,"bind pose exactly preserves authored silhouette: "+role)
		motion.sample(0.1,0.25)
		var stride_pose := poses(motion)
		check(stride_pose[0]!=Transform3D(Basis.IDENTITY,Vector3(0,0.7,0)),"motion changes the presentation: "+role)
		motion.sample(1.0,2.0,0.9,0.0,true)
		check(poses(motion)==stride_pose,"freeze holds every bone: "+role)
		var phase_before := motion.phase
		motion.sample(0.4,0.0)
		check(motion.phase==phase_before and motion.stride_weight==0.0,"stationary body stops walking: "+role)
		motion.sample(0.0,0.0,0.9)
		check(motion.release_left==0.0,"anticipation alone never invents an attack: "+role)
		motion.released("strike")
		motion.sample(0.0,0.0)
		check(motion.rig.get_bone_pose_position(0).z<0,"real release produces forward follow-through: "+role)
		motion.sample(0.05,0.0,0.0,0.0,false,true)
		check(motion.release_left==0.0,"stagger cancels follow-through: "+role)
		actor.free()
	var enemy := Enemy.spawn(self,&"ember_whelp",Vector3(3,0,0))
	enemy.set_physics_process(false)
	var motion := enemy._mesh.get_node("Motion") as CreatureMotion
	motion.set_physics_process(false)
	var collision := enemy.get_node("CollisionShape3D") as CollisionShape3D
	var original_shape := collision.shape
	var position_before := enemy.transform
	var life_before := enemy.life
	var cooldown_before := enemy._attack_cooldown
	for i in 100:
		motion.sample(1.0/60.0,0.05,float(i%10)/10.0)
	check(enemy.transform==position_before and collision.shape==original_shape,"motion never moves the body or replaces collision")
	check(enemy.life==life_before and enemy._attack_cooldown==cooldown_before,"motion never changes life or combat cadence")
	enemy.attack_released.emit("strike")
	check(motion.release_left>0,"actor release signal reaches presentation")
	enemy.configure(load("res://scripts/sim.gd").shared())
	check(enemy._mesh.get_child_count()==1 and enemy.attack_released.get_connections().size()==1,"reconfiguration replaces rig and signal connection")
	print("CODEX_CREATURE_MOTION %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)
