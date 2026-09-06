class_name StrangeResourceArt
extends RefCounted
## Shared authored visual lookup for wild specimens and their crafted payoffs.
## Native resources/contraptions own quantities, transfers and work completion.
const LOOK = preload("res://art/strange_look.tres")
const MACHINES = preload("res://art/contraption_look.tres")
const FINISH = preload("res://art/rare_finish.tres")
const IDS := ["lanternheart","thrumroot","stormglass","pullstone","ventlung"]
const LABELS := {"lanternheart":"Lanternheart in folded husks","thrumroot":"Braced Thrumroot coil","stormglass":"Intact Stormglass tube","pullstone":"Grit-bearing Pullstone","ventlung":"Breathing Ventlung membrane"}
static var _fixture_meshes: Dictionary = {}

static func supports(visual: StringName) -> bool:
	return String(visual) in IDS

static func mesh_for(visual: StringName, _seed: int = 0) -> Mesh:
	return AuthoredAssets.mesh_for("strange_"+("thrumroot_core" if visual==&"thrumroot" else String(visual)))

static func bounds_for(visual: StringName) -> Vector3:
	match String(visual):
		"thrumroot": return Vector3(2.2,0.9,0.75)
		"stormglass": return Vector3(2.2,1.12,1.35)
		"pullstone": return Vector3(2.0,1.2,1.1)
		"ventlung": return Vector3(1.2,1.2,1.2)
	return Vector3(0.75,0.9,0.75)

static func material(glow: float = 0.0, movement: float = 0.0, breathing: float = 0.0) -> ShaderMaterial:
	var result := ShaderMaterial.new()
	result.shader=preload("res://art/strange_surface.gdshader")
	result.set_shader_parameter("glow",glow)
	result.set_shader_parameter("movement",movement)
	result.set_shader_parameter("movement_rate",LOOK.paper_sway_rate)
	result.set_shader_parameter("breathing",breathing)
	return result

static func part(parent: Node3D, id: String, child_name: String, at: Vector3 = Vector3.ZERO, look: Material = null) -> MeshInstance3D:
	var instance := MeshInstance3D.new()
	instance.name=child_name
	instance.mesh=AuthoredAssets.mesh_for("strange_"+id)
	instance.material_override=material() if look==null else look
	if id=="lantern_shell" and child_name=="EmptyHousing" and look==null:
		instance.material_override=FINISH.surface("lantern_shell")
	if id=="vent_case" and child_name=="EmptyHousing" and look==null:
		instance.material_override=FINISH.surface("vent_case")
	instance.position=at
	instance.visibility_range_end=LOOK.detail_distance_m
	instance.visibility_range_end_margin=10.0
	parent.add_child(instance)
	return instance

static func attach(node: ResourceNode) -> void:
	var existing:=node.get_node_or_null("StrangeCore")
	if existing!=null: existing.free()
	var root:=Node3D.new()
	root.name="StrangeCore"
	node.add_child(root)
	var mesh:=node.get_node("MeshInstance3D") as MeshInstance3D
	mesh.hide()
	var look:=FINISH.surface(String(node.visual))
	var core:=part(root,"thrumroot_core" if node.visual==&"thrumroot" else String(node.visual),"Core",Vector3.ZERO,look)
	node._own_materials.append(look)
	root.add_child(FINISH.build(String(node.visual)))
	# A restored resource's stock appearance uses the frozen generated capacity,
	# not how many units happened to be left when its scene streamed in.
	var capacity:=node._initial_units
	var terrain:=node._terrain()
	if terrain!=null:
		for entry: Dictionary in terrain.map.get("nodes",[]):
			if String(entry.get("resource_id",""))==node.resource_id:
				capacity=maxi(capacity,int(entry.get("units",capacity)))
				break
	root.set_meta("visual_capacity",maxi(capacity,1))
	if node.visual==&"lanternheart": _light(root)
	var shape:=BoxShape3D.new()
	shape.size=bounds_for(node.visual)
	var collider:=node.get_node("CollisionShape3D") as CollisionShape3D
	collider.shape=shape
	collider.position=Vector3.UP*shape.size.y*.5
	if node.presentation_label.is_empty(): node.presentation_label=LABELS.get(String(node.visual),"")
	core.set_meta("rest_position",core.position)
	update(node,float(node.drive_progress)/float(maxi(node.drive_presses,1)))

