class_name PressurePocket
extends StaticBody3D
## The struck hearth predates the cataclysm. Its finite pressure belongs to
## the native world ledger; this remnant only exposes that state to the player.
const LOOK = preload("res://art/contraption_look.tres")
const FINISH = preload("res://art/rare_finish.tres")
var source_id := ""
var record: Dictionary = {}
var terrain: Terrain
var sim: WroughtwildSim
var _membrane: Node3D
var _highlighted := false
var _finish: Node3D


static func build(root: Node3D, ground: Terrain) -> void:
	var old:=root.get_node_or_null("PressurePockets")
	if old!=null:
		root.remove_child(old)
		old.queue_free()
	if ground.world_profile() not in ["frontier_v5", "frontier_v6","living_frontier_wave1","living_frontier_wave3"]:return
	var group:=Node3D.new()
	group.name="PressurePockets"
	root.add_child(group)
	for data: Dictionary in ground.map.get("pressure_pockets",[]):
		var pocket:=PressurePocket.new()
		pocket.name=String(data.id)
		pocket.source_id=String(data.id)
		pocket.record=data
		pocket.terrain=ground
		pocket.sim=ground._sim
		var cell:=float(ground.map.cell_size)
		pocket.position=Vector3((float(data.x)+.5)*cell,float(data.y)*cell,(float(data.z)+.5)*cell)
		var work: Vector3=data.get("work_position",pocket.position+Vector3.FORWARD)
		var toward:=work-pocket.position
		pocket.rotation.y=atan2(toward.x,toward.z)
		group.add_child(pocket)


static func find_source(tree: SceneTree, id: String, scope: Node = null) -> PressurePocket:
	for node in tree.get_nodes_in_group("pressure_pockets"):
		if node is PressurePocket and node.source_id==id and (scope==null or scope.is_ancestor_of(node)):return node
	return null


func _ready() -> void:
	add_to_group("pressure_pockets")
	var collider:=CollisionShape3D.new()
	var box:=BoxShape3D.new()
	box.size=LOOK.pocket_bounds
	collider.shape=box
	collider.position.y=box.size.y*.5
	add_child(collider)
	var hearth:=MeshInstance3D.new()
	hearth.name="OldHearth"
	hearth.mesh=AuthoredAssets.mesh_for("forge_basic")
	# An old craft remnant, never a StationSite or a free functioning forge.
	hearth.scale=Vector3.ONE*LOOK.pocket_hearth_scale
	add_child(hearth)
	var casing:=StrangeResourceArt.part(self,"vent_case","SplitCasing",LOOK.pocket_casing_offset)
	casing.scale=Vector3.ONE*LOOK.pocket_casing_scale
	_membrane=StrangeResourceArt.part(self,"ventlung","PressureMembrane",LOOK.pocket_casing_offset)
	_membrane.scale=Vector3.ONE*LOOK.pocket_membrane_scale
	_membrane.material_override=FINISH.surface("pressure")
	var inlay:=MeshInstance3D.new()
	inlay.name="ImpactInlay"
	inlay.mesh=AuthoredAssets.mesh_for("cataclysm_augmentation_inlay")
	inlay.position=LOOK.pocket_inlay_offset
	inlay.scale=LOOK.pocket_inlay_scale
	add_child(inlay)
	_finish=FINISH.build("pressure")
	add_child(_finish)
	refresh_visual()


func source_state() -> Dictionary:
	if sim==null:return {}
	for source: Dictionary in sim.contraption_pressure_sources():
		if String(source.id)==source_id:return source
	return {}


func interact_label() -> String:
	var state:=source_state()
	if int(state.get("remaining", 0)) <= 0:
		return InputPrompts.text("Struck blacksmith's hearth · Pocket spent · {interact} to inspect")
	return InputPrompts.formatted("Struck blacksmith's hearth · %d pressure strokes · {interact} to inspect", int(state.get("remaining",0)))


func interact(player: WroughtwildPlayer) -> void:
	var state:=source_state()
	var kit: Dictionary=sim.recipe("assemble_pressure_feeder")
	var kit_cost:=WorkPanel.cost_text(kit.get("inputs",{}),sim)
	var rows: Array=[{
		"text":"An asteroid struck this older blacksmith's hearth.",
		"details":"This hearth predates the catastrophe. The impact drove an augmentation trace through its pressure casing by accident; it was never built to harness the strike.",
		"button":"An older workshop", "enabled":false, "callback":func():pass},
		{"text":"%d / %d strokes remain. %s" % [int(state.get("remaining",0)),int(state.get("capacity",0)), "Hand-winding still works." if int(state.get("remaining",0)) <= 0 else "This pocket never refills."],
		"details":"Connect a pressure feeder within %.0f metres. Drawing pressure permanently spends pocket stock; stored drive remains usable and core harvesting is separate." % float(sim.contraption_config().get("feeder_attachment_range",8)),
		"button":"Finite pressure", "enabled":false, "callback":func():pass},
		{"text":"Use a bench-built feeder and your own basic forge.",
		"details":"At your workbench: %s make a pressure feeder. Load clay and ordinary fuel explicitly. Pressure supplies motion; fuel supplies heat. Hand-winding remains available after exhaustion." % kit_cost,
		"button":"Build a pressure feeder", "enabled":false, "callback":func():pass}]
	player.open_custom_panel("The struck blacksmith's hearth",rows)
	refresh_visual()


func set_highlight(on: bool) -> void:
	_highlighted=on
	refresh_visual()


func refresh_visual() -> void:
	if _membrane==null:return
	var state:=source_state()
	var fraction:=float(state.get("remaining",0))/maxf(1,float(state.get("capacity",1)))
	_membrane.scale=Vector3(1,lerpf(.4,1,fraction),1)*LOOK.pocket_membrane_scale
	# An empty source remains an inspectable old hearth. Hover never revives its
	# membrane or luminous stock promise, and cannot change the native ledger.
	_membrane.visible=fraction>0
	if _finish!=null:FINISH.set_state(_finish,fraction,0,_highlighted)


func connection_anchor() -> Vector3:
	return global_position+Vector3.UP*LOOK.feeder_link_height_m


func supported() -> bool:
	if terrain==null:return false
	var at:=StrangeSites._ground(terrain,global_position.x,global_position.z)
	return at.is_finite() and absf(at.y-global_position.y)<=LOOK.pocket_support_tolerance_m
