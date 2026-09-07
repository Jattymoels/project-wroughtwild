extends Node3D
## INT-03B: authored solid cells exercise the normal Terrain field, digging,
## placement payment and SaveManager. Chunk art is irrelevant to this rule test.
class PlacementTerrain extends Terrain:
	var rebuilt_chunks := 0
	func _rebuild_chunk(_x: int, _z: int) -> void:
		rebuilt_chunks += 1

var checks := 0
var failures := 0
var player: WroughtwildPlayer
var build: GridPlacement
var sim: WroughtwildSim
var terrain: PlacementTerrain

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL HOME_TERRAIN: ", label)

func element(kind: String, cell: Vector3i, axis := 0) -> Dictionary:
	return {"kind":kind, "axis":axis, "cell":cell}

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.position = Vector3(-8, 2, -8)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.spring_arm.set_physics_process(false)
	build = player.placement
	build.set_physics_process(false)
	build.set_build_mode_enabled(true)
	sim = player.inventory.get_sim()
	sim.add_material("wood", 200)
	sim.add_material("iron_ingot", 40)
	terrain = PlacementTerrain.new()
	terrain.name = "Terrain"
	terrain._sim = sim
	terrain.block_rules = sim.block_rules()
	add_child(terrain)
	_run.call_deferred()

func _reset(rocks: Array[Vector3i]) -> void:
	for child in get_children():
		if child is PlacedBlock:
			remove_child(child)
			child.free()
	sim.structure_clear()
	build.refresh_trims()
	var blocks := PackedByteArray()
	blocks.resize(16*16*8)
	for cell in rocks:
		# Soil is a real hand-diggable terrain kind; no work rule is bypassed.
		blocks[(cell.z*16+cell.x)*8+cell.y] = 2
	terrain.map = {"width":16, "height":16, "depth":8, "cell_size":1.0,
		"blocks":blocks, "heights":PackedInt32Array()}
	terrain._blocks = blocks.duplicate()
	terrain.broken.clear()

func _select(shape: StringName, address: Dictionary) -> void:
	var info := sim.shape(shape)
	build.fine_mode = bool(info.get("fine", false))
	# Native shape dictionaries include an empty fine_of for full-size pieces.
	var base := StringName(info["fine_of"]) if build.fine_mode else shape
	check(build.select_shape(base), "select existing shape "+String(shape))
	build.selected_material_family = &"iron" if shape==&"girder" else &"wood"
	build._refresh_selection()
	build.preview_element = address
	build.preview_visible = true
	build.preview_valid = true # A stale green preview still must be revalidated.
	check(build.placing_shape()==shape, "selection resolves exact full/fine form "+String(shape))

func _case(label: String, shape: StringName, address: Dictionary, rocks: Array[Vector3i], accepted: bool) -> void:
	_reset(rocks)
	await get_tree().physics_frame
	_select(shape, address)
	var source := "iron_ingot" if shape==&"girder" else "wood"
	var before := sim.material_count(source)
	var refusal := build.element_refusal(address)
	check(refusal.is_empty() if accepted else refusal.begins_with("Inside terrain."), label+" preview: "+refusal)
	var placed := build.try_place_block()
	check(placed==accepted, label+" final placement agrees with terrain")
	check(sim.material_count(source)==before-(sim.shape_material_cost(shape) if accepted else 0), label+" exact cost or no spending")
	check(sim.structure_piece_count()==(1 if accepted else 0), label+" native ownership agrees")

