class_name ResourceNode
extends StaticBody3D
## A harvestable world resource (wood or iron in the slice). Depletes and
## frees itself; a respawn policy is a later design question, not spiked.

## Material family granted per harvest, matching data/tuning ids
## (e.g. "wood", "iron_ore").
@export var material_family: StringName = &"wood"
@export var remaining_units: int = 20
@export var units_per_harvest: int = 2
## Gathering site in data/tuning/world.json this node belongs to; drives
## ambush chance and which enemies arrive. Empty means never ambushed.
@export var gather_site_id: StringName = &""


## Returns the units actually granted (0 when depleted).
func harvest() -> int:
	if remaining_units <= 0:
		return 0

	var granted: int = mini(units_per_harvest, remaining_units)
	remaining_units -= granted

	if remaining_units <= 0:
		queue_free()
	return granted
