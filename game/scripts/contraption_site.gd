class_name ContraptionSite
extends StaticBody3D
## A placed rare find made useful. This node owns geometry, nearby time and
## presentation only; the native ledger owns every item and stored operation.

const LOOK = preload("res://art/contraption_look.tres")
const SOUND = preload("res://art/strange_sound.gd")
const LABELS := {
	"lantern_lamp": "Lanternheart lamp", "cargo_winch": "Thrumroot cargo drum",
	"winch_landing": "Fixed cargo landing", "stormglass_lever": "Stormglass lever",
	"magnetic_sorter": "Pullstone sorting chute", "ventlung_bellows": "Ventlung bellows",
	"pressure_feeder": "Pressure feeder", "white_connection": "White connection"
}

var machine_key := ""
var kind := ""
var sim: WroughtwildSim
var _visual: Node3D
var _basket: Node3D
var _cable: MeshInstance3D
var _pulse: MeshInstance3D
var _receiver: MeshInstance3D
var _panel: ContraptionPanel
var _pulse_left := 0.0
var _last_pulses := 0
var _last_arrivals := 0
var _last_cycles := 0
var _last_feeder_status := ""
var _feeder_pipe: MeshInstance3D
var _pressure_pipe: MeshInstance3D
var _hopper_load: MeshInstance3D
var _fuel_load: MeshInstance3D
var _output_load: MeshInstance3D
var _feeder_panel_refresh_left := 0.0
## Read-only presentation snapshot. Actual operations always check current rules.
var _feeder_readout: Dictionary = {}
var _highlighted := false
var _last_state: Dictionary = {}


static func bounds_for(fixture_kind: String) -> Vector3:
	match fixture_kind:
		"cargo_winch", "winch_landing": return LOOK.winch_bounds
		"magnetic_sorter": return LOOK.sorter_bounds
		"ventlung_bellows": return LOOK.bellows_bounds
		"stormglass_lever": return LOOK.lever_bounds
		"white_connection": return LOOK.white_connection_bounds
		"pressure_feeder": return LOOK.feeder_bounds
	return LOOK.lamp_bounds


static func find_site(tree: SceneTree, key: String) -> ContraptionSite:
	for node in tree.get_nodes_in_group("contraptions"):
		if node is ContraptionSite and node.machine_key == key:
			return node as ContraptionSite
	return null


static func restore_all(parent: Node, rules: WroughtwildSim) -> void:
	# Geometry is recreated from the already validated native snapshot. Replacing
	# these nodes never redeposits cargo or grants a fixture kit.
	for node in parent.get_tree().get_nodes_in_group("contraptions"):
		if parent.is_ancestor_of(node):
			node.get_parent().remove_child(node)
			node.queue_free()
	for key in rules.contraption_ids():
		var record: Dictionary = rules.contraption_state(key)
		var site := ContraptionSite.new()
		site.machine_key = String(key)
		site.kind = String(record.get("kind", ""))
		site.sim = rules
		parent.add_child(site)


