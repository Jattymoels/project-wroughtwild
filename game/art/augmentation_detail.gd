class_name AugmentationDetail
extends RefCounted
## Shared local Blender attachment: enclosed in craft, partly exposed in hosts.
## Visual only. Never creates a body, light, interaction target or saved stock.
const LOOK = preload("res://art/augmentation_look.tres")
const INLAY_ID := "cataclysm_augmentation_inlay"
static var _stations: Dictionary = {}

static func inlay_mesh() -> ArrayMesh:
	return AuthoredAssets.mesh_for(INLAY_ID)

static func station_mesh(id: StringName, source: ArrayMesh) -> ArrayMesh:
	var inlay := inlay_mesh()
	if inlay==null: return source
	if _stations.has(id): return _stations[id]
	var output := ArrayMesh.new()
	for surface in source.get_surface_count():
		var copied := SurfaceTool.new()
		copied.begin(Mesh.PRIMITIVE_TRIANGLES)
		copied.append_from(source,surface,Transform3D.IDENTITY)
		copied.set_material(source.surface_get_material(surface))
		copied.commit(output)
	var mounts: Array[Transform3D] = []
	if String(id).begins_with("forge_"):
		mounts.append(Transform3D(Basis.from_scale(Vector3(.18,.39,.30)),Vector3(-.36,.94,.437)))
		if id==&"forge_improved":
			mounts.append(Transform3D(Basis.from_scale(Vector3(.45,.35,.30)),Vector3(0,1.52,.422)))
	elif id==&"workbench":
		mounts.append(Transform3D(Basis.from_scale(Vector3(.20,.35,.20)),Vector3(-.26,.37,.392)))
	elif id==&"mason_yard":
		mounts.append(Transform3D(Basis.from_scale(Vector3(.40,.20,.25)),Vector3(.10,.70,.452)))
	for surface in inlay.get_surface_count():
		var detail := SurfaceTool.new()
		detail.begin(Mesh.PRIMITIVE_TRIANGLES)
		for mount in mounts: detail.append_from(inlay,surface,mount)
		var material := inlay.surface_get_material(surface).duplicate() as StandardMaterial3D
		material.albedo_color*=LOOK.craft_inlay_tint
		material.roughness=maxf(material.roughness,LOOK.craft_inlay_roughness)
		material.emission_energy_multiplier*=LOOK.craft_inlay_emission_scale
		detail.set_material(material)
		detail.commit(output)
	output.set_meta("contained_augmentation",true)
	_stations[id]=output
	return output

static func attach_resource(mesh: MeshInstance3D, id: String, influence: float) -> void:
	var old := mesh.get_node_or_null("EmbeddedAugmentation")
	if old!=null: old.free()
	if influence<LOOK.common_influence_threshold: return
	var source := inlay_mesh()
	if source==null: return
	var detail := MeshInstance3D.new()
	detail.name="EmbeddedAugmentation"
	detail.mesh=source
	var scale_value: float=LOOK.resource_inlay_scale
	if id=="broadleaf_tree":
		detail.position=Vector3(0,.75,.30)
		detail.scale=Vector3(scale_value*.62,scale_value,scale_value*.40)
	elif id=="field_boulder":
		detail.position=Vector3(-.16,.18,.40)
		detail.rotation.x=-.42
		detail.scale=Vector3(scale_value*.72,scale_value*.62,scale_value*.38)
	else:
		detail.free()
		return
	mesh.add_child(detail)
	# Parenting to the existing visual retains ordinary harvesting shrink/fall.
	detail.set_meta("native_influence",influence)

static func append_creature(st: SurfaceTool, role: String) -> void:
	if role=="grazer": return # Quiet, modest life shows the pre-impact scale.
	var source := inlay_mesh()
	if source==null: return
	var s: float=LOOK.creature_inlay_scale
	var mounts: Array[Dictionary]=[]
	if role in ["melee","fast","swarm","lurker"]:
		mounts.append({"bone":0,"at":Vector3(.16,.40,-.32),"scale":Vector3(s*.72,s,s*.55),"tilt":Vector3(.12,PI,-.22)})
		mounts.append({"bone":0,"at":Vector3(-.27,.54,.18),"scale":Vector3(s*.55,s*.65,s*.55),"tilt":Vector3(.1,-PI*.5,.38)})
	elif role=="skirmisher":
		mounts.append({"bone":0,"at":Vector3(-.10,.61,-.17),"scale":Vector3(s*.55,s*.68,s*.45),"tilt":Vector3(.1,PI,.25)})
	else:
		mounts.append({"bone":0,"at":Vector3(-.08,.87,-.20),"scale":Vector3(s*.80,s,s*.45),"tilt":Vector3(0,PI,.12)})
		mounts.append({"bone":1,"at":Vector3(.17,1.29,0),"scale":Vector3(s*.43,s*.75,s*.40),"tilt":Vector3(0,PI*.5,-.28)})
	for mount in mounts:
		var transform := Transform3D(Basis.from_euler(mount.tilt).scaled(mount.scale),mount.at)
		var normal_basis := transform.basis.inverse().transposed()
		for surface in source.get_surface_count():
			var arrays := source.surface_get_arrays(surface)
			var vertices: PackedVector3Array=arrays[Mesh.ARRAY_VERTEX]
			var normals: PackedVector3Array=arrays[Mesh.ARRAY_NORMAL]
			var indices: PackedInt32Array=arrays[Mesh.ARRAY_INDEX]
			var colour: Color=LOOK.creature_inlay_colour if surface%2==0 else LOOK.creature_inlay_dark
			for i in range(indices.size() if not indices.is_empty() else vertices.size()):
				var index: int=indices[i] if not indices.is_empty() else i
				st.set_bones(PackedInt32Array([int(mount.bone),0,0,0]))
				st.set_weights(PackedFloat32Array([1,0,0,0]))
				st.set_color(colour)
				st.set_normal((normal_basis*normals[index]).normalized())
				st.add_vertex(transform*vertices[index])
