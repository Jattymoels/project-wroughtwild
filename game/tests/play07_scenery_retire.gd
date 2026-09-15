extends Node3D
func _ready() -> void:
	_run.call_deferred()
func _run() -> void:
	load("res://art/scenery_resources.gd").prepare()
	var scene := load("res://scenes/resource_node.tscn") as PackedScene
	for kind: String in StrangeResourceArt.IDS:
		for repeat in 2:
			printerr("RETIRE_PROBE create ",kind," ",repeat)
			var node := scene.instantiate() as ResourceNode
			node.visual=StringName(kind)
			node.material_family=StringName(kind)
			add_child(node)
			printerr("RETIRE_PROBE remove ",kind," ",repeat)
			remove_child(node)
			node.free()
			printerr("RETIRE_PROBE freed ",kind," ",repeat)
	for i in 3: await get_tree().process_frame
	get_tree().quit()