func _run() -> void:
	if "--placement-timing" in OS.get_cmdline_user_args():
		await _placement_timing()
		print("HOME_PLACEMENT_TIMING %d checks, %d failures" % [checks, failures])
		get_tree().quit(1 if failures else 0)
		return
	await _case("full cube clear", &"cube", element("volume",Vector3i(4,2,4)), [], true)
	await _case("full cube buried", &"cube", element("volume",Vector3i(4,2,4)), [Vector3i(2,1,2)], false)
	await _case("full cube off-grid far side", &"cube", element("volume",Vector3i(3,2,4)), [Vector3i(2,1,2)], false)
	await _case("negative anchor crosses world edge", &"cube", element("volume",Vector3i(-1,2,4)), [Vector3i(0,1,2)], false)
	await _case("negative fine cell remains outside rock", &"half_cube", element("volume",Vector3i(-1,2,4)), [Vector3i(0,1,2)], true)
	await _case("fine cube beside rock", &"half_cube", element("volume",Vector3i(3,2,4)), [Vector3i(2,1,2)], true)
	await _case("fine cube inside rock", &"half_cube", element("volume",Vector3i(4,2,4)), [Vector3i(2,1,2)], false)
	await _case("off-grid panel far side buried", &"wall_panel", element("face",Vector3i(5,2,4),2), [Vector3i(3,1,1),Vector3i(3,1,2)], false)
	await _case("tall door top buried", &"door", element("face",Vector3i(4,2,4),2), [Vector3i(2,2,1),Vector3i(2,2,2)], false)
	await _case("tall door lines mine wall", &"door", element("face",Vector3i(4,2,4),2), [Vector3i(2,1,1),Vector3i(2,2,1)], true)
	await _case("surface carpet remains legal", &"floor_slab", element("face",Vector3i(4,2,4),1), [Vector3i(2,0,2)], true)
	await _case("off-grid slab far side buried", &"floor_slab", element("face",Vector3i(5,4,4),1), [Vector3i(3,1,2),Vector3i(3,2,2)], false)
	await _case("x girder far end buried", &"girder", element("edge",Vector3i(4,4,4),0), [Vector3i(3,1,1),Vector3i(3,1,2),Vector3i(3,2,1),Vector3i(3,2,2)], false)
	await _case("z girder far end buried", &"girder", element("edge",Vector3i(4,4,4),2), [Vector3i(1,1,3),Vector3i(1,2,3),Vector3i(2,1,3),Vector3i(2,2,3)], false)
	await _case("girder touching rock edge", &"girder", element("edge",Vector3i(4,4,4),0), [Vector3i(3,1,1)], true)
	await _case("off-grid post top buried", &"pillar", element("edge",Vector3i(4,3,4),1), [Vector3i(1,2,1),Vector3i(1,2,2),Vector3i(2,2,1),Vector3i(2,2,2)], false)
	await _case("fine post below upper rock", &"half_pillar", element("edge",Vector3i(4,3,4),1), [Vector3i(1,2,1),Vector3i(1,2,2),Vector3i(2,2,1),Vector3i(2,2,2)], true)
	_native_footprints()
	await _saved_excavation()
	print("HOME_TERRAIN_PLACEMENT %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func _native_footprints() -> void:
	# Baseline production has no binding. Its normal player placement still
	# exercises every regression above and the persistence checks below.
	if not sim.has_method("lattice_footprint"):
		print("HOME_TERRAIN: baseline has no footprint inspection binding")
		return
	var cases := [
		["cube",element("volume",Vector3i(-1,2,4)),8],
		["half_cube",element("volume",Vector3i(-1,2,4)),1],
		["wall_panel",element("face",Vector3i(5,2,4),2),4],
		["door",element("face",Vector3i(4,2,4),2),8],
		["girder",element("edge",Vector3i(4,4,4),0),4],
		["girder",element("edge",Vector3i(4,4,4),2),4],
		["half_pillar",element("edge",Vector3i(4,3,4),1),1],
	]
	for entry in cases:
		var footprint: Array = sim.call("lattice_footprint",entry[0],entry[1])
		check(footprint.size()==entry[2], "native footprint extent "+String(entry[0]))
		var unique := {}
		for covered in footprint:
			unique[str(covered)] = true
			check(sim.shape_accepts(entry[0],covered), "covered element preserves native kind/axis")
		check(unique.size()==footprint.size(), "native footprint has no repeated elements")
	var empty: Array = sim.call("lattice_footprint","missing_shape",element("volume",Vector3i.ZERO))
	check(empty.is_empty(), "unknown shape cannot expose a guessed footprint")
	for invalid in [element("face",Vector3i.ZERO,1),element("not_a_kind",Vector3i.ZERO),{"kind":"volume","cell":"bad"}]:
		empty = sim.call("lattice_footprint","cube",invalid)
		check(empty.is_empty(), "invalid anchor cannot expose a guessed footprint")
	empty = sim.call("lattice_footprint","girder",element("edge",Vector3i.ZERO,3))
	check(empty.is_empty(), "out-of-range axis is refused")

func _saved_excavation() -> void:
	var solid := Vector3i(2,1,2)
	var extra := Vector3i(6,1,6)
	var address := element("volume",Vector3i(3,2,4))
	_reset([solid,extra])
	await get_tree().physics_frame
	_select(&"cube",address)
	check(build.element_refusal(address).begins_with("Inside terrain."), "future hole initially refuses placement")
	check(terrain.break_block(solid.x,solid.y,solid.z)=="dirt", "ordinary hand dig removes blocking soil")
	check(terrain.block_at(solid.x,solid.y,solid.z)==0 and terrain.broken.has(solid), "edited field records exact hole")
	var saves := SaveManager.new()
	var saved := saves.capture(player)
	check(saved.get("broken_blocks",[])==[[solid.x,solid.y,solid.z]], "normal capture includes only actual excavation")
	check(terrain.break_block(extra.x,extra.y,extra.z)=="dirt", "later dig establishes restoration must replace edits")
	var inventory_before := sim.export_json()
	check(saves.apply(player,JSON.parse_string(JSON.stringify(saved))), "edited home terrain restores through normal save: "+saves.last_error)
	check(terrain.block_at(solid.x,solid.y,solid.z)==0 and terrain.block_at(extra.x,extra.y,extra.z)!=0 and terrain.broken==[solid], "saved hole remains and later excavation is filled")
	check(sim.export_json()==inventory_before, "restoring edited terrain leaves native inventory exact")
	_select(&"cube",address)
	var before := sim.material_count("wood")
	check(build.element_refusal(address).is_empty() and build.try_place_block(), "normal placement uses restored hole")
	check(sim.material_count("wood")==before-sim.shape_material_cost("cube"), "restored hole permits one exact payment")
	var built_save := saves.capture(player)
	# Pre-fix saves can contain this piece before the terrain was dug. Loading
	# owns placement restoration and must not apply today's stricter preview.
	built_save.erase("broken_blocks")
	before = sim.material_count("wood")
	for iteration in 2:
		check(saves.apply(player,JSON.parse_string(JSON.stringify(built_save))), "old buried building restores, pass %d" % iteration)
		check(sim.structure_piece_count()==1 and sim.structure_occupied(address), "existing buried ownership remains on load")
		check(terrain.block_at(solid.x,solid.y,solid.z)!=0, "old snapshot without edits restores pristine terrain")
		check(sim.material_count("wood")==before, "old building restore neither repays nor refunds")
	check(terrain.rebuilt_chunks>0, "ordinary dig and restore request terrain rebuilds")

func _placement_timing() -> void:
	# Separate from the default regression suite so preserved baseline builds
	# can produce a successful timing report despite their expected rule failures.
	get_window().size = Vector2i(1280,720)
	Engine.max_fps = 0
	if DisplayServer.get_name()!="headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	for child in player.get_children():
		if child is CanvasLayer: child.hide()
	var inspection := Camera3D.new()
	inspection.name = "PlacementTimingCamera"
	inspection.fov = 70
	add_child(inspection)
	inspection.make_current()
	build.camera = inspection
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45,-25,0)
	sun.light_energy = 1.2
	add_child(sun)
	# This authored floor is both a real terrain field and a matching physics
	# surface. No generator, decorative population or streaming timing is claimed.
	var floor_cells: Array[Vector3i] = []
	for x in 16:
		for z in 16: floor_cells.append(Vector3i(x,0,z))
	_reset(floor_cells)
	var ground := StaticBody3D.new()
	ground.set_meta("terrain_chunk",true)
	ground.position = Vector3(8,.5,8)
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(16,1,16)
	collision.shape = box
	ground.add_child(collision)
	var visual := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = box.size
	visual.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("827862")
	visual.material_override = material
	ground.add_child(visual)
	terrain.add_child(ground)
	var report := {
		"scope":"Active real-camera placement on an authored terrain field; no world-generation or streaming measurement.",
		"display_server":DisplayServer.get_name(), "resolution":[1280,720],
		"warmup_frames":90, "sample_frames":600, "preview_calls_per_frame":1,
		"cpu_measure":"Wall time in microseconds around one synchronous GridPlacement._update_preview call; no render wait included.",
		"frame_measure":"Milliseconds between consecutive process_frame signals with one preview call per frame; includes rendering when rendered.",
		"views":[],
	}
	player.global_position = Vector3(6.5,2,9.5)
	inspection.global_position = Vector3(6.5,5,7.5)
	inspection.look_at(Vector3(6.5,1,6.5))
	_select(&"cube",element("volume",Vector3i(12,2,12)))
	for frame in 3: await get_tree().physics_frame
	var trace := build._get_view_trace()
	check(not trace.is_empty() and trace.get("collider")==ground, "timed ground camera hits the real terrain floor")
	check(sim.structure_piece_count()==0, "timed ground view uses direct surface targeting without structure")
	build._update_preview()
	check(build.preview_visible and build.preview_valid, "timed ground view produces a valid full-cube ghost")
	await _time_preview_view("direct-ground-cube",inspection,report)
	# An actual paid beam supplies the native structure. The camera passes just
	# above and beside its collision, so the normal ray has no hit and must use
	# extend_target to find a free neighbouring element.
	_select(&"beam",element("edge",Vector3i(8,6,12),0))
	check(build.try_place_block(), "timed extension starts from a normally paid beam")
	player.global_position = Vector3(2.5,2.4,6.55)
	inspection.global_position = Vector3(2.5,3.35,6.55)
	inspection.look_at(Vector3(11.5,3.35,6.55))
	for frame in 3: await get_tree().physics_frame
	trace = build._get_view_trace()
	check(trace.is_empty(), "timed extension camera ray misses ground and built geometry")
	var candidate := build.extend_target(inspection.global_position,-inspection.global_transform.basis.z,
		build.placement_range,inspection.global_position.distance_to(player.global_position))
	check(not candidate.is_empty(), "timed extension resolves an actual native candidate through empty air")
	if not candidate.is_empty():
		check(sim.structure_touches("beam",candidate) and build.element_accepts(candidate), "timed extension is free and touches the existing structure")
	build._update_preview()
	check(build.preview_visible and build.preview_valid and build.preview_element==candidate,
		"normal timed preview uses the verified extension candidate")
	await _time_preview_view("empty-air-beam-extension",inspection,report)
	report["checks"] = checks
	report["failures"] = failures
	var directory := ProjectSettings.globalize_path("res://../captures")
	DirAccess.make_dir_recursive_absolute(directory)
	var path := directory.path_join("placement-timing.json")
	var file := FileAccess.open(path,FileAccess.WRITE)
	check(file!=null, "placement timing report opens in the ignored review copy")
	if file!=null:
		file.store_string(JSON.stringify(report,"  "))
		file.close()
		print("HOME_PLACEMENT_TIMING_REPORT ",path)

