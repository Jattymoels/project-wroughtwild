class_name LeylineSource
extends StaticBody3D
## Manual host and exposed collection tray. Native LF ledger owns every lot.
const LOOK = preload("res://art/leyline_source_look.tres")
var source_id := ""
var sim: WroughtwildSim
var terrain: Terrain
var _crystals: Node3D
var _claim: MeshInstance3D
var _label: Label3D
var _panel_player: WroughtwildPlayer
var _colour := Color.WHITE
var _highlight := false

static func build(root: Node3D, ground: Terrain) -> void:
	var group := Node3D.new()
	group.name = "LeylineSources"
	root.add_child(group)
	for record: Dictionary in ground._sim.leyline_sources():
		var source := LeylineSource.new()
		source.source_id = record.id
		source.sim = ground._sim
		source.terrain = ground
		source.position = record.position
		group.add_child(source)
		# Short visible scars point toward the concentrated host from its existing
		# guaranteed home approach. These hints grant no stock or interaction.
		var spawn := ground.surface_position(int(ground.map.spawn_x), int(ground.map.spawn_z))
		var distance := spawn.distance_to(source.position)
		for i in range(1, int(distance / LOOK.clue_spacing_m)):
			var at := spawn.lerp(source.position, float(i) * LOOK.clue_spacing_m / distance)
			at.y = ground.rendered_height(at.x, at.z, at.y) + 0.035
			var clue := source._box(group, Vector3(.08,.025,LOOK.clue_length_m), at, source._colour)
			clue.look_at(Vector3(source.position.x, at.y, source.position.z), Vector3.UP)

func state() -> Dictionary:
	for record: Dictionary in sim.leyline_sources():
		if record.id == source_id: return record
	return {}

func _ready() -> void:
	add_to_group("leyline_sources")
	var record := state()
	_colour = LOOK.red if record.get("material", "") == "red_salt" else LOOK.white
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = LOOK.bounds
	collision.shape = box
	collision.position.y = LOOK.bounds.y * .5
	add_child(collision)
	_box(self, Vector3(1.4,.32,1.35), Vector3(0,.16,0), LOOK.casing)
	_crystals = Node3D.new()
	add_child(_crystals)
	for i in 5:
		var crystal := _box(_crystals, Vector3(.17,.55 + (i%2)*.2,.21), Vector3((i-2)*.23,.6,0), _colour)
		crystal.rotation = Vector3(.15*(i%2), .27*i, .12*(i-2))
	_claim = _box(self, Vector3(.9,.13,.35), Vector3(0,.38,.48), _colour)
	_label = Label3D.new()
	_label.position.y = 1.5
	_label.font_size = 32
	_label.pixel_size = .006
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = false
	add_child(_label)
	refresh()

func _box(parent: Node3D, size: Vector3, at: Vector3, colour: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = .9
	material.emission_enabled = colour != LOOK.casing
	material.emission = colour
	material.emission_energy_multiplier = LOOK.emission_energy
	mesh.material_override = material
	mesh.position = at
	parent.add_child(mesh)
	return mesh

func supported() -> bool:
	var at := StrangeSites._ground(terrain, global_position.x, global_position.z)
	if not at.is_finite() or absf(at.y-global_position.y) > .4: return false
	# Fixed hosts never relocate through paid structures or excavations.
	var query := PhysicsShapeQueryParameters3D.new()
	var shape := BoxShape3D.new()
	shape.size = LOOK.bounds * .9
	query.shape = shape
	query.transform.origin = global_position + Vector3.UP * LOOK.bounds.y * .6
	query.exclude = [get_rid()]
	for hit in get_world_3d().direct_space_state.intersect_shape(query):
		if hit.collider is PlacedBlock or hit.collider is StationSite or hit.collider is ContraptionSite: return false
	return true

func interact_label() -> String:
	var s := state()
	if s.is_empty(): return ""
	var status := "Released lot" if not s.claim.is_empty() else "Forming" if s.lot == s.lots else "%s · %d/%d" % [s.next_work,s.work,s.steps]
	return InputPrompts.formatted("%s · %s · {interact} to work", [s.label,status])

func interact(user: WroughtwildPlayer) -> void:
	_panel_player = user
	_open()

func _open(message := "") -> void:
	var s := state()
	if s.is_empty() or not is_instance_valid(_panel_player): return
	var ready := supported() and not _panel_player.trial.active()
	var rows: Array = [{"text":"%d / %d lots remain · %d %s per lot" % [s.lots-s.lot,s.lots,s.units_per_lot,Hud.pretty(s.material)], "button":"", "enabled":false,
		"details":"Each lot keeps its work and result through interruption and saves. Released claims stay here until collected; a full pack never loses them. After all lots and claims are taken, one new manifestation forms during ten minutes of active overworld play. Pauses, trials and closed games add no time."}]
	if s.claim.is_empty() and s.lot < s.lots:
		rows.append({"text":"Work %d / %d. Safe manual extraction for every class." % [s.work,s.steps],"button":s.next_work,"enabled":ready,"callback":_work})
	elif s.lot == s.lots and s.claim.is_empty():
		rows.append({"text":"Forming · %.0f / %.0f seconds of overworld activity. Return after exploring or building." % [s.formation,s.formation_seconds],"button":"Forming","enabled":false})
	for item: String in s.claim:
		rows.append({"text":"%d %s waiting in the host." % [s.claim[item],Hud.pretty(item)],"button":"Collect " + Hud.pretty(item),"enabled":ready,"callback":_collect.bind(item)})
	rows.append({"text":"Red Salt fires bricks: 8 clay + 2 salt → 4 bricks at your forge." if s.material == "red_salt" else "White mineral carries a request through a placed connection.","button":"Material use","enabled":false,
		"details":"Red Salt replaces the brick variant's fuel only. It supplies no mechanical winding. An intact Faint Ember has a %.1f%% chance per fixed Red lot and uses its existing Foundry rules; it is a bonus, not a required harvest." % (float(s.rare_per_10000)/100.0) if s.material == "red_salt" else "A signal requests a trip; the cargo drum spends its own stored winding."})
	if not ready: message = "Clear the host's workspace and restore its ground support to work or collect."
	_panel_player.open_custom_panel(s.label,rows,message,"leyline:"+source_id)
	refresh()

func _can_act() -> bool:
	return is_instance_valid(_panel_player) and not _panel_player.trial.active() and _panel_player.global_position.distance_to(global_position) < 5.0 and supported()

func _work() -> void:
	if not _can_act(): return
	var result: Dictionary = sim.leyline_work(source_id)
	_open(result.message)

func _collect(item: String) -> void:
	if not _can_act(): return
	var result: Dictionary = sim.leyline_collect(source_id,item)
	_open(result.message)

func set_highlight(on: bool) -> void:
	_highlight = on
	refresh()

func refresh() -> void:
	if _crystals == null: return
	var s := state()
	if s.is_empty(): return
	_crystals.visible = s.lot < s.lots
	_crystals.scale.y = 1.0 - float(s.work) / float(s.steps) * .45
	_claim.visible = not s.claim.is_empty()
	_label.text = s.label + "\n" + ("Collect released lot" if _claim.visible else "Forming" if s.lot == s.lots else s.next_work)
	_label.visible = _highlight and (not is_instance_valid(_panel_player) or not _panel_player.work_panel.is_open())
