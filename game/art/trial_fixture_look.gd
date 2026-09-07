extends Resource
## Readable Forge interactions inside their unchanged 1.2 × 2.1 × 0.7 m body.
## Mesh coordinates are an authored kit, not new movement/interaction dimensions.

@export_group("Compact labels")
## Text sits above the fixture with enough room for three short lines.
@export var label_height_m := 2.43
## Local -Z faces the gallery; this keeps the label out of the corridor wall.
@export var label_front_m := 0.6
## These three values limit the plaque to roughly 1.9 metres of world width.
@export var label_font_size := 28
@export var label_pixel_size := 0.004
@export var label_width_pixels := 480.0
## Leave space for the outline rather than wrapping a fourth world-text line.
@export var label_padding_pixels := 16.0
## A concise line retains a name or preview without filling the corridor.
@export var label_character_limit := 34
## Ordinary current choices can be read along an approach, not across the floor.
@export var label_distance_m := 17.0
## A hidden catch's words are visible only close by, capped at player reach.
@export var secret_label_distance_m := 3.5
## Short fade avoids a distracting label pop at the edge of readable distance.
@export var label_fade_margin_m := 0.4
## A dark narrow outline separates small text from pale stone without HUD backing.
@export var label_outline_pixels := 4

@export_group("Restrained state marks")
## Warm copper marks an available interaction; this is much dimmer than danger.
@export var ready_colour := Color("c69a61")
@export var ready_emission := 0.24
## Cool worn metal and neutral stone distinguish finished and unavailable states.
@export var finished_colour := Color("72918b")
@export var sealed_colour := Color("4b514b")
@export var secret_latch_colour := Color("53574e")
@export var text_colour := Color("e2d5b5")
@export var finished_text_colour := Color("a8b4a8")
## Four review palette pairs can coexist in the fixed five-role body cache.
@export var body_mesh_cache_limit := 20
