extends SceneTree
## Imported skins/clips plus independent actor capsule and projectile-contact tests.
var count := 0
var failures := 0

func check(ok: bool, message: String) -> void:
	count += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",message)

func _initialize() -> void:
	create_timer(45).timeout.connect(func(): printerr("Mob checks timed out"); quit(1))
	call_deferred("run")

func nodes_of(node: Node, kind: String) -> Array[Node]:
	var found: Array[Node] = []
	if node.is_class(kind):
		found.append(node)
	for child in node.get_children():
		found.append_array(nodes_of(child,kind))
	return found

func vector(value: Array) -> Vector3:
	return Vector3(value[0],value[1],value[2])

func source_number(source: String, key: String) -> float:
	var regex := RegEx.new()
	regex.compile(key+" = ([0-9.]+)")
	return float(regex.search(source).get_string(1))

func source_centre(source: String) -> Vector3:
	var regex := RegEx.new()
	regex.compile("position = Vector3\\(([^)]+)")
	var values := regex.search(source).get_string(1).split(",")
	return Vector3(float(values[0]),float(values[1]),float(values[2]))

func skinned(instance: MeshInstance3D, rig: Skeleton3D) -> PackedVector3Array:
	var arrays: Array = instance.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
	var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
	var result := PackedVector3Array()
	var matrices: Array[Transform3D] = []
	for bind in instance.skin.get_bind_count():
		var bone := rig.find_bone(instance.skin.get_bind_name(bind))
		if bone < 0:
			bone = instance.skin.get_bind_bone(bind)
		matrices.append(rig.global_transform*rig.get_bone_global_pose(bone)*instance.skin.get_bind_pose(bind))
	for i in vertices.size():
		var point := Vector3.ZERO
		for j in 4:
			if weights[i*4+j] > 0:
				point += (matrices[bones[i*4+j]]*vertices[i])*weights[i*4+j]
		result.append(point)
	return result

func sweep(world: World3D, shape: Shape3D, x: float, y: float, basis: Basis = Basis.IDENTITY) -> float:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(basis,basis*Vector3(x,y,-3))
	query.motion = basis*Vector3(0,0,6)
	return world.direct_space_state.cast_motion(query)[0]

