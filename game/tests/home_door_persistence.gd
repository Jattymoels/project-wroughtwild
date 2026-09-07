extends Node3D
## INT-03B: actual door poses and physics survive the normal atomic save path.
## The seedless fixture uses isolated review stock and never opens a user save.
const OUTPUT := "res://../captures/home-reliability/door-checkpoint.json"
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var build: GridPlacement
var sim: WroughtwildSim
var manager := SaveManager.new()
var cases: Array[Dictionary] = []
var view: Camera3D

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL HOME DOORS: ",label)
	return ok

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position = Vector3(-8,1,-8)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	build = player.placement
	build.set_physics_process(false)
	sim = player.inventory.get_sim()
	sim.add_material("wood",80)
	view = Camera3D.new()
	add_child(view)
	# Independent inspection camera leaves the saved player pose untouched.
	player.camera = view
	_run.call_deferred()

func _run() -> void:
	await _create_doors()
	if cases.size()!=8:
		check(false,"all eight axis, hinge and open-state cases were constructed")
		_finish()
		return
	var open_case: Dictionary = cases[1]
	var doorway := _door(open_case).global_position
	player.position = doorway
	player.rotation.y = .25
	player.spring_arm.rotation.x = -.15
	check(not _capsule_hits(_door(open_case)),"player fits inside the open doorway before saving")
	var original := manager.capture(player)
	var records := 0
	for entry: Dictionary in original.blocks:
		if entry.shape=="door":
			records += 1
			check(entry.has("door_open") and entry.door_open is bool,"door records contain an explicit boolean pose")
		else:
			check(not entry.has("door_open"),"ordinary construction does not gain irrelevant door state")
	check(records==8,"all doors are represented once")
	var inventory_before := sim.inventory().duplicate(true)
	var directory := ProjectSettings.globalize_path(OUTPUT).get_base_dir()
	DirAccess.make_dir_recursive_absolute(directory)
	check(manager.write_data(OUTPUT,original),"normal atomic write accepts the door checkpoint")
	for entry: Dictionary in cases: _door(entry).toggle()
	player.position += Vector3(0,0,8)
	sim.add_material("stone",3)
	check(manager.read(OUTPUT,player),"normal file read restores the matching home: "+manager.last_error)
	await get_tree().physics_frame
	_validate_restored("first read")
	check(manager.capture(player).blocks==original.blocks,"save/read retains exact piece addresses, families, hinge and door state")
	check(sim.inventory()==inventory_before,"restore recovers exact inventory without another placement payment")
	check(player.position.is_equal_approx(doorway),"player restores to the saved doorway position")
	check(not _capsule_hits(_door(open_case)),"restoration does not close the leaf onto the saved player capsule")
	var read_back: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OUTPUT))
	check(manager.apply(player,read_back),"repeated application accepts the same checkpoint")
	await get_tree().physics_frame
	_validate_restored("repeated load")
	check(manager.capture(player).blocks==original.blocks and sim.inventory()==inventory_before,"repeated loads do not toggle doors or charge inventory")
	# Exercise actual E after restoration, aiming at each leaf's current body.
	for entry: Dictionary in cases:
		var door := _door(entry)
		var old_state := door.open
		check(_aim_leaf(door),"restored leaf is a physical E target")
		player.interact()
		check(door.open!=old_state,"E changes each restored door once")
		await get_tree().physics_frame
		check(_aim_leaf(door),"swung leaf remains a physical E target")
		player.interact()
		check(door.open==old_state,"E returns the same door to its saved pose")
		await get_tree().physics_frame
	_validate_restored("after E")
	# Complete validation must happen before inventory, player pose or ANY live
	# building changes, even when a malformed door is the last saved record.
	var invalid_values: Array = [null,0,1,"false","true",[],{}]
	for value in invalid_values:
		var bad := read_back.duplicate(true)
		var last: Dictionary = bad.blocks.pop_back()
		last["door_open"] = value
		bad.blocks.append(last)
		var candidate := WroughtwildSim.new()
		check(candidate.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()),"malformed fixture uses the existing rules definitions")
		check(candidate.import_json(String(bad.sim)),"malformed fixture starts with valid native rules state")
		candidate.add_material("stone",29)
		bad.sim = candidate.export_json()
		bad.player.position = [70,9,70]
		var before := manager.capture(player)
		var first_id := _door(cases[0]).get_instance_id()
		check(not manager.apply(player,bad),"invalid late-record door state is rejected: "+str(value))
		check(manager.capture(player)==before and _door(cases[0]).get_instance_id()==first_id,"invalid door state leaves all live state and existing nodes untouched")
		await get_tree().physics_frame
	_validate_restored("after malformed loads")
	var legacy := read_back.duplicate(true)
	for entry: Dictionary in legacy.blocks: entry.erase("door_open")
	check(manager.apply(player,legacy),"older schema-2 snapshots without door state remain readable")
	await get_tree().physics_frame
	for entry: Dictionary in cases:
		var door := _door(entry)
		check(not door.open,"legacy door retains the historical closed default")
		check(_centre_hit(door)==door and _capsule_hits(door),"legacy closed leaf has matching ray and capsule collision")
	check(manager.apply(player,read_back),"new checkpoint still restores after reading a legacy snapshot")
	await get_tree().physics_frame
	_validate_restored("after legacy load")
	_finish()

