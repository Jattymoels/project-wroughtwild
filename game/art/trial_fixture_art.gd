class_name TrialFixtureArt
extends RefCounted
## A fixed role kit: merged stone/iron body, state inlay and compact world label.
## The host owns collision and eligibility; this helper never changes either.
const LOOK = preload("res://art/trial_fixture_look.tres")
const KINDS := ["route", "reward", "boundary", "secret", "conduit"]
const BODY_SIZE := Vector3(1.2, 2.1, 0.7)
static var _bodies: Dictionary = {}
static var _inlays: Dictionary = {}
static var _states: Dictionary = {}
static var _body_material: StandardMaterial3D

static func build(fixture: TrialFixture, stone: Material, iron: Material) -> void:
	if fixture.has_node("FixtureBody"): return
	if _body_material == null: _body_material = ArtGeometry.material()
	var body := MeshInstance3D.new()
	body.name = "FixtureBody"
	body.mesh = body_mesh(fixture.fixture_kind, _colour(stone, Color("51534b")), _colour(iron, Color("292c2a")))
	body.material_override = _body_material
	fixture.add_child(body)
	fixture.glow = MeshInstance3D.new()
	fixture.glow.name = "FixtureInlay"
	fixture.glow.mesh = inlay_mesh(fixture.fixture_kind)
	fixture.glow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fixture.add_child(fixture.glow)
	fixture.label = Label3D.new()
	fixture.label.name = "FixtureLabel"
	fixture.label.position = Vector3(0, LOOK.label_height_m, -LOOK.label_front_m)
	fixture.label.font_size = LOOK.label_font_size
	fixture.label.pixel_size = LOOK.label_pixel_size
	fixture.label.width = LOOK.label_width_pixels
	fixture.label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fixture.label.outline_size = LOOK.label_outline_pixels
	fixture.label.outline_modulate = Color("222722")
	fixture.label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	fixture.label.no_depth_test = false
	fixture.label.visibility_range_end = LOOK.label_distance_m
	fixture.label.visibility_range_end_margin = LOOK.label_fade_margin_m
	if fixture.fixture_kind == "secret":
		var player := fixture.get_tree().get_first_node_in_group("player") as WroughtwildPlayer
		fixture.label.visibility_range_end = minf(LOOK.secret_label_distance_m, player.interact_range if player != null else LOOK.secret_label_distance_m)
	fixture.add_child(fixture.label)
	refresh(fixture)

static func _colour(material: Material, fallback: Color) -> Color:
	return (material as StandardMaterial3D).albedo_color if material is StandardMaterial3D else fallback

static func _kind(kind: String) -> String:
	return kind if kind in KINDS else "route"

static func body_mesh(kind: String, stone: Color, iron: Color) -> ArrayMesh:
	kind = _kind(kind)
	var key := kind + ":" + stone.to_html() + ":" + iron.to_html()
	if _bodies.has(key): return _bodies[key]
	var st := ArtGeometry.begin()
	# Every role has a supported plinth and its own recognisable upper outline.
	ArtGeometry.box(st, Vector3(0,0.09,0), Vector3(1.12,0.18,0.64), stone)
	match kind:
		"route":
			for side in [-1.0,1.0]:
				ArtGeometry.box(st, Vector3(side * 0.43,1.1,0.08), Vector3(0.17,1.84,0.36), stone)
				ArtGeometry.box(st, Vector3(side * 0.43,0.55,-0.01), Vector3(0.19,0.1,0.4), iron)
			ArtGeometry.box(st, Vector3(0,1.56,-0.035), Vector3(0.83,0.66,0.39), stone)
			ArtGeometry.box(st, Vector3(0,2.02,0.04), Vector3(1.12,0.15,0.48), iron)
		"reward":
			ArtGeometry.box(st, Vector3(0,0.63,0.02), Vector3(0.67,0.92,0.43), stone)
			ArtGeometry.box(st, Vector3(0,1.08,-0.015), Vector3(1.08,0.17,0.62), stone)
			ArtGeometry.box(st, Vector3(0,1.29,0.1), Vector3(0.86,0.24,0.32), iron)
			for side in [-1.0,1.0]:
				ArtGeometry.box(st, Vector3(side * 0.44,1.53,0.14), Vector3(0.11,1.08,0.24), iron)
			ArtGeometry.box(st, Vector3(0,2.01,0.14), Vector3(0.98,0.13,0.27), stone)
		"boundary":
			for side in [-1.0,1.0]:
				ArtGeometry.box(st, Vector3(side * 0.45,1.1,0.06), Vector3(0.2,1.94,0.48), iron)
			ArtGeometry.box(st, Vector3(0,2.005,0.06), Vector3(1.12,0.17,0.5), stone)
			ArtGeometry.box(st, Vector3(0,0.91,-0.045), Vector3(0.58,0.58,0.29), stone)
			for i in 10:
				var a := TAU * float(i) / 10
				var b := TAU * float(i + 1) / 10
				ArtGeometry.branch(st, Vector3(cos(a)*0.32,1.56+sin(a)*0.32,-0.14), Vector3(cos(b)*0.32,1.56+sin(b)*0.32,-0.14),0.045,iron,1.0)
			ArtGeometry.branch(st,Vector3(-0.24,1.56,-0.14),Vector3(0.24,1.56,-0.14),0.04,iron,1.0)
		"secret":
			ArtGeometry.box(st, Vector3(0,1.12,0.085), Vector3(1.05,1.93,0.47), stone)
			for side in [-1.0,1.0]:
				ArtGeometry.box(st, Vector3(side * 0.25,1.07,-0.19), Vector3(0.45,1.61,0.11), stone.darkened(0.09))
			ArtGeometry.box(st, Vector3(0.16,1.05,-0.275), Vector3(0.28,0.08,0.07), iron)
		"conduit":
			ArtGeometry.branch(st,Vector3(0,0.19,0.02),Vector3(0,1.96,0.02),0.22,stone,0.83)
			for y in [0.38,0.99,1.8]:
				ArtGeometry.box(st,Vector3(0,y,0.01),Vector3(0.72,0.14,0.48),iron)
			for side in [-1.0,1.0]:
				ArtGeometry.branch(st,Vector3(side*0.43,0.2,0.08),Vector3(side*0.27,1.88,0.08),0.065,iron,1.0)
			ArtGeometry.box(st,Vector3(0,2.015,0.01),Vector3(0.61,0.15,0.52),stone)
	var mesh := st.commit()
	while _bodies.size() >= clampi(LOOK.body_mesh_cache_limit, 5, 20): _bodies.erase(_bodies.keys()[0])
	_bodies[key] = mesh
	return mesh