func _ready() -> void:
	add_to_group("contraptions")
	if sim == null:
		sim = load("res://scripts/sim.gd").shared()
	var record: Dictionary = sim.contraption_state(machine_key)
	if record.is_empty():
		push_error("A contraption scene has no native placement: %s" % machine_key)
		set_physics_process(false)
		return
	kind = String(record.get("kind", kind))
	global_position = record.get("position", Vector3.ZERO)
	rotation.y = float(record.get("quarter_turns", 0)) * PI * 0.5
	var shape := BoxShape3D.new()
	shape.size = bounds_for(kind)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	collider.position.y = shape.size.y * 0.5
	add_child(collider)
	_visual = StrangeResourceArt.fixture_visual(kind)
	add_child(_visual)
	if kind == "cargo_winch":
		_basket = StrangeResourceArt.fixture_visual("cargo_basket")
		add_child(_basket)
	if kind in ["cargo_winch", "stormglass_lever", "white_connection"]:
		_cable = MeshInstance3D.new()
		var cylinder := CylinderMesh.new()
		cylinder.top_radius = 1.0
		cylinder.bottom_radius = 1.0
		cylinder.height = 1.0
		cylinder.radial_segments = 6
		_cable.mesh = cylinder
		_cable.material_override = _material(LOOK.white_connection_colour if kind == "white_connection" else LOOK.cable_colour)
		add_child(_cable)
		_pulse = _sphere(LOOK.pulse_radius_m, LOOK.pulse_colour)
		add_child(_pulse)
		_pulse.hide()
	if kind in ["cargo_winch", "lantern_lamp", "pressure_feeder", "white_connection"]:
		_receiver = _sphere(LOOK.receiver_radius_m, LOOK.receiver_colour)
		_receiver.position = Vector3(0, bounds_for(kind).y + 0.04, 0)
		add_child(_receiver)
	_last_pulses = int(record.get("pulses", 0))
	_last_arrivals = int(record.get("completed_trips", 0))
	_last_cycles = int(record.get("completed_cycles",0))
	if kind=="pressure_feeder":
		_feeder_pipe=_connection_mesh(LOOK.feeder_forge_link_colour)
		_pressure_pipe=_connection_mesh(LOOK.feeder_pressure_link_colour)
		_hopper_load=_load_mesh(LOOK.feeder_hopper_load,LOOK.feeder_hopper_size,_material(LOOK.feeder_clay_colour))
		_fuel_load=_load_mesh(LOOK.feeder_fuel_load,LOOK.feeder_fuel_size,_material(LOOK.feeder_fuel_colour))
		_output_load=_load_mesh(LOOK.feeder_output_load,LOOK.feeder_output_size,PieceLook.material_for(sim,&"rustclay_brick"))
	refresh_from_sim()


static func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.85
	return material


static func _sphere(radius: float, colour: Color) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = 12
	mesh.rings = 6
	node.mesh = mesh
	var material := _material(colour)
	material.emission_enabled = true
	material.emission = colour
	material.emission_energy_multiplier = 0.4
	node.material_override = material
	return node


func interact_label() -> String:
	if kind == "pressure_feeder":
		return InputPrompts.formatted("Pressure feeder · %s · {interact} to use", String(_feeder_readout.get("headline", "Inspect setup")))
	return InputPrompts.formatted("%s · {interact} to use", LABELS.get(kind, kind))

func feeder_readout() -> Dictionary:
	return _feeder_readout


func interact(player: WroughtwildPlayer) -> void:
	if _panel == null:
		_panel = ContraptionPanel.new()
	_panel.open_at(self, player)


func set_highlight(on: bool) -> void:
	_highlighted = on
	if _receiver != null:
		_receiver.scale = Vector3.ONE * (1.2 if on else 1.0)


func _physics_process(delta: float) -> void:
	if sim == null or _visual == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or player.global_position.distance_squared_to(global_position) > LOOK.active_distance_m * LOOK.active_distance_m:
		return
	if kind == "cargo_winch":
		# A neighbouring lever may have changed the drum since its last frame.
		# Query authority before advancing, so signals take effect immediately.
		var current: Dictionary = sim.contraption_state(machine_key)
		if bool(current.get("moving", false)):
			sim.contraption_tick(machine_key, delta, span_clear())
	var feeder_geometry: Dictionary = {}
	if kind=="pressure_feeder":
		_feeder_panel_refresh_left-=delta
		var current: Dictionary=sim.contraption_state(machine_key)
		if int(current.get("escrow_drive",0))>0:
			feeder_geometry = feeder_status(current)
			sim.contraption_tick(machine_key,delta,bool(feeder_geometry.ready))
	if _pulse_left > 0:
		_pulse_left = maxf(0, _pulse_left - delta)
	refresh_from_sim(feeder_geometry)


