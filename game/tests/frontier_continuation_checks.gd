extends Node3D
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL: ",label)

func _ready() -> void:
	get_window().size = Vector2i(1280,720)
	var sim := WroughtwildSim.new()
	check(sim.load_tuning(load("res://scripts/sim.gd").get_tuning_directory()),"load isolated comparison rules")
	check(sim.compare_equipment(-1,"iron_shield").is_empty() and sim.compare_equipment(99).is_empty(),"reject unavailable candidates")
	for base_id in sim.item_base_ids():
		sim.add_material(base_id,1)
		var saved := sim.export_json()
		var view: Dictionary = sim.compare_equipment(-1,base_id)
		check(not view.is_empty() and sim.export_json()==saved,"plain preview leaves state untouched: "+base_id)
		check(sim.equip_from_inventory(base_id),"equip candidate: "+base_id)
		var actual: Dictionary = sim.derived_stats()
		var exact := true
		for key in view.after:
			exact = exact and is_equal_approx(actual[key],view.after[key])
		for skill in view.skills:
			exact = exact and is_equal_approx(sim.skill_cooldown_seconds(skill.id),skill.after.cooldown_seconds)
		check(exact,"preview matches actual equipped stats and cadence: "+base_id)
		check(sim.import_json(saved),"restore isolated fixture")
	var index := sim.roll_item_into_pack("frost_sceptre","wrought",3,117)
	var saved := sim.export_json()
	var rolled: Dictionary = sim.compare_equipment(index)
	check(not rolled.candidate.mods.is_empty() and sim.export_json()==saved,"rolled modifiers retained without preview mutation")
	var panel := InventoryPanel.new()
	panel.sim = sim
	add_child(panel)
	panel.open_panel()
	check(panel.compare_item(index) and panel.is_open() and panel.comparison.visible,"compare opens within pack lifecycle")
	for i in 5:
		await get_tree().process_frame
	check(Rect2(Vector2.ZERO,get_viewport().get_visible_rect().size).encloses(panel.comparison.get_global_rect()),"comparison and its equip/back controls fit the viewport")
	check(panel.equip_compared() and sim.equipment().weapon.base_id=="frost_sceptre","explicit equip applies reviewed candidate")
	var stale := sim.roll_item_into_pack("iron_mace","keen",1,3)
	panel.compare_item(stale)
	sim.discard_pack_item(stale)
	check(not panel.equip_compared(),"stale candidate cannot equip another item")
	panel.close_panel()
	check(not panel.is_open(),"escape/close lifecycle closes comparison")
	panel.queue_free()
	var player: WroughtwildPlayer = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.set_physics_process(false)
	var hands := player.camera.get_node("FirstPersonHands") as FirstPersonHands
	hands.set_process(false)
	var before_camera := player.camera.transform
	var before_body := player.transform
	player.combat.use_skill(PlayerCombat.AREA_SKILL)
	check(hands.remaining>0.0 and hands.active_delivery=="cone","committed skill reaches hand animation")
	var remaining := hands.remaining
	check(not player.combat.use_skill(PlayerCombat.AREA_SKILL) and hands.remaining==remaining,"cooldown refusal does not restart gesture")
	for i in 40:
		hands.sample(0.02)
	check(hands.remaining==0.0 and player.camera.transform==before_camera and player.transform==before_body,"gesture settles without camera or body motion")
	player.first_person = false
	hands._process(0.0)
	check(not hands.visible,"third-person camera hides hands")
	player.first_person = true
	player.placement.build_mode_enabled = true
	hands._process(0.0)
	check(not hands.visible,"build preview hides hands")
	player.placement.build_mode_enabled = false
	var wall := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3,3,0.1)
	shape.shape = box
	wall.add_child(shape)
	add_child(wall)
	wall.global_transform = hands.global_transform.translated_local(Vector3(0,0,-0.4))
	await get_tree().physics_frame
	await get_tree().physics_frame
	hands._process(0.0)
	check(hands.wall_retract>0.5,"nearby solid wall withdraws hands")
	check(player.camera.transform==before_camera and player.transform==before_body,"wall avoidance never pushes the camera or body")
	wall.free()
	player.queue_free()
	_habitat()
	for kind in ["cairn","altar","rift"]:
		var landmark := Landmark.spawn(self,{"id":"fixture","look":kind},Vector3.ZERO)
		check(landmark.get_node_or_null("CurioInlay")!=null,"landmark retains distinct curio detail: "+kind)
		var bodies := 0
		for child in landmark.get_children():
			if child is CollisionShape3D:
				bodies += 1
		check(bodies>0 and landmark.interact_label(sim).contains("nothing"),"landmark collision and interaction remain: "+kind)
		landmark.free()
	print("CODEX_FRONTIER_CONTINUATION %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _habitat() -> void:
	var heights := PackedInt32Array()
	var biomes := PackedInt32Array()
	heights.resize(64*64)
	heights.fill(1)
	biomes.resize(64*64)
	var map := {"width":64,"height":64,"spawn_x":0,"spawn_z":0,"gate_x":63,"gate_z":63,"heights":heights,"biomes":biomes,"biome_defs":[{"id":"forest"}],"nodes":[{"x":30,"z":30}],"landmarks":[]}
	HabitatCover.prepare(map)
	var centres := PackedVector3Array()
	for x in 64:
		for z in 64:
			centres.append(Vector3(x+0.5,0.5,z+0.5))
	var data := {"kinds":{"forest_floor":centres}}
	var faces := PackedVector3Array([Vector3(0,1,0),Vector3(64,1,0),Vector3(64,1,64),Vector3(0,1,0),Vector3(64,1,64),Vector3(0,1,64)])
	var chunk := Node3D.new()
	add_child(chunk)
	chunk.set_meta("surface_sampler",SurfaceSampler.new(faces))
	var count := HabitatCover.build(chunk,data,map,1.0)
	check(count>10 and count<400,"habitat patches provide variety with open space")
	var transforms := []
	var grounded := true
	var cleared := true
	for batch: MultiMeshInstance3D in chunk.get_children():
		for i in batch.multimesh.instance_count:
			var transform := _habitat_transform(batch,i)
			transforms.append(transform)
			grounded = grounded and absf(transform.origin.y-0.965)<0.00005
			cleared = cleared and not map.habitat_reserved.has(Vector2i(floori(transform.origin.x),floori(transform.origin.z)))
	check(grounded and cleared,"habitat roots grounded and resource work area clear")
	for child in chunk.get_children():
		child.free()
	check(HabitatCover.build(chunk,data,map,1.0)==count,"rebuild preserves placement count")
	var second := []
	for batch: MultiMeshInstance3D in chunk.get_children():
		for i in batch.multimesh.instance_count:
			var transform := _habitat_transform(batch,i)
			second.append(transform)
	check(transforms==second,"rebuild preserves exact transforms")
	for child in chunk.get_children():
		child.free()
	chunk.set_meta("surface_sampler",SurfaceSampler.new(PackedVector3Array()))
	check(HabitatCover.build(chunk,data,map,1.0)==0,"removed terrain support removes habitat")
	chunk.free()

func _habitat_transform(batch: MultiMeshInstance3D, index: int) -> Transform3D:
	if DisplayServer.get_name()=="headless":
		return batch.get_meta("world_transforms")[index]
	var transform := batch.multimesh.get_instance_transform(index)
	transform.origin += batch.position
	return transform