static func inlay_mesh(kind: String) -> ArrayMesh:
	kind = _kind(kind)
	if _inlays.has(kind): return _inlays[kind]
	var st := ArtGeometry.begin()
	match kind:
		"route":
			for side in [-1.0,1.0]:
				ArtGeometry.box(st,Vector3(side*0.1,1.6,-0.25),Vector3(0.25,0.055,0.025),Color.WHITE,Vector3(0,0,side*0.62))
		"reward":
			for x in [-0.23,0.0,0.23]: ArtGeometry.box(st,Vector3(x,1.255,-0.195),Vector3(0.12,0.12,0.06),Color.WHITE,Vector3(0,0,PI/4))
		"boundary":
			for y in [0.82,1.03]:
				for side in [-1.0,1.0]: ArtGeometry.box(st,Vector3(side*0.085,y,-0.205),Vector3(0.22,0.045,0.025),Color.WHITE,Vector3(0,0,side*0.65))
		"secret": ArtGeometry.box(st,Vector3(0.16,1.05,-0.32),Vector3(0.13,0.045,0.018),Color.WHITE)
		"conduit":
			for x in [-0.11,0.11]: ArtGeometry.box(st,Vector3(x,1.41,-0.22),Vector3(0.065,0.57,0.035),Color.WHITE)
	var mesh := st.commit()
	_inlays[kind] = mesh
	return mesh

static func state_material(state: String) -> StandardMaterial3D:
	if state not in ["ready","finished","sealed","secret"]: state = "sealed"
	if _states.has(state): return _states[state]
	var material := StandardMaterial3D.new()
	material.albedo_color = {"ready":LOOK.ready_colour,"finished":LOOK.finished_colour,"sealed":LOOK.sealed_colour,"secret":LOOK.secret_latch_colour}[state]
	material.roughness = 0.9
	material.emission_enabled = state == "ready"
	material.emission = LOOK.ready_colour
	material.emission_energy_multiplier = LOOK.ready_emission
	_states[state] = material
	return material

static func compact_line(text: String) -> String:
	var clean := " ".join(text.replace("\n"," ").replace("\r"," ").split(" ", false))
	if clean.length() > LOOK.label_character_limit: clean = clean.left(LOOK.label_character_limit - 1).strip_edges() + "…"
	var font := ThemeDB.fallback_font
	while clean.length() > 1 and font.get_string_size(clean, HORIZONTAL_ALIGNMENT_LEFT, -1, LOOK.label_font_size).x > LOOK.label_width_pixels - LOOK.label_padding_pixels:
		clean = clean.trim_suffix("…").left(clean.trim_suffix("…").length() - 1).strip_edges() + "…"
	return clean

static func refresh(fixture: TrialFixture) -> void:
	if fixture.label != null:
		var lines := PackedStringArray()
		for line in fixture.world_lines(): lines.append(compact_line(line))
		fixture.label.text = "\n".join(lines)
		fixture.label.modulate = LOOK.finished_text_colour if fixture.claimed else LOOK.text_colour
		fixture.label.visible = (fixture.fixture_kind != "route" or fixture.available or fixture.claimed) and not bool(fixture.payload.get("terminal", false))
	if fixture.glow != null:
		var state := "finished" if fixture.claimed else "secret" if fixture.fixture_kind == "secret" else "ready" if fixture.available else "sealed"
		fixture.glow.material_override = state_material(state)
		fixture.glow.visible = (fixture.fixture_kind != "route" or fixture.available or fixture.claimed) and not bool(fixture.payload.get("terminal", false))
