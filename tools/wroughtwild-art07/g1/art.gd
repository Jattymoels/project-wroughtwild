class_name G1Art
extends RefCounted
## Isolated presentation dispatch. Never writes native state or changes a body.
static var piece_cache: Dictionary = {}
const D1=preload("res://art07_d1/adapter.gd")
const D2=preload("res://art07_d2/adapter.gd")
const D3=preload("res://art07_d3/adapter.gd")
static var fallback_material:=StandardMaterial3D.new()

static func enabled() -> bool:
	return not "--baseline" in OS.get_cmdline_user_args()

static func piece_mesh(id: String, form: String, family: String) -> Mesh:
	if form in ["chest","fire"]: return E3HomeArt.closed(form,family)
	var mesh:Mesh
	if id in D1.IDS:mesh=D1.mesh_for(id)
	elif id in D2.IDS:mesh=D2.mesh_for(id)
	elif id in D3.IDS:mesh=D3.mesh_for(id,family)
	if mesh!=null:
		# Keep a valid base material behind each live per-instance family override.
		# It also remains valid while the preview releases its override at exit.
		for i in mesh.get_surface_count():
			if mesh.surface_get_material(i)==null:mesh.surface_set_material(i,fallback_material)
	return mesh

static func resource(scene: PackedScene, record: Dictionary) -> ResourceNode:
	var node: ResourceNode = scene.instantiate()
	if not enabled(): return node
	var visual := String(record.get("visual",""))
	var family := String(record.get("family",record.get("material_family","")))
	var script := ""
	if visual == "tree":
		script = "b1/native_tree" if family in ["wood","pine"] else "c1/native_resource" if family=="bog_oak" else "c3/native_resource" if family=="resinheart_log" else "c4/native_tree" if family=="ash_wood" else ""
	elif visual in ["boulder","seam"]: script="b3/native_resource"
	elif visual in ["clay_bank","reed_bed"]: script="c1/native_resource"
	elif visual in ["slate_seam","shellstone_seam"]: script="c2/native_resource"
	elif visual in ["resinheart_tree","corkbark_deadfall"]: script="c3/native_resource"
	elif visual in ["iron_vein","copper_vein","tin_vein","ember_iron_vein","silver_vein"]:script="c5/native_resource"
	# C5's raised bodies are only for the source's fallback review. The native
	# faceted ore ribbon remains exact in this game's generated geography.
	if not script.is_empty():
		node.set_script(load("res://"+script+".gd"))
		node.set_meta("g1_source",script.split("/")[0])
		if script=="b1/native_tree": node.source_kind="pine" if family=="pine" else "broadleaf"
	return node
