class_name LeylineSource
extends StaticBody3D
## Manual host and exposed collection tray. Native source ledger owns every lot.
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
	if not ground._sim.leyline_sources().is_empty() and G1Art.enabled(): G1Colours.prepare_resources()
	var group := Node3D.new()
	group.name = "LeylineSources"
	root.add_child(group)
	for record: Dictionary in ground._sim.leyline_sources():
		var source := LeylineSource.new()
		source.source_id = record.id
		source.sim = ground._sim
		source.terrain = ground
		source.position = record.position
		if ground.world_profile() in ["frontier_v11","frontier_v12"]:
			var supported_at := StrangeSites._ground(ground,source.position.x,source.position.z)
			if supported_at.is_finite(): source.position = supported_at
		group.add_child(source)
		# Ordinary routes/host clues belong to FrontierSites so terrain/paid placement
		# can refresh their support; Red's authored landform is its own lead.
		if ground.world_profile() in ["frontier_v11","frontier_v12"]: continue
		# Published LF clue geography remains unchanged.
		var spawn := ground.surface_position(int(ground.map.spawn_x), int(ground.map.spawn_z))
		var distance := spawn.distance_to(source.position)
		for i in range(1, int(distance / LOOK.clue_spacing_m)):
			var at := spawn.lerp(source.position, float(i) * LOOK.clue_spacing_m / distance)
			at = StrangeSites._ground(ground,at.x,at.z)
			if not at.is_finite(): continue
			at.y += 0.035
			var clue := source._box(group, Vector3(.08,.025,LOOK.clue_length_m), at, source._colour)
			clue.look_at(Vector3(source.position.x, at.y, source.position.z), Vector3.UP)

func state() -> Dictionary:
	for record: Dictionary in sim.leyline_sources():
		if record.id == source_id: return record
	return {}

func _ready() -> void:
	add_to_group("leyline_sources")
	var record := state()
	_colour = {"red_salt":LOOK.red,"white_mineral":LOOK.white,"blue_flake":LOOK.blue,"green_resin":LOOK.green}.get(record.get("material",""),LOOK.white)
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
	if G1Art.enabled(): G1Colours.mount_source(self)

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
	if not at.is_finite() or absf(at.y-global_position.y) > LOOK.support_tolerance_m:
		# Excavation does not move the anchor. A real built surface can restore
		# it, including when the excavation was saved by an older game version.
		var ray := PhysicsRayQueryParameters3D.create(
			global_position + Vector3.UP * LOOK.support_tolerance_m,
			global_position - Vector3.UP * LOOK.support_tolerance_m)
		ray.exclude = [get_rid()]
		var hit := get_world_3d().direct_space_state.intersect_ray(ray)
		if not hit.get("collider") is PlacedBlock or hit.normal.y < LOOK.support_normal_y: return false
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
	var uses := {"red_salt":"Red Salt fires bricks: 8 clay + 2 salt → 4 bricks. Build a paid Red Heat Buffer at your workbench to store heat for a feeder.","white_mineral":"Workbench: 2 White Mineral + 2 wood → 1 White Connection Kit.","blue_flake":"Workbench: 2 Blue Flakes + 2 wood → 1 Blue Delay Kit.","green_resin":"Workbench: 2 Green Resin + 2 wood → 1 Green Junction Kit."}
	var detail := "Red Salt replaces the brick variant's fuel only. Forge Faint Ember: 96 salt + 4 iron ingots + 8 charcoal, immediately at a basic forge (Blacksmithing 1). Salt supplies no mechanical winding. A buffer costs 4 salt + 4 wood + 2 iron ingots; each stored heat costs 2 salt and fires one clay cycle. A feeder still needs its paid clay and winding." if s.material=="red_salt" else "A signal requests a trip; the cargo drum spends its own stored winding. Blue holds one request for three active nearby seconds, with Pause, Resume and Cancel controls."
	if not String(s.rare_item).is_empty(): detail += " Each fixed lot has a %.1f%% bonus %s opportunity, independent of work or collection splits." % [float(s.rare_per_10000)/100.0,Hud.pretty(String(s.rare_item))]
	rows.append({"text":uses.get(s.material,""),"button":"Material use","enabled":false,"details":detail})
	if terrain.world_profile() in ["living_frontier_wave3","frontier_v12"] or (terrain.world_profile()=="frontier_v11" and source_id=="red_home_margin"):
		rows.append({"text":frontier_observation(),"button":"Field reading","enabled":false,"details":frontier_manufacture()})
	if not ready: message = "Clear the host's workspace and restore its ground support to work or collect."
	_panel_player.open_custom_panel(s.label,rows,message,"leyline:"+source_id)
	refresh()

