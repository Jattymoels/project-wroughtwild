class_name WroughtwildInventory
extends Node
## View over the material families the rules library holds for the player
## (construction spec core rule 1: "a harvested material is stored as a
## family, not as every possible placeable geometry"). Counts live in the sim
## so gathering, construction, crafting and orders draw on one economy.

## Rules instance; defaults to the Sim autoload's shared economy.
var sim: WroughtwildSim


func get_sim() -> WroughtwildSim:
	if sim == null:
		sim = load("res://scripts/sim.gd").shared()
	return sim


func get_count(material_family: StringName) -> int:
	return get_sim().material_count(material_family)


func add_material(material_family: StringName, amount: int) -> void:
	if amount <= 0:
		return
	get_sim().add_material(material_family, amount)


## Returns false (and consumes nothing) when fewer than amount are held.
func consume_material(material_family: StringName, amount: int) -> bool:
	return get_sim().consume_material(material_family, amount)
