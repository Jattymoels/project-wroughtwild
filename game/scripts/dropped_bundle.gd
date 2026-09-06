class_name DroppedBundle
extends StaticBody3D
## The pack a player drops on open-world death (D-006): every carried material
## family, recoverable by walking back and interacting. Equipment and
## currency are never in it.

var contents: Dictionary = {}
var _claimed := false


func interact(player: WroughtwildPlayer) -> void:
	if _claimed or is_queued_for_deletion() or player == null: return
	if player.trial != null and player.trial.active(): return
	_claimed = true
	var recovered := contents
	contents = {}
	player.inventory.get_sim().add_materials(recovered)
	if player.hud != null:
		player.hud.notify("You recover your pack: %s." % WorkPanel.amounts_text(recovered))
	queue_free()