func refresh_from_sim(feeder_geometry: Dictionary = {}) -> void:
	if sim == null or _visual == null:
		return
	var record: Dictionary = sim.contraption_state(machine_key)
	if record.is_empty():
		return
	if int(record.get("pulses", 0)) != _last_pulses:
		_pulse_left = LOOK.pulse_seconds
		_last_pulses = int(record.get("pulses", 0))
		SOUND.play(self, "pulse", LOOK.pulse_volume_db)
	if int(record.get("completed_trips", 0)) != _last_arrivals:
		_last_arrivals = int(record.get("completed_trips", 0))
		if _panel != null:
			_panel.refresh_if_open("The basket has arrived. Collect the haul at its endpoint.")
	if kind == "lantern_lamp":
		var on: bool = record.get("lamp_on", true)
		var light := _visual.get_node_or_null("WarmInterior") as OmniLight3D
		if light != null: light.visible = on
		var heart := _visual.get_node_or_null("Heart") as Node3D
		if heart != null: heart.visible = on
		if _receiver != null: _receiver.visible = on or _highlighted
	if kind == "cargo_winch":
		var drum := _visual.get_node_or_null("Drum") as Node3D
		if drum != null:
			drum.rotation.x = (float(record.get("energy", 0)) * 0.45 + float(record.get("progress", 0)) * LOOK.drum_turns_per_trip) * TAU
		if _receiver != null:
			_receiver.visible = int(record.get("energy", 0)) > 0 or bool(record.get("moving", false)) or _highlighted
	if kind == "stormglass_lever":
		var lever := _visual.get_node_or_null("Lever") as Node3D
		if lever != null: lever.rotation.x = -sin(_pulse_left / LOOK.pulse_seconds * PI) * 0.6
	if kind == "ventlung_bellows":
		var bladder := _visual.get_node_or_null("Bellows") as Node3D
		if bladder != null:
			var capacity: float = float(sim.contraption_config().get("energy_capacity", 4))
			bladder.scale.y = 0.48 + 0.15 * float(record.get("energy", 0)) / maxf(1, capacity)
	if kind=="pressure_feeder":
		_refresh_feeder(record, feeder_geometry)
	_refresh_span(record)
	_last_state = record


func _refresh_span(record: Dictionary) -> void:
	if _cable == null:
		return
	var target := find_site(get_tree(), String(record.get("link", "")))
	_cable.visible = target != null
	if target == null:
		if _basket != null: _basket.position = Vector3(0, LOOK.cable_height_m - 0.45, 0)
		if _pulse != null: _pulse.hide()
		return
	var from := cable_anchor()
	var to := target.cable_anchor()
	var direction := to - from
	if direction.length_squared() < 0.0001:
		_cable.hide()
		return
	var up := direction.normalized()
	var across := Vector3.UP.cross(up).normalized()
	if across.length_squared() < 0.1: across = Vector3.RIGHT
	var depth := across.cross(up).normalized()
	# Scale the local cylinder axes. Basis.scaled would stretch in world axes
	# and turn a sloping cable into a tall spike beside the fixture.
	var basis := Basis(across * float(LOOK.cable_radius_m), up * direction.length(), depth * float(LOOK.cable_radius_m))
	_cable.global_transform = Transform3D(basis, (from + to) * 0.5)
	if _basket != null:
		var fraction := 1.0 if bool(record.get("at_landing", false)) else 0.0
		if bool(record.get("moving", false)):
			fraction += float(record.get("progress", 0)) * (-1.0 if fraction > 0 else 1.0)
		_basket.global_position = from.lerp(to, fraction) + Vector3.DOWN * 0.45
	if _pulse != null:
		_pulse.visible = _pulse_left > 0
		if _pulse.visible: _pulse.global_position = from.lerp(to, 1.0 - _pulse_left / LOOK.pulse_seconds)


func cable_anchor() -> Vector3:
	var height: float = LOOK.cable_height_m if kind in ["cargo_winch", "winch_landing"] else bounds_for(kind).y
	return global_position + Vector3.UP * height


func _exclusions(target: ContraptionSite = null) -> Array[RID]:
	var exclusions: Array[RID] = [get_rid()]
	if target != null: exclusions.append(target.get_rid())
	var player := get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player != null: exclusions.append(player.get_rid())
	return exclusions


func supported() -> bool:
	if not is_inside_tree(): return false
	var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * LOOK.support_probe_above_m,
		global_position - Vector3.UP * LOOK.support_probe_below_m)
	query.exclude = _exclusions()
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and Vector3(hit.get("normal", Vector3.ZERO)).dot(Vector3.UP) > 0.5


func link_clear(target: ContraptionSite) -> bool:
	if target == null or not is_inside_tree(): return false
	if kind == "white_connection" or target.kind == "white_connection":
		if not supported() or not target.supported(): return false
	if kind == "cargo_winch":
		if not supported() or not target.supported(): return false
		var shape := SphereShape3D.new()
		shape.radius = LOOK.basket_clearance_radius_m
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = shape
		query.transform = Transform3D(Basis.IDENTITY, cable_anchor() + Vector3.DOWN * 0.25)
		query.motion = target.cable_anchor() - cable_anchor()
		query.exclude = _exclusions(target)
		var space := get_world_3d().direct_space_state
		if not space.intersect_shape(query, 1).is_empty(): return false
		var sweep := space.cast_motion(query)
		return sweep.size() == 2 and sweep[0] >= 0.9999
	var ray := PhysicsRayQueryParameters3D.create(cable_anchor(), target.cable_anchor())
	ray.exclude = _exclusions(target)
	return get_world_3d().direct_space_state.intersect_ray(ray).is_empty()


