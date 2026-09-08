extends Resource
## Presentation only: a low dark host, exposed coloured inclusions and claim tray.
@export var bounds := Vector3(1.5, 1.1, 1.5)
## Existing terrain-height allowance, also used for physical repair contact.
@export var support_tolerance_m := 0.4
## Upward-facing construction must hold the host, rather than touch its side.
@export var support_normal_y := 0.7
@export var red := Color("e56937")
@export var white := Color("d9e6dd")
@export var casing := Color("343a37")
@export var emission_energy := 0.55
@export var clue_spacing_m := 8.0
@export var clue_length_m := 1.0
