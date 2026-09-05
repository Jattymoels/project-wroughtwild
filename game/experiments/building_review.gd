extends "res://experiments/roof_workshop.gd"
## The workshop rebuilt using the NORMAL catalogue and materials, no lab dressing.
var framed := false

func review_id() -> String:
	return "normal-building"

func shape_fixtures() -> Array:
	return []

func _build_room() -> void:
	check(sim.shape_unlocked("codex_corner") and sim.shape_unlocked("codex_corner_floor"),"normal corner pieces are in the starting palette")
	check(not sim.shape_unlocked("codex_roof_slope"),"normal pitched roofs retain the existing stonecut unlock")
	sim.record_world_effect("stonecut_blocks")
	check(sim.shape_unlocked("codex_roof_slope"),"existing stonecut reward unlocks normal roof forms")
	super._build_room()

func _dress() -> void:
	if framed:
		return
	framed = true
	# Neutral ground supports the inherited ray-placement check outside the house.
	var ground := StaticBody3D.new()
	ground.position = Vector3(7,-0.15,7)
	add_child(ground)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(60,0.2,60)
	mesh.mesh = box
	var ground_material := StandardMaterial3D.new()
	ground_material.albedo_color = Color("43553a")
	mesh.material_override = ground_material
	ground.add_child(mesh)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = box.size
	collision.shape = shape
	ground.add_child(collision)
	# Real, saved beam pieces make the ceiling framing visible in the normal look.
	for x in [4,7,10]:
		for z in range(3,11):
			_put(Vector3i(x,5,z),&"beam",0,&"bog_oak","edge",2)
	# Existing campfire is a placed, fuelled light, with its normal burn lifetime.
	_put(Vector3i(4,1,7),&"campfire",0,&"wood")

func _setup_view() -> void:
	super._setup_view()
	player.camera.get_node("FirstPersonHands").hide()
	caption.text = "NORMAL BUILDING · SHARED WORKSHOP LOOK\nOrdinary palette, placed beams and station models · save / restore checked"

func _probe() -> void:
	super._probe()
	observations["save_scope"] = "normal catalogue and save schema; isolated inspection only"
	check(PieceLook.material_for(sim,&"pine") is ShaderMaterial,"normal pine uses the continuous board material")
	check(PieceLook.material_for(sim,&"pine","frame")!=PieceLook.material_for(sim,&"pine"),"framing has its own dark timber treatment")

func _capture(id: String) -> void:
	caption.text = "NORMAL BUILDING · "+id.to_upper()+"\nOctagonal walls, roofs, timber and framing from the ordinary palette"
	await super._capture(id)