func span_clear() -> bool:
	var record: Dictionary = sim.contraption_state(machine_key)
	return link_clear(find_site(get_tree(), String(record.get("link", ""))))


func perform(action: String) -> Dictionary:
	var before: Dictionary = sim.contraption_state(machine_key)
	var clear := true
	var other_clear := true
	var feeder_geometry: Dictionary = {}
	if kind == "pressure_feeder" and action in ["start","charge","resume"]:
		feeder_geometry = feeder_status(before)
		clear = bool(feeder_geometry.ready)
	elif action == "start": clear = span_clear()
	if kind=="pressure_feeder" and action in ["start","charge","resume"] and not clear:
		_feeder_panel_refresh_left = 0
		refresh_from_sim(feeder_geometry)
		return {"ok":false,"message":String(feeder_geometry.message)}
	if action == "pulse":
		clear = span_clear()
		var record: Dictionary = sim.contraption_state(machine_key)
		var receiver := find_site(get_tree(), String(record.get("link", "")))
		if receiver != null and receiver.kind == "white_connection":
			clear = clear and receiver.span_clear()
			var relay: Dictionary = sim.contraption_state(receiver.machine_key)
			receiver = find_site(get_tree(), String(relay.get("link", "")))
		other_clear = receiver != null and (receiver.span_clear() if receiver.kind=="cargo_winch" else bool(receiver.feeder_status().ready) if receiver.kind=="pressure_feeder" else true)
	var result: Dictionary = sim.contraption_action(machine_key, action, clear, other_clear, 0.0)
	if bool(result.get("ok", false)) and action in ["wind", "prime", "start", "sort","charge"]:
		SOUND.play(self, "tick", LOOK.work_volume_db)
	if action == "sort" and bool(result.get("ok", false)):
		_animate_sorting(before, sim.contraption_state(machine_key))
	if kind == "pressure_feeder": _feeder_panel_refresh_left = 0
	refresh_from_sim(feeder_geometry)
	if kind=="pressure_feeder":
		var pocket:=PressurePocket.find_source(get_tree(),String(before.get("source_id","")),get_parent())
		if pocket!=null:pocket.refresh_visual()
	return result


func feeder_forge(key: String) -> StationSite:
	for node in get_tree().get_nodes_in_group("crafting_stations"):
		if node is StationSite and get_parent().is_ancestor_of(node) and node.station_key==key:
			return node
	return null


func feeder_status(state: Dictionary = {}) -> Dictionary:
	if state.is_empty():state=sim.contraption_state(machine_key)
	var forge:=feeder_forge(String(state.get("forge_key","")))
	var source_id:=String(state.get("source_id",""))
	var pocket:=PressurePocket.find_source(get_tree(),source_id,get_parent()) if not source_id.is_empty() else null
	if forge==null:return {"ready":false,"message":"Attach your own basic forge before starting."}
	if not source_id.is_empty() and pocket==null:return {"ready":false,"message":"The pressure pocket is not present. Work is paused."}
	if forge.global_position.distance_to(Vector3(state.get("forge_position",Vector3.INF)))>.01:
		return {"ready":false,"message":"The forge moved. Reattach it before starting."}
	return feeder_connection_status(forge,pocket)


