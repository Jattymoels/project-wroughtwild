class_name DroppedBundle
extends StaticBody3D
## The pack a player drops on open-world death (D-006): every carried material
## family, recoverable by walking back and interacting. Equipment and
## currency are never in it.

var contents: Dictionary = {}


func interact(player: WroughtwildPlayer) -> void:
	player.inventory.get_sim().add_materials(contents)
	player.hud.notify("You recover your pack: %s." % WorkPanel.amounts_text(contents))
	contents = {}
	queue_free()
