extends Node3D
## INT-05A: readable existing fixture states, bounded shared geometry and exact
## retained collision. Native run/reward lifecycle is covered by trial_intensive.
var checks := 0
var failures := 0
var player: WroughtwildPlayer
var stone: StandardMaterial3D
var iron: StandardMaterial3D
var fixtures: Array[TrialFixture] = []

func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL FORGE_FIXTURES: ", label)
	return ok

func _ready() -> void:
	player = preload("res://scenes/player.tscn").instantiate()
	add_child(player)
	player.class_panel.choose("warden")
	player.set_physics_process(false)
	player.combat.set_physics_process(false)
	player.placement.set_physics_process(false)
	stone = StandardMaterial3D.new()
	stone.albedo_color = Color("51534b")
	iron = StandardMaterial3D.new()
	iron.albedo_color = Color("292c2a")
	_run.call_deferred()

func fixture(kind: String, title: String = "Existing Forge fixture") -> TrialFixture:
	var value := TrialFixture.new()
	value.fixture_kind = kind
	value.title = title
	value.detail = "Use the existing fixture"
	value.position = Vector3(fixtures.size() * 3.0, 0, 0)
	add_child(value)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(1.2,2.1,0.7)
	collision.shape = shape
	collision.position.y = 1.05
	value.add_child(collision)
	TrialFixtureArt.build(value, stone, iron)
	fixtures.append(value)
	return value

func _run() -> void:
	var native_before := player.inventory.get_sim().export_json()
	_geometry_and_budget()
	_route_states()
	_other_roles()
	_text_bounds()
	check(player.inventory.get_sim().export_json() == native_before, "art and text never change native inventory, choices or progression")
	print("FORGE_FIXTURES %d checks, %d failures" % [checks, failures])
	get_tree().quit(1 if failures else 0)

func _geometry_and_budget() -> void:
	var fingerprints := {}
	for kind: String in TrialFixtureArt.KINDS:
		var first := fixture(kind)
		var second := fixture(kind)
		var body := first.get_node("FixtureBody") as MeshInstance3D
		var clone := second.get_node("FixtureBody") as MeshInstance3D
		check(body.mesh == clone.mesh and first.glow.mesh == second.glow.mesh, kind + " shares body and inlay meshes")
		check(body.material_override == clone.material_override, kind + " shares its body material")
		check(body.mesh.get_surface_count() == 1 and first.glow.mesh.get_surface_count() == 1, kind + " uses two merged mesh surfaces")
		check(first.get_child_count() == 4, kind + " keeps one collider, two meshes and one label")
		var arrays := body.mesh.surface_get_arrays(0)
		fingerprints[(arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).to_byte_array().hex_encode().hash()] = true
		for visual: MeshInstance3D in [body, first.glow]:
			var bounds := visual.mesh.get_aabb()
			check(bounds.position.x >= -0.6001 and bounds.end.x <= 0.6001, kind + " visual fits the original body width")
			check(bounds.position.y >= -0.0001 and bounds.end.y <= 2.1001, kind + " visual fits the original body height")
			check(bounds.position.z >= -0.3501 and bounds.end.z <= 0.3501, kind + " visual fits the original body depth")
		var collision := first.get_child(0) as CollisionShape3D
		var original_shape := collision.shape
		for state in [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)]:
			first.available = bool(state.x)
			first.claimed = bool(state.y)
			first.refresh()
			check(first.available == bool(state.x) and first.claimed == bool(state.y), kind + " refresh only reads eligibility")
			check(collision.shape == original_shape and (collision.shape as BoxShape3D).size == Vector3(1.2,2.1,0.7)
				and collision.position == Vector3(0,1.05,0) and not collision.disabled, kind + " refresh preserves exact active collision")
			check(first.world_lines().size() <= 3, kind + " world text has at most three explicit lines")
		TrialFixtureArt.build(first, stone, iron)
		check(first.get_child_count() == 4, kind + " repeated presentation build cannot duplicate nodes")
	check(fingerprints.size() == 5, "five roles have distinguishable body geometry")
	check(TrialFixtureArt._bodies.size() == 5 and TrialFixtureArt._inlays.size() == 5, "normal role set occupies a fixed ten-mesh cache")
	for i in 30:
		TrialFixtureArt.body_mesh("route", Color(float(i)/31.0,0.2,0.3), iron.albedo_color)
		TrialFixtureArt.inlay_mesh("unknown" + str(i))
		TrialFixtureArt.state_material("unknown" + str(i))
	check(TrialFixtureArt._bodies.size() <= TrialFixtureArt.LOOK.body_mesh_cache_limit, "review palette changes cannot grow the body cache without bound")
	check(TrialFixtureArt._inlays.size() == 5 and TrialFixtureArt._states.size() <= 4, "unknown roles/states cannot expand closed presentation palettes")
	for value in fixtures:
		for child in value.get_children():
			check(child is CollisionShape3D or child is MeshInstance3D or child is Label3D, "fixture adds no light, particle, viewport, sound or gameplay node")

