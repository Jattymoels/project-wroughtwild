extends Node3D
## INT-02A: actual work readouts, streamed saved metadata and opt-in material
## navigation. A five-node fixture uses native tuning; no generated/user save.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var sim: WroughtwildSim
var terrain: Terrain
var native_guides: Array
var original_records: Array

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL DISCOVERY: ",label)

func _buttons(node: Node) -> Array[Button]:
	var result: Array[Button] = []
	for child in node.get_children():
		if child is Button: result.append(child)
		result.append_array(_buttons(child))
	return result

func _visible_text(node: Node) -> String:
	var result := ""
	for child in node.get_children():
		if child is Label and child.is_visible_in_tree(): result += child.text+"\n"
		result += _visible_text(child)
	return result

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.placement.set_physics_process(false)
	player.combat.set_physics_process(false)
	sim = player.combat.sim
	native_guides = sim.rare_resource_guide()
	check(native_guides.size()==5,"native guide exposes the bounded five rare components")
	_setup_resources()
	_run.call_deferred()

func _setup_resources() -> void:
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(
		load("res://scripts/sim.gd").get_tuning_directory().path_join("worldgen.json")))
	var definitions: Array = []
	for index in native_guides.size():
		var info: Dictionary = native_guides[index]
		var row: Dictionary = data.nodes[String(info.id)].duplicate(true)
		# Only fixture positions/identities are authored here; work and yield
		# remain the existing source definition, metadata comes through native.
		row.merge({"type":info.id,"resource_id":"clarity_"+String(info.id),
			"x":8+index*8,"y":0,"z":8,"site_id":"clarity_site_"+String(info.id),
			"harvest_stages":info.harvest_stages,"use_preview":info.use_preview},true)
		definitions.append(row)
	terrain = Terrain.new()
	terrain.name = "Terrain"
	add_child(terrain)
	terrain.set_process(false)
	terrain.set_physics_process(false)
	terrain._sim = sim
	var heights := PackedInt32Array()
	heights.resize(64*64)
	terrain.map = {"cell_size":1.0,"width":64,"height":64,"depth":8,
		"heights":heights,"nodes":definitions,"regions":[],"habitats":[]}
	terrain.nodes_root = Node3D.new()
	terrain.nodes_root.name = "ResourceNodes"
	terrain.add_child(terrain.nodes_root)
	terrain.resource_stream = ResourceStream.new()
	terrain.resource_stream.setup(terrain,definitions)
	original_records = terrain.resource_stream.capture()

func _node(id: String) -> ResourceNode:
	return terrain.resource_stream.materialise("clarity_"+id)

func _run() -> void:
	var before := sim.export_json()
	var control := WroughtwildSim.new()
	check(control.load_tuning(load("res://scripts/sim.gd").get_tuning_directory())
		and control.import_json(before),"independent rules instance restores the same inspection baseline")
	sim.begin_fight(9257)
	control.begin_fight(9257)
	_work_readouts()
	_saved_metadata()
	_stage_boundaries()
	_material_notes()
	check(sim.export_json()==before,"work and material inspection never spend, grant, unlock or change native loadout")
	for index in 8:
		check(sim.player_hit_damage("prototype_heavy_strike",false)==control.player_hit_damage("prototype_heavy_strike",false),
			"inspection leaves the native random hit sequence unchanged: %d" % index)
	if OS.get_cmdline_user_args().has("--discovery-capture"):
		await _capture_ui()
	_contextual_work()
	for frame in 2: await get_tree().process_frame
	print("DISCOVERY_CLARITY %d checks, %d failures" % [checks,failures])
	get_tree().quit(1 if failures else 0)