func _time_preview_view(id: String, inspection: Camera3D, report: Dictionary) -> void:
	var held := sim.inventory().duplicate(true)
	var pose := inspection.global_transform
	var wanted := build.preview_element.duplicate(true)
	for frame in 90:
		await get_tree().process_frame
		build._update_preview()
	var cpu_us: Array[float] = []
	var frame_ms: Array[float] = []
	var last_frame := Time.get_ticks_usec()
	for frame in 600:
		await get_tree().process_frame
		var frame_at := Time.get_ticks_usec()
		frame_ms.append(float(frame_at-last_frame)/1000.0)
		last_frame = frame_at
		var begin := Time.get_ticks_usec()
		build._update_preview()
		cpu_us.append(float(Time.get_ticks_usec()-begin))
	cpu_us.sort()
	frame_ms.sort()
	check(inspection.global_transform==pose, id+" keeps its fixed camera")
	check(build.preview_visible and build.preview_valid and build.preview_element==wanted, id+" keeps the verified active preview")
	check(sim.inventory()==held, id+" preview timing never spends materials")
	var image_name := ""
	if DisplayServer.get_name()!="headless":
		await RenderingServer.frame_post_draw
		var directory := ProjectSettings.globalize_path("res://../captures")
		DirAccess.make_dir_recursive_absolute(directory)
		image_name = "placement-"+id+".png"
		check(get_viewport().get_texture().get_image().save_png(directory.path_join(image_name))==OK, id+" records the actual timed view")
	report.views.append({"id":id,"image":image_name,"camera":[pose.origin.x,pose.origin.y,pose.origin.z],
		"preview_element":str(wanted),"cpu_median_us":cpu_us[300],"cpu_p95_us":cpu_us[569],
		"frame_median_ms":frame_ms[300],"frame_p95_ms":frame_ms[569],"samples":600,
		"draw_calls":Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)})
