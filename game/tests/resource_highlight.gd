extends Node3D
## Shader features stay ready; hover/heat/cooling remain per-node uniforms.
var checks := 0
var failures := 0

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures += 1
		printerr("FAIL RESOURCE HIGHLIGHT: ",label)

func _ready() -> void:
	for visual in ["boulder","tree","seam","iron_vein","copper_vein","tin_vein","ember_vein","silver_vein","slate_seam","shellstone_seam","clay_bank","corkbark_deadfall"]:
		var nodes: Array[ResourceNode] = []
		for i in 2:
			var node: ResourceNode = preload("res://scenes/resource_node.tscn").instantiate()
			node.visual = StringName(visual)
			node.position = Vector3(i*4,0,0)
			node.heat_to_work = 1
			add_child(node)
			nodes.append(node)
		var source := nodes[0]
		var neighbour := nodes[1]
		var initial := [source.remaining_units,source.drive_progress,source.wedge_set]
		check(not source._own_materials.is_empty(), visual+": own materials exist")
		_verify(source,false,false,visual+" initially cold")
		source.set_highlight(true)
		_verify(source,true,false,visual+" hovered")
		_verify(neighbour,false,false,visual+" neighbouring node stays cold")
		source.soak(2,10.0)
		_verify(source,true,true,visual+" heated")
		check(source.quench(),visual+": existing heat-to-crack rule still works")
		_verify(source,true,false,visual+" cracked and hovered")
		source.set_highlight(false)
		_verify(source,false,false,visual+" no longer hovered")
		check(initial==[source.remaining_units,source.drive_progress,source.wedge_set],visual+": visual states do not harvest or drive a wedge")
		for node in nodes: node.free()
	print("RESOURCE_HIGHLIGHT %d checks, %d failures" % [checks,failures])
	get_tree().quit(0 if failures==0 else 1)

func _verify(node: ResourceNode, hovered: bool, heated: bool, label: String) -> void:
	for material in node._own_materials:
		if not material is BaseMaterial3D: continue
		check(material.emission_enabled,label+": shader feature remains prepared")
		var expected: float = 1.2 if heated else preload("res://art/gathering_look.tres").hover_energy if hovered else 0.0
		check(is_equal_approx(material.emission_energy_multiplier,expected),label+": exact glow strength")
		if heated: check(material.emission==Color(1,.4,.05),label+": existing heat colour")
		check(material.albedo_color==(Color(.55,.5,.5) if node.cracked else Color.WHITE),label+": existing cracked tint")
