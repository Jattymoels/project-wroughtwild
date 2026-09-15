extends Sandpit
var checks := 0
var failures := 0
var output := ""
var trace: Node
var held := false
var receipt := {}
class EntryControls extends WorldSeedControls:
	var probe: Node
	func release() -> void:
		probe.check(load("res://art/scenery_resources.gd").ready() and not player.is_physics_processing(),"Continue prepares scenery before control release")
		super.release()
func check(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL SCENERY ",label)
	return ok
func _ready() -> void:
	output=OS.get_environment("WROUGHTWILD_ARRIVAL_OUTPUT")
	trace=preload("res://scripts/play03_trace.gd").install(self,PackedStringArray(["--play03-trace="+output]))
	if OS.get_cmdline_user_args().has("--scenery-device-only"):
		_device_only.call_deferred()
		return
	seed_controls=EntryControls.new()
	seed_controls.probe=self
	add_child(seed_controls)
	seed_controls.configure(self,"77",output.get_base_dir().path_join("lifecycle-start.json"))
	_run.call_deferred()
func _build_world(seed_value: int) -> void:
	held=not player.is_physics_processing() and not player.is_processing_unhandled_input()
	super._build_world(seed_value)
func _retire(node: Node) -> void:
	node.get_parent().remove_child(node)
	node.free()
func _materials(node: ResourceNode) -> Array:
	if node.visual!=&"thrumroot": return node.get_node("StrangeCore").materials
	var result := []
	for mesh: MeshInstance3D in node.get_node("F2Source").find_children("*","MeshInstance3D",true,false): result.append(mesh.material_override)
	return result
func _run() -> void:
	var resources=load("res://art/scenery_resources.gd")
	check(not resources.ready(),"fresh process begins without scenery preparation")
	var saved: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(seed_controls.save_path))
	var selection: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(output.get_base_dir().path_join("lifecycle-selection.json")))
	var began := Time.get_ticks_usec()
	if not check(seed_controls.continue_saved(),"validated Continue accepts labelled partial/depleted RF05 fixture"):
		finish();return
	receipt["continue_ms"]=(Time.get_ticks_usec()-began)/1000.0
	check(held and player.is_physics_processing(),"normal Continue holds then releases movement")
	check(_sim().export_json()==String(saved.sim),"Continue retains exact native paid ownership/progression")
	var captured: Dictionary=JSON.parse_string(JSON.stringify(SaveManager.new().capture(player),"",true,true))
	check(captured.blocks==saved.blocks and captured.stations==saved.stations and captured.world_drops==saved.world_drops,"paid buildings/stations and loose ownership remain exact")
	check(terrain.world_profile()=="frontier_v8" and terrain.seed_value()==77 and terrain.map.lakes.size()==1,"RF05 identity/lake preserved")
	check(load("res://art/creature_resources.gd").ready_for(_sim()),"full creature preparation still complete")
	var native := _sim().export_json()
	var before_count := get_tree().get_nodes_in_group("resources").size()
	var adapters: Array=resources._adapters.duplicate()
	began=Time.get_ticks_usec()
	resources.prepare(trace)
	receipt["repeat_prepare_ms"]=(Time.get_ticks_usec()-began)/1000.0
	check(resources._adapters==adapters and before_count==get_tree().get_nodes_in_group("resources").size() and _sim().export_json()==native,"repeat preparation keeps caches and creates no source or owner")
	check(not terrain.resource_stream.records.has(selection.depleted) and terrain.resource_stream.materialise(selection.depleted)==null,"fresh Continue does not resurrect depleted source")
	var scene := load("res://scenes/resource_node.tscn") as PackedScene
	for kind: String in selection.sources:
		var id: String=selection.sources[kind]
		var record: Dictionary=terrain.resource_stream.records[id].duplicate(true)
		var node := terrain.resource_stream.materialise(id)
		check(node.drive_progress==1 and node.remaining_units==int(record.remaining_units),kind+" restores partial work and stock")
		check((node.get_node("CollisionShape3D").shape as BoxShape3D).size==StrangeResourceArt.bounds_for(StringName(kind)),kind+" exact existing collision envelope")
		var other := scene.instantiate() as ResourceNode
		other.visual=StringName(kind);other.material_family=StringName(kind)
		other.drive_presses=node.drive_presses;other.remaining_units=node.remaining_units
		terrain.nodes_root.add_child(other)
		var a: Array=_materials(node)
		var b: Array=_materials(other)
		check(not a.is_empty() and a.size()==b.size() and a[0]!=b[0],kind+" independent work shader instances")
		var parameter := "work_level" if kind=="thrumroot" else "work"
		var other_work: Variant=b[0].get_shader_parameter(parameter)
		a[0].set_shader_parameter(parameter,.713)
		check(b[0].get_shader_parameter(parameter)==other_work,kind+" material work cannot leak to another source")
		if kind!="thrumroot":
			var root := node.get_node("StrangeCore")
			check(root.get_node("Core").get_child_count()==3,kind+" retains all three authored LODs")
			for level: String in ["near","middle","far"]:
				root.set_lod(level)
				for child in root.get_node("Core").get_children(): check(child.visible==(child.name==level),kind+" exact LOD visibility "+level)
			root.set_lod("near")
		_retire(other)
		var work := node.work(_sim())
		check(not work.has("refusal") and node.drive_progress==2 and node.remaining_units==int(record.remaining_units),kind+" next normal work preserves finite stock until completion")
		_retire(node)
		node=terrain.resource_stream.materialise(id)
		check(node.drive_progress==2 and node.remaining_units==int(record.remaining_units) and node.position==Vector3(record.position[0],record.position[1],record.position[2]),kind+" unload/reload preserves work stock and anchor")
		var granted := 0
		for i in 100:
			if node.remaining_units<=0: break
			granted+=int(node.work(_sim()).get("granted",0))
		check(node.remaining_units==0 and granted==int(record.remaining_units),kind+" depletion pays exactly remaining finite units")
		_retire(node)
		check(not terrain.resource_stream.records.has(id) and terrain.resource_stream.materialise(id)==null,kind+" retired depletion cannot recreate a source")
	check(_sim().export_json()==native,"source presentation/work changes no native inventory without caller collection")
	_device_check()
	# Short use check of the private near-source pose, no pointer interaction.
	for i in 8: await get_tree().physics_frame
	check(player.is_on_floor() and player.position.y>0,"private scenery pose loads onto supported ground")
	check(Input.mouse_mode==Input.MOUSE_MODE_VISIBLE,"headless check never captures mouse")
	finish()