## Optional rendered evidence uses normal aim/HUD and material-page code. The
## ground and light are an isolated inspection backdrop, not generated content.
func _capture_ui() -> void:
	check(DisplayServer.get_name()!="headless","UI capture requires the rendered review runner")
	if DisplayServer.get_name()=="headless": return
	var before := sim.export_json()
	terrain.resource_stream.restore(original_records)
	var node := _node("ventlung")
	node.work(sim)
	node.work(sim)
	var expected := node.work_view(sim)
	var floor_mesh := MeshInstance3D.new()
	var floor_plane := PlaneMesh.new()
	floor_plane.size = Vector2(16,16)
	floor_mesh.mesh = floor_plane
	var surface := StandardMaterial3D.new()
	surface.albedo_color = Color("686f63")
	surface.roughness = 1.0
	floor_mesh.material_override = surface
	add_child(floor_mesh)
	floor_mesh.global_position = node.global_position+Vector3(0,-0.02,0)
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("29343a")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("b5c1c6")
	environment.environment.ambient_light_energy = 0.65
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48,-28,0)
	sun.light_color = Color("fff0d5")
	sun.light_energy = 1.0
	sun.shadow_enabled = true
	add_child(sun)
	player.global_position = node.global_position+Vector3(0.15,1.0,2.65)
	player.spring_arm.set_physics_process(false)
	player.camera.look_at(node.global_position+Vector3(0,0.6,0),Vector3.UP)
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var output := ProjectSettings.globalize_path("res://../captures/discovery-ui")
	check(DirAccess.make_dir_recursive_absolute(output)==OK,"UI evidence directory is writable in the isolated project")
	for viewport_size in [Vector2i(1280,720),Vector2i(1920,1080)]:
		get_window().size = viewport_size
		player.inventory_panel.close_panel()
		for frame in 8: await get_tree().process_frame
		await get_tree().physics_frame
		player.hud._refresh_crosshair()
		check(player.aim_probe().target==node,"rendered work view uses an actual Ventlung crosshair hit at "+str(viewport_size))
		check(player.hud._work_display.visible and player.hud._work_label.text==expected.text,"rendered HUD shows the native Ventlung stage at "+str(viewport_size))
		_check_bounds(player.hud._work_display,"work widget",viewport_size)
		_check_bounds(player.hud._work_label,"work text",viewport_size)
		await _save_ui(output,"ventlung-work-%dx%d" % [viewport_size.x,viewport_size.y],viewport_size)
		player.inventory_panel.open_panel()
		check(player.inventory_panel.inspect_material("ventlung"),"rendered opt-in Source/use opens through the normal inventory request")
		for frame in 8: await get_tree().process_frame
		player.hud._refresh_crosshair()
		check(not player.hud._work_display.visible,"work overlay stays hidden while reading Source/use")
		_check_bounds(player.inventory_panel._root,"Source/use panel",viewport_size)
		await _save_ui(output,"ventlung-source-use-%dx%d" % [viewport_size.x,viewport_size.y],viewport_size)
	player.inventory_panel.close_panel()
	check(sim.export_json()==before,"rendered framing, work inspection and material navigation leave native possessions unchanged")
	print("DISCOVERY_UI_CAPTURE ",output)

func _check_bounds(control: Control, label: String, viewport_size: Vector2i) -> void:
	var rect := control.get_global_rect()
	check(rect.size.x>0 and rect.size.y>0 and rect.position.x>=0 and rect.position.y>=0
		and rect.end.x<=viewport_size.x+1 and rect.end.y<=viewport_size.y+1,
		"%s fits %s: %s" % [label,viewport_size,rect])

func _save_ui(output: String, id: String, viewport_size: Vector2i) -> void:
	for frame in 2: await get_tree().process_frame
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	check(image.get_size()==viewport_size,"rendered image uses requested pixel size: "+id)
	check(image.save_png(output.path_join(id+".png"))==OK,"saved actual UI evidence: "+id)

func _work_readouts() -> void:
	for info: Dictionary in native_guides:
		var id := String(info.id)
		var node := _node(id)
		check(node!=null,"native resource definition materialises: "+id)
		if node==null: continue
		var stages := PackedStringArray(info.harvest_stages)
		check(stages.size() in [2,3] and node.drive_presses==4,"current native staged-work fixture is two/three descriptions over four presses: "+id)
		if stages.size() not in [2,3]: continue
		var expected := [0,0,1,1] if stages.size()==2 else [0,0,1,2]
		var original_units := node.remaining_units
		var crosshair := node.interact_label(sim)
		for progress in 4:
			node.drive_progress = progress
			var view := node.work_view(sim)
			check(String(view.text).begins_with(stages[expected[progress]]+" · "),"actual work text selects the current physical stage: %s %d/4" % [id,progress])
			check(is_equal_approx(float(view.fraction),float(progress)/4.0) and view.ready,"stage wording preserves authoritative progress and hand-work readiness: "+id)
			check(String(view.text).ends_with("next yield %d %s" % [mini(node.units_per_harvest,original_units),Hud.pretty(id)]),"work display retains the exact next finite yield: "+id)
			player.hud.show_work_view(view)
			check(player.hud._work_display.visible and player.hud._work_label.text==view.text,"ordinary HUD work widget renders the selected stage: "+id)
		check(node.remaining_units==original_units and node.interact_label(sim)==crosshair,"inspection preserves stock and concise crosshair action: "+id)
		check(not crosshair.contains(String(info.use_preview)),"extended use advice stays out of the crosshair: "+id)
		node.drive_progress = 2
	player.hud.show_work_view({})

