extends Node3D
## Real kit placement, supported spans, clearances, panels, one-owner cargo,
## mid-trip restoration and existing resource impact. No forced enemy clears.
var checks := 0
var failures := 0
var sim: WroughtwildSim
var player: WroughtwildPlayer
var fixtures: Dictionary = {}


func check(condition: bool, text: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: contraptions: ", text)


func _ready() -> void:
	call_deferred("_run")


func _body(at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.position = at
	var shape := BoxShape3D.new()
	shape.size = size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("737464")
	material.roughness = 1.0
	mesh.material_override = material
	body.add_child(mesh)
	add_child(body)
	return body


func _run() -> void:
	sim = load("res://scripts/sim.gd").shared()
	check(sim.last_error().is_empty(), "native tuning loaded")
	check(sim.contraption_load(""), "empty legacy fixture state loads")
	sim.add_station("workbench")
	_body(Vector3(0, -0.5, 0), Vector3(50, 1, 30))
	_body(Vector3(12.5, 2, 0.5), Vector3(3, 4, 3))
	player = preload("res://scenes/player.tscn").instantiate()
	player.position = Vector3(-3, 0.96, -1)
	add_child(player)
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_process(false)
	player.placement.set_physics_process(false)
	player.placement.set_build_mode_enabled(true)
	for frame in 3: await get_tree().physics_frame
	var cells := {
		"cargo_winch": Vector3i(0, 0, 0), "winch_landing": Vector3i(24, 8, 0),
		"stormglass_lever": Vector3i(-6, 0, 4), "lantern_lamp": Vector3i(-8, 0, 10),
		"magnetic_sorter": Vector3i(-6, 0, -8), "ventlung_bellows": Vector3i(10, 0, -10)
	}
	for kind in cells:
		fixtures[kind] = _place(String(kind), cells[kind])
		await get_tree().physics_frame
	if fixtures.values().has(null):
		_finish()
		return
	var drum: ContraptionSite = fixtures.cargo_winch
	var landing: ContraptionSite = fixtures.winch_landing
	var lever: ContraptionSite = fixtures.stormglass_lever
	var lamp: ContraptionSite = fixtures.lantern_lamp
	var sorter: ContraptionSite = fixtures.magnetic_sorter
	var bellows: ContraptionSite = fixtures.ventlung_bellows
	check(drum.supported() and landing.supported(), "two fixed endpoints have actual floor support")
	check(drum.link_clear(landing), "raised landing has basket clearance through full span")
	check(sim.contraption_link(drum.machine_key, landing.machine_key, drum.link_clear(landing)).ok, "link supported cargo span")
	drum.refresh_from_sim()
	check((drum._cable.global_transform * Vector3(0, -0.5, 0)).is_equal_approx(drum.cable_anchor())
		and (drum._cable.global_transform * Vector3(0, 0.5, 0)).is_equal_approx(landing.cable_anchor()),
		"sloped authored cable reaches both endpoints without world-axis stretching")
	check(sim.contraption_link(lever.machine_key, drum.machine_key, lever.link_clear(drum)).ok, "link actual Stormglass receiver")
	check(not lever.perform("pulse").ok, "pulse cannot invent energy")
	check(sim.contraption_state(lever.machine_key).pulses == 1, "unwound drum receives a visible pulse")
	check(drum.perform("wind").ok, "ordinary hand winding works")
	sim.add_material("raw_slate", 18)
	check(sim.contraption_deposit(drum.machine_key, "raw_slate", 18).moved == 18, "basket receives explicitly loaded building supplies")
	check(sim.material_count("raw_slate") == 0, "loaded cargo has left pack exactly once")
	for excluded in ["vanguard", "iron_chest_armour"]:
		check(not sim.contraption_deposit(drum.machine_key, excluded, 1).ok, excluded + " cannot enter an ingredient basket")
		var incompatible: Dictionary = JSON.parse_string(sim.contraption_save())
		for machine in incompatible.machines:
			if machine.key == drum.machine_key: machine.cargo = {excluded: 1}
		check(not sim.contraption_validate(JSON.stringify(incompatible)), excluded + " cannot enter restored ingredient cargo")
	check(lever.perform("pulse").ok, "complete connected experiment departs through actual geometry")
	check(sim.contraption_state(drum.machine_key).energy == 0, "signal spends stored winding only once")
	drum._physics_process(0.4)
	var state: Dictionary = sim.contraption_state(drum.machine_key)
	check(state.moving and state.progress > 0, "engine time advances native trip")
	check(drum._basket.global_position.distance_to(drum.cable_anchor()) > 0.5, "authored basket visibly moves along its span")
	var obstacle := _body(Vector3(6, 3.3, 0.5), Vector3(1, 4, 2))
	for frame in 2: await get_tree().physics_frame
	check(not drum.span_clear(), "full basket sweep detects an added wall")
	var stopped_progress: float = sim.contraption_state(drum.machine_key).progress
	drum._physics_process(0.4)
	check(sim.contraption_state(drum.machine_key).progress == stopped_progress, "obstruction pauses without losing cargo or progress")
	obstacle.free()
	for frame in 2: await get_tree().physics_frame
	check(drum.span_clear(), "cleared span can resume")
	var snapshot: String = sim.contraption_save()
	check(sim.contraption_validate(snapshot), "travelling native snapshot validates")
	check(sim.contraption_load(snapshot), "travelling native snapshot restores")
	ContraptionSite.restore_all(self, sim)
	for node in get_tree().get_nodes_in_group("contraptions"): node.set_physics_process(false)
	check(sim.contraption_save() == snapshot, "scene restoration grants nothing and does not advance time")
	drum = ContraptionSite.find_site(get_tree(), "fixture_0_0_0")
	landing = ContraptionSite.find_site(get_tree(), "fixture_24_8_0")
	lever = ContraptionSite.find_site(get_tree(), "fixture_-6_0_4")
	lamp = ContraptionSite.find_site(get_tree(), "fixture_-8_0_10")
	sorter = ContraptionSite.find_site(get_tree(), "fixture_-6_0_-8")
	bellows = ContraptionSite.find_site(get_tree(), "fixture_10_0_-10")
	for frame in 2: await get_tree().physics_frame
	drum._physics_process(20.0)
	check(sim.contraption_state(drum.machine_key).at_landing and sim.contraption_state(drum.machine_key).completed_trips == 1, "resume arrives exactly once")
	check(sim.contraption_withdraw(landing.machine_key, "cargo", "raw_slate", 18).moved == 18, "collect at actual landing")
	check(not sim.contraption_withdraw(landing.machine_key, "cargo", "raw_slate", 18).ok, "second collection cannot duplicate cargo")
	check(sim.contraption_link(lever.machine_key, lamp.machine_key, lever.link_clear(lamp)).ok, "lever can select a lamp receiver")
	check(lever.perform("pulse").ok, "physical signal toggles lamp")
	lamp.refresh_from_sim()
	check(not (lamp._visual.get_node("WarmInterior") as OmniLight3D).visible, "lamp illumination matches authoritative shutter state")
	lamp.interact(player)
	check(player.work_panel.is_open() and player.work_panel._custom_title == "Lanternheart lamp", "normal interaction opens familiar work panel")
	lamp._panel._operate("toggle")
	check((lamp._visual.get_node("WarmInterior") as OmniLight3D).visible, "panel switches the real placed lamp")
	player.work_panel.close_panel()
	sim.add_material("iron_ore", 10)
	sim.add_material("raw_reed", 10)
	check(sim.contraption_deposit(sorter.machine_key, "iron_ore", 10).moved == 10, "hand-feed ferrous input")
	check(sim.contraption_deposit(sorter.machine_key, "raw_reed", 10).moved == 10, "hand-feed mixed organic input")
	check(sorter.perform("sort").ok, "first visible hand operation sorts batch")
	sorter.perform("sort")
	var sorted: Dictionary = sim.contraption_state(sorter.machine_key)
	check(sorted.ferrous.get("iron_ore", 0) == 10 and sorted.remainder.get("raw_reed", 0) == 10, "only configured ferrous ingredients follow Pullstone")
	var resource: ResourceNode = preload("res://scenes/resource_node.tscn").instantiate()
	resource.position = bellows.position + Vector3(1.7, 0, 0)
	resource.visual = &"seam"
	resource.material_family = &"split_stone"
	resource.remaining_units = 8
	resource.units_per_harvest = 2
	resource.tool_item = &"timber_wedge"
	resource.wedge_set = true
	resource.drive_presses = 4
	add_child(resource)
	for frame in 2: await get_tree().physics_frame
	check(bellows.bellows_target() == resource, "bellows finds nearby prepared seam through real line of sight")
	check(bellows.perform("prime").ok, "hand-prime pressure")
	check(bellows.release_at_resource(player).ok, "release drives existing impact response")
	check(resource.remaining_units == 6 and not resource.wedge_set, "existing split consumes prepared wedge and yields finite portion")
	check(not bellows.release_at_resource(player).ok, "spent pressure cannot duplicate impact")
	var sorter_key := sorter.machine_key
	var core_before: int = sim.material_count("pullstone")
	var iron_before: int = sim.material_count("iron_ore")
	sim.add_material("pullstone", 2147483647 - core_before)
	var protected_machines: String = sim.contraption_save()
	var protected_inventory: Dictionary = sim.inventory()
	check(not sim.contraption_remove(sorter_key).ok, "refund overflow refuses before removing the fixture")
	check(sim.contraption_save() == protected_machines and sim.inventory() == protected_inventory, "refused core refund preserves fixture, both trays and pack exactly")
	check(sim.consume_material("pullstone", 2147483647 - core_before), "restore ordinary test pack after overflow probe")
	var refund: Dictionary = sim.contraption_remove(sorter_key)
	check(refund.ok and sim.material_count("pullstone") == core_before + 1, "dismantling recovers intact rare core")
	check(sim.material_count("iron_ore") == iron_before + 10, "dismantling recovers all tray contents")
	check(not sim.contraption_remove(sorter_key).ok, "removed fixture cannot refund twice")
	if DisplayServer.get_name() != "headless" and OS.get_cmdline_user_args().has("--contraption-record"):
		await _record(drum, landing, lever, lamp)
	_finish()


func _place(kind: String, cell: Vector3i) -> ContraptionSite:
	var recipe: Dictionary = sim.recipe("assemble_" + kind)
	check(not recipe.is_empty() and recipe.outputs.get(kind + "_kit", 0) == 1, kind + " has one useful kit recipe")
	for item in recipe.get("inputs", {}): sim.add_material(String(item), int(recipe.inputs[item]))
	check(sim.craft("assemble_" + kind).get("crafted", false), kind + " crafts at existing workbench")
	check(player.placement.placeables().has({"kind": "kit", "id": StringName(kind + "_kit")}), kind + " appears in normal building selection")
	player.placement._select_kit(StringName(kind + "_kit"))
	var element := {"kind": "volume", "axis": 0, "cell": cell}
	check(player.placement.element_accepts(element), kind + " full authored bounds fit supported footprint: " + player.placement.element_refusal(element))
	player.placement.preview_element = element
	check(player.placement._place_kit(), kind + " uses normal kit placement transaction")
	var key := "fixture_%d_%d_%d" % [cell.x, cell.y, cell.z]
	var site := ContraptionSite.find_site(get_tree(), key)
	check(site != null and sim.material_count(kind + "_kit") == 0, kind + " scene and native inventory agree")
	if site != null: site.set_physics_process(false)
	return site


func _finish() -> void:
	print("CONTRAPTION_INTENSIVE %d checks, %d failures" % [checks, failures])
	get_tree().quit(0 if failures == 0 else 1)


func _record(drum: ContraptionSite, landing: ContraptionSite, lever: ContraptionSite, lamp: ContraptionSite) -> void:
	# Recorded engine frames advance only the active native trip by a known
	# amount. The same body/clearance and operation routes were checked above.
	get_window().size = Vector2i(1440, 900)
	player.hud.hide()
	player.placement.set_build_mode_enabled(false)
	player.work_panel.close_panel()
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color("9aa9a2")
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color("c5c4b0")
	environment.environment.ambient_light_energy = 0.55
	environment.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	add_child(environment)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-38, -30, 0)
	sun.light_color = Color("ffe0b1")
	sun.light_energy = 1.1
	sun.shadow_enabled = true
	add_child(sun)
	var camera := Camera3D.new()
	camera.fov = 56
	add_child(camera)
	camera.position = Vector3(4, 6.5, 15)
	camera.look_at(Vector3(5.5, 2, 0.5))
	camera.make_current()
	var canvas := CanvasLayer.new()
	var title := Label.new()
	title.position = Vector2(32, 25)
	title.add_theme_font_size_override("font_size", 24)
	title.text = "THRUMROOT + STORMGLASS · A SIGNAL REQUESTS WORK; WINDING POWERS IT"
	canvas.add_child(title)
	add_child(canvas)
	var directory := ProjectSettings.globalize_path("res://../build/strange-frontier/contraptions")
	DirAccess.make_dir_recursive_absolute(directory)
	check(sim.contraption_deposit(landing.machine_key, "raw_slate", 18).moved == 18, "recorded return haul loaded at landing")
	check(sim.contraption_link(lever.machine_key, drum.machine_key, lever.link_clear(drum)).ok, "recorded lever is physically connected to drum")
	check(drum.perform("wind").ok, "recorded drum is hand-wound")
	drum.refresh_from_sim()
	lever.refresh_from_sim()
	for frame in 3: await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("ready.png"))
	check(lever.perform("pulse").ok, "recorded pulse begins real cargo cycle")
	var names: Array = []
	for frame in 100:
		drum._physics_process(0.05)
		lever._physics_process(0.05)
		await RenderingServer.frame_post_draw
		var filename := "trip-%03d.png" % frame
		get_viewport().get_texture().get_image().save_png(directory.path_join(filename))
		names.append(filename)
	check(not sim.contraption_state(drum.machine_key).moving and not sim.contraption_state(drum.machine_key).at_landing,
		"recorded return haul reaches drum")
	title.text = "LANTERNHEART LAMP · WARM LIGHT FROM A FINITE WILD FIND"
	if not bool(sim.contraption_state(lamp.machine_key).lamp_on): lamp.perform("toggle")
	camera.position = lamp.global_position + Vector3(1.7, 1.4, 2.6)
	camera.look_at(lamp.global_position + Vector3.UP * 0.5)
	for frame in 3: await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(directory.path_join("lanternheart.png"))
	var html := "<!doctype html><meta charset='utf-8'><title>A small connected experiment</title><style>body{margin:30px auto;max-width:1100px;background:#20271f;color:#e7e3ce;font:17px system-ui}img{width:100%%;border-radius:12px}button,input{margin:12px}p{line-height:1.5}input{width:70%%}</style><h1>A small connected experiment</h1><p>Load a basket at a fixed landing. Wind the Thrumroot drum, then strike its linked Stormglass lever. The signal requests work; stored winding powers the return. These are actual Godot frames from the tested kit-placement and inventory path.</p><img id='frame'><button id='play'>Pause</button><input id='scrub' type='range' min='0' max='99' value='0'><p>The basket owns one native inventory throughout the trip. A blocked span pauses it; saving or removing an endpoint preserves its contents. This test stage verifies operation, rather than certifying exploration excitement or usefulness in a human-built home.</p><img src='lanternheart.png'><script>const frames=%s;let n=0,playing=true;const frame=document.getElementById('frame'),scrub=document.getElementById('scrub');function show(){frame.src=frames[n];scrub.value=n}document.getElementById('play').onclick=e=>{playing=!playing;e.target.textContent=playing?'Pause':'Play'};scrub.oninput=()=>{playing=false;n=+scrub.value;show()};setInterval(()=>{if(playing){n=(n+1)%%frames.length;show()}},50);show()</script>" % JSON.stringify(names)
	var file := FileAccess.open(directory.path_join("index.html"), FileAccess.WRITE)
	file.store_string(html)
	file.close()
	print("CONTRAPTION_RECORDING ", directory.path_join("index.html"))