func _finish() -> void:
	print("HOME_DOOR_PERSISTENCE %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _create_doors() -> void:
	build.set_build_mode_enabled(true)
	build.selected_material_family = &"wood"
	check(build.select_shape(&"door"),"existing door is selected from the normal catalogue")
	for axis in [0,2]:
		var axis_start := cases.size()
		for hinge in [0,1]:
			for is_open in [false,true]:
				var element := {"kind":"face","axis":axis,"cell":Vector3i(cases.size()*8,0,0)}
				build.preview_element = element
				build.preview_visible = true
				build.preview_rotation_step = hinge
				var before := sim.material_count("wood")
				check(build.try_place_block(),"normal payment places axis %d hinge %d" % [axis,hinge])
				var entry := {"element":element,"open":is_open,"hinge":hinge}
				var door := _door(entry)
				if not check(door!=null,"paid door is represented by its real placed body"): return
				check(door.rotation_step==hinge,"paid door preserves the selected hinge step")
				if hinge==1:
					var first_hinge: Transform3D = cases[axis_start].body
					check(is_equal_approx(first_hinge.basis.x.dot(door.basis.x),-1.0),"odd hinge actually reverses the leaf's body orientation on this axis")
				check(sim.material_count("wood")==before-sim.shape_material_cost("door"),"one door consumes its existing exact cost")
				await get_tree().physics_frame
				if is_open:
					check(_aim_leaf(door),"new closed leaf can be aimed at")
					player.interact()
					await get_tree().physics_frame
				check(door.open==is_open,"fixture records actual E-opened and untouched closed doors")
				entry["body"] = door.transform
				entry["pivot"] = door._pivot.transform
				entry["leaf"] = door._collision_shapes[0].transform
				entry["point"] = door.leaf_point()
				cases.append(entry)
	build.set_build_mode_enabled(false)
	# A non-door record proves the optional field is not spread to every piece.
	check(build.place_piece({"kind":"volume","axis":0,"cell":Vector3i(100,0,0)},&"cube",&"stone")!=null,"ordinary block remains part of the same snapshot")
	# Keep the last record a door so malformed-state checks occur after many
	# otherwise valid records and cannot pass through partial restoration.
	var final_door := _door(cases[-1])
	move_child(final_door,get_child_count()-1)

func _door(entry: Dictionary) -> PlacedBlock:
	for child in get_children():
		if child is PlacedBlock and child.element==entry.element: return child
	return null

func _validate_restored(context: String) -> void:
	for entry: Dictionary in cases:
		var door := _door(entry)
		if not check(door!=null,context+": original door element exists"): continue
		check(door.rotation_step==int(entry.hinge),context+": saved hinge step survives exactly")
		check(door.open==entry.open,context+": saved open/closed state survives")
		check(door.transform.is_equal_approx(entry.body) and door._pivot.transform.is_equal_approx(entry.pivot),context+": saved axis, hinge and visual leaf pose survive")
		check(door._collision_shapes[0].transform.is_equal_approx(entry.leaf) and door.leaf_point().is_equal_approx(entry.point),context+": leaf collision and visible pivot restore together")
		check((_centre_hit(door)!=door)==bool(entry.open),context+": doorway ray is clear exactly when open")
		check(_capsule_hits(door)!=bool(entry.open),context+": original player capsule crosses only an open doorway")
		check(_aim_leaf(door),context+": open or closed leaf remains ray-targetable")

func _centre_hit(door: PlacedBlock) -> Object:
	var normal := door.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(door.global_position+normal,door.global_position-normal)
	query.exclude = [player]
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider")

func _capsule_hits(door: PlacedBlock) -> bool:
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = player.get_node("CollisionShape3D").shape
	query.transform = Transform3D(Basis.IDENTITY,door.global_position)
	query.exclude = [player]
	for hit: Dictionary in get_world_3d().direct_space_state.intersect_shape(query,32):
		if hit.collider==door: return true
	return false

func _aim_leaf(door: PlacedBlock) -> bool:
	var leaf := door._collision_shapes[0]
	var target := door.leaf_point()
	view.global_position = target+leaf.global_basis.z*1.4
	view.look_at(target,Vector3.UP)
	var query := PhysicsRayQueryParameters3D.create(view.global_position,target-leaf.global_basis.z*.2)
	query.exclude = [player]
	return get_world_3d().direct_space_state.intersect_ray(query).get("collider")==door
