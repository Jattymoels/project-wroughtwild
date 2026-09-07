extends Node3D
## Isolated presentation/stream lifecycle. Existing native rare definitions are
## placed on a controlled support plane, not passed off as generated geography.
## No user saves, inventory grants or audio device are needed by these checks.
const KINDS := ["lanternheart","thrumroot","stormglass","pullstone","ventlung"]
const EMPTY_MESHES := ["empty_husk","thrumroot_shell","lightning_scar","scree","vent_case"]
const SOUND = preload("res://art/strange_sound.gd")
const DISCOVERY = preload("res://art/discovery_look.tres")

class SupportTerrain extends Terrain:
	var support_y := 4.0
	var missing := false
	func height_at(_x: int, _z: int) -> int:
		return 4
	func rendered_height(_x: float, _z: float, _reference_y: float, _reach := .8) -> float:
		return INF if missing else support_y

var checks := 0
var failures := 0
var terrain: SupportTerrain
var sim: WroughtwildSim
var dressing: Node3D
var original_records: Array=[]

func check(ok: bool, label: String) -> bool:
	checks+=1
	if not ok:
		failures+=1
		printerr("FAIL DISCOVERY: ",label)
	return ok

func _ready() -> void:
	_run.call_deferred()

func _run() -> void:
	sim=load("res://scripts/sim.gd").shared()
	if not check(sim.last_error().is_empty(),"native tuning is available"):
		_finish()
		return
	var economy_before:=sim.export_json()
	var machines_before:=sim.contraption_save()
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(load("res://scripts/sim.gd").get_tuning_directory().path_join("worldgen.json")))
	terrain=SupportTerrain.new()
	terrain.name="Terrain"
	terrain._sim=sim
	terrain.map={"cell_size":1.0,"width":128,"height":128,"seed":719,"nodes":[],"rare_sites":[]}
	add_child(terrain)
	terrain.set_physics_process(false)
	terrain.nodes_root=Node3D.new()
	terrain.nodes_root.name="ResourceNodes"
	terrain.add_child(terrain.nodes_root)
	for i in KINDS.size():
		var kind: String=KINDS[i]
		var site_id:="controlled_"+kind
		var at:=Vector3(12.5+i*20,4,12.5)
		var definition: Dictionary=data.nodes[kind].duplicate(true)
		definition.merge({"type":kind,"resource_id":site_id+"_intact","site_id":site_id,"x":int(at.x),"y":4,"z":int(at.z)},true)
		terrain.map.nodes.append(definition)
		terrain.map.rare_sites.append({"id":site_id,"resource_type":kind,"x":int(at.x),"z":int(at.z),
			"clue_points":PackedVector3Array([at+Vector3(-4,0,-2),at+Vector3(-2,0,3)]),
			"approach":PackedVector3Array([at+Vector3(-6,0,0),at+Vector3(-4,0,0),at+Vector3(-2,0,0),at])})
	# Exact chunks distinguish missing support from an unloaded native surface.
	for x in range(0,128,16):
		var chunk:=Node3D.new()
		terrain.add_child(chunk)
		terrain.chunks["%d_0"%x]=chunk
	terrain.resource_stream=ResourceStream.new()
	terrain.resource_stream.setup(terrain,terrain.map.nodes)
	original_records=terrain.resource_stream.capture()
	var generated_before:=var_to_bytes(terrain.map)
	dressing=StrangeSites.build(self,terrain)
	_check_clues()
	_check_support_and_building()
	await _check_cue_lifetime()
	check(var_to_bytes(terrain.map)==generated_before,"presentation retains every source definition, clue point and site anchor")
	check(sim.export_json()==economy_before and sim.contraption_save()==machines_before,"decoration and cue queries award no inventory and initialize no pressure ledger")
	_finish()

