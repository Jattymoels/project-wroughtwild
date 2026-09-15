class_name ResourceStream
extends RefCounted
## Generated resources persist independently of their nearby presentation.
## An unloaded node keeps its record; only a depleted node loses its record.
# Load lazily, then retain once. A script-time preload cycles through
# ResourceNode -> Terrain -> ResourceStream in terrain-only entry scenes.
static var _resource_scene: PackedScene
var terrain: Terrain
var records: Dictionary = {}
var active: Dictionary = {}
var buckets: Dictionary = {}
var _presentation_defaults: Dictionary = {}
var _timer := 0.0
var _focus := Vector3.INF
var radius_m := 120.0
var retire_margin_m := 32.0
var nodes_per_frame := 12
var resource_build_budget_ms: float
var refresh_seconds := 0.25
var _pending: Array[String] = []
var canopies: ResourceCanopies
var _projection_pending: Dictionary = {} # Weak, coalesced decorative seam jobs; never saved.

func setup(owner_terrain: Terrain, definitions: Array) -> void:
	terrain = owner_terrain
	var settings: Dictionary = preload("res://art/strange_stream.tres").settings()
	radius_m = settings.radius_m
	retire_margin_m = settings.retire_margin_m
	nodes_per_frame = settings.nodes_per_frame
	resource_build_budget_ms = settings.resource_build_budget_ms
	refresh_seconds = settings.refresh_seconds
	for def in definitions:
		var row:=definition_record(def,float(terrain.map.cell_size))
		records[row.resource_id]=row
	for id in records:
		_presentation_defaults[id]={}
		for field in ["visual","resource_id","habitat_id","presentation_label","era","site_id","harvest_stages","use_preview"]:
			_presentation_defaults[id][field]=records[id][field]
	_reindex()
	canopies = ResourceCanopies.new()
	canopies.setup(self)

static func definition_record(def: Dictionary, cs: float) -> Dictionary:
	var id := String(def.get("resource_id", "wn_%s_%d_%d_%d" % [def.type,def.x,def.y,def.z]))
	return {
		"name":id,"resource_id":id,"habitat_id":String(def.get("habitat_id","")),
		"presentation_label":String(def.get("presentation_label",def.get("display_name",""))),
		"parent":"Terrain/ResourceNodes","family":String(def.material_family),"visual":String(def.visual),
		"position":[(int(def.x)+0.5)*cs,float(def.y),(int(def.z)+0.5)*cs],
		"remaining_units":int(def.units),"units_per_harvest":int(def.units_per_harvest),
		"heat_to_work":int(def.get("heat_to_work",0)),"tool_item":String(def.get("tool_item","")),
		"drive_presses":int(def.get("drive_presses",1)),"drive_progress":0,"wedge_set":false,"cracked":false,
		"era":int(def.get("era",1)),"site_id":String(def.get("site_id","")),
		"harvest_stages":Array(def.get("harvest_stages",[])),"use_preview":String(def.get("use_preview",""))}

func _reindex() -> void:
	buckets.clear()
	for id in records:
		var p: Array = records[id].position
		var bucket := Vector2i(floori(float(p[0])/32.0),floori(float(p[2])/32.0))
		if not buckets.has(bucket): buckets[bucket]=[]
		buckets[bucket].append(id)

func _remember(id: String) -> void:
	var node: ResourceNode = active.get(id)
	if not is_instance_valid(node):
		# tree_exiting captures depletion before a streamed scene disappears.
		active.erase(id)
		return
	if node.remaining_units <= 0:
		records.erase(id)
		return
	var record: Dictionary = records[id]
	for field in ["remaining_units","units_per_harvest","heat_to_work","tool_item","drive_presses","drive_progress","wedge_set","cracked"]:
		record[field] = node.get(field)
	record.position = [node.position.x,node.position.y,node.position.z]

func _exiting(id: String) -> void:
	var node: ResourceNode = active.get(id)
	if is_instance_valid(node): _projection_pending.erase(node.get_instance_id())
	_remember(id)
	active.erase(id)
	if canopies != null: canopies.update(id)

func capture() -> Array:
	for id in active.keys(): _remember(id)
	var result: Array = []
	for id in records.keys(): result.append(records[id].duplicate(true))
	return result

func restore(saved: Array) -> void:
	_projection_pending.clear()
	for id in active.keys():
		var node: ResourceNode = active[id]
		if is_instance_valid(node):
			node.tree_exiting.disconnect(_exiting.bind(id))
			node.get_parent().remove_child(node)
			node.free()
	active.clear()
	records.clear()
	_pending.clear()
	for entry in saved:
		var id:=String(entry.name)
		var restored:Dictionary=entry.duplicate(true)
		# Optional presentation fields were absent in early schema-2 payloads.
		# Recover them from this exact profile's generated definition, never
		# replacing the saved quantities, partial work or depleted-node list.
		var defaults:Dictionary=_presentation_defaults.get(id,{})
		for field in defaults:
			if not restored.has(field): restored[field]=defaults[field]
		records[id] = restored
	_reindex()
	_focus=Vector3.INF
	if canopies != null: canopies.rebuild()