static func update(node: ResourceNode, progress: float, depleted: bool = false) -> void:
	var root:=node.get_node_or_null("StrangeCore") as Node3D
	if root==null: return
	var core:=root.get_node("Core") as Node3D
	var t:=clampf(progress,0,1)
	var previous:=float(root.get_meta("work_progress",t))
	if t>previous and not depleted: preload("res://art/strange_sound.gd").play(node,String(node.visual))
	root.set_meta("work_progress",t)
	match String(node.visual):
		"lanternheart": core.rotation.z=t*.16; core.position.y=t*.13
		"thrumroot": core.scale=Vector3(1.0+t*.12,1.0-t*.22,1.0)
		"stormglass": core.rotation.z=t*.12
		"pullstone": core.rotation.z=-t*.12; core.position.y=t*.09
		"ventlung": core.scale=Vector3(1.0-t*.16,1.0-t*.3,1.0-t*.16)
	var finish:=root.get_node("RareFinish") as Node3D
	# Filaments follow the worked specimen; host chips remain on its original base.
	for detail in finish.get_children():
		if detail.name!=&"HostFragments":detail.transform=core.transform
	FINISH.set_state(finish,0.0 if depleted else float(node.remaining_units)/float(root.get_meta("visual_capacity",1)),t,node._highlighted)
	root.visible=not depleted
	var light:=root.get_node_or_null("WarmInterior") as OmniLight3D
	if light!=null:
		light.visible=not depleted and node.remaining_units>0
		light.light_energy=LOOK.heart_light_energy*clampf(float(node.remaining_units)/float(root.get_meta("visual_capacity",1)),0,1)

static func _light(parent: Node3D) -> OmniLight3D:
	var light:=OmniLight3D.new()
	light.name="WarmInterior"
	light.position=Vector3(0,.48,0)
	light.light_color=LOOK.heart_colour
	light.light_energy=LOOK.heart_light_energy
	light.omni_range=LOOK.heart_light_range_m
	light.shadow_enabled=false
	light.distance_fade_enabled=true
	light.distance_fade_begin=30
	light.distance_fade_length=12
	parent.add_child(light)
	return light

static func fixture_visual(kind: String) -> Node3D:
	var root:=Node3D.new()
	root.name="StrangeFixtureVisual"
	match kind:
		"lantern_lamp":
			part(root,"lamp","Housing")
			var heart:=part(root,"lanternheart","Heart",Vector3(0,.18,0),material(LOOK.heart_emission,LOOK.paper_sway_m))
			heart.scale=Vector3.ONE*.78
			_light(root)
		"cargo_winch":
			part(root,"winch","Housing")
			part(root,"drum","Drum",Vector3(0,1.05,0))
		"winch_landing": part(root,"landing","Housing")
		"cargo_basket": part(root,"basket","Basket")
		"stormglass_lever":
			part(root,"lever","Housing")
			part(root,"arm","Lever",Vector3(0,.4,0))
		"magnetic_sorter": part(root,"sorter","Housing")
		"ventlung_bellows":
			part(root,"bellows","Housing")
			var bladder:=part(root,"ventlung","Bellows",Vector3(0,.12,0),material(0,0,LOOK.breath_fraction))
			bladder.scale=Vector3(.76,.63,.76)
		"pressure_feeder":
			for entry: Dictionary in MACHINES.feeder_parts:
				var pivot:=Node3D.new()
				pivot.name=String(entry.name)
				pivot.position=entry.at
				root.add_child(pivot)
				var child:=part(pivot,String(entry.asset),"Part")
				var bounds:=child.mesh.get_aabb()
				child.scale=Vector3(entry.size)/bounds.size
				child.position=-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z)*child.scale
	return root

## Catalogue and placement previews flatten the very same articulated visual.
static func fixture_mesh(kind: String) -> Mesh:
	if _fixture_meshes.has(kind): return _fixture_meshes[kind]
	var root:=fixture_visual(kind)
	var mesh:=ArrayMesh.new()
	AuthoredAssets._collect(root,Transform3D.IDENTITY,mesh)
	root.free()
	_fixture_meshes[kind]=mesh
	return mesh