func feeder_connection_status(forge: StationSite, pocket: PressurePocket = null) -> Dictionary:
	var player:=get_tree().get_first_node_in_group("player") as WroughtwildPlayer
	if player!=null and player.trial!=null and player.trial.active():return {"ready":false,"message":"Production is paused while you are in a trial."}
	if forge==null or not forge.feeder_eligible(sim):return {"ready":false,"message":"Choose a basic forge that you built yourself."}
	var range_m:=float(sim.contraption_config().get("feeder_attachment_range",8))
	if global_position.distance_to(forge.global_position)>range_m:return {"ready":false,"message":"The forge is beyond the %.0f metre connection." % range_m}
	if not _feeder_support(self,LOOK.feeder_support_half_width_m) or not _feeder_support(forge,LOOK.station_support_half_width_m):
		return {"ready":false,"message":"Support all feet of the feeder and forge to resume."}
	if not _connection_clear(forge,forge.global_position+Vector3.UP*LOOK.feeder_link_height_m):return {"ready":false,"message":"Clear the connection between the feeder and forge."}
	if pocket!=null:
		if pocket.sim!=sim or pocket.source_state().is_empty():return {"ready":false,"message":"This pocket belongs to another world."}
		if global_position.distance_to(pocket.global_position)>range_m:return {"ready":false,"message":"The pocket is beyond the %.0f metre connection." % range_m}
		if not pocket.supported():return {"ready":false,"message":"The pressure casing has lost its supporting ground."}
		if not _connection_clear(pocket,pocket.connection_anchor()):return {"ready":false,"message":"Clear the connection to the pressure pocket."}
	return {"ready":true,"message":"The forge and feeder are supported; their connections are clear."}


func _feeder_support(body: StaticBody3D, half_width: float) -> bool:
	var exclusions: Array[RID]=[body.get_rid(),get_rid()]
	var player:=get_tree().get_first_node_in_group("player") as CollisionObject3D
	if player!=null:exclusions.append(player.get_rid())
	for x in [-half_width,half_width]:
		for z in [-half_width,half_width]:
			var foot:=body.to_global(Vector3(x,0,z))
			var query:=PhysicsRayQueryParameters3D.create(foot+Vector3.UP*LOOK.support_probe_above_m,foot-Vector3.UP*LOOK.support_probe_below_m)
			query.exclude=exclusions
			var hit:=get_world_3d().direct_space_state.intersect_ray(query)
			var collider: Object=hit.get("collider")
			if hit.is_empty() or not collider is StaticBody3D or collider is ResourceNode or collider is ContraptionSite or collider is StationSite or collider is PressurePocket:return false
			if Vector3(hit.get("normal",Vector3.ZERO)).dot(Vector3.UP)<.5:return false
	return true


func _connection_clear(target: StaticBody3D, destination: Vector3) -> bool:
	var shape:=SphereShape3D.new()
	shape.radius=LOOK.feeder_link_radius_m
	var query:=PhysicsShapeQueryParameters3D.new()
	query.shape=shape
	query.transform=Transform3D(Basis.IDENTITY,global_position+Vector3.UP*LOOK.feeder_link_height_m)
	query.motion=destination-query.transform.origin
	var exclusions:=_exclusions()
	exclusions.append(target.get_rid())
	query.exclude=exclusions
	var space:=get_world_3d().direct_space_state
	if not space.intersect_shape(query,1).is_empty():return false
	var sweep:=space.cast_motion(query)
	return sweep.size()==2 and sweep[0]>=.9999


func attach_feeder(forge_key: String, source_id: String) -> Dictionary:
	var forge:=feeder_forge(forge_key)
	var pocket:=PressurePocket.find_source(get_tree(),source_id,get_parent()) if not source_id.is_empty() else null
	if forge==null or (not source_id.is_empty() and pocket==null):
		_feeder_panel_refresh_left = 0
		refresh_from_sim()
		return {"ok":false,"message":"That forge or pocket is no longer here."}
	var status:=feeder_connection_status(forge,pocket)
	if not bool(status.ready):
		# A rejected candidate does not replace the stored attachment. Refresh its
		# own current diagnosis, rather than cache the candidate's obstruction.
		_feeder_panel_refresh_left = 0
		refresh_from_sim()
		return {"ok":false,"message":String(status.message)}
	var result: Dictionary=sim.contraption_attach_feeder(machine_key,source_id,forge_key,forge.global_position,true)
	_feeder_panel_refresh_left = 0
	refresh_from_sim()
	return result


func _connection_mesh(colour: Color) -> MeshInstance3D:
	var node:=MeshInstance3D.new()
	var mesh:=CylinderMesh.new()
	mesh.top_radius=1
	mesh.bottom_radius=1
	mesh.height=1
	mesh.radial_segments=6
	node.mesh=mesh
	node.material_override=_material(colour)
	add_child(node)
	return node