func _check_clues() -> void:
	var shared: Material
	check(not _has_gameplay_node(dressing),"all five site decorations contain no resource, pickup, collision or light nodes")
	check(terrain.resource_stream.capture()==original_records,"building site art leaves finite stock and work exactly unchanged")
	for i in KINDS.size():
		var definition: Dictionary=terrain.map.rare_sites[i]
		var group:=dressing.get_node(String(definition.id))
		var ids: Array=group.get_meta("resource_ids",[])
		check(ids==[String(definition.id)+"_intact"],KINDS[i]+" cue is bound to its generated stable resource identity")
		check(int(group.get_meta("clue_count",0))==definition.clue_points.size(),KINDS[i]+" keeps every supported native clue point")
		check(group.get_meta("intact_anchor")==Vector3(float(definition.x)+.5,4,float(definition.z)+.5),KINDS[i]+" retains its intact resource anchor")
		for j in definition.clue_points.size():
			var clue:=group.get_node("Clue_%02d"%j) as MeshInstance3D
			if not check(clue!=null and clue.mesh!=null,KINDS[i]+" has an inspectable decorative mesh"):continue
			check(clue.position==definition.clue_points[j],KINDS[i]+" keeps exact native clue X/Z and supported ground")
			check(String(clue.get_meta("clue_mesh_kind",""))==EMPTY_MESHES[i] and clue.mesh==AuthoredAssets.mesh_for("strange_"+EMPTY_MESHES[i]),KINDS[i]+" uses empty host/scar geometry, never the intact core")
			check(clue.get_child_count()==0 and not clue.has_method("interact") and not clue.has_method("work"),KINDS[i]+" clue offers no gathering action or payload")
			var actual_size:=clue.mesh.get_aabb().size*clue.scale
			check(actual_size.is_equal_approx(DISCOVERY.clue_size(KINDS[i])),KINDS[i]+" clue has the bounded documented readable size")
			check(clue.visibility_range_end>0 and clue.visibility_range_end<=preload("res://art/strange_look.tres").detail_distance_m,KINDS[i]+" clue has finite detail distance")
			var material:=clue.material_override as ShaderMaterial
			check(material!=null,KINDS[i]+" clue uses the inert shared surface")
			if material!=null:
				if shared==null:shared=material
				check(material==shared,KINDS[i]+" reuses the same cached clue material")
				check(float(material.get_shader_parameter("glow"))==0.0 and float(material.get_shader_parameter("movement"))==0.0 and float(material.get_shader_parameter("breathing"))==0.0,KINDS[i]+" empty clue has no glow or stock-like movement")

func _check_support_and_building() -> void:
	var group:=dressing.get_node("controlled_thrumroot")
	var clue:=group.get_node("Clue_00") as MeshInstance3D
	var original:=clue.transform
	terrain.support_y=3.25
	StrangeSites.refresh_area(self,terrain,0,0,128)
	check(clue.position.is_equal_approx(original.origin-Vector3.UP*.75),"clue follows the changed exact ground without moving its X/Z anchor")
	terrain.missing=true
	StrangeSites.refresh_area(self,terrain,0,0,128)
	check(not clue.visible and not bool(clue.get_meta("ground_supported",true)),"clue hides over an excavated unsupported chunk")
	StrangeSites.refresh_buildings(self,terrain)
	check(not clue.visible,"building refresh cannot revive an unsupported clue")
	terrain.missing=false
	terrain.support_y=4
	StrangeSites.refresh_area(self,terrain,0,0,128)
	check(clue.visible and clue.transform.is_equal_approx(original),"returning ground restores the identical inert clue pose")
	# Use the real native lattice registry as the presentation's building input.
	# This is a footprint probe, not a claim of paid first-person construction.
	var element:={"kind":"volume","axis":0,"cell":Vector3i(floori(clue.position.x/sim.lattice_registry_grid()),floori(clue.position.y/sim.lattice_registry_grid()),floori(clue.position.z/sim.lattice_registry_grid()))}
	var records_before:=terrain.resource_stream.capture()
	if check(sim.structure_place(element,"cube","wood",0),"a real native building footprint is available over the clue"):
		StrangeSites.refresh_buildings(self,terrain)
		check(not clue.visible and bool(clue.get_meta("hidden_by_building",false)),"building footprint suppresses the decorative clue")
		check(sim.structure_remove(element),"native footprint removal succeeds")
		StrangeSites.refresh_buildings(self,terrain)
		check(clue.visible and clue.transform.is_equal_approx(original),"removing the footprint restores exactly the same clue")
	check(terrain.resource_stream.capture()==records_before,"support and building clearing neither harvest nor refill resources")

