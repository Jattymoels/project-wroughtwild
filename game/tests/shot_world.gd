extends Node3D
## Scratch: windowed screenshots of the expansive pass - the meadow with
## its cover and the rim on the horizon, then the forest's pines. Deleted
## before commit.

const SANDPIT := preload("res://scenes/sandpit.tscn")
const OUT := "C:/Users/Matty/AppData/Local/Temp/claude/c--Users-Matty-Dev-project-wroughtwild/db10cf9b-05e2-4267-8297-a9e09077bd62/scratchpad/"

var _frame := 0
var _player


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	add_child(SANDPIT.instantiate())


func _biome_cell(id: String) -> Vector2i:
	var terrain: Terrain = _player.get_parent().terrain
	var w := int(terrain.map["width"])
	var h := int(terrain.map["height"])
	var defs: Array = terrain.map["biome_defs"]
	var biomes: PackedInt32Array = terrain.map["biomes"]
	var best := Vector2i(-1, -1)
	var best_d := 1e9
	var sx := int(_player.global_position.x)
	var sz := int(_player.global_position.z)
	for z in range(4, h - 4, 3):
		for x in range(4, w - 4, 3):
			if String(defs[biomes[z * w + x]]["id"]) != id:
				continue
			var d := Vector2(x - sx, z - sz).length()
			if d < best_d:
				best_d = d
				best = Vector2i(x, z)
	return best


func _stand_at(cell: Vector2i, yaw: float, pitch: float) -> void:
	var terrain: Terrain = _player.get_parent().terrain
	var at: Vector3 = terrain.surface_position(cell.x, cell.y)
	_player.global_position = at + Vector3(0, 1.4, 0)
	_player.velocity = Vector3.ZERO
	_player.rotation.y = yaw
	_player.spring_arm.rotation.x = pitch


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		30:
			_player = get_tree().get_first_node_in_group("player")
			_player.class_panel.choose("ranger")
			# The meadow: from the clearing, looking at the far rim.
			_stand_at(Vector2i(int(_player.global_position.x), int(_player.global_position.z)), 0.6, -0.05)
		70:
			get_viewport().get_texture().get_image().save_png(OUT + "world_meadow.png")
			var forest := _biome_cell("forest")
			if forest.x >= 0:
				_stand_at(forest, 2.0, -0.1)
			else:
				print("no forest found")
		120:
			get_viewport().get_texture().get_image().save_png(OUT + "world_forest.png")
			var wastes := _biome_cell("ember_wastes")
			if wastes.x >= 0:
				_stand_at(wastes, 3.5, -0.08)
			else:
				print("no wastes found")
		170:
			get_viewport().get_texture().get_image().save_png(OUT + "world_wastes.png")
		174:
			get_tree().quit()
