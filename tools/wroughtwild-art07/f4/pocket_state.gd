extends Node3D
## SaveManager restores the native ledger after generated pockets are built.
## Observe that ledger so fresh loads cannot retain the initial full visual pose.
var observed_remaining := -1

func _process(_delta: float) -> void:
	var pocket:=get_parent() as PressurePocket
	if pocket==null:return
	var remaining:=int(pocket.source_state().get("remaining",0))
	if remaining!=observed_remaining:
		observed_remaining=remaining
		pocket.refresh_visual()
