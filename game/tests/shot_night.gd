extends Node3D
## Scratch: windowed screenshots of dusk and night at the spawn clearing.
## Deleted before commit.

const SANDPIT := preload("res://scenes/sandpit.tscn")
const OUT := "C:/Users/Matty/AppData/Local/Temp/claude/c--Users-Matty-Dev-project-wroughtwild/db10cf9b-05e2-4267-8297-a9e09077bd62/scratchpad/"

var _frame := 0
var _player


func _ready() -> void:
	DisplayServer.window_set_size(Vector2i(1920, 1080))
	add_child(SANDPIT.instantiate())


func _set_fraction(fraction: float) -> void:
	var sim: WroughtwildSim = _player.inventory.get_sim()
	var rules: Dictionary = sim.day_rules()
	sim.set_day_clock((fraction - 0.1) * float(rules["length_seconds"]))


func _physics_process(_delta: float) -> void:
	_frame += 1
	match _frame:
		30:
			_player = get_tree().get_first_node_in_group("player")
			_player.class_panel.choose("ranger")
			_player.rotation.y = 0.6
			_player.spring_arm.rotation.x = -0.05
			_set_fraction(0.62)
		200:
			get_viewport().get_texture().get_image().save_png(OUT + "world_dusk.png")
			_set_fraction(0.83)
		380:
			get_viewport().get_texture().get_image().save_png(OUT + "world_night.png")
			print("HUD: ", _player.hud._status.text)
		384:
			get_tree().quit()