func _check_cue_lifetime() -> void:
	var stream:=terrain.resource_stream
	for kind: String in KINDS:
		var group:=dressing.get_node("controlled_"+kind)
		var cue:=group.get_node("DiscoveryCue")
		var id:="controlled_"+kind+"_intact"
		check(stream.active.is_empty() and cue.eligible(),kind+" stocked unloaded record remains eligible for a local cue")
		var node:=stream.materialise(id)
		if not check(node!=null,kind+" actual resource scene can materialise from its record"):continue
		var units:=node.remaining_units
		var response:=node.work(sim)
		check(node.drive_progress==1 and node.remaining_units==units and not response.has("granted"),kind+" ordinary first press records partial work without yielding stock")
		check(cue.eligible() and int(stream.records[id].drive_progress)==1,kind+" eligibility synchronizes active partial work")
		stream.focus(Vector3(-1000,4,-1000),true)
		check(not stream.active.has(id) and cue.eligible(),kind+" partial stocked scene may unload without silencing its find")
		var checkpoint:=stream.capture()
		stream.restore(checkpoint)
		check(cue.eligible() and int(stream.records[id].drive_progress)==1,kind+" restored partial records remain eligible without loading a scene")
		node=stream.materialise(id)
		if not check(node!=null,kind+" partial record rematerialises"):continue
		var harvested:=0
		for press in node.drive_presses:
			if node.remaining_units<=0:break
			harvested+=int(node.work(sim).get("granted",0))
		check(node.remaining_units==0 and harvested==units,kind+" ordinary completed work exhausts exactly the existing finite haul")
		check(not cue.eligible() and not stream.records.has(id),kind+" depletion silences the cue before the resource scene finishes shrinking")
		var exhausted:=stream.capture()
		stream.restore(exhausted)
		check(not cue.eligible() and stream.materialise(id)==null,kind+" exhausted save/revisit cannot recreate a cue or resource")
		check(group.get_node("Clue_00").visible,kind+" empty decorative remains persist after finite depletion")
		stream.restore(checkpoint)
		check(cue.eligible() and stream.active.is_empty(),kind+" loading an earlier stocked checkpoint restores eligibility without fabricated stock")
		# Return to the all-unloaded initial state for the next independent family.
		stream.restore(original_records)
		await get_tree().process_frame
	# Multiple generated records belong to one site: only total exhaustion mutes it.
	var multiple:=SOUND.new()
	multiple.terrain=terrain
	multiple.resource_ids=["controlled_lanternheart_intact","controlled_ventlung_intact"]
	add_child(multiple)
	var reduced:=original_records.filter(func(row: Dictionary)->bool:return String(row.name)!="controlled_lanternheart_intact")
	stream.restore(reduced)
	check(multiple.eligible(),"another intact record at the same site keeps its cue eligible")
	stream.restore([])
	check(not multiple.eligible() and stream.records.is_empty(),"all missing records silence the site without initializing stock")
	stream.restore(original_records)
	check(multiple.eligible(),"restoring finite records restores a multi-resource site's cue")
	multiple.free()
	var clip_before:=SOUND._clip("thrumroot")
	check(SOUND._clip("thrumroot")==clip_before and clip_before.data.size()>0,"harvest one-shot synthesis retains its existing cached audio path")

func _has_gameplay_node(node: Node) -> bool:
	if node is CollisionObject3D or node is CollisionShape3D or node is Light3D or node is ResourceNode or node is Pickup:return true
	for child in node.get_children():
		if _has_gameplay_node(child):return true
	return false

func _finish() -> void:
	print("DISCOVERY_SITES %d checks, %d failures"%[checks,failures])
	get_tree().quit(1 if failures else 0)