func frontier_observation() -> String:
	if terrain.world_profile()=="frontier_v12":
		return {
			"red_home_margin":"Red gathers and releases within swollen mineral seams. On the separate Steppe route, a scarred boar roots before planting its feet to release a circle of heat. Back away or interrupt it. This manual workplace needs no hunt.",
			"white_home_margin":"White offsets mineral banks in one direction; roots brace the loaded joints and the seam stops at breaks. The separate observation route reaches a scarred stag: it grazes and flees disturbance. White connections carry requests; the receiver pays for its own work.",
			"blue_home_margin":"Blue holds nested mineral layers inside the bank. Work from the dry stance beside the flakes. A separate clearing holds the scarred boar, which commits to a straight charge: move sideways or interrupt it. A paid delay retains one request, then passes it to a receiver that pays its own work.",
			"green_home_margin":"Green splits at connected root junctions. Tall woodland fans and low Steppe colonies express the same branching force; genuinely dry gaps stop it. This is the single resin owner. The separate growth route reaches a moth that visits branches and flees. A paid junction sends requests to two independently paid receivers."
		}.get(source_id,"")
	if terrain.world_profile()=="frontier_v11":
		return "Red gathers and releases within swollen mineral seams. On the separate Steppe route, a scarred boar roots before planting its feet to release a circle of heat. Observe safely, back away or interrupt it. This manual workplace needs no hunt."
	return {
		"red_home_margin":"Red vents outward. Beyond the calm clearing, a scarred boar plants its feet before releasing a circle of heat. Back away or interrupt it. The metal clamps here bear three matching cuts; follow them toward the Collection Annex.",
		"blue_home_margin":"Blue holds before releasing. The scarred boar beyond the calm clearing commits to a straight charge: move sideways or interrupt it. Its flakes share this source's held pattern.",
		"white_home_margin":"White carries an impulse. The stag beyond the calm clearing grazes and flees; its narrow scars share this mineral's pattern. Hunting it is optional.",
		"green_home_margin":"Green branches through connected growth. The moth beyond the calm clearing visits those branches and flees disturbance. Its resin shares this source's pattern."
	}.get(source_id,"")

func frontier_manufacture() -> String:
	var recipes: Array={"red_home_margin":["ember"],"blue_home_margin":["frost"],"green_home_margin":["preserving"],"white_home_margin":["impact","piercing"]}.get(source_id,[])
	var detail:="An affected animal yields four matching raw units through its physical drops. These also pay ordinary useful recipes. Safe manual source work supplies bulk material, so a hunt or rare find is never required.\n\nReliable manufacture at your basic forge (Blacksmithing 1):"
	for id: String in recipes:
		var recipe: Dictionary=sim.recipe("forge_faint_"+id)
		detail+="\n%s: %s." % [String(recipe.display_name),WorkPanel.amounts_text(recipe.inputs)]
	detail+="\n\nA signal requests work. Each receiver still pays its own winding; stored Red heat remains a separate thermal cost."
	if terrain.world_profile()=="living_frontier_wave3": detail+=" The later collection apparatus leads to sealed laboratory sites."
	return detail

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
