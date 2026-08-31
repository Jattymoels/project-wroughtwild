class_name WroughtwildInventory
extends Node
## Stores harvested materials by family (construction spec core rule 1:
## "a harvested material is stored as a family, not as every possible
## placeable geometry").

var _material_counts: Dictionary = {}


func get_count(material_family: StringName) -> int:
	return _material_counts.get(material_family, 0)


func add_material(material_family: StringName, amount: int) -> void:
	if amount <= 0:
		return
	_material_counts[material_family] = get_count(material_family) + amount


## Returns false (and consumes nothing) when fewer than amount are held.
func consume_material(material_family: StringName, amount: int) -> bool:
	if get_count(material_family) < amount:
		return false
	_material_counts[material_family] -= amount
	return true