func materialise(id: String, stream_projection := false) -> ResourceNode:
	if active.has(id) and is_instance_valid(active[id]): return active[id]
	if not records.has(id): return null
	var record: Dictionary = records[id]
	if int(record.get("era",1))>terrain.current_era: return null
	# Retain the packed scene: instantiated nodes do not retain the source
	# PackedScene, so a local load can otherwise reread it for every arrival.
	if _resource_scene == null: _resource_scene = load("res://scenes/resource_node.tscn")
	var trace_began := Time.get_ticks_usec() if terrain.play03_trace != null else 0
	var node: ResourceNode = G1Art.resource(_resource_scene,record)
	node.name=id
	for field in ["resource_id","habitat_id","presentation_label","remaining_units","units_per_harvest","heat_to_work","tool_item","drive_presses","drive_progress","wedge_set","cracked","visual"]:
		if record.has(field): node.set(field,record[field])
	node.material_family=StringName(record.family)
	var p: Array=record.position
	node.position=Vector3(p[0],p[1],p[2])
	node.set_meta("rare_stages",record.get("harvest_stages",[]))
	node.set_meta("rare_use",record.get("use_preview",""))
	node.set_meta("site_id",record.get("site_id",""))
	node.set_meta("stream_projection",stream_projection)
	node.set_meta("arrival_trace", terrain.play03_trace)
	var entry_began := Time.get_ticks_usec() if terrain.play03_trace != null else 0
	terrain.nodes_root.add_child(node)
	if terrain.play03_trace != null and StrangeResourceArt.supports(node.visual): terrain.play03_trace.note_arrival("scenery_tree_entry",entry_began,{"visual":String(node.visual),"id":id})
	active[id]=node
	if canopies != null: canopies.update(id)
	node.tree_exiting.connect(_exiting.bind(id))
	node._refresh_wedge_look()
	node.set_meta("stream_projection",true)
	if terrain.play03_trace != null: terrain.play03_trace.note_resource(trace_began,String(node.visual),stream_projection)
	return node

func focus(at: Vector3, immediate := false) -> void:
	_focus=at
	var centre := Vector2i(floori(at.x/32.0),floori(at.z/32.0))
	var reach := ceili(radius_m/32.0)
	var wanted: Array[String]=[]
	for z in range(centre.y-reach,centre.y+reach+1):
		for x in range(centre.x-reach,centre.x+reach+1):
			for id in buckets.get(Vector2i(x,z),[]):
				if not records.has(id) or active.has(id): continue
				var r: Dictionary=records[id]
				if int(r.get("era",1))>terrain.current_era: continue
				var p: Array=r.position
				if Vector2(float(p[0])-at.x,float(p[2])-at.z).length_squared()<=radius_m*radius_m: wanted.append(id)
	wanted.sort_custom(func(a:String,b:String)->bool:
		var pa:Array=records[a].position; var pb:Array=records[b].position
		return Vector2(pa[0]-at.x,pa[2]-at.z).length_squared()<Vector2(pb[0]-at.x,pb[2]-at.z).length_squared())
	_pending=wanted
	for id in active.keys():
		var node: ResourceNode=active[id]
		if not is_instance_valid(node): active.erase(id); continue
		if node.is_queued_for_deletion(): continue
		if Vector2(node.position.x-at.x,node.position.z-at.z).length()>radius_m+retire_margin_m:
			_remember(id)
			node.get_parent().remove_child(node)
			node.free()
	if immediate:
		for id in _pending: materialise(id)
		_pending.clear()
		_step_projections(0)

func refresh_due(delta: float) -> bool:
	return _timer <= delta

func tick(delta: float, at: Vector3, allow_work := true, refresh := true) -> void:
	_timer-=delta
	# Terrain focus takes precedence for one frame; retain the due timer and
	# pending IDs so stationary next-frame processing cannot lose this work.
	if not allow_work: return
	if _timer<=0 and refresh:
		_timer=refresh_seconds
		focus(at)
		return # Freeing distant nodes and creating arrivals use separate frames.
	var began := Time.get_ticks_usec()
	var deadline := began + int(resource_build_budget_ms*1000.0)
	for i in mini(nodes_per_frame,_pending.size()):
		materialise(_pending.pop_front(),true)
		if Time.get_ticks_usec() >= deadline: break
	_step_projections(deadline)

func has_resource(id: String) -> bool:
	if active.has(id): _remember(id)
	return records.has(id)

## Decoration uses the existing resource-work slot and budget, not one budget
## per node. Collision/native ribbons remain synchronous and authoritative.
func queue_projection(node: ResourceNode) -> void:
	_projection_pending[node.get_instance_id()] = weakref(node)

func _step_projections(deadline_usec: int) -> void:
	while not _projection_pending.is_empty() and (deadline_usec==0 or Time.get_ticks_usec()<deadline_usec):
		var id: int = _projection_pending.keys()[0]
		var node: ResourceNode = _projection_pending[id].get_ref()
		if not is_instance_valid(node) or not node.is_inside_tree() or node.is_queued_for_deletion():
			_projection_pending.erase(id)
		elif bool(node.call("step_projection",deadline_usec)):
			_projection_pending.erase(id)
		else:
			return