func _device_check() -> void:
	# One affected real crafted device, with explicitly seeded test recipe inputs.
	_sim().add_station("workbench")
	var recipe: Dictionary=_sim().recipe("assemble_ventlung_bellows")
	for item: String in recipe.inputs: _sim().add_material(item,int(recipe.inputs[item]))
	check(_sim().craft("assemble_ventlung_bellows").get("crafted",false),"bellows crafts through existing paid recipe")
	check(_sim().contraption_place("ventlung_bellows","play07_bellows",player.position+Vector3(4,0,0),0),"native placement consumes bellows kit")
	var site := ContraptionSite.new()
	site.machine_key="play07_bellows";site.sim=_sim();add_child(site)
	var other_device := StrangeResourceArt.fixture_visual("ventlung_bellows")
	add_child(other_device)
	var resting: float=other_device.membrane.scale.y
	check(site._visual.materials[0]!=other_device.materials[0],"crafted device has independent animated materials")
	check(site.perform("prime").get("ok",false),"existing bellows hand-priming succeeds")
	check(int(_sim().contraption_state(site.machine_key).energy)>0 and site._visual.membrane.scale.y!=resting and other_device.membrane.scale.y==resting,"paid energy drives only its own membrane")
	var ledger := _sim().contraption_save()
	_retire(other_device)
	ContraptionSite.restore_all(self,_sim())
	check(_sim().contraption_save()==ledger and ContraptionSite.find_site(get_tree(),"play07_bellows")!=null,"device scene restore preserves exact stored energy and owner")
func _device_only() -> void:
	load("res://art/scenery_resources.gd").prepare(trace)
	player.set_physics_process(false)
	_device_check()
	finish()
func finish() -> void:
	trace.stop("scenery_lifecycle")
	receipt.merge({"checks":checks,"failures":failures,"trace":trace.output_path})
	FileAccess.open(output.path_join("report.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"))
	print("SCENERY_LIFECYCLE ",JSON.stringify(receipt))
	get_tree().quit(0 if failures==0 else 1)