func _show_connection(node: MeshInstance3D, target: Vector3) -> void:
	node.visible=target.is_finite()
	if not node.visible:return
	var from:=global_position+Vector3.UP*LOOK.feeder_link_height_m
	var delta:=target-from
	if delta.length()<.01:
		node.hide()
		return
	var up:=delta.normalized()
	var across:=Vector3.UP.cross(up).normalized()
	if across.length_squared()<.1:across=Vector3.RIGHT
	var depth:=across.cross(up).normalized()
	node.global_transform=Transform3D(Basis(across*LOOK.feeder_link_radius_m,up*delta.length(),depth*LOOK.feeder_link_radius_m),(from+target)*.5)


func _refresh_feeder(record: Dictionary, geometry: Dictionary = {}) -> void:
	var status := feeder_status(record) if geometry.is_empty() else geometry
	var config := sim.contraption_config()
	var active:=int(record.get("escrow_drive",0))>0
	var paused:=bool(record.get("feeder_paused",false)) or not bool(status.ready)
	var progress:=float(record.get("cycle_seconds",0))/maxf(.01,float(config.get("feeder_cycle_seconds",8)))
	var drum:=_visual.get_node_or_null("Drum") as Node3D
	if drum!=null:drum.rotation.x=(float(record.get("energy",0))*.25+progress)*TAU
	var bellows:=_visual.get_node_or_null("Bellows") as Node3D
	if bellows!=null:bellows.scale.y=.72+(.28*(.5+.5*sin(progress*TAU)) if active else .28*float(record.get("energy",0))/maxf(1,float(config.get("energy_capacity",4))))
	if _receiver!=null:_receiver.visible=active or int(record.get("energy",0))>0 or _highlighted
	var inputs: Dictionary = record.get("input", {})
	var has_clay := false
	var has_fuel := false
	for family in config.get("feeder_inputs", {}):
		if int(inputs.get(family, 0)) > 0: has_clay = true
	for family in config.get("feeder_fuels", {}):
		if int(inputs.get(family, 0)) > 0: has_fuel = true
	_hopper_load.visible = has_clay
	_fuel_load.visible = has_fuel
	_output_load.visible=not Dictionary(record.get("output",{})).is_empty()
	var forge:=feeder_forge(String(record.get("forge_key","")))
	_show_connection(_feeder_pipe,forge.global_position+Vector3.UP*LOOK.feeder_link_height_m if forge!=null else Vector3.INF)
	var pocket:=PressurePocket.find_source(get_tree(),String(record.get("source_id","")),get_parent())
	_show_connection(_pressure_pipe,pocket.connection_anchor() if pocket!=null else Vector3.INF)
	var changed:=int(record.get("completed_cycles",0))!=_last_cycles
	var status_key:=str(active)+str(paused)+String(status.message)
	var state_changed := changed or status_key != _last_feeder_status
	for field in ["input", "output", "energy", "escrow_drive", "queued_cycles", "feeder_paused", "forge_key", "source_id"]:
		if record.get(field) != _last_state.get(field): state_changed = true
	var refresh_due := _feeder_panel_refresh_left <= 0
	var readout_changed := false
	if state_changed or refresh_due or _feeder_readout.is_empty():
		var next_readout := FeederReadout.inspect(self, record, status)
		readout_changed = next_readout != _feeder_readout
		_feeder_readout = next_readout
		_feeder_panel_refresh_left = LOOK.feeder_panel_refresh_seconds
	# Commit the presentation snapshot before a panel callback can inspect us.
	_last_state = record
	if state_changed:
		_last_cycles=int(record.get("completed_cycles",0))
		_last_feeder_status=status_key
		if changed:SOUND.play(self,"tick",LOOK.work_volume_db)
		if _panel!=null:_panel.refresh_if_open("A firing cycle is complete. Bricks are in the output tray." if changed else "")
	elif _panel!=null and refresh_due and (active or readout_changed):
		_panel.refresh_if_open()


func _load_mesh(at: Vector3, size: Vector3, material: Material) -> MeshInstance3D:
	# A bounded representative load is presentation; the native hopper/tray
	# retains exact item ownership and the inspection panel shows quantities.
	var node:=MeshInstance3D.new()
	var mesh:=BoxMesh.new()
	mesh.size=size
	node.mesh=mesh
	node.position=at
	node.material_override=material
	_visual.add_child(node)
	return node


