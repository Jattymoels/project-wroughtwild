class_name Landmark
extends StaticBody3D
## The lock (Wave 8 slice 2, the curio and the lock): a landmark deep in a
## biome that takes a trial's curio and turns the era. Worldgen places one
## per def (worldgen.json landmarks); the sim says what it wants; E sets
## it. The look is built here from the def's `look`: a cairn with a
## standing stone, a ring of drowned slabs, a black rift with an ember light.

const STONE := Color(0.5, 0.5, 0.54)
const STONE_DARK := Color(0.36, 0.36, 0.4)
const DROWNED := Color(0.32, 0.4, 0.38)
const RIFT := Color(0.08, 0.06, 0.08)

var landmark_id := ""
var display_name := ""
var look := "cairn"


static func spawn(root: Node, def: Dictionary, at: Vector3) -> Landmark:
	var landmark := Landmark.new()
	landmark.landmark_id = String(def.get("id", ""))
	landmark.display_name = String(def.get("display_name", ""))
	landmark.look = String(def.get("look", "cairn"))
	landmark.name = "Landmark_%s" % landmark.landmark_id
	landmark.add_to_group("landmarks")
	landmark.position = at
	root.add_child(landmark)
	landmark.global_position = at
	landmark._build()
	return landmark


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 1.0
	return material


func _box(size: Vector3, at: Vector3, colour: Color, yaw: float = 0.0) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var art := preload("res://art/landmark_look.tres")
	var shade: Color = art.drowned_colour if look=="altar" else art.rift_colour if look=="rift" else art.stone_colour
	mesh.mesh = art.stone(size,shade.lerp(colour,0.15),hash(at))
	mesh.material_override = art.material()
	mesh.position = at
	mesh.rotation.y = yaw
	add_child(mesh)
	return mesh


func _collide(size: Vector3, at: Vector3) -> void:
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	shape.shape = box
	shape.position = at
	add_child(shape)


func _build() -> void:
	var detail := MeshInstance3D.new()
	detail.name = "CurioInlay"
	detail.mesh = preload("res://art/landmark_look.tres").inlay(look)
	detail.material_override = preload("res://art/landmark_look.tres").material()
	add_child(detail)
	match look:
		"altar":
			# A ring of drowned slabs around a dark block, low in the reeds.
			_box(Vector3(1.4, 0.6, 1.4), Vector3(0, 0.3, 0), RIFT)
			for i in 6:
				var angle := TAU * float(i) / 6.0
				_box(Vector3(1.0, 0.35, 0.5), Vector3(cos(angle) * 1.6, 0.18, sin(angle) * 1.6), DROWNED, -angle)
			_box(Vector3(0.5, 2.6, 0.5), Vector3(0, 1.3, -2.4), DROWNED)
			_collide(Vector3(4.0, 0.7, 4.0), Vector3(0, 0.35, 0))
		"rift":
			# A black crack standing out of the ash, lit from within.
			_box(Vector3(1.3, 5.0, 0.5), Vector3(0, 2.5, 0), RIFT, 0.2)
			_box(Vector3(0.7, 3.2, 0.4), Vector3(1.0, 1.6, 0.3), RIFT, -0.3)
			var light := OmniLight3D.new()
			light.light_color = Color(1.0, 0.5, 0.2)
			light.omni_range = 9.0
			light.light_energy = 1.6
			light.position = Vector3(0, 1.2, 0.6)
			add_child(light)
			_collide(Vector3(2.2, 5.0, 1.0), Vector3(0.4, 2.5, 0.1))
		_:
			# A cairn: stacked stones tapering, and a standing stone behind so
			# it reads from across the hills.
			var sizes := [1.6, 1.3, 1.0, 0.7, 0.45]
			var y := 0.0
			for i in sizes.size():
				var s: float = sizes[i]
				_box(Vector3(s, 0.42, s * 0.9), Vector3(0, y + 0.21, 0), STONE if i % 2 == 0 else STONE_DARK, 0.3 * i)
				y += 0.42
			_box(Vector3(0.7, 3.6, 0.45), Vector3(0, 1.8, -1.3), STONE_DARK, 0.15)
			_collide(Vector3(1.7, 2.2, 1.6), Vector3(0, 1.1, 0))
			_collide(Vector3(0.8, 3.6, 0.6), Vector3(0, 1.8, -1.3))


## What the crosshair offers: the curio it wants, or that it waits.
func interact_label(sim: WroughtwildSim) -> String:
	var wants: Dictionary = sim.landmark_wants(landmark_id)
	var title := display_name.capitalize() if display_name != "" else "A landmark"
	if wants.is_empty():
		return "%s — it wants nothing yet" % title
	if bool(wants.get("held", false)):
		return InputPrompts.formatted("%s — {interact} set %s", [title, wants.get("display_name", "the curio")])
	return "%s — it waits for %s" % [title, wants.get("display_name", "something")]


## E: set the curio it wants, and the era turns (the sandpit tells the era).
func interact(player: WroughtwildPlayer) -> void:
	var sim: WroughtwildSim = player.inventory.get_sim()
	var wants: Dictionary = sim.landmark_wants(landmark_id)
	if wants.is_empty():
		player.hud.notify("%s. It wants nothing yet." % display_name.capitalize())
		return
	if sim.set_curio(landmark_id):
		PulseRing.burst(get_parent(), global_position + Vector3(0, 0.6, 0), 14.0, Color(1.0, 0.8, 0.35, 0.5), 1.6)
		player.hud.notify("You set %s in %s. The ground answers." % [wants.get("display_name", "the curio"), display_name])
	else:
		player.hud.notify("%s waits for %s. You do not have it." % [display_name.capitalize(), wants.get("display_name", "something")])
