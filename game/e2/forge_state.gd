extends Node
## Read-only projection of existing station completion and feeder escrow.
## No timers, writes, native calls that advance work, or saved presentation state.
var surface: ShaderMaterial
var clinker: StandardMaterial3D
var visual_state := "cold"
var phase := 0.0
var amount := 0.0

func bind_mesh() -> void:
	var site := get_parent() as StationSite
	if site._mesh == null or site._mesh.mesh == null: return
	for i in site._mesh.mesh.get_surface_count():
		var original: Material = site._mesh.mesh.surface_get_material(i)
		if original.resource_name == "Work":
			surface = original.duplicate() as ShaderMaterial
			site._mesh.set_surface_override_material(i, surface)
		elif original.resource_name == "Charcoal":
			clinker = original.duplicate() as StandardMaterial3D
			clinker.emission_enabled = true
			clinker.emission = Color(1,.16,.015)
			clinker.emission_energy_multiplier = 0
			site._mesh.set_surface_override_material(i, clinker)
	_process(0)

func _process(_delta: float) -> void:
	if get_tree().paused: return
	var site := get_parent() as StationSite
	var sim: WroughtwildSim = load("res://scripts/sim.gd").shared()
	visual_state = "cold"
	phase = 0
	amount = 0
	var response := site.get_node_or_null("CraftWorkResponse")
	if response != null and not response.is_queued_for_deletion():
		visual_state = "manual completion"
		amount = float(E2ForgeArt.look().manual_amount)
	for node: Node in get_tree().get_nodes_in_group("contraptions"):
		if not node is ContraptionSite or node.kind != "pressure_feeder": continue
		var record: Dictionary = sim.contraption_state(node.machine_key)
		if String(record.get("forge_key", "")) != site.station_key or site.station_key.is_empty(): continue
		if int(record.get("escrow_drive", 0)) <= 0: continue
		phase = float(record.get("cycle_seconds",0)) / float(sim.contraption_config().feeder_cycle_seconds)
		var status: Dictionary = node.feeder_status(record)
		var player := get_tree().get_first_node_in_group("player") as Node3D
		var distant := player == null or player.global_position.distance_squared_to(node.global_position) > pow(ContraptionSite.LOOK.active_distance_m,2)
		var paused := bool(record.get("feeder_paused", false)) or not bool(status.ready) or distant or bool(sim.trial_active())
		visual_state = "paused / held firing" if paused else "paid firing"
		# Paid heat remains held while paused; phase stays frozen at native progress.
		amount = maxf(amount, float(E2ForgeArt.look().held_amount if paused else E2ForgeArt.look().firing_amount))
	if surface != null:
		surface.set_shader_parameter("work_amount", amount)
		surface.set_shader_parameter("native_phase", phase)
	if clinker != null: clinker.emission_energy_multiplier = amount * float(E2ForgeArt.look().clinker_gain)