func _saved_metadata() -> void:
	# Exercise the same record capture, JSON roundtrip and scene materialisation
	# used by saved/unloaded resources, without regenerating a full kilometre.
	var saved: Array = JSON.parse_string(JSON.stringify(terrain.resource_stream.capture()))
	terrain.resource_stream.restore(saved)
	for info: Dictionary in native_guides:
		var node := _node(String(info.id))
		check(node.drive_progress==2 and node.remaining_units==int(terrain.resource_stream.records[node.resource_id].remaining_units),"record restore keeps exact partial harvesting: "+String(info.id))
		check(PackedStringArray(node.get_meta("rare_stages"))==PackedStringArray(info.harvest_stages),"loaded scene receives its saved native harvest metadata: "+String(info.id))
		check(String(node.work_view(sim).text).begins_with(String(info.harvest_stages[1])+" · "),"restored work text reflects partial progress: "+String(info.id))
	var historical: Array = saved.duplicate(true)
	historical[0].harvest_stages = ["Saved opening step","Saved release step"]
	terrain.resource_stream.restore(historical)
	var id := String(historical[0].name).trim_prefix("clarity_")
	check(String(_node(id).work_view(sim).text).begins_with("Saved release step · "),"saved profile wording is authoritative over current tuning")
	for row: Dictionary in saved: row.erase("harvest_stages")
	terrain.resource_stream.restore(saved)
	for info: Dictionary in native_guides:
		var node := _node(String(info.id))
		check(node.drive_progress==2 and String(node.work_view(sim).text).begins_with(String(info.harvest_stages[1])+" · "),"older optional metadata recovers wording without resetting work: "+String(info.id))

func _stage_boundaries() -> void:
	var node := ResourceNode.new()
	node.visual = &"lanternheart"
	node.drive_presses = 4
	node.set_meta("rare_stages",["Open","Lift"])
	for entry in [[0,"Open"],[1,"Open"],[2,"Lift"],[3,"Lift"],[-4,"Open"],[12,"Lift"]]:
		node.drive_progress = entry[0]
		check(String(node.work_view(sim).text).begins_with(String(entry[1])+" · "),"fewer stages clamp safely at progress "+str(entry[0]))
	node.set_meta("rare_stages",PackedStringArray(["A","B","C","D","E","F","G","H"]))
	for entry in [[0,"A"],[1,"C"],[2,"E"],[3,"G"],[4,"H"]]:
		node.drive_progress = entry[0]
		check(String(node.work_view(sim).text).begins_with(String(entry[1])+" · "),"more descriptions never create extra presses: "+str(entry[0]))
	node.set_meta("rare_stages",["Only stage"])
	node.drive_progress = 3
	check(String(node.work_view(sim).text).begins_with("Only stage · "),"single-stage metadata remains valid throughout work")
	node.drive_presses = 0
	node.drive_progress = 0
	check(String(node.work_view(sim).text).begins_with("Only stage · 0/1"),"zero authored presses retains the existing safe denominator")
	for metadata: Variant in [[],{},"not a stage list",[" ",27,null]]:
		node.set_meta("rare_stages",metadata)
		check(String(node.work_view(sim).text).begins_with("Folding back husks · "),"malformed optional metadata retains the ordinary verb")
	node.set_meta("rare_stages",[" ","  Work carefully  ",27])
	check(String(node.work_view(sim).text).begins_with("Work carefully · "),"nonempty text is trimmed and invalid stage entries are ignored")
	node.remove_meta("rare_stages")
	check(String(node.work_view(sim).text).begins_with("Folding back husks · "),"missing metadata keeps ordinary resource feedback")
	node.set_meta("rare_stages",["Never override a refusal"])
	node.heat_to_work = 2
	check(not node.work_view(sim).ready and String(node.work_view(sim).text).begins_with(node.work_refusal()),"stage prose never hides existing heat refusal")
	node.heat_to_work = 0
	node.tool_item = &"timber_wedge"
	check(not node.work_view(sim).ready and String(node.work_view(sim).text).begins_with("Needs timber wedge"),"stage prose never grants a missing seam tool")
	node.wedge_set = true
	check(node.work_view(sim).ready and String(node.work_view(sim).text).begins_with("Driving wedge"),"a set seam retains its existing work action")
	node.remaining_units = 1
	node.units_per_harvest = 9
	check(String(node.work_view(sim).text).ends_with("next yield 1 wood"),"nearly depleted nodes still display only remaining stock")
	node.remaining_units = 0
	check(node.work_view(sim).is_empty(),"depleted nodes offer no work text")
	node.free()

