class_name OrderBoard
extends StaticBody3D
## The notice board where a bulk order is read and delivered. The order's
## demand, reward and completion all live in the sim (crafting.json orders).

@export var order_id: StringName = &"reinforce_old_mine"


func interact(player: WroughtwildPlayer) -> void:
	player.open_order(order_id)
