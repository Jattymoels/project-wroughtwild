class_name TrialFixture
extends StaticBody3D
## A physical route seal, shrine, lift, secret catch or furnace conduit.
## Eligibility/reward remains in TrialSession through the controller.
var fixture_kind := "route"
var stage_index := -1
var choice_index := -1
var title := ""
var detail := ""
var available := false
var claimed := false
var label: Label3D
var glow: MeshInstance3D
var entry_point := Vector3.ZERO
var payload: Dictionary = {}

func trial_label() -> String:
	if claimed: return "%s — spent" % title
	return "%s — E to %s" % [title, detail] if available else "%s — sealed" % title

func refresh() -> void:
	if label != null:
		label.text = title + ("\n" + detail if available and not claimed else "\nSpent" if claimed else "\nSealed")
		label.modulate = Color("e2d5b5") if available else Color("807f72")
	if glow != null:
		glow.visible = available and not claimed

func interact(player: WroughtwildPlayer) -> void:
	if player.trial != null:
		player.trial.interact_fixture(self)