func run() -> void:
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://report.json"))
	var realtime: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://combat_realtime.json"))
	var character_source: Resource = load("res://character_source.gd").new()
	var player_source := FileAccess.get_file_as_string("res://player_source.txt")
	var player := CapsuleShape3D.new()
	player.radius = source_number(player_source,"radius")
	player.height = source_number(player_source,"height")
	var shot := SphereShape3D.new()
	shot.radius = realtime.behaviours.ranged.projectile.radius_m
	check(report.assets.size() == 12,"twelve current actors including the passive elk and boss")
	for id in report.assets:
		var data: Dictionary = report.assets[id]
		var source_pivots: PackedVector3Array = character_source.pivots(data.role)
		var pivots_match: bool = source_pivots.size()==data.bone_pivots.size()
		if pivots_match:
			for i in source_pivots.size():
				pivots_match = pivots_match and (source_pivots[i]*vector(data.applied_visual_scale)).is_equal_approx(vector(data.bone_pivots[i]))
		check(pivots_match,id+" skeleton layout matches actual CharacterLook source")
		var visual: Node3D = load("res://"+id+".glb").instantiate()
		root.add_child(visual)
		var meshes := nodes_of(visual,"MeshInstance3D")
		var rigs := nodes_of(visual,"Skeleton3D")
		var players := nodes_of(visual,"AnimationPlayer")
		check(meshes.size()==1,id+" one mesh")
		check(rigs.size()==1,id+" one imported skeleton")
		check(players.size()==1,id+" one animation player")
		check(visual.transform.is_equal_approx(Transform3D.IDENTITY),id+" world-metre root with applied family scale")
		check(nodes_of(visual,"CollisionShape3D").is_empty(),id+" skin contains no collision")
		if meshes.size()==1 and rigs.size()==1 and players.size()==1:
			var instance: MeshInstance3D = meshes[0]
			var rig: Skeleton3D = rigs[0]
			var animation: AnimationPlayer = players[0]
			animation.active = false
			rig.reset_bone_poses()
			check(instance.mesh.get_surface_count()==1,id+" one status material surface")
			check(instance.skin!=null,id+" skin binding exists")
			check(rig.get_bone_count()==data.bones.size(),id+" expected six/eight-part rig")
			var material: StandardMaterial3D = instance.mesh.surface_get_material(0)
			check(material.vertex_color_use_as_albedo,id+" linear vertex colour material imported")
			var arrays: Array = instance.mesh.surface_get_arrays(0)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var bones: PackedInt32Array = arrays[Mesh.ARRAY_BONES]
			var weights: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS]
			var valid := bones.size()==vertices.size()*4 and weights.size()==bones.size()
			if valid:
				for i in vertices.size():
					var total := 0.0
					for j in 4:
						total += weights[i*4+j]
						valid = valid and weights[i*4+j]>=0 and bones[i*4+j]>=0 and bones[i*4+j]<instance.skin.get_bind_count()
					valid = valid and is_equal_approx(total,1.0)
			check(valid,id+" every vertex has valid normalized joint weights")
			for i in data.bones.size():
				var bone := rig.find_bone(data.bones[i])
				check(bone>=0,id+" named part "+str(i))
				if bone>=0:
					check((rig.global_transform*rig.get_bone_global_rest(bone)).origin.is_equal_approx(vector(data.bone_pivots[i])),id+" bind pivot "+str(i))
			var rest := skinned(instance,rig)
			var rest_exact := true
			var bounds := AABB(rest[0],Vector3.ZERO)
			for i in rest.size():
				rest_exact = rest_exact and rest[i].distance_to(instance.global_transform*vertices[i])<.00002
				bounds = bounds.expand(rest[i])
			check(rest_exact,id+" inverse binds reproduce exact rest geometry")
			check(bounds.position.is_equal_approx(vector(data.visual_bounds[0])),id+" actual skinned minimum matches Blender")
			check(bounds.end.is_equal_approx(vector(data.visual_bounds[1])),id+" actual skinned maximum matches Blender")
			for clip in data.clips:
				check(animation.has_animation(clip),id+" clip "+clip)
				if not animation.has_animation(clip):
					continue
				var resource := animation.get_animation(clip)
				check(absf(resource.length-float(data.clips[clip]))<.011,id+" clip duration "+clip)
				var presentation_only := true
				for track in resource.get_track_count():
					presentation_only = presentation_only and resource.track_get_type(track) in [Animation.TYPE_POSITION_3D,Animation.TYPE_ROTATION_3D,Animation.TYPE_SCALE_3D]
				check(presentation_only,id+" no gameplay event tracks in "+clip)
				animation.active = true
				animation.play(clip)
				animation.seek(resource.length*.25,true)
				animation.advance(0)
				var posed := skinned(instance,rig)
				var finite := true
				var moved := false
				for i in posed.size():
					finite = finite and posed[i].is_finite()
					moved = moved or posed[i].distance_to(rest[i])>.001
				check(finite and moved,id+" valid changing skinned pose in "+clip)
				check(visual.transform.is_equal_approx(Transform3D.IDENTITY),id+" clip never moves actor root")
				animation.stop()
				rig.reset_bone_poses()
			check(not data.passive or (not animation.has_animation("windup") and not animation.has_animation("release")),id+" passive actor has no attack clips")
			var expected_windup: float = realtime.boss.claw_windup_seconds if data.role=="boss" else realtime.behaviours[data.role].windup_seconds
			if not data.passive:
				check(absf(animation.get_animation("windup").length-expected_windup)<.011,id+" windup matches combat table independently")
		var actor: Node3D = load("res://"+id+"_collision.glb").instantiate()
		root.add_child(actor)
		check(actor is CharacterBody3D,id+" retains character body type")
		check(nodes_of(actor,"MeshInstance3D").is_empty(),id+" proxy invisible")
		var shapes := nodes_of(actor,"CollisionShape3D")
		check(shapes.size()==1,id+" single capsule")
		if shapes.size()==1:
			var collider: CollisionShape3D = shapes[0]
			check(collider.shape is CapsuleShape3D,id+" original primitive type")
			if not collider.shape is CapsuleShape3D:
				actor.free()
				visual.free()
				continue
			var source := FileAccess.get_file_as_string("res://boss_source.txt" if data.role=="boss" else "res://enemy_source.txt")
			var radius := source_number(source,"radius")
			var height := source_number(source,"height")
			check(is_equal_approx(collider.shape.radius,radius) and is_equal_approx(collider.shape.height,height),id+" dimensions match actual scene source")
			check(collider.position.is_equal_approx(source_centre(source)),id+" capsule offset matches actual source")
			var before := collider.transform
			visual.scale *= float(data.elite_visual_scale_only)
			check(collider.transform==before and is_equal_approx(collider.shape.radius,radius),id+" elite visual enlargement leaves collision unchanged")
			for turn in 4:
				actor.rotation.y = turn*PI/2
				await physics_frame
				await physics_frame
				var space := actor.get_world_3d()
				check(sweep(space,player,0,player.height/2,actor.basis)<1,id+" player capsule meets actor at turn "+str(turn))
				check(is_equal_approx(sweep(space,player,radius+player.radius+.04,player.height/2,actor.basis),1),id+" player passes alongside at turn "+str(turn))
				check(sweep(space,shot,0,height/2,actor.basis)<1,id+" projectile sphere contacts body at turn "+str(turn))
				check(is_equal_approx(sweep(space,shot,radius+shot.radius+.04,height/2,actor.basis),1),id+" projectile misses outside body at turn "+str(turn))
		actor.free()
		visual.free()
	print("BLENDER_MOBS_CHECKS ",count," checks, ",failures," failures")
	quit(0 if failures==0 else 1)