func _material_notes() -> void:
	var pack := player.inventory_panel
	for info: Dictionary in native_guides:
		var id := String(info.id)
		var notes := MaterialGuide.describe(sim,id)
		check(not notes.is_empty() and String(notes.source).contains(String(info.display_name)),"rare source notes use the native specimen name: "+id)
		for property in info.properties:
			check(String(notes.source).contains(String(property)),"source notes retain the native physical property: "+id)
		check(notes.use==info.use_preview,"rare use advice comes directly from native definition: "+id)
		check(String(notes.work).contains(" → ".join(info.harvest_stages)),"opt-in work details retain all native stages: "+id)
		var consumers: Array = []
		for recipe_id in sim.recipe_ids():
			if sim.recipe(recipe_id).get("inputs",{}).has(id): consumers.append(String(recipe_id))
		check(not consumers.is_empty() and notes.uses==consumers,"every use link corresponds exactly to an actual native recipe input: "+id)
		check(notes.recipe=="" and notes.shape=="","raw finite components add no producer recipe or placement form: "+id)
		pack.open_panel()
		check(pack.inspect_material(id) and pack.guide.page=="Material","existing inventory request accepts the rare component: "+id)
		check(_visible_text(pack.guide).contains(String(info.use_preview)),"opt-in material page shows useful payoff immediately: "+id)
		check(not _visible_text(pack.guide).contains(String(info.harvest_stages[0])),"full gathering instructions remain collapsed by default: "+id)
		var expanded := false
		for button in _buttons(pack.guide):
			if button.text=="Work and collection":
				button.button_pressed = true
				expanded = true
		check(expanded and _visible_text(pack.guide).contains(String(info.harvest_stages[0])),"deliberate Details exposes the native work sequence: "+id)
		var consumer := String(consumers[0]) if not consumers.is_empty() else ""
		check(pack.open_recipe(consumer) and player.work_panel._station==null,"rare consumer link opens the existing hand-context reference: "+id)
		check(player.work_panel.catalogue._action.disabled,"reading a rare consumer never enables remote station crafting: "+id)
		player.work_panel.close_panel()
	pack.close_panel()
	check(MaterialGuide.describe(sim,"not_a_material").is_empty(),"unsupported IDs acquire no invented source or use")
	check(MaterialGuide.describe(sim,"wood").source==MaterialGuide.SOURCES.wood[0],"existing early material advice is preserved")

func _contextual_work() -> void:
	terrain.resource_stream.restore(original_records)
	var before := sim.export_json()
	for info: Dictionary in native_guides:
		var node := _node(String(info.id))
		var original_units := node.remaining_units
		var expected_yield := mini(node.units_per_harvest,original_units)
		check(node.heat_to_work==0 and node.tool_item==&"","ordinary contextual work remains sufficient: "+String(info.id))
		for press in node.drive_presses-1:
			var result := node.work(sim)
			check(not result.has("granted") and node.remaining_units==original_units,"wording adds no early payout: %s press %d" % [info.id,press+1])
		var completed := node.work(sim)
		check(int(completed.get("granted",0))==expected_yield and node.remaining_units==original_units-expected_yield,"the existing final press yields the same finite quantity: "+String(info.id))
		check(not terrain.resource_stream.has_resource(node.resource_id) and node.work_view(sim).is_empty(),"completed work leaves the existing depleted state: "+String(info.id))
	check(sim.export_json()==before,"resource work still returns its payout to the caller without silently crediting inventory")
