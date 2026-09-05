extends Resource
## Brief, non-colliding flakes at the actual work point. No inventory value.
@export var fragment_count := 9
@export var max_bursts := 6
@export var lifetime := 0.48
@export var speed := 1.3
@export var gravity := 4.0
@export var wood_colour := Color("a1875d")
@export var stone_colour := Color("89857c")
## Subtle target lift retains bark/stone colour instead of whitening the whole prop.
@export var hover_energy := 0.025
## Recovery and reach of the gathering hand; never changes work timing.
@export var hand_seconds := 0.24
@export var hand_reach := 0.14
## Width and height of the crosshair work meter in screen pixels.
@export var meter_width := 300.0
@export var meter_height := 5.0
