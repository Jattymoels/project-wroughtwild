extends Node3D
## INT-03A: compare the actual station body/visual with normal paid kit placement.
## Fixed stock is inspection context, never a pacing or new save migration test.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var build: GridPlacement
var sim: WroughtwildSim

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL HOME_STATION: ",label)

func element(at: Vector3i) -> Dictionary:
	return {"kind":"volume","axis":0,"cell":at*2}

func select(id: StringName, at: Vector3i, turn := 0) -> void:
	build._select_kit(id)
	build.preview_rotation_step = turn
	build.preview_element = element(at)
	build.preview_visible = true

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	player.position = Vector3(-8,1.1,-8)
	build = player.placement
	build.set_physics_process(false)
	build.set_build_mode_enabled(true)
	sim = player.inventory.get_sim()
	for id in ["workbench_kit","mason_yard_kit","forge_kit"]: sim.add_material(id,20)
	_run.call_deferred()

func _run() -> void:
	var old_body := preload("res://scenes/station_site.tscn").instantiate() as StationSite
	add_child(old_body)
	old_body.position = Vector3(-20,0,-20)
	var original_size: Vector3 = old_body.get_node("CollisionShape3D").shape.size
	check(original_size.is_equal_approx(Vector3(.96,2,.96)),"existing station body dimensions are preserved")
	remove_child(old_body)
	old_body.queue_free()
	var ids := [&"workbench_kit",&"mason_yard_kit",&"forge_kit"]
	for index in ids.size():
		var id: StringName = ids[index]
		var at := Vector3i(index*8,0,0)
		for turn in 4:
			select(id,at,turn)
			check(build.shape_size.is_equal_approx(original_size),"placement uses real body extent: %s rotation %d" % [id,turn])
		var before := sim.material_count(id)
		check(build.try_place_block(),"normal paid placement accepts first station: "+String(id))
		check(sim.material_count(id)==before-1,"station consumes exactly its one kit: "+String(id))
		await get_tree().physics_frame
		var site := _station_at(Vector3(at)+Vector3(.5,0,.5))
		check(site!=null,"paid station uses its normal cell-floor anchor: "+String(id))
		if site==null: continue
		check(is_equal_approx(site.rotation.y,PI*1.5),"placed station retains selected rotation: "+String(id))
		select(id,at+Vector3i.RIGHT)
		var refusal := build.element_refusal(build.preview_element)
		check(refusal.is_empty(),"one-cell neighbour fits beside actual station: %s [%s]" % [id,refusal])
		before = sim.material_count(id)
		check(build.try_place_block() and sim.material_count(id)==before-1,"adjacent station can actually be paid/placed: "+String(id))
		await get_tree().physics_frame
		select(id,at)
		before = sim.material_count(id)
		check(not build.try_place_block() and sim.material_count(id)==before,"occupied station cannot consume another kit: "+String(id))
		# Compare the actual authored mesh, including embedded materials, after
		# first selecting a window (two surface overrides) and another family.
		build.selected_material_family = &"cinderglass"
		check(build.select_shape(&"glazed_window"),"real window selection primes its surface materials")
		select(id,at+Vector3i(0,0,4))
		var mesh: Mesh = site._mesh.mesh
		check(build._preview_mesh.mesh==mesh,"world kit ghost shares the actual station mesh: "+String(id))
		check(player.build_palette._mesh(id,true)==mesh,"catalogue and placed station share geometry: "+String(id))
		check(build._preview_mesh.material_override==null,"prior family does not repaint kit ghost: "+String(id))
		var clean := true
		for surface in build._preview_mesh.get_surface_override_material_count():
			clean = clean and build._preview_mesh.get_surface_override_material(surface)==null
		check(clean,"window surface overrides do not leak into station: "+String(id))
		await _preview_pose(id,at+Vector3i(0,0,4))
	# An actual blocker near the top of the existing body must invalidate both
	# preview and final payment, even though the earlier short box missed it.
	var blocker := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.5,.2,.5)
	shape.shape = box
	blocker.add_child(shape)
	blocker.position = Vector3(30.5,1.7,.5)
	add_child(blocker)
	await get_tree().physics_frame
	select(&"workbench_kit",Vector3i(30,0,0))
	var before := sim.material_count("workbench_kit")
	check(not build.element_refusal(build.preview_element).is_empty(),"full existing station height detects an overhead prop")
	check(not build.try_place_block() and sim.material_count("workbench_kit")==before,"overhead obstruction cannot consume kit")
	select(&"forge_kit",Vector3i(34,0,0))
	var before_upgrade := SaveManager.new().capture(player)
	build.set_build_mode_enabled(false)
	sim.add_station("forge_improved")
	for child in get_children():
		if child is StationSite: child.refresh_visual(sim)
	build.set_build_mode_enabled(true)
	build._update_preview()
	var upgraded: Mesh = preload("res://art/station_look.tres").mesh_for(&"forge_improved")
	check(build._preview_mesh.mesh==upgraded and player.build_palette._mesh(&"forge_kit",true)==upgraded,"retained kit selection shows upgraded forge in both previews without reselection")
	check(SaveManager.new().apply(player,JSON.parse_string(JSON.stringify(before_upgrade))),"pre-upgrade save restores with a retained kit selection")
	build._update_preview()
	var basic: Mesh = preload("res://art/station_look.tres").mesh_for(&"forge_basic")
	check(build._preview_mesh.mesh==basic and player.build_palette._mesh(&"forge_kit",true)==basic,"loading an earlier tier refreshes the retained kit ghost without reselection")
	var saved := SaveManager.new().capture(player)
	check(SaveManager.new().apply(player,JSON.parse_string(JSON.stringify(saved))),"normal save/restore accepts the compact workshop arrangement")
	var count := 0
	for child in get_children():
		if child is StationSite:
			count += 1
			check(child.get_node("CollisionShape3D").shape.size==original_size,"restored station keeps original body dimensions")
	check(count==6,"all six paid stations survive restore")
	print("HOME_STATION_PLACEMENT %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _station_at(at: Vector3) -> StationSite:
	for child in get_children():
		if child is StationSite and child.position.is_equal_approx(at): return child
	return null

func _preview_pose(id: StringName, at: Vector3i) -> void:
	# A small ray-only floor makes the ordinary target calculation observable.
	var floor_body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2,.2,2)
	collision.shape = box
	floor_body.add_child(collision)
	floor_body.position = Vector3(at)+Vector3(.5,-.1,.5)
	add_child(floor_body)
	player.global_position = Vector3(at)+Vector3(.5,1.1,3)
	# SpringArm3D maintains its child's position internally. A fixed camera
	# exercises the same real ray without that rig moving the inspection pose.
	var inspection := Camera3D.new()
	add_child(inspection)
	inspection.global_position = Vector3(at)+Vector3(.5,2.8,.5)
	inspection.look_at(Vector3(at)+Vector3(.5,0,.5),Vector3.FORWARD)
	build.camera = inspection
	await get_tree().physics_frame
	await get_tree().physics_frame
	for turn in 4:
		select(id,at,turn)
		build._update_preview()
		check(build.preview_visible,"ordinary ray produces station ghost: "+String(id))
		if not build.preview_visible: continue
		var pose := build.piece_pose(&"cube",build.preview_element,0)
		var foot: Vector3 = pose.centre-Vector3.UP*.5
		check(build._preview_mesh.global_position.is_equal_approx(foot),"authored ghost uses eventual station foot: %s rotation %d" % [id,turn])
		check(is_equal_approx(build._preview_mesh.rotation.y,turn*PI*.5),"authored ghost preserves selected yaw")
	remove_child(floor_body)
	floor_body.queue_free()
	build.camera = player.camera
	inspection.queue_free()
