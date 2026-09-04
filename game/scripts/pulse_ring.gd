class_name PulseRing
extends RefCounted
## An expanding translucent ring: greybox VFX that tells a radius honestly
## (the horn's call, Wave 7 slice 3). A sphere grows to the radius and
## fades, then frees itself.


static func burst(root: Node, at: Vector3, radius: float, colour: Color, seconds: float = 0.8) -> MeshInstance3D:
	if root == null:
		return null
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = colour
	material.emission_enabled = true
	material.emission = Color(colour.r, colour.g, colour.b)
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	sphere.material = material
	mesh.mesh = sphere
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(mesh)
	mesh.global_position = at
	mesh.scale = Vector3(0.2, 0.05, 0.2)
	var tween := mesh.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh, "scale", Vector3(radius * 2.0, 0.05, radius * 2.0), seconds).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color", Color(colour.r, colour.g, colour.b, 0.0), seconds)
	tween.chain().tween_callback(mesh.queue_free)
	return mesh
