extends "res://c4/native_tree.gd"
## The predecessor's authored, terrain-free wastes fixture. Live trees use
## their actual Terrain biome through c4/native_tree.gd instead.
func _biome_id() -> String:
	return "ember_wastes"
