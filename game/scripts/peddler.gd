class_name Peddler
extends StaticBody3D
## The wandering peddler at the spawn clearing: the first thing trade
## currency buys (crafting.json market). Life beyond hostiles, and the
## dependable route to a catalyst when the drops are unkind. Every row
## calls one sim method; prices live in data.

var _mesh: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group("peddlers")
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.55, 0.42, 0.62)
	_mesh = MeshInstance3D.new()
	var body := CapsuleMesh.new()
	body.radius = 0.4
	body.height = 1.8
	_mesh.mesh = body
	_mesh.material_override = material
	_mesh.position = Vector3(0, 0.9, 0)
	add_child(_mesh)
	var pack := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.7, 0.8, 0.5)
	pack.mesh = box
	var pack_material := StandardMaterial3D.new()
	pack_material.albedo_color = Color(0.45, 0.32, 0.2)
	pack.material_override = pack_material
	pack.position = Vector3(0, 1.1, 0.5)
	add_child(pack)
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)
	_label = Label3D.new()
	_label.text = "Peddler"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
	_label.pixel_size = 0.006
	_label.position = Vector3(0, 2.3, 0)
	add_child(_label)


func interact_label() -> String:
	return "Peddler — E to trade"


## Opens the stall: one row per offer, Buy where affordable.
func interact(player: WroughtwildPlayer) -> void:
	var sim: WroughtwildSim = player.inventory.get_sim()
	var rows: Array = []
	for offer in sim.market_offers():
		var have: int = sim.currency_count(offer["currency"])
		var text := "[b]%s[/b]  ×%d  —  %d %s  (you have %d)" % [
			Hud.pretty(offer["item"]), int(offer["count"]), int(offer["price"]), Hud.pretty(offer["currency"]), have]
		rows.append({"text": text, "button": "Buy", "enabled": offer["affordable"],
			"callback": _buy.bind(player, String(offer["item"]))})
	player.open_custom_panel("The Peddler", rows,
		"\"Coin for goods, friend. The road is long and my pack is heavy.\"")


func _buy(player: WroughtwildPlayer, item: String) -> void:
	var sim: WroughtwildSim = player.inventory.get_sim()
	if sim.buy(item):
		player.hud.notify("Bought %s." % Hud.pretty(item))
	else:
		player.hud.notify("You cannot afford that.")
	interact(player)
