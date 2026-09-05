extends Resource
## Screen-space dimensions keep catalogue controls accessible at 720p.
@export var panel_size := Vector2(1000,580)
@export var tile_size := Vector2(150,116)
## Neutral shape previews describe geometry; placed pieces retain their real materials.
@export var thumbnail_colour := Color("b29a73")
@export var thumbnail_view := Vector3(-0.45,0.65,0)
@export var thumbnail_fill := 0.85
## World-space front marker size and lift above the ghost, in metres.
@export var arrow_length := 0.5
@export var arrow_lift := 0.08
@export var arrow_colour := Color("eadbad")