func vent_unused_drive(amount: int) -> void:
	if amount<=0:return
	var cloud:=_sphere(LOOK.pulse_radius_m,LOOK.feeder_vent_colour)
	get_parent().add_child(cloud)
	cloud.global_position=global_position+Vector3.UP*LOOK.feeder_link_height_m
	var tween:=cloud.create_tween()
	tween.set_parallel(true)
	tween.tween_property(cloud,"position:y",cloud.position.y+.65,LOOK.feeder_vent_seconds)
	tween.tween_property(cloud,"scale",Vector3.ONE*3,LOOK.feeder_vent_seconds)
	tween.chain().tween_callback(cloud.queue_free)
	SOUND.play(cloud,"tick",LOOK.work_volume_db)


static func _inventory_units(items: Dictionary) -> int:
	var total := 0
	for count in items.values(): total += int(count)
	return total


func _animate_sorting(before: Dictionary, after: Dictionary) -> void:
	for port in ["ferrous", "remainder"]:
		var moved := _inventory_units(after.get(port, {})) - _inventory_units(before.get(port, {}))
		for index in mini(moved, int(LOOK.sort_visual_units)):
			var chip := MeshInstance3D.new()
			var mesh := BoxMesh.new()
			mesh.size = Vector3(0.08, 0.06, 0.07)
			chip.mesh = mesh
			chip.material_override = _material(LOOK.iron_chip_colour if port == "ferrous" else LOOK.ordinary_chip_colour)
			_visual.add_child(chip)
			chip.position = Vector3(0.02 * float(index), 1.05, -0.12)
			var attracted := Vector3(-0.35, 0.86, 0.02) if port == "ferrous" else Vector3(0.32, 0.66, 0.02)
			var landing := Vector3(-0.4, 0.32, 0.15) if port == "ferrous" else Vector3(0.4, 0.32, 0.15)
			var tween := create_tween()
			tween.tween_interval(float(index) * 0.035)
			tween.tween_property(chip, "position", attracted, LOOK.sort_cycle_seconds * 0.45).set_trans(Tween.TRANS_SINE)
			tween.tween_property(chip, "position", landing, LOOK.sort_cycle_seconds * 0.55)
			tween.tween_callback(chip.queue_free)


func bellows_target() -> ResourceNode:
	var range_m: float = float(sim.contraption_config().get("bellows_range", 3.0))
	var nearest: ResourceNode
	var nearest_distance := range_m + 1.0
	# Deliberately local physical input. Never inspect inventories, intact items,
	# trial deposits, enemies or hidden resource state for a remote target.
	for node in get_tree().get_nodes_in_group("resources"):
		if not node is ResourceNode: continue
		var resource := node as ResourceNode
		var distance_m := global_position.distance_to(resource.global_position)
		if distance_m > range_m or distance_m >= nearest_distance or not _responds_to_impact(resource): continue
		var query := PhysicsRayQueryParameters3D.create(global_position + Vector3.UP * 0.6,
			resource.global_position + Vector3.UP * 0.3)
		query.exclude = _exclusions()
		var hit := get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty() and hit.get("collider") != resource: continue
		nearest = resource
		nearest_distance = distance_m
	return nearest


static func _responds_to_impact(resource: ResourceNode) -> bool:
	if resource.remaining_units <= 0: return false
	if resource.is_seam(): return resource.wedge_set
	if resource.visual in [&"slate_seam", &"shellstone_seam", &"clay_bank", &"corkbark_deadfall"]: return true
	return resource.heat_to_work > 0 and not resource.cracked and resource.hot_level >= resource.heat_to_work


func release_at_resource(player: WroughtwildPlayer) -> Dictionary:
	var resource := bellows_target()
	var distance_m := global_position.distance_to(resource.global_position) if resource != null else -1.0
	var result: Dictionary = sim.contraption_action(machine_key, "release", resource != null, true, distance_m)
	if bool(result.get("ok", false)) and resource != null:
		SOUND.play(self, "tick", LOOK.work_volume_db)
		# Use the exact existing impact/pickup route. No invented output multiplier
		# or spell requirement is introduced by the pressure chamber.
		player._apply_work(resource, resource.strike())
		var pressure := _sphere(LOOK.pulse_radius_m, LOOK.pulse_colour)
		add_child(pressure)
		pressure.global_position = global_position + Vector3.UP * 0.55
		var tween := create_tween()
		tween.tween_property(pressure, "global_position", resource.global_position + Vector3.UP * 0.3, LOOK.pressure_pulse_seconds)
		tween.tween_callback(pressure.queue_free)
	refresh_from_sim()
	return result
