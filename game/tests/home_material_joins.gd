extends Node3D
## INT-03: mixed-material corner edits and real catalogue/ghost/placed roles.
## Uses a seedless fixture and normal save payload; never reads a user save.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var build: GridPlacement
var palette: BuildPalette
const CORNER := Vector3i(10,0,10)

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL HOME MATERIALS: ",label)

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position = Vector3(-8,1,0)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	sim = player.inventory.get_sim()
	build = player.placement
	palette = player.build_palette
	_run.call_deferred()

func _run() -> void:
	var economy_before := sim.export_json()
	_mixed_corner()
	_preview_roles()
	check(sim.export_json()==economy_before,"join and preview fixtures introduce no economy, unlock or build-effect changes")
	for frame in 2: await get_tree().process_frame
	print("HOME_MATERIAL_JOINS %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

func _face(axis: int) -> Dictionary:
	return {"kind":"face","axis":axis,"cell":CORNER}

func _trim() -> MeshInstance3D:
	return build._trims.get("10_0_10") as MeshInstance3D

func _check_current_trims(context: String) -> void:
	var edges: Array = sim.structure_trim_edges()
	check(build.trim_count()==edges.size(),context+": exact native trim population")
	for edge: Dictionary in edges:
		var cell: Vector3i = edge.cell
		var key := "%d_%d_%d" % [cell.x,cell.y,cell.z]
		var trim: MeshInstance3D = build._trims.get(key)
		check(trim!=null,context+": native edge has a visible join "+key)
		if trim==null: continue
		check(trim.material_override==PieceLook.material_for(sim,StringName(edge.family),"frame"),context+": current native adjoining family owns the trim "+key)
		check(trim.global_position.is_equal_approx(edge.centre) and (trim.mesh as BoxMesh).size==Vector3(GridPlacement.TRIM_SIZE,build.registry_grid,GridPlacement.TRIM_SIZE),context+": trim pose and dimensions stay unchanged "+key)

func _mixed_corner() -> void:
	# The x-normal wall has native family priority at this shared edge. Start
	# with only the perpendicular stone wall so the existing trim must change.
	var stone := build.place_piece(_face(2),&"wall_panel",&"stone")
	check(stone!=null and _trim()!=null,"stone wall establishes the original shared-edge trim")
	if stone==null or _trim()==null: return
	var shared := _trim()
	check(shared.material_override==PieceLook.material_for(sim,&"stone","frame"),"initial end post has its stone wall's material")
	var wood := build.place_piece(_face(0),&"wall_panel",&"wood")
	check(wood!=null and _trim()==shared,"adding the perpendicular wall retains the same existing trim node")
	check(shared.material_override==PieceLook.material_for(sim,&"wood","frame"),"existing corner changes to the native timber family immediately")
	_check_current_trims("mixed corner added")
	check(build.remove_piece(wood),"remove the material that currently owns the mixed corner")
	check(_trim()==shared and shared.material_override==PieceLook.material_for(sim,&"stone","frame"),"surviving edge immediately returns to stone after removal")
	var shellstone := build.place_piece(_face(0),&"wall_panel",&"shellstone")
	check(shellstone!=null and _trim()==shared and shared.material_override==PieceLook.material_for(sim,&"shellstone","frame"),"replacement wall updates the surviving join to shellstone")
	_check_current_trims("corner material replaced")
	var manager := SaveManager.new()
	var original := manager.capture(player)
	var expected_blocks: Array = original.blocks.duplicate(true)
	var saved: Dictionary = JSON.parse_string(JSON.stringify(original))
	check(build.remove_piece(shellstone),"prepare a different live corner before loading")
	var pine := build.place_piece(_face(0),&"wall_panel",&"pine")
	check(pine!=null and _trim().material_override==PieceLook.material_for(sim,&"pine","frame"),"the live corner really differs from the saved corner")
	check(manager.apply(player,saved),"ordinary save application restores the mixed-material home fragment")
	check(manager.capture(player).blocks==expected_blocks,"restored piece families and lattice addresses match the saved home exactly")
	check(_trim()!=null and _trim().material_override==PieceLook.material_for(sim,&"shellstone","frame"),"restoring an overlapping existing trim does not retain the pre-load pine")
	_check_current_trims("corner restored")
	check(manager.apply(player,saved),"repeated restoration does not duplicate corner decoration")
	_check_current_trims("corner restored twice")
	for child in get_children():
		if child is PlacedBlock: build.remove_piece(child)
	check(build.trim_count()==0 and sim.structure_trim_edges().is_empty(),"removing both restored walls removes all their joins")

func _preview_roles() -> void:
	palette.open_panel()
	var cases := [
		{"id":"wall_panel","family":"wood","role":"surface","kind":"face","axis":2,"fine":false},
		{"id":"pillar","family":"wood","role":"frame","kind":"edge","axis":1,"fine":false},
		{"id":"beam","family":"resinheart","role":"frame","kind":"edge","axis":0,"fine":false},
		{"id":"pillar","family":"pine","role":"frame","kind":"edge","axis":1,"fine":true},
		{"id":"beam","family":"bog_oak","role":"frame","kind":"edge","axis":0,"fine":true},
		{"id":"door","family":"wood","role":"door","kind":"face","axis":2,"fine":false},
		{"id":"light_panel","family":"woven_reed","role":"surface","kind":"face","axis":2,"fine":false},
		{"id":"glazed_window","family":"cinderglass","role":"surface","kind":"face","axis":2,"fine":false},
		{"id":"beam","family":"wood","role":"frame","kind":"edge","axis":0,"fine":false}]
	for index in cases.size():
		var entry: Dictionary = cases[index]
		if build.fine_mode!=bool(entry.fine): build.toggle_fine()
		palette.select_material(StringName(entry.family))
		palette.select_entry(StringName(entry.id))
		var shape := build.placing_shape()
		var element := {"kind":entry.kind,"axis":entry.axis,"cell":Vector3i(20+index*6,0,10)}
		var piece := build.place_piece(element,shape,StringName(entry.family),build.preview_rotation_step)
		check(piece!=null,"existing selected form places for visual comparison: "+String(shape))
		if piece==null: continue
		var expected := PieceLook.material_for(sim,StringName(entry.family),String(entry.role))
		var preview := palette.picture._material_mesh
		check(preview.get_active_material(0)==expected,"catalogue uses the selected piece's exact material role: "+String(shape))
		check(build._preview_mesh.get_active_material(0)==expected and piece._mesh.get_active_material(0)==expected,"catalogue, world ghost and real piece share the same role material: "+String(shape))
		check(preview.mesh.get_faces()==piece._mesh.mesh.get_faces(),"catalogue and placed shape keep the same triangles: "+String(shape))
		if entry.role=="frame":
			var framing := expected as ShaderMaterial
			check(framing!=null and is_equal_approx(float(framing.get_shader_parameter("frame_shade")),preload("res://art/building_look.tres").frame_shade),"actual frame preview uses the authored darkening: "+String(shape))
			check(is_zero_approx(float(framing.get_shader_parameter("joint_width"))),"frame preview has no surface-board joint seams: "+String(shape))
		if entry.role=="door":
			check(bool((expected as ShaderMaterial).get_shader_parameter("object_space")),"door preview grain uses the same local coordinates as its swinging leaf")
			palette.turn(1)
			check(palette.picture._material_mesh.get_active_material(0)==expected and palette.picture.turn==2,"hinge inspection preserves the actual door material role")
			palette.turn(-1)
		if String(entry.id) in ["light_panel","glazed_window"]:
			var preview_frame := preview.get_active_material(1) as StandardMaterial3D
			var actual_frame := piece._mesh.get_active_material(1) as StandardMaterial3D
			check(preview_frame!=null and actual_frame!=null and preview_frame.albedo_color==actual_frame.albedo_color and preview_frame.transparency==actual_frame.transparency,"integrated panel/window frames keep the same opaque finish in the catalogue")
		build.remove_piece(piece)
	palette.close_panel()
	build.set_build_mode_enabled(false)
