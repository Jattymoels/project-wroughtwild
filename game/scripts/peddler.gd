class_name Peddler
extends StaticBody3D
## The wandering peddler at the spawn clearing: goods for kinds, and one
## kind changed for another (crafting.json market; D-023 slice 3). Life
## beyond hostiles, and the dependable route to a catalyst when the drops
## are unkind. Every row calls one sim method; prices live in data.

var _mesh: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group("peddlers")
	var material := StandardMaterial3D.new()
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 1.0
	_mesh = MeshInstance3D.new()
	_mesh.mesh = preload("res://art/character_look.tres").build("peddler")
	_mesh.material_override = material
	_mesh.scale = Vector3.ONE * 1.08
	add_child(_mesh)
	CreatureMotion.attach(_mesh,self,"peddler")
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.45
	capsule.height = 1.8
	shape.shape = capsule
	shape.position = Vector3(0, 0.9, 0)
	add_child(shape)
	_label = Label3D.new()
	_label.set_script(preload("res://scripts/actor_nameplate.gd"))
	_label.text = "Peddler"
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.font_size = 40
	_label.pixel_size = 0.006
	_label.position = Vector3(0, 2.3, 0)
	add_child(_label)


func interact_label() -> String:
	return InputPrompts.text("Peddler — {interact} to trade")


## Opens the stall: one row per offer, Buy where affordable; then the
## exchange, one row per kind you hold enough of, per other kind.
func interact(player: WroughtwildPlayer) -> void:
	var sim: WroughtwildSim = player.inventory.get_sim()
	var rows: Array = []
	for offer in sim.market_offers():
		var have: int = sim.currency_count(offer["currency"])
		var text := "[b]%s[/b]  ×%d  —  %d %s  (you have %d)" % [
			Hud.pretty(offer["item"]), int(offer["count"]), int(offer["price"]), Hud.pretty(offer["currency"]), have]
		rows.append({"text": text, "button": "Buy", "enabled": offer["affordable"],
			"callback": _buy.bind(player, String(offer["item"]))})
	var rate: int = sim.exchange_rate()
	var kinds: Array = sim.currency_kinds()
	for from_kind in kinds:
		if not from_kind["exchangeable"] or int(from_kind["held"]) < rate:
			continue
		for to_kind in kinds:
			if not to_kind["exchangeable"] or to_kind["id"] == from_kind["id"]:
				continue
			rows.append({"text": "Change %d %s for 1 [b]%s[/b]  (you hold %d)" % [
					rate, from_kind["display_name"], to_kind["display_name"], int(from_kind["held"])],
				"button": "Change", "enabled": true,
				"callback": _exchange.bind(player, String(from_kind["id"]), String(to_kind["id"]))})
	player.open_custom_panel("The Peddler", rows,
		"\"Kinds for goods, friend, and I change one kind for another at %d to one. The road is long and my pack is heavy.\"" % rate)


func _buy(player: WroughtwildPlayer, item: String) -> void:
	var sim: WroughtwildSim = player.inventory.get_sim()
	if sim.buy(item):
		player.hud.notify("Bought %s." % Hud.pretty(item))
	else:
		player.hud.notify("You cannot afford that.")
	interact(player)


func _exchange(player: WroughtwildPlayer, from_kind: String, to_kind: String) -> void:
	var sim: WroughtwildSim = player.inventory.get_sim()
	if sim.exchange(from_kind, to_kind):
		player.hud.notify("Changed %d %s for a %s." % [sim.exchange_rate(), Hud.pretty(from_kind), Hud.pretty(to_kind)])
		player.hud.refresh()
	else:
		player.hud.notify("The peddler will not make that change.")
	interact(player)