func _route_states() -> void:
	var route := fixture("route", "Working Gallery")
	route.payload = {"reward":"boon_offer","reward_label":"Blessing", "encounter":PackedStringArray(["ash_guard","ash_guard","ward_bearer"]),"danger_summary":"3 foes · Warding bearer"}
	route.stage_index = 2
	route.choice_index = 1
	route.entry_point = Vector3(5,0.5,-8)
	var payload := route.payload.duplicate(true)
	var entry := route.entry_point
	route.available = true
	route.refresh()
	check(route.label.visible and route.glow.visible, "available route has a readable face and state mark")
	check(route.label.text.split("\n").size() == 3, "current route shows title, reward and danger")
	check(route.trial_label().contains("Enter") and route.trial_label().contains("Blessing") and route.trial_label().contains("3 foes"), "aimed current route previews its actual use and reward/danger")
	check(not route.label.text.contains("boon_offer") and not route.label.text.contains("ash_guard"), "native internal IDs never fill the plaque")
	var ready_material := route.glow.material_override as StandardMaterial3D
	# The renderer stores this property at float precision while the Resource's
	# script number is a double. Compare the intended value at that boundary;
	# also require actual emission and the documented restrained range.
	check(ready_material.emission_enabled and ready_material.emission_energy_multiplier > 0.0
		and ready_material.emission_energy_multiplier < 1.0
		and absf(ready_material.emission_energy_multiplier - TrialFixtureArt.LOOK.ready_emission) <= 0.000001,
		"ready mark uses bounded restrained emission")
	route.available = false
	route.refresh()
	check(not route.label.visible and not route.glow.visible, "future route hides corridor text and active mark")
	check(route.trial_label().contains("Sealed") and not route.trial_label().contains("E ·"), "aiming at a future route still explains its closed state")
	route.claimed = true
	route.refresh()
	check(route.label.visible and route.label.text.ends_with("Chosen"), "selected route remains recognisable as Chosen")
	check(route.trial_label().ends_with("Chosen") and not route.trial_label().to_lower().contains("spent"), "selected route is never labelled spent")
	check(not (route.glow.material_override as StandardMaterial3D).emission_enabled, "chosen route no longer advertises an active interaction")
	check(route.payload == payload and route.entry_point == entry and route.stage_index == 2 and route.choice_index == 1, "presentation preserves native payload and exact route identity")
	for reward in ["boon_offer","weakness_offer","materials","catalyst","completion"]:
		route.payload = {"reward":reward,"encounter":["ash_guard","unknown_future_actor"]}
		route.available = true
		route.claimed = false
		route.refresh()
		check(not route.label.text.contains("_") and route.danger_label() == "2 foes", "fallback describes native reward and count without inventing an actor role")

func _other_roles() -> void:
	var lift := fixture("boundary", "The descent lift")
	lift.available = true
	lift.refresh()
	check(lift.trial_label().contains("Continue, bank or suspend"), "cleared story boundary offers its three actual options")
	lift.payload.terminal = true
	lift.title = "End of gallery"
	lift.refresh()
	check(not lift.label.visible and not lift.glow.visible and lift.trial_label() == "End of gallery", "terminal gallery does not promise a locked or usable next floor")
	player.interact_range = 2.75
	var secret := fixture("secret", "Loose furnace catch")
	secret.available = true
	secret.refresh()
	check(secret.label.visibility_range_end <= player.interact_range, "secret words stay within current interaction reach")
	check(not secret.label.no_depth_test, "secret label never appears through walls")
	check(not (secret.glow.material_override as StandardMaterial3D).emission_enabled, "secret latch emits no distant beacon")
	check(secret.trial_label().ends_with("Inspect") and not secret.trial_label().contains("store"), "unopened environmental catch avoids announcing unseen contents")
	secret.claimed = true
	secret.available = false
	secret.refresh()
	check(secret.label.text.ends_with("Searched") and not secret.trial_label().contains("E ·"), "searched secret cannot advertise a second claim")
	check(secret.glow.material_override == TrialFixtureArt.state_material("finished")
		and not (secret.glow.material_override as StandardMaterial3D).emission_enabled,
		"searched secret uses a distinct finished mark while remaining matte")
	player.interact_range = 3.5
	var conduit := fixture("conduit", "Ward conduit")
	conduit.available = true
	conduit.refresh()
	check(conduit.trial_label().contains("Cool ward protection"), "active conduit explains its defensive role")
	conduit.available = false
	conduit.claimed = true
	conduit.refresh()
	check(conduit.trial_label().ends_with("Cooling"), "temporarily disabled conduit has an accurate state")
	conduit.available = true
	conduit.claimed = false
	conduit.refresh()
	check(conduit.trial_label().contains("E ·"), "normal native rearm becomes readable again")
	var offering := fixture("reward", "Recovered offering")
	offering.available = true
	for reward in ["boon_offer","weakness_offer","materials","catalyst","completion"]:
		offering.payload = {"reward_type":reward}
		offering.refresh()
		check(not offering.label.text.contains("_") and offering.world_lines().size() == 2, "offering action uses compact native reward identity")
	offering.claimed = true
	offering.available = false
	offering.refresh()
	check(offering.trial_label().ends_with("Finished"), "resolved offering does not claim that a skipped blessing was collected")

func _text_bounds() -> void:
	var route := fixture("route", "WWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWWW")
	route.available = true
	route.payload = {"reward_label":"Blessing\nInjected extra line", "danger_summary":"Many threats\r\nmore lines and exceptionally lengthy descriptive material"}
	route.refresh()
	check(route.label.text.split("\n").size() == 3, "source newlines cannot create a wall of extra text")
	var font := ThemeDB.fallback_font
	for line in route.label.text.split("\n"):
		check(font.get_string_size(line,HORIZONTAL_ALIGNMENT_LEFT,-1,route.label.font_size).x <= route.label.width - TrialFixtureArt.LOOK.label_padding_pixels + 0.1,
			"every world line fits the configured pixel width before wrapping")
	check(route.label.width * route.label.pixel_size <= 2.0, "plaque width stays below roughly two metres")
	check(route.label.position.z < -0.35 and route.label.position.y > 2.1, "label clears the existing body toward the gallery")
	check(not route.label.no_depth_test and route.label.billboard == BaseMaterial3D.BILLBOARD_ENABLED, "ordinary world depth and readable billboard are retained")
